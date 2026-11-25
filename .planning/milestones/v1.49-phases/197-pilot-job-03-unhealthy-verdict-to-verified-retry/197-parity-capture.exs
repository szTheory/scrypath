defmodule ScrypathOps.ParityCaptureTest do
  @moduledoc """
  THROWAWAY LOCAL EVIDENCE, never a gate and never committed under a test path (Phase 197,
  PILOT-03). Captures the rendered Search health and Failed sync pages (and the pages the copy
  rules anchor) so a before and after of an extraction can be compared as canonical trees, not text.
  Reused by Plans 02, 03 and 04.

  ## Usage

  Copy this file to `scrypath_ops/test/zz_parity_capture_test.exs`, run it, delete the copy.

  Capture the HEAD tree:

      cd scrypath_ops
      PARITY_OUT=<dir>/head mix test test/zz_parity_capture_test.exs

  Capture the BASE tree (the commit before the extraction):

      git worktree add <scratchpad>/parity-base <base sha>
      rsync -a scrypath_ops/deps/ <scratchpad>/parity-base/scrypath_ops/deps/
      rsync -a scrypath_ops/_build/ <scratchpad>/parity-base/scrypath_ops/_build/
      cp <this file> <scratchpad>/parity-base/scrypath_ops/test/zz_parity_capture_test.exs
      (cd <scratchpad>/parity-base/scrypath_ops && PARITY_OUT=<dir>/base mix test test/zz_parity_capture_test.exs)
      git worktree remove --force <scratchpad>/parity-base

  Capture-only mode needs no `HtmlCanon`, so the base tree may predate it.

  Compare (in the HEAD tree, where `ScrypathOps.Test.HtmlCanon` exists):

      PARITY_COMPARE=<dir>/base,<dir>/head mix test test/zz_parity_capture_test.exs

  It prints each differing file with a unified diff of the canonical lines and a final
  `PARITY: <n> differences over <m> captures` line. A file present on one side only counts as a
  difference. Delete the copied file and remove the worktree afterwards (the plan's verify step
  asserts both).

  ## What is captured

    * every scenario in `ScrypathFixtures.Scenarios.ids/0`: `<id>__health.html` and
      `<id>__failed-sync.html` (FixtureEnv, `live/2`, `render_async/1`, `render/1`)
    * `phase173__<name>.html`: `/ops/phase173/health?scenario=<name>` for every name the Phase 173
      fixture source declares (read from its source, so the list cannot drift)
    * `copy__<surface id>.html`: every `ScrypathOps.Test.CopySurfaces` anchored surface

  A page that raises is captured as `CRASH: <message>` so a crash that exists on both sides
  compares equal and a new one shows up as a difference.
  """
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.CopyStubs.Posture, as: PostureStubs
  alias ScrypathOps.Test.CopySurfaces
  alias ScrypathOps.Test.FixtureEnv

  @pages [{"health", "/ops/health"}, {"failed-sync", "/ops/failed-sync"}]
  @fixture_source Path.expand("support/phase173_fixture_source.ex", __DIR__)

  if System.get_env("PARITY_OUT") do
    setup do
      previous = PostureStubs.put_env()
      PostureStubs.start_agent()

      on_exit(fn ->
        PostureStubs.restore_env(previous)
        PostureStubs.stop_agent()
      end)

      :ok
    end

    test "capture every scenario page, phase173 fixture page and copy surface", %{conn: conn} do
      out = System.fetch_env!("PARITY_OUT")
      File.mkdir_p!(out)
      now = ScrypathFixtures.preview_epoch()

      for id <- ScrypathFixtures.Scenarios.ids(), {page, path} <- @pages do
        restore = FixtureEnv.put(ScrypathFixtures.Scenarios.get!(id, now))

        try do
          write(out, "#{id}__#{page}", capture(fn -> mounted_html(conn, path) end))
        after
          restore.()
        end
      end

      for name <- phase173_names() do
        html =
          capture(fn ->
            html = mounted_html(conn, "/ops/phase173/health?scenario=#{name}")
            # The scenario must really be selected: an unknown name silently falls back to healthy.
            selected = html |> LazyHTML.from_fragment() |> LazyHTML.query("option[selected]")
            if LazyHTML.attribute(selected, "value") != [name], do: raise("scenario #{name} not selected")
            html
          end)

        write(out, "phase173__#{name}", html)
      end

      # The copy surfaces read the wall clock unless the test clock is pinned, so pin it for them.
      clock = Path.join(System.tmp_dir!(), "parity-clock-#{System.unique_integer([:positive])}.txt")
      File.write!(clock, DateTime.to_iso8601(now) <> "\n")
      previous_clock = Application.fetch_env(:scrypath_ops, :test_clock_file)
      Application.put_env(:scrypath_ops, :test_clock_file, clock)

      try do
        for id <- CopySurfaces.ids() do
          write(out, "copy__#{id}", capture(fn -> CopySurfaces.render(id, %{conn: conn}) end))
        end
      after
        case previous_clock do
          {:ok, value} -> Application.put_env(:scrypath_ops, :test_clock_file, value)
          :error -> Application.delete_env(:scrypath_ops, :test_clock_file)
        end

        File.rm(clock)
      end

      files = out |> File.ls!() |> Enum.filter(&String.ends_with?(&1, ".html"))
      IO.puts("PARITY CAPTURE: #{length(files)} files written to #{out}")
      assert files != []
    end
  end

  if System.get_env("PARITY_COMPARE") do
    test "compare two capture directories as canonical trees" do
      [base, head] = "PARITY_COMPARE" |> System.fetch_env!() |> String.split(",", trim: true)
      names = Enum.uniq(list(base) ++ list(head)) |> Enum.sort()

      differing =
        for name <- names, diff = compare(Path.join(base, name), Path.join(head, name)), do: {name, diff}

      for {name, diff} <- differing do
        IO.puts("\n--- DIFFERENT: #{name}\n#{diff}")
      end

      IO.puts("\nPARITY: #{length(differing)} differences over #{length(names)} captures")
      assert names != []
    end
  end

  defp list(dir), do: dir |> File.ls!() |> Enum.filter(&String.ends_with?(&1, ".html"))

  defp compare(base_file, head_file) do
    case {File.read(base_file), File.read(head_file)} do
      {{:ok, a}, {:ok, b}} ->
        a_lines = a |> canon() |> String.split("\n")
        b_lines = b |> canon() |> String.split("\n")

        if a_lines == b_lines, do: nil, else: unified(a_lines, b_lines)

      {{:ok, _}, {:error, _}} ->
        "only in base"

      {{:error, _}, {:ok, _}} ->
        "only in head"
    end
  end

  # A CRASH capture is plain text, not HTML: compare it as one line.
  defp canon("CRASH: " <> _ = text), do: text
  defp canon(html) do
    # A recovery handle is 24 random bytes, new on every render of a queued retry.
    html
    |> then(&Regex.replace(~r/recovery=[A-Za-z0-9_\-]{16,}/, &1, "recovery=HANDLE"))
    |> ScrypathOps.Test.HtmlCanon.canon()
  end

  defp unified(a, b) do
    a
    |> List.myers_difference(b)
    |> Enum.flat_map(fn
      {:eq, _lines} -> []
      {:del, lines} -> Enum.map(lines, &"- #{&1}")
      {:ins, lines} -> Enum.map(lines, &"+ #{&1}")
    end)
    |> Enum.join("\n")
  end

  defp mounted_html(conn, path) do
    {:ok, view, _html} = live(conn, path)
    _ = render_async(view, 5_000)
    render(view)
  end

  defp capture(fun) do
    fun.()
  rescue
    exception -> "CRASH: " <> Exception.message(exception)
  catch
    kind, reason -> "CRASH: #{kind} #{inspect(reason)}"
  end

  defp write(out, name, html), do: File.write!(Path.join(out, name <> ".html"), html)

  defp phase173_names do
    source = File.read!(@fixture_source)

    [_, list] = Regex.run(~r/normalize_scenario\(scenario\)\s+when scenario in \[(.*?)\]/s, source)
    Regex.scan(~r/"([^"]+)"/, list) |> Enum.map(fn [_, name] -> name end)
  end
end
