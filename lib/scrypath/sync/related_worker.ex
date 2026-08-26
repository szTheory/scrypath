if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Sync.RelatedWorker do
    @moduledoc false

    use Oban.Worker, queue: :scrypath, max_attempts: 8

    alias Scrypath.Config

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      %{"document_ids" => document_ids, "opts" => opts_map} = args

      with {:ok, schema_module} <- resolve_schema(args),
           {:ok, fan_out_key} <- resolve_fan_out(schema_module, args) do
        opts =
          opts_map
          |> Enum.map(fn
            {"backend", v} when is_binary(v) -> {:backend, String.to_existing_atom(v)}
            {"otp_app", v} when is_binary(v) -> {:otp_app, String.to_existing_atom(v)}
            {"repo", v} when is_binary(v) -> {:repo, String.to_existing_atom(v)}
            {k, v} -> {String.to_existing_atom(k), v}
          end)
          |> Keyword.put(:fan_out, fan_out_key)
          |> Keyword.put(:sync_mode, :inline)

        config = Config.resolve!(opts)

        fan_outs = Scrypath.Schema.Metadata.fan_outs(schema_module) || []

        fan_out_config =
          Keyword.get(fan_outs, fan_out_key) ||
            raise ArgumentError,
                  "fan_out #{inspect(fan_out_key)} is not configured on #{inspect(schema_module)}"

        metadata =
          Scrypath.Telemetry.common_metadata(schema_module, config,
            fan_out: fan_out_key,
            document_count: length(document_ids)
          )

        sync_result =
          Scrypath.Telemetry.span([:scrypath, :sync, :related, :resolve], metadata, fn ->
            target_module = Keyword.fetch!(fan_out_config, :target)
            {mod, fun, mfa_args} = Keyword.fetch!(fan_out_config, :resolver)

            resolved_records = apply(mod, fun, [document_ids] ++ mfa_args)

            result = Scrypath.Sync.sync_records(target_module, resolved_records, opts)

            {result, Scrypath.Telemetry.stop_metadata(result)}
          end)

        case sync_result do
          :ok ->
            :ok

          {:ok, _result} ->
            :ok

          {:error, {:http_error, status, body}} when status in 400..499 ->
            {:cancel, "HTTP #{status}: #{inspect(body)}"}

          {:error, reason} ->
            {:error, reason}
        end
      else
        {:error, reason} when reason in [:invalid_schema, :invalid_fan_out] ->
          {:cancel, {:invalid_job, reason}}
      end
    end

    defp resolve_schema(%{"schema" => name}) when is_binary(name) do
      {:ok, String.to_existing_atom(name)}
    rescue
      ArgumentError -> {:error, :invalid_schema}
    end

    defp resolve_schema(_args), do: {:error, :invalid_schema}

    defp resolve_fan_out(schema_module, %{"fan_out" => fan_out_string})
         when is_binary(fan_out_string) do
      fan_out_key = String.to_existing_atom(fan_out_string)
      fan_outs = Scrypath.Schema.Metadata.fan_outs(schema_module) || []

      if Keyword.has_key?(fan_outs, fan_out_key) do
        {:ok, fan_out_key}
      else
        {:error, :invalid_fan_out}
      end
    rescue
      ArgumentError -> {:error, :invalid_fan_out}
    end

    defp resolve_fan_out(_schema_module, _args), do: {:error, :invalid_fan_out}
  end
else
  defmodule Scrypath.Sync.RelatedWorker do
    @moduledoc false
  end
end
