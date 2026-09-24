---
phase: 160-package-backed-phoenix-proof
plan: 01
subsystem: verification
tags: [elixir, mix, hex, phoenix, meilisearch]
requires: []
provides:
  - "Package-backed Phoenix proof command with isolated artifact and consumer workspaces"
  - "Safe service preflight, subprocess diagnostics, and failure cleanup behavior"
affects: [160-02, 160-03, phase-160-verification]
actuals:
  tokens: 3500
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: ["Staged consumer resolves a tagged local Git artifact"]
key-files:
  created:
    - lib/mix/tasks/verify/phoenix_example/package.ex
    - test/mix/tasks/verify_phoenix_example_package_test.exs
  modified:
    - lib/mix/tasks/verify/capability.ex
    - lib/mix/tasks/verify.adopter.ex
    - test/mix/tasks/verify_capability_test.exs
key-decisions:
  - "Preserved the no-argument path-backed proof and added package mode behind --package."
  - "Did not start Docker because the plan requires pre-existing local services."
patterns-established:
  - "Subprocess output is captured and known sensitive environment values are redacted before display."
requirements-completed: [PKG-01, PKG-02, PKG-03]
coverage:
  - id: D1
    description: "Package mode builds and tags the checkout artifact, stages the consumer, and checks lock provenance."
    requirement: PKG-01
    verification:
      - kind: unit
        ref: test/mix/tasks/verify_phoenix_example_package_test.exs
        status: pass
      - kind: integration
        ref: "https://github.com/szTheory/scrypath/actions/runs/36000999039/job/107637337872 — exact-SHA package artifact/tag, staged dependency provenance, and consumer compile PASS"
        status: pass
    human_judgment: false
  - id: D2
    description: "Four real-service Phoenix integration scenarios run against the package artifact."
    requirement: PKG-02
    verification:
      - kind: integration
        ref: "https://github.com/szTheory/scrypath/actions/runs/36000999039/job/107637337872 — integration scenarios completed; 10 tests, 0 failures; no integration exclusion"
        status: pass
    human_judgment: false
  - id: D3
    description: "Failure handling reports stage/status and removes or explicitly retains the owned workspace."
    requirement: PKG-03
    verification:
      - kind: unit
        ref: test/mix/tasks/verify_phoenix_example_package_test.exs
        status: pass
    human_judgment: false
duration: 45min + hosted acceptance
completed: 2026-09-24
status: complete
---

# Phase 160 Plan 01: Package-backed Phoenix proof command

The command and deterministic failure lifecycle are implemented, and the required real-service acceptance passed on the exact candidate SHA in hosted CI.

## Accomplishments

- Added strict `--package` dispatch while preserving the no-argument path-backed route.
- Added package build/tagging, isolated staged dependency resolution, consumer compile/test, stage diagnostics, redaction, and owned-workspace cleanup/retention.
- Added focused mode and failure-lifecycle tests.
- Focused capability, adopter, package lifecycle, and release consumer smoke tests passed (19 tests total).

## Task Commits

1. Plan 01 implementation and failure tests — `b40f298` (`feat(160-01): add package-backed Phoenix proof command`).
2. Workspace ownership hardening — `d2b2e5b` (`fix(160-01): constrain package proof workspace cleanup`).
3. Secret-redaction assertion — `47fb5b5` (`test(160-01): assert endpoint redaction in raised errors`).

## Issues Encountered

- The required package-backed integration command stopped at service preflight: Postgres was reachable, but no Meilisearch listener was available at `127.0.0.1:7700`. Per plan instructions, Docker was not started.
- The cross-phase regression command ran 151 tests with 0 assertion failures but returned exit code 2. Isolating `test/mix/tasks/verify_adopter_test.exs` reproduced exit code 2 with 8 tests and 0 failures; this gate is unresolved and was not reported as passed.

## Hosted Acceptance

- Candidate and workflow source SHA: `7931271abe53e83261d85a22077176f75898eb81`.
- [CI run 36000999039](https://github.com/szTheory/scrypath/actions/runs/36000999039), job `phoenix-example (advisory)` ID `107637337872`, ran on that exact SHA.
- The path-backed command passed before the package-backed command; both named steps concluded `success`.
- Package artifact `v0.3.10` was built and tagged; the staged lock resolved Scrypath from `file:///tmp/scrypath-phoenix-package-1/artifact` at that tag; the consumer compiled.
- With `SCRYPATH_EXAMPLE_INTEGRATION=1`, package tests completed with **10 tests, 0 failures** and no integration exclusion. The four exercised integration modules are inline, Oban, related-inline, and related-Oban.
- Run logs and acceptance mapping are recorded in [`160-VALIDATION.md`](./160-VALIDATION.md).

## Resume Requirement

The `phoenix-example` hosted CI run provides the required exact-SHA real-service acceptance for PKG-01/PKG-02 and closes the live acceptance gap without asking a maintainer to recreate the service environment locally. The earlier cross-phase regression command's exit code 2 remains a separate unresolved result and is not represented as passing here.
