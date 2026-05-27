---
phase: 99
slug: drift-gates-and-ci-enforcement
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
updated: 2026-05-27
---

# Phase 99 — Validation Strategy

> Per-phase Nyquist validation contract and audit evidence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir test) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scrypath/phase99_contract_test.exs test/mix/tasks/verify.phase99_test.exs test/mix/tasks/workflow_wiring_test.exs` |
| **Full suite command** | `mix verify.phase99` |
| **Estimated runtime** | ~2 seconds local |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/phase99_contract_test.exs test/mix/tasks/verify.phase99_test.exs test/mix/tasks/workflow_wiring_test.exs`
- **After every plan wave:** Run `mix verify.phase99`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement IDs | Test Files | Automated Command | Status |
|---------|------|------|-----------------|------------|-------------------|--------|
| 99-01-01 | 01 | 1 | TEST-01 | `test/scrypath/phase99_contract_test.exs` | `mix test test/scrypath/phase99_contract_test.exs` | ✅ COVERED |
| 99-01-02 | 01 | 1 | TEST-02 | `test/scrypath/phase99_contract_test.exs` | `mix test test/scrypath/phase99_contract_test.exs` | ✅ COVERED |
| 99-01-03 | 01 | 1 | TEST-01, TEST-02 | `test/scrypath/phase99_contract_test.exs` | `mix test test/scrypath/phase99_contract_test.exs` | ✅ COVERED |
| 99-02-01 | 02 | 2 | GATE-01 | `lib/mix/tasks/verify.phase99.ex`, `test/mix/tasks/verify.phase99_test.exs` | `mix test test/mix/tasks/verify.phase99_test.exs` | ✅ COVERED |
| 99-02-02 | 02 | 2 | GATE-01 | `test/mix/tasks/verify.phase99_test.exs` | `mix test test/mix/tasks/verify.phase99_test.exs` | ✅ COVERED |
| 99-02-03 | 02 | 2 | TEST-03, GATE-01 | `mix.exs`, `test/mix/tasks/workflow_wiring_test.exs`, `test/scrypath/phase99_contract_test.exs` | `mix test test/mix/tasks/workflow_wiring_test.exs test/scrypath/phase99_contract_test.exs` | ✅ COVERED |
| 99-03-01 | 03 | 3 | GATE-02 | `.github/workflows/ci.yml`, `test/mix/tasks/workflow_wiring_test.exs` | `mix test test/mix/tasks/workflow_wiring_test.exs` | ✅ COVERED |
| 99-03-02 | 03 | 3 | GATE-02 | `CONTRIBUTING.md`, `test/scrypath/phase99_contract_test.exs` | `mix test test/scrypath/phase99_contract_test.exs` | ✅ COVERED |
| 99-03-03 | 03 | 3 | TEST-03, GATE-02 | `test/mix/tasks/workflow_wiring_test.exs`, `test/scrypath/phase99_contract_test.exs` | `mix test test/mix/tasks/workflow_wiring_test.exs test/scrypath/phase99_contract_test.exs` | ✅ COVERED |

## Requirement Coverage Map

| Requirement | Coverage Evidence | Status |
|-------------|-------------------|--------|
| TEST-01 | `phase99_contract_test.exs` TEST-01 describe block; high-risk docs token assertions | ✅ COVERED |
| TEST-02 | `phase99_contract_test.exs` TEST-02 describe block; env token and command-order checks | ✅ COVERED |
| TEST-03 | `phase99_contract_test.exs` TEST-03 parity checks + `workflow_wiring_test.exs` phase99 required-check wiring tests | ✅ COVERED |
| GATE-01 | `verify.phase99` task implementation + `verify.phase99_test.exs` contract tests + `mix.exs` preferred env wiring assertions | ✅ COVERED |
| GATE-02 | CI `phase99-trust` job + contributor required-check contract tokens + workflow/parity tests | ✅ COVERED |

---

## Wave 0 Requirements

- [x] `test/scrypath/phase99_contract_test.exs` — focused trust assertions for TEST-01/02/03
- [x] `test/mix/tasks/verify.phase99_test.exs` — verify task contract and focused test markers
- [x] `lib/mix/tasks/verify.phase99.ex` — dedicated deterministic phase gate

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Branch-protection required-check mapping remains enforced in repo settings | GATE-02 | GitHub branch protection is external to repo tests | Confirm required checks include `main-ci`, `repo-hygiene`, `release-truth`, and the phase-99 trust check in repository settings |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Nyquist audit complete

## Validation Audit 2026-05-27

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Automated evidence:
- `mix test test/scrypath/phase99_contract_test.exs test/mix/tasks/verify.phase99_test.exs test/mix/tasks/workflow_wiring_test.exs` → 36 tests, 0 failures
- `mix verify.phase99` → pass, docs build succeeds with warnings as errors
