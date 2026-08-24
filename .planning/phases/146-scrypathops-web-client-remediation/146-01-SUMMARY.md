---
phase: 146-scrypathops-web-client-remediation
plan: 01
subsystem: dependencies
tags: [elixir, phoenix, swoosh, req, postgrex, security]
requires:
  - phase: 145-legacy-phoenix-and-ecto-decimal-remediation
    provides: fixed-compatible legacy graph and shared Req closure
provides:
  - approved ScrypathOps web, mailer, and Postgrex dependency bounds
  - deterministic fixed-compatible Ops lock closure
  - service-free Swoosh.ApiClient.Req request and transport-error contract
affects: [146-02, 146-03, 147-ecommerce-mounted-ops-remediation-and-closure-evidence]
tech-stack:
  added: []
  patterns: [direct real-client Req.Test contracts, bounded causal lock updates]
key-files:
  created:
    - scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs
  modified:
    - scrypath_ops/mix.exs
    - scrypath_ops/mix.lock
key-decisions:
  - "Retained the reviewed Plug 1.19.5 causal lock selection for deterministic proof; the later execution-discovery amendment accepts an audit-clean compatible transitive Plug 1.x in lockless evidence without moving the primary lock."
  - "Called Swoosh.ApiClient.Req directly with per-test Req.Test plugs, preserving the suite-wide Swoosh test adapter configuration."
patterns-established:
  - "Swoosh HTTP-client compatibility is proven through direct API-client calls and per-test Req.Test ownership, without provider traffic or global config changes."
requirements-completed: [SEC-03, EVID-03]
coverage:
  - id: D1
    description: "Fixed-compatible ScrypathOps dependency manifest and causal lock closure."
    requirement: SEC-03
    verification:
      - kind: other
        ref: "cd scrypath_ops && mix deps.get --check-locked && mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Production-selected Swoosh.ApiClient.Req request precedence, raw response, and transport error behavior."
    requirement: SEC-03
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Postgrex 0.22.4 publication and affected-range decision remains live-confirmed."
    requirement: EVID-03
    verification:
      - kind: other
        ref: "Hex registry and EEF CNA jq predicates in 146-01-PLAN.md"
        status: pass
    human_judgment: false
duration: 24min
completed: 2026-08-24
status: complete
---

# Phase 146 Plan 01: Fixed-candidate Swoosh Req Path Summary

**Fixed-compatible ScrypathOps Phoenix, Swoosh, and Postgrex bounds with a direct Req.Test contract for the production-selected mail HTTP client.**

## Performance

- **Duration:** 24 min
- **Completed:** 2026-08-24
- **Tasks:** 1/1
- **Files modified:** 3

## Accomplishments

- Bound Phoenix, LiveView, Bandit, Swoosh, and Postgrex to the approved fixed-compatible cohort while retaining Req and all forbidden packages as transitive dependencies.
- Updated the standalone Ops lock through the targeted resolver closure and retained Plug 1.19.5, Mint 1.9.3, and hpax 1.0.4.
- Added service-free direct Swoosh.ApiClient.Req coverage for initialization, POST request precedence, raw response normalization, forwarded options, and timeout propagation.

## Verification

- Live Hex and EEF CNA Postgrex dual-source jq predicates: passed before dependency edits.
- `cd scrypath_ops && mix test test/scrypath_ops/swoosh_api_client_req_test.exs`: passed (2 tests).
- `cd scrypath_ops && mix deps.get --check-locked`: passed.
- `cd scrypath_ops && mix compile --warnings-as-errors`: passed.
- `cd scrypath_ops && mix precommit`: passed (2 doctests, 154 tests, 0 failures).

## Task Commit

1. **Task 1: Build and commit the fixed-candidate Swoosh Req path end to end** - `59d2e6a` (feat)

## Files Created/Modified

- `scrypath_ops/mix.exs` - declares the approved direct fixed-compatible dependency bounds.
- `scrypath_ops/mix.lock` - records the reviewed causal resolution, including the fixed Plug selection.
- `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs` - exercises the real Swoosh Req client through per-test Req.Test plugs.

## Decisions Made

- Kept the reviewed causal Plug 1.19.5 lock row for deterministic proof and introduced no direct Plug ownership or override. Plan 146-03 later established that the former `< 1.20.0` fresh-proof ceiling conflicted with transitive ownership; amended D-05 now accepts an audit-clean compatible Plug 1.x for lockless evidence without changing this lock result.
- Used direct calls to `Swoosh.ApiClient.Req` so normal test configuration remains `Swoosh.Adapters.Test` with `api_client: false`.

## Deviations from Plan

None - plan executed exactly as written at the time. The reviewed lock retained Plug 1.19.5; the later D-05 execution-discovery amendment changes only what lockless evidence may accept, not this deterministic result.

## Issues Encountered

- The first targeted resolver result selected Plug 1.20.3. The reviewed 1.19.5 lock selection passed the checked-lock, compile, focused-test, and precommit gates. Plan 146-03 later confirmed 1.20.3 as a valid transitive 1.x fresh selection under amended D-05, subject to the mandatory unsuppressed audit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 146-02 can run the root Ops verification and exact-candidate evidence gates against implementation commit `59d2e6a`.

## Self-Check: PASSED

- Confirmed the three implementation files exist and commit `59d2e6a` contains exactly those files.
- Confirmed no tracked files were deleted by the implementation commit.
