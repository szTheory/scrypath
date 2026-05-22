# Phase 81: Edge normalization errors and Phoenix wrappers - Pattern Map

**Mapped:** 2026-05-23  
**Files analyzed:** 14 mandatory files + 2 supporting Phoenix fixture tests  
**Analogs found:** 13 / 15 likely Phase 81 touchpoints

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scrypath/query_params.ex` | utility | transform | `lib/scrypath/query_params.ex` | exact |
| `lib/scrypath/query_params/caster.ex` | service | transform | `lib/scrypath/query_params/caster.ex` + `lib/scrypath/options.ex` | exact |
| `lib/scrypath/query_params/error.ex` | model | transform | `lib/scrypath/options.ex` validation tuples + `test/scrypath/docs_contract_test.exs` assertion style | role-match |
| `lib/scrypath/phoenix.ex` | utility | request-response | `test/support/docs/phoenix_example_case.ex` + Phoenix guides | role-match |
| `test/scrypath/query_params_test.exs` | test | transform | `test/scrypath/query_params_test.exs` | exact |
| `test/scrypath/search_test.exs` | test | request-response | `test/scrypath/search_test.exs` | exact |
| `test/scrypath/docs_contract_test.exs` | test | request-response | `test/scrypath/docs_contract_test.exs` | exact |
| `test/support/docs/phoenix_example_case.ex` | test | request-response | `test/support/docs/phoenix_example_case.ex` | exact |
| `test/support/docs/phoenix_examples_test.exs` | test | request-response | `test/support/docs/phoenix_examples_test.exs` | exact |
| `test/support/docs/phoenix_request_shape_smoke_test.exs` | test | request-response | `test/support/docs/phoenix_request_shape_smoke_test.exs` | exact |
| `guides/phoenix-contexts.md` | config | request-response | `guides/phoenix-contexts.md` | exact |
| `guides/phoenix-liveview.md` | config | request-response | `guides/phoenix-liveview.md` | exact |
| `guides/phoenix-controllers-and-json.md` | config | request-response | `guides/phoenix-controllers-and-json.md` | exact |
| `guides/faceted-search-with-phoenix-liveview.md` | config | request-response | `guides/faceted-search-with-phoenix-liveview.md` | exact |
| `test/scrypath/phoenix_test.exs` or similar new helper-suite file | test | request-response | `test/support/docs/phoenix_examples_test.exs` + `test/scrypath/query_params_test.exs` | role-match |

## Pattern Assignments

### `lib/scrypath/query_params.ex` (public facade, transform)

**Analog:** `lib/scrypath/query_params.ex`

**Public seam and boundary wording** (lines 2-14):
```elixir
@moduledoc """
Public request-edge toolkit for turning top-level request params into one stable
plain-data Scrypath search-args shape.

`%Scrypath.Query{}` remains **internal normalized query state** owned by the common
`Scrypath.search/3` runtime. Host applications should use this module when they want a
framework-light contract that can be cast from request params and then converted into
`{text, keyword_opts}` for a context-owned `Scrypath.search/3` call.
...
This module is data-only: it does not validate schema-specific search semantics and it does not execute searches.
"""
```

**Narrow public API shape** (lines 32-55):
```elixir
@spec cast(map()) :: t()
def cast(params) when is_map(params) do
  Caster.cast(params)
end

@spec to_search_args(t()) :: {String.t(), keyword()}
def to_search_args(%{} = query_params) do
  text = Map.get(query_params, :text, "")

  opts =
    Enum.map(@search_option_keys, fn key ->
      {key, Map.get(query_params, key, default_value(key))}
    end)

  {text, opts}
end
```

**Planner guidance:** keep Phase 81 additive on this module. Add a non-raising normalize/cast path here if it stays the public seam; do not add search execution helpers, macros, or a Phoenix-only shape to the core module.

---

### `lib/scrypath/query_params/caster.ex` (core normalizer, transform)

**Analogs:** `lib/scrypath/query_params/caster.ex`, `lib/scrypath/options.ex`

**Current fetch-and-merge skeleton** (lines 14-32):
```elixir
@spec cast(map()) :: Scrypath.QueryParams.t()
def cast(params) when is_map(params) do
  text =
    params
    |> fetch_text()
    |> normalize_text()

  query_params =
    Map.merge(@default, %{
      text: text,
      filter: fetch_value(params, :filter, "filter", []),
      sort: fetch_value(params, :sort, "sort", []),
      page: fetch_value(params, :page, "page", []),
      facets: fetch_value(params, :facets, "facets", []),
      facet_filter: fetch_value(params, :facet_filter, "facet_filter", []),
      per_query: fetch_value(params, :per_query, "per_query", %{})
    })

  validate_runtime_compatible_nested_values!(query_params)
end
```

**Phase-80 raise seam that Phase 81 replaces** (lines 56-99):
```elixir
defp validate_keyword_value!(query_params, key) do
  value = Map.fetch!(query_params, key)

  if value == [] or Keyword.keyword?(value) do
    query_params
  else
    raise ArgumentError, unsupported_nested_shape_message(key, "a keyword list")
  end
end

defp unsupported_nested_shape_message(key, expected_shape) do
  "Scrypath.QueryParams.cast/1 expects runtime-compatible nested values for #{inspect(key)} " <>
    "during phase 80. Use #{expected_shape} instead of request-style nested params."
end
```

**Allowlisted validation flow to mirror** from `lib/scrypath/options.ex` lines 452-470:
```elixir
def validate_search_options(schema_module, opts) when is_list(opts) do
  ...
  with {:ok, validated} <- nimble_options_result(@search_options, search_opts),
       :ok <- validate_search_facets(schema_module, Keyword.get(validated, :facets, [])),
       :ok <-
         validate_search_facet_filter(schema_module, Keyword.get(validated, :facet_filter, [])) do
    try do
      validated
      |> validate_filterable_fields!(filterable)
      |> validate_sortable_fields!(sortable)
      |> then(&{:ok, &1})
    rescue
      e in ArgumentError -> {:error, {:validation, Exception.message(e)}}
    end
  end
end
```

**Nimble-style invalid-option shaping** from `lib/scrypath/options.ex` lines 485-492:
```elixir
defp nimble_options_result(schema, opts) do
  case NimbleOptions.validate(opts, schema) do
    {:ok, validated} ->
      {:ok, validated}

    {:error, %NimbleOptions.ValidationError{} = error} ->
      {:error, nimble_validation_to_invalid_options(error)}
  end
end
```

**Planner guidance:** implement browser-param normalization here or in a tightly scoped child module under `lib/scrypath/query_params/`; return aggregate structured errors instead of raising. Keep the output keyed as the existing `QueryParams.t()` contract so `to_search_args/1` and the `Scrypath.search/3` path remain unchanged.

---

### `lib/scrypath/query_params/error.ex` (new structured edge-error model, transform)

**Closest analogs:** `lib/scrypath/options.ex`, `test/scrypath/query_params_test.exs`

**Existing tagged-error discipline to reuse** from `lib/scrypath/options.ex` lines 452-483:
```elixir
@spec validate_search_options(module(), keyword()) :: {:ok, keyword()} | {:error, term()}
...
{:error, {:validation, message}}
{:error, {:invalid_options, _field, message}}
{:error, {:unknown_facet, facet}}
{:error, {:invalid_facet_filter, reason}}
```

**Contract-focused assertion style to mirror** from `test/scrypath/query_params_test.exs` lines 59-69:
```elixir
assert_raise ArgumentError, ~r/runtime-compatible nested values for :filter/, fn ->
  QueryParams.cast(%{"q" => "phoenix", "filter" => %{"status" => "published"}})
end
```

**Planner guidance:** prefer a plain map or small public struct with explicit fields:
- `form_errors`
- `field_errors`
- `errors`

Each leaf issue should be plain data with `code`, `message`, `path`, and `meta`. Do not project Ecto changeset tuples into the core module. Keep Phoenix projection in `Scrypath.Phoenix`.

---

### `lib/scrypath/phoenix.ex` (optional Phoenix wrapper, request-response)

**Closest analogs:** `test/support/docs/phoenix_example_case.ex`, `guides/phoenix-liveview.md`, `guides/phoenix-controllers-and-json.md`

**Why this is a role match, not an exact analog:** there is no existing Phoenix helper module in `lib/`, and `rg` found no live `Phoenix.*` dependency seam in the library source. The closest live behavior is the hand-written web-layer glue in docs fixtures.

**Controller translation seam to replace** from `test/support/docs/phoenix_example_case.ex` lines 49-58:
```elixir
def index(params) do
  query = Map.get(params, "q", "")

  with {:ok, result} <- Content.search_posts(query, filter: [status: "published"]) do
    %{posts: result.records, search: result}
  end
end
```

**JSON paging normalization seam to replace** from `test/support/docs/phoenix_example_case.ex` lines 65-92:
```elixir
def index(params) do
  query = Map.get(params, "q", "")
  page_number = params |> Map.get("page", 1) |> normalize_page()

  with {:ok, result} <- Content.search_posts(query, page: [number: page_number, size: 20]) do
    %{
      data: Enum.map(result.records, &serialize_post/1),
      page: %{number: page_number, size: 20},
      search: result
    }
  end
end
```

**LiveView URL-source-of-truth seam to replace** from `test/support/docs/phoenix_example_case.ex` lines 122-139:
```elixir
def handle_params(params, socket) do
  q = Map.get(params, "q", "")
  genres = parse_genres(params["genre"])

  facet_filter =
    case genres do
      [] -> []
      list -> [genre: list]
    end

  with {:ok, result} <-
         Content.search_movies(q,
           facets: [:genre, :year, :rating],
           facet_filter: facet_filter
         ) do
    Map.merge(socket, %{q: q, posts: result.records, facet_filter: facet_filter})
  end
end
```

**Boundary wording to preserve** from `guides/phoenix-liveview.md` lines 3-5 and 32-39:
```md
LiveView is a strong fit for search interfaces, but the recommended Scrypath boundary stays the same: LiveView owns UI state, and the context owns repo access plus Scrypath orchestration.
...
The context should own:
- repo-backed hydration
- backend selection
- `Scrypath.search/3` options
- write-path sync and delete orchestration
```

**Planner guidance:** recommended location is one plain-function module, `lib/scrypath/phoenix.ex`. Keep helpers literal:
- `from_params/1` or `normalize_params/1` delegating to `Scrypath.QueryParams`
- `to_form_data/1` or similar projection for attempted values + errors
- `to_query_params/1` for URL round-tripping

Do not add controller macros, `use Scrypath.Phoenix`, components, sockets, or context calls.

---

### `test/scrypath/query_params_test.exs` (core normalization contract tests, transform)

**Analog:** `test/scrypath/query_params_test.exs`

**Current happy-path shape assertion** (lines 6-48):
```elixir
assert %{
         text: "phoenix",
         filter: [status: "published"],
         sort: [desc: :inserted_at],
         page: [number: 2, size: 20],
         facets: [:genre, :year],
         facet_filter: [genre: ["Action", "Drama"]],
         per_query: %{show_ranking_score: true}
       } = query_params = QueryParams.cast(params)
...
assert {"phoenix", [...]} = QueryParams.to_search_args(query_params)
```

**Current narrow-surface checks** (lines 72-81):
```elixir
assert function_exported?(QueryParams, :cast, 1)
assert function_exported?(QueryParams, :to_search_args, 1)
refute function_exported?(QueryParams, :search, 1)
refute function_exported?(QueryParams, :search, 2)
refute function_exported?(QueryParams, :search, 3)
```

**Planner guidance:** extend this file for Phase 81 with explicit browser-shape cases:
- `page[number]` / `page[size]`
- `filter[field]` and `filter[field][]`
- `facet_filter[field]`
- indexed or scalar `sort`
- unknown nested keys producing structured aggregate errors

Keep assertions explicit and shape-focused. Assert full error payload maps, not just messages.

---

### `test/scrypath/search_test.exs` (runtime continuity tests, request-response)

**Analog:** `test/scrypath/search_test.exs`

**Existing “toolkit feeds the same runtime” proof** (lines 117-152):
```elixir
query_params =
  QueryParams.cast(%{
    "q" => "phoenix",
    "filter" => [status: "published"],
    "sort" => [desc: :inserted_at],
    "page" => [number: 2, size: 20],
    "per_query" => %{show_ranking_score: true}
  })

{text, search_opts} = QueryParams.to_search_args(query_params)

assert {:ok, %SearchResult{query: toolkit_query}} =
         Scrypath.search(SearchablePost, text,
           Keyword.put(search_opts, :backend, Scrypath.TestSupport.FakeBackend)
         )
...
assert toolkit_query == direct_query
```

**Error-vs-raise vocabulary to preserve** from `lib/scrypath/search.ex` lines 17-25 and 27-41:
```elixir
* **`ArgumentError`** — reserved for caller misuse that mirrors invalid option shapes
* **`{:error, reason}`** — operational and validation outcomes you should branch on
```

**Planner guidance:** keep one continuity test here proving that browser-shaped normalization still feeds the existing runtime path with no second execution surface. Do not move request-edge failure assertions into `search_test.exs`; they belong in `query_params_test.exs` or a dedicated Phoenix helper test.

---

### `test/scrypath/docs_contract_test.exs` (guide and docs drift protection)

**Analog:** `test/scrypath/docs_contract_test.exs`

**Guide fixture anchor pattern** (lines 359-370):
```elixir
docs = [@readme | Map.values(@guides)] |> Enum.join("\n")

assert_contains_all(docs, [
  "search_posts(query, opts \\\\ [])",
  "publish_post(post, attrs)",
  "defmodule MyAppWeb.PostController",
  "defmodule MyAppWeb.PostLive",
  "defmodule MyAppWeb.Api.PostController"
])
```

**Phoenix boundary assertions** (lines 776-798):
```elixir
assert_contains_all(@guides["guides/phoenix-contexts.md"], [
  "Scrypath fits Phoenix best when your context is the application-facing boundary",
  "Do not teach controllers or LiveView modules to compose raw `Repo` and `Scrypath.*` calls as the main pattern."
])

assert_contains_all(@guides["guides/phoenix-controllers-and-json.md"], [
  "Phoenix controllers should translate request params into a context call",
  "Do not recommend direct `Repo` queries plus direct `Scrypath.search/3` calls inside the controller.",
  "page_number =",
  "normalize_page()",
  "Integer.parse(page)"
])
```

**Planner guidance:** add narrow string-anchor tests for new Phoenix helper docs:
- optional Phoenix namespace
- `handle_params/3` as canonical normalization point
- field-scoped renderable errors
- no hard Phoenix dependency in the core path

Do not snapshot full guides.

---

### `test/support/docs/phoenix_example_case.ex` (compile-checked docs fixture)

**Analog:** `test/support/docs/phoenix_example_case.ex`

**Current hand-rolled controller/LiveView glue** (lines 49-58, 65-92, 97-115, 122-139) is the best live source for what Phase 81 should simplify.

**Request-shape fidelity on write events** (lines 111-115):
```elixir
def handle_event("publish", %{"id" => id, "post" => attrs}, socket) do
  post = Content.get_post!(id)
  {:ok, _post} = Content.publish_post(post, attrs)

  socket
end
```

**Planner guidance:** update this fixture to use the new helper module in read flows only:
- controller params -> helper normalize -> context call
- LiveView `handle_params/3` -> helper normalize -> context call
- attempted values / error projection in assigns

Keep writes string-keyed and out of Scrypath.Phoenix unless Phase 81 explicitly includes generic form-error projection.

---

### `test/support/docs/phoenix_examples_test.exs` (fixture contract tests)

**Analog:** `test/support/docs/phoenix_examples_test.exs`

**Boundary-policing style** (lines 18-31):
```elixir
refute controller_section =~ "Repo"
refute controller_section =~ "Scrypath.search"
refute controller_section =~ "Scrypath.sync"
refute liveview_section =~ "Repo"
refute liveview_section =~ "Scrypath.search"
refute liveview_section =~ "Scrypath.sync"
assert controller_section =~ "Content.search_posts"
assert liveview_section =~ "Content.search_posts"
```

**Explicit param-normalization test style** (lines 48-76):
```elixir
assert api_section =~ "page_number = params |> Map.get(\"page\", 1) |> normalize_page()"
...
Enum.each(cases, fn params ->
  response = ApiPostController.index(params)
  assert response.page == %{number: 1, size: 20}
end)
```

**Planner guidance:** mirror this file when adding helper-driven fixture coverage. Assert helpers reduce glue, but still keep context calls in the web boundary.

---

### `test/support/docs/phoenix_request_shape_smoke_test.exs` (Plug-decoded shape smoke test)

**Analog:** `test/support/docs/phoenix_request_shape_smoke_test.exs`

**Plug-native request shape proof** (lines 6-10):
```elixir
params = Plug.Conn.Query.decode("id=1&post[title]=Published")
socket = PostLive.mount()

assert %{"id" => "1", "post" => %{"title" => "Published"}} = params
```

**Planner guidance:** add equivalent smoke tests for the new browser grammar using `Plug.Conn.Query.decode/1`. This is the best exact analog for proving the phase is based on real Plug decoding, not invented nested maps.

---

### `guides/phoenix-contexts.md` (boundary guide)

**Analog:** `guides/phoenix-contexts.md`

**Context-first rule to preserve** (lines 5-19):
```md
Keep these responsibilities in the context:
- `Scrypath.search/3` calls plus repo-backed hydration policy
- preload, filter, sort, and paging defaults that belong to the feature

Do not teach controllers or LiveView modules to compose raw `Repo` and `Scrypath.*` calls as the main pattern.
```

**Planner guidance:** Phase 81 guide updates should mention helpers as request-edge glue only. Do not reframe the architecture around `Scrypath.Phoenix`.

---

### `guides/phoenix-liveview.md` (LiveView boundary guide)

**Analog:** `guides/phoenix-liveview.md`

**Canonical `handle_params/3` pattern** (lines 5-23):
```elixir
def handle_params(%{"q" => query}, _uri, socket) do
  {:ok, result} = Content.search_posts(query, preload: [:author])

  {:noreply,
   assign(socket,
     posts: result.records,
     search: result,
     query: query
   )}
end
```

**Ownership split to preserve** (lines 32-39):
```md
LiveView should own:
- current query text
- filter and sort params that belong in the URL

The context should own:
- repo-backed hydration
- backend selection
- `Scrypath.search/3` options
```

**Planner guidance:** update this guide to show `handle_params/3` calling the new normalize helper once, assigning attempted values and field errors, then calling the context only on success.

---

### `guides/phoenix-controllers-and-json.md` (controller guide)

**Analog:** `guides/phoenix-controllers-and-json.md`

**Thin-controller translation pattern** (lines 15-21, 36-63):
```elixir
def index(conn, params) do
  {:ok, result} =
    Content.search_posts(Map.get(params, "q", ""),
      filter: [status: "published"]
    )

  render(conn, :index, posts: result.records, search: result)
end
...
page_number =
  params
  |> Map.get("page", 1)
  |> normalize_page()
```

**Anti-shortcut wording** (lines 67-73):
```md
Keep JSON shaping in the controller or view layer. Keep repo access, search orchestration, and sync visibility choices in the context.

Do not recommend direct `Repo` queries plus direct `Scrypath.search/3` calls inside the controller.
```

**Planner guidance:** update examples to show helper-produced normalized args and helper-projected error payloads for HTML/JSON, while keeping controller rendering and context calls explicit.

---

### `guides/faceted-search-with-phoenix-liveview.md` (Phoenix URL and filter guide)

**Analog:** `guides/faceted-search-with-phoenix-liveview.md`

**URL-first recommendation** (lines 94-113):
```md
## Primary path: `handle_params` + URL sync

**Recommended:** normalize query + facet params in `handle_params/3`, then call your context with a keyword list that mirrors what you will pass to `Scrypath.search/3`.
```

**Current anti-pattern wording that Phase 81 should sharpen, not replace** (lines 224-230):
```md
#### UI — Mutating URL only in `handle_event`
...
**Do instead:** Mirror params in `handle_params/3` and `push_patch/2`.
```

**Current error-rendering wording** (lines 147-152):
```md
## Loading and errors
...
On `{:error, reason}`, show **Search could not complete.** with `inspect(reason)` in monospace
```

**Planner guidance:** this guide should become the canonical place for field-scoped normalization errors in faceted LiveView flows. Keep the distinction between request-edge errors and runtime `{:error, reason}` tuples explicit.

## Shared Patterns

### Small Public APIs Stay Thin And Delegating

**Sources:**
- `lib/scrypath/query_params.ex` lines 32-55
- `lib/scrypath/query.ex` lines 2-7

Apply to Phase 81:
- keep `Scrypath.QueryParams` as the public core seam
- keep `%Scrypath.Query{}` internal
- keep helper functions boring and literal

### Validation Should Aggregate Errors Before Search Runtime

**Sources:**
- `lib/scrypath/options.ex` lines 452-470
- `lib/scrypath/search.ex` lines 27-41

Apply to Phase 81:
- normalize request-edge input before `Scrypath.search/3`
- convert browser-shape failures into `{:error, error_map}`
- do not mix request-edge validation failures with runtime/backend failures

### Plug-Decoded Shapes Should Be Tested Directly

**Sources:**
- `test/support/docs/phoenix_request_shape_smoke_test.exs` lines 6-10
- `test/support/docs/phoenix_example_case.ex` lines 111-115

Apply to Phase 81:
- use `Plug.Conn.Query.decode/1` for nested param grammar tests
- prove the accepted grammar is Plug-native, not hypothetical

### Phoenix Remains An Optional Edge Adapter

**Sources:**
- `guides/phoenix-contexts.md` lines 15-19
- `guides/phoenix-liveview.md` lines 32-39
- `guides/phoenix-controllers-and-json.md` lines 67-73
- `test/support/docs/phoenix_examples_test.exs` lines 18-31

Apply to Phase 81:
- helpers may normalize params, shape form data, and round-trip URL params
- helpers must not call contexts, execute searches, own sockets, or introduce a second runtime

### Docs Contract Tests Should Pin Stable Claims Only

**Sources:**
- `test/scrypath/docs_contract_test.exs` lines 359-370
- `test/scrypath/docs_contract_test.exs` lines 776-798

Apply to Phase 81:
- assert optional Phoenix namespace wording
- assert context-first architecture wording
- assert `handle_params/3` as the canonical LiveView search entry
- avoid full prose snapshots

## Anti-Patterns To Block

- Creating a second execution surface that bypasses `Scrypath.QueryParams.to_search_args/1` and the existing `Scrypath.search/3` runtime.
- Hard-wiring Phoenix dependencies into the core `Scrypath.QueryParams` path. No existing `lib/` module provides a Phoenix seam today.
- Turning the core error contract into `%Ecto.Changeset{}` semantics. Phoenix projection belongs in `Scrypath.Phoenix`, not the core normalizer.
- Adding `use Scrypath.Phoenix`, controller mixins, macros, or generated widgets.
- Letting LiveView `handle_event/3` become a second search path instead of computing and patching URL state.
- Widening the browser grammar to expose `per_query` or a richer query DSL just to shorten docs examples.

## No Exact Analog Found

| File / Concern | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/scrypath/phoenix.ex` | utility | request-response | No existing optional Phoenix helper module exists in the live library source. |
| `lib/scrypath/query_params/error.ex` | model | transform | No current public structured edge-error model exists; current seam is raising or tagged validation tuples. |

## Planner Recommendations

1. Put the core work in `lib/scrypath/query_params.ex` and `lib/scrypath/query_params/caster.ex`, not in `Scrypath.Search` and not in a second “browser runtime” module.
2. Add one new public optional helper module at `lib/scrypath/phoenix.ex` if the dependency strategy allows it; otherwise keep the planner honest that Phoenix helper content may need to land as docs-first until the optional dependency seam is decided.
3. Add focused tests in `test/scrypath/query_params_test.exs` for browser grammar and structured error payloads, plus one runtime continuity assertion in `test/scrypath/search_test.exs`.
4. Update the compile-checked Phoenix fixture and its tests so controllers and LiveView normalize once, assign attempted values/errors, and still call the context boundary for actual search work.
5. Update `guides/phoenix-liveview.md`, `guides/phoenix-controllers-and-json.md`, and `guides/faceted-search-with-phoenix-liveview.md` together; back them with narrow `docs_contract_test.exs` anchors that pin the context-first boundary and the new helper story.
6. Use `Plug.Conn.Query.decode/1` in tests to define accepted nested param shapes exactly. That is the strongest live pattern for the “ordinary Phoenix/Plug params” requirement in `81-CONTEXT.md`.

## Metadata

**Analog search scope:** `lib/scrypath/`, `test/scrypath/`, `test/support/docs/`, `guides/`, `.planning/phases/80-public-query-toolkit-contract/`, `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/`  
**Files scanned:** 16  
**Pattern extraction date:** 2026-05-23
