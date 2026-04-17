# Phase 21: Multi-Index Search — Technical Research

**Phase:** 21 — Multi-Index Search  
**Question:** What do we need to know to PLAN this phase well?  
**Status:** Ready for execution agents

---

## Summary

Phase 21 adds `Scrypath.search_many/2` as a Meilisearch-first federated API: tuple list `{schema, text}` / `{schema, text, opts}`, shared runtime opts with per-entry right-biased merge (MULTI-02), whitelist for federation-global keys at shared level only (MULTI-03), `%Scrypath.MultiSearchResult{}` with `ordered`, `by_schema`, `failures`, `federation` (MULTI-04–07), native `/multi-search` on `Scrypath.Meilisearch` with `facetsByIndex` unpack and **never** `mergeFacets` (MULTI-08), concurrent hydration via `Task.async_stream/5` (MULTI-09), cardinality rails (MULTI-10), optional `Backend.search_many/3` with sequential fallback (MULTI-12), telemetry (MULTI-13), and `guides/multi-index-search.md` per UI-SPEC + MULTI-11.

Canonical sources: `.planning/phases/21-multi-index-search/21-CONTEXT.md`, `.planning/research/deep/MULTI_INDEX.md`, `.planning/REQUIREMENTS.md` (MULTI-01..13), `lib/scrypath/search.ex`, `lib/scrypath/backend.ex`, Phase 20 facet decoders.

---

## Implementation Notes

### Public API and options

- Mirror `search/3` validation: reuse `Scrypath.Options.validate_search_options/2` per entry after merging shared vs entry opts per MULTI-02 (per-key: entry wins; document as Keyword merge semantics where applicable).
- Reject empty list with `{:error, :empty_schema_list}`; malformed tuples with `{:error, {:invalid_options, _}}` or `ArgumentError` only where single-search already raises before dispatch — align with `21-CONTEXT` D-02.
- `max_schemas`, `federation_limit`, `federation_offset`, `hydration_timeout`, `federation_timeout` belong to shared whitelist; if present inside a per-entry opts keyword, return `{:error, {:invalid_options, _}}` (MULTI-03).

### Meilisearch wire

- Build `queries: [%{indexUid: ..., q: ..., ...}, ...]` in declaration order; add `federation` object without `mergeFacets`.
- Response handling: read federation hits + `facetsByIndex` keyed by index UID; map UID back to schema module via same ordering used to build queries.
- `FakeBackend` should gain `search_many/3` for unit tests; default implementation in `Search` when callback missing = sequential `search/3` calls (MULTI-12), preserving partial-failure semantics at Scrypath layer (each call’s error becomes a `failures` entry).

### Partial failure vs total failure

- `{:ok, %MultiSearchResult{}}` when ≥1 sub-query produced a `%SearchResult{}`; failed slots only in `failures:` with shape `%{schema: module(), reason: term()}` (MULTI-07).
- `{:error, {:all_failed, _}}` when every sub-query failed after dispatch; validation-before-dispatch uses canonical table in MULTI-06.
- `search_many!/2` raises only on `{:error, _}` top-level; never raises solely because `failures != []` (CONTEXT D-02).

### Hydration

- After raw hits grouped per schema, run `Task.async_stream/5` over schemas needing hydration: `ordered: true`, `max_concurrency: length(entries)`, `timeout: hydration_timeout`, `on_timeout: :kill_task`; map timeouts to `reason: :hydration_timeout` in `failures` (MULTI-09).

### Testing strategy

- Heavy unit coverage in `test/scrypath/search_many_test.exs` + extended `FakeBackend`.
- One `Req.Test` golden for `POST /multi-search` body (no `mergeFacets`, `queries` + `federation` keys present as required).
- Tagged integration (2–4 tests): MULTI-08 facet parity vs solo `search/3` on pinned Meilisearch image.

---

## Pitfalls

1. **Keyword duplicate keys:** tuple list avoids duplicate schema modules collapsing — document `by_schema` last-wins vs `ordered` authority (CONTEXT D-03).
2. **Facet parity:** any accidental `mergeFacets` breaks MULTI-08 — grep CI/tests for literal `mergeFacets` must be absent from request builder.
3. **False-green CI:** integration tests must be excluded by default; document `SCRYPATH_INTEGRATION` gate like existing search tests.
4. **Federation nil:** when `failures != []`, default `federation: nil` unless normalized totals are proven safe (CONTEXT D-04).

---

## Open Questions (executor resolves in code)

- Exact `%MultiSearchResult.Federation{}` field set after one live response sample against pinned CI image version.
- Whether `remoteErrors`-style engine fields need explicit surfacing in v1.3 or stay internal.

---

## Validation Architecture

> Nyquist Dimension 8 — plans MUST cite automated commands per task; sampling continuity across waves.

| Dimension | How Phase 21 satisfies it |
|-----------|---------------------------|
| **Unit** | `mix test test/scrypath/search_many_test.exs`, `mix test test/scrypath/options_test.exs` (if extended), extended `FakeBackend` tests — run after every task touching lib. |
| **Contract** | `Req.Test` asserts JSON body keys; `grep`-style plan acceptance for forbidden strings (`mergeFacets`). |
| **Integration** | `@moduletag :integration` subset under `test/scrypath/` with `SCRYPATH_INTEGRATION=1`; facet byte-for-byte / struct equality MULTI-08. |
| **Docs** | `DocsContractTest` for `guides/multi-index-search.md`; `PhoenixExamplesTest` (or repo equivalent) for HEEx compile. |
| **Telemetry** | `assert_receive` or telemetry helper patterns mirroring `[:scrypath, :search]` tests for `[:scrypath, :search_many, *]`. |

**Wave sampling:** After wave 1 — `mix test` scoped to new modules; after wave 2 — add client tests; after wave 3 — full `mix test --exclude integration` (or project default); after wave 4 — integration slice + doc tests.

---

## RESEARCH COMPLETE

Phase 21 is ready for planner-quality PLAN.md execution: boundaries, Meilisearch transport, structs, failure algebra, hydration, telemetry, and validation dimensions are anchored in CONTEXT + deep research + requirements.
