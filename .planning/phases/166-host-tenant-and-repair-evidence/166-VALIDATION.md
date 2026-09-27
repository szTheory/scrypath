---
phase: "166"
slug: "host-tenant-and-repair-evidence"
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Estimated runtime** | Unmeasured; record the first focused run rather than assume a duration |

Live acceptance requires the configured Postgres/Meilisearch tuple or the existing hosted advisory Phoenix lane. Local Postgres availability alone does not identify its database or credentials; local Meilisearch was unavailable during research. Do not record live acceptance from Req.Test or an unverified local service.

## Sampling Rate

- **After every task commit:** Run that task's focused test or source-freshness command.
- **After each plan wave:** Run the applicable root fast suite or Phoenix consumer scenario for both dependency modes.
- **Before `$gsd-verify-work`:** Complete the exact named live/service and package evidence for the accepted claims, or record the bounded result as UNKNOWN when execution is unavailable.
- **Max feedback latency:** Unmeasured; record focused command durations during execution.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 166-01-01 | 01 | 1 | HOST-01, HOST-02 | T-166-01 | Host membership controls trusted scope; raw hits, hydrated records, counts, and facets exclude foreign tenant data | Phoenix/Postgres/Meilisearch integration | `mix verify.phoenix_example` | Existing consumer harness; scenario to add | pending |
| 166-01-02 | 01 | 1 | PKG-04 | T-166-01 | Same named host scenario passes with repository path and freshly built package artifact | Consumer package integration | `mix verify.phoenix_example --package` | Existing package harness; scenario to add | pending |
| 166-02-01 | 02 | 1 | REPAIR-01 | T-166-02 | Read-only mismatch report causes no write; manual backfill affects only the explicit selected IDs | ExUnit/live backend integration | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/live_operator_verification_test.exs` | Existing file; scenario to add | pending |
| 166-02-02 | 02 | 1 | REPAIR-02 | T-166-02 | Exact returned task succeeds on expected index and the same Scrypath query shows the repaired ID/value while controls remain correct | ExUnit/Meilisearch integration | `mix verify.backend` | Existing backend verification surface; scenario to add | pending |
| 166-02-03 | 02 | 1 | DELETE-01 | T-166-03 | Receipt reuse is source-bound; a relevant invalidator requires fresh evidence or UNKNOWN | Deterministic source comparison plus receipt review | `git diff --name-only dc400b2b57aec0ca6b0ef16c9477d266fd41a433...HEAD -- lib examples config test/support .github/workflows mix.exs mix.lock` | Existing receipt; comparison to repeat at final SHA | pending |

The plan checker may adjust plan/task IDs and split tasks while retaining this requirement-to-proof mapping. The existing Phoenix package task stages the same consumer and runs the suite against the package artifact; retain its current advisory CI posture and do not add a required lane.

## Wave 0 Requirements

- [ ] Extend `examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs` with the persisted synthetic actor/membership scenario and both raw and hydrated data assertions.
- [ ] Extend `test/scrypath/live_operator_verification_test.exs` with the known mismatch, no-write report, selected-ID repair, exact task, and visible-search assertions.
- [ ] Reuse existing fixtures, task polling, SQL Sandbox/service setup, diagnostics, cleanup, and package harness; no framework or dependency installation is needed.
- [ ] Establish or identify the exact live Postgres/Meilisearch service tuple and credentials without recording secrets; use exact-SHA hosted evidence if the local tuple cannot be verified.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final-SHA C-09 receipt disposition | DELETE-01 | Historical receipt identity and current source freshness must be compared at the final assessment SHA | Repeat the relevant-path comparison against the final SHA; reuse only if no semantic invalidator exists, otherwise capture targeted evidence or record UNKNOWN. |
| Hosted named consumer evidence | PKG-04 | Exact commit, advisory job, dependency mode, service tuple, and task/run identifiers are hosted execution metadata | Confirm the named scenario passed in both modes on the recorded exact SHA; preserve the job's advisory status. |

## Validation Sign-Off

- [ ] All plan tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing scenario references.
- [ ] No watch-mode flags.
- [ ] Focused command feedback latency recorded from execution.
- [ ] `nyquist_compliant: true` set only after validation evidence exists.

**Approval:** pending
