---
phase: 26
plan: 01
status: complete
---

# Plan 26-01 Summary

## Delivered

- **`Scrypath.Operator.ReasonClassCounts`** with enforced `version`, `total`, dense `by_class`, and **`Jason.Encoder`** with stable key order for JSON.
- **`Scrypath.Operator.FailedSyncWorkInspection`** wrapper struct for opt-in API.
- **`FailedWork.reason_class_counts/1`** — pure aggregator; `nil` `reason_class` counts as `:unknown`; documented rollup invariant in **`FailedWork`** moduledoc.
- **`Operator.failed_sync_work/2`** / **`Scrypath.failed_sync_work/2`** — `:reason_class_counts` in operator-only opts; stripped before **`FailedWork.list/3`**; default `{:ok, list}` unchanged.
- Tests in **`failed_work_test.exs`** under **OPS14-01** describe.

## Verification

- `mix format --check-formatted && mix test test/scrypath/operator/failed_work_test.exs --warnings-as-errors`

## Self-Check: PASSED
