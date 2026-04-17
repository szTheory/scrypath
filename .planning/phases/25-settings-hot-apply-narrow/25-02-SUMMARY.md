---
phase: 25
plan: "02"
status: complete
---

## Outcome

Added `mix scrypath.settings.hot_apply` (`lib/mix/tasks/scrypath.settings.hot_apply.ex`), `preferred_envs` entry, Mix task tests (`test/mix/tasks/scrypath_settings_hot_apply_test.exs`), and integration coverage (`test/scrypath/meilisearch/settings_hot_apply_integration_test.exs`, `@moduletag :integration`).

## Self-Check

PASSED — `mix test test/mix/tasks/scrypath_settings_hot_apply_test.exs`; integration file compiles (0 tests when `SCRYPATH_INTEGRATION` unset).

## Key files

- `lib/mix/tasks/scrypath.settings.hot_apply.ex`
- `mix.exs`
- `test/mix/tasks/scrypath_settings_hot_apply_test.exs`
- `test/scrypath/meilisearch/settings_hot_apply_integration_test.exs`
