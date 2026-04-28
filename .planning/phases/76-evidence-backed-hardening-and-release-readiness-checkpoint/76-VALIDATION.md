---
phase: 76
plan: 01
slug: evidence-backed-hardening-and-release-readiness-checkpoint
status: complete
created: 2026-04-28
updated: 2026-04-28
---

# Phase 76 Validation Ledger

Append-only ledger for the bounded Phase 76 evidence window. Only evidence from `mix verify.adopter`, `mix verify.adopter --live`, or a structured adopter-intake report may enter this file.

## Evidence Window

- Fast proof command: `mix verify.adopter`
- Live proof command: `mix verify.adopter --live`
- Structured intake reviewed: none beyond the canonical template; no real or rehearsal adopter report was present for this plan

## Ledger Rows

| ID | Evidence handle | Source | User-facing failure or confusion | Admissibility | Proposed bounded fix seam | Recurrence guard seam | Disposition |
|----|-----------------|--------|----------------------------------|---------------|---------------------------|-----------------------|-------------|
| 76-01-E01 | `fast-2026-04-28/mix-verify-adopter/pass` | fast | None surfaced. Fast readiness contracts and task-surface tests passed cleanly. | admissible | none | none | deferred |
| 76-01-E02 | `live-2026-04-28/mix-verify-adopter-live/missing-env` | live | `mix verify.adopter --live` stops on missing `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL`. This is the documented contract and not a new papercut on its own. | admissible | none | none | deferred |
| 76-01-E03 | `live-2026-04-28/mix-verify-adopter-live/env-set-db-refused` | live | After supplying the documented env contract, the root live proof fell through to a deep `DBConnection.ConnectionError` instead of failing fast with an explicit "services are not running" prerequisite message. Fixed by adding a root-task reachability preflight before `mix deps.get` or example boot. | admissible | `lib/mix/tasks/verify.adopter.ex` live preflight and wording | `test/mix/tasks/verify_adopter_test.exs` (`raises clearly when live services are unreachable`) | accepted |
| 76-01-E04 | `live-2026-04-28/mix-verify-adopter-live/runtime-blocked-then-passed` | live | Full live verification was initially blocked because Postgres and Meilisearch services were not running under the expected example contract. After starting the documented example services with `docker compose up -d`, the same live proof passed without additional code changes. | admissible | none; execution-environment precondition already documented by the example proof path | none | deferred |

## Working Notes

- Accepted papercuts are capped at three. Current accepted count: `1`.
- No inadmissible maintainer-only cleanup entered scope.
- No fourth papercut was accepted.

## Verification Results

- `mix test test/mix/tasks/verify_adopter_test.exs` -> passed after the accepted fix
- `mix test test/scrypath/readiness_contract_test.exs test/mix/tasks/verify_adopter_test.exs && mix verify.adopter` -> passed
- `mix verify.adopter --live` with no env -> blocked as documented by missing `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL`
- `SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.adopter --live` -> passed after starting the documented example Postgres and Meilisearch services with `docker compose up -d` from `examples/phoenix_meilisearch`

## Freeze Summary

- Evidence window status: closed
- Accepted papercuts: `1`
- Deferred items: `3`
- Blockers: `0`
- Adopter-intake evidence class used: template only; no outside adopter report and no internal rehearsal report for this plan
