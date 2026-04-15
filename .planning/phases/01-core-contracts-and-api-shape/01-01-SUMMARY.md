---
phase: 01-core-contracts-and-api-shape
plan: 01-01
subsystem: api
tags: [elixir, ecto, nimble_options, schema]
requires: []
provides:
  - searchable schema declaration macro
  - runtime reflection helpers
  - schema contract tests
affects: [phase-02, projection, sync]
tech-stack:
  added: [ecto, nimble_options]
  patterns: [metadata-only macro, centralized option validation, reflection helpers]
key-files:
  created:
    - mix.exs
    - .formatter.exs
    - lib/scrypath.ex
    - lib/scrypath/schema.ex
    - lib/scrypath/options.ex
    - test/test_helper.exs
    - test/scrypath/schema_test.exs
    - test/support/searchable_post.ex
    - mix.lock
    - .gitignore
  modified: []
key-decisions:
  - "Kept `use Scrypath` metadata-only and exposed runtime reflection through `__scrypath__/1`."
  - "Centralized schema declaration validation in `Scrypath.Options` with NimbleOptions."
patterns-established:
  - "Schema modules declare search metadata but do not gain generated runtime verbs."
  - "Shared test fixtures live under `test/support/` and load through test_helper."
requirements-completed: [SCMA-01, SCMA-03, BACK-02]
duration: 2m
completed: 2026-04-15
---

# Phase 1: Core Contracts and API Shape Summary

**Metadata-only searchable schema declaration with centralized validation and runtime reflection helpers**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-15T18:50:07-04:00
- **Completed:** 2026-04-15T18:51:53-04:00
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Added the initial Mix scaffold for an Elixir OSS library with Ecto and NimbleOptions.
- Locked the `use Scrypath` declaration contract around normalized `__scrypath__/1` metadata.
- Added schema contract tests and a shared searchable fixture to prove the reflection surface.

## Task Commits

Each task was committed atomically:

1. **Task 1: Initial library scaffold** - `219f137` (feat)
2. **Task 2: Schema declaration contract** - `f93cfb2` (feat)
3. **Task 3: Schema contract tests** - `253682e` (test)

## Files Created/Modified
- `mix.exs` - Mix project definition and dependency boundary
- `.formatter.exs` - Elixir formatter inputs
- `lib/scrypath.ex` - top-level reflection helpers and `use Scrypath` entrypoint
- `lib/scrypath/schema.ex` - metadata declaration macro and `__scrypath__/1`
- `lib/scrypath/options.ex` - schema option validation
- `test/test_helper.exs` - ExUnit bootstrap and support file loading
- `test/support/searchable_post.ex` - shared searchable schema fixture
- `test/scrypath/schema_test.exs` - reflection and validation contract tests
- `mix.lock` - locked dependency resolution for reproducible runs
- `.gitignore` - ignored Elixir build artifacts

## Decisions Made
- Used a persisted module attribute plus `__scrypath__/1` clauses for runtime reflection.
- Stored normalized config as a map so later runtime code can access keys predictably.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `mix.lock` after dependency resolution**
- **Found during:** Task 3 (Schema contract tests)
- **Issue:** Running `mix deps.get` to satisfy verification produced a lockfile the plan did not enumerate.
- **Fix:** Kept `mix.lock` under version control so the new library has reproducible dependency resolution.
- **Files modified:** `mix.lock`
- **Verification:** `mix test test/scrypath/schema_test.exs`
- **Committed in:** `253682e`

**2. [Rule 3 - Blocking] Added Elixir `.gitignore` entries**
- **Found during:** Task 3 (Schema contract tests)
- **Issue:** `_build/` and `deps/` were untracked after the first verification run because the repo had no Elixir ignore rules.
- **Fix:** Added a focused `.gitignore` for generated Elixir artifacts.
- **Files modified:** `.gitignore`
- **Verification:** `git status --short`
- **Committed in:** `253682e`

---

**Total deviations:** 2 auto-fixed (2 blocking hygiene issues)
**Impact on plan:** Both fixes were required to make the new Mix project runnable and keep generated artifacts out of the repo. No API scope changed.

## Issues Encountered
`mix test` initially ran before `mix deps.get` had finished in a parallel verification call. Re-running after dependency installation completed resolved the issue.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
Phase 2 can now build on a stable schema declaration contract, reflection surface, and option-validation layer. The runtime still needs projection, config resolution, and the backend seam before any search sync code can land.

---
*Phase: 01-core-contracts-and-api-shape*
*Completed: 2026-04-15*
