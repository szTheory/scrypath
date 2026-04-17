# Phase 26: Operator failure rollups — Research

**Phase:** 26 — Operator failure rollups  
**Date:** 2026-04-17  
**Question:** What do we need to know to plan OPS14-01 well?

---

## Summary

Rollup counts are a **pure fold** over `[FailedWork.t()]` keyed by `reason_class/0`. Every consumer must call the **same** function on the **same** list they expose (list-only API, enriched API, `%Reconcile{}`, CLI). The public contract is **dense**: all five `reason_class` atoms present with `non_neg_integer` values, plus `total` and a small `version` field for forward-compatible JSON/docs.

`FailedWork.list/3` already backs both `Operator.failed_sync_work/2` and `Reconcile.run/3`; no new fetch verbs. Opt-in enrichment belongs on **`failed_sync_work/2`** via an operator-only option (split with `Keyword.split/2` like `:meilisearch_tasks`), so `Config.resolve!/1` never sees rollup flags.

---

## Codebase anchors

| Area | Finding |
|------|---------|
| `FailedWork` | `@enforce_keys` fixed set; `reason_class` on every row; `@type reason_class` lists exactly five atoms |
| `Operator.failed_sync_work/2` | Splits `@operator_only_opts`, resolves config, calls `FailedWork.list/3` |
| `Reconcile.run/3` | Same `FailedWork.list/3`; assembles `%Reconcile{failed_work: rows}` |
| `Scrypath.failed_sync_work/2` | Thin delegate; `@spec` today is list-only `{:ok, [FailedWork.t()]}` |
| CLI | `OperatorTask.render_failed_work/2`, `render_reconcile_report/1`; `mix scrypath.failed` delegates to API; settings diff has `--json` precedent |
| Tests | `test/scrypath/operator/failed_work_test.exs` exercises `Scrypath.failed_sync_work/2`; `docs_contract_test.exs` lists public API strings |

---

## API shape (locked from 26-CONTEXT)

1. **Default:** `{:ok, [FailedWork.t()]}` unchanged when rollup option absent.
2. **Opt-in:** `{:ok, %FailedSyncWorkInspection{entries: rows, counts: %ReasonClassCounts{}}}` (names per CONTEXT; executor may place structs under `Scrypath.Operator` if cleaner).
3. **`%ReasonClassCounts{}`:** `version: 1`, `total: non_neg_integer`, `by_class: %{atom => non_neg_integer}` with **all five** keys from `FailedWork.reason_class/0`, zeros explicit.
4. **No** new recovery verbs; **no** `@enforce_keys` change on `%FailedWork{}`.

---

## Mix / operator UX

- Human **`mix scrypath.failed`:** rollup block before per-row lines when count > 0; each row includes stable `reason_class=` (or equivalent) token.
- **`--json`:** single JSON document to stdout; no `Mix.shell().info` interleaving on that path (match settings diff task).
- **`--no-class-summary`** (or equivalent): suppress rollup header only.
- **`mix scrypath.reconcile`:** report path prints the **same** counts shape for report-first triage.

---

## Risks / pitfalls

| Risk | Mitigation |
|------|------------|
| Silent omission of a class | Dense map + tests vs `Enum.frequencies/1` on `reason_class` |
| Drift between API counts and CLI | Single `reason_class_counts/1` (or equivalent) used everywhere |
| Unknown future classes | CONTEXT D-10: no silent `:other`; explicit `extras` only in a semver-major follow-up |
| Dialyzer / ExDoc | Named structs, `@type` unions on `failed_sync_work/2` |

---

## Validation Architecture

**Nyquist / Dimension 8 — automated feedback for this phase**

| Dimension | Strategy |
|-----------|----------|
| Correctness of counts | Unit tests: fixture rows → `reason_class_counts/1` matches `Enum.frequencies_by(& &1.reason_class, rows)`; `sum(by_class values) == total == length(rows)` |
| Exhaustive keys | Test asserts `Map.keys(by_class) |> Enum.sort` equals sorted five atoms from `FailedWork.reason_class/0` type set |
| API default unchanged | Test `failed_sync_work(schema, opts)` without rollup flag returns `{:ok, list}` and `is_list(elem(..., 1))` |
| Opt-in branch | Test with flag returns struct; `entries` same length as `counts.total` |
| Reconcile | Test `reconcile_sync` report includes new field populated from same rows as `failed_work` |
| CLI / JSON | Tests capture `Mix.shell()` or task module tests with injected backend opts (existing `operator_task_test` / `Application.get_env(:scrypath, :operator_task_test_opts)` pattern) |
| Docs contract | `docs_contract_test.exs` updated for any new public module names / arity strings |

**Quick command:** `mix test test/scrypath/operator/failed_work_test.exs test/scrypath/operator/reconcile_test.exs test/scrypath/mix_tasks/operator_tasks_test.exs test/scrypath/docs_contract_test.exs`

**Full suite:** `mix test`

**Sampling:** After each plan wave, run the quick command; before phase sign-off, full `mix test`.

---

## RESEARCH COMPLETE

Findings above are sufficient for executable plans without further external research.
