defmodule Mix.Tasks.Verify.DeepQuality do
  use Mix.Task
  @shortdoc "Runs canonical deep-quality verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:deep_quality, args)
end
