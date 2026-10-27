---
phase: 182-reliable-full-browser-verification-and-ci-caches
plan: "04"
subsystem: ci
tags: [github-actions, playwright, docker-compose, exunit, node-test, browser-evidence]

requires:
  - phase: 182-02
    provides: "Safe Playwright target selection and counted browser lifecycle/target contracts."
  - phase: 182-03
    provides: "Strict Playwright reconciliation and the source-bound evidence receipt writer."
provides:
  - "Fresh run-owned full-browser evidence bundles with same-selection inventory/results and failure-preserving collection."
  - "A scheduled/manual 30-minute advisory hosted lane exposing raw verifier and artifact outputs while preserving the five required jobs."
  - "Contributor guidance for the focused/full boundary, artifact ownership, timing reserve, and evidence limits."
affects: [182-05, 182-08, ecommerce-e2e-verification]

actuals:
  tokens: 17187.5
  tasks: 2
  commits: 4
  plan_head_before: 95cfbc70c2ca4677d48403e3627105de0d4fd4be
  plan_head_after: dbdf04fb44a7fd7482e909f5203d0859ea80cd2a

tech-stack:
  added: []
  patterns:
    - "Each hosted verification invocation uses a fresh run-id directory and uploads only that directory."
    - "The advisory job exposes raw step outcome separately from job conclusion and retains artifact identity outputs."
    - "Full-job timing begins before checkout and tool setup, with a provisional reserve for finalization and upload."

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - CONTRIBUTING.md
    - examples/scrypath_ecommerce/compose.e2e.yaml
    - examples/scrypath_ecommerce/docker-playwright.sh
    - examples/scrypath_ecommerce/playwright.config.ts
    - examples/scrypath_ecommerce/scripts/verify-e2e.sh
    - scripts/ci/ecommerce_lifecycle.test.cjs
    - test/mix/tasks/workflow_wiring_test.exs

key-decisions:
  - "Keep full ecommerce-e2e scheduled/manual and advisory; keep exactly the five established required jobs."
  - "Expose the raw verifier outcome and immutable artifact ID, URL, and digest independently of the advisory job conclusion."
  - "Use a 300-second initial finalization/upload reserve, explicitly provisional until Phase 182-08 measures hosted maxima plus at least 60 seconds."
  - "Leave BROW-01, BROW-02, and BROW-03 incomplete until their required real browser and hosted exact-SHA evidence exists."

requirements-completed: []

coverage:
  - id: D1
    description: "The full verifier owns one fresh evidence bundle and preserves failure state through report copying and cleanup."
    requirement: BROW-01
    verification:
      - kind: integration
        ref: "node --test scripts/ci/ecommerce_lifecycle.test.cjs scripts/ci/ecommerce_evidence.test.cjs scripts/ci/ecommerce_target.test.cjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "The hosted workflow preserves source/run identity, raw verifier outcome, and current-run artifact outputs while keeping the required mounted lane separate."
    verification:
      - kind: unit
        ref: "test/mix/tasks/workflow_wiring_test.exs#ecommerce-e2e preserves raw outcome and uploads only this run's evidence"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/workflow_wiring_test.exs#mounted E2E failure upload is scoped to the current invocation"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix verify.repository_contracts"
        status: pass
    human_judgment: true
    rationale: "Static contracts pass, but this plan did not run the hosted Actions job; its real artifact identity, failure outputs, and finalization/upload timing remain reserved for the exact-SHA acceptance in plan 182-08."

duration: 30min
completed: 2026-10-26
status: complete
---

# Phase 182 Plan 04: Full Browser Evidence and Hosted CI Summary

**Fresh full-browser evidence bundles now feed a 30-minute advisory Actions lane with independent raw outcomes and current-run artifact identity.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-10-27T00:17:59Z
- **Completed:** 2026-10-27T00:48:05Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Full verification now records same-selection Playwright inventory and results in a fresh run directory. It copies only the container's allowlisted outputs, writes stage/lifecycle/source metadata, and rejects missing reports, failed copies, and timeouts without masking the original failure.
- The hosted full lane starts its clock before checkout and toolchain setup, verifies the checkout against `GITHUB_SHA`, uses a 30-minute total job timeout, and keeps a provisional five-minute finalization/upload reserve. It exposes the raw verifier outcome and artifact ID, URL, and digest separately from the advisory job conclusion.
- The required mounted lane still uses its focused proof and now scopes failure uploads to the current run. Contracts confirm the five established required jobs remain exactly the same.
- Updated contributor guidance distinguishes mounted and full runs, explains per-run artifact paths and timing, and states that diagnostics, width/contrast checks, and synthetic tests are not full visual or hosted acceptance.

## Verification

- `node --test scripts/ci/ecommerce_lifecycle.test.cjs scripts/ci/ecommerce_evidence.test.cjs scripts/ci/ecommerce_target.test.cjs` — 38 tests passed; zero failures, skips, or todos.
- `HEX_HOME=/private/tmp/scrypath-phase182-hex MIX_HOME=/private/tmp/scrypath-phase182-mix MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_capability_test.exs test/scrypath/phase108_contract_test.exs test/scrypath/phase111_contract_test.exs` — compilation passed; 69 tests passed.
- `HEX_HOME=/private/tmp/scrypath-phase182-hex MIX_HOME=/private/tmp/scrypath-phase182-mix MIX_ENV=test mix verify.repository_contracts` — 93 tests passed; the repository contract includes the counted lifecycle, evidence, and target Node suites.
- `HEX_HOME=/private/tmp/scrypath-phase182-hex MIX_HOME=/private/tmp/scrypath-phase182-mix MIX_ENV=test mix format --check-formatted test/mix/tasks/workflow_wiring_test.exs` — passed.
- `git diff --check` — passed.
- Task 1 RED evidence classified `RED_EVIDENCE_OK`; the target failed because the old browser runner did not produce the required same-selection inventory. Task 2 RED evidence classified `RED_EVIDENCE_OK`; the targeted ExUnit contract executed and failed on the expected `timeout-minutes: 30` assertion while the workflow still specified 20 minutes. The task 2 record is at `examples/scrypath_ecommerce/test-results/.tdd-red-evidence-182-04-02.json` (ignored generated evidence; not force-staged).
- No real full-browser run or hosted exact-SHA acceptance was performed by this plan. Plan 182-08 must provide that evidence before the related requirements can be completed.

## Task Commits

1. **Task 1 RED:** `edbb1a64` — `test(182-04): require owned full browser evidence`
2. **Task 1 GREEN:** `4fdade75` — `feat(182-04): collect owned full browser evidence`
3. **Task 2 RED:** `d08698b7` — `test(182-04): cover hosted full E2E artifact contract`
4. **Task 2 GREEN:** `dbdf04fb` — `feat(182-04): expose bounded hosted browser evidence`

Plan metadata is committed separately after this summary's self-check.

## Files Modified

- `.github/workflows/ci.yml` — starts the hosted deadline before setup, validates exact source, exports raw/outcome and artifact outputs, and scopes both full and mounted uploads to the current run.
- `CONTRIBUTING.md` — documents run scope, exact-run evidence, the provisional reserve, and limits of diagnostics and synthetic evidence.
- `examples/scrypath_ecommerce/compose.e2e.yaml` — removes judge credentials from the ordinary proof path.
- `examples/scrypath_ecommerce/docker-playwright.sh` — produces one serial full inventory/result run without activating the paid judge.
- `examples/scrypath_ecommerce/playwright.config.ts` — directs structured reports into the owned run bundle.
- `examples/scrypath_ecommerce/scripts/verify-e2e.sh` — manages per-run collection, stage status, deadlines, artifact copy, and cleanup.
- `scripts/ci/ecommerce_lifecycle.test.cjs` — covers same-selection inventory, fresh ownership, timeout, copy, failure preservation, and cleanup behavior.
- `test/mix/tasks/workflow_wiring_test.exs` — asserts the workflow boundary and runs counted lifecycle, evidence, and target behavior suites.

## Decisions Made

- Kept the scheduled/manual full lane advisory and preserved the five required job names and roles.
- Treated raw `ecommerce_verify` outcome as the browser verdict; the advisory job conclusion is not sufficient evidence of a passing run.
- Left the 300-second finalization/upload reserve provisional pending the hosted timing measurement in Phase 182 plan 08.
- Kept `requirements-completed` empty. The passing tests validate the harness and workflow contract, not real browser execution or hosted exact-SHA acceptance.

## TDD Gate Compliance

- **Task 1 RED:** The named lifecycle test failed on the missing Playwright JSON inventory command; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`. **GREEN:** `4fdade75` implemented owned collection and the lifecycle suite passed.
- **Task 2 RED:** The TAP target wrapped the named ExUnit workflow contract; the ExUnit test executed and failed specifically because the job timeout was still 20 minutes instead of 30. The evidence classifier returned `RED_EVIDENCE_OK`. **GREEN:** `dbdf04fb` implemented the current-run workflow contract, docs, and supporting assertions; the required verification passed.

## Deviations from Plan

Post-merge root verification found that the historical Phase 147 contract also
requires the literal advisory-posture sentence in CONTRIBUTING. Restored that
wording while preserving the scheduled/manual trigger and new evidence runbook.

## Issues Encountered

- The worktree had no local `deps` directory. `mix deps.get` populated only existing locked dependencies using disposable `HEX_HOME` and `MIX_HOME` under `/private/tmp`; no dependency or lockfile changed.
- The first task 2 RED attempt used unsupported `mix test --name` and then encountered missing dependencies. Both were corrected before collecting the valid TAP evidence with the supported `--name-pattern` option; invalid attempts did not authorize GREEN.
- Git initially could not write the linked worktree index inside the sandbox. Staging and commits were retried through the authorized approval mechanism, and normal commit hooks ran.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 182-05 can proceed. The owned browser collection and hosted wiring are ready for integration. BROW-01/BROW-02/BROW-03 remain incomplete until the later plan produces real full-browser and hosted exact-SHA evidence and confirms the finalization/upload margin. No hosted acceptance is claimed here.

## Self-Check: PASSED

- Summary and all eight task files exist.
- All four task commits are ancestors of this branch; the plan-scoped resolver found the four commits.
- `.planning/STATE.md` and `.planning/ROADMAP.md` are unchanged.

---
*Phase: 182-reliable-full-browser-verification-and-ci-caches*
*Completed: 2026-10-26*
