defmodule Mix.Tasks.E2e.PrepareSearch do
  @shortdoc "Prepares search backend settings for E2E browser tests"

  @moduledoc """
  Applies the search index settings required by the Phase 105 browser tests.

  The browser lane exercises real Meilisearch filters, so the index must have
  declared filterable attributes before Playwright begins polling visibility.
  """

  use Mix.Task

  alias Scrypath.Meilisearch.Client
  alias Scrypath.Meilisearch.TaskPayload
  alias Scrypath.Meilisearch.Tasks
  alias ScrypathEcommerce.Catalog.Product
  alias ScrypathEcommerce.Catalog.Variant

  # Both schemas the operator UI federates over (Search & federation / multi-index). The
  # index must exist before Playwright runs a multi-index probe, or Meilisearch returns
  # index_not_found for the un-prepared schema and the whole federation errors.
  @schemas [Product, Variant]

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")

    config = Scrypath.Config.resolve!(sync_mode: :manual)
    backend = Scrypath.Config.fetch_backend!(config)

    for schema <- @schemas do
      index = backend.index_name(schema, config)

      ensure_index!(index, config)

      schema
      |> backend.apply_settings(index, config)
      |> wait!(config, "apply #{inspect(schema)} index settings")

      Mix.shell().info("Prepared E2E search index settings for #{index}.")
    end
  end

  defp ensure_index!(index, config) do
    case Client.get_settings(index, config) do
      {:ok, _settings} ->
        :ok

      {:error, {:http_error, 404, _}} ->
        result =
          with {:ok, response} <- Client.create_index(index, :id, config),
               {:ok, task} <- TaskPayload.normalize(response) do
            {:ok, %{task: task}}
          end

        wait!(result, config, "create #{index}")

      {:error, reason} ->
        Mix.raise("inspect #{index} failed: #{inspect(reason)}")
    end
  end

  defp wait!({:ok, %{task: task}}, config, action) when is_map(task) do
    case Tasks.wait_for_task(task, config) do
      {:ok, _task} -> :ok
      {:error, reason} -> Mix.raise("#{action} failed: #{inspect(reason)}")
    end
  end

  defp wait!({:ok, result}, _config, action),
    do: Mix.raise("#{action} returned no task: #{inspect(result)}")

  defp wait!({:error, reason}, _config, action),
    do: Mix.raise("#{action} failed: #{inspect(reason)}")
end
