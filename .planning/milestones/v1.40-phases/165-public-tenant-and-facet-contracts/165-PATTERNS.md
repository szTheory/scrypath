# Phase 165: Public Tenant and Facet Contracts - Pattern Map

**Mapped:** 2026-09-26
**Files classified:** 8 core candidates (2 new tests, 6 conditional production edits); 4 existing test homes classified separately
**Analogs found:** 8 / 8 core candidates

## Scope and Evidence

Use two independently runnable public-entry test files from RESEARCH.md. Production files below are correction candidates, not an instruction to edit all of them. C10-R1 and C11-R1 remain unexecuted hypotheses. This mapping ran no tests and establishes no defect or passing contract.

AGENTS.md and CONTRIBUTING.md govern execution. No project skill files were found under `.codex/skills/` or `.agents/skills/`. Relevant local Elixir/Ecto prompts support pure translation separated from IO and explicit orchestration; the historical search prompt's Typesense recommendation is superseded by the current Meilisearch decision.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/scrypath/tenant_scope_contract_test.exs` (new) | test | request-response | `test/scrypath/search_many_test.exs` | exact |
| `test/scrypath/facet_values_contract_test.exs` (new) | test | request-response | `test/scrypath/meilisearch/client_test.exs`, supplemented by public assertions in `test/scrypath/search_test.exs` | exact |
| `lib/scrypath/search/single.ex` (conditional) | service | request-response | its existing `run/5` and `runtime_opts/1` | exact, in-place |
| `lib/scrypath/search/many.ex` (conditional) | service | batch, request-response | `lib/scrypath/search/single.ex` option separation; own preflight/dispatch | exact for option separation |
| `lib/scrypath/search/facet_values.ex` (conditional) | service | request-response | `lib/scrypath/search/single.ex` | exact |
| `lib/scrypath/meilisearch.ex` (conditional) | service | request-response | own facet callback and ordinary search delegation | exact, in-place |
| `lib/scrypath/meilisearch/client.ex` (conditional) | service | request-response | own `search_payload/1`; `lib/scrypath/meilisearch/query.ex` for filter translation | exact, in-place |
| `lib/scrypath/meilisearch/query.ex` (conditional) | utility | transform | own `translate_filter/1` and `format_value/1` | exact, in-place |

CONTEXT also names existing test homes. Prefer the two independent new files; these are alternatives or narrow supplemental regressions, not four additional mandatory edits:

| Existing file | Role | Data Flow | Pattern assignment |
|---|---|---|---|
| `test/scrypath/options_test.exs` | test | transform | Own tenant normalization examples, lines 620–663; validator-only evidence cannot replace public calls |
| `test/scrypath/search_test.exs` | test | request-response | Own public facet/error tests, lines 107–142 |
| `test/scrypath/search_many_test.exs` | test | batch, request-response | Own recording backend, lines 81–109, and shared input assertion, lines 288–297 |
| `test/scrypath/meilisearch/client_test.exs` | test | request-response | Own encoded facet body test, lines 127–151; preserve rendered-filter compatibility |

`lib/scrypath/options/search.ex` is the existing validation authority to preserve, not a planned redesign. Public facade `lib/scrypath/search.ex` is an error-compatibility reference. No new config, dependency, global support fixture, CI task, migration, or authentication module is implied.

## Pattern Assignments

### `test/scrypath/tenant_scope_contract_test.exs`

**Primary analog:** `test/scrypath/search_many_test.exs`.

**Test conventions** (lines 1–5):

```elixir
defmodule Scrypath.SearchManyTest do
  use ExUnit.Case, async: false

  alias Scrypath.MultiSearchResult
  alias Scrypath.SearchResult
```

The analog attaches global telemetry handlers later in the file. A new file using only local modules and process-local messages can follow `search_test.exs:1–7` and use `async: true`; do not copy global telemetry setup solely to copy its async setting.

**Recording backend core** (`search_many_test.exs:100–104`):

```elixir
@impl true
def search(_schema, query, _config) do
  send(self(), {:per_query_search, query})
  {:ok, %{"hits" => [%{"id" => 1, "title" => query.text}], "page" => 1, "hitsPerPage" => 20}}
end
```

**Shared input and dispatch assertion** (lines 288–297):

```elixir
test "search_many per_query: shared-only merge (sequential path)" do
  opts =
    Keyword.merge(@base_opts,
      backend: PerQuerySeqBackend,
      per_query: [show_ranking_score: true]
    )

  assert {:ok, _} = Scrypath.search_many([{SearchablePost, "x"}], opts)

  assert_receive {:per_query_search, %Scrypath.Query{per_query: %{show_ranking_score: true}}}
```

Adapt the message to record schema and query; assert the combined tenant and status filter. Put `tenant_scope:` in shared multi-search options to exercise `Many.runtime_opts/1`. A sequential-only recorder is sufficient for this seam and avoids building federation fixtures. Record facet options in the facet callback as well. After invalid calls, assert the path-specific error plus `refute_received` for the dispatch message.

Implement the behavior's `name/0`, `index_name/2`, upsert/delete, search, and facet callbacks. The analog's lines 82–109 provide the full skeleton. `search_test.exs:63–66` supplies a successful facet callback:

```elixir
@impl true
def search_facet_values(_schema_module, _facet_name, search_string, _opts, _config) do
  {:ok, %{"facetQuery" => search_string, "facetHits" => [%{"value" => "foo", "count" => 1}]}}
end
```

Use local declared schema fixtures with tenant/status metadata and an undeclared control. `options_test.exs:620–633` contains minimal metadata-only mocks; they are sufficient for the validator but lack the full metadata needed by public result decoration. Do not copy those mocks unchanged into a public-entry test. Prefer a real schema declaration as recommended by RESEARCH.md.

### `test/scrypath/facet_values_contract_test.exs`

**Primary analog:** `test/scrypath/meilisearch/client_test.exs`; public result and raising assertions from `test/scrypath/search_test.exs`.

**Imports/test setup** (`client_test.exs:1–4`): `use ExUnit.Case, async: true` and one alias per line. New public tests should call `Scrypath.search_facet_values/4` with `backend: Scrypath.Meilisearch`, not the aliased Client function.

**Encoded request observation** (`client_test.exs:129–145`):

```elixir
stub = Module.concat(__MODULE__, FacetSearchOkStub)

Req.Test.stub(stub, fn conn ->
  assert conn.method == "POST"
  assert conn.request_path == "/indexes/posts_v2/facet-search"
  {:ok, body, conn} = Plug.Conn.read_body(conn)
  params = Jason.decode!(body)

  assert params["facetName"] == "genre"
  assert params["facetQuery"] == "co"
  assert params["filter"] == ["status = 'published'"]

  Req.Test.json(conn, %{
    "facetHits" => [%{"value" => "comedy", "count" => 42}],
    "facetQuery" => "co"
  })
end)
```

The quoted filter belongs to the existing low-level rendered-input test. The new public input must be keyword data such as `filter: [status: "published"]`; its expected string follows the existing JSON-literal renderer, including double quotes. Supply `meilisearch_url: "http://localhost:7700"` and `req_options: [plug: {Req.Test, stub}, retry: false]` through the public API. Use a deterministic index override or the fixture's declared index and assert its actual route.

Keep defaults and keyword-filter probes separate, initially without tenant scope. Research documents that the pinned v1.15 parser ignores unknown search parameters: do not invent an exact-key whitelist rejection oracle for defaults. This is request-shape proof, not a live-service receipt.

**Public result** (`search_test.exs:109–116`):

```elixir
assert {:ok,
        %Scrypath.FacetSearchResult{
          hits: [%Scrypath.SearchResult.Facets.Bucket{value: "foo", count: 1}],
          facet_query: "fo"
        }} =
         Scrypath.search_facet_values(SearchablePost, "category", "fo",
           backend: HydrationBackend
         )
```

Replace the test backend with the real adapter for the HTTP contract. For backend HTTP failure, copy `client_test.exs:26–30`:

```elixir
Req.Test.stub(stub, fn conn ->
  conn
  |> Plug.Conn.put_status(404)
  |> Req.Test.json(%{"message" => "not found"})
end)
```

For transport failure, lines 42–49 use `Req.Test.transport_error(conn, :timeout)` and assert `{:error, {:transport_error, %Req.TransportError{reason: :timeout}}}` with retries disabled. Count or record requests so error propagation cannot silently introduce an unfiltered retry.

### `lib/scrypath/search/single.ex`, `many.ex`, and `facet_values.ex`

**Primary analog:** `single.ex`, retaining each existing file's shape.

**Alias convention** (`single.ex:4–7`):

```elixir
alias Scrypath.Config
alias Scrypath.Query
alias Scrypath.Search.Result
alias Scrypath.Telemetry
```

**Validated data versus original caller configuration** (`single.ex:14–15`):

```elixir
config = Config.resolve!(runtime_opts(caller_opts))
query = Query.new(text, search_opts)
```

**Existing extraction pattern** (`single.ex:44–54`):

```elixir
defp runtime_opts(opts) do
  Keyword.drop(opts, [
    :filter,
    :sort,
    :page,
    :facets,
    :facet_filter,
    :global_schemas,
    :per_query
  ])
end
```

The sibling lists are `many.ex:187–197` and `facet_values.ex:33–43`. If the public probe reproduces tenant runtime leakage, make the narrow exclusion in the responsible lists. Preserve strict config validation and the normalized filter. Avoid a new shared abstraction merely for three one-key edits.

`many.ex:44–46` resolves shared configuration after per-entry validation; `many.ex:73–81` preserves the schema-associated failure wrapper. `facet_values.ex:17–27` forwards validated options to the callback and only decorates successful results. These are in-place assignments, not a reason to unify their distinct result/error behavior.

### `lib/scrypath/meilisearch.ex`

**Analog:** own ordinary search delegation (`54–63`) and facet callback (`65–75`). Imports already alias Client, Naming, MeilisearchQuery, and common Query (`16–24`). Preserve index precedence and injected client behavior:

```elixir
# lines 68–74
def search_facet_values(schema_module, facet_name, facet_query, opts, config) do
  index =
    Keyword.get(config, :index_name) ||
      Keyword.get(config, :target_index) ||
      index_name(schema_module, config)

  client(config).facet_search(index, facet_name, facet_query, opts, config)
```

Only modify this seam if reproduction identifies it as the appropriate common-to-native translation boundary. Keep the injected client contract in mind when choosing between adapter and client changes.

### `lib/scrypath/meilisearch/client.ex`

**Analog:** own ordinary search path plus `query.ex` translator.

**Imports** (`client.ex:6–7`):

```elixir
alias Scrypath.Meilisearch.Query, as: MeilisearchQuery
alias Scrypath.Query, as: CommonQuery
```

**Existing compatibility split** (`188–190`):

```elixir
defp search_payload(%CommonQuery{} = query), do: MeilisearchQuery.to_payload(query)
defp search_payload(query) when is_binary(query), do: %{q: query}
defp search_payload(query) when is_map(query), do: query
```

Facet construction (`104–123`) currently camelizes top-level keys and preserves values. If keyword filter serialization fails, reuse only the needed filter translation and preserve the rendered filter list exercised by `client_test.exs:147–150`. Do not blindly copy the full ordinary-search payload with pagination and ranking semantics. Retain `run_request/5`, transport injection, and response normalization.

### `lib/scrypath/meilisearch/query.ex`

**Analog:** own pure filter renderer (`76–88`):

```elixir
defp translate_filter([]), do: nil

defp translate_filter(filters) do
  Enum.flat_map(filters, fn
    {field, value} when is_list(value) ->
      Enum.map(value, fn {operator, operand} ->
        "#{field} #{translate_operator(operator)} #{format_value(operand)}"
      end)

    {field, value} ->
      ["#{field} = #{format_value(value)}"]
  end)
end
```

**Literal encoding** (`104–105`):

```elixir
defp format_value(value) when is_atom(value), do: Jason.encode!(Atom.to_string(value))
defp format_value(value), do: Jason.encode!(value)
```

If a narrow internal reuse seam is necessary, keep the same grammar and error assumptions. Operators at `98–102` are `eq`, `gt`, `gte`, `lt`, `lte`. Add one discriminating escaping/range regression only if the changed seam warrants it; do not create a second renderer or a broad property suite.

## Shared Patterns

### Validation and tenant composition

**Source:** `lib/scrypath/options/search.ex:93–95`; apply to both public contract files and preserve in production:

```elixir
opts
|> Keyword.delete(:tenant_scope)
|> Keyword.put(:filter, Keyword.put(existing, tenant_field, tenant_scope))
```

The same function rejects absent tenant declarations (`81–84`) and collisions (`88–91`). The validator rescues `ArgumentError` into `{:error, {:validation, message}}` (`15–23`). Collision is any existing tenant key, even if its value matches. Tenant scope is filter composition; authentication, membership, trusted actor selection, and database authorization stay host-owned.

### Public error compatibility

**Source:** `lib/scrypath/search.ex:77–82`; apply to single/facet rejection tests:

```elixir
case Scrypath.Options.validate_search_options(schema_module, opts) do
  {:error, {:validation, message}} when is_binary(message) ->
    raise ArgumentError, message

  {:error, {:invalid_options, _field, message}} when is_binary(message) ->
    raise ArgumentError, message
```

Multi-search instead wraps validation failures (`many.ex:79–80`):

```elixir
{:error, reason} ->
  {:halt, {:error, {:validation_failed, schema, reason}}}
```

The facet bang wrapper raises `Scrypath.Search.Error` with the original `reason` (`search.ex:94–98`). The existing assertion pattern captures `err = assert_raise ...` then checks `err.reason` (`search_test.exs:129–135`). Do not standardize these different behaviors as part of this phase.

### HTTP errors and telemetry

**Source:** `client.ex:173–179`; apply to facet failure probes:

```elixir
defp normalize_response({:ok, %Req.Response{status: status, body: body}}) do
  {:error, {:http_error, status, body}}
end

defp normalize_response({:error, exception}) do
  {:error, {:transport_error, exception}}
end
```

`single.ex:22–31`, `facet_values.ex:14–30`, and `client.ex:143–149` retain the existing `Telemetry.span` pattern with `{result, stop_metadata}`. No additional logging or transport wrapper is needed. Backend fixtures must implement name/index hooks so telemetry setup succeeds before dispatch.

## No Analog Found

No core candidate lacks a useful analog. There is no single existing test that combines a public facet call, real adapter, and encoded Req.Test assertion: compose the public test and client test patterns above. Real local schema fixtures and exact rejection-before-dispatch assertions are the deliberate new proof, not inferred existing coverage.

## Metadata

**Analog search scope:** `lib/scrypath/search*`, `lib/scrypath/options/search.ex`, `lib/scrypath/meilisearch*`, and the four named existing test files.
**Primary reusable matches:** 5 — search-many tests, public search tests, client tests, single-search orchestration, and query translation. Additional reads were the directly named correction targets and error authority, not an expanded analog hunt.
**Source/test files inspected:** 12 (some supporting test excerpts only).
**Tracked-source gate:** `git ls-files --` returned every existing source/test path named as an analog; no install/runtime mirrors are referenced.
**Pattern extraction date:** 2026-09-26.
**Tool adaptation:** This runtime exposes no Read/Write tools; file reads used shell commands and this sole output used the available `apply_patch` writer. No source edits or tests were performed.
**Execution handoff:** Run the two new files independently before assigning failure/pass dispositions; then follow CONTRIBUTING's applicable fast/core, tenant, facet, multi-search, and backend checks. Historical focused wrappers do not necessarily include the new files. Preserve exact source identity and claim limits in execution evidence; Phase 166 service implications remain conditional on actual results.
