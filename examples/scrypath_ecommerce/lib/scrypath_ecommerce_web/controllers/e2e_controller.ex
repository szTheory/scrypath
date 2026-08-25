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
  alias ScrypathEcommerce.Catalog.Variant
  alias ScrypathEcommerce.Repo
  alias Scrypath.Meilisearch.IndexManagement
  alias Scrypath.Meilisearch.Tasks
  alias Oban.Job

  @product_schema "Elixir.ScrypathEcommerce.Catalog.Product"

  # Failed-sync reason-class fixtures for the `incident` scenario. Error strings are matched
  # verbatim by Scrypath.Operator.FailedWork's reason-class classifier — a typo silently
  # degrades a row to :unknown, so keep the signal substrings intact. Mirrors the Mix-task
  # demo seed so both seeding paths produce the same operational state.
  @failed_sync_specs [
    %{
      worker: "Scrypath.Oban.UpsertWorker",
      operation: "upsert",
      state: "discarded",
      error: "** (Ecto.CastError) cannot cast \"n/a\" to :integer for field :category_id",
      attempt: 1,
      max_attempts: 1,
      class: "validation",
      replay_payload?: true
    },
    %{
      worker: "Scrypath.Oban.UpsertWorker",
      operation: "upsert",
      state: "retryable",
      error: "** (Req.TransportError) timeout connecting to the search backend",
      attempt: 3,
      max_attempts: 20,
      class: "transport",
      replay_payload?: true
    },
    %{
      worker: "Scrypath.Oban.UpsertWorker",
      operation: "upsert",
      state: "discarded",
      error: "invalid_state: index is processing a settings update and rejected the batch",
      attempt: 5,
      max_attempts: 5,
      class: "backend_rejected",
      replay_payload?: false
    },
    %{
      worker: "Scrypath.Oban.UpsertWorker",
      operation: "upsert",
      state: "discarded",
      error: "** (RuntimeError) boom",
      attempt: 8,
      max_attempts: 8,
      class: "queue_exhausted",
      replay_payload?: false
    },
    %{
      worker: "Scrypath.Oban.DeleteWorker",
      operation: "delete",
      state: "retryable",
      error: "** (RuntimeError) unclassified delete failure from upstream",
      attempt: 2,
      max_attempts: 20,
      class: "unknown",
      replay_payload?: true
    }
  ]

  # Named operational scenarios for the screenshot/audit harness (SEED-01). Each drives
  # the operator UI into a deterministic posture covering a screen's state range:
  #   all_green  — catalog seeded + synced; no failed sync, no drift  (verdict trusts search)
  #   degraded   — catalog seeded + synced; drift only                (verdict degraded)
  #   incident   — catalog seeded + synced; failed sync + drift        (verdict can't-fully-trust)
  #   empty      — no synced products / signals                        (every empty state)
  # All are reset-safe: reset_state! clears catalog/queue and the active+target index docs;
  # prepare_search restores the declared contract before a scenario re-decides drift.
  @operational_scenarios ~w(all_green degraded incident empty)

  def seed(conn, %{"scenario" => scenario}) when scenario in @operational_scenarios do
    reset_state!()
    prepare_indexes!()

    if scenario == "empty" do
      # No catalog, no sync, no signals — render every screen's empty state.
      json(conn, %{
        scenario: scenario,
        tenant_id: nil,
        categories: %{},
        products: %{},
        failed_count: 0,
        drift: false
      })
    else
      data = CatalogFixtures.scenario_e2e_search_catalog()
      sync_products!(data.products)

      failed_count =
        if scenario == "incident", do: inject_failed_sync_classes!(data), else: 0

      drift = scenario in ["incident", "degraded"]
      if drift, do: inject_contract_drift!()

      categories_by_name = Map.new(data.categories, fn c -> {c.name, c.id} end)
      products_by_name = Map.new(data.products, fn p -> {p.name, p.id} end)

      json(conn, %{
        scenario: scenario,
        tenant_id: data.tenant.id,
        categories: categories_by_name,
        products: products_by_name,
        failed_count: failed_count,
        drift: drift
      })
    end
  end

  def seed(conn, %{"scenario" => scenario}) do
    case scenario do
      "e2e_search_catalog" ->
        # The e2e lane runs against a persistent (non-sandbox) DB + shared global
        # Meilisearch index, so reset prior catalog/queue/index state before seeding —
        # otherwise identically-named products from earlier tests accumulate and break
        # the tenant-guard / facet assertions.
        reset_state!()

        # A quantum-free control tenant so the tenant-guard test has a second tenant to
        # switch to whose catalog does NOT contain "Quantum CyberPhone X". Seeded first so
        # the deterministic e2e tenant keeps the highest id (storefront default tenant).
        _control = CatalogFixtures.scenario_demo_sparse()

        data = CatalogFixtures.scenario_e2e_search_catalog()
        prepare_swap_target!(data.products)

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
    result = drain_queue_until_idle(5, %{success: 0, failure: 0})
    json(conn, result)
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

  def product_delete(conn, %{"tenant_id" => tenant_id, "product_id" => product_id}) do
    with {:ok, tenant_id} <- parse_integer(tenant_id),
         {:ok, product_id} <- parse_integer(product_id) do
      product = Catalog.get_product!(tenant_id, product_id)

      case Catalog.delete_product(tenant_id, product) do
        {:ok, product} ->
          json(conn, %{product_id: product.id, deleted: true, queued_delete_sync: true})

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
        |> where(
          [j],
          fragment("?->>'index' = ?", j.args, ^"scrypath_ecommerce_products_#{tenant}")
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
      filters =
        opts
        |> Keyword.get(:filter, [])
        |> Keyword.put(:category_id, category_id)

      {:ok, Keyword.put(opts, :filter, filters)}
    end
  end

  defp maybe_put_category_filter(opts, _params), do: {:ok, opts}

  # Reset persistent state before a scenario seed: clear the search index documents,
  # truncate the catalog tables, and drop queued sync jobs. Index docs are cleared by the
  # ids currently in the DB (every indexed doc came from a persisted product), which clears
  # the previous scenario's documents from both the active and swap-target indexes before
  # the tables are truncated.
  defp reset_state! do
    clear_search_indexes!()

    Repo.delete_all(Variant, skip_tenant_id: true)
    Repo.delete_all(Product, skip_tenant_id: true)
    Repo.delete_all(Category, skip_tenant_id: true)
    Repo.delete_all(Tenant, skip_tenant_id: true)
    Repo.delete_all(Job, skip_tenant_id: true)
  end

  defp clear_search_indexes! do
    config = Scrypath.Config.resolve!(sync_mode: :manual)
    backend = Scrypath.Config.fetch_backend!(config)
    target_index = IndexManagement.target_index_name(Product, config)
    ids = Product |> Repo.all(skip_tenant_id: true) |> Enum.map(& &1.id)

    if ids != [] do
      clear_index_docs!(backend, ids, config)
      clear_index_docs!(backend, ids, Keyword.put(config, :index_name, target_index))
    end
  end

  defp clear_index_docs!(backend, ids, config) do
    case backend.delete_documents(Product, ids, config) do
      {:ok, %{task: %{uid: uid} = task}} when is_integer(uid) ->
        _ = Tasks.wait_for_task(task, config)
        :ok

      _ ->
        :ok
    end
  rescue
    _ -> :ok
  end

  defp prepare_swap_target!(products) do
    config = Scrypath.Config.resolve!(sync_mode: :manual)
    backend = Scrypath.Config.fetch_backend!(config)
    target_index = Scrypath.Meilisearch.IndexManagement.target_index_name(Product, config)
    target_config = Keyword.put(config, :index_name, target_index)

    Product
    |> backend.create_index(:id, target_config)
    |> wait_or_ignore_existing!(config, "create swap target")

    Product
    |> backend.apply_settings(target_index, config)
    |> wait_task!(config, "apply swap target settings")

    documents = Enum.map(products, &Scrypath.Projection.document(Product, &1))

    Product
    |> backend.upsert_documents(documents, target_config)
    |> wait_sync!(config, "seed swap target documents")
  end

  defp wait_or_ignore_existing!({:ok, %{task: task}}, config, action) do
    case Tasks.wait_for_task(task, config) do
      {:ok, _task} -> :ok
      {:error, {:task_failed, %{raw: %{"error" => %{"code" => "index_already_exists"}}}}} -> :ok
      {:error, reason} -> raise ArgumentError, "#{action} failed: #{inspect(reason)}"
    end
  end

  defp wait_or_ignore_existing!({:ok, _result}, _config, _action), do: :ok

  defp wait_or_ignore_existing!(
         {:error, {:http_error, status, %{"code" => "index_already_exists"}}},
         _config,
         _action
       )
       when status in [400, 409],
       do: :ok

  defp wait_or_ignore_existing!({:error, reason}, _config, action),
    do: raise(ArgumentError, "#{action} failed: #{inspect(reason)}")

  defp wait_task!({:ok, %{task: task}}, config, action) do
    case Tasks.wait_for_task(task, config) do
      {:ok, _task} -> :ok
      {:error, reason} -> raise ArgumentError, "#{action} failed: #{inspect(reason)}"
    end
  end

  defp wait_task!({:ok, _result}, _config, _action), do: :ok

  defp wait_task!({:error, reason}, _config, action),
    do: raise(ArgumentError, "#{action} failed: #{inspect(reason)}")

  defp wait_sync!({:ok, %{task: %{uid: uid} = task}}, config, action) when is_integer(uid) do
    case Tasks.wait_for_task(task, config) do
      {:ok, _task} -> :ok
      {:error, reason} -> raise ArgumentError, "#{action} failed: #{inspect(reason)}"
    end
  end

  defp wait_sync!({:ok, _result}, _config, _action), do: :ok

  defp wait_sync!({:error, reason}, _config, action),
    do: raise(ArgumentError, "#{action} failed: #{inspect(reason)}")

  defp drain_queue_until_idle(0, acc), do: acc

  defp drain_queue_until_idle(remaining, acc) do
    result = Oban.drain_queue(queue: :scrypath_sync)

    next = %{
      success: acc.success + result.success,
      failure: acc.failure + result.failure
    }

    if result.success == 0 and result.failure == 0 do
      next
    else
      drain_queue_until_idle(remaining - 1, next)
    end
  end

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
    config = Scrypath.Config.resolve!(sync_mode: :manual)

    case Scrypath.reconcile_sync(schema_module, sync_mode: :manual) do
      {:ok, reconcile} ->
        terminal_state =
          cond do
            reconcile.reindex.cutover == :completed -> "completed"
            recent_index_swap_succeeded?(config) -> "completed"
            reconcile.reindex.cutover == :pending -> "pending"
            true -> "not_started"
          end

        {terminal_state == "completed", terminal_state, reconcile.index, nil}

      {:error, reason} ->
        {false, "unknown", fallback_index(schema_module), classify_swap_error(reason)}
    end
  end

  defp recent_index_swap_succeeded?(config) do
    client = Keyword.get(config, :meilisearch_client) || Scrypath.Meilisearch.Client

    case client.tasks([types: ["indexSwap"]], config) do
      {:ok, %{"results" => results}} when is_list(results) ->
        Enum.any?(results, &task_succeeded?/1)

      {:ok, %{results: results}} when is_list(results) ->
        Enum.any?(results, &task_succeeded?/1)

      _ ->
        false
    end
  end

  defp task_succeeded?(task) when is_map(task) do
    (Map.get(task, "type") || Map.get(task, :type)) == "indexSwap" and
      (Map.get(task, "status") || Map.get(task, :status)) in ["succeeded", :succeeded]
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

  # ── Operational-scenario helpers (SEED-01) ───────────────────────────────────

  # Ensure the Product + Variant indexes exist with their DECLARED settings applied.
  # Re-applying settings restores the full filterable contract, undoing any drift a
  # prior `degraded`/`incident` seed injected (so re-seeding `all_green` is clean).
  defp prepare_indexes! do
    config = Scrypath.Config.resolve!(sync_mode: :manual)
    backend = Scrypath.Config.fetch_backend!(config)

    for schema <- [Product, Variant] do
      index = backend.index_name(schema, config)

      schema
      |> backend.create_index(:id, Keyword.put(config, :target_index, index))
      |> wait_or_ignore_existing!(config, "create #{inspect(schema)} index")

      schema
      |> backend.apply_settings(index, config)
      |> wait_task!(config, "apply #{inspect(schema)} settings")
    end

    :ok
  rescue
    _ -> :ok
  end

  defp sync_products!(products) do
    products = Repo.preload(products, :category, skip_tenant_id: true)

    case Scrypath.sync_records(Product, products, sync_mode: :inline, inline_timeout: 15_000) do
      {:ok, _result} -> :ok
      {:error, reason} -> raise ArgumentError, "scenario product sync failed: #{inspect(reason)}"
    end
  end

  # Insert failed Oban jobs directly (one per reason class) with hand-picked state +
  # error text so each row classifies into its intended class via FailedWork. Retryable
  # rows are parked far in the future so the running queue never executes (and re-states)
  # them. Idempotent: clears prior demo_seed_* rows first.
  defp inject_failed_sync_classes!(data) do
    tenant_id = data.tenant.id
    category_id = data.categories |> List.first() |> Map.fetch!(:id)
    product_id = data.products |> List.first() |> Map.fetch!(:id)
    index = "scrypath_ecommerce_products_#{tenant_id}"

    from(j in Job,
      where: j.queue == "scrypath_sync",
      where: fragment("?->>'scenario_key' LIKE 'demo_seed_%'", j.args)
    )
    |> Repo.delete_all(skip_tenant_id: true)

    now = DateTime.utc_now()
    far_future = DateTime.add(now, 3650 * 24 * 60 * 60, :second)

    @failed_sync_specs
    |> Enum.with_index()
    |> Enum.each(fn {spec, idx} ->
      attempted_at = DateTime.add(now, -idx * 137, :second)

      insert_failed_job!(
        spec,
        tenant_id,
        category_id,
        product_id,
        index,
        attempted_at,
        far_future
      )
    end)

    length(@failed_sync_specs)
  end

  defp insert_failed_job!(
         spec,
         tenant_id,
         category_id,
         product_id,
         index,
         attempted_at,
         far_future
       ) do
    base = %{
      "operation" => spec.operation,
      "schema" => @product_schema,
      "backend" => "Elixir.Scrypath.Meilisearch",
      "index" => index,
      "scenario_key" => "demo_seed_#{spec.class}",
      "document_count" => 1
    }

    args = Map.merge(base, replay_args(spec, tenant_id, category_id, product_id))

    errors = [
      %{
        "attempt" => spec.attempt,
        "at" => DateTime.to_iso8601(attempted_at),
        "error" => spec.error
      }
    ]

    scheduled_at = if spec.state == "retryable", do: far_future, else: attempted_at

    %Job{}
    |> Ecto.Changeset.cast(
      %{
        worker: spec.worker,
        queue: "scrypath_sync",
        args: args,
        state: spec.state,
        attempt: spec.attempt,
        max_attempts: spec.max_attempts,
        errors: errors,
        attempted_at: attempted_at,
        scheduled_at: scheduled_at,
        inserted_at: attempted_at
      },
      [
        :worker,
        :queue,
        :args,
        :state,
        :attempt,
        :max_attempts,
        :errors,
        :attempted_at,
        :scheduled_at,
        :inserted_at
      ]
    )
    |> Repo.insert!()
  end

  defp replay_args(%{replay_payload?: false}, _tenant_id, _category_id, _product_id), do: %{}

  defp replay_args(%{operation: "delete"}, _tenant_id, _category_id, product_id) do
    %{"document_ids" => [product_id]}
  end

  defp replay_args(%{operation: "upsert"}, tenant_id, category_id, product_id) do
    %{
      "document_ids" => [product_id],
      "documents" => [
        %{
          "id" => product_id,
          "source" => "fields",
          "data" => %{
            "name" => "Ops Incident Lab item",
            "description" => "Deterministic demo failure injection",
            "category_id" => category_id,
            "tenant_id" => tenant_id
          }
        }
      ]
    }
  end

  # Diverge the live index from the declared contract: drop tenant_id from filterable.
  defp inject_contract_drift! do
    config = Scrypath.Config.resolve!(sync_mode: :manual)
    backend = Scrypath.Config.fetch_backend!(config)
    index = backend.index_name(Product, config)
    patch = %{"filterableAttributes" => ["category_id"]}

    case Scrypath.Meilisearch.Client.update_settings(index, patch, config) do
      {:ok, task} -> _ = Tasks.wait_for_task(task, config)
      _ -> :ok
    end

    :ok
  rescue
    _ -> :ok
  end

  defp find_category_id(tenant_id) do
    Category
    |> where([c], c.tenant_id == ^tenant_id)
    |> limit(1)
    |> Repo.one!(skip_tenant_id: true)
    |> Map.fetch!(:id)
  end
end
