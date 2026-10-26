if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Oban.DeleteWorker do
    @moduledoc false

    use Oban.Worker, queue: :scrypath, max_attempts: 8

    alias Scrypath.Chunks
    alias Scrypath.Oban.IndexingAck
    alias Scrypath.Oban.JobArgs
    alias Scrypath.Telemetry

    @impl Oban.Worker
    def perform(%Oban.Job{args: args} = oban_job) do
      with {:ok, job} <- JobArgs.decode_delete(args),
           {:ok, config} <-
             JobArgs.resolve_config([backend: job.backend, sync_mode: :manual] ++ job.opts) do
        config = Keyword.put(config, :index_name, job.index)

        metadata =
          Telemetry.job_start_metadata(job.schema, config, oban_job, job.document_ids, job.index)

        # The span starts only once decode and config succeeded, so every tag is known.
        Telemetry.span([:scrypath, :oban, :delete], metadata, fn ->
          result = write(job.backend, job.schema, job.document_ids, config)
          {result, Telemetry.job_stop_metadata(result)}
        end)
      else
        {:error, tag} -> {:cancel, {:invalid_job, tag}}
      end
    end

    # Deletes at most Chunks.max_ids/0 ids per call and waits for each chunk's task
    # before sending the next; the first failure stops the job so Oban retries it.
    defp write(_backend, _schema_module, [], _config), do: :ok

    defp write(backend, schema_module, document_ids, config) do
      document_ids
      |> Chunks.ids()
      |> Chunks.each_ok(fn chunk ->
        IndexingAck.await(backend, backend.delete_documents(schema_module, chunk, config), config)
      end)
    end
  end
end
