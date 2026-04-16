---
phase: 11-public-release-contract
verified: 2026-04-16T21:05:00Z
status: human_needed
score: 5/8 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Run the canonical GitHub release flow for a real version"
    expected: "Release Please creates vX.Y.Z, publish-hex checks out tag_name, Hex shows the same version, and the tag/changelog/manifest/package state all agree"
    why_human: "This depends on GitHub Actions and Hex publishing, which are external systems not exercised by local verification"
  - test: "Verify the published package from a throwaway consumer app"
    expected: "A fresh app using {:scrypath, \"~> X.Y.Z\"} runs mix deps.get, mix compile, and the minimal use Scrypath schema compiles successfully"
    why_human: "The automated smoke test uses the locally built package artifact via a tagged local git repo, not the live published Hex package"
  - test: "Confirm the versioned HexDocs page is reachable after publish"
    expected: "curl -Ifs https://hexdocs.pm/scrypath/X.Y.Z returns success for the released version"
    why_human: "HexDocs reachability is an external service check and is only documented, not programmatically exercised here"
---
# Phase 11: Public Release Contract Verification Report

**Phase Goal:** Maintainers can trust the canonical release path because tag, changelog, package version, Hex artifact state, and clean-consumer verification all line up under one repeatable contract.
**Verified:** 2026-04-16T21:05:00Z
**Status:** human_needed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Maintainer can cut a release from the canonical GitHub flow and confirm the tag, changelog, manifest, package version, and Hex artifact all agree. | ? UNCERTAIN | Local contract checks exist in [lib/mix/tasks/verify.phase11.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex#L22) and the workflow publishes from `tag_name` in [.github/workflows/release-please.yml](/Users/jon/projects/scrypath/.github/workflows/release-please.yml#L34), but no real GitHub Actions or Hex publish run was exercised. |
| 2 | Maintainer can install the published package in a clean consumer flow, reach HexDocs, and run a basic Scrypath usage path successfully. | ? UNCERTAIN | The local consumer proof compiles from a packaged artifact in [test/release/consumer_smoke_test.exs](/Users/jon/projects/scrypath/test/release/consumer_smoke_test.exs#L6), and the manual published-package and HexDocs steps are documented in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L47), but the live published package and HexDocs page were not exercised. |
| 3 | Maintainer can follow one documented recovery path for tag or version drift, failed publish attempts, and published-artifact mismatch without ad hoc spelunking. | ✓ VERIFIED | Recovery runbooks are documented in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L93) and enforced by [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L135). |
| 4 | Maintainer can prove the repo's declared release version, tag ref, and package metadata all describe the same package release. | ✓ VERIFIED | Version-derived metadata is defined in [mix.exs](/Users/jon/projects/scrypath/mix.exs#L4) and asserted exactly in [test/release/package_metadata_test.exs](/Users/jon/projects/scrypath/test/release/package_metadata_test.exs#L14). |
| 5 | Maintainer has one automated command that fails when release metadata or workflow wiring drifts. | ✓ VERIFIED | `mix verify.phase11` runs release tests, docs build, manifest/workflow checks, and local package assembly in [lib/mix/tasks/verify.phase11.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex#L22). I ran `mix verify.phase11` successfully. |
| 6 | Release-facing links no longer point at moving main-branch targets for release artifacts. | ✓ VERIFIED | Release links are version-scoped in [mix.exs](/Users/jon/projects/scrypath/mix.exs#L94) and the exact URLs are locked by [test/release/package_metadata_test.exs](/Users/jon/projects/scrypath/test/release/package_metadata_test.exs#L23). |
| 7 | Maintainer can prove Scrypath works from a clean consumer app before trusting the public release. | ✓ VERIFIED | The smoke harness builds a package artifact, creates a throwaway app with `mix new`, installs Scrypath without a `path:` dependency, and compiles a `use Scrypath` schema in [test/release/consumer_smoke_test.exs](/Users/jon/projects/scrypath/test/release/consumer_smoke_test.exs#L16). |
| 8 | Maintainer has concrete recovery runbooks for tag/version drift, failed publish, and artifact mismatch. | ✓ VERIFIED | The canonical flow plus all three recovery sections are present in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L23) and enforced by [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L135). |

**Score:** 5/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `mix.exs` | Version-derived package and docs metadata for the public package contract | ✓ VERIFIED | Defines `@version`, `@source_ref`, versioned HexDocs links, and registers `verify.phase11` in [mix.exs](/Users/jon/projects/scrypath/mix.exs#L4). |
| `test/release/package_metadata_test.exs` | Exact assertions for release-aware package metadata | ✓ VERIFIED | Asserts GitHub, HexDocs, changelog, and guides links from `MixProject.project/0` in [test/release/package_metadata_test.exs](/Users/jon/projects/scrypath/test/release/package_metadata_test.exs#L14). |
| `lib/mix/tasks/verify.phase11.ex` | Canonical automated Phase 11 release-contract verification entrypoint | ✓ VERIFIED | Wires release tests, docs build, workflow checks, manifest alignment, and `hex.build --unpack` in [lib/mix/tasks/verify.phase11.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex#L22). |
| `test/release/consumer_smoke_test.exs` | Automated clean-consumer smoke harness for the documented quick path | ✓ VERIFIED | Builds a local artifact, wraps it in a tagged git repo, and compiles a fresh consumer app in [test/release/consumer_smoke_test.exs](/Users/jon/projects/scrypath/test/release/consumer_smoke_test.exs#L6). |
| `docs/releasing.md` | Canonical release and recovery runbooks for maintainers | ✓ VERIFIED | Documents the gate, canonical flow, and three recovery runbooks in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L5). |
| `test/scrypath/docs_contract_test.exs` | Doc contract assertions for release runbooks and manual public checks | ✓ VERIFIED | Enforces release-gate, HexDocs, and recovery wording in [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L116). |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `mix.exs` | `test/release/package_metadata_test.exs` | `MixProject.project/0` assertions for exact package/docs link values | ✓ WIRED | The test aliases `Scrypath.MixProject` and asserts `MixProject.project()` package links in [test/release/package_metadata_test.exs](/Users/jon/projects/scrypath/test/release/package_metadata_test.exs#L4). |
| `lib/mix/tasks/verify.phase11.ex` | `.release-please-manifest.json` | manifest/version alignment shell check | ✓ WIRED | `validate_release_contract!/0` compares `@version` in `mix.exs` with `.release-please-manifest.json` in [lib/mix/tasks/verify.phase11.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex#L59). |
| `lib/mix/tasks/verify.phase11.ex` | `.github/workflows/release-please.yml` | same-workflow publish contract validation | ✓ WIRED | The grep contract check looks for `release_created`, `tag_name`, and `mix hex.publish --yes`, and the workflow contains them in [.github/workflows/release-please.yml](/Users/jon/projects/scrypath/.github/workflows/release-please.yml#L21). |
| `test/release/consumer_smoke_test.exs` | `README.md` | compiled clean-consumer schema mirrors the documented quick path | ✓ WIRED | The smoke schema uses `use Scrypath` with the documented fields/filterable/sortable shape in [test/release/consumer_smoke_test.exs](/Users/jon/projects/scrypath/test/release/consumer_smoke_test.exs#L81), matching the documented quick path. |
| `docs/releasing.md` | `test/scrypath/docs_contract_test.exs` | runbook section headings and concrete commands asserted in docs contract tests | ✓ WIRED | The docs define all required headings and commands in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L93), and the contract test asserts them in [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L135). |
| `lib/mix/tasks/verify.phase11.ex` | `test/release/consumer_smoke_test.exs` | Phase 11 verification runs the clean-consumer smoke automatically | ✓ WIRED | `mix verify.phase11` includes `test/release/consumer_smoke_test.exs` in [lib/mix/tasks/verify.phase11.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex#L26). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `mix.exs` | `@source_ref`, `@release_docs_url`, `package[:links]` | `@version` in [mix.exs](/Users/jon/projects/scrypath/mix.exs#L4) | Yes - release URLs are derived from the declared version and surfaced through `MixProject.project/0` | ✓ FLOWING |
| `test/release/consumer_smoke_test.exs` | `tag`, generated consumer dependency, compiled beam file | `MixProject.project()[:version]` and local `mix hex.build --unpack` in [test/release/consumer_smoke_test.exs](/Users/jon/projects/scrypath/test/release/consumer_smoke_test.exs#L6) | Yes - the test builds a real package artifact and compiles a real throwaway app | ✓ FLOWING |
| `docs/releasing.md` contract | Recovery headings and release commands | Literal runbook content enforced by [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L135) | Yes - the assertions fail if required commands or headings disappear | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Release metadata contract tests pass | `mix test test/release/package_metadata_test.exs` | `3 tests, 0 failures` | ✓ PASS |
| Clean-consumer smoke harness passes | `mix test test/release/consumer_smoke_test.exs` | `2 tests, 0 failures` | ✓ PASS |
| Release docs contract passes | `mix test test/scrypath/docs_contract_test.exs` | `11 tests, 0 failures` | ✓ PASS |
| Canonical Phase 11 gate passes | `mix verify.phase11` | release tests passed, docs built, workflow contract validated, `hex.build --unpack` succeeded | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| REL-01 | 11-01-PLAN.md | Maintainer can publish Scrypath from the canonical GitHub release flow with aligned tag, changelog, manifest, package version, and Hex artifact state. | ? NEEDS HUMAN | Local alignment is enforced by [lib/mix/tasks/verify.phase11.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex#L50) and the workflow is wired in [.github/workflows/release-please.yml](/Users/jon/projects/scrypath/.github/workflows/release-please.yml#L34), but no real publish run was verified. |
| REL-02 | 11-02-PLAN.md | Maintainer can verify the published package from a clean consumer flow that confirms install, docs availability, and basic runtime usability. | ? NEEDS HUMAN | The local smoke harness proves the packaged artifact path in [test/release/consumer_smoke_test.exs](/Users/jon/projects/scrypath/test/release/consumer_smoke_test.exs#L6), and the manual published-package/HexDocs checks are documented in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L47), but live Hex install and HexDocs reachability remain manual. |
| REL-03 | 11-02-PLAN.md | Maintainer can recover from common release failures using documented runbooks for tag/version drift, failed publish, and published-artifact mismatch. | ✓ SATISFIED | All three runbooks are present in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L93) and enforced by [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L135). |

No orphaned Phase 11 requirements were found in [.planning/REQUIREMENTS.md](/Users/jon/projects/scrypath/.planning/REQUIREMENTS.md#L47).

### Anti-Patterns Found

No blocking or warning-level anti-patterns found in the Phase 11 files scanned (`mix.exs`, `lib/mix/tasks/verify.phase11.ex`, `test/release/package_metadata_test.exs`, `test/release/consumer_smoke_test.exs`, `test/scrypath/docs_contract_test.exs`, `docs/releasing.md`).

### Human Verification Required

### 1. Canonical Publish Flow

**Test:** Merge a real Release Please PR, let `.github/workflows/release-please.yml` publish from `tag_name`, then compare `mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`, the git tag, and `mix hex.info scrypath`.
**Expected:** All release identifiers point to the same `X.Y.Z`, and Hex shows the same published version.
**Why human:** This depends on GitHub Actions and Hex state outside the repo.

### 2. Public Consumer Smoke

**Test:** In a fresh throwaway app, add `{:scrypath, "~> X.Y.Z"}`, add the documented `use Scrypath` schema, run `mix deps.get`, and `mix compile`.
**Expected:** The published package installs and the schema compiles without using a local artifact shortcut.
**Why human:** The automated smoke test only exercises the locally built package artifact through a tagged local git repo.

### 3. Versioned HexDocs Reachability

**Test:** Run `curl -Ifs https://hexdocs.pm/scrypath/X.Y.Z` after the real publish.
**Expected:** The versioned HexDocs page responds successfully for the released version.
**Why human:** This is an external HexDocs availability check.

### Gaps Summary

No code or documentation gaps were found in the Phase 11 implementation. The remaining work is live-release validation against GitHub Actions, Hex, and HexDocs, so the correct status is `human_needed`, not `gaps_found`.

---

_Verified: 2026-04-16T21:05:00Z_
_Verifier: Claude (gsd-verifier)_
