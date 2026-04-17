---
phase: 24
slug: public-hex-release-parity-gates
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-17
---

# Phase 24 — Validation Strategy

> Release automation and docs — feedback via Mix tests and static workflow checks.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/mix/tasks/workflow_wiring_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~1–3 minutes (host), longer in CI |

---

## Sampling Rate

- **After every task commit:** `mix test test/mix/tasks/workflow_wiring_test.exs`
- **After every plan wave:** `mix test test/mix/tasks/workflow_wiring_test.exs` + `mix format --check-formatted`
- **Before `/gsd-verify-work`:** `mix test` green
- **Max feedback latency:** CI-quality job budget

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|
| 24-01-01 | 01 | 1 | SHIP-01 | T-24-01 | JSON valid; no secret keys in repo | unit | `mix test test/mix/tasks/workflow_wiring_test.exs` | ⬜ |
| 24-02-01 | 02 | 2 | SHIP-03 | T-24-02 | Workflow only reads `GITHUB_TOKEN` / existing secrets | unit | `mix test test/mix/tasks/workflow_wiring_test.exs` | ⬜ |
| 24-03-01 | 03 | 2 | SHIP-02, SHIP-03 | T-24-03 | Docs only; no new credentials | unit | `mix test ...` + grep docs | ⬜ |

---

## Wave 0 Requirements

Existing infrastructure covers this phase — no new test framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First real Hex publish after merge | SHIP-01 | Needs `HEX_API_KEY` | Follow `docs/releasing.md` on a fork or production with maintainer key |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or documented manual row
- [x] Sampling continuity maintained via `workflow_wiring_test.exs`
- [x] No watch-mode flags
- [ ] `nyquist_compliant: true` after execution green

**Approval:** pending execution
