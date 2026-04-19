---
phase: 30
status: passed
verified: 2026-04-18
---

# Phase 30 Verification

## Automated (root repo)

| Check | Result |
|--------|--------|
| `mix format --check-formatted` | Pass |
| `mix test test/scrypath/docs_contract_test.exs --exclude integration` | Pass |

## Example app (`examples/phoenix_meilisearch`)

| Check | Result |
|--------|--------|
| `mix compile` (with **`{:oban, "~> 2.21"}`** + **`ScrypathDemo.Oban`**) | Pass (local / CI) |
| `SCRYPATH_EXAMPLE_INTEGRATION=1 mix test` with Postgres + Meilisearch | **CI:** GitHub Actions job **`phoenix-example-integration`** in **`.github/workflows/ci.yml`**. **Local:** **`./scripts/smoke.sh`** or Compose + env per example README |

## Must-haves (requirements)

| REQ-ID | Evidence | Status |
|--------|----------|--------|
| **EXAM-01** | `test/smoke/meilisearch_oban_stack_test.exs` + Oban migration + supervision | Pass |
| **EXAM-02** | Example README env table; golden path pointer; CONTRIBUTING CI row; README + releasing cross-links | Pass |

## Notes

- **`test/release/consumer_smoke_test.exs`** unchanged by design (packaging rail vs live example).
