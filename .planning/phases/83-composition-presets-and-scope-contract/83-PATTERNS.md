# Phase 83: Composition Presets And Scope Contract - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 10
**Analogs found:** 9 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scrypath/composition.ex` | utility | transform | `lib/scrypath/query_params.ex` | exact |
| `lib/scrypath/composition/merge.ex` | utility | transform | `lib/scrypath/multi_search/entries.ex` | exact |
| `lib/scrypath/composition/normalize.ex` | utility | transform | `lib/scrypath/query_params.ex` | role-match |
| `lib/scrypath/composition/result.ex` | model | transform | `lib/scrypath/multi_search_result.ex` | role-match |
| `lib/mix/tasks/verify.phase83.ex` | utility | batch | `lib/mix/tasks/verify.phase82.ex` | exact |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `test/scrypath/composition_test.exs` | test | transform | `test/scrypath/query_params_test.exs` | role-match |
| `test/scrypath/composition_property_test.exs` | test | transform | `test/scrypath/multi_search/entries_test.exs` | partial |
| `test/scrypath/docs_contract_test.exs` | test | request-response | `test/scrypath/docs_contract_test.exs` | exact |
| `lib/scrypath.ex` | utility | request-response | `lib/scrypath.ex` | exact |

## Pattern Assignments

### `lib/scrypath/composition.ex` (utility, transform)

**Analog:** `lib/scrypath/query_params.ex`

**Imports and alias pattern** ([lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:19)):
```elixir
alias Scrypath.QueryParams.Caster
alias Scrypath.QueryParams.Error
```

**Public plain-data contract pattern** ([lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:22)):
```elixir
@typedoc "Stable public plain-data contract for `Scrypath.search/3` args."
@type t :: %{
        text: String.t(),
        filter: keyword(),
        sort: keyword(),
        page: keyword(),
        facets: [atom()],
        facet_filter: keyword(),
        per_query: map()
      }
```

**Narrow function-first facade pattern** ([lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:41)):
```elixir
@spec normalize(map()) :: {:ok, t()} | {:error, normalize_error_map()}
def normalize(params) when is_map(params) do
  Caster.normalize(params)
end

@spec cast(map()) :: t()
def cast(params) when is_map(params) do
  Caster.cast(params)
end
```

**Canonical output conversion pattern** ([lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:61)):
```elixir
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

**Boundary language to preserve on the new public seam** ([lib/scrypath.ex](/Users/jon/projects/scrypath/lib/scrypath.ex:27)):
```elixir
Keep request-edge casting in controllers, LiveViews, or other app-owned boundaries with
`Scrypath.QueryParams`. If you are in Phoenix, `Scrypath.Phoenix` is optional glue for
params, forms, and URL round-tripping only. Keep orchestration in your contexts, where
`Scrypath.search/3` remains the canonical runtime entrypoint.
```

### `lib/scrypath/composition/merge.ex` (utility, transform)

**Analog:** `lib/scrypath/multi_search/entries.ex`

**Module doc pattern for explicit precedence rules** ([lib/scrypath/multi_search/entries.ex](/Users/jon/projects/scrypath/lib/scrypath/multi_search/entries.ex:2)):
```elixir
@moduledoc """
Normalizes `search_many/2` entry tuples and shared runtime options.

Shared and per-entry keyword options merge with **per-key right bias**: when both
sides define the same top-level key, the entry value wins.
"""
```

**Reducer-based normalization pattern** ([lib/scrypath/multi_search/entries.ex](/Users/jon/projects/scrypath/lib/scrypath/multi_search/entries.ex:67)):
```elixir
defp normalize_entries(entries, shared) do
  Enum.reduce_while(entries, {:ok, []}, fn entry, {:ok, acc} ->
    case normalize_one(entry, shared) do
      {:ok, quad} -> {:cont, {:ok, acc ++ [quad]}}
      {:error, _} = err -> {:halt, err}
    end
  end)
end
```

**Top-level merge with entry bias pattern** ([lib/scrypath/multi_search/entries.ex](/Users/jon/projects/scrypath/lib/scrypath/multi_search/entries.ex:80)):
```elixir
with {:ok, fed_opts} <- federation_weight_opts(raw_weight),
     :ok <- reject_shared_only_in_entry(entry_core),
     merged <- Keyword.merge(shared, entry_core, fn _k, _s, e -> e end),
     merged <- merge_per_query_shallow(shared, entry_core, merged),
     :ok <- validate_page_size(merged) do
  {:ok, {schema, text, merged, fed_opts}}
end
```

**Field-specific shallow merge pattern for map-backed data** ([lib/scrypath/multi_search/entries.ex](/Users/jon/projects/scrypath/lib/scrypath/multi_search/entries.ex:130)):
```elixir
defp merge_per_query_shallow(shared, entry_core, merged) do
  case {Keyword.get(shared, :per_query), Keyword.get(entry_core, :per_query)} do
    {nil, nil} ->
      merged

    {s, nil} ->
      Keyword.put(merged, :per_query, per_query_as_map(s))

    {nil, e} ->
      Keyword.put(merged, :per_query, per_query_as_map(e))

    {s, e} ->
      Keyword.put(
        merged,
        :per_query,
        Map.merge(per_query_as_map(s), per_query_as_map(e))
      )
  end
end
```

**Stable explicit tuple errors pattern** ([lib/scrypath/multi_search/entries.ex](/Users/jon/projects/scrypath/lib/scrypath/multi_search/entries.ex:123)):
```elixir
defp reject_shared_only_in_entry(entry_opts) do
  case Enum.find(entry_opts, fn {k, _} -> MapSet.member?(@shared_only_federation_keys, k) end) do
    nil -> :ok
    {k, _} -> {:error, {:invalid_options, {:federation_key_in_entry, k}}}
  end
end
```

### `lib/scrypath/composition/normalize.ex` (utility, transform)

**Analog:** `lib/scrypath/query_params.ex`

**Keep normalization separate from execution** ([lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:11)):
```elixir
Use `normalize/1` at the request edge when handling Plug-decoded browser params.
It returns either `{:ok, query_params}` or `{:error, error_map}`.

This module is data-only: it does not validate schema-specific search semantics and it
does not execute searches.
```

**Deterministic field ordering pattern for canonical output** ([lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:39)):
```elixir
@search_option_keys [:filter, :sort, :page, :facets, :facet_filter, :per_query]
```

**Keyword and page-shape normalization pattern** ([lib/scrypath/query.ex](/Users/jon/projects/scrypath/lib/scrypath/query.ex:50)):
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

### `lib/scrypath/composition/result.ex` (model, transform)

**Analog:** `lib/scrypath/multi_search_result.ex`

**Struct + typed wrapper pattern** ([lib/scrypath/multi_search_result.ex](/Users/jon/projects/scrypath/lib/scrypath/multi_search_result.ex:7)):
```elixir
@enforce_keys [:ordered, :by_schema, :failures]
defstruct [:ordered, :by_schema, :failures, :federation, :merge_hit_order]

@type t :: %__MODULE__{
        ordered: [{module(), SearchResult.t()}],
        by_schema: %{optional(module()) => SearchResult.t()},
        failures: [failure()],
        federation: Federation.t() | nil,
        merge_hit_order: [{module(), term()}] | nil
      }
```

**Constructor accepting keyword or map attrs** ([lib/scrypath/multi_search_result.ex](/Users/jon/projects/scrypath/lib/scrypath/multi_search_result.ex:20)):
```elixir
@spec new(keyword() | map()) :: t()
def new(attrs) when is_list(attrs), do: new(Map.new(attrs))

def new(attrs) when is_map(attrs) do
  struct!(__MODULE__,
    ordered: Map.fetch!(attrs, :ordered),
    by_schema: Map.fetch!(attrs, :by_schema),
    failures: Map.fetch!(attrs, :failures),
    federation: federation,
    merge_hit_order: Map.get(attrs, :merge_hit_order)
  )
end
```

**Result-wrapper purpose to copy, but with plain-data composition metadata instead of runtime structs** ([lib/scrypath/multi_search_result.ex](/Users/jon/projects/scrypath/lib/scrypath/multi_search_result.ex:44)):
```elixir
@doc """
Projects federated **merge order** into `{schema, hit_map}` pairs.
...
Returns `[]` when `merge_hit_order` is `nil`.
"""
```

### `lib/mix/tasks/verify.phase83.ex` (utility, batch)

**Analog:** `lib/mix/tasks/verify.phase82.ex`

**Focused verify-task module pattern** ([lib/mix/tasks/verify.phase82.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase82.ex:1)):
```elixir
defmodule Mix.Tasks.Verify.Phase82 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs focused request-edge docs/examples verification (Phase 82)"
```

**Focused test list pattern** ([lib/mix/tasks/verify.phase43.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase43.ex:7)):
```elixir
@focused_tests [
  "test/scrypath/per_query_tuning_test.exs",
  "test/scrypath/search_test.exs",
  "test/scrypath/search_many_test.exs",
  "test/scrypath/docs_contract_test.exs"
]
```

**Run flow pattern with strict docs build when public language changes** ([lib/mix/tasks/verify.phase82.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase82.ex:15)):
```elixir
@impl true
def run(args) do
  Mix.Task.run("app.start")
  ensure_no_args!(args)

  run_test!(@focused_tests, "Phase 82 request-edge docs/examples verification")

  Mix.shell().info("==> Building docs with warnings as errors")
  Mix.Task.reenable("docs")
  Mix.Task.run("docs", ["--warnings-as-errors"])
end
```

**Argument rejection pattern** ([lib/mix/tasks/verify.phase82.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase82.ex:33)):
```elixir
defp ensure_no_args!([]), do: :ok

defp ensure_no_args!(args) do
  Mix.raise("verify.phase82 does not accept arguments, got: #{Enum.join(args, " ")}")
end
```

### `mix.exs` (config, batch)

**Analog:** `mix.exs`

**Preferred env wiring pattern** ([mix.exs](/Users/jon/projects/scrypath/mix.exs:37)):
```elixir
def cli do
  [
    preferred_envs: [
      "verify.phase43": :test,
      "verify.phase82": :test,
      ...
    ]
  ]
end
```

**Keep phase verify tasks grouped with existing aliases** ([mix.exs](/Users/jon/projects/scrypath/mix.exs:39)):
```elixir
"verify.phase41": :test,
"verify.phase43": :test,
"verify.phase82": :test,
"verify.adopter": :test,
```

### `test/scrypath/composition_test.exs` (test, transform)

**Analog:** `test/scrypath/query_params_test.exs`

**Lean ExUnit structure pattern** ([test/scrypath/query_params_test.exs](/Users/jon/projects/scrypath/test/scrypath/query_params_test.exs:1)):
```elixir
defmodule Scrypath.QueryParamsTest do
  use ExUnit.Case, async: true

  alias Scrypath.QueryParams
  alias Scrypath.QueryParams.Error
```

**Assert full plain-data shape, not internal runtime structs** ([test/scrypath/query_params_test.exs](/Users/jon/projects/scrypath/test/scrypath/query_params_test.exs:7)):
```elixir
assert %{
         text: "phoenix",
         filter: [status: "published"],
         sort: [desc: :inserted_at],
         page: [number: 2, size: 20],
         facets: [:genre, :year],
         facet_filter: [genre: ["Action", "Drama"]],
         per_query: %{show_ranking_score: true}
       } = query_params

refute match?(%Scrypath.Query{}, query_params)
```

**Parity assertion against canonical `{text, opts}` output** ([test/scrypath/query_params_test.exs](/Users/jon/projects/scrypath/test/scrypath/query_params_test.exs:41)):
```elixir
assert {"phoenix",
        [
          filter: [status: "published"],
          sort: [desc: :inserted_at],
          page: [number: 2, size: 20],
          facets: [:genre, :year],
          facet_filter: [genre: ["Action", "Drama"]],
          per_query: %{show_ranking_score: true}
        ]} = QueryParams.to_search_args(query_params)
```

**Narrow public-facade contract test pattern** ([test/scrypath/query_params_test.exs](/Users/jon/projects/scrypath/test/scrypath/query_params_test.exs:176)):
```elixir
assert function_exported?(QueryParams, :normalize, 1)
assert function_exported?(QueryParams, :cast, 1)
assert function_exported?(QueryParams, :to_search_args, 1)
refute function_exported?(QueryParams, :search, 0)
refute function_exported?(QueryParams, :search, 1)
```

### `test/scrypath/composition_property_test.exs` (test, transform)

**Analog:** `test/scrypath/multi_search/entries_test.exs`

**Minimal async ExUnit + local helper modules pattern** ([test/scrypath/multi_search/entries_test.exs](/Users/jon/projects/scrypath/test/scrypath/multi_search/entries_test.exs:1)):
```elixir
defmodule Scrypath.MultiSearch.EntriesTest do
  use ExUnit.Case, async: true

  alias Scrypath.MultiSearch.Entries

  defmodule Post do
  end
```

**Explicit tuple-error assertions pattern** ([test/scrypath/multi_search/entries_test.exs](/Users/jon/projects/scrypath/test/scrypath/multi_search/entries_test.exs:31)):
```elixir
assert {:error, {:invalid_options, {:page_size, 51, 50}}} =
         Entries.normalize([{Post, "q", page: [size: 51]}], [])
```

**Deterministic precedence assertion pattern** ([test/scrypath/multi_search/entries_test.exs](/Users/jon/projects/scrypath/test/scrypath/multi_search/entries_test.exs:46)):
```elixir
assert {:ok, quads} =
         Entries.normalize(
           [{Post, "q", page: [size: 5]}],
           page: [size: 10]
         )

assert [{schema, "q", merged, []}] = quads
assert Keyword.get(merged, :page) == [size: 5]
```

**Supplement for map shallow-merge expectations** ([test/scrypath/per_query_tuning_test.exs](/Users/jon/projects/scrypath/test/scrypath/per_query_tuning_test.exs:8)):
```elixir
test "per_query rejects unknown inner keys" do
  assert {:error, _} = Options.validate_search_options(SearchablePost, per_query: [bad: :key])
end
```

### `test/scrypath/docs_contract_test.exs` (test, request-response)

**Analog:** `test/scrypath/docs_contract_test.exs`

**File-loaded contract fixture pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:5)):
```elixir
@readme File.read!("README.md")
@architecture File.read!("ARCHITECTURE.md")
@contributing File.read!("CONTRIBUTING.md")
@ci_workflow File.read!(".github/workflows/ci.yml")
@verify_phase82 File.read!("lib/mix/tasks/verify.phase82.ex")
```

**Public-boundary wording assertions pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:128)):
```elixir
assert_contains_all(@request_edge_guide, [
  "Scrypath.QueryParams",
  "Scrypath.Phoenix",
  "QueryParams.to_search_args/1",
  "Scrypath.search/3",
  "%Scrypath.Query{}",
  "not public API"
])
```

**Root moduledoc contract pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:138)):
```elixir
assert_contains_all(File.read!("lib/scrypath.ex"), [
  "guides/request-edge-search.md",
  "Scrypath.Phoenix` is optional glue"
])
```

**Verify-task drift assertion pattern** ([test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:26)):
```elixir
@verify_phase82 File.read!("lib/mix/tasks/verify.phase82.ex")
```

### `lib/scrypath.ex` (utility, request-response)

**Analog:** `lib/scrypath.ex`

**Public entry-point list pattern** ([lib/scrypath.ex](/Users/jon/projects/scrypath/lib/scrypath.ex:15)):
```elixir
## Entry points

- **`Scrypath.QueryParams`** — framework-light request-edge normalization before your
  context calls `search/3`
- **`search/3`** — hydrated search on one schema
- **`search_many/2`** — federated multi-schema search
```

**Keep new public seam on the same boundary line** ([lib/scrypath.ex](/Users/jon/projects/scrypath/lib/scrypath.ex:27)):
```elixir
If you are in Phoenix, `Scrypath.Phoenix` is optional glue for
params, forms, and URL round-tripping only. Keep orchestration in your contexts, where
`Scrypath.search/3` remains the canonical runtime entrypoint.
```

## Shared Patterns

### Public Plain-Data Seams
**Source:** [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:22)
**Apply to:** `lib/scrypath/composition.ex`, `lib/scrypath/composition/normalize.ex`, `lib/scrypath/composition/result.ex`
```elixir
@type t :: %{
        text: String.t(),
        filter: keyword(),
        sort: keyword(),
        page: keyword(),
        facets: [atom()],
        facet_filter: keyword(),
        per_query: map()
      }
```

### Validation And Invalid-Options Translation
**Source:** [lib/scrypath/options.ex](/Users/jon/projects/scrypath/lib/scrypath/options.ex:453)
**Apply to:** `lib/scrypath/composition.ex`, `lib/scrypath/composition/merge.ex`
```elixir
with {:ok, validated} <- nimble_options_result(@search_options, search_opts),
     :ok <- validate_search_facets(schema_module, Keyword.get(validated, :facets, [])),
     :ok <- validate_search_facet_filter(schema_module, Keyword.get(validated, :facet_filter, [])) do
  try do
    validated
    |> validate_filterable_fields!(filterable)
    |> validate_sortable_fields!(sortable)
    |> then(&{:ok, &1})
  rescue
    e in ArgumentError -> {:error, {:validation, Exception.message(e)}}
  end
end
```

### Keyword-List Guardrails
**Source:** [lib/scrypath/options.ex](/Users/jon/projects/scrypath/lib/scrypath/options.ex:821)
**Apply to:** `lib/scrypath/composition/merge.ex`, `lib/scrypath/composition/normalize.ex`
```elixir
def validate_search_filter(value) when is_list(value) do
  if Keyword.keyword?(value) do
    {:ok, value}
  else
    {:error, "expected filter to be a keyword list"}
  end
end
```

### Explicit Error-Vs-Raise Boundary
**Source:** [lib/scrypath/search.ex](/Users/jon/projects/scrypath/lib/scrypath/search.ex:27)
**Apply to:** `lib/scrypath/composition.ex`, docs wording in `lib/scrypath.ex`
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

### Verify-Task Wiring
**Source:** [lib/mix/tasks/verify.phase82.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase82.ex:15), [mix.exs](/Users/jon/projects/scrypath/mix.exs:37)
**Apply to:** `lib/mix/tasks/verify.phase83.ex`, `mix.exs`
```elixir
def run(args) do
  Mix.Task.run("app.start")
  ensure_no_args!(args)
  run_test!(@focused_tests, "Phase 82 request-edge docs/examples verification")
  Mix.Task.reenable("docs")
  Mix.Task.run("docs", ["--warnings-as-errors"])
end
```

### Docs Contract Drift Protection
**Source:** [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:128)
**Apply to:** `test/scrypath/docs_contract_test.exs`, `lib/scrypath.ex`
```elixir
assert_contains_all(@request_edge_guide, [
  "Scrypath.QueryParams",
  "Scrypath.Phoenix",
  "QueryParams.to_search_args/1",
  "Scrypath.search/3",
  "%Scrypath.Query{}",
  "not public API"
])
```

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/scrypath/composition_property_test.exs` | test | transform | No existing `StreamData` / `ExUnitProperties` property-test file is present in the repo yet; use `test/scrypath/multi_search/entries_test.exs` only for assertion style and introduce property-test structure from research. |

## Metadata

**Analog search scope:** `lib/scrypath/`, `lib/mix/tasks/`, `test/scrypath/`, `mix.exs`, phase 83 inputs  
**Files scanned:** 18  
**Pattern extraction date:** 2026-05-23
