---
phase: 111-advisory-proof-stability-decision
reviewed: 2026-06-01T00:25:43Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .github/workflows/ci.yml
  - examples/scrypath_ecommerce/playwright.config.ts
  - examples/scrypath_ecommerce/e2e/helpers/e2e.ts
  - scripts/ci/phase105_evidence.sh
  - test/mix/tasks/workflow_wiring_test.exs
  - CONTRIBUTING.md
  - test/scrypath/phase111_contract_test.exs
  - lib/mix/tasks/verify.phase99.ex
  - test/mix/tasks/verify.phase99_test.exs
findings:
  critical: 0
  warning: 4
  info: 0
  total: 4
status: issues_found
---

# Phase 111: Code Review Report

**Reviewed:** 2026-06-01T00:25:43Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed CI wiring, e2e helpers/evidence generation, and contract tests for trust-lane stability. No direct security criticals were found, but there are correctness and brittleness defects that can skew failure evidence and allow CI-policy drift to slip through.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: `infra_boot` Failure Class Is Unreachable

**File:** `scripts/ci/phase105_evidence.sh:83-91`  
**Issue:** `classifyFailure/2` checks `!hadSeed` before `events.length === 0`. For an empty event stream, `hadSeed` is always false, so the function returns `"fixture_seed"` and can never return `"infra_boot"`. This misclassifies infra boot failures and pollutes advisory stability evidence.
**Fix:**
```js
function classifyFailure(events, report) {
  if (events.length === 0) return "infra_boot";
  const evOps = new Set(events.map((ev) => ev.operation));
  // ...existing checks...
}
```

### WR-02: Min-Failed-Count Guard Skips Valid Zero Threshold

**File:** `examples/scrypath_ecommerce/e2e/helpers/e2e.ts:214`  
**Issue:** `if (args.minFailedSyncCount)` treats `0` as false and skips the polling/assertion path. This is a logic bug for boundary input and makes behavior depend on JS truthiness rather than explicit intent.
**Fix:**
```ts
if (args.minFailedSyncCount !== undefined) {
  // existing poll/assertion block
}
```

### WR-03: Workflow Wiring Test Is Too Loose and Can False-Pass

**File:** `test/mix/tasks/workflow_wiring_test.exs:10-12`  
**Issue:** The test `"ci.yml quality job runs mix verify"` only asserts that `"mix verify"` appears somewhere in `ci.yml`. It does not verify that `repo-hygiene` owns that command, so unrelated occurrences can satisfy the test while intended wiring regresses.
**Fix:** Parse/assert by job block (or use ordered block assertions) to tie the command to `repo-hygiene`, e.g. assert both `"\n  repo-hygiene:\n"` and its specific run line within the same sliced section.

### WR-04: Help-Output Assertion Is Version-Brittle

**File:** `test/mix/tasks/verify.phase99_test.exs:24`  
**Issue:** The test requires exact text `"There is no documentation for this task"`, which is not a stable behavioral contract and can change across Elixir/Mix versions, causing unnecessary CI breaks.
**Fix:** Assert stable markers only (task name and/or shortdoc), for example keep `assert output =~ "verify.phase99"` and replace the second assertion with a less version-coupled invariant.

---

_Reviewed: 2026-06-01T00:25:43Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
