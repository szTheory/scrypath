---
phase: 176-search-and-playbooks
plan: 05
subsystem: ui
tags: [phoenix-live-view, playbooks, modal-focus, accessibility, playwright, responsive-ui]

requires:
  - phase: 176-04
    provides: Explicit bounded imports and captured run provenance through asynchronous outcomes.
provides:
  - Contextual per-row file mutations inside closed native Manage disclosures.
  - Server-guarded rename, duplicate, and typed-delete actions with readable recovery states.
  - Modal initial focus, validation focus, and visible logical focus return through LiveView row patches.
  - Executable keyboard, responsive, theme, and contrast evidence for the completed Search and Playbooks phase.
affects: [playbooks, search-capture, ops-modal, operator-accessibility, phase-177-delivery-proof]

actuals:
  # Touched files overlap earlier Phase 176 plans; this is the full recovery-scope diff estimate.
  tokens: 35645
  tasks: 3
  commits: 1

tech-stack:
  added: []
  patterns:
    - Keep occasional file mutations in a closed in-flow native disclosure while preserving server authorization and Store checks.
    - Carry stable record identity and a visible logical successor through modal patches; reject hidden, removed, or reused focus targets.
    - Focus an invalid field only for a new validation request, after LiveView patch focus restoration settles.

key-files:
  created:
    - .planning/phases/176-search-and-playbooks/176-05-SUMMARY.md
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/assets/js/ops_hooks.js
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - scrypath_ops/priv/static/assets/js/app.js
    - scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
    - examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts

key-decisions:
  - "Keep Manage closed by default and retain Load preview and Run without preview as the common row actions."
  - "Close Manage before opening a mutation dialog and restore focus only to a visible control representing the correct file."
  - "Keep server authorization, configured-root, safe basename/path, collision, and exact delete-name checks authoritative."
  - "Avoid dependencies and reuse the existing OpsModal, OpsUi disclosure, Store, and browser lane."

patterns-established:
  - "OpsModal focus return validates visibility and file identity after LiveView patches, then tries a named successor and a stable catalog fallback."
  - "Validation focus is request-scoped so ordinary patches do not repeatedly steal focus."

requirements-completed: [OPUX-23, OPUX-24, OPUX-25]
coverage:
  - id: D1
    description: Search capture remains tied to an eligible submitted result, rejects occupied destinations, and retains actionable error recovery.
    requirement: OPUX-23
    verification:
      - kind: integration
        ref: mix verify.ops_ui — 286 tests and 2 doctests
        status: pass
      - kind: e2e
        ref: examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts — 38/38 admin-depth tests
        status: pass
    human_judgment: false
  - id: D2
    description: Playbooks preserve draft/run provenance and import only on explicit submit while retaining the prior valid preview after errors.
    requirement: OPUX-24
    verification:
      - kind: unit
        ref: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs — 34 focused tests
        status: pass
      - kind: integration
        ref: mix verify.ops_ui — 286 tests and 2 doctests
        status: pass
      - kind: e2e
        ref: examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts — 38/38 admin-depth tests
        status: pass
    human_judgment: false
  - id: D3
    description: File mutation controls remain contextual and server-guarded; forged actions, collisions, and exact typed deletion are rejected.
    requirement: OPUX-25
    verification:
      - kind: unit
        ref: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs — 34 focused tests including authorization, collision, and typed-delete cases
        status: pass
      - kind: integration
        ref: mix verify.ops_ui — 286 tests and 2 doctests
        status: pass
    human_judgment: false
  - id: D4
    description: Mutation dialogs preserve keyboard containment and validation focus, then restore focus to a visible correct row after cancel, rename, duplicate, or delete patches.
    requirement: OPUX-25
    verification:
      - kind: e2e
        ref: examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts — 38/38 admin-depth tests, including mutation focus and patch cases
        status: pass
      - kind: automated_ui
        ref: examples/scrypath_ecommerce/test-results/phase176-management-evidence — light/dark before-and-after evidence at 1440px, 768px, and 390px
        status: pass
      - kind: other
        ref: make -C examples/scrypath_ecommerce contrast — zero AA failures
        status: pass
    human_judgment: false

duration: 58min
completed: 2026-10-11
status: complete
---

# Phase 176 Plan 05: Contextual file actions and patch-safe modal focus

**Playbook file actions now stay in a quiet per-row disclosure, and mutation dialogs return keyboard focus to the correct visible record after LiveView patches.**

## Performance

- **Duration:** approximately 58 min; the original execution crossed a context reset.
- **Started:** 2026-10-11T18:39:00Z (approximate).
- **Completed:** 2026-10-11T19:36:57Z (from the execution record).
- **Tasks:** 3.
- **Files modified:** 8 implementation, asset, test, and browser-spec files.

## Accomplishments

- Moved Duplicate, Rename, and Delete into a closed, in-flow Manage disclosure; kept Load preview and Run without preview as the common row actions and omitted mutations for read-only examples.
- Preserved host authorization, configured-root and path checks, Store collision handling, and exact typed-delete confirmation regardless of client-visible controls.
- Made OpsModal close the invoking disclosure, focus the requested input or Cancel control, preserve invalid input, and return focus only to a visible target with the expected record identity. Removed, hidden, closed-disclosure, and reused nodes are rejected before successor/fallback selection.
- Added LiveView and real-browser coverage for disclosure state, forged events, collisions, typed confirmation, modal containment, invalid-value retention, and focus restoration after actual row changes.
- Captured light/dark before-and-after evidence at 1440px, 768px, and 390px; existing shared tokens were sufficient, so DESIGN-TOKENS.md did not need an update.

## Task Commits

The original inline execution did not produce per-task commits. Following the maintainer-approved recovery, the already-verified Phase 176 changes and plan summaries are represented by one aggregate recovery commit containing this summary. No implementation task was replayed.

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` — per-row Manage actions, mutation dialog state, stable focus identities, and validation recovery.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — disclosure summary identity and reusable OpsModal focus/successor properties; body-sized hints and errors.
- `scrypath_ops/assets/js/ops_hooks.js` and `scrypath_ops/priv/static/assets/js/app.js` — disclosure closing, request-scoped validation focus, visible/identity-safe focus restoration, and successor fallback.
- `scrypath_ops/assets/css/app.css` and `scrypath_ops/priv/static/assets/css/app.css` — filename wrapping and narrow-layout containment using existing tokens.
- `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` — rendered action, authorization, collision, dialog-state, and focus metadata coverage.
- `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` — real-browser keyboard, focus-return, patch, theme, and responsive cases.
- `examples/scrypath_ecommerce/test-results/phase176-management-evidence/` — ignored before/after screenshots for desktop, changed, and mobile widths in light and dark themes.

## Decisions Made

- Kept infrequent mutations discoverable without letting them compete with preview or run actions.
- Kept all mutation eligibility and filesystem policy on the server; the disclosure is presentation only.
- Reused the existing modal and Store contracts, with no new package or storage abstraction.
- Kept validation focus event-driven and record-aware instead of restoring focus to a connected but stale DOM node.

## Deviations from Plan

**Recovery closeout:** The implementation and executable checks were completed inline in the existing GSD phase worktree, but its prior executor could not create normal per-task commits. Per the maintainer-approved recovery, the complete verified Phase 176 delta is consolidated into one aggregate recovery commit and this summary. This avoids replaying the implementation and keeps the phase in the existing isolated feature worktree; the original checkout and preview remain untouched.

## Issues Encountered

- GSD plan-scoped evaluation initially found no commits because the changes remained uncommitted. The recovery commit is recorded under `176-05`; Plans 176-01 through 176-04 retain their accurate summaries and are not redispatched.
- Two flagged, spec-less Store assumptions remain unresolved: guarantees for repeating the same mutation and for concurrent/interrupted mutations. Existing Store collision/missing-file behavior and server eligibility checks remain authoritative; no stronger guarantee is claimed here.
- The disposable browser stack used for evidence was removed after verification. Preview port 4012 and its data were left untouched.

## Verification

- `cd scrypath_ops && mix assets.build` — passed.
- Focused Playbooks LiveView suite — 34 tests passed.
- `cd scrypath_ops && mix precommit` — passed.
- `mix verify.ops_ui` — 286 tests and 2 doctests passed.
- `make -C examples/scrypath_ecommerce contrast` — zero AA contrast violations.
- `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-depth` — 38/38 passed.
- `git diff --check` — passed before closeout.

## User Setup Required

None.

## Next Phase Readiness

Phase 176 implementation and executable plan gates are complete. Phase-level verification and review are recorded in `176-VERIFICATION.md`, `176-REVIEW.md`, and `176-UI-REVIEW.md`; Phase 177 is not started and owns cross-surface pattern consolidation and delivery proof.

## Self-Check: PASSED

- Summary and declared implementation files exist.
- `gsd_run check evaluation-scope --plan 176-05 --commits-only --raw` resolves the aggregate recovery commit on this branch.
- Focused tests, the Ops gate, asset build, contrast, and the 38-test admin-depth browser suite are recorded above as passing.
- No implementation plan was redispatched or replayed during recovery.

---
*Phase: 176-search-and-playbooks*
*Completed: 2026-10-11*
