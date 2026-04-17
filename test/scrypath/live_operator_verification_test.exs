defmodule Scrypath.LiveOperatorVerificationTest do
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

  test "sync_status/2 reports live backend visibility while keeping queue state unobserved outside oban mode", %{
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
             backend: %{last_succeeded: %Scrypath.Operator.State{id: ^task_uid, state: :completed}},
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

  test "reconcile_sync/2 reports target-index visibility without mutating the live index by default", %{
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
end
