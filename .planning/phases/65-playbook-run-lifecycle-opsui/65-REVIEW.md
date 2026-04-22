---
phase: 65-playbook-run-lifecycle-opsui
reviewed: 2026-04-22T19:08:02Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - /Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex
  - /Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex
  - /Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs
  - /Users/jon/projects/scrypath/scrypath_ops/config/test.exs
  - /Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
  - /Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
  - /Users/jon/projects/scrypath/scrypath_ops/test/support/search_playground_stub_adapter.ex
  - /Users/jon/projects/scrypath/scrypath_ops/assets/js/app.js
  - /Users/jon/projects/scrypath/scrypath_ops/docs/playbook-schema-v1.md
  - /Users/jon/projects/scrypath/mix.exs
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 65: Code Review Report

**Reviewed:** 2026-04-22T19:08:02Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Reviewed the phase 65 run lifecycle, failure enrichment, UI, docs, and root test-routing changes. The main risks are in async cancellation bookkeeping inside `PlaybookLive` and in the new root `mix test` alias, which currently only works for the narrow no-flag invocation covered by the phase acceptance command.

## Warnings

### WR-01: Cancelled async exits can be misattributed to a newer run

**File:** `/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:411-424`
**Issue:** `handle_async/3` handles `{:exit, reason}` by looking only at the current `run_ui.run_id`. Exit payloads do not include the original `run_id`, so if an old task is cancelled in `maybe_supersede_running_run/1` and a new run starts before the cancelled task's exit arrives, that stale exit will be applied to the newer run. The result is a false cancelled/timeout/error state and duplicate stop telemetry for the wrong run.
**Fix:**
```elixir
# Track the async task ref or a per-run token when starting work,
# and only apply exits that match the active run.
socket
|> assign(:run_ui, %{phase: :running, run_id: run_id, started_monotonic: now_ms(), task_ref: nil})
|> start_async(@playbook_run_async_key, fn ->
  {run_id, Runner.run_validated(draft, allowlist, scrypath_opts)}
end)

def handle_async(@playbook_run_async_key, {:exit, {run_id, reason}}, socket) do
  if active_run?(socket, run_id) do
    ...
  else
    {:noreply, socket}
  end
end
```

### WR-02: Root test delegation stops working as soon as normal `mix test` flags are added

**File:** `/Users/jon/projects/scrypath/mix.exs:98-116`
**Issue:** `maybe_delegate_opsui_test/1` only delegates when every arg starts with `scrypath_ops/test/`. Common invocations such as `mix test --seed 0 scrypath_ops/test/...`, `mix test --trace ...`, or `mix test --include foo ...` fall through to the root project and fail again. That makes the alias brittle outside the exact single-path command added in this phase.
**Fix:**
```elixir
defp maybe_delegate_opsui_test(args) when is_list(args) do
  {paths, passthrough} = Enum.split_with(args, &String.starts_with?(&1, "scrypath_ops/test/"))

  if paths != [] and length(paths) + length(passthrough) == length(args) do
    ops_args =
      Enum.map(args, fn
        "scrypath_ops/" <> rest -> rest
        other -> other
      end)

    ...
  else
    :passthrough
  end
end
```

## Info

### IN-01: `maybe_put_basename/1` is dead code and never changes the copied diagnostics payload

**File:** `/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex:101-112`
**Issue:** `take_copy/2` removes `:basename` before calling `maybe_put_basename/1`, and `maybe_put_basename/1` just returns the map unchanged in both branches. The helper currently adds no behavior and makes it look like `basename` may be part of the copied diagnostics when it never is.
**Fix:** Remove `maybe_put_basename/1`, or pass the original context in and explicitly add `:basename` when that is intentional.

---

_Reviewed: 2026-04-22T19:08:02Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
