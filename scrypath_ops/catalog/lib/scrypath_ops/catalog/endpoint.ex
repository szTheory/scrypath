defmodule ScrypathOps.Catalog.Endpoint do
  @moduledoc false

  # The review server for the component catalog (`mix scrypath_ops.catalog.serve`): a small
  # endpoint with no Repo, no code reloader and no watchers, so it answers the same way whether or
  # not a database is running. It exists only in dev and test (`catalog/lib`), binds loopback in
  # `config/dev.exs`, and serves nothing but the storybook and its static files.
  use Phoenix.Endpoint, otp_app: :scrypath_ops

  @session_options [
    store: :cookie,
    key: "_scrypath_catalog_key",
    signing_salt: "catalogsession",
    same_site: "Lax"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(Plug.Static, at: "/", from: :scrypath_ops, only: ScrypathOpsWeb.static_paths())

  plug(Plug.RequestId)

  # Without a parser the router never reads the query string, so variation_id and theme would be
  # silently dropped (the same reason the planted test endpoint has one).
  plug(Plug.Parsers, parsers: [:urlencoded], pass: ["*/*"])
  plug(Plug.Session, @session_options)
  plug(ScrypathOps.Catalog.Router)
end
