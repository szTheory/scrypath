# Phase 89: Related-Data Fan-Out API - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scrypath.ex` | public api entrypoint | delegation | `lib/scrypath.ex` | exact |
| `lib/scrypath/sync.ex` | service / delegator | side-effects / operations | `lib/scrypath/sync.ex` | exact |
| `lib/scrypath/sync/related.ex` (or similar) | metadata / struct | plain data reflection | `lib/scrypath/operations/result.ex` | role-match |

## Pattern Assignments

### `lib/scrypath.ex` (public api entrypoint, delegation)

**Analog:** `lib/scrypath.ex`

**Public delegation pattern** (lines 175-184):
```elixir
  @doc @sync_public_ops_doc
  @spec sync_record(module(), struct() | map(), keyword()) :: {:ok, term()} | {:error, term()}
  def sync_record(schema_module, record, opts \\ []) do
    Scrypath.Sync.sync_record(schema_module, record, opts)
  end

  @doc @sync_public_ops_doc
  @spec sync_records(module(), [struct() | map()], keyword()) :: {:ok, term()} | {:error, term()}
  def sync_records(schema_module, records, opts \\ []) do
    Scrypath.Sync.sync_records(schema_module, records, opts)
  end
```

### `lib/scrypath/sync.ex` (service / delegator, side-effects / operations)

**Analog:** `lib/scrypath/sync.ex`

**Internal dispatch and telemetry pattern** (lines 19-35):
```elixir
  @spec sync_records(module(), [struct() | map()], keyword()) :: {:ok, term()} | {:error, term()}
  def sync_records(schema_module, records, opts \\ []) when is_list(records) do
    config = Config.resolve!(opts)
    documents = Enum.map(records, &Projection.document(schema_module, &1))

    metadata =
      Telemetry.common_metadata(schema_module, config, document_count: length(documents))

    Telemetry.span([:scrypath, :sync, :upsert], metadata, fn ->
      result =
        case documents do
          [] -> noop_result(config)
          _documents -> dispatch_upsert(schema_module, documents, config)
        end

      {result, Telemetry.stop_metadata(result)}
    end)
  end
```

### Fan-Out Structs (metadata / struct, plain data reflection)

**Analog:** `lib/scrypath/operations/result.ex`

**Plain data struct pattern** (lines 1-22):
```elixir
defmodule Scrypath.Operations.Result do
  @moduledoc false

  alias Scrypath.Operations.Task

  @enforce_keys [:mode, :status]
  defstruct [:mode, :status, document_ids: [], document_count: 0, task: nil, metadata: %{}]

  @type t :: %__MODULE__{
          mode: :inline | :manual | :oban | atom(),
          status: :accepted | :completed | :noop | atom(),
          document_ids: [term()],
          document_count: non_neg_integer(),
          task: Task.t() | nil,
          metadata: map()
        }

  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(__MODULE__, attrs)
  end
```

## Shared Patterns

### Configuration Resolution
**Source:** `lib/scrypath/sync.ex`
**Apply to:** Internal sync functions
```elixir
config = Config.resolve!(opts)
```

### Telemetry Spans
**Source:** `lib/scrypath/sync.ex`
**Apply to:** Operations that perform network requests or significant processing
```elixir
    metadata =
      Telemetry.common_metadata(schema_module, config, document_count: length(documents))

    Telemetry.span([:scrypath, :sync, :upsert], metadata, fn ->
        # ... work ...
      {result, Telemetry.stop_metadata(result)}
    end)
```

## No Analog Found

None. The existing sync API entrypoints, internal dispatching via telemetry, and explicit metadata struct boundaries provide a direct map to establishing `sync_related/3`.

## Metadata

**Analog search scope:** `lib/scrypath.ex`, `lib/scrypath/sync.ex`, `lib/scrypath/operations/*`
**Files scanned:** 3
**Pattern extraction date:** 2024-05-24
