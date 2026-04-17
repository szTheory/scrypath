# Deep Research — Multi-Index (Federated) Search for Scrypath v1.3

**Scope:** `Scrypath.search_many/2` — one of five target capabilities for v1.3. This document settles the DX design decisions that downstream consumers (Phase 21 roadmap → plan-phase researcher → PLAN.md) need in order to land 4–8 REQ-IDs with acceptance criteria.

**Non-goals locked (hard constraints, verified against `PROJECT.md` + prior research):**
- No second public backend. `Scrypath.search_many/2` is Meilisearch-first like every other v1.3 capability.
- No vector / hybrid / semantic search. Meilisearch federation's optional embedder rerank is ignored.
- No breaking change to the v1.2 public contracts (`%SearchResult{}`, `%Query{}`, `%FailedWork{}`, single-schema `Scrypath.search/3` shape, the `Backend` behaviour's five required callbacks).
- Meilisearch `/multi-search` federation endpoint (stable since v1.12) is the transport.

**Researched:** 2026-04-17
**Confidence:** HIGH (grounded in direct reads of `lib/scrypath/**` at HEAD, Meilisearch `/multi-search` OpenAPI shape, Typesense `/multi_search` docs, Elasticsearch `_msearch` docs, Algolia `multipleQueries` community examples, and Searchkick's `Searchkick.multi_search` signature).

---

## Executive Recommendation

```elixir
Scrypath.search_many(
  [
    {Post,  "elixir", filter: [published: true], page: [size: 5], facets: [:tag]},
    {User,  "elixir", filter: [active?: true]},
    {Event, "elixir"}
  ],
  repo: MyApp.Repo,
  page: [size: 10]     # shared default, overridden per-entry above
)

# => {:ok, %Scrypath.MultiSearchResult{
#      ordered:   [{Post, %SearchResult{}}, {User, %SearchResult{}}, {Event, %SearchResult{}}],
#      by_schema: %{Post => %SearchResult{}, User => %SearchResult{}, Event => %SearchResult{}},
#      failures:  []
#    }}
```

**The six load-bearing decisions** (one-line each, full rationale in "Design Decisions" below):

1. **Call signature = Option A (list of 3-tuples `{schema, text, opts}`) + shared keyword opts.** Matches `Scrypath.search/3` cognitively (`schema, text, opts`) and mirrors Typesense's `searches: [...]` + top-level common params shape. Rejected: Option B (map), Option C (single shared query), Option D (keyword list — schemas aren't keys).
2. **Option layering = shared defaults, per-entry overrides (right-biased merge).** Shared `repo` applies to all. Per-entry `filter:` / `sort:` / `facets:` / `page:` wins locally. Shared `page:` is a *default*, not a union; mirrors Ecto's `Repo.transaction`/`Repo.all`-with-opts composition where call-site opts override defaults.
3. **Return shape = `%Scrypath.MultiSearchResult{}` struct with both `ordered` (list of 2-tuples) and `by_schema` (map) plus an explicit `failures:` list.** Preserves declaration order for LiveView rendering; preserves O(1) by-schema lookup; makes partial failure a first-class field, not a stowaway in `{:ok, %{...}}`.
4. **Partial failure envelope = always `{:ok, %MultiSearchResult{}}` when *any* sub-query succeeds** — failed entries appear in `failures:` with `%{schema: ..., reason: ...}` tuples and are *absent* from `ordered`/`by_schema`. `{:error, reason}` is reserved for *transport/validation-before-dispatch* failures where zero sub-queries ran. This is the "graceful degradation" shape that plays best with Phoenix render-partial patterns.
5. **Facet / relevance interaction = per-schema, always.** `facets:` and `settings:` are declared per schema; `mergeFacets` is NOT passed to Meilisearch; `facetsByIndex` is unpacked back to per-schema `%SearchResult.facets` exactly as if each schema had been searched solo. Cross-schema facet merging is the path Algolia chose and is precisely the coupling Scrypath's "schemas stay decoupled" philosophy forbids.
6. **Hydration concurrency = `Task.async_stream/5` with `max_concurrency: length(schemas)`, `ordered: true`, `timeout: hydration_timeout_ms`.** One parallel pass; per-schema repo/preload preserved; ordered results keep the `ordered:` field in declaration order without a second sort pass. Sequential hydration leaves obvious latency on the table for the 5-schema dashboard fan-out case.

**Cardinality rails (default = "safe for the 5-schema dashboard"):**

| Rail | Default | Rationale |
|---|---|---|
| Max schemas per call | **10** | Matches Meilisearch's comfortable federation range in practice; matches PITFALLS' suggestion; ~2× the canonical "5-schema dashboard" use case. Raisable via opt. |
| Max total hits (federation `limit`) | **200** | Meilisearch federation `limit` default is 20; we raise to 200 because per-schema grouping typically wants enough per-schema depth to paginate. Individual per-schema `page.size` still caps each bucket. |
| Max per-schema page size | **50** | Same ceiling as sensible defaults for `Scrypath.search/3`; user must opt in above. |
| Hydration per-schema timeout | **5_000 ms** | Matches existing `inline_timeout` default in `@runtime_options`. |
| Cumulative federation timeout | **7_500 ms** | Above hydration so a slow schema does not starve others before their results return. |

---

## Reference Library Survey

| Library | Request shape | Response shape | Partial failure | Facets across indexes | Cardinality rails | Takeaway for Scrypath |
|---|---|---|---|---|---|---|
| **Meilisearch `/multi-search`** (native transport) | `{queries: [{indexUid, q, ...}, ...], federation?: {limit, offset, facetsByIndex, mergeFacets, distinct}}` | Federated mode: flat `hits: [...]` with `_federation.indexUid` + `queriesPosition` per hit. Non-federated: results grouped per query. `facetsByIndex: %{uid => {distribution, stats}}` | `remoteErrors` field captures per-remote failure; same-host partial failure semantics are less crisp — verify at plan time. No full-error-on-one-bad-query. | `facetsByIndex` per-index structure; optional `mergeFacets.maxValuesPerFacet` for a merged view (rejected for Scrypath). | None documented in the OpenAPI schema. | Use federated mode to get `_federation.indexUid`, then unpack back to per-schema at the Scrypath layer; skip `mergeFacets`. |
| **Typesense `/multi_search`** | `{searches: [{collection, q, ...}, ...], ...common params}` with explicit `union: true` to merge, default is federated | Federated: `{results: [...]}` "guaranteed to be in the same order as the queries you send" | Not documented in the public docs page (verify at plan time). | Not aggregated across collections in federated mode. | `limit_multi_searches` caps concurrent searches per request (default **50**). | **Best signature match** for Scrypath: explicit top-level common params + per-search params, order preserved, no implicit merging. Directly informs our cardinality cap (we pick **10**, tighter than Typesense's 50, to match Scrypath's more opinionated posture). |
| **Elasticsearch `_msearch`** | ND-JSON: alternating `{index: ...}\n{query: ...}\n` lines | `{responses: [{...}, {...}]}` aligned to request order | Individual responses carry their own error per-entry; one bad sub-query does not fail the whole request. | Aggregations returned per-response; never auto-merged. | `max_concurrent_searches` defaults to `max(1, data_nodes * min(thread_pool, 10))`; `max_concurrent_shard_requests` per sub-search. | **Canonical partial-failure pattern**: always 200 OK with per-entry errors. Directly informs our `failures:` list shape — we adopt the "one sub-query errors, others still succeed" semantic, but expose it more explicitly than ES buries it in the `responses[i].error` field. |
| **Algolia `multipleQueries`** (now `search()` with multiple requests) | `{requests: [{indexName, query, ...}, ...], strategy: "none" \| "stopIfEnoughMatches"}` | `{results: [{hits: [...], nbHits, index: ..., ...}, ...]}` — order matches request order; each result carries `index` (index name) | Individual result errors surfaced per-entry, similar to ES. | No auto-merge across indexes. | Rate-limited by Algolia plan, not a hard-coded per-request cap. | `strategy: stopIfEnoughMatches` is tempting but overkill — Scrypath's `search_many` users want all results, not "stop at first hit." Rejected. We borrow the order-preservation contract. |
| **Searchkick `Searchkick.multi_search`** (Ruby) | Array of `Model.search("q", execute: false)` lazy queries, then `Searchkick.multi_search([q1, q2, q3])` | Each query object becomes result-bearing in-place (side-effect style); no grouped struct | Errors do NOT raise — caller must check `.error` on each query. | No auto-merge. | None. | **Closest idiomatic precedent** for what we're doing. But Ruby's side-effect-on-object style is not idiomatic Elixir. We take Searchkick's "don't raise, return partial" philosophy and translate to immutable Elixir structs. |
| **algoliasearch-rails `search_index!(:all)`** | Global search against all indexed models | Flat hit list tagged by model | Binary success / failure | Merged hits, model tag on each | Hard-coded to "all indexed models" — no explicit list | **Exactly the anti-pattern** FEATURES.md warned about. We require an explicit schema list — no `:all`, no hidden registry. |
| **GraphQL DataLoader** (reference for batching + partial-failure) | Batched keys grouped by loader | `[{:ok, val} | {:error, reason}]` aligned by input key | Per-input-key errors; others succeed | N/A | N/A | Informs our `failures:` list → per-schema `{:error, reason}` rather than `{:error, "one of them failed"}`. Also informs: separate validation-error paths from dispatch-error paths. |
| **Elixir `Task.async_stream/5`** | `Task.async_stream(enum, fun, opts)` with `max_concurrency`, `ordered`, `timeout`, `on_timeout` | Stream of `{:ok, result} | {:exit, reason}` | Built-in — partial failures are native to the stream shape | N/A | `max_concurrency`, `timeout` | **Direct implementation primitive** for concurrent hydration (Decision 6). Per-schema repos map naturally to per-task work. |

**Winner of the "closest DX match" race: Typesense.** Typesense's `searches: [...]` + top-level common params is the most elegant fit for Scrypath's "one Scrypath.Options validator per sub-request, shared opts at top level" layering. The `{schema, text, opts}` tuple is our Elixir-idiomatic translation of Typesense's per-search map.

---

## Design Decisions

### 1. Call signature — Option A (list of tuples `{schema, text, opts}`) + shared opts

**Recommendation: Option A** — `search_many([{Schema, "query", per_opts}, ...], shared_opts)`.

**Why:**
- **Single-schema cognitive continuity.** `Scrypath.search(Post, "elixir", opts)` → `Scrypath.search_many([{Post, "elixir", opts}, ...], shared_opts)`. The tuple is literally the argument triple you would pass to `search/3`. No new grammar; every `search/3` example composes directly into `search_many/2`.
- **Inline one-liner ergonomics.** `Scrypath.search_many([{Post, "q"}, {User, "q"}], repo: R)` — 2-tuple form (`{schema, text}`) elides empty opts, reads like a Python-dict-lookalike without the punctuation cost of maps.
- **5-schema dashboard readability.** A vertical list of `{Schema, "q", opts}` tuples reads top-to-bottom as "search these things in this order" with per-entry opts visually aligned; the map form (Option B) buries the schema key among text/opts keys.
- **Validation parity.** `Options.validate_search_options!(Schema, opts)` runs exactly once per tuple — zero new validation code. No pre-merge across schemas means per-schema `filterable`/`sortable`/`faceting` declarations remain independently enforced (PITFALLS P6 mitigated structurally).

**Rejected alternatives:**

| Option | Why not |
|---|---|
| **B — list of maps**: `[%{schema: Post, text: "q", opts: [...]}, ...]` | Heavier syntax for zero benefit. Schema is not conceptually "one key among many" — it's the *identity* of the sub-query. Maps read badly in Elixir for ordered positional data; tuples are the idiomatic shape. Also collides visually with `%Scrypath.Query{}` and `%SearchResult{}` struct literals. |
| **C — shared query text + per-schema opts**: `search_many("query", [{Post, post_opts}, ...], shared_opts)` | Breaks the core dashboard use case: `{Post, "recent posts about Elixir"}` vs `{User, "users named Elixir"}` is common (global-search bars *do* want the same text, but federated-dashboard and "search across A with filters, B with different filters" doesn't). Forcing one text reintroduces the shared-opts coupling PITFALLS P6 warns against. Also locks out future "per-schema query text rewriting" (synonyms differ per schema). |
| **D — keyword list**: `search_many(post: [text: "q", ...], user: [text: "q", ...])` | Schemas are modules, not atoms. Using `:post` as a key forces a registry lookup (`Post` module from `:post` atom) which is exactly the hidden-global-registry anti-feature FEATURES.md rejects. Also: Elixir keyword lists collapse duplicate keys, so searching the same schema twice (`Post` with two different filter sets for a comparison UI) would silently deduplicate. |

**DX rationale:** Option A is the only signature where *every* idiom in `search/3` composes losslessly into `search_many/2`. That is the governing property — Scrypath's existing `search/3` examples become `search_many/2` examples by visual wrap, not by rewrite.

**Best reference:** Typesense `{searches: [{collection, q, ...}, ...]}` — top-level + per-search params.
**Worst reference:** algoliasearch-rails `search_index!(:all)` — implicit global registry anti-pattern.

**v1.3 phase plan implication:** The `Backend.search_many/3` `@optional_callback` takes `[{module(), %Query{}}]` (already-validated, already-normalized internal form) + `config`. The public-to-internal translation happens once in `Scrypath.Search.search_many/2` before dispatching to the backend.

---

### 2. Shared-vs-per-schema option layering — shared defaults, per-entry overrides (right-biased merge per key)

**Recommendation:** Shared opts provide defaults; per-entry opts override on a **per-key basis** (not whole-opts replacement).

**The layering rule, precisely:**

```
for each entry {schema, text, per_opts}:
  effective_opts_for_schema = shared_opts |> Keyword.merge(per_opts)
  # Keyword.merge is right-biased: per_opts keys win when present
  Options.validate_search_options!(schema, effective_opts_for_schema)
```

**Worked examples:**

| Call | Effective per-schema opts |
|---|---|
| `search_many([{Post, "q", []}], repo: R, page: [size: 10])` | Post gets `repo: R, page: [size: 10]` |
| `search_many([{Post, "q", page: [size: 5]}], repo: R, page: [size: 10])` | Post gets `repo: R, page: [size: 5]` — per-entry `page:` **fully replaces** shared `page:` (not "merged inside `page:`") |
| `search_many([{Post, "q", filter: [published: true]}], repo: R)` | Post gets `repo: R, filter: [published: true]` |
| `search_many([{Post, "q", repo: R2}], repo: R)` | Post gets `repo: R2` — per-entry override wins on shared `:repo` too |

**Why whole-keyword replacement (not nested merge):**
- Nested merge (`shared page: [size: 10]` + `per-entry page: [number: 3]` → `[size: 10, number: 3]`) looks convenient but reintroduces the "silent cross-entry coupling" PITFALLS warns about. A caller who sets `page: [size: 5]` locally is explicitly reasoning about that schema's pagination; picking up `size: 10` from shared opts violates that reasoning.
- `Keyword.merge/2` is the canonical right-biased merge in the stdlib — using anything more elaborate (`DeepMerge`, custom recursive merger) invents a semantic we'd then have to document and version.
- Matches Ecto's composition posture: `Repo.all(query, prefix: "tenant1")` does not silently merge with anything from `Application.get_env(:my_app, MyRepo)[:prefix]`; call-site opts override.

**Reference calibration:**

| Library | Layering |
|---|---|
| Ecto `Repo.transaction(fun, opts)` | Call-site opts override config-level timeouts on whole-key basis. |
| Ecto `Repo.preload(records, preloads, opts)` | `opts` override defaults on whole-key basis; nested keyword preloads are *not* deep-merged with previous preloads. |
| Typesense `/multi_search` | Top-level common params apply to all searches; per-search params override. Exactly our pattern. |
| ES `_msearch` | Header line overrides request-level `index:`, `type:`, `search_type:` on whole-key basis. |

**Whitelist of keys valid in shared opts** (phase plan clarification needed):

- **Runtime transport / hydration keys** (apply to all unless overridden): `repo`, `preload`, `backend`, `meilisearch_url`, `meilisearch_api_key`, `meilisearch_client`, `req_options`, `inline_poll_interval`, `inline_timeout`.
- **Federation-global keys** (shared only, no per-entry meaning): `federation_limit`, `federation_offset` — map directly to Meilisearch federation mode's top-level `limit`/`offset`. These govern cross-schema result slicing (next section) and are meaningless per-entry.
- **Per-query search keys** (shared = default, per-entry = override): `filter`, `sort`, `page`, `facets`, `facet_filter`.

**Rejected: shared `filter:` key fanning out to schemas.** A shared `filter: [published: true]` would require *every* schema in the list to declare `published` as `filterable:`, otherwise validation raises per-schema and the whole call fails (Pitfall 6 exactly). **Mitigation:** document explicitly that `filter:` in shared opts is a default only; validation runs per-schema and failure in any schema's validation short-circuits the call with `{:error, {:validation_failed, schema, reason}}`.

**DX rationale:** Operators reason about per-schema opts locally; shared opts are for the boring cross-cutting concerns (`repo:`, transport, federation limits). This matches how Phoenix LiveView code actually composes — the mount assigns the repo once and the event handler writes per-card filters locally.

**Best reference:** Ecto's right-biased `Keyword.merge/2` composition across `Repo.*` functions.
**Worst reference:** Any library that deep-merges nested keyword options silently (no exemplar named; universally disliked).

**v1.3 phase plan implication:** Two REQ-IDs — one for the merge semantics (REQ MULTI-02), one for the shared-opts whitelist validator that rejects keys that are *only* meaningful per-entry (REQ MULTI-03).

---

### 3. Return shape — `%Scrypath.MultiSearchResult{}` with `ordered` + `by_schema` + `failures`

**Recommendation:** A new Scrypath-owned struct:

```elixir
defmodule Scrypath.MultiSearchResult do
  @enforce_keys [:ordered, :by_schema, :failures]
  defstruct [:ordered, :by_schema, :failures, :federation]

  @type t :: %__MODULE__{
          ordered:    [{module(), Scrypath.SearchResult.t()}],
          by_schema:  %{module() => Scrypath.SearchResult.t()},
          failures:   [%{schema: module(), reason: term()}],
          federation: map() | nil
        }
end
```

**Why a struct (and why both views):**
- **`ordered:` (list of 2-tuples)** preserves declaration order. Phoenix LiveView's `for {schema, result} <- @results.ordered` renders deterministically, which matches how users *wrote* the call. Map iteration order in Elixir is not guaranteed for non-`struct`-derived maps — relying on it is a sharp edge.
- **`by_schema:` (map)** provides O(1) lookup. The common "pull Post results to render in the sidebar, ignore the rest" pattern uses `result.by_schema[Post]` in-template.
- **`failures:` (list)** is a first-class field. Partial failures stop being a surprise — they're guaranteed present (empty list when all succeed) and a LiveView can trivially check `@results.failures != []` for a degradation banner.
- **`federation:` (optional map)** exposes the federation-level metadata from Meilisearch (`estimated_total_hits`, `processing_time_ms`, federation `limit`/`offset`). Nil when one sub-query failed the transport (keeps the struct non-misleading).

**Why not the three alternatives:**

| Alternative | Pro | Con | Verdict |
|---|---|---|---|
| `%{module() => SearchResult.t()}` (bare map) | Simplest typing | Map iteration order not guaranteed → rendering order not stable across BEAM versions; `failures` have to hide inside `{:error, reason}` stowaways which `Enum.into` mangles | Rejected |
| `[{module(), SearchResult.t()}]` (list of tuples) | Order-preserving; Elixir-idiomatic | O(N) `List.keyfind/3` for by-schema lookup; `failures` have to hide inside `{module(), {:error, reason}}` tuples which breaks typespecs | Rejected as the *only* view |
| `%{ordered: [...], by_schema: %{...}}` (bare map with both views) | Both benefits | Unopinionated; loses the chance to make `failures` a first-class slot; forces consumers to pattern-match a map shape that can silently drift | Rejected — a struct is the right container |

**Why `@enforce_keys` is safe here (unlike on `SearchResult`):** `MultiSearchResult` is a **new struct in v1.3** with no shipped consumers. We can and should enforce the three mandatory fields from day one, per the "new public struct = tight contract" rule. The `@enforce_keys` warning in PITFALLS P2/P3 applies to *existing* structs that have 0.3.0 consumers.

**Phoenix LiveView rendering pattern this enables:**

```heex
<section :for={{schema, result} <- @results.ordered} class={"section-#{schema_slug(schema)}"}>
  <h2><%= schema_label(schema) %></h2>
  <.result_card :for={record <- result.records} record={record} />
</section>

<aside :if={@results.failures != []} class="degradation-banner">
  Partial results:
  <span :for={%{schema: schema} <- @results.failures}>
    <%= schema_label(schema) %> unavailable
  </span>
</aside>
```

**`Enum.into` round-trip:** `Enum.into(result.ordered, %{})` → same map as `result.by_schema`. That's the pattern consumers will use if they want a *third* derived view; we don't need to pre-compute it.

**DX rationale:** The struct makes the three most common access patterns (ordered render, by-schema lookup, failure check) all first-class and all equally discoverable via `t:Scrypath.MultiSearchResult.t/0`. No hidden stowaways, no map-iteration-order footguns.

**Best reference:** The LiveView idiom `for {x, y} <- @something` universally expects a list of tuples. We provide that directly as `ordered:`.
**Worst reference:** Returning `{:ok, %{...}}` where the map is the primary data and `%MultiSearchResult{}` doesn't exist — invites both the ordering and the stowaway failure problems.

**v1.3 phase plan implication:** One REQ-ID (REQ MULTI-04) for the struct; one (REQ MULTI-05) for `ordered`/`by_schema` parity (`by_schema == ordered |> Enum.into(%{})` as a property test invariant).

---

### 4. Partial failure envelope — `{:ok, %MultiSearchResult{failures: [...]}}` for any-sub-query-succeeded case

**Recommendation:**

| Scenario | Return |
|---|---|
| All N sub-queries succeed | `{:ok, %MultiSearchResult{ordered: [...N tuples], by_schema: %{...}, failures: []}}` |
| K of N sub-queries succeed (0 < K < N) | `{:ok, %MultiSearchResult{ordered: [...K tuples in declaration order, skipping failures], by_schema: %{...K keys}, failures: [%{schema: FailedSchema, reason: ...}, ...]}}` |
| All N sub-queries fail (transport down, all invalid) | `{:error, {:all_failed, [%{schema: ..., reason: ...}, ...]}}` |
| Pre-dispatch validation failure (any schema's opts don't validate) | `{:error, {:validation_failed, schema, reason}}` — short-circuits before *any* dispatch |
| Pre-dispatch options failure (bad shared opts, bad call shape) | `{:error, {:invalid_options, reason}}` — raises on `search_many!/2` |

**The "any sub-query succeeded → `:ok`" rule is load-bearing.** This is the single most important DX decision in this document. Rationale:

1. **Phoenix render partials want to render what they can.** A dashboard that shows 4 of 5 sections is valuable; forcing an all-or-nothing `{:error, ...}` for one flaky schema forces every LiveView to write its own retry/catch-and-partial-render logic.
2. **Elasticsearch `_msearch` sets the industry precedent.** ES always returns 200 OK with per-entry errors, and this is the pattern Meilisearch `/multi-search` follows via `remoteErrors`. Our `{:ok, ...}` with `failures:` list is the Elixir-idiomatic translation.
3. **Scrypath's "operational honesty" posture.** Returning `:ok` with `failures: [...]` is *more* honest than hiding degradation behind `{:error, ...}` — the degradation is named, typed, and queryable.

**The "all failed = `:error`" rule prevents misleading empty results.**
- If every sub-query errored, returning `{:ok, %MultiSearchResult{ordered: [], by_schema: %{}, failures: [...N entries]}}` looks like "search succeeded with no hits."
- Forcing `{:error, {:all_failed, [...]}}` here is the loud, unmissable signal the caller actually needs.

**The "pre-dispatch validation = `:error`" rule preserves per-schema validation honesty.**
- If `Options.validate_search_options!(Post, effective_opts)` raises (filter on non-filterable field), `search_many/2` short-circuits with `{:error, {:validation_failed, Post, "filter field :internal is not declared as filterable"}}`.
- Zero dispatch happens. No partial results. This matches single-`search/3` behavior where an invalid filter raises, and it matches the principle "validation lives before the network."

**Rejected alternatives:**

| Shape | Why rejected |
|---|---|
| `{:ok, %{working => SearchResult, failed => {:error, reason}}}` (mixed values in one map) | Typespec nightmare (`%{module() => SearchResult.t() \| {:error, term()}}`); breaks all `Enum.map` pipelines that assume value type; hides `failures` as stowaways. |
| `{:partial, %{...}, [{failed, reason}]}` (three-tagged tuple) | Third return shape forces every call site to `case` on three arms (`:ok`, `:partial`, `:error`). Phoenix `with` pipelines become ugly. Inventing `:partial` as a new atom burdens every downstream pattern-match. |
| `{:error, %{failed => reason, ok: %{...}}}` (`:error` wraps both) | "Partial success returns `:error`" is the exact counter-intuitive trap this document argues against. Forces even the successful-sibling renderers to unwrap errors. |

**Phoenix error rendering comparison:**

```elixir
# Recommended shape:
case Scrypath.search_many(queries, shared_opts) do
  {:ok, %MultiSearchResult{} = results} ->
    socket
    |> assign(:results, results)
    |> maybe_add_degradation_flash(results.failures)
  {:error, {:all_failed, failures}} ->
    socket |> put_flash(:error, humanize_all_failed(failures))
  {:error, {:validation_failed, schema, reason}} ->
    socket |> put_flash(:error, "Bad filter on #{inspect(schema)}: #{reason}")
end

# vs. the rejected 3-tagged shape's equivalent:
case Scrypath.search_many(queries, shared_opts) do
  {:ok, results} -> ...
  {:partial, results, failures} -> ... # now every LiveView needs this arm
  {:error, reason} -> ...
end
```

The recommended shape collapses the happy + partial paths into one `:ok` arm that idiomatic LiveView code already writes — degradation becomes a data question (`results.failures != []`) not a control-flow question.

**Best reference:** Elasticsearch `_msearch` "always 200, errors are per-entry"; Meilisearch `/multi-search` `remoteErrors` field. Both bake partial-failure-as-data into the transport.
**Worst reference:** Any library returning `{:error, reason}` on single-sub-query failure — Searchkick's raise-per-query is not a model to emulate in Elixir's tagged-tuple idiom.

**v1.3 phase plan implication:** Two REQ-IDs — REQ MULTI-06 for the five-case return shape; REQ MULTI-07 for the `failures:` struct shape (`[%{schema: module(), reason: term()}]` — **no** `{:error, reason}` tagged tuples in the list, because the list itself *is* the failure bucket).

---

### 5. Facet / relevance interaction — per-schema always; no `mergeFacets`; facets returned in each schema's own `%SearchResult{}`

**Recommendation:** Each schema's `faceting:` declaration is scoped to that schema. `search_many/2` passes `facets:` per-entry into Meilisearch's `federation.facetsByIndex.<indexUid>` and unpacks the response's per-index `facetsByIndex` back into each sub-result's `%SearchResult.facets`. **`mergeFacets` is never set.**

**The request-side mapping:**

```elixir
# User call:
Scrypath.search_many([
  {Post,  "elixir", facets: [:tag, :author_id]},
  {Event, "elixir", facets: [:venue_type]}
])

# → Meilisearch /multi-search body (pseudocode):
%{
  queries: [
    %{indexUid: "scrypath_post",  q: "elixir"},
    %{indexUid: "scrypath_event", q: "elixir"}
  ],
  federation: %{
    limit: 200,
    offset: 0,
    facetsByIndex: %{
      "scrypath_post"  => ["tag", "author_id"],
      "scrypath_event" => ["venue_type"]
    }
    # NO mergeFacets key
  }
}
```

**The response-side unpacking:**

```json
{
  "hits": [...],
  "facetsByIndex": {
    "scrypath_post":  {"distribution": {"tag": {"elixir": 42}}, "stats": {...}},
    "scrypath_event": {"distribution": {"venue_type": {"online": 8}}, "stats": {}}
  }
}
```

→ `by_schema[Post].facets` ← `facetsByIndex["scrypath_post"]` normalized
→ `by_schema[Event].facets` ← `facetsByIndex["scrypath_event"]` normalized

**Why per-schema always:**
- **Scrypath's philosophy says schemas stay decoupled.** A merged `facet_distribution` across Post and Event is semantic nonsense (what does `{"tag" => {"elixir" => 42}}` mean when both Post and Event schemas have different `tag` fields? Worse — what if Post has `:tag` as `filterable` but Event doesn't?).
- **Each schema has its own `faceting:` declaration.** There is no concept of a "multi-schema facet" in Scrypath's schema DSL. Exposing one in `search_many/2` results would force us to invent one, which loops back to the non-goal "no dashboard product surface" territory.
- **Algolia's approach (cross-index facet merge) is exactly what Scrypath rejects.** Algolia merges because their "multi-index search" targets a unified-vertical UX (global products across verticals). Scrypath's `search_many/2` targets the "distinct sections on a dashboard" UX.

**Relevance tuning (`settings:`) scope is untouched by federation.** Each schema's declared `settings:` (synonyms, typo_tolerance, ranking_rules, distinct_attribute, stop_words) live on that schema's Meilisearch index and are applied at reindex time. `/multi-search` federation runs against already-configured indexes — it does not accept per-query setting overrides. Cross-schema ranking rule tuning is impossible *and* should remain impossible (Phase B's relevance-tuning contract).

**What happens if a user passes `facets:` to a schema that doesn't have them declared?** Validation short-circuits at `Options.validate_search_options!/2` per Phase C's contract: each facet atom must appear in that schema's `faceting.attributes`. Fails before any dispatch, with `{:error, {:validation_failed, Schema, reason}}`.

**Worked facet example (the 5-schema dashboard):**

```elixir
Scrypath.search_many([
  {Post,    "elixir", facets: [:tag]},
  {User,    "elixir"},  # no facets declared for Users
  {Event,   "elixir", facets: [:venue_type, :region]},
  {Tag,     "elixir"},  # no facets
  {Comment, "elixir", facets: [:approved?]}
], repo: MyApp.Repo)

# Result:
# result.by_schema[Post].facets    == %{tag: %{distribution: ..., stats: ...}}
# result.by_schema[User].facets    == %{}    # empty map, not nil — consistent with single-search
# result.by_schema[Event].facets   == %{venue_type: ..., region: ...}
# result.by_schema[Tag].facets     == %{}
# result.by_schema[Comment].facets == %{approved?: ...}
```

**DX rationale:** A facet UI panel for Posts rendered from `result.by_schema[Post].facets` is identical to the panel the same user wrote from `Scrypath.search(Post, ...)`. Zero new mental model.

**Best reference:** ES `_msearch` — aggregations are always per-response, never merged across responses.
**Worst reference:** Algolia's unified-facet philosophy — the right call for Algolia's market, the wrong call for Scrypath's market.

**v1.3 phase plan implication:** REQ MULTI-08 — `facetsByIndex` request construction uses Meilisearch's `indexUid` derived from `Scrypath.Meilisearch.index_name/2`; response unpacking keys back from `indexUid` → `schema` via the same map Scrypath built on the request side (i.e., we don't rely on Meilisearch to preserve our mapping; we keep a request-side dict).

---

### 6. Hydration layering — `Task.async_stream/5` with per-schema repo/preload, ordered results

**Recommendation:**

```elixir
# After Meilisearch returns federated hits, each already tagged with its schema:
hits_by_schema
|> Task.async_stream(
  fn {schema, hits} ->
    effective_opts_for_schema = shared_and_per_entry_opts[schema]
    repo    = Keyword.fetch!(effective_opts_for_schema, :repo)
    preload = Keyword.get(effective_opts_for_schema, :preload, [])
    {schema, Scrypath.Hydration.hydrate(schema, hits, repo: repo, preload: preload)}
  end,
  max_concurrency: max(length(entries), 1),
  ordered: true,
  timeout: hydration_timeout_ms,
  on_timeout: :kill_task
)
|> Enum.map(fn
  {:ok, {schema, {records, missing_ids}}} -> {:ok, schema, records, missing_ids}
  {:exit, reason} -> {:error, reason}  # hydration timeout or crash → partial failure
end)
```

**Why parallel:**
- Each schema has its own repo; connections are pool-separated; parallelism is essentially free.
- The 5-schema dashboard hydration case sequentially waits on 5 round trips; in parallel it waits on 1 × (slowest round trip).
- PostgreSQL connection pools via DBConnection handle per-repo contention fine.

**Why `Task.async_stream/5` specifically (not `Task.async/await` in a loop, not `Ecto.Multi.run`):**

| Primitive | Fits? | Notes |
|---|---|---|
| `Task.async_stream/5` | **YES** — chosen | Built-in timeout, back-pressure via `max_concurrency`, `ordered: true` preserves declaration order, `:kill_task` on timeout = clean per-task failure handling. Canonical Elixir pattern for "N independent I/O-bound operations, possibly with timeouts, collect results." |
| `Task.async/await` in a loop | No | No built-in per-task timeout; timeout applied to `Task.await_many/2` is cumulative, not per-task; harder to identify which task timed out. |
| `Ecto.Multi.run/3` | No | Transactional semantics are the point of `Ecto.Multi` — but hydration queries don't need to run in a shared transaction (each schema's hits hydrate independently, no write). Using `Multi` here would force them all into one repo's transaction, breaking multi-repo support. |
| `Flow` / `GenStage` | No | Overkill for N ≤ 10 parallel operations; dependency weight not justified. |
| Sequential loop | No | Linear latency; obvious footgun for the 5-schema fan-out UX promise. |

**`ordered: true` is required.** The result stream must align with the declaration order so `ordered:` assembly is O(N) without a second sort step. `Task.async_stream` buffers to preserve ordering — for N ≤ 10 that's negligible.

**`on_timeout: :kill_task` semantics:** A schema whose hydration times out becomes a failure entry in `failures:` (reason: `:hydration_timeout`); the *search* hits for that schema are preserved in `ordered:`/`by_schema:` but with `records: []` and `missing_ids:` == all hit ids. *Alternative to consider at plan time:* should a hydration timeout demote the schema entirely to `failures:`, or should it surface as partial hydration? Plan-phase research decision.

**Critical gotcha from the research:** ecto_sql issue #122 — "Database operations within a task within a transaction in test mode hang indefinitely." Not applicable here because hydration runs *outside* any shared transaction (we're reading per-repo, no shared `Repo.transaction/1`), but must be called out in the test guide to avoid adopter confusion.

**Per-schema repo uniformity is NOT assumed.** Two schemas with different repos work exactly as well as two schemas with the same repo. The shared `repo: MyApp.Repo` in shared_opts applies to schemas that don't override; a per-entry `repo:` override sends a specific schema to a different repo. Use case: read replicas, per-tenant dbs.

**DX rationale:** `Task.async_stream/5` is the Elixir-idiomatic answer to "do N independent things in parallel with timeout." Using it signals to adopters "this is standard Elixir" — no bespoke concurrency model to learn.

**Best reference:** Elixir stdlib `Task.async_stream/5`; this is the pattern every `Enum.map` over I/O-bound work should migrate to when parallelism is free.
**Worst reference:** Sequential `Enum.map` over per-schema queries — works at N=2, becomes obvious latency bug at N=5.

**v1.3 phase plan implication:** REQ MULTI-09 — concurrent hydration with `Task.async_stream` and configurable `hydration_timeout_ms` (default 5_000). Also: document in the LiveView guide that hydration runs under an auto-supervised task (default BEAM `Task`, not `Task.Supervisor` — the latter only matters if the caller is itself a supervised process; single-call usage from a LiveView process is already supervised).

---

### 7. Cardinality rails — defaults sized for "safe for a 5-schema dashboard"

**Defaults (restated from the summary):**

| Rail | Default | Configurable? | Rationale |
|---|---|---|---|
| Max schemas per call | **10** | Yes, via `max_schemas` opt | 2× the canonical 5-schema dashboard. Matches PITFALLS' suggestion. Halves Typesense's `limit_multi_searches` default of 50 because Scrypath's hit→hydration→records fanout amplifies cost. |
| Max per-schema page size | **50** | Yes, via per-entry `page: [size: ...]` | Same ceiling as sensible `Scrypath.search/3` defaults; raise only if the UI genuinely renders >50 items per section (rare). |
| Max total federated hits (`federation.limit`) | **200** | Yes, via shared `federation_limit:` | Caps absolute fanout. 10 schemas × 20 per-schema = 200 feels right. Meilisearch's native default is 20 — we raise because per-schema grouping consumes the quota unevenly. |
| Hydration per-task timeout | **5_000 ms** | Yes, via shared `hydration_timeout:` | Matches existing `inline_timeout` in `@runtime_options`. |
| Federation request timeout | **7_500 ms** | Yes, via shared `req_options` → `receive_timeout` | Above hydration so a slow sub-query doesn't starve the others' hydration. |

**Reference calibration:**

| Library | Max concurrent sub-queries |
|---|---|
| Meilisearch `/multi-search` | Not hard-documented; federation has a soft performance cliff beyond ~20 indexes in practice. |
| Typesense `/multi_search` | `limit_multi_searches: 50` (default) |
| Elasticsearch `_msearch` | `max(1, data_nodes × min(thread_pool, 10))` — scales with cluster. |
| Algolia `multipleQueries` | Plan-tier rate limits, not per-request. |

**Why pick 10 and not something looser:**
- PITFALLS (lines 340–341) explicitly suggests `max schema count (e.g., 10)` for `search_many/2` fan-out.
- 10 is a natural cognitive cliff — past 10, the dashboard designer should reconsider whether federation is the right tool (vs. a single unified index with a `_type` attribute or a Postgres JOIN).
- The opt is easy to raise with evidence; it's hard to lower once adopters rely on unbounded fanout.

**On over-limit behavior:** `{:error, {:too_many_schemas, count, max}}` raised at pre-dispatch. Loud, fast, not a silent truncation. Truncation would be the "works until it doesn't" trap.

**v1.3 phase plan implication:** REQ MULTI-10 — all five rails have opts, all five have defaults, over-limit raises `{:error, ...}` at pre-dispatch.

---

### 8. `missing_ids` semantics — per-schema on each `%SearchResult{}`, never aggregated

**Recommendation:** `missing_ids` stays on each sub-result. It is **never** aggregated across the federation.

**Why:** `missing_ids` is a per-schema concept by construction — it's "hits that Meilisearch returned for this schema but the repo for this schema couldn't find when asked." Aggregating across schemas would require either:
1. A unified ID namespace (IDs from different schemas collide), or
2. Tagging each missing ID with its origin schema (at which point you just reinvented the per-schema grouping).

Either way is worse than keeping them per-schema, which is exactly how single-schema `Scrypath.search/3` already works. No new semantics.

**The result for the 5-schema example:**

```elixir
result.by_schema[Post].missing_ids     == [42, 91]     # Post hits with no Post record
result.by_schema[User].missing_ids     == []           # all User hits hydrated fine
result.by_schema[Event].missing_ids    == [77]
# ... and so on
```

**Operator use case preserved:** A LiveView rendering a degradation banner reads `Enum.flat_map(result.ordered, fn {schema, r} -> r.missing_ids |> Enum.map(&{schema, &1}) end)` to get the tagged flat list if it wants — cheap, explicit, lossless.

**Reference check:** Elasticsearch `_msearch` keeps `_shards.failed` counts per-response; Meilisearch `/multi-search` has no equivalent (Meilisearch doesn't deal in missing IDs, but the principle maps: per-response diagnostics never auto-merge).

**DX rationale:** "Each schema's `%SearchResult{}` looks and behaves exactly like the one `Scrypath.search/3` returns" is the one-sentence mental model. Keeping `missing_ids` per-schema is table stakes for that promise.

**v1.3 phase plan implication:** No new REQ — this is a "it already works this way, preserve it" constraint. Acceptance criterion: test that single-schema `missing_ids` computation for schema S is byte-identical whether called via `search/3` or via `search_many/2` with one entry.

---

### 9. Phoenix LiveView guide — "unified site search that stays decoupled"

**Worked example the v1.3 guide must ship:**

The canonical demo is a `/search` LiveView that hits Post + User + Tag + Event schemas concurrently and renders sectioned results with per-section facet panels. **Server-side state; no client-side InstantSearch component library.** The smallest real example, concretely:

```elixir
defmodule MyAppWeb.SearchLive do
  use MyAppWeb, :live_view
  alias MyApp.{Post, User, Tag, Event}

  @searchable [Post, User, Tag, Event]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", results: nil, selected_tags: [])}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, assign(socket, query: q, results: run_search(q, socket.assigns))}
  end

  @impl true
  def handle_event("toggle_tag", %{"tag" => tag}, socket) do
    selected = toggle(socket.assigns.selected_tags, tag)
    {:noreply,
     socket
     |> assign(:selected_tags, selected)
     |> assign(:results, run_search(socket.assigns.query, %{socket.assigns | selected_tags: selected}))}
  end

  defp run_search("", _), do: nil
  defp run_search(q, %{selected_tags: tags}) do
    post_opts =
      if tags == [],
        do: [facets: [:tag]],
        else: [facet_filter: [tag: tags], facets: [:tag]]

    case Scrypath.search_many(
           [
             {Post,  q, post_opts ++ [filter: [published: true], page: [size: 5]]},
             {User,  q, [filter: [active?: true], page: [size: 5]]},
             {Tag,   q, [page: [size: 10]]},
             {Event, q, [facets: [:venue_type], filter: [visible?: true], page: [size: 5]]}
           ],
           repo: MyApp.Repo,
           federation_limit: 100
         ) do
      {:ok, %Scrypath.MultiSearchResult{} = r} -> r
      {:error, reason} -> {:error, reason}
    end
  end

  defp toggle(list, tag), do: if(tag in list, do: list -- [tag], else: [tag | list])
end
```

```heex
<form phx-submit="search">
  <input name="q" value={@query} placeholder="Search everything..." phx-debounce="200" />
</form>

<%= case @results do %>
  <% nil -> %>
    <p>Type to search.</p>

  <% {:error, reason} -> %>
    <.error_banner reason={reason} />

  <% %Scrypath.MultiSearchResult{} = r -> %>
    <.degradation_banner :if={r.failures != []} failures={r.failures} />

    <div class="grid grid-cols-[1fr_300px]">
      <main>
        <section :for={{schema, result} <- r.ordered}>
          <h2><%= section_label(schema) %> (<%= length(result.records) %>)</h2>
          <div :for={record <- result.records}>
            <.result_row record={record} schema={schema} />
          </div>
        </section>
      </main>

      <aside>
        <.facet_panel
          :if={r.by_schema[Post]}
          title="Filter posts by tag"
          facets={r.by_schema[Post].facets[:tag]}
          selected={@selected_tags}
          event="toggle_tag"
        />
      </aside>
    </div>
<% end %>
```

**Why this example and not something grander:**
- **Four schemas, not five** — still fans out, still exercises multiple-facet and no-facet cases, but fits on one screen of code the reader can scan.
- **Server-side state only.** LiveView assigns hold the query + selected tags; no JS; no InstantSearch client component. This matches Phoenix persona expectations.
- **Facets are per-schema** — only the Post section has a facet panel in this example. Demonstrates that the API doesn't *require* every schema to participate in faceting.
- **Partial failure is explicit** — `<.degradation_banner :if={r.failures != []}>` shows the pattern; Pitfall-6 mitigation becomes a 2-line template change, not a 40-line `with` chain.
- **Realistic opts mix** — `filter:`, `page:`, `facets:`, `facet_filter:` all appear; shared `repo:` + `federation_limit:` at top level shows the layering from Decision 2.

**What the guide explicitly does NOT teach:**
- Custom JS on top of LiveView (kept server-side on purpose).
- Union-style result merging (Scrypath doesn't support it; federation is section-per-type).
- Cross-schema filter sharing (shared `filter:` → validation fan-out hazard per Decision 2).
- Algolia InstantSearch-compatibility (different DX contract; out of scope for Scrypath).

**Cross-links the guide includes:**
- → `guides/faceted-search.md` (Phase C) for the facet panel patterns.
- → `guides/sync-modes-and-visibility.md` (existing) for write-path caveats when the `search_many` results include freshly-created records.
- → Algolia InstantSearch (one external link, clearly labeled "different architecture") so adopters coming from Rails/JS see the explicit boundary.

**v1.3 phase plan implication:** REQ MULTI-11 — `guides/multi-index-search.md` ships with this worked example; doctest-level snippets for the core call + result-struct access.

---

### 10. Coherence with the other v1.3 categories

**With faceting (per-schema `faceting:` extensions, Phase C):**
- `search_many/2` routes `facets:` per-entry into Meilisearch's `federation.facetsByIndex[indexUid]`.
- `result.by_schema[S].facets` is bit-for-bit the same shape as `Scrypath.search(S, text, facets: [:x]).facets` would produce on its own.
- Compile-time + runtime guards: `Options.validate_search_options!(S, per_opts)` still enforces `facets:` atoms against `S.__scrypath__(:faceting).attributes`. No new validation path.
- `mergeFacets` is deliberately not used — Decision 5 covers why.

**With relevance tuning (per-schema `settings:` extensions, Phase B):**
- Per-schema `synonyms`, `typo_tolerance`, `ranking_rules`, `distinct_attribute`, `stop_words` are index-level settings applied at reindex. They are honored automatically by every `search_many/2` sub-query because the request routes to each schema's own Meilisearch index.
- `search_many/2` does NOT accept per-query `settings:` overrides (same as `Scrypath.search/3` doesn't).
- Cross-schema ranking normalization is not possible in Meilisearch federation and is not attempted by Scrypath; each sub-result's `_rankingScore` is per-schema and NOT normalized to a federation-wide score. The federation `limit`/`offset` controls aggregate slicing without implying cross-schema ranking parity.

**With operator polish (richer `FailedWork`, Phase E):**
- `search_many/2` itself does NOT produce `FailedWork` entries (those are *sync-path* failures, not search-path failures). A federation sub-query that fails produces a `failures:` entry in `MultiSearchResult`, not a `FailedWork`.
- Operators who want to ensure `search_many/2` degradation is observable wire telemetry to `[:scrypath, :search_many, :partial]` events — plan-phase research decides the exact telemetry shape.
- The drift-recovery guide (Phase E) gets to reference `search_many` as "the operator's friend for multi-schema dashboards, including when one schema is mid-reindex" — the guide can honestly say degradation still renders the other schemas.

**With `/multi-search` HTTP surface:**
- Single new HTTP wrapper `Scrypath.Meilisearch.Client.multi_search/2`.
- Thin translation module `Scrypath.Meilisearch.MultiSearch` owns request-building + response-unpacking; the `Client` stays a thin transport.
- `Backend.search_many/3` is an `@optional_callback` with a default N-sequential-calls fallback implemented in `Scrypath.Search` — a future backend without native federation remains a viable target without blocking v1.3.

---

## Usage Examples — Three Flavors

### Flavor 1: Inline one-liner

```elixir
# Search two schemas with the same query text; shared repo; no per-schema opts.
{:ok, results} =
  Scrypath.search_many(
    [{Post, "elixir"}, {User, "elixir"}],
    repo: MyApp.Repo
  )

for {schema, result} <- results.ordered do
  IO.puts("#{inspect(schema)}: #{length(result.records)} records")
end
# Post: 5 records
# User: 3 records
```

### Flavor 2: Five-schema dashboard fan-out with per-schema opts

```elixir
{:ok, results} =
  Scrypath.search_many(
    [
      {Post,    query, filter: [published: true], page: [size: 5], facets: [:tag, :author_id]},
      {User,    query, filter: [active?: true],   page: [size: 3]},
      {Tag,     query,                             page: [size: 10]},
      {Event,   query, filter: [visible?: true],  page: [size: 5], facets: [:venue_type]},
      {Comment, query, filter: [approved?: true], page: [size: 5]}
    ],
    repo: MyApp.Repo,
    federation_limit: 200,
    hydration_timeout: 5_000
  )

# results.ordered   — [{Post, ...}, {User, ...}, {Tag, ...}, {Event, ...}, {Comment, ...}]
# results.by_schema — %{Post => ..., User => ..., Tag => ..., Event => ..., Comment => ...}
# results.failures  — []  (or list of %{schema: ..., reason: ...} if any sub-query errored)
```

### Flavor 3: Per-schema facets + facet filters + partial-failure handling

```elixir
case Scrypath.search_many(
       [
         {Post,  "elixir", facets: [:tag], facet_filter: [tag: ["phoenix", "ecto"]]},
         {Event, "elixir", facets: [:venue_type, :region]}
       ],
       repo: MyApp.Repo
     ) do
  {:ok, %Scrypath.MultiSearchResult{failures: []} = r} ->
    render_everything(r)

  {:ok, %Scrypath.MultiSearchResult{failures: failures} = r} ->
    log_degradation(failures)
    render_partial(r)

  {:error, {:all_failed, failures}} ->
    render_search_down(failures)

  {:error, {:validation_failed, schema, reason}} ->
    render_bad_query_error(schema, reason)
end
```

---

## Partial Failure Semantics — Canonical Table

| Pre-dispatch state | Dispatch state | Post-dispatch state | Return |
|---|---|---|---|
| Bad shared opts shape | — | — | `{:error, {:invalid_options, reason}}` |
| Schema list empty | — | — | `{:error, :empty_schema_list}` |
| Schema count > `max_schemas` | — | — | `{:error, {:too_many_schemas, count, max}}` |
| Per-entry opts validation fails | — | — | `{:error, {:validation_failed, schema, reason}}` (short-circuits, no dispatch) |
| All validation passes | Transport error (e.g., Meilisearch unreachable) | — | `{:error, {:transport_failed, reason}}` |
| All validation passes | `/multi-search` returns per-query errors for *all* queries | — | `{:error, {:all_failed, [%{schema: ..., reason: ...}, ...]}}` |
| All validation passes | Some queries succeed, some fail at Meilisearch | Hydration runs only for succeeded | `{:ok, %MultiSearchResult{ordered: succeeded, by_schema: ..., failures: [failures]}}` |
| All validation passes | All queries succeed | Hydration succeeds for all | `{:ok, %MultiSearchResult{ordered: [...N], by_schema: %{...N}, failures: []}}` |
| All validation passes | All queries succeed | Hydration times out for one schema | `{:ok, %MultiSearchResult{ordered: [...N], by_schema: %{...N}, failures: [%{schema: TimedOut, reason: :hydration_timeout}]}}` — hits remain, records empty, timed-out schema also appears in failures (plan-phase: reconcile the "both present + failed" shape; candidate: omit from `ordered:`/`by_schema:` when hydration fails) |

**Phase-plan decision flagged:** the last row (hydration timeout) has two candidate behaviors — either (a) keep the schema in `ordered:` with empty records + a failures entry, or (b) drop from `ordered:` and only list in `failures:`. Recommendation: **(b)** — simpler mental model ("if it's in `ordered:`, it succeeded end-to-end"), mirrors ES `_msearch` where timed-out sub-responses drop from the responses array. Confirm at Phase D plan time.

---

## Proposed REQ-IDs

| REQ-ID | Requirement | Acceptance Criterion |
|---|---|---|
| **MULTI-01** | `Scrypath.search_many/2` public API accepts a non-empty list of `{schema, text}` or `{schema, text, opts}` tuples plus shared opts. | Call succeeds for `[{Post, "q"}]`, `[{Post, "q", []}]`, `[{Post, "q"}, {User, "q", filter: [...]}]`. Call errors for `[]`, `[{Post}]`, `[{"not a module", "q"}]`. |
| **MULTI-02** | Shared opts are layered under per-entry opts with right-biased `Keyword.merge/2` on a per-key basis. | `search_many([{Post, "q", page: [size: 5]}], page: [size: 10])` → Post gets `page: [size: 5]` (fully replaced, not merged). Property test across `:repo`, `:preload`, `:filter`, `:sort`, `:page`, `:facets`, `:facet_filter`. |
| **MULTI-03** | Shared-opts whitelist: federation-global keys (`federation_limit`, `federation_offset`, `hydration_timeout`, `max_schemas`) are shared-only and meaningless per-entry; per-entry opts with these keys raise `{:error, {:invalid_options, ...}}`. | Call with `{Post, "q", federation_limit: 100}` (wrong level) raises. |
| **MULTI-04** | New public struct `%Scrypath.MultiSearchResult{ordered:, by_schema:, failures:, federation:}` with `@enforce_keys` on the first three. | Struct can be constructed, field access works, dialyzer spec matches. |
| **MULTI-05** | `by_schema == ordered \|> Enum.into(%{})` always (property invariant). | Property test over random schema lists + success / partial / failure scenarios. |
| **MULTI-06** | Return shape per the canonical table: `{:ok, %MultiSearchResult{}}` when any sub-query succeeded; `{:error, {:all_failed, ...}}` when none did; `{:error, {:validation_failed, ...}}` pre-dispatch; `{:error, {:transport_failed, ...}}` when the HTTP call itself errored; `{:error, {:invalid_options, ...}}` or `{:error, :empty_schema_list}` / `{:error, {:too_many_schemas, ...}}` on malformed calls. | Five-case test suite with explicit assertions per branch. |
| **MULTI-07** | `failures:` is `[%{schema: module(), reason: term()}]`. Never tagged tuples; schema key always present; reason is either an atom (`:hydration_timeout`, `:meilisearch_error`) or a map/struct with structured detail. | Typespec + dialyzer-clean. |
| **MULTI-08** | Per-schema facets flow via `federation.facetsByIndex[indexUid]`; unpacking uses the request-side `indexUid → schema` map. `mergeFacets` is never set. `result.by_schema[S].facets` matches single-`search(S, ...)` output byte-for-byte for the same `facets:` opt. | Integration test against live Meilisearch v1.15 that cross-checks single-vs-federated facet output. |
| **MULTI-09** | Hydration runs concurrently via `Task.async_stream/5` with `ordered: true`, `max_concurrency: length(entries)`, `timeout: hydration_timeout_ms` (default 5_000), `on_timeout: :kill_task`. Timed-out schemas drop from `ordered:`/`by_schema:` and appear in `failures:` with `reason: :hydration_timeout`. | Integration test with one schema's repo artificially slowed; assert declaration-order preservation + timeout honored + failures entry present. |
| **MULTI-10** | Cardinality rails: `max_schemas` (default 10), per-entry `page.size` max (default 50), `federation_limit` (default 200), `hydration_timeout` (default 5_000 ms), `federation_timeout` (default 7_500 ms). Over-limit returns `{:error, {:too_many_schemas, count, max}}`. | Unit tests for each rail at default + configured values. |
| **MULTI-11** | `guides/multi-index-search.md` ships with a worked Phoenix LiveView example covering the 4-schema dashboard pattern (search + per-schema facets + partial-failure banner). Cross-links to faceted-search guide and sync-modes guide. | Guide file present; doctest-level snippet compiles under `mix docs --warnings-as-errors`. |
| **MULTI-12** | `Scrypath.Backend.search_many/3` added as `@optional_callback`. Default N-sequential-calls fallback implemented in `Scrypath.Search.search_many/2` so a backend without a native implementation continues to work. `Scrypath.Meilisearch.search_many/3` implements the native `/multi-search` translation. | Unit test: with a test backend that omits `search_many/3`, calls still succeed via fallback. Integration test: Meilisearch path uses the native endpoint (one HTTP request observed). |
| **MULTI-13** | Telemetry: `[:scrypath, :search_many, :start]`, `[:scrypath, :search_many, :stop]` wrap the entire federated call (including hydration). `[:scrypath, :search_many, :partial]` emitted when `failures != []`. | Telemetry test; documented in the multi-index guide. |

(13 REQs total; 4–8 is the downstream-specified range, but multi-index is the most complex v1.3 capability and benefits from finer granularity. Phase D plan can fold MULTI-05 into MULTI-04 and MULTI-13 into MULTI-06 if it wants to compress; the breakdown above is the maximal shape for clarity.)

---

## Coherence With Other v1.3 Categories

| v1.3 Category | Interaction | Plan-Phase Coupling |
|---|---|---|
| **Phase B — Relevance tuning** | `search_many/2` uses each schema's index (already configured with its own `synonyms` / `typo_tolerance` / `ranking_rules` / `distinct_attribute` / `stop_words`). No per-query `settings:` override. | None — Phase B ships independently; Phase D consumes its output transparently. |
| **Phase C — Faceted search** | `search_many/2` routes per-entry `facets:` / `facet_filter:` through Meilisearch's `facetsByIndex`. `result.by_schema[S].facets` is shape-identical to single-search output. | **Phase C must ship before Phase D.** Phase D's MULTI-08 acceptance test asserts byte-for-byte equivalence between single-search facets and federated facets. |
| **Phase E — Operator polish** | `search_many/2` failures surface in `MultiSearchResult.failures`, NOT `FailedWork`. Drift-recovery guide references `search_many` as "operator's friend during per-schema reindex downtime." | Phase E references Phase D in guide copy only; no code coupling. |
| **Phase A — Release-parity gate / CI** | Cardinality-rail defaults (MULTI-10) double as invariants the verification sweep checks. | None direct. |
| **Phase F — VALIDATION.md closure** | Phase D's VALIDATION.md cites the live-Meilisearch integration test path for MULTI-08 and MULTI-09. | None direct. |

**Non-coherence (explicit):**
- **No cross-schema ranking normalization.** `result.ordered[*].result.hits[*]._rankingScore` is per-schema only; Scrypath does not expose a federation-wide relevance score.
- **No `:all` schema wildcard.** Explicit schema list only; no hidden global registry.
- **No backend override per-entry.** `{Post, "q", backend: AlternativeBackend}` is not supported; federation is one backend at a time.

---

## Non-Goal Tripwires

These are the signals during Phase D planning / implementation that would indicate the design has drifted toward a non-goal. Every PR touching `search_many` should be checked against this list.

| Tripwire signal | Non-goal violated | What to do instead |
|---|---|---|
| A new option named `backend:` appears per-entry in `search_many` | "No public multi-backend support" | Backend selection stays one-per-call (via shared `backend:` in shared opts only, which is already the `@runtime_options` key). |
| A `strategy:` or `union:` mode parameter added to merge hits across schemas | "No dashboard product surface" (+ Scrypath's schemas-stay-decoupled philosophy) | Schemas stay grouped; if a consumer wants a union-interleaved list, they derive it from `ordered:` in user code. |
| `mergeFacets` / cross-schema facet merging implemented | Schemas-stay-decoupled philosophy | Facets per-schema only; cross-schema facet aggregation is a downstream (user-code) concern. |
| `facet_filter` value references another schema | Implicit cross-schema coupling | Each schema's `facet_filter` references its own `faceting.attributes` only. |
| Meilisearch `federation.embedder` / vector rerank exposed | "No vector/hybrid/semantic search" | Ignore the Meilisearch federation vector knobs entirely. |
| `search_many` signature accepts `backend_options:` / raw Meilisearch JSON escape hatch at the public layer | Backend-native shapes stay under `Scrypath.Meilisearch.*` | Raw federation access stays under `Scrypath.Meilisearch.MultiSearch.run/2` namespace. |
| A `Scrypath.search_all/1` wildcard-schema function added | "No hidden global schema registry" | Always require an explicit schema list. |
| Result struct picks up `facetDistribution` camelCase keys | "No backend-native shape leakage" | `result.by_schema[S].facets` uses snake_case and the sub-struct shape from Phase C. |
| `failures:` list includes `FailedWork.t()` structs | `FailedWork` is for sync-path failures, not search-path | `failures:` is `[%{schema: ..., reason: ...}]` only. |
| A custom weighting / boost parameter for cross-schema score fusion | "No custom ranking fusion" non-goal | Per-schema `_rankingScore` only; no fused score on `MultiSearchResult`. |
| Mix task `mix scrypath.search_many` added for ad-hoc dashboard queries | "No CLI product surface" | No Mix task at all; `search_many` is a library function. Mix tasks remain sync/operator-surface only. |
| `search_many` accepts anonymous functions for per-schema post-processing | Widens the API into middleware territory | Post-processing stays in user code; library returns data structures. |
| `Backend.search_many/3` becomes required (not `@optional_callback`) | Blocks future backends without native federation | Keep optional; ship the N-sequential-calls fallback. |

**Process tripwire:** If any Phase D plan or PR hits two or more tripwires above, escalate to the non-goals check before merging. Per PITFALLS P9, tripwires catch "small individual wideners that compound into a non-goal violation."

---

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/scrypath/lib/scrypath.ex` — current public API surface.
- `/Users/jon/projects/scrypath/lib/scrypath/search.ex` — current single-schema search orchestration.
- `/Users/jon/projects/scrypath/lib/scrypath/search_result.ex` — `SearchResult.t()` shape and helpers.
- `/Users/jon/projects/scrypath/lib/scrypath/backend.ex` — behaviour (five required callbacks; `search_many/3` not yet present).
- `/Users/jon/projects/scrypath/lib/scrypath/hydration.ex` — per-schema `Hydration.hydrate/3` contract.
- `/Users/jon/projects/scrypath/lib/scrypath/meilisearch.ex` — backend impl including `index_name/2` used for `indexUid` mapping.
- `/Users/jon/projects/scrypath/lib/scrypath/options.ex` — `@search_options`, `validate_search_options!/2`.
- `/Users/jon/projects/scrypath/lib/scrypath/query.ex` — `%Query{}` struct shape.
- `/Users/jon/projects/scrypath/.planning/research/{STACK,FEATURES,ARCHITECTURE,PITFALLS,SUMMARY}.md` — prior-round convergence.
- `/Users/jon/projects/scrypath/.planning/PROJECT.md` — non-goals and scope boundaries.
- [Meilisearch `/multi-search` API reference](https://www.meilisearch.com/docs/reference/api/multi_search) — request/response shapes, `federation` object, `facetsByIndex`, `remoteErrors`.
- [Elasticsearch `_msearch` API reference](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-multi-search.html) — ND-JSON shape, `responses` array, `max_concurrent_searches`.
- [Elixir `Task.async_stream/5`](https://hexdocs.pm/elixir/Task.html) — concurrency primitive for Decision 6.

### Secondary (MEDIUM confidence)
- [Typesense `/multi_search`](https://typesense.org/docs/30.1/api/federated-multi-search.html) — federated vs union modes, `limit_multi_searches: 50` default. Fetched page returned partial content; relied on community/ecosystem summaries for the finer details.
- [Algolia `multipleQueries` / community examples](https://discourse.algolia.com/t/combine-multiplequeries-results/10991) — `results` array in request order with `index` field per entry. Algolia's own API doc page was sparse when fetched.
- [Searchkick `Searchkick.multi_search`](https://github.com/ankane/searchkick) — lazy `execute: false` pattern, per-query error inspection, no raise-on-partial-failure.
- [Ecto `Repo.transaction` + `Repo.preload` composition docs](https://hexdocs.pm/ecto/Ecto.Repo.html) — right-biased opts override.
- [ecto_sql issue #122](https://github.com/elixir-ecto/ecto_sql/issues/122) — transactional-task hang caveat (not applicable here, but documented in plan-phase test guide).

### Tertiary (LOW confidence — flagged for plan-phase verification)
- Exact Meilisearch `/multi-search` partial-failure semantics when one sub-query errors (the `remoteErrors` field is documented; per-query error surface within `hits[]` is less crisp). **Verify at Phase D plan time** with a live v1.15 test that errors one sub-query deliberately (e.g., invalid filter) and inspects the response shape.
- Whether `facetsByIndex` with per-schema attribute lists is exactly symmetric with single-index `facets:` (i.e., zero drift in `facetDistribution` / `facetStats` keys between single and federated). Assumption based on OpenAPI schema congruence; confirm at Phase D plan time.

---
*Deep research for: Scrypath v1.3 — Multi-Index (Federated) Search design (Phase 21 input)*
*Researched: 2026-04-17*
