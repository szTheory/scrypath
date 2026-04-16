# Phase 3: Search Query API and Hydration - Pattern Map

**Mapped:** 2026-04-15
**Files analyzed:** 13
**Analogs found:** 12 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scrypath.ex` | utility | request-response | `lib/scrypath.ex` | exact |
| `lib/scrypath/backend.ex` | service | request-response | `lib/scrypath/backend.ex` | exact |
| `lib/scrypath/options.ex` | config | transform | `lib/scrypath/options.ex` | exact |
| `lib/scrypath/config.ex` | config | transform | `lib/scrypath/config.ex` | exact |
| `lib/scrypath/query.ex` | model | transform | `lib/scrypath/document.ex` | role-match |
| `lib/scrypath/search_result.ex` | model | transform | `lib/scrypath/document.ex` | role-match |
| `lib/scrypath/search.ex` | service | request-response | `lib/scrypath/sync.ex` | role-match |
| `lib/scrypath/hydration.ex` | service | CRUD | `lib/scrypath/identity.ex` | flow-match |
| `lib/scrypath/meilisearch.ex` | service | request-response | `lib/scrypath/meilisearch.ex` | exact |
| `lib/scrypath/meilisearch/client.ex` | service | request-response | `lib/scrypath/meilisearch/client.ex` | exact |
| `test/support/fake_backend.ex` | test | request-response | `test/support/fake_backend.ex` | exact |
| `test/scrypath/search_test.exs` | test | request-response | `test/scrypath/sync_test.exs` | role-match |
| `test/scrypath/meilisearch_test.exs` | test | request-response | `test/scrypath/meilisearch_test.exs` | exact |

## Pattern Assignments

### `lib/scrypath.ex` (utility, request-response)

**Analog:** `lib/scrypath.ex`

**Public facade style** (`lib/scrypath.ex:28-70`):
```elixir
@spec schema_config(module()) :: map()
def schema_config(schema_module) do
  schema_module.__scrypath__(:config)
end

@spec sync_record(module(), struct() | map(), keyword()) :: {:ok, term()} | {:error, term()}
def sync_record(schema_module, record, opts \\ []) do
  Scrypath.Sync.sync_record(schema_module, record, opts)
end
```

**Copy forward:** add `search/3` and `search!/3` here as thin delegates. Keep the top-level API as explicit verbs under `Scrypath.*`; do not add schema-generated runtime search methods.

---

### `lib/scrypath/backend.ex` (service, request-response)

**Analog:** `lib/scrypath/backend.ex`

**Behaviour evolution point** (`lib/scrypath/backend.ex:6-12`):
```elixir
@callback name() :: atom()
@callback index_name(module(), keyword()) :: String.t()
@callback upsert_documents(module(), [Document.t()], keyword()) ::
            {:ok, term()} | {:error, term()}
@callback delete_documents(module(), [term()], keyword()) ::
            {:ok, term()} | {:error, term()}
@callback search(module(), term(), keyword()) :: {:ok, term()} | {:error, term()}
```

**Copy forward:** evolve only the `search/3` callback contract, not the whole behaviour. Phase 3 should tighten `term()` toward a normalized query struct and keep the return as `{:ok, term()} | {:error, term()}` so backend and facade stay aligned with existing tuple style.

---

### `lib/scrypath/options.ex` (config, transform)

**Analog:** `lib/scrypath/options.ex`

**Option schema pattern** (`lib/scrypath/options.ex:37-82`):
```elixir
@runtime_options [
  backend: [
    type: {:custom, __MODULE__, :validate_backend, []},
    required: true,
    doc: "Backend module responsible for search operations."
  ],
  repo: [
    type: {:custom, __MODULE__, :validate_optional_module, []},
    default: nil,
    doc: "Optional Ecto repo used by runtime operations."
  ],
  index_prefix: [
    type: {:custom, __MODULE__, :validate_optional_string, []},
    default: nil,
    doc: "Optional runtime index prefix override."
  ]
]
```

**Validation helpers** (`lib/scrypath/options.ex:98-115`):
```elixir
def validate_optional_string(value) when is_binary(value), do: {:ok, value}
def validate_optional_string(nil), do: {:ok, nil}
def validate_optional_string(_value), do: {:error, "expected a string or nil"}

def validate_keyword_list(value) when is_list(value) do
  if Keyword.keyword?(value), do: {:ok, value}, else: {:error, "expected a keyword list"}
end
```

**Raise-on-invalid convention** (`lib/scrypath/options.ex:117-124`):
```elixir
defp validate!(opts, schema) do
  case NimbleOptions.validate(opts, schema) do
    {:ok, validated} ->
      validated

    {:error, error} ->
      raise ArgumentError, Exception.message(error)
  end
end
```

**Copy forward:** validate `filter:`, `sort:`, `page:`, `preload:`, and `repo:` through `NimbleOptions` and small custom validators. Normalize from keyword input into an internal struct after validation. Preserve the current `ArgumentError` behaviour for invalid public options.

---

### `lib/scrypath/config.ex` (config, transform)

**Analog:** `lib/scrypath/config.ex`

**Runtime config resolution** (`lib/scrypath/config.ex:6-10`):
```elixir
@spec resolve!(keyword()) :: keyword()
def resolve!(opts) when is_list(opts) do
  Application.get_env(:scrypath, :defaults, [])
  |> Keyword.merge(opts)
  |> Options.validate_runtime_options!()
end
```

**Canonical fetch helpers** (`lib/scrypath/config.ex:13-35`):
```elixir
@spec fetch_backend!(keyword()) :: module()
def fetch_backend!(config) do
  Keyword.fetch!(config, :backend)
end

@spec fetch_meilisearch_url!(keyword()) :: String.t()
def fetch_meilisearch_url!(config) do
  Keyword.fetch!(config, :meilisearch_url)
end
```

**Copy forward:** if Phase 3 adds repo-specific helpers, put them here. Keep explicit runtime opts canonical and do not infer repo globally for hydration.

---

### `lib/scrypath/query.ex` (model, transform)

**Analog:** `lib/scrypath/document.ex`

**Struct pattern** (`lib/scrypath/document.ex:4-11`):
```elixir
@enforce_keys [:id, :data, :source]
defstruct [:id, :data, :source]

@type t :: %__MODULE__{
        id: term(),
        data: map(),
        source: :fields | :custom
      }
```

**Copy forward:** `Scrypath.Query` should be a small enforced struct with typed fields for the normalized public query shape. Stay explicit and flat, similar to `Scrypath.Document`, instead of hiding state in a builder.

---

### `lib/scrypath/search_result.ex` (model, transform)

**Analog:** `lib/scrypath/document.ex`

**Stable internal data shape pattern** (`lib/scrypath/document.ex:4-11`):
```elixir
@enforce_keys [:id, :data, :source]
defstruct [:id, :data, :source]
```

**Result decoration pattern** (`lib/scrypath/sync.ex:75-80`):
```elixir
defp decorate_result({:ok, result}, config) when is_map(result) do
  {:ok,
   result
   |> Map.put(:mode, Keyword.fetch!(config, :sync_mode))
   |> Map.put(:status, result_status(config))}
end
```

**Copy forward:** use one stable result envelope struct for common search results and decorate it in one place. Include hydrated records, raw hits, pagination metadata, and `missing_ids` on the same struct instead of switching shapes by option.

---

### `lib/scrypath/search.ex` (service, request-response)

**Analog:** `lib/scrypath/sync.ex`

**Thin orchestration style** (`lib/scrypath/sync.ex:14-20`):
```elixir
@spec sync_records(module(), [struct() | map()], keyword()) :: {:ok, term()} | {:error, term()}
def sync_records(schema_module, records, opts \\ []) when is_list(records) do
  config = Config.resolve!(opts)
  documents = Enum.map(records, &Projection.document(schema_module, &1))

  dispatch_upsert(schema_module, documents, config)
end
```

**Private dispatch split** (`lib/scrypath/sync.ex:41-55`):
```elixir
defp dispatch_upsert(schema_module, documents, config) do
  backend = Config.fetch_backend!(config)

  backend.upsert_documents(schema_module, documents, config)
  |> maybe_wait_for_task(config)
  |> decorate_result(config)
end
```

**Copy forward:** organize search similarly: resolve config, normalize query, dispatch to backend, optionally hydrate, then decorate a stable result. Keep backend calls and hydration as private helpers, not inline in the facade.

---

### `lib/scrypath/hydration.ex` (service, CRUD)

**Analog:** `lib/scrypath/identity.ex`

**Metadata-driven field resolution** (`lib/scrypath/identity.ex:23-36`):
```elixir
defp default_document_id(schema_module, source_record) when is_map(source_record) do
  document_id_field = schema_module.__scrypath__(:document_id)

  cond do
    Map.has_key?(source_record, document_id_field) ->
      Map.fetch!(source_record, document_id_field)
```

**Explicit local failure style** (`lib/scrypath/identity.ex:33-35`):
```elixir
true ->
  raise ArgumentError,
        "missing document id #{inspect(document_id_field)} in source record"
```

**Projection's explicit preload stance** (`lib/scrypath/projection.ex:9-11`):
```elixir
Association-derived data requires explicit preload work before projection. Scrypath
does not reach through unloaded associations or infer extra queries on behalf of the
caller.
```

**Copy forward:** hydration should resolve source ids from an explicit field, batch-load via the provided repo, then restore hit order in Elixir. Keep preload explicit on the hydration query and surface missing records instead of dropping them.

---

### `lib/scrypath/meilisearch.ex` (service, request-response)

**Analog:** `lib/scrypath/meilisearch.ex`

**Explicit backend namespace boundary** (`lib/scrypath/meilisearch.ex:2-12`):
```elixir
@moduledoc """
Meilisearch-specific runtime entrypoints for Scrypath.

`Scrypath.*` remains the common path for syncing records and deleting documents.
This namespace is the explicit escape hatch for Meilisearch-native behavior that
should stay visible instead of being tunneled through generic options.
"""
```

**Minimal backend wrapper pattern** (`lib/scrypath/meilisearch.ex:63-67`):
```elixir
@impl true
def search(schema_module, query, config) do
  index = index_name(schema_module, config)
  client(config).search(index, query, config)
end
```

**Copy forward:** keep common-path translation small. If Phase 3 needs richer Meilisearch-native search power, add it under `Scrypath.Meilisearch.*` rather than tunneling opaque options through `Scrypath.search/3`.

---

### `lib/scrypath/meilisearch/client.ex` (service, request-response)

**Analog:** `lib/scrypath/meilisearch/client.ex`

**Transport and response normalization** (`lib/scrypath/meilisearch/client.ex:28-33`, `:45-56`):
```elixir
@spec search(String.t(), term(), keyword()) :: {:ok, map()} | {:error, term()}
def search(index_name, query, config) do
  request(config)
  |> Req.post(url: "/indexes/#{index_name}/search", json: search_payload(query))
  |> normalize_response()
end
```

```elixir
defp normalize_response({:ok, %Req.Response{status: status, body: body}})
     when status >= 200 and status < 300 and is_map(body) do
  {:ok, body}
end

defp normalize_response({:error, exception}) do
  {:error, {:transport_error, exception}}
end
```

**Current translation seam** (`lib/scrypath/meilisearch/client.ex:62-63`):
```elixir
defp search_payload(query) when is_binary(query), do: %{q: query}
defp search_payload(query) when is_map(query), do: query
```

**Copy forward:** this is the right place to translate `%Scrypath.Query{}` into Meilisearch payloads. Preserve the current request construction and normalized tuple returns.

---

### `test/support/fake_backend.ex` (test, request-response)

**Analog:** `test/support/fake_backend.ex`

**Behaviour test double pattern** (`test/support/fake_backend.ex:1-30`):
```elixir
defmodule Scrypath.TestSupport.FakeBackend do
  @behaviour Scrypath.Backend

  @impl true
  def search(_schema_module, query, _config) do
    {:ok, %{query: query, hits: []}}
  end
end
```

**Copy forward:** evolve the fake backend alongside the behaviour so backend tests keep asserting the normalized query contract without depending on Meilisearch specifics.

---

### `test/scrypath/search_test.exs` (test, request-response)

**Analog:** `test/scrypath/sync_test.exs`

**Top-level public API test naming** (`test/scrypath/sync_test.exs:91-104`):
```elixir
test "Scrypath.sync_record/3 projects one record and delegates through shared sync orchestration" do
  ...
  assert config[:backend] == RecordingBackend
  assert config[:sync_mode] == :inline
end
```

**Stable tuple and shape assertions** (`test/scrypath/sync_test.exs:113-125`):
```elixir
assert {:ok,
        %{document_ids: [1, 2], sync_mode: :manual, mode: :manual, status: :accepted}} =
         Scrypath.sync_records(SearchablePost, records,
           backend: RecordingBackend,
           sync_mode: :manual
         )
```

**Copy forward:** name tests around public functions and behavioural guarantees. Assert exact result fields and ordering, including hydrated records, hits, pagination, and `missing_ids`.

---

### `test/scrypath/meilisearch_test.exs` (test, request-response)

**Analog:** `test/scrypath/meilisearch_test.exs`

**Recording client pattern** (`test/scrypath/meilisearch_test.exs:6-39`):
```elixir
defmodule RecordingClient do
  def search(index_name, query, config) do
    send(self(), {:client_search, index_name, query, config})
    {:ok, %{"hits" => [%{"id" => 99}], "query" => query}}
  end
end
```

**Transport assertion pattern** (`test/scrypath/meilisearch_test.exs:133-136`):
```elixir
assert {:ok, %{"hits" => [], "query" => "hello"}} =
         Scrypath.Meilisearch.Client.search("tenant_searchable_post", "hello", config)

assert_received {:request, "POST", "/indexes/tenant_searchable_post/search", _, %{"q" => "hello"}}
```

**Copy forward:** keep Meilisearch tests split between backend wrapper behaviour and raw client payload translation. Assert the exact JSON payload generated from the normalized query struct.

## Shared Patterns

### Public API Style
**Sources:** `lib/scrypath.ex:28-70`, `README.md:53-62`, `test/scrypath/schema_test.exs:24-25`
```elixir
@spec sync_record(module(), struct() | map(), keyword()) :: {:ok, term()} | {:error, term()}
def sync_record(schema_module, record, opts \\ []) do
  Scrypath.Sync.sync_record(schema_module, record, opts)
end
```

```elixir
These helpers are intended to keep runtime code centralized under `Scrypath.*`
modules instead of generating APIs such as `Post.search/2`.
```

**Apply to:** `Scrypath.search/3`, `Scrypath.search!/3`, and any new common-path modules. Keep runtime verbs under `Scrypath.*` only.

### Option Validation And Normalization
**Sources:** `lib/scrypath/options.ex:37-124`, `test/scrypath/options_test.exs:21-80`
```elixir
config =
  Scrypath.Options.validate_runtime_options!(
    backend: FakeBackend,
    meilisearch_url: "http://localhost:7700",
    meilisearch_api_key: "secret"
  )
```

```elixir
assert_raise ArgumentError, ~r/meilisearch_url/, fn ->
  Scrypath.Options.validate_runtime_options!(
    backend: FakeBackend,
    meilisearch_url: 123
  )
end
```

**Apply to:** public query options and any query normalization helpers. Validate early, normalize once.

### Result Tuple And Stable Envelope
**Sources:** `lib/scrypath/sync.ex:75-89`, `test/scrypath/sync_test.exs:113-125`, `test/scrypath/meilisearch/tasks_test.exs:62-71`
```elixir
{:ok,
 result
 |> Map.put(:mode, Keyword.fetch!(config, :sync_mode))
 |> Map.put(:status, result_status(config))}
```

```elixir
assert {:error, {:task_failed, %{uid: 102, status: :failed, raw: raw}}} =
         Tasks.wait_for_task(...)
```

**Apply to:** `search/3` should return `{:ok, %Scrypath.SearchResult{}} | {:error, reason}`; `search!/3` can raise, but the non-bang path should preserve the stable tuple convention.

### Explicit Data Loading
**Sources:** `lib/scrypath/projection.ex:9-11`, `README.md:51`, `.planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md`
```elixir
Association-derived data requires explicit preload work before projection. Scrypath
does not reach through unloaded associations or infer extra queries on behalf of the
caller.
```

**Apply to:** hydration. Require explicit `repo:` and make `preload:` explicit on hydration queries only.

### Backend-Native Escape Hatch
**Sources:** `lib/scrypath/meilisearch.ex:2-12`, `ARCHITECTURE.md:14-16`
```elixir
`Scrypath.Meilisearch.*` is the explicit escape hatch for Meilisearch-specific behavior
such as task-native results and later index-level operations.
```

**Apply to:** native Meilisearch search entrypoints or richer search features. Do not pass them through opaque common-path options.

### Test Organization
**Sources:** `test/scrypath/schema_test.exs`, `test/scrypath/sync_test.exs`, `test/scrypath/meilisearch_test.exs`
```elixir
defmodule Scrypath.SyncTest do
  use ExUnit.Case, async: true
```

**Apply to:** keep tests in `test/scrypath/*_test.exs`, use `async: true` unless global app env mutation requires `async: false`, and name tests around public behaviour rather than internals.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/scrypath/hydration.ex` | service | CRUD | No existing repo-backed batch reload module exists yet; use `Scrypath.Identity` for metadata lookup style and `Scrypath.Projection` for explicit loading boundaries |

## Metadata

**Analog search scope:** `lib/`, `test/`, `README.md`, `ARCHITECTURE.md`, `.planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md`
**Files scanned:** 23
**Pattern extraction date:** 2026-04-15
