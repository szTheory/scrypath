defmodule Scrypath.Oban.Enqueue do
  @moduledoc false
  @compile {:no_warn_undefined, [Oban, Oban.Job, Oban.Repo]}

  alias Ecto.Changeset
  alias Scrypath.Chunks
  alias Scrypath.Config
  alias Scrypath.Loader
  alias Scrypath.Oban.Payload
  alias Scrypath.Operations
  alias Scrypath.Operations.Result

  @upsert_worker "Scrypath.Oban.UpsertWorker"
  @delete_worker "Scrypath.Oban.DeleteWorker"

  @spec enqueue_upsert(module(), [term()], keyword()) ::
          {:ok, map()} | {:error, term()}
  def enqueue_upsert(schema_module, document_ids, config) when is_list(document_ids) do
    config =
      config
      |> Config.resolve!()
      |> Config.ensure_oban_ready!()

    ensure_durable_api_key!(config)

    changesets =
      document_ids
      |> Payload.serialize_ids!()
      |> Chunks.ids()
      |> at_least_one_chunk()
      |> Enum.map(&upsert_job_changeset(schema_module, &1, config))

    enqueue_chunks(changesets, config, index_metadata(changesets))
  end

  @spec enqueue_delete(module(), [term()], keyword()) :: {:ok, map()} | {:error, term()}
  def enqueue_delete(schema_module, document_ids, config) when is_list(document_ids) do
    config =
      config
      |> Config.resolve!()
      |> Config.ensure_oban_ready!()

    ensure_durable_api_key!(config)

    changesets =
      document_ids
      |> Payload.serialize_ids!()
      |> Chunks.ids()
      |> at_least_one_chunk()
      |> Enum.map(&delete_job_changeset(schema_module, &1, config))

    enqueue_chunks(changesets, config, index_metadata(changesets))
  end

  @spec upsert_job_changeset(module(), [term()], keyword()) :: Changeset.t()
  def upsert_job_changeset(schema_module, document_ids, config) when is_list(document_ids) do
    config =
      config
      |> Config.resolve!()
      |> Config.ensure_oban_ready!()

    ensure_durable_api_key!(config)
    Loader.ensure_loadable!(schema_module, config)

    payload = Payload.build_upsert(schema_module, document_ids, config)

    job_changeset(payload, @upsert_worker, config)
  end

  @spec delete_job_changeset(module(), [term()], keyword()) :: Changeset.t()
  def delete_job_changeset(schema_module, document_ids, config) when is_list(document_ids) do
    config =
      config
      |> Config.resolve!()
      |> Config.ensure_oban_ready!()

    ensure_durable_api_key!(config)

    payload = Payload.build_delete(schema_module, document_ids, config)

    job_changeset(payload, @delete_worker, config)
  end

  @doc false
  # The unique policy shared by every Scrypath sync job (upsert, delete, related).
  # Jobs load current records when they run, so an identical pending batch adds nothing.
  # :executing is left out on purpose (D-20): a running job may already have read its rows
  # before the caller's write committed, so a sync that arrives while an identical job runs
  # must enqueue a fresh job. Collapsing it into the running job would lose that update.
  # There is no keys:/fields: override, so the whole args map (with its sorted ids) is
  # compared.
  #
  # Oban 2.23 flags :states lists that omit incomplete states (:executing, :suspended) as
  # "may break uniqueness" (Oban.Job.warn_unique/1). That check runs only for worker-level
  # `use Oban.Worker, unique: ...` at compile time; this list is passed to Oban.Job.new/2 at
  # runtime, so nothing warns. None of Oban's unique groups (:all, :incomplete, :scheduled,
  # :successful) excludes :executing while keeping :available and :retryable, so an explicit
  # list is required. The gap is safe for the open-source engines (Basic, Lite, Dolphin), which
  # check uniqueness with a query at insert time only. An engine that enforces uniqueness with a
  # database index (Oban Pro's Smart engine) may report a conflict when a retried job
  # re-enters :retryable while a newer identical job is pending; this is not verified
  # against Pro. :suspended is not added either: Scrypath never inserts jobs as suspended.
  @spec unique_opts() :: keyword()
  def unique_opts, do: [period: :infinity, states: [:available, :scheduled, :retryable]]

  @doc false
  # Inserts one job per changeset (see insert_chunks/2) and builds one combined result
  # whose tasks list every job and whose task is the last job.
  @spec enqueue_chunks([Changeset.t()], keyword(), map()) ::
          {:ok, Result.t()} | {:error, term()}
  def enqueue_chunks(changesets, config, metadata_extra)
      when is_list(changesets) and is_map(metadata_extra) do
    case insert_chunks(Config.oban_module(config), changesets) do
      {:ok, jobs} -> {:ok, combined_result(jobs, config, metadata_extra)}
      {:error, _reason} = error -> error
    end
  end

  @doc false
  # One changeset inserts exactly as before. Two or more are inserted one by one (never
  # in bulk: open-source Oban ignores unique: on bulk inserts) and halt on the first
  # failed insert, returning its bare {:error, reason}:
  #
  #   * Outside a transaction, the inserts run inside one transaction on the Oban
  #     instance's repo, rolled back on the first failure so no orphan chunk jobs persist.
  #   * Inside the caller's transaction (for example a sync call from Ecto.Multi.run/3),
  #     no nested transaction is opened and nothing is rolled back here: a nested rollback
  #     would mark the caller's whole transaction as failed. The caller's transaction
  #     already makes the chunk jobs all-or-nothing, so the caller must fail it on
  #     {:error, _}; returning {:error, _} from Multi.run/3 does exactly that. This also
  #     follows Oban.Repo.transaction/3's nested-transaction guidance (no retry loop runs
  #     inside a caller's transaction).
  #   * A module with no running Oban instance (a test fake) inserts sequentially.
  @spec insert_chunks(module(), [Changeset.t()]) :: {:ok, [struct()]} | {:error, term()}
  def insert_chunks(oban, [changeset]) do
    case insert_job(oban, changeset) do
      {:ok, job} -> {:ok, [job]}
      {:error, _reason} = error -> error
    end
  end

  def insert_chunks(oban, changesets) when is_list(changesets) do
    case oban_conf(oban) do
      {:ok, conf} ->
        if Oban.Repo.in_transaction?(conf) do
          Chunks.reduce_ok(changesets, &insert_job(oban, &1))
        else
          insert_chunks_in_transaction(conf, oban, changesets)
        end

      :none ->
        Chunks.reduce_ok(changesets, &insert_job(oban, &1))
    end
  end

  defp insert_chunks_in_transaction(conf, oban, changesets) do
    Oban.Repo.transaction(conf, fn ->
      case Chunks.reduce_ok(changesets, &insert_job(oban, &1)) do
        {:ok, jobs} -> jobs
        {:error, reason} -> Oban.Repo.rollback(conf, reason)
      end
    end)
  end

  defp oban_conf(oban) do
    {:ok, Oban.config(oban)}
  rescue
    # "No Oban instance named ... is running": a bare fake module.
    RuntimeError -> :none
  end

  # An empty id list still enqueues one empty job, as it did before chunking.
  defp at_least_one_chunk([]), do: [[]]
  defp at_least_one_chunk(chunks), do: chunks

  defp index_metadata([changeset | _rest]) do
    %{index: changeset |> Changeset.get_field(:args) |> Map.get("index")}
  end

  defp combined_result(jobs, config, metadata_extra) do
    tasks = Enum.map(jobs, &(&1 |> public_job() |> Operations.task_from_job()))
    document_ids = Enum.flat_map(jobs, &job_document_ids/1)

    oban = %{
      queue: Config.oban_queue(config),
      max_attempts: Config.oban_max_attempts(config),
      name: Config.oban_module(config)
    }

    Result.new(
      mode: :oban,
      status: :accepted,
      document_ids: document_ids,
      document_count: length(document_ids),
      task: List.last(tasks),
      tasks: tasks,
      metadata: Map.merge(%{oban: oban}, metadata_extra)
    )
  end

  defp public_job(job) do
    %{
      id: job.id,
      worker: job.worker,
      queue: job.queue,
      state: job.state,
      attempt: job.attempt,
      max_attempts: job.max_attempts,
      conflict?: Map.get(job, :conflict?, false)
    }
  end

  defp job_document_ids(%{args: %{"document_ids" => ids}}) when is_list(ids), do: ids
  defp job_document_ids(_job), do: []

  defp job_changeset(payload, worker, config) do
    oban_job_module!().new(payload,
      worker: worker,
      queue: to_string(Config.oban_queue(config)),
      max_attempts: Config.oban_max_attempts(config),
      # Jobs load current records when they run, so an identical pending batch adds nothing.
      unique: unique_opts()
    )
  end

  defp insert_job(oban, changeset) do
    cond do
      function_exported?(oban, :insert, 1) ->
        oban.insert(changeset)

      function_exported?(oban, :insert, 2) ->
        oban.insert(changeset, [])

      true ->
        Oban.insert(oban, changeset)
    end
  end

  defp oban_job_module! do
    if Code.ensure_loaded?(Oban.Job) do
      Oban.Job
    else
      raise ArgumentError,
            "Oban dependency is required for sync_mode :oban. Add {:oban, \"~> 2.21\", optional: true} to your deps."
    end
  end

  @doc false
  @spec ensure_durable_api_key!(keyword()) :: :ok
  def ensure_durable_api_key!(config) do
    durable_config =
      [backend: Config.fetch_backend!(config), sync_mode: :manual]
      |> Config.resolve!()

    case {Config.meilisearch_api_key(config), Config.meilisearch_api_key(durable_config)} do
      {nil, _} ->
        :ok

      {key, durable_key} when is_binary(key) and key == durable_key ->
        :ok

      {_key, _} ->
        raise ArgumentError,
              "meilisearch_api_key for sync_mode :oban must be configured durably; per-call API keys are not persisted in Oban job args"
    end
  end
end
