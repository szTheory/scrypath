---
phase: 174-recovery-entry-and-diagnosis
plan: 07
subsystem: ui
tags: [phoenix, liveview, mutationobserver, command-palette, playwright]

# Dependency graph
requires:
  - phase: 174-02
    provides: validated operator schema target and navigation contract
provides:
  - Server-rendered contextual recovery destination manifest outside the ignored palette
  - CommandPalette synchronization for existing ignored-link hrefs across manifest patches
  - Native browser regression harness for destination, keyboard, focus, and observer lifecycle
affects: [174-08, ops-shell, command-palette]

# Actuals (#2632), measured from the realized diff and persisted plan ledger.
actuals:
  tokens: 5553
  tasks: 2
  commits: 4
plan_head_before: 8cb2f0d064d1c428fe220f217c12acbe7a2ddc14
plan_head_after: c0f51b30bef1dbcb8cb1aa7a5266d60dff8059c6

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Stable server-owned sibling manifest bridges LiveView patches into an ignored subtree.
    - A native MutationObserver updates only existing links and disconnects with the hook.

key-files:
  created:
    - scrypath_ops/test/ops_palette_hook_browser.test.mjs
    - .planning/phases/174-recovery-entry-and-diagnosis/174-07-T1-RED.json
    - .planning/phases/174-recovery-entry-and-diagnosis/174-07-T2-RED.json
  modified:
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
    - scrypath_ops/assets/js/ops_hooks.js
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/priv/static/assets/css/app.css
    - scrypath_ops/priv/static/assets/js/app.js
    - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs

key-decisions:
  - "Keep a stable sibling manifest present without a validated target so the hook can observe later insertions or URL-target removal; only canonical Nav destinations carry the selected schema."
  - "Copy patched href attributes into existing palette anchors, preserving the ignored DOM, keyboard state, and focus lifecycle."

patterns-established:
  - "LiveView-owned context crosses an ignored DOM boundary through a stable, server-rendered manifest and real browser MutationObserver."

requirements-completed: []
coverage:
  - id: D1
    description: "The shell renders canonical contextual recovery destinations and patches the sibling manifest from allowlisted schema A to B while omitting schema context for an invalid target."
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs#command palette recovery destinations follow the validated schema through patches"
        status: pass
    human_judgment: false
  - id: D2
    description: "The actual CommandPalette hook copies changed manifest hrefs into existing ignored links, preserves filtering and keyboard/focus behavior, and disconnects its observer on teardown."
    verification:
      - kind: automated_ui
        ref: "node --test scrypath_ops/test/ops_palette_hook_browser.test.mjs (existing Playwright Chromium; actual LiveView-rendered fixture and native MutationObserver)"
        status: pass
    human_judgment: false

# Metrics
duration: 33m
completed: 2026-10-07
status: complete
---

# Phase 174 Plan 07: Patched command-palette destinations and hook lifecycle Summary

**Contextual recovery links now follow the validated schema across LiveView patches while the ignored command palette keeps its existing anchors and keyboard/focus lifecycle.**

## Performance

- **Duration:** 33m
- **Started:** 2026-10-07T13:41:09Z
- **Completed:** 2026-10-07T14:13:26Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Rendered a canonical destination manifest beside the ignored palette, with stable item IDs and current validated schema context.
- Added native `MutationObserver` synchronization for initial and patched hrefs, with teardown cleanup and no palette subtree replacement.
- Proved the actual exported hook in Chromium against a LiveView-rendered fixture, including schema A→B href changes, filtering, Escape, focus return, and observer disconnect.
- Updated the component catalog and rebuilt both committed Ops bundles.

## Task Commits

1. **Task 1 RED:** `223ab93` — failing LiveView destination regression with classified evidence.
2. **Task 1 GREEN:** `65c7044` — render validated contextual palette destinations.
3. **Task 2 RED:** `d37cd18` — failing native browser href-patch regression with classified evidence.
4. **Task 2 GREEN:** `c0f51b3` — observe contextual palette destinations.

The RED records both returned `RED_EVIDENCE_OK` from `gsd_run check tdd-red-evidence`; each named target failed on the planned missing behavior before production edits. Both tests passed after their corresponding implementation commits.

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` and `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` — server-owned sibling manifest and initial contextual recovery links.
- `scrypath_ops/assets/js/ops_hooks.js` — manifest observer, targeted href synchronization, and hook teardown.
- `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` — A/B patch and invalid-target LiveView assertions; optional real-render fixture export for browser proof.
- `scrypath_ops/test/ops_palette_hook_browser.test.mjs` — existing Playwright browser harness for the actual exported hook and native DOM observer.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — catalog entry for the new OpsUi export.
- `scrypath_ops/priv/static/assets/css/app.css` and `scrypath_ops/priv/static/assets/js/app.js` — outputs of the existing asset build.
- `.planning/phases/174-recovery-entry-and-diagnosis/174-07-T1-RED.json` and `174-07-T2-RED.json` — unchanged classified RED evidence.

## Decisions Made

- Keep the sibling manifest root stable even when no validated target exists. Its unscoped destinations remain safe, and the hook can observe later insertion or removal of schema context.
- Let the server's canonical `Nav.primary` output own destination values; the browser copies only those encoded hrefs into existing ignored anchors.

## Verification

- `mix test test/scrypath_ops_web/ops_shell_contract_test.exs` — 12 tests, 0 failures; emitted the actual schema-A shell fixture used by Chromium.
- `node --test scrypath_ops/test/ops_palette_hook_browser.test.mjs` with the existing Playwright module — 1 test, 1 pass. Chromium confirmed all three palette anchors changed from A to B, filtering and Escape still work, focus returns to the opener, and observer disconnect prevents later copies.
- `mix assets.build` — passed; Tailwind and esbuild rebuilt the existing Ops assets.
- `mix precommit` — 264 tests + 2 doctests, 0 failures.
- `git diff --check` — passed.

The first precommit run found the new `OpsUi` export missing from `DESIGN-TOKENS.md`; the catalog row was added and the full precommit then passed. Compilation continues to report the pre-existing Dialyzer warning in `scrypath/lib/scrypath/sync.ex:61`, outside this plan's changes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Made the native browser harness runnable from either checkout root**
- **Found during:** Task 2 (Synchronize existing palette hrefs when the manifest patches)
- **Issue:** The test hard-coded a repository-root-relative hook path and its first filter query did not match the rendered “Sync and drift” label.
- **Fix:** Resolve the hook source from the test module location and search using the actual rendered label.
- **Files modified:** `scrypath_ops/test/ops_palette_hook_browser.test.mjs`
- **Verification:** The Playwright Chromium test passed all destination, filter, Escape, focus-return, and observer-disconnect assertions.
- **Committed in:** `c0f51b3`.

**2. [Rule 3 - Blocking issue] Added the new OpsUi export to the component catalog**
- **Found during:** Task 2 verification (`mix precommit`)
- **Issue:** The catalog contract rejected the new exported component until its role was documented.
- **Fix:** Documented the server-owned destination manifest role in `assets/css/DESIGN-TOKENS.md`.
- **Files modified:** `scrypath_ops/assets/css/DESIGN-TOKENS.md`
- **Verification:** Full `mix precommit` passed with 264 tests and 2 doctests.
- **Committed in:** `c0f51b3`.

**Total deviations:** 2 auto-fixed (2 Rule 3). Both were required to complete the planned browser proof and existing project checks.

## TDD Gate Compliance

| Task | RED commit/evidence | GREEN commit | Result |
| --- | --- | --- | --- |
| 174-07-T1 | `223ab93`; T1 LiveView assertion failed because the destination manifest was absent; `RED_EVIDENCE_OK` | `65c7044`; LiveView contract test passes | Compliant |
| 174-07-T2 | `d37cd18`; actual Chromium hook test found all three ignored hrefs stayed on schema A after the manifest changed to B; `RED_EVIDENCE_OK` | `c0f51b3`; native browser behavior and lifecycle pass | Compliant |

## Next Phase Readiness

Plan 08 can exercise the server-owned manifest in both entrypoints and complete the broader browser/history checks. OPUX-19 remains pending until that dependent real LiveView/browser proof is complete; this plan establishes and tests its palette patch seam. No human-review judgment or completion is recorded for that outstanding requirement.

---
*Phase: 174-recovery-entry-and-diagnosis*
*Completed: 2026-10-07*

## Self-Check: PASSED

The summary and both RED evidence records exist; all four task commits are ancestors of the current plan branch.
