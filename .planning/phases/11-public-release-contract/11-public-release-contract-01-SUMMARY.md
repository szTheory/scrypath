---
phase: 11-public-release-contract
plan: 01
subsystem: release
tags: [elixir, hex, release-please, github-actions, ex_doc]
requires:
  - phase: 10-release-hardening
    provides: "Phase 10 package metadata tests and verify.phase10 orchestration pattern"
provides:
  - "Version-scoped package links derived from the declared release version"
  - "Focused release metadata tests that fail on moving branch/docs URLs"
  - "Canonical mix verify.phase11 gate for manifest, workflow, docs, and local Hex package alignment"
affects: [phase-11-plan-02, release-contract, maintainers, hex-publish]
tech-stack:
  added: []
  patterns: ["Version-derived package metadata", "Phase-specific Mix verify gate", "Shell-level manifest/workflow alignment checks"]
key-files:
  created: [lib/mix/tasks/verify.phase11.ex]
  modified: [mix.exs, test/release/package_metadata_test.exs]
key-decisions:
  - "Release-facing package links stay pinned to @version and @source_ref instead of moving main/latest-doc targets."
  - "Phase 11 verification extends the narrow verify.phase10 orchestration shape instead of introducing a new release script."
patterns-established:
  - "Release contract tests assert exact public URLs exposed by MixProject.project/0."
  - "Release alignment checks combine focused tests, docs warnings-as-errors, grep validation, and local hex.build --unpack."
requirements-completed: [REL-01]
duration: 2min
completed: 2026-04-16
---

# Phase 11 Plan 01: Public Release Contract Summary

**Version-anchored Hex package links and a canonical `mix verify.phase11` gate for Release Please, manifest, and local package alignment**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-16T16:17:00-04:00
- **Completed:** 2026-04-16T16:18:53Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Changed package metadata to publish version-scoped HexDocs, guides, and changelog links derived from `@version` and `@source_ref`.
- Extended the release metadata contract test so moving `main` and latest-doc URLs fail locally and in CI.
- Added `mix verify.phase11` as the canonical auth-free release-alignment gate for tests, docs, Release Please wiring, manifest checks, and local Hex package assembly.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lock release-facing metadata to the package version** - `e454591` (`test`)
2. **Task 2: Add the canonical Phase 11 release-alignment gate** - `f778312` (`feat`)

_Note: Task 1 followed the TDD flow by first proving the new package-link contract failed on the prior moving URLs, then keeping the passing implementation in the same task commit sequence._

## Files Created/Modified

- `mix.exs` - version-derived package links and `verify.phase11` CLI registration
- `test/release/package_metadata_test.exs` - exact release-aware package metadata assertions
- `lib/mix/tasks/verify.phase11.ex` - Phase 11 release-alignment verification task

## Decisions Made

- Kept the repo homepage and source URL fixed on the canonical GitHub repo while scoping only release-facing artifact links by version.
- Reused the narrow `verify.phase10` orchestration pattern so Phase 11 stays a small aggregator over tests and shell checks.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first `verify.phase11` implementation used an over-quoted shell snippet that treated `@source_ref "v#{@version}"` as a literal string instead of an evaluated value. The fix split source-ref validation into its own grep check and reran `mix verify.phase11` successfully.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 11 now has a canonical local gate for release metadata and workflow alignment.
- Plan 11-02 can build on this by adding published-artifact smoke proof and maintainer recovery runbooks.

## Self-Check: PASSED

- Found `.planning/phases/11-public-release-contract/11-public-release-contract-01-SUMMARY.md`
- Found commit `e454591`
- Found commit `f778312`
