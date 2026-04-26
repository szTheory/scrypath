if Code.ensure_loaded?(Sigra.Session) do
  defmodule ScrypathOps.Integrations.Sigra.OnMount do
    @moduledoc false

    import Phoenix.Component, only: [assign: 3]

    alias ScrypathOps.Integrations.Sigra.OperatorContext

    def on_mount(:default, _params, _session, socket) do
      {:cont, assign(socket, :operator_context, OperatorContext.from_socket(socket))}
    end
  end
else
  defmodule ScrypathOps.Integrations.Sigra.OnMount do
    @moduledoc false

    import Phoenix.Component, only: [assign: 3]

    def on_mount(:default, _params, _session, socket) do
      {:cont, assign(socket, :operator_context, nil)}
    end
  end
end
