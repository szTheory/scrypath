defmodule ScrypathFixtures.MixProject do
  use Mix.Project

  # ADR 0002: a dev/test-only Mix project. It depends only on :scrypath, has no lock file and no
  # test directory (its tests live in scrypath_ops), and never ships in the Hex tarball.
  def project do
    [
      app: :scrypath_fixtures,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: ["lib"],
      start_permanent: false,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  # Keep this declaration exactly as written: an extra option (for example `only:`) can make it
  # diverge from scrypath_ops's own `{:scrypath, path: ".."}` and Mix would refuse the graph.
  defp deps do
    [
      {:scrypath, path: "../.."}
    ]
  end
end
