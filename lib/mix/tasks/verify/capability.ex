defmodule Mix.Tasks.Verify.Capability do
  @moduledoc false

  @spec run(atom(), [String.t()]) :: :ok
  def run(:core, args), do: run_task!("verify", args)

  def run(:package, args),
    do: no_args!(:package, args, &Mix.Tasks.Verify.Phase11.run_without_docs/0)

  def run(:repository_contracts, args),
    do: no_args!(:repository_contracts, args, &Mix.Tasks.Verify.Phase99.run_without_docs/0)

  def run(:backend, args), do: backend!(args)
  def run(:compatibility, args), do: compatibility!(args)
  def run(:deep_quality, args), do: deep_quality!(args)

  def run(:ecommerce_mounted, args),
    do:
      command!(:ecommerce_mounted, args, "make", [
        "-C",
        "examples/scrypath_ecommerce",
        "verify-mounted"
      ])

  def run(:phoenix_example, args), do: phoenix_example!(args)

  def run(:ecommerce_e2e, args),
    do:
      command!(:ecommerce_e2e, args, "make", ["-C", "examples/scrypath_ecommerce", "verify-e2e"])

  @doc false
  @spec run_deep_quality_without_audit() :: :ok
  @spec run_deep_quality_without_audit(keyword()) :: :ok
  def run_deep_quality_without_audit(opts \\ []),
    do: run_deep_quality_sequence(false, opts)

  @doc false
  @spec run_deep_quality_with_audit() :: :ok
  @spec run_deep_quality_with_audit(keyword()) :: :ok
  def run_deep_quality_with_audit(opts \\ []),
    do: run_deep_quality_sequence(true, opts)

  defp no_args!(_capability, [], callback), do: callback.()

  defp no_args!(capability, args, _task) do
    Mix.raise("verify.#{capability} does not accept arguments, got: #{Enum.join(args, " ")}")
  end

  defp backend!(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: [skip_integration: :boolean])

    if argv != [] or invalid != [] do
      Mix.raise("verify.backend accepts only --skip-integration")
    end

    run_task!(
      "verify.meilisearch_smoke",
      if(opts[:skip_integration], do: ["--skip-integration"], else: [])
    )
  end

  defp phoenix_example!([]), do: run_task!("verify.adopter", ["--live"])

  defp phoenix_example!(args) do
    {opts, argv, invalid} =
      OptionParser.parse(args, strict: [package: :boolean, keep_temp_on_failure: :boolean])

    if argv != [] or invalid != [] or opts[:package] != true do
      Mix.raise(
        "verify.phoenix_example does not accept arguments other than --package [--keep-temp-on-failure]"
      )
    end

    Mix.Tasks.Verify.PhoenixExample.Package.run(
      keep_temp_on_failure: opts[:keep_temp_on_failure] || false
    )
  end

  defp deep_quality!([]) do
    run_deep_quality_with_audit()
  end

  defp deep_quality!(args) do
    Mix.raise("verify.deep_quality does not accept arguments, got: #{Enum.join(args, " ")}")
  end

  defp run_deep_quality_sequence(include_audit?, opts) do
    task_runner = Keyword.get(opts, :task_runner, &run_deep_quality_task!/2)
    command_runner = Keyword.get(opts, :command_runner, &run_mix_command!/2)

    task_runner.("verify.no_optional_deps", [])
    task_runner.("scrypath.namespace_fence", [])
    if include_audit?, do: command_runner.("hex.audit", [])
    command_runner.("dialyzer", [])
    :ok
  end

  defp run_deep_quality_task!("scrypath.namespace_fence", []) do
    Mix.Task.run("scrypath.namespace_fence")
    :ok
  end

  defp run_deep_quality_task!(task, args), do: run_task!(task, args)

  defp compatibility!([]) do
    run_task!("compile", ["--warnings-as-errors"])

    run_task!("test", [
      "--warnings-as-errors",
      "--exclude",
      "integration",
      "--exclude",
      "docs_contract",
      "--include",
      "requires_clean_workspace"
    ])
  end

  defp compatibility!(args) do
    Mix.raise("verify.compatibility does not accept arguments, got: #{Enum.join(args, " ")}")
  end

  defp command!(capability, [], command, args) do
    {output, status} = System.cmd(command, args, stderr_to_stdout: true)
    Mix.shell().info(output)

    if status != 0 do
      Mix.raise("verify.#{capability} failed: #{command} #{Enum.join(args, " ")}")
    end

    :ok
  end

  defp command!(capability, supplied, _command, _args) do
    Mix.raise("verify.#{capability} does not accept arguments, got: #{Enum.join(supplied, " ")}")
  end

  defp run_task!(task, args) do
    Mix.shell().info("==> verify capability delegates to mix #{task}")
    Mix.Task.reenable(task)
    Mix.Task.run(task, args)
    :ok
  end

  defp run_mix_command!(task, args) do
    mix = System.find_executable("mix") || Mix.raise("could not find the mix executable")

    {output, status} =
      System.cmd(mix, [task | args],
        env: [{"MIX_ENV", Atom.to_string(Mix.env())}],
        stderr_to_stdout: true
      )

    Mix.shell().info(output)

    if status != 0 do
      Mix.raise("mix #{task} failed")
    end
  end
end
