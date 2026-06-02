---
phase: 111-advisory-proof-stability-decision
plan: "01"
subsystem: testing
tags: [github-actions, playwright, ci, advisory-evidence, stability]
requires:
  - phase: 109-release-train-and-package-truth-audit
    provides: Lean required-gate posture and workflow wiring contract patterns
  - phase: 110-support-intake-and-evidence-routing
    provides: Evidence routing discipline and bounded artifacts posture
provides:
  - Advisory `phase105-e2e` run evidence manifest and markdown summary generation
  - Structured Playwright JSON output for retry-derived flake signal detection
  - Stage-level E2E helper evidence events with bounded payloads
  - Workflow wiring assertions that lock the advisory evidence contract
affects: [STAB-01, STAB-02, phase105-e2e, CI]
tech-stack:
  added: []
  patterns: [always-run evidence summarization, bounded advisory artifacts, retry-pass flake surfacing]
key-files:
  created:
    - scripts/ci/phase105_evidence.sh
  modified:
    - .github/workflows/ci.yml
    - examples/scrypath_ecommerce/playwright.config.ts
    - examples/scrypath_ecommerce/e2e/helpers/e2e.ts
    - test/mix/tasks/workflow_wiring_test.exs
key-decisions:
  - "Kept `phase105-e2e` advisory and added promotion-grade evidence collection without changing required-gate topology."
  - "Treat retry-pass as explicit `flaky_signal` via structured Playwright JSON, not as a silent clean pass."
patterns-established:
  - "Advisory E2E lanes must emit run metadata + runtime + flake + failure classification in machine-readable form."
  - "Failure uploads remain bounded to the triage bundle rather than broad dumps."
requirements-completed: [STAB-01]
duration: 20min
completed: 2026-06-01
---

# Phase 111 Plan 01: Advisory Proof Stability Decision Summary

**Hardened `phase105-e2e` as an advisory evidence lane by adding structured run manifests, stage events, and bounded failure triage artifacts for promotion-readiness review.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-06-01T00:20:00Z
- **Completed:** 2026-06-01T00:40:00Z
- **Tasks:** 1
- **Files modified:** 6

## Accomplishments

- Extended `phase105-e2e` workflow wiring with `PHASE105_EVIDENCE_PATH`, start/end capture, always-run evidence generation, and step-summary append.
- Added CI Playwright JSON reporter output at `examples/scrypath_ecommerce/test-results/phase105-playwright.json` while preserving retry/worker/trace semantics.
- Added bounded NDJSON evidence emission in E2E helpers for `seed`, `drain`, `search_visible`, `rename_category`, `inject_failed_sync`, `operator_state`, and `swap_outcome`.
- Added `scripts/ci/phase105_evidence.sh` that writes `phase105-evidence.json` + `phase105-evidence-summary.md`, computes runtime, surfaces retry-pass flake signal, and classifies failures into explicit buckets.
- Updated workflow wiring tests to lock evidence env var, always-run summary step, structured report path, and bounded artifact policy.

## Task Commits

1. **Task 1: Add promotion-grade advisory evidence capture to `phase105-e2e`** - committed atomically in this plan execution.

## Files Created/Modified

- `scripts/ci/phase105_evidence.sh` - Generates machine-readable evidence manifest and markdown summary from workflow metadata, Playwright JSON, and NDJSON events.
- `.github/workflows/ci.yml` - Wires evidence env/start-end capture, always-run summary generation, and bounded artifact uploads for advisory failures.
- `examples/scrypath_ecommerce/playwright.config.ts` - Adds structured JSON reporter output for flake/evidence extraction.
- `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` - Emits bounded operation-level NDJSON evidence events.
- `test/mix/tasks/workflow_wiring_test.exs` - Adds deterministic assertions for STAB-01 advisory evidence wiring.

## Decisions Made

- Keep required gates unchanged and preserve advisory posture while collecting promotion-grade stability evidence.
- Encode failure classification and flake visibility in generated artifacts so maintainers can triage without immediate rerun.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `phase105-e2e` now emits stable evidence artifacts suitable for future advisory/required decision scoring.
- Phase 111 Plan 02 can consume this evidence contract for thresholding and decision-surface finalization.

## Self-Check: PASSED

- Summary file created at `.planning/phases/111-advisory-proof-stability-decision/111-01-SUMMARY.md`.
- Verification command passed: `mix test test/mix/tasks/workflow_wiring_test.exs`.
