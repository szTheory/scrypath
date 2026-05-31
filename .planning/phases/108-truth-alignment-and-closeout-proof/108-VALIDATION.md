---
phase: 108
slug: truth-alignment-and-closeout-proof
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-31
---

# Phase 108 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix verify.phase108` |
| **Full suite command** | `mix test --exclude integration --exclude docs_contract` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.phase108`
- **After every plan wave:** Run `mix test --exclude integration --exclude docs_contract`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds for the phase gate

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 108-01-01 | 01 | 0 | TRUTH-01 | T-108-01 / T-108-02 / T-108-03 | Focused, no-arg, service-free verification task prevents hidden runtime or CI posture drift | contract/unit | `mix verify.phase108` | no W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `test/scrypath/phase108_contract_test.exs` - TRUTH-01 token assertions for related-data docs, planning/JTBD truth, and verification posture.
- [ ] `lib/mix/tasks/verify.phase108.ex` - focused phase gate task.
- [ ] `test/mix/tasks/verify.phase108_test.exs` - task contract checks for no-args behavior and covered test files.
- [ ] `mix.exs` - `cli.preferred_envs` maps `"verify.phase108": :test`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | TRUTH-01 | All phase behaviors have automated verification | Run `mix verify.phase108` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
