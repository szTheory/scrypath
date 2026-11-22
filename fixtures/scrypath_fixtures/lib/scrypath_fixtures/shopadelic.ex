defmodule ScrypathFixtures.Shopadelic do
  @moduledoc """
  Shopadelic scenarios. Shopadelic is a fictional online-shop product; the data is for development
  and tests only, Scrypath-owned, and no record is copied from a real product.

  Three named states, all ordinary (none is a stress case):

    * `:settings_aligned` is a healthy install: succeeded task history, completed jobs, nothing
      pending or failed, and the index settings equal what the schema declares.
    * `:settings_drift` is the same install after the index's `filterableAttributes` lost
      `storeId`: `Scrypath.index_contract_drift/2` reports `only_declared: "storeId"`. This is
      drift of the whole index's settings against its schema, the only kind Scrypath reports.
    * `:failed_journey` is the entry state for the failed-work journey: one failed Meilisearch
      task and four Oban jobs that need a decision (a discarded upsert, a retryable upsert, a
      cancelled upsert and a discarded delete).

  Every failure text comes from `ScrypathFixtures.Failures`. Everything is built from raw wire
  shapes, so the real `Scrypath.sync_status/2` and `Scrypath.failed_sync_work/2` do the
  normalizing and only reachable states exist.
  """

  alias ScrypathFixtures.AppliedSettings
  alias ScrypathFixtures.FakeMeilisearchClient
  alias ScrypathFixtures.FakeObanInspector
  alias ScrypathFixtures.Meili
  alias ScrypathFixtures.ObanJob
  alias ScrypathFixtures.Scenario
  alias ScrypathFixtures.Shopadelic.Product

  # Scrypath has no default Oban queue (`oban_queue` defaults to nil), so the name is Shopadelic's
  # own choice.
  @queue :shopadelic_sync
  @index_prefix "shopadelic"

  @states [:settings_aligned, :settings_drift, :failed_journey]

  # The document id Meilisearch rejects in the failed task: a space and a slash.
  @bad_document_id "SPD 2041/B"

  @doc "The state names `scenario/2` builds."
  @spec states() :: [:settings_aligned | :settings_drift | :failed_journey]
  def states, do: @states

  @doc "Builds one named Shopadelic scenario at `now`."
  @spec scenario(:settings_aligned | :settings_drift | :failed_journey, keyword()) ::
          Scenario.t()
  def scenario(state, now: %DateTime{} = now) when state in @states do
    {settings_state, label, expect} = describe(state)

    base_opts = [
      backend: Scrypath.Meilisearch,
      sync_mode: :oban,
      oban_queue: @queue,
      index_prefix: @index_prefix,
      meilisearch_url: AppliedSettings.url(settings_state),
      meilisearch_client: FakeMeilisearchClient,
      oban_inspector: FakeObanInspector
    ]

    runtime_config = base_opts |> Scenario.runtime_opts() |> Scrypath.Config.resolve!()
    max_attempts = Scrypath.Config.oban_max_attempts(runtime_config)
    index = Scrypath.Meilisearch.index_name(Product, index_prefix: @index_prefix)

    %Scenario{
      id: :"shopadelic_#{state}",
      adopter: :shopadelic,
      label: label,
      kind: :ordinary,
      now: now,
      allowlist: [Product],
      scrypath_opts:
        base_opts ++
          [
            meilisearch_tasks: tasks(state, now, index, settings_state),
            oban_jobs: jobs(state, now, index, max_attempts)
          ],
      expect: expect
    }
  end

  # {which applied settings the scenario's URL serves, label, expectations}
  defp describe(:settings_aligned) do
    {:shopadelic_aligned, "Shopadelic products, settings aligned (fictional)",
     %{
       sync_status: :ok,
       failed_sync_work: :ok,
       index_contract_drift: :ok,
       posture: %{state: :ok, headline: "No sync failures found"}
     }}
  end

  defp describe(:settings_drift) do
    {:shopadelic_drift, "Shopadelic products, settings drift (fictional)",
     %{
       sync_status: :ok,
       failed_sync_work: :ok,
       index_contract_drift: :ok,
       posture: %{state: :ok, headline: "No sync failures found"}
     }}
  end

  defp describe(:failed_journey) do
    {:shopadelic_aligned, "Shopadelic products, failed journey (fictional)",
     %{
       sync_status: :ok,
       failed_sync_work: :ok,
       index_contract_drift: :ok,
       posture: %{state: :degraded, headline: "Sync jobs and Meilisearch tasks failed"}
     }}
  end

  # -- Meilisearch tasks -----------------------------------------------------------------------

  defp tasks(state, now, index, settings_state) do
    history(now, index, settings_state) ++ failed_tasks(state, now, index)
  end

  # The index was created five days ago and its settings applied just after; then 38 batches of
  # product updates and two deletes landed over the last twelve hours.
  defp history(now, index, settings_state) do
    creation =
      Meili.task(%{
        type: "indexCreation",
        status: "succeeded",
        uid: 1,
        index_uid: index,
        now: now,
        enqueued_ago: 432_000,
        primary_key: "id"
      })

    settings =
      Meili.task(%{
        type: "settingsUpdate",
        status: "succeeded",
        uid: 2,
        index_uid: index,
        now: now,
        enqueued_ago: 431_900,
        # A settings task echoes what it was sent: the drifted index only ever got `status`.
        details: %{"filterableAttributes" => applied_filterable(settings_state)}
      })

    additions =
      for n <- 3..40 do
        Meili.task(%{
          type: "documentAdditionOrUpdate",
          status: "succeeded",
          uid: n,
          index_uid: index,
          now: now,
          enqueued_ago: 43_200 - n * 1_000,
          documents: rem(n, 3) + 1
        })
      end

    deletes =
      for n <- 41..42 do
        Meili.task(%{
          type: "documentDeletion",
          status: "succeeded",
          uid: n,
          index_uid: index,
          now: now,
          enqueued_ago: 2_000 - n * 10
        })
      end

    [creation, settings | additions] ++ deletes
  end

  defp applied_filterable(:shopadelic_drift), do: ["status"]
  defp applied_filterable(_aligned), do: ["status", "storeId"]

  defp failed_tasks(:failed_journey, now, index) do
    [
      Meili.task(%{
        type: "documentAdditionOrUpdate",
        status: "failed",
        uid: 43,
        index_uid: index,
        now: now,
        enqueued_ago: 5_400,
        failure: {:invalid_document_id, id: @bad_document_id}
      })
    ]
  end

  defp failed_tasks(_state, _now, _index), do: []

  # -- Oban jobs -------------------------------------------------------------------------------

  # Twelve completed upserts and nothing waiting, in every state.
  defp jobs(state, now, index, max_attempts) do
    completed =
      for n <- 1..12 do
        job(now, index, max_attempts, n, "completed", :upsert,
          ago: 3_600 - n * 200,
          attempt: 1,
          ids: ["SPD-#{n}", "SPD-#{n + 100}"]
        )
      end

    completed ++ journey_jobs(state, now, index, max_attempts)
  end

  defp journey_jobs(:failed_journey, now, index, max_attempts) do
    delete_ids = ["SPD-2077"]

    [
      # Discarded: every attempt hit a transport error, the last one at max_attempts.
      job(now, index, max_attempts, 101, "discarded", :upsert,
        ago: 7_200,
        attempt: max_attempts,
        ids: ["SPD-2041", "SPD-2042"],
        errors: transport_errors(now, 7_200, max_attempts)
      ),
      # Retryable: third attempt failed, the fourth is eight minutes away.
      job(now, index, max_attempts, 102, "retryable", :upsert,
        ago: 120,
        attempt: 3,
        scheduled_in: 480,
        ids: ["SPD-2043"],
        errors: transport_errors(now, 120, 3)
      ),
      # Cancelled on its first attempt: the node that ran it had not loaded the schema module
      # yet (a rolling deploy), so the worker refused the arguments rather than retry.
      job(now, index, max_attempts, 103, "cancelled", :upsert,
        ago: 5_400,
        attempt: 1,
        ids: ["SPD-2044"],
        errors: [{:oban_cancel_invalid_job, 1, [schema: Product]}]
      ),
      # Discarded delete: each attempt's deletion task failed on Meilisearch's side.
      job(now, index, max_attempts, 104, "discarded", :delete,
        ago: 9_000,
        attempt: max_attempts,
        ids: delete_ids,
        errors: task_failed_errors(now, index, 9_000, max_attempts)
      )
    ]
  end

  defp journey_jobs(_state, _now, _index, _max_attempts), do: []

  # One error entry per attempt, the earlier attempts further back (a flat ten minutes apart).
  defp transport_errors(now, last_ago, attempts) do
    for n <- 1..attempts do
      {:oban_transport, n, [at: attempt_time(now, last_ago, attempts, n)]}
    end
  end

  # Each attempt's deletion task failed with a table entry's error, so the stored text embeds
  # that raw failed task. Deleting from an index that is not there is the one failure the table
  # has for a deletion task.
  defp task_failed_errors(now, index, last_ago, attempts) do
    for n <- 1..attempts do
      task =
        Meili.task(%{
          type: "documentDeletion",
          status: "failed",
          uid: 900 + n,
          index_uid: index,
          now: now,
          enqueued_ago: last_ago + (attempts - n) * 600,
          failure: {:index_not_found_task, uid: index}
        })

      {:oban_task_failed, n, [at: attempt_time(now, last_ago, attempts, n), task: task]}
    end
  end

  defp attempt_time(now, last_ago, attempts, n),
    do: DateTime.add(now, -(last_ago + (attempts - n) * 600), :second)

  defp job(now, index, max_attempts, id, state, role, opts) do
    {ids, opts} = Keyword.pop!(opts, :ids)
    operation = if role == :delete, do: "delete", else: "upsert"

    ObanJob.job(
      Map.merge(
        %{
          id: id,
          state: state,
          worker: role,
          queue: Atom.to_string(@queue),
          now: now,
          max_attempts: max_attempts,
          args: %{
            "operation" => operation,
            "schema" => Atom.to_string(Product),
            "backend" => Atom.to_string(Scrypath.Meilisearch),
            "index" => index,
            "sync_mode" => "oban",
            "document_ids" => ids,
            "document_count" => length(ids)
          }
        },
        Map.new(opts)
      )
    )
  end
end
