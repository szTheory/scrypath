---
phase: 82-docs-examples-and-drift-protection
plan: 01
subsystem: docs
tags: [elixir, ex_doc, docs, phoenix, query-params]

# Dependency graph
requires: []
provides:
  - Canonical request-edge guide for the v1.21 public story
  - Root README and moduledoc wayfinding into the shared guide
  - ExDoc extras/group wiring for the request-edge guide
affects:
  - Phase 82 plan 02 Phoenix guide rewrites
  - Phase 82 plan 03 docs-contract drift protection

# Tech tracking
tech-stack:
  added: [guides/request-edge-search.md]
  patterns: [single-source request-edge guide, root-doc wayfinding, ExDoc guide grouping]

key-files:
  created: [.planning/phases/82-docs-examples-and-drift-protection/82-01-SUMMARY.md, guides/request-edge-search.md]
  modified: [README.md, lib/scrypath.ex, mix.exs, guides/overview.md, guides/getting-started.md, guides/golden-path.md]

key-decisions:
  - "Keep the shared request-edge story in one canonical guide instead of duplicating it across README and Phoenix guides."
  - "Keep `Scrypath.search/3` and app contexts canonical while presenting `Scrypath.Phoenix` as optional request-edge glue only."

patterns-established:
  - "Pattern 1: root docs summarize the boundary and point to one canonical guide instead of restating the full contract."
  - "Pattern 2: ExDoc extras and guide groups must expose new canonical public guides directly."

requirements-completed: [DOC-01]

# Metrics
duration: 18m
completed: 2026-05-23
---

# Phase 82: Docs, examples, and drift protection Summary

**One canonical request-edge guide now anchors the v1.21 public story, with README and ExDoc reduced to wayfinding surfaces around it**

## Performance

- **Duration:** 18m
- **Started:** 2026-05-23T12:10:00Z
- **Completed:** 2026-05-23T12:28:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `guides/request-edge-search.md` as the single canonical guide for browser params, `Scrypath.QueryParams`, optional `Scrypath.Phoenix`, and context-owned `Scrypath.search/3`.
- Rewired README, `Scrypath` moduledoc, getting-started, golden-path, and overview docs to route readers into that guide instead of repeating stale or contradictory boundary language.
- Wired the guide into `mix.exs` ExDoc extras and guide groups so the public docs surface matches the intended teaching flow.

## Task Commits

No new task commit was created during this execution pass. The target changes were already present in the working tree and were verified in place.

## Files Created/Modified

- `guides/request-edge-search.md` - canonical v1.21 request-edge guide
- `README.md` - root wayfinding to the canonical guide
- `lib/scrypath.ex` - compact moduledoc lobby with optional Phoenix wording
- `mix.exs` - ExDoc extras/group registration for the guide
- `guides/overview.md` - guide table-of-contents entry for request-edge docs
- `guides/getting-started.md` - start-here pointer into the shared request-edge guide
- `guides/golden-path.md` - linear onboarding pointer into the shared request-edge guide

## Decisions Made

- Kept `%Scrypath.Query{}` mentioned only as a non-public reminder inside the canonical guide.
- Removed stale phase-80 wording from the root moduledoc instead of preserving duplicate contract explanation there.

## Deviations from Plan

None - the checked-out changes match the plan intent and acceptance criteria.

## Issues Encountered

- The repository was already dirty on Phase 82 target files before execution began, so this run verified and documented the in-place changes instead of replaying them from a clean branch.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 1 is complete and exposes the shared request-edge guide for all downstream Phoenix docs.
- Phase 82 plan 02 can safely treat the canonical guide as the single source of truth.

---
*Phase: 82-docs-examples-and-drift-protection*
*Completed: 2026-05-23*
