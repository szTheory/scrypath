# Phase 105: Hermetic E2E Pipeline - Pattern Map

**Mapped:** 2026-05-30
**Source:** Inline pattern mapping during `$gsd-plan-phase 105`

## Files to Create or Modify

| File | Role | Closest Existing Analog | Notes |
|------|------|-------------------------|-------|
| `examples/scrypath_ecommerce/package.json` | Node test runner manifest | Root `mix.exs` aliases and CI commands | Keep Node scoped to the example app; expose `test:e2e` and `test:e2e:list`. |
| `examples/scrypath_ecommerce/package-lock.json` | Locked npm dependency graph | `mix.lock` | Commit lockfile so CI uses the same `@playwright/test` dependency graph. |
| `examples/scrypath_ecommerce/playwright.config.ts` | Playwright runner config | Research baseline and existing Phoenix endpoint config | Use configured `baseURL`; do not own Phoenix lifecycle through `webServer.command`. |
| `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` | Browser/helper API | `examples/scrypath_ecommerce/test/support/data_case.ex` | Centralize seed/readiness helper calls, app URL, and high-signal polling errors. |
| `examples/scrypath_ecommerce/e2e/storefront.spec.ts` | Storefront E2E specs | `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/live/search_live_test.exs` | Assert user-visible search and facet behavior for deterministic catalog names. |
| `examples/scrypath_ecommerce/e2e/operator.spec.ts` | Operator E2E specs | `scrypath_ops/test/scrypath_ops_web/live/*_test.exs` | Use visible labels/text and stable `data-testid` hooks where needed. |
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` | Dev/test harness API | Existing `/dev/e2e/seed` controller | Extend with scenario-scoped seeding, Oban drain, search readiness, failure injection, and backend probes. |
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex` | Domain mutation helpers | Existing `update_category/3` related sync flow | Add test-only helper only if needed; do not add public Scrypath APIs. |
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/live/search_live.html.heex` | Storefront assertion surface | Existing form and result markup | Add stable labels/test IDs only where role/text selectors are insufficient. |
| `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` | Failed work browser surface | Existing failed sync LiveView tests | Existing "Refresh failed sync jobs", "Failed sync jobs", and "Retry job" copy should remain primary selectors. |
| `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` | Swap browser surface | Existing posture LiveView tests | Existing "Refresh posture", `data-testid="posture-row"`, and "Swap live index" copy are canonical selectors. |
| `.github/workflows/ci.yml` or `.github/workflows/phase105-e2e.yml` | Advisory E2E CI lane | Existing `main-ci`/service job style | Prefer stable job name `phase105-e2e`; upload Playwright artifacts on failure. |
| `CONTRIBUTING.md` | Verification docs | Existing contributor gate descriptions | Document the advisory E2E lane and promotion criteria without making it required yet. |

## Concrete Patterns

### Dev/Test Route Guard

`examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex` already gates the E2E route:

```elixir
if Mix.env() in [:dev, :test] do
  scope "/dev/e2e", ScrypathEcommerceWeb do
    pipe_through :api
    post "/seed", E2EController, :seed
  end
end
```

Phase 105 should extend this route group only. No production route or public runtime API should be introduced for test harness behavior.

### Deterministic Fixture Spine

`CatalogFixtures.scenario_e2e_search_catalog/1` already creates:

- `Quantum CyberPhone X`
- `Quantum CyberPhone Pro`
- `Nebula Ultrabook`
- `Smartphones`
- `Laptops`

Use these exact strings for strict Playwright assertions and avoid broad fuzzy result checks.

### Storefront Search Surface

`SearchLive` already drives search from URL params and filters by tenant:

- `q`
- `category_id`
- `Scrypath.search(Product, text, filter: [tenant_id: tenant_id], facets: [:category_id])`

The Playwright spec should interact with the visible `Search products` input and category checkbox labels, then assert rendered result headings.

### Operator Surfaces

`FailedSyncLive` exposes browser-facing anchors:

- Button: `Refresh failed sync jobs`
- Heading: `Failed sync jobs`
- Row detail summary: `Row detail`
- Button: `Retry job`

`PostureLive` exposes browser-facing anchors:

- Button: `Refresh posture`
- Table rows: `data-testid="posture-row"`
- Button: `Swap live index`
- Headline region: `data-testid="posture-next-checks"`

Prefer these over private LiveView DOM structure. Add new `data-testid` only if a necessary browser assertion cannot be expressed with role/text selectors.

### Existing CI Style

`.github/workflows/ci.yml` uses:

- `actions/checkout@v6`
- `erlef/setup-beam@v1`
- explicit Elixir/OTP versions
- scoped cache keys per job
- concrete `mix` commands with descriptive job names

The E2E lane should follow that style and add `actions/setup-node@v6`, `npx playwright install --with-deps chromium`, service containers, health checks, and artifact upload on failure.

## Risks to Preserve in Plans

- Playwright must not hide Phoenix boot failures behind `webServer.command`.
- No fixed sleeps for readiness. Use HTTP health, Ecto/fixture responses, Oban drain, Meilisearch task/search visibility, and Playwright web-first assertions.
- Failure injection must be dev/test-only, one-shot, and scenario-scoped.
- The lane starts advisory on PRs; required-check promotion is out of scope until stability criteria are documented and met.
