---
phase: 69-adopter-verify-spine
plan: "01"
subsystem: verification
tags: [mix, verify, docs, ci, example]
provides:
  - durable `mix verify.adopter` maintainer command
  - strict fast/live task behavior with loud live prerequisite failures
  - task-focused regression coverage and CLI registration
key-files:
  created:
    - lib/mix/tasks/verify.adopter.ex
    - test/mix/tasks/verify_adopter_test.exs
  modified:
    - mix.exs
requirements-completed: [INTG-02]
completed: 2026-04-23T01:25:33Z
---

# Phase 69 Plan 01: Adopter verify task and CLI wiring Summary

**Scrypath now has a durable root maintainer task, `mix verify.adopter`, with a fast default path, an explicit `--live` path, and regression coverage for argument handling and loud prerequisite failures.**

## Accomplishments

- Added `Mix.Tasks.Verify.Adopter` with real public help text, strict `--fast` / `--live` parsing, a bounded fast slice, and the canonical live example path.
- Kept live mode orchestration-only: it shells into `examples/phoenix_meilisearch` for `mix deps.get` then `mix test`, and refuses to run without `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL`.
- Registered `"verify.adopter": :test` in `mix.exs`.
- Added `test/mix/tasks/verify_adopter_test.exs` for stray arg rejection, unknown flag rejection, conflicting mode rejection, missing live env failures, and fast-path progress markers.

## Files Created/Modified

- `lib/mix/tasks/verify.adopter.ex`
- `test/mix/tasks/verify_adopter_test.exs`
- `mix.exs`

## Verification

- `mix test test/mix/tasks/verify_adopter_test.exs`
- `mix help verify.adopter`

## Issues Encountered

- `mix help verify.adopter` did not discover the new task until the dev environment was compiled; `mix compile` resolved that.
- The repo already had unrelated local modifications in tracked files, so this plan was executed without task commits to avoid mixing unrelated user changes into a commit.

## Self-Check: PASSED
