---
phase: 22
slug: operator-polish-drift-recovery-guide
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-17
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/operator/failed_work_test.exs` |
| **Full suite command** | `mix test --exclude integration` |
| **Estimated runtime** | ~30–120s full project (hardware dependent) |

---

## Sampling Rate

- **After every task commit:** Run the quick command for the files touched by that task.
- **After every plan wave:** Run `mix test --exclude integration`.
- **Before `/gsd-verify-work`:** Full suite green (or document integration skips).
- **Max feedback latency:** Target under 3 minutes on laptop-class hardware for quick path.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|---------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | OPS-05,06,07,08,10 | T-22-01-01 | No PII in default telemetry metadata | unit | `mix test test/scrypath/operator/failed_work_test.exs` | ✅ | ⬜ pending |
| 22-01-02 | 01 | 1 | OPS-10 | T-22-01-02 | Document label cardinality hazard | unit | `mix test test/scrypath/operator/failed_work_test.exs` | ✅ | ⬜ pending |
| 22-02-01 | 02 | 2 | OPS-09 | T-22-02-01 | Guide uses placeholders not real secrets | manual grep | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 22-02-02 | 02 | 2 | OPS-09 | — | N/A | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no new Wave 0 stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Readability of drift guide | OPS-09 | Prose quality | Maintainer read-through of `guides/drift-recovery.md` for six scenarios + map. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented manual step
- [ ] Sampling continuity maintained across tasks
- [ ] No watch-mode flags in verify commands
- [ ] `nyquist_compliant: true` set in frontmatter after execution evidence attached

**Approval:** pending
