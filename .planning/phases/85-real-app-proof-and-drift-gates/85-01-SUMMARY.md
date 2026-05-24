---
phase: 85-real-app-proof-and-drift-gates
plan: 01
subsystem: docs
tags: [docs, exdoc, composition, metadata, phoenix]
requires: []
provides:
  - canonical phase85 composition and metadata guide
  - root and exdoc wayfinding into the new guide
  - explicit non-goal authority for the real-app composition story
affects: [phase-85, docs, exdoc]
tech-stack:
  added: []
  patterns: [single canonical guide, short-doc wayfinding, bounded non-goal authority]
key-files:
  created: [guides/composing-real-app-search.md]
  modified: [guides/overview.md, guides/request-edge-search.md, README.md, lib/scrypath.ex, mix.exs]
key-decisions:
  - "Made one new guide the sole authority for composition, metadata, and compose_many semantics instead of spreading that story across README and Phoenix guides."
  - "Placed the guide immediately after request-edge docs in ExDoc so the public reading order stays params first, composition second, framework proofs third."
patterns-established:
  - "Short docs link into the canonical guide instead of becoming alternate authorities."
requirements-completed: [DOC-01, DOC-02]
duration: 1 session
completed: 2026-05-23
---

# Phase 85 Plan 01: Real-App Proof And Drift Gates Summary

**The canonical Phase 85 docs lane now exists and the short docs route readers into it**

## Accomplishments

- Added `guides/composing-real-app-search.md` as the canonical authority for `defaults`, `fixed`, metadata reflection, `compose_many/2`, and Phase 85 non-goals.
- Reordered ExDoc and guide wayfinding so readers move from request-edge normalization into composition before the Phoenix proof surfaces.
- Tightened README and the root moduledoc to point at the canonical guide instead of restating the full milestone semantics.

## Files Created/Modified

- `guides/composing-real-app-search.md` - Canonical real-app composition and metadata guide.
- `guides/overview.md` - Guide index and reading order updated for the new lane.
- `guides/request-edge-search.md` - Added the bounded handoff into the composition guide.
- `README.md` - Added root wayfinding for the real-app composition story.
- `lib/scrypath.ex` - Updated lobby docs to point `Scrypath.Composition` and `Scrypath.Metadata` at the canonical guide.
- `mix.exs` - Added the guide to ExDoc extras and ordering.

## Verification

- `mix test test/scrypath/docs_contract_test.exs`
- `mix docs --warnings-as-errors`

## Task Commits

No commits were created during this execution run.

## Issues Encountered

None.

## Next Phase Readiness

The canonical docs authority is in place and ready for focused contract coverage plus the Phase 85 verify task.

---
*Phase: 85-real-app-proof-and-drift-gates*
*Completed: 2026-05-23*
