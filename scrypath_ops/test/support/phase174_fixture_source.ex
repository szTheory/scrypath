defmodule ScrypathOps.Test.Phase174FixtureSource do
  @moduledoc false

  @observed_at ~U[2026-10-07 12:00:00Z]
  @schemas [ScrypathOps.Test.OpsPostA, ScrypathOps.Test.OpsPostB]
  @scenarios [
    "a-selected-b-worse",
    "source-collision",
    "retained",
    "no-success",
    "unknown",
    "error",
    "long-value",
    "empty"
  ]

  def scenario(name) when name in @scenarios do
    {tasks, jobs} = source_records(name)

    %{
      allowlist: if(name == "empty", do: [], else: @schemas),
      observed_at: @observed_at,
      opts: [
        backend: Scrypath.Meilisearch,
        sync_mode: :oban,
        oban_queue: :scrypath_sync,
        index_prefix: "phase174_",
        meilisearch_url: "http://fixture.invalid",
        meilisearch_client: __MODULE__,
        meilisearch_tasks: tasks,
        oban_inspector: __MODULE__,
        oban_jobs: jobs
      ]
    }
  end

  def scenario(_invalid), do: scenario("a-selected-b-worse")

  def tasks(filters, opts) do
    if :fixture_source_error in Keyword.get(opts, :meilisearch_tasks, []) do
      {:error, :fixture_backend_unavailable}
    else
      index_uids = Keyword.get(filters, :index_uids, [])

      results =
        opts
        |> Keyword.get(:meilisearch_tasks, [])
        |> Enum.filter(&is_map/1)
        |> Enum.filter(&(&1["indexUid"] in index_uids))

      {:ok, %{results: results, next: nil}}
    end
  end

  def list_jobs(schema, opts) do
    case Keyword.get(opts, :oban_jobs, []) do
      [:fixture_queue_error] ->
        {:error, :fixture_queue_unavailable}

      jobs ->
        schema_name = Atom.to_string(schema)
        {:ok, Enum.filter(jobs, &(get_in(&1, [:args, "schema"]) == schema_name))}
    end
  end

  defp source_records("empty"), do: {[], []}
  defp source_records("error"), do: {[:fixture_source_error], [:fixture_queue_error]}
  defp source_records("retained"), do: {[:fixture_source_error], []}

  defp source_records(name) do
    tasks = Enum.map(@schemas, &task(&1, name))
    jobs = Enum.map(@schemas, &job(&1, name))
    {tasks, jobs}
  end

  defp task(schema, scenario) do
    selected_a? = schema == ScrypathOps.Test.OpsPostA

    status =
      cond do
        scenario == "no-success" -> "processing"
        scenario == "unknown" -> "future-status"
        scenario == "source-collision" -> "failed"
        scenario == "a-selected-b-worse" and selected_a? -> "succeeded"
        true -> "failed"
      end

    reason =
      if scenario == "long-value",
        do: String.duplicate("Fixture backend failure with a complete diagnostic value. ", 14),
        else: "Phase 174 fixture backend failure for #{inspect(schema)}"

    %{
      "uid" => 501,
      "status" => status,
      "type" => "documentAdditionOrUpdate",
      "indexUid" => Scrypath.Meilisearch.index_name(schema, index_prefix: "phase174_"),
      "finishedAt" => DateTime.to_iso8601(@observed_at),
      "error" => %{"message" => reason},
      "details" => %{"title" => if(scenario == "long-value", do: reason, else: nil)}
    }
  end

  defp job(schema, scenario) do
    selected_a? = schema == ScrypathOps.Test.OpsPostA

    state =
      cond do
        scenario == "no-success" -> "retryable"
        scenario == "unknown" -> "available"
        scenario == "source-collision" -> "discarded"
        scenario == "a-selected-b-worse" and selected_a? -> "completed"
        true -> "discarded"
      end

    %{
      id: 501,
      state: state,
      worker: "Scrypath.Oban.UpsertWorker",
      queue: "scrypath_sync",
      attempt: 4,
      max_attempts: 4,
      attempted_at: DateTime.to_iso8601(@observed_at),
      errors: [%{"error" => "Phase 174 fixture queue failure"}],
      args: %{
        "operation" => "upsert",
        "schema" => Atom.to_string(schema),
        "backend" => "Elixir.Scrypath.Meilisearch",
        "index" => Scrypath.Meilisearch.index_name(schema, index_prefix: "phase174_"),
        "document_count" => 1,
        "document_ids" => ["phase174:fixture:501"],
        "documents" => [%{"id" => "phase174:fixture:501", "data" => %{"title" => "fixture"}}]
      }
    }
  end
end
