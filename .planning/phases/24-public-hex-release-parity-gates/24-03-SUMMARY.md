---
phase: 24-public-hex-release-parity-gates
plan: "03"
status: complete
completed: 2026-04-17
---

## Summary — Plan 24-03: Releasing docs, README, UAT drift lock

### Outcome

Updated `docs/releasing.md` for post-publish parity on Release Please and manual recovery workflows; set README install line to `~> 0.3.0`; extended the HexDocs releasing contract test (UAT-06) and aligned `docs_contract_test.exs` with the new README constraint.

### Key files

- `docs/releasing.md`
- `README.md`
- `test/mix/tasks/workflow_wiring_test.exs`
- `test/scrypath/docs_contract_test.exs`

### Deviations

- Plan text referenced “UAT-07” for releasing.md; the in-repo test id is **UAT-06** — assertions were added there.

## Self-Check: PASSED
