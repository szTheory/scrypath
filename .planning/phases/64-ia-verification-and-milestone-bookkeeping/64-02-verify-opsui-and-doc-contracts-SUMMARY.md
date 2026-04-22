---
phase: 64-ia-verification-and-milestone-bookkeeping
plan: "02"
subsystem: docs
tags: [verify.opsui, contributing, doc-contract]

requires: []
provides:
  - Contributor path documents mix scrypath_ops.playbooks.validate beside verify.opsui
  - guides/meilisearch-operations.md restored for ExDoc and docs_contract compilation
affects: []

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - guides/meilisearch-operations.md
  modified:
    - CONTRIBUTING.md
    - guides/operator-mix-tasks.md
    - test/scrypath/docs_contract_test.exs
    - .planning/REQUIREMENTS.md

key-decisions:
  - "AUDT-01 traceability row kept on rolling REQUIREMENTS.md so Nyquist doc-contract tests read a single requirements file."

patterns-established: []

requirements-completed:
  - OPS2-06

duration: 20min
completed: 2026-04-22
---

# Phase 64: verify.opsui and doc contracts — Summary

**Default contributor docs now mention `mix scrypath_ops.playbooks.validate`, the operator Mix guide lists it, and `mix verify.opsui` plus `docs_contract_test` stay green.**

## Self-Check: PASSED

- `mix test test/scrypath/docs_contract_test.exs` and `mix verify.opsui` exit 0 after edits.

## Accomplishments

- **CONTRIBUTING** — when to run directory validation for `scrypath_ops` JSON fixtures, alongside **`mix verify.opsui`**.
- **`guides/operator-mix-tasks.md`** — subsection for **`mix scrypath_ops.playbooks.validate`** from **`scrypath_ops/`**.
- **`guides/meilisearch-operations.md`** — restored published operator guide referenced by **`mix.exs`**, cross-links, and **`docs_contract_test`** module attributes.
- **`docs_contract_test`** — asserts CONTRIBUTING contains the validate invocation string; operator-mix-tasks spine includes the same substring.
- **`.planning/REQUIREMENTS.md`** — re-added **`AUDT-01`** traceability row required by the phase 32 Nyquist hygiene test when the rolling file is the primary source.
