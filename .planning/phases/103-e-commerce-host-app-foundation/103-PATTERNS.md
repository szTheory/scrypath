# Phase 103: E-Commerce Host App Foundation - Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 11
**Analogs found:** 10 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/tenant.ex` | model | CRUD | `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/brand.ex` | exact |
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/category.ex` | model | CRUD | `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/brand.ex` | role-match |
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/product.ex` | model | CRUD | `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/product.ex` | exact |
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/variant.ex` | model | CRUD | `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/product.ex` | role-match |
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex` | service | CRUD | `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex` | exact |
| `examples/scrypath_ecommerce/repo.ex` | middleware | transform | No analog | none |
| `examples/scrypath_ecommerce/test/support/fixtures/catalog_fixtures.ex` | utility | test | `examples/scrypath_ecommerce/test/support/fixtures/catalog_fixtures.ex` | exact |
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/endpoint.ex` | config | request-response | `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/endpoint.ex` | exact |
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex` | route | request-response | `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex` | exact |
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` | controller | request-response | `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/page_controller.ex` | role-match |
| `examples/scrypath_ecommerce/lib/mix/tasks/scrypath.seed.ex` | task | batch | `lib/mix/tasks/scrypath.status.ex` | role-match |

## Pattern Assignments

### `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/tenant.ex` & `variant.ex` (model, CRUD)

**Analog:** `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/brand.ex`

**Model Pattern** (lines 1-10):
```elixir
defmodule ScrypathEcommerce.Catalog.Brand do
  use Ecto.Schema
  import Ecto.Changeset

  schema "brands" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end
```

**Changeset Pattern** (lines 12-16):
```elixir
  @doc false
  def changeset(brand, attrs) do
    brand
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
```

---

### `examples/scrypath_ecommerce/lib/mix/tasks/scrypath.seed.ex` (task, batch)

**Analog:** `lib/mix/tasks/scrypath.status.ex`

**Mix Task Pattern** (lines 1-22):
```elixir
defmodule Mix.Tasks.Scrypath.Status do
  use Mix.Task

  @shortdoc "Prints sync visibility for one Scrypath schema"

  @moduledoc """
  Shows pending, failed, and last-successful sync visibility for one searchable schema.
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    # Command implementation
  end
end
```

---

### `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` (controller, request-response)

**Analog:** `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/page_controller.ex`

**Controller Pattern** (lines 1-7):
```elixir
defmodule ScrypathEcommerceWeb.PageController do
  use ScrypathEcommerceWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
```
*(Note: From RESEARCH.md, we will be responding with `json(conn, %{status: "ok", data: data})`)*

---

## Shared Patterns

### Entity Relations (Belongs To)
**Source:** `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/product.ex`
**Apply to:** Models (`Category`, `Variant`, `Product`)
```elixir
  schema "products" do
    # ...
    belongs_to :brand, ScrypathEcommerce.Catalog.Brand
    belongs_to :category, ScrypathEcommerce.Catalog.Category
```

### Context CRUD API
**Source:** `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex`
**Apply to:** `catalog.ex` (Updating APIs to require `tenant` scope)
```elixir
  def list_brands do
    Repo.all(Brand)
  end
  # Note: To be updated to `list_brands(%Tenant{} = tenant)`
```

### Sandbox Config & Seed Endpoint
**Source:** `103-RESEARCH.md`
**Apply to:** `endpoint.ex`, `router.ex`, `e2e_controller.ex`
```elixir
# lib/scrypath_ecommerce_web/endpoint.ex
if sandbox = Application.compile_env(:scrypath_ecommerce, :sandbox) do
  plug Phoenix.Ecto.SQL.Sandbox, sandbox: sandbox
end
```

### `prepare_query` Tenancy Check
**Source:** `103-RESEARCH.md`
**Apply to:** `repo.ex`
```elixir
@impl true
def prepare_query(_operation, query, opts) do
  cond do
    opts[:skip_tenant_id] || opts[:schema_migration] ->
      {query, opts}
    tenant_id = opts[:tenant_id] ->
      {Ecto.Query.where(query, tenant_id: ^tenant_id), opts}
    true ->
      raise ArgumentError, "expected :tenant_id or :skip_tenant_id option in Repo operation"
  end
end
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `examples/scrypath_ecommerce/repo.ex` | middleware | transform | First introduction of `prepare_query/3` pattern into the Repo. Provided by RESEARCH.md. |

## Metadata

**Analog search scope:** `examples/scrypath_ecommerce/lib/**/*.ex` and `lib/mix/tasks/*.ex`
**Files scanned:** ~50
**Pattern extraction date:** 2026-05-30
