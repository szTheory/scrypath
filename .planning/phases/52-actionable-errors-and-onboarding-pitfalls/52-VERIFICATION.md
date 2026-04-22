---
status: passed
phase: 52
verified: 2026-04-22
---

# Phase 52 verification

## Must-haves

| Item | Evidence |
|------|----------|
| **ONBD-05** — pitfalls guide + discoverability | `guides/common-mistakes.md`; links from `guides/overview.md`, `CONTRIBUTING.md`, `README.md`, `mix.exs` extras; `mix test test/scrypath/docs_contract_test.exs` |
| **ONBD-04** — bounded errors + bang exception | `lib/scrypath/search/error.ex`; `Scrypath.Search.Error` raises; `mix test test/scrypath/search_test.exs test/scrypath/search_many_test.exs` |
| **ONBD-06** — lobby + operator task docs | `lib/scrypath.ex` @moduledoc; four `lib/mix/tasks/scrypath.*.ex` Read next blocks; `test/scrypath/docs_contract_test.exs` lobby ordering test |

## Automated checks

- `mix test` — **413** tests, **0** failures (2026-04-22)

## Human verification

None required for this phase (operator `mix help` spot-check optional).
