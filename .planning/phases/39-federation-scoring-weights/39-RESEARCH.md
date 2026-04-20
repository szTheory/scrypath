# Phase 39 — Technical research: federation scoring & weights

**Phase:** 39 — Federation scoring & weights  
**Requirement:** FED-01  
**Date:** 2026-04-20

## Question

What do we need to know to **plan** Meilisearch-aligned federation weights for `Scrypath.search_many/2`, merge-order observability, and sequential-backend semantics?

## Meilisearch wire shape

- Multi-search accepts `queries[]` where each element is a search body plus `indexUid`.
- Per-query **`federationOptions`** (object) can include **`weight`** (number). When omitted, Meilisearch applies its documented default; Scrypath should **not** inject `1.0` on every query (see `39-CONTEXT.md` D-05).
- Top-level **`federation`** continues to carry merge window controls (`limit`, `offset` in JSON) — already mapped in `Scrypath.Meilisearch.search_many/2` from config (`:federation_limit`, `:federation_offset`).
- Federated responses use a **flat `hits`** array with **`_federation.indexUid`** on each hit; `Scrypath.Meilisearch.FederatedDecode` groups by UID into per-schema raw maps. **Global merge order** equals the order of hits in that flat list before grouping.

**Reference:** [Perform a multi-search](https://www.meilisearch.com/docs/reference/api/multi_search) — federation request/response, `federationOptions`, merged hits.

## Code touchpoints (current)

| Area | Role |
|------|------|
| `MultiSearch.Entries.normalize/2` | Tuple merge, shared-only federation keys, page/schema rails; must **validate** `federation_weight:` (finite, no NaN/Inf), **reject** bad types, and ensure merged opts passed to `Options.validate_search_options/2` **exclude** `federation_weight:` (D-08). |
| `Search.run_search_many/2` | Branches on `function_exported?(backend, :search_many, 2)`; builds `paired_queries` from validated triples. Must **fail fast** when any entry carries merge-only `federation_weight:` and backend lacks `search_many/2` (D-13–D-14). |
| `Meilisearch.search_many/2` | Builds `queries` via `Meilisearch.Query.to_payload/1` + `indexUid`; must add optional `"federationOptions" => %{"weight" => float}` per query when entry requested a weight. |
| `FederatedDecode` | After decode, derive **merge order trace** as `[{schema, id}, ...]` by walking federated flat `hits` (string keys only; no `String.to_atom/1` on remote keys). |
| `MultiSearchResult` | Add optional field (name TBD in implementation) for merge trace; `nil` when not federated / sequential path / undefined (D-09–D-10). |
| `Options.validate_search_options/2` | Uses `NimbleOptions` on search opts; unknown keys error — **strip** entry-only federation keys before this call. |

## Testing strategy

- **Unit:** `entries_test.exs` — valid weights, invalid weights (`:nan`, `:inf`, non-numeric), omission does not add key to merged opts for validation.
- **Integration:** `search_many_test.exs` — extend `FakeBackend.search_many/2` to echo `federationOptions` or simulate weighted ordering so tests assert **deterministic** merged ordering and **error** when using `SequentialOnlyBackend` + `federation_weight:`.
- **Decode:** Federated payload with ordered hits → `merge_projection/1` or new field matches expected `[{schema, id}, ...]`.

## Pitfalls

- **Silent sequential fallback** with custom weights would lie about ranking — blocked by explicit `{:invalid_options, {:federation_merge_requires_native_search_many, _}}` (D-14).
- **Duplicate schema modules** in one call require **per-entry** weight placement (already decided in CONTEXT); map keyed by module is insufficient.
- **Primary key field:** hits use schema `document_id` / `"id"` — merge trace should use the same id Meilisearch returns (string or number as in payload).

## Validation Architecture

This phase is validated primarily through **ExUnit** and **`mix compile --warnings-as-errors`**.

| Dimension | Approach |
|-----------|----------|
| **Correctness** | Unit tests for `Entries`, integration tests for `search_many/2` + `FakeBackend`, decode tests for merge trace order. |
| **Regression** | Existing `search_many` tests remain green; weighted path additive. |
| **Docs** | `@doc` on `search_many/2` and guide pointer (`guides/multi-index-search.md`) — grep-verifiable strings per D-16/D-17. |

Sampling: after each logical task group, run `mix test test/scrypath/multi_search/entries_test.exs` and targeted `search_many` tests; before phase close, `mix test` (or CI-equivalent).

---

## RESEARCH COMPLETE

Planning can proceed with `39-CONTEXT.md`, this file, and `FED-01` in `REQUIREMENTS.md`.
