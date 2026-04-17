# ARCHITECTURE Research — Scrypath v1.3

**Domain:** Elixir OSS search-indexing library (Meilisearch-first, Ecto-native) — subsequent milestone adding faceting, relevance tuning, multi-index search, and operator polish onto an already-shipped public contract.
**Researched:** 2026-04-17
**Confidence:** HIGH (driven by direct reading of existing modules — `/Users/jon/projects/scrypath/lib/scrypath/*`)

---

## 1. Existing Architecture — What Must Be Preserved

Before prescribing integration, the five load-bearing contracts v1.3 work must not perturb:

| Contract | Lives in | Why it can't move |
|---|---|---|
| `use Scrypath` → `__scrypath__/1` reflection | `lib/scrypath/schema.ex`, `options.ex` (`@schema_options`) | Public DSL. Any new metadata keys must additionally be exposed via `__scrypath__/key` without breaking the existing allowed-key allowlist. |
| Common search returns `%Scrypath.SearchResult{}` | `lib/scrypath/search.ex:42-46`, `lib/scrypath/search_result.ex` | `@enforce_keys [:query, :hits, :records, :raw, :missing_ids, :page]` — new fields are **additive only**, never breaking the shape. |
| Backend behaviour (`Scrypath.Backend`) takes `%Scrypath.Query{}` | `lib/scrypath/backend.ex`, `query.ex` | `%Query{}` is the only common-path payload backends receive. Faceting/multi-index must route through this struct, not around it. |
| Meilisearch-native surface is namespaced | `lib/scrypath/meilisearch/*` | ARCHITECTURE.md lines 10–18: `Scrypath.Meilisearch.*` is the **only** public escape hatch. New backend-native power (facet filter strings, ranking rules, federated `/multi-search`) must be *translated* from Scrypath-owned shapes here, not leaked as kwargs on `Scrypath.search/3`. |
| Internal operations seam (`Scrypath.Operations.Task`, `Scrypath.Operations.Result`) | `lib/scrypath/operations/*`, `operator/failed_work.ex:107-125` | Sync/reindex/operator read paths project internal results to public maps at boundary. New operator fields must live on Scrypath-owned structs, not backend-native payloads. |

---

## 2. Per-Feature Integration Design

### (a) Faceted Search

#### Where the `faceting` declaration lives

**Answer: extend `@schema_options` in `lib/scrypath/options.ex`, not a new config namespace.**

Rationale: `filterable:` and `sortable:` already live there as first-class declarative lists. A new `faceting:` key follows that precedent exactly — it stays co-located with the rest of the schema contract, validates at compile time through NimbleOptions, and lands on `__scrypath__/1` via the existing `@scrypath_config` attribute plumbing in `schema.ex`.

**Shape recommendation:**
```elixir
faceting: [
  type: {:custom, __MODULE__, :validate_faceting, []},
  default: %{},
  doc: "Declarative facet configuration: attributes, max_values_per_facet, sort_facet_values_by."
]
```

Keep the Scrypath-owned shape a **plain map** (`%{attributes: [atom()], max_values_per_facet: pos_integer(), sort_facet_values_by: %{...}}`). This matches how `settings:` is already stored (`validate_settings` accepts a map) — staying Ecto/Elixir-idiomatic and keeping the Meilisearch-native key names (`maxValuesPerFacet`, `sortFacetValuesBy`) confined to `Scrypath.Meilisearch.Settings`.

**Files touched:**
- `lib/scrypath/options.ex` — add `faceting:` to `@schema_options`, add `validate_faceting/1`.
- `lib/scrypath/schema.ex` — add `__scrypath__(:faceting)` clause.
- `lib/scrypath.ex` — add `schema_faceting/1` reflection helper mirroring `schema_fields/1`.

**Compile-time validation to add:** every atom in `faceting.attributes` MUST also appear in `filterable:`. This is both a Meilisearch hard requirement (facets require filterable attributes) and a Scrypath correctness rule — surface it at `use Scrypath` time, not at search time.

#### How facet filter validation composes with the existing Query filter parser

**Answer: do NOT widen the common `filter:` kwarg. Add a sibling `facet_filter:` kwarg that validates through a *separate* path, then merges into `%Scrypath.Query{}` as a new field.**

Why not overload `filter:`? The existing filter validator (`options.ex:462-491`) is explicitly narrow: it rejects boolean composition (`:and`, `:or`, `:not`) and only accepts `{field, value}` or `{field, [operator: operand]}` pairs. That narrowness is a **deliberate product decision** (ARCHITECTURE.md lines 30–32 lock the common filter shape). Facets fundamentally need disjunction (`genre = "fiction" OR genre = "mystery"`) — breaking that constraint retroactively would widen the common path and invalidate the "common filter is Ecto-shaped and narrow" contract.

**Recommended shape:**
```elixir
# New option
facet_filter: [
  # Keyword-list-of-atoms-to-value-list per facet attribute
  # Validates: each key appears in schema's faceting.attributes
  #            values match filterable types
  [genre: ["fiction", "mystery"], year: [2024, 2025]]
]
```

**Translation path (new module):**

```
Scrypath.search/3
  → Options.validate_search_options!/2  [validates facet_filter against schema's faceting.attributes]
  → Query.new/2                         [stores facet_filter on %Query{}]
  → Backend.search/3 (Scrypath.Meilisearch)
  → Scrypath.Meilisearch.Query.to_payload/1  [translates to Meilisearch array-of-arrays string syntax]
  → Scrypath.Meilisearch.Client.search/3
```

**Files touched:**
- **New:** add `facet_filter` field to `%Scrypath.Query{}` struct in `lib/scrypath/query.ex` (`defstruct text: nil, filter: [], sort: [], page: %{}, facet_filter: [], facets: []`).
- `lib/scrypath/options.ex` — add `@search_options` entry `facet_filter:` + `validate_facet_filter/1` that checks against `schema_module.__scrypath__(:faceting)`.
- `lib/scrypath/meilisearch/query.ex` — extend `to_payload/1` with `translate_facet_filter/1` producing Meilisearch's array-of-arrays OR syntax (`[["genre = fiction", "genre = mystery"]]`) and `translate_facets/1` for the `facets:` array.
- `lib/scrypath/meilisearch/client.ex:82-89` — no change needed; `search_payload/1` already delegates to `MeilisearchQuery.to_payload/1`.

#### Where facet distribution lives on `SearchResult`

**Answer: extend `%Scrypath.SearchResult{}` additively with a single new key `:facets`.**

The existing struct already keeps the backend-native `raw` map for opt-out power users (`search_result.ex:7`). Facet distribution is a first-class search-result concern in the same way `page` is — it deserves its own top-level field, not to be buried in `raw`.

**Shape:**
```elixir
# lib/scrypath/search_result.ex
@enforce_keys [:query, :hits, :records, :raw, :missing_ids, :page]
defstruct [:query, :hits, :records, :raw, :missing_ids, :page, facets: %{}]

@type t :: %__MODULE__{
  ...
  facets: %{atom() => %{facet_values: %{String.t() => non_neg_integer()}, stats: map()}}
}
```

Note: `facets:` is NOT in `@enforce_keys` — that preserves backward compatibility. All previously-constructed `%SearchResult{}` instances keep working; `.facets` defaults to `%{}` when absent.

**Files touched:**
- `lib/scrypath/search_result.ex` — add `facets` field with default `%{}`, add private `facets(raw)` helper mirroring the existing `page(raw)` pattern (extract both `facetDistribution` and `facetStats` from raw Meilisearch response, keyed by atom for Elixir-idiomatic consumption).
- `lib/scrypath/search.ex:42-46` — `decorate_result/4` passes through untouched; the `SearchResult.new/4` call already receives the full `raw_result`.

---

### (b) Relevance Tuning

#### Where the declarations live: schema vs config

**Answer: schema metadata, not runtime config. Extend the existing `settings:` key — don't add parallel top-level keys.**

The `settings:` map already lives in `@schema_options` and already flows through the existing reindex pipeline via `Scrypath.Meilisearch.Settings.resolve/2` (`lib/scrypath/meilisearch/settings.ex:8-12`). Synonyms, typo tolerance, ranking rules, distinct attribute, and stop words are **already** Meilisearch settings — they naturally belong in the same map that flows through `apply_settings`.

However, the current shape is unstructured (`%{}` default, loosely validated). v1.3 should add **structured subkeys with validation** rather than relying on raw Meilisearch JSON keys:

```elixir
settings: %{
  synonyms: %{"nyc" => ["new york"], "tv" => ["television"]},
  typo_tolerance: %{enabled: true, min_word_size_for_typos: %{one_typo: 5, two_typos: 9}},
  ranking_rules: [:words, :typo, :proximity, :attribute, :sort, :exactness, "released_at:desc"],
  distinct_attribute: :product_line,
  stop_words: ["the", "a", "an"]
}
```

Rationale for staying in `settings:` rather than creating `relevance:`:
1. **Reindex pipeline already handles it.** `lib/scrypath/reindex.ex:23-25` calls `meilisearch.apply_settings/3` which calls `Settings.resolve/2` which reads `schema_module |> Scrypath.schema_settings() |> Map.merge(...)`. Zero pipeline restructure needed.
2. **Avoids a second public concept.** `settings` is already the user-facing word. Splitting into `relevance` vs `settings` would create two near-synonymous config surfaces.
3. **Meilisearch-native translation is one shape, not two.** The `PATCH /indexes/:uid/settings` endpoint takes one merged body — Scrypath's internal representation should mirror that.

**New work:** the translation layer in `Scrypath.Meilisearch.Settings` needs to convert Scrypath-owned Elixir shapes (snake_case atoms, Elixir types) to Meilisearch's camelCase JSON:

```elixir
# Before (current): settings map passed raw to client
Client.update_settings(index_name, settings, config)

# After: translate first
Client.update_settings(index_name, translate_settings(settings), config)
```

Put `translate_settings/1` **in `lib/scrypath/meilisearch/settings.ex`** — not in `Scrypath.*`. That keeps snake_case→camelCase Meilisearch-native mapping confined to the namespaced adapter.

#### How reindex applies them safely without breaking concurrent sync

The existing fixed reindex order (`reindex.ex:20-44`) already solves this:

```
create target_index → apply settings to target → backfill target → optional cutover
```

Settings always land on the **target** index, never the live one. Concurrent sync continues writing to the live index throughout. Cutover is a single atomic swap via `/swap-indexes`. This is already correct for relevance tuning — no pipeline change needed beyond translation.

**One new safety check to add:** `Scrypath.Reindex.run/2` should **refuse to cutover** if the caller's declared `settings` in schema metadata differs from what was actually applied to the target. Today the result just returns `settings_applied: true` without verification. For relevance tuning — where misapplied ranking rules silently ruin search quality — add a post-apply verification step that reads back the target's settings and compares.

**Files touched:**
- `lib/scrypath/meilisearch/settings.ex` — add `translate_settings/1`, add typed validators per subkey.
- `lib/scrypath/options.ex` — replace current `validate_settings/1` (accepts any map) with a NimbleOptions-based nested schema validating `synonyms`/`typo_tolerance`/`ranking_rules`/`distinct_attribute`/`stop_words`.
- `lib/scrypath/reindex.ex` — add optional post-apply verification step (new private `verify_settings_applied/3`) before cutover.
- **No change** to the orchestration order or concurrent-sync semantics.

---

### (c) Multi-Index Search (`Scrypath.search_many/2`)

#### Preserving per-schema validation + hydration without a second-class result shape

**Answer: federated result is a *collection* of `%SearchResult{}`, not a new flat shape.**

The core insight: each schema has its own filterable/sortable/faceting declarations, its own primary key, its own repo/preload. A "flattened" federated hit loses all of that. The only shape that preserves per-schema contracts is **a map of schema → `%SearchResult{}`**.

**Recommended public API:**

```elixir
@spec search_many([{module(), keyword()}], keyword()) ::
  {:ok, %{module() => Scrypath.SearchResult.t()}} | {:error, term()}
def search_many(queries, opts \\ []) when is_list(queries) do
  Scrypath.Search.search_many(queries, opts)
end

# Usage:
Scrypath.search_many([
  {MyApp.Post, text: "elixir", filter: [published: true]},
  {MyApp.User, text: "elixir", filter: [active: true]}
], repo: MyApp.Repo)
# => {:ok, %{MyApp.Post => %SearchResult{...}, MyApp.User => %SearchResult{...}}}
```

Why this shape and not a flat `[Hit]`:
- Every `%SearchResult{}` in the map was validated through the same `Options.validate_search_options!/2` path as `Scrypath.search/3` would produce — no duplicated validation code, no second-class "federated hit" that bypasses filterable/sortable checks.
- Hydration stays per-schema: each entry runs `Hydration.hydrate/3` against that schema's repo/primary key.
- No new public struct type. The SearchResult contract is intact.

**Internal orchestration** (where to put the Meilisearch-native federation):

Meilisearch 1.3+ supports a native `/multi-search` endpoint that batches N index searches in one round-trip. That's the performance win — but it's backend-specific and therefore belongs under `Scrypath.Meilisearch.*`.

```
Scrypath.search_many/2 (public)
  → Scrypath.Search.search_many/2 (new, private)
    → per-entry: Options.validate_search_options!/2 + Query.new/2
    → Backend.search_many/3 (new internal seam callback)
      → Scrypath.Meilisearch.search_many/3 (batches into /multi-search)
        → Scrypath.Meilisearch.Client.multi_search/2
    → per-entry: decorate_result/4 produces %SearchResult{}
  → {:ok, %{schema => %SearchResult{}}}
```

**Adding to the `Scrypath.Backend` behaviour:**

ARCHITECTURE.md lines 62–70 define the current callbacks: `name/0`, `index_name/2`, `upsert_documents/3`, `delete_documents/3`, `search/3`. Adding `search_many/3` is behaviour-safe for a single-backend v1.3 (only `Scrypath.Meilisearch` must implement it). Give it a default implementation that falls back to N sequential `search/3` calls so the seam isn't structurally blocked by `/multi-search`-specific semantics:

```elixir
@callback search_many([{module(), Query.t()}], config()) ::
  {:ok, [{module(), map()}]} | {:error, term()}

@optional_callbacks search_many: 2
```

**Files touched:**
- **New module** `lib/scrypath/search.ex` — add `search_many/2` alongside existing `search/2`.
- `lib/scrypath.ex` — add public `search_many/2` delegate.
- `lib/scrypath/backend.ex` — add optional callback.
- `lib/scrypath/meilisearch.ex` — add `search_many/3` impl.
- **New** `lib/scrypath/meilisearch/multi_search.ex` — Meilisearch-native `/multi-search` payload building and response unpacking (keeps the Meilisearch-specific JSON shape out of `Client`).
- `lib/scrypath/meilisearch/client.ex` — add `multi_search/2` HTTP wrapper.

---

### (d) Extending `FailedWork.t()` — struct itself or companion?

**Answer: extend the struct itself. Do not add a companion.**

Evidence from current code:
- `FailedWork.t()` already has `metadata: map()` as the escape valve for backend-specific detail (`lib/scrypath/operator/failed_work.ex:28`, line 119–124 and 142–146).
- `@enforce_keys` is `[:id, :schema, :mode, :source, :operation, :state, :retryable?]` — everything else is already optional. Adding fields is additive.
- `recovery: nil` and `metadata: %{}` defaults set the pattern: new optional fields default to a benign value.

Target additions for v1.3 per milestone goal (attempt count, error reason class, last attempt timestamp):

```elixir
defstruct [
  :id, :schema, :mode, :source, :operation, :state, :retryable?,
  :reason, :failed_at,
  recovery: nil,
  metadata: %{},
  # NEW v1.3 fields:
  attempt: nil,           # non_neg_integer() | nil  — attempt count
  max_attempts: nil,      # non_neg_integer() | nil
  reason_class: nil,      # :transport | :backend_rejected | :validation | :queue_discard | :unknown
  last_attempt_at: nil    # DateTime.t() | nil
]
```

**Why not a companion struct?** Three reasons:
1. **Consumers would have to look in two places.** Operators today call `Scrypath.failed_sync_work/2` and pattern-match `%FailedWork{}`. A companion forces `Scrypath.failed_work_details(work)` — extra API surface for no win.
2. **Both existing sources (Meilisearch task + Oban job) already populate all the new fields.** Attempt count is already on Oban jobs (`attempt`, `max_attempts` fields); Meilisearch tasks carry `finishedAt` → maps to `last_attempt_at`. The struct just needs to read them. Nothing conceptually warrants a separate shape.
3. **`metadata: map()` is already the open-ended escape hatch.** If something later turns out to be truly backend-specific, it belongs in `metadata`, not in a new struct.

**Build order inside (d):** add the fields with defaults first (backward compatible), then populate in `from_backend_task/3` and `from_queue_job/3`, then update typespec, then update operator verification evidence.

**Files touched:**
- `lib/scrypath/operator/failed_work.ex` — add fields to `defstruct` + `@type`; populate in both `from_backend_task/3` and `from_queue_job/3` (most data already flows in via Oban's and Meilisearch's native fields).
- `test/scrypath/operator/failed_work_test.exs` — add assertions.
- No change to `Scrypath.*` public API surface — the struct change is purely additive.

---

### (e) Phase Ordering

**Recommendation: Relevance tuning FIRST, then faceting, then multi-index, then operator polish + tooling debt.**

Reasoning walks the dependency graph:

1. **Relevance tuning (settings extension) is the narrowest change and unblocks everything downstream.** It only modifies the schema DSL, `Options.validate_settings`, and `Scrypath.Meilisearch.Settings` translation. It touches the reindex pipeline but the pipeline orchestration order doesn't change. No `%Query{}` or `%SearchResult{}` changes. Crucially, it establishes the **translation-layer pattern** (snake_case Scrypath atoms → camelCase Meilisearch JSON in `Scrypath.Meilisearch.*`) that faceting then reuses.

2. **Faceting goes second because it builds on that translation pattern and needs `%Query{}` + `%SearchResult{}` extensions.** Once relevance tuning has proven "Scrypath-owned shape in, backend-native shape out, translation confined to the namespaced adapter" works, faceting extends both structs additively without inventing a new pattern.

3. **Multi-index comes third because it depends on the per-schema search+validation flow being solid.** `search_many/2` fans out N calls through the already-extended `%Query{}`/`%SearchResult{}` path. Doing multi-index first would force rework: every facet/relevance addition would then have to be re-proven through the federated path.

4. **Operator polish + tooling debt close the milestone.** The `FailedWork` extension is isolated — zero coupling to search features. It can slot anywhere, but running it last means operator docs get to reference the new relevance/facet/multi-search features in the drift recovery guide. Release/tooling debt (GitHub Actions Node 20, missing v1.2 VALIDATION.md artifacts) is pure plumbing and should be its own terminal phase so its verification gate is uncontaminated.

**Counterargument considered:** "Do faceting first because it's the highest-visibility persona-facing feature." Rejected because faceting needs the settings-translation pattern and validates the `%SearchResult{}` additive-extension approach — proving those on the *smaller* relevance change first de-risks the larger faceting change. If the smaller change breaks any public contract, the fix is narrower.

**Suggested phase layout (what the roadmapper should adopt):**

| Phase | Scope | Depends on | Why here |
|---|---|---|---|
| 18. Relevance Tuning | Structured `settings:` subkeys (synonyms/typo/ranking/distinct/stop words), translation layer in `Meilisearch.Settings`, reindex verify-before-cutover | v1.2 (merged) | Narrowest change; establishes Scrypath-owned → Meilisearch-native translation pattern reused by phase 19 |
| 19. Faceting | `faceting:` schema key, `facet_filter:`/`facets:` on `%Query{}`, `facets:` on `%SearchResult{}`, `Meilisearch.Query` translation, LiveView guide | 18 | Reuses translation pattern from 18; additive `%SearchResult{}` extension |
| 20. Multi-index Search | `Scrypath.search_many/2`, optional `Backend.search_many/3` callback, `Meilisearch.MultiSearch`, `/multi-search` client | 19 | Fans out through stabilized `%Query{}`/`%SearchResult{}` path |
| 21. Operator Polish + Drift Recovery Guide | `FailedWork.t()` additive fields (`attempt`, `reason_class`, `last_attempt_at`, `max_attempts`), end-to-end drift recovery guide referencing new search features | 20 | Orthogonal to search features; drift guide references them |
| 22. Release & Tooling Debt | GitHub Actions beyond Node 20 deprecation; close v1.2 VALIDATION.md artifacts for phases 13/14/15 | independent | Pure plumbing; terminal phase for clean v1.3 milestone closure |

---

## 3. Integration Points (File-Level Ownership)

| Concern | Owning file (new or extend) | New vs. extended |
|---|---|---|
| `faceting:` schema DSL key | `lib/scrypath/options.ex` (`@schema_options`) | extend |
| `faceting` reflection (`__scrypath__(:faceting)`) | `lib/scrypath/schema.ex` | extend |
| `schema_faceting/1` helper | `lib/scrypath.ex` | extend |
| `facet_filter:` / `facets:` search options | `lib/scrypath/options.ex` (`@search_options`) | extend |
| `facet_filter` / `facets` on query struct | `lib/scrypath/query.ex` | extend (`defstruct`) |
| Meilisearch facet filter/facets translation | `lib/scrypath/meilisearch/query.ex` | extend |
| `facets` on SearchResult | `lib/scrypath/search_result.ex` | extend (`defstruct` default + helper) |
| Structured relevance subkeys (synonyms/typo/ranking/distinct/stop_words) | `lib/scrypath/options.ex` (replace `validate_settings/1`) | extend |
| snake_case → camelCase relevance translation | `lib/scrypath/meilisearch/settings.ex` | extend |
| Reindex verify-before-cutover | `lib/scrypath/reindex.ex` (new private `verify_settings_applied/3`) | extend |
| `Scrypath.search_many/2` public | `lib/scrypath.ex` + `lib/scrypath/search.ex` | extend |
| `Backend.search_many/3` callback | `lib/scrypath/backend.ex` | extend (optional callback) |
| Meilisearch multi-search adapter | **new:** `lib/scrypath/meilisearch/multi_search.ex` | new |
| Meilisearch `/multi-search` HTTP | `lib/scrypath/meilisearch/client.ex` (new `multi_search/2`) | extend |
| Meilisearch backend multi-search impl | `lib/scrypath/meilisearch.ex` (new `search_many/3`) | extend |
| `FailedWork` attempt/reason_class/last_attempt_at fields | `lib/scrypath/operator/failed_work.ex` | extend |

**New modules: two.** (`Scrypath.Meilisearch.MultiSearch`, plus a likely new test helper under `test/support/`.)
**Extended modules: twelve.** All extensions are **additive** — no breaking changes to public structs, no renamed functions.

---

## 4. Data Flow Changes (per feature)

### Faceting flow
```
caller: Scrypath.search(Post, "elixir", facet_filter: [genre: ["fiction"]], facets: [:genre, :year])
  → Options.validate_search_options!/2        [validates facet_filter keys against __scrypath__(:faceting).attributes]
  → Query.new/2                                [%Query{facet_filter: ..., facets: [...]}]
  → Meilisearch.search/3 (Backend impl)
  → Client.search/3 → MeilisearchQuery.to_payload/1
     translate_facet_filter: [["genre = fiction"]]
     translate_facets:       ["genre", "year"]
  → HTTP POST /indexes/.../search
  → Client returns raw with facetDistribution + facetStats
  → Search.decorate_result/4 → SearchResult.new/4 → facets(raw) helper extracts
  → {:ok, %SearchResult{hits: [...], facets: %{genre: %{facet_values: %{"fiction" => 42}, stats: %{}}}}}
```

### Relevance tuning flow (reindex)
```
caller: Scrypath.reindex(Post, cutover?: true, ...)
  → Reindex.run
     → Meilisearch.create_index (target)
     → wait task
     → Meilisearch.apply_settings (target)
        → Settings.resolve: schema settings ⊕ config override
        → Settings.translate_settings: snake_case → camelCase
        → Client.update_settings(target, translated, config)
     → wait task
     → NEW: Reindex.verify_settings_applied(target)   [read-back check]
     → Backfill.run (target)
     → wait batch tasks
     → maybe_cutover (swap-indexes)
```

### Multi-index flow
```
caller: Scrypath.search_many([{Post, [text: "x"]}, {User, [text: "x"]}], repo: R)
  → Scrypath.Search.search_many/2
     → Enum.map: Options.validate_search_options!/2 per-schema (fails loud on any schema)
     → Enum.map: Query.new/2 per-schema
     → Backend.search_many/3 (one batched /multi-search call)
     → Enum.map: decorate_result/4 → SearchResult.new/4 per-schema
  → {:ok, %{Post => %SearchResult{}, User => %SearchResult{}}}
```

---

## 5. Quality-Gate Checklist Verification

- [x] **Integration points named at file level** — section 3 lists every file path.
- [x] **New vs. modified modules explicit** — two new files (`multi_search.ex` + support), twelve extensions.
- [x] **Build order considers dependencies** — section 2(e) derives ordering from the pattern dependency graph (translation pattern → query/result struct extension → federation → orthogonal polish).
- [x] **`Scrypath.Meilisearch.*` backend-native boundary preserved** — facet-filter string syntax, `/multi-search` JSON, camelCase settings keys all confined to `Scrypath.Meilisearch.*`; callers see only Scrypath-owned Elixir shapes.
- [x] **Internal operations seam not bypassed by new public API** — `search_many` routes through `%Scrypath.Query{}` and `%SearchResult{}`; relevance reindex continues to use `Scrypath.Operations.Task`/`Result` via existing `maybe_wait_for_result_task`; `FailedWork` extensions stay inside the already-Scrypath-owned operator struct.
- [x] **No breaking changes to existing public shapes** — `%SearchResult{}` extension is a new defaulted field outside `@enforce_keys`; `%Query{}` extension is two new defaulted fields; `%FailedWork{}` extensions are new defaulted fields; sync map and operator structs untouched; the `Backend` behaviour gets only an `@optional_callback`.

---

## 6. Open Questions Roadmapper Should Know About

1. **`NimbleOptions`-nested vs. plain-map settings validation.** Replacing `validate_settings/1` (currently accepts any map) with structured validation is a small semver risk: users with unusual in-map keys may start getting validation errors. Mitigation: validate **known** subkeys strictly, pass through unknown subkeys unchanged. Flag as "phase 18 plan-level decision."

2. **`Backend.search_many/3` as optional callback vs. required.** Recommending `@optional_callbacks` because (a) v1.3 is still Meilisearch-only, (b) a future backend without native multi-search can always be served by a default N-sequential-calls fallback in `Scrypath.Search`. Phase 20 plan should decide whether to actually ship the fallback or require backends to implement it.

3. **Facet filter values for non-string filterables.** Meilisearch facet filter syntax quotes strings but not numerics. `Meilisearch.Query.format_value/1` already handles this via `Jason.encode!`. Re-verify at phase 19 plan time that all filterable types round-trip correctly through the facet filter path (booleans are the usual gotcha).

---

**Files read for this research:**
- `/Users/jon/projects/scrypath/.planning/PROJECT.md`
- `/Users/jon/projects/scrypath/.planning/milestones/v1.2-ROADMAP.md`
- `/Users/jon/projects/scrypath/ARCHITECTURE.md`
- `/Users/jon/projects/scrypath/lib/scrypath.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/schema.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/search.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/search_result.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/query.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/options.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/meilisearch.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/meilisearch/query.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/meilisearch/settings.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/meilisearch/client.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/reindex.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/operator/failed_work.ex`
- `/Users/jon/projects/scrypath/lib/scrypath/operations/result.ex`
