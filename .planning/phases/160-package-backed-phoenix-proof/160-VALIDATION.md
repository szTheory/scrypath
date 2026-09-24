---
phase: 160
slug: package-backed-phoenix-proof
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-09-23
---

# Phase 160 — Validation Map

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit / Mix |
| Supported verification environments | Elixir 1.19.0 / Erlang OTP 28.1; Elixir 1.19.5 / Erlang OTP 28.5 |
| Fast suite | `mix test --exclude integration --exclude docs_contract` |
| Phase 160 docs contract | `mix test test/scrypath/docs_contract_test.exs` |
| Package/capability contracts | `mix test test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_phoenix_example_package_test.exs` |
| Real-service package proof | `SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.phoenix_example --package` |

Commands were run with `ASDF_ERLANG_VERSION=28.5 ASDF_ELIXIR_VERSION=1.19.5-otp-28 asdf exec mix ...` because the repository has no selected local asdf version. The sandbox denied Mix's local TCP socket until the test command was run with the approved elevated sandbox execution.

## Requirement Verification Map

| Behavior | Requirement | Test Type | Automated Command / Evidence | Coverage Status | Acceptance Status |
|----------|-------------|-----------|------------------------------|-----------------|-------------------|
| Package mode dispatches strictly, preserving default path mode | PKG-01, PROOF-01 | Unit | `mix test test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_phoenix_example_package_test.exs` — 11 tests, 0 failures | ✅ Covered | ✅ Green |
| Package command builds/unpacks current artifact, resolves staged consumer from its tagged local artifact, and compiles it | PKG-01 | Integration | Exact-SHA run [35998481376](https://github.com/szTheory/scrypath/actions/runs/35998481376), job 107629043080; artifact/tag, staged lock, and compile PASS markers below | ✅ Covered by hosted package run | ✅ Green |
| Four existing inline, Oban, and related-data flows execute against package artifact | PKG-02 | Integration | Exact-SHA run [35998481376](https://github.com/szTheory/scrypath/actions/runs/35998481376), job 107629043080; integration PASS with 10 tests, 0 failures and no integration exclusion | ✅ Covered by hosted package run | ✅ Green |
| Service preflight occurs before workspace/package commands; failures redact endpoint values | PKG-03 | Unit | `test/mix/tasks/verify_phoenix_example_package_test.exs` | ✅ Covered | ✅ Green |
| Subprocess failure reports stage/status and cleans task-owned workspace; explicit failed-run retention works | PKG-03 | Unit | `test/mix/tasks/verify_phoenix_example_package_test.exs` | ✅ Covered | ✅ Green |
| Documentation and CI agree on command order, advisory services, prerequisites, and normal path dependency | PROOF-01 | Contract | `mix test test/scrypath/docs_contract_test.exs` — 71 tests, 0 failures | ✅ Covered | ✅ Green |

## Execution Results

- Package task tests: **6 tests, 0 failures**, including realistic lock provenance and success/dependency/compile/test cleanup coverage.
- Capability plus package task contracts: **11 tests, 0 failures**.
- Phase 160 docs contract: **71 tests, 0 failures**.
- Documented fast suite passed after isolating the telemetry listener with a unique backend marker and adding lock provenance/lifecycle regressions: Elixir 1.19.0 / OTP 28.1, **572 tests, 0 failures** (80 excluded).
- Earlier, before the lock provenance regression was added, the same suite passed on Elixir 1.19.5 / OTP 28.5 with **570 tests, 0 failures** (80 excluded).
- The local package-backed integration command is intentionally not counted as a pass: local service prerequisites are unavailable. Exact-SHA hosted evidence is recorded below; it is automated service-backed evidence, not a human UAT request.

## Exact-SHA Hosted Package Proof

- **Candidate / source workflow SHA:** `d7b499b93d9ebcc4c84b16c316266fa524dfc61a` (`.github/workflows/ci.yml` was read from this commit).
- **Workflow run:** [CI run 35998481376](https://github.com/szTheory/scrypath/actions/runs/35998481376), `workflow_dispatch`, branch `gsd/v1.37-code-quality-ratchet`; run head SHA exactly matches the candidate SHA above.
- **Job:** `phoenix-example (advisory)`, job ID `107629043080`, conclusion `success`.
- **Ordered proof steps:** `Run mix verify.phoenix_example` — `success`; then `Run mix verify.phoenix_example --package` — `success`.
- **Package markers:** artifact created and tagged `v0.3.10`; staged dependencies resolved to `file:///tmp/scrypath-phoenix-package-1/artifact` at `v0.3.10`; consumer compiled; integration scenarios completed. The source URL is the run's local tagged artifact URL from the staged lock output.
- **Live integration result:** package step ran with `SCRYPATH_EXAMPLE_INTEGRATION=1`; ExUnit reported **10 tests, 0 failures**. The log contains no `Excluding tags: ... integration` line. The staged example's four integration modules cover inline, Oban, related-inline, and related-Oban scenarios.
- **Evidence source:** [job 107629043080](https://github.com/szTheory/scrypath/actions/runs/35998481376/job/107629043080); hosted log markers were checked individually, since the parent workflow's advisory status does not establish this job's result.

## Status

No uncovered Phase 160 requirement needs a new test harness: focused executable contracts cover command dispatch, fail-closed behavior, cleanup/retention, and CI/documentation drift; the exact-SHA hosted package run now proves artifact build, staged dependency provenance, consumer compilation, and service-backed integration execution.
