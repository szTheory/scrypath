defmodule Scrypath.ReindexTest do
  use ExUnit.Case, async: true

  defmodule RecordingMeilisearch do
    def create_index(schema_module, primary_key, config) do
      send(self(), {:create_index, schema_module, primary_key, config})

      {:ok,
       %{
         live_index: "scrypath_queryable_post",
         target_index: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
         task: %{uid: 10}
       }}
    end

    def apply_settings(schema_module, index_name, config) do
      send(self(), {:apply_settings, schema_module, index_name, config})

      {:ok,
       %{
         index: index_name,
         settings: Keyword.get(config, :settings, %{}),
         task: %{uid: 11}
       }}
    end

    def swap_indexes(schema_module, config) do
      send(self(), {:swap_indexes, schema_module, config})

      {:ok,
       %{
         live_index: "scrypath_queryable_post",
         target_index: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
         task: %{uid: 12}
       }}
    end
  end

  defmodule RecordingBackfill do
    def run(schema_module, config) do
      send(self(), {:backfill, schema_module, config})

      {:ok,
       %{
         index: Keyword.fetch!(config, :index_name),
         batches: 3,
         documents: 7,
         batch_results: [
           %{index: Keyword.fetch!(config, :index_name), documents: 3},
           %{index: Keyword.fetch!(config, :index_name), documents: 2},
           %{index: Keyword.fetch!(config, :index_name), documents: 2}
         ]
       }}
    end
  end

  test "reindex creates target index, applies settings, backfills, and cuts over in order" do
    assert {:ok,
            %{
              live_index: "scrypath_queryable_post",
              target_index: "posts_rebuild_v2",
              settings_applied: true,
              batches: 3,
              documents: 7,
              cutover: true
            }} =
             Scrypath.reindex(QueryablePost,
               backend: RecordingMeilisearch,
               repo: Scrypath.BackfillTest.BackfillRepo,
               batch_size: 100,
               target_index: "posts_rebuild_v2",
               settings: %{searchableAttributes: ["title"]},
               meilisearch: RecordingMeilisearch,
               backfill: RecordingBackfill
             )

    assert_received {:create_index, QueryablePost, :id, create_config}
    assert create_config[:target_index] == "posts_rebuild_v2"

    assert_received {:apply_settings, QueryablePost, "posts_rebuild_v2", settings_config}
    assert settings_config[:target_index] == "posts_rebuild_v2"

    assert_received {:backfill, QueryablePost, backfill_config}
    assert backfill_config[:index_name] == "posts_rebuild_v2"

    assert_received {:swap_indexes, QueryablePost, swap_config}
    assert swap_config[:target_index] == "posts_rebuild_v2"
  end

  test "reindex with cutover?: false leaves the live index untouched and returns target counts" do
    assert {:ok,
            %{
              live_index: "scrypath_queryable_post",
              target_index: "scrypath_queryable_post__reindex",
              settings_applied: true,
              batches: 3,
              documents: 7,
              cutover: false
            }} =
             Scrypath.reindex(QueryablePost,
               backend: RecordingMeilisearch,
               repo: Scrypath.BackfillTest.BackfillRepo,
               batch_size: 100,
               cutover?: false,
               meilisearch: RecordingMeilisearch,
               backfill: RecordingBackfill
             )

    refute_received {:swap_indexes, _, _}
    assert_received {:create_index, QueryablePost, :id, _}
    assert_received {:apply_settings, QueryablePost, "scrypath_queryable_post__reindex", _}
    assert_received {:backfill, QueryablePost, backfill_config}
    assert backfill_config[:index_name] == "scrypath_queryable_post__reindex"
  end

  test "reindex exposes the workflow result fields operators need to inspect what happened" do
    assert {:ok, result} =
             Scrypath.reindex(QueryablePost,
               backend: RecordingMeilisearch,
               repo: Scrypath.BackfillTest.BackfillRepo,
               batch_size: 100,
               cutover?: false,
               meilisearch: RecordingMeilisearch,
               backfill: RecordingBackfill
             )

    assert Map.has_key?(result, :live_index)
    assert Map.has_key?(result, :target_index)
    assert Map.has_key?(result, :settings_applied)
    assert Map.has_key?(result, :batches)
    assert Map.has_key?(result, :documents)
    assert Map.has_key?(result, :cutover)
  end
end
