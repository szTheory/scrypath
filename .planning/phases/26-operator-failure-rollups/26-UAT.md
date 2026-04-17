---
status: complete
phase: 26-operator-failure-rollups
source:
  - 26-01-SUMMARY.md
  - 26-02-SUMMARY.md
automation: mix verify.phase26
started: "2026-04-17T00:00:00Z"
updated: "2026-04-17T12:00:00Z"
---

## Current Test

[testing complete — automated gate]

## Tests

Phase 26 acceptance is enforced in CI and locally by **`mix verify.phase26`**: the focused modules from `26-VERIFICATION.md` (including **`docs_contract_test.exs`**, which asserts CI and operator docs stay aligned), then **`mix docs --warnings-as-errors`**. No manual conversational UAT; the prior four checkpoints map to those tests.

### 1. Opt-in failed sync work rollups
expected: |
  Opt-in API returns list plus dense reason_class counts; default path unchanged.
result: pass
automation: test/scrypath/operator/failed_work_test.exs

### 2. Mix scrypath.failed human output
expected: |
  Human-readable rows, optional class summary, `--no-class-summary` behavior.
result: pass
automation: test/scrypath/mix_tasks/operator_tasks_test.exs

### 3. Mix scrypath.failed JSON
expected: |
  `--json` emits a single JSON object for scripts.
result: pass
automation: test/scrypath/mix_tasks/operator_tasks_test.exs

### 4. Reconcile report rollups
expected: |
  Reconcile attaches `failed_work_counts` consistent with the shared aggregator.
result: pass
automation: test/scrypath/operator/reconcile_test.exs

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0

## Gaps

(none)
