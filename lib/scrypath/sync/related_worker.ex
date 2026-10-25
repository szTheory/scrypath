if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Sync.RelatedWorker do
    @moduledoc false

    use Oban.Worker, queue: :scrypath, max_attempts: 8

    alias Scrypath.Loader
    alias Scrypath.Oban.JobArgs
    alias Scrypath.Telemetry

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      with {:ok, job} <- JobArgs.decode_related(args),
           opts = job.opts ++ [fan_out: job.fan_out, sync_mode: :inline],
           {:ok, config} <- JobArgs.resolve_config(opts) do
        run(job, opts, config)
      else
        {:error, tag} -> {:cancel, {:invalid_job, tag}}
      end
    end

    # Resolvers receive the trigger records as they are now, never bare ids: a retried or
    # delayed job must not fan out from rows that were deleted or soft-deleted since.
    defp run(%{schema: schema_module, document_ids: document_ids} = job, opts, config) do
      case Loader.load(schema_module, document_ids, config) do
        {:ok, records, missing} ->
          job
          |> resolve(records, missing, opts, config)
          |> job_result()

        {:error, reason} when reason in [:repo_required, :search_records_required] ->
          {:cancel, {:invalid_job, reason}}

        {:error, reason} ->
          {:error, reason}
      end
    end

    defp resolve(job, records, missing, opts, config) do
      metadata =
        Telemetry.common_metadata(job.schema, config,
          fan_out: job.fan_out,
          document_count: length(job.document_ids)
        )

      Telemetry.span([:scrypath, :sync, :related, :resolve], metadata, fn ->
        result = sync_resolved(job.fan_out_config, records, opts)
        {result, Telemetry.stop_metadata(result, missing_count: length(missing))}
      end)
    end

    # No trigger still exists, so there is nothing to fan out from. Returning :ok keeps
    # Oban from retrying work that can never succeed.
    defp sync_resolved(_fan_out_config, [], _opts) do
      {:ok, %{mode: :inline, status: :noop, document_ids: [], document_count: 0}}
    end

    defp sync_resolved(fan_out_config, records, opts) do
      target_module = Keyword.fetch!(fan_out_config, :target)
      {mod, fun, mfa_args} = Keyword.fetch!(fan_out_config, :resolver)

      resolved_records = apply(mod, fun, [records | mfa_args])

      Scrypath.Sync.sync_records(target_module, resolved_records, opts)
    end

    defp job_result(:ok), do: :ok
    defp job_result({:ok, _result}), do: :ok

    defp job_result({:error, {:http_error, status, body}}) when status in 400..499,
      do: {:cancel, "HTTP #{status}: #{inspect(body)}"}

    defp job_result({:error, reason}), do: {:error, reason}
  end
else
  defmodule Scrypath.Sync.RelatedWorker do
    @moduledoc false
  end
end
