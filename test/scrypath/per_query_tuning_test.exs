defmodule Scrypath.PerQueryTuningTest do
  use ExUnit.Case, async: true

  alias Scrypath.Meilisearch.Query, as: MeilisearchQuery
  alias Scrypath.Options
  alias Scrypath.Query

  defmodule RankingDetailsBackend do
    @moduledoc false
    @behaviour Scrypath.Backend

    @impl true
    def name, do: :ranking_details_test

    @impl true
    defdelegate index_name(schema_module, config), to: Scrypath.TestSupport.FakeBackend

    @impl true
    defdelegate upsert_documents(schema_module, documents, config),
      to: Scrypath.TestSupport.FakeBackend

    @impl true
    defdelegate delete_documents(schema_module, document_ids, config),
      to: Scrypath.TestSupport.FakeBackend

    @impl true
    defdelegate search(schema_module, query, config), to: Scrypath.TestSupport.FakeBackend

    @impl true
    defdelegate search_facet_values(schema_module, facet_name, facet_query, opts, config),
      to: Scrypath.TestSupport.FakeBackend

    @impl true
    defdelegate search_many(paired_queries, config), to: Scrypath.TestSupport.FakeBackend
  end

  def capture_search_start(
        _event,
        _measurements,
        %{schema: SearchablePost, backend: :ranking_details_test} = metadata,
        parent
      ) do
    send(parent, {:search_start_meta, metadata})
  end

  def capture_search_start(_event, _measurements, _metadata, _parent), do: :ok

  test "per_query rejects unknown inner keys" do
    assert {:error, _} = Options.validate_search_options(SearchablePost, per_query: [bad: :key])
  end

  test "per_query ranking threshold flows into Meilisearch JSON" do
    assert {:ok, kw} =
             Options.validate_search_options(SearchablePost,
               per_query: [ranking_score_threshold: 0.5]
             )

    payload =
      "hi"
      |> Query.new(kw)
      |> MeilisearchQuery.to_payload()

    assert payload["rankingScoreThreshold"] == 0.5
  end

  test "search/3 telemetry start metadata marks ranking_score_details when enabled" do
    handler_id = {:__MODULE__, :ranking_details, make_ref()}

    :telemetry.attach_many(
      handler_id,
      [[:scrypath, :search, :start]],
      &__MODULE__.capture_search_start/4,
      self()
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    assert {:ok, _} =
             Scrypath.search(SearchablePost, "x",
               backend: RankingDetailsBackend,
               per_query: [show_ranking_score_details: true]
             )

    assert_receive {:search_start_meta, meta}
    assert meta.ranking_score_details == true
  end
end
