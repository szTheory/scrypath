---
gsd_state_version: 1.0
milestone: v1.28
milestone_name: milestone
status: ready
last_updated: "2026-05-30T22:58:20.787Z"
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 15
  completed_plans: 15
  percent: 100
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** Phase 105 — hermetic-e2e-pipeline

## Current Position

Phase: 105 (hermetic-e2e-pipeline) — COMPLETE
Plan: 4 of 4
**Phase:** 105
**Plan:** 04
**Status:** Phase 105 complete
**Progress:**
[██████████] 100%

## Performance Metrics

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 103 | 00 | 5m | 2 | 2 |
| 104 | 04 | 5m | 2 | 3 |
| 105 | 01 | 38m | 4 | 9 |
| 105 | 03 | 46m | 4 | 6 |

- **Completed Phases:** 4
- **Completed Plans:** 15
- **Requirements Met:** 12/15

| Phase 103 P03 | 5m | 2 tasks | 6 files |
| Phase 105 P02 | 29m | 4 tasks | 6 files |
| Phase 105 P03 | 46m | 4 tasks | 6 files |
| Phase 105 P04 | 52m | 4 tasks | 8 files |

## Accumulated Context

### Key Decisions

- Adopted the mountable engine pattern for `scrypath_ops` to enable embedding within host apps.
- Created an isolated e-commerce testbed app (`examples/scrypath_ecommerce`) rather than bloating the root library or using trivial domains.
- E2E testing uses standard Node `@playwright/test` integrated with `Ecto.Adapters.SQL.Sandbox` in shared mode, verified against a live Meilisearch CI container.
- Provided structural test cases for tenancy requirements.

### Active Blockers

- None.

### Todos

- None.

### Historical Contract Pointers

- Phase 32 AUDT-01 retained immutable planning pointers: `18-VERIFICATION.md`, `v1.4-MILESTONE-AUDIT.md`, `260416-eoj-SUMMARY.md`, `260416-if2-SUMMARY.md`.

## Session Continuity

- **Last Session:** 2026-05-30T22:57:51.834Z

- [x] Initialized v1.28 roadmap with Phases 102-105.

## Decisions

- [Phase ?]: Configured Phoenix.Ecto.SQL.Sandbox conditionally in the endpoint based on application environment configuration.
- [Phase 103]: Wrapped the /dev/e2e/seed route in `if Mix.env() in [:dev, :test] do` to strictly prevent production access.
- [Phase 103]: Delegated standard scenario creation to existing ScrypathEcommerce.CatalogFixtures functions.
- [Phase 104]: Use specific product names in e2e scenario fixture to enable strict, deterministic search assertions later in the phase.
- [Phase 104]: Related category-to-product propagation uses Scrypath's built-in related-sync worker rather than an app-specific worker.
- [Phase 104]: Recovered the minimal Phoenix scaffold for examples/scrypath_ecommerce so Phase 104 execution can compile and test inside the host app.
- [Phase 104]: Storefront search uses URL-driven LiveView state and explicit tenant_id filtering for Scrypath.search/3 tenant isolation.
- [Phase 105]: Playwright remains browser-only with Mix/CI owning Phoenix/service lifecycle orchestration.
- [Phase 105]: Standardized deterministic dev/test `/dev/e2e` contracts for seed, drain, readiness polling, and operator probes.
- [Phase 105]: Added storefront result test ids and category rendering to support robust browser-visible E2E assertions. — Playwright needs stable repeated-result scoping and visible related-data text.
- [Phase 105]: Enforced deterministic readiness chain (seed -> drain -> waitForSearchVisible) before storefront assertions. — Avoids flaky timing-based assertions and matches threat mitigation requirements.
- [Phase 105]: Failed-sync harness injection is scenario-keyed one-shot and remains example-local/dev-test only to avoid public Scrypath failure-injection surface.
- [Phase 105]: Operator-state probe response is restricted to counts/ids/reason-class/retryable summary and excludes raw args/documents payloads.
- [Phase 105]: Added stable operator swap-outcome probe fields for browser assertions without exposing raw task payloads.
- [Phase 105]: Added advisory phase105-e2e CI lane with Postgres+Meilisearch health checks and failure artifacts.
