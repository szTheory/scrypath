---
phase: 29
slug: golden-path-adoption-documentation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-18
---

# Phase 29 — Validation Strategy

> Documentation phase: validation is **format + ExDoc + existing verify gates**, not new ExUnit features.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir / Mix (existing repo) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix format --check-formatted` |
| **Full suite command** | `MIX_ENV=test mix docs --warnings-as-errors && mix verify.phase11` |
| **Estimated runtime** | ~120–300 seconds (depends on CI cache) |

---

## Sampling Rate

- **After every task commit:** `mix format --check-formatted`
- **After every plan wave:** `MIX_ENV=test mix docs --warnings-as-errors` (mandatory when `mix.exs` extras or any `guides/*.md` under ExDoc changes)
- **Before phase close / verify-work:** `mix verify.phase11` green on branch
- **Max feedback latency:** acceptable if full `verify.phase11` runs once per wave, not every micro-commit

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 1 | ADPT-01 | T-29-DOC-01 / — | No secret literals in docs | docs | `mix format --check-formatted` | ✅ | ⬜ pending |
| 29-01-02 | 01 | 1 | ADPT-01 | — | N/A | docs | `MIX_ENV=test mix docs --warnings-as-errors` | ✅ | ⬜ pending |
| 29-02-01 | 02 | 2 | ADPT-02 | — | N/A | docs | `mix format --check-formatted` | ✅ | ⬜ pending |
| 29-03-01 | 03 | 2 | ADPT-03 | — | N/A | docs + contract | `mix format --check-formatted && mix verify.phase11` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [x] **Existing infrastructure covers all phase requirements** — no new test framework; reuse `mix docs`, `mix verify.phase11`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Golden path readability | ADPT-01 | subjective flow | Maintainer hands doc to a colleague; confirm single spine completes without dead links |
| HexDocs navigation | ADPT-01 | browser | After release, open HexDocs “Getting Started” group and confirm golden path page appears |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: doc-changing tasks run `mix docs --warnings-as-errors` when ExDoc inputs change
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
