---
phase: 24-public-hex-release-parity-gates
status: passed
verified: 2026-04-17
---

## Verification — Phase 24: Public Hex release & parity gates

### Automated

- `jq empty release-please-config.json`
- `mix format --check-formatted`
- `mix test test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors`
- `mix test test/scrypath/docs_contract_test.exs --warnings-as-errors`
- `mix test --exclude integration --warnings-as-errors` — one intermittent failure observed in `FailedWorkTest` on a parallel run; the same test passed on immediate rerun (pre-existing flake, not introduced by Phase 24 edits).

### Must-haves (from plans)

| Item | Evidence |
|------|----------|
| SHIP-01 — pre-1.0 Release Please bump keys | `release-please-config.json`, UAT-09 in `workflow_wiring_test.exs` |
| SHIP-03 — `release_parity` after `release_publish` on both publish workflows | `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`, `describe "SHIP-03"` in `workflow_wiring_test.exs` |
| SHIP-02 — README + contracts on current line | `README.md`, `docs_contract_test.exs`, UAT-06 extensions in `workflow_wiring_test.exs` |
| Maintainer docs parity narrative | `docs/releasing.md` |

### Human / live

- None required for this slice (workflow YAML is contract-tested; live Actions runs when merged).

### Gaps

- None for the three executed plans. Actual Hex `0.3.1` publish and manifest/version bumps remain on the Release Please release PR path (per plan scope).

## Self-Check: PASSED
