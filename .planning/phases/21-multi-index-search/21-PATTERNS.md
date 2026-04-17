# Phase 21 — Pattern Map

Analogs in-repo for executors. Read these before editing listed targets.

---

## Orchestration and public API

| Planned surface | Analog file | Excerpt / pattern |
|-----------------|-------------|-------------------|
| `search_many/2` entry | `lib/scrypath/search.ex` | `search/3` → `validate_search_options` → `Telemetry.span [:scrypath, :search]` → `backend.search` → `decorate_result` → `maybe_hydrate` |
| Bang unwrap | `lib/scrypath/search.ex` | `search!/3` raises `RuntimeError` with `inspect(reason)` on `{:error, reason}` |
| Runtime config | `lib/scrypath/config.ex` | `Config.resolve!`, `fetch_backend!` |

---

## Backend seam

| Planned surface | Analog file | Excerpt / pattern |
|-----------------|-------------|-------------------|
| Optional callback | `lib/scrypath/backend.ex` | Add `@optional_callback` with `@doc` noting internal seam |
| Fake backend | `test/support/fake_backend.ex` | Implement new callback; mirror `search/3` return shapes |

---

## Meilisearch client

| Planned surface | Analog file | Excerpt / pattern |
|-----------------|-------------|-------------------|
| HTTP + JSON | `lib/scrypath/meilisearch/*.ex` | Follow existing `Req` post patterns; pinned paths from `.github/workflows/ci.yml` Meilisearch image |
| Query payload | `lib/scrypath/meilisearch/query.ex` | Field naming for Meilisearch JSON; never leak `mergeFacets` |

---

## Results and facets

| Planned surface | Analog file | Excerpt / pattern |
|-----------------|-------------|-------------------|
| `%SearchResult{}` | `lib/scrypath/search_result.ex` | `SearchResult.new/4`, struct keys |
| Facet decode | `lib/scrypath/search_result/facets.ex` | Phase 20 decoders — reuse for per-schema facet maps unpacked from `facetsByIndex` |

---

## Tests and docs contracts

| Planned surface | Analog file | Excerpt / pattern |
|-----------------|-------------|-------------------|
| Search tests | `test/scrypath/search_test.exs` | `FakeBackend`, options validation, telemetry |
| Req.Test | `test/scrypath/meilisearch/*_test.exs` | Golden body / response handling |
| Guide contracts | `test/scrypath/docs_contract_test.exs` (if present) | Path allow-list for new guide |

---

## PATTERN MAPPING COMPLETE
