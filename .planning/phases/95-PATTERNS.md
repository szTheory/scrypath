# Phase 95: API Contract and Execution - Pattern Map

**Mapped:** 2024
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scrypath.ex` | facade | request-response | `lib/scrypath.ex` | exact |
| `lib/scrypath/search.ex` | service | request-response | `lib/scrypath/search.ex` | exact |
| `lib/scrypath/backend.ex` | interface | contract | `lib/scrypath/backend.ex` | exact |
| `lib/scrypath/meilisearch.ex` | provider | request-response | `lib/scrypath/meilisearch.ex` | exact |
| `lib/scrypath/meilisearch/client.ex` | provider client | request-response | `lib/scrypath/meilisearch/client.ex` | exact |
| `lib/scrypath/facet_search_result.ex` | struct | transform | `lib/scrypath/search_result.ex` | role-match |
| `test/support/fake_backend.ex` | test double | mock | `test/support/fake_backend.ex` | exact |
| `scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex` | interface | mock | `scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex` | exact |

## Pattern Assignments

### `lib/scrypath.ex` (facade, request-response)

**Analog:** `lib/scrypath.ex`

**Core Pattern (Delegation and Errors vs Raises docs)**:
```elixir
  @doc """
  ...
  ## Errors vs raises

  * **`ArgumentError`** — some invalid shapes are rejected synchronously before
    backend dispatch.
  * **`{:error, reason}`** — operational failures, including backend errors and
    tuples such as `{:transport_failed, _}`, for callers that want to branch.

  `search!/3` raises `Scrypath.Search.Error` with the same `reason` instead of returning
  `{:error, _}`.
  """
  @spec search(module(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def search(schema_module, text, opts \\ []) do
    Scrypath.Search.search(schema_module, text, opts)
  end

  @doc """
  Like `search/3`, but returns the same hydrated search result payload or raises
  `Scrypath.Search.Error` when the non-bang API would return `{:error, _}`.
  """
  @spec search!(module(), String.t(), keyword()) :: term()
  def search!(schema_module, text, opts \\ []) do
    Scrypath.Search.search!(schema_module, text, opts)
  end
```

### `lib/scrypath/search.ex` (service, request-response)

**Analog:** `lib/scrypath/search.ex`

**Core Pattern (Validation and Error Handling)**:
```elixir
  @spec search(module(), String.t(), keyword()) :: {:ok, SearchResult.t()} | {:error, term()}
  def search(schema_module, text, opts \\ []) when is_binary(text) and is_list(opts) do
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
  end
```

### `lib/scrypath/backend.ex` (interface, contract)

**Analog:** `lib/scrypath/backend.ex`

**Core Pattern (Callback definition)**:
```elixir
  @callback search(module(), Query.t(), keyword()) :: {:ok, map()} | {:error, term()}
```

### `lib/scrypath/meilisearch.ex` (provider, request-response)

**Analog:** `lib/scrypath/meilisearch.ex`

**Core Pattern (Alias resolution and client delegation)**:
```elixir
  @spec search(module(), Query.t() | map() | String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def search(schema_module, query, config) do
    index =
      Keyword.get(config, :index_name) ||
        Keyword.get(config, :target_index) ||
        index_name(schema_module, config)

    client(config).search(index, query, config)
  end
```

### `lib/scrypath/meilisearch/client.ex` (provider client, request-response)

**Analog:** `lib/scrypath/meilisearch/client.ex`

**Core Pattern (HTTP Payload and Telemetry)**:
```elixir
  @spec search(String.t(), CommonQuery.t() | map() | String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def search(index_name, query, config) do
    run_request(
      :post,
      "/indexes/#{index_name}/search",
      [json: search_payload(query)],
      config,
      index: index_name
    )
  end
```

### `lib/scrypath/facet_search_result.ex` (struct, transform)

**Analog:** `lib/scrypath/search_result.ex`

**Core Pattern (Struct enforcement and parsing)**:
```elixir
  alias Scrypath.SearchResult.Facets.Bucket

  @enforce_keys [:query, :hits, :records, :raw, :missing_ids, :page]
  defstruct [:query, :hits, :records, :raw, :missing_ids, :page, :facets]

  @type t :: %__MODULE__{ ... }

  @spec new(Query.t(), map(), [struct()], [term()]) :: t()
  def new(%Query{} = query, raw, records, missing_ids) when is_map(raw) do
    %__MODULE__{
      ...
```

### `test/support/fake_backend.ex` (test double, mock)

**Analog:** `test/support/fake_backend.ex`

**Core Pattern (Mocked implementation)**:
```elixir
  @impl true
  def search_many(paired_queries, config) when is_list(paired_queries) do
    # ... mock implementation
  end
```

### `scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex` (interface, mock)

**Analog:** `scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex`

**Core Pattern (Delegated default)**:
```elixir
  @callback search(module(), String.t(), keyword()) :: search_result()
...
  @impl true
  def search(schema, text, opts), do: Scrypath.search(schema, text, opts)
```

## Shared Patterns

### Error Wrapping
**Source:** `lib/scrypath.ex`
**Apply to:** Facade bang methods (`search_facet_values!/4`)
**Pattern:**
```elixir
  def search!(schema_module, text, opts \\ []) do
    Scrypath.Search.search!(schema_module, text, opts)
  end
```

### Options Validation
**Source:** `lib/scrypath/search.ex`
**Apply to:** `Scrypath.Search.search_facet_values/4`
**Pattern:**
```elixir
    case Scrypath.Options.validate_search_options(schema_module, opts) do
      {:error, {:validation, message}} when is_binary(message) ->
        raise ArgumentError, message
...
```

## Metadata

**Analog search scope:** `lib/scrypath/**/*.ex`, `test/support/*.ex`, `scrypath_ops/lib/**/*.ex`
**Files scanned:** 104
**Pattern extraction date:** 2024-05
