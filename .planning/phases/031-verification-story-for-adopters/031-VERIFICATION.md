---
phase: 31
status: passed
verified: 2026-04-18
---

# Phase 31 Verification

## Requirements (VRFY-01, VRFY-02)

| REQ | Evidence | Status |
|-----|----------|--------|
| **VRFY-01** | [`CONTRIBUTING.md`](../../../CONTRIBUTING.md) CI table (**Job \| Purpose**) maps **`test`**, **`quality`**, **`phase5-verification`**, **`phase13-verification`**, **`meilisearch-smoke`**, **`phoenix-example-integration`** to what each gate exercises | Pass |
| **VRFY-02** | Same table + **Verification** section document **`mix test --exclude integration`** as the default path; integration jobs use live Meilisearch (and Postgres for the example job); [`test/scrypath/docs_contract_test.exs`](../../../test/scrypath/docs_contract_test.exs) asserts CONTRIBUTING and [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml) stay aligned | Pass |

## Automated

| Check | Result |
|--------|--------|
| `mix test test/scrypath/docs_contract_test.exs --exclude integration` | Pass |
| GitHub Actions **`phoenix-example-integration`** | Runs `examples/phoenix_meilisearch` **`mix test`** with Postgres + Meilisearch on every PR |

## Notes

- Phase 30 example smoke is no longer maintainer-only; CI owns the same **`SCRYPATH_EXAMPLE_INTEGRATION=1`** path as local Compose / **`./scripts/smoke.sh`**.
