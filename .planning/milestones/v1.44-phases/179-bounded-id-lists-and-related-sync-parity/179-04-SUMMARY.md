---
phase: 179-bounded-id-lists-and-related-sync-parity
plan: 04
subsystem: oban
status: complete
requirements-completed: [FAN-03, PAGE-03]
tags: [oban, job-args, chunking, fan-03, page-03, atom-safety]
requires:
  - 179-01 (Scrypath.Chunks, chunked Loader.load/3)
provides:
  - "Scrypath.Oban.JobArgs (pure, @moduledoc false): decode_upsert/1, decode_delete/1, decode_related/1, resolve_config/1"
  - "D-15 decode tags: {:unknown_schema, n}, {:unknown_fan_out, n}, {:unknown_backend, n}, {:unknown_repo, n}, {:unknown_otp_app, n}, {:invalid_arg, key}, {:invalid_config, msg}"
  - "UpsertWorker / DeleteWorker cancel bad args as {:cancel, {:invalid_job, tag}} and write in awaited chunks of at most 1000"
  - "FakeRepo.__adapter__/0"
affects: [179-05, 180]
tech-stack:
  added: []
  patterns:
    - "decode job args via JobArgs, map {:error, tag} to {:cancel, {:invalid_job, tag}}"
    - "module names resolve only in exact to_string(module) form via String.to_existing_atom + Module.safe_concat, then a per-role callback check"
    - "related opts read from a fixed string-key allowlist; nil/\"\" are absent; unknown keys ignored"
key-files:
  created:
    - lib/scrypath/oban/job_args.ex
    - test/scrypath/oban/job_args_test.exs
  modified:
    - lib/scrypath/oban/delete_worker.ex
    - lib/scrypath/oban/upsert_worker.ex
    - test/support/fake_repo.ex
    - test/scrypath/oban/worker_test.exs
decisions:
  - "A module name resolves only when Atom.to_string(module) == name, so \"Scrypath.TestSupport.FakeRepo\" (no Elixir. prefix) decodes as unknown even though Module.safe_concat would resolve it"
  - "A non-binary, non-nil \"repo\" on an upsert job, or a non-binary allowlisted related opt, returns {:invalid_arg, key}"
  - "A non-map args value returns {:invalid_arg, \"args\"} so perform/1 never raises a FunctionClauseError"
metrics:
  duration: ~25m
  completed: 2026-10-25
estimate:
  tokens: 50000
  tasks: 3
actuals:
  tokens: 10200
  tasks: 3
  commits: 5
plan_head_before: cb3a241f37a5b49c7897c8a27d1779601b88456d
plan_head_after: ae0f382c09b0947c84bdfccb2ace3dfca78b8c20
---

# Phase 179 Plan 04: JobArgs decoder and bounded upsert/delete workers Summary

One pure decoder, `Scrypath.Oban.JobArgs`, now decodes the args of all three Scrypath Oban jobs. It never creates an atom from job input and never calls a module unless the module is loaded and exports the callbacks its role needs. The upsert and delete workers use it. They cancel bad jobs with a specific tag, cancel an edited unresolvable `"repo"`, and send at most 1000 ids per backend call, awaiting each chunk.

## What was built

- **`Scrypath.Oban.JobArgs`** (`lib/scrypath/oban/job_args.ex`). No Oban references and no Oban guard; `mix verify.no_optional_deps` passes.
  - `decode_delete/1`: `"schema"`, `"backend"` (needs `delete_documents/3` and `index_name/2`), a non-empty `"index"`, a `"document_ids"` list, and a `"document_count"` equal to its length. `"repo"` is ignored.
  - `decode_upsert/1`: `"schema"`, `"backend"` (also needs `upsert_documents/3`), `"index"`, `"document_ids"`, and `"repo"` per D-18:
    - a name that resolves to a module exporting `__adapter__/0` sets `opts[:repo]`
    - any other name returns `{:unknown_repo, name}`
    - `nil`, `""` or a missing key leaves `:repo` unset (the legacy path)
  - `decode_related/1`: `"schema"`, then `"fan_out"`:
    - an atom that does not exist, an atom that is not configured, or a `fan_outs` lookup that raises all return `{:unknown_fan_out, name}`
    - then `"document_ids"`, then a map `"opts"`
    - opts are read only from the allowlist `index_prefix`, `meilisearch_url`, `backend`, `otp_app`, `repo`
    - `otp_app` must be an existing atom with `Application.spec/1 != nil`
  - `resolve_config/1`: `Config.resolve!/1` with `ArgumentError` → `{:invalid_config, message}`.
  - Names resolve only in exact `to_string(module)` form.
- **`DeleteWorker`**: decodes with `JobArgs`, deletes over `Chunks.ids/1` with `Chunks.each_ok/2`, and runs `IndexingAck.await/3` per chunk. The first error stops the job and is returned for retry.
- **`UpsertWorker`**: decodes with `JobArgs` and keeps the loader, legacy snapshot and `:repo_required` / `:search_records_required` branches as they were. Its `write/5` chunks:
  - upserts with `Chunks.by_id/2`
  - missing-id deletes with `Chunks.ids/1`
  - each chunk is awaited, and all upserts finish before the deletes start
- **`FakeRepo.__adapter__/0`** returns `Ecto.Adapters.SQLite3`.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | Tracer: JobArgs.decode_delete/1 + DeleteWorker cancel and 3-chunk delete | 74dac3d6 |
| 2 | UpsertWorker on JobArgs, D-18 repo cancel, chunked upserts then deletes | 7f298847 (RED), 072ceed3 (GREEN) |
| 3 | JobArgs.decode_related/1, opts allowlist, atom-safety proofs | 53d785d7 (RED), ae0f382c (GREEN) |

Tracer gate: Task 1's `<verify>` was re-run end-to-end (35 tests, 0 failures) before expanding.

## TDD Gate Compliance

- Task 2 RED (7f298847): 19 failures, all from `decode_upsert/1` being undefined or the old worker's tags and unchunked writes. GREEN (072ceed3): 63 tests across `job_args_test`, `worker_test` and `loader_test`, 0 failures.
- Task 3 RED (53d785d7): 20 failures, all `UndefinedFunctionError` for `decode_related/1`. GREEN (ae0f382c): 50 tests, 0 failures.
- No refactor commits were needed.

## Verification

- `mix test test/scrypath/oban/job_args_test.exs test/scrypath/oban/worker_test.exs test/scrypath/loader_test.exs`: 0 failures.
- `mix verify.no_optional_deps`, `mix compile --warnings-as-errors`, `mix format --check-formatted` and `mix credo --strict` (no issues) all exit 0.
- Full `mix test`: 865 tests, 1 failure. The failure is the known `Scrypath.NoHumanGatesContractTest` backstop for the 179-04 and 179-05 PLANs. This SUMMARY clears 179-04; 179-05's entry stays until that plan lands.
- The `invalid_job, :repo_required` count in `worker_test.exs` is 2 before and after. The legacy snapshot tests were not edited (the diff only adds lines).
- The atom-count test decodes 10 job shapes. Each uses a fresh unknown name in one field (schema, backend, repo, fan_out, otp_app, or an unknown opts key) and is decoded twice. Both decodes return the same result, and `:erlang.system_info(:atom_count)` does not change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Names without the `Elixir.` prefix resolved through `Module.safe_concat`**
- **Found during:** Task 1
- **Issue:** The lifted `safe_module/1` resolves `"SearchablePost"` and `"Scrypath.TestSupport.FakeRepo"` to real modules. The plan's encoding truth says only the exact `to_string(module)` form may match.
- **Fix:** `resolve_existing_module/3` also requires `Atom.to_string(module) == name`.
- **Files modified:** lib/scrypath/oban/job_args.ex
- **Commit:** 74dac3d6

### Notes on acceptance greps

- The Task 1 check `grep -v '^\s*#' job_args.ex | grep -cE 'Oban\.(Job|Worker|Repo|insert)|use Oban'` prints 2, not 0. The two matches are the plan-mandated module name `Scrypath.Oban.JobArgs` and the `alias Scrypath.Oban.JobConfig` line, because both contain `Oban.Job`. There are no references to `Oban.Job`, `Oban.Worker`, `Oban.Repo` or `Oban.insert`, and `mix verify.no_optional_deps` passes.
- `grep -c 'def decode_related'` prints 2 because there are two clauses. The second is a non-map guard that returns `{:invalid_arg, "args"}`.
- The worker `write` helpers have arity 4 in `DeleteWorker` (it has no `fun` argument) and 5 in `UpsertWorker`.

## Known Stubs

None.

## Threat Flags

None. T-179-09..12 are mitigated as planned: no `String.to_atom`, the opts allowlist, role callback checks before any call, cancel instead of retry, and the D-18 repo cancel. No new endpoints, auth paths or schema changes.

## Self-Check: PASSED

- FOUND: lib/scrypath/oban/job_args.ex, test/scrypath/oban/job_args_test.exs, lib/scrypath/oban/delete_worker.ex, lib/scrypath/oban/upsert_worker.ex, test/support/fake_repo.ex, test/scrypath/oban/worker_test.exs
- FOUND commits: 74dac3d6, 7f298847, 072ceed3, 53d785d7, ae0f382c
