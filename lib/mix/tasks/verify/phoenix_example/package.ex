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
    Mix.shell().info("PASS package proof: artifact created and tagged #{tag}")

    stage_example!(consumer)
    artifact_url = "file://#{Path.expand(artifact)}"
    replace_dependency!(consumer, artifact_url, tag)
    manifest = File.read!(Path.join(consumer, "mix.exs"))

    if Regex.match?(~r/scrypath[^\n]*path\s*:/, manifest),
      do: fail!(:dependency, "staged manifest still has a Scrypath path dependency")

    isolated = [{"HEX_HOME", hex_home}, {"MIX_HOME", mix_home}]
    Mix.shell().info("==> package proof: resolving staged dependencies")
    invoke!(runner, :dependency, "mix", ["deps.get"], cd: consumer, env: isolated)
    lock = File.read!(Path.join(consumer, "mix.lock"))

    unless lock_resolves_to_artifact?(lock, artifact_url, tag),
      do:
        fail!(
          :dependency,
          "staged lock does not resolve Scrypath from the tagged local artifact"
        )

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
  def lock_resolves_to_artifact?(lock, expected_url, expected_tag) do
    with {:ok, {:%{}, _meta, entries}} <- Code.string_to_quoted(lock),
         {:{}, _tuple_meta, [:git, ^expected_url, _revision, options | _rest]} <-
           Enum.find_value(entries, fn
             {"scrypath", value} -> value
             {:scrypath, value} -> value
             _ -> nil
           end),
         true <- Enum.any?(options, &match?({:tag, ^expected_tag}, &1)) do
      true
    else
      _ -> false
    end
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
    :ok
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

  defp fail!(stage, message) do
    Process.put({__MODULE__, :failed}, true)
    Mix.raise("package Phoenix proof failed during #{stage} stage: #{message}")
  end
end
