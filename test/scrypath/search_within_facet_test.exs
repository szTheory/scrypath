defmodule Scrypath.SearchWithinFacetTest do
  # Telemetry handlers are process-global; keep this module sequential like
  # `Scrypath.TelemetryTest` to avoid cross-test `:scrypath, :search` noise.
  use ExUnit.Case, async: false

  alias Scrypath.SearchResult

  test "search_within_facet rejects duplicate facet attribute in facet_filter" do
    assert_raise ArgumentError, ~r/^search_within_facet:/, fn ->
      Scrypath.search_within_facet(FacetableMovie, "x", {:genre, "Action"},
        facet_filter: [genre: "Drama"],
        backend: Scrypath.TestSupport.FakeBackend
      )
    end
  end

  test "scoped search attaches search_scope and scoped_facet to search telemetry" do
    handler_id = {:__MODULE__, :scoped, make_ref()}

    :telemetry.attach_many(
      handler_id,
      [[:scrypath, :search, :stop]],
      fn _event, _meas, meta, _ -> send(self(), {:search_stop_meta, meta}) end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    assert {:ok, _} =
             Scrypath.search_within_facet(FacetableMovie, "x", {:genre, "Action"},
               backend: Scrypath.TestSupport.FakeBackend
             )

    assert_receive {:search_stop_meta, meta}
    assert meta.search_scope == :within_facet
    assert meta.scoped_facet == :genre
  end

  test "search_within_facet composes filter, facet_filter, and bucket in one Meilisearch body" do
    stub = Module.concat(__MODULE__, ScopedFacetReqStub)

    Req.Test.stub(stub, fn conn ->
      send(self(), {:scoped_search_body, conn.body_params})

      Req.Test.json(conn, %{
        "hits" => [],
        "page" => 1,
        "hitsPerPage" => 20,
        "totalHits" => 0
      })
    end)

    assert {:ok, %SearchResult{}} =
             Scrypath.search_within_facet(FacetableMovie, "aliens", {:genre, "Action"},
               backend: Scrypath.Meilisearch,
               meilisearch_url: "http://localhost:7700",
               req_options: [plug: {Req.Test, stub}],
               filter: [director: "Scott"],
               facet_filter: [year: 1979]
             )

    assert_received {:scoped_search_body, body}
    assert body["q"] == "aliens"
    assert "director = \"Scott\"" in body["filter"]
    assert "genre = \"Action\"" in body["facetFilters"]
    assert "year = 1979" in body["facetFilters"]
  end
end
