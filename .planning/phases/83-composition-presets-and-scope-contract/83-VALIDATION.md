---
phase: 83
slug: composition-presets-and-scope-contract
status: validated
nyquist_compliant: true
created: 2026-05-23
updated: 2026-05-23
---

# Phase 83 Validation Ledger

Append-only validation ledger for Phase 83. This file locks the proof seams the phase plans must satisfy before execution starts.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` plus `mix docs` |
| **Config file** | `test/test_helper.exs` and `mix.exs` docs config |
| **Quick composition gate** | `mix verify.phase83` after Wave 0 adds it |
| **Focused fallback command** | `mix test test/scrypath/composition_test.exs test/scrypath/docs_contract_test.exs` |
| **Property command** | `mix test test/scrypath/composition_property_test.exs` |
| **Docs build command** | `mix docs --warnings-as-errors` |
| **Fast suite command** | `mix test --exclude integration --exclude docs_contract` |
| **Full suite command** | `mix test` |

## Validation Targets

| ID | Requirement | Proof seam | Automated command | Status |
|----|-------------|------------|-------------------|--------|
| 83-VAL-01 | CMP-01 | Presets and scopes resolve into the same canonical `{text, keyword_opts}` contract already consumed by `Scrypath.search/3`, with no second runtime and no public `%Scrypath.Query{}`. | `mix test test/scrypath/composition_test.exs` | planned |
| 83-VAL-02 | CMP-02 | Defaults, caller input, and fixed constraints obey deterministic field-specific precedence, including explicit conflicts for incompatible fixed keys. | `mix test test/scrypath/composition_test.exs test/scrypath/composition_property_test.exs` | planned |
| 83-VAL-03 | CMP-03 | Visibility metadata (`applied`, `defaulted`, `fixed`, optional warnings/sources) matches the final criteria that would reach the canonical runtime. | `mix test test/scrypath/composition_test.exs` | planned |
| 83-VAL-04 | CMP-04 | Public docs and API wording keep composition context-owned, keep Phoenix optional, and avoid schema-owned or facade-style runtime drift. | `mix test test/scrypath/docs_contract_test.exs` | planned |
| 83-VAL-05 | Phase docs hygiene | The published docs still compile cleanly after adding the composition contract and its guide updates. | `mix docs --warnings-as-errors` | planned |
| 83-VAL-06 | Phase workflow gate | A dedicated Phase 83 verify task exists and runs the intended composition proof seams. | `mix test test/scrypath/docs_contract_test.exs` | planned |

## Per-Plan Verification Map

| Task ID | Plan | Wave | Requirement | Automated command | File Exists | Status |
|---------|------|------|-------------|-------------------|-------------|--------|
| 83-01-01 | 01 | 1 | CMP-01, CMP-03 | `rg -n "@spec compose\\(.*\\) :: \\{:ok,.*\\} \\| \\{:error, term\\(\\)\\}" lib/scrypath/composition.ex && rg -n "@spec compose!\\(" lib/scrypath/composition.ex && rg -n "@spec to_search_args\\(" lib/scrypath/composition.ex && rg -n "defaults|fixed|applied|defaulted|sources|warnings" lib/scrypath/composition.ex lib/scrypath/composition/result.ex && ! rg -n "%Scrypath.Query\\{\\}" lib/scrypath/composition.ex lib/scrypath/composition/result.ex` | ❌ Wave 0 | planned |
| 83-01-02 | 01 | 1 | CMP-04, docs hygiene | `rg -n "Scrypath\\.Composition" lib/scrypath.ex && rg -n "contexts|search/3 remains the canonical runtime entrypoint" lib/scrypath.ex && rg -n "optional glue" lib/scrypath.ex && rg -n "schema-specific runtime verbs|generated UI|tenant" lib/scrypath.ex && mix docs --warnings-as-errors` | ✅ | planned |
| 83-02-01 | 02 | 1 | CMP-01, CMP-02, CMP-03 | `mix test test/scrypath/composition_test.exs` | ❌ Wave 0 | planned |
| 83-02-02 | 02 | 1 | CMP-02, CMP-04 | `mix deps.get && mix test test/scrypath/composition_property_test.exs test/scrypath/docs_contract_test.exs` | ❌ / ✅ | planned |
| 83-03-01 | 03 | 2 | CMP-01, CMP-02 | `mix test test/scrypath/composition_test.exs --seed 0` | ❌ Wave 0 | planned |
| 83-03-02 | 03 | 2 | CMP-02, CMP-03 | `mix test test/scrypath/composition_test.exs test/scrypath/composition_property_test.exs` | ❌ Wave 0 | planned |
| 83-03-03 | 03 | 2 | CMP-01, CMP-02, CMP-03, CMP-04 | `mix verify.phase83` | ❌ Wave 0 | planned |

## Baseline Notes

- The checked-out repo already centers one canonical single-search runtime: `Scrypath.QueryParams` prepares plain data and `Scrypath.search/3` executes it.
- `%Scrypath.Query{}` is explicitly internal and must stay out of the public composition contract.
- The new risk surface is merge honesty: duplicate keyword keys, whole-value override fields, and fixed-constraint conflicts must be tested directly rather than implied through generic merge helpers.
- Recent phases already use phase-scoped verify tasks and bounded docs contracts; Phase 83 should extend that pattern instead of introducing a new verification style.
- The current execution layout is three plans in two waves: `83-01` and `83-02` in wave 1, then `83-03` in wave 2 after the contract and verification harness exist.

## Manual-Only / Deferred

| Behavior | Requirement | Disposition | Notes |
|----------|-------------|-------------|-------|
| Persisted or externally exchanged preset definitions | CMP-01 | deferred | Explicitly out of scope for Phase 83. |
| Phoenix-owned composition helpers, macros, or runtime facades | CMP-04 | rejected | This phase must keep Phoenix as request-edge glue only. |
| Full merge trace or explain-engine output | CMP-03 | rejected | Keep visibility coarse and stable. |

## Acceptance Gate

Phase 83 validation can only be marked complete when:

- `83-VAL-01` proves composition resolves to existing search args rather than a second runtime.
- `83-VAL-02` and `83-VAL-03` prove precedence, conflict handling, and visibility metadata are stable and inspectable.
- `83-VAL-04` and `83-VAL-06` prove the public boundary and phase-specific verify task stay honest.
- `83-VAL-05` proves the published docs remain warning-clean after the new contract lands.

## Sign-Off

- [x] Requirements `CMP-01` through `CMP-04` each map to explicit proof seams
- [x] The validation ledger exists before execution so Nyquist dimension 8 has a concrete artifact
- [x] The ledger does not claim execution evidence that has not yet been produced
- [x] Merge-risk areas are called out directly instead of being hidden behind broad “search still works” checks
