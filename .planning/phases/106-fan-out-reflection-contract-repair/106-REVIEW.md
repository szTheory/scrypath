---
phase: 106-fan-out-reflection-contract-repair
reviewed: 2026-05-31T15:50:32Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/mix/tasks/verify.phase106.ex
  - test/mix/tasks/verify.phase106_test.exs
  - test/scrypath/schema_test.exs
  - test/scrypath/sync/related_test.exs
  - test/scrypath/sync/related_worker_test.exs
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---
# Phase 106: Code Review Report

**Reviewed:** 2026-05-31T15:50:32Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed all scoped Phase 106 files at standard depth. No direct security vulnerabilities were found, but there are contract and test-reliability defects that can hide regressions in CI.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Argument contract check happens after app boot side effects

**Classification:** WARNING
**File:** `lib/mix/tasks/verify.phase106.ex:16`
**Issue:** `run/1` starts the application before validating that no arguments were passed. Invalid invocations still execute `app.start` side effects before raising, which weakens the argument contract and can trigger unnecessary startup work.
**Fix:**
```elixir
@impl true
def run(args) do
  ensure_no_args!(args)
  Mix.Task.run("app.start")

  Mix.shell().info("==> verify.phase106: fan-out reflection contract checks")
  run_test!(@focused_tests, "Phase 106 fan-out reflection contract verification")
end
```

### WR-02: Oban-path test does not prove enqueue actually occurred

**Classification:** WARNING
**File:** `test/scrypath/sync/related_test.exs:123`
**Issue:** The `sync_mode: :oban` test asserts only the returned struct fields and never asserts `EnqueueOban.insert/1` was called. A regression that returns accepted metadata without enqueueing can still pass.
**Fix:**
```elixir
assert {:ok, result} = Scrypath.sync_related(...)
assert_received {:oban_insert, job}
assert job.queue == "test_queue"
```

### WR-03: Entire worker test module is silently skipped when Oban is unavailable

**Classification:** WARNING
**File:** `test/scrypath/sync/related_worker_test.exs:6`
**Issue:** All tests are wrapped in `if Code.ensure_loaded?(Oban.Worker) do ... end`. In environments missing Oban, the file compiles with zero tests and silently passes, which hides regressions in critical worker behavior.
**Fix:** Add an explicit fallback branch that fails or at least emits an explicit skipped test so CI surfaces missing coverage intentionally.
```elixir
if Code.ensure_loaded?(Oban.Worker) do
  # existing tests
else
  test "Oban.Worker is required for related worker contract tests" do
    flunk("Oban.Worker not loaded; related worker contract tests were skipped")
  end
end
```

---

_Reviewed: 2026-05-31T15:50:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
