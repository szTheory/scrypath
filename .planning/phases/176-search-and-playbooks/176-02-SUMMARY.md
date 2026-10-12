---
phase: 176-search-and-playbooks
plan: 02
subsystem: ui
tags: [phoenix-live-view, search, playbooks, persistence, playwright, accessibility, responsive-ui]

requires:
  - phase: 176-01
    provides: Frozen submitted Search criteria and eligible response ownership.
provides:
  - Progressive Search capture form tied to the actual completed single or partial multi response.
  - Inline collision, configuration, validation, and write-error feedback that retains entered metadata.
  - Criteria-and-metadata-only playbook persistence with a closed exact-JSON disclosure.
  - Browser evidence for collision rejection, successful zero-hit save, Playbooks handoff, and responsive layouts.
affects: [176-03, search-capture, playbooks]

actuals:
  tokens: 6570
  tasks: 2
  commits: 0

tech-stack:
  added: []
  patterns:
    - Keep form errors associated with Filename and display the actual safe filesystem error code with the approved recovery copy.
    - Save only the frozen query criteria plus optional metadata; keep raw JSON evidence closed by default.

key-files:
  created:
    - .planning/phases/176-search-and-playbooks/176-02-SUMMARY.md
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts

key-decisions:
  - Keep Search capture's no-replace policy, using the existing Store collision guard and temporary-workspace verification.
  - Show save errors inline, retain typed values, and report filesystem error atoms without exposing workspace paths.
  - Keep exact JSON behind a closed native disclosure so the common save flow stays compact.
  - Add no dependency; existing OpsUi controls, Store, and Playwright lane cover the required behavior.

patterns-established:
  - Search capture is available only after an eligible returned response, including zero-hit single and partial multi results.
  - Collision and write failures retain user values and never announce successful persistence.
  - Responsive evidence covers 1440px, 768px, and 390px in both light and dark themes.

requirements-completed: [OPUX-23]
coverage:
  - id: D1
    description: Eligible zero-hit and partial Search responses save submitted criteria and optional metadata without response documents.
    requirement: OPUX-23
    verification:
      - kind: unit
        ref: scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs — zero-hit and partial multi capture tests
        status: pass
      - kind: integration
        ref: mix verify.ops_ui — 273 tests and 2 doctests
        status: pass
    human_judgment: false
  - id: D2
    description: Capture errors retain values, reject collisions, expose associated recovery guidance, and the browser can save to Playbooks across widths and themes.
    requirement: OPUX-23
    verification:
      - kind: unit
        ref: scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs — collision, missing-workspace, and write-failure tests
        status: pass
      - kind: e2e
        ref: examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts — 35/35 admin surface depth tests
        status: pass
      - kind: automated_ui
        ref: examples/scrypath_ecommerce/test-results/phase176-search-capture-evidence — 12 light/dark form and collision screenshots at 1440px, 768px, and 390px
        status: pass
      - kind: other
        ref: cd scrypath_ops && mix assets.build
        status: pass
    human_judgment: false

duration: 19min
completed: 2026-10-11
status: complete
---

# Phase 176 Plan 02: Search capture persistence and recovery

**Search capture now saves only the last eligible run's criteria, with retained values, explicit recovery, and a proven no-replace flow.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-10-11T16:56:00Z
- **Completed:** 2026-10-11T17:15:16Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Restricted capture to eligible returned Search results and verified successful zero-hit single and partial multi responses. Saved JSON contains submitted query criteria and optional title/description, without result documents.
- Replaced generic error flashes with filename-associated inline errors. Collision, missing workspace setup, and write errors retain entered values; write failures show the safe actual reason (`:enotdir` in the deterministic failure test) and the approved recovery copy.
- Renamed the fields to `Filename` and `Search title`, added the `.json`/no-replace hint, and moved exact JSON into a closed `Exact playbook JSON` disclosure.
- Extended the real browser path to reject an occupied seed file, verify unchanged bytes, save a unique zero-hit check, validate its JSON, and find it in Playbooks.
- Reviewed light/dark images at 1440px, 768px, and 390px. The capture form and wrapped error remain readable; document width stays within each viewport.

## Task Commits

No commits were created; this execution worktree's branch guard remains in force.

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` — inline save state, safe actual error details, accessible progressive form, and closed JSON disclosure.
- `scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs` — eligibility, saved JSON, collision, retained fields, setup failure, and write failure coverage.
- `scrypath_ops/assets/css/app.css` and `scrypath_ops/priv/static/assets/css/app.css` — capture form wrapping and built production styles.
- `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` — collision-to-save browser scenario across six theme/viewport combinations.

## Decisions Made

- Keep the existing `Store.save_workspace_file/3` and Search collision guard; no additional dependency or storage abstraction was needed.
- Restrict displayed filesystem details to safe error atoms so recovery is concrete without exposing local paths.
- Treat an eligible zero-hit or partial response as criteria worth saving while keeping its partial/zero result truth visible.

## Deviations from Plan

None. A first browser assertion assumed the page-size default was 10; the scenario now sets 10 explicitly and verifies that submitted value in the saved JSON.

## Issues Encountered

- The canonical `mix verify.ops_ui` alias must run from repository root. Invoking the inner app from `scrypath_ops` used a nonexistent nested path; rerunning the documented root command passed.
- The E2E preview used the disposable Compose service on port 4004 because host port 4002 was unavailable. The retained `:4012` feedback preview was not touched.

## User Setup Required

None.

## Next Phase Readiness

Plan 176-03 can now implement the Playbooks catalog and independent draft-save flow using the truthful Search handoff produced here. The disposable browser lane remains isolated from the retained preview.

## Self-Check: PASSED

- Summary and all declared implementation artifacts exist.
- `git diff --check` is clean.
- Focused LiveView tests, `mix verify.ops_ui`, asset build, and the full 35-test browser lane match the recorded passing evidence.
- No commit hashes are claimed; execution remains in the guarded phase worktree.

---
*Phase: 176-search-and-playbooks*
*Completed: 2026-10-11*
