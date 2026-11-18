defmodule Scrypath.Sync.RelatedEnqueue do
  @moduledoc false

  alias Scrypath.Chunks
  alias Scrypath.Identity
  alias Scrypath.Loader
  alias Scrypath.Oban.Enqueue
  alias Scrypath.Oban.Payload
  alias Scrypath.Operations.Result

  @worker "Scrypath.Sync.RelatedWorker"

  @spec enqueue(module(), struct() | [struct()], atom(), keyword()) ::
          {:ok, Scrypath.Operations.Result.t()} | {:error, term()}
  def enqueue(schema_module, records, fan_out_key, config) do
    Enqueue.ensure_durable_api_key!(config)
    # The worker loads current trigger records before resolving, so a missing repo or
    # an unmappable custom document id must fail here, not inside the job.
    Loader.ensure_loadable!(schema_module, config)

    case Identity.document_ids(schema_module, List.wrap(records)) do
      [] ->
        # Sync.sync_related/3 already short-circuits empty input; kept as a guard.
        {:ok,
         Result.new(
           mode: Keyword.fetch!(config, :sync_mode),
           status: :noop,
           document_ids: [],
           document_count: 0
         )}

      document_ids ->
        # One job per bounded, sorted chunk of the ids as the job stores them, under the
        # same unique policy and transactional insert as the main sync jobs. The shared
        # builder raises a clear ArgumentError when Oban is not installed.
        document_ids
        |> Payload.serialize_ids!()
        |> Chunks.ids()
        |> Enum.map(fn chunk ->
          Enqueue.job_changeset(
            job_args(schema_module, chunk, fan_out_key, config),
            @worker,
            config,
            []
          )
        end)
        |> Enqueue.enqueue_chunks(config, %{})
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
end
