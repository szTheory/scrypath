---
phase: 39-federation-scoring-weights
plan: 02
subsystem: search
tags: [meilisearch, federation, docs]

requires:
  - phase: 39-01
    provides: Quad entries and fed_opts on search_many rows
provides:
  - Meilisearch federationOptions.weight JSON
  - merge_hit_order + merge_projection/1 on MultiSearchResult
  - FakeBackend deterministic weighted ordering tests
  - Public docs and multi-index guide § Federation weights
affects: [40, 41]

tech-stack:
  added: []
  patterns:
    - "Optional merge_hit_order derived only from flat federated responses"

key-files:
  created:
    - test/scrypath/meilisearch/federated_decode_test.exs
  modified:
    - lib/scrypath/meilisearch.ex
    - lib/scrypath/meilisearch/federated_decode.ex
    - lib/scrypath/multi_search_result.ex
    - lib/scrypath/search.ex
    - lib/scrypath.ex
    - test/support/fake_backend.ex
    - test/scrypath/search_many_test.exs
    - guides/multi-index-search.md
    - test/scrypath/docs_contract_test.exs

key-decisions:
  - "merge_hit_order decode errors map to nil trace so transport success is preserved."

patterns-established:
  - "merge_projection/1 pairs merge order with hydrated hit maps from by_schema."

requirements-completed: [FED-01]

duration: 35min
completed: 2026-04-20
---

# Phase 39: Federation scoring & weights — Plan 02 Summary

**Meilisearch multi-search now sends per-query `federationOptions.weight`, exposes merge trace metadata on `%MultiSearchResult{}`, and documents how merge weights relate to per-schema relevance.**

## Task Commits

1. **Task 1: Meilisearch `federationOptions`** — `d11add2` (feat)
2. **Task 2: Merge trace + `merge_projection/1`** — `39e62fb` (feat)
3. **Task 3: FakeBackend ordering + docs + tests** — `a9e794d` (feat)

## Verification

- `mix compile --warnings-as-errors` — PASS
- `mix test test/scrypath/meilisearch/federated_decode_test.exs test/scrypath/search_many_test.exs` — PASS
- Full `mix test` — PASS

## Self-Check: PASSED
