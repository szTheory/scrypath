---
phase: "161"
slug: "release-and-tidy-closeout"
status: release-ready
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
| 161-03 / PR checks | REL-01 | Pull request #77 checks on its exact head SHA | PASS — all required checks and other running PR checks succeeded; coverage/E2E are skipped on pull_request and passed in the exact-SHA dispatch run |
| 161-04 / ownership cleanup | HYGIENE-01, CLOSE-01 | Fresh branch/worktree/service/status inventory | PASS — only previously-owned branch remains for open PR; task-owned temp/generated output removed; unrelated dirt preserved |
| 161-04 / final SHA | REL-01, CLOSE-01 | Closeout helper after final tracked edits | SCHEDULED — run after the final evidence/summary commit; receipt retained outside tracked files |

### Hosted candidate closeout

- Initial candidate SHA: `febcd53b96a4ca4d981f45d9902a1abcee5bc631`; base `main` SHA: `1ccf353eb6c6e315d57903166431ec63ef1a7fab`.
- PR/final-pre-evidence candidate SHA: `3053efcf06bf574d599e3969385dfd904d31ca53`.
- Branch: `gsd/v1.37-code-quality-ratchet`.
- Initial exact-SHA run: [36038210399](https://github.com/szTheory/scrypath/actions/runs/36038210399).
- Refreshed exact-SHA run on the PR source SHA: [36039689035](https://github.com/szTheory/scrypath/actions/runs/36039689035) — success.
- PR check run on that same SHA: [36046106195](https://github.com/szTheory/scrypath/actions/runs/36046106195) — all five required checks and running advisory checks succeeded; coverage and E2E skipped for the pull_request event, but both passed in run 36039689035.
- Event: `workflow_dispatch`; remote branch and run both matched the candidate SHA.
- Required jobs: `core (required)`, `package (required)`, `repository-contracts (required)`, `backend (required)`, and `ecommerce-mounted (required)` — all successful.
- Advisory lanes: `coverage (advisory)`, `deep-quality (advisory)`, `phoenix-example (advisory)`, and `ecommerce-e2e (advisory)` — all successful. Compatibility advisory lanes succeeded. `ops-ui (path-scoped)` was skipped by its path selector.
- Mint: CI dependency resolution reported Mint 1.10.1; hosted deep-quality completed successfully with Dialyzer `Total errors: 0`. Local `mix hex.audit` reported no retired packages. The previously reported Mint advisories are cleared on this candidate.
- Refreshed closeout coverage artifact: ID `10826796367`, digest `sha256:9c2f7bbcad2b091ded76718bf0d70869eed7325a40dae94790841d40e45ccfc5`, expires `2026-10-01T18:13:50Z`.
- Refreshed closeout attestation artifact: ID `10826671760`, digest `sha256:8b1d6b82e4505916f3b584f17be0f2b637354c3f748e50a968b5956f000d21b2`, expires `2026-10-01T18:16:48Z`.
- Refreshed run receipt is also retained outside tracked files at `/private/tmp/scrypath-161-closeout-3053efc.json`.

## Release and PR gates

| Gate | Evidence / status |
|------|-------------------|
| Current release truth | `mix.exs`, `.release-please-manifest.json`, and top `CHANGELOG.md` entry agree on version `0.3.12`; the current release tag is `scrypath-v0.3.12`. |
| New milestone PR | [#77](https://github.com/szTheory/scrypath/pull/77), open; base `main`, head `gsd/v1.37-code-quality-ratchet`; PR_CREATED_SHA and PR_REVIEW_SHA are `3053efcf06bf574d599e3969385dfd904d31ca53`. |
| Release Please PR | No open Release Please PR exists. Latest Release Please workflow run is successful on current `main` SHA `1ccf353eb6c6e315d57903166431ec63ef1a7fab`; it did not produce an open release PR. |
| Publisher credential | `HEX_API_KEY` secret name is present in GitHub Actions; its value was not accessed. |
| Publication | No new Phase 161 release has been published. Do not call this milestone shipped. |
| Review / merge | PR #77 has no submitted review or review comments; all required checks pass and merge state is clean. It is not merged. Human review and merge authorization remain external. |
| Final disposition | `release-ready`; Phase 161 is not shipped. Final-SHA closeout runs after the summary/evidence commit, with its receipt retained externally. |

## Manual / external gates

A maintainer authorized submission of PR #77. A real review and merge decision, a subsequent Release Please version/tag, Hex publication, versioned HexDocs, consumer verification, and package-to-tag parity remain external gates. The already-published 0.3.12 release is historical baseline evidence, not Phase 161 publication evidence.
