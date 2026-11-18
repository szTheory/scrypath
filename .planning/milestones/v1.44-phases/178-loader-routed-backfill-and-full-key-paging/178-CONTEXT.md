# Phase 178: Loader-routed backfill and full-key paging - Context

**Gathered:** 2026-10-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Backfill and reindex (`lib/scrypath/backfill.ex`, and through it `lib/scrypath/reindex.ex`) build documents through `Scrypath.Loader`, exactly as Oban sync does. They visit every row of the caller's scope exactly once, whatever the primary-key shape. Composite keys page on the full key. The loader and backfill are proven against real Postgres in an existing required CI lane.

Requirements: LOAD-01, LOAD-02, LOAD-03, PAGE-01, PAGE-02, TEST-06. The work is library-only (`lib/`, `test/`, CI, docs), with no `scrypath_ops` or UI change. It ships as one PR, squash-merged on green lean gates, with no new required CI job.

Not in this phase:
- Id-list chunking (PAGE-03), related-sync parity (FAN-*): Phase 179.
- Oban worker telemetry (OBS-*): Phase 180.
- Hook callbacks and the no-Oban build (HYG-*): Phase 181.
- Inline sync keeps projecting the records the caller hands it. Routing inline sync through the loader is out of scope.

</domain>

<decisions>
## Implementation Decisions

The maintainer delegated these calls. Each was researched by a dedicated subagent with primary-source prior art (searchkick, meilisearch-rails, elasticsearch-model, Laravel Scout, Rails 7.1+ batches, paginator, use-the-index-luke, ecto_sql/Oban/Flop CI). Alternatives are in `178-DISCUSSION-LOG.md`.

### Loader integration shape (LOAD-01/02/03)
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

### Omitted records (LOAD-02)
- **D-04:** In a live-index backfill, ids from the batch that `search_records/2` leaves out are deleted from the index, matching the documented contract (`guides/sync-modes-and-visibility.md`: "Scrypath removes the rest from the index") and the Oban upsert worker. Reindex into a fresh target passes an internal, undocumented backfill flag that skips the delete calls but still counts omissions. This is the same split searchkick (`full:`) and meilisearch-rails (`if:`/`unless:` on reindex) make. — **Reversibility:** costly — this is a visible behavior change: backfills that previously indexed everything now remove documents. Undoing it later would be a second behavior change for adopters, and the CHANGELOG and guide must state it.
- **D-05:** Reporting:
  - Each batch result gains `removed:` (a count) next to `documents:`.
  - The top-level result gains a total `removed:`.
  - Reindex reports `omitted:` instead, because nothing was removed from a fresh target.
  - Do not return id lists in results (keep them bounded and simple).
  - Don't add new telemetry events here; Phase 180 owns telemetry. Only add counts to existing span stop metadata if a span already wraps the call.
- **D-06:** Document the scope limit. The default path never omits rows, and documents for rows deleted outside Scrypath or outside the visited scope stay in the index; finding those is reconcile/drift recovery's job. The guide must not imply that a backfill prunes the whole index.

### Composite keyset paging (PAGE-01)
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

### Cursor shape (PAGE-02)
- **D-09:** `last_primary_key` stays a scalar for single-column keys, so the existing `backfill_test.exs` asserts and adopters' matches keep working. For composite keys it is a keyword list in primary-key order (`[org_id: 1, id: 7]`), the shape `Ecto.primary_key/1` uses.
  - The internal paging cursor (a plain value list) is kept separate from this public value.
  - Don't add a `:cursor` key; that name is reserved for a possible future opaque resume token.
  - — **Reversibility:** costly — once documented, the polymorphic shape is a public contract for 0.3.x and later.
- **D-10:** Give `Scrypath.backfill/2` a `@doc` that formally describes the result map: `index`, `batches`, `documents`, `removed`, `mode`, `batch_results[].{index, documents, removed, last_primary_key, task}`, and the composite cursor shape. Mention the reindex `omitted` count where reindex results are documented.

### Real-Postgres tests in CI (TEST-06)
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

### Test coverage (success criteria 1–4)
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

### Docs and release notes
- **D-16:** Update the guides:
  - `guides/sync-modes-and-visibility.md` and `guides/related-data-and-reindexing.md`: backfill now honors `preload:` and `search_records/2`; omitted ids are removed in scope only; composite keys are supported; declare PK fields in constraint order; `:query` must not fan out.
  - Commits use conventional `fix:` messages, so release-please records a CHANGELOG entry that calls out the behavior change in D-04.

### Reindex index primary key (added at plan time, 2026-10-25)
- **D-17:** `Reindex.primary_key/1` (`lib/scrypath/reindex.ex`) copies the first-column-only bug and passes that column to `create_index` as the Meilisearch `primaryKey`. Documents carry their id under `Metadata.document_id(schema)`, so a composite-key reindex would collapse or reject rows even after the paging fix. Fix it in this phase: the target index's primaryKey is `Metadata.document_id(schema)`, with a test asserting the composite-key case. Existing `QueryablePost` reindex asserts (`:id`) stay green. Found by phase research (RESEARCH.md Open Question 1); decided under the maintainer's delegation because the phase goal says "whatever its primary-key shape". Commit as `fix:`.

### Claude's Discretion
- Exact names of the new Loader function, the internal reindex flag and the private keyset builder.
- Whether the delete for omitted ids reuses the Oban worker's backend-delete helper or a small shared one, as long as backfill and Oban share the semantics.
- Task module layout for `verify.postgres` and the shared parameterized test module.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/ROADMAP.md` § Phase 178: goal and success criteria 1–4
- `.planning/REQUIREMENTS.md`: LOAD-01–03, PAGE-01–02, TEST-06 (PAGE-01 records the maintainer decision to page on the full key)
- `.planning/reference/ROLLING-ROADMAP.md` §2: origin of the v1.44 findings
- `.planning/STATE.md`: v1.44 open questions (this context resolves the CI-lane question)

### Code under change
- `lib/scrypath/backfill.ex`: `base_query/3`, `batch_query/4`, `primary_key/1` (first column only: the bug), `batch_result/4`
- `lib/scrypath/loader.ex`: `load/3`, `fetch/3`, `preload_records/3`, `check_loadable/2`
- `lib/scrypath/oban/upsert_worker.ex`: Oban semantics to match (load, then delete missing ids)
- `lib/scrypath/reindex.ex`: `backfill_config/1` pass-through keys and `maybe_wait_for_backfill_tasks/2`
- `lib/scrypath/sync.ex`: inline projection of caller records (unchanged; the parity reference)
- `lib/scrypath/identity.ex`, `lib/scrypath/schema/metadata.ex`, `lib/scrypath/options.ex` (`@backfill_options`)
- `lib/scrypath.ex`: `backfill/2` (needs `@doc`)

### Tests and CI
- `test/scrypath/backfill_test.exs`: existing scalar `last_primary_key` asserts that must stay green
- `test/support/fake_repo.ex`, `test/support/integration_repo.ex`, `test/support/meilisearch_integration.ex`, `test/test_helper.exs`
- `.github/workflows/ci.yml`: `core` and `backend` jobs
- `lib/mix/tasks/verify/capability.ex` (`backend!/1`), `lib/mix/tasks/verify.meilisearch_smoke.ex`, `lib/mix/tasks/verify.all.ex`
- `compose.yaml`, `CONTRIBUTING.md` (core is service-free; verify task table)

### Docs
- `guides/sync-modes-and-visibility.md` (~L100–120): the `search_records/2` contract
- `guides/related-data-and-reindexing.md`: when to choose backfill or reindex

### Project guidance
- `prompts/ecto-best-practices-deep-research.md`, `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`, `prompts/elixir-search-lib-deep-research.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scrypath.Loader.preload_records/3`: becomes the shared preload step for both the Oban and backfill paths. Add `force: true`.
- `Scrypath.Identity.document_ids/2`: maps scoped rows to the ids `search_records/2` takes.
- `Scrypath.Projection.document/2`: unchanged document builder.
- `Operations.normalize_write_result/2`, `MeilisearchOperations.upsert_documents/3`: existing write path in backfill.
- `stream_data` and `ecto_sqlite3` (and the transitive `ecto_sql`) are already test deps.

### Established Patterns
- Curated `verify.*` capability tasks run one `mix test` process per file.
- Env-gated integration tags in `test_helper.exs`.
- `SCRYPATH_*` env var naming.
- Backfill options are validated with NimbleOptions in `Options.validate_backfill_options!/1`. An internal reindex-only flag must be allowed without being documented as public.

### Integration Points
- `Reindex` → `Backfill.run/2` through `@backfill_pass_through_keys`; the omit-not-delete flag goes through here.
- `backend (required)` CI job → `verify.backend` → `verify.postgres` (new).

</code_context>

<specifics>
## Specific Ideas

- The maintainer prefers copy-paste over a new dependency. The keyset builder is hand-rolled (no paginator/quarto), and postgrex is a test-only dependency.
- No human UAT: every success criterion is backed by an executable test that runs on the phase PR.

</specifics>

<deferred>
## Deferred Ideas

- Postgres row-value `(a, b) > (x, y)` fast path, or a decomposed seek for adopters with very large leading groups (one huge tenant in `(org_id, id)`). Do this only if adopters report slow backfills; D-07 leaves a seam for it.
- A resume-from-cursor backfill option (an opaque `:cursor` token). The name stays free (D-09).
- Routing inline sync through the records-in loader entry point, so caller records get the declared `preload:` too. This is a product decision; it stays out of v1.44 unless it is raised.
- Whole-index pruning of documents whose rows are gone. That stays with reconcile and drift recovery, not backfill.

</deferred>

---

*Phase: 178-loader-routed-backfill-and-full-key-paging*
*Context gathered: 2026-10-25*
