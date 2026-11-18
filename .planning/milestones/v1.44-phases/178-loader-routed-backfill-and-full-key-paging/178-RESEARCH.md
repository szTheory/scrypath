# Phase 178: Loader-routed backfill and full-key paging - Research

**Researched:** 2026-10-25
**Domain:** Ecto keyset pagination, Ecto loader/preload semantics, ExUnit + Ecto SQL Sandbox (Postgres + SQLite), Mix verify-task and GitHub Actions wiring
**Confidence:** HIGH. Every load-bearing behavior below was read in source this session or run against Ecto 3.14 / ecto_sql 3.14 / postgrex 0.22.4 / Postgres 16 / ecto_sqlite3 0.24 in throwaway probes.

## Summary

The locked decisions (D-01..D-16) already pick the approach. This research grounds them in the code as it stands today. `Scrypath.Backfill` is a 160-line module. Its single-column bug is `primary_key/1` (it returns only the first PK field), and the same bug is copied into `Scrypath.Reindex.primary_key/1`, which reindex passes to `create_index`. Documents are built with `Projection.document/2` on raw rows, with no preload and no `search_records/2`. `Scrypath.Loader` already holds the two pieces the new records-in entry point needs: the private `preload_records/3`, which needs `force: true`, and the custom path inside `load/3`, which already computes `missing` ids with `to_string` comparison. The new function wraps the existing logic. It does not need a new algorithm.

The keyset predicate D-07 describes builds cleanly with `Ecto.Query.dynamic/2` and `field(r, ^col)`. A probe confirmed it yields `WHERE ((a >= ?) AND ((a > ?) OR ((a = ?) AND (b > ?))))` on both SQLite and Postgres. Parameters keep their schema types, so a `binary_id` is dumped to a 16-byte binary on Postgres. The single-column case produces exactly the AST that today's `where([r], field(r, ^pk) > ^cursor)` produces, so the in-test `BackfillRepo` fake keeps working unchanged. Composite cases need real databases, which D-13/D-14 already require.

The harness has three traps, all reproduced in probes. (1) `Ecto.Migrator.up/4` under a Sandbox pool with `pool_size: 1` deadlocks on SQLite and raises on Postgres, so use `pool_size` ≥ 2 (use 10). (2) `System.unique_integer([:positive])` repeats across fresh VMs, so tmp-file DB names collide with leftovers and `storage_up`/`Migrator.up` return `:already_up` against stale schema. (3) `mix test` loads `test_helper.exs` with `Code.require_file`, so when `verify.backend` runs several `mix test` invocations in one VM, the helper is evaluated only once. `verify.postgres` must therefore pass `--include postgres` explicitly. It cannot rely on the helper's exclude list.

**Primary recommendation:** Add `Scrypath.Loader.prepare_records/3` (`@doc false`). Rebuild `Backfill.run_batches` around an explicit state map: Credo `max_arity: 8` is already at its limit. Add a private `keyset_after/2` using the D-07 OR-expansion. Write the DB tests once as a `__using__` case template in `test/support/`. Elixir 1.17 has no ExUnit `parameterize:`. Run that template from a SQLite file in `core` and a `@moduletag :postgres` file through a new `verify.postgres` task that `verify.backend` calls after `verify.meilisearch_smoke`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

The maintainer delegated these calls. Each was researched by a dedicated subagent with primary-source prior art (searchkick, meilisearch-rails, elasticsearch-model, Laravel Scout, Rails 7.1+ batches, paginator, use-the-index-luke, ecto_sql/Oban/Flop CI). Alternatives are in `178-DISCUSSION-LOG.md`.

#### Loader integration shape (LOAD-01/02/03)
- **D-01:** Hybrid, records-in. Backfill keeps fetching full rows from the caller's scoped keyset query. It hands each batch to a new `Scrypath.Loader` entry point that takes records (name it in the plan, e.g. `prepare_records/3`).
  - Default path: `repo.preload(records, Metadata.preload(schema), force: true)`. This is the same preload helper `load/3` uses, so the document equals Oban's.
  - Custom path (`search_records/2` defined): call `search_records(Identity.document_ids(schema, rows), %{repo: repo})`, and project only the records it returns.
  - Rejected: the ids-then-`Loader.load/3` approach. It regresses schemas with `search_document_id/1` and no `search_records/2`, which can backfill today but would hit `:search_records_required`. It also doubles queries on the default path.
- **D-02:** The caller's `:query` stays the sole row selector (LOAD-03). `base_query` strips `:order_by`, `:limit`, `:offset`, `:select` and `:preload` from it, and keeps `where`/`join` scope.
  - Stripping `:offset` fixes a latent row-skipping bug.
  - `select:` would break projection.
  - Caller preloads would make documents differ from Oban's.
  - The declared `preload:` and `search_records/2` alone decide document content.
- **D-03:** On the custom path, the keyset cursor advances on the scoped rows' primary key, never on what `search_records/2` returned. A batch where every record is omitted still advances, and the loop never ends early. Records `search_records/2` returns whose ids were not in the batch are ignored, so the scope stays authoritative.

#### Omitted records (LOAD-02)
- **D-04:** In a live-index backfill, ids from the batch that `search_records/2` leaves out are deleted from the index, matching the documented contract (`guides/sync-modes-and-visibility.md`: "Scrypath removes the rest from the index") and the Oban upsert worker. Reindex into a fresh target passes an internal, undocumented backfill flag that skips the delete calls but still counts omissions. This is the same split searchkick (`full:`) and meilisearch-rails (`if:`/`unless:` on reindex) make. — **Reversibility:** costly — this is a visible behavior change: backfills that previously indexed everything now remove documents. Undoing it later would be a second behavior change for adopters, and the CHANGELOG and guide must state it.
- **D-05:** Reporting:
  - Each batch result gains `removed:` (a count) next to `documents:`.
  - The top-level result gains a total `removed:`.
  - Reindex reports `omitted:` instead, because nothing was removed from a fresh target.
  - Do not return id lists in results (keep them bounded and simple).
  - Don't add new telemetry events here; Phase 180 owns telemetry. Only add counts to existing span stop metadata if a span already wraps the call.
- **D-06:** Document the scope limit. The default path never omits rows, and documents for rows deleted outside Scrypath or outside the visited scope stay in the index; finding those is reconcile/drift recovery's job. The guide must not imply that a backfill prunes the whole index.

#### Composite keyset paging (PAGE-01)
- **D-07:** A single portable predicate, hand-rolled with `Ecto.Query.dynamic/2`, with no new dependency. It is the OR-expansion plus a redundant leading-column bound:
  `a >= ^x and (a > ^x or (a == ^x and b > ^y) ...)`
  - Comparisons use `field(r, ^col) > ^v`, so Ecto type casting holds for UUID, binary_id and Decimal.
  - `order_by` is `asc:` on every key column, in `__schema__(:primary_key)` order.
  - A single-column key emits exactly today's `a > ^x`, so its SQL doesn't change.
  - Put the predicate behind one private builder (e.g. `keyset_after/3`) so a Postgres row-value fast path can be swapped in later without an API change.
  - Rejected: row-value `fragment`s (per-arity clauses, lose type inference, unsupported on MSSQL, not index-usable on MySQL) and the decomposed multi-query seek (novel, extra round trips).
- **D-08:** Edge cases:
  - Always ascending.
  - Never re-sort keys in Elixir (Decimal and UUID term order is not database order); take the cursor from the last loaded record.
  - Within a batch, dedupe rows by key tuple (`Enum.uniq_by`) in case a caller `:query` join fans out, and document that `:query` must not fan out. Don't add `distinct: true`.
  - On the no-primary-key `document_id` fallback, add `where: not is_nil(field)`, and raise if a cursor value is ever nil.
  - Document "declare composite primary-key fields in the database constraint's column order" so the btree can serve the ORDER BY.

#### Cursor shape (PAGE-02)
- **D-09:** `last_primary_key` stays a scalar for single-column keys, so the existing `backfill_test.exs` asserts and adopters' matches keep working. For composite keys it is a keyword list in primary-key order (`[org_id: 1, id: 7]`), the shape `Ecto.primary_key/1` uses.
  - The internal paging cursor (a plain value list) is kept separate from this public value.
  - Don't add a `:cursor` key; that name is reserved for a possible future opaque resume token.
  - — **Reversibility:** costly — once documented, the polymorphic shape is a public contract for 0.3.x and later.
- **D-10:** Give `Scrypath.backfill/2` a `@doc` that formally describes the result map: `index`, `batches`, `documents`, `removed`, `mode`, `batch_results[].{index, documents, removed, last_primary_key, task}`, and the composite cursor shape. Mention the reindex `omitted` count where reindex results are documented.

#### Real-Postgres tests in CI (TEST-06)
- **D-11:** Lane:
  - Add a `postgres:16-alpine` service (with a pg_isready health check, the same image as phoenix-example and ops-ui) to the existing **`backend (required)`** job, and set `SCRYPATH_POSTGRES_URL`.
  - Add a new curated task `verify.postgres`. `Verify.Capability.backend!/1` calls it after `verify.meilisearch_smoke`, and `verify.all` is updated too. The check name doesn't change, so branch protection is untouched.
  - Core stays service-free, as CONTRIBUTING promises.
  - Don't fold the tests into `verify.meilisearch_smoke`, which would misname it.
  - The new task sits with the other `verify.*` tasks that v1.45 plans to move to `dev/mix/tasks`, so v1.45 moves it with them.
- **D-12:** Tagging and local DX:
  - Use a distinct `@moduletag :postgres`, excluded in `test_helper.exs` unless `SCRYPATH_POSTGRES_URL` is set. It is independent of `SCRYPATH_INTEGRATION`, so a contributor with only Meilisearch, or only Postgres, gets no connection errors.
  - `verify.postgres` raises a clear error when the URL is missing, following the `ensure_integration_env!` pattern. A plain `mix test` never fails for lack of Postgres.
  - Use the namespaced env var, not `DATABASE_URL`, which could point at a real dev database. The test DB name is `scrypath_test#{MIX_TEST_PARTITION}`.
  - Add a `postgres` service to the root `compose.yaml` on a free host port (e.g. 5434; 5433 is taken by phoenix-example), and document it in CONTRIBUTING.
- **D-13:** Harness, the ecto_sql/Oban pattern:
  - `{:postgrex, ..., only: :test}` is the only new package; ecto_sql and db_connection are already locked through `ecto_sqlite3`. It must stay `only: :test` so `verify.package` and the optional-deps parity checks are unaffected.
  - A dedicated `Scrypath.TestSupport.PostgresRepo` with `pool: Ecto.Adapters.SQL.Sandbox`.
  - `storage_up` plus `Ecto.Migrator.up(repo, 0, InlineMigration, log: false)` once, then manual sandbox mode with `checkout` per test.
  - Composite keys are declared portably in the migration (`primary_key: false` plus two `primary_key: true` columns).
  - StreamData iterations run inside `Repo.transaction(fn -> ...; Repo.rollback(:reset) end)`, which becomes a savepoint under the sandbox, giving clean state per iteration. `max_runs` stays modest (about 25–50).
- **D-14:** The same shared test module, parameterized by repo, also runs against SQLite in `core (required)`. It uses a new dedicated SQLite repo (tmp-file DB, Sandbox), not the shared `IntegrationRepo` singleton, whose per-file race is documented in `verify.meilisearch_smoke`. This catches Postgres-only SQL leaking into an adapter-agnostic library on every PR without a service. The same inline migration is reused, and Postgres stays the authority on types and collation.

#### Test coverage (success criteria 1–4)
- **D-15:** Required tests:
  - `preload:` parity: backfill and reindex documents equal inline-with-preloaded-records and Oban-loader documents for the same rows.
  - `search_records/2`: every batch is loaded through it, omitted ids are removed (backfill) or omitted (reindex), and the `:query` scope still decides which rows are visited.
  - The composite-key StreamData property:
    - Keys come from a tiny leading domain (e.g. `integer(1..3)`) to force repeated leading values across boundaries, with `batch_size` drawn from `integer(1..12)`.
    - It asserts every row is visited exactly once and `batches == ceil(n / batch_size)`.
    - Each batch's `last_primary_key` equals the max key of that batch, in keyword shape, and cursors strictly increase.
  - A pinned regression: keys `[{1,1},{1,2},{1,3},{2,1}]` with batch size 2. Today's code skips `{1,3}`.
  - Single-column SQL and cursor unchanged.
  - A caller `:query` with `where` plus `offset` (the offset is ignored).
  - A binary_id or string second key column (type casting).

#### Docs and release notes
- **D-16:** Update the guides:
  - `guides/sync-modes-and-visibility.md` and `guides/related-data-and-reindexing.md`: backfill now honors `preload:` and `search_records/2`; omitted ids are removed in scope only; composite keys are supported; declare PK fields in constraint order; `:query` must not fan out.
  - Commits use conventional `fix:` messages, so release-please records a CHANGELOG entry that calls out the behavior change in D-04.

### Claude's Discretion
- Exact names of the new Loader function, the internal reindex flag and the private keyset builder.
- Whether the delete for omitted ids reuses the Oban worker's backend-delete helper or a small shared one, as long as backfill and Oban share the semantics.
- Task module layout for `verify.postgres` and the shared parameterized test module.

### Deferred Ideas (OUT OF SCOPE)
- Postgres row-value `(a, b) > (x, y)` fast path, or a decomposed seek for adopters with very large leading groups (one huge tenant in `(org_id, id)`). Do this only if adopters report slow backfills; D-07 leaves a seam for it.
- A resume-from-cursor backfill option (an opaque `:cursor` token). The name stays free (D-09).
- Routing inline sync through the records-in loader entry point, so caller records get the declared `preload:` too. This is a product decision; it stays out of v1.44 unless it is raised.
- Whole-index pruning of documents whose rows are gone. That stays with reconcile and drift recovery, not backfill.

Also out of phase (from CONTEXT domain): PAGE-03 id-list chunking and FAN-* (Phase 179), OBS-* Oban telemetry (Phase 180), HYG-* hooks / no-Oban build (Phase 181).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (verbatim from `.planning/REQUIREMENTS.md:11-40`) | Research Support |
|----|-------------|------------------|
| LOAD-01 | A backfill or reindex of a schema that declares `preload:` builds documents identical to the ones inline and Oban sync build for the same records. | `Loader.preload_records/3` exists, but it is private and lacks `force: true`. `force: true` refreshes already-loaded assocs (probe below). Backfill currently calls `Projection.document/2` on raw rows (`backfill.ex`, `run_batches`). See Pattern 1. |
| LOAD-02 | A backfill or reindex of a schema that defines `search_records/2` loads every batch through it, and records it leaves out are not indexed. | `Loader.load/3` custom path already returns `{:ok, records, missing}` with `to_string` matching (`loader.ex:87-117`). Reuse it inside `prepare_records/3` and filter out extras (D-03). Delete path: Pattern 4. |
| LOAD-03 | A caller's `:query` scope still selects which rows a backfill visits, while the shared loader builds the documents. | `base_query/3` today strips only `:order_by`/`:limit` (`backfill.ex`). Add `exclude(:offset)`, `exclude(:select)`, `exclude(:preload)`. The probe confirmed `{offset, select, preloads} == {nil, nil, []}` after the strip. |
| PAGE-01 | Composite PK visits every row exactly once, lexicographic keyset on all key columns; property test with repeated leading values across boundaries. | Pattern 2 (`keyset_after/2`). The probe confirmed SQL and parameter typing on SQLite and Postgres 16. The StreamData-in-savepoint pattern was verified (rollback restores row count). |
| PAGE-02 | Batch results report the full cursor for composite keys. | `Ecto.primary_key/1` returns `[org_id: 1, uid: "a7a1…"]` (probe), which is the D-09 keyword shape. Pattern 3. |
| TEST-06 | Loader and backfill (composite + `preload:`) tested against real Postgres in an existing CI lane. | CI `backend` job (`ci.yml:72-105`), `Verify.Capability.backend!/1` (`capability.ex:49-60`), test_helper exclusion, PostgresRepo `init/2` config. See Pattern 5 and Validation Architecture. |
</phase_requirements>

## Project Constraints (from CLAUDE.md / AGENTS.md / CONTRIBUTING.md)

- No `CLAUDE.md` in the repo. `AGENTS.md` is the project instruction file. Directives:
  - Ecto-first, function-heavy API; internal adapter seam only (no public multi-backend facade).
  - Operational clarity: delete semantics and backfill/reindex behavior **must be explicit** (it backs D-04/D-06 doc work).
  - Green-main release train: keep `main` green on the lean required gates; PR-first; **completion backed by executable tests or exact-SHA hosted evidence, never human UAT**.
  - Do not invent work; update `.planning/PROJECT.md` only on intentional scope change.
  - Supported floor Elixir `1.17` / OTP `26`. CI compatibility (advisory) runs 1.17.3/26.2.5 (`ci.yml:115`).
- CONTRIBUTING: `core` is service-free (`CONTRIBUTING.md:161`, "That fast path stays service-free"); required checks are `core`, `package`, `repository-contracts`, `backend` (+ `ecommerce-mounted`). The verify table at `CONTRIBUTING.md:30-41` lists `mix verify.backend` → "Curated live backend smoke (`mix verify.meilisearch_smoke`)", so update that row for Postgres.
- Credo `--strict` runs in `core` over `lib/`, `test/`, `mix.exs` (`.credo.exs:6`). Default `FunctionArity max_arity: 8` and `CyclomaticComplexity max_complexity: 9` apply. Nesting is disabled. [VERIFIED: deps/credo/lib/credo/check/refactor/function_arity.ex:4 `param_defaults: [max_arity: 8, ignore_defp: false]`; cyclomatic_complexity.ex:4 `param_defaults: [max_complexity: 9]`]
- `mix verify` (core) runs `compile --warnings-as-errors`, `test --warnings-as-errors`, `docs --warnings-as-errors` (`lib/mix/tasks/verify.ex:22-34`). New `@doc` text must not link hidden functions.
- No `config/` directory exists in the repo. Repos are configured at runtime (`IntegrationRepo.start_link(database: ..., ...)` in `test/support/meilisearch_integration.ex:147-156`).
- Memory note: the maintainer wants zero human UAT. Every success criterion must be a CI-run assertion.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Row selection (scope, keyset, order, limit) | Library: `Scrypath.Backfill` (Ecto query builder) | Database (index-served ORDER BY) | The caller's `:query` is the selector (D-02). The keyset predicate is portable Ecto (D-07). |
| Document content (preload / `search_records/2`) | Library: `Scrypath.Loader` | Adopter schema callbacks | One loader for Oban and backfill keeps the documents identical (D-01). |
| Projection | Library: `Scrypath.Projection.document/2` | — | Unchanged. |
| Index writes (upsert + delete omitted) | Library: Backfill → backend seam (`Scrypath.Meilisearch.Operations` / `backend.*`) | Meilisearch | Same seam backfill already uses for upsert. |
| Reindex fresh-target behavior | Library: `Scrypath.Reindex` → Backfill internal flag | — | Pass-through key list (`reindex.ex:224-238`). |
| Real-DB proof | Test harness (`test/support/`) + Mix task + CI `backend` job | Docker compose (local) | TEST-06. Core stays service-free. |

## Current Code Facts (read this session)

### `lib/scrypath/backfill.ex` (whole file read)
- Public: `backfill/2` (delegates to `run/2`) and `run/2` (`@spec run(module(), keyword()) :: {:ok, map()} | {:error, term()}`). [VERIFIED: lib/scrypath/backfill.ex]
- `run/2`: `config = Options.validate_backfill_options!(opts)`, then `index = Keyword.get(config, :index_name) || backend.index_name(schema_module, config)`, `primary_key = primary_key(schema_module)`, then `base_query |> run_batches(schema_module, primary_key, batch_size, config, index, 0, [])`.
- `run_batches/8` is **already at Credo's max arity (8)**. Adding `removed` totals or flags as parameters breaks `credo --strict`. Refactor to a state map.
- Cursor today: `cursor = last_primary_key(acc)` reads the **public** `last_primary_key` from the previous batch result. D-09 requires separating the internal value-list cursor from the public value.
- Bug site, verbatim:
  ```elixir
  defp primary_key(schema_module) do
    case schema_module.__schema__(:primary_key) do
      [field | _rest] -> field
      [] -> Scrypath.Schema.Metadata.document_id(schema_module)
    end
  end
  ```
- `base_query/3` verbatim: `(config[:query] || schema_module) |> exclude(:order_by) |> exclude(:limit) |> order_by([record], asc: field(record, ^primary_key))`.
- `batch_query/4`: `nil` cursor → `limit(^batch_size)`; otherwise `where([record], field(record, ^primary_key) > ^cursor) |> limit(^batch_size)`.
- `upsert_documents/5` dispatch: `Scrypath.Meilisearch -> MeilisearchOperations.upsert_documents(schema_module, documents, config)`; `_other -> backend.upsert_documents(schema_module, documents, config)`. `config` has `:index_name` put first.
- `batch_result/4` returns `%{index:, documents:, last_primary_key:, task: public_task(result.task)} |> maybe_drop_nil(:task)`.
- Top-level result: `%{index:, batches: length(acc), documents: total, mode: Keyword.fetch!(config, :sync_mode), batch_results: Enum.reverse(acc)}`.
- **An empty batch is never sent today, but after this phase a batch may have 0 documents** (all omitted). The test `RecordingBackend.upsert_documents` computes `Enum.max_by(documents, & &1.id)` (`test/scrypath/backfill_test.exs:37`), which raises on `[]`. Backfill must skip the upsert call when `documents == []`, the way the Oban worker does (`defp write(_backend, _fun, _schema_module, [], _config), do: :ok`, `upsert_worker.ex:50`).
- No telemetry span wraps backfill. [VERIFIED: grep of `span|Telemetry` in backfill.ex returned nothing.] Per D-05, add no telemetry.

### `lib/scrypath/loader.ex` (whole file read)
- Public: `custom_loader?/1`, `check_loadable/2`, `ensure_loadable!/1`, `load/3` (`@spec load(module(), [term()], keyword()) :: {:ok, [struct()], [term()]} | {:error, term()}`).
- `load/3` (`loader.ex:88-94`): `found = MapSet.new(Identity.document_ids(schema_module, records), &to_string/1)`; `missing = Enum.reject(document_ids, &MapSet.member?(found, to_string(&1)))`.
- `fetch/3` custom path (`loader.ex:101-105`): `schema_module.search_records(document_ids, %{repo: repo})` → `records when is_list(records) -> {:ok, records}`; `other -> {:error, {:invalid_search_records, other}}`.
- Private preload (`loader.ex:119-121`), verbatim:
  ```elixir
  defp preload_records(_repo, records, preload) when preload in [nil, []], do: records
  defp preload_records(_repo, [], _preload), do: []
  defp preload_records(repo, records, preload), do: repo.preload(records, preload)
  ```
  D-01 wants `force: true`. The `[]`-preload short-circuit matters. Neither `FakeRepo` (`test/support/fake_repo.ex`) nor `BackfillRepo` defines `preload/2,3`, so the default path must keep skipping `repo.preload` when the schema declares no preload, or every FakeRepo test breaks.
- `Scrypath.Loader` is a **documented public module** (it has a `@moduledoc`). Make the new function `@doc false` unless you intend it to be public. Do not link it from `Scrypath.backfill/2`'s `@doc`; ExDoc warns on hidden refs, and `docs --warnings-as-errors` runs in core.

### `lib/scrypath/oban/upsert_worker.ex` (whole file read)
- The whole module is wrapped in `if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do`, and `write/5` is private and calls `IndexingAck.await(...)`. **The worker's delete helper cannot be reused from Backfill.** It doesn't exist without Oban (an optional dep), and it blocks on acks that backfill doesn't do in `:manual` mode. Use a small private `delete_documents/5` in Backfill that mirrors its own `upsert_documents/5` dispatch. Semantics are shared: the same ids that `Loader` reports missing go to `delete_documents` on the same index.
- Oban order: upsert the found documents, then delete the missing ids (`with :ok <- write(... :upsert_documents ...) do write(... :delete_documents, ..., missing_ids, ...)`). Backfill does the same per batch.

### `lib/scrypath/reindex.ex` (whole file read)
- Backfill injection: `backfill = Keyword.get(opts, :backfill, Scrypath.Backfill)`. Call: `backfill.run(schema_module, workflow_config |> backfill_config() |> Keyword.put(:index_name, target_index))`.
- Existing internal-key convention: `|> Keyword.put(:_scrypath_schema, schema_module)` (`reindex.ex:33`). Name the new flag in the same style, e.g. `:_scrypath_fresh_target`.
- `@backfill_pass_through_keys` (`reindex.ex:224-238`), verbatim: `[:backend, :repo, :batch_size, :query, :index_prefix, :index_name, :meilisearch_url, :meilisearch_api_key, :meilisearch_client, :req_options, :inline_poll_interval, :inline_timeout, :sync_mode]`. Note that `:query` passes through (`Options.validate_reindex_options!` has no `:query` key, so reindex callers can't set it today. Leave that unchanged).
- Result map (`reindex.ex:52-60`): `%{live_index:, target_index:, settings_applied: true, batches: Map.fetch!(backfill_result, :batches), documents: Map.fetch!(backfill_result, :documents), cutover:}`. Add `omitted:` with `Map.get(backfill_result, :omitted, 0)`. The test stub `RecordingBackfill` (`test/scrypath/reindex_test.exs:295-350`) returns no omitted/removed key, so `Map.fetch!` would break 6+ reindex tests.
- `maybe_wait_for_backfill_tasks/2`: for each batch result, `followable_task(%{task: task}) when is_map(task)` → `Operations.task_from_backend(task, source: :meilisearch)` → `Tasks.wait_for_task` over HTTP. **In a real-DB reindex test, the recording backend must return `task: nil`** so `batch_result` drops `:task`. Otherwise reindex tries to reach Meilisearch.
- Settings verification (`maybe_verify_settings/3`) calls `Settings.verify_applied` directly; nothing is injectable. A real-DB reindex test must pass `skip_settings_verification?: true` (it logs a warning, so wrap the call in `ExUnit.CaptureLog`) plus `meilisearch: StubMeilisearch` returning task-less maps (the shape of `RecordingMeilisearch` in `reindex_test.exs:89-149`, minus tasks).
- **Latent composite bug, outside the locked decisions:** `reindex.ex:244-249` duplicates the first-column-only `primary_key/1` and passes it as the **Meilisearch index primaryKey** to `create_index` (`reindex.ex:36`). Documents are sent with the id under `Metadata.document_id(schema)` (`meilisearch/operations.ex:16-22`, `client.ex:197-198` `Map.put(data, document_id_field, id)`). For a composite schema `(org_id, id)`, the target index is created with `primaryKey: "org_id"`, so a live reindex would collapse rows or fail. See Open Question 1.

### `lib/scrypath/options.ex`
- `@backfill_options` (`options.ex:231-296`) keys: `backend` (required), `repo` (required), `batch_size` (required), `query` (`type: :any, default: nil`), `index_prefix`, `index_name`, `meilisearch_url`, `meilisearch_api_key`, `meilisearch_client`, `req_options`, `inline_poll_interval` (default `100`), `inline_timeout` (default `5_000`), `sync_mode` (`type: {:in, [:inline, :manual, :oban]}, default: :manual`). [VERIFIED: lib/scrypath/options.ex:231-296]
- `validate_backfill_options!/1` = `validate!(@backfill_options) |> validate_bulk_sync_mode!()`. `validate!/2` calls `NimbleOptions.validate(opts, schema)` and raises `ArgumentError` on unknown keys. **An unlisted internal flag raises.** It must be added to `@backfill_options`.
- No `NimbleOptions.docs/1` call exists anywhere in `lib/` (grep), so option `doc:` strings are not rendered into HexDocs. Add the flag with `type: :boolean, default: false, doc: false`. NimbleOptions 1.1.1 is locked (`mix.lock:27`) and supports `doc: false` to hide a key. [CITED: hexdocs.pm/nimble_options — `:doc` "set to false to hide"] [ASSUMED that this behavior is unchanged in 1.1.1; it is irrelevant here because docs are never generated from this schema.]

### `lib/scrypath/identity.ex`, `schema/metadata.ex`, `projection.ex`
- `Identity.document_ids/2` = `Enum.map(source_records, &document_id(schema_module, &1))`. It uses `search_document_id/1` when exported, otherwise `Metadata.document_id` field.
- The `document_id` option default is `:id` (`options.ex:31-35`: `type: :atom, default: :id`). `preload` option: `type: :any, default: []`.
- `Projection.build_field_document/2` takes `Document.id` from the `Metadata.document_id` field, **not** `search_document_id/1`. `build_custom_document/2` takes `:id`/`"id"` from `search_document/1` output, falling back to the field. **A composite-key test schema therefore needs a unique document id:** either `search_document/1` returning `id: "#{org_id}:#{id}"` together with a matching `search_document_id/1`, or `document_id:` pointing at a unique column. The first also exercises the D-01 regression guard (schemas with `search_document_id/1` and no `search_records/2` must still backfill).

### Public API (`lib/scrypath.ex:375-383`)
- `backfill/2` and `reindex/2` have `@spec` but **no `@doc`**. D-10 adds one for backfill. README documents the reindex result keys (`README.md:154-167`: `result.live_index … result.cutover`). Add `result.omitted` there (README is pinned by `docs_contract_test.exs`, so run it).

### Other Backfill callers
- `Scrypath.Operator.RecoveryAction.retry/2` for `kind: :backfill` calls `Backfill.backfill(action.schema, opts)` (`operator/recovery_action.ex:33-36`). It inherits the new delete behavior automatically. No change is needed, but the D-04 CHANGELOG note should cover operator-triggered backfills too.
- `scrypath_ops` calls only `Scrypath.Loader.load/3` (`sync_drift_live.ex:1119`). It is unaffected as long as `load/3` keeps its signature and semantics.

## Standard Stack

### Core (already locked; no change)
| Library | Version (mix.lock) | Purpose |
|---------|---------|---------|
| ecto | 3.14.0 | `dynamic/2`, `field/2`, `exclude/2`, `Ecto.primary_key/1` |
| ecto_sql | 3.14.0 (test, via ecto_sqlite3 + oban) | Sandbox, Migrator, `Ecto.Adapters.SQL.to_sql/3` |
| ecto_sqlite3 | 0.24.0 (`only: :test, runtime: false`) | SQLite repo for core-lane run of the shared cases |
| stream_data | 1.3.0 (`only: :test`) | Composite-key property (`use ExUnitProperties`, already used in `test/scrypath/runtime_safety_property_test.exs`) |
| nimble_options | 1.1.1 | Backfill option schema |
| db_connection | 2.10.1 | Satisfies postgrex `~> 2.9` |

[VERIFIED: mix.lock lines 6, 11, 12, 13, 27, 35]

### New (test-only)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| postgrex | `~> 0.22` (latest stable 0.22.4, published 2026-08-07) | Postgres driver for `PostgresRepo` | Official elixir-ecto driver. ecto_sql 3.14 declares `{:postgrex, "~> 0.19 or ~> 1.0", optional: true}` and Oban 2.23 `{:postgrex, "~> 0.20", optional: true}` (mix.lock:12, 30). |

**Installation (mix.exs deps):**
```elixir
{:postgrex, "~> 0.22", only: :test, runtime: false},
```
`runtime: false` mirrors `ecto_sqlite3`. The Ecto SQL adapter starts the driver app when the repo starts (`Ecto.Adapters.SQL` `ensure_all_started`). [ASSUMED for postgrex specifically; this is the same mechanism the existing `ecto_sqlite3 runtime: false` IntegrationRepo relies on today.] Dropping `runtime: false` is also fine. Then run `mix deps.get`. That should add only a `"postgrex"` entry to `mix.lock`: its requirements `db_connection ~> 2.9`, `decimal ~> 1.5 or ~> 2.0 or ~> 3.0`, and optional `jason`/`table` are already satisfied or optional. [VERIFIED: hex.pm API /packages/postgrex/releases/0.22.4 requirements; `elixir: "~> 1.15"` meets the 1.17 floor]

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `__using__` case template for shared DB tests | ExUnit `parameterize:` | `parameterize` is absent in Elixir 1.17.3 and present in 1.18.4 [VERIFIED: grep count 0 vs 15 in each installed `ex_unit/case.ex`]. The 1.17 compatibility lane would break. |
| Hand-rolled `keyset_after` | paginator / quarto | Locked out by D-07. |

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| postgrex | Hex | ~10 yrs (first releases 2016) | 142,628,258 all-time | github.com/elixir-ecto/postgrex | OK (manual) | Approved |

- The `gsd-tools package-legitimacy check` seam supports only `npm|pypi|crates` (it returned a usage error for `hex`). I checked the Hex API manually instead. The latest stable is 0.22.4. The only retirements are the 2016 mis-tagged `1.0.0-rc.0/rc.1` ("Superseded by v0.13.0-rc.0"), and the `~> 0.22` requirement excludes them. The package comes from the elixir-ecto org, and the official ecto_sql and Oban packages declare it as their optional driver. Hex has no postinstall scripts (Mix compile only). [VERIFIED: hex.pm/api/packages/postgrex]
- **Packages removed due to [SLOP]:** none. **Flagged [SUS]:** none.
- `scripts/ci/dependency_audit.ex` (advisory deep-quality) runs `mix hex.audit`. It has no package allowlist (grep), so a new non-retired dep passes.

## Architecture Patterns

### System Architecture Diagram

```
Scrypath.backfill/2 ──┐                    Scrypath.reindex/2
RecoveryAction.retry ─┤                        │ create target idx, settings
                      ▼                        │ backfill_config + index_name + _scrypath_fresh_target: true
            Options.validate_backfill_options! ◄┘
                      │
                      ▼
   base_query: caller :query (where/join kept) − order_by/limit/offset/select/preload
               + order_by asc on every PK col (constraint order)
                      │
      ┌──────────── loop (state map: cursor values, totals, acc) ────────────┐
      │  batch query = base + keyset_after(pk_cols, cursor) + limit ^batch    │
      │        │ repo.all                                                     │
      │        ▼                                                              │
      │  rows == [] ? ──yes──► return result (batches, documents, removed/omitted)
      │        │ no                                                           │
      │  dedupe by key tuple (uniq_by); cursor := key values of LAST row      │
      │        ▼                                                              │
      │  Loader.prepare_records(schema, rows, config)                         │
      │     ├ no search_records/2 → repo.preload(rows, preload, force: true)  │
      │     │                       (skip when preload == [])  omitted = []   │
      │     └ search_records/2   → load(schema, doc_ids(rows)) → drop extras  │
      │                             omitted = missing ids                     │
      │        ▼                                                              │
      │  Projection.document/2 per record                                     │
      │        ▼                                                              │
      │  docs != [] → backend upsert (Meilisearch.Operations | backend)       │
      │  omitted != [] and not fresh_target → backend delete (same index)     │
      │        ▼                                                              │
      │  batch_result %{index, documents, removed, last_primary_key, task?}  │
      └───────────────────────────────────────────────────────────────────────┘
```

### Recommended file layout
```
lib/scrypath/backfill.ex            # state-map loop, keyset_after/2, delete dispatch, cursor shaping
lib/scrypath/loader.ex              # + prepare_records/3 (@doc false); preload_records gains force: true
lib/scrypath/reindex.ex             # pass fresh-target flag; result gains omitted:
lib/scrypath/options.ex             # @backfill_options + internal flag (doc: false)
lib/scrypath.ex                     # @doc for backfill/2 (result contract)
lib/mix/tasks/verify.postgres.ex    # new curated task (sits beside verify.meilisearch_smoke.ex)
lib/mix/tasks/verify/capability.ex  # backend!/1 → verify.meilisearch_smoke then verify.postgres
lib/mix/tasks/verify.all.ex         # add postgres step
mix.exs                             # postgrex dep + "verify.postgres": :test preferred env
test/support/postgres_repo.ex       # Scrypath.TestSupport.PostgresRepo (init/2 reads env)
test/support/sqlite_sandbox_repo.ex # Scrypath.TestSupport.SQLiteSandboxRepo
test/support/loader_backfill_migration.ex  # inline Ecto.Migration (shared)
test/support/loader_backfill_schemas.ex    # composite, preload, search_records schemas
test/support/loader_backfill_cases.ex      # defmacro __using__(repo:, setup:) – the shared tests
test/scrypath/loader_backfill_sqlite_test.exs    # use cases with SQLite (core lane)
test/scrypath/loader_backfill_postgres_test.exs  # @moduletag :postgres, use cases with PostgresRepo
test/test_helper.exs                # compose exclude list incl. :postgres
.github/workflows/ci.yml            # backend job: postgres service + SCRYPATH_POSTGRES_URL
compose.yaml, CONTRIBUTING.md, guides/*.md, README.md
```
Every `test/support/**/*.ex` is loaded with `Code.require_file` from `test_helper.exs:9-11`, and `mix.exs` `support_file?/1` keeps Mix 1.19 from treating them as tests.

### Pattern 1: Records-in loader entry point
```elixir
# lib/scrypath/loader.ex
@doc false
@spec prepare_records(module(), [struct()], keyword()) ::
        {:ok, [struct()], [term()]} | {:error, term()}
def prepare_records(_schema_module, [], _config), do: {:ok, [], []}

def prepare_records(schema_module, rows, config) do
  if custom_loader?(schema_module) do
    ids = Identity.document_ids(schema_module, rows)
    allowed = MapSet.new(ids, &to_string/1)

    with {:ok, records, missing} <- load(schema_module, ids, config) do
      # D-03: ignore records search_records/2 returned for ids outside this batch
      in_scope =
        Enum.filter(records, fn record ->
          MapSet.member?(allowed, to_string(Identity.document_id(schema_module, record)))
        end)

      {:ok, in_scope, missing}
    end
  else
    repo = Keyword.fetch!(config, :repo)
    {:ok, preload_records(repo, rows, Metadata.preload(schema_module)), []}
  end
end

defp preload_records(_repo, records, preload) when preload in [nil, []], do: records
defp preload_records(_repo, [], _preload), do: []
defp preload_records(repo, records, preload), do: repo.preload(records, preload, force: true)
```
- `force: true` matters. A probe on ecto 3.14 / SQLite preloaded `:cat`, updated the row, and re-preloaded: without force the stale `"a"` came back, and with `force: true` the result was `"changed"`. [VERIFIED: probe2 output `no force: "a"` / `force: "changed"`] Rows from `repo.all` have no loaded assocs, so `force` changes nothing for backfill. It matters for Oban's `load/3` sharing the helper and for callers' structs.
- Applying `force: true` to `load/3`'s shared helper changes Oban behavior only for already-loaded assocs, and `load/3` always loads fresh rows. Safe.

### Pattern 2: `keyset_after/2` (D-07)
```elixir
# lib/scrypath/backfill.ex (private)
defp keyset_after(query, _pairs = nil), do: query
defp keyset_after(query, pairs), do: where(query, ^keyset_predicate(pairs))

# single column: exactly today's `a > ^x`
defp keyset_predicate([{col, v}]), do: dynamic([r], field(r, ^col) > ^v)

# composite: redundant leading bound + OR-expansion
defp keyset_predicate([{col, v} | _] = pairs),
  do: dynamic([r], field(r, ^col) >= ^v and ^expand(pairs))

defp expand([{col, v}]), do: dynamic([r], field(r, ^col) > ^v)

defp expand([{col, v} | rest]),
  do: dynamic([r], field(r, ^col) > ^v or (field(r, ^col) == ^v and ^expand(rest)))

defp order_by_key(query, cols), do: order_by(query, ^Enum.map(cols, &{:asc, &1}))
```
Verified output (probe):
- Single column: where expr `{:>, [], [{{:., [], [{:&, [], [0]}, :id]}, [], []}, {:^, [], [0]}]}`, params `[{5, {0, :id}}]`. That is the AST shape `BackfillRepo.evaluate/3` (`backfill_test.exs:99-101`) already matches, so the existing tests keep passing.
- Composite on SQLite: `WHERE ((m0."org_id" >= ?) AND ((m0."org_id" > ?) OR ((m0."org_id" = ?) AND (m0."uid" > ?)))) ORDER BY m0."org_id", m0."uid" LIMIT ?`, which returned 2 rows after the first of 3 (correct).
- Composite on Postgres 16 + postgrex 0.22.4: same shape. The `binary_id` param was dumped as `<<46, 143, …>>` (16 bytes), so typing holds. Result 2 (correct). [VERIFIED: probe_pg output]
- The parameter count is N(N+1)/2 + 1 per query (3 columns gives 6 cursor params plus limit). That's fine.
- `dynamic([r], …)` binds position 0, the root source, even when the caller's `:query` has joins. That's correct for PK columns.
- `order_by(^[asc: :org_id, asc: :uid])` produces **one** `ByExpr` with two entries. `BackfillRepo.order_records/2` matches only a single `[asc: field]`, so composite tests must use the real repos (planned).

### Pattern 3: Cursor shaping (D-08/D-09)
```elixir
cols = pk_columns(schema_module)        # __schema__(:primary_key), or [document_id] fallback
last = List.last(rows)
values = Enum.map(cols, fn col ->
  case Map.fetch!(last, col) do
    nil -> raise ArgumentError, "backfill cursor column #{inspect(col)} is nil ..."
    v -> v
  end
end)
public_cursor = case cols do
  [_single] -> hd(values)                # scalar: existing asserts stay green
  _ -> Enum.zip(cols, values)            # [org_id: 1, id: 7], Ecto.primary_key/1 shape
end
# next batch uses Enum.zip(cols, values) pairs for keyset_after; never sort in Elixir
```
- `Ecto.primary_key(struct)` returned `[org_id: 1, uid: "a7a100ac-…"]` in the probe, which is the keyword shape D-09 names. [VERIFIED: probe2]
- With no primary key, the `document_id` fallback must add `where([r], not is_nil(field(r, ^col)))` (D-08).
- Dedupe within a batch: `Enum.uniq_by(rows, fn r -> Enum.map(cols, &Map.fetch!(r, &1)) end)`. Take the cursor from the last row; dedupe doesn't change which row is last.

### Pattern 4: Batch step with omitted-id deletes
```elixir
with {:ok, records, omitted} <- Loader.prepare_records(schema, rows, config),
     documents = Enum.map(records, &Projection.document(schema, &1)),
     {:ok, upsert} <- maybe_upsert(schema, documents, backend, config, index),   # skip when []
     {:ok, removed} <- maybe_delete(schema, omitted, backend, config, index) do  # skip when [] or fresh target
  ...
end

defp delete_documents(schema, ids, backend, config, index) do
  config = Keyword.put(config, :index_name, index)
  case backend do
    Scrypath.Meilisearch -> MeilisearchOperations.delete_documents(schema, ids, config)
    _other -> backend.delete_documents(schema, ids, config)
  end
end
```
- `MeilisearchOperations.delete_documents/3` exists, `@spec delete_documents(module(), [term()], keyword()) :: {:ok, Result.t()} | {:error, term()}`, and posts to `/indexes/#{index}/documents/delete-batch`. [VERIFIED: lib/scrypath/meilisearch/operations.ex:37-53, client.ex:70-74]
- Meilisearch processes tasks per index in enqueue order, so upsert-then-delete in the same batch is safe. Deleted ids and upserted ids don't overlap anyway. [ASSUMED: Meilisearch FIFO task queue per index; well-known, not re-checked this session]
- When a batch upserts nothing (everything omitted), there's no upsert task. `batch_result` drops `:task` via `maybe_drop_nil/2`, and reindex's waiter skips it.
- Reporting (D-05): per batch `removed: length(omitted)` when deleted, `0` under the fresh-target flag. Top-level `removed:` is the sum. Also accumulate the omitted count and expose it as top-level `omitted:` only when the fresh-target flag is set, so Reindex can read `Map.get(backfill_result, :omitted, 0)`. Keep `removed:` present (as 0) in that case too, so the backfill contract stays uniform.

### Pattern 5: Real-DB harness (D-13/D-14)
```elixir
# test/support/postgres_repo.ex
defmodule Scrypath.TestSupport.PostgresRepo do
  @moduledoc false
  use Ecto.Repo, otp_app: :scrypath, adapter: Ecto.Adapters.Postgres

  @impl true
  def init(_type, config) do
    url = System.fetch_env!("SCRYPATH_POSTGRES_URL")
    db = "scrypath_test#{System.get_env("MIX_TEST_PARTITION")}"

    {:ok,
     config
     |> Keyword.merge(Ecto.Repo.Supervisor.parse_url(url))
     |> Keyword.merge(database: db, pool: Ecto.Adapters.SQL.Sandbox, pool_size: 10)}
  end
end
```
- `Repo.config/0` calls `init(:runtime, …)` (`deps/ecto/lib/ecto/repo/supervisor.ex:27-48`, `repo_init(type, repo, config)`). `:url` is then popped and **merged over** the config (`{:ok, Keyword.merge(config, url_config)}`), so a `database:` set alongside `url:` would lose to the URL's path. Parse the URL yourself inside `init/2` and set `database:` afterwards, as above. `Ecto.Repo.Supervisor.parse_url/1` is public (`@doc`, supervisor.ex:99-109). [VERIFIED: deps/ecto/lib/ecto/repo/supervisor.ex:24-48, 99-109] The postgrex module name `Ecto.Adapters.Postgres` is in ecto_sql (probe used it).
- One-time setup in the case template's `setup_all`:
  ```elixir
  repo.__adapter__().storage_down(repo.config())   # fresh schema every run (see Pitfall 3)
  :ok = repo.__adapter__().storage_up(repo.config())
  start_supervised!(repo)                          # or {:ok, _} = repo.start_link()
  :ok = Ecto.Migrator.up(repo, 0, Scrypath.TestSupport.LoaderBackfillMigration, log: false) |> normalize
  Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)
  ```
  per test: `:ok = Ecto.Adapters.SQL.Sandbox.checkout(repo)`.
  [VERIFIED: probe_pg: `storage_up: :ok`, `migrate: :ok`, rows inserted after `checkout`] `Migrator.up` returns `:ok` the first time and `:already_up` after.
- Portable composite migration (verified on SQLite and Postgres):
  ```elixir
  create table(:lb_memberships, primary_key: false) do
    add :org_id, :integer, primary_key: true
    add :uid, :binary_id, primary_key: true
    ...
  end
  ```
  Schema: `@primary_key false` with `field :org_id, :integer, primary_key: true` and `field :uid, :binary_id, primary_key: true`.
- StreamData per-iteration isolation:
  ```elixir
  check all keys <- uniq_list_of({integer(1..3), integer(1..20)}, max_length: 30),
            batch_size <- integer(1..12), max_runs: 40 do
    repo.transaction(fn ->
      ... insert_all, run backfill, assert ...
      repo.rollback(:reset)
    end)
  end
  ```
  Probe: inside the sandbox, `transaction(fn -> delete_all; rollback(:reset) end)` returned `{:error, :reset}`, and the row count afterwards was back to 3 on **both** SQLite and Postgres. [VERIFIED: probe2/probe_pg `after rollback: {{:error, :reset}, 3}`] Assertion failures raised inside `transaction` still propagate, because ExUnit's `ExUnit.AssertionError` exception escapes and the transaction rolls back.
- SQLite repo: same shape with `database: Path.join(System.tmp_dir!(), "scrypath-lb-#{System.os_time()}-#{System.unique_integer([:positive])}.db")`, `pool: Ecto.Adapters.SQL.Sandbox`, `pool_size: 2` or more. Remove the file in `on_exit`.
- Shared cases: `defmacro __using__(opts)` in `test/support/loader_backfill_cases.ex` expands to `setup_all`/`setup`/`test`/`property` blocks referencing `unquote(opts[:repo])`. The SQLite file: `use ExUnit.Case, async: false` + `use ExUnitProperties` + `use Scrypath.TestSupport.LoaderBackfillCases, repo: SQLiteSandboxRepo`. The Postgres file adds `@moduletag :postgres`. Use `async: false`: the tests are DB-bound, and it avoids any SQLite writer contention with other modules. Each module has a dedicated repo, so `async: true` would also be safe within one module.

### Pattern 6: Parity assertions (success criterion 1)
- Inline document: `Scrypath.sync_records(schema, repo.preload(records, preload), backend: RecordingBackend, sync_mode: :manual, repo: repo)`, capturing the documents the recording backend receives. Alternatively, call `Projection.document/2` on preloaded records directly. Inline sync projects caller records unchanged (`sync.ex` `sync_records/3` → `dispatch_upsert`).
- Oban-loader document: `{:ok, records, []} = Scrypath.Loader.load(schema, ids, repo: repo)` then `Enum.map(records, &Projection.document(schema, &1))`. No Oban runtime is needed; this is the exact code path `UpsertWorker.perform/1` runs (`upsert_worker.ex:23-25`).
- Backfill/reindex documents: captured from a recording backend whose `upsert_documents/3` sends `{:upsert_documents, schema, docs, config}` to `self()` and returns `{:ok, Result.new(..., task: nil)}`.
- Compare with `assert Enum.sort_by(backfill_docs, & &1.id) == Enum.sort_by(oban_docs, & &1.id)`. Ids here are integers or strings, so Elixir sort is fine for test comparison. Don't sort UUIDs to *derive cursor expectations*; use DB order for that.

### Anti-Patterns to Avoid
- **Adding parameters to `run_batches/8`.** Credo `--strict` (max_arity 8) fails core. Carry a state map.
- **Reusing `UpsertWorker.write/5`.** It's private, Oban-conditional, and ack-blocking.
- **Deriving the next cursor from `search_records/2` output.** It violates D-03 and can loop forever or end early.
- **`distinct: true` to fix fan-out.** Rejected by D-08. Dedupe in Elixir and document the constraint.
- **Linking the `@doc false` loader function from public docs.** ExDoc `--warnings-as-errors` fails core.
- **Putting `verify.postgres` tests under `@moduletag :integration`.** That couples them to `SCRYPATH_INTEGRATION`, which D-12 forbids.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Missing-id computation for `search_records/2` | New diff logic | `Loader.load/3` (already does `to_string` matching) | Keeps Oban and backfill semantics identical |
| URL → repo opts | A regex/URI parser | `Ecto.Repo.Supervisor.parse_url/1` | Handles ssl and query params, same as Ecto |
| DB create/migrate | Raw `CREATE TABLE` SQL (as `MeilisearchIntegration.create_tables!/0` does) | `storage_up` + `Ecto.Migrator.up/4` with an inline migration | Portable DDL for SQLite and Postgres, plus composite PK support |
| Per-iteration DB reset | `DELETE FROM` loops | `repo.transaction(fn -> …; repo.rollback(:reset) end)` under the sandbox | Verified savepoint rollback |
| Composite cursor shape | A custom struct | Keyword list (the `Ecto.primary_key/1` shape) | D-09 |

## Common Pitfalls

### Pitfall 1: Migrator deadlock or raise with a Sandbox pool of 1
**What goes wrong:** `Ecto.Migrator.up/4` with `pool: Sandbox, pool_size: 1`. SQLite failed with `DBConnection.ConnectionError … connection not available and request was dropped from queue after 5988ms` (from `Ecto.Migrator.run_maybe_in_transaction/5`). Postgres raises `Ecto.Adapters.SQL.raise_migration_pool_size_error/0` ("pool_size: 2 # at least") from `lock_for_migrations/3`. [VERIFIED: both probes]
**How to avoid:** Use `pool_size: 10` for Postgres and `2` or more for SQLite. Run the migration before `Sandbox.mode(repo, :manual)`.

### Pitfall 2: The `test_helper.exs` exclude list is set once, and wholesale
**What goes wrong:** `mix test` loads the helper with `Code.require_file` (`elixir 1.19.0 lib/mix/lib/mix/tasks/test.ex:1046-1050`). When `verify.backend` runs several `Mix.Task.run("test", …)` calls in one VM, the helper is evaluated **only on the first run**. Also, `ExUnit.configure(exclude: …)` replaces the list rather than appending. Today's helper calls it only when `SCRYPATH_INTEGRATION` is unset (`test_helper.exs:1-5`). A naive second `ExUnit.configure(exclude: [:postgres])` would drop `:integration`.
**How to avoid:** Compute one list:
```elixir
integration? = System.get_env("SCRYPATH_INTEGRATION") in ["1", "true", "TRUE"]
postgres? = System.get_env("SCRYPATH_POSTGRES_URL") not in [nil, ""]
exclude =
  if(integration?, do: [], else: [:integration, :requires_clean_workspace]) ++
    if(postgres?, do: [], else: [:postgres])
ExUnit.configure(exclude: exclude)
```
and have `verify.postgres` always pass `["--include", "postgres", path]`. Mix applies CLI options after the helper ("Configure ExUnit now and then again so the task options override test_helper.exs", test.ex:633). Note the `backend` CI job sets `SCRYPATH_INTEGRATION: "1"` at job level (`ci.yml:80-82`).

### Pitfall 3: Tmp DB name collisions and a stale migrated schema
**What goes wrong:** `System.unique_integer([:positive])` restarts low in each fresh VM. Re-running the probe found the "unique" SQLite file existing (`storage_up: {:error, :already_up}`, `migrate: :already_up`). On a persistent local Postgres, `Migrator.up(…, 0, …)` returns `:already_up` even after the inline migration changed, leaving old tables. [VERIFIED: probe re-runs] `MeilisearchIntegration.repo_database_path/0` has this same weakness.
**How to avoid:** Include `System.os_time()` (or `:erlang.unique_integer` plus the OS pid) in the SQLite path and `File.rm` it on exit. For Postgres, `storage_down` then `storage_up` in `setup_all`. The DB is namespaced (`scrypath_test<partition>`), so dropping it is safe. Don't use `DATABASE_URL`.

### Pitfall 4: Fake repos lack `preload` and composite ordering
**What goes wrong:** `FakeRepo` and `BackfillRepo` implement only `all/1`. `BackfillRepo` evaluates only `==`/`>` with a single `asc` order (`backfill_test.exs:95-121`).
**How to avoid:** Keep the `preload in [nil, []]` short-circuit. Keep single-column SQL byte-identical (verified AST). Put all composite, preload, and search_records DB assertions in the shared real-DB cases. The existing `backfill_test.exs` asserts (`last_primary_key: 2/4/5`, `length(second_query.wheres) == 1`, `first_query.wheres == []`) must stay green. The single-column path adds no extra `where` for `not is_nil` (only the no-PK fallback does).

### Pitfall 5: An empty documents list sent to the backend
**What goes wrong:** All-omitted batches call `upsert_documents([])`. The test RecordingBackend raises `Enum.EmptyError` (`Enum.max_by` at `backfill_test.exs:37`), and Meilisearch receives a pointless task.
**How to avoid:** Skip the upsert when `documents == []`, and skip the delete when `omitted == []`.

### Pitfall 6: Reindex test against a real DB tries to reach Meilisearch
**What goes wrong:** Any batch `task` map, or a `create_index`/`apply_settings` result with an `%Operations.Task{source: :meilisearch}`, triggers `Tasks.wait_for_task` HTTP polling. Settings verification always calls `Settings.verify_applied`.
**How to avoid:** Use a stub `meilisearch:` module returning `{:ok, %{}}`-style maps without `:task`, pass `skip_settings_verification?: true` inside `capture_log`, and use a recording backend returning `task: nil`.

### Pitfall 7: The reindex Meilisearch primary key for composite schemas (see Open Question 1)
The recording-backend tests can't catch this. Only a live Meilisearch reindex of a composite schema would.

### Pitfall 8: CI and contract tests that pin wiring
- `test/mix/tasks/verify_capability_test.exs:24-29` requires `verify.backend` to reject stray args with `~r/accepts only --skip-integration/`. Keep the parser, and pass `--skip-integration` through to `verify.postgres` as well (skip both live services).
- `verify_capability_test.exs:64-69` checks `preferred_envs` for canonical tasks. Add `"verify.postgres": :test` to `mix.exs` `cli/0` `preferred_envs` (the list at `mix.exs:47-103`).
- `test/mix/tasks/workflow_wiring_test.exs` (repository-contracts lane) pins ci.yml job blocks via `workflow_job_block/2`. It has an ops-ui Postgres assertion pattern at lines 382-390 (`"image: postgres:16-alpine"`, `"POSTGRES_USER: postgres"`, `"pg_isready -U postgres"`). Add a mirrored assertion for the `backend` block (`postgres:16-alpine`, `SCRYPATH_POSTGRES_URL`, `pg_isready`). That turns TEST-06 wiring into a CI-enforced contract.
- `workflow_wiring_test.exs:236` requires `CONTRIBUTING.md` to contain `**\`backend\`**`. Edit that row's text, but keep the bold token.
- Guides are pinned by `docs_contract_test.exs` (sync-modes at :54/:283/:463/:476, related-data at :58/:253/:284), `phase108_contract_test.exs:6`, `phase112_contract_test.exs`, `telemetry_test.exs:293`, and `test/release/package_metadata_test.exs:92`. Run them after guide edits. `docs_contract` is excluded in the core CI command (`ci.yml:35`), so run it explicitly with `mix test --include docs_contract test/scrypath/docs_contract_test.exs`.

### Pitfall 9: The Mix task lives in `lib/`, so it ships in the Hex package
`package files:` includes `lib` (`mix.exs:270-271`). `verify.postgres.ex` must not reference test-only modules (`Postgrex`, `PostgresRepo`) at compile time. It only shells into `Mix.Task.run("test", …)` like `verify.meilisearch_smoke.ex`, which is safe. `verify.no_optional_deps` compiles with `--no-optional-deps` in `MIX_ENV=test`. postgrex is a non-optional test dep, so it's unaffected.

### Pitfall 10: Dirty cache keys
Every CI job's cache key hashes `mix.lock` and `mix.exs` (`ci.yml:33` etc.), so adding postgrex triggers a full dep rebuild on the PR. That's expected; it is not a failure.

## Code Examples

### `verify.postgres` task (mirrors `verify.meilisearch_smoke.ex`)
```elixir
defmodule Mix.Tasks.Verify.Postgres do
  use Mix.Task
  @shortdoc "Runs loader/backfill tests against a real Postgres (curated list)"
  @moduledoc """
  Runs the `@moduletag :postgres` loader and backfill suites against Postgres.

  ## Environment
  - `SCRYPATH_POSTGRES_URL` — required unless `--skip-integration`
    (e.g. `postgres://postgres:postgres@127.0.0.1:5434`). The database
    `scrypath_test<MIX_TEST_PARTITION>` is dropped and recreated.
  """
  @postgres_tests ["test/scrypath/loader_backfill_postgres_test.exs"]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    {opts, _argv, _invalid} = OptionParser.parse(args, strict: [skip_integration: :boolean])

    if opts[:skip_integration] do
      Mix.shell().info("==> Skipping Postgres loader suite (--skip-integration)")
    else
      ensure_postgres_env!()
      for path <- @postgres_tests do
        Mix.Task.reenable("test")
        Mix.Task.run("test", ["--include", "postgres", path])
      end
    end
  end

  defp ensure_postgres_env! do
    if System.get_env("SCRYPATH_POSTGRES_URL") in [nil, ""] do
      Mix.raise("""
      SCRYPATH_POSTGRES_URL is required for Postgres loader verification.

        docker compose up -d postgres
        SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres
      """)
    end
  end
end
```
In `Capability.backend!/1`, after the existing `run_task!("verify.meilisearch_smoke", …)`, add `run_task!("verify.postgres", same_args)`. `run_task!/2` already re-enables tasks (`capability.ex:138-143`).

### CI `backend` job additions (`ci.yml:72-98`)
```yaml
    services:
      meilisearch: { ...unchanged... }
      postgres:
        image: postgres:16-alpine
        env: {POSTGRES_USER: postgres, POSTGRES_PASSWORD: postgres}
        ports: [5434:5432]
        options: >-
          --health-cmd "pg_isready -U postgres"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    env:
      SCRYPATH_INTEGRATION: "1"
      SCRYPATH_MEILISEARCH_URL: http://127.0.0.1:7700
      SCRYPATH_POSTGRES_URL: postgres://postgres:postgres@127.0.0.1:5434
```
The service block format is copied from the `ops-ui` job (`ci.yml:200-210`). The job name `backend (required)` is unchanged, so branch protection is untouched. Extending `Backend failure diagnostics` with `docker logs` for the postgres container is optional.

### compose.yaml
```yaml
  postgres:
    image: postgres:16-alpine
    ports:
      - "5434:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
```
Host port 5434 is free on the maintainer machine. Listening ports seen were only 5432 and 5439. [VERIFIED: lsof this session]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Backfill projects raw rows | Backfill routes rows through the Loader (preload / `search_records/2`) | This phase | Documents equal Oban's; omitted ids deleted (behavior change, `fix:` + CHANGELOG) |
| First-column keyset `a > ^x` | Full-key OR-expansion with leading bound | This phase | Composite PKs no longer skip rows (pinned regression `{1,3}`) |
| ExUnit module parameterization by copy | `parameterize:` (Elixir 1.18+) | Elixir 1.18 | Not usable here (1.17 floor). Use `__using__` |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `postgrex` with `runtime: false` is started on demand by the Ecto SQL adapter when `PostgresRepo` starts | Standard Stack | Low. Drop `runtime: false` if the repo fails to start |
| A2 | Meilisearch processes the upsert then delete tasks for one index in FIFO order | Pattern 4 | Low. The ids don't overlap |
| A3 | NimbleOptions 1.1.1 accepts `doc: false` on a key | options.ex facts | Low. Even if not, any `doc:` string is invisible because docs are never generated from this schema |
| A4 | Fixing the reindex `create_index` primary key to `Metadata.document_id/1` is in scope (or acceptable as a small adjacent fix) | Open Question 1 | Medium. If excluded, composite reindex against live Meilisearch stays broken despite PAGE-01's "backfill or reindex" wording |

## Open Questions

1. **The reindex `create_index` primary key for composite (and custom `document_id`) schemas**
   - What we know: `Reindex.primary_key/1` returns the first Ecto PK column (`reindex.ex:244-249`) and passes it as the Meilisearch `primaryKey` (`reindex.ex:36`, `client.ex:208` `Map.put(payload, "primaryKey", to_string(primary_key))`). Documents carry their id under `Metadata.document_id(schema)` (`client.ex:197-198`). Existing tests assert `{:create_index, QueryablePost, :id, _}` (`reindex_test.exs:379,422,467,494,520`). Those still hold if the value becomes `Metadata.document_id(QueryablePost)`, which is `:id`.
   - What's unclear: whether the maintainer wants this fixed in Phase 178. No locked decision covers it.
   - Recommendation: replace `Reindex.primary_key/1` with `Scrypath.Schema.Metadata.document_id(schema_module)`. It's a one-line `fix:` that makes PAGE-01's "or reindex" true end to end. Add a reindex unit assertion for a composite schema (`{:create_index, CompositeSchema, <document_id field>, _}`). If the planner treats it as out of scope, record it as a known limitation in the guide.
2. **Whether `verify.phase5` and `verify.all` should run the SQLite shared cases explicitly**
   - Recommendation: `verify.all` gains a `verify.postgres` step (D-11). Add the SQLite file to `verify.phase5`'s focused list. That's cheap and keeps the historical wrapper meaningful.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP (CI tuple) | all | ✓ via asdf (no repo `.tool-versions`; set `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1`) | 1.19.0 / 28.1; also 1.17.3, 1.18.4 installed | — |
| Docker | local Postgres via compose | ✓ | 29.5.2 | Any Postgres ≥ 14 via `SCRYPATH_POSTGRES_URL` |
| postgres:16-alpine image | local + CI | ✓ (pulled and run this session) | 16 | — |
| Host port 5434 | compose postgres | ✓ free | — | Any free port; URL is env-driven |
| Meilisearch | not needed for the new tests | — | — | Recording backend |

No missing dependencies block execution.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.0 CI) + StreamData 1.3.0 (`use ExUnitProperties`) |
| Config file | `test/test_helper.exs` (tag excludes), `mix.exs` (`test_ignore_filters`, `preferred_envs`) |
| Quick run command | `mix test test/scrypath/backfill_test.exs test/scrypath/loader_backfill_sqlite_test.exs test/scrypath/reindex_test.exs test/scrypath/oban/worker_test.exs` |
| Postgres run | `docker compose up -d postgres && SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres` |
| Full suite command | `mix verify.core --exclude integration --exclude docs_contract` (core lane) + `SCRYPATH_INTEGRATION=1 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 SCRYPATH_POSTGRES_URL=… mix verify.backend` + `mix verify.repository_contracts` + `mix verify.package` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOAD-01 | backfill and reindex docs == inline (preloaded) docs == `Loader.load/3` docs for a `preload:` schema | integration (real DB, both adapters) | `mix test test/scrypath/loader_backfill_sqlite_test.exs` ; `mix verify.postgres` | ❌ Wave 0 |
| LOAD-01 | `preload_records` uses `force: true`; no `repo.preload` call when preload is `[]` (FakeRepo still works) | unit | `mix test test/scrypath/loader_test.exs test/scrypath/backfill_test.exs` | ❌ loader_test (Wave 0); backfill_test ✅ |
| LOAD-02 | every batch goes through `search_records/2`; omitted ids are deleted (backfill) or counted in `omitted:` with no delete call (reindex); `removed:` counts per batch and in total; all-omitted batch advances the cursor | integration + unit | same as above, plus `mix test test/scrypath/reindex_test.exs` | ❌ Wave 0 |
| LOAD-03 | `:query` `where` scope decides the visited rows; `offset`/`select`/`preload`/`order_by`/`limit` on the caller query are ignored; extras returned by `search_records/2` are ignored | integration + unit | `mix test test/scrypath/backfill_test.exs` (FakeRepo where-scope) + shared cases | partial ✅ (`backfill_test.exs:155-176`) |
| PAGE-01 | property: composite keys (leading `integer(1..3)`), `batch_size` in 1..12, every row exactly once, `batches == ceil(n/bs)`; pinned `[{1,1},{1,2},{1,3},{2,1}]` bs=2 regression; binary_id second column | property + example (real DB) | shared cases via SQLite file and `mix verify.postgres` | ❌ Wave 0 |
| PAGE-02 | composite `last_primary_key` is a keyword list in PK order, equals the batch's max key, strictly increasing; single-column stays scalar (`2,4,5`) | property + unit | shared cases; `mix test test/scrypath/backfill_test.exs:197` | partial ✅ |
| TEST-06 | the postgres file runs in `backend (required)`; CI has a postgres service + `SCRYPATH_POSTGRES_URL`; `verify.backend` calls `verify.postgres`; `verify.postgres` raises without the URL | contract + CI run | `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_capability_test.exs`; hosted `backend (required)` job log on the PR SHA | ❌ new assertions |

### Sampling Rate
- **Per task commit:** the quick run command (under 30s, no services).
- **Per wave merge:** quick run plus `mix verify.postgres` locally (compose) plus `mix credo --strict` and `mix compile --warnings-as-errors`.
- **Phase gate:** hosted PR checks green on the exact SHA: `core`, `package`, `repository-contracts`, `backend` (the log must show `loader_backfill_postgres_test.exs` running with non-zero tests), `ecommerce-mounted`.

### Wave 0 Gaps
- [ ] `test/support/postgres_repo.ex`, `test/support/sqlite_sandbox_repo.ex`: the repos (Pattern 5)
- [ ] `test/support/loader_backfill_migration.ex`, `test/support/loader_backfill_schemas.ex`: inline migration + composite/preload/search_records schemas
- [ ] `test/support/loader_backfill_cases.ex`: shared `__using__` cases
- [ ] `test/scrypath/loader_backfill_sqlite_test.exs`, `test/scrypath/loader_backfill_postgres_test.exs`
- [ ] `test/scrypath/loader_test.exs`: `prepare_records/3` unit tests (FakeRepo-compatible default path, custom path filtering)
- [ ] `test_helper.exs` composed exclude list (Pitfall 2)
- [ ] Framework install: `mix deps.get` after adding `{:postgrex, "~> 0.22", only: :test, runtime: false}`

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | indirect | Caller `:query` remains the sole row selector, so scope (e.g. tenant `where`) is never widened; `search_records/2` extras outside the batch are dropped (D-03) |
| V5 Input Validation | yes | NimbleOptions `@backfill_options`; the internal flag is boolean-typed |
| V6 Cryptography | no | — |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Test DB URL pointing at a real database | Tampering | Namespaced `SCRYPATH_POSTGRES_URL` and a fixed DB name `scrypath_test<partition>` (never `DATABASE_URL`). Dropping only that DB is safe |
| `search_records/2` returning out-of-scope rows (tenant leak into index) | Information disclosure | Filter returned records to the batch id set (Pattern 1) |
| SQL injection via cursor values | Tampering | All values are pinned `^` params with schema types (verified param typing) |
| Unintended index deletions | Tampering | Deletes are limited to ids in the visited batch that `search_records/2` omitted; reindex fresh target never deletes; documented (D-04/D-06) |

## Sources

### Primary (HIGH confidence)
- Repo source read this session: `lib/scrypath/{backfill,loader,reindex,options,identity,projection,sync}.ex`, `lib/scrypath/oban/upsert_worker.ex`, `lib/scrypath/meilisearch/{operations,client}.ex`, `lib/scrypath/operator/recovery_action.ex`, `lib/scrypath.ex`, `lib/mix/tasks/{verify.ex,verify.all.ex,verify.meilisearch_smoke.ex,verify.phase5.ex,verify.no_optional_deps.ex}`, `lib/mix/tasks/verify/{capability,backend,core}.ex`, `mix.exs`, `mix.lock`, `test/test_helper.exs`, `test/support/*`, `test/scrypath/{backfill,reindex}_test.exs`, `test/mix/tasks/*`, `.github/workflows/ci.yml`, `compose.yaml`, `CONTRIBUTING.md`, `.credo.exs`
- `deps/ecto/lib/ecto/repo/supervisor.ex` (init_config/parse_url), `deps/credo` check defaults, Elixir 1.19.0 `mix/tasks/test.ex`, Elixir 1.17.3/1.18.4 `ex_unit/case.ex`
- Executable probes: Ecto 3.14 dynamic AST and SQL on SQLite (ecto_sqlite3 0.24) and Postgres 16 (postgrex 0.22.4 via `Mix.install`); Sandbox + Migrator pool-size failure modes; `preload force: true`; savepoint rollback
- hex.pm API: postgrex package and 0.22.4 release metadata

### Secondary (MEDIUM confidence)
- NimbleOptions `doc: false` (hexdocs, not re-fetched)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. Lockfile read; postgrex checked on Hex; driver probe ran.
- Architecture: HIGH. Every touched function read; keyset SQL verified on both adapters.
- Pitfalls: HIGH. Pitfalls 1–3 reproduced; 4–10 read from source and tests.

**Research date:** 2026-10-25
**Valid until:** 2026-11-24 (stable libraries; re-check if ecto/ecto_sql bump past 3.14)
