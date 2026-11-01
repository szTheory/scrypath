---
phase: 184-explicit-and-lean-dependency-graphs
plan: "07"
subsystem: dependencies
tags: [elixir, mix, hex, req, oban, bandit, sigra]

# Dependency graph
requires:
  - phase: 184-06
    provides: isolated consumer verification and cold mounted runtime checks
provides:
  - Four independently refreshed Mix locks with stable compatible Req, Oban and Bandit selections
  - Current non-retired optional Sigra selection and a primary-source dependency evidence ledger
affects: [dependency-management, phase-184-10]

# Actuals
actuals:
  tokens: 21939
  tasks: 2
  commits: 2
  plan_head_before: 0e90ba9505500681ba0191adbd945c4123c865fa
  plan_head_after: 599086408c08ffd43e045354730dc5d547da4a19

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Resolve and prune each consumer Mix graph independently after inspecting its active tree
    - Record registry metadata, lock digests, verifier results and advisory findings together
key-files:
  created:
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-DEPENDENCY-EVIDENCE.md
  modified:
    - mix.exs
    - mix.lock
    - scrypath_ops/mix.lock
    - examples/phoenix_meilisearch/mix.lock
    - examples/scrypath_ecommerce/mix.lock
    - test/scrypath/docs_contract_test.exs
key-decisions:
  - "Adopt Req 0.7.5 and Oban 2.24.2 while preserving the public Req union and optional Oban boundary."
  - "Use Bandit 1.14.1 across Ops and both examples; preserve each existing manifest bound."
  - "Keep Sigra optional under the existing ~> 1.5 bound and select non-retired 1.7.1 rather than retired 1.20.0."
  - "Advance the ExDoc development bound to ~> 0.40 because release metadata retains the Elixir 1.17 floor."
requirements-completed: [DEP-01, DEP-02, DEP-03, DEP-06, DEP-07]
coverage:
  - id: D1
    description: Root runtime and test tooling use compatible stable releases with the public Req and optional Oban boundaries preserved.
    verification:
      - kind: unit
        ref: "mix test --exclude integration --exclude docs_contract"
        status: pass
      - kind: other
        ref: "mix docs --warnings-as-errors"
        status: pass
      - kind: other
        ref: "mix dialyzer"
        status: pass
      - kind: integration
        ref: "mix verify.no_optional_deps"
        status: pass
      - kind: integration
        ref: "mix verify.package (final locks)"
        status: pass
    human_judgment: false
  - id: D2
    description: Ops and both example graphs use refreshed compatible Req, Bandit and Oban selections, preserve optional Sigra, and pass affected consumer behavior checks.
    verification:
      - kind: integration
        ref: "mix verify.ops_ui"
        status: pass
      - kind: integration
        ref: "mix verify.phoenix_example --package"
        status: pass
      - kind: integration
        ref: "mix verify.backend"
        status: pass
      - kind: e2e
        ref: "mix verify.ecommerce_mounted"
        status: pass
      - kind: other
        ref: "scripts/ci/dependency_audit.exs (Hex 2.5.1; Ops findings recorded in evidence ledger)"
        status: fail
    human_judgment: true
    rationale: "The final Ops graph still reports high and medium Cloak advisories that require an explicit maintainer disposition; the audit result is recorded as affected and was not ignored."
duration: 2h 19m
completed: 2026-10-30
status: complete
---

# Phase 184 Plan 07: Explicit and Lean Dependency Graphs Summary

**Four independent locks now select coordinated Req 0.7.5, Oban 2.24.2 and fixed Bandit 1.14.1, with usable optional Sigra 1.7.1**

## Performance

- **Duration:** 2h 19m
- **Started:** 2026-10-30T04:36:24Z
- **Completed:** 2026-10-30T06:55:33Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Refreshed the root graph to Req 0.7.5, optional Oban 2.24.2, StreamData 1.4.0, ExDoc 0.40.4 and Dialyxir 1.4.8. Preserved the public Req union and Telemetry bound; narrowed only the ExDoc dev/test bound to ~> 0.40.
- Independently updated the Ops, Phoenix example and ecommerce locks to Bandit 1.14.1 and Req 0.7.5, with Oban 2.24.2 in both examples. Kept Ops Sigra optional and selected non-retired 1.7.1.
- Pruned only unused mail dependencies after inspecting the full active graphs; recorded source links, exact manifest/lock digests, toolchain and advisory dispositions in 184-DEPENDENCY-EVIDENCE.md.
- Ran the required root, Ops, Phoenix package, backend and cold ecommerce mounted checks against the final locks.

## Verification

All Mix checks ran with Elixir 1.19.5 / OTP 28.5 and private per-project dependency/build paths. The evidence ledger contains exact source and lock hashes.

| Command | Result |
| --- | --- |
| mix test --exclude integration --exclude docs_contract | PASS — 1,012 tests and 5 properties, 0 failures. |
| mix docs --warnings-as-errors | PASS. |
| mix dialyzer | PASS — zero errors. |
| mix verify.no_optional_deps | PASS — isolated build without Oban. |
| mix verify.package | PASS — repeated after final consumer locks; release contract and package consumer proofs completed. |
| mix verify.ops_ui | PASS — root boundary 2 tests; Ops suite 2 doctests and 316 tests; 0 failures. |
| mix verify.phoenix_example --package | PASS — staged package compiled; 18 integration tests, 0 failures. |
| mix verify.backend | PASS — Meilisearch and Postgres loader checks; loader property ran 15 tests with 0 failures. |
| mix verify.ecommerce_mounted | PASS — cold test and production dependency-boundary images and served assets; focused Playwright 4 passed; cleanup succeeded. |
| mix deps.get --check-locked in all four graphs | PASS — final locks resolved without mutation. |

The dependency audit completed with root, phoenix_meilisearch and scrypath_ecommerce clean. Ops remains affected by high Cloak 1.1.4 and medium Cloak Ecto 1.3.0 findings; no advisories were ignored. Bandit 1.14.1 has no finding in the final full-lock audit. This plan records the remaining findings as unaccepted for maintainer disposition rather than claiming a clean aggregate audit.

The Ops direct suite emitted PostgreSQL 53300 too_many_connections connection-attempt errors during parallel tests, but completed with 316 tests and zero failures. The core support floor Elixir 1.17 / OTP 26 was not exercised in this plan; the selected Sigra tier was exercised on Elixir 1.19.5 / OTP 28.5, and its Elixir ~> 1.18 requirement is documented in the ledger.

## Task Commits

Each task was committed atomically:

1. **184-07-01: Resolve root runtime/test tooling with primary-source evidence** — 4efc3bee (chore)
2. **184-07-02: Resolve Ops and both example graphs; fix compatible advisories** — 59908640 (chore)

**Plan metadata:** this summary commit.

## Files Created/Modified

- mix.exs, mix.lock — root tooling bounds and refreshed root graph.
- scrypath_ops/mix.lock, examples/phoenix_meilisearch/mix.lock, examples/scrypath_ecommerce/mix.lock — independently resolved consumer graphs.
- test/scrypath/docs_contract_test.exs — updated the release verifier contract assertion to match its current System.cmd/3 dispatch.
- .planning/phases/184-explicit-and-lean-dependency-graphs/184-DEPENDENCY-EVIDENCE.md — primary-source, hash, verification and advisory evidence.

## Decisions Made

- Kept independent consumer resolution and avoided adding dependency overrides.
- Kept the existing Sigra manifest requirement and optional status. A temporary resolver constraint selected 1.7.1; the manifest was restored and the final lock was checked against it.
- Preserved the exact public Req union and optional Oban contract while coordinating stable defaults across the graphs.
- Kept Hex's Cloak findings visible and unaccepted; updating Bandit does not resolve them.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated the stale release verifier contract assertion**
- **Found during:** Task 184-07-01
- **Issue:** The package gate failed because the docs contract test still expected a literal "mix test" command after the verifier moved to structured System.cmd/3 dispatch.
- **Fix:** Updated the focused test to assert the current executable, argument list and working-directory contract.
- **Files modified:** test/scrypath/docs_contract_test.exs
- **Verification:** Focused contract test passed (74 tests, 0 failures); final mix verify.package passed.
- **Committed in:** 4efc3bee

**2. [Rule 3 - Blocking] Replaced the retired Sigra lock selection**
- **Found during:** Task 184-07-02
- **Issue:** The existing ~> 1.5 constraint admitted Hex-retired Sigra 1.20.0, which the resolver selected.
- **Fix:** Temporarily constrained resolution to the usable 1.7.x line, selected 1.7.1, restored the original manifest constraint and verified the lock against it.
- **Files modified:** scrypath_ops/mix.lock
- **Verification:** Hex release metadata confirms 1.20.0 is retired and 1.7.1 is non-retired; Ops tests and final lock checks passed.
- **Committed in:** 59908640

**Total deviations:** 2 auto-fixed (2 blocking issues). **Impact:** Both fixes were scoped to required verification and correct release selection.

## Issues Encountered

- The aggregate Hex audit remains nonzero for the documented Ops Cloak advisories. The plan requires those findings to remain explicitly unaccepted; they are preserved without ignore entries.
- The first mounted ecommerce verifier attempt could not write Buildx metadata under the read-only user home. Rerunning with private BUILDX_CONFIG passed while leaving the retained preview services running.
- The Ops tests encountered transient PostgreSQL connection-limit errors noted above, while the test suite still completed successfully.

## User Setup Required

None — verification services used disposable local targets and were cleaned up.

## Next Phase Readiness

The four lock graphs and verification evidence are ready for the next plan. Keep the unresolved Ops Cloak findings visible for explicit maintainer disposition; the support matrix and exact-source review remain for phase 184-10.

## Self-Check: PASSED

- The Task 184-07-01 and Task 184-07-02 commits are ancestors of this worktree HEAD.
- All seven production/evidence files listed above exist; the completed root package check has an explicit exit status of 0.
- Required final-lock behavior checks passed, and the nonzero advisory audit is accurately recorded as an unresolved finding.
- STATE.md and ROADMAP.md were not modified.

---
*Phase: 184-explicit-and-lean-dependency-graphs*
*Completed: 2026-10-30*
