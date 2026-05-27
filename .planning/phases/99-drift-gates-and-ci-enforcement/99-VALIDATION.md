---
phase: 99
slug: drift-gates-and-ci-enforcement
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 99 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir test) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scrypath/phase99_contract_test.exs test/mix/tasks/verify.phase99_test.exs` |
| **Full suite command** | `mix verify.phase99` |
| **Estimated runtime** | ~40 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/phase99_contract_test.exs test/mix/tasks/verify.phase99_test.exs`
- **After every plan wave:** Run `mix verify.phase99`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 99-01-01 | 01 | 1 | TEST-01 | T-99-01 | Canonical docs anchors remain present on high-risk surfaces | unit | `mix test test/scrypath/phase99_contract_test.exs` | ❌ W0 | ⬜ pending |
| 99-01-02 | 01 | 1 | TEST-02 | T-99-02 | Fast/live proof boundary tokens stay aligned across root and example docs | unit | `mix test test/scrypath/phase99_contract_test.exs` | ❌ W0 | ⬜ pending |
| 99-01-03 | 01 | 1 | TEST-03 | T-99-03 | Required-check and verify alias references stay in sync across docs/workflow | integration | `mix test test/scrypath/phase99_contract_test.exs test/mix/tasks/workflow_wiring_test.exs` | ❌ W0 | ⬜ pending |
| 99-02-01 | 02 | 2 | GATE-01 | T-99-04 | `mix verify.phase99` exists and alias wiring for phase 97-99 is explicit | integration | `mix test test/mix/tasks/verify.phase99_test.exs test/mix/tasks/workflow_wiring_test.exs` | ❌ W0 | ⬜ pending |
| 99-02-02 | 02 | 2 | GATE-02 | T-99-05 | Required PR checks are explicitly documented and map to workflow job tokens | integration | `mix test test/mix/tasks/workflow_wiring_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scrypath/phase99_contract_test.exs` — focused trust assertions for TEST-01/02/03
- [ ] `test/mix/tasks/verify.phase99_test.exs` — verify task contract and focused test markers
- [ ] `lib/mix/tasks/verify.phase99.ex` — dedicated deterministic phase gate

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Branch-protection required-check mapping remains enforced in repo settings | GATE-02 | GitHub branch protection is external to repo tests | Confirm required checks include `main-ci`, `repo-hygiene`, `release-truth`, and the phase-99 trust check in repository settings |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
