---
phase: 112-public-website-and-docs-truth-alignment
plan: "03"
subsystem: ui
tags: [website, docs, routing, scope-policy]
requires:
  - phase: 112-01
    provides: canonical scope/reopen policy authority and route targets
provides:
  - Homepage claim envelope aligned to fixed Ecto-native wording
  - Docs map explicit routes to README and scope/reopen policy
  - Evaluate and operators pages concise scope/visibility truth with evidence routing
affects: [WEB-01, WEB-02, SCOPE-01, public-website-copy]
tech-stack:
  added: []
  patterns: [route-first website copy, concise policy routing, visibility honesty]
key-files:
  created: []
  modified:
    - website/src/pages/index.html
    - website/src/pages/docs.html
    - website/src/pages/evaluate.html
    - website/src/pages/operators.html
key-decisions:
  - "Kept website pages as route-map surfaces and added policy/README authority links instead of procedural expansion."
  - "Preserved explicit visibility-honesty language while routing scope pressure to canonical policy and outside-adopter evidence."
patterns-established:
  - "Homepage first mention uses the fixed descriptor: Scrypath, the Ecto-native search indexing library."
  - "Website route pages remain concise and delegate detailed procedure to README/guides."
requirements-completed: [WEB-01, WEB-02, SCOPE-01]
duration: 24 min
completed: 2026-06-01
---

# Phase 112 Plan 03: Tighten website route-map copy and add README/scope-policy routes without expanding the site Summary

**Website route pages now use the fixed Ecto-native claim envelope, explicit README/scope-policy authority links, and concise visibility/scope truth without becoming a second docs system.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-06-01T16:18:00Z
- **Completed:** 2026-06-01T16:42:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Updated homepage copy to the fixed descriptor while retaining required capability nouns and concise route-map depth.
- Added explicit README and scope/reopen policy routes to the docs map while preserving guide/example/support link structure.
- Updated evaluate and operators pages with evidence-gated reopen truth and preserved visibility honesty language.

## Task Commits

Each task was committed atomically:

1. **Task 1: Align the homepage and docs map to the fixed claim envelope and README route** - `bb5ec79` (feat)
2. **Task 2: Keep evaluate and operators pages concise while making scope and visibility truth explicit** - `77eae6a` (feat)

## Files Created/Modified
- `website/src/pages/index.html` - Fixed first-mention claim envelope and concise lede wording.
- `website/src/pages/docs.html` - Added explicit README and scope-policy authority routes.
- `website/src/pages/evaluate.html` - Added concise reopen-trigger language and scope-policy route.
- `website/src/pages/operators.html` - Preserved exact visibility-honesty sentence and added scope/evidence routing sentence.

## Decisions Made
- Kept all changes within existing page roles and route-map structure.
- Reused existing layout/footer authority links for Hex/HexDocs/GitHub; no layout changes.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 112 plan 03 website copy/routing constraints are complete and verified by website build/check.
- Ready for downstream phase 112 contract-proof plan execution.

## Self-Check: PASSED

---
*Phase: 112-public-website-and-docs-truth-alignment*
*Completed: 2026-06-01*
