defmodule Scrypath.MixProject do
  use Mix.Project

  @version "0.3.6"
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
      aliases: aliases(),
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
        "verify.phase38": :test,
        "verify.phase41": :test,
        "verify.phase43": :test,
        "verify.phase82": :test,
        "verify.phase83": :test,
        "verify.phase84": :test,
        "verify.phase85": :test,
        "verify.adopter": :test,
        "verify.opsui": :test,
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
      {:stream_data, "~> 1.3", only: :test},
      {:ecto_sqlite3, "~> 0.22", only: :test, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.37", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      test: &test_alias/1
    ]
  end

  defp test_alias(args) do
    case maybe_delegate_opsui_test(args) do
      :handled -> :ok
      :passthrough -> Mix.Tasks.Test.run(args)
    end
  end

  defp maybe_delegate_opsui_test(args) when is_list(args) do
    paths = Enum.filter(args, &test_path_arg?/1)
    passthrough_args = Enum.reject(args, &test_path_arg?/1)

    if paths != [] and Enum.all?(paths, &String.starts_with?(&1, "scrypath_ops/test/")) do
      ops_dir = Path.expand("scrypath_ops", File.cwd!())

      ops_args =
        Enum.map(paths, &String.replace_prefix(&1, "scrypath_ops/", "")) ++ passthrough_args

      Mix.shell().info("==> test: delegating scrypath_ops paths into #{ops_dir}")

      {out, status} =
        System.cmd("mix", ["test" | ops_args], cd: ops_dir, stderr_to_stdout: true)

      Mix.shell().info(out)

      if status != 0 do
        Mix.raise("test delegation for scrypath_ops failed with status #{status}")
      end

      :handled
    else
      :passthrough
    end
  end

  defp test_path_arg?(<<"-", _::binary>>), do: false
  defp test_path_arg?(arg), do: String.ends_with?(arg, ".exs")

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: @source_ref,
      extras: [
        "README.md",
        "CONTRIBUTING.md",
        "ARCHITECTURE.md",
        "guides/overview.md",
        "guides/common-mistakes.md",
        "guides/drift-recovery.md",
        "guides/getting-started.md",
        "guides/golden-path.md",
        "guides/request-edge-search.md",
        "guides/composing-real-app-search.md",
        "guides/jtbd-and-user-flows.md",
        "guides/related-data-and-reindexing.md",
        "guides/meilisearch-operations.md",
        "guides/phoenix-walkthrough.md",
        "guides/phoenix-contexts.md",
        "guides/phoenix-controllers-and-json.md",
        "guides/phoenix-liveview.md",
        "guides/faceted-search-with-phoenix-liveview.md",
        "guides/multi-index-search.md",
        "guides/sync-modes-and-visibility.md",
        "guides/operator-mix-tasks.md",
        "guides/relevance-tuning.md",
        "guides/per-query-tuning-pipeline.md",
        "docs/releasing.md",
        "docs/jtbd-gap-map.md",
        "docs/operator-support.md",
        "docs/search-backend-sre.md"
      ],
      groups_for_extras: [
        "Getting Started": [
          "README.md",
          "guides/overview.md",
          "guides/jtbd-and-user-flows.md",
          "guides/getting-started.md",
          "guides/golden-path.md",
          "guides/request-edge-search.md",
          "guides/composing-real-app-search.md",
          "guides/related-data-and-reindexing.md",
          "guides/common-mistakes.md"
        ],
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
          "guides/meilisearch-operations.md",
          "guides/operator-mix-tasks.md",
          "guides/relevance-tuning.md",
          "guides/per-query-tuning-pipeline.md",
          "guides/sync-modes-and-visibility.md"
        ],
        Maintainers: [
          "CONTRIBUTING.md",
          "docs/jtbd-gap-map.md",
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
      # The optional Phoenix operator app under scrypath_ops/ must never be listed in
      # files: above — it is not part of the Hex tarball (see docs/releasing.md).
      files:
        ~w(lib .formatter.exs mix.exs README.md CONTRIBUTING.md ARCHITECTURE.md CHANGELOG.md guides docs),
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => @release_docs_url,
        "Changelog" => "#{@source_url}/blob/#{@source_ref}/CHANGELOG.md",
        "Guides" => "#{@release_docs_url}/readme.html"
      }
    ]
  end
end
