---
phase: 185-executable-ui-quality-foundations
plan: "04"
subsystem: browser-evidence
status: complete
requires: [185-01]
provides:
  - Retired paid/mock judge execution
  - Fresh receipts without retired reviewer fields
  - Read-only legacy receipt compatibility
key-files:
  created:
    - .planning/phases/185-executable-ui-quality-foundations/185-04-01-RED.json
    - .planning/phases/185-executable-ui-quality-foundations/185-04-02-RED.json
  modified:
    - scripts/ci/ecommerce_evidence.cjs
    - scripts/ci/ecommerce_evidence.test.cjs
    - test/mix/tasks/workflow_wiring_test.exs
requirements-completed: []
---

# Phase 185 Plan 04 — Paid/mock judge retirement

Removed the judge module, npm entrypoint, Makefile selector/matrix-only branch and judge-dependent exit condition. Deterministic shell/wash commands and their failure conditions remain. The dedicated rubric and active retired-command guidance are removed. Current documentation describes deterministic proof limits and deferred calibrated review.

Fresh evidence and summaries omit retired judge fields and sections. The reader accepts only the exact previously valid legacy retired-field shape, retaining the old derived summary format for that shape; it validates all deterministic contents against run-owned artifacts and never rewrites stored bytes. Synthetic approval and unknown data still fail aggregate equality. This compatibility path generates no fresh reviewer result.

## Execution and evidence

- Entrypoint RED/GREEN: `4e98c4cf` / `aa0edf6e`.
- Evidence-shape RED/GREEN: `a59bd108` / `308d691d`.
- Guidance/retired rubric: `c5f15a9e`.
- Both checked-in RED records returned `RED_EVIDENCE_OK`, followed by semantic assertion inspection. An initial interruption fixture attempted a forbidden output rewrite; it was corrected to use a fresh third run before its RED record was accepted.
- Focused workflow wiring checks passed after executable removal and writer changes.
- `node --test scripts/ci/ecommerce_evidence.test.cjs scripts/ci/ecommerce_target.test.cjs` passed. Log: `/private/tmp/phase185-04-evidence.log`.
- The Node suite covers fresh output, prior valid legacy shape without byte changes, rejection of forged legacy status, distinct invocation identities, borrowed receipt rejection, refusal to rewrite existing output, interrupted collection/missing required artifact, synthetic reviewer metadata, and existing deterministic checks.
- Final `mix verify.repository_contracts` passed after all source/doc changes. Log: `/private/tmp/phase185-04-canonical.log`.
- `MIX_ENV=test mix docs --warnings-as-errors` passed. Log: `/private/tmp/phase185-04-docs.log`.
- `node --check`, `git diff --check`, and the active executable/runbook reference audit passed. Remaining retired field names are confined to legacy compatibility and tests of retirement.

## Limits and deviations

No archived receipt or historical phase was edited. Compatibility fixtures establish the previously valid fixed legacy shape, not every historical or externally supplied schema. No real Docker/browser acceptance or visual review is claimed by these tests. The target helper needed no source change; its existing tests passed. The retained preview and its data remain untouched. No package acquisition, paid call, key change, design approval, merge or release occurred. UIF-06 is only partially delivered here; later preservation and closeout work remains required.

## Self-Check: PASSED

The created RED artifacts exist, plan-scoped commits are reachable on this branch, and the required canonical command passed after the last application/doc source changes. Plan 02 remains incomplete in Wave 2; no wave or phase completion is claimed.
