---
phase: 175-repair-and-verification
reviewed: 2026-10-11T13:25:44Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - examples/scrypath_ecommerce/e2e/operator.spec.ts
  - scrypath_ops/assets/css/app.css
  - scrypath_ops/assets/js/ops_hooks.js
  - scrypath_ops/lib/scrypath_ops/document_observation.ex
  - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
  - scrypath_ops/priv/static/assets/css/app.css
  - scrypath_ops/priv/static/assets/js/app.js
  - scrypath_ops/test/scrypath_ops/document_observation_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 175: Code Review Report

**Reviewed:** 2026-10-11T13:25:44Z  
**Depth:** standard  
**Files Reviewed:** 9  
**Status:** issues_found

## Summary

Reviewed the phase-owned recovery observation, promotion verification, modal focus, responsive styling, generated assets, and mounted regression coverage against the phase plans and summaries. Two robustness defects remain in document observation: promotion can hold the LiveView process while it performs a sequence of backend requests, and a task payload without a UID can still be accepted as the exact completed task.

## Warnings

### WR-01: [WARNING] Promotion document reads can block the LiveView process

**File:** `scrypath_ops/lib/scrypath_ops/document_observation.ex:38`
**Issue:** `check_effects/4` performs document reads synchronously through `Enum.reduce_while/3` and has no overall deadline. It is called from `observe_promotion_effects/1` while handling the swap observer result. The expected list may contain 50 documents, and each request can wait up to the configured receive timeout, so a slow or unreachable backend can leave the LiveView process unable to handle events or render updates for minutes.
**Fix:** Run the effect check in a bounded async task with a single overall deadline, then apply its result only if the promotion generation and task UID still match. Preserve the existing unknown/unavailable outcome on timeout.

### WR-02: [WARNING] Missing task UID can pass exact-task verification

**File:** `scrypath_ops/lib/scrypath_ops/document_observation.ex:296`
**Issue:** `task_status/2` rejects a UID only when one is present and mismatched. A map such as `%{"status" => "succeeded"}` therefore passes identity validation; if the expected documents match, `check/3` returns `:verified` even though it cannot establish that the payload represents the receipt's `task_uid`. The LiveView currently validates the UID before calling this function, but the observer's own boundary permits false verification for malformed payloads or other callers.
**Fix:** Require a recognized task UID and compare it to the receipt UID before accepting any status. Return `:unknown` with `:invalid_task_payload` or `:task_uid_mismatch` when the UID is absent or differs.

---

_Reviewed: 2026-10-11T13:25:44Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
