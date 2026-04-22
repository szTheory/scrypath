---
phase: 59
slug: playbook-schema-and-persistence-mvp
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 59 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `scrypath_ops/config/config.exs` (test env) |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops/playbook/` |
| **Full suite command** | `cd scrypath_ops && mix test` |
| **Estimated runtime** | ~30–90 seconds (project-dependent) |

---

## Sampling Rate

- **After every task commit:** Run `cd scrypath_ops && mix test test/scrypath_ops/playbook/`
- **After every plan wave:** Run `cd scrypath_ops && mix test`
- **Before `/gsd-verify-work`:** Full `scrypath_ops` suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-01-01 | 01 | 1 | OPS-PB-01 | TM-59-01 | No `keys: :atoms!` on untrusted JSON | unit | `cd scrypath_ops && mix test test/scrypath_ops/playbook/v1_test.exs` | ⬜ W0 | ⬜ pending |
| 59-01-02 | 01 | 1 | OPS-PB-01 | TM-59-02 | Secret-ish keys rejected on decode/validate | unit | `cd scrypath_ops && mix test test/scrypath_ops/playbook/v1_test.exs` | ⬜ W0 | ⬜ pending |
| 59-02-01 | 02 | 1 | OPS-PB-01 / OPS-PB-03 | TM-59-03 | Docs state no secrets in exports | doc grep | `rg -n 'playbook-schema-v1' scrypath_ops/docs/operator-ia.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scrypath_ops/test/scrypath_ops/playbook/v1_test.exs` — ExUnit covering decode/validate/encode and negative fixtures
- [ ] `scrypath_ops/test/support/fixtures/playbooks/*.json` — optional golden files for OPS-PB-01

*Wave 0 is satisfied once Plan 01 lands the first test file.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human spec readability | OPS-PB-01 | Prose quality | Read `scrypath_ops/docs/playbook-schema-v1.md` end-to-end |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
