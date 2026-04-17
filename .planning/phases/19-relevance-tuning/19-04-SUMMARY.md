---
phase: 19-relevance-tuning
plan: "04"
status: complete
---

## Summary

- `Scrypath.Reindex.run/2`: `maybe_verify_settings/3` after settings apply+wait; `enforce_ranking_rules_strict!/1` before the `with` chain; `:skip_settings_verification?` + telemetry (`:verify_skipped`, `:settings_verified` span); test-only `__get_settings_response__` merge for drift simulations.
- `Scrypath.Config.resolve!/1`: three-source merge (global → per-repo → per-call) via `per_repo_config/1`; optional `otp_app` when repo has no `Application.get_application/1`.
- Tests: `test/scrypath/reindex_test.exs`, `test/scrypath/config_test.exs`.
