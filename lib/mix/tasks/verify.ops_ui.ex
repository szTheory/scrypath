defmodule Mix.Tasks.Verify.OpsUi do
  use Mix.Task

  @shortdoc "Runs canonical ScrypathOps verification"

  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:ops_ui, args)
end
