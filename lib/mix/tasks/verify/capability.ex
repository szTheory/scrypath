defmodule Mix.Tasks.Verify.Capability do
  @moduledoc false

  @spec run(atom(), [String.t()]) :: :ok
  def run(capability, args) do
    case capability do
      :core ->
        run_task!("verify", args)

      :package ->
        no_args!(capability, args, &Mix.Tasks.Verify.Phase11.run_without_docs/0)

      :repository_contracts ->
        no_args!(capability, args, &Mix.Tasks.Verify.Phase99.run_without_docs/0)

      :backend ->
        backend!(args)

      :compatibility ->
        compatibility!(args)

      :deep_quality ->
        deep_quality!(args)

      :ecommerce_mounted ->
        command!(capability, args, "make", ["-C", "examples/scrypath_ecommerce", "verify-mounted"])

      :phoenix_example ->
        phoenix_example!(args)

      :ops_ui ->
        no_args!(capability, args, fn -> run_task!("verify.opsui", []) end)

      :ecommerce_e2e ->
        command!(capability, args, "make", ["-C", "examples/scrypath_ecommerce", "verify-e2e"])
    end
  end

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
    Mix.raise("verify.phoenix_example does not accept arguments, got: #{Enum.join(args, " ")}")
  end

  defp deep_quality!([]) do
    run_task!("verify.no_optional_deps", [])
    Mix.Task.run("scrypath.namespace_fence")
    Mix.Task.run("hex.audit")
    Mix.Task.run("dialyzer")
    :ok
  end

  defp deep_quality!(args) do
    Mix.raise("verify.deep_quality does not accept arguments, got: #{Enum.join(args, " ")}")
  end

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
end
