defmodule ScrypathOpsWeb.FixturesDeterminismTest do
  @moduledoc false
  # Phase 196 (FIX-04, research N15): rendering the same scenario at two clocks changes only
  # time-derived text. Every stamp in a builder is `now` minus an offset, so moving `now` moves the
  # absolute times and nothing else: relative ages ("2 hrs ago") stay put.
  #
  # The render carries per-render randomness that has nothing to do with time (LiveView ids and
  # tokens, and DOM ids built from `System.unique_integer/1`), so the comparison runs over a
  # normalized projection of the DOM. The plant pins the task times while the scenario clock moves
  # and asserts the cause itself, the relative-age text, rather than only that the two renders
  # differ: a bare inequality passes for the wrong reason (research Pitfall 5).
  #
  # App env is global, so this module is async: false and every render restores what it touched.
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathFixtures.Logistify
  alias ScrypathOps.Test.FixtureEnv

  @three_days 3 * 86_400

  # What moves with `now`: absolute stamps, in the UI's own format and as ISO 8601.
  @absolute_ui ~r/[A-Z][a-z]{2} \d{1,2}, \d{4} at \d{2}:\d{2}:\d{2} UTC/
  @absolute_iso ~r/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})/

  # What must not move: how long ago something happened, as `ScrypathOpsWeb.Components.OpsUI` words it.
  @relative_age ~r/just now|\d+ (?:min|mins|hr|hrs|day|days) ago/

  # Per-render randomness.
  @phx_data ~r/ data-phx-[\w-]+="[^"]*"/
  @phx_id ~r/id="phx-[^"]*"/
  @unique_id ~r/ops-(time|section|empty-hero-heading)-\d+/

  describe "the Logistify deep queue at two clocks" do
    test "differs only in time-derived text" do
      earlier = render_health(deep_queue(epoch()))
      later = render_health(deep_queue(DateTime.add(epoch(), @three_days)))

      # positive control: the two renders really used different clocks
      assert absolute_times(earlier) != []
      assert absolute_times(earlier) != absolute_times(later)

      # the property: nothing but absolute time moved
      assert normalize(earlier) == normalize(later)

      # and relative age, which is now-relative in every builder, did not move at all
      assert relative_ages(normalize(earlier)) != []
      assert relative_ages(normalize(earlier)) == relative_ages(normalize(later))
    end

    test "the normalizer is live: the raw projections differ in more than time" do
      first = render_health(deep_queue(epoch()))
      second = render_health(deep_queue(epoch()))

      # same scenario, same clock: any raw difference is per-render randomness
      assert first |> project() |> Enum.any?(&Regex.match?(@unique_id, &1))
      assert project(first) != project(second)
      assert normalize(first) == normalize(second)
    end
  end

  describe "a plant that pins the task times while the scenario clock moves" do
    test "differs in relative age and in nothing else" do
      clean = deep_queue(epoch())
      moved = deep_queue(DateTime.add(epoch(), @three_days))

      # the plant: tasks built at the fixed epoch, scenario.now three days later
      planted =
        put_in(
          moved.scrypath_opts[:meilisearch_tasks],
          Keyword.fetch!(clean.scrypath_opts, :meilisearch_tasks)
        )

      assert planted.now == moved.now

      assert Keyword.fetch!(planted.scrypath_opts, :meilisearch_tasks) ==
               Keyword.fetch!(clean.scrypath_opts, :meilisearch_tasks)

      clean_page = clean |> render_health() |> normalize()
      planted_page = planted |> render_health() |> normalize()

      # the cause: relative age moved
      assert relative_ages(clean_page) != relative_ages(planted_page)

      # and only that: with relative ages masked as well, the two pages are equal
      assert mask_relative(clean_page) == mask_relative(planted_page)
    end
  end

  # -- helpers -------------------------------------------------------------------------------

  defp epoch, do: ScrypathFixtures.preview_epoch()

  defp deep_queue(now), do: Logistify.scenario(:deep_queue, now: now)

  # Puts the scenario in app env, renders /ops/health through LiveViewTest, and puts everything
  # back. `render(lv)` is the LiveView's own HTML; the full `live/2` document carries a csrf meta
  # tag that changes on every request.
  defp render_health(scenario) do
    restore = FixtureEnv.put(scenario)
    on_exit(restore)

    try do
      {:ok, lv, _document} = live(build_conn(), ~p"/ops/health")
      render(lv)
    after
      restore.()
    end
  end

  # The whole rendered DOM as one line per element start tag (with every attribute) and per
  # non-blank text node, in document order. Comments are dropped.
  defp project(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.to_tree(sort_attributes: true, skip_whitespace_nodes: true)
    |> flatten()
  end

  defp flatten(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &flatten/1)
  defp flatten({:comment, _text}), do: []

  defp flatten({tag, attrs, children}) do
    rendered = Enum.map_join(attrs, "", fn {name, value} -> ~s( #{name}="#{value}") end)
    ["<#{tag}#{rendered}>" | flatten(children)]
  end

  defp flatten(text) when is_binary(text) do
    case String.trim(text) do
      "" -> []
      trimmed -> [trimmed]
    end
  end

  # Removes the per-render randomness and the absolute times, and keeps relative ages.
  defp normalize(html) when is_binary(html), do: html |> project() |> Enum.map(&normalize_line/1)

  defp normalize_line(line) do
    line
    |> then(&Regex.replace(@phx_data, &1, ""))
    |> then(&Regex.replace(@phx_id, &1, ~s(id="phx-ID")))
    |> then(&Regex.replace(@unique_id, &1, "ops-\\1-N"))
    |> then(&Regex.replace(@absolute_ui, &1, "<absolute time>"))
    |> then(&Regex.replace(@absolute_iso, &1, "<iso time>"))
  end

  # Relative ages masked as well, for the plant's "and nothing else" half.
  defp mask_relative(lines), do: Enum.map(lines, &Regex.replace(@relative_age, &1, "<age>"))

  defp absolute_times(html) when is_binary(html) do
    html
    |> project()
    |> Enum.flat_map(&Regex.scan(@absolute_ui, &1))
    |> List.flatten()
  end

  defp relative_ages(lines) do
    lines |> Enum.flat_map(&Regex.scan(@relative_age, &1)) |> List.flatten()
  end
end
