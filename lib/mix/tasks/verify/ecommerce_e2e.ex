defmodule Mix.Tasks.Verify.EcommerceE2e do
  use Mix.Task
  @shortdoc "Runs canonical full ecommerce E2E verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:ecommerce_e2e, args)
end
