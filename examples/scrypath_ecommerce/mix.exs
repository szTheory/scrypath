defmodule ScrypathEcommerce.MixProject do
  use Mix.Project

  def project do
    [
      app: :scrypath_ecommerce,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  def application do
    [
      mod: {ScrypathEcommerce.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [
        precommit: :test,
        setup: :dev,
        "assets.setup": :dev,
        "assets.build": :dev
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:scrypath, path: "../.."},
      {:scrypath_ops, path: "../../scrypath_ops"},
      {:phoenix, "~> 1.8.9"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.22.4"},
      {:oban, "~> 2.21"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.33"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3", only: :dev},
      {:esbuild, "~> 0.10", only: :dev, runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", only: :dev, runtime: Mix.env() == :dev},
      {:heroicons, "~> 0.5.7", app: false},
      {:req, "~> 0.6.1 or ~> 0.7"},
      {:telemetry_metrics, "~> 1.0", only: :dev},
      {:telemetry_poller, "~> 1.0", only: :dev},
      {:jason, "~> 1.2"},
      {:bandit, "~> 1.13"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind scrypath_ecommerce", "esbuild scrypath_ecommerce"],
      "e2e.prepare": ["ecto.create --quiet", "ecto.migrate --quiet", "e2e.prepare_search"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
