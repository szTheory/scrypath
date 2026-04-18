---
phase: 28
slug: operator-cli-docs-verify-gate
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-17
---

# Phase 28 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix format --check-formatted && mix compile --warnings-as-errors` |
| **Full suite command** | `mix verify.phase28` |
| **Estimated runtime** | ~60–120 seconds (depends on host) |

---

## Sampling Rate

- **After every task commit:** Run the task’s `<automated>` verify command from the active PLAN.md.
- **After every plan wave:** Run `mix test` on the files touched by that wave plus `mix compile --warnings-as-errors`.
- **Before `/gsd-verify-work`:** `mix verify.phase28` must be green.
- **Max feedback latency:** Target under 3 minutes for `mix verify.phase28` on a laptop.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 28-01-01 | 01 | 1 | OPS15-02 | T-28-CLI | Read-only `get_settings` via existing builder; no index mutation | unit + mix task | `mix test test/scrypath/mix_tasks/operator_tasks_test.exs` (after tests added) | ✅ | ⬜ pending |
| 28-02-01 | 02 | 2 | OPS15-03 | — | Docs only; no secrets | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 28-03-01 | 03 | 2 | OPS15-04 | — | Verify task auth-free | integration | `mix verify.phase28` | ❌ until W0 | ⬜ pending |

---

## Wave 0 Requirements

- [x] Existing ExUnit + Mix task infrastructure covers Phase 28; no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Terminal colors / TTY | OPS15-02 | CI is non-TTY | Optional: run `mix scrypath.index.contract_drift SearchablePost` in an interactive shell and confirm ANSI only when TTY |

*Default: All phase behaviors have automated verification via tests + `mix verify.phase28`.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no three consecutive tasks without automated verify
- [ ] No watch-mode flags in commands
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
