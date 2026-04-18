---
phase: 27
status: passed
verified: 2026-04-17
---

# Phase 27 Verification — Schema–index drift report (read-only)

## Automated

- `mix format --check-formatted` — pass
- `mix compile --warnings-as-errors` — pass
- `mix test --warnings-as-errors` — pass (348 tests)

## Must-haves (from plans)

| ID | Check | Result |
|----|--------|--------|
| OPS15-01 | `Scrypath.index_contract_drift/2` delegates to operator and returns `{:ok, %Report{}} \| {:error, term()}` | Pass |
| DRIFT15-01 | Settings dimension uses `Settings.resolve/2`, `translate_settings/1`, `compute_drift/2` on same live settings map | Pass |
| DRIFT15-02 | Dimensions expose `match` and structured `details` on mismatch | Pass |
| D-04–D-06 | Optional `include_index_contract_drift`; same builder; `@enforce_keys` unchanged | Pass |

## Human

- None required for this phase (read-only library surface; no live cluster in CI).

## Notes

- `gsd-sdk query` CLI is not available in this workspace; phase tracking updates were applied manually in `STATE.md` / `ROADMAP.md`.
