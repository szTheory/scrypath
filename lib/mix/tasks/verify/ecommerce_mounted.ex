defmodule Mix.Tasks.Verify.EcommerceMounted do
  @moduledoc false
  use Mix.Task
  @shortdoc "Runs canonical mounted ecommerce verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:ecommerce_mounted, args)
end
