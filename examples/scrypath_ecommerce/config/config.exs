# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :scrypath_ecommerce,
  ecto_repos: [ScrypathEcommerce.Repo],
  generators: [timestamp_type: :utc_datetime]

config :scrypath, :defaults,
  backend: Scrypath.Meilisearch,
  meilisearch_url: System.get_env("SCRYPATH_MEILISEARCH_URL") || "http://localhost:7700",
  index_prefix: "ecommerce_",
  sync_mode: :oban,
  oban: Oban,
  oban_queue: :scrypath_sync

config :scrypath_ops,
  schema_allowlist: [ScrypathEcommerce.Catalog.Product, ScrypathEcommerce.Catalog.Variant],
  backend: Scrypath.Meilisearch,
  meilisearch_url: System.get_env("SCRYPATH_MEILISEARCH_URL") || "http://localhost:7700",
  index_prefix: "ecommerce_",
  sync_mode: :oban,
  oban: Oban,
  oban_queue: :scrypath_sync,
  oban_inspector: ScrypathEcommerceWeb.E2EObanInspector

config :scrypath_ecommerce, Oban,
  repo: ScrypathEcommerce.Repo,
  # A long prune window keeps the demo's deliberately-seeded failed sync work
  # (mix scrypath.demo.seed) visible on the Failed Sync page instead of vanishing
  # after the default 60s. Real failures still age out within the week.
  plugins: [{Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7}],
  queues: [default: 10, scrypath_sync: 5]

# Configure the endpoint
config :scrypath_ecommerce, ScrypathEcommerceWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ScrypathEcommerceWeb.ErrorHTML, json: ScrypathEcommerceWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ScrypathEcommerce.PubSub,
  live_view: [signing_salt: "8QlRSM/3"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  scrypath_ecommerce: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  scrypath_ecommerce: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
config :swoosh, :api_client, false
