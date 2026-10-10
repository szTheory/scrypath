---
phase: 174-recovery-entry-and-diagnosis
reviewed: 2026-10-07T21:31:10Z
depth: standard
files_reviewed: 34
files_reviewed_list:
  - examples/scrypath_ecommerce/compose.phase174.yaml
  - examples/scrypath_ecommerce/docker-playwright.sh
  - examples/scrypath_ecommerce/e2e/phase174_recovery.spec.ts
  - examples/scrypath_ecommerce/scripts/phase174-standalone-entrypoint.sh
  - examples/scrypath_ecommerce/scripts/verify-phase174.sh
  - scrypath_ops/assets/css/DESIGN-TOKENS.md
  - scrypath_ops/assets/css/app.css
  - scrypath_ops/assets/js/ops_hooks.js
  - scrypath_ops/config/test.exs
  - scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex
  - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
  - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
  - scrypath_ops/lib/scrypath_ops_web/dev_router.ex
  - scrypath_ops/lib/scrypath_ops_web/endpoint.ex
  - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex
  - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
  - scrypath_ops/lib/scrypath_ops_web/nav.ex
  - scrypath_ops/priv/static/assets/css/app.css
  - scrypath_ops/priv/static/assets/js/app.js
  - scrypath_ops/test/ops_palette_hook_browser.test.mjs
  - scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/phase174_fixture_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/recovery_journey_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
  - scrypath_ops/test/support/oban_job_fixture.ex
  - scrypath_ops/test/support/phase174_fixture_source.ex
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 174: Code Review Report

**Reviewed:** 2026-10-07T21:31:10Z  
**Depth:** standard  
**Files Reviewed:** 34  
**Status:** issues_found

## Summary

Reviewed the Phase 174 recovery navigation, failed-work identity and action handling, authorization return, async observation, palette lifecycle, test fixtures, browser harness, and generated assets. One collision edge breaks the promised accepted-retry status handoff, and the shared shell can retain a removed target after an allowlist change.

## Narrative Findings (AI reviewer)

### CR-01: Collision-safe retry identity is lost during status verification

**Severity:** BLOCKER

**File:** `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:690-693`  
**Issue:** `read_expected_effects/3` selects an original failure by numeric ID alone. The new failed-work UI distinguishes backend tasks from queue jobs with the same ID, while `Scrypath.Operator.FailedWork.list/3` returns backend rows before queue rows. After retrying a Queue job whose ID collides with a Backend task, verification therefore picks the Backend row, which has no manual recovery action, and reports the accepted replacement as unknown instead of checking its expected document effect.  
**Fix:** Store the original row's `source` in the accepted receipt, preserve it through `RecoveryObservation.failure_reference/1`, and match by both source and ID when loading expected effects. Add a regression covering the colliding Backend task/Queue job through the Check sync status handoff.

### WR-01: Shell navigation validates against a stale allowlist snapshot

**Severity:** WARNING

**File:** `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex:45-58`  
**Issue:** `recovery_target/3` prefers `assigns.schema_allowlist`, which is a mount-time snapshot on the production Control Room and the previous handle-params value on other views. If the configured allowlist changes while the LiveView remains connected, the hook can render the removed schema in the recovery-target label and palette/sidebar links even when the view's own `handle_params/3` has rejected it against the current allowlist. This leaves stale destinations in the shell and contradicts the current-allowlist target contract.  
**Fix:** Resolve shell targets against the current configured allowlist, with a narrowly scoped fixture override for the test-only Phase 174 routes. Refresh Control Room's `schema_allowlist` before resolving params and loading a refreshed summary.

---

_Reviewed: 2026-10-07T21:31:10Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
