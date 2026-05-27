---
phase: 98
slug: surface-reconciliation-and-adopter-flow-clarity
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 98 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scrypath/readiness_contract_test.exs` |
| **Full suite command** | `mix verify.phase98` |
| **Estimated runtime** | ~45-90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/readiness_contract_test.exs`
- **After every plan wave:** Run `mix verify.phase98`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 98-01-01 | 01 | 1 | PROOF-01 | T-98-01 | Canonical adopter proof command remains one-hop discoverable | unit | `mix test test/scrypath/readiness_contract_test.exs` | ✅ | ⬜ pending |
| 98-01-02 | 01 | 1 | PROOF-02 | T-98-02 | Fast/live proof boundary and prerequisites remain explicit and truthful | unit | `mix test test/scrypath/readiness_contract_test.exs` | ✅ | ⬜ pending |
| 98-02-01 | 02 | 1 | PROOF-03 | T-98-03 | Example runbook stays aligned with canonical proof boundary | integration | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 98-03-01 | 03 | 2 | SUP-01 | T-98-04 | Intake evidence contract is deterministic and complete | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 98-03-02 | 03 | 2 | SUP-02 | T-98-05 | Escalation routing prevents ambiguous triage outcomes | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 98-04-01 | 04 | 2 | PROOF-01,PROOF-02,PROOF-03,SUP-01,SUP-02 | T-98-06 | Phase gate enforces bounded surface contract without runtime expansion | gate | `mix verify.phase98` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `lib/mix/tasks/verify.phase98.ex` - phase gate task scaffold
- [ ] `test/mix/tasks/verify.phase98_test.exs` - gate wiring/contract tests
- [ ] `test/scrypath/phase98_contract_test.exs` - focused phase assertions

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Adopter-facing wording is concise and non-duplicative while preserving canonical authority | PROOF-01, SUP-02 | Editorial quality and routing clarity cannot be fully encoded in token checks | Review `README.md`, `CONTRIBUTING.md`, and support/intake guides for one-hop routing and no policy-owner drift |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
