---
phase: "161"
slug: "release-and-tidy-closeout"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-24"
updated: "2026-09-25"
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
| 161-04 / final SHA | REL-01, CLOSE-01 | Closeout helper after final tracked edits | Final exact-SHA run and artifacts are retained in `/private/tmp/scrypath-161-final-closeout.json`; no tracked edits follow the run. |

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

## Release and PR gates — refreshed after publication

| Gate | Evidence / status |
|------|-------------------|
| Current release truth | `mix.exs`, `.release-please-manifest.json`, changelog, and tag agree on `0.3.13` / `scrypath-v0.3.13`. |
| Phase 161 PR | [#77](https://github.com/szTheory/scrypath/pull/77), merged as `465aef9bc6c9c05fb021b5aa3d5b6b584aed568d`; exact-head CI and post-merge `main` CI passed. Maintainer authorized squash merge after checks; no GitHub review object was submitted. |
| Release Please PR | [#78](https://github.com/szTheory/scrypath/pull/78), exact-head required CI passed; merged as `28d3877a05479f2cc104754fc24ab0c9d545c01b`. |
| Release workflow | [Run 36083655678](https://github.com/szTheory/scrypath/actions/runs/36083655678) succeeded. Package job passed `mix verify.package`, dry-run, Hex publish, `mix verify.release_publish 0.3.13`, and `mix verify.release_parity 0.3.13`. |
| Publisher credential | `HEX_API_KEY` was available to the scoped publish job; its value was not accessed. |
| Publication | GitHub release and Hex `0.3.13` were published on 2026-09-25; versioned HexDocs, consumer compile, and tag/package parity passed. |
| Final disposition | `shipped`; no human UAT or release blocker remains. |

## Validation audit 2026-09-25

| Metric | Count |
|--------|-------|
| Nyquist requirement behaviors mapped to automated unit, docs-contract, package, integration, or exact-SHA release evidence | 4 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated to manual-only | 0 |

## Automated Evidence Map

| Requirement | Automated verification | Result |
|-------------|------------------------|--------|
| DOC-01 | Docs contract tests in required package/core verification; Release Please publish job also ran the package gate | Pass |
| HYGIENE-01 | Repository contracts, exact-SHA evidence and release workflow clean-workspace gate | Pass |
| REL-01 | PR #78 exact-head CI, post-merge main CI, Release Please publish job, `verify.release_publish`, and `verify.release_parity` | Pass |
| CLOSE-01 | Cleanup inventory and preservation record in `161-RELEASE-EVIDENCE.md`; post-merge verification | Pass |

No human-facing UAT was needed. Maintainer merge authorization was the only external decision; all software acceptance and publication checks ran automatically.
