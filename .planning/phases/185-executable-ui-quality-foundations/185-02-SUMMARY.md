---
phase: 185-executable-ui-quality-foundations
plan: "02"
subsystem: ui-verification
tags: [ui-literals, git-history, repository-contracts, css, tailwind]

requires:
  - phase: 185-01
    provides:
      - Canonical repository-contracts lane and disposable subprocess contract patterns
provides:
  - Bounded scanner for four classes of authored UI literals
  - Immutable-bootstrap, shrink-only multiset ledger
  - Event-aware trusted Git history resolver for local checks and CI
  - Required repository-contracts integration and CI invocation
affects: [repository-contracts, phase-185-ui-quality-gates]

actuals:
  tokens: 19825
  tasks: 2
  commits: 8
  plan_head_before: 0d39fa8b40e3a666d36256ac9cf95b6313f9e732
  plan_head_after: 619cd3ce215f07a5477148b05429367972a5a7c1

tech-stack:
  added: []
  patterns:
    - Bounded authored-source scanning with stable structural identities
    - Exact integer multiset ledger with first-parent monotonicity
    - Immutable Git-tree bootstrap and independently fetched trusted target
    - Canonical production command exercised from root contracts and required CI

key-files:
  created:
    - scripts/ci/ui_literal_policy.cjs
    - scripts/ci/ui_literal_policy.test.cjs
    - scripts/ci/ui-literal-baseline.json
    - test/mix/tasks/ui_literal_contract_test.exs
  modified:
    - dev/mix/tasks/verify.phase99.ex
    - .github/workflows/ci.yml

key-decisions:
  - "Pin bootstrap inventory to immutable commit 767f368473f17fba43d7be4675c53ab65a87530c and introduce its exact 36-occurrence ledger before reductions."
  - "Keep production comparison authority in the canonical origin and event resolver; the CLI accepts no candidate, target, bootstrap, or skip override."
  - "Run the same production resolver from local checks, the root focused contract, and the existing full-history repository-contracts CI job."

requirements-completed: [UIF-01]

coverage:
  - id: D1
    description: "The bounded scanner finds raw hex, arbitrary utility values, inline styles, and literal z utilities with stable identities and exact multiplicities."
    requirement: UIF-01
    verification:
      - kind: unit
        ref: "scripts/ci/ui_literal_policy.test.cjs#discovers the four rules only in authored UI sources and keeps stable identities"
        status: pass
      - kind: unit
        ref: "scripts/ci/ui_literal_policy.test.cjs#malformed ledger metadata and non-integer multiplicities fail closed"
        status: pass
    human_judgment: false
  - id: D2
    description: "The first committed ledger matches the immutable bootstrap inventory, and later candidate history cannot grow, reset, or reverse it."
    requirement: UIF-01
    verification:
      - kind: unit
        ref: "scripts/ci/ui_literal_policy.test.cjs#the committed bootstrap ledger is the exact pinned-source multiset"
        status: pass
      - kind: unit
        ref: "scripts/ci/ui_literal_policy.test.cjs#a side-branch merge cannot hide a first-parent ledger increase"
        status: pass
      - kind: integration
        ref: "test/mix/tasks/ui_literal_contract_test.exs#canonical child fails when source and candidate ledger bless a new finding"
        status: pass
    human_judgment: false
  - id: D3
    description: "Local, pull request, push, schedule, and manual-dispatch runs resolve comparison history from validated event and canonical-origin authority."
    requirement: UIF-01
    verification:
      - kind: unit
        ref: "scripts/ci/ui_literal_policy.test.cjs#event resolution pins local, PR, push, schedule and dispatch authorities"
        status: pass
      - kind: integration
        ref: "test/mix/tasks/ui_literal_contract_test.exs#production command checks this checkout against fresh trusted history"
        status: pass
    human_judgment: false
  - id: D4
    description: "The required repository-contracts CI job runs the production resolver with full checkout history and reports its resolved OIDs."
    requirement: UIF-01
    verification:
      - kind: integration
        ref: "test/mix/tasks/ui_literal_contract_test.exs#required repository-contracts lane runs the production resolver with full history"
        status: pass
    human_judgment: false

duration: "40 min"
completed: 2026-10-31
status: complete
---

# Phase 185 Plan 02: Executable UI Quality Foundations Summary

A bounded scanner and first-parent Git ratchet now enforce a pinned, shrink-only multiset of 36 authored UI literal findings, with the same trusted resolver in local checks and required CI.

## Performance

- Duration: 40 minutes measured from the first Plan 02 task commit through the final implementation commit; preparation preceded that recorded interval.
- Started: 2026-10-31T09:45:09-04:00, the first task commit.
- Completed: 2026-10-31T10:24:47-04:00, the final implementation commit.
- Tasks: 2 complete.
- Files created or modified: 6.

## Accomplishments

- Added bounded, dependency-free discovery and scanning across the four authored UI source roots. The scanner reports raw hex values, arbitrary utility values, inline style attributes, and literal z utilities with stable structural context, current location, repair guidance, and exact multiplicity.
- Added the bootstrap ledger from immutable Git tree 767f368473f17fba43d7be4675c53ab65a87530c. Its dedicated introduction commit precedes the scanner implementation and any reductions. It records 36 occurrences across 36 finding identities.
- Added a trusted resolver for local, pull request, push, schedule, and manual-dispatch runs. It validates the canonical szTheory/scrypath origin and event objects, fetches required target refs, verifies candidate and target histories, and fails closed on shallow or missing history. The production CLI accepts no authority overrides.
- Added canonical root tests, including a disposable-repository witness where both source and candidate ledger bless a new z utility but the production command rejects it. Child runs clear inherited event-name context so local disposable history is checked in local mode while still fetching the canonical public origin.
- Added the production command to the existing required repository-contracts job. That job already checked out full history; its existing fetch-depth: 0 setting remains in place.

## Task Commits

1. Task 1 RED scanner behavior test: 548ff4ed.
2. Task 1 dedicated bootstrap ledger introduction: 4e61f1af.
3. Task 1 scanner and history policy: 006862b6.
4. Task 1 exact ledger-growth diagnostics: c64c2f28.
5. Task 1 scanner and Git authority corrections: 3b5fcaf0.
6. Task 1 focused root and real-history contract witnesses: badb9bc4.
7. Task 2 RED CI and resolved-comparison assertions: fe94ffcc.
8. Task 2 production diagnostics and required CI invocation: 619cd3ce.

The summary metadata was committed separately after this file was written.

## Files Created or Modified

- scripts/ci/ui_literal_policy.cjs — bounded scanner, trusted event resolver, and first-parent verifier.
- scripts/ci/ui_literal_policy.test.cjs — temporary-tree and real-Git history tests.
- scripts/ci/ui-literal-baseline.json — exact pinned bootstrap multiset.
- test/mix/tasks/ui_literal_contract_test.exs — canonical production-command and malicious-child witnesses.
- dev/mix/tasks/verify.phase99.ex — includes the scanner contract in the focused root lane.
- .github/workflows/ci.yml — invokes the production resolver in the existing full-history required job.

## Decisions Made

- Bootstrap identity and trust authority are code-pinned and event-derived; candidate files and CLI arguments cannot select comparison refs.
- Disposable negative tests use the production command and canonical origin. Only the inherited GitHub event name is cleared so the resolver evaluates the child repository as a local run.
- Keep CI wiring in the existing repository-contracts job and retain its full-history checkout.

## TDD Evidence

- Task 1 began with a test-only scanner behavior commit before the baseline and implementation commits.
- Task 2 began with a test-only commit. The focused Mix run failed only on the two planned missing assertions: the resolver did not yet print all comparison OIDs, and the required job did not yet invoke the production command. After implementation, the focused Mix suite passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Include raw hex colors in suffixed border declarations**

- Found during: Task 1, immutable bootstrap scan.
- Issue: The initial scanner inventory omitted the raw hex in a border-bottom declaration, producing 35 occurrences instead of the pinned source's 36.
- Fix: Broadened CSS color-property recognition and corrected the dedicated bootstrap ledger before any cleanup or reduction.
- Files modified: scripts/ci/ui_literal_policy.cjs; scripts/ci/ui-literal-baseline.json.
- Verification: The pinned-source inventory test and complete Node suite pass with 36 occurrences.
- Committed in: 4e61f1af and 3b5fcaf0.

**Total deviations:** 1 auto-fixed (Rule 1 bug).
**Impact on plan:** The correction restored exact bootstrap coverage; it did not enlarge the permitted inventory or add a generator command.

## Verification

- node --check scripts/ci/ui_literal_policy.cjs — passed.
- node --check scripts/ci/ui_literal_policy.test.cjs — passed.
- node --test --test-reporter=spec scripts/ci/ui_literal_policy.test.cjs — 10 passed, 0 failed.
- MIX_ENV=test mix test test/mix/tasks/ui_literal_contract_test.exs --warnings-as-errors — 3 passed, 0 failed.
- mix verify.repository_contracts — 131 tests passed, 0 failed. Full output: /private/tmp/phase185-02-repository-contracts.log.
- node scripts/ci/ui_literal_policy.cjs — passed on candidate 619cd3ce215f07a5477148b05429367972a5a7c1; trusted target 6b65f8a019ab467c11357ab59942ce67feb62735; bootstrap ledger introduction 4e61f1af2c8876e0a66f225ab09b865a266a3efc; finding occurrences 36.
- git diff --check — passed before commits.
- No packages were installed and no retained preview, container, or preview data was touched.

## Issues Encountered

The planned test-first run for Task 2 failed on the two new assertions before implementation, then passed after the implementation commit. No unresolved implementation or test failures remain.

## User Setup Required

None.

## Next Phase Readiness

Plan 02 is complete and committed. The parent executor owns worktree integration and phase-level gates. No hosted GitHub Actions run was performed in this worktree, so hosted workflow evidence remains unknown. No user action is needed for this plan.

## Self-Check: PASSED

All six plan-owned artifacts exist, all eight task commits are ancestors of the final task head, the plan-scoped commit resolver found the expected task commits, and the documented Node, Mix, repository-contracts, and production CLI checks passed.

