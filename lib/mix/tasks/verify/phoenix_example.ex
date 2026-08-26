defmodule Mix.Tasks.Verify.PhoenixExample do
  @moduledoc false
  use Mix.Task
  @shortdoc "Runs canonical live Phoenix example verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:phoenix_example, args)
end
