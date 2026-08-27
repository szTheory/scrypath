defmodule Mix.Tasks.Verify.EcommerceE2e do
  @moduledoc "Runs the canonical full ecommerce browser capability."
  use Mix.Task
  @shortdoc "Runs canonical full ecommerce E2E verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:ecommerce_e2e, args)
end
