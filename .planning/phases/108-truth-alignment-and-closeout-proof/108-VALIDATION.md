---
phase: 108
slug: truth-alignment-and-closeout-proof
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
updated: 2026-05-31
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
| 108-01-01 | 01 | 0 | TRUTH-01 | T-108-01 / T-108-02 / T-108-03 | Related-data guide presents ordinary generated fan-out reflection while preserving owner-only hand-written reflection as an escape hatch | contract | `mix verify.phase108` | yes | green |
| 108-01-02 | 01 | 0 | TRUTH-01 | T-108-01 / T-108-02 / T-108-03 | Focused, no-arg, service-free verification task prevents hidden runtime or CI posture drift | contract/unit | `mix verify.phase108` | yes | green |
| 108-01-03 | 01 | 0 | TRUTH-01 | T-108-01 / T-108-02 / T-108-03 | Planning and JTBD authorities close v1.29 without reopening deferred breadth or promoting advisory proof lanes | contract | `mix verify.phase108` | yes | green |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [x] `test/scrypath/phase108_contract_test.exs` - TRUTH-01 token assertions for related-data docs, planning/JTBD truth, and verification posture.
- [x] `lib/mix/tasks/verify.phase108.ex` - focused phase gate task.
- [x] `test/mix/tasks/verify.phase108_test.exs` - task contract checks for no-args behavior and covered test files.
- [x] `mix.exs` - `cli.preferred_envs` maps `"verify.phase108": :test`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | TRUTH-01 | All phase behaviors have automated verification | Run `mix verify.phase108` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved

## Validation Audit 2026-05-31

| Metric | Count |
|--------|-------|
| Requirements audited | 1 |
| Task rows audited | 3 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Manual-only | 0 |

**Automated proof:** `mix verify.phase108` passed with 6 tests, 0 failures.

**Coverage finding:** `TRUTH-01` is covered by `test/scrypath/phase108_contract_test.exs`,
`test/mix/tasks/verify.phase108_test.exs`, `lib/mix/tasks/verify.phase108.ex`, and the
`"verify.phase108": :test` Mix preferred-env registration.
