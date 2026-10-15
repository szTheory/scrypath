defmodule ScrypathEcommerce.Phase173PartialSchema do
  use Ecto.Schema

  use Scrypath,
    fields: [:title],
    filterable: [],
    sortable: []

  embedded_schema do
    field(:title, :string)
  end
end

defmodule ScrypathEcommerce.Phase173VeryLongSchemaIdentifierForNarrowOperatorDisplays do
  use Ecto.Schema

  use Scrypath,
    fields: [:title],
    filterable: [],
    sortable: []

  embedded_schema do
    field(:title, :string)
  end
end

defmodule ScrypathEcommerce.Phase173FixtureSource do
  @moduledoc false

  @snapshot "2026-10-06T13:18:42.318-04:00"
  @task_finished "2026-10-04T13:02:05.123456-04:00"
  @queue_completed "2026-10-05T11:12:13.456-04:00"

  def fixture(params) do
    scenario = normalize_scenario(params["scenario"])

    %{
      scenario: scenario,
      allowlist: allowlist(scenario),
      scrypath_opts: scrypath_opts(scenario),
      snapshot_at: snapshot_at()
    }
  end

  def fail_refresh(scrypath_opts) do
    Keyword.put(scrypath_opts, :meilisearch_tasks, {:error, :phase173_backend_unavailable})
  end

  def tasks(filters, config) do
    case Keyword.get(config, :meilisearch_tasks, []) do
      {:error, _reason} = error ->
        error

      tasks when is_list(tasks) ->
        index_uids = Keyword.get(filters, :index_uids, [])

        if "phase173_phase173_partial_schema" in index_uids do
          {:error, :phase173_backend_unavailable}
        else
          {:ok, %{results: Enum.filter(tasks, &(Map.get(&1, "indexUid") in index_uids))}}
        end
    end
  end

  def list_jobs(_schema, config) do
    case Keyword.get(config, :oban_jobs, []) do
      {:error, _reason} = error -> error
      jobs when is_list(jobs) -> {:ok, jobs}
    end
  end

  defp normalize_scenario(scenario)
       when scenario in [
              "healthy",
              "failed",
              "unavailable",
              "unknown",
              "empty",
              "partial",
              "long",
              "invalid-time",
              "queue-unused",
              "refresh-failure",
              "refresh-disabled",
              "processing",
              "backend-failed",
              "retrying",
              "completed"
            ],
       do: scenario

  defp normalize_scenario(_scenario), do: "healthy"

  defp allowlist("empty"), do: []

  defp allowlist("partial"),
    do: [ScrypathEcommerce.Catalog.Product, ScrypathEcommerce.Phase173PartialSchema]

  defp allowlist("long"),
    do: [
      ScrypathEcommerce.Catalog.Product,
      ScrypathEcommerce.Phase173VeryLongSchemaIdentifierForNarrowOperatorDisplays
    ]

  defp allowlist(_scenario), do: [ScrypathEcommerce.Catalog.Product]

  defp scrypath_opts(scenario) do
    [
      backend: Scrypath.Meilisearch,
      sync_mode: if(scenario == "queue-unused", do: :manual, else: :oban),
      oban: Oban,
      oban_queue: :default,
      index_prefix: "phase173",
      meilisearch_url: "http://phase173.invalid",
      meilisearch_client: __MODULE__,
      meilisearch_tasks: tasks_for(scenario),
      oban_inspector: __MODULE__,
      oban_jobs: jobs_for(scenario)
    ]
  end

  # These fixed snapshots demonstrate transient states without pausing a live backend.
  defp tasks_for("processing") do
    [
      task(840, "succeeded", "phase173_product", @task_finished),
      task(845, "processing", "phase173_product", nil),
      task(846, "enqueued", "phase173_product", nil)
    ]
  end

  defp tasks_for("backend-failed") do
    [
      task(847, "failed", "phase173_product", @snapshot)
      |> Map.put("error", %{
        "code" => "missing_document_id",
        "message" => "Document is missing its id field."
      })
    ]
  end

  defp tasks_for("retrying"), do: [task(840, "succeeded", "phase173_product", @task_finished)]
  defp tasks_for("completed"), do: [task(848, "succeeded", "phase173_product", @snapshot)]

  defp tasks_for("empty"), do: []

  defp tasks_for("unavailable"), do: {:error, :phase173_backend_unavailable}

  defp tasks_for("failed") do
    [task(841, "failed", "phase173_product", @task_finished)]
  end

  defp tasks_for("unknown"), do: [task(842, "succeeded", "phase173_product", @task_finished)]

  defp tasks_for("partial") do
    [
      task(843, "succeeded", "phase173_product", @task_finished),
      task(844, "succeeded", "phase173_phase173_partial_schema", @task_finished)
    ]
  end

  defp tasks_for("long") do
    long_index =
      Scrypath.Meilisearch.index_name(
        ScrypathEcommerce.Phase173VeryLongSchemaIdentifierForNarrowOperatorDisplays,
        index_prefix: "phase173"
      )

    [
      task(9_876_543_210, "succeeded", "phase173_product", @task_finished),
      task(9_876_543_211, "succeeded", long_index, @task_finished)
    ]
  end

  defp tasks_for("invalid-time") do
    [task(905, "succeeded", "phase173_product", "not-a-timestamp")]
  end

  defp tasks_for(_scenario) do
    [task(840, "succeeded", "phase173_product", @task_finished)]
  end

  defp jobs_for("processing") do
    jobs_for("healthy") ++
      [
        %{
          id: 910,
          state: "executing",
          worker: "Scrypath.Oban.UpsertWorker",
          queue: "scrypath_sync"
        }
      ]
  end

  defp jobs_for("retrying") do
    jobs_for("healthy") ++
      [
        %{
          id: 911,
          state: "retryable",
          worker: "Scrypath.Oban.UpsertWorker",
          queue: "scrypath_sync",
          attempted_at: "2026-10-06T13:17:42-04:00",
          scheduled_at: "2026-10-06T13:19:42-04:00"
        }
      ]
  end

  defp jobs_for("completed") do
    [
      %{
        id: 912,
        state: "completed",
        worker: "Scrypath.Oban.UpsertWorker",
        queue: "scrypath_sync",
        completed_at: @snapshot
      }
    ]
  end

  defp jobs_for("empty"), do: []

  defp jobs_for("failed") do
    [
      %{
        id: 902,
        state: "discarded",
        worker: "ScrypathEcommerce.Phase173FixtureWorker",
        queue: "default"
      }
    ]
  end

  defp jobs_for("unknown"), do: {:error, :phase173_queue_unavailable}

  defp jobs_for("partial") do
    [
      %{
        id: 903,
        state: "completed",
        worker: "ScrypathEcommerce.Phase173FixtureWorker",
        queue: "default",
        completed_at: @queue_completed
      }
    ]
  end

  defp jobs_for("long") do
    [
      %{
        id: 904,
        state: "completed",
        worker: String.duplicate("Phase173FixtureWorker", 12),
        queue: "default",
        completed_at: @queue_completed
      }
    ]
  end

  defp jobs_for("invalid-time") do
    [
      %{
        id: 906,
        state: "completed",
        worker: "ScrypathEcommerce.Phase173FixtureWorker",
        queue: "default",
        completed_at: "not-a-timestamp"
      }
    ]
  end

  defp jobs_for(_scenario) do
    [
      %{
        id: 901,
        state: "completed",
        worker: "ScrypathEcommerce.Phase173FixtureWorker",
        queue: "default",
        completed_at: @queue_completed
      }
    ]
  end

  defp task(uid, status, index_uid, finished_at) do
    %{
      "uid" => uid,
      "status" => status,
      "type" => "documentAdditionOrUpdate",
      "indexUid" => index_uid,
      "finishedAt" => finished_at
    }
  end

  defp snapshot_at do
    {:ok, datetime, _offset} = DateTime.from_iso8601(@snapshot)
    datetime
  end
end
