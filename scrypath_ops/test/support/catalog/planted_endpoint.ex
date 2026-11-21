defmodule ScrypathOps.Catalog.PlantedEndpoint do
  @moduledoc false

  # Test-only endpoint for the planted failing storybook. It binds no port (server: false in
  # config/test.exs) and nothing in lib references it.
  use Phoenix.Endpoint, otp_app: :scrypath_ops

  @session_options [
    store: :cookie,
    key: "_planted_key",
    signing_salt: "plantedsession",
    same_site: "Lax"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(Plug.Static, at: "/", from: :scrypath_ops, only: ~w(assets))

  # Without a parser the router never reads the query string, so variation_id and theme would be
  # silently dropped and every plant would render the first variation with no theme.
  plug(Plug.Parsers, parsers: [:urlencoded], pass: ["*/*"])
  plug(Plug.Session, @session_options)
  plug(ScrypathOps.Catalog.PlantedRouter)
end
