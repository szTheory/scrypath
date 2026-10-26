---
phase: 180-oban-worker-telemetry
plan: 01
subsystem: telemetry
status: complete
requirements-completed: [OBS-01, OBS-02]
tags: [telemetry, oban, observability, workers]
requires: []
provides:
  - "[:scrypath, :oban, :upsert, :start | :stop | :exception] span"
  - "[:scrypath, :oban, :delete, :start | :stop | :exception] span"
  - "[:scrypath, :oban, :upsert, :missing_removed] point event"
  - "Scrypath.Telemetry.job_stop_metadata/1"
  - "Scrypath.TestSupport.TelemetryCapture"
  - "Scrypath.TestSupport.ObanTelemetryScenarios (run/1, scenarios/0)"
affects: [180-02 telemetry guide, 180-03 telemetry contract test]
tech-stack:
  added: []
  patterns:
    - "Worker span wraps only the post-decode/post-config work (D-02); decode failures stay silent"
    - "sync/4 returns {result, facts}; stop map = job_stop_metadata(result) merged with facts, never document_count"
    - "Point event fires only after every delete chunk returned :ok"
key-files:
  created:
    - test/support/telemetry_capture.ex
    - test/support/oban_telemetry_scenarios.ex
    - test/scrypath/oban/worker_telemetry_test.exs
  modified:
    - lib/scrypath/telemetry.ex
    - lib/scrypath/oban/delete_worker.ex
    - lib/scrypath/oban/upsert_worker.ex
    - test/scrypath/telemetry_test.exs
decisions:
  - "Upsert stop keeps source/upserted_count/missing_count when the load planned work but the backend write failed (D-06: counts describe the plan, outcome is authoritative); only cancel and load-error outcomes omit them"
  - "cancel_reason/1 keeps the atom head of a cancel tag, drops the detail, and falls back to :other; no atom is ever created from job input"
  - "oban_telemetry_scenarios.ex requires telemetry_capture.ex itself because test_helper loads support files alphabetically"
metrics:
  duration: "~30m"
  completed: 2026-10-25
estimate:
  tokens: 55000
  tasks: 3
actuals:
  tokens: 10082
  tasks: 3
  commits: 3
plan_head_before: cd83c4acdd88d03bbacd398f9a84cc2bb98d23e6
plan_head_after: ac62f31886a09d950c887a0957d450f91460699b
---

# Phase 180 Plan 01: Oban Worker Telemetry Spans Summary

The Oban upsert and delete workers now each emit one telemetry span per job. Start metadata carries schema, backend, index, `sync_mode: :oban`, attempt, max_attempts, a deduped `document_count`, and `repo` when the config has one. Stop metadata adds outcome, error_kind and cancel_reason, and the upsert stop also carries source, upserted_count and missing_count. A new `[:scrypath, :oban, :upsert, :missing_removed]` event with `%{count: n}` fires once, and only after every delete chunk for the missing ids has succeeded.

## Tasks

| Task | Name | Commit |
| ---- | ---- | ------ |
| 1 | Tracer: delete-worker span through job_stop_metadata/1 and capture helper | d4e2ef4f |
| 2 | Upsert span with facts threading; error/cancel/raise/decode outcomes for both workers | d886aded |
| 3 | missing_removed point event after confirmed deletes, plus cardinality guard | ac62f318 |

The tracer gate after Task 1 passed: its `<verify>` commands (worker tests and `mix verify.no_optional_deps`) were green before Task 2 started.

## Verification

- `mix test test/scrypath/oban/worker_telemetry_test.exs test/scrypath/telemetry_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync/related_worker_test.exs test/scrypath/loader_test.exs`: 101 tests, 0 failures
- `mix compile --warnings-as-errors --force`: clean
- `mix verify.no_optional_deps`: green
- `mix format --check-formatted`: clean
- `mix credo --strict`: no issues
- Acceptance greps: `def job_stop_metadata` = 3; `Oban` in telemetry.ex = 0; `Logger` in upsert_worker.ex = 0; `missing_removed` in the worker test = 10; `source: :legacy_snapshot` = 1; the missing_removed literal appears once in upsert_worker.ex

## Deviations from Plan

**1. [Rule 1 - Spec conflict] Upsert backend-error stop keeps the planned counts**
- **Found during:** Task 2
- **Issue:** One Task 2 behavior bullet said a TransientBackend upsert error should carry no source/upserted_count/missing_count. That contradicts CONTEXT D-06 ("counts describe the plan; outcome is authoritative", which covers failed chunks) and the plan's own must_have truth (the keys appear "exactly when the load or legacy snapshot produced a plan").
- **Fix:** Followed D-06. The load succeeds before the write fails, so the stop carries `source: :loaded`, `upserted_count: 1`, `missing_count: 0` next to `outcome: :error`. The test pins this. Cancel outcomes still carry none of the three keys.
- **Commit:** d886aded

**2. [Rule 3 - Blocking] Support-file load order**
- **Found during:** Task 2
- **Issue:** `test_helper.exs` requires `test/support/**/*.ex` alphabetically, so `oban_telemetry_scenarios.ex` compiled before `telemetry_capture.ex` and raised undefined-module warnings.
- **Fix:** `Code.require_file("telemetry_capture.ex", __DIR__)` at the top of the scenarios file. `require_file` loads each file only once, so there is no redefinition.
- **Commit:** d886aded

**3. Added `scenarios/0` to ObanTelemetryScenarios.** It lists every `run/1` scenario. The cardinality guard uses it, and plan 180-03 can iterate it.

**4. Dropped one plan edge that job args can't express.** The plan's `:a == "a"` identity example can't be built: decode accepts only integer or binary ids. The repeated-id precision edges are covered with `[1, 1, 2]` (delete) and `[404, 404, 1]` (upsert).

**TDD note:** Tests were written alongside each implementation step, not as a separate RED commit. This plan is `type: execute`, so the per-plan TDD gate does not apply.

## Deferred Issues / Environment Notes

- **Worktree build setup:** The worktree has no `deps/`, so checks ran with `MIX_DEPS_PATH=/Users/jon/projects/scrypath/deps` and a copied `_build`.
- **Shared deps pollution:** A full `mix test` under that setup ran `test/mix/tasks/verify_phoenix_example_package_test.exs`. That package proof inherited `MIX_DEPS_PATH`, updated ecto and finch in the main checkout's `deps/`, and created `deps/scrypath/`. It also failed with "artifact failed", which comes from this environment, not from this plan's code. ecto 3.14.0 and finch 0.23.0 were restored with `mix deps.get` against the unchanged lock. The stray `/Users/jon/projects/scrypath/deps/scrypath/` directory is still there for the maintainer to remove. The rest of the full suite passed: 977 tests, 1 failure (that package proof).

## Known Stubs

None.

## Threat Flags

None. Metadata is limited to atoms, integers, modules and the index string, as T-180-01..04 require. The cardinality test walks every captured worker event across all scenarios.

## Self-Check: PASSED

- FOUND: lib/scrypath/telemetry.ex, lib/scrypath/oban/delete_worker.ex, lib/scrypath/oban/upsert_worker.ex
- FOUND: test/support/telemetry_capture.ex, test/support/oban_telemetry_scenarios.ex, test/scrypath/oban/worker_telemetry_test.exs
- FOUND commits: d4e2ef4f, d886aded, ac62f318 (ancestors of HEAD)
