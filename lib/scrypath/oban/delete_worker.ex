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
        metadata = start_metadata(job, config, oban_job)

        # The span starts only once decode and config succeeded, so every tag is known.
        Telemetry.span([:scrypath, :oban, :delete], metadata, fn ->
          result = write(job.backend, job.schema, job.document_ids, config)
          {result, Telemetry.job_stop_metadata(result)}
        end)
      else
        {:error, tag} -> {:cancel, {:invalid_job, tag}}
      end
    end

    # sync_mode: :oban overrides the :manual the config resolves with: extra merges last.
    # index is the one the job writes to (job.index, set as :index_name above). A backend's
    # index_name/2 may rebuild the name from the current prefix config instead, which
    # differs from the queued name after a deploy that changes the prefix.
    defp start_metadata(job, config, %Oban.Job{} = oban_job) do
      Telemetry.common_metadata(job.schema, config,
        sync_mode: :oban,
        attempt: oban_job.attempt,
        max_attempts: oban_job.max_attempts,
        document_count: Chunks.distinct_count(job.document_ids),
        index: job.index
      )
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
