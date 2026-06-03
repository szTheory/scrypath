defmodule Mix.Tasks.E2e.PrepareSearch do
  @shortdoc "Prepares search backend settings for E2E browser tests"

  @moduledoc """
  Applies the search index settings required by the Phase 105 browser tests.

  The browser lane exercises real Meilisearch filters, so the index must have
  declared filterable attributes before Playwright begins polling visibility.
  """

  use Mix.Task

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

      schema
      |> backend.create_index(:id, Keyword.put(config, :target_index, index))
      |> wait_or_ignore_existing(config)

      schema
      |> backend.apply_settings(index, config)
      |> wait!(config, "apply #{inspect(schema)} index settings")

      Mix.shell().info("Prepared E2E search index settings for #{index}.")
    end
  end

  defp wait_or_ignore_existing({:ok, %{task: task}}, config) do
    case Tasks.wait_for_task(task, config) do
      {:ok, _task} -> :ok
      {:error, {:task_failed, %{raw: %{"error" => %{"code" => "index_already_exists"}}}}} -> :ok
      {:error, reason} -> Mix.raise("create Product index failed: #{inspect(reason)}")
    end
  end

  defp wait_or_ignore_existing(
         {:error, {:http_error, 400, %{"code" => "index_already_exists"}}},
         _config
       ),
       do: :ok

  defp wait_or_ignore_existing(
         {:error, {:task_failed, %{raw: %{"error" => %{"code" => "index_already_exists"}}}}},
         _config
       ),
       do: :ok

  defp wait_or_ignore_existing({:error, {:http_error, 409, _payload}}, _config), do: :ok

  defp wait_or_ignore_existing({:error, reason}, _config),
    do: Mix.raise("create Product index failed: #{inspect(reason)}")

  defp wait!({:ok, %{task: task}}, config, action) do
    case Tasks.wait_for_task(task, config) do
      {:ok, _task} -> :ok
      {:error, reason} -> Mix.raise("#{action} failed: #{inspect(reason)}")
    end
  end

  defp wait!({:error, reason}, _config, action),
    do: Mix.raise("#{action} failed: #{inspect(reason)}")
end
