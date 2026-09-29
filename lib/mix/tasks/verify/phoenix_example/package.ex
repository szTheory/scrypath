defmodule Mix.Tasks.Verify.PhoenixExample.Package do
  @moduledoc false

  @example "examples/phoenix_meilisearch"
  @staged_files ["mix.exs", "mix.lock", "config", "lib", "priv", "test"]

  def run(opts \\ []) do
    Process.delete({__MODULE__, :failed})

    service_check =
      Keyword.get(opts, :service_check, &Mix.Tasks.Verify.Adopter.ensure_live_prerequisites!/0)

    command_runner = Keyword.get(opts, :command_runner, &System.cmd/3)
    keep_on_failure? = Keyword.get(opts, :keep_temp_on_failure, false)

    Mix.shell().info("==> package proof: service preflight")
    call_stage!(:service, fn -> service_check.() end)
    Mix.shell().info("PASS package proof: service preflight")

    root = unique_root!()
    failed? = Process.get({__MODULE__, :failed}, false)

    try do
      execute!(root, command_runner)
    rescue
      error in Mix.Error ->
        Process.put({__MODULE__, :failed}, true)
        reraise error, __STACKTRACE__

      error ->
        Process.put({__MODULE__, :failed}, true)

        Mix.raise(
          "package Phoenix proof failed during setup stage: #{redact(Exception.message(error))}"
        )
    after
      failed? = Process.get({__MODULE__, :failed}, failed?)

      if keep_on_failure? and failed? do
        Mix.shell().info("Retained failed package proof workspace: #{root}")
      else
        remove_owned_root!(root)
      end

      Process.delete({__MODULE__, :failed})
    end
  end

  defp execute!(root, runner) do
    artifact = Path.join(root, "artifact")
    consumer = Path.join(root, "consumer")
    hex_home = Path.join(root, "HEX_HOME")
    mix_home = Path.join(root, "MIX_HOME")
    Enum.each([artifact, consumer, hex_home, mix_home], &File.mkdir_p!/1)
    version = Mix.Project.config()[:version]
    tag = "v#{version}"
    source_lock_path = Path.expand(Path.join([@example, "mix.lock"]), File.cwd!())
    source_lock = read_lock!(source_lock_path, :setup)
    source_identity = graph_identity!(source_lock, :setup)

    source_sha =
      runner
      |> invoke!(:source, "git", ["rev-parse", "HEAD"], cd: File.cwd!())
      |> String.trim()

    unless Regex.match?(~r/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/, source_sha),
      do: fail!(:source, "git rev-parse did not return a valid source checkout SHA")

    Mix.shell().info("==> package proof: building artifact")

    invoke!(runner, :artifact, "mix", ["hex.build", "--unpack", "--output", artifact],
      cd: File.cwd!()
    )

    invoke!(runner, :artifact, "git", ["init", "-q"], cd: artifact)

    invoke!(runner, :artifact, "git", ["config", "user.email", "scrypath-proof@example.invalid"],
      cd: artifact
    )

    invoke!(runner, :artifact, "git", ["config", "user.name", "Scrypath package proof"],
      cd: artifact
    )

    invoke!(runner, :artifact, "git", ["add", "."], cd: artifact)
    invoke!(runner, :artifact, "git", ["commit", "-qm", "package artifact"], cd: artifact)
    invoke!(runner, :artifact, "git", ["tag", tag], cd: artifact)

    artifact_commit =
      runner
      |> invoke!(:artifact, "git", ["rev-parse", "HEAD"], cd: artifact)
      |> String.trim()

    unless Regex.match?(~r/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/, artifact_commit),
      do: fail!(:artifact, "local package artifact returned an invalid commit SHA")

    Mix.shell().info(
      "PASS package proof: artifact tag=#{tag} artifact_commit_sha=#{artifact_commit}"
    )

    stage_example!(consumer)
    artifact_url = "file://#{Path.expand(artifact)}"
    replace_dependency!(consumer, artifact_url, tag)
    manifest = File.read!(Path.join(consumer, "mix.exs"))

    if Regex.match?(~r/scrypath[^\n]*path\s*:/, manifest),
      do: fail!(:dependency, "staged manifest still has a Scrypath path dependency")

    isolated = [{"HEX_HOME", hex_home}, {"MIX_HOME", mix_home}]
    Mix.shell().info("==> package proof: resolving staged dependencies")
    invoke!(runner, :dependency, "mix", ["deps.get"], cd: consumer, env: isolated)
    lock = read_lock!(Path.join(consumer, "mix.lock"), :dependency)
    resolved_identity = graph_identity!(lock, :dependency)

    report_graph_identity!("package", source_sha, source_identity, resolved_identity)

    try do
      Mix.Tasks.Verify.PhoenixExample.LockGraph.assert_package!(
        source_lock,
        lock,
        artifact_url,
        tag,
        artifact_commit
      )
    rescue
      error in [ArgumentError] -> fail!(:dependency, error.message)
    end

    Mix.shell().info(
      "PASS package proof: staged dependencies resolve to #{artifact_url} at #{tag}"
    )

    Mix.shell().info("==> package proof: compiling consumer")

    invoke!(runner, :compile, "mix", ["compile"],
      cd: consumer,
      env: isolated ++ [{"MIX_ENV", "test"}]
    )

    Mix.shell().info("PASS package proof: consumer compiled")

    Mix.shell().info("==> package proof: running integration scenarios")

    invoke!(runner, :test, "mix", ["test"],
      cd: consumer,
      env: isolated ++ [{"MIX_ENV", "test"}, {"SCRYPATH_EXAMPLE_INTEGRATION", "1"}]
    )

    Mix.shell().info("PASS package proof: integration scenarios completed")
    :ok
  end

  @doc false
  def lock_resolves_to_artifact?(lock, expected_url, expected_tag, expected_revision) do
    case Mix.Tasks.Verify.PhoenixExample.LockGraph.parse!(lock)["scrypath"] do
      {:git, ^expected_url, ^expected_revision, options} when is_list(options) ->
        Enum.any?(options, &match?({:tag, ^expected_tag}, &1))

      _ ->
        false
    end
  rescue
    ArgumentError -> false
  end

  defp read_lock!(path, stage) do
    File.read!(path)
  rescue
    error -> fail!(stage, "could not read the Phoenix lockfile (#{Exception.message(error)})")
  end

  defp graph_identity!(lock, stage) do
    Mix.Tasks.Verify.PhoenixExample.LockGraph.identity!(lock)
  rescue
    error in [ArgumentError] -> fail!(stage, error.message)
  end

  defp report_graph_identity!(mode, source_sha, source_identity, resolved_identity) do
    Mix.shell().info(
      "Phoenix example proof source_sha=#{source_sha} mode=#{mode} " <>
        "source_lock_sha256=#{source_identity.sha256} resolved_lock_sha256=#{resolved_identity.sha256}"
    )

    packages =
      Enum.map_join(resolved_identity.packages, ", ", fn {name, version} ->
        "#{name}@#{version}"
      end)

    Mix.shell().info("Phoenix example proof packages=#{packages}")
  end

  defp stage_example!(consumer) do
    source = Path.expand(@example, File.cwd!())
    unless File.dir?(source), do: fail!(:setup, "Phoenix example directory is missing")

    Enum.each(@staged_files, fn name ->
      from = Path.join(source, name)
      to = Path.join(consumer, name)
      if File.dir?(from), do: File.cp_r!(from, to), else: File.cp!(from, to)
    end)
  end

  defp replace_dependency!(consumer, url, tag) do
    path = Path.join(consumer, "mix.exs")
    source = File.read!(path)

    updated =
      String.replace(
        source,
        "{:scrypath, path: \"../..\"}",
        "{:scrypath, git: \"#{url}\", tag: \"#{tag}\"}"
      )

    if updated == source,
      do: fail!(:setup, "could not locate the example Scrypath path dependency")

    File.write!(path, updated)
  end

  defp invoke!(runner, stage, command, args, opts) do
    Mix.shell().info("==> package proof [#{stage}]: #{command} #{Enum.join(args, " ")}")
    {output, status} = runner.(command, args, Keyword.merge([stderr_to_stdout: true], opts))
    safe_output = redact(output)
    if safe_output != "", do: Mix.shell().info(safe_output)
    if status != 0, do: fail!(stage, "#{command} #{Enum.join(args, " ")} exited #{status}")
    output
  rescue
    error in Mix.Error ->
      reraise(error, __STACKTRACE__)

    error ->
      fail!(
        stage,
        "#{command} #{Enum.join(args, " ")} could not run (#{Exception.message(error)})"
      )
  end

  defp call_stage!(stage, fun) do
    fun.()
  rescue
    error ->
      Mix.raise(
        "package Phoenix proof failed during #{stage} stage: #{redact(Exception.message(error))}"
      )
  end

  defp redact(output) do
    System.get_env()
    |> Enum.filter(fn {name, value} ->
      value != "" and
        (String.match?(name, ~r/(TOKEN|PASSWORD|SECRET|KEY|URL)/i) or
           name in ["SCRYPATH_MEILISEARCH_URL"])
    end)
    |> Enum.reduce(output, fn {_name, value}, acc -> String.replace(acc, value, "[REDACTED]") end)
  end

  defp unique_root! do
    root =
      Path.join(
        System.tmp_dir!(),
        "scrypath-phoenix-package-#{System.unique_integer([:positive, :monotonic])}"
      )

    case File.mkdir(root) do
      :ok ->
        root

      {:error, :eexist} ->
        unique_root!()

      {:error, reason} ->
        Mix.raise(
          "package Phoenix proof failed during setup stage: cannot create temporary workspace (#{:file.format_error(reason)})"
        )
    end
  end

  defp remove_owned_root!(root) do
    tmp = Path.expand(System.tmp_dir!())
    expanded = Path.expand(root)
    basename = Path.basename(expanded)

    with true <- Path.dirname(expanded) == tmp,
         true <- Regex.match?(~r/^scrypath-phoenix-package-[0-9]+$/, basename),
         {:ok, %{type: :directory}} <- File.lstat(expanded) do
      File.rm_rf!(expanded)
    else
      _ -> :ok
    end
  end

  @spec fail!(atom(), String.t()) :: no_return()
  defp fail!(stage, message) do
    Process.put({__MODULE__, :failed}, true)
    Mix.raise("package Phoenix proof failed during #{stage} stage: #{message}")
  end
end
