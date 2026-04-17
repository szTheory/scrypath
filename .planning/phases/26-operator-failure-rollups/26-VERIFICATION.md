---
status: passed
phase: 26
updated: 2026-04-17
---

# Phase 26 verification — Operator failure rollups (OPS14-01)

## Must-haves (from plans)

| Criterion | Evidence |
|-----------|----------|
| Single pure aggregator; consumers use same row list | `FailedWork.reason_class_counts/1`; `Operator.failed_sync_work/2` inspection; `Reconcile.run/3`; CLI renderers all call it on attached lists. |
| Default `failed_sync_work/2` unchanged | Keyword default `false`; tests assert list-only path. |
| Dense five-key `by_class` + `total` + `version` | `%ReasonClassCounts{}` + tests. |
| Mix human rollup + `reason_class=`; JSON path | `operator_tasks_test.exs`, `OperatorTask` implementation. |

## Automated checks run

Canonical gate (also runs on every PR in `ci.yml` **quality**):

```bash
mix verify.phase26
```

Focused tests (also run inside **`mix verify.phase26`** before the docs build):

```bash
mix test test/scrypath/operator/failed_work_test.exs \
  test/scrypath/operator/reconcile_test.exs \
  test/scrypath/mix_tasks/operator_tasks_test.exs \
  test/scrypath/docs_contract_test.exs --warnings-as-errors
```

Then **`mix docs --warnings-as-errors`** (same shape as **`mix verify.phase22`**).

## Notes

- **ROADMAP** / **STATE** / **REQUIREMENTS** updated 2026-04-17 after automated gate green (`mix verify.phase26`, CI **quality**).
