---
phase: 182-reliable-full-browser-verification-and-ci-caches
plan: "07"
subsystem: ci
tags: [github-actions, buildx, beam-cache, exact-source, acceptance]

# Dependency graph
requires:
  - phase: 182-06
    provides: Existing exact-source browser verification and CI cache contracts
provides:
  - Exact-source Actions collector for attempt-specific jobs, raw logs, immutable artifacts, and candidate-session history
  - Opt-in Docker and BEAM cache probes wired into existing CI jobs
  - Contributor runbook for isolated namespaces and hosted evidence collection
affects: [phase-182-acceptance, ci, contributor-verification]

# Actuals, measured from the realized non-planning diff at plan closeout.
actuals:
  tokens: 36725
  tasks: 2
  commits: 4
  plan_head_before: 2b4a2a1f3151b4f5e21e96262d0d944d9d1824ec
  plan_head_after: 108e5e711164bd27d7a4ced839603ac745a70a51

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Use gh argument arrays and exact run/attempt identity for hosted evidence collection."
    - "Keep cache experiments in explicit namespaces and preserve each candidate-session attempt."

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - CONTRIBUTING.md
    - scripts/ci/phase182_acceptance.cjs
    - scripts/ci/phase182_acceptance.test.cjs
    - scripts/ci/beam_cache.test.cjs
    - test/mix/tasks/workflow_wiring_test.exs

key-decisions:
  - "Reuse existing CI jobs and canonical Mix verifiers; add opt-in probes without adding a job or required lane."
  - "Use an isolated temporary checkout for the comment-only lock probe and never edit the tracked source lockfile."

patterns-established:
  - "Cache acceptance requires raw hosted import/export evidence in addition to workflow receipts."
  - "A candidate cache namespace is seeded before warm/fallback evidence is collected; runs remain append-only within an explicitly bound session."

requirements-in-scope: [BROW-03, CACHE-01, CACHE-02]
requirements-completed: []

# Coverage metadata
coverage:
  - id: D1
    description: "Exact-source collector validates newly dispatched run/attempt identity, paginated job and artifact records, raw verifier outcomes, archive digests, and candidate-session history."
    verification:
      - kind: unit
        ref: "node --test scripts/ci/phase182_acceptance.test.cjs scripts/ci/beam_cache.test.cjs scripts/ci/ecommerce_build.test.cjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Existing CI jobs expose isolated Docker and BEAM cold, fallback, lock-change, and warm-cache proof controls."
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs"
        status: pass
    human_judgment: true
    rationale: "The local contract tests prove wiring and failure handling; actual GitHub Actions cache imports, exports, cold execution, and full browser acceptance were not run in this plan execution."

# Metrics
duration: 42min
completed: 2026-10-26
status: complete
---

# Phase 182 Plan 07: Exact-Source Acceptance and Cache Probes Summary

**Exact-SHA Actions evidence collection and isolated Docker/BEAM cache probes wired into Scrypath's existing CI jobs.**

## Performance

- **Duration:** 42 min, measured from the earliest recorded task commit; executor start time was not retained across the context handoff.
- **Started:** 2026-10-26T22:02:02-04:00 (first task commit)
- **Completed:** 2026-10-26T22:43:41-04:00
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added a strict collector that binds workflow-dispatch evidence to the requested branch and full source SHA, selects the newly created run and attempt, exhausts job/artifact pagination, checks raw verifier outcomes and immutable artifact bytes, and preserves candidate-session history.
- Added opt-in cache probe controls to existing CI jobs: a fresh cache-free Buildx builder for Docker cold proof, BEAM cold/fallback modes, and a comment-only lock change in a temporary checkout. Existing canonical verification commands and job topology remain in place.
- Documented namespace seeding, probe meanings, collector usage, capability requirements, and evidence boundaries. The tests protect the tooling and wiring; no hosted browser/cache acceptance is claimed here.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED:** `6f9f6fc3` (`test(182-07): add failing exact-source acceptance coverage`)
2. **Task 1 GREEN:** `6e3cede1` (`feat(182-07): collect exact-source acceptance evidence`)
3. **Task 2 RED:** `cfc6cb97` (`test(182-07): add failing workflow probe contract`)
4. **Task 2 GREEN:** `108e5e71` (`feat(182-07): wire cache probes into existing CI jobs`)

The summary metadata is committed separately after this file is written.

## Files Created/Modified

- `.github/workflows/ci.yml` - Added validated manual inputs and proof steps to the existing core, mounted, and full browser jobs.
- `CONTRIBUTING.md` - Added hosted probe modes, namespace seeding, session ownership, and exact-source collector guidance.
- `scripts/ci/phase182_acceptance.cjs` - Added the exact-source collector, cache proof controls, lock-copy preparation, and validation CLI.
- `scripts/ci/phase182_acceptance.test.cjs` - Added collector, cache-mode, namespace, and lock-copy behavior tests.
- `scripts/ci/beam_cache.test.cjs` - Updated the core cache wiring assertion for the new Phase 182 planner wrapper while preserving direct-planner assertions for other jobs.
- `test/mix/tasks/workflow_wiring_test.exs` - Added Phase 182 workflow contract coverage and included the relevant Node suites in the wiring behavior runner.

## Decisions Made

- Reused existing CI jobs and canonical Mix verification commands rather than adding a new job or required check.
- Kept probe cache data isolated by explicit namespace and used an owned temporary checkout for the lock-change experiment.
- Left `BROW-03`, `CACHE-01`, and `CACHE-02` uncompleted in this summary because their live GitHub Actions behavior was not exercised in this run.

## Verification

- <code>node --test scripts/ci/phase182_acceptance.test.cjs scripts/ci/beam_cache.test.cjs scripts/ci/ecommerce_build.test.cjs</code> - **PASS**, 46 tests.
- <code>MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs</code> - **PASS**, 59 tests, 0 failures.
- <code>node --check scripts/ci/phase182_acceptance.cjs</code> - **PASS**.
- <code>git diff --check</code> - **PASS**.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated the existing core cache wiring assertion for the Phase 182 planner wrapper**
- **Found during:** Task 2
- **Issue:** The existing BEAM cache test required the core job to invoke `beam_cache.cjs` directly after the plan routed cache planning through the Phase 182 wrapper.
- **Fix:** Updated the assertion to expect the wrapper for `core` and retain the direct planner expectation for other cache jobs.
- **Files modified:** `scripts/ci/beam_cache.test.cjs`
- **Verification:** Both prescribed Node and ExUnit commands passed.
- **Committed in:** `108e5e71`

**Total deviations:** 1 auto-fixed (Rule 3 - blocking test contract update).
**Impact:** Kept the existing cache contract aligned with the planned wrapper; no job or requirement scope was added.

## Issues Encountered

The first Elixir verification attempt found the checkout's locked dependencies were not fetched. `mix deps.get` initially could not write Hex's user-level registry cache (`:eaccess`); the configured automatic approval path allowed the normal locked dependency fetch to complete. `mix.lock` remained unchanged, and the required ExUnit command then passed.

## User Setup Required

None - no external service configuration was changed.

## Next Phase Readiness

The collector and probe controls are ready for a maintainer-owned hosted run. Actual successful full-browser evidence and real GitHub Actions cache import/export behavior still need to be collected before marking `BROW-03`, `CACHE-01`, or `CACHE-02` complete. No hosted acceptance was attempted or inferred from the synthetic tests.

## Self-Check: PASSED

- All six changed files exist and are tracked on the plan branch.
- All four task commits are present in this branch's history; there were no tracked deletions.
- The prescribed Node and warning-as-error ExUnit checks passed with nonzero test counts.
- `STATE.md` and `ROADMAP.md` were not modified.

---
*Phase: 182-reliable-full-browser-verification-and-ci-caches*
*Completed: 2026-10-26*

## Post-merge preflight repair reconciliation

This follow-up repairs three concrete integration blockers found before Phase 182-08 hosted acceptance. The original plan work and evidence above are preserved. These repairs did not run or claim hosted acceptance, and `requirements-completed` remains empty.

### Repair commits

1. `0e60d9d2` - **Expose BEAM cache restore keys safely.** Core now uses the pinned restore-only action, whose matched-key output is available to the fallback proof. Explicit pinned save steps use each planned primary key, skip exact hits and beam-cold, and require successful core verification.
2. `d101f07f` - **Verify per-target BuildKit cache progress.** The parser accepts the pinned BuildKit GHA export vertex name and binds imports, useful cached steps, and successful exports to every checked Bake target and scope. It rejects missing target progress, exporter warnings/errors, generic unscoped headlines, forged mappings, and status-only assertions. The collector and validator share this parser and retain hashes of the matched log bytes.
3. `29fab44b` - **Preserve validated Docker probe policy.** Preparation, configuration checks, and pre/post handoff verification now share one mode/namespace policy. Candidate refs can export only to bounded namespaces on trusted same-repository workflow dispatch; cold mode has no cache imports or exports. The workflow carries probe inputs into preparation and both handoff checks. The contributor runbook and CLI help now show the seed-first collection sequence and the required session-root and identity arguments for both validation modes.

### Repair verification

- <code>node --test scripts/ci/ecommerce_*.test.cjs scripts/ci/beam_cache.test.cjs scripts/ci/phase182_acceptance.test.cjs</code> - **PASS**, 90 tests, 0 failures.
- <code>HEX_HOME=/private/tmp/scrypath-phase182-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.19.0-otp-28 asdf exec mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs</code> - **PASS**, Elixir 1.19.0 / OTP 28, 59 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.0-otp-28 asdf exec mix format --check-formatted` - **PASS** under Elixir 1.19.0.
- `actionlint .github/workflows/ci.yml` - **PASS**.
- <code>git diff --check</code> - **PASS** before the repair commit.

The checkout did not initially have Mix dependencies fetched. The locked dependencies were fetched without changing `mix.lock`, using a Hex cache under `/private/tmp` after the default user-level Hex registry cache rejected writes. The focused ExUnit run then exposed unsupported `String.index/2` assertions in the cache wiring test; these were changed to `:binary.match/2` and formatted with the CI Elixir version. A first policy test attempt also exposed incomplete dispatch environment setup in the test fixture; the fixture was aligned with the workflow inputs, and the final complete Node run passed.

### Acceptance limits

No GitHub Actions workflow was dispatched. Synthetic logs and Docker doubles verify parser, wiring, policy, source/model/tag identity, and runtime handoff behavior only; they do not establish real GHA cache imports/exports, browser acceptance, or hosted timing. The seed-first real run and strict `validate --mode caches` plus `validate --mode full` commands are documented for the Phase 182-08 executor. The five required jobs, advisory full job, 1800-second budget, trust boundaries, locks, source joins, and retained preview data were preserved. `STATE.md`, `ROADMAP.md`, and `REQUIREMENTS.md` were not changed.

## Repair Self-Check: PASSED

- The three repair commits are present on this branch; no tracked files were deleted.
- All requested local regression, formatter, workflow lint, and diff checks passed.
- Hosted acceptance remains unclaimed, and all original requirement IDs remain pending.
