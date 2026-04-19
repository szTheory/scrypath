---
phase: 29
slug: golden-path-adoption-documentation
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-18
updated: 2026-04-18
---

# Phase 29 — Validation Strategy

> Documentation phase: automated verification is **`test/scrypath/docs_contract_test.exs`** (README + guide contracts) plus **`MIX_ENV=test mix docs --warnings-as-errors`** and **`mix verify.phase11`** from plan `<verification>` blocks.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir / ExUnit (`Mix.Project` test env) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix format --check-formatted && mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `MIX_ENV=test mix docs --warnings-as-errors && mix verify.phase11` |
| **Estimated runtime** | ~2 min local (`docs_contract` ~1s; `verify.phase11` dominates) |

---

## Sampling Rate

- **After every task commit:** `mix format --check-formatted`
- **After every plan wave / any `guides/*.md` or README / `mix.exs` extras change:** `MIX_ENV=test mix docs --warnings-as-errors`
- **Before phase close:** `mix verify.phase11` green
- **Nyquist mapping:** Doc-only tasks map to **`docs_contract_test.exs`** rows below so no requirement is “format only” without a content anchor.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat / note | Secure / contract behavior | Test Type | Automated verification | Status |
|---------|------|------|-------------|---------------|---------------------------|-----------|------------------------|--------|
| 29-01-T1 | 01 | 1 | ADPT-01 | T-29-DOC-01 | Golden path: inline search spine, placeholders | ExUnit + docs | `docs_contract_test` → `phase 29 golden path…` ; `mix docs` | ✅ |
| 29-01-T2 | 01 | 1 | ADPT-01 | — | `mix.exs` extras + Getting Started group | docs | `MIX_ENV=test mix docs --warnings-as-errors` | ✅ |
| 29-01-T3 | 01 | 1 | ADPT-01 | — | Getting started → golden path link | ExUnit | `docs_contract_test` → `Golden path](golden-path.md)` | ✅ |
| 29-01-T4 | 01 | 1 | ADPT-01 | — | README Start here → golden path | ExUnit | `docs_contract_test` → `**Start here:**` + `guides/golden-path.md` | ✅ |
| 29-02-T1 | 02 | 2 | ADPT-02 | T-29-DOC-02 | Sync modes heuristics + authority link in section | ExUnit | `docs_contract_test` → `**Choosing a mode:**` ; `ordered?` Sync→Search | ✅ |
| 29-02-T2 | 02 | 2 | ADPT-03 | T-29-DOC-03 | Versioning + `~> 0.3` + verify pointer | ExUnit + verify | `README opens…` + `phase 29…` + `mix verify.phase11` | ✅ |
| 29-02-T3 | 02 | 2 | ADPT-03 | — | `docs/releasing.md` adopter note | verify | `mix verify.phase11` (full gate) | ✅ |
| 29-02-T4 | 02 | 2 | ADPT-03 | — | CHANGELOG Unreleased cross-link | verify | `mix verify.phase11` | ✅ |

---

## Wave 0 Requirements

- [x] **Existing infrastructure** — reuse `docs_contract_test.exs`, `mix docs --warnings-as-errors`, `mix verify.phase11`; no new framework.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Golden path narrative flow | ADPT-01 | subjective reading order | New reader follows `guides/golden-path.md` top-to-bottom without confusion |
| HexDocs navigation | ADPT-01 | browser | After publish, open HexDocs **Getting Started** group → **Golden path** page renders |

---

## Validation Audit 2026-04-18

| Metric | Count |
|--------|-------|
| Gaps found | 3 (stale pending rows; wrong plan `03`; no ExUnit anchor for golden path / phase-29 README) |
| Resolved | 3 |
| Escalated | 0 |

---

## Validation Sign-Off

- [x] All tasks map to `<automated>` equivalents (`docs_contract` / `mix docs` / `verify.phase11`)
- [x] Sampling continuity preserved for doc edits
- [x] Wave 0 covers repository; no watch-mode
- [x] `nyquist_compliant: true`

**Approval:** approved 2026-04-18
