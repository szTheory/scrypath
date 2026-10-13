---
phase: "174"
slug: "recovery-entry-and-diagnosis"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-10"
updated: "2026-10-13"
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

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Failure Direction | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|-------------------|--------|
| 174-01-T1 | 174-01 | 1 | OPUX-18, OPUX-19 | T-174-01, T-174-02, T-174-03 | The focused LiveView route resolves its explicit allowed schema, renders the matching failed row, invokes current host-gated retry, and shows accepted work beside its source failure. | LiveView route/render/action | cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs | Yes; extend failed_sync_live_test.exs | Fails if route selection differs from the explicit schema, row/receipt identities diverge, current eligibility or host authorization is bypassed, accepted work replaces the source failure, the exact-schema href loses query/prefix, or completion is claimed. | ✅ pass — 16 tests |
| 174-01-T2 | 174-01 | 1 | OPUX-18, OPUX-19 | T-174-01, T-174-02, T-174-03, T-174-04 | Forged/removed schema, stale context, denied host gate, hostile values, and browser presentation/history cases fail closed while preserving the selected schema. | LiveView render/action/security + mounted Playwright/browser history | make -C examples/scrypath_ecommerce verify-mounted<br>cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs | Yes; extend assertions and operator.spec.ts | Fails if unavailable rows show actions, stale/forged targets affect another schema, receipt state survives changed context, host denial inserts work, hostile output becomes markup, history changes identity, or layout/focus/theme checks regress. | ✅ pass — 16 ExUnit tests; mounted 4/4 |
| 174-02-T1 | 174-02 | 2 | OPUX-16 | T-174-05 | Control Room never presents partial/unavailable observations as healthy and setup states do not imply recovery. | LiveView render/state | cd scrypath_ops && mix test test/scrypath_ops_web/live/control_room_live_test.exs | Yes; extend assertions | Fails if there is more than one primary health route, state/scope order is wrong, a setup state offers recovery, or refresh failure erases prior evidence or reports success. | ✅ pass — 7 tests, including no-prior-complete-observation state |
| 174-02-T2 | 174-02 | 2 | OPUX-16 | T-174-05 | The mounted landing page exposes one primary route and keeps change/search intents secondary. | Mounted Playwright/navigation | make -C examples/scrypath_ecommerce verify-mounted | Yes; extend operator.spec.ts | Fails if the primary link is absent/duplicated, the scope is hidden, or secondary intents become the incident route. | ✅ pass — mounted 4/4 |
| 174-03-T1 | 174-03 | 2 | OPUX-17 | T-174-06 | Worst-first schema records preserve complete identity/time, plain groups, truthful unknowns, exact handoff, and escaped error output. | LiveView render/order/security | cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs | Yes; extend assertions | Fails if ordering/groups/record semantics drift, unknown becomes zero, retained evidence changes snapshot, a link loses schema identity, or a hostile reason creates markup. | ✅ pass — 19 tests, including empty-allowlist and missing-backend refresh outcomes |
| 174-03-T2 | 174-03 | 2 | OPUX-17 | T-174-06 | Both entrypoints keep long schema/index values readable with no overflow and preserve focus/theme behavior. | Mounted and standalone Playwright + contrast | bash examples/scrypath_ecommerce/scripts/verify-phase173.sh status && make -C examples/scrypath_ecommerce contrast | Yes; extend existing lane | Fails if status cases collapse, required content clips, contextual links disappear, width overflows at 320px/390px or rail boundaries, keyboard focus is missing, or any AA pair fails. | ✅ pass — browser 6/6; 0 AA failures |

## Wave 0 Requirements

- [x] 174-01-T2 extends the current mounted browser lane with a real rendered non-first-schema selection, same-schema handoff, refresh, reload, and Back/Forward restoration assertion.
- [x] 174-01-T2 proves forged/unknown and allowlist-removed schema targets fail closed with cleared actions and no operation on another schema.
- [x] 174-01-T2 and 174-03-T2 cover narrow viewports with long schema/index/work values and failure reasons, full readable content, and no page-level horizontal overflow.
- [x] Reuse existing Playwright, LiveView, and accessibility infrastructure; no dependency, framework, or CI service installation.

## Manual-Only Verifications

All acceptance behavior has automated verification. Compare representative light/dark and 320/390px before/after renders as supporting evidence; screenshots or human visual inspection do not replace assertions or become a human-only completion gate.

## Validation Sign-Off

- [x] Every planned task has an executable `<automated>` verification or an earlier Wave 0 task creates it.
- [x] No three consecutive tasks lack automated feedback.
- [x] Wave 0 covers missing rendered handoff, invalid-target, and long-content browser cases.
- [x] No watch-mode command is used.
- [x] Feedback latency remains bounded for the quick lane; mounted proof stays at wave-level.
- [x] The plan checker and completed execution confirm every task is mapped and passing.

**Approval:** validation contract complete; phase-goal verifier pending.

## Validation Audit 2026-10-11

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Final Exact-Revision Evidence

Source revision: `2375f6b71f57037e9e636ae060828e26f59a82c6`.

- `cd scrypath_ops && mix verify.ops_ui` — 252 tests + 2 doctests, 0 failures.
- `make -C examples/scrypath_ecommerce verify-mounted` — 4/4 mounted operator journeys passed.
- `make -C examples/scrypath_ecommerce contrast` — 0 AA failures (43 AAA advisories).
- Phase 173 regression lanes, all mounted and standalone at this exact source revision: shell 14/14, status 6/6, time 8/8, and copy 10/10.
- `cd scrypath_ops && mix test test/scrypath_ops_web/live/control_room_live_test.exs` — 6 tests, 0 failures after the final reading-order correction.

**Approval:** automated phase validation and phase-goal verification passed (19/19 must-haves; see `174-VERIFICATION.md`).
