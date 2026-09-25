# Deferred Items

## 2026-04-22

status: resolved

- **Resolution (2026-09-23):** The original AUDT-01 and CONTRIBUTING ordering assertions now pass. The docs-contract suite exposed one related stale assertion that still expected the Phase 97 anchor in the root roadmap index; updated it to check the canonical v1.30 roadmap archive. Verified with `mix test test/scrypath/docs_contract_test.exs`: 70 tests, 0 failures.

- `mix test test/scrypath/docs_contract_test.exs` fails outside this plan's file scope:
  - `phase 32 AUDT-01 planning hygiene contracts (Nyquist invariants)` expects an `AUDT-01` row in `REQUIREMENTS.md`.
  - `CONTRIBUTING scrypath-ops row matches ci.yml mix ordering (Phase 53)` raises from a stale ordering expectation in `CONTRIBUTING.md` / `ci.yml`.
