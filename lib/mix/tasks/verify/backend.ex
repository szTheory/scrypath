defmodule Mix.Tasks.Verify.Backend do
  use Mix.Task
  @shortdoc "Runs canonical Meilisearch backend verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:backend, args)
end
