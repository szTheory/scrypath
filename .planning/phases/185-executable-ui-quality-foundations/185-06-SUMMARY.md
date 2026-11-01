---
phase: 185-executable-ui-quality-foundations
plan: "06"
subsystem: ui
tags: [tailwind, css, bundle-contract, mounted-runtime]

requires:
  - phase: 185-05
    provides: Source-pinned pre-change evidence for utility preservation
provides:
  - Color utility namespace resets for standalone Ops and ecommerce host CSS
  - Forced generated-bundle assertions wired into the existing mounted dependency-boundary lane
affects: [185-09, UIF-02]

actuals:
  tokens: 3739
  tasks: 2
  commits: 5
  plan_head_before: ef02737da30944c5cd7f12a6da3fb021d1b1e438
  plan_head_after: 3ec93c4b380ea91e2f7d7bc73d602cc2f551019b

tech-stack:
  added: []
  patterns:
    - Force representative Tailwind utilities only inside disposable build copies or containers
    - Assert each generated CSS profile independently and inspect the actual mounted stylesheet order
key-files:
  created:
    - scripts/ci/ui_bundle_contract.cjs
  modified:
    - scrypath_ops/assets/css/app.css
    - examples/scrypath_ecommerce/assets/css/app.css
    - scripts/ci/ui_bundle_contract.test.cjs
    - examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh
key-decisions:
  - Reset only the color namespace and explicitly restore black and white in both CSS profiles
  - Keep semantic primary and base-content utilities owned by Ops; mounted pages load the separate Ops stylesheet after host CSS
  - Require the bundle helper only in runtime verification, leaving static-only source fixtures independent
requirements: ["UIF-02"]
requirements-completed: ["UIF-02"]

coverage:
  - id: D1
    description: Both generated CSS profiles omit forced default palette utilities and retain black, white, spacing, and typography utilities; standalone Ops also retains its semantic utilities.
    requirement: UIF-02
    verification:
      - kind: integration
        ref: scripts/ci/ui_bundle_contract.test.cjs#both configured Tailwind profiles remove forced default palette utilities
        status: pass
    human_judgment: false
  - id: D2
    description: The required mounted lane verifies both forced bundles, actual host-first/Ops-second stylesheet composition, and independent test and production runtime asset serving.
    requirement: UIF-02
    verification:
      - kind: integration
        ref: mix verify.ecommerce_mounted; source SHA 3ec93c4b; receipt /private/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-dependency-boundary-20261101t013952z-45200-14645503.dCB1kP/runtime-receipt.json
        status: pass
    human_judgment: false
  - id: D3
    description: Static-only dependency-boundary fixtures remain runnable without the runtime-only bundle helper.
    verification:
      - kind: unit
        ref: scripts/ci/ui_bundle_contract.test.cjs#static dependency boundary mode does not require the runtime bundle helper
        status: pass
    human_judgment: false

duration: 98 min
completed: 2026-10-31
status: complete
---

# Phase 185 Plan 06: CSS utility preservation summary

Tailwind color resets preserve forced utilities in the standalone Ops and ecommerce host bundles, with mounted stylesheet order and runtime boundaries checked in the existing disposable lane.

## Performance

- Duration: 98 min
- Started: 2026-10-31T20:09:43-04:00
- Completed: 2026-10-31T21:47:13-04:00
- Tasks: 2
- Files modified: 5

## Accomplishments

- Added only the color reset and explicit black/white definitions to both actual CSS source profiles. Spacing, typography, focus treatment, and other declarations remain intact.
- Added scripts/ci/ui_bundle_contract.cjs and tests that force representative utilities into disposable builds, then assert default palette removal, required black/white and generic utilities, and Ops-owned semantic utilities.
- Wired those assertions into the existing mounted dependency-boundary lane. It now checks both generated outputs and the actual mounted HTML in test and production, while preserving the host stylesheet followed by the independently served Ops stylesheet.
- Kept runtime builders out of test and production runtime images. No packages or lockfiles changed.

## Task Commits

1. Task 185-06-01 RED: 1a9ad36b and ce36a6ae. These existing behavioral RED commits captured actual forced bundle output before implementation; they were preserved and not rerun.
2. Task 185-06-01 GREEN: d87aec9f — reset the color namespace in both profiles and add generated-output assertions.
3. Task 185-06-02 RED: 67ba7446 — digest-named host stylesheet assertion failed on the intended behavior. The complete TAP report is at /private/tmp/scrypath-phase185-06-agent-p185-06-1zmhv7id/task2-mounted-red.tap; machine classification returned RED_EVIDENCE_OK.
4. Task 185-06-02 GREEN: ccf22f2c — recognize digest-named host and Ops CSS paths and run the bundle checks in the mounted lane.
5. Task 185-06-02 regression RED: bc77f8d6 — sparse static-only fixture exposed an unnecessary runtime-helper prerequisite. Its TAP report is at /private/tmp/scrypath-phase185-06-agent-p185-06-1zmhv7id/task2-static-boundary-red.tap; machine classification returned RED_EVIDENCE_OK.
6. Task 185-06-02 fix: 3ec93c4b — require the bundle helper only in runtime mode.

## Verification

- node --test --test-concurrency=1 scripts/ci/ui_bundle_contract.test.cjs scripts/ci/ecommerce_build.test.cjs scripts/ci/ecommerce_lifecycle.test.cjs — passed, 54 tests. Captured at /private/tmp/scrypath-phase185-06-agent-p185-06-1zmhv7id/node-regressions-final.log.
- ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' MIX_ENV=test mix verify.repository_contracts — passed, 145 tests.
- ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' MIX_ENV=test BUILDX_CONFIG=/private/tmp/scrypath-phase185-06-agent-p185-06-1zmhv7id/buildx-config mix verify.ecommerce_mounted — passed against source SHA 3ec93c4b. Both forced bundles and both mounted responses passed; the focused browser lane passed four tests. Receipt cleanup_status is 0, with no owned containers, networks, or volumes left. Full evidence remains under /private/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-dependency-boundary-20261101t013952z-45200-14645503.dCB1kP/.
- The actual generated CSS artifacts from the Node build are under /private/tmp/scrypath-phase185-06-agent-p185-06-1zmhv7id/ui-bundle-final/ecde70da354644e7a60fc50aec2527a2/.

## Decisions Made

The ecommerce host owns no DaisyUI semantic theme or plugin. Its generated bundle is checked for generic utilities, while semantic primary and base-content utilities are asserted in the standalone Ops bundle. The mounted HTML must link host CSS first and the separate Ops CSS second. No host mapping or duplicate semantic theme was introduced.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Keep the runtime bundle helper out of static-only fixture prerequisites.
   - Found during: Task 2 repository-contract verification.
   - Issue: Adding the helper to the shared required-file list caused the static-only clean-copy fixture to fail, although that mode does not invoke the helper.
   - Fix: Move the helper existence check into the runtime branch and add a sparse-fixture regression test.
   - Files modified: scripts/ci/ui_bundle_contract.test.cjs, examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh.
   - Verification: Regression test passed; mix verify.repository_contracts passed with 145 tests.
   - Commits: bc77f8d6 (RED test), 3ec93c4b (fix).

Total deviations: 1 auto-fixed (Rule 1 bug). Impact: preserves static verification and runtime bundle enforcement without changing the plan’s product scope.

## Issues Encountered

- The first repository-contract attempt was blocked when the sandbox denied Git’s FETCH_HEAD write. Retrying with the task’s required Git-metadata permission reached the assertions. The final committed-tree run passed.
- The first mounted build could not write to Docker’s default Buildx state directory. The retry used an isolated Buildx config under /private/tmp.
- The first mounted response check revealed Phoenix’s digest-named host CSS path. The matcher and its test were corrected, then the final test and production mounted responses passed.
- A concurrent Node run hit an existing lifecycle readiness deadline during the slow bundle build. The isolated lifecycle case passed, and the complete serialized suite passed with 54 tests.
- Node’s native TAP output for AssertionError diagnostics was rejected by the RED classifier; tap-flat was not installed. The tests now emit plain failure errors, and both new RED reports were machine-classified successfully. No package was installed.

## User Setup Required

None.

## Next Phase Readiness

Plan 06 is complete. UIF-02 remains flagged as unclassified until Plan 09 supplies matched rendered image/copy comparisons. This plan proves generated utility behavior and mounted stylesheet composition; it makes no claim of visual parity or aesthetic approval.

---
Phase: 185-executable-ui-quality-foundations
Completed: 2026-10-31

## Self-Check: PASSED

- All declared source artifacts exist.
- Every listed RED and implementation commit is an ancestor of the current plan head.
- Final Node, repository-contract, and mounted verification evidence is recorded above.

