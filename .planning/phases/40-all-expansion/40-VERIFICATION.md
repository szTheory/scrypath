---
status: passed
phase: 40
generated: 2026-04-20
---

# Phase 40 verification — `:all` expansion (FED-02)

## Must-haves

| Criterion | Evidence |
|-----------|----------|
| `{:all, …}` expands before `Entries.normalize/2` | `Search.run_search_many_inner/2` calls `AllExpansion.expand/2` then `Entries.normalize/2` |
| `global_schemas:` optional runtime option | `lib/scrypath/options.ex` `@runtime_options` + `validate_global_schemas/1` |
| Empty registry error shape | `{:invalid_options, {:all_expansion, :empty_registry}}` in `AllExpansion` + tests |
| `max_schemas` applies post-expansion | `search_many_test` `:all_expansion respects max_schemas after splice` |
| Tests for happy, empty, missing otp, malformed | `all_expansion_test.exs` + `search_many_test.exs` |

## Automated

- `mix compile --warnings-as-errors` — PASS
- `mix test` — PASS (399 tests)

## Human verification

None required.

## Self-Check

Orchestrator: requirements from plans 40-01 and 40-02 satisfied; no gaps found.
