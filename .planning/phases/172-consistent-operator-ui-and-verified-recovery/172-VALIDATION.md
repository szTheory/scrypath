---
phase: "172"
slug: consistent-operator-ui-and-verified-recovery
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-03"
---

# Phase 172 — Validation Strategy

## Test Infrastructure

Existing ExUnit/Phoenix LiveView tests, static token and contrast contracts, Playwright mounted/full suites, and Docker Compose verifiers. Read CONTRIBUTING.md and `.planning/research/v1.42/UI-AUTOMATION.md` for canonical commands and actual proof boundaries. No framework installation or new required CI job.

## Sampling Rate

- After each behavior task, run focused existing/new ExUnit or browser assertions for that behavior.
- After each coherent wave, run `mix verify.ops_ui` (or its documented container equivalent); shared CSS also runs fast contrast/token checks.
- Final: existing required checks and `make verify-mounted` from `examples/scrypath_ecommerce`, plus one appropriate advisory visual run. No full matrix after every commit.
- Tests must fail on nonzero exit or no selected tests; arbitrary sleeps, optional Retry branches, prior successful tasks and generic existing documents do not prove recovery.

## Per-Task Verification Map

Planner must fill task IDs, commands, file existence and threat references after the plan set is authored; keep runtime status pending until executed.

| Coverage | Requirements | Test type | Status |
| --- | --- | --- | --- |
| Tokens, readable controls, compact counts, single shortcut hint, responsive long content | OPUX-01/03 | Component + browser geometry + direct image inspection | pending |
| Labels/help, mode/disabled semantics, complete dialog focus lifecycle | OPUX-02 | Component/LiveView + browser keyboard | pending |
| Allowed non-first schema, invalid/removed query, back/refresh and late result isolation | OPUX-04 | LiveView + rendered browser journey | pending |
| Retry/task acceptance vs terminal/unknown/stale/failure/timeout; current promotion predicate | OPUX-05 | Focused service boundary/LiveView | pending |
| Newly correlated job/task and unique active-index content from replayable failure | OPUX-06 | Required mounted browser lane | pending |
| Both-theme contrast, representative widths/states, automated evidence and clean delivery | OPUX-07/08 | Existing checks/hosted receipts | pending |

## Wave 0 Requirements

Existing infrastructure is available. New tests/fixtures must be introduced with their owning behavior, listed explicitly by the planner; no empty stubs treated as coverage.

## Manual-Only Verifications

None. Direct agent screenshot inspection is part of the implementation review. Maintainer feedback is optional design direction, not pending acceptance.

## Validation Sign-Off

- [ ] Every planned task has an executable check and observable failure direction.
- [ ] Missing test/fixture paths are created by an explicit dependency.
- [ ] Sampling has no three consecutive tasks without automated verification.
- [ ] Runtime evidence covers each listed behavior at the changed source.
- [ ] Nyquist compliance audited after implementation; no planning-time pass claim.
