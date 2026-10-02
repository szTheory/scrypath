# Phase 168 Plan 02 Summary

## Objective

Resolve the approved Mint security correction independently in all four maintained Mix graphs and prove the existing root, backend, mounted ecommerce, and Ops behavior on that committed graph.

## Completed tasks

- Refreshed Hex Mint/HPAX release metadata and queried OSV against the Mint versions currently published in Hex. The resulting inventory contains 14 distinct Mint EEF CVEs; Mint 1.10.1 matched three current advisories and Mint 1.11.0 matched none. The full advisory table and source links are in [168-02-GRAPHS.md](168-02-GRAPHS.md).
- Started a task-owned clone at public `main` SHA `ad73b92d5883b4136fa961e134c987a95939fac2`, confirmed it clean, and committed the focused graph change as `d4976944e8049699f31dc6769cd68d719bc4a814` on `fix/phase168-dependency-security`.
- Updated Mint to 1.11.0 in all four locks and HPAX to 1.1.0 in the three graphs that needed it. Amended the plan narrowly for retired optional Sigra 1.20.0: its Ops constraint now follows Hex's `~> 1.5.0` retirement guidance. No other lock or manifest entries changed.
- The four `mix deps.get --check-locked` and `mix hex.audit` pairs passed in 8 seconds on the warm-cache pass; all audits reported no retired packages, and committed lock bytes stayed fixed.
- Root behavior passed (574 tests); live backend passed (7 tests); mounted ecommerce passed (4 Playwright checks); standalone Ops passed (2 doctests and 154 tests). All evidence is source-bound in the graph record.

## Verification

- `git diff --check` passed before commit; candidate contains exactly five selected files.
- Four-graph strict fetch/audit passed with all five selected SHA-256 values retained after the behavior runs.
- `mix test --exclude integration --exclude docs_contract`: 574 tests, 0 failures.
- `mix verify.backend`: 7 integration tests, 0 failures.
- `mix verify.ecommerce_mounted`: 4 Playwright checks passed; owned Docker resources were removed.
- `mix verify.ops_ui`: 2 doctests, 154 tests, 0 failures. The clean rerun took 5 seconds; its database service was task-owned and stopped after the proof.

## Follow-up

The graph record describes repository-owned locks only. Phoenix path/package graph identity, the recurring four-graph audit implementation, the candidate PR, named hosted advisory/Ops results, merge, and post-merge evidence remain in Plans 03–05. No adopter lockfile or Hex publication is claimed.
