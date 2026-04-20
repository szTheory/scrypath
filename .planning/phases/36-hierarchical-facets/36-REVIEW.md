---
status: clean
phase: 36-hierarchical-facets
reviewer: orchestrator-inline
depth: quick
completed: 2026-04-19
---

# Phase 36 code review

## Scope

Library changes for hierarchical facets: `options.ex`, Meilisearch `settings.ex`, tests, guide, `mix verify.phase36`.

## Findings

None blocking. Hierarchical path validation is intentionally conservative (single dot, `lvl` + digits suffix). `String.to_atom/1` during hierarchy expansion runs at schema compile time only.

## Notes

- `mix test` full suite may time out on `ConsumerSmokeTest` when `deps.get` is slow; `mix verify.phase36` is the intended CI slice for this phase.
