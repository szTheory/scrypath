---
phase: 184-explicit-and-lean-dependency-graphs
plan: "03"
subsystem: dependencies
tags: [elixir, mix, phoenix, telemetry, optional-dependencies]
requires:
  - phase: 184-11
    provides:
      - Removed the obsolete Ops development mailbox route and its Swoosh-only references.
      - Parsed-AST dependency and route contracts that preserve unrelated host configuration.
provides:
  - Ops Dashboard, metrics and poller dependencies are optional and development-only.
  - Compile-time capability guards preserve direct-dev diagnostics without imposing them on mounted, test or production builds.
  - Application tests preserve core children and separate standalone Endpoint/Repo ownership from diagnostics.
affects: [184-06, dependency-boundary-verification]
actuals:
  tokens: 5374
  tasks: 2
  commits: 3
  plan_head_before: 0a34e4ce707ceed516b2bb6922439209fe4af34c
  plan_head_after: ff1128f692fa0841e5b7d382d11dea0fe0527db1
tech-stack:
  added: []
  patterns:
    - Optional Phoenix router DSL is injected by a compile-time macro only when the module and tracked route policy are available.
    - Diagnostic supervision follows compiled capability; standalone continues to own only Ops Repo, DNSCluster and Endpoint.
key-files:
  created: []
  modified:
    - scrypath_ops/mix.exs
    - scrypath_ops/lib/scrypath_ops_web/telemetry.ex
    - scrypath_ops/lib/scrypath_ops/application.ex
    - scrypath_ops/lib/scrypath_ops_web/endpoint.ex
    - scrypath_ops/lib/scrypath_ops_web/dev_router.ex
    - scrypath_ops/test/scrypath_ops/application_test.exs
    - scrypath_ops/test/scrypath_ops_web/router_test.exs
    - test/mix/tasks/dependency_boundary_contract_test.exs
key-decisions:
  - Keep the three diagnostic dependencies both only: :dev and optional so mounted hosts do not inherit them.
  - Pass Application.compile_env(:scrypath_ops, :dev_routes) into the optional router macro, preserving route policy while avoiding import expansion when Dashboard is absent.
  - Keep core Telemetry, RecoveryObservation, PubSub and TaskSupervisor independent from diagnostic capability and standalone ownership.
requirements-completed: [DEP-04]
coverage:
  - id: D1
    description: Ops diagnostics remain available in direct development while mounted, test and production modes preserve core supervision and supported routes without the diagnostic dependency slice.
    requirement: DEP-04
    verification:
      - kind: integration
        ref: MIX_ENV=dev mix run --no-start; asserts /dev/dashboard, metrics and diagnostic/core children
        status: pass
      - kind: integration
        ref: MIX_ENV=test mix run --no-start; Dashboard, RequestLogger, Metrics and poller code-path absence
        status: pass
      - kind: integration
        ref: MIX_ENV=prod mix compile and mounted-mode mix run startup; core children present, Repo/Endpoint/diagnostics absent
        status: pass
      - kind: unit
        ref: test/scrypath_ops/application_test.exs and test/scrypath_ops_web/router_test.exs (5 tests)
        status: pass
      - kind: unit
        ref: test/mix/tasks/dependency_boundary_contract_test.exs (8 tests)
        status: pass
      - kind: integration
        ref: mix verify.ops_ui (2 doctests, 311 tests; disposable Postgres)
        status: pass
      - kind: other
        ref: mix format --check-formatted
        status: pass
    human_judgment: false
duration: 24 min
completed: 2026-10-29
status: complete
---

# Phase 184 Plan 03: Explicit and Lean Dependency Graphs Summary

**ScrypathOps keeps Dashboard and metrics available in direct development while mounted, test and production builds retain core routes and ownership without the diagnostic slice.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-10-29T21:23:41Z
- **Completed:** 2026-10-29T21:49:02Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Scoped LiveDashboard, telemetry_metrics and telemetry_poller to optional direct-development dependencies.
- Guarded optional Telemetry module compilation, the RequestLogger plug, dashboard routes and telemetry supervisor child at their compile/runtime boundaries.
- Verified mounted ownership and supported operator routes while retaining RecoveryObservation, PubSub, TaskSupervisor and core Telemetry.

## Task Commits

1. **Task 1 RED:** 01270a4 — test(184-03): add failing diagnostics boundary tests.
2. **Task 1 GREEN:** 2124058 — feat(184-03): scope Ops diagnostics to direct development.
3. **Task 2 contract update:** ff1128f — test(184-03): pin compile-safe diagnostic guards.


- **Orchestrator repair:** `bdf54f8e6480f81c6405f74155c85952875af01e` — fix(184-03): require the complete diagnostics capability.

## Files Created/Modified

- scrypath_ops/mix.exs — dev-only optional diagnostic dependencies.
- scrypath_ops/lib/scrypath_ops_web/telemetry.ex — conditional metrics module compilation.
- scrypath_ops/lib/scrypath_ops/application.ex — capability-specific diagnostic child with core and standalone children kept separate.
- scrypath_ops/lib/scrypath_ops_web/endpoint.ex — RequestLogger plug guarded by module availability.
- scrypath_ops/lib/scrypath_ops_web/dev_router.ex — optional Dashboard macro expansion and unchanged Ops routes.
- scrypath_ops/test/scrypath_ops/application_test.exs — diagnostic and runtime ownership assertions.
- scrypath_ops/test/scrypath_ops_web/router_test.exs — supported route and asset assertions.
- test/mix/tasks/dependency_boundary_contract_test.exs — dependency scope and compile-guard contracts.

## Decisions Made

- Diagnostics require both a dev-only optional dependency declaration and capability-aware compile/start behavior.
- The dashboard route receives Mix-tracked dev_routes configuration as a macro argument so absent Dashboard macros are never expanded.
- The standalone setting controls Endpoint/Repo/DNSCluster ownership only; it does not select dependencies or diagnostic children.

## TDD Gate Compliance

- **RED:** Commit 01270a4 added the dependency and capability contract tests. The TAP report recorded eight executed tests; the named dependency-scope target failed on the planned assertion, and the classifier returned RED_EVIDENCE_OK.
- **GREEN:** Commit 2124058 implemented the optional/dev dependency scopes and capability guards. Direct-dev, test, production and Ops-suite checks passed.
- **REFACTOR:** None required.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Make the optional dashboard DSL compile-safe**

- **Found during:** Task 1 (compiler/startup boundary).
- **Issue:** An import nested in a false if branch was still expanded during router compilation when the dashboard dependency was absent.
- **Fix:** Added a private macro that inserts the Dashboard import and route only when the module is available and the compile-time dev_routes policy is enabled; updated the source contract to pin this two-part guard.
- **Files modified:** scrypath_ops/lib/scrypath_ops_web/dev_router.ex, test/mix/tasks/dependency_boundary_contract_test.exs.
- **Verification:** MIX_ENV=test Ops compile and route tests pass; direct dev exposes /dev/dashboard and starts telemetry; clean test target has no dashboard code path.
- **Committed in:** 2124058 and ff1128f.

**Total deviations:** 1 auto-fixed (1 Rule 1 bug).
**Impact on plan:** Required to make the planned capability boundary compile safely; no product scope changed.

## Issues Encountered

An initial full Ops run hit connection saturation in the disposable Postgres instance. The final full-suite rerun used ERL_FLAGS=+S 4 and passed with 2 doctests and 311 tests. Existing non-blocking search_live compile and async-assign warnings were unchanged.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

This plan's source, ownership and route checks are complete. The independent clean-consumer and mounted-host matrix remains owned by 184-06; no blocker remains for the other phase plans.

## Self-Check: PASSED

- All eight task files exist.
- The RED, GREEN and contract commits are ancestors of the current plan head.
- Plan commit-scope evaluation resolved and found three plan commits.
- Required plan verification commands passed.

---
*Phase: 184-explicit-and-lean-dependency-graphs*
*Completed: 2026-10-29*

