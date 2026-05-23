---
phase: 82
slug: docs-examples-and-drift-protection
status: validated
nyquist_compliant: true
created: 2026-05-23
updated: 2026-05-23
---

# Phase 82 Validation Ledger

Append-only validation ledger for Phase 82. This file locks the proof seams the phase plans must satisfy and gives the checker a concrete Nyquist artifact before execution begins.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` plus `mix docs` |
| **Config file** | `test/test_helper.exs` and `mix.exs` docs config |
| **Core docs contract command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Fixture proof command** | `mix test test/support/docs/phoenix_examples_test.exs test/support/docs/phoenix_request_shape_smoke_test.exs` |
| **Docs build command** | `mix docs --warnings-as-errors` |
| **Full suite command** | `mix test` |

## Validation Targets

| ID | Requirement | Proof seam | Automated command | Status |
|----|-------------|------------|-------------------|--------|
| 82-VAL-01 | DOC-01 | Root docs route readers through one canonical request-edge story while keeping contexts and `Scrypath.search/3` canonical. | `mix test test/scrypath/docs_contract_test.exs` | planned |
| 82-VAL-02 | DOC-01 | Phoenix guides and compile-checked fixtures tell the same helper-only boundary story for controller and LiveView usage. | `mix test test/support/docs/phoenix_examples_test.exs test/support/docs/phoenix_request_shape_smoke_test.exs test/scrypath/phoenix_test.exs` | planned |
| 82-VAL-03 | VRFY-01 | Drift protection fails if `%Scrypath.Query{}` becomes public-facing, Phoenix stops being optional, or helpers imply a second runtime. | `mix test test/scrypath/docs_contract_test.exs test/scrypath/phoenix_test.exs` | planned |
| 82-VAL-04 | VRFY-01 | Example README, CI job, and local smoke instructions remain aligned on commands, env vars, and proof posture. | `mix test test/scrypath/docs_contract_test.exs` | planned |
| 82-VAL-05 | Phase docs hygiene | The published docs still compile cleanly after the guide and wayfinding changes. | `mix docs --warnings-as-errors` | planned |

## Per-Plan Verification Map

| Task ID | Plan | Wave | Requirement | Automated command | File Exists | Status |
|---------|------|------|-------------|-------------------|-------------|--------|
| 82-01-01 | 01 | 1 | DOC-01 | `mix test test/scrypath/docs_contract_test.exs` | ✅ | planned |
| 82-01-02 | 01 | 1 | DOC-01 | `mix docs --warnings-as-errors` | ✅ | planned |
| 82-02-01 | 02 | 2 | VRFY-01 | `mix test test/scrypath/docs_contract_test.exs test/support/docs/phoenix_examples_test.exs test/support/docs/phoenix_request_shape_smoke_test.exs` | ✅ | planned |
| 82-02-02 | 02 | 2 | VRFY-01 | `mix test test/scrypath/phoenix_test.exs test/support/docs/phoenix_examples_test.exs` | ✅ | planned |

## Baseline Notes

- The checked-out Phase 81 code and guides already ship the request-edge runtime and helper surfaces; Phase 82 exists to make the public story coherent and durable.
- `lib/scrypath.ex` still contains phase-80-only wording about nested request params, so root-doc drift is already present before implementation.
- `test/scrypath/docs_contract_test.exs` already uses bounded contract assertions, which is the right base seam for this phase.

## Manual-Only / Deferred

| Behavior | Requirement | Disposition | Notes |
|----------|-------------|-------------|-------|
| Broad information architecture rewrites beyond the v1.21 request-edge lane | DOC-01 | deferred | Keep this phase narrow; only move docs needed for the public request-edge story. |
| Full prose snapshots of published docs | VRFY-01 | rejected | Keep contracts targeted and contributor-friendly. |

## Acceptance Gate

Phase 82 validation can only be marked complete when:

- `82-VAL-01` and `82-VAL-02` prove the canonical guide and Phoenix guide cluster tell one consistent boundary story.
- `82-VAL-03` and `82-VAL-04` prove the new docs contracts catch public-story and example/CI drift.
- `82-VAL-05` proves the docs build remains warning-clean.

## Sign-Off

- [x] Requirements `DOC-01` and `VRFY-01` each map to explicit proof seams
- [x] The validation ledger exists before execution so Nyquist dimension 8 has a concrete artifact
- [x] The ledger does not claim execution evidence that has not yet been produced
- [x] The public-story assertions stay contract-shaped rather than prose-snapshot-shaped
