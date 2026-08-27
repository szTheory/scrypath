defmodule Mix.Tasks.Verify.EcommerceMounted do
  @moduledoc "Runs the canonical mounted ecommerce capability."
  use Mix.Task
  @shortdoc "Runs canonical mounted ecommerce verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:ecommerce_mounted, args)
end
