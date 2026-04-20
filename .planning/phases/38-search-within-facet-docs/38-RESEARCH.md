# Phase 38 — Technical research: search within facet + docs

**Phase:** 38 — Search within facet + docs  
**Question:** What do we need to know to plan implementation and verification well?

## 1. Meilisearch and query encoding (source of truth)

- `lib/scrypath/meilisearch/query.ex` documents that when both `filter` and `facetFilters` are present, Meilisearch applies **AND** between them. Scoped “within bucket” search is therefore **one POST `/indexes/:uid/search`** with the bucket encoded as an additional facet refinement (or OR-group for that attribute) alongside any caller-supplied `facet_filter:` keys on **other** attributes.
- `translate_facet_filter/1` already encodes list values as OR within a field and multiple keyword entries as AND across fields — the locked bucket should merge into `facet_filter` **before** `Query.new/2` so the existing encoder stays authoritative.

## 2. Library integration points

- **`Scrypath.Search.search/3`** is the single pipeline: `validate_search_options` → `Query.new` → telemetry span `[:scrypath, :search]` → backend → decorate. `search_within_facet/4` should remain a **thin** caller: merge bucket into `opts[:facet_filter]`, then delegate to `search/3` (or a shared private body) without duplicating HTTP or hydration.
- **`Scrypath.Options.validate_search_options/2`** already validates facet keys against `faceting.attributes`. Same-attribute conflicts with caller-supplied `facet_filter:` must be rejected **before** validation with a stable `ArgumentError` prefix so operators get a clear “omit duplicate or use `search/3`” message (per `38-CONTEXT.md` D-06).
- **Bang parity:** Mirror `search!/3` → `RuntimeError` on `{:error, _}` from backend; validation still raises `ArgumentError` like today.

## 3. Telemetry distinction (D-11)

- Today `Telemetry.common_metadata/3` accepts an `extra` keyword. Preferred approach: add an **optional**, documented search option (e.g. `:telemetry_extra` keyword list, default `[]`) to the Nimble search schema, **strip it before** `Query.new/2`, and merge into `common_metadata` inside `search/3`. `search_within_facet/4` passes `telemetry_extra: [search_scope: :within_facet, scoped_facet: attr]` (exact keys left to implementation) so operators can distinguish scoped searches without a second top-level `:telemetry.span`.

## 4. Testing strategy

- **Unit-level:** `Scrypath.Meilisearch.QueryTest` already asserts `facetFilters` shapes — scoped search should be proven at **integration** level: `Scrypath.search_within_facet/4` + `backend: Scrypath.Meilisearch` + `Req.Test` stub, mirroring `test/scrypath/meilisearch_test.exs` “common search translates normalized query fields into Meilisearch payloads”.
- **Conflict:** ExUnit `assert_raise ArgumentError, ~r/search_within_facet/, fn -> ... end` when `facet_filter:` already contains the bucket attribute.
- **Composition:** One test with `filter:` + `facet_filter:` on another attribute + bucket shows combined `filter` and `facetFilters` in `body_params`.

## 5. Documentation and contracts (FACET-04)

- New guide sections must use **stable `##` headings** agreed in plans; `test/scrypath/docs_contract_test.exs` locks short substrings (no internal REQ IDs — hygiene test forbids them in published markdown).
- **`mix verify.phase38`:** Follow `lib/mix/tasks/verify.phase37.ex`: focused test list including new search test file and `docs_contract_test.exs`; register `preferred_cli_env` in `mix.exs`.

## 6. Risks explicitly avoided

- Silent merge of duplicate facet keys (support burden / empty-hit confusion).
- Multi-search as default for this API (stays Phase 37 / app-composed).

## RESEARCH COMPLETE

Findings above are sufficient to plan FACET-03 and FACET-04 without further external spikes.

---

## Validation Architecture

**Nyquist / execution feedback**

| Dimension | How this phase is verified |
|-----------|----------------------------|
| **1 — Correctness** | ExUnit: Req.Test payload asserts AND composition; `ArgumentError` on same-attribute conflict; `mix test` on new file. |
| **2 — Regression** | Existing `search/3` and `Query` tests remain green; `mix verify.phase38` runs focused slice + docs contracts. |
| **3 — Security** | Library-only: no new secrets; threat model in PLAN.md covers misleading filter composition docs. |
| **4 — Performance** | Single HTTP search default unchanged; no extra round-trips in happy path. |
| **5 — Operability** | Telemetry extras document scoped search in metadata for log aggregation. |
| **6 — DX** | Public `Scrypath.search_within_facet/4` + `@doc` / guide cross-links; README one-line pointer. |
| **7 — Compatibility** | Public API additive; existing `search/3` behavior unchanged when `search_within_facet` not used. |
| **8 — Sampling continuity** | After each plan wave: `mix verify.phase38`; full `mix test` before release per project norms. |

Sampling commands (executor):

- Wave 1: `mix test test/scrypath/search_within_facet_test.exs` (path as created in plan 01).
- Wave 2: `mix verify.phase38`.
- Broader: `mix compile --warnings-as-errors && mix test`.
