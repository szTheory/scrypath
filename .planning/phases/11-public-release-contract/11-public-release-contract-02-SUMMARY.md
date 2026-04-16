---
phase: 11-public-release-contract
plan: 02
subsystem: release
tags: [elixir, hex, release-please, docs, verification]
requires:
  - phase: 11-public-release-contract
    provides: "Version-scoped release metadata and the canonical verify.phase11 gate from Plan 01"
provides:
  - "A clean-consumer smoke harness built from the packaged artifact under test"
  - "Concrete maintainer runbooks for canonical release, drift recovery, failed publish, and artifact mismatch"
  - "Phase 11 docs-contract enforcement for the public release path and recovery contract"
affects: [maintainers, release-contract, hex-publish, public-docs]
tech-stack:
  added: []
  patterns: ["Temporary consumer Mix app smoke verification", "Release-runbook docs contracts", "Auth-free aggregate release gate"]
key-files:
  created: [test/release/consumer_smoke_test.exs]
  modified: [docs/releasing.md, test/scrypath/docs_contract_test.exs, lib/mix/tasks/verify.phase11.ex]
key-decisions:
  - "The local clean-consumer proof uses the unpacked Hex package contents wrapped in a tagged local git repo so the smoke test avoids `path:` dependencies while staying auth-free."
  - "Phase 11 release docs stay tied to the existing Release Please plus GitHub Actions publish flow instead of introducing any parallel publish path."
patterns-established:
  - "Public release verification now includes package metadata, clean-consumer compile proof, release-doc contracts, docs build, workflow alignment, and local package assembly under `mix verify.phase11`."
  - "Maintainer runbooks name exact files and commands so drift and publish recovery stay testable."
requirements-completed: [REL-02, REL-03]
duration: 10min
completed: 2026-04-16
---

# Phase 11 Plan 02: Public Release Contract Summary

**Clean-consumer compile proof and maintainer recovery runbooks enforced through the Phase 11 release gate**

## Performance

- **Duration:** 10 min
- **Completed:** 2026-04-16T20:27:12Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `test/release/consumer_smoke_test.exs`, which builds the local package artifact, wraps it in a tagged temporary git repo, generates a throwaway Mix app with `mix new`, installs Scrypath without a `path:` dependency, and proves the documented `use Scrypath` schema compiles.
- Expanded `docs/releasing.md` into one canonical maintainer contract with a Phase 11 gate, post-publish public smoke steps, and concrete recovery runbooks for tag/version drift, failed publish, and published artifact mismatch.
- Extended `test/scrypath/docs_contract_test.exs` so Phase 11 now enforces the release gate name, recovery headings, recovery commands, and the explicit HexDocs public smoke language.

## Task Commits

1. **Task 1 RED: consumer smoke contract** - `3b3f57e` (`test`)
2. **Task 1 GREEN: clean-consumer smoke verification** - `41fa6f8` (`feat`)
3. **Task 2: maintainer release recovery runbooks** - `9daf4b8` (`docs`)
4. **Task 3 RED: failing Phase 11 release contract checks** - `18499be` (`test`)
5. **Task 3 GREEN: enforce the Phase 11 release contract** - `7a34f44` (`feat`)

## Files Created/Modified

- `test/release/consumer_smoke_test.exs` - temp-app consumer smoke harness for the packaged artifact under test
- `lib/mix/tasks/verify.phase11.ex` - Phase 11 gate now includes the consumer smoke test
- `docs/releasing.md` - canonical release flow, clean-consumer public smoke, and three recovery runbooks
- `test/scrypath/docs_contract_test.exs` - docs contract checks for the Phase 11 release path and recovery language

## Decisions Made

- Kept the local clean-consumer proof auth-free by building the package locally and consuming the packaged contents through a versioned git tag rather than a repo `path:` dependency.
- Kept `mix verify.phase11` as the only automated local release gate; live Hex publication and live HexDocs reachability stay documented as manual-only release checks.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Updated the existing docs contract to the Phase 11 gate name**
- **Found during:** Task 2 verification
- **Issue:** `test/scrypath/docs_contract_test.exs` still enforced `mix verify.phase10`, so the Task 2 release-doc rewrite could not pass its verify step after moving the canonical gate to Phase 11.
- **Fix:** Repointed the existing release-doc expectation to `mix verify.phase11` before continuing with the fuller Phase 11 contract work.
- **Files modified:** `test/scrypath/docs_contract_test.exs`
- **Commit:** `9daf4b8`

**2. [Rule 1 - Bug] Added explicit HexDocs wording to the public smoke runbook**
- **Found during:** Task 3 TDD RED phase
- **Issue:** The docs included the versioned HexDocs URL but did not explicitly name HexDocs, leaving the new Phase 11 contract test red.
- **Fix:** Added explicit HexDocs wording to the canonical post-publish checks.
- **Files modified:** `docs/releasing.md`
- **Commit:** `7a34f44`

## Known Stubs

None.

## Threat Flags

None.

## Verification

- `mix test test/release/consumer_smoke_test.exs`
- `mix test test/scrypath/docs_contract_test.exs`
- `mix verify.phase11`

## Self-Check: PASSED

- Found `.planning/phases/11-public-release-contract/11-public-release-contract-02-SUMMARY.md`
- Found commit `3b3f57e`
- Found commit `41fa6f8`
- Found commit `9daf4b8`
- Found commit `18499be`
- Found commit `7a34f44`
