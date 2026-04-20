---
status: passed
phase: 39
verified: 2026-04-20
---

# Phase 39 verification

## Goal

Deliver **FED-01** federation weighting for `search_many/2`: validated per-entry
weights, native Meilisearch wire support, predictable merged ordering metadata, and
documentation—without breaking per-schema `%SearchResult{}` usage.

## Must-haves (from plans)

| Item | Evidence |
|------|----------|
| Quads + weight validation | `Entries.normalize/2`, `entries_test.exs` |
| Native `search_many` fed_opts rows | `Backend`, `Search`, `Meilisearch`, `FakeBackend` |
| Error on weighted + sequential-only backend | `search_many_test.exs` |
| `federationOptions` JSON only when weight set | `meilisearch.ex`, grep |
| `merge_hit_order` + `merge_projection/1` | `FederatedDecode`, `MultiSearchResult`, tests |
| Guide `## Federation weights` | `guides/multi-index-search.md` |

## Automated

- `mix compile --warnings-as-errors` — pass
- `mix test` — pass (391 tests, 9 excluded integration)

## Human verification

None required for this phase.

## Gaps

None identified.
