defmodule ScrypathOps.Playbook.RunnerTest do
  use ExUnit.Case, async: false

  alias ScrypathOps.Playbook.Runner
  alias ScrypathOps.Playbook.V1
  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.SearchPlayground.Adapter.Scrypath, as: ScrypathAdapter
  alias ScrypathOps.Test.SearchPlaygroundStubAdapter

  defmodule FacetedOpsPost do
    @moduledoc false

    use Ecto.Schema

    use Scrypath,
      fields: [:title, :genre],
      filterable: [:genre],
      faceting: [attributes: [:genre], max_values_per_facet: 20]

    embedded_schema do
      field(:title, :string)
      field(:genre, :string)
    end
  end

  defmodule ParityBackend do
    @moduledoc false
    @behaviour Scrypath.Backend

    alias Scrypath.MultiSearchResult
    alias Scrypath.Query
    alias Scrypath.SearchResult

    @impl true
    def name, do: :runner_parity

    @impl true
    def index_name(schema_module, config) do
      prefix = Keyword.get(config, :index_prefix, "runner_test")
      schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()
      "#{prefix}_#{schema_name}"
    end

    @impl true
    def upsert_documents(_schema_module, documents, _config), do: {:ok, documents}

    @impl true
    def delete_documents(_schema_module, document_ids, _config), do: {:ok, document_ids}

    @impl true
    def search(_schema_module, %Query{} = query, _config) do
      raw = %{
        "hits" => [],
        "query" => query,
        "page" => 1,
        "hitsPerPage" => 20,
        "totalHits" => 0
      }

      {:ok, SearchResult.new(query, raw, [], [])}
    end

    @impl true
    def search_facet_values(_schema, _facet, _query, _opts, _config),
      do: {:error, :not_implemented}

    @impl true
    def search_many(paired_queries, _config) when is_list(paired_queries) do
      ordered =
        Enum.map(paired_queries, fn {schema_module, %Query{} = query, _fed_opts} ->
          raw = %{
            "hits" => [],
            "query" => query,
            "page" => 1,
            "hitsPerPage" => 20,
            "totalHits" => 0
          }

          {schema_module, SearchResult.new(query, raw, [], [])}
        end)

      by_schema = Map.new(ordered)
      {:ok, MultiSearchResult.new(ordered: ordered, by_schema: by_schema, failures: [])}
    end
  end

  defmodule ErrorBackend do
    @moduledoc false
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :runner_error

    @impl true
    def index_name(_schema_module, _config), do: "runner_error"

    @impl true
    def upsert_documents(_schema_module, _documents, _config), do: {:ok, []}

    @impl true
    def delete_documents(_schema_module, _document_ids, _config), do: {:ok, []}

    @impl true
    def search(_schema_module, _query, _config), do: {:error, :search_failed}

    @impl true
    def search_facet_values(_schema, _facet, _query, _opts, _config),
      do: {:error, :not_implemented}
  end

  defmodule NativeTransportFailBackend do
    @moduledoc false
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :runner_native_transport_fail

    @impl true
    def index_name(schema_module, config), do: ParityBackend.index_name(schema_module, config)

    @impl true
    def upsert_documents(a, b, c), do: ParityBackend.upsert_documents(a, b, c)

    @impl true
    def delete_documents(a, b, c), do: ParityBackend.delete_documents(a, b, c)

    @impl true
    def search(a, b, c), do: ParityBackend.search(a, b, c)

    @impl true
    def search_facet_values(_schema, _facet, _query, _opts, _config),
      do: {:error, :not_implemented}

    @impl true
    def search_many(_paired, _config), do: {:error, :reset_by_peer}
  end

  setup do
    prev_allow = Application.get_env(:scrypath_ops, :schema_allowlist)
    prev_backend = Application.get_env(:scrypath_ops, :backend)
    prev_sync = Application.get_env(:scrypath_ops, :sync_mode)
    prev_prefix = Application.get_env(:scrypath_ops, :index_prefix)
    prev_url = Application.get_env(:scrypath_ops, :meilisearch_url)
    prev_adapter = Application.get_env(:scrypath_ops, :search_playground_adapter)
    prev_stub_variant = Application.get_env(:scrypath_ops, :search_stub_variant)

    Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB, FacetedOpsPost])
    Application.put_env(:scrypath_ops, :backend, ParityBackend)
    Application.put_env(:scrypath_ops, :sync_mode, :manual)
    Application.put_env(:scrypath_ops, :index_prefix, "runner_test")
    Application.put_env(:scrypath_ops, :meilisearch_url, "http://localhost:7700")
    Application.put_env(:scrypath_ops, :search_playground_adapter, SearchPlaygroundStubAdapter)
    Application.put_env(:scrypath_ops, :search_stub_variant, :ok)

    on_exit(fn ->
      restore = fn k, v ->
        if v == nil,
          do: Application.delete_env(:scrypath_ops, k),
          else: Application.put_env(:scrypath_ops, k, v)
      end

      restore.(:schema_allowlist, prev_allow)
      restore.(:backend, prev_backend)
      restore.(:sync_mode, prev_sync)
      restore.(:index_prefix, prev_prefix)
      restore.(:meilisearch_url, prev_url)
      restore.(:search_playground_adapter, prev_adapter)
      restore.(:search_stub_variant, prev_stub_variant)
    end)

    :ok
  end

  test "run_validated search dispatches stub adapter after V1.validate/1" do
    raw = %{
      "playbook_format" => 1,
      "mode" => "search",
      "schema" => "ScrypathOps.Test.OpsPostA",
      "q" => "needle",
      "opts" => %{"page" => %{"size" => 5}}
    }

    assert {:ok, map} = V1.validate(raw)

    assert {:ok, res} =
             Runner.run_validated(map, [OpsPostA, OpsPostB], base_opts())

    assert res.hits == []
  end

  test "run_validated search_many maps entries and dispatches" do
    raw = %{
      "playbook_format" => 1,
      "mode" => "search_many",
      "entries" => [
        ["ScrypathOps.Test.OpsPostA", "a", %{}],
        ["ScrypathOps.Test.OpsPostB", "b", %{}]
      ],
      "opts" => %{}
    }

    assert {:ok, map} = V1.validate(raw)

    assert {:ok, %Scrypath.MultiSearchResult{} = ms} =
             Runner.run_validated(map, [OpsPostA, OpsPostB], base_opts())

    assert length(ms.ordered) == 2
  end

  test "rejects {:error, _} tuple" do
    assert {:error, :playbook_not_validated} =
             Runner.run_validated({:error, :x}, [OpsPostA], backend: Scrypath.Meilisearch)
  end

  describe "runner-library parity matrix" do
    setup do
      Application.put_env(:scrypath_ops, :search_playground_adapter, ScrypathAdapter)
      :ok
    end

    test "search happy path matches direct Scrypath.search/3" do
      raw = %{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "Elixir.ScrypathOps.Test.OpsPostA",
        "q" => "needle",
        "opts" => %{"page" => %{"number" => 2, "size" => 5}}
      }

      assert {:ok, validated} = V1.validate(raw)

      assert {:ok, %Scrypath.SearchResult{} = direct} =
               Scrypath.search(OpsPostA, "needle", base_opts(page: [number: 2, size: 5]))

      assert {:ok, %Scrypath.SearchResult{} = via_runner} =
               Runner.run_validated(validated, [OpsPostA, OpsPostB, FacetedOpsPost], base_opts())

      assert via_runner == direct
    end

    test "search_many happy path matches direct Scrypath.search_many/2" do
      raw = %{
        "playbook_format" => 1,
        "mode" => "search_many",
        "entries" => [
          ["Elixir.ScrypathOps.Test.OpsPostA", "a", %{}],
          ["Elixir.ScrypathOps.Test.OpsPostB", "b", %{}]
        ],
        "opts" => %{}
      }

      assert {:ok, validated} = V1.validate(raw)

      assert {:ok, %Scrypath.MultiSearchResult{} = direct} =
               Scrypath.search_many(
                 [{OpsPostA, "a"}, {OpsPostB, "b"}],
                 base_opts()
               )

      assert {:ok, %Scrypath.MultiSearchResult{} = via_runner} =
               Runner.run_validated(validated, [OpsPostA, OpsPostB, FacetedOpsPost], base_opts())

      assert via_runner == direct
    end

    test "pre-dispatch config failure stays at the runner boundary" do
      raw = %{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "Elixir.ScrypathOps.Test.OpsPostA",
        "q" => "needle",
        "opts" => %{}
      }

      assert {:ok, validated} = V1.validate(raw)

      assert {:error, {:config, :missing_backend}} =
               Runner.run_validated(validated, [OpsPostA], Keyword.delete(base_opts(), :backend))
    end

    test "backend/runtime failure matches direct Scrypath.search/3" do
      raw = %{
        "playbook_format" => 1,
        "mode" => "search",
        "schema" => "Elixir.ScrypathOps.Test.OpsPostA",
        "q" => "needle",
        "opts" => %{}
      }

      assert {:ok, validated} = V1.validate(raw)
      opts = base_opts(backend: ErrorBackend)

      assert {:error, :search_failed} = Scrypath.search(OpsPostA, "needle", opts)

      assert {:error, :search_failed} =
               Runner.run_validated(validated, [OpsPostA], opts)
    end

    test "multi-search validation_failed edge matches direct Scrypath.search_many/2" do
      raw = %{
        "playbook_format" => 1,
        "mode" => "search_many",
        "entries" => [
          ["Elixir.ScrypathOps.Playbook.RunnerTest.FacetedOpsPost", "a", %{"facets" => ["nope"]}]
        ],
        "opts" => %{}
      }

      assert {:ok, validated} = V1.validate(raw)

      assert {:error, {:validation_failed, FacetedOpsPost, {:unknown_facet, :nope}}} =
               Scrypath.search_many(
                 [{FacetedOpsPost, "a", facets: [:nope]}],
                 base_opts()
               )

      assert {:error, {:validation_failed, FacetedOpsPost, {:unknown_facet, :nope}}} =
               Runner.run_validated(validated, [FacetedOpsPost], base_opts())
    end

    test "multi-search backend/runtime failure matches direct Scrypath.search_many/2" do
      raw = %{
        "playbook_format" => 1,
        "mode" => "search_many",
        "entries" => [
          ["Elixir.ScrypathOps.Test.OpsPostA", "a", %{"federation_weight" => 1.0}],
          ["Elixir.ScrypathOps.Playbook.RunnerTest.FacetedOpsPost", "b", %{}]
        ],
        "opts" => %{}
      }

      assert {:ok, validated} = V1.validate(raw)
      opts = base_opts(backend: NativeTransportFailBackend)

      assert {:error, {:transport_failed, :reset_by_peer}} =
               Scrypath.search_many(
                 [
                   {OpsPostA, "a", federation_weight: 1.0},
                   {FacetedOpsPost, "b"}
                 ],
                 opts
               )

      assert {:error, {:transport_failed, :reset_by_peer}} =
               Runner.run_validated(validated, [OpsPostA, FacetedOpsPost], opts)
    end
  end

  defp base_opts(overrides \\ []) do
    [
      backend: ParityBackend,
      meilisearch_url: "http://localhost:7700",
      index_prefix: "runner_test",
      sync_mode: :manual
    ]
    |> Keyword.merge(overrides)
  end
end
