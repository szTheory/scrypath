---
phase: 19-relevance-tuning
plan: 02
subsystem: testing
tags: [meilisearch, settings, translation, synonyms]

requires: []
provides:
  - expand_synonyms/1 (list-of-groups, one_way, map passthrough)
  - translate_settings/1 (camelCase wire, meta strip, __unrecognized__ merge)
  - resolve/2 normalize-both-sides + settings_merge :replace | :deep + deep_merge/2
  - apply/3 translates before Client.update_settings/3
affects: [19-03, 19-04, 19-05]

tech-stack:
  added: []
  patterns:
    - "Wire boundary: canonical map in apply/3 return; translated map to client only"

key-files:
  created: []
  modified:
    - lib/scrypath/meilisearch/settings.ex
    - test/scrypath/meilisearch/settings_test.exs
    - test/scrypath/meilisearch_test.exs

key-decisions:
  - "one_way for synonym expansion is read from canonical map or __unrecognized__ bucket before strip, then removed from the wire payload."
  - "maybe_normalize/1 treats any map with :__unrecognized__ as already canonical per plan 19-02."

patterns-established:
  - "Map.merge(recognized_camel, unrecognized) for translate_settings — bucket keys pass through without key rewriting."

requirements-completed: [TUNE-01, TUNE-02, TUNE-06]

duration: unknown
completed: 2026-04-17
---

# Phase 19 relevance tuning: plan 02 summary

**Meilisearch settings translation and merge primitives: synonym sugar expansion, camelCase wire translation with recursive nested maps, normalize-before-merge resolve/2, and deep merge mode.**

## Accomplishments

- Implemented `expand_synonyms/1`, `translate_settings/1`, `strip_scrypath_meta_keys/1` (private), `deep_merge/2` (private), extended `resolve/2` and `apply/3` per 19-02-PLAN.md.
- Added coverage for TUNE-02 expansion, TUNE-01 translate + unrecognized passthrough, D-04 meta stripping, D-17 doubled-key regression, D-09 `:replace` vs `:deep` semantics.
- Updated `apply_settings/3` integration assertion in `meilisearch_test.exs` to expect camelCase wire payloads.

## Verification

- `mix test test/scrypath/meilisearch/settings_test.exs` — pass (27 tests).
- `mix compile --warnings-as-errors` — pass.
- `mix test --exclude external_meilisearch --exclude requires_clean_workspace --exclude integration` — pass except known workspace-clean gate when dirty.

## Self-Check: PASSED
