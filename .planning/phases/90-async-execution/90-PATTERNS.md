# Phase 90: Async Execution and Error Propagation - Pattern Map

**Mapped:** 2024-05-25
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scrypath/sync/related_worker.ex` | worker | event-driven | `lib/scrypath/oban/upsert_worker.ex` | exact |
| `lib/scrypath/sync.ex` | service | request-response | *Self* | exact |

## Pattern Assignments

### `lib/scrypath/sync/related_worker.ex` (worker, event-driven)

**Analog:** `lib/scrypath/oban/upsert_worker.ex`

**Worker Error Handling Pattern** (lines 13-26):
```elixir
    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      with {:ok, schema_module} <- resolve_schema(args),
           # ... configuration parsing ...
           {:ok, config} <- build_config(backend, index_name, args) do
        case backend.upsert_documents(schema_module, documents, config) do
          {:ok, _} = ok -> IndexingAck.await(backend, ok, config)
          {:error, reason} -> {:error, reason}
        end
      else
        {:error, reason} -> {:cancel, {:invalid_job, reason}}
      end
    end
```
*Application for Phase 90:* 
Currently, `RelatedWorker.perform/1` ends with `:ok` unconditionally, swallowing any errors from `Scrypath.Sync.sync_records`. You must replace the unconditional `:ok` with a return that bubbles up the result of `sync_records`. 
- Return `{:error, reason}` for transient errors to trigger Oban retries.
- Catch argument errors or resolution failures before dispatching and return `{:cancel, {:invalid_request, reason}}` to immediately discard the job.

---

### `lib/scrypath/sync.ex` (service, request-response)

**Analog:** `lib/scrypath/sync.ex` (Lines 47-52)

**Job Enqueue Handoff Pattern**:
```elixir
      :oban ->
        config
        |> Config.ensure_oban_ready!()
        |> then(&Scrypath.Sync.RelatedWorker.enqueue(schema_module, records, fan_out_key, &1))
        |> decorate_result(config)
```
*Application for Phase 90:*
The `RelatedWorker.enqueue/4` function correctly surfaces `{:error, reason}` if the database insert fails. When called via `sync_related/3`, this error bubbles up through `decorate_result`. The logic here remains sound but relies on `RelatedWorker` appropriately formatting its result map/error tuple.

## Shared Patterns

### Unrecoverable Errors
**Source:** `lib/scrypath/oban/upsert_worker.ex`
**Apply to:** `lib/scrypath/sync/related_worker.ex`
When a configuration parse fails or schema resolution fails, wrap in a `with` statement and capture in the `else` block to return `{:cancel, reason}`. This instructs Oban not to retry.

## Metadata

**Analog search scope:** `lib/scrypath/**/*.ex`
**Files scanned:** 3
**Pattern extraction date:** 2024-05-25