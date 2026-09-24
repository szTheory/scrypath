---
phase: "161"
slug: "release-and-tidy-closeout"
status: in_progress
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-24"
updated: "2026-09-24"
---

# Phase 161 — Validation Strategy and Evidence

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit and GitHub Actions |
| **Local runtime** | Elixir 1.19.0 / OTP 28.1 |
| **Hex cache** | `/private/tmp/scrypath-161-hex` |
| **Exact-SHA helper** | `node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"` |

## Task Evidence

| Plan/task | Requirement | Command or authority | Result |
|-----------|-------------|----------------------|--------|
| 161-01 / docs contract | DOC-01, HYGIENE-01 | `mix test test/scrypath/docs_contract_test.exs test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_phoenix_example_package_test.exs` | PASS — 128 tests, 0 failures on merged candidate tree |
| 161-01 / docs build | DOC-01 | `mix docs --warnings-as-errors` | PASS |
| 161-01 / source hygiene | HYGIENE-01 | `git diff --check` | PASS |
| 161-02 / dependency audit | REL-01 | `mix deps.update mint`; lockfile inspection; `mix hex.audit` | PASS — Mint 1.10.1, hpax 1.1.0; no retired packages; affected Mint advisories cleared |
| 161-02 / package proof | DOC-01, REL-01 | `mix verify.package` | PASS — 80 release contract tests, package build and unpack succeeded |
| 161-02 / deep quality | REL-01 | `mix verify.deep_quality` | PASS — Dialyzer 0 errors |
| 161-03 / exact hosted candidate | REL-01, CLOSE-01 | CI workflow dispatch, exact SHA below | PASS — all five required jobs, coverage, closeout attestation, and SHA-bound artifact digests |
| 161-04 / ownership cleanup | HYGIENE-01, CLOSE-01 | Fresh branch/worktree/service/status inventory | PENDING — Plan 04 |
| 161-04 / final SHA | REL-01, CLOSE-01 | Closeout helper after final tracked edits | PENDING — Plan 04 |

### Hosted candidate closeout

- Candidate SHA: `febcd53b96a4ca4d981f45d9902a1abcee5bc631`
- Base `main` SHA: `1ccf353eb6c6e315d57903166431ec63ef1a7fab`
- Branch: `gsd/v1.37-code-quality-ratchet`
- Run: [36038210399](https://github.com/szTheory/scrypath/actions/runs/36038210399)
- Run URL: https://github.com/szTheory/scrypath/actions/runs/36038210399
- Event: `workflow_dispatch`; remote branch and run both matched the candidate SHA.
- Required jobs: `core (required)`, `package (required)`, `repository-contracts (required)`, `backend (required)`, and `ecommerce-mounted (required)` — all successful.
- Advisory lanes: `coverage (advisory)`, `deep-quality (advisory)`, `phoenix-example (advisory)`, and `ecommerce-e2e (advisory)` — all successful. Compatibility advisory lanes succeeded. `ops-ui (path-scoped)` was skipped by its path selector.
- Mint: CI dependency resolution reported Mint 1.10.1; hosted deep-quality completed successfully with Dialyzer `Total errors: 0`. Local `mix hex.audit` reported no retired packages. The previously reported Mint advisories are cleared on this candidate.
- Coverage artifact: ID `10825490951`, digest `sha256:47d4c63939990c214d1eaf1f83b221258ecac1a217af9fc9e6c70377bc6ffd82`, expires `2026-10-01T18:01:53Z`.
- Closeout attestation artifact: ID `10826650035`, digest `sha256:d543a5653c103d7672dd338b887e12bd7a3cbe40f76427e14debb2f900749e98`, expires `2026-10-01T18:05:05Z`.

## Release and PR gates

| Gate | Evidence / status |
|------|-------------------|
| Current release truth | `mix.exs`, `.release-please-manifest.json`, and top `CHANGELOG.md` entry agree on version `0.3.12`; the current release tag is `scrypath-v0.3.12`. |
| New milestone PR | No matching Phase 161 / v1.38 milestone PR exists. Exact submission material is being prepared for the blocking authorization checkpoint. |
| Release Please PR | No open Release Please PR exists. Latest Release Please workflow run is successful on current `main` SHA `1ccf353eb6c6e315d57903166431ec63ef1a7fab`; it did not produce an open release PR. |
| Publisher credential | `HEX_API_KEY` secret name is present in GitHub Actions; its value was not accessed. |
| Publication | No new Phase 161 release has been published. Do not call this milestone shipped. |
| Final disposition | Pending Plan 03 authorization checkpoint and Plan 04 final-SHA/cleanup gates. |

## Manual / external gates

A maintainer must explicitly authorize submission of the prepared milestone PR. Review, merge, a subsequent Release Please version/tag, Hex publication, versioned HexDocs, consumer verification, and package-to-tag parity are external gates. The already-published 0.3.12 release is historical baseline evidence, not Phase 161 publication evidence.
