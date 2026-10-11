---
phase: "174"
slug: "recovery-entry-and-diagnosis"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-10"
---

# Phase 174 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest; existing mounted browser lane uses Playwright. |
| **Config file** | Existing `scrypath_ops/mix.exs` aliases and `examples/scrypath_ecommerce/Makefile`; no new test setup. |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops_web/live/control_room_live_test.exs test/scrypath_ops_web/live/posture_live_test.exs test/scrypath_ops_web/live/failed_sync_live_test.exs` |
| **Full suite command** | `mix verify.ops_ui`; cross-route rendered proof: `make -C examples/scrypath_ecommerce verify-mounted`. |
| **Estimated runtime** | Budget up to 60 seconds for the focused ExUnit feedback loop; the mounted lane is container-backed and may take several minutes. |

## Sampling Rate

- **After every task commit:** run the focused LiveView test(s) for changed surfaces and any focused accessibility contract affected by markup/focus changes.
- **After every plan wave:** run `mix verify.ops_ui`; run `make -C examples/scrypath_ecommerce verify-mounted` for any wave that changes rendered routing, URL continuity, browser history, focus, or narrow layout.
- **Before `$gsd-verify-work`:** focused tests, full Ops UI suite, and exact-source mounted handoff proof must pass.
- **Max feedback latency:** 60 seconds for the quick ExUnit lane; the existing mounted lane is a wave-level acceptance check.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 174-?? | TBD | TBD | OPUX-16 | — | Setup states never expose recovery actions; unavailable is not zero/healthy. | LiveView render | `cd scrypath_ops && mix test test/scrypath_ops_web/live/control_room_live_test.exs` | Yes; extend assertions | ⬜ pending |
| 174-?? | TBD | TBD | OPUX-17 | — | Exact schema identity and observation remain adjacent; unknown queue data is not zero. | LiveView render + responsive browser | `cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs` | Yes; extend assertions | ⬜ pending |
| 174-?? | TBD | TBD | OPUX-18 | T-174-01 | Retry is reauthorized/revalidated server-side; acceptance never replaces retained failure evidence. | LiveView action/state | `cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs` | Yes; extend assertions | ⬜ pending |
| 174-?? | TBD | TBD | OPUX-19 | T-174-01 | Explicit invalid/removed schema fails closed and cannot operate on another schema. | Rendered selection + mounted browser history | `make -C examples/scrypath_ecommerce verify-mounted` | Partial; add rendered handoff/history and stale-target cases | ⬜ pending |

## Wave 0 Requirements

- [ ] Extend the current mounted browser lane with a real rendered non-first-schema selection, schema-specific handoff, refresh, and Back/Forward restoration assertion.
- [ ] Add rendered proof for forged/unknown and allowlist-removed schema targets; assert unavailable state, cleared actions, and no operation on a different schema.
- [ ] Add a narrow viewport case with a long schema/index/work identifier and failure reason; assert full content remains readable without page-level horizontal overflow.
- [ ] Reuse existing Playwright, LiveView, and accessibility infrastructure; no dependency, framework, or CI service installation.

## Manual-Only Verifications

All acceptance behavior has automated verification. Compare representative light/dark and 320/390px before/after renders as supporting evidence; screenshots or human visual inspection do not replace assertions or become a human-only completion gate.

## Validation Sign-Off

- [ ] Every planned task has an executable `<automated>` verification or an earlier Wave 0 task creates it.
- [ ] No three consecutive tasks lack automated feedback.
- [ ] Wave 0 covers missing rendered handoff, invalid-target, and long-content browser cases.
- [ ] No watch-mode command is used.
- [ ] Feedback latency remains bounded for the quick lane; mounted proof stays at wave-level.
- [ ] Set `nyquist_compliant: true` only after the final plan/checker confirms every task is mapped and execution has passing evidence.

**Approval:** pending plan review and phase verification.
