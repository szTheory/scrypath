---
phase: 178-loader-routed-backfill-and-full-key-paging
plan: 02
subsystem: verification / CI
status: complete
tags: [ci, postgres, mix-task, verify, TEST-06]
requires:
  - 178-01 (LoaderBackfillCases, PostgresRepo, compose postgres service on 5434)
provides:
  - Mix.Tasks.Verify.Postgres (curated real-Postgres loader/backfill lane)
  - verify.backend dispatching verify.meilisearch_smoke then verify.postgres
  - Postgres service + SCRYPATH_POSTGRES_URL inside the existing backend (required) CI job
affects:
  - lib/mix/tasks/verify/capability.ex
  - .github/workflows/ci.yml
  - lib/mix/tasks/verify.all.ex
  - lib/mix/tasks/verify.phase5.ex
tech-stack:
  added: []
  patterns:
    - "Curated verify task: one `mix test --include <tag> <file>` per file with Mix.Task.reenable, env guard via Mix.raise"
key-files:
  created:
    - lib/mix/tasks/verify.postgres.ex
    - test/mix/tasks/verify_postgres_test.exs
  modified:
    - lib/mix/tasks/verify/capability.ex
    - mix.exs
    - test/mix/tasks/verify_capability_test.exs
    - .github/workflows/ci.yml
    - test/mix/tasks/workflow_wiring_test.exs
    - lib/mix/tasks/verify.all.ex
    - lib/mix/tasks/verify.phase5.ex
decisions:
  - "The Postgres lane lives inside the existing backend (required) job; no new job or check name (required-job count stays 5)"
  - "verify.postgres always passes --include postgres because the test helper exclude list is evaluated once per VM"
  - "verify.postgres treats an empty SCRYPATH_POSTGRES_URL the same as unset"
metrics:
  duration: "2 min (measured wall clock from plan start epoch)"
  completed: 2026-10-25
actuals:
  tokens: 9000
  tasks: 2
  commits: 2
plan_head_before: 49ba78670ea2392eaa546756334b53f364554c97
plan_head_after: 9889b4ad5d6e18e12dcafd6d15619639d3897e87
requirements: [TEST-06]
---

# Phase 178 Plan 02: verify.postgres in the backend (required) lane Summary

The new `mix verify.postgres` task runs the real-Postgres loader/backfill shared cases. `verify.backend` now calls it right after the Meilisearch smoke. The existing `backend (required)` CI job gets a `postgres:16-alpine` service on 5434 and `SCRYPATH_POSTGRES_URL`, and a contract test pins both, so removing the lane turns CI red.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (tracer) | verify.backend dispatches curated verify.postgres | ce195a49 | lib/mix/tasks/verify.postgres.ex, lib/mix/tasks/verify/capability.ex, mix.exs, test/mix/tasks/verify_capability_test.exs, test/mix/tasks/verify_postgres_test.exs |
| 2 | Postgres service in backend job, contract pin, verify.all / verify.phase5 | 9889b4ad | .github/workflows/ci.yml, test/mix/tasks/workflow_wiring_test.exs, lib/mix/tasks/verify.all.ex, lib/mix/tasks/verify.phase5.ex |

## Verification evidence (local)

- `mix test test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_postgres_test.exs`: 9 tests, 0 failures.
- `MIX_TEST_PARTITION=2 SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres` against the compose Postgres (container `scrypath-postgres-1`, healthy): printed `test/scrypath/loader_backfill_postgres_test.exs`, `Including tags: [:postgres]`, 1 test, 0 failures, exit 0. Plan 01 ships one shared case today, so 1 is the expected count. Later plans in this phase add more.
- Tracer gate: re-ran the automated `<verify>` end to end. It passed, so expansion went ahead.
- `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_postgres_test.exs`: 55 tests, 0 failures.
- The PyYAML check on the backend job (postgres service and SCRYPATH_POSTGRES_URL) printed `ok`.
- `grep -c 'name: backend (required)'` = 1. `grep -c 'name: .*(required)'` = 5, the same as the baseline.
- `mix test test/scrypath/loader_backfill_sqlite_test.exs`: 1 test, 0 failures. This is the file newly added to verify.phase5.
- `mix format --check-formatted`, `mix credo --strict` (no issues, 251 files) and `MIX_ENV=test mix compile --warnings-as-errors --force` all exit 0.
- After filtering out comment lines, grepping `lib/mix/tasks/verify.postgres.ex` for Postgrex/TestSupport finds 0 matches.

Not run locally: the full `mix verify.all` and `mix verify.phase5` (they need Meilisearch and build docs). The hosted proof on the exact SHA is still owed: the phase PR's `backend (required)` log must show `loader_backfill_postgres_test.exs` running with a non-zero test count.

## Deviations from Plan

None. The plan was executed as written. Two minor notes:
- Task 2 was committed with the `ci(...)` conventional type, which fits the workflow change.
- The env guard rejects an empty-string URL as well as an unset one, as the plan's action text asks (nil or empty).

## Known Stubs

None.

## Threat Flags

None. The only new surface is the throwaway CI Postgres service, which the threat model already covers as T-178-03 (accept).

## Self-Check: PASSED

- FOUND: lib/mix/tasks/verify.postgres.ex
- FOUND: test/mix/tasks/verify_postgres_test.exs
- FOUND: ce195a49 (ancestor of HEAD)
- FOUND: 9889b4ad (ancestor of HEAD)
