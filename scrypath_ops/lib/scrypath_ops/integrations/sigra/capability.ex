defmodule ScrypathOps.Integrations.Sigra do
  @moduledoc false

  def available? do
    Code.ensure_loaded?(Sigra.Session) and
      Code.ensure_loaded?(Sigra.Audit) and
      function_exported?(Sigra.Audit, :log_safe, 3) and
      Code.ensure_loaded?(ScrypathOps.Integrations.Sigra.OnMount) and
      function_exported?(ScrypathOps.Integrations.Sigra.OnMount, :on_mount, 4) and
      Code.ensure_loaded?(ScrypathOps.Integrations.Sigra.OperatorContext) and
      function_exported?(ScrypathOps.Integrations.Sigra.OperatorContext, :from_socket, 1)
  end

  def unavailable_message do
    "OPSUI_AUTH_MODE=sigra requires the Sigra integration (Sigra.Session and " <>
      "Sigra.Audit.log_safe/3) to be available. Add the optional Sigra dependency and " <>
      "recompile scrypath_ops. See scrypath_ops/README.md and " <>
      "guides/support-and-compatibility.md."
  end
end
