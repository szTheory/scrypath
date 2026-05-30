defmodule ScrypathEcommerceWeb.E2EController do
  use ScrypathEcommerceWeb, :controller
  import Ecto.Query

  alias Scrypath.Operator.Status
  alias ScrypathEcommerce.Catalog
  alias ScrypathEcommerce.CatalogFixtures
  alias ScrypathEcommerce.Catalog.Category
  alias ScrypathEcommerce.Catalog.Product
  alias ScrypathEcommerce.Catalog.Tenant
  alias ScrypathEcommerce.Repo

  def seed(conn, %{"scenario" => scenario}) do
    case scenario do
      "e2e_search_catalog" ->
        data = CatalogFixtures.scenario_e2e_search_catalog()
        categories_by_name = Map.new(data.categories, fn category -> {category.name, category.id} end)
        products_by_name = Map.new(data.products, fn product -> {product.name, product.id} end)

        json(conn, %{
          tenant_id: data.tenant.id,
          categories: categories_by_name,
          products: products_by_name
        })

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Unknown scenario: #{scenario}"})
    end
  end

  def drain(conn, _params) do
    result = Oban.drain_queue(queue: :scrypath_sync)
    json(conn, %{success: result.success, failure: result.failure})
  end

  def search_visible(conn, %{"tenant_id" => tenant_id, "query" => query} = params) do
    search_opts =
      [tenant_scope: [tenant_id: parse_integer!(tenant_id)]]
      |> maybe_put_category_filter(params)

    case Scrypath.search(Product, query, search_opts) do
      {:ok, result} ->
        names =
          Enum.map(result.hits, fn hit ->
            Map.get(hit, "name") || Map.get(hit, :name)
          end)

        json(conn, %{hits: names})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  def category_name(conn, %{"tenant_id" => tenant_id, "category_id" => category_id, "name" => name}) do
    tenant = Repo.get!(Tenant, parse_integer!(tenant_id), skip_tenant_id: true)
    category = Catalog.get_category!(tenant.id, parse_integer!(category_id))

    case Catalog.update_category(tenant.id, category, %{name: name}) do
      {:ok, category} ->
        json(conn, %{category_id: category.id, name: category.name, queued_related_sync: true})

      {:error, reason} -> conn |> put_status(:bad_request) |> json(%{error: inspect(reason)})
    end
  end

  def inject_failed_sync(conn, %{"tenant_id" => tenant_id}) do
    tenant = parse_integer!(tenant_id)
    category_id = find_category_id(tenant)

    job =
      Scrypath.Oban.UpsertWorker.new(
        %{
          "operation" => "upsert",
          "schema" => "Elixir.ScrypathEcommerce.Catalog.Product",
          "backend" => "Elixir.NotARealBackend",
          "index" => "scrypath_ecommerce_products_#{tenant}",
          "document_count" => 1,
          "document_ids" => [-1],
          "documents" => [
            %{
              "id" => -1,
              "source" => "fields",
              "data" => %{
                "name" => "Injected Broken Sync",
                "description" => "Intentional failure injection",
                "category_id" => category_id,
                "tenant_id" => tenant
              }
            }
          ]
        },
        queue: :scrypath_sync,
        max_attempts: 1
      )

    case Oban.insert(job) do
      {:ok, inserted_job} -> json(conn, %{job_id: inserted_job.id, queue: inserted_job.queue})
      {:error, reason} -> conn |> put_status(:bad_request) |> json(%{error: inspect(reason)})
    end
  end

  def operator_state(conn, %{"tenant_id" => tenant_id}) do
    tenant = parse_integer!(tenant_id)

    status_result =
      Scrypath.sync_status(Product,
        sync_mode: :oban,
        tenant_scope: [tenant_id: tenant],
        oban_queue: :scrypath_sync
      )

    failed_work_result =
      Scrypath.failed_sync_work(Product, sync_mode: :oban, oban_queue: :scrypath_sync)

    with {:ok, %Status{} = status} <- status_result,
         {:ok, failed_work} <- failed_work_result do
      json(conn, %{
        pending: length(status.backend.pending),
        failed: length(status.backend.failed),
        queue_failed: length(status.queue.failed),
        failed_sync_count: length(failed_work)
      })
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  defp maybe_put_category_filter(opts, %{"category_id" => category_id}) do
    Keyword.put(opts, :filter, [category_id: parse_integer!(category_id)])
  end

  defp maybe_put_category_filter(opts, _params), do: opts

  defp parse_integer!(value) when is_integer(value), do: value
  defp parse_integer!(value) when is_binary(value), do: String.to_integer(value)

  defp find_category_id(tenant_id) do
    Category
    |> where([c], c.tenant_id == ^tenant_id)
    |> limit(1)
    |> Repo.one!(skip_tenant_id: true)
    |> Map.fetch!(:id)
  end
end
