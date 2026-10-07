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
    "empty",
    "a-removed"
  ]

  def scenario(name) when name in @scenarios or name == "empty-history" do
    fixture(name)
  end

  def scenario("reorder-after"), do: fixture("reorder-after")
  def scenario("retained-after"), do: fixture("retained-after")

  def scenario("reorder-" <> token) when token != "" do
    scenario(sequence_scenario("reorder", token, "a-selected-b-worse", "reorder-after"))
  end

  def scenario("retained-" <> token) when token != "" do
    scenario(sequence_scenario("retained", token, "a-selected-b-worse", "retained-after"))
  end

  def scenario("busy-" <> token) when token != "" do
    fixture("busy", token)
  end

  def scenario(_invalid), do: scenario("a-selected-b-worse")

  defp fixture(name, token \\ nil) do
    {tasks, jobs} = source_records(name)
    index_prefix = index_prefix(name)

    opts = [
      backend: Scrypath.Meilisearch,
      sync_mode: :oban,
      oban_queue: :scrypath_sync,
      index_prefix: index_prefix,
      meilisearch_url: "http://fixture.invalid",
      meilisearch_client: __MODULE__,
      meilisearch_tasks: tasks,
      oban_inspector: __MODULE__,
      oban_jobs: jobs
    ]

    opts = fixture_markers(opts, name, token)

    %{
      allowlist:
        cond do
          name == "empty" -> []
          name == "a-removed" -> [ScrypathOps.Test.OpsPostB]
          true -> @schemas
        end,
      observed_at: @observed_at,
      opts: opts,
      sequence_token: token
    }
  end

  def tasks(filters, opts) do
    maybe_delay(fixture_delay(opts))

    task_records = fixture_task_records(opts)

    if :fixture_source_error in task_records do
      {:error, :fixture_backend_unavailable}
    else
      index_uids = Keyword.get(filters, :index_uids, [])

      results =
        task_records
        |> Enum.filter(&(&1["indexUid"] in index_uids))

      {:ok, %{results: results, next: nil}}
    end
  end

  def list_jobs(schema, opts) do
    maybe_delay(fixture_delay(opts))
    jobs = fixture_job_records(opts)

    cond do
      :fixture_queue_error in jobs ->
        {:error, :fixture_queue_unavailable}

      true ->
        schema_name = Atom.to_string(schema)

        {:ok,
         Enum.filter(jobs, fn job ->
           get_in(job, [:args, "schema"]) == schema_name
         end)}
    end
  end

  defp source_records("empty"), do: {[], []}
  defp source_records("busy"), do: source_records("a-selected-b-worse")

  defp source_records("empty-history") do
    tasks = Enum.map(@schemas, &task(&1, "empty-history"))
    jobs = Enum.map(@schemas, &job(&1, "empty-history"))
    {tasks, jobs}
  end

  defp source_records("error"), do: {[:fixture_source_error], [:fixture_queue_error]}
  defp source_records("retained"), do: source_records("a-selected-b-worse")

  defp source_records("retained-after"),
    do: {[:fixture_source_error], [:fixture_queue_error]}

  defp source_records(name) do
    tasks = Enum.map(@schemas, &task(&1, name))
    jobs = Enum.map(@schemas, &job(&1, name))
    {tasks, jobs}
  end

  defp task(schema, scenario) do
    selected_a? = schema == ScrypathOps.Test.OpsPostA

    status =
      cond do
        scenario == "empty-history" -> "succeeded"
        scenario == "reorder-after" and selected_a? -> "failed"
        scenario == "reorder-after" -> "succeeded"
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
      "indexUid" => Scrypath.Meilisearch.index_name(schema, index_prefix: index_prefix(scenario)),
      "finishedAt" => DateTime.to_iso8601(@observed_at),
      "error" => %{"message" => reason},
      "details" => %{"title" => if(scenario == "long-value", do: reason, else: nil)}
    }
  end

  defp job(schema, scenario) do
    selected_a? = schema == ScrypathOps.Test.OpsPostA

    state =
      cond do
        scenario == "empty-history" -> "completed"
        scenario == "reorder-after" and selected_a? -> "discarded"
        scenario == "reorder-after" -> "completed"
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
      completed_at: if(state == "completed", do: DateTime.to_iso8601(@observed_at)),
      errors: [
        %{
          "error" =>
            if(scenario == "long-value",
              do: String.duplicate("Fixture queue failure with a complete diagnostic value. ", 14),
              else: "Phase 174 fixture queue failure"
            )
        }
      ],
      args: %{
        "operation" => if(scenario == "long-value", do: "delete", else: "upsert"),
        "schema" => Atom.to_string(schema),
        "backend" => "Elixir.Scrypath.Meilisearch",
        "index" => Scrypath.Meilisearch.index_name(schema, index_prefix: index_prefix(scenario)),
        "document_count" => 1,
        "document_ids" => [document_id(scenario)],
        "documents" => [%{"id" => document_id(scenario), "data" => %{"title" => "fixture"}}]
      }
    }
  end

  defp index_prefix("long-value"), do: "phase174_" <> String.duplicate("long_", 14)
  defp index_prefix(_scenario), do: "phase174_"

  defp document_id("long-value"),
    do: "phase174:" <> String.duplicate("fixture-document-", 10) <> "501"

  defp document_id(_scenario), do: "phase174:fixture:501"

  defp sequence_scenario(kind, token, initial, after_refresh) do
    key = {__MODULE__, :sequence, kind, token}
    count = :persistent_term.get(key, 0) + 1

    if count < 3 do
      :persistent_term.put(key, count)
      initial
    else
      :persistent_term.erase(key)
      after_refresh
    end
  end

  defp fixture_markers(opts, "busy", _token) do
    opts
    |> Keyword.update!(:meilisearch_tasks, &[{:phase174_delay, 700} | &1])
    |> Keyword.update!(:oban_jobs, &[{:phase174_delay, 700} | &1])
  end

  defp fixture_markers(opts, _name, _token), do: opts

  defp fixture_delay(opts) do
    opts
    |> Keyword.get(:meilisearch_tasks, [])
    |> Enum.find_value(0, fn
      {:phase174_delay, ms} -> ms
      _ -> nil
    end)
  end

  defp fixture_task_records(opts) do
    Keyword.get(opts, :meilisearch_tasks, [])
    |> Enum.reject(&match?({:phase174_delay, _}, &1))
  end

  defp fixture_job_records(opts) do
    Keyword.get(opts, :oban_jobs, [])
    |> Enum.reject(&match?({:phase174_delay, _}, &1))
  end

  defp maybe_delay(ms) when is_integer(ms) and ms > 0, do: Process.sleep(ms)
  defp maybe_delay(_ms), do: :ok
end
