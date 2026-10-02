---
phase: 170-documentation-and-readiness-closeout
plan: "02"
subsystem: readiness tooling
tags: [github-actions, ci, attestation, closeout]

# Dependency graph
requires:
  - phase: 170-01
    provides: Documentation delivery branch and established closeout workflow context
provides:
  - Read-only exact-run and attempt readiness evidence collection
  - Factual readiness record validation and deterministic comment rendering/readback
  - Fake CLI regression coverage and contributor documentation for the commands
affects: [170-03, 170-04, 170-06, 170-08]

# Actuals measured from the Plan 02 diff, chars/4; commit count measured from the plan base.
actuals:
  tokens: 24213
  tasks: 3
  commits: 3
commits: 3
plan_head_before: b8a746677bf092e24888dbfb46c62f7f6958348e

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Explicit repository, source SHA, run, and attempt identities remain joined throughout collection.
    - Archive digest and extracted attestation-member digest remain separate evidence facts.
    - Readiness tooling validates supplied judgments and never creates semantic judgments or approval.

key-files:
  created: []
  modified:
    - scripts/ci_monitor.cjs
    - test/scripts/ci_monitor_test.exs
    - CONTRIBUTING.md

key-decisions:
  - "Reuse the existing CI maintenance CLI and add no dependency, lane, or dispatch contract."
  - "Keep collection read-only, attempt-specific, bounded, and explicit about archive versus member hashes."
  - "Require supplied condition judgments, provenance, and maintainer decision; validation is factual and cannot authorize posting."
  - "Preserve the seven inherited edge probes as unresolved user-level assumptions."

patterns-established:
  - "Fake GH_BIN and GIT_BIN fixtures exercise collector and validator boundaries without live services."
  - "Canonical public records use an allowlist and stable rendering; corrections retain dated supersession identity."

requirements-completed: [GATE-05, CLOSE-04]
coverage:
  - id: D1
    description: "Collect and validate exact-attempt closeout evidence and attestation bytes with fail-closed identity and archive checks."
    requirement: GATE-05
    verification:
      - kind: unit
        ref: "mix test test/scripts/ci_monitor_test.exs"
        status: pass
      - kind: other
        ref: "MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract"
        status: pass
    human_judgment: false
  - id: D2
    description: "Validate an externally supplied readiness record and verify the authoritative public comment without inferring approval."
    requirement: CLOSE-04
    verification:
      - kind: unit
        ref: "mix test test/scripts/ci_monitor_test.exs"
        status: pass
    human_judgment: true
    rationale: "The tooling checks structure and provenance only; six-condition meaning, scope choices, and the terminal maintainer decision require an accountable human and later closeout plans."

# Metrics
duration: 37min
completed: 2026-09-30
status: complete
---

# Phase 170 Plan 02: Exact-Source Readiness Evidence Summary

**Read-only exact-attempt evidence collection, fail-closed readiness record checks, and deterministic comment verification now run through the existing CI maintenance CLI.**

## Performance

- **Duration:** 37 min (measured from first task commit through final task commit; initial exploration is not included)
- **Started:** 2026-09-30T17:29:19Z
- **Completed:** 2026-09-30T18:05:46Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added `collect-readiness` to join explicit repository, SHA, run, and attempt identities; exhaust paginated jobs and artifacts; validate the exact expected job set and workflow facts; download bounded binary evidence outside the checkout; verify artifact and attestation hashes; and retain the validated attestation bytes.
- Added `validate-readiness` stages for draft, inputs, and terminal records, plus stable public comment rendering and read-only authoritative comment readback. Supplied judgments, evidence limits, provenance, delivery state, and a human decision are required; READY cannot be inferred from passing automation.
- Added service-free fake CLI fixtures for identity, archive, record, correction, and comment boundaries, and documented explicit command arguments, external output paths, record schema, hash distinctions, and factual-only limits in CONTRIBUTING.

## Task Commits

Each task was committed atomically on `agent-170-01-docs`, preserving Plan 01's preceding commits for Plan 04:

1. **Task 1: Collect exact-attempt readiness evidence** - `8e66905` (feat)
2. **Task 2: Validate frozen readiness records** - `a63293a` (feat)
3. **Task 3: Document factual readiness checks** - `db3948f` (feat)

**Plan metadata:** the summary and maintainer tracking updates were committed after the restricted Git index write was approved for the named files only.

## Files Created/Modified

- `scripts/ci_monitor.cjs` - bounded exact-attempt collection, validation, deterministic rendering, and read-only comment verification.
- `test/scripts/ci_monitor_test.exs` - positive and negative fake-CLI fixtures using real archive hashes.
- `CONTRIBUTING.md` - contributor-facing command and limitation documentation.

## Decisions Made

- Reused the existing command surface and left workflow dispatch, release ownership, dependencies, and required/advisory topology unchanged.
- Kept source identity, run attempt, artifact identity, archive digest, and attestation-member digest distinct and explicit.
- Kept semantic condition assessment, risk acceptance, and approval with the accountable maintainer; the tooling only checks supplied facts and structure.
- Preserved all seven inherited edge probes as unresolved user-level assumptions.

## Deviations from Plan

None - plan executed as written. No additional workflow lane or dependency was introduced.

## Issues Encountered

- The delivery branch is a linked worktree whose Git metadata resides under the pinned checkout. Filesystem writes to that metadata were restricted, so task commits used the authorized narrow Git operation while source edits remained in the delivery worktree. All three task commits are present and the worktree is clean.
- The first normal-sandbox attempt to write maintainer metadata returned `staging_failed` because creating `.git/index.lock` was denied (`Operation not permitted`). The phase orchestrator committed only the summary and related tracking files through the approved narrow Git operation; unrelated checkout changes remained unstaged.

## Verification

- `node --check scripts/ci_monitor.cjs` - passed.
- `mix test test/scripts/ci_monitor_test.exs` - passed, 14 tests and 0 failures.
- `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract` - passed, 638 tests and 0 failures (85 excluded).
- `mix docs --warnings-as-errors` - passed.
- `git diff --check` - passed.
- Focused feedback time measured once: 11.323 seconds.
- Delivery branch `agent-170-01-docs` contains the four preserved Plan 01 commits followed by the three Plan 02 commits and has no uncommitted changes.

## Known Stubs

None found in the files changed by this plan.

## User Setup Required

None - no external service configuration is needed for the read-only commands or fake CLI fixtures.

## Next Phase Readiness

Plan 03 can bound the durable evidence set and establish its pointer using the new factual checks. Plan 04 can join these commits to Plan 01 on the preserved delivery branch. The tooling does not assess the truth of the six readiness conditions or make the terminal decision; those remain for the later closeout plans and maintainer.

---
*Phase: 170-documentation-and-readiness-closeout*
*Completed: 2026-09-30*

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Task commits `8e66905`, `a63293a`, and `db3948f` exist on the delivery branch.
- Delivery worktree is clean; unrelated maintainer-checkout changes remain unstaged.
- The summary and matching state, roadmap, and requirement tracking updates are committed on the maintainer branch.
