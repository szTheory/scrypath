---
phase: "174"
slug: recovery-entry-and-diagnosis
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-06"
---

# Phase 174 — Validation Strategy

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit, Phoenix.LiveViewTest, existing Playwright Docker lane |
| Config | scrypath_ops/test/test_helper.exs; examples/scrypath_ecommerce/package.json |
| Quick run | `cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs test/scrypath_ops_web/live/posture_live_test.exs` |
| Full Ops suite | `cd scrypath_ops && mix precommit` |
| Phase gate | Focused Ops suites, `mix verify.ops_ui`, token contrast and scoped Phase174 browser proof in standalone and mounted entrypoints |
| Runtime | Record observed durations during execution; research does not supply measured latency |

## Sampling Rate

After each task, run the smallest affected ExUnit suite; after each plan wave, run Ops precommit. Verify the first real selected-schema journey before expanding it. Browser-only behavior uses the scoped disposable runner after its Wave0 creation. No watch mode. Tests must report executed cases and zero failures; a nonzero exit, missing cases or missing native result is not a pass. Run browser proof and contrast against the final changed source before phase verification.

## Per-Task Verification Map

The planner replaces these requirement-level seeds with exact task IDs, threat references and commands as plans are created.

| Task seed | Requirement | Secure behavior | Test type | Automated command | Exists | Status |
|---|---|---|---|---|---|---|
| 174-selected-journey | OPUX-19 | Current allowlist context survives navigation; explicit invalid target never defaults | unit/LiveView/browser | `cd scrypath_ops && mix test test/scrypath_ops/operator_selection_test.exs test/scrypath_ops/integrations/sigra/gating_test.exs` plus scoped browser runner | Unit files yes; scoped runner W0 | pending |
| 174-entry | OPUX-16 | Fleet ranking cannot silently change recovery target | LiveView/browser | `cd scrypath_ops && mix test test/scrypath_ops_web/live/control_room_live_test.exs test/scrypath_ops_web/live/posture_live_test.exs` | yes; add behavior cases | pending |
| 174-health | OPUX-17 | Unknown observation remains unknown; full source evidence survives refresh/reorder | LiveView/browser | `cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs` plus scoped browser runner | yes; extend | pending |
| 174-failed-work | OPUX-18 | Source-qualified lookup, current authorization/revalidation, receipt accepted≠complete | unit/LiveView/browser | `mix test test/scrypath/operator/failed_work_test.exs` and `cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs` | yes; extend collision/stale cases | pending |

## Wave 0 Requirements

- [ ] Add Phase174-scoped disposable browser runner and actual tests, following the existing tracked Phase173 runner and mounted selection journey. Unique Compose names/ports; preserve retained preview :4012 and frozen173 source.
- [ ] Add assertions for source ID collision, fleet target independence, actual palette DOM links after patches, safe auth returns, invalid/removed schemas, stale generations and focus after reordering.
- Existing ExUnit, Playwright and Docker infrastructure covers framework setup. No dependency install or new mandatory CI lane is proposed.

## Manual-Only Verifications

All required phase behaviors have automated verification. Before/after images and agent inspection supplement runnable assertions. Maintainer review of the working UI is feedback, not a pending completion gate or simulated approval.

## Validation Sign-Off

- [ ] Each plan task has automated verification or explicit Wave0 dependencies.
- [ ] No three consecutive tasks without verification.
- [ ] Missing runner/test references are created before use.
- [ ] Final production browser proof covers both entrypoints, themes, responsive states and selected-schema seams.
- [ ] All 30 explicit UI criteria are mapped to executable evidence.
- [ ] Record measured latency and results; set compliance only after evidence exists.

Approval: pending execution evidence.
