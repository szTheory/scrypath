---
phase: 184-explicit-and-lean-dependency-graphs
plan: "06"
subsystem: dependency-boundaries
tags: [elixir, ecto, phoenix, docker, mix]
requires:
  - phase: 184-explicit-and-lean-dependency-graphs
    provides:
      - independent runtime_test and runtime_prod graphs with output-only asset handoff
provides:
  - clean mounted and direct Ops dependency, startup, and auth-mode proofs
  - independent test and production runtime graph and served-asset checks
  - mounted verification that runs the runtime boundary proof before Compose
affects:
  - 184-explicit-and-lean-dependency-graphs
  - ecommerce verification
actuals:
  tokens: 17156
  tasks: 2
  commits: 4
  plan_head_before: 881c0e3ec0997c5c6b0f4b8064e9a9d16a128f92
  plan_head_after: a3ca8c332637232e066173b3f14952c9020afd1d
tech-stack:
  added: []
  patterns:
    - independent clean Mix environments for installed dependency graph and application checks
    - image provenance labels and SHA-256 comparison from asset builder through HTTP response
key-files:
  created: []
  modified:
    - test/release/ops_dependency_boundary_test.exs
    - dev/mix/tasks/verify.ops_ui.ex
    - test/mix/tasks/verify_capability_test.exs
    - examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh
    - examples/scrypath_ecommerce/scripts/verify-e2e.sh
    - scripts/ci/ecommerce_build.test.cjs
    - scripts/ci/ecommerce_lifecycle.test.cjs
    - test/mix/tasks/dependency_boundary_contract_test.exs
key-decisions:
  - "Use isolated Compose projects, private databases, random loopback ports, and external runtime receipts for each test and production proof."
  - "Probe the existing mounted Ops route at /admin/search and standalone route at /ops; their public bundles are served from /assets, so the proof follows the current router without weakening CSRF."
requirements-completed: [DEP-03, DEP-04, DEP-05, DEP-06]
coverage:
  - id: D1
    description: "Mounted and direct Ops consumers prove the intended clean dependency graphs and distinct development diagnostics."
    requirement: DEP-04
    verification:
      - kind: integration
        ref: test/release/ops_dependency_boundary_test.exs#direct Ops dev, test, and production graphs preserve their distinct runtime contracts
        status: pass
      - kind: unit
        ref: test/mix/tasks/verify_capability_test.exs#Ops verification pins the mounted dependency proof before the direct suite
        status: pass
    human_judgment: false
  - id: D2
    description: "Clean mounted test and production consumers reject unavailable optional Sigra before startup and do not invoke protected callbacks."
    requirement: DEP-06
    verification:
      - kind: integration
        ref: test/release/ops_dependency_boundary_test.exs#mounted test and production consumers compile and start without optional Ops dependencies
        status: pass
    human_judgment: false
  - id: D3
    description: "Ops direct and mounted dependency proofs keep Swoosh and the unused Mailer out of the supported graphs."
    requirement: DEP-03
    verification:
      - kind: integration
        ref: test/release/ops_dependency_boundary_test.exs#mounted test and production consumers compile and start without optional Ops dependencies
        status: pass
    human_judgment: false
  - id: D4
    description: "Independent test and production images contain no builder or development dependency leakage and serve the exact current Ops and storefront bundles."
    requirement: DEP-05
    verification:
      - kind: integration
        ref: mix verify.ecommerce_mounted; runtime receipt 20261030T035244Z-60095-1469820387
        status: pass
      - kind: integration
        ref: bash examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh --runtime
        status: pass
    human_judgment: false
  - id: D5
    description: "The maintained mounted and standalone browser routes preserve supported theme, keyboard, and responsive behavior."
    verification:
      - kind: e2e
        ref: mix verify.ecommerce_e2e; run 20261030T035734Z-45111-171843251; 189/189 tests
        status: pass
      - kind: automated_ui
        ref: phase105 evidence; 30/30 light-parity captures; contrast AA failures 0
        status: pass
    human_judgment: false
duration: 2h 54m
completed: 2026-10-30
status: complete
---

# Phase 184 Plan 06: Explicit and Lean Dependency Graphs Summary

**Clean Ops consumer probes and independent test/production asset-serving proofs now run through the mounted verifier**

## Performance

- **Duration:** 2h 54m
- **Started:** 2026-10-29T21:11:58-04:00
- **Completed:** 2026-10-30T00:06:21-04:00
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added isolated mounted test/production consumers and direct Ops dev/test/production checks. They inspect dependency selections, generated application requirements, module code paths, started applications, standalone diagnostics, optional Sigra gating, and protected callback behavior. The Ops capability runs these checks before the existing direct Ops suite.
- Extended the ecommerce dependency proof to independently build and start clean test and production targets, inspect their graphs and environment, reject development-tool leakage, and compare four asset outputs from the builder, target images, and HTTP responses by SHA-256.
- Wired the runtime proof into focused mounted verification. The disposable full browser lane passed 189/189 tests; theme/light-parity evidence passed 30/30 captures and the contrast scan had zero AA failures. I spot-checked captured search and health screens at desktop/mobile sizes across light, dark, and system themes.

## Verification

**Toolchain:** Elixir 1.19.5 / OTP 28.5 via asdf. Mix build, dependency, Hex, and runtime receipt paths were isolated under /private/tmp/scrypath-phase184-06-20261029T220000Z. No dependency lockfiles changed.

**Task 1**

- MIX_ENV=test asdf exec mix test test/mix/tasks/verify_capability_test.exs --warnings-as-errors — PASS, 10 tests.
- MIX_ENV=test asdf exec mix test test/release/ops_dependency_boundary_test.exs --warnings-as-errors — PASS, 2 tests.
- asdf exec mix verify.ops_ui — PASS; dependency proof ran before the existing Ops suite (316 tests).

**Task 2**

- bash -n examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh examples/scrypath_ecommerce/scripts/verify-e2e.sh and bash examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh --static-contract-only — PASS.
- node --test scripts/ci/ecommerce_build.test.cjs scripts/ci/ecommerce_lifecycle.test.cjs — PASS, 43 tests.
- MIX_ENV=test asdf exec mix test test/mix/tasks/dependency_boundary_contract_test.exs --warnings-as-errors — PASS, 14 tests.
- SCRYPATH_DEPENDENCY_BOUNDARY_ARTIFACT_DIR=/private/tmp/scrypath-phase184-06-20261029T220000Z/runtime SCRYPATH_DEPENDENCY_BOUNDARY_COLD=0 bash examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh --runtime — PASS for test and production targets. The canonical mounted run below also completed the runtime proof with the default cold test-image build.
- mix verify.ecommerce_mounted — PASS; clean runtime proof and all 4 focused Playwright tests passed. The exact invocation used the supported asdf tuple, isolated root Mix paths, and external artifact roots under /private/tmp/scrypath-phase184-06-20261029T220000Z.
- mix verify.ecommerce_e2e — PASS; 189/189 browser tests in 6.1 minutes, mounted and standalone readiness passed, 30/30 light-parity captures passed, contrast had 0 AA failures, and owned cleanup reported 0 containers, networks, or volumes. External artifacts: /private/tmp/scrypath-phase184-06-20261029T220000Z/e2e-full-artifacts/20261030T035734Z-45111-171843251. The optional visual judge was marked not required and was not run; no independent UI review is claimed.

**Runtime source and lock identity**

- Checkout SHA used by the runtime and full E2E proofs: 0bd45a1a45cf256ea8548a4ad1a07b5bd6512197; dirty-source fingerprint: sha256:b540fb0be8dc5a705d9c6d6f9b900cb76e5f202ce91f90e3a3f54b34fed88efa.
- Ecommerce Dockerfile SHA-256: 0c8a16da7fbecfca2237bc3a5f6afd85fe76cd4bf38973b1664ba5832d88aa2b.
- Lock SHA-256: root mix.lock bd30554574b9b902df5e28f027db4dfc04afcb7a7fd8c93b757391e5337d20f8; Ops scrypath_ops/mix.lock a9685eba8236f7925d30044db9b2bf96a3c644d61c5f4a13db66af037f4dc95c; ecommerce examples/scrypath_ecommerce/mix.lock 9c30fb79d83a5e6ce8b97f583bd62774aff9fd466ec998c4070c4d903b5cb4e1.
- Runtime receipt 20261030T035244Z-60095-1469820387 records test/prod image identities, ephemeral loopback ports, and cleanup status 0. The full E2E lifecycle receipt records exit status 0 and clean owned-resource cleanup.

## Task Commits

1. **Task 1 RED:** 154d1e1c — test(184-06): pin Ops dependency proof invocation; the target assertion failed because the ordered Ops verification command plan was not exposed.
2. **Task 1 GREEN:** f42ceef1 — feat(184-06): verify clean Ops dependency modes.
3. **Task 2 RED:** 0bd45a1a — test(184-06): pin mounted dependency proof ordering; the target assertion failed because the runtime proof was not part of focused mounted verification.
4. **Task 2 GREEN:** a3ca8c33 — feat(184-06): prove mounted assets in clean images.
5. **Plan metadata:** this summary is committed separately after the task commits.

## Files Created/Modified

- test/release/ops_dependency_boundary_test.exs — real mounted/direct clean consumer graph and startup checks.
- dev/mix/tasks/verify.ops_ui.ex — runs the dependency proof before the direct Ops suite.
- test/mix/tasks/verify_capability_test.exs — pins verifier order and argument behavior.
- examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh — isolated runtime image, graph, startup, served asset, and cleanup proof.
- examples/scrypath_ecommerce/scripts/verify-e2e.sh — external artifact root support and runtime-proof integration.
- scripts/ci/ecommerce_build.test.cjs — focused verifier invocation contract.
- scripts/ci/ecommerce_lifecycle.test.cjs — runtime integration and ordering contracts.
- test/mix/tasks/dependency_boundary_contract_test.exs — wrong-runtime-environment mutation contract.

## Decisions Made

- Runtime acceptance uses uniquely named Compose projects and external receipts, keeping the retained preview and checkout clean.
- Runtime asset checks follow existing router behavior: mounted Ops is under /admin/search, standalone Ops routes are under /ops, and their static bundles are linked at /assets. The verifier leaves the existing CSRF boundary intact.

## Deviations from Plan

**[Rule 3 - Blocking] Aligned standalone asset probes with current router paths** — Found during Task 2. The plan described /ops/assets/..., while the existing standalone Ops page links its assets from /assets; the mounted host uses /admin/search. The verification script now follows those supported routes and validates the linked bundle bytes. No production route or CSRF behavior changed. **Verification:** mix verify.ecommerce_mounted and the direct --runtime proof passed. **Committed in:** a3ca8c33.

**Total deviations:** 1 auto-fixed (Rule 3 - Blocking). **Impact:** The proof exercises the existing application route contract; no scope or public API change.

## Issues Encountered

- The full contrast lane reported 101 AAA advisory items and zero AA failures. The optional paid visual judge was not required by the lane. Representative captures were visually inspected; no independent UI-review claim is made.
- The full browser stack emitted the expected Meilisearch rejection for a cross-tenant filter in its negative-isolation scenario; the browser run passed and all owned services were removed.

## User Setup Required

None.

## Next Phase Readiness

- Plan 184-06 requirements are covered by executable direct/mounted dependency checks and disposable test/production runtime proofs.
- No blocker remains for the dependent plans. STATE.md and ROADMAP.md were not modified; those writes remain with the orchestrator.

## Self-Check: PASSED

- All eight task files exist, and the four RED/GREEN task commits are ancestors of HEAD.
- Evaluation scope resolves this plan with four task commits on the branch.
- The task verification commands passed as recorded above.
