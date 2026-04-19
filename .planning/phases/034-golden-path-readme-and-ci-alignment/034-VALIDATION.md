---
phase: 34
slug: golden-path-readme-and-ci-alignment
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-19
---

# Phase 34 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (doc + ExUnit contracts).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix test` (optional for doc-only PR if CI runs full matrix) |
| **Estimated runtime** | ~5–30 seconds for docs contract module |

---

## Sampling Rate

- **After every task commit:** `mix test test/scrypath/docs_contract_test.exs`
- **After every plan wave:** same
- **Before `/gsd-verify-work`:** contract module green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | ADPT-01, ADPT-03 | T-34-DOC-01 / — | N/A — docs integrity | ExUnit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 34-01-02 | 01 | 1 | ADPT-01, ADPT-03 | T-34-DOC-02 | N/A | ExUnit | same | ✅ | ⬜ pending |
| 34-02-01 | 02 | 1 | ADPT-02, ADPT-03, VRFY-01 | T-34-DOC-01 | N/A | ExUnit | same | ✅ | ⬜ pending |
| 34-02-02 | 02 | 1 | ADPT-02, VRFY-01 | — | N/A | ExUnit | same | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements — **no** Wave 0 install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README read order | ADPT-01 | subjective | Open README: Quick Path reads as teaser + CTA into golden path |

---

## Validation Sign-Off

- [ ] All tasks have ExUnit verify via `docs_contract_test.exs`
- [ ] `nyquist_compliant: true` set in frontmatter after execution green

**Approval:** pending
