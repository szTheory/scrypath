defmodule ScrypathFixtures.Logistify do
  @moduledoc """
  Logistify scenarios. Logistify is a fictional freight-tracking product; the data is for
  development and tests only.

  `scenario(:deep_queue, now: now)` is a busy but healthy install: a long Oban queue and a few
  enqueued Meilisearch tasks, with nothing failed. It is built from raw wire shapes only, so the
  real `Scrypath.sync_status/2` reads it as pending work and `failed_sync_work/2` finds no rows.
  """

  alias ScrypathFixtures.AppliedSettings
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

  @doc "Builds one named Logistify scenario at `now`."
  @spec scenario(:deep_queue, keyword()) :: Scenario.t()
  def scenario(:deep_queue, now: %DateTime{} = now) do
    base_opts = [
      backend: Scrypath.Meilisearch,
      sync_mode: :oban,
      oban_queue: @queue,
      index_prefix: @index_prefix,
      # RFC 2606: the .invalid top-level domain never resolves.
      meilisearch_url: AppliedSettings.url(:logistify),
      meilisearch_client: FakeMeilisearchClient,
      oban_inspector: FakeObanInspector
    ]

    runtime_config = base_opts |> Scenario.runtime_opts() |> Scrypath.Config.resolve!()
    max_attempts = Scrypath.Config.oban_max_attempts(runtime_config)
    index = Scrypath.Meilisearch.index_name(Shipment, index_prefix: @index_prefix)

    %Scenario{
      id: :logistify_deep_queue,
      adopter: :logistify,
      label: "Logistify shipments, deep queue (fictional)",
      kind: :ordinary,
      now: now,
      allowlist: [Shipment],
      scrypath_opts:
        base_opts ++
          [
            meilisearch_tasks: deep_queue_tasks(now, index),
            oban_jobs: deep_queue_jobs(now, index, max_attempts)
          ],
      expect: %{
        sync_status: :ok,
        failed_sync_work: :ok,
        index_contract_drift: :ok,
        posture: %{state: :ok, headline: "No sync failures found"}
      }
    }
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
    document_ids = ["LSH-#{id}", "LSH-#{id + 1000}"]

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
