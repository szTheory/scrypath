defmodule Scrypath.ReindexTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  def capture_reindex_event(event, measurements, metadata, parent) do
    send(parent, {:telemetry_event, event, measurements, metadata})
  end

  def capture_settings_verified(event, measurements, metadata, parent) do
    send(parent, {:telemetry_span, event, measurements, metadata})
  end

  defmodule ReindexRankingFullSchema do
    use Ecto.Schema

    use Scrypath,
      fields: [:title],
      settings: %{
        ranking_rules: [:words, :typo, :proximity, :attribute, :sort, :exactness]
      }

    schema "reindex_ranking_full" do
      field(:title, :string)
    end
  end

  defmodule ReindexRankingPartialSchema do
    use Ecto.Schema

    use Scrypath,
      fields: [:title],
      settings: %{ranking_rules: [:typo, :proximity]}

    schema "reindex_ranking_partial" do
      field(:title, :string)
    end
  end

  defmodule ReindexRankingPartialOptOutSchema do
    use Ecto.Schema

    use Scrypath,
      fields: [:title],
      settings: %{
        ranking_rules: [:typo, :proximity],
        ranking_rules_strict?: false
      }

    schema "reindex_ranking_partial_opt_out" do
      field(:title, :string)
    end
  end

  defmodule ReindexRankingSynonymsOnlySchema do
    use Ecto.Schema

    use Scrypath,
      fields: [:title],
      settings: %{synonyms: [["nyc", "new york"]]}

    schema "reindex_ranking_synonyms_only" do
      field(:title, :string)
    end
  end

  defmodule ReindexRankingExtraSchema do
    use Ecto.Schema

    use Scrypath,
      fields: [:title],
      settings: %{
        ranking_rules: [
          :words,
          :typo,
          :proximity,
          :attribute,
          :sort,
          :exactness,
          "custom:asc"
        ]
      }

    schema "reindex_ranking_extra" do
      field(:title, :string)
    end
  end

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
    alias Scrypath.Meilisearch.Settings

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

    def get_settings(index, config) do
      send(self(), {:get_settings, index, config})

      cond do
        response = Keyword.get(config, :__get_settings_response__) ->
          response

        schema = Keyword.get(config, :_scrypath_schema) ->
          wire =
            schema
            |> Settings.resolve(config)
            |> Settings.translate_settings()

          {:ok, wire}

        true ->
          {:ok, %{}}
      end
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

    assert_receive {:get_settings, "posts_rebuild_v2", verify_config}
    assert verify_config[:target_index] == "posts_rebuild_v2"

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
    assert_receive {:get_settings, "scrypath_queryable_post__reindex", _}
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
    assert_receive {:get_settings, "passive_posts", _}
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
    assert_receive {:get_settings, "future_posts", _}
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
    assert_receive {:get_settings, "raw_tasks_posts", _}
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

  describe "verify step (TUNE-03, TUNE-05, D-03)" do
    @base [
      backend: RecordingMeilisearch,
      repo: Scrypath.BackfillTest.BackfillRepo,
      batch_size: 100,
      meilisearch_client: RecordingTaskClient,
      meilisearch: RecordingMeilisearch,
      backfill: RecordingBackfill,
      cutover?: false,
      meilisearch_url: "http://localhost:7700"
    ]

    test "settings drift blocks cutover" do
      drift_opts =
        @base ++
          [
            target_index: "drift_posts",
            settings: %{synonyms: [["nyc", "new york"]]}
          ]

      {extra, core} = Keyword.split(drift_opts, [:__get_settings_response__])
      core = Keyword.drop(core, [:meilisearch, :backfill])
      validated = Scrypath.Options.validate_reindex_options!(core) |> Keyword.merge(extra)

      declared_wire =
        QueryablePost
        |> Scrypath.Meilisearch.Settings.resolve(validated)
        |> Scrypath.Meilisearch.Settings.translate_settings()

      bad_wire = Map.put(declared_wire, "synonyms", %{"nyc" => ["wrong"]})

      assert {:error, {:settings_drift, drift}} =
               Scrypath.reindex(
                 QueryablePost,
                 drift_opts ++ [__get_settings_response__: {:ok, bad_wire}]
               )

      assert drift != []
      refute_received {:swap_indexes, _, _}
    end

    test "verify transport error other than drift short-circuits reindex" do
      assert {:error, :econnrefused} =
               Scrypath.reindex(
                 QueryablePost,
                 @base ++
                   [
                     target_index: "conn_posts",
                     __get_settings_response__: {:error, :econnrefused}
                   ]
               )

      refute_received {:swap_indexes, _, _}
    end

    test "skip_settings_verification? skips verify and emits telemetry + warning" do
      parent = self()
      handler_id = "reindex-test-verify-skipped-#{System.unique_integer([:positive])}"

      :ok =
        :telemetry.attach(
          handler_id,
          [:scrypath, :reindex, :verify_skipped],
          &__MODULE__.capture_reindex_event/4,
          parent
        )

      log =
        capture_log(fn ->
          assert {:ok, %{}} =
                   Scrypath.reindex(
                     QueryablePost,
                     @base ++
                       [
                         target_index: "skip_verify_posts",
                         skip_settings_verification?: true
                       ]
                   )
        end)

      assert log =~ "skip_settings_verification?"

      assert_receive {:telemetry_event, [:scrypath, :reindex, :verify_skipped], %{},
                      %{reason: :user_opt_out}}

      refute_received {:get_settings, _, _}
      :telemetry.detach(handler_id)
    end

    test "successful verify emits settings_verified span" do
      parent = self()
      handler_id = "reindex-test-settings-verified-#{System.unique_integer([:positive])}"

      :ok =
        :telemetry.attach_many(
          handler_id,
          [
            [:scrypath, :reindex, :settings_verified, :start],
            [:scrypath, :reindex, :settings_verified, :stop]
          ],
          &__MODULE__.capture_settings_verified/4,
          parent
        )

      assert {:ok, %{}} =
               Scrypath.reindex(
                 QueryablePost,
                 @base ++ [target_index: "verify_ok_posts"]
               )

      assert_receive {:telemetry_span, [:scrypath, :reindex, :settings_verified, :start], _, _}

      assert_receive {:telemetry_span, [:scrypath, :reindex, :settings_verified, :stop], _,
                      %{result: :parity}}

      :telemetry.detach(handler_id)
    end

    test "index not found on verify surfaces to caller" do
      assert {:error, :index_not_found} =
               Scrypath.reindex(
                 QueryablePost,
                 @base ++
                   [
                     target_index: "missing_posts",
                     __get_settings_response__: {:error, {:http_error, 404, "x"}}
                   ]
               )
    end
  end

  describe "ranking_rules reindex-time safety rail (TUNE-04)" do
    @base [
      backend: RecordingMeilisearch,
      repo: Scrypath.BackfillTest.BackfillRepo,
      batch_size: 100,
      meilisearch_client: RecordingTaskClient,
      meilisearch: RecordingMeilisearch,
      backfill: RecordingBackfill,
      cutover?: false,
      meilisearch_url: "http://localhost:7700"
    ]

    test "full default ranking_rules passes guard" do
      assert {:ok, _} = Scrypath.reindex(ReindexRankingFullSchema, @base ++ [target_index: "rf1"])
    end

    test "partial ranking with strict opt-out passes" do
      assert {:ok, _} =
               Scrypath.reindex(ReindexRankingPartialOptOutSchema, @base ++ [target_index: "rf2"])
    end

    test "partial ranking without opt-out raises before with chain" do
      err =
        assert_raise ArgumentError, fn ->
          Scrypath.reindex(ReindexRankingPartialSchema, @base ++ [target_index: "rf3"])
        end

      assert err.message =~ "ranking_rules is missing"
      assert err.message =~ "words"
      assert err.message =~ "ranking_rules_strict?: false"
    end

    test "schema without ranking_rules key skips guard" do
      assert {:ok, _} =
               Scrypath.reindex(ReindexRankingSynonymsOnlySchema, @base ++ [target_index: "rf4"])
    end

    test "extra ranking rules beyond defaults are allowed" do
      assert {:ok, _} =
               Scrypath.reindex(ReindexRankingExtraSchema, @base ++ [target_index: "rf5"])
    end
  end
end
