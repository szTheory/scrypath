# Phase 40: `:all` expansion - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **FED-02**: an explicit **`:all` (or documented equivalent)** path for **`Scrypath.search_many/2`** that expands to every schema **declared** for global search, with **documented resolution rules**, **cardinality rails** (aligned with existing `max_schemas` and related shared opts), **timeouts** consistent with today’s native vs hydration split, and **explicit `{:error, _}`** tuples when expansion cannot produce a valid ordered query list—without adding a competing top-level search verb or breaking Phase **21** tuple semantics / Phase **39** federation weight rules.

**Out of scope here:** README/guide contract strings and verify-slice naming (**Phase 41 / FED-03**), operator LiveView (**OPSUI-01**).

</domain>

<decisions>
## Implementation Decisions

### 1) Call-site shape (expansion token) — one spine, explicit tag

- **D-01 (Canonical public shape):** Support a **tagged list element** **`{:all, text}`** or **`{:all, text, entry_keyword}`** as a **peer** to normal **`{schema_module, text}`** / **`{schema_module, text, keyword}`** entries inside the **`entries`** list passed to **`search_many/2`**. Normal entries keep the invariant **“schema slot is a module”**; expansion is never a bare reserved module atom pretending to be Ecto.

- **D-02 (Expansion semantics):** **`{:all, text, entry_kw}`** expands to a **flat, ordered** list of normal triples **`{schema, text, merged_entry_opts}`** inserted **at the tag’s position** in the caller’s list (concatenation / splice). **Registry order** is the order of modules in the resolved allowlist (config or per-call override). **No silent dedupe** of modules: if the allowlist contains duplicates, they produce duplicate slots (consistent with Phase **21** duplicate-schema story).

- **D-03 (Merging precedence):** For each expanded slot, **`merged_entry_opts = Keyword.merge(shared_opts, entry_kw, fn … -> entry wins end)`** using the same **right-biased** merge policy as **`MultiSearch.Entries`** today, then per-schema entry core vs shared (same as explicit tuples). **`federation_weight:`** on **`{:all, …}`**’s `entry_kw` applies as a **default** copied onto **each** expanded tuple unless overridden by a future per-schema map (not required in v1 unless planning discovers a hard need).

- **D-04 (Rejected primary APIs):** A separate **`search_all_schemas/2`** (or similar) as the **main** story — it duplicates Phase **21**’s “tuple list is the API” posture and splits telemetry/errors. **`schemas: :all` / `expand: :all` in shared_opts alone** as the **only** surface — ambiguous when combined with an arbitrary mixed list (precedence footgun). **Reflection / `@attribute` auto-discovery** of “all Scrypath schemas” — non-deterministic, release-unsafe, bad multi-tenant hygiene.

- **D-05 (Optional sugar later):** Shared-only sugar that **lowers** to the same internal representation as **`{:all, …}`** is acceptable **only** if narrowly documented (e.g. allowed only when the entry list is exactly one template tuple); headline API remains the **tagged element**.

### 2) Resolution rule — declared allowlist, Phoenix-friendly

- **D-06 (Default source of truth):** Resolve **`:all`** against an **explicit ordered allowlist** read from **application config**, e.g. **`Application.get_env(:my_app, :scrypath_global_search, [])`** (exact application key is an implementation detail; **must** be documented). Production docs should steer teams to **`config/runtime.exs`** (same mental model as URLs and secrets).

- **D-07 (Per-call override):** Support **`global_schemas: [module()]`** (name finalizable) in **`shared_opts`**. Precedence: when present, it **replaces** the configured list **entirely** for that call (no implicit merge). Tests should prefer this override over mutating **`Application.put_env`** when possible.

- **D-08 (Operator / product invariant):** Phrase in docs: **“`:all` is not every Ecto schema in your app — it is an allowlist you declare, like routes.”** Membership is **declared**, never **discovered** via codebase scan.

- **D-09 (Catalog module pattern, optional):** A thin app module **`MyApp.SearchCatalog.schemas/0`** that returns the list, called from **`runtime.exs`** to set env, is a **documentation pattern**, not a required second registry inside Scrypath.

### 3) Cardinality rails & error tuples — extend, do not overload

- **D-10 (Over `max_schemas` after expansion):** Return **`{:error, {:too_many_schemas, count, max}}`** — identical to an explicit entry list that is too long. Reuse existing operator handling and wording.

- **D-11 (Registry empty after `:all` resolution):** Return **`{:error, {:invalid_options, {:all_expansion, :empty_registry}}}}`** — **not** **`:empty_schema_list`**, which remains reserved for **`entries == []`**.

- **D-12 (Ambiguous resolution — reserved):** If the implementation introduces cases where resolution is not unique, use **`{:error, {:invalid_options, {:all_expansion, {:ambiguous, metadata}}}}`** with **small, log-safe** `metadata` (e.g. capped candidate list or counts). If v1 has no ambiguous case, **reserve** the shape for forward compatibility.

- **D-13 (Semver):** New **`{:all_expansion, _}`** details under **`{:invalid_options, _}`** are **additive (minor)**; callers matching **`{:invalid_options, _}`** already accept a superset.

### 4) Timeouts & failure boundaries — match Phase 21 envelope

- **D-14 (Resolution phase):** Expansion, allowlist read, **`max_schemas`** enforcement for the expanded slot list, and **`:all`-specific** invalid shapes happen **before** any backend HTTP. Outcomes are **`{:error, reason}`** only — **no** **`%MultiSearchResult{}`**.

- **D-15 (Timeout knobs — unchanged split):** After expansion, keep **one** native **`federation_timeout`** budget for the **single** **`/multi-search`** call and **per-schema** **`hydration_timeout`** for hydration (same as today). **Do not** replace with one combined “expand+search+hydrate” budget.

- **D-16 (Per-slot validation vs envelope):** Keep **current shipped behavior** for **`validate_search_options`** failures: **fail-fast** **`{:error, {:validation_failed, schema, reason}}}`** on the **first** invalid expanded slot (same as explicit tuples today). **Do not** silently drop bad slots in Phase 40 — that would be a **semantic change** relative to existing **`search_many/2`** and belongs in a dedicated contract phase if ever desired. **Partial `failures:`** remains for **hydration**, **sequential transport**, and other post-success paths per Phase **21** docs — not for compile-time option validation unless the project later standardizes otherwise.

- **D-17 (Transport):** Whole-request native failure stays **`{:error, {:transport_failed, reason}}}`**; **`search_many!/2`** continues to mean **`{:ok, _}`** vs **`{:error, _}`** only, with **`failures != []`** still possible on success (**Phase 21** bang semantics).

### Cross-cutting (vision)

- **D-18:** **Least surprise** (one **`search_many/2`** spine, explicit tag, explicit allowlist), **operational honesty** (distinct errors for registry-empty vs empty entry list), **Meilisearch-native** batch after expansion, **DX** (per-call **`global_schemas:`** for tests and scripts).

### Claude's Discretion

- Final keyword name: **`global_schemas:`** vs **`all_schemas:`** vs **`global_search_schemas:`**.
- Exact inner keys for **`{:ambiguous, metadata}`** when introduced.
- Whether **`{:all, text}`** without a third element is allowed (recommended **yes**, equivalent to **`[]`** entry opts).
- Minor wording of config key examples in docs (Phase 41).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements

- `.planning/REQUIREMENTS.md` — **FED-02** acceptance text
- `.planning/ROADMAP.md` — Phase 40 goal, success criteria, Progress checklist

### Prior phase contracts (must not contradict)

- `.planning/phases/21-multi-index-search/21-CONTEXT.md` — tuple API, duplicates, **`ordered`**, partial failures, bang semantics
- `.planning/phases/39-federation-scoring-weights/39-CONTEXT.md` — **`federation_weight:`**, native **`search_many`** requirement, merge trace, sequential fallback guard

### Code anchors (expected touchpoints)

- `lib/scrypath/multi_search/entries.ex` — normalization, rails, merge semantics
- `lib/scrypath/search.ex` — **`search_many/2`** orchestration pipeline
- `lib/scrypath/options.ex` — validation layering for new shared keys
- `test/scrypath/search_many_test.exs` — extend for expansion / errors

### External

- [Meilisearch multi-search](https://www.meilisearch.com/docs/reference/api/multi_search) — federated request shape (expanded call still one **`queries[]`** batch)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Scrypath.MultiSearch.Entries.normalize/2`** — schema count check, shared/per-entry merge, **`federation_weight:`** stripping, page-size validation: expansion should feed **the same** normalization path after producing explicit tuples.
- **`Scrypath.Search.run_search_many/2` pipeline** — native vs sequential branch, telemetry span: `:all` is a **pre-normalization** concern on the entry list.

### Established patterns

- **Right-biased `Keyword.merge`** for entry vs shared opts (`Entries`).
- **Explicit error families**: `:empty_schema_list`, `{:too_many_schemas, _, _}`, `{:invalid_options, _}`, `{:validation_failed, _, _}`.

### Integration points

- **Application environment** — typical Phoenix **`config/runtime.exs`** surface for allowlist.
- **Tests** — prefer **`global_schemas:`** (or final name) in **`shared_opts`** to avoid global config mutation.

</code_context>

<specifics>
## Specific Ideas

- User requested **deep comparative research** (subagents) across Elixir idioms and **Searchkick / Meilisearch-Rails / Laravel Scout**-style explicit per-model opt-in; synthesis favors **explicit allowlists** and **no magic discovery**.
- Expansion ergonomics: **tagged `{:all, text, opts}`** list element spliced into the tuple list reads like other Elixir tagged forms (`{:via, _, _}`, etc.) and preserves Phase **21**’s primary API.

</specifics>

<deferred>
## Deferred Ideas

- **Shared-only `schemas: :all` sugar** — only if it strictly lowers to tagged expansion and precedence is bulletproof.
- **Per-slot “drop invalid schema, continue” for option validation** — contract change vs today’s fail-fast validation; not Phase 40 unless explicitly pulled in.
- **Per-schema default `federation_weight:` map** on registry entries — nice-to-have if omnibox weighting needs differ by model.

### Reviewed Todos (not folded)

- None from `todo.match-phase`.

</deferred>

---

*Phase: 40-all-expansion*
*Context gathered: 2026-04-20*
