defmodule Scrypath.MixProject do
  use Mix.Project

  @version "0.3.3"
  @source_url "https://github.com/szTheory/scrypath"
  @source_ref "v#{@version}"
  @hexdocs_url "https://hexdocs.pm/scrypath"
  @release_docs_url "#{@hexdocs_url}/#{@version}"

  def project do
    [
      app: :scrypath,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      homepage_url: @source_url,
      source_url: @source_url,
      source_ref: @source_ref,
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
        "verify.phase8": :test,
        "verify.phase10": :test,
        "verify.phase11": :test,
        "verify.phase13": :test,
        "verify.phase14": :test,
        "verify.phase20": :test,
        "verify.phase22": :test,
        "verify.phase26": :test,
        "verify.phase28": :test,
        "verify.phase36": :test,
        "verify.phase37": :test,
        "verify.meilisearch_smoke": :test,
        "verify.release_publish": :test,
        "verify.workspace_clean": :test,
        "verify.release_parity": :test,
        "scrypath.index.contract_drift": :test,
        "scrypath.settings.diff": :test,
        "scrypath.settings.read": :test,
        "scrypath.settings.hot_apply": :test,
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
      source_ref: @source_ref,
      extras: [
        "README.md",
        "ARCHITECTURE.md",
        "guides/drift-recovery.md",
        "guides/getting-started.md",
        "guides/golden-path.md",
        "guides/phoenix-walkthrough.md",
        "guides/phoenix-contexts.md",
        "guides/phoenix-controllers-and-json.md",
        "guides/phoenix-liveview.md",
        "guides/faceted-search-with-phoenix-liveview.md",
        "guides/multi-index-search.md",
        "guides/sync-modes-and-visibility.md",
        "guides/operator-mix-tasks.md",
        "guides/relevance-tuning.md",
        "docs/releasing.md",
        "docs/operator-support.md",
        "docs/search-backend-sre.md"
      ],
      groups_for_extras: [
        "Getting Started": ["README.md", "guides/getting-started.md", "guides/golden-path.md"],
        Phoenix: [
          "guides/phoenix-walkthrough.md",
          "guides/phoenix-contexts.md",
          "guides/phoenix-controllers-and-json.md",
          "guides/phoenix-liveview.md",
          "guides/faceted-search-with-phoenix-liveview.md",
          "guides/multi-index-search.md"
        ],
        Operations: [
          "ARCHITECTURE.md",
          "guides/drift-recovery.md",
          "guides/operator-mix-tasks.md",
          "guides/relevance-tuning.md",
          "guides/sync-modes-and-visibility.md"
        ],
        Maintainers: [
          "docs/releasing.md",
          "docs/operator-support.md",
          "docs/search-backend-sre.md"
        ]
      ]
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      files: ~w(lib .formatter.exs mix.exs README.md ARCHITECTURE.md CHANGELOG.md guides docs),
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => @release_docs_url,
        "Changelog" => "#{@source_url}/blob/#{@source_ref}/CHANGELOG.md",
        "Guides" => "#{@release_docs_url}/readme.html"
      }
    ]
  end
end
