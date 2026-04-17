---
phase: 21-multi-index-search
plan: "03"
subsystem: search
tags: [multi-search, orchestration, telemetry]
key-files:
  created:
    - test/scrypath/search_many_test.exs
  modified:
    - lib/scrypath/search.ex
    - lib/scrypath.ex
---

## Summary

Implemented `Scrypath.Search.search_many/2`, `search_many!/2`, public delegates on `Scrypath`, native vs sequential backend dispatch, federated decode → decorate, `Task.async_stream` hydration with timeout → `:hydration_timeout` failures, `{:error, {:all_failed, _}}` when no successes remain, telemetry span `[:scrypath, :search_many]` plus `:partial` execute, and regression tests.

## Self-Check: PASSED

- `mix test test/scrypath/search_many_test.exs`
- `mix test --exclude integration`

## Deviations

None.
