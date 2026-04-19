---
phase: 33
status: passed
verified: 2026-04-18
---

# Phase 33 verification

## Goal

Root-facing docs and contract tests agree on **cwd** for the Phoenix example `scripts/smoke.sh`; no implied `./scripts/smoke.sh` from repository root without scoping.

## Must-haves

| Criterion | Evidence |
|-----------|----------|
| `examples/phoenix_meilisearch/scripts/smoke.sh` exists; repo root has no `scripts/smoke.sh` | `File.regular?` / `refute File.regular?` in `docs_contract_test.exs`; shell `test -f` / `test ! -f` |
| README, CONTRIBUTING, golden-path do not teach orphan root `./scripts/smoke.sh` | Doc edits + `rg '\./scripts/smoke\.sh'` shows each hit paired with `cd examples/phoenix_meilisearch` or example-directory context |
| CI contract slice passes | `mix test test/scrypath/docs_contract_test.exs` |

## Human verification

None required for automated closure; optional spot-check: fresh-clone reader sees explicit `cd` before example-local `./scripts/smoke.sh` in README integration paragraph.

## Gaps

None.
