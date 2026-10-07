---
phase: 173-shared-visual-foundation-and-operational-time
reviewed: 2026-10-07T01:19:41Z
depth: standard
files_reviewed: 39
files_reviewed_list:
  - examples/scrypath_ecommerce/assets/js/app.js
  - examples/scrypath_ecommerce/compose.phase173.yaml
  - examples/scrypath_ecommerce/config/test.exs
  - examples/scrypath_ecommerce/docker-playwright.sh
  - examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts
  - examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts
  - examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts
  - examples/scrypath_ecommerce/e2e/phase173_time.spec.ts
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/endpoint.ex
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex
  - examples/scrypath_ecommerce/scripts/phase173-standalone-entrypoint.sh
  - examples/scrypath_ecommerce/scripts/verify-phase173.sh
  - examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex
  - lib/scrypath/operator/state.ex
  - scrypath_ops/assets/css/DESIGN-TOKENS.md
  - scrypath_ops/assets/css/app.css
  - scrypath_ops/assets/css/contrast-pairs.mjs
  - scrypath_ops/assets/js/app.js
  - scrypath_ops/assets/js/ops_hooks.js
  - scrypath_ops/config/test.exs
  - scrypath_ops/lib/scrypath_ops/posture.ex
  - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
  - scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex
  - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
  - scrypath_ops/lib/scrypath_ops_web/dev_router.ex
  - scrypath_ops/lib/scrypath_ops_web/endpoint.ex
  - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
  - scrypath_ops/priv/static/assets/css/app.css
  - scrypath_ops/priv/static/assets/js/app.js
  - scrypath_ops/test/scrypath_ops_web/components/ops_ui_test.exs
  - scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/shell_chrome_token_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs
  - scrypath_ops/test/support/phase173_fixture_source.ex
  - scrypath_ops/test/support/tap_formatter.ex
  - scrypath_ops/test/test_helper.exs
  - test/scrypath/operator/status_test.exs
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 173: Code Review Report

**Reviewed:** 2026-10-07T01:19:41Z  
**Depth:** standard  
**Files Reviewed:** 39  
**Status:** issues_found

## Summary

Reviewed the 39 source paths in the resolved Phase 173 scope. The timestamp provenance and guarded theme preference paths preserve the intended source values and in-memory fallback. Three correctness gaps remain around distinguishing a successful empty queue observation from unavailable data and retaining per-schema evidence when independent sources or timed-out scans fail.

## Critical Issues

### CR-01: Empty Oban history is reported as unavailable

**Classification:** BLOCKER  
**File:** `lib/scrypath/operator/status.ex:108-115`  
**Reproduction:** In `:oban` mode, let the inspector return `{:ok, []}`. This is a successful observation with zero jobs, but `observed?` becomes false because it is derived from `states != []`. The Search health row then says “Queue observations unavailable” and suppresses the queue metrics, even though the queue was observed and is empty. The UI consequently conflates zero work with a failed observation.  
**Fix:** Preserve fetch success separately from the returned list. Set `observed?: true` for every successful Oban inspection, including an empty list; reserve `false` for modes where the queue is not used, and represent inspection errors as errors.

## Warnings

### WR-01: Queue inspection failure marks the successful backend observation unavailable

**Classification:** WARNING  
**File:** `lib/scrypath/operator/status.ex:55-65`  
**Reproduction:** In Oban mode, make `backend_states/3` succeed and `queue_states/3` return an error. The `with` returns only the queue error, discarding the successful backend states. `Posture.last_success_refs/3` then treats the schema as one failed row and retains both source references; the LiveView labels the backend observation unavailable and hides the current backend counts, despite having just fetched them successfully. This breaks the source-local retention and partial-observation contract.  
**Fix:** Preserve backend and queue outcomes independently through the posture projection. Keep the successful source's current data/reference while marking only the failing source unavailable with its reason; avoid changing the public API contract if the separation can be implemented in the operator presentation seam.

### WR-02: Timed-out schema scans lose the schema key needed to retain its last success

**Classification:** WARNING  
**File:** `scrypath_ops/lib/scrypath_ops/posture.ex:184-196`  
**Reproduction:** After a successful scan, make one schema's `Scrypath.sync_status/2` exceed the 15-second stream timeout. `Task.async_stream/3` emits `{:exit, reason}` without the input module, and the mapper records the error under the shared `:posture_stream` key. `last_success_refs/3` therefore cannot find that schema's prior references, and the LiveView's error row has no retained timestamp to display. Multiple timeouts also collapse to duplicate `:posture_stream` rows.  
**Fix:** Carry schema identity through the timeout/error path so each failed schema has its own row and the previous backend/queue references can be retained and displayed. Add a focused regression for one timed-out schema among successful schemas.

---

_Reviewed: 2026-10-07T01:19:41Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
