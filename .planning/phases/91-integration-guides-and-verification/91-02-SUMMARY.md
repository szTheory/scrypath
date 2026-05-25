---
phase: 91-integration-guides-and-verification
plan: 02
subsystem: testing
tags: [mix-task, verify, docs-contract, related-data, fan-out, hermetic]

requires:
  - phase: 91-01
    provides: "Canonical sync_related/3 guide rewrite with shared canonical-string contract"

provides:
  - "Mix.Tasks.Verify.Phase91 — hermetic related-data + docs-contract gate"
  - "Inverted docs-contract assertion locking canonical sync_related/3 story (D-11)"
  - "@verify_phase91 discoverability attr + 'stays wired' test (D-12)"

affects:
  - "91-03 (inherits the green verify.phase91 gate as a correctness baseline)"

tech-stack:
  added: []
  patterns:
    - "verify.phaseNN task family: copy verify.phase85 shape, swap module/label/@focused_tests"
    - "Discoverability triple: @verify_phaseNN attr + stays-wired test + mix.exs preferred_envs"
    - "Inverted docs-contract: refute banned strings + assert_contains_all canonical strings"

key-files:
  created:
    - "lib/mix/tasks/verify.phase91.ex"
  modified:
    - "test/scrypath/docs_contract_test.exs"
    - "mix.exs"
    - "guides/related-data-and-reindexing.md"

key-decisions:
  - "verify.phase91 @focused_tests contains ONLY hermetic library tests (TEST-01 boundary): related_test.exs, related_worker_test.exs, docs_contract_test.exs — no examples/ smoke paths."
  - "Inverted assertion uses refute + assert_contains_all over the exact 7 canonical strings from 91-01-SUMMARY.md shared-contract section."
  - "Guide fix: removed backtick wrapping of Scrypath.Sync.RelatedWorker in guides/related-data-and-reindexing.md:91 to prevent ExDoc hidden-module warning breaking --warnings-as-errors (Rule 1 auto-fix)."

requirements-completed: [TEST-01, TEST-02]

duration: ~10m
completed: 2026-05-25
---

# Phase 91 Plan 02: verify.phase91 Task + Inverted Docs-Contract Summary

**`Mix.Tasks.Verify.Phase91` hermetic gate running 3 related-data tests + docs-with-warnings-as-errors, with inverted docs-contract assertion locking the canonical `sync_related/3` fan-out story and forbidding the temporary-workaround framing.**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-05-25T06:31:00Z
- **Tasks:** 2 (+ 1 Rule 1 auto-fix)
- **Files modified:** 4

## Accomplishments

- Created `lib/mix/tasks/verify.phase91.ex` mirroring `verify.phase85` exactly: `@focused_tests` locked to the three hermetic related-data tests, `Mix.Task.reenable("test")` + `reenable("docs")` mandatory calls preserved, `mix docs --warnings-as-errors` as final step.
- Registered `"verify.phase91": :test` in `mix.exs` preferred_envs so the task runs under `:test` and can load test files (Pitfall 3 avoided).
- Added `@verify_phase91` attribute, "verify.phase91 stays wired into the focused maintainer flow" test, and replaced the old `"related-data guide explicitly mentions temporary Oban workaround"` test with the inverted `"related-data guide adopts sync_related/3 as the canonical fan-out story"` test in `docs_contract_test.exs`.
- Inverted test: `refute`s `"temporary workaround"` and `"first-class feature"` (D-09), and `assert_contains_all` over 7 canonical strings from the 91-01 shared contract.
- `mix verify.phase91` exits 0: 73 tests, 0 failures; docs build clean with no warnings.

## Task Commits

1. **Task 1: Create Mix.Tasks.Verify.Phase91 + register in mix.exs preferred_envs** - `177d661` (feat)
2. **Task 2: Invert related-data docs-contract assertion + @verify_phase91 + stays-wired test** - `b1906f8` (feat)
3. **Rule 1 auto-fix: Remove hidden-module backtick to unblock docs --warnings-as-errors** - `f4d9334` (fix)

## Files Created/Modified

- `lib/mix/tasks/verify.phase91.ex` — New Mix task: hermetic gate for related-data fan-out + docs-contract verification
- `test/scrypath/docs_contract_test.exs` — Added `@verify_phase91`, "stays wired" test, and inverted docs-contract assertion
- `mix.exs` — Added `"verify.phase91": :test` to `preferred_envs`
- `guides/related-data-and-reindexing.md` — Removed backtick wrapping of hidden internal module name (Rule 1 auto-fix)

## Decisions Made

- `@focused_tests` contains exactly three hermetic paths in order: `related_test.exs`, `related_worker_test.exs`, `docs_contract_test.exs`. No `examples/` smoke paths (TEST-01 boundary).
- Inverted assertion asserts all 7 strings from the 91-01-SUMMARY.md canonical-string contract: `Scrypath.sync_related/3`, `fan_outs:`, `sync_mode: :inline`, `sync_mode: :oban`, `callback magic`, `contexts own orchestration`, `library owns execution`.
- "stays wired" test placement: immediately after the `verify.phase85 stays wired` test, matching the established block style.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed hidden-module backtick reference causing ExDoc --warnings-as-errors failure**
- **Found during:** Task 1 verification (`mix verify.phase91`)
- **Issue:** `guides/related-data-and-reindexing.md` line 91 had `` `Scrypath.Sync.RelatedWorker` `` in a backtick span. ExDoc treats this as a module link and warns "references module ... but it is hidden" because `RelatedWorker` is `@moduledoc false`. With `--warnings-as-errors` this exits non-zero, blocking `mix verify.phase91`.
- **Fix:** Replaced the backtick module reference with prose `"an internal Scrypath worker"` which preserves the same meaning without triggering ExDoc module-link detection.
- **Files modified:** `guides/related-data-and-reindexing.md`
- **Verification:** `mix verify.phase91` exits 0 with clean docs build after fix.
- **Committed in:** `f4d9334`

---

**Total deviations:** 1 auto-fixed (Rule 1 bug)
**Impact on plan:** Required to achieve the plan's own success criterion (`mix verify.phase91` exits 0). No scope creep — the guide prose meaning is preserved.

## Issues Encountered

None beyond the Rule 1 auto-fix documented above.

## User Setup Required

None — no external service configuration required. All tests are hermetic (no live Meilisearch).

## Next Phase Readiness

- `mix verify.phase91` green baseline established for 91-03.
- 91-03 can add `Author` schema fan-out + Blog context + smoke tests without touching the hermetic gate or the docs-contract assertions (those strings are already locked in the guide by 91-01).
- No blockers.

---
*Phase: 91-integration-guides-and-verification*
*Completed: 2026-05-25*
