---
milestone: v1.2
phase: 13
topic: operator_primitives
status: validated
validated: 2026-04-17
---

# v1.2 Phase 13 — Operator primitives — Validation

## Scope

Evidence for **v1.2 operator primitives**: `Scrypath.Operator` status/failed-work/reconcile surfaces exercised by focused tests and by `mix verify.phase13` (without integration: default CI gate; with integration: live operator module).

Out of scope: Hex package contents vs `main` divergence (documented separately in the milestone audit).

## Runnable tests (operator-only slice)

Primary operator contract files:

- `test/scrypath/operator/status_test.exs`
- `test/scrypath/operator/failed_work_test.exs`
- `test/scrypath/operator/reconcile_test.exs`

**Command (fast slice, no live Meilisearch):**

```bash
mix test \
  test/scrypath/operator/status_test.exs \
  test/scrypath/operator/failed_work_test.exs \
  test/scrypath/operator/reconcile_test.exs \
  --exclude integration
```

**Local capture (2026-04-17, `HEAD` = `2c303eb87e4ba30981bd2c129e20252954cdb7e0`, Elixir 1.19.5 / OTP 28):**

```text
Finished in 0.2 seconds (0.2s async, 0.00s sync)
15 tests, 0 failures
```

Exit code: `0`.

## `mix verify.phase13 --skip-integration`

This is the **same command** the `quality` job runs after `mix verify.phase11` (see `.github/workflows/ci.yml`).

```bash
mix verify.phase13 --skip-integration
```

Focused paths are defined in `lib/mix/tasks/verify.phase13.ex` (`@focused_tests`), including the three operator test modules above plus related operator/oban/docs contract tests and `mix docs --warnings-as-errors`.

### CI receipt (authoritative for merge `2c303eb`)

- **Workflow:** `.github/workflows/ci.yml`  
- **Job:** `quality`  
- **Run (success on `main`):** https://github.com/szTheory/scrypath/actions/runs/24581329311  
- **Commit:** `2c303eb87e4ba30981bd2c129e20252954cdb7e0`

**Excerpt from CI log (`mix verify.phase13 --skip-integration`):**

```text
Finished in 7.2 seconds (7.2s async, 0.00s sync)
68 tests, 0 failures
```

(Excludes integration-tagged examples; matches CI `quality` Elixir 1.19.0 / OTP 28.1 matrix row.)

## Live operator path

Live Meilisearch-backed assertions live in `test/scrypath/live_operator_verification_test.exs` and run as part of **`mix verify.phase13`** (no `--skip-integration`). Evidence for that slice is centralized in [`15-VALIDATION.md`](15-VALIDATION.md) so Phase 13 vs 15 boundaries stay clear.

## Drift protocol

When this document’s counts or commands no longer match CI, **regenerate**: re-run the commands on a clean tree, update excerpts, and point to a **new** green Actions run on `main` (keep the old run link in git history via the commit that updated this file).
