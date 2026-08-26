defmodule Mix.Tasks.Verify.PhoenixExample do
  @moduledoc "Runs the canonical live Phoenix example capability."
  use Mix.Task
  @shortdoc "Runs canonical live Phoenix example verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:phoenix_example, args)
end
