---
phase: 135-shell-chrome-polish-dual-theme-s
plan: 02
subsystem: scrypath_ops_shell_chrome
status: complete
requirements:
  - SHELL-DARK-01
tags:
  - ops-ui
  - shell-chrome
  - dual-theme
  - accessibility
dependency_graph:
  requires:
    - 135-01
  provides:
    - durable shell chrome DOM markers
    - dual-dark shell chrome CSS contracts
    - mounted-demo browser proof for shell surfaces and theme toggle
  affects:
    - scrypath_ops shell layout
    - scrypath_ops CSS tokens
    - ecommerce demo mounted ops shell
tech_stack:
  added:
    - none
  patterns:
    - Phoenix LiveView HEEx shell components
    - Tailwind v4 static CSS token contracts
    - Playwright mounted-demo proof
key_files:
  created:
    - scrypath_ops/test/scrypath_ops_web/shell_chrome_token_contract_test.exs
    - .planning/phases/135-shell-chrome-polish-dual-theme-s/deferred-items.md
  modified:
    - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
    - scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
    - examples/scrypath_ecommerce/e2e/helpers/e2e.ts
    - examples/scrypath_ecommerce/assets/js/app.js
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/components/layouts.ex
decisions:
  - Keep shell chrome proof selectors on the live inline brand mark and existing theme-toggle DOM rather than adding a new shell abstraction.
  - Mirror custom shell chrome dark CSS in both explicit dark and system-dark paths.
  - Extend the ecommerce demo's existing theme provider so mounted ScrypathOps routes expose the same selected-state semantics as the standalone ops root.
metrics:
  started_at: 2026-06-26T09:19:29Z
  completed_at: 2026-06-26T09:42:56Z
  duration_seconds: 1407
  tasks_completed: 3
  commits:
    - 7be108b
    - 23a3709
    - 675019e
    - 66438db
    - 019f652
    - 6ee3c39
---

# Phase 135 Plan 02: Shell Chrome Polish Summary

Shell chrome dark polish now has durable DOM selectors, dual-dark CSS contracts, and a browser proof across shared surfaces, theme modes, and mobile/desktop viewports.

## What Changed

- Added durable `ops-brand-mark`, `ops-theme-toggle`, `ops-theme-toggle__pill`, and `ops-theme-toggle__button` selectors without changing `Nav.primary/1` route order or labels.
- Extended theme selected-state sync so `aria-pressed` and `data-theme-selected` reflect system/light/dark preference changes.
- Added dark-only shell chrome treatment for `.ops-header`, `.ops-shell`, `.ops-brand-mark`, `.ops-theme-toggle*`, and documented the selector/token contract.
- Added `shell_chrome_token_contract_test.exs` to guard one-radial shell wash, dual-dark mirrors, active-nav `--color-primary-strong`, and live brand selector usage.
- Fixed mounted ecommerce demo behavior found by browser proof: duplicate host flash chrome on ops routes, mounted theme selected-state sync, nested icon click theme dispatch, and deterministic pill position.
- Hardened the shared Playwright LiveView readiness helper after the post-wave browser gate exposed dropped `phx-click` events during mounted route transitions.

## Task Commits

| Task | Name | Commit | Notes |
| --- | --- | --- | --- |
| 1 RED | Add failing shell chrome marker contract | `7be108b` | Added failing DOM marker and root sync assertions. |
| 1 GREEN | Add durable shell chrome markers | `23a3709` | Added shell selectors and root theme selected-state sync. |
| 2 RED | Add failing shell chrome token contract | `675019e` | Added static CSS/token tripwires. |
| 2 GREEN | Tune shell chrome dark CSS | `66438db` | Added dual-dark CSS, token docs, and formatted focused contract tests. |
| 3 | Stabilize shell chrome browser proof | `019f652` | Fixed browser-discovered mounted-shell integration issues and reran proof. |
| Post-wave gate fix | Wait for mounted LiveView readiness | `6ee3c39` | Required the mounted LiveView root to reach `.phx-connected` before E2E helpers drive `phx-click` controls. |

## Verification

- `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/shell_chrome_token_contract_test.exs` - passed, 10 tests.
- `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-shell -- --grep "shared surfaces|theme toggle" --reporter=line` - passed, 12 tests.
- `cd scrypath_ops && mix verify.opsui` - passed, 2 doctests and 143 tests.
- `cd scrypath_ops && mix precommit` - passed, 2 doctests and 143 tests. The command formatted unrelated files; those unrelated deltas were discarded by explicit path and logged in `deferred-items.md`.
- Orchestrator post-wave rerun against the containerized test stack initially failed because `gotoSyncDrift` could click before the mounted LiveView root joined. After `6ee3c39`, the same `shared surfaces|theme toggle` run passed 12/12.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed duplicate mounted flash chrome**
- **Found during:** Task 3 browser proof.
- **Issue:** The ecommerce host root rendered its own `#flash-group` on `/admin/search` while ScrypathOps also rendered the operator shell flash group, causing the browser proof to find two `#flash-group` nodes.
- **Fix:** Suppressed the host flash group on mounted ops admin paths.
- **Files modified:** `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/components/layouts.ex`
- **Commit:** `019f652`

**2. [Rule 1 - Bug] Fixed mounted theme selected-state sync**
- **Found during:** Task 3 browser proof.
- **Issue:** Mounted ops routes use the ecommerce host bundle, whose theme provider updated root attributes but did not mirror selected state onto `[data-phx-theme]` buttons. Nested icon clicks could also miss `data-phx-theme`.
- **Fix:** Added mounted button sync, robust closest-button event targeting, DOM-ready/page-loading resync, and mirrored the closest-button guard in the standalone ops root provider.
- **Files modified:** `examples/scrypath_ecommerce/assets/js/app.js`, `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex`, `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs`
- **Commit:** `019f652`

**3. [Rule 1 - Bug] Made pill-position proof deterministic**
- **Found during:** Task 3 browser proof.
- **Issue:** The browser test reads computed `left` immediately after switching light to dark; transitioning `left` could still report the previous value on desktop.
- **Fix:** Kept pill color/border/shadow transitions but stopped transitioning `left`, so the computed position updates immediately.
- **Files modified:** `scrypath_ops/assets/css/app.css`
- **Commit:** `019f652`

**4. [Rule 1 - Bug] Hardened mounted LiveView readiness in browser helpers**
- **Found during:** Orchestrator post-wave browser gate.
- **Issue:** `waitForLiveConnected/1` only checked the global LiveSocket connection. During repeated mounted-route navigation, the global socket could already be connected while the new LiveView root had not yet joined, so the Sync/Drift `phx-click` was dropped and the proof stayed in "Drift not loaded".
- **Fix:** Require `[data-phx-main]` to have the `phx-connected` class before browser helpers drive interactive controls.
- **Files modified:** `examples/scrypath_ecommerce/e2e/helpers/e2e.ts`
- **Commit:** `6ee3c39`

### Out-of-Scope Findings

- `mix precommit` exposed formatter churn in unrelated files outside Plan 135-02. Details are logged in `.planning/phases/135-shell-chrome-polish-dual-theme-s/deferred-items.md`.

## Known Stubs

None. Stub scan found only command-palette state resets, an existing skeleton placeholder comment, and test assertion literals.

## Auth Gates

None.

## Threat Flags

None. The added browser behavior stays within the plan's existing theme localStorage and shell DOM trust boundary and introduced no package installs, network endpoints, auth paths, file access, or schema changes.

## Self-Check: PASSED

- Found summary, deferred-items log, and `shell_chrome_token_contract_test.exs`.
- Found task commits `7be108b`, `23a3709`, `675019e`, `66438db`, `019f652`, and post-wave gate fix `6ee3c39`.
