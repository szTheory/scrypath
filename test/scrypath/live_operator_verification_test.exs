defmodule Scrypath.LiveOperatorVerificationTest do
  use ExUnit.Case, async: false

  import Ecto.Query, only: [from: 2]

  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.TestSupport.IntegrationRepo
  alias Scrypath.TestSupport.MeilisearchIntegration

  @moduletag :integration
  @observer_process_key {__MODULE__, :request_observer_reference}

  defmodule RequestObserver do
    @observer_process_key {Scrypath.LiveOperatorVerificationTest, :request_observer_reference}

    def handle(_event_name, _measurements, metadata, {expected_owner, expected_ref}) do
      if self() == expected_owner and Process.get(@observer_process_key) == expected_ref do
        send(expected_owner, {
          :phase166_meilisearch_request,
          expected_ref,
          Map.take(metadata, [:method, :path, :index, :task_uid, :filters])
        })
      end
    end
  end

  setup_all do
    database = MeilisearchIntegration.setup_repo!()

    on_exit(fn ->
      MeilisearchIntegration.cleanup_repo!(database)
    end)

    :ok
  end

  setup do
    MeilisearchIntegration.reset_repo!()
    prefix = MeilisearchIntegration.index_prefix("scrypath-op")
    live_index = "#{prefix}_queryable_post"
    target_index = "#{live_index}__reindex"

    on_exit(fn ->
      MeilisearchIntegration.delete_indexes([live_index, target_index, "#{live_index}-candidate"])
    end)

    %{
      index_prefix: prefix,
      live_index: live_index,
      target_index: target_index
    }
  end

  test "sync_status/2 reports live backend visibility while keeping queue state unobserved outside oban mode",
       %{
         index_prefix: prefix,
         live_index: live_index
       } do
    MeilisearchIntegration.insert_posts!([
      %{
        id: 1,
        title: "Operator One",
        body: "Body One",
        status: "published",
        inserted_at: DateTime.utc_now()
      }
    ])

    assert {:ok, %{mode: :manual, task: %{uid: task_uid}}} =
             Scrypath.sync_record(
               QueryablePost,
               %QueryablePost{
                 id: 1,
                 title: "Operator One",
                 body: "Body One",
                 status: "published",
                 inserted_at: DateTime.utc_now()
               },
               backend: Scrypath.Meilisearch,
               index_prefix: prefix,
               sync_mode: :manual,
               meilisearch_url: MeilisearchIntegration.meilisearch_url!()
             )

    assert :ok = MeilisearchIntegration.wait_for_search_count!(QueryablePost, live_index, 1)

    deadline = System.monotonic_time(:millisecond) + 10_000

    MeilisearchIntegration.wait_until!(
      fn ->
        match?(
          {:ok,
           %Scrypath.Operator.Status{
             backend: %{
               last_succeeded: %Scrypath.Operator.State{id: ^task_uid, state: :completed}
             },
             queue: %{observed?: false}
           }},
          Scrypath.sync_status(QueryablePost,
            backend: Scrypath.Meilisearch,
            index_prefix: prefix,
            sync_mode: :manual,
            meilisearch_url: MeilisearchIntegration.meilisearch_url!()
          )
        )
      end,
      deadline,
      "expected sync_status/2 to surface completed backend visibility for #{live_index}"
    )
  end

  test "reconcile_sync/2 reports target-index visibility without mutating the live index by default",
       %{
         index_prefix: prefix,
         live_index: live_index,
         target_index: target_index
       } do
    MeilisearchIntegration.insert_posts!([
      %{
        id: 10,
        title: "Reconcile One",
        body: "Body Ten",
        status: "published",
        inserted_at: DateTime.utc_now()
      },
      %{
        id: 11,
        title: "Reconcile Two",
        body: "Body Eleven",
        status: "published",
        inserted_at: DateTime.utc_now()
      }
    ])

    assert {:ok, %{target_index: ^target_index, cutover: false}} =
             Scrypath.reindex(QueryablePost,
               backend: Scrypath.Meilisearch,
               repo: IntegrationRepo,
               batch_size: 1,
               index_prefix: prefix,
               cutover?: false,
               meilisearch_url: MeilisearchIntegration.meilisearch_url!()
             )

    assert MeilisearchIntegration.index_exists?(target_index)
    refute MeilisearchIntegration.index_exists?(live_index)

    deadline = System.monotonic_time(:millisecond) + 10_000

    report =
      MeilisearchIntegration.wait_until!(
        fn ->
          case Scrypath.reconcile_sync(QueryablePost,
                 backend: Scrypath.Meilisearch,
                 index_prefix: prefix,
                 sync_mode: :manual,
                 target_index: target_index,
                 meilisearch_url: MeilisearchIntegration.meilisearch_url!()
               ) do
            {:ok,
             %Scrypath.Operator.Reconcile{
               reindex: %Scrypath.Operator.Reconcile.ReindexVisibility{observed?: true} = reindex
             } = report} ->
              {:ok, report, reindex}

            _other ->
              false
          end
        end,
        deadline,
        "expected reconcile_sync/2 to observe reindex visibility for #{target_index}"
      )

    assert {:ok, %Scrypath.Operator.Reconcile{} = reconcile, reindex} = report
    assert reconcile.index == live_index
    assert reindex.live_index == live_index
    assert reindex.target_index == target_index
    assert reindex.task_state in [:pending, :completed]
    assert reindex.cutover == :not_started
    assert MeilisearchIntegration.index_exists?(target_index)
    refute MeilisearchIntegration.index_exists?(live_index)
  end

  @tag :bounded_repair
  test "bounded manual repair restores the selected raw document", %{
    index_prefix: prefix,
    live_index: live_index,
    target_index: target_index
  } do
    token = unique_repair_token()
    [target, source_only, visible_control] = repair_records(token)
    source_rows = [target, source_only, visible_control]
    MeilisearchIntegration.insert_posts!(Enum.map(source_rows, &post_row/1))

    target_source = IntegrationRepo.get!(QueryablePost, target.id)
    source_only_before = IntegrationRepo.get!(QueryablePost, source_only.id)
    visible_control_before = IntegrationRepo.get!(QueryablePost, visible_control.id)
    sync_options = sync_options(prefix)
    search_options = search_options(prefix)

    {setup_result, setup_events} =
      observe_meilisearch_requests(fn ->
        Scrypath.sync_records(
          QueryablePost,
          [target_source, visible_control_before],
          sync_options
        )
      end)

    assert {:ok, %{document_ids: [target_id, control_id], task: %{uid: setup_uid} = setup_task}} =
             setup_result

    assert target_id == target.id
    assert control_id == visible_control.id
    assert is_integer(setup_uid)
    assert setup_task.index_uid == live_index

    assert Enum.any?(setup_events, fn event ->
             event.method == :post and event.path == "/indexes/#{live_index}/documents" and
               event.index == live_index
           end),
           "request observer must capture the calibrated setup write"

    assert {:ok, setup_terminal} = Tasks.wait_for_task(setup_task, sync_options)
    assert setup_terminal.id == setup_uid
    assert setup_terminal.state == :succeeded
    assert setup_terminal.reference.index_uid == live_index

    assert :ok =
             wait_for_raw_ids!(token, search_options, MapSet.new([target.id, visible_control.id]))

    initial_hits = search_raw_hits!(token, search_options)

    assert MapSet.new(Enum.map(initial_hits, &raw_id!/1)) ==
             MapSet.new([target.id, visible_control.id])

    assert raw_projection(initial_hits, target.id) == expected_projection(target)

    assert raw_projection(initial_hits, visible_control.id) ==
             expected_projection(visible_control)

    refute Enum.any?(initial_hits, &(raw_id!(&1) == source_only.id))

    assert IntegrationRepo.get!(QueryablePost, target.id) == target_source

    assert {:ok, %{task: %{uid: deletion_uid} = deletion_task}} =
             Scrypath.delete_document(QueryablePost, target.id, sync_options)

    assert is_integer(deletion_uid)
    assert deletion_task.index_uid == live_index
    assert {:ok, deletion_terminal} = Tasks.wait_for_task(deletion_task, sync_options)
    assert deletion_terminal.id == deletion_uid
    assert deletion_terminal.state == :succeeded
    assert deletion_terminal.reference.index_uid == live_index
    assert IntegrationRepo.get!(QueryablePost, target.id) == target_source

    assert :ok = wait_for_raw_ids!(token, search_options, MapSet.new([visible_control.id]))
    missing_hits = search_raw_hits!(token, search_options)
    assert MapSet.new(Enum.map(missing_hits, &raw_id!/1)) == MapSet.new([visible_control.id])

    assert raw_projection(missing_hits, visible_control.id) ==
             expected_projection(visible_control)

    refute Enum.any?(missing_hits, &(raw_id!(&1) in [target.id, source_only.id]))

    task_config = task_options()
    indices = [live_index, target_index]
    tasks_before_report = task_snapshots!(indices, task_config)

    {{:ok, report}, report_events} =
      observe_meilisearch_requests(fn ->
        Scrypath.reconcile_sync(QueryablePost,
          backend: Scrypath.Meilisearch,
          index_prefix: prefix,
          sync_mode: :manual,
          target_index: target_index,
          meilisearch_url: MeilisearchIntegration.meilisearch_url!()
        )
      end)

    assert report.index == live_index
    assert report.reindex.live_index == live_index
    assert report.reindex.target_index == target_index
    assert report.reindex.task_state == :idle
    assert report.actions == []

    assert Enum.any?(report_events, fn event ->
             event.method == :get and event.path == "/tasks" and
               request_filters_index?(event, live_index)
           end),
           "report observer must capture the expected live task-history read"

    refute Enum.any?(report_events, &mutation_request?/1),
           "no-action reconcile must not issue a mutation request"

    tasks_after_report = task_snapshots!(indices, task_config)
    assert tasks_after_report == tasks_before_report

    assert :ok = wait_for_raw_ids!(token, search_options, MapSet.new([visible_control.id]))
    assert search_raw_hits!(token, search_options) == missing_hits

    selected_ids = [target.id]
    selected_query = from(post in QueryablePost, where: post.id in ^selected_ids)

    assert {:ok,
            %{
              index: ^live_index,
              documents: 1,
              batches: 1,
              mode: :manual,
              batch_results: [%{index: ^live_index, documents: 1, task: first_task}]
            }} =
             Scrypath.backfill(QueryablePost,
               backend: Scrypath.Meilisearch,
               repo: IntegrationRepo,
               query: selected_query,
               batch_size: 1,
               sync_mode: :manual,
               index_prefix: prefix,
               meilisearch_url: MeilisearchIntegration.meilisearch_url!()
             )

    assert_repair_task!(first_task, live_index, task_config)

    assert :ok =
             wait_for_raw_ids!(token, search_options, MapSet.new([target.id, visible_control.id]))

    repaired_hits = search_raw_hits!(token, search_options)

    assert MapSet.new(Enum.map(repaired_hits, &raw_id!/1)) ==
             MapSet.new([target.id, visible_control.id])

    assert raw_projection(repaired_hits, target.id) == expected_projection(target)

    assert raw_projection(repaired_hits, visible_control.id) ==
             expected_projection(visible_control)

    refute Enum.any?(repaired_hits, &(raw_id!(&1) == source_only.id))

    assert IntegrationRepo.get!(QueryablePost, source_only.id) == source_only_before
    assert IntegrationRepo.get!(QueryablePost, visible_control.id) == visible_control_before
    assert IntegrationRepo.get!(QueryablePost, target.id) == target_source
  end

  defp sync_options(prefix) do
    [
      backend: Scrypath.Meilisearch,
      index_prefix: prefix,
      sync_mode: :manual,
      meilisearch_url: MeilisearchIntegration.meilisearch_url!(),
      inline_poll_interval: 100,
      inline_timeout: 10_000
    ]
  end

  defp task_options do
    [
      meilisearch_url: MeilisearchIntegration.meilisearch_url!(),
      inline_poll_interval: 100,
      inline_timeout: 10_000,
      task_history_limit: 100
    ]
  end

  defp search_options(prefix) do
    [
      backend: Scrypath.Meilisearch,
      index_prefix: prefix,
      page: [number: 1, size: 20],
      meilisearch_url: MeilisearchIntegration.meilisearch_url!()
    ]
  end

  defp repair_records(token) do
    first_id = 166_000_000 + System.unique_integer([:positive, :monotonic]) * 10

    [
      %QueryablePost{
        id: first_id,
        title: "Phase 166 #{token} target",
        body: "target projection for #{token}",
        status: "published"
      },
      %QueryablePost{
        id: first_id + 1,
        title: "Phase 166 #{token} source-only control",
        body: "source-only projection for #{token}",
        status: "published"
      },
      %QueryablePost{
        id: first_id + 2,
        title: "Phase 166 #{token} visible control",
        body: "visible control projection for #{token}",
        status: "published"
      }
    ]
  end

  defp post_row(%QueryablePost{} = post) do
    %{
      id: post.id,
      title: post.title,
      body: post.body,
      status: post.status,
      inserted_at: DateTime.utc_now()
    }
  end

  defp unique_repair_token do
    "phase166repair#{System.unique_integer([:positive, :monotonic])}"
  end

  defp search_raw_hits!(token, options) do
    assert {:ok, %Scrypath.SearchResult{hits: hits}} =
             Scrypath.search(QueryablePost, token, options)

    hits
  end

  defp wait_for_raw_ids!(token, options, expected_ids) do
    deadline = System.monotonic_time(:millisecond) + 10_000

    MeilisearchIntegration.wait_until!(
      fn ->
        case Scrypath.search(QueryablePost, token, options) do
          {:ok, %Scrypath.SearchResult{hits: hits}} ->
            MapSet.new(Enum.map(hits, &raw_id!/1)) == expected_ids

          {:error, _reason} ->
            false
        end
      end,
      deadline,
      "expected raw search IDs #{inspect(MapSet.to_list(expected_ids))}"
    )
  end

  defp raw_id!(hit) do
    case Map.fetch(hit, "id") do
      {:ok, id} -> id
      :error -> Map.fetch!(hit, :id)
    end
  end

  defp raw_projection(hits, id) do
    hit = Enum.find(hits, &(raw_id!(&1) == id))
    assert is_map(hit)
    Map.take(hit, ["id", "title", "body"])
  end

  defp expected_projection(%QueryablePost{id: id, title: title, body: body}) do
    %{"id" => id, "title" => title, "body" => body}
  end

  defp assert_repair_task!(task, expected_index, task_config) do
    assert is_integer(task.uid)
    assert task.status in [:enqueued, :processing]
    assert task.index_uid == expected_index

    assert {:ok, terminal_task} = Tasks.wait_for_task(task, task_config)
    assert terminal_task.id == task.uid
    assert terminal_task.state == :succeeded
    assert terminal_task.reference.index_uid == expected_index
    terminal_task
  end

  defp task_snapshots!(indices, config) do
    Map.new(indices, fn index ->
      assert {:ok, sync_tasks} = Tasks.list_sync_tasks(index, config)
      assert {:ok, index_tasks} = Tasks.list_index_tasks(index, config)

      snapshot =
        (sync_tasks ++ index_tasks)
        |> Enum.uniq_by(& &1.id)
        |> Enum.map(fn task ->
          %{
            uid: task.id,
            state: task.state,
            index_uid: Map.get(task.reference, :index_uid),
            type: Map.get(task.metadata, :type)
          }
        end)
        |> Enum.sort_by(& &1.uid)

      {index, snapshot}
    end)
  end

  defp observe_meilisearch_requests(fun) when is_function(fun, 0) do
    owner = self()
    correlation_ref = make_ref()
    handler_id = {__MODULE__, owner, correlation_ref}
    previous_ref = Process.get(@observer_process_key, :observer_not_set)

    :ok =
      :telemetry.attach_many(
        handler_id,
        [[:scrypath, :meilisearch, :request, :start]],
        &RequestObserver.handle/4,
        {owner, correlation_ref}
      )

    Process.put(@observer_process_key, correlation_ref)

    try do
      result = fun.()
      {result, collect_observed_requests(correlation_ref, [])}
    after
      if previous_ref == :observer_not_set do
        Process.delete(@observer_process_key)
      else
        Process.put(@observer_process_key, previous_ref)
      end

      :telemetry.detach(handler_id)
    end
  end

  defp collect_observed_requests(correlation_ref, acc) do
    receive do
      {:phase166_meilisearch_request, ^correlation_ref, event} ->
        collect_observed_requests(correlation_ref, [event | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp request_filters_index?(event, index) do
    event
    |> Map.get(:filters, [])
    |> Keyword.get(:index_uids, [])
    |> Enum.member?(index)
  end

  defp mutation_request?(event), do: event.method in [:post, :put, :patch, :delete]
end
