---
phase: 43-per-query-relevance-runtime
plan: 01
subsystem: search
tags: [meilisearch, per_query, telemetry, nimble_options]

requires: []
provides:
  - Allowlisted :per_query search options validated and carried on %Scrypath.Query{}
  - Meilisearch JSON projection for rankingScoreThreshold / showRankingScore / showRankingScoreDetails
  - Telemetry ranking_score_details flag when show_ranking_score_details is enabled

key-files:
  created:
    - test/scrypath/per_query_tuning_test.exs
  modified:
    - lib/scrypath/options.ex
    - lib/scrypath/query.ex
    - lib/scrypath/meilisearch/query.ex
    - lib/scrypath/search.ex
    - test/scrypath/search_test.exs
    - test/scrypath/meilisearch/query_test.exs
    - test/scrypath/backend_test.exs

key-decisions:
  - "Omit boolean per_query JSON keys when false to minimize Meilisearch payload"
  - "Strip :per_query from runtime_opts so validate_runtime_options! stays unchanged"

requirements-completed:
  - TUNE-PQ-01

duration: 20min
completed: 2026-04-20
---

# Phase 43 Plan 01 Summary

**Shipped Plane B `:per_query` allowlisting through validation, `%Query{}`, Meilisearch `to_payload/1`, and search telemetry** so ranking-score knobs from the locked pipeline guide reach the wire with explicit operator visibility when expensive details are enabled.

## Task Commits

1. **Task 1 (43-01-01): Options, Query, Meilisearch payload, and unit tests** — `bfb4682` (feat)
2. **Task 2 (43-01-02): Telemetry metadata for ranking-score details** — `2a4182c` (feat)

## Self-Check: PASSED

- `mix test test/scrypath/per_query_tuning_test.exs test/scrypath/search_test.exs` exits 0.
- `mix test` full suite exits 0.
- `rg 'Mix\.env' lib/scrypath/search.ex` finds no matches.
