import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :scrypath_ops, ScrypathOps.Repo,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost"),
  port: String.to_integer(System.get_env("PGPORT", "5432")),
  database:
    System.get_env("SCRYPATH_OPS_TEST_DATABASE") ||
      "scrypath_ops_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :scrypath_ops, ScrypathOpsWeb.Endpoint,
  http: [
    ip: if(System.get_env("PHX_SERVER") == "true", do: {0, 0, 0, 0}, else: {127, 0, 0, 1}),
    port: String.to_integer(System.get_env("SCRYPATH_OPS_PORT") || "4002")
  ],
  secret_key_base: "udY/UcSfO841tewbYep/lb0mGkfNHX6T/WlSadeZNbpfnI1/xfrNHxvvBbaackJB",
  check_origin: System.get_env("PHX_SERVER") != "true",
  server: System.get_env("PHX_SERVER") == "true"

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :scrypath_ops, :validate_opsui_auth_on_start, false
config :scrypath_ops, standalone: true
config :scrypath_ops, :phase173_fixture_source, ScrypathOps.Phase173FixtureSource
config :scrypath_ops, :saved_search_doc_base, "https://github.com/szTheory/scrypath/blob/main/"
