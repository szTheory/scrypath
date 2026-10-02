---
phase: 166-host-tenant-and-repair-evidence
plan: "01"
subsystem: phoenix-example
tags: [ecto, phoenix, tenant-scope, meilisearch, facets]

# Dependency graph
requires:
  - phase: "165-02"
    provides: Public tenant-scope and keyword facet-filter contracts.
provides:
  - Persisted synthetic actor membership and allowlisted host search/facet entrypoints.
  - Mixed-tenant live search evidence with independent raw, count, facet, and hydration assertions.
  - Recorder-backed rejection tests and bounded example runbook wording.
affects: [166-03, phase-167-readiness]

# Actuals (#2632)
actuals:
  tokens: 6579
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Resolve tenant scope from a persisted host membership before constructing public Scrypath options.
    - Keep raw search results visible while hydrating records with both tenant and returned-ID predicates.
    - Exercise service-backed fixtures through explicit live-index setup and task completion.

key-files:
  created:
    - examples/phoenix_meilisearch/priv/repo/migrations/20260927000000_add_host_memberships_and_post_tenants.exs
    - examples/phoenix_meilisearch/test/scrypath_demo/blog_tenant_search_test.exs
  modified:
    - examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex
    - examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex
    - examples/phoenix_meilisearch/test/smoke/meilisearch_tenant_stack_test.exs
    - examples/phoenix_meilisearch/README.md

key-decisions:
  - "Derive tenant scope from persisted membership and reject all caller-controlled scope/runtime keys before dispatch."
  - "Keep raw hits and metadata separate from host hydration so scoped database rows cannot conceal a foreign search hit."
  - "Use a fixed paginated query for exact totalHits and create the live test index with an explicit id primary key."

patterns-established:
  - "Synthetic authenticated principals are fixture inputs; the host context owns persisted membership policy."
  - "Search/facet options are rebuilt from allowlisted ordinary input plus separate server-owned runtime options."

requirements-completed: [HOST-01, HOST-02, PKG-04]
coverage:
  - id: D1
    description: The Phoenix context derives scope from a persisted actor membership and hydrates only returned IDs within that tenant.
    requirement: HOST-01
    verification:
      - kind: unit
        ref: examples/phoenix_meilisearch/test/scrypath_demo/blog_tenant_search_test.exs#authorized search and facet calls dispatch with membership-derived scope
        status: pass
      - kind: integration
        ref: examples/phoenix_meilisearch/test/smoke/meilisearch_tenant_stack_test.exs#authorized tenant search and facet values
        status: pass
    human_judgment: false
  - id: D2
    description: The live scenario distinguishes tenant-safe raw hits, exact counts, category facets, and separately scoped Postgres hydration.
    requirement: HOST-02
    verification:
      - kind: integration
        ref: examples/phoenix_meilisearch/test/smoke/meilisearch_tenant_stack_test.exs#authorized tenant search and facet values
        status: pass
    human_judgment: false
  - id: D3
    description: The named path scenario, package-artifact boundary, and synthetic host-policy limits are documented for the existing consumer harness.
    requirement: PKG-04
    verification:
      - kind: unit
        ref: mix verify.phase94 (docs contract suite)
        status: pass
    human_judgment: false

# Metrics
duration: "24 min (approx; start time not captured)"
completed: 2026-09-27
status: complete
---

# Phase 166 Plan 01: Host Tenant Search Summary

**The Phoenix example now proves persisted membership-derived tenant search, raw-result separation, scoped hydration, and public facet values against Meilisearch.**

## Performance

- **Duration:** Approximately 24 minutes; the executor did not capture the exact start time.
- **Started:** Not captured; the first recorded live test began at 12:25 UTC.
- **Completed:** 2026-09-27 12:39 UTC.
- **Tasks:** 2.
- **Files modified:** 6.

## Accomplishments

- Added the additive host actor/membership migration and tenant/category fields to the Phoenix Post projection and filter/facet settings.
- Added allowlisted host search and category-facet functions. Membership is checked before dispatch, trusted options are rebuilt, raw hits remain available, and Postgres hydration uses tenant plus returned IDs.
- Added recorder-backed positive, rejection, override, malformed-input, and raw-hit/hydration checks, plus a live A/B tenant scenario with draft exclusion and facet-value results.
- Documented the scenario's synthetic-principal boundary and its local-artifact package scope.

## Task Commits

1. **Task 1: Trace the authorized member search path** — `d38dc02` (`feat(166-01): add host tenant search path`).
2. **Task 2: Prove rejection and mixed-tenant search/facets** — `6e7a119` (`test(166-01): add mixed tenant host and facet evidence`).

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `examples/phoenix_meilisearch/priv/repo/migrations/20260927000000_add_host_memberships_and_post_tenants.exs` — persisted synthetic actors/memberships and nullable post tenant/category fields.
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex` — membership policy, strict input validation, public searches, and tenant-and-ID hydration.
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex` — declared tenant and category projection/filter/facet fields.
- `examples/phoenix_meilisearch/test/scrypath_demo/blog_tenant_search_test.exs` — five recorder-backed context and privacy-boundary tests.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_tenant_stack_test.exs` — named live A/B tenant and facet-value scenario with a success-only receipt line.
- `examples/phoenix_meilisearch/README.md` — scenario command and explicit host/package claim limits.

## Decisions Made

- The example's actor map represents an already-authenticated principal; this code does not add authentication or a general adopter authorization system.
- Generic Scrypath hydration is omitted. The context preserves raw results and performs its own tenant-plus-ID database query.
- The live test creates its index with `Client.create_index/3` and an explicit `id` primary key. The higher-level `Meilisearch.create_index/3` creates a reindex target, not the live index.
- The host context uses a fixed page size so Meilisearch returns exact `totalHits`; ordinary caller input cannot override page or tenant/filter settings.

## Verification

At committed source `6e7a1193c3b18f6f7b8c2a78b112ad8f05a43f9a`:

- `mix test test/scrypath_demo/blog_tenant_search_test.exs --trace` — 5 tests, 0 failures.
- `SCRYPATH_EXAMPLE_INTEGRATION=1 mix test test/smoke/meilisearch_tenant_stack_test.exs --only host_tenant --trace` — 1 live test, 0 failures. The `SCRYPATH_PHASE166_HOST` marker recorded index `phx_tenant_67_post`, setup tasks 50/51, write tasks 52/53/54, A ID 23 and B ID 25; each tenant returned one raw hit, one category bucket, and one matching facet value. Measured scenario duration was 491 ms.
- `mix verify.phase94` — 137 tests, 0 failures; ExDoc built with warnings as errors.
- `mix verify.phase96` — 110 tests, 0 failures; ExDoc built with warnings as errors.
- `mix format` and `git diff --check` passed.

The local service tuple used Postgres 16 (`PGPORT=55433`) and Meilisearch 1.15 (`http://127.0.0.1:7700`). Port 5433 was occupied by an existing service, so the same declared service images ran under a temporary Compose project on port 55433. Existing stopped containers and unrelated services were left untouched.

## Deviations from Plan

None in scope. Initial service-test failures exposed two fixture requirements: an explicit primary key on the live index and paginated search for exact counts; both were corrected within the planned host scenario.

## Issues Encountered

- The default local Postgres port was already allocated. The Phase 166 Compose project used port 55433 and a separate network to preserve other containers and services.
- The first index helper call created a reindex target, leaving the live index to infer `id` from both `id` and `tenant_id`. The fixture now creates the live index directly with its explicit primary key.
- Default Meilisearch search responses expose estimated counts. The host search supplies a fixed page request, and the live test asserts exact `totalHits`.

## User Setup Required

None. The test uses the existing Phoenix example services and environment variables described in its README.

## Next Phase Readiness

Plan 01 is complete. Plan 02 remains runnable in Wave 1. Plan 03 must still run both consumer dependency modes and the root repair scenario at one committed source; no package-artifact or root-repair receipt is claimed here.

---
*Phase: 166-host-tenant-and-repair-evidence*
*Completed: 2026-09-27*
