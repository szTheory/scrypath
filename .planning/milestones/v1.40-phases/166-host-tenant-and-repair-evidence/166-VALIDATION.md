---
phase: "166"
slug: "host-tenant-and-repair-evidence"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-26"
---

# Phase 166 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing ExUnit; Elixir 1.19.5, OTP 28 when selecting the available asdf toolchain explicitly |
| **Config file** | `test/test_helper.exs`; Phoenix consumer SQL Sandbox support in `examples/phoenix_meilisearch/test/support/data_case.ex` |
| **Quick run command** | Run the focused contract test added or extended by the task; use the explicit asdf prefix for root tests |
| **Full suite command** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test --exclude integration --exclude docs_contract` |
| **Observed runtime** | Phoenix consumer: 16 tests in 8.7 s (path) and 8.5 s (package); root backend wrapper: 9 integration tests across four modules, including the 4-test repair module; core gate: 591 tests in 19.4 s plus docs build |

Local service tuple was verified as Postgres 16 (`postgres:16-alpine`) and Meilisearch 1.15.2 from image tag `getmeili/meilisearch:v1.15`; hosted Phoenix receipts used the same declared image tags. The root repair fixture uses SQLite `IntegrationRepo` and live Meilisearch. Local services were the phase-owned Compose project on ports 55433 and 7700; credentials are omitted.

## Sampling Rate

- **After every task commit:** Run that task's focused test or source-freshness command.
- **After each plan wave:** Run the applicable root fast suite or Phoenix consumer scenario for both dependency modes.
- **Before `$gsd-verify-work`:** Complete the exact named live/service and package evidence for the accepted claims, or record the bounded result as UNKNOWN when execution is unavailable.
- **Max feedback latency:** Unmeasured; record focused command durations during execution.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 166-01-01 | 01 | 1 | HOST-01 | T-166-01 | Persisted membership derives trusted tenant scope; raw hit and separately hydrated record match | Recorder contract + Phoenix/Postgres/Meilisearch integration | `cd examples/phoenix_meilisearch && mix test test/scrypath_demo/blog_tenant_search_test.exs` and `mix verify.phoenix_example` | 5 context tests pass; hosted and local named scenario pass | pass |
| 166-01-02 | 01 | 1 | HOST-02 | T-166-01 | A/B raw IDs, host records, counts, categories, draft exclusion, and facet values are asserted symmetrically | Phoenix/Postgres/Meilisearch integration | `mix verify.phoenix_example` | Same named scenario passes in path mode, 16 consumer tests pass | pass |
| 166-02-01 | 02 | 1 | REPAIR-01 | T-166-02 | Known mismatch is read-only in report; selected-ID backfill restores exact raw projection and preserves controls | ExUnit/live backend integration | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 SCRYPATH_INTEGRATION=1 mix test test/scrypath/live_operator_verification_test.exs --only bounded_repair --trace` | Focused scenario and full hosted backend module pass; named task/index/raw marker recorded | pass |
| 166-02-02 | 02 | 1 | REPAIR-02 | T-166-02 | Fixed selected scope succeeds again with a new task; empty selection creates no task and preserves controls | ExUnit/Meilisearch integration + unit contracts | `mix test test/scrypath/live_operator_verification_test.exs --only bounded_repair_empty --trace`; contract trio; `mix verify.backend` | Empty-scope test and 24 contract tests pass; live module 4 tests pass | pass |
| 166-03-01 | 03 | 2 | HOST-01, HOST-02, PKG-04, REPAIR-01, REPAIR-02 | T-166-E1 | Same source-bound host scenario passes in path and package modes; root repair has exact task and raw-result evidence | Local services + exact-SHA hosted job/log verification | Path, `--package`, and `SCRYPATH_INTEGRATION=1 mix verify.backend`; `node scripts/ci_monitor.cjs closeout --push --branch gsd/v1.38-cleanup-merged --sha 50d5c12d36ec560525e245bcb992c40e5927854f` | Run 36321613553 attempt 1: Phoenix job 108626420623 and backend job 108626420717 both success; named markers and local-artifact provenance recorded in EVIDENCE | pass |
| 166-03-02 | 03 | 2 | DELETE-01 | T-166-E2 | Historical C-09 receipt is compared path-by-path to the assessment source; reuse is limited to the preserved hard-delete claim | Two-tree Git path inventory plus semantic source inspection and structural JSON check | `git diff --name-only dc400b2b57aec0ca6b0ef16c9477d266fd41a433 50d5c12d36ec560525e245bcb992c40e5927854f -- lib examples config test/support .github/workflows mix.exs mix.lock`; `mix verify.core --exclude integration --exclude docs_contract` | 16 changed relevant paths all dispositioned; C-09 reusable for bounded claim; core gate passed, 591 tests and docs build | pass |

The plan checker may adjust plan/task IDs and split tasks while retaining this requirement-to-proof mapping. The existing Phoenix package task stages the same consumer and runs the suite against the package artifact; retain its current advisory CI posture and do not add a required lane.

## Wave 0 Requirements

- [x] Add the persisted synthetic actor/membership scenario with separate raw and hydrated assertions.
- [x] Add the known mismatch, calibrated no-write report, selected-ID repair, exact task, and visible-search assertions.
- [x] Reuse the existing fixtures, task polling, service setup, diagnostics, cleanup, and package harness.
- [x] Verify the Postgres/Meilisearch tuple locally and bind the three hosted executions to the exact committed source SHA.

## Automated closeout review

| Behavior | Requirement | Automated evidence and limit |
|----------|-------------|----------------------------|
| C-09 source freshness | DELETE-01 | Executor compared both trees across every planned path, inspected each semantic change, and validated the changed-path ledger with the JSON structural check. The semantic disposition remains bounded to the documented raw-hit workflow. |
| Hosted named consumer evidence | HOST-01, HOST-02, PKG-04, REPAIR-01, REPAIR-02 | `ci_monitor closeout` bound the run to the candidate SHA; GitHub job metadata and named scenario log lines were fetched and checked independently, including the advisory Phoenix job. |

## Validation Sign-Off

- [x] All six plan tasks have automated command and result mappings.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 scenarios and acceptance evidence are present.
- [x] No watch-mode flags.
- [x] Focused scenario and core-gate durations were measured and recorded.
- [x] `nyquist_compliant: true` reflects completed local and exact-SHA hosted evidence.

## Unresolved probes and prohibitions

All 11 plan assumption rows retain unresolved status; examples and passing receipts do not answer the broader questions.

| ID | Requirement | Remaining boundary |
|----|-------------|--------------------|
| EA-166-01 | HOST-01 | Synthetic authenticated principal and the named host membership policy only. |
| EA-166-02 | HOST-02 | Deterministic corpus and selected tenant outputs only. |
| EA-166-03 | PKG-04 | Local artifact/path modes on the selected service tuple only. |
| EA-166-04 | REPAIR-01 | General min/max and boundary behavior is unproved. |
| EA-166-05 | REPAIR-01 | Adjacent/equal values and merged scope behavior are unproved. |
| EA-166-06 | REPAIR-01 | Empty scope is checked; malformed/null operator selection is unproved. |
| EA-166-07 | REPAIR-01 | Ranking and tie order are not promised. |
| EA-166-08 | REPAIR-01 | Numeric precision, overflow, and boundary guarantees are unproved. |
| EA-166-09 | REPAIR-02 | The live scenario proves its task/raw result; broader unclassified behavior remains open. |
| EA-166-10 | DELETE-01 | Duplicate delivery and deleting an already-absent record are unproved. |
| EA-166-11 | DELETE-01 | Interrupted/concurrent deletion and recreation ordering are unproved. |

Six descriptor-less prohibitions also remain unresolved: `P-166-HOST-01`, `P-166-HOST-02`, `P-166-REPAIR-01`, `P-166-REPAIR-02`, `P-166-PKG-04`, and `P-166-DELETE-01`. Preserve these flags for Phase 167; the structured receipt check does not resolve them.

**Validation status:** Automated validation and source-bound evidence complete. No post-implementation human UAT is used as a software acceptance gate.

## Validation Audit 2026-09-27

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All six plan tasks remain mapped to passing automated or exact-source evidence. The phase regression gate also passed the current root fast suite in 22.8 seconds: 591 tests, 0 failures (84 excluded).
