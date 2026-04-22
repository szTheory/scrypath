---
phase: 51
slug: adoption-path-truth-and-discoverability
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-21
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (doc + ExUnit contracts).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `mix.exs` test configuration |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix test --exclude integration` |
| **Estimated runtime** | ~1–3 minutes (quick), ~5–15 minutes (full, machine-dependent) |

---

## Sampling Rate

- **After every task commit:** `mix test test/scrypath/docs_contract_test.exs`
- **After every plan wave:** Same quick command (wave 1 may run twice in parallel agents — each validates its slice)
- **Before `/gsd-verify-work`:** `mix test --exclude integration` green
- **Max feedback latency:** Target under 120s for quick command on CI-class hardware

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-01-01 | 01 | 1 | ONBD-01, ONBD-02 | — | N/A (public docs) | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 51-02-01 | 02 | 1 | ONBD-02, ONBD-03 | — | N/A | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 51-03-01 | 03 | 2 | ONBD-01, ONBD-03 | — | N/A | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red*

---

## Wave 0 Requirements

- Existing **`test/scrypath/docs_contract_test.exs`** covers published markdown contracts — no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README → golden path reader flow | ONBD-01 | Human judgment on clarity | From clean clone, read README Quick Path only; open linked golden path; confirm no contradictory dependency or sync claims vs `mix.exs` published range. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify via docs contract suite (or noted manual row)
- [ ] Sampling continuity: no three consecutive tasks without `mix test test/scrypath/docs_contract_test.exs`
- [ ] No watch-mode flags in verification commands
- [ ] `nyquist_compliant: true` set in frontmatter after execution wave sign-off

**Approval:** pending
