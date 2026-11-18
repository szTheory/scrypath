# Phase 179: Bounded id lists and related-sync parity - Pattern Map

**Mapped:** 2026-10-25
**Files analyzed:** 27 (4 new lib/test-support, 11 modified lib, 9 test files, 3 docs)
**Analogs found:** 27 / 27 (every new file has an in-repo analog; most changes are edits to the analog itself)

All paths below were checked with `git ls-files` and are tracked source. No mirror paths.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scrypath/chunks.ex` (NEW, name discretionary) | utility (pure) | transform / batch | `lib/scrypath/reindex.ex:198-214` (`reduce_while` halt) + `lib/scrypath/oban/upsert_worker.ex:96-110` (`normalize_documents` reduce_while) | role-match |
| `lib/scrypath/oban/job_args.ex` (NEW) | utility (pure decoder) | transform (job args -> config) | `lib/scrypath/oban/job_config.ex` (pure string-key allowlist) + `upsert_worker.ex:56-81,132-147` (safe module resolution) | exact |
| `lib/scrypath/oban/enqueue.ex` | service | request-response (DB insert) | itself (`enqueue_job/2`, `job_changeset/3`, `insert_job/2`) | exact |
| `lib/scrypath/sync/related_enqueue.ex` | service | request-response (DB insert) | `lib/scrypath/oban/enqueue.ex` | exact |
| `lib/scrypath/sync/related_worker.ex` | worker | event-driven (job) | `lib/scrypath/oban/upsert_worker.ex` (decode -> Loader.load -> write; cancel mapping) | exact |
| `lib/scrypath/oban/upsert_worker.ex` | worker | event-driven, batch | itself + `delete_worker.ex` | exact |
| `lib/scrypath/oban/delete_worker.ex` | worker | event-driven, batch | `upsert_worker.ex:50-54` (`write/5` + `IndexingAck.await`) | exact |
| `lib/scrypath/sync.ex` | service (orchestrator) | request-response, batch | itself (`dispatch_upsert/3`, `public_result/1`) | exact |
| `lib/scrypath/loader.ex` | service (loader) | CRUD read, batch | itself (`load/3`, `fetch/3`) | exact |
| `lib/scrypath/backfill.ex` | service | batch | itself (`run_batch` `with`, `write/5`) | exact |
| `lib/scrypath/reindex.ex` | service | batch / wait | itself (`maybe_wait_for_backfill_tasks/2`) | exact |
| `lib/scrypath/operations/result.ex` | model (struct) | transform | itself | exact |
| `lib/scrypath/operations.ex` | utility (normalizer) | transform | itself (`result_from_enqueue/2`) | exact |
| `lib/scrypath.ex` (backfill `## Result` docs ~386-415, sync result docs) | docs in public module | - | itself | exact |
| `test/support/oban_sqlite_repo.ex` (NEW) | test support (repo) | CRUD | `test/support/sqlite_sandbox_repo.ex` | exact |
| `test/support/oban_sqlite_migration.ex` or inline module (NEW) | test support (migration) | - | `test/support/loader_backfill_fixtures.ex:1-10` | exact |
| `test/support/fake_repo.ex` | test support | CRUD | itself (add `__adapter__/0`) | exact |
| `test/scrypath/oban/job_args_test.exs` (NEW) | test (pure, table-driven) | transform | `test/scrypath/oban/worker_test.exs:208-221` (cancel assertion) | role-match |
| `test/scrypath/oban/enqueue_unique_test.exs` (NEW) | test (SQLite Oban integration) | CRUD | `test/support/loader_backfill_cases.ex:487-515` (`setup_repo!/1`) + research probe | role-match |
| `test/scrypath/oban/enqueue_test.exs` | test | request-response | itself (`RecordingOban` fake) | exact |
| `test/scrypath/oban/worker_test.exs` | test | event-driven | itself (`upsert_args/4`, `LoaderPost`) | exact |
| `test/scrypath/sync/related_worker_test.exs` | test | event-driven | itself + `worker_test.exs:73-86` (`search_records/2` spy) | exact |
| `test/scrypath/sync/related_test.exs` | test | request-response | itself (`EnqueueOban`) | exact |
| `test/scrypath/sync_test.exs` | test | request-response | itself (`SeamBackend`, lines ~64-134) | exact |
| `test/scrypath/loader_test.exs` | test | CRUD read | itself (`CustomLoaderPost` spy, lines 7-31) | exact |
| `test/scrypath/loader_backfill_sqlite_test.exs` / `reindex_test.exs` | test | batch | shared `test/support/loader_backfill_cases.ex` | exact |
| `guides/related-data-and-reindexing.md` §(c) line 174, `guides/sync-modes-and-visibility.md` (`## :inline` 45, `## :oban` 66, `## :manual` 124) | docs | - | `CHANGELOG.md` 0.3.16 "Upgrade notes" block for tone | exact |

Examples (`examples/phoenix_meilisearch`, `examples/scrypath_ecommerce`) are Open Question 3 in RESEARCH and not in locked scope. If the maintainer approves, the analog for ecommerce `Category.search_records/2` is the `Scrypath.Loader` moduledoc example (`lib/scrypath/loader.ex:21-24`, `repo.all(skip_tenant_id: true)`).

---

## Pattern Assignments

### `lib/scrypath/chunks.ex` (NEW, utility, batch)

**Analog for halt-at-first-error:** `lib/scrypath/reindex.ex` lines 198-214
```elixir
batch_results
|> Enum.reduce_while({:ok, []}, fn batch_result, {:ok, acc} ->
  case maybe_wait_for_result_task(batch_result, config) do
    {:ok, waited_batch_result} -> {:cont, {:ok, [waited_batch_result | acc]}}
    {:error, reason} -> {:halt, {:error, reason}}
  end
end)
|> case do
  {:ok, waited_batch_results} -> {:ok, %{result | batch_results: Enum.reverse(waited_batch_results)}}
  {:error, reason} -> {:error, reason}
end
```
Copy this shape into `reduce_ok/2`. Module header follows every internal module: `defmodule ... do @moduledoc false` (e.g. `lib/scrypath/oban/indexing_ack.ex:1-2`). Use RESEARCH Pattern 1 for `ids/1` and `by_id/2` (dedupe by raw value, sort by `{to_string, id}`). Workers return `:ok` (not `{:ok, _}`) from `IndexingAck.await/3`, so add an `:ok`-returning variant (e.g. `each_ok/2` that halts on `{:error, _}`) or have the worker callback wrap `:ok` as `{:ok, nil}`.

No Oban references in this module (must compile with no Oban).

---

### `lib/scrypath/oban/job_args.ex` (NEW, pure decoder)

**Analog 1 (pure, string allowlist, no Oban dep):** `lib/scrypath/oban/job_config.ex` lines 8-20
```elixir
@spec merge_job_runtime_opts(keyword(), map()) :: keyword()
def merge_job_runtime_opts(keyword, args) when is_list(keyword) and is_map(args) do
  keyword
  |> put_from_arg(args, "meilisearch_url", :meilisearch_url)
  |> put_from_arg(args, "index_prefix", :index_prefix)
end

defp put_from_arg(kw, args, str_key, atom_key) do
  case Map.get(args, str_key) do
    v when is_binary(v) and v != "" -> Keyword.put(kw, atom_key, v)
    _ -> kw
  end
end
```
Use this for the D-17 allowlist (`index_prefix`, `meilisearch_url`, `backend`, `otp_app`, `repo`). The `v != ""` / non-binary fallthrough already treats `nil` as absent (RESEARCH Pitfall 5). Unknown keys never touched, so no atoms are created.

**Analog 2 (safe module resolution, lift verbatim and retag):** `lib/scrypath/oban/upsert_worker.ex` lines 56-81 and 132-147
```elixir
defp resolve_schema(%{"schema" => name}) when is_binary(name) do
  resolve_existing_module(name, fn module -> function_exported?(module, :__scrypath__, 1) end)
end
defp resolve_schema(_args), do: {:error, :invalid_schema}

defp resolve_backend(%{"backend" => name}) when is_binary(name) do
  resolve_existing_module(name, fn module ->
    function_exported?(module, :upsert_documents, 3) and
      function_exported?(module, :delete_documents, 3) and
      function_exported?(module, :index_name, 2)
  end)
end

defp fetch_index(%{"index" => index_name}) when is_binary(index_name) and byte_size(index_name) > 0,
  do: {:ok, index_name}

defp load_document_ids(%{"document_ids" => document_ids}) when is_list(document_ids),
  do: {:ok, document_ids}

defp resolve_existing_module(name, validator) do
  with {:ok, module} <- safe_module(name),
       true <- Code.ensure_loaded?(module),
       true <- validator.(module) do
    {:ok, module}
  else
    _ -> {:error, {:unknown_module, name}}
  end
end

defp safe_module(name) do
  parts = name |> String.split(".") |> Enum.map(&String.to_existing_atom/1)
  {:ok, Module.safe_concat(parts)}
rescue
  ArgumentError -> {:error, {:unknown_module, name}}
end
```
Changes: `resolve_existing_module/3` takes the D-15 tag (`:unknown_schema`, `:unknown_backend`, `:unknown_repo`) instead of the fixed `:unknown_module`; missing/ill-typed keys return `{:invalid_arg, "document_ids"}` etc. Delete worker's backend validator is narrower (`delete_worker.ex:34-39`: only `delete_documents/3` + `index_name/2`); D-16 says use the upsert check for related; keep delete's narrower one for delete (do not regress existing delete jobs against delete-only backends).

**Analog 3 (fan-out key, rescue to atom):** `lib/scrypath/sync/related_worker.ex` lines 80-94. Keep `String.to_existing_atom` in a rescue, add `rescue UndefinedFunctionError/FunctionClauseError` around `Metadata.fan_outs/1`, return `{:unknown_fan_out, name}`.

**Analog 4 (Config.resolve! rescue):** `upsert_worker.ex` lines 112-121
```elixir
defp build_config(backend, index_name, args) do
  config =
    [backend: backend, sync_mode: :manual]
    |> JobConfig.merge_job_runtime_opts(args)
    |> put_repo(args)

  {:ok, Config.resolve!(config) |> Keyword.put(:index_name, index_name)}
rescue
  error in ArgumentError -> {:error, {:invalid_config, Exception.message(error)}}
end
```
Exact model for `{:invalid_config, message}`.

**Repo check (D-16) and the D-18 change:** current `put_repo/2` (`upsert_worker.ex:123-130`) silently falls back on `{:error, _}`; new version returns `{:error, {:unknown_repo, name}}` when `"repo"` is a non-empty binary and fails `safe_module` + `Code.ensure_loaded?` + `function_exported?(m, :__adapter__, 0)`. `"repo" => nil` or absent -> no repo (legacy path, `worker_test.exs:151-189` must stay green).

**otp_app (D-16):** no existing analog; `String.to_existing_atom` in `rescue ArgumentError`, then `Application.spec(app) != nil`, else `{:unknown_otp_app, name}`.

**Expected public shape:** `decode_upsert/1`, `decode_delete/1`, `decode_related/1` each returning `{:ok, map}` or `{:error, tag}`; workers map `{:error, tag}` to `{:cancel, {:invalid_job, tag}}` exactly as `upsert_worker.ex:45-47` does today.

---

### `lib/scrypath/oban/enqueue.ex` (service, chunked + unique + transactional)

**Unique policy to extract into `unique_opts/0`** (lines 114-122):
```elixir
defp job_changeset(payload, worker, config) do
  oban_job_module!().new(payload,
    worker: worker,
    queue: to_string(Config.oban_queue(config)),
    max_attempts: Config.oban_max_attempts(config),
    # Jobs load current records when they run, so an identical pending batch adds nothing.
    unique: [period: :infinity, states: [:available, :scheduled, :retryable]]
  )
end
```
Make `unique_opts/0` a `@doc false def` so `RelatedEnqueue` can call it.

**Insert dispatch to keep (fakes depend on it)** (lines 124-135): `cond` on `function_exported?(oban, :insert, 1)` / `insert/2` / `Oban.insert(oban, cs)`. Multi-chunk insert wraps repeated calls of this in `Oban.Repo.transaction/2` when `Oban.config(oban)` resolves, else plain sequential halt (RESEARCH Pattern 3). Add `Oban.Repo` to the existing `@compile {:no_warn_undefined, [Oban, Oban.Job]}` (line 3).

**Result building to generalise** (lines 72-112): today builds one `public_job` map then `Operations.result_from_enqueue/2` and sets `metadata: %{index: ..., oban: %{queue, max_attempts, name}}`. For N chunks: build one `Operations.Task` per job (reuse `result_from_enqueue/2` per job and take `.task`), set `task: List.last(tasks)`, `tasks: tasks`, concat `document_ids`, sum `document_count`. Add `conflict?: Map.get(job, :conflict?, false)` to `public_job` and to `Task.metadata` (D-21); `RecordingOban` fakes return plain `%Oban.Job{}` whose `conflict?` defaults false.

**Chunk point:** `enqueue_upsert/3` (line 24) and `enqueue_delete/3` (line 38) call `Chunks.ids(document_ids)` and build one changeset per chunk via `upsert_job_changeset/3` / `delete_job_changeset/3`. Leave the public `*_job_changeset/3` single-changeset contract alone (used by `lib/scrypath/oban.ex:12-38` Multi helpers, Open Question 1).

---

### `lib/scrypath/sync/related_enqueue.ex` (service)

**Analog:** `lib/scrypath/oban/enqueue.ex` (above). Current code (lines 14-51) has a duplicated `insert_job/2` (75-81) and no `unique:`. Replace with:
- `Loader.ensure_loadable!(schema_module, config)` (copy the call position from `enqueue.ex:51`, right after `ensure_durable_api_key!`).
- empty `records` -> noop result (RESEARCH Pitfall 9; analog `Sync.noop_result/1`, `sync.ex:225-233`).
- `Chunks.ids(document_ids)` -> one `Oban.Job.new(args, worker: @worker, queue: ..., max_attempts: ..., unique: Enqueue.unique_opts())` per chunk -> shared transactional insert from `Enqueue` (expose a `@doc false insert_chunks/2` or similar rather than copying again).
- Keep `job_args/4` (lines 53-73) byte-for-byte: D-22 says the args shape does not change, and `JobArgs` allowlist mirrors its `Keyword.take` list.
- Keep the `if Code.ensure_loaded?(Oban.Job)` wrapper and the no-Oban stub (lines 1, 83-92).

---

### `lib/scrypath/sync/related_worker.ex` (worker, event-driven)

**Analog:** `lib/scrypath/oban/upsert_worker.ex` lines 14-48 (decode in `with`, `Loader.load/3`, Loader-reason cancel, else-cancel):
```elixir
def perform(%Oban.Job{args: args}) do
  with {:ok, schema_module} <- resolve_schema(args),
       {:ok, backend} <- resolve_backend(args),
       ...
       {:ok, config} <- build_config(backend, index_name, args) do
    case Loader.load(schema_module, document_ids, config) do
      {:ok, records, missing_ids} -> ...
      {:error, reason} when reason in [:repo_required, :search_records_required] ->
        ... {:cancel, {:invalid_job, reason}}
      {:error, reason} -> {:error, reason}
    end
  else
    {:error, reason} -> {:cancel, {:invalid_job, reason}}
  end
end
```
Replace the current raising destructure (`related_worker.ex:11`) and the `String.to_existing_atom` opts map (lines 15-24) with `JobArgs.decode_related(args)`. Keep the telemetry span (lines 35-51) and the HTTP 4xx cancel string (lines 53-65, D-19 unchanged). Within the span: `records == []` -> `{:ok, noop}` and skip resolver; else `apply(mod, fun, [records | mfa_args])`. Stop metadata: `Scrypath.Telemetry.stop_metadata(result, missing_count: length(missing))` (`lib/scrypath/telemetry.ex:31-57` already accepts `extra`). Make sure the empty-trigger branch returns `:ok` from `perform/1`, never `{:error, _}`.

Keep the `if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job)` wrapper and the `else` stub (lines 1, 96-99).

---

### `lib/scrypath/oban/upsert_worker.ex` and `delete_worker.ex` (workers, batch)

**Chunk point (upsert)** lines 50-54:
```elixir
defp write(_backend, _fun, _schema_module, [], _config), do: :ok

defp write(backend, fun, schema_module, entries, config) do
  IndexingAck.await(backend, apply(backend, fun, [schema_module, entries, config]), config)
end
```
Change the second clause to iterate `Chunks` (documents chunked by `& &1.id`, ids by `Chunks.ids/1`), calling `IndexingAck.await/3` per chunk and halting at the first `{:error, _}`. Upserts-then-deletes ordering stays in lines 27-29. Legacy snapshot path (line 36) goes through the same `write/5`.

**Delete worker** lines 19-22 currently call `backend.delete_documents` once; route through a `write/5` copied from upsert lines 50-54. Note `validate_document_count/2` (lines 54-58) checks the whole list before chunking; keep it ahead of chunking. Delete must not cancel on an unknown `"repo"` (RESEARCH Open Question 2), so `decode_delete/1` ignores `"repo"`.

**Decode:** replace `resolve_schema`/`resolve_backend`/`fetch_index`/`load_document_ids`/`safe_module`/`resolve_existing_module` private functions with `JobArgs.decode_upsert/1` / `decode_delete/1`. `build_config/3` can stay in the worker or move into `JobArgs`; JobArgs must not reference Oban.

---

### `lib/scrypath/sync.ex` (orchestrator)

**Chunk points:** `dispatch_upsert/3` inline/manual branch (lines 145-151) and `dispatch_delete/3` (lines 163-167):
```elixir
documents = Enum.map(records, &Projection.document(schema_module, &1))

backend_upsert_documents(schema_module, documents, config)
|> normalize_write_result(documents, config)
|> maybe_wait_for_task(config)
|> decorate_result(config)
```
For each chunk run `backend_* |> normalize_write_result |> maybe_wait_for_task` (the per-chunk wait is exactly `maybe_wait_for_task/2`, lines 171-190, inline only), collect via `Chunks.reduce_ok/2`, then:
- 1 chunk: existing `decorate_result/2` -> `public_result/1` (lines 212-255) plus `tasks: [public task]` (or `[]`).
- >1 chunk: build a fresh `%Result{}` (no `backend_result` in metadata, D-09) and a public map via the same `maybe_put` helpers.

**Public task shapes to reuse** (lines 273-292): `public_backend_task/1` and `public_job/1`. Add `conflict?` into `public_job/1` from `task.metadata`.

**Telemetry:** the existing single span (lines 28-36 and 122-130) wraps the whole call; do not add spans (D-10). `document_count` metadata already uses `length(records)`.

**Inline related:** `inline_resolve_and_sync/6` (lines 74-100): add the empty-list noop guard before `apply/3` (RESEARCH Open Question 5); otherwise unchanged (D-11 inline keeps caller structs).

**FakeBackend tolerance:** `normalize_write_result/3` (lines 300-309) passes non-map `{:ok, list}` through; the multi-chunk combiner must treat those as "no task" chunks (RESEARCH Pattern 2).

---

### `lib/scrypath/loader.ex` (loader)

**Chunk point** `load/3` lines 88-94 and `fetch/3` lines 127-148:
```elixir
def load(schema_module, document_ids, config) when is_list(document_ids) do
  with {:ok, records} <- fetch(schema_module, document_ids, config) do
    found = MapSet.new(Identity.document_ids(schema_module, records), &to_string/1)
    missing = Enum.reject(document_ids, &MapSet.member?(found, to_string(&1)))
    {:ok, records, missing}
  end
end
```
Call `fetch/3` per `Chunks.ids(document_ids)` chunk (halt on error), concat records, compute `missing` over the full input as now. `prepare_records/3` (lines 108-125) inherits it.

**Owner-only preload (Pitfall 3):** lines 123 and 145 call `Metadata.preload(schema_module)` which is `schema_module.__scrypath__(:preload)` (`lib/scrypath/schema/metadata.ex:18-20,51`). Add a private `preload_for/1` that returns `[]` when the clause is missing (rescue `FunctionClauseError`), mirroring the existing `preload_records/3` `preload in [nil, []]` short-circuit (line 150).

---

### `lib/scrypath/backfill.ex` (batch)

**Halt precedent** `run_batch` lines 63-67:
```elixir
with {:ok, records, omitted} <- Loader.prepare_records(schema_module, rows, config),
     documents = Enum.map(records, &Projection.document(schema_module, &1)),
     removals = if(state.fresh_target?, do: [], else: omitted),
     {:ok, upsert} <- write(:upsert, schema_module, documents, config, index),
     {:ok, delete} <- write(:delete, schema_module, removals, config, index) do
```
**Chunk point** `write/5` lines 107-121: chunk documents/ids, call the existing per-call body per chunk, halt on first error, return the per-chunk `Result`s. Batch result (lines 68-78) keeps `task: task_of(last_upsert)` and adds `tasks: Enum.map(upserts, &task_of/1) |> Enum.reject(&is_nil/1)`; `maybe_drop_nil/2` pattern stays for `task`/`delete_task`. `result_index/2` (line 134) reads from the last chunk.

### `lib/scrypath/reindex.ex` (wait every chunk task, Pitfall 1)

**Analog:** itself, lines 198-227. `maybe_wait_for_backfill_tasks/2` calls `maybe_wait_for_result_task/2` (which uses `followable_task/1`, lines 218-224, and `wait_for_result_task/3`, 191-196) once per batch. Extend so a batch with `tasks:` waits each entry with the same `Tasks.wait_for_task/2` + halt reduce_while, then keeps the `task:` update behaviour.

---

### `lib/scrypath/operations/result.ex` and `lib/scrypath/operations.ex` (model)

**Struct** lines 6-16: add `tasks: []` to `defstruct` and `tasks: [Task.t()]` to `@type t`. `new/1` uses `struct!/2` (line 20) so callers omitting `tasks` stay valid. `to_public_sync/1` (lines 24-36): add `tasks: Enum.map(result.tasks, &Task.to_public_sync/1)`.

**Job -> Task** `Operations.result_from_enqueue/2` lines 49-75: the `Task.new(source: :oban, kind: :queue_job, ...)` block is the per-chunk task builder; put `conflict?: Map.get(job, :conflict?, false)` into `metadata` next to `oban_state` (line 70). Consider extracting `task_from_job/1` (`@doc false`) so `Enqueue` can build `tasks` without re-building whole results.

---

### `test/support/oban_sqlite_repo.ex` (NEW) + migration

**Analog:** `test/support/sqlite_sandbox_repo.ex` (entire file, 47 lines). Copy verbatim with a new module name (`Scrypath.TestSupport.ObanSQLiteRepo`), a different persistent_term key and filename prefix (`scrypath-oban-...db`). Keep `pool_size: 2`, `journal_mode: :wal`, `busy_timeout: 5_000`, `log: false` and the comment about Migrator needing a second connection.

**Migration analog:** `test/support/loader_backfill_fixtures.ex` lines 1-10 (`@moduledoc false`, `use Ecto.Migration`). Body: `def up, do: Oban.Migrations.up()` / `def down, do: Oban.Migrations.down()`. Wrap in `if Code.ensure_loaded?(Oban.Migrations)` so the no-Oban build stays clean.

**Setup analog:** `test/support/loader_backfill_cases.ex` lines 487-515 `setup_repo!/1` (`storage_down`, `storage_up`, `start_supervised!(repo)`, `Ecto.Migrator.up(..., log: false)`, `Sandbox.mode(repo, :manual)`, `on_exit` file cleanup for `""`, `-wal`, `-shm`). Copy the sequence into the new test's `setup_all` (or a small helper) and then `start_supervised!({Oban, name: ..., repo: ObanSQLiteRepo, engine: Oban.Engines.Lite, testing: :manual, notifier: Oban.Notifiers.PG})` per the RESEARCH probe. Do not reuse `SQLiteSandboxRepo` (its setup drops the DB).

### `test/support/fake_repo.ex`

Add one function next to `all/1` (line 14): `def __adapter__, do: Ecto.Adapters.SQLite3` (Pitfall 7, needed for D-16 repo check). File is `Code.require_file`'d from `test/test_helper.exs`, so `Code.ensure_loaded?` holds.

---

### Tests

**`test/scrypath/oban/job_args_test.exs` (NEW, pure, `async: true`):** table-driven with `for {label, args, tag} <- [...] do test ... end`. Cancel assertion style from `worker_test.exs:208-221`:
```elixir
assert {:cancel, {:invalid_job, _reason}} =
         Scrypath.Oban.UpsertWorker.perform(%Oban.Job{args: bad_args})
```
In `job_args_test.exs` assert the exact `{:error, {:unknown_schema, "MissingSchema"}}` etc. directly on `JobArgs.decode_*`; in worker tests assert the exact `{:cancel, {:invalid_job, tag}}`. Note the existing related test expectations `{:cancel, {:invalid_job, :invalid_schema}}` (`related_worker_test.exs:140,152`) change to the D-15 tags.

**`test/scrypath/oban/enqueue_unique_test.exs` (NEW, `async: false`):** see oban_sqlite_repo above; `use Oban.Testing, repo: ObanSQLiteRepo, engine: Oban.Engines.Lite`. Checkout sandbox per test (`Ecto.Adapters.SQL.Sandbox.checkout/1`) as `loader_backfill_cases.ex` does.

**`test/scrypath/oban/enqueue_test.exs`:** fake Oban modules (lines 37-52) define only `insert/1` and have no running instance; the 2,500-id case uses a counter variant of `RecordingOban` (unique ids via `System.unique_integer([:positive])`) and `assert_received` three times. Existing assertion `job.unique[:states] == [:available, :scheduled, :retryable]` (line 87) is the model for the related-enqueue unique assertion.

**`test/scrypath/oban/worker_test.exs`:** reuse `upsert_args/4` (lines 93-106), `RecordingBackend` (7-47) and `LoaderPost` spy (73-86). 2,500-id case: `LoaderPost.search_records/2` already `send`s `{:search_records, ids, context}`, so assert three messages each `length(ids) <= 1000`. Legacy tests (151-189) must stay unchanged and green (D-18 / Pitfall 8).

**`test/scrypath/sync/related_worker_test.exs`:** fixtures `DummySchema` (48-67) and `ErrorSchema` (215-234) are plain structs with id-taking resolvers; rewrite them to define `search_records/2` (copy `worker_test.exs:82-85` / `loader_test.exs:18-30` spy style) and resolvers that pattern-match `[%DummySchema{} | _]`. `ErrorSchema` should encode the error type in a struct field returned by `search_records/2`, not in the id. Add the D-22 legacy fixture: a hard-coded map including `"opts" => %{"repo" => nil, "otp_app" => nil, "index_prefix" => nil, ...}`. Telemetry `missing_count` via `:telemetry.attach/4` with a `send(self(), ...)` handler (see `test/scrypath/telemetry_test.exs:340` `:telemetry.attach_many(handler_id, event_names, &__MODULE__.handle_event/4, {parent, ref})` idiom).

**`test/scrypath/sync/related_test.exs`:** existing Oban cases (lines ~123-194) need `repo: FakeRepo` (or a `search_records/2` on the fixture) because of D-12 (Pitfall 6). Add an `assert_raise ArgumentError, ~r/needs :repo/` case copied from `enqueue_test.exs:90-99`.

**`test/scrypath/sync_test.exs`:** copy `SeamBackend` (lines ~64-134) into a `ChunkBackend` that returns a unique task id per call (process dictionary counter) and `send`s `{:upsert_chunk, length(documents)}`; a failing variant returns `{:error, :boom}` on the 2nd call. Existing assertions at lines 252, 271, 344-377 (`sync_mode:` from merged backend map) are the single-chunk regression guard; do not change them.

**`test/scrypath/loader_test.exs`:** `CustomLoaderPost.search_records/2` (lines 18-30) is the spy; add a 2,500-id case asserting three `{:search_records, ids, _}` messages with `length(ids) <= 1000` and `missing` computed across chunks. Add an owner-only schema without `:preload` (hand-written `__scrypath__/1` clauses like `related_worker_test.exs:36-46`).

---

## Shared Patterns

### Optional-Oban compile guard
**Source:** `lib/scrypath/oban/upsert_worker.ex:1`, `lib/scrypath/sync/related_enqueue.ex:1,83-92`, `lib/scrypath/oban/enqueue.ex:3`
**Apply to:** any new Oban-touching code (`Enqueue` transaction, related enqueue, workers, test migration).
```elixir
if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Oban.UpsertWorker do ... end
end
# or, for modules that must always exist:
@compile {:no_warn_undefined, [Oban, Oban.Job]}
```
`Chunks` and `JobArgs` must have no Oban references at all.

### Cancel vs. retry mapping
**Source:** `lib/scrypath/oban/upsert_worker.ex:31-47`
**Apply to:** all three workers.
- decode/config failures -> `{:cancel, {:invalid_job, tag}}`
- Loader `:repo_required` / `:search_records_required` -> `{:cancel, {:invalid_job, reason}}`
- backend/transient errors -> `{:error, reason}` (retry)
- related 4xx -> unchanged `{:cancel, "HTTP ..."}` string (D-19)

### Halt-at-first-error sequencing
**Source:** `lib/scrypath/reindex.ex:198-214`, `lib/scrypath/backfill.ex:63-67`
**Apply to:** `Chunks.reduce_ok/2` and every chunked call site (Sync, Backfill, Loader, workers, Enqueue fallback).

### Per-chunk wait
**Source:** `lib/scrypath/sync.ex:171-190` (`maybe_wait_for_task/2`, inline only), `lib/scrypath/oban/indexing_ack.ex:11-27` (workers)
**Apply to:** each chunk inside the loop, never only the last chunk.

### Telemetry: one span, extra stop metadata
**Source:** `lib/scrypath/telemetry.ex:9-15,31-57`; usage `lib/scrypath/sync.ex:28-36`
```elixir
Telemetry.span([:scrypath, :sync, :upsert], metadata, fn ->
  result = ...
  {result, Telemetry.stop_metadata(result)}
end)
```
**Apply to:** Sync (unchanged), RelatedWorker (`stop_metadata(result, missing_count: n)`). No new events.

### Public result building
**Source:** `lib/scrypath/sync.ex:243-298` (`public_result/1`, `public_backend_task/1`, `public_job/1`, `maybe_put/3`)
**Apply to:** single-chunk path (unchanged + `tasks`), multi-chunk fresh map, Enqueue/RelatedEnqueue results.

### Raise-at-call-site validation
**Source:** `lib/scrypath/loader.ex:63-79` (`ensure_loadable!/2`), called at `lib/scrypath/oban/enqueue.ex:51`
**Apply to:** `RelatedEnqueue.enqueue/4` (D-12).

### Docs / CHANGELOG tone
**Source:** `CHANGELOG.md` 0.3.16 `### Upgrade notes` bullet (bold lead sentence, then behaviour, then link to guide anchor). Release Please owns versioned sections; per RESEARCH Open Question 6 the D-13 sentence goes in the PR body/commit footer and the release PR, not a hand-made `## Unreleased`.
**Guide contract strings to preserve:** `test/scrypath/phase108_contract_test.exs:28-32` (`"durably queued"`, `"document IDs"`, `"records"`) and `test/scrypath/docs_contract_test.exs:1305-1323`.

## No Analog Found

| File / piece | Role | Data Flow | Reason |
|---|---|---|---|
| Transactional multi-job insert inside `Enqueue` | service | DB transaction | No existing `Oban.Repo.transaction` / `Ecto.Multi` usage in `lib/`; use RESEARCH Pattern 3 (probe-verified). `lib/scrypath/oban.ex:12-52` shows the only `Ecto.Multi` + `Oban.insert(oban, multi, name, changeset)` usage if the planner prefers the Multi route. |
| `otp_app` validation in `JobArgs` | utility | transform | No existing `Application.spec` check; follow D-16 literally. |
| `Oban.Testing` usage | test | CRUD | Suite has none yet; follow RESEARCH Code Examples probe. |

## Metadata

**Analog search scope:** `lib/scrypath/{sync,loader,backfill,reindex,telemetry,operations}.ex`, `lib/scrypath/operations/`, `lib/scrypath/oban/`, `lib/scrypath/sync/`, `lib/scrypath/schema/metadata.ex`, `test/support/`, `test/scrypath/{oban,sync}/`, `test/scrypath/{sync_test,loader_test}.exs`, `guides/`, `CHANGELOG.md`
**Files scanned:** ~30
**Pattern extraction date:** 2026-10-25
