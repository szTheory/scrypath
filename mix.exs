defmodule Scrypath.MixProject do
  use Mix.Project

  def project do
    [
      app: :scrypath,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: "Ecto-native search indexing and orchestration for Elixir apps"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.13"},
      {:nimble_options, "~> 1.1"},
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "ARCHITECTURE.md"]
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/jon/scrypath"
      }
    ]
  end
end
