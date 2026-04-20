---
status: passed
phase: 43-per-query-relevance-runtime
completed: 2026-04-20
---

# Phase 43 verification

## Automated

- `mix test` — full library suite (integration excluded by default) — **passed**
- `mix verify.phase43` — doc contracts + per-query / search / search_many slice — **passed**

## Must-haves (traceability)

- **TUNE-PQ-01**: `:per_query` allowlist, `%Query{}` field, Meilisearch JSON projection,
  `search_many` inner `Map.merge` for both-side `:per_query`, telemetry
  `ranking_score_details` when `show_ranking_score_details: true` — **verified via tests**
- **TUNE-PQ-02**: Focused tests + `mix verify.phase43` — **verified**
- **TUNE-PQ-03**: `@verify_phase43` pin, CI step, CONTRIBUTING mentions, public `@doc` — **verified**

## Human verification

None required for this phase.

## Gaps

None.
