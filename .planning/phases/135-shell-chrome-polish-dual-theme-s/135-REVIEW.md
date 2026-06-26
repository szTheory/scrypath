---
phase: 135-shell-chrome-polish-dual-theme-s
reviewed: 2026-06-26T12:27:16Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - examples/scrypath_ecommerce/assets/js/app.js
  - examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts
  - examples/scrypath_ecommerce/e2e/helpers/e2e.ts
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/components/layouts.ex
  - examples/scrypath_ecommerce/package.json
  - scrypath_ops/assets/css/DESIGN-TOKENS.md
  - scrypath_ops/assets/css/app.css
  - scrypath_ops/assets/js/app.js
  - scrypath_ops/lib/scrypath_ops_web/components/core_components.ex
  - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
  - scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex
  - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
  - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/shell_chrome_token_contract_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: resolved
resolved_by:
  - 57b4566
---

# Phase 135: Code Review Report

**Reviewed:** 2026-06-26T12:27:16Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** resolved

## Summary

Reviewed the Phase 135 shell chrome implementation across the ecommerce host assets, ScrypathOps layout/components, CSS token contracts, and the new Playwright/ExUnit coverage. The scoped Elixir contract tests pass locally, and the Playwright shell suite is discoverable, but two user-facing shell defects remain: standalone `/ops` theme button ARIA state can go stale after LiveView navigation, and the shortcut sheet advertises only the macOS command key even though the JS supports Ctrl+K on other platforms.

**Resolution:** Both warnings were fixed in `57b4566` (`fix(135-review): resolve shell accessibility warnings`). Follow-up verification passed:

- `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/shell_chrome_token_contract_test.exs` — 14 tests, 0 failures.
- `mix verify.opsui` — 2 doctests, 147 tests, 0 failures.

Verification performed:

- `mix test scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs scrypath_ops/test/scrypath_ops_web/shell_chrome_token_contract_test.exs` passed: 13 tests, 0 failures.
- `npm run test:e2e:admin-shell -- --list` listed 30 Chromium tests. The browser suite itself was not run because this Playwright config has no `webServer`; it requires the ecommerce dev lane to be running manually.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01 [WARNING]: Standalone `/ops` theme toggle ARIA state is not resynced after LiveView navigation

**File:** `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex:67`

**Issue:** The root theme provider updates `aria-pressed` and `data-theme-selected` on DOMContentLoaded, storage changes, media changes, and direct `phx:set-theme` clicks, but it does not run after LiveView navigation patches. `theme_toggle/1` renders every button with `aria-pressed="false"` and `data-theme-selected="false"` by default, so replacing the LiveView shell can leave all three standalone `/ops` buttons semantically unselected until the next explicit theme event. The ecommerce host avoids this with a `phx:page-loading-stop` sync listener in `examples/scrypath_ecommerce/assets/js/app.js`, but the standalone ScrypathOps root does not.

**Fix:**

```html
window.addEventListener("phx:page-loading-stop", () => syncThemeMeta());
```

Add that listener to the root theme provider after the existing `phx:set-theme` listener, and extend the contract test to assert the root template contains `phx:page-loading-stop`.

**Resolved in:** `57b4566`

### WR-02 [WARNING]: Shortcut sheet documents the wrong command-palette shortcut on non-macOS platforms

**File:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1157`

**Issue:** The command palette handler accepts `Meta+K` and `Ctrl+K`, and the Playwright helper uses `Control+K` on non-Darwin platforms. The visible shortcut sheet, however, only renders `⌘ K`. On Windows/Linux this tells operators to use a key they do not have, making the discoverable navigation path misleading.

**Fix:**

```elixir
<dt>
  <span class="sr-only">Command or Control K</span>
  <span aria-hidden="true">
    <kbd class="ops-kbd">⌘</kbd>/<kbd class="ops-kbd">Ctrl</kbd>
    <kbd class="ops-kbd">K</kbd>
  </span>
</dt>
```

Use platform-neutral visible text such as `⌘/Ctrl K` and keep an explicit accessible label so screen readers announce the shortcut clearly.

**Resolved in:** `57b4566`

---

_Reviewed: 2026-06-26T12:27:16Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
