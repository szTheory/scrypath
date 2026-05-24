---
phase: 84-metadata-reflection-and-multi-search-parity
plan: 01
subsystem: api
tags: [elixir, ecto, metadata, search_many, docs]
requires: []
provides:
  - declaration-backed metadata reflection entrypoints
  - public multi-search lowering helpers
  - bounded docs language for honest controls and host-owned concerns
affects: [phase-84, metadata, composition, docs]
tech-stack:
  added: []
  patterns: [plain-data metadata envelopes, entry-scoped multi-search lowering]
key-files:
  created: [lib/scrypath/metadata.ex, lib/scrypath/metadata/capabilities.ex, lib/scrypath/metadata/resolve.ex, lib/scrypath/composition/multi.ex]
  modified: [lib/scrypath.ex, lib/scrypath/composition.ex, guides/multi-index-search.md, guides/faceted-search-with-phoenix-liveview.md]
key-decisions:
  - "Kept metadata function-based and data-only under Scrypath.Metadata instead of adding schema-generated APIs."
  - "Lowered multi-search composition into the existing tuple/shared-option contract instead of creating a second executor surface."
patterns-established:
  - "Capabilities derive from schema declarations plus validator allowlists."
  - "Multi-search reflection stays entry-scoped, with :all marked deferred until expansion."
requirements-completed: [META-01, META-02, META-03, MSCH-01, MSCH-02]
duration: 35min
completed: 2026-05-23
---

# Phase 84 Plan 01: Metadata Reflection And Multi-Search Parity Summary

**Declaration-backed metadata reflection and multi-search lowering helpers landed without widening the runtime boundary**

## Performance

- **Duration:** 35 min
- **Started:** 2026-05-23T19:49:13Z
- **Completed:** 2026-05-23T20:24:13Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Added `Scrypath.schema_capabilities/1`, `reflect_search/2`, and `reflect_search_many/2` over one bounded metadata envelope.
- Added `Scrypath.Composition.compose_many/2`, `compose_many!/2`, and `to_search_many_args/1` as lowering helpers over existing `search_many/2` semantics.
- Updated the root docs and guides to teach honest controls, host-owned concerns, and no generated UI story.

## Task Commits

No commits were created during this execution run.

## Files Created/Modified
- `lib/scrypath/metadata.ex` - Public metadata facade for capability and resolved-state reflection.
- `lib/scrypath/metadata/capabilities.ex` - Declaration-backed capability derivation.
- `lib/scrypath/metadata/resolve.ex` - Resolved `applied/defaulted/fixed/unsupported` overlay logic.
- `lib/scrypath/composition/multi.ex` - Multi-search composition lowering and tuple emission helpers.
- `lib/scrypath.ex` - Root entrypoints and bounded public moduledoc language.
- `guides/multi-index-search.md` - Public lowering and boundary-honesty guide text.
- `guides/faceted-search-with-phoenix-liveview.md` - Metadata-driven honest controls guidance.

## Decisions Made

- Kept the public metadata surface plain-data and framework-agnostic.
- Reused the Phase 83 composition vocabulary instead of inventing new resolved-state names.
- Rejected shared `fixed` semantics for multi-search composition.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 1 contract work is in place and ready for focused tests plus verify wiring.

---
*Phase: 84-metadata-reflection-and-multi-search-parity*
*Completed: 2026-05-23*
