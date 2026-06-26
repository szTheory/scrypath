---
phase: 135-shell-chrome-polish-dual-theme-s
plan: 03
subsystem: scrypath_ops_shell_chrome
tags:
  - ops-ui
  - shell-chrome
  - command-palette
  - flash
  - dual-theme
  - accessibility
  - playwright
requires:
  - phase: 135-02
    provides: shell chrome header, nav, theme marker, and token groundwork
provides:
  - honest command palette and shortcut sheet ARIA/focus behavior
  - durable flash chrome classes and dark overlay composition
  - full focused shell browser proof across light, dark, system-dark, mobile, and desktop
affects:
  - scrypath_ops shell chrome
  - ecommerce mounted demo host bundle
  - Phase 135 Plan 04 shell chrome report
  - Phase 136 dual-theme verification
tech-stack:
  added: []
  patterns:
    - mirrored mounted host LiveSocket hook for ScrypathOps command palette
    - renderer-neutral flash icon structural contract
    - explicit and system dark CSS mirror rules for overlay chrome
key-files:
  created: []
  modified:
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/components/core_components.ex
    - scrypath_ops/assets/js/app.js
    - examples/scrypath_ecommerce/assets/js/app.js
    - examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/shell_chrome_token_contract_test.exs
key-decisions:
  - "Keep aria-modal=true and make the existing CommandPalette hook defend bounded focus and focus return instead of downgrading semantics."
  - "Mirror command palette hook hardening into the ecommerce host bundle because mounted ops routes use the host LiveSocket."
  - "Use durable ops-flash classes on the passive alert wrapper while preserving Phoenix.Flash lookup and lv:clear-flash dismissal."
patterns-established:
  - "Mounted ScrypathOps browser behavior that lives in hooks must be mirrored in the host ecommerce bundle when the route uses the host LiveSocket."
  - "Shell overlay dark rules for palette and flash are authored as explicit selector rules in both explicit dark and system dark."
requirements-completed:
  - SHELL-DARK-01
duration: 25min
completed: 2026-06-26
status: complete
---

# Phase 135 Plan 03: Shell Chrome Polish Dual Theme Summary

**Command palette focus semantics, passive flash overlay chrome, and full browser proof for dual-theme hidden shell surfaces**

## Performance

- **Duration:** 25 min
- **Started:** 2026-06-26T09:53:35Z
- **Completed:** 2026-06-26T10:18:34Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Command palette and shortcut sheet now keep honest modal semantics with browser-proven focus containment, focus return, active-option state, and `aria-activedescendant`.
- Flash alerts render durable `ops-flash`, `ops-flash--info`, and `ops-flash--error` classes while preserving passive alert semantics, icon/text pairing, dismissal, and Phoenix flash lookup.
- Palette and flash dark chrome use explicit and system-dark ambient shadow plus border rules, with static token contracts and DESIGN-TOKENS documentation.
- The full admin shell browser proof passes across explicit light, explicit dark, system dark, mobile, and desktop.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Command palette semantics proof** - `c3872d3` (test)
2. **Task 1 GREEN: Command palette semantics hardening** - `93fdab6` (feat)
3. **Task 2 RED: Flash chrome contracts** - `509682f` (test)
4. **Task 2 GREEN: Flash overlay chrome** - `e8e59cd` (feat)
5. **Task 3: Full focused shell browser proof** - `42434e3` (test)
6. **Follow-up fix: Flash icon renderer-neutral contract** - `3fb43ee` (fix)

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` - Added stable command palette option IDs and selected-state markup while preserving existing IDs and data hooks.
- `scrypath_ops/assets/js/app.js` - Hardened the existing `CommandPalette` hook for bounded focus, focus return, active option tracking, and close behavior.
- `examples/scrypath_ecommerce/assets/js/app.js` - Mirrored the hook hardening for mounted ScrypathOps routes that use the ecommerce host LiveSocket.
- `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex` - Added durable flash classes and close-label semantics without changing flash behavior.
- `scrypath_ops/assets/css/app.css` - Added explicit and system-dark overlay recipes for `.ops-cmdk__panel` and `.ops-flash`.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` - Documented palette and flash overlay composition invariants.
- `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` - Added structural contracts for palette, shortcut sheet, and flash semantics.
- `scrypath_ops/test/scrypath_ops_web/shell_chrome_token_contract_test.exs` - Added static tripwires for dual-dark palette and flash shadow mirrors.
- `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` - Added browser proof for command palette, shortcut sheet, flash, and shell chrome across theme/viewports.

## Decisions Made

- Kept `aria-modal="true"` for the palette and shortcut sheet because the existing hook now enforces bounded focus and returns focus on close.
- Kept one `CommandPalette` hook and the `.ops-cmdk--closing` handshake instead of adding a dialog dependency or second hook.
- Added flash chrome at the existing passive alert wrapper so role, message lookup, icon/text pairing, and `lv:clear-flash` dismissal stay unchanged.
- Mirrored browser hook behavior into the ecommerce host bundle because mounted ScrypathOps routes load the host `LiveSocket` and `/assets/js/app.js`.

## Verification

- `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/shell_chrome_token_contract_test.exs` - 13 tests, 0 failures.
- `cd scrypath_ops && mix verify.opsui` - 2 doctests and 146 tests, 0 failures.
- `cd scrypath_ops && mix precommit` - 2 doctests and 146 tests, 0 failures.
- `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-shell -- --grep "command palette|shortcut sheet" --reporter=line` - 12 passed.
- `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-shell -- --grep "flash" --reporter=line` - 6 passed.
- `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-shell -- --reporter=line` - 30 passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Mirrored CommandPalette hardening into the ecommerce host bundle**
- **Found during:** Task 1
- **Issue:** Mounted ScrypathOps demo routes use the host ecommerce LiveSocket bundle, so browser proof still saw old command palette behavior after only updating `scrypath_ops/assets/js/app.js`.
- **Fix:** Applied the same existing-hook hardening to `examples/scrypath_ecommerce/assets/js/app.js`.
- **Files modified:** `examples/scrypath_ecommerce/assets/js/app.js`
- **Verification:** Command palette and shortcut sheet Playwright grep passed 12/12, and the full admin shell proof passed 30/30.
- **Committed in:** `93fdab6`

**2. [Rule 1 - Bug] Scoped flash proof to the visible alert**
- **Found during:** Task 2
- **Issue:** Hidden LiveView client/server disconnect alerts also have `role="alert"`, which made the flash locator strict-mode ambiguous before validating the intended visible flash.
- **Fix:** Updated the browser proof to target `#flash-group [role="alert"]:not([hidden])`.
- **Files modified:** `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts`
- **Verification:** Flash Playwright grep passed 6/6, and the full admin shell proof passed 30/30.
- **Committed in:** `509682f`

**3. [Rule 1 - Bug] Made flash icon contract renderer-neutral**
- **Found during:** Plan-level verification
- **Issue:** Heroicons may render either named icon markers or inline SVG output depending on compile path, making the flash structural test brittle even though the runtime semantics were correct.
- **Fix:** Allowed either the expected named Heroicons marker or the equivalent inline SVG structure while keeping role, copy, class, and dismissal assertions strict.
- **Files modified:** `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs`
- **Verification:** Focused shell contract tests passed 13/13, `mix verify.opsui` passed, and `mix precommit` passed.
- **Committed in:** `3fb43ee`

---

**Total deviations:** 3 auto-fixed Rule 1 issues.
**Impact on plan:** All fixes were required for correctness of the planned browser proof and static contracts. No new dependencies, public APIs, or unplanned UI surfaces were added.

## Issues Encountered

- Rebuilt and restarted the running ecommerce demo with the dev overlay so mounted browser proof used current source code while keeping the orchestrator-owned stack running.
- `mix precommit` emitted formatter-only diffs in three LiveView files outside the plan. Those tool-generated, unrelated diffs were inspected and discarded file-by-file to keep the plan commit scope clean.

## Known Stubs

None. The stub scan found only legitimate placeholder attributes and an existing CSS skeleton placeholder comment, not unfinished data wiring or mock UI.

## Threat Flags

None. The changes stayed within the plan's existing browser focus/hook and flash alert trust boundaries, added no network endpoints, changed no auth paths, and introduced no file or schema boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 04 can use the committed browser evidence and contracts to write the final shell chrome report. The remaining untracked generated artifacts were not staged.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/135-shell-chrome-polish-dual-theme-s/135-03-SUMMARY.md`.
- All key files listed in the summary exist.
- All task and follow-up commit hashes were found in git history: `c3872d3`, `93fdab6`, `509682f`, `e8e59cd`, `42434e3`, `3fb43ee`.

---
*Phase: 135-shell-chrome-polish-dual-theme-s*
*Completed: 2026-06-26*
