defmodule Mix.Tasks.Verify.Core do
  @moduledoc false
  use Mix.Task
  @shortdoc "Runs the canonical core repository gate"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:core, args)
end
