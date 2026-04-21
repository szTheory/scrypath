defmodule ScrypathOpsWeb.Live.OnMount do
  @moduledoc """
  Shared `on_mount` hooks for the `/ops` `live_session`.

  Stubs today; later phases attach auth, assigns, and halting here so HTTP and
  WebSocket boundaries stay aligned (see phase 44 CONTEXT D-11–D-12).
  """
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    {:cont, assign(socket, :shell, :ops)}
  end
end
