---
phase: 19-relevance-tuning
plan: "03"
status: complete
---

## Summary

- Added `Scrypath.Meilisearch.Client.get_settings/2` (GET `/indexes/:uid/settings` via `run_request/5`).
- Added `Scrypath.Meilisearch.Settings.verify_applied/3` and public `compute_drift/2` for declared-subset-of-applied drift detection, 404 → `:index_not_found`, and transport passthrough.
- Tests: `test/scrypath/meilisearch/client_test.exs`, extended `test/scrypath/meilisearch/settings_test.exs`.
