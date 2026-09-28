defmodule Scrypath.Repository.DependencyAudit do
  @moduledoc false

  @inventory [
    ".",
    "examples/phoenix_meilisearch",
    "examples/scrypath_ecommerce",
    "scrypath_ops"
  ]
  @supported_hex_version "2.5.1"
  @clean_marker "No retired or security advisory packages found"
  @meta_prefix "SCRYPATH_AUDIT_META_"

  def inventory, do: @inventory

  def run(opts \\ []) do
    root = opts |> Keyword.get(:root, File.cwd!()) |> Path.expand()
    supplied_inventory = Keyword.get(opts, :inventory, @inventory)
    runner = Keyword.get(opts, :command_runner, &System.cmd/3)
    tracked_file_reader = Keyword.get(opts, :tracked_file_reader, &read_tracked_files/1)
    clock = Keyword.get(opts, :clock, fn -> System.monotonic_time(:millisecond) end)
    progress = Keyword.get(opts, :progress, fn _message -> :ok end)

    script_path =
      Keyword.get(opts, :script_path, Path.expand("scripts/ci/dependency_audit.exs", File.cwd!()))

    errors = inventory_errors(supplied_inventory)
    {tracked, tracked_errors} = tracked_lock_files(tracked_file_reader, root)
    errors = errors ++ tracked_errors ++ tracked_lock_errors(tracked)
    {source_sha, source_errors} = source_sha(runner, root)
    errors = errors ++ source_errors
    inventory_counts = if is_list(supplied_inventory), do: counts(supplied_inventory), else: %{}

    graphs =
      Enum.map(@inventory, fn path ->
        progress.("dependency-audit starting graph=#{path}")

        run_graph(
          path,
          root,
          source_sha,
          Map.get(inventory_counts, path, 0),
          runner,
          clock,
          script_path,
          progress
        )
      end)

    %{
      status:
        if(errors == [] and Enum.all?(graphs, &(&1.status == :clean)), do: :clean, else: :failed),
      errors: errors,
      graphs: graphs
    }
  end

  def main(args \\ System.argv()) do
    case args do
      [] ->
        result = run(progress: &IO.puts/1)
        print_result(result)
        if result.status == :clean, do: :ok, else: System.halt(1)

      ["--graph"] ->
        audit_current_graph()

      _ ->
        IO.puts(:stderr, "usage: elixir scripts/ci/dependency_audit.exs [--graph]")
        System.halt(64)
    end
  end

  def audit_current_graph do
    archive_path = Path.join([Mix.path_for(:archives), "hex-2.5.1", "hex-2.5.1", "ebin"])

    unless File.dir?(archive_path) do
      Mix.raise("dependency audit requires the pinned Hex 2.5.1 archive")
    end

    Code.prepend_path(archive_path)
    Application.load(:hex)
    version = Application.spec(:hex, :vsn) |> List.to_string()

    unless version == @supported_hex_version do
      Mix.raise("dependency audit supports Hex #{@supported_hex_version}; found #{version}")
    end

    apply(Module.concat(["Hex"]), :start, [])
    metadata = ignore_metadata()

    IO.puts("#{@meta_prefix}VERSION=#{version}")

    Enum.each(metadata, fn {name, source, values} ->
      IO.puts("#{@meta_prefix}#{name}_SOURCE=#{source}")
      IO.puts("#{@meta_prefix}#{name}_VALUES=#{Base.encode64(values)}")
    end)

    {audit_output, status} = System.cmd("mix", ["hex.audit"], stderr_to_stdout: true)
    IO.write(redact(audit_output))

    if status != 0 do
      System.halt(status)
    end

    :ok
  end

  defp run_graph(path, root, source_sha, inventory_count, runner, clock, script_path, progress) do
    graph_dir = if path == ".", do: root, else: Path.join(root, path)
    lock_path = Path.join(graph_dir, "mix.lock")
    manifest_path = Path.join(graph_dir, "mix.exs")

    base = %{
      path: path,
      source_sha: source_sha,
      lock_sha_before: nil,
      lock_sha_after: nil,
      hex_version: nil,
      fetch: %{status: :not_run, duration_ms: nil},
      audit: %{status: :not_run, duration_ms: nil},
      ignore_advisories: %{source: "unavailable", values: "unavailable"},
      ignore_retirements: %{source: "unavailable", values: "unavailable"},
      fetch_output: "",
      audit_output: "",
      status: :incomplete,
      complete?: false,
      ignored?: false,
      errors: []
    }

    inventory_errors =
      cond do
        inventory_count == 0 -> ["missing inventory row: #{path}"]
        inventory_count > 1 -> ["duplicate inventory row: #{path}"]
        true -> []
      end

    cond do
      not File.dir?(graph_dir) ->
        Map.put(base, :errors, inventory_errors ++ ["graph directory is missing: #{path}"])

      not File.regular?(manifest_path) ->
        Map.put(base, :errors, inventory_errors ++ ["Mix manifest is missing: #{path}/mix.exs"])

      not File.regular?(lock_path) ->
        Map.put(base, :errors, inventory_errors ++ ["Mix lock is missing: #{path}/mix.lock"])

      true ->
        execute_graph(
          base,
          path,
          graph_dir,
          lock_path,
          source_sha,
          inventory_errors,
          runner,
          clock,
          script_path,
          progress
        )
    end
  end

  defp execute_graph(
         base,
         path,
         graph_dir,
         lock_path,
         source_sha,
         inventory_errors,
         runner,
         clock,
         script_path,
         progress
       ) do
    {:ok, source_lock} = File.read(lock_path)
    source_hash = sha256(source_lock)

    progress.("dependency-audit fetching graph=#{path}")

    fetch_command = fn ->
      runner.("mix", ["deps.get", "--check-locked"], cd: graph_dir, stderr_to_stdout: true)
    end

    {fetch_result, fetch_ms} = measured(clock, fetch_command)
    fetch_output = fetch_result.output |> redact() |> String.trim_trailing()
    after_fetch = read_lock(lock_path)
    after_fetch_hash = hash_if_readable(after_fetch)
    fetch_succeeded = fetch_result.status == 0

    common =
      base
      |> Map.put(:source_sha, source_sha)
      |> Map.put(:lock_sha_before, source_hash)
      |> Map.put(:lock_sha_after, after_fetch_hash)
      |> Map.put(:fetch, %{status: fetch_result.outcome, duration_ms: fetch_ms})
      |> Map.put(:fetch_output, fetch_output)
      |> Map.put(
        :errors,
        inventory_errors ++
          fetch_result.errors ++ command_status_error(fetch_result, "mix deps.get --check-locked")
      )

    cond do
      not fetch_succeeded ->
        changed = lock_change_error(source_lock, after_fetch, "fetch")
        finish_graph(common, :incomplete, false, false, changed)

      after_fetch != {:ok, source_lock} ->
        finish_graph(common, :incomplete, false, false, ["Mix lock bytes changed during fetch"])

      true ->
        progress.("dependency-audit auditing graph=#{path}")

        run_audit(
          common,
          graph_dir,
          lock_path,
          source_lock,
          source_hash,
          runner,
          clock,
          script_path
        )
    end
  end

  defp run_audit(
         base,
         graph_dir,
         lock_path,
         source_lock,
         source_hash,
         runner,
         clock,
         script_path
       ) do
    args = [
      "run",
      "--no-start",
      "--no-compile",
      "--no-deps-check",
      Path.expand(script_path),
      "--graph"
    ]

    audit_command = fn -> runner.("mix", args, cd: graph_dir, stderr_to_stdout: true) end
    {audit_result, audit_ms} = measured(clock, audit_command)
    audit_output = audit_result.output |> redact() |> String.trim_trailing()
    after_audit = read_lock(lock_path)
    after_audit_hash = hash_if_readable(after_audit)
    parsed = parse_audit(audit_output, audit_result.status)

    result =
      base
      |> Map.put(:lock_sha_after, after_audit_hash)
      |> Map.put(:audit, %{status: audit_result.outcome, duration_ms: audit_ms})
      |> Map.put(:audit_output, audit_output)
      |> Map.put(:hex_version, parsed.hex_version)
      |> Map.put(:ignore_advisories, parsed.ignore_advisories)
      |> Map.put(:ignore_retirements, parsed.ignore_retirements)
      |> Map.put(
        :errors,
        base.errors ++
          audit_result.errors ++ parsed.errors ++ command_status_error(audit_result, "Hex audit")
      )

    cond do
      after_audit != {:ok, source_lock} ->
        finish_graph(result, :incomplete, false, parsed.ignored?, [
          "Mix lock bytes changed during audit"
        ])

      source_hash != base.lock_sha_before ->
        finish_graph(result, :incomplete, false, parsed.ignored?, [
          "source lock hash changed before audit"
        ])

      result.source_sha == nil ->
        finish_graph(result, :incomplete, false, parsed.ignored?, [
          "source checkout SHA unavailable"
        ])

      true ->
        finish_graph(result, parsed.status, parsed.complete?, parsed.ignored?, parsed.errors)
    end
  end

  defp finish_graph(graph, status, complete?, ignored?, extra_errors) do
    errors = Enum.uniq(graph.errors ++ extra_errors)
    status = if errors != [] and status == :clean, do: :incomplete, else: status

    graph
    |> Map.put(:status, status)
    |> Map.put(:complete?, complete? and status in [:clean, :affected, :ignored])
    |> Map.put(:ignored?, ignored?)
    |> Map.put(:errors, errors)
  end

  defp parse_audit(output, exit_status) do
    plain = strip_ansi(output)
    metadata = metadata_lines(plain)
    meta_errors = metadata_errors(metadata)
    version = metadata |> Map.get("VERSION", []) |> List.first()
    advisories = ignore_metadata_from_lines(metadata, "IGNORE_ADVISORIES")
    retirements = ignore_metadata_from_lines(metadata, "IGNORE_RETIREMENTS")
    ignored_section? = Regex.match?(~r/^\s*Ignored\s+(?:retired|advisories):/im, plain)
    warning? = Regex.match?(~r/\bwarning\b/i, plain)
    active_findings? = Regex.match?(~r/^\s*(?:Retired|Advisories):/im, plain)
    clean_count = plain |> String.split("\n") |> Enum.count(&(String.trim(&1) == @clean_marker))
    configured? = configured_ignore?(advisories) or configured_ignore?(retirements)
    ignored? = ignored_section? or configured?

    errors =
      meta_errors ++
        if(warning?, do: ["Hex audit emitted a warning or unused-ignore warning"], else: []) ++
        if(ignored_section?, do: ["Hex audit reported ignored findings"], else: []) ++
        if(configured?, do: ["Hex ignore configuration is active"], else: []) ++
        if(active_findings?,
          do: ["Hex audit reported active advisories or retired packages"],
          else: []
        )

    status =
      cond do
        meta_errors != [] -> :incomplete
        active_findings? -> :affected
        ignored? -> :ignored
        warning? -> :incomplete
        exit_status != 0 -> :incomplete
        clean_count != 1 -> :incomplete
        true -> :clean
      end

    %{
      status: status,
      complete?: meta_errors == [] and (clean_count == 1 or active_findings? or ignored_section?),
      ignored?: ignored?,
      errors: errors,
      hex_version: version,
      ignore_advisories: advisories,
      ignore_retirements: retirements
    }
  end

  defp metadata_lines(output) do
    output
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(String.trim(line), "=", parts: 2) do
        [full_key, value] when is_binary(full_key) ->
          if String.starts_with?(full_key, @meta_prefix) do
            key = String.replace_prefix(full_key, @meta_prefix, "")
            Map.update(acc, key, [value], &(&1 ++ [value]))
          else
            acc
          end

        _ ->
          acc
      end
    end)
  end

  defp metadata_errors(metadata) do
    required = [
      {"VERSION", @supported_hex_version},
      {"IGNORE_ADVISORIES_SOURCE", nil},
      {"IGNORE_ADVISORIES_VALUES", nil},
      {"IGNORE_RETIREMENTS_SOURCE", nil},
      {"IGNORE_RETIREMENTS_VALUES", nil}
    ]

    Enum.flat_map(required, fn {key, expected} ->
      case Map.get(metadata, key) do
        [_value] when is_nil(expected) -> []
        [^expected] -> []
        nil -> ["Hex audit output is missing metadata #{key}"]
        _ -> ["Hex audit metadata #{key} is duplicated or unsupported"]
      end
    end) ++
      if(
        decoded_value(metadata, "IGNORE_ADVISORIES_VALUES") == :error or
          decoded_value(metadata, "IGNORE_RETIREMENTS_VALUES") == :error,
        do: ["Hex audit ignore metadata is malformed"],
        else: []
      )
  end

  defp ignore_metadata_from_lines(metadata, key) do
    source = metadata |> Map.get("#{key}_SOURCE", ["unavailable"]) |> List.first()
    value = metadata |> Map.get("#{key}_VALUES", [""]) |> List.first()

    %{
      source: source,
      values:
        case Base.decode64(value) do
          {:ok, decoded} -> decoded
          :error -> "unavailable"
        end
    }
  end

  defp configured_ignore?(%{source: source, values: values}),
    do: source != "default" or values != "[]"

  defp decoded_value(metadata, key) do
    case Map.get(metadata, key) do
      [value] -> Base.decode64(value)
      _ -> :error
    end
  end

  defp inventory_errors(inventory) when is_list(inventory) do
    valid_paths = Enum.filter(inventory, &is_binary/1)
    frequencies = counts(valid_paths)

    duplicate_errors =
      frequencies
      |> Enum.filter(fn {_path, count} -> count > 1 end)
      |> Enum.map(fn {path, _count} -> "duplicate inventory row: #{path}" end)

    missing_errors =
      Enum.reject(@inventory, &Map.has_key?(frequencies, &1))
      |> Enum.map(&"missing inventory row: #{&1}")

    extra_errors =
      Enum.reject(Map.keys(frequencies), &(&1 in @inventory))
      |> Enum.map(&"unexpected inventory row: #{&1}")

    invalid_errors =
      if length(valid_paths) == length(inventory),
        do: [],
        else: ["inventory contains a non-path row"]

    duplicate_errors ++ missing_errors ++ extra_errors ++ invalid_errors
  end

  defp inventory_errors(_), do: ["inventory is not a list"]

  defp tracked_lock_files(reader, root) do
    try do
      case reader.(root) do
        {:ok, files} when is_list(files) ->
          {Enum.filter(files, &(is_binary(&1) and Path.basename(&1) == "mix.lock")), []}

        {:error, reason} ->
          {[], ["could not read tracked repository files: #{redact(to_string(reason))}"]}

        other ->
          {[], ["tracked-file reader returned an invalid result: #{inspect(other)}"]}
      end
    rescue
      error ->
        {[], ["could not read tracked repository files: #{redact(Exception.message(error))}"]}
    end
  end

  defp tracked_lock_errors(tracked) do
    expected = Enum.map(@inventory, &lock_relative_path/1)
    duplicates = tracked -- Enum.uniq(tracked)
    missing = expected -- tracked
    unexpected = tracked -- expected

    Enum.map(duplicates, &"duplicate tracked Mix lock: #{&1}") ++
      Enum.map(missing, &"tracked Mix lock is missing: #{&1}") ++
      Enum.map(unexpected, &"unexpected tracked Mix lock: #{&1}")
  end

  defp lock_relative_path("."), do: "mix.lock"
  defp lock_relative_path(path), do: "#{path}/mix.lock"

  defp source_sha(runner, root) do
    case runner.("git", ["rev-parse", "HEAD"], cd: root, stderr_to_stdout: true) do
      {output, 0} ->
        sha = String.trim(output)

        if Regex.match?(~r/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/, sha),
          do: {sha, []},
          else: {nil, ["git rev-parse returned an invalid source SHA"]}

      {_output, status} ->
        {nil, ["git rev-parse HEAD exited #{status}"]}
    end
  rescue
    error -> {nil, ["git rev-parse HEAD could not run: #{redact(Exception.message(error))}"]}
  end

  defp read_tracked_files(root) do
    case System.cmd("git", ["ls-files", "-z"], cd: root, stderr_to_stdout: true) do
      {output, 0} -> {:ok, String.split(output, <<0>>, trim: true)}
      {output, status} -> {:error, "git ls-files exited #{status}: #{redact(output)}"}
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp measured(clock, fun) do
    started = clock.()

    result =
      try do
        case fun.() do
          {output, status} when is_binary(output) and is_integer(status) ->
            %{
              output: output,
              status: status,
              outcome: if(status == 0, do: :ok, else: :failed),
              errors: []
            }

          other ->
            %{
              output: "",
              status: 1,
              outcome: :unavailable,
              errors: ["command runner returned an invalid result: #{inspect(other)}"]
            }
        end
      rescue
        error ->
          %{
            output: "",
            status: 1,
            outcome: :unavailable,
            errors: ["command could not run: #{redact(Exception.message(error))}"]
          }
      end

    duration = max(clock.() - started, 0)
    {result, duration}
  end

  defp command_status_error(%{status: 0}, _command), do: []

  defp command_status_error(%{status: status, outcome: :failed}, command),
    do: ["#{command} exited #{status}"]

  defp command_status_error(_result, _command), do: []

  defp read_lock(path) do
    case File.read(path) do
      {:ok, contents} -> {:ok, contents}
      {:error, reason} -> {:error, reason}
    end
  end

  defp hash_if_readable({:ok, contents}), do: sha256(contents)
  defp hash_if_readable(_), do: nil

  defp lock_change_error(source_lock, {:ok, source_lock}, _stage), do: []

  defp lock_change_error(_source_lock, _observed, stage),
    do: ["Mix lock bytes changed or became unreadable during #{stage}"]

  defp sha256(contents), do: :crypto.hash(:sha256, contents) |> Base.encode16(case: :lower)

  defp ignore_metadata do
    [
      {:ignore_advisories, "IGNORE_ADVISORIES"},
      {:ignore_retirements, "IGNORE_RETIREMENTS"}
    ]
    |> Enum.map(fn {key, output_key} ->
      hex_state = Module.concat(["Hex", "State"])
      source = apply(hex_state, :fetch_source!, [key]) |> safe_source(key)
      value = apply(hex_state, :fetch!, [key]) |> safe_ignore_values(key)
      {output_key, source, inspect(value, limit: :infinity, printable_limit: 1_000)}
    end)
  end

  defp safe_source({:env, "HEX_IGNORE_ADVISORIES"}, :ignore_advisories),
    do: "env:HEX_IGNORE_ADVISORIES"

  defp safe_source({:env, "HEX_IGNORE_RETIREMENTS"}, :ignore_retirements),
    do: "env:HEX_IGNORE_RETIREMENTS"

  defp safe_source({:project_config, _key}, _ignore), do: "project_config"
  defp safe_source({:global_config, _key}, _ignore), do: "global_config"
  defp safe_source(:default, _ignore), do: "default"
  defp safe_source(_source, _ignore), do: "unsupported"

  defp safe_ignore_values(values, :ignore_advisories) when is_list(values) do
    if Enum.all?(
         values,
         &(is_binary(&1) and Regex.match?(~r/\A(?:CVE-\d{4}-\d+|GHSA-[A-Z0-9-]+)\z/i, &1))
       ),
       do: values,
       else: :invalid_redacted
  end

  defp safe_ignore_values(values, :ignore_retirements) when is_list(values) do
    safe = Enum.map(values, &safe_retirement/1)
    if Enum.all?(safe, &is_binary/1), do: safe, else: :invalid_redacted
  end

  defp safe_ignore_values(_value, _key), do: :invalid_redacted

  defp safe_retirement(name) when is_atom(name), do: Atom.to_string(name)

  defp safe_retirement({name, version}) when is_atom(name) and is_binary(version) do
    if Regex.match?(~r/\A[0-9A-Za-z.+_-]+\z/, version), do: "#{name}@#{version}", else: nil
  end

  defp safe_retirement(_), do: nil

  defp print_result(result) do
    IO.puts("dependency-audit status=#{result.status} graphs=#{length(result.graphs)}")
    Enum.each(result.errors, &IO.puts("dependency-audit error=#{&1}"))

    Enum.each(result.graphs, fn graph ->
      IO.puts([
        "dependency-audit graph=#{graph.path} status=#{graph.status} ",
        "source_sha=#{graph.source_sha || "unavailable"} ",
        "lock_sha_before=#{graph.lock_sha_before || "unavailable"} ",
        "lock_sha_after=#{graph.lock_sha_after || "unavailable"} ",
        "hex=#{graph.hex_version || "unavailable"} ",
        "fetch_status=#{graph.fetch.status} fetch_ms=#{graph.fetch.duration_ms || "unavailable"} ",
        "audit_status=#{graph.audit.status} audit_ms=#{graph.audit.duration_ms || "unavailable"} ",
        "ignore_advisories_source=#{graph.ignore_advisories.source} ",
        "ignore_advisories_values=#{graph.ignore_advisories.values} ",
        "ignore_retirements_source=#{graph.ignore_retirements.source} ",
        "ignore_retirements_values=#{graph.ignore_retirements.values}"
      ])

      Enum.each(graph.errors, &IO.puts("dependency-audit graph_error=#{graph.path}: #{&1}"))
      if graph.fetch_output != "", do: IO.puts(graph.fetch_output)

      audit_log =
        graph.audit_output
        |> String.split("\n")
        |> Enum.reject(&String.starts_with?(&1, @meta_prefix))
        |> Enum.join("\n")
        |> String.trim()

      if audit_log != "", do: IO.puts(audit_log)
    end)
  end

  defp redact(output) when is_binary(output) do
    System.get_env()
    |> Enum.filter(fn {name, value} ->
      value != "" and String.match?(name, ~r/(TOKEN|PASSWORD|SECRET|KEY|URL)/i)
    end)
    |> Enum.reduce(output, fn {_name, value}, acc -> String.replace(acc, value, "[REDACTED]") end)
  end

  defp strip_ansi(output), do: Regex.replace(~r/\e\[[0-?]*[ -\/]*[@-~]/, output, "")

  defp counts(values) when is_list(values), do: Enum.frequencies(values)
end
