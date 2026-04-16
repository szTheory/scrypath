defmodule Scrypath.Oban.Enqueue do
  @moduledoc false
  @compile {:no_warn_undefined, [Oban, Oban.Job]}

  alias Ecto.Changeset
  alias Scrypath.Config
  alias Scrypath.Oban.Payload

  @upsert_worker "Scrypath.Oban.UpsertWorker"
  @delete_worker "Scrypath.Oban.DeleteWorker"

  @spec enqueue_upsert(module(), [Scrypath.Document.t()], keyword()) ::
          {:ok, map()} | {:error, term()}
  def enqueue_upsert(schema_module, documents, config) when is_list(documents) do
    config =
      config
      |> Config.resolve!()
      |> Config.ensure_oban_ready!()

    changeset = upsert_job_changeset(schema_module, documents, config)

    enqueue_job(changeset, config)
  end

  @spec enqueue_delete(module(), [term()], keyword()) :: {:ok, map()} | {:error, term()}
  def enqueue_delete(schema_module, document_ids, config) when is_list(document_ids) do
    config =
      config
      |> Config.resolve!()
      |> Config.ensure_oban_ready!()

    changeset = delete_job_changeset(schema_module, document_ids, config)

    enqueue_job(changeset, config)
  end

  @spec upsert_job_changeset(module(), [Scrypath.Document.t()], keyword()) :: Changeset.t()
  def upsert_job_changeset(schema_module, documents, config) when is_list(documents) do
    config =
      config
      |> Config.resolve!()
      |> Config.ensure_oban_ready!()

    payload = Payload.build_upsert(schema_module, documents, config)

    job_changeset(payload, @upsert_worker, config)
  end

  @spec delete_job_changeset(module(), [term()], keyword()) :: Changeset.t()
  def delete_job_changeset(schema_module, document_ids, config) when is_list(document_ids) do
    config =
      config
      |> Config.resolve!()
      |> Config.ensure_oban_ready!()

    payload = Payload.build_delete(schema_module, document_ids, config)

    job_changeset(payload, @delete_worker, config)
  end

  defp enqueue_job(changeset, config) do
    queue = Config.oban_queue(config)
    max_attempts = Config.oban_max_attempts(config)
    oban = Config.oban_module(config)

    insert_job(oban, changeset)
    |> case do
      {:ok, job} ->
        {:ok,
         %{
           index: job.args["index"],
           document_ids: job.args["document_ids"],
           document_count: job.args["document_count"],
           job: %{
             id: job.id,
             worker: job.worker,
             queue: job.queue,
             state: job.state,
             attempt: job.attempt,
             max_attempts: job.max_attempts
           },
           oban: %{
             queue: queue,
             max_attempts: max_attempts,
             name: oban
           }
         }}

      {:error, _reason} = error ->
        error
    end
  end

  defp job_changeset(payload, worker, config) do
    oban_job_module!().new(payload,
      worker: worker,
      queue: to_string(Config.oban_queue(config)),
      max_attempts: Config.oban_max_attempts(config)
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
end
