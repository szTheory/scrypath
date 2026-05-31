# Phase 107: Ecommerce Readiness Regression Guard - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 107 proves that the e-commerce example app's dev/test readiness probe, `/dev/e2e/search-visible`, preserves tenant scope when category readiness filtering is present.

This phase is a targeted regression guard for E2E-01. It should repair and prove the known tenant/category filter merge issue in the readiness probe without expanding into deeper cross-tenant Playwright fixtures, broader storefront UX proof, new public Scrypath APIs, new tenant helper semantics, or CI lane promotion.

</domain>

<decisions>
## Implementation Decisions

### Proof Boundary
- **D-01:** Use focused controller/probe regression proof as the primary Phase 107 confidence path. The guard should assert that `/dev/e2e/search-visible` calls `Scrypath.search/3` with both `tenant_id` and `category_id` present in the resulting `Scrypath.Query.filter`.
- **D-02:** Do not add broader Playwright browser coverage or new cross-tenant fixture expansion in Phase 107. That work remains outside the known regression guard and is already deferred as future ecommerce proof breadth.
- **D-03:** Browser-level `phase105-e2e` proof remains valuable operational coverage, but Phase 107 should not use this repair to broaden or promote that advisory lane.

### Verification Gate
- **D-04:** Add a focused `mix verify.phase107` gate for the regression guard.
- **D-05:** The gate should be fast, deterministic, and service-free. It should run the e-commerce controller regression test that stubs the Scrypath backend and inspects the `Scrypath.Query` sent by `/dev/e2e/search-visible`.
- **D-06:** Keep the focused gate narrow. It should not grow into a general e-commerce E2E suite, a browser runner, or a live Meilisearch/Postgres readiness lane.
- **D-07:** Register the verify task in the normal local Mix task style, including `cli.preferred_envs` if needed, but do not change required/advisory CI topology unless release policy separately asks for that.

### Probe Semantics
- **D-08:** Keep `/dev/e2e/search-visible` on explicit filter composition for this regression: start with `filter: [tenant_id: tenant_id]`, then add `category_id` without replacing the existing filter.
- **D-09:** Do not switch the probe to `tenant_scope:` in Phase 107. `tenant_scope:` remains the stronger public safety primitive for adopter callsites, but switching this probe now would prove a different semantic path than the historical explicit-filter merge bug.
- **D-10:** Do not extract a shared storefront/probe search-options helper in Phase 107. The duplication is acceptable in this narrow repair because a new abstraction would widen blast radius and couple the dev/test probe to storefront UI evolution.

### Architecture and DX Calibration
- **D-11:** Prefer the smallest cohesive repair: transparent Phoenix controller logic, an exact regression assertion, and a named local verify command.
- **D-12:** Preserve Scrypath's established posture from prior phases and ecosystem lessons: search sync and tenant filtering should be explicit, operationally honest, and easy to prove without hiding critical behavior behind broad browser tests or framework magic.
- **D-13:** The developer experience target is a contributor-friendly failure: if tenant scope is accidentally dropped when category filtering is present, `mix verify.phase107` should fail quickly with a local, readable Elixir test failure.

### the agent's Discretion
- Exact test names, helper module names, and assertion shape are implementation details, provided the regression failure is direct and actionable.
- Exact verify task self-test shape is flexible, provided contributors can discover and run `mix verify.phase107` locally.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope and Requirements
- `.planning/ROADMAP.md` - Phase 107 goal, success criteria, dependency on Phase 106, and explicit boundary against deeper cross-tenant Playwright fixtures.
- `.planning/REQUIREMENTS.md` - E2E-01 and deferred E2E-FUTURE-01 scope.
- `.planning/PROJECT.md` - v1.29 bounded contract repair posture, advisory `phase105-e2e` stance, and no-new-breadth constraints.
- `.planning/STATE.md` - current Phase 107 focus and carried-forward e-commerce E2E decisions.

### Prior Phase Context
- `.planning/phases/105-hermetic-e2e-pipeline/105-CONTEXT.md` - existing e-commerce E2E harness decisions, dev/test route boundary, and advisory live-service CI posture.
- `.planning/phases/106-fan-out-reflection-contract-repair/106-CONTEXT.md` - v1.29 repair closeout posture and focused verify gate precedent.
- `.planning/phases/94-verification-gate/94-CONTEXT.md` - tenant-safety gate precedent and `tenant_scope:` contract boundary.
- `.planning/phases/93/93-RESEARCH.md` - `tenant_scope:` injection semantics and anti-shadowing rationale.

### Phase 107 Code Surfaces
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` - `/dev/e2e/search-visible` implementation and category filter merge point.
- `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` - focused controller regression test surface.
- `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` - Playwright helper that calls `/dev/e2e/search-visible` and already passes optional `category_id`.
- `examples/scrypath_ecommerce/e2e/storefront.spec.ts` - existing browser proof that should not be broadened for Phase 107 unless implementation discovers a direct need.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/live/search_live.ex` - storefront tenant/category filter shape used as local semantic precedent.
- `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/live/search_live_test.exs` - existing storefront search option tests.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/product.ex` - Scrypath product declaration with `tenant_field: :tenant_id`, `filterable: [:category_id, :tenant_id]`, and category facets.

### Verification Patterns
- `lib/mix/tasks/verify.phase106.ex` - focused service-free phase gate pattern.
- `lib/mix/tasks/verify.phase91.ex` - related-data focused gate pattern.
- `lib/mix/tasks/verify.phase94.ex` - tenant-safety verification gate precedent.
- `mix.exs` - root Mix task registration and `cli.preferred_envs` location.
- `examples/scrypath_ecommerce/mix.exs` - example app aliases and E2E preparation boundary.
- `.github/workflows/ci.yml` - current `phase105-e2e` advisory lane, which Phase 107 should not promote.

### Prompt Research Inputs
- `prompts/elixir-best-practices-deep-research.md` - explicit APIs, focused tests, and maintainable library architecture.
- `prompts/ecto-best-practices-deep-research.md` - context/query boundaries and Ecto-native correctness.
- `prompts/phoenix-best-practices-deep-research.md` - thin controller and route boundary guidance.
- `prompts/phoenix-live-view-best-practices-deep-research.md` - existing storefront proof and browser-test tradeoffs.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - operational system design and explicit boundary discipline.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` - OSS DX, public API restraint, and contributor-friendly proof.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - focused, low-noise verification and CI posture.
- `prompts/elixir-search-lib-deep-research.md` - search-library architecture lessons and sync/query proof boundaries.
- `prompts/search-lib-use-cases-deep-research.md` - tenant-safe access, related-data propagation, and recovery proof lessons.
- `prompts/meileisearch best practices for scrypath deep research.md` - Meilisearch operational and readiness semantics.
- `prompts/scrypath-brand-book.md` - Scrypath positioning: explicit, Ecto-native, operationally honest.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex`: existing dev/test-only controller already owns `/dev/e2e/search-visible` and has the correct small repair point in `maybe_put_category_filter/2`.
- `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs`: existing controller test can stub a Scrypath backend, capture the generated `%Scrypath.Query{}`, and assert the exact filter list.
- `examples/scrypath_ecommerce/e2e/helpers/e2e.ts`: existing helper already supports optional `categoryId` when polling `/dev/e2e/search-visible`.
- `lib/mix/tasks/verify.phase106.ex`: recent focused gate precedent for a service-free contract repair.

### Established Patterns
- Required gates stay lean and deterministic; heavier live-service/browser proof remains explicit and advisory unless deliberately promoted.
- Dev/test helper routes are acceptable in the example app only when environment-gated and used to make E2E proof deterministic.
- Phoenix controllers should remain thin and transparent over explicit query/search options.
- Tenant safety is an operational correctness issue. The proof should fail at the smallest boundary where tenant scope can be dropped.

### Integration Points
- Repair or preserve `maybe_put_category_filter/2` so it appends `category_id` to the existing `filter` keyword rather than replacing the filter.
- Add or keep the controller regression test for `GET /dev/e2e/search-visible` with both `tenant_id` and `category_id`.
- Add `lib/mix/tasks/verify.phase107.ex`, a focused task test, and `mix.exs` preferred-env registration if the task is added at the root.

</code_context>

<specifics>
## Specific Ideas

- The preferred implementation is already visible in the current unstaged repair shape: start with `[filter: [tenant_id: tenant_id]]`, derive `filters = Keyword.get(opts, :filter, []) |> Keyword.put(:category_id, category_id)`, then put the merged filter back into opts.
- The strongest regression assertion is not just response JSON; it should inspect the `%Scrypath.Query{filter: filter}` passed to the backend and assert `Enum.sort(filter) == [category_id: 202, tenant_id: 101]`.
- `tenant_scope:` should remain documented as the safer adopter-facing primitive, but Phase 107 should keep explicit filter merge to prove the concrete bug signature.
- Avoid fixed sleeps, browser-only proof, or live Meilisearch dependence for this guard. Those are already handled by the Phase 105 live E2E lane where appropriate.

</specifics>

<deferred>
## Deferred Ideas

- Broader browser E2E with explicit cross-tenant negative assertions remains deferred as E2E-FUTURE-01.
- Switching the dev/test readiness probe to `tenant_scope:` remains a possible future cleanup if the project later wants probe semantics to mirror adopter-facing tenant guardrails rather than prove this explicit-filter bug.
- Extracting a shared storefront/probe search-options helper is deferred until duplicate tenant/category composition becomes a real maintenance problem.
- Promoting `phase105-e2e` to required CI remains out of scope for v1.29 unless release policy separately changes.

</deferred>

---

*Phase: 107-ecommerce-readiness-regression-guard*
*Context gathered: 2026-05-31*
