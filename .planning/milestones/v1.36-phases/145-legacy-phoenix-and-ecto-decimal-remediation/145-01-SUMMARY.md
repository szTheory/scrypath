---
phase: 145-legacy-phoenix-and-ecto-decimal-remediation
plan: "01"
subsystem: dependencies
tags: [elixir, phoenix, bandit, ecto, postgrex, decimal, postgres, telemetry]
requires:
  - phase: 144-root-http-client-dependency-remediation
    provides: Checked legacy Req 0.6.3, Mint 1.9.3, and hpax 1.0.4 handoff
provides:
  - Fixed-compatible legacy Phoenix, Bandit, Ecto SQL, and Postgrex dependency cohort
  - Real Postgres persistence and loopback Bandit HTTP compatibility contracts
affects: [145-02, 146, 147]
tech-stack:
  added: []
  patterns: [causal Mix lock refresh, DataCase persistence contract, supervised loopback Bandit telemetry contract]
key-files:
  created:
    - examples/phoenix_meilisearch/test/scrypath_demo/ecto_compatibility_test.exs
    - examples/phoenix_meilisearch/test/scrypath_demo_web/endpoint_compatibility_test.exs
  modified:
    - examples/phoenix_meilisearch/mix.exs
    - examples/phoenix_meilisearch/mix.lock
key-decisions:
  - Kept the legacy graph limited to four direct compatibility bounds and their causal lock closure.
  - Used a direct supervised Bandit plug listener with ThousandIsland listener introspection, avoiding endpoint-policy changes.
requirements-completed: [SEC-02]
coverage:
  - id: D1
    description: Fixed-compatible legacy dependency graph with checked lock.
    requirement: SEC-02
    verification:
      - kind: other
        ref: cd examples/phoenix_meilisearch && mix deps.get --check-locked
        status: pass
    human_judgment: false
  - id: D2
    description: Existing Postgres model and Phoenix/Bandit HTTP boundaries remain compatible.
    requirement: SEC-02
    verification:
      - kind: integration
        ref: examples/phoenix_meilisearch/test/scrypath_demo/ecto_compatibility_test.exs and test/scrypath_demo_web/endpoint_compatibility_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 15m
  completed_date: 2026-08-22
status: complete
---

# Phase 145 Plan 01: Legacy Phoenix Graph Compatibility Summary

Bound the legacy Phoenix example to a fixed-compatible Phoenix/Bandit/Ecto/Postgrex cohort and proved its real Postgres persistence plus loopback Bandit HTTP boundary.

## Accomplishments

- Changed only the four planned direct requirements: Phoenix `~> 1.8.9`, Bandit `~> 1.12.1`, Ecto SQL `~> 3.14.0`, and Postgrex `~> 0.22.4`.
- Refreshed only their causal lock closure: Bandit/Thousand Island, Ecto/Decimal, Phoenix/Plug, and Jason's Decimal-3 compatibility; retained Req 0.6.3, Mint 1.9.3, and hpax 1.0.4 unchanged from Phase 144.
- Added DataCase coverage for invalid changesets, persisted Author/Post values, association preload, and timestamps.
- Added serial ConnCase coverage for unmatched JSON and malformed session cookies, plus a port-0 loopback Bandit/Req HTTP request with matching request-stop telemetry.

## Verification

- `cd examples/phoenix_meilisearch && mix deps.get --check-locked` — passed.
- `cd examples/phoenix_meilisearch && mix test test/scrypath_demo/ecto_compatibility_test.exs test/scrypath_demo_web/endpoint_compatibility_test.exs` — passed (4 tests).
- `cd examples/phoenix_meilisearch && mix format --check-formatted mix.exs test/scrypath_demo/ecto_compatibility_test.exs test/scrypath_demo_web/endpoint_compatibility_test.exs` — passed.
- `cd examples/phoenix_meilisearch && mix precommit` — passed (6 tests, 0 failures; 4 integration tests excluded).
- `git diff --check` — passed.

## Task Commit

1. **Task 1: Land the atomic fixed-compatible legacy graph and exercise persistence through real HTTP** — `e50fbd5` (`feat`)

## Decisions Made

- Kept Ecto and Decimal transitive; added no direct dependency, override, route, schema, migration, public API, or permanent test harness.
- Used `ThousandIsland.listener_info/1` on the supervised direct Bandit child because the selected public API exposes the ephemeral bound address as `{ip, port}`.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Matched the selected listener introspection return shape
   - **Found during:** Task 1
   - **Issue:** The initial test expected a map, but `ThousandIsland.listener_info/1` returns `{:ok, {ip, port}}` in the resolved Bandit/Thousand Island versions.
   - **Fix:** Asserted the documented tuple shape before issuing the loopback Req request.
   - **Files modified:** `examples/phoenix_meilisearch/test/scrypath_demo_web/endpoint_compatibility_test.exs`
   - **Verification:** Focused real-listener test and `mix precommit` pass.
   - **Committed in:** `e50fbd5`

**Total deviations:** 1 auto-fixed (Rule 1).

## Known Stubs

None.

## Next Phase Readiness

Plan 02 can perform the detached exact-candidate resolution, unsuppressed audit, and supplemental live evidence against this checked legacy graph.

## Self-Check: PASSED

- Confirmed all four task artifacts and this summary exist.
- Confirmed task commit `e50fbd5` exists in git history.
