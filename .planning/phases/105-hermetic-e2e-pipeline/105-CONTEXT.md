# Phase 105: Hermetic E2E Pipeline - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 105 builds the hermetic browser proof for the e-commerce host app: Playwright-driven storefront and operator workflows running against Phoenix, Ecto/Postgres, Oban, `scrypath_ops`, and a real Meilisearch backend.

This phase validates already-scoped integration behavior. It does not add new public runtime APIs, new search capabilities, reusable UI widgets, or broad Phoenix framework surface. Test-only helper routes and hooks are allowed only when gated to dev/test and used to make E2E proof deterministic.

</domain>

<decisions>
## Implementation Decisions

### E2E Harness Boundary
- **D-01:** Mix/GitHub Actions own Phoenix app boot, database setup, service health checks, and lifecycle orchestration. Playwright should drive the browser, not become the source of truth for app/service boot.
- **D-02:** Avoid making Playwright `webServer.command` the primary lifecycle owner for this phase. It is convenient, but it hides Elixir/Phoenix boot failures behind Node orchestration and weakens operational triage.
- **D-03:** Local DX may still be wrapped in a single command, but the underlying responsibility stays explicit: Mix starts/prepares the app, CI starts services and waits for readiness, Playwright runs browser assertions against a configured `baseURL`.

### Data and Index Readiness
- **D-04:** Implement the default Phase 105 E2E path as a deterministic harness: seed the scenario, commit database state, drain Oban work explicitly, wait for Meilisearch tasks/search visibility with polling, then assert UI through Playwright auto-retrying expectations.
- **D-05:** No fixed sleeps as readiness primitives. Readiness must be based on observable state: HTTP health checks, DB/fixture response, Oban drain result, Meilisearch task/search outcome, and visible UI state.
- **D-06:** Use `CatalogFixtures.scenario_e2e_search_catalog/1` as the canonical storefront fixture spine because it already provides deterministic product names for strict assertions.
- **D-07:** Add a later real-worker canary lane after the deterministic lane is stable. The canary may run Oban naturally to catch queue timing/idempotency issues, but it should not be the first required confidence path.

### CI Gate Placement
- **D-08:** Create a separate Phase 105 E2E CI lane rather than folding browser proof into the existing root unit gate or a broad existing live-example job.
- **D-09:** Start the lane as advisory on PRs and active on `main`/scheduled monitoring. Do not immediately make browser + live-service E2E a required branch-protection check.
- **D-10:** Define promotion criteria before any required-check escalation: stable job name, sustained low flake rate, bounded runtime, useful artifacts/logs, clear owner expectations, and no skipped-workflow pending-check ambiguity.
- **D-11:** The job should use real GitHub Actions service containers for Meilisearch and Postgres where needed, explicit health checks, Playwright artifact upload on failure, and stable job names.

### Operator Workflow Proof Shape
- **D-12:** Use hybrid operator E2E proof: Playwright asserts operator-visible UI outcomes, and test helpers assert a small number of stable backend truths.
- **D-13:** For failed-sync triage, prove both that the operator can see/action the failure in `scrypath_ops` and that the failure corresponds to durable queue/backend state surfaced through Scrypath operator APIs.
- **D-14:** For zero-downtime swap, prove both that the admin UI initiates/completes the workflow and that the stable operational outcome is true, such as terminal task success and the active logical index/search result reflecting the swap.
- **D-15:** Avoid full browser assertions over internal payloads, private queue args, raw task JSON structure, or fragile LiveView DOM internals. Browser tests should use user-visible roles/text and stable `data-testid` hooks where needed.

### Failure Injection Strategy
- **D-16:** Use a deterministic dev/test-only failure hook for E2E-05, following the existing `/dev/e2e` route pattern and guarded by `Mix.env() in [:dev, :test]`.
- **D-17:** The failure must still look operationally real to Scrypath: it should flow through Oban/Scrypath operator visibility and surface as a backend-style or sync-work failure that `scrypath_ops` can triage.
- **D-18:** Prefer one-shot, scenario-scoped failure injection with cleanup/isolation over global bad config, network sabotage, or broad environment mutation. The test should not break unrelated searches or leak state across tests.
- **D-19:** Do not add public runtime APIs for failure injection. Any test hook belongs to the example app's dev/test harness, not Scrypath's public contract.

### The Agent's Discretion
- Exact file split for Playwright specs, fixtures, and helper modules.
- Exact stable `data-testid` names for operator UI assertions, provided browser tests remain user-outcome oriented.
- Exact polling helper implementation, provided it avoids fixed sleeps and reports high-signal failure messages.
- Whether the first Phase 105 CI lane is a new workflow or a dedicated job in `ci.yml`, provided the job name and advisory/monitoring status are clear.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Requirement Authority
- `.planning/ROADMAP.md` — Phase 105 goal, dependency on Phase 104, and success criteria.
- `.planning/REQUIREMENTS.md` — `E2E-01` through `E2E-06` requirement definitions.
- `.planning/PROJECT.md` — v1.28 active scope, release-train posture, and no-new-runtime-surface constraints.
- `.planning/STATE.md` — current milestone state and carried-forward decisions from Phases 103 and 104.

### Existing Example App Surfaces
- `examples/scrypath_ecommerce/mix.exs` — example app dependencies, aliases, and test/precommit shape.
- `examples/scrypath_ecommerce/config/config.exs` — Scrypath defaults for Meilisearch, Oban queue, and index prefix.
- `examples/scrypath_ecommerce/config/test.exs` — Ecto sandbox and Oban test configuration.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex` — storefront, mounted `scrypath_ops`, and dev/test E2E route boundary.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` — existing test-only seed endpoint pattern.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog_fixtures.ex` — canonical deterministic E2E fixture scenarios.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex` — tenant-scoped catalog writes, product sync, and related-data propagation.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/product.ex` — Scrypath declaration, tenant field, facets, and projected document shape.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/live/search_live.ex` — URL-driven tenant-safe storefront search behavior.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/live/search_live.html.heex` — storefront browser assertion surface.

### Existing Verification and Operator Surfaces
- `.github/workflows/ci.yml` — current CI job style, live service containers, and lean required/advisory lanes.
- `lib/mix/tasks/verify.meilisearch_smoke.ex` — existing live Meilisearch smoke verification pattern and env requirements.
- `lib/mix/tasks/verify.phase99.ex` — focused phase-gate task pattern and docs/test orchestration style.
- `scrypath_ops/lib/scrypath_ops_web/router.ex` — mounted operator route definitions.
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` — operator posture and swap interaction surface.
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` — failed-sync triage surface.
- `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs` — existing operator UI test semantics and `data-testid` precedent.
- `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs` — existing failed-sync UI test semantics.
- `test/scrypath/operator/failed_work_test.exs` — Scrypath failed-work API behavior and recovery semantics.
- `test/scrypath/operator/status_test.exs` — sync status semantics over backend and queue state.

### Prompt Guidance to Apply
- `prompts/elixir-best-practices-deep-research.md` — explicit APIs, stable return shapes, and process discipline.
- `prompts/ecto-best-practices-deep-research.md` — context boundaries, Ecto.Multi/transaction discipline, and database-owned correctness.
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix web/domain boundary, routing, and thin LiveViews/controllers.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — user-visible UI assertions, URL state, and LiveView testing/UX footguns.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — operational system design, supervision, telemetry, and test/production boundary guidance.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS library DX, explicit configuration, and no hidden magic.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — lean CI gates, exact versions, service lanes, and release-train tradeoffs.
- `prompts/elixir-search-lib-deep-research.md` — Searchkick/Scout/Haystack lessons for search sync, reindex, and async proof.
- `prompts/search-lib-use-cases-deep-research.md` — adopter jobs around first searchable schema, related-data propagation, tenant-safe access, and recovery.
- `prompts/meileisearch best practices for scrypath deep research.md` — Meilisearch operational/task/indexing lessons where applicable.
- `prompts/scrypath-brand-book.md` — operationally honest, calm, Ecto-native product posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex`: existing dev/test-only JSON seed surface to extend for deterministic E2E scenarios.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog_fixtures.ex`: deterministic catalog fixture with `Quantum CyberPhone X`, `Quantum CyberPhone Pro`, and `Nebula Ultrabook`.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex`: existing create/update paths enqueue Scrypath product sync and related category fan-out.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/live/search_live.ex`: already uses URL params and tenant-safe `Scrypath.search/3`, suitable for Playwright storefront assertions.
- `scrypath_ops` LiveViews and tests: existing operator surfaces and stable `data-testid` patterns can guide browser selectors.
- `.github/workflows/ci.yml`: existing Meilisearch/Postgres service-container and health-check patterns can be reused.

### Established Patterns
- Required gates stay lean and deterministic; heavy/live checks are explicit lanes unless intentionally promoted.
- Phoenix app code keeps web routes/controllers/LiveViews thin over context/application logic.
- E2E/dev helper routes are acceptable only under dev/test environment guards.
- Scrypath operational proof should acknowledge eventual consistency and async task semantics rather than pretending search writes are synchronous.
- Browser assertions should prove user-visible workflows; lower-level tests and helper probes should own stable backend truth.

### Integration Points
- Add Playwright project files under `examples/scrypath_ecommerce`.
- Add or extend dev/test-only E2E controller scenarios for deterministic fixture seeding, readiness, and one-shot failure injection.
- Add CI wiring for the Phase 105 E2E lane using real Meilisearch and Postgres services.
- Add any needed `mix` alias/task or script wrapper for app boot/readiness while keeping lifecycle semantics in Elixir/CI.
- Add stable selector hooks to storefront/operator templates only where user-visible role/text selectors are insufficient.

</code_context>

<specifics>
## Specific Ideas

- Treat the E2E flow as a state machine: service healthy -> app booted -> DB migrated -> fixture seeded -> Oban drained -> Meilisearch visible -> browser assertion passed.
- Storefront happy path should use exact deterministic product names and category filters rather than broad text matching.
- Related-data sync proof should mutate a category name, drain related sync work, poll search visibility, and assert the storefront reflects the updated projection.
- Operator triage should prove an actual failed work item is visible/actionable in `scrypath_ops`, not just that a page renders.
- Zero-downtime swap should prove both operator completion feedback and the stable search/index outcome.
- Upload Playwright traces/screenshots/videos on CI failure to keep live-browser failures diagnosable.

</specifics>

<deferred>
## Deferred Ideas

- Promotion of the Phase 105 browser/live-service lane to a required PR check is deferred until stability criteria are met.
- A production-like real-worker canary lane is deferred until the deterministic harness is green and stable.
- Broader operator UI expansion, new public runtime APIs, and reusable UI widgets remain out of scope.

</deferred>

---

*Phase: 105-hermetic-e2e-pipeline*
*Context gathered: 2026-05-30*
