# Phase 178: Loader-routed backfill and full-key paging - Pattern Map

**Mapped:** 2026-10-25
**Files analyzed:** 29 (13 modified lib/config/CI/docs, 9 new test/support + test files, 7 modified tests/contracts)
**Analogs found:** 27 / 29 (2 partial: inline migration and `__using__` case template have no in-repo precedent)

All analog paths below were verified git-tracked (`git ls-files`). No gitignored mirrors are referenced.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scrypath/backfill.ex` (M) | service | batch (keyset paging + write) | itself (lines 18-162) + `lib/scrypath/oban/upsert_worker.ex` 23-29, 50 | exact (self) |
| `lib/scrypath/loader.ex` (M, + `prepare_records/3`) | service | request-response (records-in) | itself `load/3` 87-94, `fetch/3` 96-117, `preload_records/3` 119-121 | exact (self) |
| `lib/scrypath/reindex.ex` (M) | service | batch orchestration | itself 30-60, 224-249 | exact (self) |
| `lib/scrypath/options.ex` (M, internal flag) | config | validation | itself `@backfill_options` 231-297 | exact (self) |
| `lib/scrypath.ex` (M, `@doc` for `backfill/2`) | public API facade | n/a | `lib/scrypath.ex` `failed_sync_work/2` @doc 391-401 | role-match |
| `lib/mix/tasks/verify.postgres.ex` (NEW) | mix task | batch (shell to `mix test`) | `lib/mix/tasks/verify.meilisearch_smoke.ex` | exact |
| `lib/mix/tasks/verify/capability.ex` (M, `backend!/1`) | mix task dispatcher | request-response | itself 49-60, 138-143 | exact (self) |
| `lib/mix/tasks/verify.all.ex` (M) | mix task | batch | itself 28-29 | exact (self) |
| `lib/mix/tasks/verify.phase5.ex` (M, optional: add SQLite file) | mix task | batch | itself 27-36 | exact (self) |
| `mix.exs` (M: postgrex dep, preferred_envs) | config | n/a | itself 79, 115-116 | exact (self) |
| `test/support/postgres_repo.ex` (NEW) | test repo | DB I/O | `test/support/integration_repo.ex` | role-match (adds `init/2`) |
| `test/support/sqlite_sandbox_repo.ex` (NEW) | test repo | DB I/O | `test/support/integration_repo.ex` + `meilisearch_integration.ex` 15-17, 147-157 | role-match |
| `test/support/loader_backfill_migration.ex` (NEW) | migration | DDL | `test/support/meilisearch_integration.ex` 159-185 (raw SQL; replace with `Ecto.Migration`) | partial |
| `test/support/loader_backfill_schemas.ex` (NEW) | test schema | n/a | `test/support/queryable_post.ex`; `test/scrypath/oban/worker_test.exs` 73-86 (`LoaderPost.search_records/2`) | exact |
| `test/support/loader_backfill_cases.ex` (NEW, `__using__`) | test case template | DB I/O + property | `test/scrypath/live_meilisearch_verification_test.exs` 1-41 (setup_all/setup shape); `test/scrypath/runtime_safety_property_test.exs` 1-3 | partial (no `__using__` template exists) |
| `test/scrypath/loader_backfill_sqlite_test.exs` (NEW) | test | DB I/O | `test/scrypath/live_meilisearch_verification_test.exs` 1-17 | role-match |
| `test/scrypath/loader_backfill_postgres_test.exs` (NEW) | test | DB I/O | same, `@moduletag :integration` -> `:postgres` | role-match |
| `test/scrypath/loader_test.exs` (NEW) | unit test | request-response | `test/scrypath/oban/worker_test.exs` 73-86, 139-147 + `test/support/fake_repo.ex` | role-match |
| `test/test_helper.exs` (M) | config | n/a | itself 1-11 | exact (self) |
| `test/scrypath/backfill_test.exs` (M, removed:/delete asserts) | unit test | batch | itself 8-122 (RecordingBackend, BackfillRepo) | exact (self) |
| `test/scrypath/reindex_test.exs` (M, omitted:, composite create_index) | unit test | batch | itself 99-100, 294-350, 379 | exact (self) |
| `test/mix/tasks/workflow_wiring_test.exs` (M) | contract test | n/a | itself 381-392 (ops-ui Postgres assertion) | exact |
| `test/mix/tasks/verify_capability_test.exs` (M, optional) | contract test | n/a | itself 24-29, 64-70 | exact |
| `.github/workflows/ci.yml` (M, backend job) | CI config | n/a | ops-ui job service block (`ci.yml` ~lines 200-210, shown below) | exact |
| `compose.yaml` (M) | config | n/a | itself 7-13 + ops-ui service shape | exact |
| `CONTRIBUTING.md` (M) | docs | n/a | itself line 35 (verify table), 165-182, 211 | exact |
| `guides/sync-modes-and-visibility.md` (M) | docs | n/a | itself ~95-112 | exact |
| `guides/related-data-and-reindexing.md` (M) | docs | n/a | itself 379-414 | exact |
| `README.md` (M, `result.omitted`) | docs | n/a | itself 154-168 | exact |

## Pattern Assignments

### `lib/scrypath/backfill.ex` (service, batch)

**Analog:** itself + `lib/scrypath/oban/upsert_worker.ex`

**Imports/aliases to keep** (lines 1-11); add `alias Scrypath.Loader` and keep `import Ecto.Query` (needed for `dynamic/2`):
```elixir
defmodule Scrypath.Backfill do
  @moduledoc false
  import Ecto.Query
  alias Scrypath.Meilisearch.Operations, as: MeilisearchOperations
  alias Scrypath.Options
  alias Scrypath.Operations
  alias Scrypath.Operations.Result
  alias Scrypath.Operations.Task
  alias Scrypath.Projection
```

**Current loop to replace with a state map** (lines 31-90). `run_batches/8` is at Credo `max_arity: 8`; do not add params. The write+normalize shape to preserve (lines 55-69):
```elixir
with {:ok, backend_result} <-
       upsert_documents(schema_module, documents, Keyword.fetch!(config, :backend), config, index),
     result <-
       Operations.normalize_write_result(backend_result,
         mode: Keyword.fetch!(config, :sync_mode),
         document_ids: Enum.map(documents, & &1.id),
         document_count: length(documents),
         index: index
       ) do
```
Top-level result shape (lines 42-49) gains `removed:` (and `omitted:` only under the fresh-target flag):
```elixir
%{index: index, batches: length(acc), documents: total,
  mode: Keyword.fetch!(config, :sync_mode), batch_results: Enum.reverse(acc)}
```

**Bug sites:** `base_query/3` (92-97) strips only `:order_by`/`:limit`; add `exclude(:offset)`, `exclude(:select)`, `exclude(:preload)`, and order by every PK column. `batch_query/4` (99-108) single-column `field(record, ^primary_key) > ^cursor` becomes `keyset_after/2` (RESEARCH Pattern 2; single-column must keep this exact AST because `BackfillRepo.evaluate/3` in `backfill_test.exs:99-101` only matches `{:>, _, [field, {:^, _, [i]}]}`). `primary_key/1` (157-162) returns only the first column; replace with `pk_columns/1` returning the full list (fallback `[Metadata.document_id(schema)]` + `not is_nil` where).

**Backend dispatch to mirror for delete** (lines 110-120) -> add sibling `delete_documents/5`:
```elixir
defp upsert_documents(schema_module, documents, backend, config, index) do
  config = Keyword.put(config, :index_name, index)
  case backend do
    Scrypath.Meilisearch -> MeilisearchOperations.upsert_documents(schema_module, documents, config)
    _other -> backend.upsert_documents(schema_module, documents, config)
  end
end
```
`MeilisearchOperations.delete_documents/3` exists (`lib/scrypath/meilisearch/operations.ex:37-38`, `@spec delete_documents(module(), [term()], keyword()) :: {:ok, Result.t()} | {:error, term()}`).

**Oban semantics to match** (`lib/scrypath/oban/upsert_worker.ex` 23-29, 50) — upsert found, then delete missing, skip empty lists:
```elixir
case Loader.load(schema_module, document_ids, config) do
  {:ok, records, missing_ids} ->
    documents = Enum.map(records, &Projection.document(schema_module, &1))
    with :ok <- write(backend, :upsert_documents, schema_module, documents, config) do
      write(backend, :delete_documents, schema_module, missing_ids, config)
    end
...
defp write(_backend, _fun, _schema_module, [], _config), do: :ok
```
Do NOT call `write/5` (private, Oban-conditional module at line 1, ack-blocking). Copy only the empty-list skip idea. Skipping upsert on `[]` is mandatory: `backfill_test.exs:37` `Enum.max_by(documents, ...)` raises on `[]`.

**Batch result** (lines 122-130) gains `removed:`; keep `maybe_drop_nil(:task)` (144-149) so all-omitted batches have no task:
```elixir
%{index: Map.get(result.metadata, :index, index), documents: documents,
  last_primary_key: last_primary_key, task: public_task(result.task)}
|> maybe_drop_nil(:task)
```
Internal cursor must no longer be read from public `last_primary_key` (`last_primary_key/1` at 151-155); carry a value list in state.

---

### `lib/scrypath/loader.ex` (service, records-in)

**Analog:** itself. New `@doc false` `prepare_records/3` wraps `load/3` (87-94) for the custom path and `preload_records/3` (119-121) for the default path.

`load/3` missing-id logic to reuse (88-93):
```elixir
with {:ok, records} <- fetch(schema_module, document_ids, config) do
  found = MapSet.new(Identity.document_ids(schema_module, records), &to_string/1)
  missing = Enum.reject(document_ids, &MapSet.member?(found, to_string(&1)))
  {:ok, records, missing}
end
```
Preload helper (119-121) — add `force: true` only to the third clause; keep the `[nil, []]` short-circuit (FakeRepo/BackfillRepo have no `preload/3`):
```elixir
defp preload_records(_repo, records, preload) when preload in [nil, []], do: records
defp preload_records(_repo, [], _preload), do: []
defp preload_records(repo, records, preload), do: repo.preload(records, preload)
```
Doc style for public functions: `@doc "..."` + `@spec` immediately above (lines 34-36, 81-87). Since the module has a `@moduledoc`, mark the new function `@doc false` and do not link it from public docs (ExDoc `--warnings-as-errors`). Full skeleton: RESEARCH.md Pattern 1.

---

### `lib/scrypath/reindex.ex` (service, orchestration)

**Analog:** itself.
- Internal-key convention (line 33): `|> Keyword.put(:_scrypath_schema, schema_module)` — name the fresh-target flag the same way (e.g. `:_scrypath_fresh_target`), add it in the backfill call at lines 43-48:
```elixir
backfill.run(
  schema_module,
  workflow_config
  |> backfill_config()
  |> Keyword.put(:index_name, target_index)
)
```
- Result map (52-60): add `omitted: Map.get(backfill_result, :omitted, 0)` — use `Map.get`, not `Map.fetch!`, because `RecordingBackfill` in `test/scrypath/reindex_test.exs:294-350` returns no `omitted` key.
- D-17: line 36 `meilisearch.create_index(schema_module, primary_key(schema_module), workflow_config)` -> pass `Scrypath.Schema.Metadata.document_id(schema_module)`; delete `primary_key/1` (244-249). Existing asserts `{:create_index, QueryablePost, :id, _}` (reindex_test 379, 422, 467, 494) stay green.
- `@backfill_pass_through_keys` (224-238): flag is `Keyword.put` after `backfill_config/1`, so no list change is needed (or add the flag to the list — either way it must be in `@backfill_options`).

---

### `lib/scrypath/options.ex` (config, validation)

**Analog:** `@backfill_options` entries (lines 231-297). Copy entry shape:
```elixir
sync_mode: [
  type: {:in, [:inline, :manual, :oban]},
  default: :manual,
  doc: "Execution mode for the bulk workflow."
]
```
Add `_scrypath_fresh_target: [type: :boolean, default: false, doc: false]`. `validate!/2` (line 696) raises on unknown keys, so the flag must be listed.

---

### `lib/scrypath.ex` (public facade, `@doc` for `backfill/2`)

**Analog:** `failed_sync_work/2` @doc (lines 391-401) — bold-key prose + `## ` subsection, then `@spec`, then the delegating function. Current undocumented target at ~376-379:
```elixir
@spec backfill(module(), keyword()) :: {:ok, map()} | {:error, term()}
def backfill(schema_module, opts \\ []) do
  Scrypath.Backfill.run(schema_module, opts)
end
```
Doc must describe `index, batches, documents, removed, mode, batch_results[].{index, documents, removed, last_primary_key, task}` and composite keyword cursor. No links to `Scrypath.Loader.prepare_records/3` or `Scrypath.Backfill` (hidden).

---

### `lib/mix/tasks/verify.postgres.ex` (NEW mix task)

**Analog:** `lib/mix/tasks/verify.meilisearch_smoke.ex` (whole file, 73 lines). Copy structure:
- Header (1-22): `use Mix.Task`, `@shortdoc`, `@moduledoc` with `## Environment`.
- Curated file list attribute (24-29).
- `run/1` (31-55):
```elixir
Mix.Task.run("app.start")
{opts, _argv, _invalid} = OptionParser.parse(args, strict: [skip_integration: :boolean])
if opts[:skip_integration] do
  Mix.shell().info("==> Skipping Meilisearch smoke (--skip-integration)")
else
  ensure_integration_env!()
  for path <- @integration_tests do
    Mix.shell().info("==>   #{path}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", ["--include", "integration", path])
  end
end
```
Use `["--include", "postgres", path]` (helper exclude list is evaluated once per VM — RESEARCH Pitfall 2).
- Env guard (57-72) `ensure_integration_env!` with `Mix.raise("""...Example...""")` -> `ensure_postgres_env!` for `SCRYPATH_POSTGRES_URL`. Do not `System.put_env("SCRYPATH_INTEGRATION", ...)`.
- Must not reference `Postgrex`/test-support modules at compile time (lib ships in Hex). Full draft: RESEARCH.md "Code Examples".

---

### `lib/mix/tasks/verify/capability.ex` (dispatcher)

**Analog:** `backend!/1` (lines 49-60) + `run_task!/2` (138-143, already re-enables):
```elixir
defp backend!(args) do
  {opts, argv, invalid} = OptionParser.parse(args, strict: [skip_integration: :boolean])
  if argv != [] or invalid != [] do
    Mix.raise("verify.backend accepts only --skip-integration")
  end
  run_task!(
    "verify.meilisearch_smoke",
    if(opts[:skip_integration], do: ["--skip-integration"], else: [])
  )
end
```
Bind the args list once and add `run_task!("verify.postgres", same_args)` after. Keep the raise text (pinned by `verify_capability_test.exs:24-29`).

### `lib/mix/tasks/verify.all.ex`
Lines 28-29 pattern; renumber `[n/6]` -> `[n/7]` and add a step:
```elixir
Mix.shell().info("==> [5/6] Running Meilisearch integration smoke...")
Mix.Task.run("verify.meilisearch_smoke", args)
```

### `lib/mix/tasks/verify.phase5.ex` (optional, Open Question 2)
Add `"test/scrypath/loader_backfill_sqlite_test.exs"` to the `run_test!([...])` list at lines 27-36.

### `mix.exs`
- deps (115-116) pattern: `{:ecto_sqlite3, "~> 0.22", only: :test, runtime: false},` -> add `{:postgrex, "~> 0.22", only: :test, runtime: false},`.
- `cli/0` preferred_envs (line 79 `"verify.meilisearch_smoke": :test,`) -> add `"verify.postgres": :test,`.
- `support_file?/1` (177-179) already keeps `test/support/*.ex` from being treated as tests; no change.

---

### `test/support/postgres_repo.ex` and `test/support/sqlite_sandbox_repo.ex` (NEW test repos)

**Analog:** `test/support/integration_repo.ex` (whole file):
```elixir
defmodule Scrypath.TestSupport.IntegrationRepo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :scrypath,
    adapter: Ecto.Adapters.SQLite3
end
```
Postgres: `adapter: Ecto.Adapters.Postgres` + `@impl true def init(_type, config)` parsing `SCRYPATH_POSTGRES_URL` with `Ecto.Repo.Supervisor.parse_url/1`, then `database: "scrypath_test#{MIX_TEST_PARTITION}"`, `pool: Ecto.Adapters.SQL.Sandbox`, `pool_size: 10` (RESEARCH Pattern 5).
SQLite: tmp-path naming from `test/support/meilisearch_integration.ex:15-17` but add `System.os_time()` (Pitfall 3):
```elixir
Path.join(System.tmp_dir!(), "scrypath-integration-#{System.unique_integer([:positive])}.db")
```
Start options from `meilisearch_integration.ex:147-157` (`journal_mode: :wal, busy_timeout: 5_000`) but `pool: Ecto.Adapters.SQL.Sandbox, pool_size: 2+` (NOT `pool_size: 1` — Migrator deadlock, Pitfall 1).

### `test/support/loader_backfill_migration.ex` (NEW, partial analog)
Only in-repo DDL is raw SQL in `meilisearch_integration.ex:159-185` (`CREATE TABLE IF NOT EXISTS posts (...)`). Do not copy that; use `use Ecto.Migration` + `create table(:lb_memberships, primary_key: false) do add :org_id, :integer, primary_key: true; add :uid, :binary_id, primary_key: true ... end` (RESEARCH Pattern 5). Needs tables for: single-PK preload parent/child, composite PK, `search_records/2` schema.

### `test/support/loader_backfill_schemas.ex` (NEW)
**Analogs:** `test/support/queryable_post.ex` (multiple `defmodule` per file; `belongs_to` assoc; `@primary_key {...}` override + `document_id:` at 26-38):
```elixir
defmodule QueryableExternalPost do
  use Ecto.Schema
  @primary_key {:external_id, :string, autogenerate: false}
  use Scrypath,
    fields: [:title],
    document_id: :external_id
  schema "external_posts" do
    field(:title, :string)
  end
end
```
`search_records/2` shape from `test/scrypath/oban/worker_test.exs:73-86`:
```elixir
defmodule LoaderPost do
  use Ecto.Schema
  use Scrypath, fields: [:title]
  schema "loader_posts" do
    field(:title, :string)
  end
  def search_records(ids, context) do
    send(self(), {:search_records, ids, context})
    Enum.map(ids -- [404], &%__MODULE__{id: &1, title: "Loaded #{&1}"})
  end
end
```
For the real-DB version, query via `context.repo` (guide example `guides/sync-modes-and-visibility.md:104-107`). Composite schema needs a unique doc id: `search_document/1` with `id: "#{org_id}:#{uid}"` + matching `search_document_id/1` (RESEARCH, Identity/Projection facts). Namespace modules under `Scrypath.TestSupport.LoaderBackfill.*` to avoid global-name clashes.

### `test/support/loader_backfill_cases.ex` (NEW `__using__` template, partial analog)
No existing case template. Body structure copies `test/scrypath/live_meilisearch_verification_test.exs:9-41` (setup_all with `on_exit` cleanup, setup returning context map):
```elixir
setup_all do
  database = MeilisearchIntegration.setup_repo!()
  on_exit(fn -> MeilisearchIntegration.cleanup_repo!(database) end)
  :ok
end
```
Property syntax from `test/scrypath/runtime_safety_property_test.exs:1-3, 18-19` (`use ExUnitProperties`, `property "..." do check all(x <- gen) do ... end end`). Wrap in `defmacro __using__(opts)` with `quote do ... unquote(opts[:repo]) ... end`. Setup sequence + savepoint-per-iteration: RESEARCH Pattern 5. Recording backend capture: copy `RecordingBackend` from `test/scrypath/backfill_test.exs:8-62` but return `task: nil` (no `Enum.max_by`) so reindex never polls Meilisearch (Pitfall 6).

### `test/scrypath/loader_backfill_{sqlite,postgres}_test.exs` (NEW)
Analog header `live_meilisearch_verification_test.exs:1-7`:
```elixir
defmodule Scrypath.LiveMeilisearchVerificationTest do
  use ExUnit.Case, async: false
  alias Scrypath.TestSupport.IntegrationRepo
  @moduletag :integration
```
SQLite file: no moduletag. Postgres file: `@moduletag :postgres` (never `:integration`, D-12).

### `test/scrypath/loader_test.exs` (NEW unit)
Analog: `test/scrypath/oban/worker_test.exs` 88-91 (`setup do FakeRepo.reset(); :ok end`) and 139-147 (`assert_received {:search_records, ids, %{repo: FakeRepo}}`, `refute_received {:fake_repo_all, _}`). `FakeRepo` (`test/support/fake_repo.ex`) has only `all/1` — default-path tests must use schemas with `preload: []` to prove no `repo.preload` call.

---

### `test/test_helper.exs` (M)
Current (1-11):
```elixir
unless System.get_env("SCRYPATH_INTEGRATION") in ["1", "true", "TRUE"] do
  ExUnit.configure(exclude: [:integration, :requires_clean_workspace])
end
ExUnit.start()
"test/support/**/*.ex" |> Path.wildcard() |> Enum.each(&Code.require_file/1)
```
Replace with a single composed `exclude` list (RESEARCH Pitfall 2) — `ExUnit.configure(exclude:)` replaces, never appends. Keep the comment about `:requires_clean_workspace`.

### `test/scrypath/backfill_test.exs` (M)
Reuse `RecordingBackend` (8-62); its `delete_documents/3` (48-51) returns `{:ok, %{}}` without sending — add `send(self(), {:delete_documents, schema, ids, config})` if asserting deletes. `BackfillRepo` (64-122) supports only single-column `==`/`>`/single `asc` — keep composite tests out of this file. Existing asserts (e.g. 152-176, `length(query.wheres) == 1`) must stay green.

### `test/scrypath/reindex_test.exs` (M)
`create_index` recorder (99-100): `send(self(), {:create_index, schema_module, primary_key, config})`. Add composite-schema assert `{:create_index, CompositeSchema, <document_id field>, _}` (D-17), and `omitted:` result assert.

### `test/mix/tasks/workflow_wiring_test.exs` (M)
Copy lines 381-392 for the `backend` job:
```elixir
test "path-scoped ops-ui job provides its Postgres test dependency" do
  ops_ui = @ci_yml |> File.read!() |> workflow_job_block("ops-ui")
  assert ops_ui =~ "services:"
  assert ops_ui =~ "image: postgres:16-alpine"
  assert ops_ui =~ "POSTGRES_USER: postgres"
  assert ops_ui =~ "POSTGRES_PASSWORD: postgres"
  assert ops_ui =~ "ports: [5433:5432]"
  assert ops_ui =~ "pg_isready -U postgres"
```
-> `workflow_job_block(ci, "backend")`, `ports: [5434:5432]`, `SCRYPATH_POSTGRES_URL`. Line 236 pins `**\`backend\`**` in CONTRIBUTING — keep the token.

### `test/mix/tasks/verify_capability_test.exs` (M, optional)
Lines 64-70 loop checks `preferred_envs` — optionally add `"verify.postgres"` to the list; add a test that `verify.postgres` raises `Mix.Error` without `SCRYPATH_POSTGRES_URL` (use `System.delete_env` carefully; file is `async: true`, so prefer a separate `async: false` module).

---

### `.github/workflows/ci.yml` (M, backend job ~lines 72-106)
Current backend `services:`/`env:`:
```yaml
  backend:
    name: backend (required)
    runs-on: ubuntu-latest
    services:
      meilisearch:
        image: getmeili/meilisearch:v1.15
        ports: [7700:7700]
        env: {MEILI_NO_ANALYTICS: "true"}
    env:
      SCRYPATH_INTEGRATION: "1"
      SCRYPATH_MEILISEARCH_URL: http://127.0.0.1:7700
```
Service block to copy verbatim from ops-ui job:
```yaml
      postgres:
        image: postgres:16-alpine
        env: {POSTGRES_USER: postgres, POSTGRES_PASSWORD: postgres}
        ports: [5433:5432]
        options: >-
          --health-cmd "pg_isready -U postgres"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
```
Use port `5434:5432`; add `SCRYPATH_POSTGRES_URL: postgres://postgres:postgres@127.0.0.1:5434`. Keep `name: backend (required)`. Optional: extend `Backend failure diagnostics` with postgres `docker logs` (same `--filter ancestor=` idiom).

### `compose.yaml` (M)
Existing (7-13) — add a sibling `postgres:` service (`image: postgres:16-alpine`, `ports: - "5434:5432"`, `POSTGRES_USER/PASSWORD: postgres`) and extend the header comment with the `SCRYPATH_POSTGRES_URL=... mix verify.postgres` line, mirroring the existing comment style.

### Docs
- `CONTRIBUTING.md:35` verify-table row: `| Meilisearch backend | \`mix verify.backend\` | Curated live backend smoke (\`mix verify.meilisearch_smoke\`) |` -> mention `mix verify.postgres`; update 165-182 runbook and 211 `**\`backend\`**` row (keep token). Line 161 "service-free" claim for core stays true.
- `guides/sync-modes-and-visibility.md:110` ("Scrypath removes the rest from the index") — extend to backfill, scope-limited (D-04/D-06).
- `guides/related-data-and-reindexing.md:379-414` "When to choose backfill versus reindex" — add preload/search_records honor, composite PK + constraint-order note, `:query` must not fan out.
- `README.md:163-168` `result.*` list — add `result.omitted`. Run `mix test --include docs_contract test/scrypath/docs_contract_test.exs` after edits.

## Shared Patterns

### Backend dispatch (Meilisearch vs injected backend)
**Source:** `lib/scrypath/backfill.ex:110-120`
**Apply to:** new `delete_documents/5` in backfill. Always `Keyword.put(config, :index_name, index)` first.

### Empty-list write skip
**Source:** `lib/scrypath/oban/upsert_worker.ex:50`
**Apply to:** backfill upsert (documents `[]`) and delete (omitted `[]` or fresh target).

### Internal config keys
**Source:** `lib/scrypath/reindex.ex:33` (`:_scrypath_schema`)
**Apply to:** fresh-target flag; also registered in `options.ex @backfill_options` with `doc: false`.

### Curated verify task
**Source:** `lib/mix/tasks/verify.meilisearch_smoke.ex:31-72`
**Apply to:** `verify.postgres` (one `mix test` per file, `Mix.Task.reenable("test")`, `--include <tag>`, `--skip-integration`, `Mix.raise` env guard with example command).

### Env-gated tags
**Source:** `test/test_helper.exs:1-5`; `@moduletag :integration` in `live_meilisearch_verification_test.exs:7`
**Apply to:** `:postgres` tag, independent of `SCRYPATH_INTEGRATION`.

### CI contract pinning
**Source:** `test/mix/tasks/workflow_wiring_test.exs:381-392`, `verify_capability_test.exs:24-29, 64-70`
**Apply to:** every ci.yml / capability / preferred_envs change.

### Recording test doubles
**Source:** `test/scrypath/backfill_test.exs:8-62` (RecordingBackend), `test/scrypath/reindex_test.exs:99-100` (create_index recorder), `294-350` (RecordingBackfill)
**Apply to:** shared real-DB cases (return `task: nil`) and new unit asserts.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/support/loader_backfill_migration.ex` | migration | DDL | No `Ecto.Migration` exists in the repo; current test DDL is raw SQL (`meilisearch_integration.ex:159-185`). Use RESEARCH Pattern 5. |
| `test/support/loader_backfill_cases.ex` | case template | DB + property | No `defmacro __using__` test template exists; ExUnit `parameterize:` is unavailable on the 1.17 floor. Use RESEARCH Pattern 5 + the setup shape above. |
| `Backfill.keyset_after/2` (inside backfill.ex) | private builder | query | No `dynamic/2` usage precedent for keyset; use RESEARCH Pattern 2 (probe-verified). |

## Metadata

**Analog search scope:** `lib/scrypath/`, `lib/mix/tasks/`, `test/support/`, `test/scrypath/`, `test/mix/tasks/`, `.github/workflows/ci.yml`, `compose.yaml`, `mix.exs`, `CONTRIBUTING.md`, `README.md`, `guides/`
**Files scanned:** ~30
**Pattern extraction date:** 2026-10-25
