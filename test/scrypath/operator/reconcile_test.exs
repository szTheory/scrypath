defmodule Scrypath.Operator.ReconcileTest do
  use ExUnit.Case, async: true

  alias Scrypath.Operator.Reconcile
  alias Scrypath.Operator.RecoveryAction
  alias Scrypath.Operator.ReasonClassCounts

  defmodule ReconcileMeilisearchClient do
    def get_settings(_index, _config) do
      case Process.get(:reconcile_test_get_settings) do
        nil -> {:ok, %{}}
        resp -> resp
      end
    end

    def tasks(filters, config) do
      tasks =
        Keyword.get(config, :meilisearch_tasks, [])
        |> Enum.filter(fn task ->
          index_uid = task["indexUid"] || task[:indexUid] || task["index_uid"] || task[:index_uid]
          type = task["type"] || task[:type]
          index_uid in filters[:index_uids] and type in filters[:types]
        end)

      {:ok, %{results: tasks}}
    end
  end

  defmodule ReconcileObanInspector do
    def list_jobs(_schema_module, config) do
      {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end

  defmodule RecordingOban do
    def insert(changeset) do
      job = Ecto.Changeset.apply_changes(changeset)
      send(self(), {:oban_insert, job})
      {:ok, %{job | id: 1201, state: "available"}}
    end
  end

  test "reconcile_sync/2 returns a report-first view of failed work and reindex visibility" do
    assert {:ok, %Reconcile{} = report} =
             Scrypath.reconcile_sync(SearchablePost,
               backend: Scrypath.Meilisearch,
               sync_mode: :oban,
               index_prefix: "tenant",
               target_index: "tenant_searchable_post__reindex",
               meilisearch_url: "http://localhost:7700",
               meilisearch_client: ReconcileMeilisearchClient,
               meilisearch_tasks: [
                 %{
                   "uid" => 801,
                   "status" => "failed",
                   "type" => "documentAdditionOrUpdate",
                   "indexUid" => "tenant_searchable_post",
                   "error" => %{"message" => "write failed"}
                 },
                 %{
                   "uid" => 901,
                   "status" => "processing",
                   "type" => "documentAdditionOrUpdate",
                   "indexUid" => "tenant_searchable_post__reindex"
                 },
                 %{
                   "uid" => 902,
                   "status" => "succeeded",
                   "type" => "settingsUpdate",
                   "indexUid" => "tenant_searchable_post__reindex"
                 }
               ],
               oban: RecordingOban,
               oban_queue: :search_sync,
               oban_inspector: ReconcileObanInspector,
               oban_jobs: [
                 %{
                   id: 1001,
                   state: "retryable",
                   worker: "Scrypath.Oban.UpsertWorker",
                   queue: "search_sync",
                   args: %{
                     "operation" => "upsert",
                     "schema" => "Elixir.SearchablePost",
                     "backend" => "Elixir.Scrypath.Meilisearch",
                     "index" => "tenant_searchable_post",
                     "document_count" => 1,
                     "document_ids" => [1],
                     "documents" => [
                       %{"id" => 1, "data" => %{"title" => "One"}, "source" => "fields"}
                     ]
                   }
                 }
               ]
             )

    assert report.index == "tenant_searchable_post"
    assert Enum.member?(report.drift_signals, :failed_sync_work)
    assert Enum.member?(report.drift_signals, :reindex_in_progress)
    assert report.reindex.live_index == "tenant_searchable_post"
    assert report.reindex.target_index == "tenant_searchable_post__reindex"
    assert report.reindex.task_state == :pending
    assert Enum.any?(report.actions, &(&1.kind == :retry))
    assert Enum.any?(report.actions, &(&1.kind == :reindex))
    assert %ReasonClassCounts{} = report.failed_work_counts
    assert report.failed_work_counts.total == length(report.failed_work)

    assert MapSet.equal?(
             MapSet.new(Map.keys(report.failed_work_counts.by_class)),
             MapSet.new([
               :transport,
               :validation,
               :backend_rejected,
               :queue_exhausted,
               :unknown
             ])
           )

    assert report.index_contract_drift == nil

    refute_received {:oban_insert, _}
  end

  test "reconcile_sync/2 only mutates when an explicit action is provided" do
    action =
      RecoveryAction.new(
        kind: :retry,
        schema: SearchablePost,
        backend: Scrypath.Meilisearch,
        mode: :oban,
        operation: :delete,
        index: "tenant_searchable_post",
        reference: %{
          queue: "search_sync",
          payload: %{
            "operation" => "delete",
            "document_count" => 1,
            "document_ids" => ["post:7"]
          }
        }
      )

    assert {:ok, result} =
             Scrypath.reconcile_sync(SearchablePost,
               action: action,
               backend: Scrypath.Meilisearch,
               sync_mode: :oban,
               index_prefix: "tenant",
               oban: RecordingOban,
               oban_queue: :search_sync
             )

    assert result.mode == :oban
    assert_received {:oban_insert, job}
    assert job.worker == "Scrypath.Oban.DeleteWorker"
  end

  describe "index_contract_drift opt-in (Phase 27)" do
    alias Scrypath.Meilisearch.Settings
    alias Scrypath.Operator.IndexContractDrift.Report

    setup do
      on_exit(fn -> Process.delete(:reconcile_test_get_settings) end)
      :ok
    end

    test "default path leaves index_contract_drift nil (027-CONTEXT D-05)" do
      assert {:ok, %Reconcile{index_contract_drift: nil}} =
               Scrypath.reconcile_sync(SearchablePost,
                 backend: Scrypath.Meilisearch,
                 sync_mode: :manual,
                 index_prefix: "tenant",
                 meilisearch_url: "http://localhost:7700",
                 meilisearch_client: ReconcileMeilisearchClient,
                 meilisearch_tasks: []
               )
    end

    test "include_index_contract_drift: true attaches report from live settings stub" do
      config =
        Scrypath.Config.resolve!(
          backend: Scrypath.Meilisearch,
          sync_mode: :manual,
          index_prefix: "tenant",
          meilisearch_url: "http://localhost:7700",
          meilisearch_client: ReconcileMeilisearchClient
        )

      declared_wire =
        Settings.resolve(SearchablePost, config)
        |> Settings.translate_settings()

      applied =
        Map.merge(declared_wire, %{
          "searchableAttributes" =>
            SearchablePost |> Scrypath.schema_fields() |> Enum.map(&Atom.to_string/1),
          "filterableAttributes" =>
            SearchablePost.__scrypath__(:filterable) |> Enum.map(&Atom.to_string/1),
          "sortableAttributes" =>
            SearchablePost.__scrypath__(:sortable) |> Enum.map(&Atom.to_string/1),
          "faceting" => %{}
        })

      Process.put(:reconcile_test_get_settings, {:ok, applied})

      assert {:ok, %Reconcile{index_contract_drift: %Report{version: 1} = drift}} =
               Scrypath.reconcile_sync(SearchablePost,
                 backend: Scrypath.Meilisearch,
                 sync_mode: :manual,
                 index_prefix: "tenant",
                 meilisearch_url: "http://localhost:7700",
                 meilisearch_client: ReconcileMeilisearchClient,
                 meilisearch_tasks: [],
                 include_index_contract_drift: true
               )

      assert drift.dimensions.settings.match
    end

    test "include_index_contract_drift: true propagates index read failures" do
      Process.put(:reconcile_test_get_settings, {:error, {:http_error, 404, %{}}})

      assert {:error, :index_not_found} =
               Scrypath.reconcile_sync(SearchablePost,
                 backend: Scrypath.Meilisearch,
                 sync_mode: :manual,
                 index_prefix: "tenant",
                 meilisearch_url: "http://localhost:7700",
                 meilisearch_client: ReconcileMeilisearchClient,
                 meilisearch_tasks: [],
                 include_index_contract_drift: true
               )
    end
  end
end
