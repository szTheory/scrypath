---
phase: 179-bounded-id-lists-and-related-sync-parity
verified: 2026-10-25T23:47:42Z
status: passed
score: 4/4 roadmap success criteria verified (plan must-have truths 63/63 verified; 8 deliberately narrowed by review fixes, recorded below)
covered_files: [".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-01-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-01-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-02-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-02-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-03-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-03-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-04-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-04-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-05-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-05-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-06-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-06-SUMMARY.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-07-PLAN.md",".planning/phases/179-bounded-id-lists-and-related-sync-parity/179-07-SUMMARY.md","examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex","examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex","examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs","examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex","examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/category.ex","examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex","examples/scrypath_ecommerce/test/scrypath_ecommerce/catalog_test.exs","examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs","guides/related-data-and-reindexing.md","guides/sync-modes-and-visibility.md","lib/scrypath.ex","lib/scrypath/backfill.ex","lib/scrypath/chunks.ex","lib/scrypath/loader.ex","lib/scrypath/oban.ex","lib/scrypath/oban/delete_worker.ex","lib/scrypath/oban/enqueue.ex","lib/scrypath/oban/job_args.ex","lib/scrypath/oban/payload.ex","lib/scrypath/oban/upsert_worker.ex","lib/scrypath/operations.ex","lib/scrypath/operations/result.ex","lib/scrypath/operator/recovery_action.ex","lib/scrypath/reindex.ex","lib/scrypath/sync.ex","lib/scrypath/sync/related_enqueue.ex","lib/scrypath/sync/related_worker.ex","test/scrypath/backfill_test.exs","test/scrypath/chunks_test.exs","test/scrypath/loader_test.exs","test/scrypath/oban/enqueue_test.exs","test/scrypath/oban/enqueue_unique_test.exs","test/scrypath/oban/job_args_test.exs","test/scrypath/oban/worker_test.exs","test/scrypath/oban_test.exs","test/scrypath/operator/failed_work_test.exs","test/scrypath/reindex_test.exs","test/scrypath/sync/related_test.exs","test/scrypath/sync/related_worker_test.exs","test/scrypath/sync_test.exs","test/scrypath/telemetry_test.exs","test/support/fake_repo.ex","test/support/loader_backfill_cases.ex","test/support/oban_sqlite_migration.ex","test/support/oban_sqlite_repo.ex"]
covered_digest: "v3:sha256:33228d223b442db6b2dfa31ba09efbdba62c95345f331b503c03ba0caf2053b1"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 4/4 (63/63 plan truths)
  reason: "previous report went stale after 24 review-fix commits (858e83dc..6ece8de0)"
  gaps_closed:
    - "WR-01 nested-transaction enqueue (was an open warning) — fixed 24a35c9a, real-Oban SQLite tests"
    - "WR-03 upgrade note for 0.3.17 related jobs (was an open warning) — documented 81930d86 + 179-06 release note"
    - "WR-04 backfill reported only the last delete chunk task (was an open warning) — delete_tasks: 70c8f326, reindex waits on them"
    - "WR-05 span start count pre-dedupe (was an open warning) — a28bc4e7"
  gaps_remaining: []
  regressions: []
---

# Phase 179: Bounded id lists and related-sync parity — Verification Report

**Phase Goal:** Large id sets never produce unbounded loads or backend calls, and related-record sync gives resolvers the same input and the same queue behaviour in every sync mode, failing cleanly on bad job arguments.
**Verified:** 2026-10-25T23:47:42Z (HEAD 6ece8de0)
**Status:** passed
**Re-verification:** Yes. The previous report (status passed) went stale after the review-fix commits. Every truth was re-checked against the current code, and the phase tests were re-run.

## Goal Achievement

### Roadmap Success Criteria

| # | Success criterion | Status | Evidence (current code at 6ece8de0) |
|---|---|---|---|
| 1 | 2,500 ids → three record loads and three backend upsert (and delete) calls of ≤1000 ids, one combined result | ✓ VERIFIED | `Chunks` (`@max_ids 1000`) bounds `Sync.dispatch_upsert/dispatch_delete` (`Chunks.by_id`/`Chunks.ids` + `reduce_ok` + `combine_chunks`), `Loader.fetch_chunks`, `Backfill.write` (`Enum.chunk_every(Chunks.max_ids())`), `UpsertWorker.write`, `DeleteWorker.write`, `Enqueue.enqueue_upsert/delete` and `RelatedEnqueue`. Tests (re-run green): sync_test "inline sync of 2,500 records sends three bounded upserts…", "delete_documents of 2,500 ids…"; worker_test "upsert worker loads and upserts 2,500 ids in chunks…", "delete worker sends 2,500 ids as three chunks…", "upsert worker deletes 2,500 missing ids in chunks…"; enqueue_unique_test "2,500 records enqueue three chunk jobs" (also inside a caller transaction); loader_backfill_cases "a 2,500-row page with batch_size: 5000 is one batch and three bounded upserts". No `insert_all` anywhere in `lib/`. |
| 2 | `sync_related` resolver gets loaded records under inline and Oban; the Oban worker loads via the loader before resolving | ✓ VERIFIED | `RelatedWorker.run/3` calls `Loader.load(schema, document_ids, config)` and then `sync_resolved(fan_out_config, records, opts)`. Empty → `:ok` noop, and the resolver is never called with `[]`. Inline `inline_resolve_and_sync` passes the caller's structs, now deduped by id (IN-06), and an empty inline call → `noop_result`. Tests: related_worker_test "perform/1 loads trigger structs, runs the resolver with them…", partial-missing (`missing_count`), soft-deleted, all-missing → `:ok`; related_test inline cases. |
| 3 | Enqueueing the same related sync twice yields one job (same `unique:` policy) | ✓ VERIFIED | `RelatedEnqueue` builds `Oban.Job.new(..., unique: Enqueue.unique_opts())` and inserts through `Enqueue.enqueue_chunks/3`, the same path as direct upsert/delete enqueue. Real Oban (Lite engine): enqueue_unique_test "a repeated related sync in a different trigger order collapses into one job (FAN-02)" gives one job, `conflict?: true` and the same job id. related_test "every related job carries the shared unique policy". |
| 4 | Related, upsert and delete jobs naming an unknown schema, fan-out, backend, repo or app finish with a clear non-retrying error, not a `String.to_existing_atom` raise | ✓ VERIFIED | `JobArgs` decodes all three kinds and returns `{:error, tag}`, which the workers map to `{:cancel, {:invalid_job, tag}}`. `String.to_existing_atom` appears only inside `rescue` (`existing_atom/1`, `safe_module/1`), plus one guarded literal in `UpsertWorker` (`source in ["fields","custom"]`). Since the last verification the following also cancel: loader-level bad input (uncastable or undumpable ids → `{:invalid_arg, "document_ids"}`, WR-07/08) and non-list `search_records/2` (`:invalid_search_records`, IN-04). Tests: related_worker_test FAN-03 matrix, worker_test bad-args matrix, job_args_test (atom-count, runtime-module CR-01 regression), loader_test "load/3 id casting (WR-08)". |

**Score:** 4/4 success criteria verified; 0 present-but-behavior-unverified.

### Plan must-have truths: deliberate deviations after review fixes

All 63 plan truths still hold in intent. The truths below were narrowed or changed on purpose by review fixes. Each one was judged against the phase goal, and none of them defeats it.

| # | Plan truth (as written) | What the code does now | Judgment |
|---|---|---|---|
| D1 | 179-01 D-03: `Chunks.ids/1` dedupes "by raw value" | Dedupes by `Chunks.id_key/1`, the JSON-stored form (atom `:a` == `"a"`). `1` and `"1"` stay distinct (IN-01, b9d67b09). | Stronger set semantics that match what Oban stores. Order-independence and 1000/1001 boundaries hold (chunks_test green). ✓ |
| D2 | 179-01 D-08: a ≤1000-id call returns "exactly today's public map" plus a one-element `tasks` | Keys and shape are unchanged, but `document_ids` is now deduped and string-sorted at every size. The span start count is deduped (WR-05, a28bc4e7). | Deliberate narrowing, documented in the guides and the 179-06 release note. Existing merged-key assertions stay green. ✓ (adopter-visible; carry into release upgrade notes) |
| D3 | 179-01 D-11: inline `sync_related` "still pass[es] the caller's structs unchanged" | The same structs are passed, deduped by document id with the last copy winning. The fallback is the raw list when ids cannot be read (IN-06, ce86499e). | This brings inline and Oban to the same input, which serves the goal. No reload and no `:repo` requirement (D-11 prohibition holds). ✓ |
| D4 | 179-03: "every upsert/delete job changeset uses [unique_opts]" | Direct `sync_records`/`delete_documents` enqueue still uses `unique_opts/0` (oban_test "the direct enqueue changesets keep the shared unique policy"). The `Scrypath.Oban` Multi helpers now insert **without** `unique:` (189cef0f; oban_test "Multi helper jobs are inserted without the unique policy"). | Deliberate. An in-transaction unique insert could collapse into a pending job that runs before the commit. SC-3 and FAN-02 concern related enqueue vs the main enqueue path, and both still share the policy. ✓ |
| D5 | 179-03: 2+ chunk jobs are "inserted inside one Oban.Repo.transaction/2" | This holds outside a transaction. Inside a caller's transaction there is no nested transaction: it returns a bare `{:error, reason}` and the caller's transaction gives the all-or-nothing behaviour (WR-01, 24a35c9a). | Orphan-free rollback is preserved in both cases (enqueue_unique_test "rolls back every chunk job", "Multi.run step that returns the error aborts the caller's transaction"). ✓ |
| D6 | 179-03: Multi helpers "keep their one-changeset contract unchanged" | Still one changeset per Multi step. `upsert_job_changeset/4` and `delete_job_changeset/4` gained an optional `job_opts` (default arity-3 behaviour unchanged). | ✓ |
| D7 | 179-04 D-15: decode tags are exactly the listed set | `JobArgs` tags are unchanged. The workers additionally cancel on loader reasons `{:invalid_arg, "document_ids"}` (cast/dump) and `:invalid_search_records`. | Additive non-retrying cancels that serve FAN-03. Not JobArgs decode tags. ✓ |
| D8 | 179-07 D-11: catalog_test "update_category/3 enqueues related product sync" passes unchanged | That test is unchanged and passes. The file gained after-commit and failed-sync tests. The resolver test now passes structs only, because the id clause was removed (IN-03). `update_category/3` syncs after `Repo.update` commits (CR-02, IN-07). | ✓ (example only) |

Other review-fix additions that hold, beyond what the plans asked for:
- **WR-04:** batch results gain `delete_tasks:`, and reindex waits on them before cutover (`reindex.ex:223-236`).
- **WR-06:** enqueue raises `ArgumentError` for nil, float or boolean ids through the shared `JobArgs.document_id?/1`.
- **WR-09:** operator retry returns `{:error, {:invalid_retry_input, :document_ids}}` (failed_work_test:530).
- **CR-02:** the guides say to call sync after the write commits, in every mode (`related-data-and-reindexing.md:230`, `sync-modes-and-visibility.md:134-144`).

### Backstop truths (verified by directly observed behaviour at HEAD)

| Truth | Status | Evidence |
|---|---|---|
| PAGE-03 idempotency: re-running a halted chunked sync re-sends every chunk | ✓ VERIFIED | Probe `MIX_ENV=test mix run` (scratchpad): 2,500 shuffled records with chunk 2 failing → `{:error, :boom}` after 2 calls `[1000, 1000]`. The re-run made 3 calls `[1000, 1000, 500]` with `document_count: 2500`, chunk 1 identical to the first run, and all 2,500 ids sent. |
| FAN-03 concurrency: JobArgs pure, concurrent bad jobs cancel independently | ✓ VERIFIED | Same probe: 200 concurrent `RelatedWorker.perform/1` calls, each with a distinct unknown schema, all returned `{:cancel, {:invalid_job, {:unknown_schema, own_name}}}`. |
| FAN-01 ordering: set semantics, no order promised | ✓ VERIFIED | `Chunks.ids/uniq_by_id` dedupe; `related-data-and-reindexing.md:251` says "No ordering contract."; resolver tests compare ids as sets. |

### Prohibitions (judgment tier — non-authoritative LLM-judge verdicts)

All 21 prohibitions were re-judged at HEAD, and none is violated:
- There is no chunk-size option, and `:batch_size` is still the backfill page size.
- There is no per-chunk span and no new telemetry event (WR-05 changed only the count on the existing span).
- There is no `insert_all`.
- The unique policy omits `:executing` and has no `keys:`.
- There is no `String.to_atom` in `lib/scrypath/oban` or `lib/scrypath/sync`.
- The resolver is never called with ids or `[]`.
- An all-missing related job returns `:ok`.
- Reindex waits on every upsert and delete chunk task.
- `CHANGELOG.md` is untouched (`git diff 1d3399c1..HEAD -- CHANGELOG.md` is empty).
- The related job args shape is unchanged. A 0.3.17 job that cannot reload its triggers cancels `:repo_required`, which is clean and non-retrying, and is documented as an upgrade step (WR-03).
- The 179-07 "minimal example fixes" prohibition is stretched by IN-03/IN-07: `update_category_and_sync/3` and the E2E endpoint now report the related-sync outcome. This is a correctness repair to existing example code, with no ops, UI or CI changes. Judged acceptable.

### Required Artifacts / Key Links

All plan artifacts exist, are substantive and are wired:
- `chunks.ex` (`@max_ids 1000`)
- `operations/result.ex` (`tasks: []`)
- `sync.ex` (`Chunks.reduce_ok`)
- `loader.ex` (`Chunks.ids`)
- `backfill.ex`
- `reindex.ex` (`:tasks`, `:delete_tasks`)
- `oban/enqueue.ex` (`def unique_opts`, `enqueue_chunks`, `task_from_job`)
- `operations.ex` (`conflict?`)
- the SQLite Oban repo and migration
- `job_args.ex`
- the workers (`JobArgs.decode_*`)
- `fake_repo.ex` (`__adapter__`)
- `related_worker.ex` (`Loader.load`, `JobArgs.decode_related`)
- `related_enqueue.ex` (`Enqueue.unique_opts`, `Enqueue.enqueue_chunks`)
- the guides ("What your resolver receives", `conflict?`)
- `category.ex` (`def search_records`, `skip_tenant_id: true`)
- the phoenix smoke test (`repo: ScrypathDemo.Repo`)

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase test files | `mix test test/scrypath/{chunks,sync,loader,backfill,reindex,oban}_test.exs test/scrypath/oban/ test/scrypath/sync/ --exclude integration` | 252 tests, 0 failures | ✓ PASS |
| Docs contract | `mix test --only docs_contract` | 74 tests, 0 failures | ✓ PASS |
| Ecommerce catalog (native Postgres) | `PGHOST=127.0.0.1 mix test test/scrypath_ecommerce/catalog_test.exs` (examples/scrypath_ecommerce) | 13 tests, 0 failures (connection-pool noise only) | ✓ PASS |
| Halt + re-run convergence; concurrent bad-job cancel | scratchpad probe | as above | ✓ PASS |
| Full suite / compile warnings-as-errors / format / credo / docs | orchestrator run at HEAD | 871/0, clean | ✓ PASS (orchestrator) |
| Phoenix Oban related smoke; ecommerce seed-based e2e_controller tests | needs host-reachable Meilisearch | not run (environment limit) | ? → hosted `phoenix-example` / `ecommerce-mounted` lanes on the PR SHA |

### Probe Execution

The phase declares no `scripts/*/tests/probe-*.sh`. Not applicable.

### Requirements Coverage

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| PAGE-03 | 01–06 | ✓ SATISFIED | SC-1 |
| FAN-01 | 01, 05, 06, 07 | ✓ SATISFIED | SC-2 |
| FAN-02 | 03, 05, 06 | ✓ SATISFIED | SC-3. Related and direct enqueue share `unique_opts/0`. The Multi helpers deliberately do not (D4). |
| FAN-03 | 04, 05, 06 | ✓ SATISFIED | SC-4 |

REQUIREMENTS.md maps exactly these four IDs to Phase 179 (traceability rows 70–73, marked Complete). There are no orphaned requirements.

### Anti-Patterns Found

None. The scan of all 45 changed non-planning files for TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER found one false positive, "JTBD" in a guide link title.

### Notes (non-blocking)

- **Pre-merge gate, not a human item:** the hosted `phoenix-example` and `ecommerce-mounted` lanes must be green on the phase PR SHA. Nothing has been pushed yet. The code paths those lanes exercise are covered locally by loader_test "owner-only schemas without a :preload clause load without raising" and by catalog_test (13/0).
- Release-note carry-forward: D2 (deduped and sorted `document_ids` at every size), D4 (Multi helpers no longer collapse duplicate jobs) and WR-03 (0.3.17 related jobs on repo-less apps cancel) are adopter-visible. The 179-06 SUMMARY release note covers them (IN-08, 81ba55a0).
- scrypath_ops compile is blocked by a pre-existing mix.lock mismatch. scrypath_ops is unchanged by this phase. WR-09's caller already matches `{:error, _}`.

### Human Verification Required

None.

### Gaps Summary

There are no gaps. All four roadmap success criteria and all 63 plan truths are backed by passing tests or directly observed behaviour at HEAD 6ece8de0. The review fixes closed the four warnings left open by the previous verification. Eight plan truths were deliberately narrowed by those fixes, and each is recorded above with its rationale. None weakens the phase goal.

---

_Verified: 2026-10-25T23:47:42Z_
_Verifier: Claude (gsd-verifier)_
