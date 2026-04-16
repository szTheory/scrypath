defmodule Scrypath.LiveMeilisearchVerificationTest do
  use ExUnit.Case, async: false

  alias Scrypath.TestSupport.IntegrationRepo
  alias Scrypath.TestSupport.MeilisearchIntegration

  @moduletag :integration

  setup_all do
    database = MeilisearchIntegration.setup_repo!()

    on_exit(fn ->
      MeilisearchIntegration.cleanup_repo!(database)
    end)

    :ok
  end

  setup do
    MeilisearchIntegration.reset_repo!()
    prefix = MeilisearchIntegration.index_prefix()
    live_index = "#{prefix}_queryable_post"
    target_index = "#{live_index}__reindex"
    external_index = "#{prefix}_queryable_external_post"

    on_exit(fn ->
      MeilisearchIntegration.delete_indexes([
        live_index,
        target_index,
        external_index,
        "#{live_index}-candidate"
      ])
    end)

    %{
      index_prefix: prefix,
      live_index: live_index,
      target_index: target_index,
      external_index: external_index
    }
  end

  test "inline sync writes and waits against live Meilisearch", %{
    index_prefix: prefix,
    live_index: live_index
  } do
    post = %QueryablePost{
      id: 1,
      title: "First",
      body: "Body 1",
      status: "published",
      inserted_at: DateTime.utc_now()
    }

    assert {:ok, %{mode: :inline, status: :completed, task: %{status: :succeeded}}} =
             Scrypath.sync_record(QueryablePost, post,
               backend: Scrypath.Meilisearch,
               index_prefix: prefix,
               meilisearch_url: MeilisearchIntegration.meilisearch_url!()
             )

    assert :ok = MeilisearchIntegration.wait_for_search_count!(QueryablePost, live_index, 1)
  end

  test "reindex with cutover?: false builds and verifies a target index without touching live", %{
    index_prefix: prefix,
    live_index: live_index,
    target_index: target_index
  } do
    MeilisearchIntegration.insert_posts!([
      %{
        id: 10,
        title: "Tenth",
        body: "Body 10",
        status: "published",
        inserted_at: DateTime.utc_now()
      },
      %{
        id: 11,
        title: "Eleventh",
        body: "Body 11",
        status: "published",
        inserted_at: DateTime.utc_now()
      }
    ])

    assert {:ok,
            %{
              live_index: ^live_index,
              target_index: ^target_index,
              settings_applied: true,
              batches: 2,
              documents: 2,
              cutover: false
            }} =
             Scrypath.reindex(QueryablePost,
               backend: Scrypath.Meilisearch,
               repo: IntegrationRepo,
               batch_size: 1,
               index_prefix: prefix,
               cutover?: false,
               settings: %{
                 searchableAttributes: ["title"],
                 sortableAttributes: ["inserted_at"]
               },
               meilisearch_url: MeilisearchIntegration.meilisearch_url!()
             )

    refute MeilisearchIntegration.index_exists?(live_index)
    assert MeilisearchIntegration.index_exists?(target_index)
    assert :ok = MeilisearchIntegration.wait_for_search_count!(QueryablePost, target_index, 2)

    settings = MeilisearchIntegration.fetch_settings!(target_index)
    assert settings["searchableAttributes"] == ["title"]
    assert settings["sortableAttributes"] == ["inserted_at"]
  end

  test "backfill preserves custom document ids against a real index", %{
    index_prefix: prefix,
    external_index: external_index
  } do
    MeilisearchIntegration.insert_external_posts!([
      %{external_id: "ext-1", title: "External One"},
      %{external_id: "ext-2", title: "External Two"}
    ])

    assert {:ok, %{index: ^external_index, documents: 2}} =
             Scrypath.backfill(QueryableExternalPost,
               backend: Scrypath.Meilisearch,
               repo: IntegrationRepo,
               batch_size: 10,
               index_prefix: prefix,
               meilisearch_url: MeilisearchIntegration.meilisearch_url!()
             )

    assert :ok =
             MeilisearchIntegration.wait_for_search_count!(
               QueryableExternalPost,
               external_index,
               2
             )

    assert {:ok, %{"hits" => hits}} =
             Scrypath.Meilisearch.search(QueryableExternalPost, %{"q" => "", "limit" => 10},
               index_prefix: prefix,
               meilisearch_url: MeilisearchIntegration.meilisearch_url!()
             )

    assert Enum.sort(Enum.map(hits, & &1["external_id"])) == ["ext-1", "ext-2"]
  end
end
