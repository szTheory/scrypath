# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :scrypath_demo,
  ecto_repos: [ScrypathDemo.Repo],
  generators: [timestamp_type: :utc_datetime]

config :scrypath_demo, Oban,
  repo: ScrypathDemo.Repo,
  queues: [scrypath: 10],
  plugins: [{Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7}]

# Configure the endpoint
config :scrypath_demo, ScrypathDemoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ScrypathDemoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ScrypathDemo.PubSub,
  live_view: [signing_salt: "CwpW97Jb"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
