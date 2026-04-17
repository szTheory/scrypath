---
milestone: v1.2
phase: 14
topic: operator_mix_tasks_and_guides
status: validated
validated: 2026-04-17
---

# v1.2 Phase 14 — Mix tasks and guides — Validation

## Scope

Evidence for **v1.2 Phase 14**: thin `mix scrypath.*` tasks, CLI wiring, and operator-facing docs contracts (`guides/operator-mix-tasks.md`, `docs/operator-support.md`) as enforced by `mix verify.phase14`.

## Runnable tests

**Primary file (REQ VALID-02):**

- `test/scrypath/mix_tasks/operator_tasks_test.exs`

`mix verify.phase14` also runs `test/scrypath/docs_contract_test.exs` and `test/release/package_metadata_test.exs` (see `lib/mix/tasks/verify.phase14.ex` `@focused_tests`).

## `mix verify.phase14`

```bash
mix verify.phase14
```

**Local capture (2026-04-17, `HEAD` = `2c303eb87e4ba30981bd2c129e20252954cdb7e0`, Elixir 1.19.5 / OTP 28):**

```text
Finished in 0.1 seconds (0.1s async, 0.03s sync)
27 tests, 0 failures
==> Building docs with warnings as errors
Generating docs...
```

Exit code: `0`.

### CI receipt (authoritative)

- **Workflow:** `.github/workflows/ci.yml`  
- **Job:** `quality`  
- **Run (success on `main`):** https://github.com/szTheory/scrypath/actions/runs/24581329311  
- **Commit:** `2c303eb87e4ba30981bd2c129e20252954cdb7e0`

**Excerpt from CI log (`mix verify.phase14`):**

```text
==> Running Phase 14 task and docs contract tests
...
27 tests, 0 failures
```

## Drift protocol

Re-run `mix verify.phase14` on `main` and attach a new green `quality` run when behavior or test counts change materially.
