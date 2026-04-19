import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :scrypath_demo, ScrypathDemo.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: String.to_integer(System.get_env("PGPORT") || "5433"),
  database: "scrypath_demo_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :scrypath_demo, ScrypathDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "bfYMUB3+taKKhOBACqZrBHHM+R204M3aOQ/bAvh0FC7T3DAvXOD2N5riBhXCUvlP",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Run Oban jobs in-process so integration tests can assert enqueue + worker + Meilisearch
# without a separate poller (see `test/smoke/meilisearch_oban_stack_test.exs`).
config :scrypath_demo, Oban, testing: :inline
