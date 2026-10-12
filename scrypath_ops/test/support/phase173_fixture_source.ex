defmodule ScrypathOps.Phase173FixtureSchema do
  use Ecto.Schema

  use Scrypath,
    fields: [:title],
    filterable: [],
    sortable: []

  embedded_schema do
    field(:title, :string)
  end
end

defmodule ScrypathOps.Phase173PartialSchema do
  use Ecto.Schema

  use Scrypath,
    fields: [:title],
    filterable: [],
    sortable: []

  embedded_schema do
    field(:title, :string)
  end
end

defmodule ScrypathOps.Phase173VeryLongSchemaIdentifierForNarrowOperatorDisplays do
  use Ecto.Schema

  use Scrypath,
    fields: [:title],
    filterable: [],
    sortable: []

  embedded_schema do
    field(:title, :string)
  end
end

defmodule ScrypathOps.Phase173FixtureSource do
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
              "refresh-disabled"
            ],
       do: scenario

  defp normalize_scenario(_scenario), do: "healthy"

  defp allowlist("empty"), do: []

  defp allowlist("partial"),
    do: [ScrypathOps.Phase173FixtureSchema, ScrypathOps.Phase173PartialSchema]

  defp allowlist("long"),
    do: [
      ScrypathOps.Phase173FixtureSchema,
      ScrypathOps.Phase173VeryLongSchemaIdentifierForNarrowOperatorDisplays
    ]

  defp allowlist(_scenario), do: [ScrypathOps.Phase173FixtureSchema]

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

  defp tasks_for("empty"), do: []

  defp tasks_for("unavailable"), do: {:error, :phase173_backend_unavailable}

  defp tasks_for("failed") do
    [task(841, "failed", "phase173_phase173_fixture_schema", @task_finished)]
  end

  defp tasks_for("unknown"),
    do: [task(842, "succeeded", "phase173_phase173_fixture_schema", @task_finished)]

  defp tasks_for("partial") do
    [
      task(843, "succeeded", "phase173_phase173_fixture_schema", @task_finished),
      task(844, "succeeded", "phase173_phase173_partial_schema", @task_finished)
    ]
  end

  defp tasks_for("long") do
    long_index =
      Scrypath.Meilisearch.index_name(
        ScrypathOps.Phase173VeryLongSchemaIdentifierForNarrowOperatorDisplays,
        index_prefix: "phase173"
      )

    [
      task(9_876_543_210, "succeeded", "phase173_phase173_fixture_schema", @task_finished),
      task(9_876_543_211, "succeeded", long_index, @task_finished)
    ]
  end

  defp tasks_for("invalid-time") do
    [task(905, "succeeded", "phase173_phase173_fixture_schema", "not-a-timestamp")]
  end

  defp tasks_for(_scenario) do
    [task(840, "succeeded", "phase173_phase173_fixture_schema", @task_finished)]
  end

  defp jobs_for("empty"), do: []

  defp jobs_for("failed") do
    [
      %{
        id: 902,
        state: "discarded",
        worker: "ScrypathOps.Phase173FixtureWorker",
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
        worker: "ScrypathOps.Phase173FixtureWorker",
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
        worker: "ScrypathOps.Phase173FixtureWorker",
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
        worker: "ScrypathOps.Phase173FixtureWorker",
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
