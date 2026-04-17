---
phase: 25
status: passed
verified: "2026-04-17"
---

## Automated

- `mix format --check-formatted`
- `mix test --warnings-as-errors` (335 tests, 9 excluded integration)

## Must-haves (spot-check)

- `Settings.hot_apply/3`: `:live_ack_required`, `{:unsupported_hot_apply_keys, _}`, telemetry span, task wait on success path (unit + implementation review).
- `mix scrypath.settings.hot_apply`: `--ack-live` / `--settings-file` validation; delegates to `Settings.hot_apply/3`.
- Docs: `guides/relevance-tuning.md` section **Settings hot apply (v1.4)**; operator cross-link; CHANGELOG Unreleased cites TUNE14-01 / TUNE14-02.

## Human / integration

With Meilisearch up: `SCRYPATH_INTEGRATION=1 mix test test/scrypath/meilisearch/settings_hot_apply_integration_test.exs` (not run in this session).
