defmodule Scrypath.SearchManyTest do
  use ExUnit.Case, async: false

  alias Scrypath.MultiSearchResult
  alias Scrypath.SearchResult

  defmodule SlowRepo do
    @moduledoc false
    def all(%Ecto.Query{}) do
      Process.sleep(200)
      []
    end
  end

  defmodule SequentialOnlyBackend do
    @moduledoc false
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :sequential_only

    @impl true
    def index_name(schema_module, config) do
      Scrypath.TestSupport.FakeBackend.index_name(schema_module, config)
    end

    @impl true
    def upsert_documents(_, _, _), do: {:ok, []}

    @impl true
    def delete_documents(_, _, _), do: {:ok, []}

    @impl true
    def search(_schema, query, _config) do
      {:ok, %{"hits" => [%{"id" => 1, "title" => query.text}], "page" => 1, "hitsPerPage" => 20}}
    end
  end

  defmodule PartialFailBackend do
    @moduledoc false
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :partial_fail

    @impl true
    def index_name(m, c), do: Scrypath.TestSupport.FakeBackend.index_name(m, c)

    @impl true
    def upsert_documents(_, _, _), do: {:ok, []}

    @impl true
    def delete_documents(_, _, _), do: {:ok, []}

    @impl true
    def search(FacetableMovie, _, _), do: {:error, :transport}

    @impl true
    def search(SearchablePost, %Scrypath.Query{} = q, _) do
      {:ok, %{"hits" => [%{"id" => 1}], "page" => 1, "hitsPerPage" => 20, "query" => q}}
    end
  end

  defmodule FailAllBackend do
    @moduledoc false
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :fail_all

    @impl true
    def index_name(m, c), do: Scrypath.TestSupport.FakeBackend.index_name(m, c)

    @impl true
    def upsert_documents(_, _, _), do: {:ok, []}

    @impl true
    def delete_documents(_, _, _), do: {:ok, []}

    @impl true
    def search(_, _, _), do: {:error, :bad}
  end

  @base_opts [
    backend: Scrypath.TestSupport.FakeBackend,
    meilisearch_url: "http://localhost:7700"
  ]

  test "all success with native search_many path" do
    assert {:ok, %MultiSearchResult{ordered: ordered, failures: [], by_schema: by}} =
             Scrypath.search_many(
               [{SearchablePost, "a"}, {FacetableMovie, "b"}],
               @base_opts
             )

    assert length(ordered) == 2
    assert map_size(by) == 2
    assert Enum.all?(ordered, fn {_, %SearchResult{}} -> true end)
    assert Map.new(ordered) == by
  end

  test ":all expansion with global_schemas hits both schemas" do
    assert {:ok, %MultiSearchResult{ordered: ordered, failures: [], by_schema: by}} =
             Scrypath.search_many(
               [{:all, "needle"}],
               Keyword.merge(@base_opts,
                 global_schemas: [SearchablePost, FacetableMovie],
                 max_schemas: 10
               )
             )

    schemas = ordered |> Enum.map(&elem(&1, 0)) |> MapSet.new()

    assert MapSet.equal?(schemas, MapSet.new([SearchablePost, FacetableMovie]))
    assert length(ordered) == 2
    assert map_size(by) == 2
  end

  test ":all_expansion respects max_schemas after splice" do
    # :all_expansion — post-splice cardinality rail
    assert {:error, {:too_many_schemas, 2, 1}} =
             Scrypath.search_many(
               [{:all, "needle"}],
               Keyword.merge(@base_opts,
                 global_schemas: [SearchablePost, FacetableMovie],
                 max_schemas: 1
               )
             )
  end

  test "validation failure before dispatch" do
    assert {:error, {:validation_failed, SearchablePost, {:unknown_facet, :nope}}} =
             Scrypath.search_many(
               [{SearchablePost, "a", facets: [:nope]}],
               @base_opts
             )
  end

  test "sequential fallback matches shape for two schemas" do
    assert {:ok, %MultiSearchResult{ordered: ordered, failures: []}} =
             Scrypath.search_many(
               [{SearchablePost, "x"}, {FacetableMovie, "y"}],
               Keyword.put(@base_opts, :backend, SequentialOnlyBackend)
             )

    assert length(ordered) == 2
  end

  test "federation_weight with sequential-only backend returns merge error" do
    assert {:error,
            {:invalid_options,
             {:federation_merge_requires_native_search_many, %{backend: SequentialOnlyBackend}}}} =
             Scrypath.search_many(
               [
                 {SearchablePost, "a", federation_weight: 2},
                 {FacetableMovie, "b"}
               ],
               Keyword.put(@base_opts, :backend, SequentialOnlyBackend)
             )
  end

  test "no federation_weight with sequential-only backend still succeeds" do
    assert {:ok, %MultiSearchResult{ordered: ordered, failures: []}} =
             Scrypath.search_many(
               [{SearchablePost, "a"}, {FacetableMovie, "b"}],
               Keyword.put(@base_opts, :backend, SequentialOnlyBackend)
             )

    assert length(ordered) == 2
  end

  test "federation_weight merge order and merge_projection follow descending weights" do
    assert {:ok, %MultiSearchResult{merge_hit_order: order} = multi} =
             Scrypath.search_many(
               [
                 {SearchablePost, "x", federation_weight: 1.0},
                 {FacetableMovie, "y", federation_weight: 3.0}
               ],
               @base_opts
             )

    assert Enum.map(order, &elem(&1, 0)) == [FacetableMovie, SearchablePost]

    proj = MultiSearchResult.merge_projection(multi)
    assert Enum.map(proj, &elem(&1, 0)) == [FacetableMovie, SearchablePost]
    assert length(proj) == 2
  end

  test "sequential partial transport failure" do
    assert {:ok, %MultiSearchResult{ordered: ordered, failures: failures}} =
             Scrypath.search_many(
               [{FacetableMovie, "a"}, {SearchablePost, "b"}],
               Keyword.put(@base_opts, :backend, PartialFailBackend)
             )

    assert length(ordered) == 1
    assert length(failures) == 1
    assert hd(failures).schema == FacetableMovie
  end

  test "sequential all transport failures" do
    assert {:error, {:all_failed, failures}} =
             Scrypath.search_many(
               [{SearchablePost, "a"}, {FacetableMovie, "b"}],
               Keyword.put(@base_opts, :backend, FailAllBackend)
             )

    assert length(failures) == 2
  end

  test "hydration timeout surfaces as all_failed when sole entry times out" do
    assert {:error, {:all_failed, [%{schema: QueryablePost, reason: :hydration_timeout}]}} =
             Scrypath.search_many(
               [{QueryablePost, "slow"}],
               @base_opts
               |> Keyword.merge(repo: SlowRepo, hydration_timeout: 50)
             )
  end

  test "telemetry span emits start and stop" do
    parent = self()

    :telemetry.attach_many(
      "search-many-test",
      [[:scrypath, :search_many, :start], [:scrypath, :search_many, :stop]],
      fn event, measurements, metadata, _ ->
        send(parent, {:telemetry, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach("search-many-test") end)

    assert {:ok, _} =
             Scrypath.search_many([{SearchablePost, "t"}], @base_opts)

    assert_receive {:telemetry, [:scrypath, :search_many, :start], _, _}
    assert_receive {:telemetry, [:scrypath, :search_many, :stop], _, _}
  end

  test "search_many! raises on top-level error only" do
    assert_raise RuntimeError, fn ->
      Scrypath.search_many!([{SearchablePost, "a", facets: [:bad]}], @base_opts)
    end

    assert %MultiSearchResult{} = Scrypath.search_many!([{SearchablePost, "ok"}], @base_opts)
  end

  test "partial telemetry when failures present" do
    parent = self()

    :telemetry.attach_many(
      "search-many-partial",
      [[:scrypath, :search_many, :partial]],
      fn _e, m, md, _ -> send(parent, {:partial, m, md}) end,
      nil
    )

    on_exit(fn -> :telemetry.detach("search-many-partial") end)

    assert {:ok, _} =
             Scrypath.search_many(
               [{FacetableMovie, "a"}, {SearchablePost, "b"}],
               Keyword.put(@base_opts, :backend, PartialFailBackend)
             )

    assert_receive {:partial, %{count: 1}, %{failure_count: 1}}
  end
end
