# Phase 80: Public query toolkit contract - Pattern Map

**Mapped:** 2026-05-22  
**Files analyzed:** 7 likely Phase 80 touchpoints  
**Analogs found:** 6 / 7 from live code

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scrypath.ex` | utility | request-response | `lib/scrypath.ex` | exact |
| `lib/scrypath/query_params.ex` | utility | transform | `lib/scrypath.ex` + `lib/scrypath/query.ex` | role-match |
| `lib/scrypath/query_params/caster.ex` | service | transform | `lib/scrypath/options.ex` + `lib/scrypath/search.ex` | role-match |
| `test/scrypath/query_params_test.exs` | test | transform | `test/scrypath/search_test.exs` + `test/scrypath/meilisearch/query_test.exs` | role-match |
| `test/scrypath/docs_contract_test.exs` | test | transform | `test/scrypath/docs_contract_test.exs` | exact |
| `guides/phoenix-contexts.md` | config | request-response | `guides/phoenix-contexts.md` | exact |
| `guides/phoenix-liveview.md` or `guides/phoenix-controllers-and-json.md` | config | request-response | same files | exact |

## Pattern Assignments

### `lib/scrypath.ex` (public facade, request-response)

**Analog:** [`lib/scrypath.ex`](/Users/jon/projects/scrypath/lib/scrypath.ex:1)

**Public-surface style to mirror** ([lib/scrypath.ex](/Users/jon/projects/scrypath/lib/scrypath.ex:141)):
```elixir
@doc """
Primary hydrated search entry: validates options, resolves runtime config, and
returns `{:ok, search_result}` or tagged `{:error, _}` failures ...

## Errors vs raises

* **`ArgumentError`** — some invalid shapes are rejected synchronously ...
* **`{:error, reason}`** — operational failures ...
"""
@spec search(module(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}
def search(schema_module, text, opts \\ []) do
  Scrypath.Search.search(schema_module, text, opts)
end
```

**Small public reflection/API pattern** ([lib/scrypath.ex](/Users/jon/projects/scrypath/lib/scrypath.ex:26)):
```elixir
## Reflection helpers

The initial public reflection surface is intentionally small:
```

**Planner guidance:** if Phase 80 exposes a public toolkit under `Scrypath.*`, keep it as a small, documented, data-first facade with delegated implementation. Do not introduce schema-generated verbs or a second runtime entrypoint.

---

### `lib/scrypath/query_params.ex` (new public plain-data toolkit facade, transform)

**Closest analogs:** [`lib/scrypath.ex`](/Users/jon/projects/scrypath/lib/scrypath.ex:1), [`lib/scrypath/query.ex`](/Users/jon/projects/scrypath/lib/scrypath/query.ex:1)

**Boundary wording to copy** ([lib/scrypath/query.ex](/Users/jon/projects/scrypath/lib/scrypath/query.ex:2)):
```elixir
@moduledoc """
**`%Scrypath.Query{}` is internal normalized query state** ...
It is **not** a semver-stable pattern-match target for application code ...
"""
```

**Facade/delegation pattern to copy** ([lib/scrypath.ex](/Users/jon/projects/scrypath/lib/scrypath.ex:165)):
```elixir
@spec search(module(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}
def search(schema_module, text, opts \\ []) do
  Scrypath.Search.search(schema_module, text, opts)
end
```

**Recommended file location:** top-level `lib/scrypath/query_params.ex`, not under `meilisearch/` and not under Phoenix namespaces.

**Planner guidance:** make the public contract plain data, not another public struct that repeats the `Scrypath.Query` mistake in public form. If a type is needed, prefer maps/keywords in specs and docs over a new semver-frozen runtime struct in Phase 80.

---

### `lib/scrypath/query_params/caster.ex` (internal normalization/casting seam, transform)

**Closest analogs:** [`lib/scrypath/options.ex`](/Users/jon/projects/scrypath/lib/scrypath/options.ex:169), [`lib/scrypath/search.ex`](/Users/jon/projects/scrypath/lib/scrypath/search.ex:27)

**Allowlisted option-table pattern** ([lib/scrypath/options.ex](/Users/jon/projects/scrypath/lib/scrypath/options.ex:169)):
```elixir
@search_options [
  facets: [type: {:list, :atom}, default: []],
  facet_filter: [type: {:custom, __MODULE__, :validate_search_filter, []}, default: []],
  filter: [type: {:custom, __MODULE__, :validate_search_filter, []}, default: []],
  sort: [type: {:custom, __MODULE__, :validate_search_sort, []}, default: []],
  page: [type: {:custom, __MODULE__, :validate_search_page, []}, default: []],
  per_query: [type: {:custom, __MODULE__, :validate_per_query_map, []}, default: %{}]
]
```

**Validate-then-delegate flow** ([lib/scrypath/search.ex](/Users/jon/projects/scrypath/lib/scrypath/search.ex:28)):
```elixir
case Scrypath.Options.validate_search_options(schema_module, opts) do
  {:error, {:validation, message}} when is_binary(message) ->
    raise ArgumentError, message

  {:error, {:invalid_options, _field, message}} when is_binary(message) ->
    raise ArgumentError, message

  {:error, _} = err ->
    err

  {:ok, search_opts} ->
    do_search(schema_module, text, search_opts, opts, [])
end
```

**Internal-normalization pattern** ([lib/scrypath/query.ex](/Users/jon/projects/scrypath/lib/scrypath/query.ex:50)):
```elixir
def new(text, opts) when is_binary(text) and is_list(opts) do
  %__MODULE__{
    text: text,
    filter: Keyword.get(opts, :filter, []),
    sort: Keyword.get(opts, :sort, []),
    page: normalize_page(Keyword.get(opts, :page, %{})),
    facets: Keyword.get(opts, :facets, []),
    facet_filter: Keyword.get(opts, :facet_filter, []),
    per_query: Keyword.get(opts, :per_query, %{})
  }
end
```

**Recommended file location:** `lib/scrypath/query_params/caster.ex` or similarly narrow internal module under `lib/scrypath/query_params/`.

**Planner guidance:** Phase 80 should reuse the existing search grammar names (`filter`, `sort`, `page`, `facets`, `facet_filter`, `per_query`) so the toolkit feeds `Scrypath.search/3` directly. Do not invent a second vocabulary.

---

### `test/scrypath/query_params_test.exs` (new toolkit tests, transform)

**Closest analogs:** [`test/scrypath/search_test.exs`](/Users/jon/projects/scrypath/test/scrypath/search_test.exs:64), [`test/scrypath/meilisearch/query_test.exs`](/Users/jon/projects/scrypath/test/scrypath/meilisearch/query_test.exs:7), [`test/scrypath/search_within_facet_test.exs`](/Users/jon/projects/scrypath/test/scrypath/search_within_facet_test.exs:39)

**Explicit input/output test style** ([test/scrypath/search_test.exs](/Users/jon/projects/scrypath/test/scrypath/search_test.exs:97)):
```elixir
assert {:ok,
        %SearchResult{
          query: %Query{
            text: "phoenix",
            filter: [status: "published"],
            sort: [desc: :inserted_at],
            page: %{number: 2, size: 20}
          }
        }} = ...
```

**Validation-failure style** ([test/scrypath/search_test.exs](/Users/jon/projects/scrypath/test/scrypath/search_test.exs:118)):
```elixir
assert_raise ArgumentError, ~r/filterable/, fn ->
  Scrypath.search(...)
end
```

**Payload-shape assertions for filter/facet composition** ([test/scrypath/meilisearch/query_test.exs](/Users/jon/projects/scrypath/test/scrypath/meilisearch/query_test.exs:24)):
```elixir
payload = MeilisearchQuery.to_payload(q)
assert payload["facetFilters"] == ["genre = \"Action\""]
assert payload[:facets] == ["genre"]
```

**Req.Test seam for one-body proof** ([test/scrypath/search_within_facet_test.exs](/Users/jon/projects/scrypath/test/scrypath/search_within_facet_test.exs:42)):
```elixir
Req.Test.stub(stub, fn conn ->
  send(self(), {:scoped_search_body, conn.body_params})
  Req.Test.json(conn, %{"hits" => [], "page" => 1, "hitsPerPage" => 20, "totalHits" => 0})
end)
```

**Planner guidance:** keep the suite explicit and contract-shaped. Prefer 5-8 focused cases over a generalized harness: happy path cast, one invalid field, one invalid page, one sort/filter allowlist case, and one proof that cast output passes unchanged into `Scrypath.search/3`.

---

### `test/scrypath/docs_contract_test.exs` (docs drift protection)

**Analog:** [`test/scrypath/docs_contract_test.exs`](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:61)

**String-anchor pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:61)):
```elixir
assert String.contains?(@per_query_tuning_pipeline, "## Two-plane model and precedence")
```

**Published-doc hygiene pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:67)):
```elixir
refute Regex.match?(re, body),
       "remove #{label} from published doc #{path} ..."
```

**Grounded-in-live-surface pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:125)):
```elixir
refute String.contains?(public_jtbd, "Scrypath.SearchModule")
assert_contains_all(@jtbd_gap_map, [
  "planning artifacts claim a `Scrypath.SearchModule` layer shipped in `v1.20`",
  "the checked-out code does not currently expose that layer"
])
```

**Planner guidance:** when Phase 82 documents the toolkit, pin only stable facts: contexts remain canonical, Phoenix is optional, `%Scrypath.Query{}` is not public API, and the toolkit feeds `Scrypath.search/3`. Do not snapshot whole guides.

---

### `guides/phoenix-contexts.md`, `guides/phoenix-liveview.md`, `guides/phoenix-controllers-and-json.md` (boundary docs)

**Analogs:** [`guides/phoenix-contexts.md`](/Users/jon/projects/scrypath/guides/phoenix-contexts.md:3), [`guides/phoenix-liveview.md`](/Users/jon/projects/scrypath/guides/phoenix-liveview.md:3), [`guides/phoenix-controllers-and-json.md`](/Users/jon/projects/scrypath/guides/phoenix-controllers-and-json.md:3)

**Context-boundary wording** ([guides/phoenix-contexts.md](/Users/jon/projects/scrypath/guides/phoenix-contexts.md:7)):
```md
Keep these responsibilities in the context:
- `Scrypath.search/3` calls plus repo-backed hydration policy
- preload, filter, sort, and paging defaults that belong to the feature
```

**LiveView param-owner wording** ([guides/phoenix-liveview.md](/Users/jon/projects/scrypath/guides/phoenix-liveview.md:32)):
```md
LiveView should own:
- current query text
- filter and sort params that belong in the URL

The context should own:
- `Scrypath.search/3` options
```

**Controller translation wording** ([guides/phoenix-controllers-and-json.md](/Users/jon/projects/scrypath/guides/phoenix-controllers-and-json.md:67)):
```md
Keep JSON shaping in the controller or view layer. Keep repo access, search
orchestration, and sync visibility choices in the context.
```

**More specific edge-normalization wording** ([guides/faceted-search-with-phoenix-liveview.md](/Users/jon/projects/scrypath/guides/faceted-search-with-phoenix-liveview.md:96)):
```md
Recommended: normalize query + facet params in `handle_params/3`, then call your
context with a keyword list that mirrors what you will pass to `Scrypath.search/3`.
```

**Planner guidance:** these guides are the right place to teach request-param casting, but only after the public contract exists. Keep examples calling a context, not the toolkit module directly from controllers or LiveView as the canonical architecture.

## Shared Patterns

### Public APIs Are Small, Documented, And Delegating

**Sources:**
- [`lib/scrypath.ex:26`](/Users/jon/projects/scrypath/lib/scrypath.ex:26)
- [`lib/scrypath.ex:141`](/Users/jon/projects/scrypath/lib/scrypath.ex:141)

Apply to Phase 80: expose a narrow public toolkit module with strong `@doc` and minimal surface area.

### Internal Normalization Stays Internal

**Sources:**
- [`lib/scrypath/query.ex:2`](/Users/jon/projects/scrypath/lib/scrypath/query.ex:2)
- [`lib/scrypath/search.ex:95`](/Users/jon/projects/scrypath/lib/scrypath/search.ex:95)

Apply to Phase 80: do not make `%Scrypath.Query{}` public, and do not replace it with another public runtime struct too early.

### Search Grammar Is Already Stable Enough To Reuse

**Sources:**
- [`lib/scrypath/options.ex:169`](/Users/jon/projects/scrypath/lib/scrypath/options.ex:169)
- [`test/scrypath/search_test.exs:97`](/Users/jon/projects/scrypath/test/scrypath/search_test.exs:97)
- [`test/scrypath/meilisearch/query_test.exs:24`](/Users/jon/projects/scrypath/test/scrypath/meilisearch/query_test.exs:24)

Apply to Phase 80: keep toolkit output keyed as `filter`, `sort`, `page`, `facets`, `facet_filter`, and `per_query`, so it can feed `Scrypath.search/3` without an adapter layer.

### Phoenix Remains The Edge, Not The Runtime

**Sources:**
- [`guides/phoenix-contexts.md:15`](/Users/jon/projects/scrypath/guides/phoenix-contexts.md:15)
- [`guides/phoenix-liveview.md:39`](/Users/jon/projects/scrypath/guides/phoenix-liveview.md:39)
- [`guides/phoenix-controllers-and-json.md:69`](/Users/jon/projects/scrypath/guides/phoenix-controllers-and-json.md:69)

Apply to plan decomposition: Phase 80 should stop at plain-data casting and runtime delegation. Structured field errors and Phoenix wrappers belong in later phases exactly as `REQUIREMENTS.md` and `ROADMAP.md` split them.

### Docs Contracts Use Narrow String And Order Assertions

**Sources:**
- [`test/scrypath/docs_contract_test.exs:61`](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:61)
- [`test/scrypath/docs_contract_test.exs:67`](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:67)
- [`test/scrypath/docs_contract_test.exs:125`](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:125)

Apply to later docs work: pin stable claims only; avoid prose snapshots and avoid leaking internal planning labels into published docs.

## No Exact Analog Found

| File / Concern | Role | Data Flow | Reason |
|---|---|---|---|
| Public plain-data query toolkit module | utility | transform | Live code has no exact analog; best match is the combination of `Scrypath` public facade plus `Options` validation seam. |
| Structured field-scoped query-param error entries | model | transform | Planning claims `Scrypath.SearchModule.ParamError` exists, but no live code exposes it. Treat this as future work, not a copy source. |
| Phoenix helper module location | utility | request-response | No live optional-Phoenix helper surface exists in core library. Keep out of Phase 80 and defer dependency strategy decisions to Phase 81. |

## Codebase Conventions That Should Constrain Plan Decomposition

- Keep contexts as the application boundary. Live guides repeatedly forbid controller/LiveView orchestration of `Repo` plus `Scrypath.*` directly.
- Reuse existing search option names and semantics. The toolkit should cast into the current runtime grammar, not define a parallel grammar.
- Keep public API modules top-level under `lib/scrypath/`; keep implementation detail modules under subdirectories with `@moduledoc false` where appropriate.
- Avoid freezing new public structs unless the contract truly needs them. The repo already documents the cost of exposing normalized runtime state too early.
- Keep Phoenix optional. Phase 80 should be framework-light and pure-data; do not sneak Phoenix dependency work into the core toolkit slice.
- Keep tests explicit and semantic. The repo prefers focused `assert` / `assert_raise` cases and `Req.Test` payload proofs over meta-harnesses.

## Risks And Drift Notes

- **Archive/code drift is active, not historical.** Rolling planning files and the `v1.20` archive claim `Scrypath.SearchModule`, `search_args/2`, and `Scrypath.SearchModule.ParamError` shipped, but the checked-out code does not expose those APIs. See [`docs/jtbd-gap-map.md:46`](/Users/jon/projects/scrypath/docs/jtbd-gap-map.md:46), [`.planning/MILESTONES.md:11`](/Users/jon/projects/scrypath/.planning/MILESTONES.md:11), and [`.planning/todos/search-module-archive-code-drift.md:14`](/Users/jon/projects/scrypath/.planning/todos/search-module-archive-code-drift.md:14).
- **Seed scope assumes a missing layer.** The v1.21 seed says the toolkit should live "under the search-module layer", but that layer is not grounded in live code. Phase 80 planning should target the actual `Scrypath.search/3` runtime first.
- **Phase split discipline matters.** `REQUIREMENTS.md` and `ROADMAP.md` put plain-data contract work in Phase 80, structured edge errors and Phoenix wrappers in Phase 81, and docs/contract protection in Phase 82. Do not collapse those concerns into one implementation slice.

## Metadata

**Analog search scope:** `lib/scrypath/`, `test/scrypath/`, `guides/`, `docs/`, `.planning/`  
**Pattern extraction date:** 2026-05-22  
**Primary live analogs:** `lib/scrypath.ex`, `lib/scrypath/search.ex`, `lib/scrypath/options.ex`, `lib/scrypath/query.ex`, `test/scrypath/search_test.exs`, `test/scrypath/docs_contract_test.exs`
