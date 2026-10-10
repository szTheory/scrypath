---
phase: 175-repair-and-verification
reviewed: 2026-10-10T16:51:36Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - examples/scrypath_ecommerce/compose.phase175.yaml
  - examples/scrypath_ecommerce/docker-playwright.sh
  - examples/scrypath_ecommerce/e2e/helpers/e2e.ts
  - examples/scrypath_ecommerce/e2e/phase175_repair.spec.ts
  - examples/scrypath_ecommerce/e2e/phase175_ui_matrix.spec.ts
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce/e2e_recovery.ex
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex
  - examples/scrypath_ecommerce/scripts/verify-phase175.sh
  - scrypath_ops/docs/operator-ia.md
  - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
  - scrypath_ops/lib/scrypath_ops_web/dev_router.ex
  - scrypath_ops/lib/scrypath_ops_web/endpoint.ex
  - scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex
  - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
  - scrypath_ops/test/scrypath_ops/document_observation_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/phase175_fixture_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
  - scrypath_ops/test/support/phase175_browser_fixture.ex
  - scrypath_ops/test/support/phase175_fixture_source.ex
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 175: Code Review Report

**Reviewed:** 2026-10-10T16:51:36Z  
**Depth:** standard  
**Files Reviewed:** 20  
**Status:** issues_found

## Summary

Reviewed all 20 scoped files, including the production LiveView and Ops components, recovery and promotion callbacks, development/test fixtures, and browser harness. One blocker remains: the example app exposes unauthenticated development E2E endpoints that can erase its database and search-index data when its development server is reachable. The Phase 175 test-only routes and runtime identity guards are separately scoped and do not remove this risk from the `/dev/e2e` routes.

## Narrative Findings (AI reviewer)

### CR-01: BLOCKER — Unauthenticated development E2E endpoints can erase application data

**File:** `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex:58-69`; destructive implementation at `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex:123-125,528-535`

**Issue:** The `/dev/e2e` routes are compiled into both `:dev` and `:test` environments and use only the `:api` pipeline. They have no authentication or authorization check, and the API pipeline does not apply browser CSRF protection. A direct POST to `/dev/e2e/seed` with a supported scenario calls `reset_state!/0`, which removes all variants, products, categories, tenants, and Oban jobs and clears product documents from the active and target Meilisearch indexes. This turns an exposed development server into an unauthenticated data-destruction endpoint; the same route group also exposes queue draining and record mutation actions.

**Fix:** Keep these mutation/probe routes test-only by default. If development access is required, put them behind an explicit opt-in plus an unguessable authorization token checked on every route, and refuse to run destructive seed/reset operations unless the configured database and search indexes are explicitly marked disposable. Do not rely on the development listener being bound to localhost as the authorization boundary.

---

_Reviewed: 2026-10-10T16:51:36Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
