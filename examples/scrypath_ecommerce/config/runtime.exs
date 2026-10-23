import Config

# Evaluated at boot (after compile), so it sees the real runtime environment, which
# differs between the `mix e2e.prepare` / `mix test` process and the `mix phx.server`
# process.
#
# The phase105 browser-e2e lane boots the server with
#   MIX_ENV=test PHX_SERVER=true SCRYPATH_E2E_NO_SANDBOX=1 mix phx.server
# and needs a persistent, NON-sandbox database so the real
#   create_product -> Scrypath.sync_record (:oban) -> drain -> active index
# path works end-to-end across the separate HTTP requests Playwright makes.
#
# `mix test` and `mix e2e.prepare` run WITHOUT SCRYPATH_E2E_NO_SANDBOX, so they keep the
# Ecto SQL Sandbox pool and the sandbox plug from config/test.exs unchanged.
if config_env() == :test and System.get_env("SCRYPATH_E2E_NO_SANDBOX") == "1" do
  config :scrypath_ecommerce, ScrypathEcommerce.Repo,
    pool: DBConnection.ConnectionPool,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :scrypath_ecommerce, sandbox: false
end
