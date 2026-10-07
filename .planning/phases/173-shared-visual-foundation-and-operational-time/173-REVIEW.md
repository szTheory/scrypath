---
phase: 173-shared-visual-foundation-and-operational-time
reviewed: 2026-10-07T01:42:00Z
depth: standard
source_head: 41e571a02f6bfa659911a43071e8eb195f40db34
product_last_changed: 3adccd9a888518dba44c23b83d5162c5fe29d70e
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

**Reviewed:** 2026-10-07T01:42:00Z  
**Depth:** standard  
**Files Reviewed:** 43  
**Status:** issues_found  
**Source:** `41e571a02f6bfa659911a43071e8eb195f40db34` (product changes last at `3adccd9a888518dba44c23b83d5162c5fe29d70e`)

## Summary

Reviewed all 43 files in the resolved Phase 173 source scope, including the corrected operator projection, per-schema timeout handling, exact time rendering, clipboard behavior, theme shell, fixture routes, and mounted/standalone seams. The original three findings and the interim retained-queue finding are corrected in current source. One remaining configuration-error path can crash while rendering the error row. The separately running full core/Ops suites and combined browser/hosted candidate checks are not treated as completed evidence here.

## Narrative Findings (AI reviewer)

### WR-03: Invalid runtime configuration crashes the error-row renderer

**Classification:** WARNING  
**File:** `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex:470-477,654`  
**Issue:** The per-schema error row calls `queue_mode/1` during rendering, and that helper calls `Scrypath.Config.resolve!`. A malformed runtime option (for example, an unsupported `sync_mode`) raises inside the schema task and is converted by `Task.async_stream` into an error row; rendering that row then resolves the same invalid configuration and raises again. The operator page therefore crashes instead of displaying the fetch/configuration error and retained observations.  
**Fix:** Avoid bang configuration resolution in the render path. Pass a safely determined mode into the row or inspect the raw configured mode with an explicit unknown fallback, rendering queue observation as unavailable when the mode cannot be resolved.

---

_Reviewed: 2026-10-07T01:42:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
