defmodule Scrypath.Meilisearch.ClientMultiSearchTest do
  use ExUnit.Case, async: true

  alias Scrypath.Meilisearch.Client

  test "POST /multi-search sends queries and never mergeFacets" do
    stub = Module.concat(__MODULE__, MultiSearchStub)

    Req.Test.stub(stub, fn conn ->
      assert conn.method == "POST"
      assert String.ends_with?(conn.request_path, "/multi-search")

      body = conn.body_params
      assert is_list(body["queries"])
      assert length(body["queries"]) == 2
      refute Map.has_key?(body, "mergeFacets")
      refute body |> Jason.encode!() |> String.contains?("mergeFacets")

      Req.Test.json(conn, %{"hits" => [], "facetsByIndex" => %{}})
    end)

    payload = %{
      "queries" => [
        %{"indexUid" => "a", "q" => "one"},
        %{"indexUid" => "b", "q" => "two"}
      ],
      "federation" => %{"limit" => 20, "offset" => 0}
    }

    assert {:ok, %{"hits" => []}} =
             Client.multi_search(payload,
               meilisearch_url: "http://localhost:7700",
               req_options: [plug: {Req.Test, stub}]
             )
  end
end
