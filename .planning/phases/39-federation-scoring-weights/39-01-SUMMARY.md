---
phase: 39-federation-scoring-weights
plan: 01
subsystem: search
tags: [federation, search_many, elixir]

requires: []
provides:
  - Quad-shaped Entries.normalize/2 with isolated federation_weight
  - search_many pipeline carrying fed_opts through native backends
  - Hard error when weights require search_many/2 but backend lacks it
affects: [39-02]

tech-stack:
  added: []
  patterns:
    - "Per-entry fed_opts keyword beside %Query{} for search_many rows"

key-files:
  created: []
  modified:
    - lib/scrypath/multi_search/entries.ex
    - lib/scrypath/search.ex
    - lib/scrypath/backend.ex
    - lib/scrypath/meilisearch.ex
    - test/support/fake_backend.ex
    - test/scrypath/multi_search/entries_test.exs
    - test/scrypath/search_many_test.exs

key-decisions:
  - "Finite-float check uses NaN self-inequality plus abs bound against IEEE max double (OTP 27-safe)."
  - "Meilisearch ignores fed_opts in this plan; Plan 02 wires federationOptions JSON."

patterns-established:
  - "Backend search_many rows are {schema, %Query{}, fed_opts}."

requirements-completed: [FED-01]

duration: 25min
completed: 2026-04-20
---

# Phase 39: Federation scoring & weights — Plan 01 Summary

**search_many entries now carry validated `federation_weight` in `fed_opts`, and weighted calls refuse silent sequential merge when the backend lacks native `search_many/2`.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-04-20
- **Tasks:** 2

## Accomplishments

- `Entries.normalize/2` returns four-tuples; `:federation_weight` never reaches NimbleOptions merge keywords.
- `Search` validates quads into `{schema, %Query{}, fed_opts}` and errors with `{:federation_merge_requires_native_search_many, %{backend: _}}` when appropriate.
- `Backend`, `Meilisearch`, and `FakeBackend` accept three-element `search_many` rows (fed_opts ignored on wire until Plan 02).

## Task Commits

1. **Task 1: Quads in Entries.normalize/2 + weight validation** — `118368e` (feat)
2. **Task 2: Backend callback + Search quad pipeline + sequential guard** — `4cde8fc` (feat)

## Files Created/Modified

- `lib/scrypath/multi_search/entries.ex` — quad normalization and weight validation
- `lib/scrypath/search.ex` — quad validation, fed_opts guard, native 3-tuple dispatch
- `lib/scrypath/backend.ex` — `search_many` callback signature + docs
- `lib/scrypath/meilisearch.ex` — destructures `{schema, query, fed_opts}` (fed_opts ignored)
- `test/support/fake_backend.ex` — same tuple shape
- `test/scrypath/multi_search/entries_test.exs` — quad assertions and invalid weight cases
- `test/scrypath/search_many_test.exs` — SequentialOnlyBackend guard tests

## Verification

- `mix compile --warnings-as-errors` — PASS
- `mix test test/scrypath/multi_search/entries_test.exs test/scrypath/search_many_test.exs` — PASS
- Full `mix test` — PASS (386 tests)

## Self-Check: PASSED
