---
phase: 38
slug: search-within-facet-docs
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-19
---

# Phase 38 — Validation strategy

Per-phase validation contract for execution sampling (`38-RESEARCH.md` § Validation Architecture).

## Test infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/scrypath/search_within_facet_test.exs` |
| **Full suite command** | `mix test` |
| **Phase slice command** | `mix verify.phase38` |

## Sampling rate

- After **plan 01** tasks: `mix test test/scrypath/search_within_facet_test.exs`
- After **plan 02** (docs): `mix verify.phase38`
- Before release / verify-work: `mix compile --warnings-as-errors` and full `mix test`

## Per-task verification map

| Task | Plan | Wave | Requirement | Test type | Automated command | Status |
|------|------|------|-------------|-----------|-------------------|--------|
| Search refactor + API | 01 | 1 | FACET-03 | unit + integration | `mix test test/scrypath/search_within_facet_test.exs` | pending |
| Docs + contracts + verify task | 02 | 2 | FACET-04 | contract + integration | `mix verify.phase38` | pending |

## Wave 0 requirements

Existing ExUnit + `Req.Test` infrastructure covers this phase — no Wave 0 install.

## Manual-only verifications

| Behavior | Why manual | Instructions |
|----------|------------|--------------|
| Real Meilisearch cluster semantics | CI uses stubs | Optional: run example app against local Meilisearch with facet index settings |

## Validation sign-off

- [ ] All tasks include automated `mix test` (or verify task) in plan `<verify>`
- [ ] `mix verify.phase38` lists new search test file + `docs_contract_test.exs`
- [ ] `nyquist_compliant: true` after execution passes

**Approval:** pending
