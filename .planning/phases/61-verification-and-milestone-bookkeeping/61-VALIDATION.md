---
phase: 61
slug: verification-and-milestone-bookkeeping
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 61 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) — root `scrypath` + app `scrypath_ops` |
| **Config file** | `mix.exs` (aliases), `scrypath_ops/config/test.exs` |
| **Quick run command** | Narrow file: `mix test test/scrypath/docs_contract_test.exs` (root) or `cd scrypath_ops && mix test test/scrypath_ops_web/live/playbook_live_test.exs` |
| **Full suite command** | Root: `mix test --exclude integration` then `mix verify.opsui` |
| **Estimated runtime** | ~2–8 minutes depending on machine (ops app + deps.get) |

---

## Sampling Rate

- **After every task commit:** Run the narrowest test file touched (see quick command).
- **After every plan wave:** `mix test --exclude integration` from repo root + `mix verify.opsui` when `scrypath_ops/` changed.
- **Before `/gsd-verify-work`:** Full suite green per **61-RESEARCH.md** § Validation Architecture.
- **Max feedback latency:** Prefer under 10 minutes for full root + verify.opsui loop locally.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 61-01-01 | 01 | 1 | OPS-PB-05 | — | N/A (test-only) | integration LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/playbook_live_test.exs` | ✅ | ⬜ pending |
| 61-02-01 | 02 | 1 | SHIP-01 | — | N/A (planning docs) | contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing ExUnit + `mix verify.opsui` cover the stack; no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `/gsd-complete-milestone` | SHIP-01 | GSD CLI + maintainer judgment | After merge evidence, follow project milestone skill; confirm archive paths. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable for `mix verify.opsui`
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
