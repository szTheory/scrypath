defmodule Mix.Tasks.Verify.RepositoryContracts do
  @moduledoc "Runs the canonical repository-contract capability."
  use Mix.Task
  @shortdoc "Runs canonical repository-contract verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:repository_contracts, args)
end
