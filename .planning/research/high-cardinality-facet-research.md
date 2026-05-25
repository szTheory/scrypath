# High-Cardinality Facet Value Search — Research

**Researched:** 2026-05-25
**Domain:** Meilisearch `/facet-search` endpoint, Scrypath facet stack, adopter pain signals
**Confidence:** HIGH for Meilisearch mechanics (spec-verified); HIGH for current Scrypath state
(direct code read); MEDIUM for adopter pain (one simulated adopter, not production signal)

---

## Summary

"High-cardinality facet value search" means: given a facet attribute that has hundreds or
thousands of distinct values (e.g. `tags`, `categories`, `brands`), let the user type a
string to narrow the _list of facet values themselves_ before selecting one. This is the
"tag autocomplete in the filter sidebar" problem — not searching documents, but searching
the facet value vocabulary.

Meilisearch has a native endpoint for exactly this: `POST /indexes/{uid}/facet-search`,
introduced in v1.3. It returns `facetHits` — a list of `{value, count}` pairs — not
document hits. Scrypath already enables `facetSearch` feature on filterable attributes at
the settings layer (the `settings.ex` code emits `%{attribute: name, features: ["facetSearch"]}`)
but has no public API to call the endpoint.

The current workaround documented in the faceted-search guide is: "add a text input that
filters rows client-side (LiveView assign only)." That note explicitly flags the
Meilisearch facet-search API as "deferred on the roadmap" as of v1.3.

**Primary recommendation:** Add `Scrypath.search_facet_values/4` as a thin, independently
testable function that hits `POST /indexes/{uid}/facet-search` and returns a new lightweight
result struct. This is additive to `search_within_facet/4`, which solves a different problem.

---

## 1. What `search_within_facet/4` Already Does — and Does Not Do

`search_within_facet/4` searches **documents** that belong to a specific facet bucket. It
is a scoped full-text search: "give me all movies in the Genre=Action bucket, sorted and
paginated normally." It routes to `POST /indexes/{uid}/search` and returns a `SearchResult`
with hits, pagination, and facet distributions.

It does **not** search the vocabulary of facet _values_. It does not answer: "What tag
values contain the word 'blue'?" That requires a separate engine call to the
`/facet-search` endpoint.

| Concern | `search_within_facet/4` | `search_facet_values/4` (proposed) |
|---------|------------------------|-------------------------------------|
| What is being searched? | Documents scoped to a facet bucket | Facet value vocabulary for one attribute |
| Meilisearch endpoint | `POST /search` | `POST /facet-search` |
| Returns | `%SearchResult{}` (hits, records, facets, page) | `%FacetSearchResult{}` (facetHits list) |
| Use case | "Search within Action movies" | "What tags match 'blue'?" |
| Additive or replacement? | Unchanged | Purely additive |

The two functions address orthogonal use cases and should both exist.

---

## 2. Meilisearch Native Support

### The `/facet-search` endpoint [VERIFIED: Meilisearch spec 0246]

**Endpoint:** `POST /indexes/{index_uid}/facet-search`

**Request body (key fields):**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `facetName` | yes | The attribute to search within (must be `filterableAttribute` with `facetSearch` feature) |
| `facetQuery` | no | Search string against facet values; supports prefix match and typo tolerance; treated as single term |
| `q` | no | Document query — narrows which documents are considered before computing facet value counts |
| `filter` | no | Additional filter expression applied before facet search |
| `matchingStrategy` | no | `last`, `all`, or `frequency` |
| `exhaustiveFacetCount` | no | Return exact counts instead of estimates (slower) |

**Response (distinct from `/search`):**

```json
{
  "facetHits": [
    {"value": "blue jeans",  "count": 142},
    {"value": "blueberry",   "count": 27},
    {"value": "blue whale",  "count": 4}
  ],
  "facetQuery": "blue",
  "processingTimeMs": 3
}
```

This is not a `SearchResult`. There are no `hits`, no pagination, no `estimatedTotalHits`.
`facetHits` is a flat array of `{value: string, count: integer}` objects.

**Result count is governed by `maxValuesPerFacet`** — the same index setting that caps
`facetDistribution` bucket counts on regular search responses. Default is 100.
[VERIFIED: Meilisearch spec 157 — faceting settings]

**Sorting:** `sortFacetValuesBy` index setting controls order (`:alpha` default or `:count`).
The `facetSearch` feature flag must be present on the attribute's filterable entry.
Scrypath's `settings.ex` already emits this flag for every declared `faceting.attributes`
entry — so the Meilisearch index is already prepared.

**Introduced:** Meilisearch v1.3. [CITED: meilisearch.com/blog/v1-3-release]

**Typo tolerance:** Yes, the endpoint is typo-tolerant and supports prefix search.

**`q` interaction (the power feature):** Passing `q: "blue whale documentary"` alongside
`facetName: "tags"` and `facetQuery: "oce"` returns tag values matching "oce" (prefix)
_filtered to tags that appear in documents matching "blue whale documentary"_. This enables
context-aware facet suggestion: "while searching for X, what tags containing 'oce' are
relevant?" That is meaningfully richer than a static vocabulary lookup.

### `maxValuesPerFacet` limit [VERIFIED: Meilisearch spec 157]

- **Default:** 100
- **Controls:** both `facetDistribution` bucket count in regular search AND `facetHits`
  count in `/facet-search` responses
- **Max:** Not specified in the specification; practically, setting it to 1000+ is supported
  but will slow down facet computation for high-cardinality attributes

For a catalog with 10,000 tag values, `maxValuesPerFacet: 100` means facet-search still
returns at most 100 matching tag values. Raising this to 200–500 for specific attributes
is the standard approach for high-cardinality facets. Scrypath already exposes
`max_values_per_facet:` in the schema `faceting:` declaration — so hosts can tune this
today at the index level.

---

## 3. Current Scrypath State

### What's already built:

- `faceting: [attributes: [...], max_values_per_facet: N, sort_facet_values_by: %{...}]`
  schema declaration — fully implemented and reflected via `Scrypath.schema_faceting/1`.
- `Scrypath.Meilisearch.Settings` emits `%{attribute: name, features: ["facetSearch"]}` for
  every declared facet attribute — the index is configured correctly for `/facet-search`.
- `Scrypath.search_within_facet/4` — searches documents within a facet bucket (different
  concern, see Section 1 above).

### What is missing:

- No `Scrypath.Client` function for `POST /indexes/{uid}/facet-search`.
- No `%Scrypath.FacetSearchResult{}` struct (or equivalent) to decode `facetHits`.
- No public `Scrypath.search_facet_values/4` function.
- No `Backend` callback for `facet_search` (the backend behaviour has no such callback).
- No telemetry span for facet-value search calls.
- No test coverage for the `/facet-search` wire path.
- No guide section showing LiveView facet-value-as-you-type autocomplete patterns.

### The deferred note in the guide:

From `guides/faceted-search-with-phoenix-liveview.md`, line 181:
> "For long director lists, add a **text input that filters rows client-side** (LiveView
> assign only). This does **not** call the Meilisearch facet-search API (deferred on the
> roadmap); it is **assign-filter only** for v1.3."

This is an explicit acknowledged debt from v1.3. The infrastructure to _enable_ the
endpoint (the `facetSearch` feature flag on filterableAttributes) is already applied by
settings.ex. The call path and decode layer are what's missing.

---

## 4. The Concrete User Problem

### The actual failure mode

A product catalog has 500+ tags. The host declares:

```elixir
faceting: [attributes: [:tags], max_values_per_facet: 100]
```

A regular `Scrypath.search/3` call with `facets: [:tags]` returns at most 100 tag
buckets in `result.facets.distribution.tags`. If the user wants to filter by a tag not
in the top 100, there is no server-side way to find it.

The current workaround (assign-filter only) fails entirely when:
- The facet has more values than the LiveView rendered on mount (common if `max_values_per_facet` is 100 but there are 800 tags)
- The host needs to show context-sensitive counts (how many documents match _this tag value AND the current search query_)
- The host needs typo tolerance on tag names ("organik" should find "organic")

### The concrete use case

The user has typed "blue" in a tag search box. They need to see:
```
blue jeans (142 products)
blueberry jam (27 products)
blue whale documentary (4 products)
```
...for just the products currently matching their full-text query. Client-side filtering
on pre-loaded tag names cannot provide the counts or the context-sensitivity.

### Scope of the problem

This becomes a **real pain point** at roughly:
- 200+ distinct values for a single facet attribute, OR
- Any catalog where facet values change dynamically (user-generated tags), OR
- Any use case needing typo tolerance on facet values

Below 100–150 values with stable vocabulary, client-side LiveView assign-filter is
adequate (the guide's current recommendation) and no adopter pain occurs.

---

## 5. Proposed API Shape

### New public function

```elixir
# Scrypath.search_facet_values(schema, facet_attribute, facet_query, opts)
Scrypath.search_facet_values(Product, :tags, "blue", backend: MyApp.SearchBackend)
# => {:ok, %Scrypath.FacetSearchResult{
#          facet: :tags,
#          facet_query: "blue",
#          hits: [
#            %Scrypath.FacetHit{value: "blue jeans", count: 142},
#            %Scrypath.FacetHit{value: "blueberry",  count: 27}
#          ],
#          processing_time_ms: 3
#        }}
```

With context-sensitive counts (the power use case):
```elixir
Scrypath.search_facet_values(Product, :tags, "blue",
  q: "whale documentary",     # narrow documents first
  filter: [status: "active"], # additional filter
  backend: MyApp.SearchBackend
)
```

### Naming rationale

`search_facet_values` is unambiguous: it searches the _values_ of a facet, not documents.
It does not collide with `search_within_facet` (which searches _documents_ within a facet).

Algolia uses `searchForFacetValues`. Typesense uses `facet_query` on the standard search.
Meilisearch calls it `facet-search`. The Elixir function name should follow the verb pattern
established by `search/3`, `search_within_facet/4`, `search_many/2`.

### New result struct

```elixir
defmodule Scrypath.FacetSearchResult do
  defstruct [:facet, :facet_query, :hits, :processing_time_ms, :raw]

  defmodule Hit do
    defstruct [:value, :count]
  end
end
```

This is intentionally lightweight. No pagination, no `records`, no hydration — the results
are value strings with counts, not Ecto structs.

### Backend callback

```elixir
# Optional — FakeBackend must stub it, Meilisearch backend implements it
@callback search_facet_values(module(), atom(), String.t(), keyword()) ::
            {:ok, map()} | {:error, term()}
@optional_callbacks [search_facet_values: 4]
```

### Client function

```elixir
# Scrypath.Meilisearch.Client
def facet_search(index_name, payload, config) do
  run_request(:post, "/indexes/#{index_name}/facet-search", [json: payload], config,
    index: index_name)
end
```

Payload translation: `facet_name` (camelCase per Meilisearch wire), `facet_query`, and
optional `q`, `filter`.

### Validation required

- `facet_attribute` must be declared in `faceting.attributes` on the schema (same check
  as `facets:` kwarg validation in `search/3`)
- `facet_query` must be a string (empty string = placeholder search = return all values up
  to `maxValuesPerFacet`)
- Optional `q` and `filter` pass through with the same validation as `search/3`

### Telemetry span

`[:scrypath, :facet_search]` with metadata `:schema`, `:facet`, `:index`.

---

## 6. Relationship to `search_within_facet/4`

These are complementary, not competing:

```
User wants to browse products tagged "blue jeans"
  → call search_within_facet(Product, "whale", {:tags, "blue jeans"})
  → searches documents in the "blue jeans" tag bucket

User wants to find the "blue jeans" tag before selecting it
  → call search_facet_values(Product, :tags, "blue")
  → searches tag value vocabulary, returns {"blue jeans", 142}
```

A full faceted-filter LiveView would use both: `search_facet_values` to populate the
tag-search dropdown, then `search_within_facet` (or `search/3` with `facet_filter:`) once
the user selects a value.

No changes to `search_within_facet/4` are needed. This is purely additive.

---

## 7. What Other Search Clients Do

### Algolia / algoliasearch-rails [ASSUMED — training data]

Exposes `search_for_facet_values` on the index client. Takes `facet_name`, `facet_query`,
optional `params`. Returns `{facetHits: [{value, count, highlighted}]}`. The existing
Scrypath FACETING.md deep research documents this pattern and marks it as a lesson to steal.

### Typesense [ASSUMED — training data]

Facet value search is done via `facet_query` parameter on the standard search endpoint
(not a separate endpoint). Returns `facet_counts[].counts[].highlighted` alongside `value`
and `count`. The approach is more tightly coupled to document search but works for the same
use case.

### Elasticsearch / OpenSearch [ASSUMED — training data]

Uses aggregations with `include` regex for filtering bucket values. More powerful but
significantly more complex. Not applicable to Meilisearch users.

### Phoenix/Rails SaaS apps [ASSUMED — inferred from research patterns]

Common patterns: fire a debounced LiveView event on tag input change, call a context
function that issues the facet-search, push results into a `@tag_suggestions` assign,
render a dropdown from that assign. Some apps pre-load all values and filter client-side;
the crossover point where server-side is better is roughly 200+ values or when count
context-sensitivity matters.

---

## 8. Scope Estimate

### Minimal complete milestone

**Total scope: small — 4–6 implementation tasks, 2–3 test tasks, 1 guide update**

| Task | Files affected | Complexity |
|------|----------------|------------|
| Add `Client.facet_search/3` | `lib/scrypath/meilisearch/client.ex` | trivial (~10 lines) |
| Define `%FacetSearchResult{}` + `%FacetHit{}` | new `lib/scrypath/facet_search_result.ex` | small (~30 lines) |
| Add `Search.search_facet_values/4` | `lib/scrypath/search.ex` | small (~40 lines) |
| Add public `Scrypath.search_facet_values/4` | `lib/scrypath.ex` | trivial (~15 lines) |
| Add optional `Backend.search_facet_values/4` callback | `lib/scrypath/backend.ex` | trivial (~5 lines) |
| Validate `facet_attribute` against declared `faceting.attributes` | `lib/scrypath/options.ex` | small (~20 lines) |
| Telemetry span | `lib/scrypath/telemetry.ex` | trivial |
| Unit + Req.Test stub test | new `test/scrypath/search_facet_values_test.exs` | small |
| FakeBackend stub | `test/support/fake_backend.ex` | trivial |
| Guide update (new section in faceted-search guide) | `guides/faceted-search-with-phoenix-liveview.md` | small |
| Remove "assign-filter only" deferred note from guide | `guides/faceted-search-with-phoenix-liveview.md` | trivial |

The implementation is narrow because Meilisearch already does the heavy lifting.
Scrypath's job is: validate declared attribute, translate to wire payload, call the
endpoint, decode `facetHits` into `[%FacetHit{value, count}]`, wrap in struct, emit span.

### Done-enough bar

A milestone is complete when:
1. `Scrypath.search_facet_values(Schema, :attribute, "query", opts)` returns
   `{:ok, %FacetSearchResult{hits: [%FacetHit{value, count}, ...]}}`.
2. Calling with an undeclared facet attribute returns `{:error, {:unknown_facet, attr}}`.
3. `Scrypath.search_facet_values!/4` bang variant works.
4. `FakeBackend` stubs the new callback.
5. A test exercises the Meilisearch wire path with `Req.Test`.
6. The faceted-search guide removes the "deferred" note and shows a LiveView debounce
   pattern using the new function.
7. Telemetry span `[:scrypath, :facet_search]` is documented.

**Not required for done-enough:**
- The `q:` context parameter in the first cut (nice-to-have; can ship with or without)
- Highlighted value support (Meilisearch does not provide it on `/facet-search`)
- Pagination (the endpoint does not paginate — `maxValuesPerFacet` is the limit)
- `search_facet_values_many/2` federated variant (defer)

---

## 9. Is This Real Adopter Pain or Polish?

### Evidence for real pain

The outside-adopter evidence review (87-EVIDENCE-REVIEW.md) records Attempt 02:
> "Hydration fails with `FunctionClauseError` on high-cardinality facets under tenant scopes."

The issue there was hydration + tenant scoping, not specifically the facet-value search
endpoint. The adopter was hitting `max_values_per_facet` invisibility (they had thousands
of custom tags per tenant and the distribution only showed 100 of them).

The deferred note in the guide is honest about the gap: the current recommendation is
client-side filtering, which fails for catalogs with more values than `max_values_per_facet`.

### The honest position

- **Below ~200 distinct values per facet attribute:** client-side filtering is adequate.
  The guide's current recommendation works. This is "polish" for those apps.
- **At 200–500+ distinct values, or with user-generated/dynamic tags:** client-side
  filtering breaks. The host cannot pre-load all values efficiently. This is real pain.
- **At 1000+ values (e.g. customer-generated tags in a SaaS product):** client-side
  filtering is a non-starter. Count context-sensitivity is required. This is a blocker.

The outside-adopter evidence is one simulated adopter, not proven production pain. The
milestone-candidates.md ranking is correct: **B4 — useful for larger catalogs, but behind
related-data propagation (B1) and tenant-safe access (B2).**

The primary reasons to build this now rather than later:
1. The Meilisearch infrastructure is already configured (settings.ex emits `facetSearch`).
2. The scope is small and well-bounded (no design ambiguity).
3. The guide contains an explicit acknowledged debt note.
4. Once B1 and B2 ship, a B2B SaaS adopter with dynamic per-tenant tags will immediately
   hit this gap.

The primary reason to defer:
1. No outside adopter has hit this specific gap in production (yet).
2. B1 and B2 are higher priority for the next milestone cycle per the decision record.

### Verdict

This is **real adopter pain at catalog scale, not polish** — but it is not the most urgent
gap. It belongs after B1 (related-data propagation) and B2 (tenant-safe access). For the
specific adopter profile of a B2B SaaS with per-tenant user-generated tags, it becomes a
blocker at moderate scale (~300+ unique tag values per tenant).

If a future milestone opens feature work after B1/B2, this is the right third pick. The
scope is small enough that it would not dominate a milestone — it could be a primary item
in a "catalog depth" milestone alongside autocomplete/suggestions (B5).

---

## 10. Open Questions

1. **Should `q:` be in the first cut?** The context-sensitive counts are the most powerful
   feature of the `/facet-search` endpoint. Omitting `q:` ships a working but less powerful
   API. Including it adds ~5 lines of translation and a test case. Recommendation: include
   it — the implementation cost is negligible and it prevents a second API change later.

2. **Does `FakeBackend` need a stub or a passthrough?** The FakeBackend pattern in the test
   suite currently returns canned responses for `search/2`. For `search_facet_values/4`,
   a FakeBackend stub returning `{:ok, %{facetHits: [], facetQuery: nil}}` is sufficient
   for unit tests. Wire-level tests use `Req.Test.stub` like `search_within_facet_test.exs`.

3. **Naming: `search_facet_values` vs `facet_search`?** `search_facet_values` follows
   Scrypath's verb-first naming and is unambiguous (you search for facet values). `facet_search`
   matches the Meilisearch endpoint name but reads as a noun phrase. Recommendation:
   `search_facet_values` for the public function, `facet_search` for the client layer.

4. **Guide placement:** Should the LiveView pattern go in the existing faceted-search guide
   or a new guide? Recommendation: extend the existing guide with a new section after
   "Search-within-facet (director list)" — this is where the deferred note currently lives.

---

## Sources

### Primary (HIGH confidence)
- Meilisearch spec 0246 — facet-search API full specification (request params, response shape)
  https://specs.meilisearch.dev/specifications/text/0246-facet-search-api.html
- Meilisearch spec 157 — faceting settings API (maxValuesPerFacet, sortFacetValuesBy)
  https://specs.meilisearch.dev/specifications/text/157-faceting-setting-api.html
- Meilisearch v1.3 release post — facet-search feature introduction
  https://www.meilisearch.com/blog/v1-3-release
- Scrypath codebase (direct read):
  - `lib/scrypath/search.ex` — `search_within_facet/4` implementation
  - `lib/scrypath/meilisearch/settings.ex` — `facetSearch` feature flag emission
  - `lib/scrypath/meilisearch/client.ex` — no `/facet-search` call exists
  - `lib/scrypath/backend.ex` — no `facet_search` callback exists
  - `lib/scrypath/search_result/facets.ex` — existing facets struct
  - `guides/faceted-search-with-phoenix-liveview.md` — "deferred" note at line 181
  - `.planning/research/deep/FACETING.md` — prior deep research including algoliasearch-rails
    `search_for_facet_values` lesson
  - `.planning/milestone-candidates.md` — B4 ranking
  - `.planning/threads/scrypath-doneness-assessment-2026-05-24.md` — priority ordering
  - `.planning/phases/87-*/87-EVIDENCE-REVIEW.md` — adopter signal on high-cardinality facets

### Tertiary (LOW confidence — training data, not verified in session)
- Algolia `searchForFacetValues` pattern — [ASSUMED]
- Typesense `facet_query` on standard search — [ASSUMED]
- Phoenix SaaS app patterns for debounced facet-value search — [ASSUMED]
