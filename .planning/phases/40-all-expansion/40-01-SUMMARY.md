---
phase: 40-all-expansion
plan: 01
subsystem: search
tags: [search_many, federation, multi_index]

requires: []
provides:
  - AllExpansion.expand/2 before Entries.normalize
  - global_schemas optional runtime option
  - search_many telemetry schema_count post-expansion
affects: [41]

tech-stack:
  added: []
  patterns:
    - ":all entries splice from global_schemas or otp_app env allowlist"

key-files:
  created:
    - lib/scrypath/multi_search/all_expansion.ex
  modified:
    - lib/scrypath/options.ex
    - lib/scrypath/search.ex

key-decisions:
  - "Validate :all tuple shapes before allowlist resolution so malformed entries return malformed_entry instead of missing_otp_app."

patterns-established:
  - "global_schemas in shared_opts replaces :scrypath_global_search_schemas for that call when the key is present."

requirements-completed: [FED-02]

duration: 25min
completed: 2026-04-20
---

# Phase 40: `:all` expansion — Plan 01 Summary

**`search_many/2` now expands `{:all, text}` / `{:all, text, keyword}` into concrete schema tuples using `global_schemas:` or application env before normalization and backend I/O.**

## Task Commits

1. **Task 1–3: runtime option, AllExpansion, search_many wiring** — `d66edb8` (feat)

## Verification

- `mix compile --warnings-as-errors` — PASS
- `mix test test/scrypath/multi_search/entries_test.exs test/scrypath/search_many_test.exs` — PASS

## Self-Check: PASSED
