---
phase: 182-reliable-full-browser-verification-and-ci-caches
plan: "03"
subsystem: testing
tags: [playwright, node-test, browser-evidence, sha256, docker-compose]

requires:
  - phase: 182-01
    provides: "Full-scope Compose readiness and lifecycle evidence with failure-preserving cleanup."
provides:
  - "Strict, order-independent reconciliation of Playwright inventory and execution attempts by file, project, title path, and entrypoint."
  - "A source-bound phase105-evidence.json authority with a Markdown projection and explicit-run-directory CLI."
affects: [182-04, 182-08, ecommerce-e2e-verification]

actuals:
  tokens: 20559.5
  tasks: 2
  commits: 4
plan_head_before: 1eec7e22acf5551eab6e3b4e12e5024df043c238
plan_head_after: 8e6ce4570c496f163780da3826ba7fcb04e12822

tech-stack:
  added: []
  patterns:
    - "Composite Playwright case identity is reconciled as a set, with every retry attempt checked."
    - "One bounded JSON receipt decides evidence eligibility; legacy Markdown is rendered from that receipt."
    - "Run-owned artifacts are allowlisted, size-bounded, hashed, and rejected when paths escape or traverse symlinks."

key-files:
  created:
    - scripts/ci/ecommerce_evidence.cjs
    - scripts/ci/ecommerce_evidence.test.cjs
  modified:
    - scripts/ci/phase105_evidence.sh
    - test/mix/tasks/workflow_wiring_test.exs

key-decisions:
  - "Keep the receipt JSON as the only eligibility authority and derive the legacy summary from it."
  - "Treat the paid visual judge as optional and outside browser eligibility."
  - "Leave BROW-02 and BROW-03 pending until the later plans produce the required actual browser and hosted exact-SHA evidence."

requirements-completed: []

coverage:
  - id: D1
    description: "Playwright inventory and result attempts reconcile deterministically by composite identity, rejecting duplicates, missing cases, skips, retries, and masked expected failures."
    verification:
      - kind: unit
        ref: "scripts/ci/ecommerce_evidence.test.cjs#report ordering does not change set equality or attempts"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_evidence.test.cjs#missing attempts, skips, retry passes, and expected-failure masking reject clean proof"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_evidence.test.cjs#malformed and zero-case CLI reports exit nonzero"
        status: pass
    human_judgment: false
  - id: D2
    description: "A bounded receipt validates source, images, raw statuses, checker outputs, cleanup, artifacts, and summary consistency; the legacy wrapper delegates without requiring a visual judge."
    verification:
      - kind: unit
        ref: "scripts/ci/ecommerce_evidence.test.cjs#one aggregate binds exact source, reports, checkers, artifacts and derived summary"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_evidence.test.cjs#forged SHA or image identity rejects even when the advisory job says success"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_evidence.test.cjs#failed artifact copies, raw verifier errors, and unclean cleanup block eligibility"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_evidence.test.cjs#artifact path traversal and symlink escapes are rejected"
        status: pass
      - kind: integration
        ref: "scripts/ci/ecommerce_evidence.test.cjs#legacy shell entrypoint delegates to the same writer with an explicit run directory"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-10-26
status: complete
---

# Phase 182 Plan 03: Reliable Full Browser Evidence Summary

**Strict Playwright reconciliation and a source-bound JSON receipt now govern Phase 105 evidence eligibility and its legacy summary output.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-10-26T23:58:02Z
- **Completed:** 2026-10-27T00:12:51Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added a dependency-free Node reconciler that compares complete Playwright identities rather than counts or report order. It preserves distinct files, projects, title paths, and mounted/standalone entrypoints, and rejects duplicate, missing, skipped, retried, failed, and expected-failure-masked cases.
- Added one bounded evidence receipt that checks source SHA or dirty fingerprint, built/runtime image identity, Compose scope and targets, browser/package metadata, workflow provenance, raw stage statuses, checker results, cleanup, event records, and hashed artifacts. The Markdown output is a projection of the receipt, and a validator detects receipt or summary drift.
- Replaced the tolerant shell writer with an executable delegate requiring an explicit `--run-dir`. It preserves the legacy evidence filenames and summary fields while treating the paid visual judge as not required.
- Updated the existing workflow wiring contract to inspect the new delegate and the authoritative writer, removing its stale dependency on the judge output file.

## Task Commits

1. **Task 1: Reconcile Playwright inventory and attempts**
   - RED: `7ddcda79` — `test(182-03): add strict browser inventory reconciliation tests`
   - GREEN: `f6adbfd2` — `feat(182-03): reconcile Playwright cases by composite identity`
2. **Task 2: Replace tolerant evidence generation with one aggregate**
   - RED: `b70c0e80` — `test(182-03): cover authoritative evidence receipts`
   - GREEN: `8e6ce457` — `feat(182-03): implement authoritative browser evidence receipt`

Plan metadata is recorded in the summary commit.

## Verification

- <code>node --test scripts/ci/ecommerce_evidence.test.cjs</code> — 17 tests passed; zero failures, skips, or todos.
- <code>HEX_HOME=/private/tmp/scrypath-phase182-hex MIX_HOME=/private/tmp/scrypath-phase182-mix MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs</code> — compilation succeeded; 51 tests passed.
- <code>HEX_HOME=/private/tmp/scrypath-phase182-hex MIX_HOME=/private/tmp/scrypath-phase182-mix MIX_ENV=test mix format --check-formatted test/mix/tasks/workflow_wiring_test.exs</code> — passed.
- <code>bash -n scripts/ci/phase105_evidence.sh</code> — passed.
- <code>git diff --check</code> — passed.
- <code>gsd_run check evaluation-scope --plan 182-03 --commits-only --raw</code> — resolved the four task commits on this branch.

Task-level RED evidence was captured before implementation:
- Task 1: the named single-case reconciliation test exited 1 on its planned `eligible === true` assertion because the reconciler was not yet implemented; its fixture setup and target test executed.
- Task 2: the named aggregate test exited 1 on its planned receipt-eligibility assertion because the writer did not yet exist; its fixture setup and target test executed.
Both runs had one executed target test and no setup, import, collection, or syntax failure. The temporary evidence records were removed after recording these results.

## Decisions Made

- Used the JSON receipt as the sole eligibility authority and made the human-readable summary reproducible from that exact object.
- Kept judge status visible as `not-required` and removed any requirement for the dormant judge artifact.
- Left `requirements-completed` empty. These synthetic tests establish the evidence machinery, not BROW-02 execution against Docker's `web:4002` or BROW-03 hosted full-suite acceptance at the changed SHA.

## Deviations from Plan

None — the workflow wiring test update was required by the plan's instruction to reconcile existing consumers before replacing the writer.

## Issues Encountered

The default Mix command could not write Hex's global cache in the sandbox. Existing locked dependencies were fetched into temporary `HEX_HOME` and `MIX_HOME` directories, after which the required compile and ExUnit verification passed. No dependency or lockfile change was made.

## User Setup Required

None.

## Next Phase Readiness

The reconciler, receipt schema, validator, and delegate are ready for subsequent Phase 182 integration. This plan does not claim real browser execution, hosted exact-SHA acceptance, or completion of BROW-02/BROW-03; those remain pending for later plans.

## Self-Check: PASSED

- Both newly created files and both modified files exist.
- All four task commits are ancestors of the worktree HEAD, and the plan-scoped commit resolver found all four.
- `.planning/STATE.md` and `.planning/ROADMAP.md` remain unchanged.

---
*Phase: 182-reliable-full-browser-verification-and-ci-caches*
*Completed: 2026-10-26*

