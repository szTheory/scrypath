---
phase: 45
slug: posture-failure-triage
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-21
---

# Phase 45 — Validation Strategy

> Per-phase validation contract for OPSUI read-only LiveViews (`scrypath_ops`).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Phoenix **`ConnCase`** + **`Phoenix.LiveViewTest`**) |
| **Config file** | `scrypath_ops/test/test_helper.exs`, `scrypath_ops/test/support/conn_case.ex` |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops_web/live/` |
| **Full suite command** | `cd scrypath_ops && mix test` |
| **Estimated runtime** | ~30–90 seconds (depends on host) |

---

## Sampling Rate

- **After every task commit:** `cd scrypath_ops && mix test test/scrypath_ops_web/live/` (or the file touched by that task)
- **After every plan wave:** `cd scrypath_ops && mix test`
- **Before `/gsd-verify-work`:** Full ops test suite green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 45-01-01 | 01 | 1 | OPSUI-01 | T-45-01 | Allowlist only; no broad module scan | unit | `cd scrypath_ops && mix test test/scrypath_ops/` | ✅ | ⬜ pending |
| 45-02-01 | 02 | 2 | OPSUI-01 | T-45-02 | No secrets in assigns; low-card telemetry | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs` | ❌ W0 | ⬜ pending |
| 45-03-01 | 03 | 2 | OPSUI-02 | T-45-03 | Rollups from inspection struct only | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/failed_sync_live_test.exs` | ❌ W0 | ⬜ pending |
| 45-04-01 | 04 | 3 | OPSUI-03 | T-45-04 | Read-only; no recovery MFAs exposed | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs` — created in plan 02 if missing
- [ ] `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs` — created in plan 03
- [ ] `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` — created in plan 04

*Wave 0 = first test files for new LiveView behaviors.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Meilisearch posture row | OPSUI-01 | Needs running cluster + example app schema | In dev, set allowlist to example schema, start deps, open `/ops/posture`, click refresh, confirm non-stub row |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
