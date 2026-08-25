defmodule Mix.Tasks.Scrypath.Demo.Seed do
  @shortdoc "Seeds the Scrypath e-commerce showcase catalog"

  @moduledoc """
  Seeds a richer multi-tenant catalog for the click-around Scrypath demo.

      mix scrypath.demo.seed
      mix scrypath.demo.seed --scenario all_green
      mix scrypath.demo.seed --scenario degraded
      mix scrypath.demo.seed --scenario incident   # default
      mix scrypath.demo.seed --scenario empty

  The task creates deterministic demo tenants, prepares Meilisearch settings, and
  syncs product documents inline so the storefront is immediately searchable.

  ## Named operational scenarios (`--scenario`)

  Each scenario parameterizes the SAME catalog + injection logic so the operator
  UI can be driven into a deterministic posture covering every screen's state
  range. The catalog fixtures are unchanged between scenarios; only the
  injected operational signals (failed sync + contract drift + whether products
  are synced) differ:

    * `all_green` — full catalog seeded + synced; NO failed-sync injection, NO
      drift. Posture reads all-healthy, the verdict trusts search.
    * `degraded` — catalog seeded + synced; contract drift injected (the live
      index drops a declared filterable) but NO failed-sync. Posture shows a
      partial/warning, the verdict is degraded.
    * `incident` (default) — all reason classes of failed-sync work injected
      (transport / validation / backend / queue / unknown, mixing retryable and
      terminal jobs) PLUS contract drift. Posture reads red, the verdict can't
      fully trust search. This preserves the historical `make dev` / E2E
      behavior.
    * `empty` — catalog tables truncated and the live index cleared after
      preparation; NO products synced, NO failed work, NO drift. Every screen
      renders its empty state (no synced schemas / no failed work / no results /
      empty playbook workspace).

  All injections are idempotent and reset-safe across re-runs (the task drops
  `demo_seed_*` Oban jobs and resets catalog tables before reseeding).
  """

  use Mix.Task

  import Ecto.Query

  alias ScrypathEcommerce.CatalogFixtures
  alias ScrypathEcommerce.Catalog.{Category, Product, Tenant, Variant}
  alias ScrypathEcommerce.Repo

  @product_schema "Elixir.ScrypathEcommerce.Catalog.Product"

  # Error strings are matched verbatim by Scrypath.Operator.FailedWork's reason-class
  # classifier (lib/scrypath/operator/failed_work.ex). A typo silently degrades a
  # row to :unknown, so keep the signal substrings ("Ecto.CastError", "timeout",
  # "invalid_state", etc.) intact.
  @failed_sync_specs [
    %{
      class: "validation",
      worker: "Scrypath.Oban.UpsertWorker",
      operation: "upsert",
      state: "discarded",
      error: "** (Ecto.CastError) cannot cast \"n/a\" to :integer for field :category_id",
      attempt: 1,
      max_attempts: 1,
      replay_payload?: true
    },
    %{
      class: "transport",
      worker: "Scrypath.Oban.UpsertWorker",
      operation: "upsert",
      state: "retryable",
      error: "** (Req.TransportError) timeout connecting to the search backend",
      attempt: 3,
      max_attempts: 20,
      replay_payload?: true
    },
    %{
      class: "backend_rejected",
      worker: "Scrypath.Oban.UpsertWorker",
      operation: "upsert",
      state: "discarded",
      error: "invalid_state: index is processing a settings update and rejected the batch",
      attempt: 5,
      max_attempts: 5,
      replay_payload?: false
    },
    %{
      class: "queue_exhausted",
      worker: "Scrypath.Oban.UpsertWorker",
      operation: "upsert",
      state: "discarded",
      error: "** (RuntimeError) boom",
      attempt: 8,
      max_attempts: 8,
      replay_payload?: false
    },
    %{
      class: "unknown",
      worker: "Scrypath.Oban.DeleteWorker",
      operation: "delete",
      state: "retryable",
      error: "** (RuntimeError) unclassified delete failure from upstream",
      attempt: 2,
      max_attempts: 20,
      replay_payload?: true
    }
  ]

  @scenarios ~w(all_green degraded incident empty)
  @default_scenario "incident"

  @impl true
  def run(args) do
    scenario = parse_scenario!(args)

    Mix.Task.run("app.start")
    Mix.Task.run("e2e.prepare_search")
    reset_demo_data!()

    showcase = CatalogFixtures.scenario_demo_showcase(%{name: "Nova Outfitters"})
    ops = CatalogFixtures.scenario_e2e_search_catalog(%{name: "Ops Incident Lab"})
    sparse = CatalogFixtures.scenario_demo_sparse(%{name: "Quiet Branch Supply"})

    {variant_count, failed_count, drift_status} =
      apply_scenario!(scenario, [showcase, ops, sparse], ops)

    Mix.shell().info("""
    Scrypath e-commerce demo seeded (scenario: #{scenario}).

    Tenants:
      - #{showcase.tenant.name}: #{length(showcase.products)} products across #{length(showcase.categories)} categories
      - #{ops.tenant.name}: #{length(ops.products)} deterministic E2E products
      - #{sparse.tenant.name}: #{length(sparse.products)} low-volume product

    Search indices:
      - Product + Variant (SKU) indices synced; #{variant_count} variant documents
        light up multi-index / federation across the allowlist.

    Operator signals (Ops Incident Lab):
      - Failed sync work: #{failed_count} jobs across transport/validation/backend/queue/unknown
      - Contract drift: #{drift_status}

    Open the storefront at / and OPSUI at /admin/search/ (Control Room).
    """)
  end

  defp parse_scenario!(args) do
    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [scenario: :string])
    scenario = opts[:scenario] || @default_scenario

    unless scenario in @scenarios do
      Mix.raise(
        "Unknown --scenario #{inspect(scenario)}. Expected one of: #{Enum.join(@scenarios, ", ")}"
      )
    end

    scenario
  end

  # Parameterize the shared catalog + injection logic per named operational scenario.
  # The catalog fixtures are identical across scenarios; only sync state + injected
  # signals differ. Returns {variant_count, failed_count, drift_status}.

  # empty: clear the live index + truncate the catalog so every screen renders its
  # empty state — no synced schemas, no failed work, no drift, no results.
  defp apply_scenario!("empty", _scenarios, _ops) do
    clear_product_index!()
    reset_demo_data!()
    {0, 0, "none (empty scenario — no synced products)"}
  end

  defp apply_scenario!(scenario, scenarios, ops) do
    scenarios
    |> Enum.flat_map(& &1.products)
    |> preload_categories()
    |> sync_products!()

    variant_count = sync_variants!()

    failed_count =
      if scenario == "incident", do: inject_failed_sync_work!(ops), else: 0

    drift_status =
      if scenario in ["incident", "degraded"],
        do: inject_contract_drift!(),
        else: "none (#{scenario} scenario — declared contract matches live index)"

    {variant_count, failed_count, drift_status}
  end

  defp preload_categories(products) do
    Repo.preload(products, :category, skip_tenant_id: true)
  end

  defp reset_demo_data! do
    Repo.delete_all(Variant, skip_tenant_id: true)
    Repo.delete_all(Product, skip_tenant_id: true)
    Repo.delete_all(Category, skip_tenant_id: true)
    Repo.delete_all(Tenant, skip_tenant_id: true)
  end

  defp sync_products!(products) do
    case Scrypath.sync_records(Product, products, sync_mode: :inline, inline_timeout: 15_000) do
      {:ok, _result} -> :ok
      {:error, reason} -> Mix.raise("demo product sync failed: #{inspect(reason)}")
    end
  end

  # Sync the SKU/Variant index so the allowlist holds >1 schema: Posture shows a second
  # row, Search multi-index/federation lights up, and the federated playbook can run.
  # Variants are read back from the DB (the fixtures already persisted them) and synced
  # with `:product` preloaded so the denormalized product_name is searchable.
  defp sync_variants! do
    prepare_variant_index!()

    variants =
      Variant
      |> Repo.all(skip_tenant_id: true)
      |> Repo.preload(:product, skip_tenant_id: true)

    case Scrypath.sync_records(Variant, variants, sync_mode: :inline, inline_timeout: 15_000) do
      {:ok, _result} -> length(variants)
      {:error, reason} -> Mix.raise("demo variant sync failed: #{inspect(reason)}")
    end
  end

  # Create + apply settings for the Variant index (mirrors `e2e.prepare_search` for
  # Product, kept here so the deterministic E2E lane stays Product-only). Tolerant:
  # an already-existing index or a missing backend must not abort seeding.
  defp prepare_variant_index! do
    config = Scrypath.Config.resolve!(sync_mode: :manual)
    backend = Scrypath.Config.fetch_backend!(config)
    index = backend.index_name(Variant, config)

    _ =
      Variant
      |> backend.create_index(:id, Keyword.put(config, :target_index, index))
      |> wait_variant_task(config)

    _ =
      Variant
      |> backend.apply_settings(index, config)
      |> wait_variant_task(config)

    :ok
  rescue
    error ->
      Mix.shell().info("Variant index prep skipped (#{Exception.message(error)})")
      :ok
  end

  defp wait_variant_task({:ok, %{task: task}}, config) do
    Scrypath.Meilisearch.Tasks.wait_for_task(task, config)
  end

  defp wait_variant_task(other, _config), do: other

  # ── Failed sync work injection ───────────────────────────────────────────────
  #
  # The demo's Failed Sync page reads discarded/retryable Oban jobs for Product via
  # ScrypathEcommerceWeb.E2EObanInspector. We insert rows directly (rather than
  # draining real workers, which only ever yields :unknown) with hand-picked state +
  # error text so each row classifies into the intended reason class.

  defp inject_failed_sync_work!(ops) do
    tenant_id = ops.tenant.id
    category_id = ops.categories |> List.first() |> Map.fetch!(:id)
    product_id = ops.products |> List.first() |> Map.fetch!(:id)
    index = product_index_name()

    # Idempotency: drop any previously seeded demo failures before reinserting.
    from(j in Oban.Job,
      where: j.queue == "scrypath_sync",
      where: fragment("?->>'scenario_key' LIKE 'demo_seed_%'", j.args)
    )
    |> Repo.delete_all(skip_tenant_id: true)

    now = DateTime.utc_now()
    # Retryable rows are parked far in the future so the running scrypath_sync queue
    # never executes them (which would flip their state); they still list via the inspector.
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
    args =
      Map.merge(base_args(spec, index), replay_args(spec, tenant_id, category_id, product_id))

    errors = [
      %{
        "attempt" => spec.attempt,
        "at" => DateTime.to_iso8601(attempted_at),
        "error" => spec.error
      }
    ]

    scheduled_at = if spec.state == "retryable", do: far_future, else: attempted_at

    %Oban.Job{}
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

  defp base_args(spec, index) do
    %{
      "operation" => spec.operation,
      "schema" => @product_schema,
      "backend" => "Elixir.Scrypath.Meilisearch",
      "index" => index,
      "scenario_key" => "demo_seed_#{spec.class}",
      "document_count" => 1
    }
  end

  # Only retryable rows carry a replay payload; its presence is exactly what
  # FailedWork uses to decide `retryable?` (and thus whether Retry is offered).
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

  # ── Contract drift injection ─────────────────────────────────────────────────
  #
  # Diverge the LIVE index from the declared schema contract so Sync / drift shows a
  # real dimension mismatch. Product declares filterable [:category_id, :tenant_id];
  # we patch the live index to drop tenant_id. Requires a live Meilisearch (already a
  # hard dependency of the demo); failures are tolerated so seeding still completes.

  defp inject_contract_drift! do
    config = Scrypath.Config.resolve!(sync_mode: :manual)
    index = product_index_name(config)
    patch = %{"filterableAttributes" => ["category_id"]}

    case Scrypath.Meilisearch.Client.update_settings(index, patch, config) do
      {:ok, task} ->
        _ = Scrypath.Meilisearch.Tasks.wait_for_task(task, config)
        "live index dropped a declared filterable attribute"

      {:error, reason} ->
        "skipped (#{inspect(reason)})"
    end
  rescue
    error -> "skipped (#{Exception.message(error)})"
  end

  defp product_index_name(config \\ Scrypath.Config.resolve!(sync_mode: :manual)) do
    backend = Scrypath.Config.fetch_backend!(config)
    backend.index_name(Product, config)
  end

  # ── Empty-scenario index clear ───────────────────────────────────────────────
  #
  # Remove every product document currently in the active index so the `empty`
  # scenario truly renders empty states (no synced documents). Called before the
  # catalog tables are truncated so the in-DB ids still resolve the indexed docs.
  # Tolerant: a missing backend / index must not abort seeding.
  defp clear_product_index! do
    config = Scrypath.Config.resolve!(sync_mode: :manual)
    backend = Scrypath.Config.fetch_backend!(config)
    ids = Product |> Repo.all(skip_tenant_id: true) |> Enum.map(& &1.id)

    if ids != [] do
      case backend.delete_documents(Product, ids, config) do
        {:ok, %{task: task}} -> _ = Scrypath.Meilisearch.Tasks.wait_for_task(task, config)
        _ -> :ok
      end
    end

    :ok
  rescue
    _ -> :ok
  end
end
