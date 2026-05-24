---
phase: 85
slug: real-app-proof-and-drift-gates
status: validated
nyquist_compliant: true
created: 2026-05-23
updated: 2026-05-23
---

# Phase 85 Validation Ledger

Append-only validation ledger for Phase 85. This file locks the proof seams the phase plans must satisfy before execution starts.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` plus `mix docs` |
| **Config file** | `test/test_helper.exs` and `mix.exs` docs config |
| **Quick phase gate** | `mix verify.phase85` after Wave 0 adds it |
| **Focused composition command** | `mix test test/scrypath/composition_test.exs` |
| **Focused metadata command** | `mix test test/scrypath/metadata_test.exs` |
| **Focused multi-search command** | `mix test test/scrypath/composition_many_test.exs` |
| **Docs contract command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Docs build command** | `mix docs --warnings-as-errors` |

## Validation Targets

| ID | Requirement | Proof seam | Automated command | Status |
|----|-------------|------------|-------------------|--------|
| 85-VAL-01 | DOC-01 | One canonical composition/metadata guide exists and root docs route readers to it in the intended order. | `mix test test/scrypath/docs_contract_test.exs` | planned |
| 85-VAL-02 | DOC-01 | The single-schema Phoenix guide proves metadata-driven honest controls without making Phoenix or generated UI canonical. | `mix test test/scrypath/docs_contract_test.exs` | planned |
| 85-VAL-03 | DOC-01 | The multi-schema guide proves `compose_many/2` lowering and partial-failure honesty without a fake merged capability surface. | `mix test test/scrypath/docs_contract_test.exs` | planned |
| 85-VAL-04 | DOC-02 | Canonical docs keep non-goals explicit: no public `%Scrypath.Query{}`, no schema-generated verbs, no generated UI, no tenant/authz or related-data promises. | `mix test test/scrypath/docs_contract_test.exs` | planned |
| 85-VAL-05 | VRFY-01 | Composition precedence remains aligned with the public story. | `mix test test/scrypath/composition_test.exs` | planned |
| 85-VAL-06 | VRFY-01 | Metadata derivation and resolved-state semantics remain aligned with the public story. | `mix test test/scrypath/metadata_test.exs` | planned |
| 85-VAL-07 | VRFY-01 | `search_many/2` composition lowering and parity remain aligned with the public story. | `mix test test/scrypath/composition_many_test.exs` | planned |
| 85-VAL-08 | Phase docs hygiene | Published docs compile cleanly after the new canonical guide and wayfinding changes land. | `mix docs --warnings-as-errors` | planned |
| 85-VAL-09 | Phase workflow gate | `mix verify.phase85` exists and runs exactly the intended focused seams. | `mix test test/scrypath/docs_contract_test.exs` | planned |

## Per-Plan Verification Map

| Task ID | Plan | Wave | Requirement | Automated command | File Exists | Status |
|---------|------|------|-------------|-------------------|-------------|--------|
| 85-01-01 | 01 | 1 | DOC-01, DOC-02 | `rg -n "composing-real-app-search|Composition|non-goals|generated UI|tenant authz" README.md guides/overview.md lib/scrypath.ex` | ✅ / ✅ / ✅ | planned |
| 85-01-02 | 01 | 1 | DOC-01 | `rg -n "request-edge-search|composing-real-app-search|faceted-search-with-phoenix-liveview|multi-index-search" guides/overview.md mix.exs` | ✅ / ✅ | planned |
| 85-02-01 | 02 | 1 | VRFY-01 | `rg -n "verify\\.phase85" lib/mix/tasks/verify.phase85.ex mix.exs` | ❌ Wave 0 | planned |
| 85-02-02 | 02 | 1 | DOC-01, DOC-02, VRFY-01 | `mix test test/scrypath/docs_contract_test.exs` | ✅ | planned |
| 85-03-01 | 03 | 2 | DOC-01, DOC-02 | `mix docs --warnings-as-errors` | ✅ | planned |
| 85-03-02 | 03 | 2 | VRFY-01 | `mix verify.phase85` | ❌ Wave 0 | planned |

## Baseline Notes

- The checked-out repo already exposes the bounded composition and metadata runtime surfaces from Phases 83 and 84.
- The main remaining risk is public-story drift: readers could still miss the canonical composition lane or infer generated UI / merged global capability claims from scattered docs.
- The second risk is verification drift: without one phase-local gate, the milestone-close story could regress even while prior runtime tests remain green in isolation.

## Manual-Only / Deferred

| Behavior | Requirement | Disposition | Notes |
|----------|-------------|-------------|-------|
| New example app or service-backed proof lane | DOC-01 | rejected | Phase 85 proves real-app depth through guides, existing example links, and focused docs/runtime gates. |
| Generated controls, components, or macros | DOC-02 | rejected | Metadata stays host-rendering support only. |
| Tenant-safe authz or related-data propagation guarantees | DOC-02 | deferred | Still explicitly host-owned / future-scope concerns. |
| Broad milestone aggregate verification | VRFY-01 | rejected | `verify.phase85` must stay focused and local. |

## Acceptance Gate

Phase 85 validation can only be marked complete when:

- `85-VAL-01` through `85-VAL-04` prove the canonical guide, proof-guide hierarchy, and non-goal language are all present and ordered correctly.
- `85-VAL-05` through `85-VAL-07` prove the runtime truths behind the story still hold.
- `85-VAL-08` and `85-VAL-09` prove the docs build and focused phase task stay healthy.

## Sign-Off

- [x] Requirements `DOC-01`, `DOC-02`, and `VRFY-01` each map to explicit proof seams
- [x] The validation ledger exists before execution so Nyquist dimension 8 has a concrete artifact
- [x] The ledger does not claim execution evidence that has not yet been produced
- [x] The highest-risk drift areas are called out directly: canonical-guide discoverability, non-goal truth, and focused verify drift
