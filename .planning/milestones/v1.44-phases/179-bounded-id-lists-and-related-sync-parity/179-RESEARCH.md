# Phase 179: Bounded id lists and related-sync parity - Research

**Researched:** 2026-10-25
**Domain:** Elixir library internals: Ecto loader, Oban enqueue/worker contracts, sync result shapes
**Confidence:** HIGH (all findings come from reading this repo's source, the vendored Oban 2.23.0 source, and one executed Oban/SQLite probe)

## Summary

Every call site named in D-02 is a small, readable function. Chunking can be added with one `@moduledoc false` helper built on `Enum.uniq/1`, `Enum.sort_by/2` and `Enum.chunk_every/2`, plus a sequential `reduce_while` that stops at the first `{:error, _}`. The work is mostly plumbing. The risk sits in four places the CONTEXT did not name:

1. **Reindex waits on one task per batch.** `Scrypath.Reindex.maybe_wait_for_backfill_tasks/2` waits only on each batch's `task`. Once backfill splits a batch of more than 1000 rows into several writes, a failed earlier chunk would go unnoticed before cutover.
2. **`public_result/1` merges `backend_result`.** Today's tests rely on that merge: `sync_mode:` comes from the backend map. To satisfy D-08 and D-09 together, keep the single-chunk path exactly as it is and build the multi-chunk result fresh.
3. **Hand-written owner-only fan-out schemas will crash the new Oban related worker.** Both example apps' `Author` and `Category`, and most related test fixtures, define no `__scrypath__(:preload)` clause, so the call raises `FunctionClauseError`. They also rely on repos or tenant scoping that the default loader path does not satisfy.
4. **The related job's `"opts"` map carries keys whose value is `nil`.** Examples are `"repo" => nil` and `"otp_app" => nil`. `JobArgs` must treat `nil` as absent, not as `{:unknown_repo, nil}`.

Oban uniqueness and transactional multi-insert work against the repo's existing SQLite test stack. A probe run this session against Oban 2.23.0 with `Oban.Engines.Lite`, a sandboxed `Ecto.Adapters.SQLite3` repo and `testing: :manual` produced these results:

- A duplicate insert returned the same job id with `conflict?: true`.
- `Oban.Repo.transaction/2` committed two inserts.
- `Oban.Repo.rollback/2` left nothing behind.

The FAN-02 test therefore needs no Postgres. The suite has no `Oban.Testing` usage today, so the planner needs a Wave 0 task that adds a small Oban SQLite repo and migration under `test/support/`.

**Primary recommendation:** Add `Scrypath.Chunks` (internal; the name is at the planner's discretion). Route `Sync`, `Enqueue`, `RelatedEnqueue`, `Loader.load/3`, `Backfill.write/5` and the workers through it. Add `Scrypath.Oban.JobArgs` as the single decoder. Fix the two hidden callers before merge: Reindex waiting on every chunk task, and Loader's `preload` lookup for owner-only schemas.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

The maintainer asked for a research fan-out with one-shot coherent recommendations and accepted all four. There was one researcher per area, using Oban, Meilisearch SDK, meilisearch-rails, Searchkick, Laravel Scout, Ecto and Rails ActiveJob prior art. Alternatives are in `179-DISCUSSION-LOG.md`.

#### Chunk size and where chunking happens (PAGE-03)
- **D-01:** The limit is fixed at 1000, an internal module attribute (e.g. `@max_ids 1000`). There is **no public option**.
  - This matches the prior-art defaults: meilisearch-rails `DEFAULT_BATCH_SIZE = 1000`, Searchkick `batch_size || 1000`.
  - It stays far below the 65,535 bind-parameter limit (`in ^ids` uses one parameter per element).
  - An option can be added later without breaking anyone; removing one breaks adopters. Revisit only if an adopter reports Meilisearch payload-limit problems (≈100KB+ documents).
  - If an option is ever added, it must **not** be named `:batch_size`, which stays backfill's paging knob.
- **D-02:** One shared internal chunking helper (`@moduledoc false`) sits **above the adapter layer**. Every bounded call site uses it:
  - `Scrypath.Sync` upsert and delete dispatch
  - `Scrypath.Backfill` writes
  - `Scrypath.Oban.UpsertWorker` and `DeleteWorker`, including their missing-id deletes, which still run after the upserts as today
  - `Scrypath.Loader.load/3`, so `search_records/2` is guaranteed ≤1000 ids per call
  - `Scrypath.Sync.RelatedEnqueue`

  Adapter-level-only chunking was rejected: test fakes and custom backends would bypass it, and `Loader` would stay unbounded. Backfill `:batch_size` controls paging only; a `batch_size: 5000` page becomes 5 writes. Document that.
- **D-03:** Ids are deduped and sorted (stable, e.g. by `to_string/1`) before chunking. The same id set then always yields the same chunks, so `unique:` collapses duplicate jobs (D-13). Resolvers and loaders get set semantics; document that there is no ordering contract.

#### Oban job split (PAGE-03)
- **D-04:** Under `sync_mode: :oban`, enqueueing N ids inserts **one job per chunk of ≤1000 ids**, so 2,500 ids make 3 jobs. Each job is inserted with `insert` (not `insert_all`) inside one transaction.
  - Open-source Oban's `insert_all` drops `unique:` (Oban docs: only Pro's Smart Engine does bulk unique).
  - The transaction ensures a mid-enqueue failure leaves no orphan jobs.
  - Rejected: one job that chunks internally. It means huge jsonb args, whole-job retry amplification, meaningless per-job telemetry for Phase 180, and timeout risk.
  - Workers still chunk whatever they receive through D-02, so legacy jobs with more than 1000 ids stay bounded.
- **D-05:** RelatedEnqueue chunks **trigger** ids into jobs the same way. The resolver output inside the worker goes through `sync_records`, so it is chunked automatically.

#### Combined result and failure semantics (PAGE-03)
- **D-06:** Chunks run **sequentially** and the call **halts at the first failed chunk**, returning the same bare `{:error, reason}` as today. No partial payload and no id lists in errors (Phase 178 D-05: counts, not ids).
  - Chunks already sent stay applied; one docs sentence states this.
  - Rationale: writes are idempotent by id, and an Oban retry reloads current records.
  - This matches backfill's `run_batch` `with` precedent and Ecto.Multi stop-at-first-failure.
  - Rejected: continue-on-error / `{:ok, %{errors: ...}}`. Callers matching `{:ok, _}` and Oban would silently miss failures, which contradicts "sync failures are operational issues".
- **D-07:** Waiting:
  - **Inline** waits on each chunk's task before sending the next, so a failed task stops later chunks. Waiting only on the last task would miss an earlier chunk's failure; each Meilisearch task fails independently.
  - **Workers** wait per chunk through `IndexingAck` as today.
  - **Manual** mode doesn't wait; it sends all chunks and returns every task.
  - Document that `inline_timeout` applies per chunk, and that inline sync of more than 1000 ids inside a request is a smell (use Oban).
- **D-08:** `Scrypath.Operations.Result` gains `tasks: [Task.t()]`, always a list.
  - One entry per chunk, in order: Meilisearch tasks, or Oban jobs, which are already modelled as `Operations.Task` with `source: :oban`.
  - Empty for noop.
  - `task:` stays, pointing at the last chunk's task, so the ≤1000 case is unchanged plus a one-element `tasks`.
  - `document_ids` and `document_count` are combined across chunks.
  - There is **no separate `jobs:` key**. This supersedes the "add `jobs:`" wording from discussion, because enqueue results already put jobs in `task`.
  - Manual-mode docs: a successful `task:` doesn't prove earlier tasks succeeded; check `tasks`.
  - — **Reversibility:** costly — `tasks:` becomes part of the public result map for 0.3.x and later.
- **D-09:** Build the combined public result fresh. Never merge the first or last chunk's raw `metadata.backend_result` into `public_result/1`, because that would present one chunk's `task`/`raw` as covering the whole call.
- **D-10:** Telemetry stays one existing span around the whole call (`[:scrypath, :sync, :upsert | :delete]`), with the total `document_count`. No per-chunk spans and no new events.

#### Related resolver input (FAN-01)
- **D-11:** A resolver always receives a **non-empty list of current trigger structs** and returns target records.
  - **Oban:** the related worker loads triggers through `Scrypath.Loader.load/3` (with `preload:` / `search_records/2`), then calls the resolver with the survivors.
    - Triggers that no longer load, because they were deleted or excluded by `search_records/2`, are skipped and counted as `missing_count`. This is added to the existing `[:scrypath, :sync, :related, :resolve]` span's stop metadata and to the result; it is not a new event.
    - If **none** survive, the resolver is not called and the job returns `:ok`. It must not return `{:error, _}`, which would burn 8 retries.
  - **Inline:** keeps passing the caller's structs. No reload and no new inline `:repo` requirement.
  - Prior art: Searchkick, Laravel `deleteWhenMissingModels` and Oban's ids-not-structs guidance all drop missing records quietly. Rejected: passing missing ids to the resolver (a second arity or context map). It brings back two resolver shapes and adds public surface nobody has asked for. An opt-in `on_missing:` can be added later without breaking anyone.
  - — **Reversibility:** costly — this is a visible behaviour change for adopters whose resolvers only accept ids.
- **D-12:** `RelatedEnqueue` calls `Loader.ensure_loadable!` on the trigger schema before enqueueing, so a missing `:repo` or custom-id schema fails where `sync_related` is called. This matches `sync_records` under Oban.
- **D-13 (docs):**
  - Rewrite `guides/related-data-and-reindexing.md` §(c), "Write an arity-safe resolver (the #1 footgun)", as "What your resolver receives":
    - Drop the id clause, and note that existing id clauses are now dead code and safe to remove.
    - State the soft-delete skip, and to sync targets directly (`Scrypath.sync_records(Post, posts)`) to hide them.
    - Say to call `sync_related` after the write commits; enqueueing inside an open transaction can load stale or missing triggers.
    - State that inline with a deleted struct still calls the resolver, which usually returns `[]`.
  - CHANGELOG entry under **Changed**: "Oban `sync_related` resolvers now receive loaded trigger records instead of document ids."

#### Job-arg decoding and non-retrying errors (FAN-03)
- **D-14:** Every arg-decode or resolve failure in the related, upsert and delete workers returns `{:cancel, {:invalid_job, reason}}`.
  - `{:discard, _}` is deprecated in Oban. `{:error, _}` burns retries on input that can never succeed.
  - The Oban floor `~> 2.21` supports cancel.
  - A cancelled job can still be retried manually from Oban Web or Ops after a fix.
- **D-15:** One shared private decoder, `Scrypath.Oban.JobArgs` (`@moduledoc false`, pure, no Oban compile dependency), used by all three workers. It returns specific tags:
  - `{:unknown_schema, name}`, `{:unknown_fan_out, name}`, `{:unknown_backend, name}`, `{:unknown_repo, name}`, `{:unknown_otp_app, name}`
  - `{:invalid_arg, key}`, e.g. missing `"document_ids"`; this replaces today's `MatchError` on the pattern match
  - `{:invalid_config, message}`, from a rescued `Config.resolve!`. An unconfigured fan-out also maps to `{:unknown_fan_out, _}` instead of raising.

  Lift the existing `safe_module` / `Module.safe_concat` / `resolve_existing_module` pattern from the upsert and delete workers. The upsert and delete error atoms are private, so changing them breaks no contract. The tags are designed for Phase 180 telemetry metadata.
- **D-16:** Validation rules:
  - **Schema:** an existing loaded module.
  - **Backend:** the same callback check as upsert (`upsert_documents/3`, `delete_documents/3`, `index_name/2`). The related worker currently does no check.
  - **Repo:** `safe_module` + `Code.ensure_loaded?` + `function_exported?(m, :__adapter__, 0)`.
  - **otp_app:** `String.to_existing_atom` inside a rescue, plus `Application.spec(app) != nil`.
- **D-17:** Opts keys are decoded from a **string allowlist** (`index_prefix`, `meilisearch_url`, `backend`, `otp_app`, `repo`); unknown keys are ignored, not cancelled. Atoms are never created from job input, and a job enqueued by a newer version during a rolling deploy isn't stranded. Keys come only from Scrypath's own `job_args`, so a typo is a library bug that tests catch.
- **D-18:** The upsert worker's `put_repo/2` **cancels with `{:unknown_repo, name}`** when a `"repo"` value is present but can't be resolved, instead of silently falling back. Pre-0.3.16 jobs carry no `"repo"` key, so the 0.3.17 legacy path is unaffected. The plan must verify this against the 0.3.17 legacy tests.
- **D-19:** The related worker's `{:cancel, "HTTP 4xx: ..."}` string stays as is in this phase. Flag it for Phase 180 so reason shapes are aligned there.

#### Related-job uniqueness and legacy jobs (FAN-02)
- **D-20:** Extract one shared `unique_opts/0` from `Scrypath.Oban.Enqueue`: `[period: :infinity, states: [:available, :scheduled, :retryable]]`, with the default fields `[:worker, :queue, :args]` and no `keys:`. Both enqueue paths use it.
  - `executing` is deliberately excluded: a running job may have read stale rows.
  - With D-03's sorted ids, the same set collapses regardless of call order.
- **D-21:** A collapsed duplicate is reported as `conflict?: job.conflict?` in that job's `Operations.Task` metadata. Status stays `:accepted`, since the work still happens, and no new status atom is added.
- **D-22:** The related job args shape doesn't change (`schema`, `document_ids`, `fan_out`, `opts`); only the worker's behaviour changes. A test runs a hard-coded pre-upgrade args map through `perform/1` (the 0.3.17 lesson).

#### Tests (success criteria 1–4)
- **D-23:** Required:
  - 2,500 ids → 3 loads and 3 backend upsert calls, and 3 delete calls, each ≤1000, with one combined result (`document_count: 2500`, 3 `tasks`). Observe this through the test backend or fake.
  - Under Oban, 2,500 ids → 3 jobs.
  - Halt on a chunk-2 failure: chunk 3 is never sent, and the result is `{:error, reason}`.
  - A `search_records/2` spy sees ≤1000 ids per call.
  - The resolver receives structs under inline **and** Oban.
  - Under Oban, a deleted trigger is skipped and counted; all triggers deleted → resolver not called, job `:ok`; a soft-deleted trigger excluded by `search_records/2` is skipped.
  - FAN-02: enqueueing twice (ids in a different order) yields one job with `conflict?: true`. Use `Oban.Testing` in `testing: :manual`, because inline mode doesn't enforce uniqueness.
  - FAN-03: for each worker × {unknown schema, fan-out, backend, repo, otp_app, missing `document_ids`}, the job returns `{:cancel, {:invalid_job, tag}}` and never raises.
  - The legacy related-args fixture.

### Claude's Discretion
- Names of the chunking helper module and functions, and of the `@max_ids` attribute.
- Exact transaction mechanism for multi-job insert (`Ecto.Multi` vs `repo.transaction`), consistent with how `Enqueue` gets its repo or Oban instance.
- Whether `missing_count` also lands on the related-sync public result or only in the span metadata (span metadata is required).

### Deferred Ideas (OUT OF SCOPE)
- A configurable chunk size (name must not be `:batch_size`). Add only if an adopter reports payload-limit issues.
- An opt-in fan-out `on_missing:` hook that gives resolvers the missing trigger ids. Add only on real adopter demand.
- Aligning the related worker's HTTP-4xx `{:cancel, "HTTP ..."}` string with tagged reasons. Phase 180.
- New telemetry events, including per-chunk spans and an event for cancelled-job reasons. Phase 180.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAGE-03 | Id lists are chunked to at most about 1000 per record load and per backend upsert or delete call. For example, 2,500 ids make three calls and return one combined result. | Call-site map (§Architecture Patterns, "Call-site map"). Chunk helper (Pattern 1). Combined-result builder (Pattern 2). Chunked transactional enqueue (Pattern 3). Reindex wait gap (Pitfall 1). `public_result` compatibility (Pitfall 2). |
| FAN-01 | `sync_related` resolvers get loaded records in every sync mode. Under Oban, the worker loads current records through the loader before it calls the resolver. | Related worker rewrite (Pattern 5). Owner-only `preload` crash (Pitfall 3). Example-app breakage (Pitfall 4). `ensure_loadable!` effect on existing tests (Pitfall 6). |
| FAN-02 | Related enqueue uses the same `unique:` policy as the main enqueue path, so duplicate related jobs collapse. | `unique_opts/0` (Pattern 3). Probe of Oban Lite + SQLite uniqueness (Code Examples). Oban unique defaults quoted verbatim. |
| FAN-03 | Sync jobs (related, upsert and delete) whose arguments name an unknown schema, fan-out, backend, repo or app end with a clear, non-retrying error instead of crashing on `String.to_existing_atom`. | Raise inventory of today's workers (Pattern 4). `nil` opts values (Pitfall 5). FakeRepo has no `__adapter__/0` (Pitfall 7). Applicability matrix (Open Question 2). |
</phase_requirements>

## Project Constraints (from AGENTS.md)

There is no `CLAUDE.md`. The directives below come from `./AGENTS.md` and `CONTRIBUTING.md`.

- The library is Ecto-first and Meilisearch-first, behind an internal adapter seam. Don't add a public multi-backend facade.
- Oban is an **optional** dependency. Oban-touching modules stay wrapped in `if Code.ensure_loaded?(Oban.Worker)` / `Oban.Job` with no-Oban stubs [VERIFIED: lib/scrypath/sync/related_enqueue.ex:1,83-92; lib/scrypath/oban/upsert_worker.ex:1]. `JobArgs` must stay pure (CONTEXT).
- Operational clarity: sync failures are operational issues. Never swallow errors.
- Green-main release train: completion must be backed by executable tests or exact-SHA hosted evidence, **never human UAT**.
- Keep edits focused. Run the checks CONTRIBUTING names: `mix verify.core --exclude integration --exclude docs_contract` (the required `core` gate: warnings-as-errors, format, Credo, fast tests, docs build), `mix verify.package`, `mix verify.repository_contracts`, `mix verify.backend` (Meilisearch plus real Postgres), and `mix verify.ecommerce_mounted` [VERIFIED: CONTRIBUTING.md:220-232].
- Update `.planning/PROJECT.md` when shipped claims change. The resolver-input change is a shipped-claim change.
- Phase scope (CONTEXT): `lib/`, tests, guides, CHANGELOG only. No `scrypath_ops`, no UI, no new required CI job, no new telemetry events.
- The maintainer prefers "another copy-paste over another dependency": no new deps.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Id dedupe/sort/chunk | Library core (`Scrypath.Chunks`, internal) | — | Sits above the adapter seam (D-02) so fakes, custom backends and Loader can't bypass it |
| Record loading ≤1000 ids/call | Library core (`Scrypath.Loader`) | Database (Ecto repo / `search_records/2`) | Loader owns the id→record contract; chunking lives inside `load/3` |
| Backend write chunking + combined result | Library core (`Scrypath.Sync`, `Scrypath.Backfill`) | Search backend (Meilisearch tasks) | Halt and wait semantics are orchestration, not adapter, concerns |
| Job split + uniqueness + transaction | Library core (`Scrypath.Oban.Enqueue`) | Database (Oban jobs table via the Oban repo) | Uniqueness is enforced by the Oban engine in the DB |
| Job-arg decoding | Library core (`Scrypath.Oban.JobArgs`, pure) | Oban worker runtime | Decoding is pure; the workers map `{:error, tag}` to `{:cancel, …}` |
| Resolver invocation with loaded triggers | Oban worker (`Scrypath.Sync.RelatedWorker`) | Loader | The worker loads current state at run time (ids-not-structs) |

## Standard Stack

No new dependencies. Everything uses what is already locked in `mix.lock`.

### Core
| Library | Version (locked) | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir stdlib `Enum.chunk_every/2`, `Enum.uniq/1`, `Enum.sort_by/2` | Elixir ~> 1.17 | chunking | No dependency (maintainer preference) [VERIFIED: mix.exs:14] |
| ecto | 3.14.0 | Loader queries | already core [VERIFIED: mix.lock line "ecto": 3.14.0] |
| oban (optional) | 2.23.0 locked, floor `~> 2.21` | enqueue, unique, `{:cancel, _}`, `Oban.Testing` | already an optional dep [VERIFIED: mix.exs:112, mix.lock] |
| ecto_sqlite3 (test only) | 0.24.0 | Oban Lite engine + sandbox for the FAN-02 test | already a test dep [VERIFIED: mix.exs:117, mix.lock] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Oban.Repo.transaction(conf, fun)` | `Ecto.Multi` + `Oban.insert(name, multi, key, changeset)` + `conf.repo.transaction(multi)` | Multi uses only "public" Oban API. `Oban.Repo` is documented as "Meant for Extending Oban" [VERIFIED: deps/oban/lib/oban/repo.ex:8-11]. But `Oban.Repo.transaction/2` resolves dynamic repos and prefix for you and was proven by the probe. Both are fine; pick one (the planner's discretion). |
| `Oban.insert_all` | — | Rejected by D-04: OSS `insert_all` ignores `unique:` |

**Installation:** none.

## Package Legitimacy Audit

No external packages are installed in this phase. **Packages removed:** none. **Packages flagged:** none.

## Architecture Patterns

### System Architecture Diagram

```
caller ──► Scrypath.sync_records / delete_documents / sync_related
              │
              ├─ sync_mode :inline/:manual ─► Chunks.ids|docs ─► for each chunk (sequential):
              │                                   backend write ─► (:inline) wait task ─► halt on {:error,_}
              │                                   └─► Combine ─► one public map {document_ids, document_count, task(last), tasks[..]}
              │
              ├─ sync_mode :oban ─► Loader.ensure_loadable! ─► Chunks.ids ─► changesets(unique_opts)
              │                       └─► one transaction: insert job #1..#N (halt+rollback on error)
              │                           └─► Combine ─► {job(last), tasks[job..], conflict? per job}
              │
              └─ sync_related :oban ─► same path, worker = RelatedWorker (trigger ids)

Oban runtime ─► Worker.perform(args)
                 ├─ JobArgs.decode(args) ── {:error, tag} ─► {:cancel, {:invalid_job, tag}}
                 ├─ Upsert: Loader.load (chunked search_records/repo.all) ─► project ─► write chunks (IndexingAck per chunk) ─► delete missing chunks
                 ├─ Delete: write chunks (IndexingAck per chunk)
                 └─ Related: Loader.load(trigger schema) ─► [] ⇒ :ok (missing_count) | resolver(records) ─► Sync.sync_records(target, sync_mode: :inline) [chunked]

Backfill page (batch_size rows) ─► Loader.prepare_records ─► write chunks ≤1000 (upsert, then delete) ─► batch_result{task(last), tasks[..]}
Reindex ─► backfill ─► wait EVERY chunk task (not just batch.task) ─► cutover
```

### Call-site map (every D-02 site, with current code)

| Site | File:lines | Today | Change |
|------|-----------|-------|--------|
| Inline/manual upsert | `lib/scrypath/sync.ex:135-153` `dispatch_upsert/3` | projects all records, one `backend_upsert_documents/3`, `maybe_wait_for_task/2`, `decorate_result/2` | chunk documents, loop sequentially with a per-chunk wait (inline only), combine |
| Inline/manual delete | `lib/scrypath/sync.ex:155-169` `dispatch_delete/3` | one `backend_delete_documents/3` | same as upsert |
| Oban upsert/delete enqueue | `lib/scrypath/oban/enqueue.ex:14-41` `enqueue_upsert/3`, `enqueue_delete/3` → `enqueue_job/2` (72-112) | one changeset, one `insert_job/2` | chunk ids, build N changesets, insert inside one transaction, combine. Chunking **here** (not in Sync) also bounds `Scrypath.Operator.RecoveryAction.retry/2` [VERIFIED: lib/scrypath/operator/recovery_action.ex:51-55] |
| Related enqueue | `lib/scrypath/sync/related_enqueue.ex:14-51` | no `unique:`, no `ensure_loadable!`, one job | `ensure_loadable!`, chunk, `unique_opts/0`, shared transactional insert |
| Loader | `lib/scrypath/loader.ex:88-94` `load/3` → `fetch/3` (127-148) | one `search_records/2` or one `repo.all` with `in ^ids` | chunk ids, `fetch/3` per chunk, concat records, compute `missing` over the full input. `prepare_records/3` (108-125) inherits it |
| Backfill writes | `lib/scrypath/backfill.ex:107-121` `write/5` | one write per page | chunk documents/ids per page, halt on first error; batch result keeps `task` (last) and adds all tasks (Pitfall 1) |
| Upsert worker | `lib/scrypath/oban/upsert_worker.ex:23-29,50-54` | `write/5` sends all documents then all missing ids | `write/5` chunks; each chunk goes through `IndexingAck.await/3`; deletes still after upserts |
| Delete worker | `lib/scrypath/oban/delete_worker.ex:19-22` | one `backend.delete_documents` | chunk plus `IndexingAck.await` per chunk |
| Legacy snapshot path | `lib/scrypath/oban/upsert_worker.ex:31-40` | writes the legacy `documents` snapshot in one call | route through the same chunked `write/5` |
| Public Multi helper | `lib/scrypath/oban.ex:12-38` `Scrypath.Oban.enqueue_upsert/5`, `enqueue_delete/5` | one job per Multi step | **not in D-02**; see Open Question 1 |

### Recommended structure (new/changed files)
```
lib/scrypath/
├── chunks.ex                 # NEW @moduledoc false: @max_ids 1000, ids/1, by_id/2, reduce_ok/2
├── oban/job_args.ex          # NEW @moduledoc false, pure: decode_upsert/1, decode_delete/1, decode_related/1
├── oban/enqueue.ex           # unique_opts/0, chunked + transactional insert shared with RelatedEnqueue
├── operations/result.ex      # + tasks: [] field
├── sync.ex                   # chunked dispatch, combine, public tasks/conflict?
├── loader.ex                 # chunked fetch; owner-only preload tolerance (Pitfall 3)
├── backfill.ex               # chunked write/5, batch tasks
├── reindex.ex                # wait on every chunk task (Pitfall 1)
├── oban/upsert_worker.ex     # JobArgs + chunked write; put_repo cancels (D-18)
├── oban/delete_worker.ex     # JobArgs + chunked write
└── sync/related_worker.ex, sync/related_enqueue.ex
test/support/
├── oban_sqlite_repo.ex       # NEW: dedicated SQLite repo for Oban.Testing (don't share SQLiteSandboxRepo)
└── fake_repo.ex              # + __adapter__/0 (Pitfall 7)
```

### Pattern 1: One chunk helper, set semantics
**What:** Dedupe, sort stably, then chunk. Stop at the first error.
```elixir
# Source: recommendation built on stdlib; values from D-01/D-03
defmodule Scrypath.Chunks do
  @moduledoc false
  @max_ids 1000

  @spec ids([term()]) :: [[term()]]
  def ids(ids), do: ids |> Enum.uniq() |> Enum.sort_by(&sort_key/1) |> Enum.chunk_every(@max_ids)

  # Documents/records: one entry per id. Keep the LAST occurrence (latest caller copy).
  @spec by_id([a], (a -> term())) :: [[a]] when a: term()
  def by_id(items, id_fun) do
    items
    |> Enum.reverse() |> Enum.uniq_by(id_fun) |> Enum.reverse()
    |> Enum.sort_by(&sort_key(id_fun.(&1)))
    |> Enum.chunk_every(@max_ids)
  end

  # Sequential; halts at the first {:error, _}; returns {:ok, [chunk_result]} in order.
  def reduce_ok(chunks, fun) do
    Enum.reduce_while(chunks, {:ok, []}, fn chunk, {:ok, acc} ->
      case fun.(chunk) do
        {:ok, r} -> {:cont, {:ok, [r | acc]}}
        {:error, _} = e -> {:halt, e}
      end
    end)
    |> case do
      {:ok, acc} -> {:ok, Enum.reverse(acc)}
      e -> e
    end
  end

  # to_string for ordering only; the {string, term} tiebreak keeps 1 and "1" distinct and stable.
  defp sort_key(id) when is_binary(id) or is_number(id) or is_atom(id), do: {to_string(id), id}
  defp sort_key(id), do: {inspect(id), id}
end
```
Dedupe on the raw value (`Enum.uniq/1`), never on `to_string`. Otherwise `1` and `"1"` would collapse, which hides a caller bug. Note that `Loader.load/3` already matches found ids by `to_string` [VERIFIED: lib/scrypath/loader.ex:90-91].

### Pattern 2: Combined result — single chunk unchanged, multi-chunk fresh
Today's `public_result/1` merges `metadata.backend_result` first [VERIFIED: lib/scrypath/sync.ex:243-255]:
```elixir
    result.metadata
    |> Map.get(:backend_result, %{})
    |> Map.merge(%{
      mode: result.mode,
      status: result.status,
      document_ids: result.document_ids,
      document_count: result.document_count
    })
```
Existing tests assert keys that come only from that merge, for example `{:ok, %{document_ids: [123], sync_mode: :inline}}` [VERIFIED: test/scrypath/sync_test.exs:252]. So:
- **One chunk:** run today's exact path. Add `tasks: [public_task]`, or `[]` when the backend returned no task. This satisfies D-08 ("≤1000 case unchanged plus a one-element `tasks`").
- **More than one chunk:** build `%Result{document_ids: concat, document_count: sum, task: last.task, tasks: Enum.map(chunks, & &1.task) |> Enum.reject(&is_nil/1), metadata: %{index: …, oban: …}}` and **do not** carry `backend_result`. This satisfies D-09.
- In the public map, `tasks` holds the same public shape as the singular key. Backend tasks use `public_backend_task/1` (`%{uid, status, index_uid, type, raw}`). Oban jobs use `public_job/1` (`%{id, worker, queue, state, ...}`), plus `conflict?` (D-21; see Open Question 4).
- `FakeBackend.upsert_documents/3` returns `{:ok, [ids]}`, a list and not a map [VERIFIED: test/support/fake_backend.ex `{:ok, Enum.map(documents, &document_id/1)}`]. Today it passes through `normalize_write_result/3` untouched. The multi-chunk combiner must tolerate non-map `{:ok, _}` chunk results by treating them as a chunk with no task.

### Pattern 3: Chunked, unique, transactional enqueue
The current unique policy, verbatim [VERIFIED: lib/scrypath/oban/enqueue.ex:119-120]:
```elixir
      # Jobs load current records when they run, so an identical pending batch adds nothing.
      unique: [period: :infinity, states: [:available, :scheduled, :retryable]]
```
Oban's defaults that fill in `fields`/`keys`, verbatim [VERIFIED: deps/oban/lib/oban/job.ex:232-238]:
```elixir
  @unique_defaults %{
    fields: ~w(args queue worker)a,
    keys: [],
    period: 60,
    states: ~w(scheduled available executing retryable completed)a,
    timestamp: :inserted_at
  }
```
Uniqueness compares the **whole `args` map**, including the related job's `"opts"` map. The D-03 sort is therefore what makes `[2,1]` and `[1,2]` collapse.

How `Enqueue` gets its Oban instance: `Config.oban_module(config)` → `Keyword.fetch!(config, :oban)` [VERIFIED: lib/scrypath/config.ex:81-84]. The default is `Oban`, and a runtime option allows overriding it. Tests pass bare fake modules such as `RecordingOban`, `EnqueueOban` and `RetryableOban` that define only `insert/1` and have **no running instance and no repo** [VERIFIED: test/scrypath/oban/enqueue_test.exs:36-51; test/scrypath/sync/related_test.exs:89-95]. Recommended transaction shape:
```elixir
# Source: probe this session against Oban 2.23.0 (see Code Examples)
defp insert_chunks(oban, [single]), do: with({:ok, job} <- insert_job(oban, single), do: {:ok, [job]})

defp insert_chunks(oban, changesets) do
  case oban_conf(oban) do
    {:ok, conf} ->
      Oban.Repo.transaction(conf, fn ->
        case Scrypath.Chunks.reduce_ok(changesets, &insert_job(oban, &1)) do
          {:ok, jobs} -> jobs
          {:error, reason} -> Oban.Repo.rollback(conf, reason)
        end
      end)

    :none ->
      # Test fakes with no running instance: sequential, halt on first error.
      Scrypath.Chunks.reduce_ok(changesets, &insert_job(oban, &1))
  end
end

defp oban_conf(oban) do
  {:ok, Oban.config(oban)}
rescue
  RuntimeError -> :none   # "No Oban instance named ... is running" (deps/oban/lib/oban/registry.ex:31-40)
end
```
- Keep the existing `insert_job/2` `cond` that probes for `insert/1` and `insert/2`, so the fakes keep working [VERIFIED: lib/scrypath/oban/enqueue.ex:124-135].
- `Oban.Repo.transaction/3` is `@doc since: "2.18.1"` [VERIFIED: deps/oban/lib/oban/repo.ex:215], which is under the `~> 2.21` floor.
- Don't pass Oban-version-specific options such as `retry:`.
- All of this must live inside the `Code.ensure_loaded?(Oban.Job)` guard, or carry `@compile {:no_warn_undefined, [Oban, Oban.Repo]}` as `enqueue.ex` already does for `Oban` and `Oban.Job`.

### Pattern 4: `JobArgs` — today's raise inventory (what FAN-03 must close)
| Worker | Input | Today | File:line |
|--------|-------|-------|-----------|
| Related | missing `"document_ids"` or `"opts"` | `MatchError` raise | `related_worker.ex:11` |
| Related | unknown opts key | `String.to_existing_atom(k)` raises | `related_worker.ex:21` |
| Related | unknown backend/otp_app/repo string | `String.to_existing_atom(v)` raises | `related_worker.ex:18-20` |
| Related | schema is an existing atom but has no `__scrypath__/1` | `Metadata.fan_outs/1` → `UndefinedFunctionError`, not rescued (only `ArgumentError` is) | `related_worker.ex:80-92` |
| Related | backend never validated | crashes later in `Telemetry.common_metadata` (`backend.name()`) | `related_worker.ex:35-39` |
| Related | `Config.resolve!` invalid | `ArgumentError` raise | `related_worker.ex:26` |
| Upsert | repo string unknown | **silently ignored** (falls back) | `upsert_worker.ex:123-128` |
| Upsert/Delete | schema/backend unknown | already cancelled as `{:unknown_module, name}` | `upsert_worker.ex:132-147` |

The existing safe resolution to lift, verbatim [VERIFIED: lib/scrypath/oban/upsert_worker.ex:132-147]:
```elixir
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
`JobArgs` should return D-15 tags (`{:unknown_schema, name}`, …) in place of `{:unknown_module, name}`. For related schemas, "an existing loaded module" should also require `function_exported?(m, :__scrypath__, 1)`, and the fan-out lookup should be wrapped in a rescue. That closes the `UndefinedFunctionError` hole.

The related opts allowlist must match what `job_args/4` writes, verbatim [VERIFIED: lib/scrypath/sync/related_enqueue.ex:54-65]:
```elixir
        config
        |> Keyword.take([:index_prefix, :meilisearch_url, :backend, :otp_app, :repo])
        |> Enum.map(fn
          {key, value}
          when key in [:backend, :otp_app, :repo] and is_atom(value) and not is_nil(value) ->
            {key, to_string(value)}

          option ->
            option
        end)
```

### Pattern 5: Related worker flow (FAN-01)
1. `JobArgs.decode_related(args)` → `{:ok, %{schema, fan_out, document_ids, opts}}`, or `{:error, tag}` → `{:cancel, {:invalid_job, tag}}`.
2. `config = Config.resolve!(opts ++ [fan_out: key, sync_mode: :inline])`, rescued to `{:invalid_config, msg}`.
3. `Loader.load(schema, ids, config)` (chunked):
   - `{:error, r}` with `r in [:repo_required, :search_records_required]` → `{:cancel, {:invalid_job, r}}`. This mirrors `upsert_worker.ex:31-39`.
   - Any other `{:error, r}` → `{:error, r}` (retry).
4. `records == []` → `:ok`. The span still reports `missing_count`; the resolver is not called.
5. `apply(mod, fun, [records | extra])` → `Sync.sync_records(target, resolved, opts)`. This is already chunked by Pattern 1, inline mode.
6. Keep today's 4xx → `{:cancel, "HTTP …"}` mapping unchanged (D-19).

Pass span stop metadata as `Telemetry.stop_metadata(result, missing_count: length(missing))`. `stop_metadata/2` already accepts `extra` and already uses the key name `missing_count` elsewhere [VERIFIED: lib/scrypath/telemetry.ex:32-70].

### Anti-Patterns to Avoid
- **Chunking inside adapters only:** rejected by D-02. Fakes and Loader bypass it.
- **`insert_all` for chunked jobs:** OSS Oban drops `unique:` (D-04).
- **Merging one chunk's `backend_result` into a multi-chunk result:** D-09.
- **Deduping ids by `to_string`:** silently merges `1`/`"1"`. Sort by string, dedupe by value.
- **Calling the resolver with `[]`:** D-11 says the list is non-empty. Short-circuit to `:ok` (Oban) and to a noop (inline; see Open Question 5).
- **Creating atoms from job input:** `String.to_atom` is never acceptable. Use `to_existing_atom` inside a rescue, or the allowlist (D-17).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Job dedupe | A custom "pending job" lookup | Oban `unique:` (engine-enforced) | Race-free in the DB. Lite engine verified this session |
| Atomic multi-job insert | Manual cleanup on failure | `Oban.Repo.transaction/2` + `rollback/2` (or `Ecto.Multi`) | Rollback verified this session |
| Retry vs. stop | `{:discard, _}` / raising | `{:cancel, reason}` | `:discard` is deprecated [VERIFIED: deps/oban/lib/oban/worker.ex:379-380] |
| Chunking | A stream/GenStage pipeline | `Enum.chunk_every/2` | Lists are ≤ a few thousand ids; no back-pressure needed |
| Safe module decode | `String.to_atom` | `String.to_existing_atom` + `Module.safe_concat` (existing helper) | Atom-table exhaustion |

## Common Pitfalls

### Pitfall 1: Reindex only waits on the last chunk of each batch
**What goes wrong:** `Reindex.maybe_wait_for_backfill_tasks/2` waits on each `batch_result`'s `task` and then cuts over [VERIFIED: lib/scrypath/reindex.ex:198-216, 218-224]. With `batch_size: 5000`, backfill makes 5 upserts per batch. Meilisearch processes the 5 tasks in order and can fail chunk 2 independently while chunk 5 succeeds. Reindex would then swap an index that is missing documents.
**How to avoid:** Each backfill batch result keeps `task` (last upsert chunk) and gains `tasks` (all upsert chunk tasks, in order, D-08 naming). `maybe_wait_for_backfill_tasks/2` waits on every entry. Update `lib/scrypath.ex`'s backfill `## Result` docs (lines ~386-415). Live deletes (`delete_task`) are not waited on today, so an equivalent `delete_tasks` list is optional and docs-only.
**Warning signs:** a reindex test with `batch_size > 1000` asserts only one `GET /tasks/...` per batch.

### Pitfall 2: The `public_result/1` merge carries backend keys today
See Pattern 2. If the planner reads D-09 as "never merge, even for one chunk", these break: `sync_test.exs:252,271,344-367,377` (they match `sync_mode:` from the backend map) and `related_test.exs`. Recommendation: merge only when there is exactly one chunk.

### Pitfall 3: Owner-only fan-out schemas have no `:preload` clause
`Loader.fetch/3` (default path) calls `Metadata.preload(schema_module)` [VERIFIED: lib/scrypath/loader.ex:145]. That is `schema_module.__scrypath__(:preload)` [VERIFIED: lib/scrypath/schema/metadata.ex:19-21,51]. Hand-written owner-only schemas, which the guide says "remain supported as a low-level escape hatch", define only `:fan_outs` and `:document_id`:
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex:29-39`
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/category.ex:11-20`
- `test/scrypath/sync/related_test.exs` `DummySource`
- `test/scrypath/sync_test.exs` `SourceSchema`
- `test/scrypath/sync/related_worker_test.exs` `DummySchema` and `ErrorSchema`, which are plain `defstruct` modules, not Ecto schemas

Under D-11, the Oban related worker would raise `FunctionClauseError` for all of them, and Oban would retry it 8 times.
**How to avoid:** In `Loader`, treat a schema that doesn't answer `:preload` as `[]`, for example a private `preload_for(schema)` that rescues `FunctionClauseError`. That keeps the documented escape hatch working. Test fixtures that are plain structs must define `search_records/2`, because the default `from(r in schema)` path needs an Ecto schema.

### Pitfall 4: Both example apps break on the Oban fan-out path
- **phoenix_meilisearch.** The Oban related smoke test's `sync_opts` has no `:repo` [VERIFIED: examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs:69-76], and the app config sets no `:scrypath` repo default [VERIFIED: examples/phoenix_meilisearch/config/config.exs:10-17]. D-12's `ensure_loadable!` raises at enqueue. That is the advisory `phoenix-example` CI lane.
- **scrypath_ecommerce.** `:scrypath, :defaults` has no `:repo` [VERIFIED: examples/scrypath_ecommerce/config/config.exs:14-20], so `update_category/3` raises at enqueue. Even with a repo, the default loader would call `Repo.all/1` without `skip_tenant_id`, and `Repo.prepare_query/3` raises `"expected :tenant_id or :skip_tenant_id to be set in Repo options"` [VERIFIED: examples/scrypath_ecommerce/lib/scrypath_ecommerce/repo.ex:9-21]. This breaks `catalog_test.exs:81-99` and the advisory full-e2e `storefront.spec.ts:96+`. The **required** `ecommerce-mounted` focused lane runs only `harness.spec.ts` and `operator.spec.ts`, which don't touch fan-out [VERIFIED: examples/scrypath_ecommerce/docker-playwright.sh:44-46].
- Both examples also call `sync_related` inside an open `Repo.transaction` (ecommerce `catalog.ex:65-71` `Multi.run`), which D-13 now documents against.
**Recommendation:** see Open Question 3. The example resolvers' id clauses become dead code but remain harmless.

### Pitfall 5: The related job's `"opts"` carries `nil` values
`job_args/4` takes keys from the **resolved** config, so `index_prefix`, `otp_app` and `repo` are present with `nil` when unset (Pattern 4 quote: `nil` values fall through to `option -> option`). `JobArgs` must treat `"repo" => nil` and `"otp_app" => nil` as absent. The D-22 legacy fixture should include these `nil`-valued keys so it matches what 0.3.17 actually wrote.

### Pitfall 6: D-12 changes existing Oban related tests
`related_test.exs` "sync_mode: :oban enqueues a job" and "generated use Scrypath fan_out metadata is consumed for oban enqueue" pass no `:repo` [VERIFIED: test/scrypath/sync/related_test.exs:123-194]. They must add `repo: FakeRepo` or have the fixture define `search_records/2`. `related_worker_test.exs` resolvers take ids (`resolve_comments([_ | _] = ids, :extra_arg)`), and `ErrorSchema` encodes the error type in the **id**. These fixtures must be rewritten so `search_records/2` returns structs and the resolver reads them.

### Pitfall 7: `FakeRepo` fails D-16's repo check
`FakeRepo` defines only `put_records/1`, `reset/0` and `all/1` [VERIFIED: test/support/fake_repo.ex]. D-16 requires `function_exported?(m, :__adapter__, 0)`, so D-18 would cancel every existing worker test that passes `"repo" => FakeRepo` [VERIFIED: test/scrypath/oban/worker_test.exs:93-106]. Add `def __adapter__, do: Ecto.Adapters.SQLite3` (any adapter atom) to `FakeRepo` in Wave 0. Also `Code.ensure_loaded?(FakeRepo)` is true because test/support is `Code.require_file`'d [VERIFIED: test/test_helper.exs].

### Pitfall 8: Legacy upsert jobs and D-18
The legacy snapshot tests delete `"repo"` from args [VERIFIED: test/scrypath/oban/worker_test.exs:151-189]. D-18 cancels only when a non-empty `"repo"` string is present and unresolvable, so these stay green. Also keep `{:cancel, {:invalid_job, :repo_required}}` for the no-repo, no-snapshot case (lines 154, 185). These are Loader reasons, not `JobArgs` tags.

### Pitfall 9: Empty trigger lists
`RelatedEnqueue.enqueue/4` currently enqueues a job even for `[]` records, and the inline path calls the resolver with `[]`. Both violate D-11's "non-empty". Return a noop result, consistent with `sync_records([])` [VERIFIED: lib/scrypath/sync.ex:30-33, 225-233].

### Pitfall 10: `in ^ids` parameter counts differ by adapter
D-01's "one parameter per element" holds for SQLite and MySQL. On Postgres, Ecto sends `= ANY($1)` with one array parameter [ASSUMED]. This doesn't change the decision; just don't write a test that asserts parameter counts.

### Pitfall 11: Docs-contract strings
`test/scrypath/phase108_contract_test.exs:28-32` asserts that the related guide contains `"durably queued"`, `"document IDs"` and `"records"`. The §(c) rewrite must keep the phrase "document IDs" (e.g. "Oban jobs carry document IDs and reload the records"), or update that test deliberately. `docs_contract_test.exs:1305-1323` asserts more required tokens; don't remove them.

## Runtime State Inventory

This is not a rename phase, but the change in job semantics affects queued state:

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Pending `Scrypath.Sync.RelatedWorker` jobs in adopters' `oban_jobs` with the 0.3.17 args shape (`schema`, `document_ids`, `fan_out`, `opts` with `nil` values) | None to migrate. D-22 keeps the shape. The test runs a hard-coded legacy map. Their resolvers now get structs: docs plus CHANGELOG |
| Stored data | Pending upsert/delete jobs with more than 1000 ids (pre-179) | None. Workers chunk on read (D-04) |
| Live service config | None. Verified: Meilisearch indexes are untouched; no index rename | none |
| OS-registered state | None. Library only | none |
| Secrets/env vars | None. `ensure_durable_api_key!/1` is unchanged | none |
| Build artifacts | None | none |

## Code Examples

### Verified: Oban Lite + SQLite uniqueness, transaction and rollback (probe run this session)
```elixir
# Ran as a throwaway test against deps oban 2.23.0, ecto_sqlite3 0.24.0; output below.
start_supervised!({Oban, name: ZzProbe.Oban, repo: ZzProbe.Repo, engine: Oban.Engines.Lite,
                   testing: :manual, notifier: Oban.Notifiers.PG})
cs = fn ids -> Oban.Job.new(%{"document_ids" => ids}, worker: "W", queue: "q",
               unique: [period: :infinity, states: [:available, :scheduled, :retryable]]) end
{:ok, j1} = Oban.insert(ZzProbe.Oban, cs.([1, 2]))
{:ok, j2} = Oban.insert(ZzProbe.Oban, cs.([1, 2]))
conf = Oban.config(ZzProbe.Oban)
Oban.Repo.transaction(conf, fn -> ... two inserts ... end)
Oban.Repo.transaction(conf, fn -> insert; Oban.Repo.rollback(conf, :boom) end)
```
Output observed:
```
unique: {1, false, 1, true}
txn: {:ok, [2, 3]}
rollback: {:error, :boom}
enqueued count: 3
```
- The setup used `Ecto.Migrator.up(repo, 1, Migration)` with `def up, do: Oban.Migrations.up()`, which dispatches to `Oban.Migrations.SQLite` [VERIFIED: deps/oban/lib/oban/migration.ex:273], and `use Oban.Testing, repo: ZzProbe.Repo, engine: Oban.Engines.Lite`.
- One `[error] Exqlite ... database is locked` connection-log line appeared and was benign. Use `journal_mode: :wal, busy_timeout: 5_000`, as `SQLiteSandboxRepo` does [VERIFIED: test/support/sqlite_sandbox_repo.ex:16-25].
- Use a **dedicated** repo module. `LoaderBackfillCases.setup_repo!/1` runs `storage_down` and `start_supervised!` on `SQLiteSandboxRepo` [VERIFIED: test/support/loader_backfill_cases.ex:487-515].

### Result struct change
Current struct, verbatim [VERIFIED: lib/scrypath/operations/result.ex:6-7]:
```elixir
  @enforce_keys [:mode, :status]
  defstruct [:mode, :status, document_ids: [], document_count: 0, task: nil, metadata: %{}]
```
Add `tasks: []` and update `@type t` and `to_public_sync/1`. `Result.new/1` uses `struct!/2`, so existing callers that omit `tasks` stay valid.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `{:discard, reason}` | `{:cancel, reason}` | Oban 2.x (`:discard` documented deprecated in 2.23 source) | Use cancel (D-14) |
| `insert_all` + unique | per-job `insert` in a transaction (OSS) | OSS `insert_all` doesn't do unique; the Pro Smart Engine does [CITED: oban.hexdocs.pm/unique_jobs.html per CONTEXT] | D-04 |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Postgres `in ^list` is sent as `= ANY($1)` (one array param) | Pitfall 10 | None to the plan; informational |
| A2 | Within one Meilisearch `documentAdditionOrUpdate` payload, the last duplicate id wins, so `by_id` keeping the last occurrence matches today's single-call behaviour | Pattern 1 | Low; dedupe changes which duplicate is sent only for callers that pass duplicates |
| A3 | Meilisearch processes an index's tasks in enqueue order, and one failed task doesn't fail later ones | Pitfall 1 | If wrong in the other direction, waiting on all tasks is still correct, just redundant |

## Open Questions

1. **Public `Scrypath.Oban.enqueue_upsert/5` / `enqueue_delete/5` Multi helpers (not in D-02).**
   - They put one job per Multi step [VERIFIED: lib/scrypath/oban.ex:12-38]. Chunking would mean N Multi steps with derived names, which changes adopters' Multi result keys.
   - Recommendation: leave the shape unchanged in this phase. Workers bound the work on read (D-04). Add one doc sentence. Confirm with the maintainer only if they want args bounded there too.
2. **FAN-03 matrix applicability.**
   - Upsert/delete args carry `schema`, `backend`, `index`, `document_ids`, `document_count` and `repo`, but **no `otp_app` and no fan-out** [VERIFIED: lib/scrypath/oban/payload.ex:20-40]. Only related `opts` carries `otp_app`, and `fan_out` is related-only.
   - The delete worker receives `"repo"` but never uses it.
   - Recommendation: test the applicable cells only:
     - related: schema, fan_out, backend, repo, otp_app, `document_ids`, `opts`
     - upsert: schema, backend, repo, `document_ids`, index
     - delete: schema, backend, `document_ids`, `document_count`, index
   - The delete worker should **not** cancel on an unknown repo, because it can still delete correctly.
   - Record this as a plan-level interpretation of D-23.
3. **Example apps (Pitfall 4).**
   - The CONTEXT says library-only, but a library change breaks both examples' Oban fan-out path: one advisory CI lane plus the ecommerce unit test and advisory e2e.
   - Options:
     - (a) Include minimal example fixes in this phase: pass or configure `repo`, and give ecommerce `Category` a `search_records/2` that uses `skip_tenant_id: true`.
     - (b) Defer to a follow-up and accept advisory-lane red.
   - Recommendation: (a). It is small, keeps `main` truthful, and the example resolvers already accept structs. It needs a maintainer nod because it widens the file scope.
4. **`conflict?` on the public map.**
   - D-21 puts it in `Operations.Task.metadata`, but `sync_records/3` returns the public map, not the struct. The FAN-02 test therefore needs `conflict?` on `public_job/1`.
   - Recommendation: always include `conflict?: boolean` in each public job map (`job:` and `tasks:` entries).
5. **Inline `sync_related(schema, [])`.**
   - Recommendation: noop without calling the resolver (D-11 "non-empty"). This is a tiny behaviour change; mention it in the guide.
6. **CHANGELOG mechanics.**
   - The repo uses Release Please with default sections and no `Changed` section [VERIFIED: release-please-config.json]. The 0.3.16 "Upgrade notes" block was hand-edited into the release PR.
   - Recommendation: write the D-13 sentence into the PR body and commit footer, and add it to CHANGELOG on the release PR under an "Upgrade notes"/"Changed" heading, as 0.3.16 did. Don't add an `## Unreleased` section that Release Please would not manage.
7. **`missing_count` on the related public result (discretion).** Under Oban the related public result is the enqueue result. `missing_count` exists only at worker time, so it can only be span metadata there. Recommendation: span metadata only.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP | all | ✓ (asdf; repo has no `.tool-versions`) | run with `ASDF_ERLANG_VERSION=28.1 ASDF_ELIXIR_VERSION=1.19.0-otp-28` (CI tuple) | 1.17.3-otp-27 also installed |
| SQLite (ecto_sqlite3/exqlite) | FAN-02 Oban.Testing test, backfill chunk case | ✓ | 0.24.0 | — |
| Oban | enqueue/worker tests | ✓ | 2.23.0 | — |
| Postgres | `mix verify.postgres` (backend lane) | not probed; compose on :5434 per CONTRIBUTING | — | hosted `backend` job |
| Meilisearch | `mix verify.backend` integration | not probed | — | hosted `backend` job |

Baseline this session: `mix test test/scrypath/sync_test.exs test/scrypath/oban test/scrypath/sync test/scrypath/loader_test.exs test/scrypath/backfill_test.exs test/scrypath/oban_test.exs` → **69 tests, 0 failures, 0.5s**.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (CI Elixir 1.19.0 / OTP 28.1) + `Oban.Testing` (new usage) |
| Config file | `test/test_helper.exs` (composed `exclude:`; `test/support/**/*.ex` required) |
| Quick run command | `mix test test/scrypath/sync_test.exs test/scrypath/oban test/scrypath/sync test/scrypath/loader_test.exs test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs test/scrypath/oban_test.exs test/scrypath/loader_backfill_sqlite_test.exs` |
| Full suite command | `mix verify.core --exclude integration --exclude docs_contract`, then `mix test --only docs_contract` (or `mix verify.phase108`) for guide changes |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PAGE-03 | 2,500 records inline/manual → 3 upsert calls ≤1000, combined `document_count: 2500`, `tasks` length 3 (task-returning recording backend) | unit | `mix test test/scrypath/sync_test.exs` | ✅ file; ❌ cases |
| PAGE-03 | `delete_documents` 2,500 ids → 3 delete calls, combined result | unit | same | ❌ cases |
| PAGE-03 | chunk-2 failure → `{:error, r}`, chunk 3 never sent (inline and manual); inline waits per chunk (Req.Test stub sees N task GETs) | unit | same | ❌ |
| PAGE-03 | single-chunk result unchanged plus one-element `tasks` (existing assertions stay green) | regression | same | ✅ |
| PAGE-03 | Oban: 2,500 ids → 3 jobs (fake Oban counts inserts), combined `tasks` of 3 jobs, `job:` = last | unit | `mix test test/scrypath/oban/enqueue_test.exs` | ✅ file; ❌ case |
| PAGE-03 | Oban multi-chunk insert is transactional: an invalid 2nd changeset → `{:error, _}` and 0 jobs persisted | integration (SQLite Oban) | `mix test test/scrypath/oban/enqueue_unique_test.exs` | ❌ Wave 0 |
| PAGE-03 | `Loader.load/3` with 2,500 ids → `search_records/2` spy sees 3 calls, each ≤1000; `missing` correct across chunks | unit | `mix test test/scrypath/loader_test.exs` | ✅ file; ❌ case |
| PAGE-03 | UpsertWorker job with 2,500 ids (legacy >1000) → 3 loads, 3 upserts, missing-id deletes chunked and after the upserts | unit | `mix test test/scrypath/oban/worker_test.exs` | ❌ case |
| PAGE-03 | DeleteWorker 2,500 ids → 3 delete calls | unit | same | ❌ |
| PAGE-03 | backfill `batch_size: 5000` over 2,500 rows → 1 batch, 3 upserts, batch `tasks` length 3; reindex waits every chunk task | integration (SQLite shared cases) + unit | `mix test test/scrypath/loader_backfill_sqlite_test.exs test/scrypath/reindex_test.exs` | ❌ cases |
| FAN-01 | inline resolver gets caller structs | unit | `mix test test/scrypath/sync/related_test.exs` | ✅ |
| FAN-01 | Oban RelatedWorker: resolver gets loaded structs (`search_records/2` fixture); deleted trigger skipped and `missing_count` in span stop metadata (`:telemetry.attach`); all missing → resolver not called, `:ok`; soft-deleted excluded | unit | `mix test test/scrypath/sync/related_worker_test.exs` | ❌ cases (fixtures rewritten) |
| FAN-01 | `sync_related` under Oban raises at the call site without repo/loader (D-12) | unit | `mix test test/scrypath/sync/related_test.exs` | ❌ |
| FAN-01 | owner-only hand-written schema without `:preload` loads under Oban | unit | `mix test test/scrypath/loader_test.exs` | ❌ |
| FAN-02 | enqueue related twice with ids `[2,1]` then `[1,2]` → one job, second result `conflict?: true` | integration (SQLite Oban, `testing: :manual`) | `mix test test/scrypath/oban/enqueue_unique_test.exs` | ❌ Wave 0 |
| FAN-02 | related changeset carries `unique_opts/0` (fake Oban: `job.unique[:states] == [:available, :scheduled, :retryable]`) | unit | `mix test test/scrypath/sync/related_test.exs` | ❌ |
| FAN-03 | per-worker × applicable bad arg → `{:cancel, {:invalid_job, tag}}`, never raises (Open Question 2 matrix) | unit (table-driven) | `mix test test/scrypath/oban/job_args_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync/related_worker_test.exs` | ❌ Wave 0 (`job_args_test.exs`) |
| FAN-03 | unknown opts key ignored (D-17); `nil` opts values are absent | unit | same | ❌ |
| FAN-03 / D-18 | upsert with an unresolvable `"repo"` → `{:cancel, {:invalid_job, {:unknown_repo, name}}}`; legacy snapshot tests (no `"repo"`) stay green | unit | `mix test test/scrypath/oban/worker_test.exs` | ✅ legacy; ❌ new |
| D-22 | hard-coded 0.3.17 related args map (incl. `nil` opts) runs through `perform/1` → `:ok` | unit | `mix test test/scrypath/sync/related_worker_test.exs` | ❌ |
| D-13 | guide contract strings still present | docs contract | `mix verify.phase108` and `mix test test/scrypath/docs_contract_test.exs --include docs_contract` | ✅ |

### Sampling Rate
- **Per task commit:** the quick run command (well under 30s, no services).
- **Per wave merge:** quick run + `mix compile --warnings-as-errors` + `mix credo --strict` + `mix format --check-formatted` + `mix verify.phase108`.
- **Phase gate:** `mix verify.core --exclude integration --exclude docs_contract` locally, then hosted PR checks green on the exact SHA: `core`, `package`, `repository-contracts`, `backend` (runs `mix verify.postgres`, so the shared backfill chunk case runs on real Postgres too), `ecommerce-mounted`. Advisory `phoenix-example` should be green if Open Question 3 resolves to (a).

### Wave 0 Gaps
- [ ] `test/support/oban_sqlite_repo.ex` + an inline Oban migration module (`Oban.Migrations.up()`): dedicated repo with WAL and busy_timeout
- [ ] `test/scrypath/oban/enqueue_unique_test.exs` (`async: false`, `use Oban.Testing, repo: …, engine: Oban.Engines.Lite`; start `{Oban, testing: :manual, engine: Oban.Engines.Lite, notifier: Oban.Notifiers.PG, name: …}` in `setup_all`)
- [ ] `test/scrypath/oban/job_args_test.exs` (pure, table-driven)
- [ ] `FakeRepo.__adapter__/0` (Pitfall 7)
- [ ] A task-returning recording backend for the 3-`tasks` assertions (reuse the `SeamBackend` style from `sync_test.exs:64-134`, with a counter in the process dictionary for unique uids)
- [ ] Rewrite the related fixtures to define `search_records/2` and struct-taking resolvers (Pitfall 6)

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no (tenant scoping is the adopter's `search_records/2`) | — |
| V5 Input Validation | yes: Oban job args are persisted, mutable input | `JobArgs` allowlist + `String.to_existing_atom` in a rescue + `Module.safe_concat` + behaviour checks (D-15–D-17) |
| V6 Cryptography | no | — |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom-table exhaustion via crafted job args | DoS | never `String.to_atom`; allowlisted keys (D-17) |
| Arbitrary module invocation via `"schema"`/`"backend"`/`"repo"` strings | Elevation/Tampering | require an existing module **and** the expected callbacks (`__scrypath__/1`, backend callbacks, `__adapter__/0`) before calling anything |
| Unbounded payload, memory or SQL params from huge id lists | DoS | 1000-id chunks at every site (PAGE-03) |
| Tenant leak via the default loader on tenant-scoped repos | Information disclosure | Owner schemas on tenant repos must define `search_records/2` (ecommerce `Category`; Pitfall 4) |

## Sources

### Primary (HIGH confidence)
- Repo source read this session: `lib/scrypath/{sync,loader,backfill,reindex,operations,config,options,telemetry,oban}.ex`, `lib/scrypath/operations/{result,task}.ex`, `lib/scrypath/oban/{enqueue,upsert_worker,delete_worker,payload,job_config,indexing_ack}.ex`, `lib/scrypath/sync/{related_enqueue,related_worker}.ex`, `lib/scrypath/schema/metadata.ex`, `lib/scrypath/identity.ex`, `lib/scrypath/operator/recovery_action.ex`
- Tests: `test/scrypath/{sync_test,oban/enqueue_test,oban/worker_test,sync/related_test,sync/related_worker_test,backfill_test,phase108_contract_test}.exs`, `test/support/{fake_repo,fake_backend,sqlite_sandbox_repo,loader_backfill_cases}.ex`
- Vendored Oban 2.23.0: `deps/oban/lib/oban.ex` (insert/insert_all/`use Oban` facade), `lib/oban/job.ex:232-238,655-680`, `lib/oban/repo.ex:1-30,205-235`, `lib/oban/registry.ex:31-40`, `lib/oban/worker.ex:371-386`, `lib/oban/engines/lite.ex` (unique), `lib/oban/testing.ex`, `lib/oban/migration.ex:273`
- Executed probe: Oban Lite + SQLite uniqueness, transaction and rollback (output above)
- Examples: `examples/phoenix_meilisearch/{config/config.exs,lib/scrypath_demo/blog/author.ex,test/smoke/meilisearch_related_oban_stack_test.exs}`, `examples/scrypath_ecommerce/{config/config.exs,lib/scrypath_ecommerce/catalog.ex,catalog/category.ex,repo.ex,docker-playwright.sh}`
- `CONTRIBUTING.md:20-41,220-234`, `.github/workflows/ci.yml:167-193`, `release-please-config.json`

### Secondary (MEDIUM confidence)
- Oban hexdocs unique jobs / `insert_all` Pro note, as cited in CONTEXT (not re-fetched; consistent with the vendored source)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. No new deps; versions read from `mix.lock`.
- Architecture: HIGH. Every call site read; Oban behaviour probed.
- Pitfalls: HIGH for 1–9 and 11 (each read in source); LOW for 10 (assumed, non-blocking).

**Research date:** 2026-10-25
**Valid until:** 2026-11-24 (stable internal code; re-check if Oban is bumped past 2.23)
