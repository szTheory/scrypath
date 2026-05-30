# Phase 105: Hermetic E2E Pipeline - Research

**Researched:** 2026-05-30
**Domain:** Hermetic browser E2E for Phoenix/Ecto/Oban/Meilisearch with Playwright
**Confidence:** HIGH

## User Constraints

### Locked Decisions
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

### the agent's Discretion
- Exact file split for Playwright specs, fixtures, and helper modules.
- Exact stable `data-testid` names for operator UI assertions, provided browser tests remain user-outcome oriented.
- Exact polling helper implementation, provided it avoids fixed sleeps and reports high-signal failure messages.
- Whether the first Phase 105 CI lane is a new workflow or a dedicated job in `ci.yml`, provided the job name and advisory/monitoring status are clear.

### Deferred Ideas (OUT OF SCOPE)
- Promotion of the Phase 105 browser/live-service lane to a required PR check is deferred until stability criteria are met.
- A production-like real-worker canary lane is deferred until the deterministic harness is green and stable.
- Broader operator UI expansion, new public runtime APIs, and reusable UI widgets remain out of scope.

## Project Constraints (from AGENTS.md)
- Elixir OSS library with Ecto-first APIs and Phoenix-friendly integrations is mandatory. [VERIFIED: codebase grep]
- v1 backend target is Meilisearch with internal adapter seam and no premature public abstraction. [VERIFIED: codebase grep]
- Write-path support must include inline, Oban-backed, and manual sync. [VERIFIED: codebase grep]
- Keep operational clarity explicit (eventual consistency, deletes, backfills, reindex). [VERIFIED: codebase grep]
- Follow `CONTRIBUTING.md` gates and keep `main` green with lean required checks. [VERIFIED: codebase grep]

## Summary
Phase 105 should be planned as a deterministic, two-layer verification pipeline: Elixir controls lifecycle/readiness, Playwright validates user-visible workflows. This matches locked D-01/D-02 and aligns with Playwright guidance that `webServer` is a convenience option, not a requirement, and with existing repo CI patterns that already own service boot/readiness in shell steps. [CITED:https://playwright.dev/docs/test-webserver] [VERIFIED: codebase grep]

Use explicit readiness proofs at each boundary (Postgres ready, Meilisearch healthy, fixture seeded, Oban drained, Meilisearch task succeeded, UI assertion passed). Oban officially supports `Oban.drain_queue/1,2` for integration tests, and Meilisearch task docs define polling terminal states (`succeeded`/`failed`) and error surfaces. [CITED:https://oban.hexdocs.pm/testing_queues.html] [CITED:https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks]

CI should be a dedicated advisory lane first, with service containers, Playwright browser install, and artifact upload on failure. This mirrors both GitHub service-container guidance and Playwright CI examples (workers=1 in CI + artifact upload). [CITED:https://docs.github.com/en/actions/tutorials/use-containerized-services] [CITED:https://playwright.dev/docs/ci] [CITED:https://github.com/actions/upload-artifact]

**Primary recommendation:** Plan Phase 105 as one deterministic hermetic E2E lane first (advisory), with Elixir-owned orchestration and Playwright-owned browser assertions.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| App/service boot and teardown | API / Backend | Frontend Server (SSR) | Mix/tasks and CI steps should own process lifecycle and readiness checks. |
| Browser journey assertions | Browser / Client | Frontend Server (SSR) | Playwright asserts rendered UI behavior and user actions. |
| Fixture seeding and failure injection | API / Backend | Database / Storage | Dev/test controller + context functions create deterministic state. |
| Async sync completion proof | API / Backend | Database / Storage | Oban drain and operator APIs verify queue/backend processing. |
| Search task completion proof | API / Backend | External Meilisearch service | Task API polling confirms eventual consistency before UI checks. |
| CI service topology | CDN / Static | API / Backend | GitHub Actions services run Meilisearch/Postgres with explicit checks. |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| E2E-01 | Add Playwright suite to `scrypath_ecommerce`. | Standard stack, project structure, CI/install commands, selectors/readiness patterns. |
| E2E-02 | Add GitHub Actions workflow with real Meilisearch + health checks. | Service-container pattern and health-gate guidance. |
| E2E-03 | Consumer happy path (search + facet). | Deterministic fixture + Playwright auto-wait assertions. |
| E2E-04 | Related-data sync proof. | Oban drain + Meilisearch task polling + storefront assertion sequence. |
| E2E-05 | Operator triage proof (intentional failure). | Dev/test-only failure hook + hybrid UI/backend assertion model. |
| E2E-06 | Zero-downtime swap proof via ops UI. | Operator UI proof + terminal backend outcome assertions. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@playwright/test` | `1.60.0` | Browser E2E runner and assertions | Official Playwright test runner; CI guidance and artifact patterns are first-party. [VERIFIED: npm registry] [CITED:https://playwright.dev/docs/ci] |
| `Phoenix.Ecto.SQL.Sandbox` | `phoenix_ecto 4.7.0 docs` | External-browser DB sandboxing for acceptance flows | Official Phoenix/Ecto mechanism for transactional acceptance tests from external clients. [CITED:https://phoenix-ecto.hexdocs.pm/Phoenix.Ecto.SQL.Sandbox.html] |
| `Oban` | `2.23.0 docs` | Queue work execution proof in tests via drain | Official testing docs support draining queues during integration tests. [CITED:https://oban.hexdocs.pm/testing_queues.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `actions/setup-node` | `v6` | Node runtime in GitHub Actions | Required for Playwright install/test job. [CITED:https://playwright.dev/docs/ci] |
| `actions/upload-artifact` | `v7` | Upload traces/screenshots/reports | Always on failures for diagnosability. [CITED:https://github.com/actions/upload-artifact] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Elixir-owned lifecycle orchestration | Playwright `webServer.command` | Faster setup, but blurs Phoenix boot failures and violates D-01/D-02 ownership. [CITED:https://playwright.dev/docs/test-webserver] |

**Installation:**
```bash
cd examples/scrypath_ecommerce
npm install --save-dev @playwright/test
npx playwright install --with-deps chromium
```

**Version verification:**
```bash
npm view @playwright/test version
```
Result verified in-session: `1.60.0` (modified `2026-05-30T06:19:02.185Z`). [VERIFIED: npm registry]

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `@playwright/test` | npm | ~5.7 years (created 2020-09-24) | 36,074,237/week (`2026-05-23` to `2026-05-29`) | `github.com/microsoft/playwright` | OK (`slopcheck install -e npm @playwright/test`) | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram
```text
GitHub Actions Job / Local Mix Task
  -> Start Postgres + Meilisearch services
  -> Run DB create/migrate + start Phoenix endpoint
  -> POST /dev/e2e/seed (scenario + optional failure hook)
  -> Drain Oban queue(s)
  -> Poll Meilisearch task/search visibility
  -> Run Playwright specs (storefront + /admin/search ops UI)
  -> On failure: upload traces/screenshots/report artifacts
```

### Recommended Project Structure
```text
examples/scrypath_ecommerce/
├── e2e/
│   ├── storefront.spec.ts
│   ├── operator.spec.ts
│   └── helpers/
├── playwright.config.ts
├── package.json
└── lib/scrypath_ecommerce_web/controllers/e2e_controller.ex
```

### Pattern 1: Deterministic Readiness Chain
**What:** Replace sleeps with state checks across DB, queue, search backend, then UI.  
**When to use:** Every E2E flow touching async indexing.  
**Example:** Poll Meilisearch task status until terminal + assert via Playwright `expect(...).toHaveText(...)`. [CITED:https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks] [CITED:https://playwright.dev/docs/actionability]

### Anti-Patterns to Avoid
- **Fixed `sleep` as synchronization:** Causes flakes across CI load variance; use queue/task/UI state checks instead. [CITED:https://playwright.dev/docs/actionability]
- **Testing private internals in browser:** Assert visible outcome in Playwright, internal payloads in Elixir tests.
- **Required-PR gate too early:** Start advisory lane first per locked D-09.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser action waiting | Custom polling wrappers for every click/assertion | Playwright auto-wait + web-first assertions | Already retries and reduces flake surface. [CITED:https://playwright.dev/docs/actionability] |
| Queue drain loop | Raw SQL polling of `oban_jobs` | `Oban.drain_queue/1,2` | Official, explicit testing contract. [CITED:https://oban.hexdocs.pm/testing_queues.html] |
| Task status parser | Custom undocumented task-state heuristics | Meilisearch task API/status fields | Uses backend-defined terminal states and error semantics. [CITED:https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks] |

**Key insight:** Leverage each subsystem’s official readiness primitive to keep hermetic E2E deterministic.

## Common Pitfalls

### Pitfall 1: Mixed lifecycle ownership
**What goes wrong:** Failures appear as generic Playwright startup errors instead of actionable Phoenix/DB/service logs.  
**Why it happens:** `webServer.command` becomes the de facto orchestrator.  
**How to avoid:** Keep lifecycle in Mix/CI steps; Playwright only consumes `baseURL`.  
**Warning signs:** Flaky startup timeouts with sparse server diagnostics.

### Pitfall 2: Async visibility races
**What goes wrong:** UI assertions run before queue/task completion.  
**Why it happens:** Oban and Meilisearch are eventually consistent paths.  
**How to avoid:** Drain queue + poll terminal task status before UI assertion.  
**Warning signs:** Intermittent “missing expected product” failures.

## Code Examples

### Playwright CI baseline
```yaml
# Source: https://playwright.dev/docs/ci
- uses: actions/setup-node@v6
  with:
    node-version: lts/*
- run: npm ci
- run: npx playwright install --with-deps
- run: npx playwright test
```

### Oban queue drain in tests
```elixir
# Source: https://oban.hexdocs.pm/testing_queues.html
assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :search_sync)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Sleep-based E2E stabilization | Auto-retry assertions + explicit backend readiness checks | Ongoing best practice | Lower flake rates and clearer failures. [CITED:https://playwright.dev/docs/actionability] |
| Monolithic required E2E gates early | Advisory lane first, promote after stability evidence | Current CI reliability practice | Prevents merge friction while lane matures. [ASSUMED] |

**Deprecated/outdated:**
- `actions/upload-artifact@v3` usage in new workflows is deprecated upstream; use modern major versions. [CITED:https://github.com/actions/upload-artifact]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Advisory-first promotion model is best for this repo’s branch protection cadence. | State of the Art | Could delay gate hardening or over-soften CI policy. |

## Open Questions

1. **Where should the new lane live (`ci.yml` job vs dedicated workflow)?**
   - What we know: both are allowed by discretion; job naming stability matters.
   - What's unclear: maintainer preference for observability and required-check UX.
   - Recommendation: pick one stable job identity now and document promotion criteria.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Playwright runner | ✓ | `v22.14.0` | — |
| npm | Playwright package install | ✓ | `11.1.0` | — |
| Docker | Local service parity checks | ✓ | `29.5.2` | Use GitHub Actions services in CI even if local Docker absent |
| PostgreSQL client (`pg_isready`) | DB readiness checks | ✓ | `14.17` | Curl app-level readiness endpoint |
| curl | Service health polling | ✓ | `8.7.1` | Minimal bash TCP probe (weaker) |
| Playwright CLI (global) | Optional local convenience | ✗ | — | Use local `npx playwright ...` |

**Missing dependencies with no fallback:**
- none

**Missing dependencies with fallback:**
- Global Playwright binary (`playwright`) missing; `npx playwright` is sufficient.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (`mix test`) + Playwright (`@playwright/test`) |
| Config file | `examples/scrypath_ecommerce/config/test.exs`; new `examples/scrypath_ecommerce/playwright.config.ts` |
| Quick run command | `cd examples/scrypath_ecommerce && mix test` |
| Full suite command | `mix verify --exclude integration` + Phase 105 E2E lane command |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| E2E-01 | Playwright suite scaffold | e2e | `cd examples/scrypath_ecommerce && npx playwright test --list` | ❌ Wave 0 |
| E2E-02 | CI service lane + health checks | CI integration | `act`/GitHub run of lane | ❌ Wave 0 |
| E2E-03 | Storefront search + facets | e2e | `npx playwright test e2e/storefront.spec.ts` | ❌ Wave 0 |
| E2E-04 | Related-data eventual sync | e2e + backend helper | `npx playwright test e2e/storefront.spec.ts -g "related"` | ❌ Wave 0 |
| E2E-05 | Failed-sync triage | e2e + backend helper | `npx playwright test e2e/operator.spec.ts -g "triage"` | ❌ Wave 0 |
| E2E-06 | Zero-downtime swap | e2e + backend helper | `npx playwright test e2e/operator.spec.ts -g "swap"` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `cd examples/scrypath_ecommerce && npx playwright test <focused spec>`
- **Per wave merge:** Full Phase 105 lane (services + full Playwright set)
- **Phase gate:** Phase 105 lane green on `main` monitoring + acceptable flake budget

### Wave 0 Gaps
- [ ] `examples/scrypath_ecommerce/package.json` scripts for Playwright
- [ ] `examples/scrypath_ecommerce/playwright.config.ts` baseline config
- [ ] `examples/scrypath_ecommerce/e2e/*.spec.ts` initial spec files
- [ ] CI lane job/workflow definition with artifact upload

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Reuse existing app/session auth boundaries in `/admin`; no test-only auth bypass in prod. [VERIFIED: codebase grep] |
| V3 Session Management | yes | Keep browser tests on real cookie/session flows; avoid manual token injection. [ASSUMED] |
| V4 Access Control | yes | Keep tenant-scoped search assertions and operator route expectations. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Exercise UI inputs through LiveView and existing Ecto changesets. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No new cryptographic primitive introduced in this phase. [ASSUMED] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Test-only route exposed in prod | Elevation of Privilege | Keep `if Mix.env() in [:dev, :test]` route guard only. [VERIFIED: codebase grep] |
| Cross-tenant data leakage in search assertions | Information Disclosure | Always include tenant fixture boundaries and scoped assertions. [VERIFIED: codebase grep] |
| Flaky readiness causing false negatives | DoS (pipeline) | Explicit health/task/queue checks before browser assertions. [CITED:https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks] |

## Sources

### Primary (HIGH confidence)
- Playwright CI docs: https://playwright.dev/docs/ci
- Playwright auto-wait/assertions: https://playwright.dev/docs/actionability
- Playwright web server option docs: https://playwright.dev/docs/test-webserver
- Phoenix SQL sandbox docs: https://phoenix-ecto.hexdocs.pm/Phoenix.Ecto.SQL.Sandbox.html
- Oban testing queues docs: https://oban.hexdocs.pm/testing_queues.html
- Meilisearch task monitoring docs: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks
- GitHub Actions service containers docs: https://docs.github.com/en/actions/tutorials/use-containerized-services
- Upload artifact action docs: https://github.com/actions/upload-artifact
- Local repo files (`AGENTS.md`, `.github/workflows/ci.yml`, `examples/scrypath_ecommerce/**`, `scrypath_ops/test/**`) [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- npm package metadata API (`npm view @playwright/test ...`) [VERIFIED: npm registry]
- npm weekly downloads API (`https://api.npmjs.org/downloads/point/last-week/@playwright/test`) [VERIFIED: npm registry]

### Tertiary (LOW confidence)
- none

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - official docs + npm verification + slopcheck npm check.
- Architecture: HIGH - locked context decisions + existing CI/app patterns + official docs.
- Pitfalls: HIGH - directly tied to documented async and E2E behavior.

**Research date:** 2026-05-30  
**Valid until:** 2026-06-29
