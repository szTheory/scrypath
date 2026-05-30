defmodule Mix.Tasks.Scrypath.Seed do
  @shortdoc "Generates a multi-tenant test catalog in the DB"
  @moduledoc """
  Generates sample multi-tenant catalog data using the `ScrypathEcommerce.CatalogFixtures`.

  This task can be run via:
      mix scrypath.seed

  It ensures the application is started, then invokes `CatalogFixtures.scenario_standard_catalog/1`.
  """
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    IO.puts("Seeding standard catalog data...")

    graph = ScrypathEcommerce.CatalogFixtures.scenario_standard_catalog(%{name: "Seed Tenant"})

    IO.puts("""
    Seed successful!
    Created:
      - 1 Tenant (#{graph.tenant.name})
      - #{length(graph.categories)} Categories
      - #{length(graph.products)} Products
      - #{length(graph.variants)} Variants
    """)
  end
end
