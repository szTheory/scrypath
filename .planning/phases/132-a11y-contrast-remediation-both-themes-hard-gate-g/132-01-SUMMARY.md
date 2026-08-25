---
phase: 132-a11y-contrast-remediation-both-themes-hard-gate-g
plan: 01
subsystem: ui
tags: [accessibility, wcag-aa, css-tokens, tailwind-v4, daisyui, scrypath-ops]

requires:
  - phase: 128-contrast-harness
    provides: Fast token checker, muted manifest, and browser contrast-report contract
  - phase: 131-glow-dark-shadow-and-copper-accent-system-r-g
    provides: Deferred Cluster 3 primary-violet and muted-text contrast failures
provides:
  - Named `--ops-text-muted` AA floor for readable muted text
  - Scoped `--color-primary-strong` token for text-bearing selected violet fills
  - Fast checker support for named muted tokens and `primary-strong`
  - Design-token documentation for Phase 132 contrast floors
affects: [phase-132, phase-136-dualverify, scrypath_ops, admin-contrast-gate]

tech-stack:
  added: []
  patterns:
    - Named readable-muted contrast token with manifest `css_var` lockstep
    - Scoped text-bearing primary fill token separate from decorative primary/accent

key-files:
  created:
    - .planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-01-SUMMARY.md
  modified:
    - examples/scrypath_ecommerce/contrast-checker.mjs
    - scrypath_ops/assets/css/contrast-pairs.mjs
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md

key-decisions:
  - "Readable muted text routes through `--ops-text-muted` at 64% instead of scattered raw percentages."
  - "`--color-primary-strong` is `#5b4ad1` in both themes and is limited to text-bearing selected fills."
  - "AA remains the hard gate; AAA body/long-form contrast remains advisory/report-only."

patterns-established:
  - "Manifest entries with `css_var: \"ops-text-muted\"` must match `color: var(--ops-text-muted)` consumers and the 64% token declaration in `app.css`."
  - "Generated `bg-primary text-primary-content` selected states are corrected with a scoped CSS override, not component edits."

requirements-completed: [A11Y-TOKEN-01]

duration: ~6min
completed: 2026-06-04
---

# Phase 132 Plan 01: A11y Contrast Token Remediation Summary

**Named AA contrast tokens for muted text and selected violet fills, enforced by the fast checker and documented in the ScrypathOps token catalog**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-06-04T20:58:02Z
- **Completed:** 2026-06-04T21:04:39Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Extended `contrast-checker.mjs` so the D-15 guard requires 21 parsed `--color-*` tokens, including `primary-strong`, and evaluates `primary-content/primary-strong` as normal text at 4.5:1.
- Added `css_var: "ops-text-muted"` manifest support for named muted-token consumers while preserving raw-alpha manifest checks for existing raw muted entries.
- Added `--ops-text-muted` at `64%` and `--color-primary-strong: #5b4ad1` in both daisyUI theme blocks, then routed the six readable muted selectors, ops-owned `/60` utility text, `.ops-nav-item-active`, and `.bg-primary.text-primary-content` through those tokens.
- Documented the Phase 132 contrast floors, consumer lists, and AA-hard/AAA-advisory posture in `DESIGN-TOKENS.md`.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Extend the fast contrast gate for named AA tokens** - `2764dd9` (`test`)
2. **Task 1 GREEN: Extend the fast contrast gate for named AA tokens** - `aa3bfed` (`feat`)
3. **Task 2: Route muted text and selected violet fills through scoped AA tokens** - `4d6fcb3` (`feat`)
4. **Task 3: Document Phase 132 contrast floors in lockstep** - `8c5623e` (`docs`)

## Files Created/Modified

- `examples/scrypath_ecommerce/contrast-checker.mjs` - Added `primary-strong` parsing/guarding, text-threshold pair evaluation, and named muted-token lockstep validation.
- `scrypath_ops/assets/css/contrast-pairs.mjs` - Changed the six readable muted selectors to `css_var: "ops-text-muted"` at `alpha: 0.64`; raw/decorative entries remain in the existing form.
- `scrypath_ops/assets/css/app.css` - Added both theme tokens and routed in-scope muted/selected primary selectors without changing Phoenix components, layout, copy, spacing, motion, `--color-primary`, or `--color-accent`.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` - Added `## A11y contrast floors -- Phase 132` and documented exact token values, allowed consumers, and gate posture.

## Decisions Made

- Used one named muted floor, `--ops-text-muted`, at `64%`; the fast checker reports `AA failures:  0`, so no second muted tier was needed.
- Kept decorative violet intact by leaving `--color-primary` and `--color-accent` unchanged and using `--color-primary-strong` only for text-bearing selected fills.
- Preserved the Phase 132/135 boundary by fixing header and shell muted text via scoped CSS token routing only, with no chrome/depth/layout changes.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix verify.opsui` emitted transient Postgrex `too_many_connections` log lines during the test run, but the command exited 0 with `129 tests, 0 failures`.
- The working tree had pre-existing untracked generated/static files and a pre-existing `.planning/STATE.md` modification before execution; these were left in place except for planned GSD state updates.

## Verification

- `node --check examples/scrypath_ecommerce/contrast-checker.mjs` - exit 0.
- `node examples/scrypath_ecommerce/contrast-checker.mjs --self-test` - `self-test passed`.
- `cd examples/scrypath_ecommerce && CONTRAST_REPORT_DIR=test-results/contrast/phase132-token node contrast-checker.mjs` - `Contrast check: PASS`, `AA failures:  0`, `AAA advisory: 19` after the post-review named-token guard fix added the two shell/header muted consumers.
- `cd scrypath_ops && mix assets.build && mix verify.opsui` - Tailwind/daisyUI build completed; ExUnit completed `2 doctests, 129 tests, 0 failures`.

## Known Stubs

None. Stub-pattern scan found only internal checker accumulator initializers and an existing skeleton-loading comment; no UI-rendered placeholder data was introduced.

## Threat Flags

None. The plan introduced no new network endpoints, auth paths, file-access trust boundaries, or schema changes beyond the planned CSS/checker/reporting surfaces.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 can run the browser/admin contrast hard gate against the source-remediated tokens. The fast checker is already green with zero AA failures and the token catalog is in lockstep with the CSS and manifest.

## Self-Check: PASSED

- Files found: `132-01-SUMMARY.md`, `contrast-checker.mjs`, `contrast-pairs.mjs`, `app.css`, `DESIGN-TOKENS.md`.
- Commits found: `2764dd9`, `aa3bfed`, `4d6fcb3`, `8c5623e`.

---
*Phase: 132-a11y-contrast-remediation-both-themes-hard-gate-g*
*Completed: 2026-06-04*
