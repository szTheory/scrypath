import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :scrypath_ecommerce, ScrypathEcommerce.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "scrypath_ecommerce_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :scrypath_ecommerce, sandbox: true

config :scrypath_ecommerce, Oban, testing: :manual

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :scrypath_ecommerce, ScrypathEcommerceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Ls0BVRFJGZispLpoVX0t5uvto4v4vcEHU+n8hYDhpW2XCxwTA4VOqOM3vg5pP3he",
  server: false

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
