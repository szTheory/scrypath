defmodule Scrypath.Repository.DependencyAuditTest do
  use ExUnit.Case, async: false

  Code.require_file("scripts/ci/dependency_audit.ex")

  alias Scrypath.Repository.DependencyAudit, as: Audit

  @source_sha String.duplicate("a", 40)
  @clean_output "No retired or security advisory packages found\n"

  test "inventory names exactly the four maintained Mix graphs" do
    assert Audit.inventory() == [
             ".",
             "examples/phoenix_meilisearch",
             "examples/scrypath_ecommerce",
             "scrypath_ops"
           ]
  end

  test "a complete clean inventory attempts four distinct graphs with one root audit" do
    root = fixture_repo()
    calls_key = {__MODULE__, make_ref()}
    runner = command_runner(root, calls_key)

    result =
      Audit.run(
        root: root,
        tracked_file_reader: tracked_reader(Audit.inventory()),
        command_runner: runner,
        clock: clock()
      )

    assert result.status == :clean
    assert Enum.map(result.graphs, & &1.path) == Audit.inventory()
    assert Enum.all?(result.graphs, &(&1.status == :clean and &1.complete?))
    assert Enum.all?(result.graphs, &(&1.source_sha == @source_sha))
    assert Enum.all?(result.graphs, &(&1.fetch.duration_ms == 10))
    assert Enum.all?(result.graphs, &(&1.audit.duration_ms == 10))

    calls = Process.get(calls_key)
    assert Enum.count(calls, &(&1 == {:audit, "."})) == 1
    assert Enum.count(calls, &match?({:audit, _}, &1)) == 4
    assert Enum.count(calls, &match?({:fetch, _}, &1)) == 4
    assert Enum.count(calls, &match?({:audit, "examples/phoenix_meilisearch"}, &1)) == 1
  end

  test "a failed fetch remains incomplete and later graphs are still attempted" do
    root = fixture_repo()
    calls_key = {__MODULE__, make_ref()}

    runner =
      command_runner(root, calls_key, fn
        "mix", ["deps.get", "--check-locked"], opts ->
          if relative(opts[:cd], root) == ".", do: {"fetch failed", 23}, else: {"", 0}

        _, _, _ ->
          :default
      end)

    result =
      Audit.run(
        root: root,
        tracked_file_reader: tracked_reader(Audit.inventory()),
        command_runner: runner,
        clock: clock()
      )

    assert result.status == :failed
    assert Enum.find(result.graphs, &(&1.path == ".")).status == :incomplete
    assert Enum.count(Process.get(calls_key), &match?({:fetch, _}, &1)) == 4
    assert Enum.count(Process.get(calls_key), &match?({:audit, _}, &1)) == 3
  end

  test "missing and unexpected tracked locks fail the exact inventory guard" do
    root = fixture_repo()
    calls_key = {__MODULE__, make_ref()}
    paths = Audit.inventory()
    missing = "scrypath_ops/mix.lock"
    tracked = Enum.reject(paths, &("#{&1}/mix.lock" == missing)) ++ ["new_app/mix.lock"]

    result =
      Audit.run(
        root: root,
        tracked_file_reader: tracked_reader(tracked),
        command_runner: command_runner(root, calls_key),
        clock: clock()
      )

    assert result.status == :failed
    assert Enum.any?(result.errors, &String.contains?(&1, missing))
    assert Enum.any?(result.errors, &String.contains?(&1, "new_app/mix.lock"))
    assert Enum.count(Process.get(calls_key), &match?({:audit, _}, &1)) == 4
  end

  test "inventory omissions and duplicates are explicit while all expected graphs run" do
    root = fixture_repo()
    calls_key = {__MODULE__, make_ref()}
    supplied = [".", ".", "examples/phoenix_meilisearch", "examples/scrypath_ecommerce"]

    result =
      Audit.run(
        root: root,
        inventory: supplied,
        tracked_file_reader: tracked_reader(Audit.inventory()),
        command_runner: command_runner(root, calls_key),
        clock: clock()
      )

    assert result.status == :failed
    assert Enum.any?(result.errors, &String.contains?(&1, "duplicate inventory row: ."))
    assert Enum.any?(result.errors, &String.contains?(&1, "missing inventory row: scrypath_ops"))
    assert Enum.count(Process.get(calls_key), &match?({:audit, _}, &1)) == 4
  end

  test "missing manifests or locks produce explicit rows without blocking other graphs" do
    for missing_file <- ["mix.exs", "mix.lock"] do
      root = fixture_repo()
      File.rm!(Path.join(root, "examples/phoenix_meilisearch/#{missing_file}"))
      calls_key = {__MODULE__, make_ref()}

      result =
        Audit.run(
          root: root,
          tracked_file_reader: tracked_reader(Audit.inventory()),
          command_runner: command_runner(root, calls_key),
          clock: clock()
        )

      phoenix = Enum.find(result.graphs, &(&1.path == "examples/phoenix_meilisearch"))
      assert result.status == :failed
      assert phoenix.status == :incomplete
      assert Enum.count(Process.get(calls_key), &match?({:audit, _}, &1)) == 3
    end
  end

  test "lock changes after fetch are preserved as evidence and skip that graph audit" do
    root = fixture_repo()
    path = "examples/phoenix_meilisearch"
    before = File.read!(Path.join(root, "#{path}/mix.lock"))
    changed = before <> "# changed\n"
    calls_key = {__MODULE__, make_ref()}

    runner =
      command_runner(root, calls_key, fn
        "mix", ["deps.get", "--check-locked"], opts ->
          if relative(opts[:cd], root) == path do
            File.write!(Path.join(opts[:cd], "mix.lock"), changed)
            {"", 0}
          else
            :default
          end

        _, _, _ ->
          :default
      end)

    result =
      Audit.run(
        root: root,
        tracked_file_reader: tracked_reader(Audit.inventory()),
        command_runner: runner,
        clock: clock()
      )

    phoenix = Enum.find(result.graphs, &(&1.path == path))
    assert result.status == :failed
    assert phoenix.status == :incomplete
    assert phoenix.lock_sha_before != phoenix.lock_sha_after
    assert File.read!(Path.join(root, "#{path}/mix.lock")) == changed
    refute {:audit, path} in Process.get(calls_key)
  end

  test "lock changes during audit are reported after the child exits" do
    root = fixture_repo()
    path = "scrypath_ops"
    changed = "# changed during audit\n"
    calls_key = {__MODULE__, make_ref()}

    runner =
      command_runner(root, calls_key, fn
        "mix", ["run" | _args], opts ->
          if relative(opts[:cd], root) == path do
            File.write!(Path.join(opts[:cd], "mix.lock"), changed)
            {audit_metadata() <> @clean_output, 0}
          else
            :default
          end

        _, _, _ ->
          :default
      end)

    result =
      Audit.run(
        root: root,
        tracked_file_reader: tracked_reader(Audit.inventory()),
        command_runner: runner,
        clock: clock()
      )

    ops = Enum.find(result.graphs, &(&1.path == path))
    assert ops.status == :incomplete
    assert ops.lock_sha_before != ops.lock_sha_after
    assert File.read!(Path.join(root, "#{path}/mix.lock")) == changed
  end

  test "ignored findings and any effective ignore configuration are non-clean" do
    root = fixture_repo()
    path = "examples/phoenix_meilisearch"
    calls_key = {__MODULE__, make_ref()}

    output =
      audit_metadata(ignore_source: "project_config", advisories: ~s(["GHSA-test"])) <>
        "Ignored advisories:\n package 1.0.0 - GHSA-test\n"

    runner =
      command_runner(root, calls_key, fn
        "mix", ["run" | _args], opts ->
          if relative(opts[:cd], root) == path, do: {output, 0}, else: :default

        _, _, _ ->
          :default
      end)

    result =
      Audit.run(
        root: root,
        tracked_file_reader: tracked_reader(Audit.inventory()),
        command_runner: runner,
        clock: clock()
      )

    phoenix = Enum.find(result.graphs, &(&1.path == path))
    assert result.status == :failed
    assert phoenix.status == :ignored
    assert phoenix.ignore_advisories.source == "project_config"
    assert phoenix.ignore_advisories.values == ~s(["GHSA-test"])
  end

  test "active findings, unused-ignore warnings, ANSI output and malformed contracts fail closed" do
    cases = [
      {"active finding", audit_metadata() <> "Advisories:\n package 1.0.0 - CVE-2026-0001\n", 1},
      {"unused ignore",
       audit_metadata() <> "WARNING: ignore_advisories entry does not match\n" <> @clean_output,
       0},
      {"ANSI ignored section", audit_metadata() <> "\e[1mIgnored retired:\e[0m\n", 0},
      {"unsupported output", audit_metadata() <> "audit output changed\n", 0},
      {"unsupported Hex", audit_metadata(version: "2.4.2") <> @clean_output, 0},
      {"missing metadata", @clean_output, 0}
    ]

    for {label, output, exit_status} <- cases do
      root = fixture_repo()
      calls_key = {__MODULE__, make_ref()}

      runner =
        command_runner(root, calls_key, fn
          "mix", ["run" | _args], _opts -> {output, exit_status}
          _, _, _ -> :default
        end)

      result =
        Audit.run(
          root: root,
          tracked_file_reader: tracked_reader(Audit.inventory()),
          command_runner: runner,
          clock: clock()
        )

      assert result.status == :failed, label
      refute Enum.all?(result.graphs, &(&1.status == :clean)), label
    end
  end

  test "subprocess output is redacted and only safe audit metadata is retained" do
    root = fixture_repo()
    path = "examples/phoenix_meilisearch"
    secret = "https://private:secret@example.test"
    old = System.get_env("SCRYPATH_MEILISEARCH_URL")
    System.put_env("SCRYPATH_MEILISEARCH_URL", secret)
    on_exit(restore_env("SCRYPATH_MEILISEARCH_URL", old))
    calls_key = {__MODULE__, make_ref()}
    output = audit_metadata() <> "resolver said #{secret}\n" <> @clean_output

    runner =
      command_runner(root, calls_key, fn
        "mix", ["run" | _args], opts ->
          if relative(opts[:cd], root) == path, do: {output, 0}, else: :default

        _, _, _ ->
          :default
      end)

    result =
      Audit.run(
        root: root,
        tracked_file_reader: tracked_reader(Audit.inventory()),
        command_runner: runner,
        clock: clock()
      )

    phoenix = Enum.find(result.graphs, &(&1.path == path))
    assert phoenix.audit_output =~ "[REDACTED]"
    refute phoenix.audit_output =~ secret
  end

  test "the real CLI returns failure when its fake audit child fails" do
    root = fixture_repo()
    bin = Path.join(root, "bin")
    File.mkdir_p!(bin)
    write_executable(Path.join(bin, "git"), fake_git(Audit.inventory()))
    write_executable(Path.join(bin, "mix"), fake_mix())

    elixir = System.find_executable("elixir") || flunk("elixir executable is unavailable")
    script = Path.expand("scripts/ci/dependency_audit.exs")
    path = bin <> ":" <> System.get_env("PATH", "")

    {success_output, success_status} =
      System.cmd(elixir, [script], cd: root, env: [{"PATH", path}])

    assert success_status == 0
    assert success_output =~ "status=clean"
    assert success_output =~ "graphs=4"

    {failure_output, failure_status} =
      System.cmd(elixir, [script],
        cd: root,
        env: [{"PATH", path}, {"FAKE_AUDIT_STATUS", "19"}]
      )

    assert failure_status != 0
    assert failure_output =~ "status=failed"
  end

  test "the repository-only audit script is outside the Hex package whitelist" do
    refute "scripts" in Scrypath.MixProject.project()[:package][:files]
  end

  defp fixture_repo do
    root =
      Path.join(
        System.tmp_dir!(),
        "scrypath-dependency-audit-test-#{System.unique_integer([:positive, :monotonic])}"
      )

    Enum.each(Audit.inventory(), fn path ->
      dir = if path == ".", do: root, else: Path.join(root, path)
      File.mkdir_p!(dir)
      File.write!(Path.join(dir, "mix.exs"), "defmodule Fixture.MixProject do end\n")
      File.write!(Path.join(dir, "mix.lock"), "# #{path}\n")
    end)

    on_exit(fn -> File.rm_rf!(root) end)
    root
  end

  defp tracked_reader(paths) do
    files = Enum.map(paths, &if(&1 == ".", do: "mix.lock", else: "#{&1}/mix.lock"))
    fn _root -> {:ok, files} end
  end

  defp command_runner(root, calls_key, override \\ fn _, _, _ -> :default end) do
    fn command, args, opts ->
      relative_path = relative(opts[:cd], root)

      call =
        if command == "git",
          do: {:git, relative_path, args},
          else: {command_type(args), relative_path}

      Process.put(calls_key, Process.get(calls_key, []) ++ [call])

      case override.(command, args, opts) do
        :default -> default_response(command, args, opts, relative_path)
        result -> result
      end
    end
  end

  defp default_response("git", ["rev-parse", "HEAD"], _opts, _path), do: {@source_sha <> "\n", 0}

  defp default_response("mix", ["deps.get", "--check-locked"], _opts, _path), do: {"", 0}

  defp default_response("mix", ["run" | _args], _opts, _path),
    do: {audit_metadata() <> @clean_output, 0}

  defp default_response(_command, _args, _opts, _path), do: {"unexpected command", 90}

  defp command_type(["deps.get", "--check-locked"]), do: :fetch
  defp command_type(["run" | _]), do: :audit
  defp command_type(_), do: :other

  defp relative(path, root) do
    case Path.relative_to(Path.expand(path), Path.expand(root)) do
      "." -> "."
      value -> value
    end
  end

  defp clock do
    key = {__MODULE__, make_ref()}

    fn ->
      now = Process.get(key, 0)
      Process.put(key, now + 10)
      now
    end
  end

  defp audit_metadata(opts \\ []) do
    opts =
      Keyword.merge(
        [version: "2.5.1", ignore_source: "default", advisories: "[]", retirements: "[]"],
        opts
      )

    """
    SCRYPATH_AUDIT_META_VERSION=#{opts[:version]}
    SCRYPATH_AUDIT_META_IGNORE_ADVISORIES_SOURCE=#{opts[:ignore_source]}
    SCRYPATH_AUDIT_META_IGNORE_ADVISORIES_VALUES=#{Base.encode64(opts[:advisories])}
    SCRYPATH_AUDIT_META_IGNORE_RETIREMENTS_SOURCE=#{opts[:ignore_source]}
    SCRYPATH_AUDIT_META_IGNORE_RETIREMENTS_VALUES=#{Base.encode64(opts[:retirements])}
    """
  end

  defp fake_git(paths) do
    tracked =
      Enum.map_join(paths, "", fn path ->
        lock = if path == ".", do: "mix.lock", else: "#{path}/mix.lock"
        "printf '%s\\0' '#{lock}'\n"
      end)

    """
    #!/bin/sh
    if [ "$1" = "ls-files" ]; then
    #{tracked}      exit 0
    fi
    if [ "$1" = "rev-parse" ]; then echo '#{@source_sha}'; exit 0; fi
    exit 2
    """
  end

  defp fake_mix do
    """
    #!/bin/sh
    if [ "$1" = "deps.get" ]; then exit 0; fi
    if [ "$1" = "run" ]; then
      cat <<'AUDIT_OUTPUT'
    #{audit_metadata()}#{@clean_output}AUDIT_OUTPUT
      status="${FAKE_AUDIT_STATUS:-0}"
      if [ "$status" -ne 0 ]; then echo 'Advisories:'; exit "$status"; fi
      exit 0
    fi
    exit 2
    """
  end

  defp write_executable(path, content) do
    File.write!(path, content)
    File.chmod!(path, 0o755)
  end

  defp restore_env(name, nil), do: fn -> System.delete_env(name) end
  defp restore_env(name, value), do: fn -> System.put_env(name, value) end
end
