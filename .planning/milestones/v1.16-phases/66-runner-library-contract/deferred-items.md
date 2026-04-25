# Deferred Items

## 2026-04-22

- `mix test test/scrypath/docs_contract_test.exs` fails outside this plan's file scope:
  - `phase 32 AUDT-01 planning hygiene contracts (Nyquist invariants)` expects an `AUDT-01` row in `REQUIREMENTS.md`.
  - `CONTRIBUTING scrypath-ops row matches ci.yml mix ordering (Phase 53)` raises from a stale ordering expectation in `CONTRIBUTING.md` / `ci.yml`.
