defmodule Scrypath.ReindexTest do
  use ExUnit.Case, async: true

  defmodule RecordingMeilisearch do
    alias Scrypath.Operations

    def index_name(schema_module, config) do
      prefix = Keyword.get(config, :index_prefix) || "scrypath"
      schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

      "#{prefix}_#{schema_name}"
    end

    def create_index(schema_module, primary_key, config) do
      send(self(), {:create_index, schema_module, primary_key, config})

      {:ok,
       %{
         live_index: "scrypath_queryable_post",
         target_index: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
         task:
           Operations.task_from_backend(%{
             uid: 10,
             status: "enqueued",
             indexUid: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
             type: "indexCreation"
           })
       }}
    end

    def apply_settings(schema_module, index_name, config) do
      send(self(), {:apply_settings, schema_module, index_name, config})

      {:ok,
       %{
         index: index_name,
         settings: Keyword.get(config, :settings, %{}),
         task:
           Operations.task_from_backend(%{
             uid: 11,
             status: "enqueued",
             indexUid: index_name,
             type: "settingsUpdate"
           })
       }}
    end

    def swap_indexes(schema_module, config) do
      send(self(), {:swap_indexes, schema_module, config})

      {:ok,
       %{
         live_index: "scrypath_queryable_post",
         target_index: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
         task:
           Operations.task_from_backend(%{
             uid: 12,
             status: "enqueued",
             indexUid: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
             type: "indexSwap"
           })
       }}
    end
  end

  defmodule FutureTaskBackend do
    alias Scrypath.Operations

    def index_name(schema_module, config) do
      RecordingMeilisearch.index_name(schema_module, config)
    end

    def create_index(schema_module, primary_key, config) do
      send(self(), {:create_index, schema_module, primary_key, config})

      {:ok,
       %{
         live_index: "scrypath_queryable_post",
         target_index: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
         task:
           Operations.task_from_backend(
             %{
               uid: 110,
               status: "enqueued",
               indexUid: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
               type: "indexCreation"
             },
             source: :future_backend
           )
       }}
    end

    def apply_settings(schema_module, index_name, config) do
      send(self(), {:apply_settings, schema_module, index_name, config})

      {:ok,
       %{
         index: index_name,
         settings: Keyword.get(config, :settings, %{}),
         task:
           Operations.task_from_backend(
             %{uid: 111, status: "enqueued", indexUid: index_name, type: "settingsUpdate"},
             source: :future_backend
           )
       }}
    end

    def swap_indexes(schema_module, config) do
      send(self(), {:swap_indexes, schema_module, config})

      {:ok,
       %{
         live_index: "scrypath_queryable_post",
         target_index: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
         task:
           Operations.task_from_backend(
             %{
               uid: 112,
               status: "enqueued",
               indexUid: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
               type: "indexSwap"
             },
             source: :future_backend
           )
       }}
    end
  end

  defmodule RawTaskBackend do
    def create_index(schema_module, primary_key, config) do
      send(self(), {:create_index, schema_module, primary_key, config})

      {:ok,
       %{
         live_index: "scrypath_queryable_post",
         target_index: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
         task: %{
           uid: 210,
           status: "enqueued",
           index_uid: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
           type: "indexCreation"
         }
       }}
    end

    def apply_settings(schema_module, index_name, config) do
      send(self(), {:apply_settings, schema_module, index_name, config})

      {:ok,
       %{
         index: index_name,
         settings: Keyword.get(config, :settings, %{}),
         task: %{uid: 211, status: "enqueued", index_uid: index_name, type: "settingsUpdate"}
       }}
    end

    def swap_indexes(schema_module, config) do
      send(self(), {:swap_indexes, schema_module, config})

      {:ok,
       %{
         live_index: "scrypath_queryable_post",
         target_index: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
         task: %{
           uid: 212,
           status: "enqueued",
           index_uid: Keyword.get(config, :target_index, "scrypath_queryable_post__reindex"),
           type: "indexSwap"
         }
       }}
    end
  end

  defmodule RecordingTaskClient do
    def task(task_uid, _config) do
      send(self(), {:task_wait, task_uid})

      {:ok,
       %{
         uid: task_uid,
         status: "succeeded",
         indexUid: "waited_#{task_uid}",
         type: "documentAdditionOrUpdate"
       }}
    end
  end

  defmodule RecordingBackfill do
    alias Scrypath.Operations
    alias Scrypath.Operations.Result

    def run(schema_module, config) do
      send(self(), {:backfill, schema_module, config})

      {:ok,
       %{
         index: Keyword.fetch!(config, :index_name),
         batches: 3,
         documents: 7,
         batch_results: [
           Result.new(
             mode: :manual,
             status: :accepted,
             document_count: 3,
             metadata: %{index: Keyword.fetch!(config, :index_name)},
             task:
               Operations.task_from_backend(%{
                 uid: 21,
                 status: "enqueued",
                 indexUid: Keyword.fetch!(config, :index_name),
                 type: "documentAdditionOrUpdate"
               })
           ),
           Result.new(
             mode: :manual,
             status: :accepted,
             document_count: 2,
             metadata: %{index: Keyword.fetch!(config, :index_name)},
             task:
               Operations.task_from_backend(%{
                 uid: 22,
                 status: "enqueued",
                 indexUid: Keyword.fetch!(config, :index_name),
                 type: "documentAdditionOrUpdate"
               })
           ),
           Result.new(
             mode: :manual,
             status: :accepted,
             document_count: 2,
             metadata: %{index: Keyword.fetch!(config, :index_name)},
             task:
               Operations.task_from_backend(%{
                 uid: 23,
                 status: "enqueued",
                 indexUid: Keyword.fetch!(config, :index_name),
                 type: "documentAdditionOrUpdate"
               })
           )
         ]
       }}
    end
  end

  defmodule PassiveBackend do
    def index_name(schema_module, config) do
      RecordingMeilisearch.index_name(schema_module, config)
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
               meilisearch_client: RecordingTaskClient,
               meilisearch: RecordingMeilisearch,
               backfill: RecordingBackfill
             )

    assert_receive {:create_index, QueryablePost, :id, create_config}
    assert create_config[:target_index] == "posts_rebuild_v2"

    assert_receive {:apply_settings, QueryablePost, "posts_rebuild_v2", settings_config}
    assert settings_config[:target_index] == "posts_rebuild_v2"

    assert_receive {:backfill, QueryablePost, backfill_config}
    assert backfill_config[:index_name] == "posts_rebuild_v2"

    assert_receive {:swap_indexes, QueryablePost, swap_config}
    assert swap_config[:target_index] == "posts_rebuild_v2"
    assert_received {:task_wait, 10}
    assert_received {:task_wait, 11}
    assert_received {:task_wait, 21}
    assert_received {:task_wait, 22}
    assert_received {:task_wait, 23}
    assert_received {:task_wait, 12}
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
               meilisearch_client: RecordingTaskClient,
               meilisearch: RecordingMeilisearch,
               backfill: RecordingBackfill
             )

    refute_received {:swap_indexes, _, _}
    assert_receive {:create_index, QueryablePost, :id, _}
    assert_receive {:apply_settings, QueryablePost, "scrypath_queryable_post__reindex", _}
    assert_receive {:backfill, QueryablePost, backfill_config}
    assert backfill_config[:index_name] == "scrypath_queryable_post__reindex"
    assert_received {:task_wait, 10}
    assert_received {:task_wait, 11}
    assert_received {:task_wait, 21}
    assert_received {:task_wait, 22}
    assert_received {:task_wait, 23}
  end

  test "reindex exposes the workflow result fields operators need to inspect what happened" do
    assert {:ok, result} =
             Scrypath.reindex(QueryablePost,
               backend: RecordingMeilisearch,
               repo: Scrypath.BackfillTest.BackfillRepo,
               batch_size: 100,
               cutover?: false,
               meilisearch_client: RecordingTaskClient,
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

  test "reindex waits through seam-owned task references instead of backend identity" do
    assert {:ok, %{cutover: false, target_index: "passive_posts"}} =
             Scrypath.reindex(QueryablePost,
               backend: PassiveBackend,
               repo: Scrypath.BackfillTest.BackfillRepo,
               batch_size: 100,
               target_index: "passive_posts",
               cutover?: false,
               meilisearch_client: RecordingTaskClient,
               meilisearch: RecordingMeilisearch,
               backfill: RecordingBackfill
             )

    assert_receive {:create_index, QueryablePost, :id, create_config}
    assert create_config[:target_index] == "passive_posts"

    assert_receive {:apply_settings, QueryablePost, "passive_posts", _}
    assert_receive {:backfill, QueryablePost, backfill_config}
    assert backfill_config[:index_name] == "passive_posts"
    assert_received {:task_wait, 10}
    assert_received {:task_wait, 11}
    assert_received {:task_wait, 21}
    assert_received {:task_wait, 22}
    assert_received {:task_wait, 23}
  end

  test "reindex skips meilisearch polling for non-meilisearch seam tasks" do
    assert {:ok, %{cutover: false, target_index: "future_posts"}} =
             Scrypath.reindex(QueryablePost,
               backend: PassiveBackend,
               repo: Scrypath.BackfillTest.BackfillRepo,
               batch_size: 100,
               target_index: "future_posts",
               cutover?: false,
               meilisearch_client: RecordingTaskClient,
               meilisearch: FutureTaskBackend,
               backfill: RecordingBackfill
             )

    assert_receive {:create_index, QueryablePost, :id, create_config}
    assert create_config[:target_index] == "future_posts"
    assert_receive {:apply_settings, QueryablePost, "future_posts", _}
    assert_receive {:backfill, QueryablePost, backfill_config}
    assert backfill_config[:index_name] == "future_posts"
    refute_received {:task_wait, 110}
    refute_received {:task_wait, 111}
    refute_received {:task_wait, 112}
    assert_received {:task_wait, 21}
    assert_received {:task_wait, 22}
    assert_received {:task_wait, 23}
  end

  test "reindex normalizes raw meilisearch task maps before waiting" do
    assert {:ok, %{cutover: true, target_index: "raw_tasks_posts"}} =
             Scrypath.reindex(QueryablePost,
               backend: PassiveBackend,
               repo: Scrypath.BackfillTest.BackfillRepo,
               batch_size: 100,
               target_index: "raw_tasks_posts",
               meilisearch_client: RecordingTaskClient,
               meilisearch: RawTaskBackend,
               backfill: RecordingBackfill
             )

    assert_receive {:create_index, QueryablePost, :id, create_config}
    assert create_config[:target_index] == "raw_tasks_posts"
    assert_receive {:apply_settings, QueryablePost, "raw_tasks_posts", _}
    assert_receive {:backfill, QueryablePost, backfill_config}
    assert backfill_config[:index_name] == "raw_tasks_posts"
    assert_receive {:swap_indexes, QueryablePost, swap_config}
    assert swap_config[:target_index] == "raw_tasks_posts"
    assert_received {:task_wait, 210}
    assert_received {:task_wait, 211}
    assert_received {:task_wait, 21}
    assert_received {:task_wait, 22}
    assert_received {:task_wait, 23}
    assert_received {:task_wait, 212}
  end
end
