# Phase 38 — Pattern map

Analogs and excerpts for executors (read these files before editing).

| Planned surface | Closest existing analog | Why |
|-----------------|-------------------------|-----|
| Thin public delegate on `Scrypath` | `Scrypath.search/3`, `Scrypath.search!/3` in `lib/scrypath.ex` | Same `@spec` / delegate style to `Scrypath.Search`. |
| Single search pipeline | `Scrypath.Search.search/3` in `lib/scrypath/search.ex` | `Query.new` + `Telemetry.span([:scrypath, :search], ...)`. |
| `facetFilters` encoding | `Scrypath.Meilisearch.Query.to_payload/1` | Bucket must appear as normalized `facet_filter` keyword data. |
| Req.Test search integration | `test/scrypath/meilisearch_test.exs` test **"common search translates normalized query fields into Meilisearch payloads"** | Copy `Req.Test.stub` + `assert_received {:search_request, ...}` pattern. |
| Phase verify Mix task | `lib/mix/tasks/verify.phase37.ex` | Same `run_test!/2` + `ensure_no_args!/1` structure. |
| Guide + contract anchors | Phase 37 edits to `guides/faceted-search-with-phoenix-liveview.md` + `docs_contract_test.exs` | New `##` sections + substring assertions; no REQ IDs in prose. |

## Code excerpt — delegate pattern (`lib/scrypath.ex`)

```elixir
@spec search(module(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}
def search(schema_module, text, opts \\ []) do
  Scrypath.Search.search(schema_module, text, opts)
end
```

## Code excerpt — search pipeline entry (`lib/scrypath/search.ex`)

```elixir
def search(schema_module, text, opts \\ []) when is_binary(text) and is_list(opts) do
  case Scrypath.Options.validate_search_options(schema_module, opts) do
    {:error, {:validation, message}} when is_binary(message) ->
      raise ArgumentError, message
    ...
```

## PATTERN MAPPING COMPLETE
