---
status: clean
phase: 26
depth: standard
files_reviewed: 12
critical: 0
warning: 0
info: 1
total: 1
---

# Code review — Phase 26 (Operator failure rollups)

## Scope

Tier: manual scope (SUMMARY artifacts did not list `key_files.*`; reviewed phase-delivered sources).

| Path | Role |
|------|------|
| `lib/scrypath/operator/reason_class_counts.ex` | Rollup struct + JSON encoding |
| `lib/scrypath/operator/failed_sync_work_inspection.ex` | Opt-in API wrapper |
| `lib/scrypath/operator/failed_work.ex` | `reason_class_counts/1` + normalization |
| `lib/scrypath/operator.ex` | Operator `failed_sync_work/2` opt-in branch |
| `lib/scrypath.ex` | Public `failed_sync_work/2` doc/spec |
| `lib/scrypath/operator/reconcile.ex` | `failed_work_counts` on report |
| `lib/scrypath/cli/operator_task.ex` | Human + JSON renderers |
| `lib/mix/tasks/scrypath.failed.ex` | `--json` / `--no-class-summary` |
| `test/scrypath/operator/failed_work_test.exs` | Rollup + API contract |
| `test/scrypath/operator/reconcile_test.exs` | Reconcile counts |
| `test/scrypath/mix_tasks/operator_tasks_test.exs` | Mix task behavior |
| `test/scrypath/docs_contract_test.exs` | Doc strings contract |

## Summary

No security issues or correctness bugs identified at **standard** depth. The opt-in branch uses strict `rollup? == true` (not generic truthiness), counts are derived from the same row list as the payload, and the JSON CLI path uses `IO.puts/1` without interleaved `Mix.shell().info/1`.

## Findings

### IN-01 — `format_reason_class/1` assumes atom or nil (info)

**Where:** `lib/scrypath/cli/operator_task.ex` — `format_reason_class/1` only matches `nil` and `atom`.

**Risk:** If a row ever violated `FailedWork.t()` and carried a non-atom `reason_class`, human/JSON rendering would raise `FunctionClauseError`. Current constructors keep `reason_class` within the taxonomy or `nil`; this is defensive documentation only.

**Suggestion (optional):** Add a final clause `defp format_reason_class(other), do: "unknown"` or `inspect(other)` for crash-proof CLI output.

---

## Checklist (spot)

- [x] No new network or credential paths
- [x] Default `failed_sync_work/2` return shape preserved unless opt-in flag is boolean `true`
- [x] Rollup DRY: single `FailedWork.reason_class_counts/1` for API, reconcile, CLI
- [x] `--json` path avoids `Mix.shell` framing

## Next steps

- None required for merge quality.
- Optional: address IN-01 if you want extra-hard CLI resilience.

*Reviewer: inline orchestrator (no `gsd-code-reviewer` agent in this environment). `gsd-sdk` commit step skipped — add `26-REVIEW.md` in your next docs commit if desired.*
