---
phase: 84-metadata-reflection-and-multi-search-parity
plan: 03
subsystem: api
tags: [elixir, ecto, metadata, composition, docs]
requires:
  - phase: 84-01
    provides: public metadata and lowering contract
  - phase: 84-02
    provides: focused verification lane
provides:
  - green phase84 metadata and multi-search implementation
  - docs and contract alignment for honest controls
  - passing focused and fast verification evidence
affects: [phase-84, metadata, composition, docs, verification]
tech-stack:
  added: []
  patterns: [validator-backed reflection, entry-scoped parity over search_many]
key-files:
  created: []
  modified: [lib/scrypath.ex, lib/scrypath/metadata.ex, lib/scrypath/metadata/capabilities.ex, lib/scrypath/metadata/resolve.ex, lib/scrypath/composition.ex, lib/scrypath/composition/multi.ex, test/scrypath/metadata_test.exs, test/scrypath/composition_many_test.exs, test/scrypath/docs_contract_test.exs, guides/multi-index-search.md, guides/faceted-search-with-phoenix-liveview.md]
key-decisions:
  - "Normalized unsupported search fields into field-scoped metadata instead of turning reflection questions into runtime failures."
  - "Kept shared per_query defaults in shared opts while emitting entry-local deltas from compose_many lowering."
patterns-established:
  - "Reflection reports capability truth and resolved state separately."
  - "compose_many preserves top-level shared-vs-entry semantics while staying data-only."
requirements-completed: [META-01, META-02, META-03, MSCH-01, MSCH-02]
duration: 30min
completed: 2026-05-23
---

# Phase 84 Plan 03: Metadata Reflection And Multi-Search Parity Summary

**Metadata reflection and multi-search lowering are implemented, documented, and verified against both the focused phase gate and the fast suite**

## Performance

- **Duration:** 30 min
- **Started:** 2026-05-23T19:54:13Z
- **Completed:** 2026-05-23T20:24:13Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments
- Implemented declaration-backed capability reflection and resolved-state overlays for single-search and entry-scoped multi-search flows.
- Implemented `compose_many/2` lowering over the existing `search_many/2` tuple/shared-option contract, including explicit rejection of shared `fixed`.
- Proved the slice with `mix verify.phase84` and `mix test --exclude integration --exclude docs_contract`.

## Task Commits

No commits were created during this execution run.

## Files Created/Modified
- `lib/scrypath/metadata/capabilities.ex` - Capability derivation from declarations and validator allowlists.
- `lib/scrypath/metadata/resolve.ex` - Field-scoped `applied/defaulted/fixed/unsupported` reflection logic.
- `lib/scrypath/composition/multi.ex` - Entry composition plus shared-default lowering.
- `test/scrypath/metadata_test.exs` - Metadata contract proof.
- `test/scrypath/composition_many_test.exs` - Lowering parity proof.
- `test/scrypath/docs_contract_test.exs` - Public-language proof.
- `guides/multi-index-search.md` - Honest lowering story and non-goals.
- `guides/faceted-search-with-phoenix-liveview.md` - Metadata-driven control guidance without generated widgets.

## Decisions Made

- Reflected unsupported capabilities as inspectable plain data instead of error tuples.
- Preserved `:all` as a deferred entry rather than pretending it already has schema-specific capabilities.
- Normalized shared `per_query` output so `to_search_many_args/1` emits only entry-local deltas.

## Deviations from Plan

### Auto-fixed Issues

**1. ExDoc warning cleanup**
- **Found during:** Task 3 (phase gate)
- **Issue:** Public `Scrypath.Composition` docs referenced hidden internal types from `Scrypath.Composition.Multi`.
- **Fix:** Moved the public-facing type definitions back into `Scrypath.Composition`.
- **Files modified:** `lib/scrypath/composition.ex`
- **Verification:** `mix verify.phase84`

---

**Total deviations:** 1 auto-fixed (documentation warning cleanup)
**Impact on plan:** No scope change; the fix was required to keep the docs gate green.

## Issues Encountered

The first focused test run exposed an argument-order bug in the metadata facade and a shared `per_query` lowering issue. Both were fixed immediately and reverified through the phase gate.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 84 is complete and ready for the next milestone step with focused proofs and the fast non-integration suite green.

---
*Phase: 84-metadata-reflection-and-multi-search-parity*
*Completed: 2026-05-23*
