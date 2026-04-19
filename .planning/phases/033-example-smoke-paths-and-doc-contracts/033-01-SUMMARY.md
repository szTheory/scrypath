---
phase: 33
plan: 01
status: complete
completed: 2026-04-18
---

# Plan 033-01 Summary

## Objective

Aligned root-facing **README**, **CONTRIBUTING**, and **guides/golden-path.md** with filesystem truth for the Phoenix example smoke script (`examples/phoenix_meilisearch/scripts/smoke.sh` only; no repo-root `scripts/smoke.sh`), using **Pattern A** (`cd examples/phoenix_meilisearch && ./scripts/smoke.sh`). Extended **`Scrypath.DocsContractTest`** with filesystem and ordering contracts (Phase 33).

## Tasks completed

1. **README** — Integration smoke paragraph now instructs clone-root readers to `cd` into the example before `./scripts/smoke.sh`.
2. **CONTRIBUTING** — `phoenix-example-integration` row local approximation uses the same scoped smoke command.
3. **guides/golden-path.md** — Runbook bullet names **`examples/phoenix_meilisearch/`** as cwd before `./scripts/smoke.sh`; second bullet unchanged (Phase 34 deferral).
4. **docs_contract_test.exs** — Added three tests: script path layout, README/CONTRIBUTING cwd pairing, golden-path ordering + `optional CI wiring` anchor.

## Key files

- `README.md`
- `CONTRIBUTING.md`
- `guides/golden-path.md`
- `test/scrypath/docs_contract_test.exs`

## Verification

- `mix test test/scrypath/docs_contract_test.exs` — pass
- `mix format --check-formatted` — pass

## Deviations

- **`workflow_wiring_test.exs` UAT-09:** Post-merge suite run showed `git log -50` no longer included the phase **18** closing commit subject (branch depth). Widened the log window to **120** entries and re-ran **`mix test --exclude integration`** successfully.

## Self-Check: PASSED
