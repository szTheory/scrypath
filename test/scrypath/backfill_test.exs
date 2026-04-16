defmodule Scrypath.BackfillTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias Scrypath.Document

  defmodule RecordingBackend do
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :recording

    @impl true
    def index_name(schema_module, config) do
      prefix = Keyword.get(config, :index_prefix, "scrypath")
      schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

      "#{prefix}_#{schema_name}"
    end

    @impl true
    def upsert_documents(schema_module, documents, config) do
      send(self(), {:upsert_documents, schema_module, documents, config})

      {:ok,
       %{
         index: Keyword.get(config, :index_name) || index_name(schema_module, config),
         document_ids: Enum.map(documents, & &1.id)
       }}
    end

    @impl true
    def delete_documents(_schema_module, _document_ids, _config) do
      {:ok, %{}}
    end

    @impl true
    def search(_schema_module, _query, _config) do
      {:ok, %{hits: []}}
    end
  end

  defmodule BackfillRepo do
    def put_records(records) when is_list(records) do
      Process.put({__MODULE__, :records}, records)
      :ok
    end

    def reset do
      Process.delete({__MODULE__, :records})
      :ok
    end

    def all(%Ecto.Query{} = query) do
      send(self(), {:backfill_repo_all, query})

      Process.get({__MODULE__, :records}, [])
      |> apply_query(query)
    end

    defp apply_query(records, query) do
      records
      |> Enum.filter(&matches_wheres?(&1, query.wheres))
      |> order_records(query.order_bys)
      |> limit_records(query.limit)
    end

    defp matches_wheres?(record, wheres) do
      Enum.all?(wheres, fn where ->
        evaluate(record, where.expr, where.params)
      end)
    end

    defp evaluate(record, {:==, _, [field_ast, {:^, _, [index]}]}, params) do
      field_value(record, field_ast) == param_value(params, index)
    end

    defp evaluate(record, {:>, _, [field_ast, {:^, _, [index]}]}, params) do
      field_value(record, field_ast) > param_value(params, index)
    end

    defp field_value(record, {{:., _, [{:&, _, [0]}, field]}, _, []}) do
      Map.fetch!(record, field)
    end

    defp param_value(params, index) do
      params |> Enum.at(index) |> elem(0)
    end

    defp order_records(records, []), do: records

    defp order_records(records, [%Ecto.Query.ByExpr{expr: [asc: field_ast]}]) do
      Enum.sort_by(records, &field_value(&1, field_ast), :asc)
    end

    defp limit_records(records, nil), do: records

    defp limit_records(records, %Ecto.Query.LimitExpr{expr: {:^, _, [index]}, params: params}) do
      Enum.take(records, param_value(params, index))
    end
  end

  setup do
    BackfillRepo.reset()
    :ok
  end

  test "backfill validates options and returns an explicit manual result contract" do
    BackfillRepo.put_records([
      %QueryablePost{id: 1, title: "First", body: "Body 1"}
    ])

    assert_raise ArgumentError, ~r/batch_size/, fn ->
      Scrypath.backfill(QueryablePost, backend: RecordingBackend, repo: BackfillRepo)
    end

    assert {:ok, result} =
             Scrypath.backfill(QueryablePost,
               backend: RecordingBackend,
               repo: BackfillRepo,
               batch_size: 10,
               index_name: "posts_v2"
             )

    assert result.index == "posts_v2"
    assert result.batches == 1
    assert result.documents == 1
    assert result.mode == :manual

    assert_received {:upsert_documents, QueryablePost, [%Document{id: 1}], config}
    assert config[:index_name] == "posts_v2"
  end

  test "backfill accepts either the schema module or an explicit query override" do
    BackfillRepo.put_records([
      %QueryablePost{id: 1, title: "Draft", body: "Body 1", status: "draft"},
      %QueryablePost{id: 2, title: "Published", body: "Body 2", status: "published"},
      %QueryablePost{id: 3, title: "Published Again", body: "Body 3", status: "published"}
    ])

    scoped_query = from(post in QueryablePost, where: post.status == ^"published")

    assert {:ok, %{documents: 2, batches: 1, index: "scrypath_queryable_post", mode: :manual}} =
             Scrypath.backfill(QueryablePost,
               backend: RecordingBackend,
               repo: BackfillRepo,
               query: scoped_query,
               batch_size: 10
             )

    assert_received {:upsert_documents, QueryablePost, documents, _config}
    assert Enum.map(documents, & &1.id) == [2, 3]
    assert_received {:backfill_repo_all, %Ecto.Query{} = query}
    assert length(query.wheres) == 1
  end

  test "backfill result keeps batch counts and target index visible" do
    BackfillRepo.put_records([
      %QueryablePost{id: 9, title: "Visible", body: "Body"}
    ])

    assert {:ok, %{index: "posts_rebuild", batches: 1, documents: 1, mode: :manual} = result} =
             Scrypath.backfill(QueryablePost,
               backend: RecordingBackend,
               repo: BackfillRepo,
               batch_size: 25,
               index_name: "posts_rebuild"
             )

    assert Map.has_key?(result, :index)
    assert Map.has_key?(result, :batches)
    assert Map.has_key?(result, :documents)
    assert Map.has_key?(result, :mode)
  end

  test "backfill fetches deterministic primary-key batches without skipping page edges" do
    BackfillRepo.put_records([
      %QueryablePost{id: 5, title: "Fifth", body: "Body 5"},
      %QueryablePost{id: 1, title: "First", body: "Body 1"},
      %QueryablePost{id: 3, title: "Third", body: "Body 3"},
      %QueryablePost{id: 2, title: "Second", body: "Body 2"},
      %QueryablePost{id: 4, title: "Fourth", body: "Body 4"}
    ])

    assert {:ok,
            %{
              index: "scrypath_queryable_post",
              batches: 3,
              documents: 5,
              mode: :manual,
              batch_results: [
                %{documents: 2, last_primary_key: 2},
                %{documents: 2, last_primary_key: 4},
                %{documents: 1, last_primary_key: 5}
              ]
            }} =
             Scrypath.backfill(QueryablePost,
               backend: RecordingBackend,
               repo: BackfillRepo,
               batch_size: 2
             )

    assert_received {:upsert_documents, QueryablePost, batch_one, _config}
    assert_received {:upsert_documents, QueryablePost, batch_two, _config}
    assert_received {:upsert_documents, QueryablePost, batch_three, _config}

    assert Enum.map(batch_one, & &1.id) == [1, 2]
    assert Enum.map(batch_two, & &1.id) == [3, 4]
    assert Enum.map(batch_three, & &1.id) == [5]

    assert_received {:backfill_repo_all, first_query}
    assert_received {:backfill_repo_all, second_query}
    assert_received {:backfill_repo_all, third_query}

    assert first_query.wheres == []
    assert length(second_query.wheres) == 1
    assert length(third_query.wheres) == 1
  end

  test "backfill writes every batch through the backend with the target index override" do
    BackfillRepo.put_records([
      %QueryablePost{id: 1, title: "First", body: "Body 1"},
      %QueryablePost{id: 2, title: "Second", body: "Body 2"},
      %QueryablePost{id: 3, title: "Third", body: "Body 3"}
    ])

    assert {:ok,
            %{
              index: "posts_rebuild",
              batches: 2,
              documents: 3,
              mode: :manual,
              batch_results: [
                %{index: "posts_rebuild", documents: 2},
                %{index: "posts_rebuild", documents: 1}
              ]
            }} =
             Scrypath.backfill(QueryablePost,
               backend: RecordingBackend,
               repo: BackfillRepo,
               batch_size: 2,
               index_name: "posts_rebuild"
             )

    assert_received {:upsert_documents, QueryablePost, first_batch, first_config}
    assert_received {:upsert_documents, QueryablePost, second_batch, second_config}

    assert Enum.map(first_batch, & &1.id) == [1, 2]
    assert Enum.map(second_batch, & &1.id) == [3]
    assert first_config[:index_name] == "posts_rebuild"
    assert second_config[:index_name] == "posts_rebuild"
  end
end
