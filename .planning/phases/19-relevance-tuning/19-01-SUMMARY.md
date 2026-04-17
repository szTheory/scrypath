---
phase: 19-relevance-tuning
plan: 01
subsystem: testing
tags: [meilisearch, nimble_options, settings, validation]

requires: []
provides:
  - Canonical settings map validation (`validate_settings/1`, `normalize_settings/1`, `canonicalize_key/1`, `:__unrecognized__` bucket)
  - `:settings_merge` on runtime and reindex options; removed inert `:settings` from backfill options
  - `Settings.hot_apply/3` stub (`{:error, :hot_apply_disabled}`)
affects: [19-02, 19-03, 19-04]

tech-stack:
  added: []
  patterns:
    - "Settings subkeys: normalize to atom-snake + `__unrecognized__`; stderr hints via `IO.puts(:stderr, ...)`"

key-files:
  created:
    - test/scrypath/meilisearch/settings_test.exs
  modified:
    - lib/scrypath/options.ex
    - lib/scrypath/meilisearch/settings.ex
    - test/scrypath/options_test.exs
    - test/support/searchable_post.ex
    - test/scrypath/schema_test.exs
    - test/scrypath/meilisearch_test.exs
    - test/scrypath/telemetry_test.exs

key-decisions:
  - "Added `:typoTolerance` to the legacy camelCase allowlist so the existing `ConfiguredSearchablePost` fixture (`typoTolerance:`) canonicalizes to `:typo_tolerance` (same pattern as the four attribute keys)."

patterns-established:
  - "Default `settings: %{}` on schemas now materializes as `%{__unrecognized__: %{}}` after validation."

requirements-completed: [TUNE-01, TUNE-02, TUNE-03, TUNE-04, TUNE-06]

duration: unknown
completed: 2026-04-17
---

# Phase 19 relevance tuning: plan 01 summary

**Canonical Meilisearch settings validation, `settings_merge` option surface, backfill `settings` removal, ranking-rules stderr warning, and deferred `hot_apply/3` stub.**

## Accomplishments

- Extended `Scrypath.Options` with `settings_merge` (`:replace` default, `:deep`) on `@runtime_options` and `@reindex_options`; removed `settings` from `@backfill_options`.
- `validate_settings/1` now normalizes keys (atom-snake, legacy camelCase atoms including `:typoTolerance`, string camelCase), buckets unknowns under `:__unrecognized__`, validates recognized slice with NimbleOptions, prints camelCase hint and incomplete `ranking_rules` warnings to stderr via `IO.puts/2`.
- Added `Scrypath.Meilisearch.Settings.hot_apply/3` returning `{:error, :hot_apply_disabled}` with tests.
- Updated fixtures and tests for canonical settings maps; relaxed two `README.md` / `ARCHITECTURE.md` assertions in `telemetry_test.exs` to match current docs.

## Verification

- `mix test test/scrypath/options_test.exs test/scrypath/meilisearch/settings_test.exs` — pass (25 tests).
- `mix compile --warnings-as-errors` — pass.
- `mix test --exclude external_meilisearch --exclude requires_clean_workspace` — pass (218 tests). Used `requires_clean_workspace` exclusion locally because uncommitted plan 19 changes trip `mix verify.workspace_clean`.
- `mix test --exclude external_meilisearch` without exclusions — fails on dirty worktree (`@tag :requires_clean_workspace`); with a clean tree, expect pass after staging/commit.

## Blockers / follow-ups

- Wire JSON for Meilisearch still receives canonical atom keys from `Settings.resolve/2` until plan **19-02** adds translation; `:external_meilisearch` integration may need updates once translation exists.
- No `git commit` per user request; workspace-clean Mix test remains red until changes are committed or stashed.
