---
phase: 21-multi-index-search
status: passed
verified: 2026-04-17
---

## Verification — Phase 21: Multi-Index Search

### Automated

- `mix test --exclude integration` — full suite green (integration tests excluded by default).
- `mix compile --warnings-as-errors` — clean.
- `mix format --check-formatted` — clean on touched Elixir sources.

### Must-haves (from plans)

| Item | Evidence |
|------|----------|
| MULTI structs + entries rails | `lib/scrypath/multi_search_result*.ex`, `lib/scrypath/multi_search/entries.ex`, `entries_test.exs` |
| Backend optional `search_many`, Meilisearch `/multi-search`, decode | `backend.ex`, `meilisearch.ex`, `client.ex`, `federated_decode.ex`, `client_multi_search_test.exs` |
| `search_many/2` orchestration, telemetry, bang | `search.ex`, `scrypath.ex`, `search_many_test.exs` |
| Guide + docs contract + integration hook | `guides/multi-index-search.md`, `docs_contract_test.exs`, `search_many_integration_test.exs` |

### Human / live

- Live integration test `test/scrypath/search_many_integration_test.exs` runs only with `:integration` included and reachable Meilisearch (`SCRYPATH_MEILISEARCH_URL` per existing harness).

### Gaps

- MULTI-05 full StreamData property test not added; invariant covered by unit assertion on `Map.new(ordered) == by_schema`.

## Self-Check: PASSED
