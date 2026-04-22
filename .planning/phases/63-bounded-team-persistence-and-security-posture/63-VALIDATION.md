---
phase: 63
slug: bounded-team-persistence-and-security-posture
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 63 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir **1.17+**) |
| **Config file** | `scrypath_ops/mix.exs` test alias; root `mix.exs` for `verify.opsui` |
| **Quick run command** | `mix test scrypath_ops/test/scrypath_ops/playbook/v1_test.exs` (adjust paths per task) |
| **Full suite command** | `mix verify.opsui` (from repository root) |
| **Estimated runtime** | ~60–180 seconds (ops app + Postgres per existing `verify.opsui` contract) |

---

## Sampling Rate

- **After every task commit:** Run the plan’s scoped `mix test …` command(s).
- **After every plan wave:** Run `mix verify.opsui` from repo root before merging phase work.
- **Before `/gsd-verify-work`:** Full `mix verify.opsui` must exit **0**.
- **Max feedback latency:** ~180s on cold DB (existing ops test baseline).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 63-01-01 | 01 | 2 | OPS2-04 | T-63-01 | Docs describe single workspace authority | doc grep | `grep -q 'SCRYPATH_OPS_PLAYBOOK_DIR' scrypath_ops/docs/*.md` | ✅ | ⬜ pending |
| 63-02-01 | 02 | 1 | OPS2-04 | T-63-02 | Fixture JSON passes `V1.validate` | unit + mix | `mix test scrypath_ops/test/...` + `mix scrypath_ops.playbooks.validate` (path TBD in plan) | ✅ W0 | ⬜ pending |
| 63-03-01 | 03 | 3 | OPS2-07 | T-63-03 | Banned keys rejected; delete confirm strict | unit + LV | `mix test scrypath_ops/test/scrypath_ops/playbook/v1_test.exs` + `playbook_live_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] **Existing infrastructure covers all phase requirements** — no new framework install; reuse `scrypath_ops` ExUnit + Postgres test alias.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Mounted volume + release env in real k8s/VM | OPS2-04 | Infra-specific | Follow shipped operator doc with a throwaway deploy; confirm `SCRYPATH_OPS_PLAYBOOK_DIR` absolute path and catalog read/write. |

---

## Validation Sign-Off

- [ ] All tasks have `<acceptance_criteria>` with grep- or test-verifiable conditions
- [ ] Sampling continuity: no three consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags in verify commands
- [ ] Feedback latency within budget above
- [ ] `nyquist_compliant: true` set in frontmatter when execution completes

**Approval:** pending
