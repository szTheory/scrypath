# Phase 36 — Technical research: hierarchical facets

**Phase:** 36 — Hierarchical facets  
**Question:** What do we need to know to plan declarative nested facet paths for Scrypath + Meilisearch v1?

---

## Meilisearch behavior (authoritative)

- **Facet model:** Hierarchy is expressed as **multiple filterable attributes** (e.g. `categories.lvl0`, `categories.lvl1`) or denormalized flat names — not a nested JSON tree in `facetDistribution`.
- **Responses:** `facetDistribution` and `facetStats` are **flat maps per attribute** (`attributeName` → `{value => count}`). Client UIs compose trees from parallel per-level distributions.
- **Filters:** Dotted attribute names are valid in filter expressions when those attributes are filterable; AND across attributes is the usual drill-down refinement model.
- **Versioning:** Team should confirm **minimum Meilisearch** version assumed in docs when citing facet/filter behavior (lock in PLAN execution, not here).

---

## Current codebase constraints

| Area | Today | Phase 36 change |
|------|--------|-----------------|
| `lib/scrypath/options.ex` `validate_faceting_rules!/1` | Rejects any faceting attribute atom whose string form contains `"."` with `ArgumentError` mentioning hierarchical facet | **Opt-in** path (CONTEXT D-10): same rejection by default; when opt-in enabled, allow **documented** dotted atoms that are also in `filterable:` |
| `filterable:` vs `faceting.attributes` | Subset enforced with `MapSet.member?/2` on atoms | Dotted facet atoms must appear **verbatim** in `filterable:` (same atom), preserving FACET-02 style |
| `lib/scrypath/meilisearch/settings.ex` | Projects faceting attributes onto filterable object form | Ensure dotted names flow to Meilisearch JSON as expected string keys |
| `lib/scrypath/operator/index_contract_drift.ex` | Normalizes declared vs applied `faceting` | Extend wire normalization so hierarchical attribute lists compare cleanly (no false drift) |
| `lib/scrypath/search_result.ex` `decode_facets/2` | Uses `Atom.to_string(field)` for wire keys | Already compatible with dotted atoms if `Query.facets` carries those atoms |
| Phase 20 guide appendix | States hierarchical dotted atoms in `faceting.attributes` are a mistake | **Replace** with opt-in + supported shapes (CONTEXT D-14) |

---

## Declaration design (aligned with CONTEXT)

1. **Canonical:** `faceting: [attributes: [...]]` remains 1:1 with Meilisearch — atoms may include dots when opt-in is on.
2. **Optional sugar:** e.g. `hierarchy:` (exact keyword TBD in implementation) expands at compile/normalization time into `attributes:` only — no second declaration channel.
3. **Semantics lock:** One atom identifier everywhere (schema, `facets:` option, `facet_filter:`, `result.facets.distribution` keys) per CONTEXT D-09.

---

## Testing strategy

- **Regression spine:** Keep existing Phase 20 facet tests unchanged (default no opt-in).
- **Parallel coverage:** New schema module(s) under `test/support/` with opt-in + dotted attributes; `mix test` targets for options + (if present) integration/verify slice.
- **Docs:** `guides/faceted-search-with-phoenix-liveview.md` new stable section + `docs_contract_test.exs` substring locks per CONTEXT D-15 (no REQ IDs in published strings).

---

## Open questions for implementation (planner discretion)

- Exact NimbleOptions keyword for opt-in (`nested_facet_paths`, `nested_paths`, etc.).
- Exact `hierarchy:` sugar grammar (max depth, field name, `lvlN` vs dotted segments).
- Whether to add a dedicated `mix verify.phase36` or fold into an existing verify task — prefer **minimal CI noise** (CONTEXT D-12).

---

## Validation Architecture

> Nyquist / execution sampling for Phase 36.

**Stack:** Elixir 1.17+, ExUnit, `mix test`.

**Commands:**

| Layer | Command | When |
|-------|---------|------|
| Quick | `mix compile --warnings-as-errors` | After options/schema/compiler-facing edits |
| Focused | `mix test test/scrypath/options_test.exs` | After `validate_faceting_rules!` / NimbleOptions changes |
| Facet slice | `mix test test/scrypath/search_result_test.exs` (or nearest existing facet decode tests — executor confirms path) | After `decode_facets` / `Facets` changes |
| Drift | `mix test` on operator drift test module if touched (`test/scrypath/operator/*` grep `IndexContractDrift`) | After drift normalization |
| Full | `mix test` | After each plan wave merge; before handoff |

**Sampling expectations:**

- No task that changes Elixir library behavior ships without **automated** `mix test` (or compile-only where truly doc-only, then docs contract test in same wave).
- Integration-style hierarchical facet end-to-end: at least **one** test path proving `facetDistribution` keys round-trip to `%Facets{}.distribution` for dotted attributes when opt-in schema is used.

**Dimension 8 (Nyquist):** Every behavioral PLAN task maps to a concrete `mix test` path or compile gate above; manual steps only for Meilisearch instance bring-up if integration tests require it — document in PLAN verification.

---

## RESEARCH COMPLETE

Research artifact is sufficient to plan Phase 36 with locked CONTEXT decisions D-01–D-19.
