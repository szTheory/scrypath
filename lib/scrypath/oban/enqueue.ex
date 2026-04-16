defmodule Scrypath.Oban.Enqueue do
  @moduledoc false

  alias Oban.Job
  alias Scrypath.Config
  alias Scrypath.Oban.Payload

  @upsert_worker "Scrypath.Oban.UpsertWorker"
  @delete_worker "Scrypath.Oban.DeleteWorker"

  @spec enqueue_upsert(module(), [Scrypath.Document.t()], keyword()) ::
          {:ok, map()} | {:error, term()}
  def enqueue_upsert(schema_module, documents, config) when is_list(documents) do
    config = Config.resolve!(config)
    payload = Payload.build_upsert(schema_module, documents, config)

    enqueue_job(payload, @upsert_worker, config)
  end

  @spec enqueue_delete(module(), [term()], keyword()) :: {:ok, map()} | {:error, term()}
  def enqueue_delete(schema_module, document_ids, config) when is_list(document_ids) do
    config = Config.resolve!(config)
    payload = Payload.build_delete(schema_module, document_ids, config)

    enqueue_job(payload, @delete_worker, config)
  end

  defp enqueue_job(payload, worker, config) do
    queue = Config.oban_queue(config)
    max_attempts = Config.oban_max_attempts(config)
    oban = Config.oban_module(config)

    payload
    |> Job.new(worker: worker, queue: to_string(queue), max_attempts: max_attempts)
    |> oban.insert()
    |> case do
      {:ok, job} ->
        {:ok,
         %{
           index: payload["index"],
           document_ids: payload["document_ids"],
           document_count: payload["document_count"],
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
end
