---
phase: 26
slug: operator-failure-rollups
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-17
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (operator rollups / OPS14-01).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) |
| **Config file** | `mix.exs` (test env) |
| **Quick run command** | `mix test test/scrypath/operator/failed_work_test.exs test/scrypath/operator/reconcile_test.exs test/scrypath/mix_tasks/operator_tasks_test.exs test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30–120 seconds (project-dependent) |

---

## Sampling Rate

- **After every task commit:** Run the **quick run command** above (or the plan’s narrower file scope if listed).
- **After every plan wave:** Run **full suite** `mix test`.
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** Target under 3 minutes on CI-class hardware.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-01-01 | 01 | 1 | OPS14-01 | T-26-API | No new secrets in telemetry/CLI | unit | `mix test test/scrypath/operator/failed_work_test.exs` | ✅ | ⬜ pending |
| 26-01-02 | 01 | 1 | OPS14-01 | T-26-API | Default return path unchanged | unit | `mix test test/scrypath/operator/failed_work_test.exs` | ✅ | ⬜ pending |
| 26-02-01 | 02 | 1 | OPS14-01 | — | N/A | unit | `mix test test/scrypath/operator/reconcile_test.exs` | ✅ | ⬜ pending |
| 26-02-02 | 02 | 1 | OPS14-01 | T-26-CLI | JSON path no stray stdout | unit | `mix test test/scrypath/mix_tasks/operator_tasks_test.exs` | ✅ | ⬜ pending |
| 26-02-03 | 02 | 1 | OPS14-01 | — | N/A | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no new Wave 0 stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| None | — | — | All behaviors targeted by automated tests per 26-RESEARCH.md |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable on CI
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
