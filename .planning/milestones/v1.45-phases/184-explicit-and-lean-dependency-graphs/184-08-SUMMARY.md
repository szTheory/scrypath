---
phase: 184-explicit-and-lean-dependency-graphs
plan: "08"
subsystem: ci
tags: [github-actions, cache, workflow-security, release-engineering]
requires:
  - phase: 184-01
    provides: [approved dependency and compatibility baseline for release workflows]
provides:
  - Compatible immutable action pins across six workflows with matching version comments
  - Static contracts for action identity, workflow trust boundaries, and Phase 182 cache semantics
  - Current dispositions and revisit triggers for Actions PRs #65, #68, #70, #71, and #72
affects: [ci, dependency-compatibility, release-engineering, github-actions]
actuals:
  tokens: 10863
  tasks: 2
  commits: 2
  plan_head_before: 5b628a0a1f73767d8258cf7aaca694a08f90724b
  plan_head_after: 533f9e38e966f249da69e232292e44b14ab9007e
tech-stack:
  added: []
  patterns:
    - Immutable GitHub Action commit pins carry matching upstream version comments.
    - Workflow event, permissions, checkout, and cache semantics are enforced by source contracts.
key-files:
  created:
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-ACTIONS-DISPOSITIONS.md
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-08-SUMMARY.md
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/workflow-security.yml
    - .github/workflows/website.yml
    - .github/workflows/publish-hex.yml
    - .github/workflows/release-please.yml
    - .github/workflows/verify-published-release.yml
    - scripts/ci/beam_cache.test.cjs
    - test/mix/tasks/workflow_wiring_test.exs
key-decisions:
  - "Use verified immutable releases: checkout v7.0.1, cache v6.1.0, dependency-review v5.0.0, setup-node v7.1.0, and deploy-pages v5.0.1."
  - "Preserve Node 22 as the website build input, npm lockfile cache authority, release tag refs, full-history needs, event conditions, credential persistence, and least-permission job scopes."
  - "Record PR dispositions from a read-only inventory; do not mutate bot PRs or trigger release/publication/deployment events as verification."
requirements-completed: [DEP-07]
coverage:
  - id: D1
    description: "Five Actions PR proposals have current evidence-based dispositions, selected versions, and revisit triggers."
    requirement: DEP-07
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/184-explicit-and-lean-dependency-graphs/184-ACTIONS-DISPOSITIONS.md (read-only GitHub PR inventory and official release metadata)"
        status: pass
    human_judgment: true
    rationale: "A maintainer should review the temporal release and runner compatibility evidence before relying on it for future runner or self-hosted-runner changes."
  - id: D2
    description: "Six workflows use compatible immutable action pins while retaining job, permission, event, checkout, and cache trust contracts."
    requirement: DEP-07
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs (67 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "mix verify.repository_contracts (106 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/ci.yml .github/workflows/workflow-security.yml .github/workflows/website.yml .github/workflows/publish-hex.yml .github/workflows/release-please.yml .github/workflows/verify-published-release.yml"
        status: pass
      - kind: unit
        ref: "node --test scripts/ci/beam_cache.test.cjs (12 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "git diff --check"
        status: pass
    human_judgment: false
metrics:
  duration: "not recorded"
completed: 2026-10-29
status: complete
---

# Phase 184 Plan 08: Explicit and Lean Dependency Graphs Summary

**Six GitHub workflows now use verified immutable Action pins with source contracts that preserve CI, cache, website deployment, and release trust boundaries.**

## Performance

- **Duration:** Not reliably captured; the execution start timestamp was not retained in the resumed context.
- **Started:** Not captured.
- **Completed:** 2026-10-29T20:56:15Z
- **Tasks:** 2
- **Files modified:** 9 (excluding this summary)

## Accomplishments

- Updated CI cache, checkout, dependency-review, website setup-node, and Pages deployment refs to currently compatible immutable commits with matching version comments.
- Preserved exactly five required CI jobs, fail-closed dependency review, cache restore/save topology and trust boundaries, and the independent quality follow-up after dependency audit failure.
- Preserved website Node 22/npm lock authority, push-only Pages deployment, release refs and full-history fetches, default credential persistence, and scoped permissions.
- Recorded current read-only dispositions for Actions PRs #65, #68, #70, #71, and #72, including runner evidence and revisit triggers.

## Task Commits

Each task was committed atomically:

1. **Task 1: Reconcile CI cache and dependency review Actions** - `68ff2277` (`feat`)
2. **Task 2: Reconcile website and release workflow action uses** - `533f9e38` (`feat`)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-ACTIONS-DISPOSITIONS.md` - records five PR dispositions, official release identities, runner requirements, and revisit triggers.
- `.github/workflows/ci.yml` - updates checkout and cache pins and keeps the independent quality follow-up eligible after a failing audit.
- `.github/workflows/workflow-security.yml` - updates checkout and dependency-review pins while retaining fail-closed PR review.
- `.github/workflows/website.yml` - updates checkout, setup-node, and deploy-pages pins without changing Node 22 or npm cache authority.
- `.github/workflows/publish-hex.yml`, `.github/workflows/release-please.yml`, `.github/workflows/verify-published-release.yml` - update checkout pins and retain tag/history behavior.
- `scripts/ci/beam_cache.test.cjs` - checks cache pin comments, graph/environment isolation, and trusted writer boundaries.
- `test/mix/tasks/workflow_wiring_test.exs` - asserts immutable pins across all six workflows and their job, event, permission, checkout, release, and cache contracts.

## Decisions Made

- Adopted checkout `3d3c42e5aac5ba805825da76410c181273ba90b1` (v7.0.1), cache `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` (v6.1.0), dependency review `a1d282b36b6f3519aa1f3fc636f609c47dddb294` (v5.0.0), setup-node `949feb2413d6458794dcd2491c4babbbce0c15c1` (v7.1.0), and deploy-pages `368f82528645a54fb793d4d04e342629a3f51346` (v5.0.1), based on official release and action metadata recorded in the dispositions ledger.
- Kept the website's Node 22 input, `website/package-lock.json` cache dependency path, website push path filter, and job-scoped Pages/OIDC permissions.
- Kept publish tag inputs, full-history checkouts where required, default checkout credential persistence, existing release secrets, and release event gates.

## Verification

- Selected toolchain: Elixir 1.19.5 / OTP 28.5; Node v26.10.0; actionlint 1.7.12.
- `node --test scripts/ci/beam_cache.test.cjs` - 12 tests, 0 failures.
- `HEX_HOME=/private/tmp/scrypath-hex-184-08 ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs` after Task 1 - 62 tests, 0 failures.
- The same compile and focused ExUnit command after Task 2 - 67 tests, 0 failures.
- `HEX_HOME=/private/tmp/scrypath-hex-184-08 ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix verify.repository_contracts` - 106 tests, 0 failures.
- `actionlint` on all six affected workflows - passed.
- `git diff --check` - passed. No old checkout, setup-node, or deploy-pages refs remain in the six affected workflow files.
- `mix.lock` is unchanged; its tree object remains `27ec4c136d6c4338fdcf03b73cc18347ca590612` from plan base `5b628a0a1f73767d8258cf7aaca694a08f90724b` through the production commits.
- Official action source commits are pinned exactly as listed in the dispositions ledger. Node 24 action manifests require runner v2.327.1 or later; the ledger records that GitHub-hosted `ubuntu-latest` is expected to meet this managed-runner floor and calls out the limit for future self-hosted use.
- No exact-SHA hosted CI run, publication, or Pages deployment was triggered. The local checks establish source contracts and syntax, not hosted execution evidence.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The default Hex cache location was not writable in the sandbox during dependency resolution. Re-running with `HEX_HOME=/private/tmp/scrypath-hex-184-08` succeeded without changing `mix.lock` or repository files.
- The plan start timestamp was not retained in the resumed execution context, so duration is reported as not recorded rather than estimated.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 184-08 is complete and ready for plan 184-09. Hosted exact-SHA CI remains part of the repository's closeout process; this summary does not claim that hosted evidence exists.

---
*Phase: 184-explicit-and-lean-dependency-graphs*
*Completed: 2026-10-29*

## Self-Check: PASSED

- Both task commits are ancestors of this worktree HEAD.
- All nine declared created/modified files exist, and the summary is being added in this commit.
- The repository lockfile is unchanged; `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/config.json` were not modified.
