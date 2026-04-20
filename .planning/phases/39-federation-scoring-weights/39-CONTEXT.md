# Phase 39: Federation scoring & weights - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **FED-01**: **Meilisearch-aligned** federation **scoring / weighting** for **`Scrypath.search_many/2`** so merged hit ordering is **predictable**, **test-covered**, and reflected in public types (`%MultiSearchResult{}` and federation-related metadata) **without** breaking existing **`%SearchResult{}`** contracts for callers that only use **`by_schema`**.

**Process note:** User selected **all** gray areas upfront, then **parallel subagent research** + **one-shot synthesis**; this file locks the merged outcome for planning and implementation.

**Tension with Phase 21 docs (explicit):** Phase 21 guide narrative warned that **raw relevance scores are not comparable across schemas** for the “same `q` everywhere” recipe. Phase 39 adds **engine-native federation weights** that change **merged** ordering across queries—documentation must **reconcile** those truths (weights tune **merge contribution**, not a claim that solo-index scores became globally comparable).

</domain>

<decisions>
## Implementation Decisions

### 1) Federation weight API (per-entry, Meilisearch-faithful)

- **D-01 (Primary shape):** Expose **`federation_weight:`** (name finalizable, but keep **one obvious atom**) as a **per-entry** keyword on the tuple’s third element: `{schema, text, [federation_weight: 2.0 | …]}`. It **must** align **1:1** with declaration order, **`ordered`**, and the Meilisearch **`queries[]`** array—same mental model as **`filter:`**, **`page:`**, etc.

- **D-02 (Wire mapping):** Map each entry’s weight into Meilisearch’s per-query **`federationOptions`** (see Meilisearch OpenAPI / **Perform a multi-search** — `SearchQueryWithIndex.federationOptions`). Do **not** use a **schema-keyed** weight map as the primary API: it **cannot** represent duplicate schema modules in one call (Phase 21 **D-03**).

- **D-03 (Rejected primary APIs):** **Parallel list** of weights in `shared_opts` (two lists to keep in sync—refactor footgun). **`federation_weights: %{Module => float}`** as primary (last-wins / impossible duplicates).

- **D-04 (Optional sugar later):** A **shared default weight** used only when entries omit `federation_weight:` is acceptable **only if** documented as **pure merge in Elixir** into per-query payloads and **never** implied to solve duplicate-schema rows without per-entry override.

### 2) Defaults, validation, semver, errors

- **D-05 (Omit on wire):** When the caller omits **`federation_weight:`**, **omit** the corresponding **`federationOptions`** / **`weight`** field on that query object—do **not** inject default **`1.0`** for every query. Preserves request bodies for unchanged callers. Document in prose that omission matches **Meilisearch’s documented default** for federation weighting.

- **D-06 (Validation):** Accept **finite** numbers; **integer → float** coercion allowed for DX. **Reject** `NaN`, `±Inf`, and non-numerics **before** HTTP. **No** “weights must sum to 1” (or similar) rules—those would be Scrypath-invented semantics.

- **D-07 (Semver):** Additive **minor**: new optional entry keys only; default behavior unchanged when weights absent.

- **D-08 (Error families — stay consistent):**
  - Invalid weight placement/type/range → **`{:error, {:invalid_options, {:federation_weight, detail}}}}`** (same **outer** `{:invalid_options, _}` family as `{:federation_key_in_entry, _}` / page size errors).
  - Per-schema search opts → **`{:error, {:validation_failed, schema, reason}}`** unchanged.
  - Bad **runtime** config → **`ArgumentError`** from **`Config.resolve!/1`** unchanged.
  - **Strip** `federation_weight:` (and any future entry-only federation knobs) **before** **`Options.validate_search_options/2`** so federation tuning is not modeled as schema-declared search fields.

### 3) Merged ordering on `%MultiSearchResult{}` (omnibox / future OPSUI)

- **D-09 (Merge trace — references, not duplicate hits):** Add an **optional** field on **`%MultiSearchResult{}`** carrying **global merge order** as **references** into canonical per-schema hits—preferred shape **`{schema, id}`** list where **`id`** is the document primary key as returned in hits (supports hydration-aware UIs; avoids list-index fragility if rows are dropped). Alternative: engine-native **`queriesPosition`** only if documented and tested against hydration edge cases.

- **D-10 (`nil` semantics):** Field is **`nil`** when merge order is undefined or would mislead: non-federated **`results[]`** responses, **sequential** backend fallback without a single federated merge stream, or cases analogous to Phase 21 **D-04** honesty for **`federation:`** metadata.

- **D-11 (Ergonomic projection):** Provide a **small public helper** (exact module/name at implementation discretion—e.g. **`Scrypath.MultiSearchResult.merge_projection/1`**) that combines the trace + **`ordered`** / **`by_schema`** into a **`[{schema, hit_map}]`** (or records when hydrated) for omnibox ribbons—**one** blessed projection path; avoid encouraging ad-hoc zip logic in apps.

- **D-12 (Rejected as primary):** A second **full hit payload** list on the struct (**`merged_hits`**) as the **only** story—duplicates memory and risks divergence from **`%SearchResult{}`**.

### 4) Sequential `search_many` fallback (non-native backends)

- **D-13 (Fail fast for merge-only options):** If **`backend.search_many/2`** is **not** implemented, keep today’s **sequential** path for calls **without** merge-only entry options (same as current behavior).

- **D-14 (When caller sets custom `federation_weight:`):** If any entry requests a non-default merge contribution (starting with **explicit** `federation_weight:`), **do not** run sequential **`search/3`** fallback—return **`{:error, {:invalid_options, {:federation_merge_requires_native_search_many, detail}}}}`** where **`detail`** optionally includes **`backend:`** module for operators. Reserve the **same guard** for future merge-only per-entry knobs.

- **D-15 (Rationale):** **No silent ignore** (wrong ranking in prod while tests pass) and **no client-side merge** in Elixir (fake federation, unbounded maintenance). Custom **`Backend`** mocks in tests should implement a trivial **`search_many/2`** or omit merge-only options.

### 5) Documentation touchpoints (coordination with Phase 41)

- **D-16 (Phase 39 minimum):** Public **`@doc`** for **`search_many/2`** (and module summaries as needed) must describe **weights**, **error shapes**, **nil merge trace**, and **sequential fallback limitation**—adopters must not need to read Meilisearch OpenAPI cold.

- **D-17 (Guide split):** **`guides/multi-index-search.md`** must gain at least a short **federation weights** subsection **or** clearly point to where Phase 41 will expand prose—avoid contradicting Phase 21 without a **“merge vs per-schema scores”** clarification paragraph. Full narrative polish may still belong to **Phase 41** (**FED-03**), but Phase 39 ships **accurate** pointers and avoids stale warnings that imply weights cannot exist.

### Cross-cutting (vision alignment)

- **D-18:** **Operational honesty** (explicit errors when merge cannot run), **Meilisearch-native** wire shape, **least surprise** (per tuple = per query = per weight), **DX** (omit-by-default, early validation, one merge projection helper).

### Claude's Discretion

- Exact atom name **`federation_weight:`** vs nested **`federation: [weight: …]`** if more per-query federation options land in the same release.
- Exact inner error map keys for **`federation_merge_requires_native_search_many`** (slim tuple vs `%{backend: _, …}`).
- Whether **`queriesPosition`** is also stored alongside **`id`** for debugging/telemetry.
- Final field name on **`%MultiSearchResult{}`** for the merge trace list.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 39 goal, success criteria, **FED-01**
- `.planning/REQUIREMENTS.md` — **FED-01**; traceability table

### Prior phase context (multi-index + product posture)

- `.planning/phases/21-multi-index-search/21-CONTEXT.md` — tuple API, **`ordered`** vs **`by_schema`**, duplicate schemas, **`%MultiSearchResult.Federation{}`**, partial failures, test pyramid
- `guides/multi-index-search.md` — current multi-section vs omnibox narrative (must be reconciled with weights in D-16/D-17)

### Project principles

- `.planning/PROJECT.md` — Meilisearch-first, operational honesty, Ecto-first, DX

### Code anchors (expected touchpoints)

- `lib/scrypath/search.ex` — `search_many/2`, native vs sequential branch
- `lib/scrypath/multi_search/entries.ex` — normalization, shared-only federation keys
- `lib/scrypath/meilisearch.ex` — `search_many/2` payload (`queries`, top-level `federation`)
- `lib/scrypath/meilisearch/federated_decode.ex` — federated `hits` / `_federation`
- `lib/scrypath/multi_search_result.ex` — struct surface
- `lib/scrypath/multi_search_result/federation.ex` — federation metadata mirror
- `lib/scrypath/options.ex` — validation layering vs new entry keys
- `test/scrypath/search_many_test.exs` — extend for ordering + weights

### External (Meilisearch)

- [Perform a multi-search](https://www.meilisearch.com/docs/reference/api/multi_search) — federated request/response shape, `federationOptions`, merged `hits` with `_federation`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Scrypath.MultiSearch.Entries.normalize/2`** — right-biased merge, **`@shared_only_federation_keys`**, schema count rails; extend with weight validation and strip-before-validate behavior.
- **`Scrypath.Meilisearch.search_many/2`** — builds **`queries`** + top-level **`federation`** (`limit`/`offset` from config); extend per-query **`federationOptions`** from normalized triples.
- **`Scrypath.Meilisearch.FederatedDecode`** — groups federated flat **`hits`** by **`_federation.indexUid`**; natural place to also derive **global merge order trace** before or while splitting per-schema raw maps.
- **`%MultiSearchResult{}` / `%MultiSearchResult.Federation{}`** — additive fields without breaking **`ordered`/`by_schema`/`failures`**.

### Established patterns

- **`{:invalid_options, _}`** for entry/rails problems; **`{:validation_failed, schema, _}`** for per-schema search options; **`ArgumentError`** for invalid runtime **`Config.resolve!`** path.
- **`search_many!/2`** unwraps only **`{:ok, _}`** vs **`{:error, _}`** (Phase 21 bang semantics).

### Integration points

- Public API surface on **`lib/scrypath.ex`** (delegates).
- **`FakeBackend`** / **`Req.Test`** — extend for weighted federated payloads and fallback guard tests.

</code_context>

<specifics>
## Specific Ideas

User requested **maximum delegation**: parallel research subagents, one-shot synthesis, and **no interactive per-area Q&A**—decisions above are the integrated outcome.

</specifics>

<deferred>
## Deferred Ideas

- **FED-02 / Phase 40** — **`:all`** expansion, cardinality rails, empty/ambiguous resolution (out of scope for Phase 39).
- **FED-03 / Phase 41** — full README + **`docs_contract_test.exs`** expansion for federation + `:all` (Phase 39 should still land accurate module/docs pointers per D-16/D-17).
- **OPSUI-01** — operator LiveView over federation-shaped results (explicit follow-up after primitives).

### Reviewed Todos (not folded)

None — `todo.match-phase` returned no matches for phase 39.

</deferred>

---

*Phase: 39-federation-scoring-weights*
*Context gathered: 2026-04-20*
