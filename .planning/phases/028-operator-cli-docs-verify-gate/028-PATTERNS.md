# Phase 28 — Pattern map

Analogous code for planners and executors.

| Role | Reference file | Use for Phase 28 |
|------|------------------|------------------|
| Operator Mix task + `--json` + exit 0/2/1 | `lib/mix/tasks/scrypath.settings.diff.ex` | argv parsing, `System.halt(2)`, JSON vs human branches |
| Verify milestone gate | `lib/mix/tasks/verify.phase26.ex` | `verify.phase28` structure: focused tests + `mix docs --warnings-as-errors` |
| CLI helpers | `lib/scrypath/cli/operator_task.ex` | `parse!/2`, `schema_from_argv!/1`, `runtime_opts/1`, `test_operator_opts/0`, `error!/2` |
| Report source of truth | `lib/scrypath/operator/index_contract_drift/report.ex` | `Jason.Encoder`, `%Dimension{match:, details:}` |
| Builder | `lib/scrypath/operator/index_contract_drift.ex` | `build/2` — single `get_settings` |
| Mix task integration tests | `test/scrypath/mix_tasks/operator_tasks_test.exs` | env setup, `Mix.Task.run`, `capture_io` |
| Docs contract | `test/scrypath/docs_contract_test.exs` | `@verify_phaseNN` module reads, string allow-lists |

## PATTERN MAPPING COMPLETE
