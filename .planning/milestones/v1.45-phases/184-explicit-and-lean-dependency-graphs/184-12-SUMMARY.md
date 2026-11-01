---
phase: 184-explicit-and-lean-dependency-graphs
plan: "12"
subsystem: infra
tags:
  - docker
  - elixir
  - phoenix
  - dependency-boundaries
  - ecommerce
requires:
  - phase: 184-explicit-and-lean-dependency-graphs
    provides:
      - production runtime configuration and static manifest declarations
provides:
  - isolated dev asset builder for Ops and ecommerce static outputs
  - independent runtime_test and runtime_prod dependency graphs
  - static dependency handoff mutation checker
affects:
  - 184-06
  - ecommerce Docker builds
  - dependency boundary verification
actuals:
  tokens: 6112
  tasks: 2
  commits: 3
  plan_head_before: eb8fdeab9ab6d3753057132ab443184b135651e7
  plan_head_after: 7a09965761531a09964bf8d1708bd838b916e394
tech-stack:
  added: []
  patterns:
    - isolated asset generation with output-only static handoff
    - independent test and production Mix compile graphs
key-files:
  created:
    - examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh
  modified:
    - examples/scrypath_ecommerce/Dockerfile
    - examples/scrypath_ecommerce/docker-e2e-entrypoint.sh
    - examples/scrypath_ecommerce/scripts/phase173-standalone-entrypoint.sh
    - examples/scrypath_ecommerce/compose.yaml
    - examples/scrypath_ecommerce/compose.phase173.yaml
    - test/mix/tasks/dependency_boundary_contract_test.exs
    - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
key-decisions:
  - Keep the existing Elixir/OTP image and resolve each application graph independently per target.
  - Make runtime_test the default final stage while Compose selects it explicitly for both test services.
  - Use copied source fixtures to test clean and mutated static boundary declarations without running Docker.
requirements-completed:
  - DEP-05
coverage:
  - id: D1
    description: Ops and ecommerce assets are built from current source, transferred as static trees, and consumed by independent test and production targets.
    requirement: DEP-05
    verification:
      - kind: integration
        ref: docker build --target runtime_test -f examples/scrypath_ecommerce/Dockerfile .
        status: pass
      - kind: integration
        ref: docker build --target runtime_prod -f examples/scrypath_ecommerce/Dockerfile .
        status: pass
      - kind: e2e
        ref: mix verify.ecommerce_mounted; run p18412-final-mounted-20261030; 4/4 focused Playwright tests
        status: pass
    human_judgment: false
  - id: D2
    description: Static source contracts accept the output-only handoff and reject unsafe builder copies, missing outputs, and runtime wrapper installation.
    requirement: DEP-05
    verification:
      - kind: unit
        ref: test/mix/tasks/dependency_boundary_contract_test.exs#static dependency handoff checker accepts clean output-only targets and rejects mutations
        status: pass
      - kind: other
        ref: bash examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh --static-contract-only
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-10-30
status: complete
---

# Phase 184 Plan 12: Explicit and Lean Dependency Graphs Summary

Two current-source asset bundles now feed separate test and production runtime graphs, with production digests and mutation-tested static handoff contracts.

## Performance

- Duration: 25 min
- Started: 2026-10-30T00:36:55Z
- Completed: 2026-10-30T01:02:40Z
- Tasks: 2
- Files modified: 8

## Accomplishments

- Added an asset_builder stage that independently builds the Ops and ecommerce development wrappers, removes stale generated assets first, and verifies all four JS/CSS outputs.
- Added runtime_test and runtime_prod stages that independently resolve and compile the root, Ops, and ecommerce projects. Production digests each Phoenix app’s generated static tree.
- Updated mounted and standalone test services to use runtime_test. Runtime entrypoints assert prebuilt asset presence and do not install or build wrappers.
- Added a static-only dependency boundary checker and clean/mutated source fixtures for unsafe builder transfer, missing bundle output, and stale runtime wrapper installation.

## Task Commits

1. Task 184-12-01: 4c860da9 — feat(184-12): isolate asset builds from runtime graphs
2. Task 184-12-02 RED: 7b882e35 — test(184-12): add failing static dependency handoff contract
3. Task 184-12-02 GREEN: 7a099657 — feat(184-12): enforce static dependency handoff contract

## Source and Dependency Identities

- Committed source used by the final mounted verifier: 7a09965761531a09964bf8d1708bd838b916e394. Its artifact manifest records the same checkout and built source SHA with dirty=false.
- Host Mix verification used Elixir 1.19.5 / OTP 28.5. Docker targets use the repository’s pinned base image hexpm/elixir:1.19.0-erlang-28.1-debian-bookworm-20260518.
- Lockfile SHA-256:
  - mix.lock: bd30554574b9b902df5e28f027db4dfc04afcb7a7fd8c93b757391e5337d20f8
  - scrypath_ops/mix.lock: a9685eba8236f7925d30044db9b2bf96a3c644d61c5f4a13db66af037f4dc95c
  - examples/scrypath_ecommerce/mix.lock: 9c30fb79d83a5e6ce8b97f583bd62774aff9fd466ec998c4070c4d903b5cb4e1

## Verification

- node --test scripts/ci/ecommerce_build.test.cjs scripts/ci/ecommerce_lifecycle.test.cjs — 41 passed, 0 failed.
- docker compose -p scrypath_p18412_configcheck_20261030 -f examples/scrypath_ecommerce/compose.yaml -f examples/scrypath_ecommerce/compose.e2e.yaml -f examples/scrypath_ecommerce/compose.phase173.yaml config --quiet — passed.
- docker build --target runtime_test -f examples/scrypath_ecommerce/Dockerfile . — passed; image SHA-256 da41612f78d6886ac2651f146146f7ce4d1e574b86f883d912994287f04090d5.
- docker build --target runtime_prod -f examples/scrypath_ecommerce/Dockerfile . — passed; image SHA-256 5cc8fbe2be49176384517f3085aa57f7bd95a9860ada28a2994e9ce1e166e550. Both Ops and ecommerce phx.digest commands completed.
- bash examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh --static-contract-only — passed and emitted its success summary.
- MIX_ENV=test mix test test/mix/tasks/dependency_boundary_contract_test.exs --warnings-as-errors — 14 passed, 0 failed.
- mix verify.ecommerce_mounted — passed against source SHA 7a09965761531a09964bf8d1708bd838b916e394; the focused browser suite passed 4/4. Compose project scrypath_p18412_final_20261030 ended with zero containers, networks, or volumes. Artifacts are outside the checkout at /private/tmp/scrypath-phase184-12-20261030T0034Z/artifacts/docker-focused/p18412-final-mounted-20261030.

## TDD Gate Compliance

- RED commit 7b882e35: the named ExUnit target ran as a single TAP test and failed on the planned assertion that the new checker exists. The semantic failure was intentional; the TAP classifier returned RED_EVIDENCE_OK with reason target_test_failed.
- GREEN commit 7a099657: the contract and all mutation fixtures passed in the 14-test ExUnit run.
- No refactor commit was needed. RED is an ancestor of GREEN.
- The RED record and TAP output are under /private/tmp/scrypath-phase184-12-20261030T0034Z. The classifier was invoked with a temporary --project-dir under that same external directory so the evidence stayed outside this checkout.

## Decisions Made

- Reused the existing image/toolchain policy and limited cross-stage asset transfer to the two complete priv/static trees.
- Kept fixture root selection as an environment-only test seam; the public verifier accepts exactly one argument, --static-contract-only.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking] Grouped the backend_run_error?/1 helpers after the complete format_run_error/1 clause group.
   - Found during: Task 184-12-01, while building the WAE runtime targets.
   - Issue: The separated function-clause groups emitted a compiler warning, which blocked the planned warnings-as-errors target build.
   - Fix: Moved the backend_run_error?/1 clauses below the final format_run_error/1 clause without changing behavior.
   - Files modified: scrypath_ops/lib/scrypath_ops_web/live/search_live.ex.
   - Verification: Both committed runtime_test and runtime_prod targets passed.
   - Commit: 4c860da9.

Total deviations: 1 auto-fixed (Rule 3 blocking compile issue). Impact: a behavior-preserving source-order fix was needed to make the target warning gate complete; no additional scope was introduced.

## Issues Encountered

- The first host Mix verifier attempt pointed at absent checkout-local dependencies and failed before running the task. It was rerun with per-project disposable build paths and the already available external dependency trees; the mounted verification then passed.
- Dependency compilation emitted third-party warnings from Oban and ASN.1 tooling. Both target Docker builds exited successfully; this run does not establish that those dependency warnings are absent.
- The evidence checker rejected an external RED record when invoked with the repository as its allowed root. The record remained in /private/tmp, and the supported explicit project-dir option let the classifier validate it under an external temporary project root.

## User Setup Required

None.

## Next Phase Readiness

Plan 184-12 deliverables and listed verifications are complete. The orchestrator can perform phase-level verification and own central planning-state updates.

## Self-Check: PASSED

- All eight task files exist, and the three task commits are ancestors of the current branch head.
- Measured task commit count is 3 from plan_head_before; source and working tree were clean before writing this summary.
- The task acceptance commands and final mounted run completed successfully.
