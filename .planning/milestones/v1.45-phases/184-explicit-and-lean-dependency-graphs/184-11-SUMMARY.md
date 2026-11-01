---
phase: 184-explicit-and-lean-dependency-graphs
plan: 11
subsystem: dependencies
tags: [elixir, phoenix, mix, ecto, dependency-boundaries]
requires:
  - phase: 184-02
    provides:
      - "Removed direct Swoosh declarations and the unused mail implementation from the Ops and ecommerce dependency graph."
provides:
  - "Removed the obsolete Ops development mailbox route and ecommerce Swoosh client configuration."
  - "Added executable mutation contracts for restored mail dependencies, source, configuration, and mailbox routing."
  - "Verified the Ops application test suite and ecommerce test compilation on the selected Sigra-compatible toolchain."
affects: [184-07, dependency-boundary-verification]
actuals:
  tokens: 2399
  tasks: 2
  commits: 3
  plan_head_before: c04a28ebb0ba0ca52a133d06fa24a85ca330e685
  plan_head_after: ae590a5c559572b49055005fa68f4e4c12b6c12f
tech-stack:
  added: []
  patterns:
    - "Use parsed Elixir AST fixtures to guard dependency, config, and route boundaries without banning unrelated application settings."
key-files:
  created:
    - test/mix/tasks/dependency_boundary_contract_test.exs
  modified:
    - scrypath_ops/lib/scrypath_ops_web/dev_router.ex
    - examples/scrypath_ecommerce/config/config.exs
    - examples/scrypath_ecommerce/config/dev.exs
    - dev/mix/tasks/verify.phase99.ex
key-decisions:
  - "Detect the removed mailbox route by the /mailbox path so alias spelling cannot bypass the contract."
  - "Inspect active Elixir configuration and router ASTs while allowing unrelated Phoenix, Oban, Endpoint, and Repo configuration."
requirements-completed: ["DEP-03"]
coverage:
  - id: D1
    description: "Mail-free Ops routing and ecommerce configuration are guarded by mutation contracts and verified against the real application test and compile paths."
    requirement: DEP-03
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#mail configuration fixtures reject restored settings in every configuration site"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#mailbox route fixtures reject the removed path regardless of target alias"
        status: pass
      - kind: integration
        ref: "mix verify.repository_contracts (112 tests)"
        status: pass
      - kind: integration
        ref: "mix verify.ops_ui (2 doctests, 309 tests; disposable Postgres)"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix do deps.get + compile --warnings-as-errors (ecommerce)"
        status: pass
    human_judgment: false
duration: 14 min
completed: 2026-10-29
status: complete
---

# Phase 184 Plan 11: Explicit and Lean Dependency Graphs Summary

**Mail-free Ops routing and ecommerce configuration with AST mutation contracts and real application verification**

## Performance

- **Duration:** 14 min from the first recorded runtime artifact; initial context-reading time was not timed.
- **Started:** 2026-10-29T21:04:51Z (first recorded verification workspace)
- **Completed:** 2026-10-29T21:19:06Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Removed only the /dev/mailbox Swoosh preview forward while preserving the standalone root, /ops, dashboard, and diagnostics fixture routes.
- Removed the ecommerce host Swoosh API-client configuration and corrected the stale mailbox comment.
- Added mutation fixtures covering direct dependency declarations, deleted mail source, all five Ops and both host config files, and qualified or aliased mailbox forwards; wired the contract into mix verify.repository_contracts.
- Verified the Ops test suite and ecommerce test-environment compile using Elixir 1.18.4 / OTP 27.3.4.15, with temporary build and dependency paths outside the checkout.

## TDD Gate Compliance

- **RED:** The test named “mailbox route fixtures reject the removed path regardless of target alias” failed on its intended assertion: the current detector missed forward("/mailbox", MailboxPreview). The run reported 5 passing and 1 failing test. The actual TAP output and evidence record are at /private/tmp/scrypath-phase184-11-20261029T210446Z/task2-red.tap and /private/tmp/scrypath-phase184-11-20261029T210446Z/task2-red-evidence.json; the GSD classifier returned RED_EVIDENCE_OK. A temporary validator input copy was removed after validation.
- **GREEN:** The detector now rejects a forward whose path is /mailbox regardless of target alias. The focused contract passes with 6 tests and 0 failures.
- **REFACTOR:** None needed.

## Verification Results

- MIX_ENV=test mix test test/mix/tasks/dependency_boundary_contract_test.exs --warnings-as-errors — passed, 6 tests, 0 failures.
- mix verify.repository_contracts — passed, 112 tests, 0 failures.
- mix verify.ops_ui — passed, 2 doctests and 309 tests, 0 failures, against a disposable Postgres container on 127.0.0.1:55432.
- From examples/scrypath_ecommerce: MIX_ENV=test mix do deps.get + compile --warnings-as-errors — passed; generated ScrypathEcommerce.
- mix format --check-formatted on all five changed files — passed.

The verified source was commit ae590a5c559572b49055005fa68f4e4c12b6c12f. Lockfiles were unchanged. SHA-256 identities after verification:

- mix.lock: bd30554574b9b902df5e28f027db4dfc04afcb7a7fd8c93b757391e5337d20f8
- scrypath_ops/mix.lock: a9685eba8236f7925d30044db9b2bf96a3c644d61c5f4a13db66af037f4dc95c
- examples/scrypath_ecommerce/mix.lock: 9c30fb79d83a5e6ce8b97f583bd62774aff9fd466ec998c4070c4d903b5cb4e1

The Ops lock resolved Sigra 1.5.0. Runtime logs are retained outside the checkout under /private/tmp/scrypath-phase184-11-20261029T210446Z/.

## Task Commits

1. **Task 1: Remove obsolete development mailbox route and host mail config** — c46d5334 (fix).
2. **Task 2 RED: Add mail restoration fixtures** — 1bb71bf5 (test).
3. **Task 2 GREEN: Reject aliased mailbox route restorations** — ae590a5c (feat).

## Files Created/Modified

- test/mix/tasks/dependency_boundary_contract_test.exs — AST-based negative contracts and clean/restored fixtures.
- scrypath_ops/lib/scrypath_ops_web/dev_router.ex — removed the obsolete mailbox forward.
- examples/scrypath_ecommerce/config/config.exs — removed Swoosh client configuration.
- examples/scrypath_ecommerce/config/dev.exs — corrected the stale mailbox comment.
- dev/mix/tasks/verify.phase99.ex — added the contract to the repository verification lane.

## Decisions Made

- Key the mailbox mutation contract on the removed route path rather than a specific alias.
- Limit negative checks to active dependency tuples, configuration ASTs, and router ASTs so comments and unrelated application configuration do not create false positives.

## Deviations from Plan

None in source scope. A temporary external Mix wrapper routed the nested Ops command to its own disposable build and dependency target; this avoided mixing the Ops and root lock graphs.

## Issues Encountered

- The initial Ops invocation inherited the root temporary dependency path in its nested login shell and failed to start stream_data. I routed the nested shell through the external wrapper, restored the root target from its locked dependencies, and reran the canonical task successfully with an independent Ops target.
- Successful Ops and ecommerce runs emitted existing warnings from untouched search_live.ex, sync_drift_live.ex, and dependency compilation, plus Hex advisory notices for locked Bandit and Cloak packages. The commands exited zero; these unrelated files and lock versions were left unchanged under this plan's scope.
- The retained UI preview preflight reported that its named checkout does not include origin/main. The checkout also had unrelated dirty and untracked work. No preview files, container state, or data were changed, and no visual review claim is made for this code-only plan.

## User Setup Required

None - no external service configuration is required.

## Next Phase Readiness

The mail-free route and host configuration boundary is implemented and covered. Lock pruning remains owned by plan 184-07.

---

*Phase: 184-explicit-and-lean-dependency-graphs*
*Completed: 2026-10-29*

## Self-Check: PASSED

- All five planned source/test files and this summary exist.
- The three task commits are ancestors of the worktree HEAD.
- Focused contract, repository contract, Ops application, and ecommerce compile receipts all record exit code 0.
- All three lockfile SHA-256 values match the values captured before application verification.
