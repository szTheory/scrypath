---
phase: 173-shared-visual-foundation-and-operational-time
plan: 04
subsystem: operator-ui
tags: [phoenix, liveview, clipboard, playwright, accessibility]
requires:
  - phase: 173-01
    provides: production mounted and standalone PostureLive fixture routes
  - phase: 173-02
    provides: operational timestamp presentation and snapshot-relative age
  - phase: 173-03
    provides: shared visual foundation and theme behavior
provides:
  - Validated operational last-success timestamps copy as exact source ISO in both Ops entrypoints
  - Awaited success, persistent clipboard failure recovery, and latest-activation feedback ordering
  - Browser and LiveView proof for copy eligibility, keyboard/touch use, timer reset, and failed refresh retention
affects: [operator-ui, operational-time, clipboard-feedback]
actuals:
  tokens: 16225
  tasks: 2
  commits: 4
  plan_head_before: 1545c5600977fc90b20e9a725abda95e22f34d7b
  plan_head_after: 6b39f9f68d60fef8771710fb2fc0a7331299700e
tech-stack:
  added: []
  patterns:
    - Shared OpsTimestampCopy hook registered in both LiveSockets
    - Latest user activation owns asynchronous clipboard feedback
key-files:
  created:
    - examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts
    - .planning/phases/173-shared-visual-foundation-and-operational-time/173-04-T1-red.json
    - .planning/phases/173-shared-visual-foundation-and-operational-time/173-04-T1-red.xml
    - .planning/phases/173-shared-visual-foundation-and-operational-time/173-04-T2-red.json
    - .planning/phases/173-shared-visual-foundation-and-operational-time/173-04-T2-red.xml
  modified:
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/assets/js/ops_hooks.js
    - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
    - examples/scrypath_ecommerce/docker-playwright.sh
    - examples/scrypath_ecommerce/assets/js/app.js
    - scrypath_ops/priv/static/assets/js/app.js
key-decisions:
  - "Offer copy only when source_iso parses to the same instant as the displayed DateTime."
  - "Use the latest activation to guard out-of-order clipboard promise completions; do not read the clipboard or use fallback copying."
requirements-completed: [OPUX-15]
coverage:
  - id: D1
    description: "Both Ops entrypoints copy only validated operational source timestamps and present feedback that reflects the latest clipboard outcome."
    requirement: OPUX-15
    verification:
      - kind: automated_ui
        ref: "bash examples/scrypath_ecommerce/scripts/verify-phase173.sh copy at 6b39f9f68d60fef8771710fb2fc0a7331299700e (12 passed)"
        status: pass
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs (11 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "mix verify.ops_ui (244 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 37min
completed: 2026-10-06
status: complete
---

# Phase 173 Plan 04: Shared Visual Foundation and Operational Time Summary

**Ops last-success timestamps copy their validated source ISO in both LiveView entrypoints, with truthful clipboard feedback and selectable fallback evidence.**

## Performance

- **Duration:** 37 min, measured from the first timestamped baseline browser run through completion
- **Started:** 2026-10-06T20:20:26-04:00
- **Completed:** 2026-10-06T20:57:48-04:00
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Added a visible, named copy button beside operational last-success timestamps. It copies the validated full source ISO after user activation and shows success only after `writeText` resolves.
- Added persistent, dismissible failure feedback with the exact timestamp disclosure open for manual selection. Older in-flight writes can no longer overwrite feedback from a newer activation.
- Verified both mounted and standalone LiveView routes with browser and LiveView coverage for rejection, unavailable clipboard, repeat timer reset, keyboard/touch activation, invalid or missing timestamps, Checked metadata, theme changes, narrow layout, and failed-refresh age retention.

## Task Commits

Tasks were committed individually, with a RED test commit before each GREEN implementation:

1. **Task 1 RED:** `25a7113` (`test(173-04): add failing timestamp copy browser proof`)
2. **Task 1 GREEN:** `105038e` (`feat(173-04): copy validated operational timestamps from Ops`)
3. **Task 2 RED:** `1fec011` (`test(173-04): prove stale clipboard completion race`)
4. **Task 2 GREEN:** `6b39f9f` (`feat(173-04): preserve latest clipboard outcome`)

**Plan metadata:** committed separately after self-check.

## Verification

- `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh copy` — **12 passed** against committed source `6b39f9f68d60fef8771710fb2fc0a7331299700e`; both production routes asserted `phx-connected` before interaction.
- `scrypath_ops` `mix test test/scrypath_ops_web/live/posture_live_test.exs` — **11 tests, 0 failures**.
- Root `mix verify.ops_ui` — **244 tests, 0 failures**.
- `scrypath_ops` `mix precommit` — **2 doctests, 244 tests, 0 failures**.
- Root `mix test test/scrypath/operator/status_test.exs` — **5 tests, 0 failures**.
- `make -C examples/scrypath_ecommerce contrast` — **PASS**, 0 AA failures; 35 AAA advisories.
- Retained Phase 173-02 `mix verify.core --exclude integration --exclude docs_contract` pass (659 tests, 0 failures, warnings-as-errors compile); this plan changed no root core files.
- Task 1 and Task 2 TDD RED reports are preserved in the phase directory. The T2 evidence classifier returned `RED_EVIDENCE_OK`: both route cases failed the intended latest-outcome assertion, while the two existing success cases passed.

## Visual Evidence

Actual browser captures and source identity files are preserved outside the worktree at `/private/tmp/scrypath-phase173-20261006-155750/evidence/173-04/`:

- `before/` — 16 baseline captures across mounted and standalone routes, widths 390/1279/1280/1440, and light/dark themes; source `1545c5600977fc90b20e9a725abda95e22f34d7b`.
- `after-task1/` — 8 copy-state captures at 390/1440 in both themes and routes; source `105038e3efa2c53712a920eb327d0919ab5a7072`.
- `after-task2/` — the same 8 view combinations and the final JUnit report; source `6b39f9f68d60fef8771710fb2fc0a7331299700e`.

Inspection showed the labeled control and resolved success message remain readable next to “Last success” on mobile and desktop in both entrypoints and themes. At 390px the page has no horizontal overflow. The baseline views had no dedicated copy control. Failure and repeat-timer states are covered by executable browser assertions rather than screenshots.

The disposable Phase 173 Compose project completed cleanup. Its browser, web, Ops, Postgres, and Meilisearch containers, the fixture volume, and the project network were removed; follow-up container and network label queries returned empty.

## Decisions Made

- Copy eligibility requires a parsed source ISO that matches the displayed timestamp instant; invalid, absent, and unobserved times do not get a misleading action.
- Each activation supersedes prior pending writes for feedback purposes. The newest activation keeps its success or failure state even if an older promise settles afterward.
- No clipboard-read request, fallback copy path, dependency, or CI lane was added.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The referenced `173-UI-SPEC.md`, `173-UI-CHECK.md`, and `173-RESEARCH.md` were absent from this worktree. Execution followed the available approved `173-CONTEXT.md`, `173-PATTERNS.md`, `173-VALIDATION.md`, and prior plan summaries; browser and pixel evidence covered the planned UI contract.
- An initial `mix verify.ops_ui` invocation from inside `scrypath_ops` resolved its project path twice and failed before testing. Running the documented alias from the repository root passed.
- An initial draft of the added LiveView test used unavailable `Application.update_env/3`; it was corrected to `Application.put_env/3`, then the focused suite passed.
- Standalone asset compilation reports the existing `Scrypath.Sync.sync_related/3` typing warning. `RelatedEnqueue.enqueue/4` has a compile-time no-Oban fallback that always raises, so the optional Oban branch is inferred as `none()` at `decorate_result/2`. The warning did not block Ops verification or precommit; root core files were unchanged, and the prior required warnings-as-errors core gate passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

OPUX-15 is complete with current-source browser, LiveView, contrast, and Ops precommit evidence. No blocker remains for the next plan.

## Self-Check: PASSED

- All key files and four task commits exist on this worktree branch.
- `evaluation-scope --plan 173-04 --commits-only` resolved all four task commits.
- Plan verification commands passed or, for the unchanged root core gate, are retained from Phase 173-02 as requested.

---
*Phase: 173-shared-visual-foundation-and-operational-time*
*Completed: 2026-10-06*
