---
phase: 19-relevance-tuning
plan: "06"
status: complete
---

## Summary

- Added `Mix.Tasks.Scrypath.Settings.Read` (`mix scrypath.settings.read`) — thin delegate over `Client.get_settings/2` with pretty `inspect` output and 404 → `Mix.Error` via `OperatorTask`.
- Tests: `test/mix/tasks/scrypath_settings_read_test.exs`.
