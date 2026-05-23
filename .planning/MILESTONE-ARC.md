# Milestone Arc

## Active arc: Batteries-Included Search Modules

**Status:** active - `v1.21` shipped on 2026-05-23 after opening on 2026-05-22; `v1.22` remains the next candidate  
**Started:** 2026-05-07

## Why this arc exists

Scrypath already proved a credible Meilisearch-first, Ecto-native indexing and sync story. The next leverage move is to make app-facing search ergonomics feel substantially more complete for Phoenix and Ecto teams without abandoning the existing operational honesty.

The target is not hidden callback magic. The target is a thin, explicit layer that removes repeated context/query/params boilerplate while preserving the current Scrypath runtime as the canonical engine.

## Arc goals

- Make common Phoenix/Ecto search flows declarative, validated, and low-boilerplate.
- Keep contexts as the application boundary for both reads and writes.
- Keep `use Scrypath` metadata-only on schemas.
- Normalize browser-shaped params once at the edge, then call the existing `Scrypath.search/3` path.
- Preserve explicit sync, visibility, and backend semantics.

## Arc non-goals

- No schema-generated runtime verbs.
- No public multi-backend expansion in this arc.
- No Phoenix hard dependency in core search abstractions.
- No hidden sync/reindex/retry automation.
- No vendor-dashboard or OPSUI-depth milestone as the headline deliverable here.

## Milestone sequence

### v1.20 — Search Module Foundation

- **Status:** shipped on 2026-05-08
- Context-owned `Scrypath.SearchModule`
- Stable param normalization for text, filter, sort, page, and facet request/filter inputs
- Structured param errors
- `search/2`, `search!/2`, and `search_args/2` over the current `Scrypath.search/3` runtime

### v1.21 — Query Toolkit And Phoenix Edge Helpers

- **Status:** shipped on 2026-05-23
- Public normalization/casting helpers behind the search-module layer
- Optional Phoenix-facing helpers for URL/form/LiveView round-tripping
- No Phoenix coupling in the core runtime
- Locked as a narrow-balanced slice: framework-light toolkit first, thin Phoenix wrappers second, contexts still canonical

### v1.22 — Composition And Real-App Depth

- **Status:** next candidate
- Reusable presets/scopes where they help real app flows
- Composition support aligned with `search_many/2`
- Stronger UI metadata exposure for declared filters, sorts, facets, and paging

## Planning posture for future milestone opens

- Start from this arc before inventing a new milestone theme.
- Prefer parallel research and synthesis before asking the user for milestone-shaping input.
- Ask the user only on high-impact product or architecture decisions when repo and ecosystem evidence do not already point clearly enough.
