defmodule Mix.Tasks.Verify.Compatibility do
  use Mix.Task
  @shortdoc "Runs canonical compatibility-contract verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:compatibility, args)
end
