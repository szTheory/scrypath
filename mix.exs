defmodule Scrypath.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/jon/scrypath"

  def project do
    [
      app: :scrypath,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: "Ecto-native search indexing and orchestration for Elixir apps",
      dialyzer: [
        plt_add_apps: [:mix],
        plt_file: {:no_warn, "priv/plts/scrypath.plt"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [
        "verify.phase5": :test,
        credo: :test,
        dialyzer: :test
      ]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.13"},
      {:nimble_options, "~> 1.1"},
      {:oban, "~> 2.21", optional: true},
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.18", only: :test},
      {:ecto_sqlite3, "~> 0.22", only: :test, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.37", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "ARCHITECTURE.md",
        "guides/getting-started.md",
        "guides/phoenix-walkthrough.md",
        "guides/phoenix-contexts.md",
        "guides/phoenix-controllers-and-json.md",
        "guides/phoenix-liveview.md",
        "guides/sync-modes-and-visibility.md"
      ],
      groups_for_extras: [
        "Getting Started": ["README.md", "guides/getting-started.md"],
        "Phoenix": [
          "guides/phoenix-walkthrough.md",
          "guides/phoenix-contexts.md",
          "guides/phoenix-controllers-and-json.md",
          "guides/phoenix-liveview.md"
        ],
        "Operations": ["ARCHITECTURE.md", "guides/sync-modes-and-visibility.md"]
      ]
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => "https://hexdocs.pm/scrypath"
      }
    ]
  end
end
