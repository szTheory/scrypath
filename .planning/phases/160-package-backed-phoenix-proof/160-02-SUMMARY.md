---
phase: 160-package-backed-phoenix-proof
plan: 02
subsystem: ci-documentation
tags: [github-actions, phoenix, documentation, contracts]
requires:
  - phase: 160-package-backed-phoenix-proof
    provides: "Package-backed Phoenix proof command"
provides:
  - "Ordered path-backed then package-backed commands in the existing advisory CI job"
  - "Maintainer documentation and drift contracts for package mode"
affects: [phase-160-verification]
actuals:
  tokens: 1300
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: ["Job-scoped CI contract pins proof order and advisory service topology"]
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - CONTRIBUTING.md
    - examples/phoenix_meilisearch/README.md
    - test/scrypath/docs_contract_test.exs
key-decisions:
  - "Reused the existing advisory Phoenix service job and its Postgres/Meilisearch services."
  - "Kept the example's ordinary path dependency unchanged."
patterns-established:
  - "Documentation contracts assert path/package order, advisory status, service versions, prerequisites, and path dependency."
requirements-completed: [PROOF-01]
coverage:
  - id: D1
    description: "Advisory CI runs path mode before package mode with the current service block."
    requirement: PROOF-01
    verification:
      - kind: unit
        ref: test/scrypath/docs_contract_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: "Contributor and example runbooks document package mode and prerequisites while retaining the path workflow."
    requirement: PROOF-01
    verification:
      - kind: unit
        ref: test/scrypath/docs_contract_test.exs
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-09-23
status: complete
---

# Phase 160 Plan 02: Advisory CI and proof documentation

The existing advisory Phoenix service job now runs both proof modes in order, with documentation and machine checks aligned to the executable command contract.

## Accomplishments

- Added package mode after the existing path-backed proof in the `phoenix-example` CI job; service declarations and `continue-on-error` remain unchanged.
- Updated contributor and example runbooks with the package command and service prerequisites.
- Added job-scoped contracts for proof order, advisory topology, service versions, and the unchanged path dependency.
- Focused documentation and package command contract tests passed (80 tests).

## Task Commits

1. CI wiring — `b4d9091` (`ci(160-02): run package proof in advisory Phoenix lane`).
2. Documentation and contracts — `cf71c18` (`docs(160-02): document package-backed Phoenix proof`).

## Issues Encountered

- The Plan 01 live acceptance gate remains blocked by unavailable local Meilisearch, so this completed documentation/CI plan does not make Phase 160 complete.
