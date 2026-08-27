if Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Sync.RelatedEnqueue do
    @moduledoc false

    alias Scrypath.Config
    alias Scrypath.Identity
    alias Scrypath.Oban.Enqueue
    alias Scrypath.Operations

    @worker "Scrypath.Sync.RelatedWorker"

    @spec enqueue(module(), struct() | [struct()], atom(), keyword()) ::
            {:ok, Scrypath.Operations.Result.t()} | {:error, term()}
    def enqueue(schema_module, records, fan_out_key, config) do
      Enqueue.ensure_durable_api_key!(config)
      document_ids = Identity.document_ids(schema_module, List.wrap(records))
      args = job_args(schema_module, document_ids, fan_out_key, config)
      queue = Config.oban_queue(config)
      max_attempts = Config.oban_max_attempts(config)
      oban = Config.oban_module(config)

      changeset =
        Oban.Job.new(args,
          worker: @worker,
          queue: to_string(queue),
          max_attempts: max_attempts
        )

      with {:ok, job} <- insert_job(oban, changeset) do
        result =
          Operations.result_from_enqueue(
            %{
              job: %{
                id: job.id,
                worker: job.worker,
                queue: job.queue,
                state: job.state,
                attempt: job.attempt,
                max_attempts: job.max_attempts
              },
              document_ids: document_ids,
              document_count: length(document_ids)
            },
            mode: :oban,
            status: :accepted
          )

        {:ok,
         %{result | metadata: %{oban: %{queue: queue, max_attempts: max_attempts, name: oban}}}}
      end
    end

    defp job_args(schema_module, document_ids, fan_out_key, config) do
      opts =
        config
        |> Keyword.take([:index_prefix, :meilisearch_url, :backend, :otp_app, :repo])
        |> Enum.map(fn
          {key, value}
          when key in [:backend, :otp_app, :repo] and is_atom(value) and not is_nil(value) ->
            {key, to_string(value)}

          option ->
            option
        end)
        |> Enum.into(%{})

      %{
        "schema" => to_string(schema_module),
        "document_ids" => document_ids,
        "fan_out" => to_string(fan_out_key),
        "opts" => opts
      }
    end

    defp insert_job(oban, changeset) do
      cond do
        function_exported?(oban, :insert, 1) -> oban.insert(changeset)
        function_exported?(oban, :insert, 2) -> oban.insert(changeset, [])
        true -> Oban.insert(oban, changeset)
      end
    end
  end
else
  defmodule Scrypath.Sync.RelatedEnqueue do
    @moduledoc false

    def enqueue(_schema_module, _records, _fan_out_key, _config) do
      raise ArgumentError,
            "Oban dependency is required for sync_mode :oban. Add {:oban, \"~> 2.21\", optional: true} to your deps."
    end
  end
end
