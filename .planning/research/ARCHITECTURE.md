# Architecture Patterns: Realistic Demo App & Admin UI Proof (v1.28)

**Domain:** Elixir Open-Source Library (Declarative Search Indexing)
**Researched:** 2026-05-30
**Confidence:** HIGH

## Executive Summary

To achieve the v1.28 milestone ("Realistic Demo App & Admin UI Proof") with Elixir ecosystem excellence, we must bridge the gap between `scrypath_ops` (the admin UI) and how adopters actually consume LiveView dashboards. Currently, `scrypath_ops` exists as a standalone companion app. To provide the principle of least surprise and best-in-class developer ergonomics (DX), **we must refactor `scrypath_ops` into a mountable router engine** (similar to `Phoenix.LiveDashboard` or `Oban.Web`), and integrate it directly into `examples/scrypath_ecommerce`.

Coupled with a robust, Playwright-backed CI/CD pipeline, this proves to adopters that Scrypath scales gracefully in real-world, production-shaped applications without operational headaches.

---

## 1. Architectural Decision: Mountable Admin UI

### The Anti-Pattern: Standalone Sidecar App
Running `scrypath_ops` as a completely separate Phoenix application requires adopters to manage parallel deployments, maintain double DB connection pools, reimplement authentication natively within the sidecar, and use compile-time `runtime: false` hacks just to share Ecto schemas. This does not feel "native to the Elixir ecosystem".

### The Recommended Pattern: Mountable Engine
We will convert `scrypath_ops` into a library that provides a router macro, allowing adopters to mount the UI directly into their existing `router.ex`.

**Component Boundaries:**
| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `scrypath` | Core library, purely data/Ecto-driven. | Ecto Repo, Meilisearch HTTP API. |
| `scrypath_ops` | LiveView UI components for observability/operations. | `scrypath` APIs. |
| `examples/scrypath_ecommerce` | The "host" demo app. | Mounts `scrypath_ops`, provides Ecto schemas, provides user Auth. |

**Example Integration in Demo App:**
```elixir
# examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex
defmodule ScrypathEcommerceWeb.Router do
  use ScrypathEcommerceWeb, :router
  import ScrypathOps.Router

  # Existing host app auth mechanism protects the route natively!
  pipeline :require_admin do
    plug ScrypathEcommerceWeb.Plugs.RequireAdmin
  end

  scope "/admin", ScrypathEcommerceWeb do
    pipe_through [:browser, :require_admin]
    
    # Mounts the ops UI and injects the allowlisted schemas
    scrypath_ops "/search", schemas: [ScrypathEcommerce.Catalog.Product]
  end
end
```

**Why this is the perfect solution:**
- **DX:** Adopters don't have to deploy a separate Docker container for the admin panel.
- **Security:** Natively utilizes the host app's authentication and authorization pipelines (Plugs).
- **Simplicity:** Eliminates the `scrypath_ecommerce` path-dependency from `scrypath_ops/mix.exs`. The host application directly passes in the schema allowlist.

---

## 2. CI/CD Architecture & Playwright E2E Best Practices

For an Elixir OSS library testing against a real Meilisearch instance, the CI must be fast, deterministic, and hermetic. 

### Recommended CI/CD Pipeline Additions

We will introduce a dedicated `e2e_playwright_smoke` job to `.github/workflows/ci.yml`.

**Key Practices:**
1. **GitHub Actions Services:** Continue using native `services:` for `postgres:16-alpine` and `getmeili/meilisearch:v1.15`. This avoids the flaky complexity of starting services via bash scripts or Docker-in-Docker.
2. **Setup-Beam & Cache:** Use `erlef/setup-beam@v1` with strict exact versions. Cache `_build`, `deps`, AND Playwright's browser binaries (`~/.cache/ms-playwright`).
3. **Playwright Integration:** Use Playwright natively within the `scrypath_ecommerce` demo app. Tests should live in `examples/scrypath_ecommerce/test/e2e/`.
4. **Compile Constraints:** Ensure E2E tests run on a build with `--warnings-as-errors`.

**Example CI Job Definition:**
```yaml
  e2e_playwright_smoke:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports:
          - 5433:5432
      meilisearch:
        image: getmeili/meilisearch:v1.15
        ports:
          - 7700:7700
        env:
          MEILI_NO_ANALYTICS: "true"
    env:
      PGPORT: "5433"
      SCRYPATH_MEILISEARCH_URL: http://127.0.0.1:7700
    steps:
      - uses: actions/checkout@v6
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.19.0"
          otp-version: "28.1"
      - uses: actions/cache@v5
        with:
          path: |
            deps
            _build
            examples/scrypath_ecommerce/deps
            examples/scrypath_ecommerce/_build
          key: ${{ runner.os }}-e2e-${{ hashFiles('**/mix.lock') }}
      - uses: actions/cache@v5
        with:
          path: ~/.cache/ms-playwright
          key: ${{ runner.os }}-playwright-${{ hashFiles('examples/scrypath_ecommerce/package.json') }}
      - name: Wait for Postgres & Meilisearch
        run: | # Standard bash wait loops as currently used...
      - name: Run Playwright Tests
        working-directory: examples/scrypath_ecommerce
        run: |
          mix deps.get
          npm ci
          npx playwright install --with-deps
          mix ecto.setup
          mix test.e2e # Custom alias invoking playwright
```

### E2E Testing Scope
The Playwright harness should target the "golden path":
1. **Host App Integrity:** User adds a product via the ecommerce admin form.
2. **Search Parity:** User searches for the product on the ecommerce storefront and verifies it appears (verifying Ecto->Meilisearch background sync).
3. **Ops UI Verification:** Admin logs into the mounted `/admin/search` (`scrypath_ops`) route and verifies the document exists in the index playground, proving the operator shell functions natively inside the host app.

---

## 3. Pitfalls & Anti-Patterns to Avoid

### Anti-Pattern 1: E2E Testing without a Populated DB
**What goes wrong:** Tests boot up, assert the page says "No results", and pass. You get high coverage but zero confidence in the search integration.
**Instead:** Run `mix run priv/repo/seeds.exs` or use specific Ecto factories in the Playwright setup phase before running assertions. Playwright tests must assert against populated, real-world data shapes.

### Anti-Pattern 2: Manually Managing Background Phoenix Servers in CI
**What goes wrong:** E2E CI jobs start a `mix phx.server &` in the background, which leaks processes, swallows logs, and causes intermittent port-binding failures.
**Instead:** Utilize Elixir ecosystem tools like `PhoenixTest.Playwright` (as seen in `sigra` dependencies) or use Playwright's native `webServer` configuration in `playwright.config.ts` to deterministically manage the Elixir backend lifecycle during the test run.

### Anti-Pattern 3: Maintaining `scrypath_ops` as a Standalone App
**What goes wrong:** Adopter friction skyrockets. They must configure CORS, handle port allocations, ensure DB credential parity, and somehow share their internal schema modules with an external codebase.
**Instead:** Make it a mountable engine. This resolves all schema context, authentication, and deployment complexities inherently.