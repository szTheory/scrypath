---
phase: 66
slug: runner-library-contract
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 66 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveViewTest |
| **Config file** | `test/test_helper.exs`, `scrypath_ops/test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/search_test.exs test/scrypath/search_many_test.exs test/scrypath/mix_tasks/operator_tasks_test.exs scrypath_ops/test/scrypath_ops/playbook/runner_test.exs scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` |
| **Full suite command** | `mix test && mix verify.opsui` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/search_test.exs test/scrypath/search_many_test.exs test/scrypath/mix_tasks/operator_tasks_test.exs scrypath_ops/test/scrypath_ops/playbook/runner_test.exs scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`
- **After every plan wave:** Run `mix test && mix verify.opsui`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 66-01-01 | 01 | 1 | OPS3-03 | T-66-01 | Runner contract stays raw `{:ok, result}` / `{:error, reason}` with canonical docs in `Runner` | unit | `mix test scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` | ✅ | ⬜ pending |
| 66-01-02 | 01 | 1 | OPS3-03 | T-66-01 | Wire-format docs link to the canonical runner contract instead of redefining it | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 66-02-01 | 02 | 2 | OPS3-03 | T-66-02 | Representative parity cases keep raw reason identities aligned with core search/search_many paths | unit | `mix test test/scrypath/search_test.exs test/scrypath/search_many_test.exs scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` | ✅ | ⬜ pending |
| 66-02-02 | 02 | 2 | OPS3-03 | T-66-03 | UI/operator layers consume raw reasons without redefining the contract or swallowing divergence | integration | `mix test scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs test/scrypath/mix_tasks/operator_tasks_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-22
