---
phase: 179-bounded-id-lists-and-related-sync-parity
plan: 05
subsystem: sync-related
status: complete
tags: [oban, fan-out, related-sync, fan-01, fan-02, fan-03, page-03, telemetry]
requires:
  - 179-01 (Scrypath.Chunks.ids/1, chunked Loader.load/3)
  - 179-03 (Enqueue.unique_opts/0, Enqueue.enqueue_chunks/3, real-Oban SQLite harness)
  - 179-04 (JobArgs.decode_related/1, JobArgs.resolve_config/1)
provides:
  - "RelatedWorker.perform/1: JobArgs decode -> resolve_config -> Loader.load/3 -> resolver called with loaded trigger structs only"
  - "All-missing (deleted or soft-deleted) triggers finish :ok without calling the resolver"
  - "missing_count key on [:scrypath, :sync, :related, :resolve, :stop] (existing event, new metadata key)"
  - "RelatedEnqueue: Loader.ensure_loadable!/2 at the call site, one job per Chunks.ids/1 chunk, Enqueue.unique_opts/0, Enqueue.enqueue_chunks/3"
affects: [179-06, 179-07]
tech-stack:
  added: []
  patterns:
    - "related worker mirrors UpsertWorker: decode -> resolve_config -> Loader.load -> cancel mapping"
    - "related enqueue reuses the main unique policy and transactional insert instead of its own"
key-files:
  created: []
  modified:
    - lib/scrypath/sync/related_worker.ex
    - lib/scrypath/sync/related_enqueue.ex
    - test/scrypath/sync/related_worker_test.exs
    - test/scrypath/sync/related_test.exs
    - test/scrypath/oban/enqueue_unique_test.exs
decisions:
  - "The stop event's document_count is the resolved target count (from the sync result), as before; the trigger count is document_count in start metadata, and missing_count is the only new stop key"
  - "Loader :repo_required / :search_records_required in the related worker cancel as {:cancel, {:invalid_job, reason}}; other loader errors retry as {:error, reason}"
  - "RelatedEnqueue keeps the empty-trigger guard (noop Result in the configured mode) even though Sync.sync_related/3 short-circuits first"
metrics:
  duration: ~6m
  completed: 2026-10-25
estimate:
  tokens: 55000
  tasks: 3
actuals:
  tokens: 7400
  tasks: 3
  commits: 4
plan_head_before: 90c3a1671fe5b328c75c6f32b0f9312c4c922b59
plan_head_after: f6354a2319de0d61ab9698b4d893ae2bb59f227b
---

# Phase 179 Plan 05: Related sync parity under Oban Summary

Under Oban, `sync_related` now gives resolvers the current trigger records, not ids. Related jobs are bounded to 1000 triggers each. They share the main sync jobs' unique policy, so a repeated related sync collapses into one job reported with `conflict?: true`. A related job with undecodable args cancels with a specific tag and never raises.

## What was built

- **`Scrypath.Sync.RelatedWorker.perform/1`** (`lib/scrypath/sync/related_worker.ex`)
  - Decodes args with `JobArgs.decode_related/1` and resolves config with `JobArgs.resolve_config/1`. Any `{:error, tag}` becomes `{:cancel, {:invalid_job, tag}}`. Every `String.to_existing_atom` call and the raising destructure are gone (baseline 6, now 0).
  - Loads triggers with `Loader.load(schema, document_ids, config)`. The resolver gets only the loaded structs. If none load, the resolver is not called and the job returns `:ok`, so Oban never retries work that can never succeed (D-11).
  - Adds `missing_count: length(missing)` to the stop metadata of the existing `[:scrypath, :sync, :related, :resolve]` span. No new event (D-10, OQ7).
  - The result mapping is unchanged (D-19): 4xx → `{:cancel, "HTTP #{status}: ..."}`, other errors → `{:error, reason}`.
- **`Scrypath.Sync.RelatedEnqueue.enqueue/4`** (`lib/scrypath/sync/related_enqueue.ex`)
  - Calls `ensure_durable_api_key!` and then `Loader.ensure_loadable!/2` (D-12). Without a `:repo` or `search_records/2`, the call raises at the call site.
  - Builds one `RelatedWorker` changeset per `Chunks.ids/1` chunk (sorted, deduped, at most 1000 ids), each with `unique: Enqueue.unique_opts()` (D-20). It inserts them with `Enqueue.enqueue_chunks/3`, which is transactional and reports `tasks:` and `conflict?` (D-21).
  - The private `insert_job/2` copy is deleted. `job_args/4` is byte-for-byte unchanged, so the args shape stays the same (D-22).
- **Tests**
  - `related_worker_test.exs`: the fixtures now use struct-taking resolvers with `search_records/2`, backed by a process-dictionary `Rows` list that supports deleted and soft-deleted rows. A telemetry stop handler checks `missing_count` for the partial, soft-delete and all-missing cases. The cancel matrix has 7 FAN-03 rows. Also covered: the hard-coded 0.3.17 args with nil-valued `index_prefix`/`otp_app`/`repo`, and a tolerated unknown opts key.
  - `related_test.exs`: the existing Oban cases pass `repo: FakeRepo`. New cases cover the D-12 `~r/needs :repo/` raise, 2,500 triggers producing 3 sorted, disjoint, bounded jobs with 3 `tasks`, the shared unique policy, and the args keys `["document_ids", "fan_out", "opts", "schema"]`.
  - `enqueue_unique_test.exs`: a real-Oban (Lite/SQLite, `testing: :manual`) FAN-02 case. Triggers `[2, 1]` and then `[1, 2]` produce one `RelatedWorker` job, and the second result's task has `conflict?: true`.

## Verification

- `mix test test/scrypath/sync test/scrypath/oban test/scrypath/sync_test.exs test/scrypath/loader_test.exs`: 160 tests, 0 failures
- `mix test test/scrypath/sync/related_worker_test.exs test/scrypath/oban/job_args_test.exs test/scrypath/oban/worker_test.exs`: 93 tests, 0 failures, with no MatchError or UndefinedFunctionError
- `mix verify.no_optional_deps`, `mix compile --warnings-as-errors --force`, `mix format --check-formatted` and `mix credo --strict` all exit 0
- Full `mix test`: 897 tests. Before this SUMMARY existed, the only failure was the expected `Scrypath.NoHumanGatesContractTest` flag on `179-05-PLAN.md verification: backstop`. It was re-checked after the SUMMARY commit (see Self-Check).
- Tracer gate (Task 1): `<verify>` was re-run end to end after the commit and passed before expansion.

## TDD Gate Compliance

- Task 2: RED `b6a3a88f` ran the new tests against the old `RelatedEnqueue` and got 5 expected failures (no-repo raise, 3-chunk split, unique policy, args shape, real-Oban collapse). GREEN `858086dd` passes them.
- Task 3 only adds tests. Its behavior was already implemented in Task 1, so every row passed on first run and there was no observable RED. No fix in `job_args.ex` or `related_worker.ex` was needed.

## Deviations from Plan

### Auto-fixed Issues

None in production code. Two test assertions were adjusted to match existing behavior:

1. **[Rule 1 - Test] Stop-event `document_count` is the result count.** `Telemetry.stop_metadata/2` merges the sync result's `document_count` (resolved targets, or 0 for noop) over the span's start metadata. So the stop assertions check `missing_count` and `status`, not the trigger count. Trigger count stays in start metadata, which is unchanged.
2. **[Rule 1 - Test] Related job opts are atom-keyed before insert.** `job_args/4` builds `opts` with `Enum.into(%{})` from a keyword list, so the keys are atoms until Oban's JSON round trip turns them into strings. This is unchanged 0.3.17 behavior (D-22). The args-shape test reads `args["opts"][:repo]`.

## Known Stubs

None.

## Threat Flags

None. All surface is covered by T-179-13..16. Decoding goes through `JobArgs` and the FAN-03 matrix proves it. All-missing returns `:ok` and bad args cancel. `ensure_loadable!` runs at enqueue. A real-Oban test proves that duplicate jobs collapse.

## Commits

- `e16da280` feat(179-05): load trigger structs in RelatedWorker before resolving
- `b6a3a88f` test(179-05): add failing related enqueue loadability, chunk and unique tests
- `858086dd` feat(179-05): chunk related enqueue into unique jobs after a loadability check
- `f6354a23` test(179-05): cover related FAN-03 cancel matrix and 0.3.17 legacy args

## Self-Check: PASSED

- All 5 modified files exist; all 4 task commits are ancestors of HEAD.
- `mix test test/scrypath/no_human_gates_contract_test.exs` with this SUMMARY present: 2 tests, 0 failures.
