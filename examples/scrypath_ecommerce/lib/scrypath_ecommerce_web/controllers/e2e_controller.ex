defmodule ScrypathEcommerceWeb.E2EObanInspector do
  import Ecto.Query

  alias Oban.Job
  alias ScrypathEcommerce.Repo

  def list_jobs(schema_module, config) do
    schema = Atom.to_string(schema_module)
    queue = config[:oban_queue] |> to_string()

    jobs =
      Job
      |> where([j], j.queue == ^queue)
      |> where([j], fragment("?->>'schema' = ?", j.args, ^schema))
      |> order_by([j], desc: j.id)
      |> limit(100)
      |> Repo.all(skip_tenant_id: true)
      |> Enum.map(fn job ->
        %{
          id: job.id,
          state: job.state,
          worker: job.worker,
          queue: job.queue,
          args: job.args,
          errors: job.errors,
          attempt: job.attempt,
          max_attempts: job.max_attempts,
          attempted_at: job.attempted_at
        }
      end)

    {:ok, jobs}
  end
end

defmodule ScrypathEcommerceWeb.E2EController do
  use ScrypathEcommerceWeb, :controller
  import Ecto.Query

  alias ScrypathEcommerce.Catalog
  alias ScrypathEcommerce.CatalogFixtures
  alias ScrypathEcommerce.Catalog.Category
  alias ScrypathEcommerce.Catalog.Product
  alias ScrypathEcommerce.Catalog.Tenant
  alias ScrypathEcommerce.Repo
  alias Oban.Job

  def seed(conn, %{"scenario" => scenario}) do
    case scenario do
      "e2e_search_catalog" ->
        data = CatalogFixtures.scenario_e2e_search_catalog()

        categories_by_name =
          Map.new(data.categories, fn category -> {category.name, category.id} end)

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
    with {:ok, tenant_id} <- parse_integer(tenant_id),
         {:ok, search_opts} <-
           [filter: [tenant_id: tenant_id]]
           |> maybe_put_category_filter(params),
         {:ok, result} <- Scrypath.search(Product, query, search_opts) do
      names =
        Enum.map(result.hits, fn hit ->
          Map.get(hit, "name") || Map.get(hit, :name)
        end)

      json(conn, %{hits: names})
    else
      {:error, :invalid_integer} ->
        invalid_integer(conn)

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  def category_name(conn, %{
        "tenant_id" => tenant_id,
        "category_id" => category_id,
        "name" => name
      }) do
    with {:ok, tenant_id} <- parse_integer(tenant_id),
         {:ok, category_id} <- parse_integer(category_id) do
      tenant = Repo.get!(Tenant, tenant_id, skip_tenant_id: true)
      category = Catalog.get_category!(tenant.id, category_id)

      case Catalog.update_category(tenant.id, category, %{name: name}) do
        {:ok, category} ->
          json(conn, %{category_id: category.id, name: category.name, queued_related_sync: true})

        {:error, reason} ->
          conn |> put_status(:bad_request) |> json(%{error: inspect(reason)})
      end
    else
      {:error, :invalid_integer} -> invalid_integer(conn)
    end
  end

  def inject_failed_sync(conn, %{"tenant_id" => tenant_id} = params) do
    with {:ok, tenant} <- parse_integer(tenant_id) do
      category_id = find_category_id(tenant)
      scenario_key = Map.get(params, "scenario_key", "default")

      existing_job =
        Job
        |> where([j], j.queue == "scrypath_sync")
        |> where(
          [j],
          fragment("?->>'schema' = ?", j.args, "Elixir.ScrypathEcommerce.Catalog.Product")
        )
        |> where([j], fragment("?->>'scenario_key' = ?", j.args, ^scenario_key))
        |> order_by([j], desc: j.id)
        |> limit(1)
        |> Repo.one(skip_tenant_id: true)

      job_id =
        case existing_job do
          %Job{id: id} ->
            id

          nil ->
            job =
              Scrypath.Oban.UpsertWorker.new(
                %{
                  "operation" => "upsert",
                  "schema" => "Elixir.ScrypathEcommerce.Catalog.Product",
                  "backend" => "Elixir.NotARealBackend",
                  "index" => "scrypath_ecommerce_products_#{tenant}",
                  "scenario_key" => scenario_key,
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
              {:ok, inserted_job} ->
                inserted_job.id

              {:error, reason} ->
                raise ArgumentError, "inject_failed_sync failed: #{inspect(reason)}"
            end
        end

      _ = Oban.drain_queue(queue: :scrypath_sync)

      with {:ok, failed_work} <-
             Scrypath.failed_sync_work(Product,
               sync_mode: :oban,
               oban_queue: :scrypath_sync,
               oban_inspector: ScrypathEcommerceWeb.E2EObanInspector
             ) do
        row =
          Enum.find(failed_work, fn fw -> to_string(fw.id) == to_string(job_id) end) ||
            Enum.find(failed_work, fn fw ->
              to_string(fw.schema) == "Elixir.ScrypathEcommerce.Catalog.Product"
            end)

        json(conn, %{
          failed_work_id: if(row, do: row.id, else: job_id),
          schema:
            if(row,
              do: Atom.to_string(row.schema),
              else: "Elixir.ScrypathEcommerce.Catalog.Product"
            ),
          state: if(row, do: Atom.to_string(row.state), else: "failed"),
          reason_class: if(row, do: Atom.to_string(row.reason_class || :unknown), else: "unknown")
        })
      else
        {:error, reason} ->
          conn |> put_status(:bad_request) |> json(%{error: inspect(reason)})
      end
    else
      {:error, :invalid_integer} -> invalid_integer(conn)
    end
  end

  def operator_state(conn, %{"tenant_id" => tenant_id}) do
    with {:ok, tenant} <- parse_integer(tenant_id) do
      {swap_terminal_success, swap_terminal_state, active_index, swap_error} = swap_probe(Product)
      active_index_visible = active_index_visible?(tenant)

      with {:ok, failed_work} <-
             Scrypath.failed_sync_work(Product,
               sync_mode: :oban,
               oban_queue: :scrypath_sync,
               oban_inspector: ScrypathEcommerceWeb.E2EObanInspector
             ) do
        first = List.first(failed_work)
        reason_class_counts = Scrypath.Operator.FailedWork.reason_class_counts(failed_work)

        json(conn, %{
          failed_count: length(failed_work),
          first_failed_work_id: if(first, do: first.id, else: nil),
          reason_class_counts: reason_class_counts.by_class,
          retryable: Enum.any?(failed_work, & &1.retryable?),
          swap_terminal_success: swap_terminal_success,
          swap_terminal_state: swap_terminal_state,
          active_index: active_index,
          active_index_visible: active_index_visible,
          swap_error_class: swap_error
        })
      else
        {:error, reason} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: inspect(reason)})
      end
    else
      {:error, :invalid_integer} -> invalid_integer(conn)
    end
  end

  defp maybe_put_category_filter(opts, %{"category_id" => category_id}) do
    with {:ok, category_id} <- parse_integer(category_id) do
      {:ok, Keyword.put(opts, :filter, category_id: category_id)}
    end
  end

  defp maybe_put_category_filter(opts, _params), do: {:ok, opts}

  defp parse_integer(value) when is_integer(value), do: {:ok, value}

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _ -> {:error, :invalid_integer}
    end
  end

  defp parse_integer(_value), do: {:error, :invalid_integer}

  defp invalid_integer(conn) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "invalid integer parameter"})
  end

  defp swap_probe(schema_module) do
    case Scrypath.reconcile_sync(schema_module, sync_mode: :manual) do
      {:ok, reconcile} ->
        terminal_state =
          case reconcile.reindex.cutover do
            :completed -> "completed"
            :pending -> "pending"
            :not_started -> "not_started"
          end

        {reconcile.reindex.cutover == :completed, terminal_state, reconcile.index, nil}

      {:error, reason} ->
        {false, "unknown", fallback_index(schema_module), classify_swap_error(reason)}
    end
  end

  defp fallback_index(schema_module) do
    Scrypath.Config.resolve!(sync_mode: :manual)
    |> Scrypath.Config.fetch_backend!()
    |> then(& &1.index_name(schema_module, sync_mode: :manual))
  end

  defp classify_swap_error({:transport_failed, _}), do: "transport"
  defp classify_swap_error({:http_error, _}), do: "backend"
  defp classify_swap_error({:unsupported_operator_backend, _}), do: "unsupported_backend"
  defp classify_swap_error(_), do: "unknown"

  defp active_index_visible?(tenant_id) do
    case Scrypath.search(Product, "CyberPhone", filter: [tenant_id: tenant_id]) do
      {:ok, result} ->
        Enum.any?(result.hits, fn hit ->
          value = Map.get(hit, "name") || Map.get(hit, :name)
          is_binary(value) and String.contains?(value, "CyberPhone")
        end)

      {:error, _reason} ->
        false
    end
  end

  defp find_category_id(tenant_id) do
    Category
    |> where([c], c.tenant_id == ^tenant_id)
    |> limit(1)
    |> Repo.one!(skip_tenant_id: true)
    |> Map.fetch!(:id)
  end
end
