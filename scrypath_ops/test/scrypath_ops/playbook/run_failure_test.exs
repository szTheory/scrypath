defmodule ScrypathOps.Playbook.RunFailureTest do
  use ExUnit.Case, async: true

  alias ScrypathOps.Playbook.RunFailure

  test "{:config, :no_schema} yields a stable failure payload" do
    failure =
      RunFailure.enrich({:config, :no_schema},
        basename: "customer-search.json",
        schema: "Elixir.MyApp.Customer",
        mode: "search",
        secret: "ignore-me",
        page_size: 999
      )

    assert failure.failure_class != ""
    assert failure.message != ""
    assert is_map(failure.copy)
    assert failure.copy == %{schema: "Elixir.MyApp.Customer", mode: "search"}

    assert String.starts_with?(failure.doc.primary, "https://")
    assert String.contains?(failure.doc.primary, "playbook-schema")
    assert String.contains?(failure.doc.primary, "github.com")
    assert length(failure.doc.related) <= 2
  end

  test "page size failures expose only allowlisted diagnostic keys" do
    failure =
      RunFailure.enrich({:page_size_out_of_range, 75, 50},
        basename: "catalog.json",
        schema: "Elixir.MyApp.Product",
        mode: "search_many",
        page_size: 75,
        max_page_size: 50,
        query: "secret query text",
        api_key: "secret"
      )

    assert failure.copy == %{
             schema: "Elixir.MyApp.Product",
             mode: "search_many",
             page_size: 75,
             max_page_size: 50
           }

    assert Map.keys(failure.copy) |> Enum.sort() == [:max_page_size, :mode, :page_size, :schema]
  end
end
