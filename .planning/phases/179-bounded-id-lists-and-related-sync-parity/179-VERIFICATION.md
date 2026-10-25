---
phase: 179-bounded-id-lists-and-related-sync-parity
verified: 2026-10-25T23:30:00Z
status: passed
score: 4/4 roadmap success criteria verified (plan must-have truths 63/63 verified)
covered_files: [".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-01-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-01-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-02-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-02-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-03-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-03-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-04-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-04-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-05-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-05-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-06-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-06-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-07-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-07-SUMMARY.md","examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex","examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex","examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs","examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex","examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/category.ex","guides/related-data-and-reindexing.md","guides/sync-modes-and-visibility.md","lib/scrypath.ex","lib/scrypath/backfill.ex","lib/scrypath/chunks.ex","lib/scrypath/loader.ex","lib/scrypath/oban.ex","lib/scrypath/oban/delete_worker.ex","lib/scrypath/oban/enqueue.ex","lib/scrypath/oban/job_args.ex","lib/scrypath/oban/upsert_worker.ex","lib/scrypath/operations.ex","lib/scrypath/operations/result.ex","lib/scrypath/reindex.ex","lib/scrypath/sync.ex","lib/scrypath/sync/related_enqueue.ex","lib/scrypath/sync/related_worker.ex","test/scrypath/backfill_test.exs","test/scrypath/chunks_test.exs","test/scrypath/loader_test.exs","test/scrypath/oban/enqueue_test.exs","test/scrypath/oban/enqueue_unique_test.exs","test/scrypath/oban/job_args_test.exs","test/scrypath/oban/worker_test.exs","test/scrypath/reindex_test.exs","test/scrypath/sync/related_test.exs","test/scrypath/sync/related_worker_test.exs","test/scrypath/sync_test.exs","test/support/fake_repo.ex","test/support/loader_backfill_cases.ex","test/support/oban_sqlite_migration.ex","test/support/oban_sqlite_repo.ex"]
covered_digest: "v3:sha256:f826e7f1c14e79371ea26287eb4dc72c8573b13284602c0b637cd3727b486108"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 179: Bounded id lists and related-sync parity — Verification Report

**Phase Goal:** Large id sets never produce unbounded loads or backend calls, and related-record sync gives resolvers the same input and the same queue behaviour in every sync mode, failing cleanly on bad job arguments.
**Verified:** 2026-10-25T23:30:00Z
**Status:** passed (with open non-blocking warnings; see Warnings)
**Re-verification:** No — initial verification

## Goal Achievement

### Roadmap Success Criteria

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | 2,500 ids → three record loads and three backend upsert (and delete) calls of ≤1000 ids, one combined result | ✓ VERIFIED | `Scrypath.Chunks` (`@max_ids 1000`) used by `Sync.dispatch_upsert/dispatch_delete` (`Chunks.by_id`/`Chunks.ids` + `Chunks.reduce_ok` + `combine_chunks`), `Loader.fetch_chunks`, `Backfill.write`, `UpsertWorker.write`, `DeleteWorker.write`, `Enqueue.enqueue_upsert/delete`, `RelatedEnqueue`. Tests (run, green): `sync_test.exs` "inline sync of 2,500 records sends three bounded upserts and one combined result", "delete_documents of 2,500 ids sends three bounded deletes…"; `worker_test.exs` "upsert worker loads and upserts 2,500 ids in chunks" (3 `search_records` loads ≤1000, 3 upserts ≤1000), "delete worker sends 2,500 ids as three chunks"; `loader_test.exs` 2,500-id load; `enqueue_unique_test.exs` "2,500 records enqueue three chunk jobs" (real Oban Lite); `backfill_test.exs` / `loader_backfill_cases.ex` batch_size 5000 → 3 upserts. |
| 2 | `sync_related` resolver gets loaded records under inline and Oban; Oban worker loads via the loader before resolving | ✓ VERIFIED | `RelatedWorker.run/3` calls `Loader.load(schema, document_ids, config)` then `resolve` with structs; empty → noop without resolver (`sync_resolved(_, [], _)`). Inline path passes caller structs (`inline_resolve_and_sync`), empty inline → `noop_result`. Tests: `related_worker_test.exs` "perform/1 loads trigger structs, runs the resolver with them…" (asserts `search_records` called and resolver got `%DummySchema{}`), partial-missing / soft-deleted / all-missing cases with `missing_count`; `related_test.exs` inline case. Resolver fixtures only match `[%__MODULE__{} | _]`, so an id list would FunctionClauseError. |
| 3 | Enqueueing the same related sync twice yields one job (same `unique:` policy) | ✓ VERIFIED | `RelatedEnqueue` builds changesets with `unique: Enqueue.unique_opts()` and inserts via `Enqueue.enqueue_chunks/3` (shared path). Test against real Oban (Lite engine, `testing: :manual`): `enqueue_unique_test.exs` "a repeated related sync in a different trigger order collapses into one job (FAN-02)" — one `RelatedWorker` job, second result `conflict?: true`, same job id. |
| 4 | Related, upsert and delete jobs naming an unknown schema, fan-out, backend, repo or app finish with a clear non-retrying error, not a `String.to_existing_atom` raise | ✓ VERIFIED | `Scrypath.Oban.JobArgs` decodes all three job kinds; every failure is `{:error, tag}` → workers return `{:cancel, {:invalid_job, tag}}`. `String.to_existing_atom` only inside `rescue` (`existing_atom/1`, `safe_module/1`). Tests: `related_worker_test.exs` FAN-03 matrix (schema, fan_out, backend, repo, otp_app, missing document_ids/opts; asserts no raise); `worker_test.exs` upsert bad-args matrix (schema, backend, repo, document_ids, index); `job_args_test.exs` delete/upsert/related tables, atom-count safety, and the CR-01 release regression (runtime-built module whose alias segments are not atoms resolves for all three decoders). |

**Score:** 4/4 success criteria verified; 0 present-but-behavior-unverified.

### Plan must-have truths (179-01 … 179-07)

All plan truths were checked against code and the tests above. Highlights beyond the SC rows:

| Truth | Status | Evidence |
|---|---|---|
| Chunks dedupe + `{to_string(id), id}` sort, 1000/1001 boundaries, shuffle-stable | ✓ VERIFIED | `chunks.ex` `ids/1`, `sort_key/1`; `chunks_test.exs` green |
| Failed chunk halts later chunks, bare `{:error, reason}` | ✓ VERIFIED | `Chunks.reduce_ok`; `sync_test.exs` "a failed chunk halts later chunks…" (inline + manual) |
| Inline waits per chunk; manual never waits | ✓ VERIFIED | `maybe_wait_for_task/2` inside the per-chunk reducer; sync_test Req.Test task-GET tests green |
| One telemetry span over the whole chunked call | ✓ VERIFIED | single `Telemetry.span([:scrypath, :sync, :upsert/:delete])`; sync_test `{:upsert_stop, 2500}` |
| `conflict?:` on every public job map, default false | ✓ VERIFIED | `Sync.public_job/1`, `Operations.task_from_job/1` |
| Reindex waits on every chunk task before cutover | ✓ VERIFIED | `Reindex.maybe_wait_for_batch_tasks/2` iterates `tasks`; reindex_test green |
| Multi-chunk enqueue uses `Oban.insert` (never `insert_all`) in one transaction, rolled back on failure | ✓ VERIFIED | `Enqueue.insert_chunks/2`; no `insert_all` in `lib/`; enqueue_unique_test rollback test |
| `unique_opts/0` = `[period: :infinity, states: [:available, :scheduled, :retryable]]`, no keys | ✓ VERIFIED | `enqueue.ex`; related_test "every related job carries the shared unique policy" |
| `ensure_loadable!` before related enqueue | ✓ VERIFIED | `RelatedEnqueue.enqueue/4`; related_test "raises at the call site…" |
| Related job args shape unchanged; 0.3.17 args with nil opts run to `:ok` | ✓ VERIFIED | `job_args/4` keys `schema/document_ids/fan_out/opts`; related_worker_test legacy fixture |
| Owner-only schemas without `:preload` load without FunctionClauseError | ✓ VERIFIED | `Loader.preload_for/1` rescue scoped to `__scrypath__`; loader_test green |
| Docs: §(c) "What your resolver receives", chunking/tasks/halt/inline_timeout/conflict?, no-ordering contract, fixed chunk size | ✓ VERIFIED | `guides/related-data-and-reindexing.md:175,221,230,236`; `guides/sync-modes-and-visibility.md:31,35,61,69,129,150`; `lib/scrypath.ex:395-397`; docs_contract suite 74/0 (orchestrator run) |
| CHANGELOG not hand-edited | ✓ VERIFIED | `git diff 1d3399c1..HEAD -- CHANGELOG.md` empty |
| PROJECT.md marks the three v1.44 items done for Phase 179 | ✓ VERIFIED | `.planning/PROJECT.md:523-526` |
| Ecommerce `Category.search_records/2` with explicit `skip_tenant_id: true`, exact ids | ✓ VERIFIED (code) | `category.ex:25-28`; catalog_test.exs unmodified. Test run is executor-reported (native PG); not re-run here (example deps lock out of date in this checkout). Hosted `ecommerce-mounted`/`phoenix-example` lanes must be green on the PR SHA. |
| Phoenix Oban related smoke passes `repo:` | ✓ VERIFIED (code) | smoke test line 75 `repo: ScrypathDemo.Repo`; live run executor-reported; hosted `phoenix-example` lane pending on PR |

Backstop truths (non-inferable; verified by directly observed behaviour, not presence):

| Truth | Status | Evidence |
|---|---|---|
| PAGE-03 idempotency: re-running a halted chunked sync re-sends every chunk | ✓ VERIFIED | Throwaway probe (scratchpad, `MIX_ENV=test mix run`): 2,500 records, backend fails chunk 2 → 2 upsert calls, `{:error, :boom}`; re-run → 3 calls, chunk 1 identical, all 2,500 ids, `document_count: 2500`. |
| FAN-03 concurrency: JobArgs pure, concurrent bad jobs cancel independently | ✓ VERIFIED | Same probe: 200 concurrent `RelatedWorker.perform/1` calls with distinct unknown schemas → each returned `{:cancel, {:invalid_job, {:unknown_schema, own_name}}}`. `job_args.ex` holds no process/ETS state. |
| FAN-01 ordering: set semantics, no order promised | ✓ VERIFIED | `Chunks.ids` dedupes; guide line 236 "No ordering contract."; resolver tests compare sorted ids. |

### Prohibitions (judgment tier — non-authoritative LLM-judge verdicts)

All 21 prohibitions across plans 01–07 were judged against code; none violated. Notable checks: no `:batch_size`/chunk-size option (`Chunks` has no option; `batch_size` stays backfill paging); no per-chunk telemetry span; no `Oban.insert_all`; unique policy omits `:executing` and has no `keys:`; no `String.to_atom` in `lib/scrypath/oban` or `lib/scrypath/sync`; resolver never called with ids or `[]`; all-missing related job returns `:ok`; reindex waits on every chunk task; CHANGELOG untouched; examples change only 5 files, no ops/UI/CI changes.
One partial tension, flagged: plan 05's D-22 prohibition rationale ("0.3.17 jobs already queued … keep running") holds only when the trigger schema is loadable — see WR-03 below.

### Behavioral spot-checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase test files | `mix test` on chunks, sync, worker, related_worker, related, enqueue_unique, job_args, loader, backfill, reindex, enqueue tests (`--exclude integration`) | 214 tests, 0 failures | ✓ PASS |
| Halt + re-run convergence; concurrent bad-job cancel | scratchpad probe via `MIX_ENV=test mix run` | as above | ✓ PASS |
| Full suite / docs contract / warnings-as-errors / format | orchestrator run | 837/0, 74/0, clean | ✓ PASS (orchestrator) |
| Ecommerce catalog_test | `PGHOST=127.0.0.1 mix test test/scrypath_ecommerce/catalog_test.exs` | could not run: example deps lock mismatch in this checkout (did not run `deps.get`) | ? SKIP → hosted lane |

### Probe Execution

No `scripts/*/tests/probe-*.sh` declared by this phase. Not applicable.

### Requirements Coverage

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| PAGE-03 | 01, 02, 03, 04, 05, 06 | ✓ SATISFIED | SC-1 row |
| FAN-01 | 01, 05, 06, 07 | ✓ SATISFIED | SC-2 row |
| FAN-02 | 03, 05, 06 | ✓ SATISFIED | SC-3 row |
| FAN-03 | 04, 05, 06 | ✓ SATISFIED | SC-4 row |

No orphaned requirements: REQUIREMENTS.md maps exactly PAGE-03, FAN-01, FAN-02, FAN-03 to Phase 179, all claimed by plans. (REQUIREMENTS.md checkboxes/traceability still read "Pending"; update at phase close.)

### Anti-Patterns Found

No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER markers in any of the 37 changed non-planning files. No stubs.

### Warnings (open review findings — none defeats a must-have)

| Finding | Severity | Assessment |
|---|---|---|
| WR-01 multi-chunk enqueue opens/rolls back its own transaction inside a caller's transaction | ⚠️ WARNING | Plan intentionally specified the transaction (D-04); SCs and truths hold. Behaviour inside an outer `Ecto.Multi` with >1000 ids differs from ≤1000 (outer txn poisoned). Owner decision needed; fix in the review (check `Oban.Repo.in_transaction?/1`) is small. |
| WR-03 in-flight 0.3.17 related jobs from repo-less apps cancel `:repo_required` on upgrade | ⚠️ WARNING | Fails cleanly (non-retrying), consistent with D-12 and SC-4, but the 179-06 release note does not tell adopters to configure `:repo`/drain the queue before upgrading. Add an upgrade-note line before release. |
| WR-04 backfill reports only the last delete chunk task | ⚠️ WARNING | Outside the SC wording (SC-1 covers calls, not delete task reporting); reindex cutover waits on upsert chunk tasks. Docs tell callers to follow `delete_task`, which is insufficient for >1000 removals/page. |
| WR-05 span start count pre-dedupe; ≤1000 results now deduped + string-sorted | ⚠️ WARNING | D-08's "exactly today's map" holds for keys/shape; `document_ids` order/dedupe changed per D-03 set semantics. Telemetry start/stop count mismatch for duplicate input matters for Phase 180. |
| IN-01..IN-05 | ℹ️ INFO | No must-have impact. |
| CR-01, WR-02 | fixed | 858e83dc (verified by `job_args_test.exs` runtime-module tests), 4d74ed9d (`document_ids elements` tests). |

### Human Verification Required

None. Remaining example-lane evidence is exact-SHA hosted CI (`phoenix-example`, `ecommerce-mounted`) on the phase PR, per project policy.

### Gaps Summary

No gaps. All four roadmap success criteria and all plan must-have truths are backed by passing tests or directly observed behaviour. The open review warnings (WR-01, WR-03, WR-04, WR-05) are quality and upgrade-communication issues that do not defeat the phase goal; WR-03 (upgrade note) and WR-01 (nested transaction) should be resolved or explicitly accepted before the release that ships this phase.

---

_Verified: 2026-10-25T23:30:00Z_
_Verifier: Claude (gsd-verifier)_
