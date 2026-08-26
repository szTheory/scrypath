defmodule Mix.Tasks.Verify.Package do
  use Mix.Task
  @shortdoc "Runs the canonical package and release-contract gate"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:package, args)
end
