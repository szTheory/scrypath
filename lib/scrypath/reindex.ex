defmodule Scrypath.Reindex do
  @moduledoc false

  alias Scrypath.Options

  @spec run(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(schema_module, opts \\ []) do
    meilisearch = Keyword.get(opts, :meilisearch, Scrypath.Meilisearch)
    backfill = Keyword.get(opts, :backfill, Scrypath.Backfill)
    config = Options.validate_reindex_options!(Keyword.drop(opts, [:meilisearch, :backfill]))
    backend = Keyword.fetch!(config, :backend)
    live_index = backend.index_name(schema_module, config)
    target_index = Keyword.get(config, :target_index) || "#{live_index}__reindex"
    workflow_config = Keyword.put(config, :target_index, target_index)

    with {:ok, _create_result} <-
           meilisearch.create_index(schema_module, primary_key(schema_module), workflow_config),
         {:ok, _settings_result} <-
           meilisearch.apply_settings(schema_module, target_index, workflow_config),
         {:ok, backfill_result} <-
           backfill.run(schema_module, Keyword.put(workflow_config, :index_name, target_index)),
         {:ok, cutover} <- maybe_cutover(schema_module, workflow_config, meilisearch) do
      {:ok,
       %{
         live_index: live_index,
         target_index: target_index,
         settings_applied: true,
         batches: Map.fetch!(backfill_result, :batches),
         documents: Map.fetch!(backfill_result, :documents),
         cutover: cutover
       }}
    end
  end

  defp maybe_cutover(schema_module, config, meilisearch) do
    if Keyword.get(config, :cutover?) do
      case meilisearch.swap_indexes(schema_module, config) do
        {:ok, _result} -> {:ok, true}
        {:error, reason} -> {:error, reason}
      end
    else
      {:ok, false}
    end
  end

  defp primary_key(schema_module) do
    case schema_module.__schema__(:primary_key) do
      [field | _rest] -> field
      [] -> Scrypath.document_id_field(schema_module)
    end
  end
end
