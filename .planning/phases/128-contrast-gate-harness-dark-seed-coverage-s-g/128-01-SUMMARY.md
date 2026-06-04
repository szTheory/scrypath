---
phase: 128-contrast-gate-harness-dark-seed-coverage-s-g
plan: "01"
subsystem: testing
tags: [axe-core, playwright, wcag, contrast, a11y, npm]

# Dependency graph
requires: []
provides:
  - "@axe-core/playwright devDependency installed in examples/scrypath_ecommerce"
  - "test:e2e:admin-contrast npm script pointing to admin_contrast_matrix.spec.ts"
  - "scrypath_ops/assets/css/contrast-pairs.mjs — 13-entry muted-alpha manifest (D-11)"
affects:
  - "128-02 — contrast-checker.mjs imports contrast-pairs.mjs via dynamic import"
  - "128-03 — admin_contrast_matrix.spec.ts imports AxeBuilder from @axe-core/playwright"

# Tech tracking
tech-stack:
  added: ["@axe-core/playwright@^4.11.3 (devDependency — Dequelabs monorepo, no postinstall)"]
  patterns:
    - "muted-alpha manifest: ESM .mjs beside DESIGN-TOKENS.md; token names only, no hex (D-10)"
    - "D-11: MUTED_PAIRS export — selector/alpha/fg_token/bg_token/role/note per entry"
    - "D-12: sRGB compositing documented: out = fg·α + bg·(1−α) per channel"
    - "D-15: lockstep guard input — D-15 checker in Plan 02 imports this manifest"

key-files:
  created:
    - "scrypath_ops/assets/css/contrast-pairs.mjs — 13-entry MUTED_PAIRS manifest"
  modified:
    - "examples/scrypath_ecommerce/package.json — @axe-core/playwright devDep + test:e2e:admin-contrast script"
    - "examples/scrypath_ecommerce/package-lock.json — lockfile updated by npm install"

key-decisions:
  - "D-10: app.css is single source of truth for hex values; manifest references token names only"
  - "D-11: 13 entries (12 contrast-gated + 1 decorative for .ops-trail__sep)"
  - "D-12: sRGB compositing matches axe-core behavior so fast checker and browser gate agree"
  - ".ops-badge-neutral uses bg_token base-200 (badge bg composites over base-200, not base-100)"
  - ".ops-handoff__eyebrow role=large (uppercase + font-weight 700 qualifies as WCAG large text)"

patterns-established:
  - "contrast-pairs.mjs: token-name manifest with role field for D-14 threshold routing"
  - "decorative role exclusion: .ops-trail__sep alpha 35% excluded from contrast gate"

requirements-completed:
  - CONTRAST-HARNESS-01

# Metrics
duration: 4min
completed: 2026-06-04
---

# Phase 128 Plan 01: Axe Dependency + Muted-Alpha Manifest Summary

**@axe-core/playwright 4.11.3 installed as devDep, test:e2e:admin-contrast wired, and 13-entry MUTED_PAIRS manifest created as the D-15 lockstep guard input for Plans 02 and 03**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-06-04T07:27:00Z
- **Completed:** 2026-06-04T07:31:07Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Installed @axe-core/playwright@^4.11.3 (official Dequelabs monorepo, no postinstall, devDep only)
- Added test:e2e:admin-contrast script following exact test:e2e:admin-matrix shape
- Created contrast-pairs.mjs with all 13 muted-alpha entries from D-11 spec
- Verified AxeBuilder is importable as `function`, MUTED_PAIRS exports 13 entries, exactly 1 decorative entry

## Task Commits

Each task was committed atomically:

1. **Task 1: Install @axe-core/playwright and add test:e2e:admin-contrast npm script** - `af1529e` (feat)
2. **Task 2: Create contrast-pairs.mjs muted-alpha manifest (D-11)** - `6da526b` (feat)

## Files Created/Modified
- `examples/scrypath_ecommerce/package.json` - Added @axe-core/playwright devDep + test:e2e:admin-contrast script
- `examples/scrypath_ecommerce/package-lock.json` - Updated by npm install
- `scrypath_ops/assets/css/contrast-pairs.mjs` - New: 13-entry MUTED_PAIRS muted-alpha manifest

## Decisions Made
- .ops-badge-neutral uses `bg_token: "base-200"` (badge background is base-200 ~74%, not base-100) per plan acceptance criteria
- .ops-handoff__eyebrow uses `role: "large"` (uppercase + font-weight 700 qualifies as WCAG large text — AA 3.0 threshold)
- .ops-trail__sep uses `role: "decorative"` — excluded from D-15 checker evaluation, no threshold applied
- Comment in file header used `decorative` (no double quotes) in field reference to ensure `grep -c '"decorative"'` returns exactly 1

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Minor: The comment block initially used `"decorative"` (double-quoted) in the field reference table, which would have caused `grep -c '"decorative"'` to return 2 instead of 1. Fixed by removing the quotes from the comment text, leaving only the actual `role: "decorative"` data value as the sole match.

## Known Stubs

None — this plan creates a complete data manifest and installs a package. No UI rendering, no placeholder data.

## Threat Flags

None — @axe-core/playwright is verified as the official Dequelabs monorepo package (T-128-01 accepted per threat model). contrast-pairs.mjs is read-only static data with no I/O, network, or user input.

## Next Phase Readiness
- Plan 02 (contrast-checker.mjs) can now import MUTED_PAIRS via `import('./../../scrypath_ops/assets/css/contrast-pairs.mjs')`
- Plan 03 (admin_contrast_matrix.spec.ts) can now import AxeBuilder from `@axe-core/playwright`
- Zero CSS token changes — this phase measured only, no design-system mutations

## Self-Check

- `scrypath_ops/assets/css/contrast-pairs.mjs` exists: FOUND
- `examples/scrypath_ecommerce/package.json` contains @axe-core/playwright: FOUND
- `examples/scrypath_ecommerce/package.json` contains test:e2e:admin-contrast: FOUND
- Task 1 commit af1529e: FOUND
- Task 2 commit 6da526b: FOUND

## Self-Check: PASSED

---
*Phase: 128-contrast-gate-harness-dark-seed-coverage-s-g*
*Completed: 2026-06-04*
