defmodule ScrypathFixtures.Logistify do
  @moduledoc """
  Logistify scenarios. Logistify is a fictional freight-tracking product; the data is for
  development and tests only.

  Fictional adopter: Scrypath-owned data, no records copied from any other project.

  Three named states, built from raw wire shapes only, so the real `Scrypath.sync_status/2` and
  `Scrypath.failed_sync_work/2` do the normalizing:

    * `:deep_queue` is a busy but healthy install: a long Oban queue and a few enqueued
      Meilisearch tasks, with nothing failed. It is read as pending work.
    * `:steady` is a quiet healthy install: a few hundred succeeded tasks, only completed jobs,
      nothing waiting and nothing failed. It is read as clear.
    * `:history_over_limit` is a stress variation and never ordinary data. Its task history is
      longer than the 1,000 tasks Scrypath reads, so `Scrypath.sync_status/2` returns
      `{:error, {:task_history_truncated, ...}}`. That renders finding F1, a known defect handed to
      the maintainer and not fixed in this phase; a story that shows it must say so.
  """

  alias ScrypathFixtures.AppliedSettings
  alias ScrypathFixtures.Bulk
  alias ScrypathFixtures.FakeMeilisearchClient
  alias ScrypathFixtures.FakeObanInspector
  alias ScrypathFixtures.Logistify.Shipment
  alias ScrypathFixtures.Meili
  alias ScrypathFixtures.ObanJob
  alias ScrypathFixtures.Scenario

  # Scrypath has no default Oban queue (`oban_queue` defaults to nil and is required for
  # `sync_mode: :oban`; research N10), so the queue name is Logistify's own choice.
  @queue :logistify_sync

  @index_prefix "logistify"

  # The seed of the ordinary shipment records `ScrypathFixtures.Bulk` picks (the Phase 196 number).
  @bulk_seed 196

  # Every ordinary Logistify state reads clean: nothing failed, applied settings equal the schema.
  @clean_expect %{
    sync_status: :ok,
    failed_sync_work: :ok,
    index_contract_drift: :ok,
    posture: %{state: :ok, headline: "No sync failures found"}
  }

  @doc "The state names `scenario/2` builds."
  @spec states() :: [:deep_queue | :steady | :history_over_limit]
  def states, do: [:deep_queue, :steady, :history_over_limit]

  @doc "Builds one named Logistify scenario at `now`."
  @spec scenario(:deep_queue | :steady | :history_over_limit, keyword()) :: Scenario.t()
  def scenario(:deep_queue, now: %DateTime{} = now) do
    {index, max_attempts} = context()

    build(now, %{
      id: :logistify_deep_queue,
      label: "Logistify shipments, deep queue (fictional)",
      kind: :ordinary,
      tasks: deep_queue_tasks(now, index),
      jobs: deep_queue_jobs(now, index, max_attempts),
      expect: @clean_expect
    })
  end

  def scenario(:steady, now: %DateTime{} = now) do
    {index, max_attempts} = context()

    build(now, %{
      id: :logistify_steady,
      label: "Logistify shipments, steady (fictional)",
      kind: :ordinary,
      tasks: steady_tasks(now, index),
      jobs: steady_jobs(now, index, max_attempts),
      expect: @clean_expect
    })
  end

  def scenario(:history_over_limit, now: %DateTime{} = now) do
    {index, max_attempts} = context()

    build(now, %{
      id: :logistify_history_over_limit_f1,
      label:
        "Logistify shipments, stress: task history over 1,000 reproduces finding F1 (fictional)",
      kind: :stress,
      tasks: over_limit_tasks(now, index),
      jobs: deep_queue_jobs(now, index, max_attempts),
      expect: %{
        sync_status: {:error, :task_history_truncated},
        failed_sync_work: {:error, :task_history_truncated},
        index_contract_drift: :ok,
        posture: %{state: :degraded, headline: "Search health could not be fully checked"}
      }
    })
  end

  defp base_opts do
    [
      backend: Scrypath.Meilisearch,
      sync_mode: :oban,
      oban_queue: @queue,
      index_prefix: @index_prefix,
      # RFC 2606: the .invalid top-level domain never resolves.
      meilisearch_url: AppliedSettings.url(:logistify),
      meilisearch_client: FakeMeilisearchClient,
      oban_inspector: FakeObanInspector
    ]
  end

  # The index name and `max_attempts` come from Scrypath's own naming and config, not literals.
  defp context do
    runtime_config = base_opts() |> Scenario.runtime_opts() |> Scrypath.Config.resolve!()

    {Scrypath.Meilisearch.index_name(Shipment, index_prefix: @index_prefix),
     Scrypath.Config.oban_max_attempts(runtime_config)}
  end

  defp build(now, %{id: id, label: label, kind: kind, tasks: tasks, jobs: jobs, expect: expect}) do
    %Scenario{
      id: id,
      adopter: :logistify,
      label: label,
      kind: kind,
      now: now,
      allowlist: [Shipment],
      scrypath_opts: base_opts() ++ [meilisearch_tasks: tasks, oban_jobs: jobs],
      expect: expect
    }
  end

  # 300 succeeded tasks over the last day: a quiet install with nothing waiting.
  defp steady_tasks(now, index) do
    for n <- 1..300 do
      Meili.task(%{
        type: "documentAdditionOrUpdate",
        status: "succeeded",
        uid: n,
        index_uid: index,
        now: now,
        enqueued_ago: 86_400 - n * 280 + 3
      })
    end
  end

  # Forty completed upserts and nothing else: no queue depth, no retries, no failures.
  defp steady_jobs(now, index, max_attempts) do
    for n <- 1..40 do
      job(now, index, max_attempts, n, "completed", :upsert, ago: 3_600 - n * 80, attempt: 1)
    end
  end

  # 1,200 succeeded tasks: more than the 1,000 Scrypath reads, so the read stops with `next` set.
  # This is the F1 stress input, never part of an ordinary state.
  defp over_limit_tasks(now, index) do
    for n <- 1..1_200 do
      Meili.task(%{
        type: "documentAdditionOrUpdate",
        status: "succeeded",
        uid: n,
        index_uid: index,
        now: now,
        enqueued_ago: (1_200 - n) * 90 + 30
      })
    end
  end

  # 640 succeeded tasks spread over the last day and 7 waiting. The history stays under
  # Scrypath's 1,000-task read limit; a longer one is a separate stress case (finding F1).
  defp deep_queue_tasks(now, index) do
    succeeded =
      for n <- 1..640 do
        Meili.task(%{
          type: "documentAdditionOrUpdate",
          status: "succeeded",
          uid: n,
          index_uid: index,
          now: now,
          enqueued_ago: 86_400 - n * 120 + 3
        })
      end

    waiting =
      for n <- 641..647 do
        Meili.task(%{
          type: "documentAdditionOrUpdate",
          status: "enqueued",
          uid: n,
          index_uid: index,
          now: now,
          enqueued_ago: (648 - n) * 30
        })
      end

    succeeded ++ waiting
  end

  # 180 available upserts, 12 scheduled deletes (in the future) and 3 executing upserts on their
  # first attempt: 195 jobs in the queue and none failed or retrying.
  defp deep_queue_jobs(now, index, max_attempts) do
    available =
      for n <- 1..180 do
        job(now, index, max_attempts, n, "available", :upsert, ago: 600 - n)
      end

    scheduled =
      for n <- 181..192 do
        job(now, index, max_attempts, n, "scheduled", :delete,
          ago: 60,
          scheduled_in: 900 + n
        )
      end

    executing =
      for n <- 193..195 do
        job(now, index, max_attempts, n, "executing", :upsert, ago: 20, attempt: 1)
      end

    available ++ scheduled ++ executing
  end

  defp job(now, index, max_attempts, id, state, role, opts) do
    operation = if role == :delete, do: "delete", else: "upsert"
    # Two ordinary shipments per job, picked by `Bulk` so the ids are the ones its records carry.
    document_ids = [
      Bulk.row(:shipment, @bulk_seed, id).id,
      Bulk.row(:shipment, @bulk_seed, id + 1_000).id
    ]

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
            "schema" => Atom.to_string(Shipment),
            "backend" => Atom.to_string(Scrypath.Meilisearch),
            "index" => index,
            "sync_mode" => "oban",
            "document_ids" => document_ids,
            "document_count" => length(document_ids)
          }
        },
        Map.new(opts)
      )
    )
  end
end
