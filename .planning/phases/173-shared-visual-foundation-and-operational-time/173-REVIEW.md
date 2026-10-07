---
phase: 173-shared-visual-foundation-and-operational-time
reviewed: 2026-10-07T01:35:36Z
depth: standard
source_head: 940fc3d33f43c449ea837e1ac1ebd6382216e8b8
product_last_changed: da8df9cf5d275614b69f3df6d9e85349bbd27150
scope_status: resolved
files_reviewed: 43
files_reviewed_list:
  - examples/scrypath_ecommerce/assets/js/app.js
  - examples/scrypath_ecommerce/compose.phase173.yaml
  - examples/scrypath_ecommerce/config/test.exs
  - examples/scrypath_ecommerce/docker-playwright.sh
  - examples/scrypath_ecommerce/e2e/harness.spec.ts
  - examples/scrypath_ecommerce/e2e/operator.spec.ts
  - examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts
  - examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts
  - examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts
  - examples/scrypath_ecommerce/e2e/phase173_time.spec.ts
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/endpoint.ex
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex
  - examples/scrypath_ecommerce/scripts/phase173-standalone-entrypoint.sh
  - examples/scrypath_ecommerce/scripts/verify-phase173.sh
  - examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex
  - lib/scrypath/operator.ex
  - lib/scrypath/operator/state.ex
  - lib/scrypath/operator/status.ex
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
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 173: Code Review Report

**Reviewed:** 2026-10-07T01:35:36Z  
**Depth:** standard  
**Files Reviewed:** 43  
**Status:** issues_found  
**Source:** `940fc3d33f43c449ea837e1ac1ebd6382216e8b8` (product changes last at `da8df9cf5d275614b69f3df6d9e85349bbd27150`)

## Summary

Reviewed all 43 files in the resolved Phase 173 source scope, including the corrected operator projection, per-schema timeout handling, exact time rendering, clipboard behavior, theme shell, fixture routes, and mounted/standalone seams. The three findings from the earlier report are corrected in current source. One remaining display gap hides retained queue evidence when a whole schema scan errors or times out. The separately running combined browser and hosted candidate checks are not treated as completed evidence here.

## Narrative Findings (AI reviewer)

### WR-01: Whole-schema errors hide retained queue evidence

**Classification:** WARNING  
**File:** `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex:448-477`  
**Issue:** When `Task.async_stream/3` times out for a schema, or both source inspections fail, `ScrypathOps.Posture` records an error row while retaining the previous references for both `:backend` and `:queue`. The error-row rendering handles only the retained backend reference and omits the queue section entirely. In Oban mode, operators therefore cannot see the last successful queue observation or its snapshot age during a whole-schema outage, even though that evidence remains available in `last_success_refs`.  
**Fix:** Render unavailable signals for both sources in the error-row branch, using the retained queue reference and the queue-unavailable reason. Keep the explicit “Queue not used” treatment for inline/manual modes.

---

_Reviewed: 2026-10-07T01:35:36Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
