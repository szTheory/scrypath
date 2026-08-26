defmodule Mix.Tasks.Verify.DeepQuality do
  @moduledoc "Runs the canonical advisory static-analysis capability."
  use Mix.Task
  @shortdoc "Runs canonical deep-quality verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:deep_quality, args)
end
