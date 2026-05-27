---
phase: 101
slug: ci-compatibility-truth-and-drift-guard-completion
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 101 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scrypath/phase99_contract_test.exs` |
| **Full suite command** | `mix verify.phase99` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/phase99_contract_test.exs`
- **After every plan wave:** Run `mix verify.phase99`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 101-01-01 | 01 | 1 | TRUTH-03 | T101-P1-001 | Canonical compatibility claims and CI evidence tuples stay aligned | unit | `mix test test/scrypath/phase99_contract_test.exs` | ✅ | ⬜ pending |
| 101-02-01 | 02 | 2 | TEST-01 | T101-P2-001 | Contract tests enforce tuple parity and route-only ownership | unit | `mix test test/scrypath/phase99_contract_test.exs` | ✅ | ⬜ pending |
| 101-03-01 | 03 | 3 | TEST-01 | T101-P3-001 | Trust lane wiring remains stable and required checks unchanged | unit | `mix test test/mix/tasks/workflow_wiring_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CI required-check policy remains accepted by repository settings | TRUTH-03 | Branch protection configuration is external to repo tests | Confirm required checks in GitHub branch protection still match documented set after CI updates |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
