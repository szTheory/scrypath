defmodule Mix.Tasks.Verify.Core do
  @moduledoc "Runs the canonical core-library verification capability."
  use Mix.Task
  @shortdoc "Runs the canonical core repository gate"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:core, args)
end
