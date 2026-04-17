---
phase: 26
plan: 02
status: complete
---

# Plan 26-02 Summary

## Delivered

- **`%Reconcile.failed_work_counts`** — always set on successful **`run/3`** via **`FailedWork.reason_class_counts/1`** on the same **`failed_work`** list.
- **`OperatorTask`** — human **`render_failed_work/3`** with optional rollup + **`reason_class=`** per row; **`render_reconcile_report/1`** rollup lines; **`failed_work_cli_json/2`** for Mix JSON path.
- **`mix scrypath.failed`** — **`--json`** (single **`IO.puts`**, inspection API) and **`--no-class-summary`**; **`@moduledoc`** examples.
- Guides (**`operator-mix-tasks.md`**, **`drift-recovery.md`**), **`CHANGELOG`**, **`docs_contract_test`**, **`reconcile_test`**, **`operator_tasks_test`** updates.

## Verification

- `mix test test/scrypath/mix_tasks/operator_tasks_test.exs test/scrypath/operator/reconcile_test.exs test/scrypath/docs_contract_test.exs --warnings-as-errors`

## Self-Check: PASSED
