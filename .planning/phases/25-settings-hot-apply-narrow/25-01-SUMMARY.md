---
phase: 25
plan: "01"
status: complete
---

## Outcome

Implemented `Scrypath.Meilisearch.Settings.hot_apply/3`: allow-list validation, `acknowledge_live_index` gate, `translate_settings/1` + `update_settings` + `Tasks.wait_for_task`, `{:hot_apply_failed, details}` normalization, and `[:scrypath, :settings, :hot_apply]` telemetry. Replaced `:hot_apply_disabled` stub. Unit tests in `test/scrypath/meilisearch/settings_test.exs`.

## Self-Check

PASSED — `mix test test/scrypath/meilisearch/settings_test.exs --warnings-as-errors`

## Key files

- `lib/scrypath/meilisearch/settings.ex`
- `test/scrypath/meilisearch/settings_test.exs`
