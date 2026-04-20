---
status: passed
phase: 41
verified: 2026-04-20
---

# Phase 41 — Verification

## Automated

- `mix compile --warnings-as-errors` — PASS
- `mix verify.phase41` — PASS (40 tests)

## Must-haves (from plans)

- `mix verify.phase41` exists, registered in `mix.exs` `cli/0` preferred_envs, CI `quality` job, CONTRIBUTING — verified in repo and tests.
- `guides/multi-index-search.md` documents `:all`, `global_schemas:`, `:scrypath_global_search_schemas`, two-layer score vs merge — verified via doc contract tests and file review.
- `search_many/2` `@doc` includes per-index score scope — verified `within one index` in `lib/scrypath/search.ex`.
- README and golden path link `guides/multi-index-search.md` — verified.
- FED-02 checkbox and traceability table updated — verified `.planning/REQUIREMENTS.md`.

## Regression note

Full `mix test --exclude integration --include requires_clean_workspace` failed **only** `Mix.Tasks.Verify.WorkspaceCleanTest` because the working tree contained **pre-existing** unrelated modified/untracked files (`docs/search-backend-sre.md`, `guides/overview.md`, etc.). Phase 41 commits are otherwise green on `mix verify.phase41`.

## Human verification

None required for this phase (documentation + static contracts only).
