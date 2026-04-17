---
phase: 22-operator-polish-drift-recovery-guide
status: passed
verified: 2026-04-17
---

## Verification — Phase 22: Operator Polish + Drift Recovery Guide

### Automated

- **`mix verify.phase22`** — canonical gate for this phase: `failed_work_test.exs`, `docs_contract_test.exs` (includes drift-recovery contract), `package_metadata_test.exs` (HexDocs extras / Operations group), then `mix docs --warnings-as-errors`. Run in CI on every PR (quality job).
- **`mix verify.phase13 --skip-integration`** — broader operator surface (status, reconcile, Oban, `tasks_test.exs`, etc.); still includes `failed_work_test.exs` and `docs_contract_test.exs` as part of its focused list. Live Meilisearch path: `mix verify.phase13` in the `phase13-verification` workflow job.
- `mix test --exclude integration` — full unit matrix remains the net for unrelated regressions.
- `mix compile --warnings-as-errors` — enforced in CI compile step.

### Must-haves (from plans)

| Item | Evidence |
|------|----------|
| OPS-05..08, OPS-10 — `FailedWork` fields, classifier, telemetry | `lib/scrypath/operator/failed_work.ex`, `test/scrypath/operator/failed_work_test.exs` |
| OPS-10 — SRE telemetry table | `docs/search-backend-sre.md` |
| OPS-09 — six-scenario drift runbook + ExDoc + contract | `guides/drift-recovery.md`, `mix.exs`, `test/scrypath/docs_contract_test.exs`, `test/release/package_metadata_test.exs` |

### Human / live

- None required beyond normal doc review; no live Meilisearch dependency added on the default test path.

### Gaps

- None noted for v1.3 scope; `metadata.discard_reason` remains deferred per CONTEXT D-10.

## Self-Check: PASSED
