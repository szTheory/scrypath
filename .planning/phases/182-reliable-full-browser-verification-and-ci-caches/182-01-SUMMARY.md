---
phase: 182-reliable-full-browser-verification-and-ci-caches
plan: "01"
subsystem: testing
tags: [docker-compose, bash, playwright, node-test]

requires: []
provides:
  - "Full-only mounted and standalone Ops route readiness in the canonical isolated Compose project."
  - "Per-run lifecycle evidence and failure-preserving disposal for verifier artifacts and owned Docker resources."
affects: [182-02, 182-04, ecommerce-e2e-verification]

actuals:
  tokens: 7761
  tasks: 2
  commits: 5
plan_head_before: ba624a7452e717c335a26369b8db8523d2551ee9
plan_head_after: 53135c6ec54658aeb62ef19806553ec64e7816bf

tech-stack:
  added: []
  patterns:
    - "Readiness-only diagnostics use production Compose and browser-network route checks but never claim Playwright acceptance."
    - "Verifier finalization reports original, artifact-copy and cleanup status separately while restricting disposal to the owned Compose project."

key-files:
  created: []
  modified:
    - examples/scrypath_ecommerce/scripts/verify-e2e.sh
    - examples/scrypath_ecommerce/docker-playwright.sh
    - scripts/ci/ecommerce_lifecycle.test.cjs

key-decisions:
  - "Full mode alone adds the Phase 173 overlay and waits for both actual Ops fixture routes before browser execution."
  - "The readiness-only diagnostic builds the production full graph and stops before Playwright, keeping readiness proof distinct from browser acceptance."
  - "Cleanup uses exact Compose project labels and retains the original verifier exit status when artifact collection or teardown also fails."

patterns-established:
  - "Use one unique Compose project for full-scope config validation, services, diagnostics and cleanup."
  - "Record lifecycle.json before exit with readiness routes, original exit status, artifact-copy result and owned container/network/volume counts."

requirements-completed: []

coverage:
  - id: D1
    description: "The production full diagnostic reaches mounted and standalone Ops health routes in one isolated full graph while focused scope remains unchanged."
    verification:
      - kind: integration
        ref: "KEEP_E2E_STACK=0 bash examples/scrypath_ecommerce/scripts/verify-e2e.sh full --readiness-only"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_lifecycle.test.cjs#full readiness diagnostic uses the full overlay without claiming browser acceptance"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_lifecycle.test.cjs#focused verification keeps its existing Compose service scope"
        status: pass
      - kind: other
        ref: "docker compose config --format json with focused/full service and host-port assertions"
        status: pass
    human_judgment: false
  - id: D2
    description: "Lifecycle evidence preserves earlier failures and makes artifact-copy, cleanup, owned-resource leak and debug-preservation outcomes visible."
    verification:
      - kind: unit
        ref: "scripts/ci/ecommerce_lifecycle.test.cjs#browser failure stays primary when artifact copies and Compose down also fail"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_lifecycle.test.cjs#artifact copy failure makes an otherwise successful verification fail"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_lifecycle.test.cjs#owned network or volume leaks fail success while every query is project-scoped"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_lifecycle.test.cjs#successful verification records readiness and confirms owned resources are gone"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_lifecycle.test.cjs#KEEP_E2E_STACK preserves the owned project and is reported as not clean"
        status: pass
    human_judgment: false

duration: 23 min
completed: 2026-10-26
status: complete
---

# Phase 182 Plan 01: Full-Stack Readiness and Lifecycle Summary

**Full verification now probes mounted and standalone Ops routes in one disposable Compose project, with readiness diagnostics separated from browser acceptance and lifecycle failures reported without masking the original result.**

## Performance

- **Duration:** 23 min
- **Started:** 2026-10-26T23:28:22Z
- **Completed:** 2026-10-26T23:52:17Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Full scope now appends the Phase 173 Compose overlay, builds the actual full graph, and requires both mounted `/admin/search/phase173/health` and standalone `/ops/phase173/health` routes before Playwright can run. Focused scope retains its prior service graph.
- Added `full --readiness-only` to exercise the production browser-network readiness path, then exit with explicit output that Playwright and full-browser acceptance were not run.
- Added per-run `lifecycle.json`, bounded Docker operations and bounded Compose diagnostics. Finalization records artifact-copy and cleanup results separately, preserves the original verifier exit code, and fails on remaining owned containers, networks or volumes. `KEEP_E2E_STACK=1` reports `preserved_not_clean` and exits nonzero.

## Task Commits

1. **Task 1 RED:** `e7d1c89c` — `test(182-01): add full verifier lifecycle behavior tests`
2. **Task 1 GREEN:** `fd6857db` — `feat(182-01): add full-stack browser readiness tracer`
3. **Task 2 RED:** `fef21879` — `test(182-01): cover verifier lifecycle failures`
4. **Docker-double correction:** `dedd7566` — `test(182-01): model successful browser containers`
5. **Task 2 GREEN:** `53135c6e` — `feat(182-01): preserve verifier failures and owned cleanup`

**Plan metadata:** recorded after summary self-check.

## Files Created/Modified

- `examples/scrypath_ecommerce/scripts/verify-e2e.sh` — full-only overlay selection, unique run artifacts, bounded Docker calls, lifecycle status capture and project-label-scoped disposal.
- `examples/scrypath_ecommerce/docker-playwright.sh` — bounded web and fixture-route readiness plus explicit readiness-only exit before Playwright.
- `scripts/ci/ecommerce_lifecycle.test.cjs` — Docker-double contracts for full/focused scope, route ordering and failure-preserving lifecycle behavior.

## Decisions Made

- Reused the existing Phase 173 overlay for full scope so mounted and standalone Ops routes share one isolated Compose network and project.
- Kept the readiness-only diagnostic explicitly ineligible for browser acceptance; actual route health does not substitute for the normal Playwright run.
- Gave the verifier's original status precedence over artifact-copy and cleanup failures while recording each finalization result in `lifecycle.json`.
- Left `requirements-completed` empty. This plan proves readiness and lifecycle behavior, but it did not run the full browser suite or hosted exact-SHA acceptance required to complete BROW-01/BROW-03.

## TDD Gate Compliance

- **Task 1 RED:** `node --test --test-reporter=tap scripts/ci/ecommerce_lifecycle.test.cjs` returned 1. Target test `full readiness diagnostic uses the full overlay without claiming browser acceptance` executed and failed on the planned assertion that full scope includes `compose.phase173.yaml`. The evidence classifier returned `RED_EVIDENCE_OK`; the failure was an assertion on planned behavior.
- **Task 1 GREEN:** `fd6857db` added the full-only overlay and actual browser-network route readiness. The real diagnostic passed after the commit and again against the final committed lifecycle implementation.
- **Task 2 RED:** the same TAP command returned 1. Target test `browser failure stays primary when artifact copies and Compose down also fail` executed and failed on the assertion that lifecycle evidence must be written. The evidence classifier returned `RED_EVIDENCE_OK`; the failure was the planned missing lifecycle record.
- **Task 2 GREEN:** `53135c6e` added lifecycle reporting and ownership checks. Final Node run passed all 12 tests with zero failures, skips or cancellations.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The first diagnostic attempt did not pass readiness-only mode through Compose and began the browser suite. It was stopped after the first test, and its disposable project was cleaned. The verifier now passes `E2E_READINESS_ONLY=1` explicitly to `docker compose run`; subsequent diagnostics exited before Playwright.
- Docker Buildx initially could not write its external activity metadata under the sandbox. The authorized escalation mechanism allowed the same disposable diagnostic to run; sandbox restrictions were not bypassed.
- Git initially could not create the linked worktree's index lock outside the writable checkout. Staging and commits were retried through the authorized escalation mechanism with normal hooks enabled.
- The final diagnostic's `lifecycle.json` records both routes passed, artifact collection passed, and cleanup counts of zero containers, networks and volumes. The uniquely labeled Docker project left no resources behind.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The full-stack route tracer and owned cleanup behavior are ready for subsequent Phase 182 work. The diagnostic is not full-browser acceptance; BROW-01 and BROW-03 remain unmarked until their full browser and hosted exact-SHA evidence is produced. The unrelated root `.planning/config.json` edit remains preserved outside this worktree in `/private/tmp/scrypath-phase182-execution/config-before.patch`.

## Self-Check: PASSED

- Summary and all three modified source files exist.
- All five plan commits are ancestors of the execution branch.
- Evaluation scope resolves five plan commits on this branch.
- `STATE.md` and `ROADMAP.md` are unchanged.

---
*Phase: 182-reliable-full-browser-verification-and-ci-caches*
*Completed: 2026-10-26*
