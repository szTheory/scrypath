---
phase: 35
slug: sync-guide-lifecycle-parity
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-19
---

# Phase 35 — Validation Strategy

> Doc-only phase: validation is **ExUnit doc contract tests** plus light manual read of the new guide subsection.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30–120 seconds (environment dependent) |

---

## Sampling Rate

- **After every task commit:** `mix test test/scrypath/docs_contract_test.exs`
- **After every plan wave:** Same command (single wave)
- **Before `/gsd-verify-work`:** `mix test` green for scope the phase touched
- **Max feedback latency:** ~120s

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | ADPT-02, ADPT-03 | T-35-DOC-01 / — | N/A (docs integrity) | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 35-01-02 | 01 | 1 | ADPT-02, ADPT-03 | T-35-DOC-01 | N/A | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 35-01-03 | 01 | 1 | ADPT-02, ADPT-03 | T-35-DOC-02 | N/A | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — **no Wave 0 install**.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guide reads as one spec | ADPT-03 | Tone and duplication are subjective | Read `guides/sync-modes-and-visibility.md` from **The Contract** through start of **`## :inline`**; confirm lifecycle gloss does not re-derive entire mode narrative |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify
- [ ] Sampling continuity maintained
- [ ] `nyquist_compliant: true` set in frontmatter after execution pass

**Approval:** pending
