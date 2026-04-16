---
phase: 11-public-release-contract
verified: 2026-04-16T21:05:15Z
status: human_needed
score: 6/8 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Run the first real Release Please publish and confirm the workflow-owned live checks pass"
    expected: "Release Please creates vX.Y.Z, publish-hex checks out tag_name, verifies mix.exs/version alignment, runs mix verify.phase11, runs mix hex.publish --dry-run --yes, publishes to Hex, then mix verify.release_publish X.Y.Z succeeds"
    why_human: "The release, Hex visibility, and HexDocs availability are external systems that cannot be proven before the first public publish exists"
---
# Phase 11: Public Release Contract Verification Report

**Phase Goal:** Maintainers can trust the canonical release path because tag, changelog, package version, Hex artifact state, and clean-consumer verification all line up under one repeatable contract.
**Verified:** 2026-04-16T21:05:15Z
**Status:** human_needed
**Re-verification:** Yes - updated after release automation hardening

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Maintainer can cut a release from the canonical GitHub flow and confirm the tag, changelog, manifest, package version, and Hex artifact all agree. | ? UNCERTAIN | The hardened publish workflow now checks out `tag_name`, verifies the version in `mix.exs`, runs `mix verify.phase11`, runs `mix hex.publish --dry-run --yes`, then publishes in [.github/workflows/release-please.yml](/Users/jon/projects/scrypath/.github/workflows/release-please.yml#L46), but no real GitHub Actions or Hex publish run has been exercised yet. |
| 2 | Maintainer can install the published package in a clean consumer flow, reach HexDocs, and run a basic Scrypath usage path successfully. | ? UNCERTAIN | [lib/mix/tasks/verify.release_publish.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.release_publish.ex#L1) now automates the live published-package, throwaway-app compile, and versioned HexDocs checks, and both the release workflow and the scheduled monitor call it, but the published package and HexDocs page do not exist yet. |
| 3 | Maintainer can follow one documented recovery path for tag or version drift, failed publish attempts, and published-artifact mismatch without ad hoc spelunking. | ✓ VERIFIED | Recovery runbooks are documented in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L89), enforced by [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L118), and backed by the explicit recovery workflow in [.github/workflows/publish-hex.yml](/Users/jon/projects/scrypath/.github/workflows/publish-hex.yml#L1). |
| 4 | Maintainer can prove the repo's declared release version, tag ref, and package metadata all describe the same package release. | ✓ VERIFIED | Version-derived metadata is defined in [mix.exs](/Users/jon/projects/scrypath/mix.exs#L4) and asserted exactly in [test/release/package_metadata_test.exs](/Users/jon/projects/scrypath/test/release/package_metadata_test.exs#L14). |
| 5 | Maintainer has one automated command that fails when release metadata or workflow wiring drifts. | ✓ VERIFIED | `mix verify.phase11` runs release tests, docs build, targeted workflow checks, manifest alignment, and local package assembly in [lib/mix/tasks/verify.phase11.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex#L14). I re-ran `mix verify.phase11` successfully. |
| 6 | Release-facing links no longer point at moving main-branch targets for release artifacts. | ✓ VERIFIED | Release links are version-scoped in [mix.exs](/Users/jon/projects/scrypath/mix.exs#L94) and the exact URLs are locked by [test/release/package_metadata_test.exs](/Users/jon/projects/scrypath/test/release/package_metadata_test.exs#L23). |
| 7 | Maintainer can prove Scrypath works from a clean consumer app before trusting the public release. | ✓ VERIFIED | The smoke harness builds a package artifact, creates a throwaway app with `mix new`, installs Scrypath without a `path:` dependency, and compiles a `use Scrypath` schema in [test/release/consumer_smoke_test.exs](/Users/jon/projects/scrypath/test/release/consumer_smoke_test.exs#L16). |
| 8 | Maintainer has concrete recovery runbooks for tag/version drift, failed publish, and artifact mismatch. | ✓ VERIFIED | The canonical flow plus all three recovery sections are present in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L23) and enforced by [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L135). |

**Score:** 6/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `mix.exs` | Version-derived package and docs metadata for the public package contract | ✓ VERIFIED | Defines `@version`, `@source_ref`, versioned HexDocs links, and registers `verify.phase11` in [mix.exs](/Users/jon/projects/scrypath/mix.exs#L4). |
| `test/release/package_metadata_test.exs` | Exact assertions for release-aware package metadata | ✓ VERIFIED | Asserts GitHub, HexDocs, changelog, and guides links from `MixProject.project/0` in [test/release/package_metadata_test.exs](/Users/jon/projects/scrypath/test/release/package_metadata_test.exs#L14). |
| `lib/mix/tasks/verify.phase11.ex` | Canonical automated Phase 11 release-contract verification entrypoint | ✓ VERIFIED | Wires release tests, docs build, targeted workflow checks, manifest alignment, and `hex.build --unpack` in [lib/mix/tasks/verify.phase11.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex#L14). |
| `test/release/consumer_smoke_test.exs` | Automated clean-consumer smoke harness for the documented quick path | ✓ VERIFIED | Builds a local artifact, wraps it in a tagged git repo, and compiles a fresh consumer app in [test/release/consumer_smoke_test.exs](/Users/jon/projects/scrypath/test/release/consumer_smoke_test.exs#L6). |
| `docs/releasing.md` | Canonical release and recovery runbooks for maintainers | ✓ VERIFIED | Documents the gate, canonical flow, and three recovery runbooks in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L5). |
| `test/scrypath/docs_contract_test.exs` | Doc contract assertions for release runbooks and manual public checks | ✓ VERIFIED | Enforces release-gate, HexDocs, and recovery wording in [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L116). |
| `lib/mix/tasks/verify.release_publish.ex` | Live published-release verifier for Hex, consumer install, and HexDocs reachability | ✓ VERIFIED | Polls Hex package visibility, compiles a throwaway consumer app against `{:scrypath, "~> X.Y.Z"}`, and checks the versioned HexDocs URL in [lib/mix/tasks/verify.release_publish.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.release_publish.ex#L1). |
| `.github/workflows/publish-hex.yml` | Explicit recovery workflow for rerunning publish from a reviewed ref | ✓ VERIFIED | Checks out the provided ref, verifies `@version`, reruns the release gate, runs `mix hex.publish --dry-run --yes`, publishes, and re-verifies the live release in [.github/workflows/publish-hex.yml](/Users/jon/projects/scrypath/.github/workflows/publish-hex.yml#L1). |
| `.github/workflows/verify-published-release.yml` | Ongoing published-release monitor for the latest Hex version | ✓ VERIFIED | Resolves `latest_stable_version` from Hex, skips cleanly before first publish, and runs `mix verify.release_publish` on a daily schedule in [.github/workflows/verify-published-release.yml](/Users/jon/projects/scrypath/.github/workflows/verify-published-release.yml#L1). |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `mix.exs` | `test/release/package_metadata_test.exs` | `MixProject.project/0` assertions for exact package/docs link values | ✓ WIRED | The test aliases `Scrypath.MixProject` and asserts `MixProject.project()` package links in [test/release/package_metadata_test.exs](/Users/jon/projects/scrypath/test/release/package_metadata_test.exs#L4). |
| `lib/mix/tasks/verify.phase11.ex` | `.release-please-manifest.json` | manifest/version alignment shell check | ✓ WIRED | `validate_release_contract!/0` compares `@version` in `mix.exs` with `.release-please-manifest.json` in [lib/mix/tasks/verify.phase11.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex#L59). |
| `lib/mix/tasks/verify.phase11.ex` | `.github/workflows/release-please.yml` | same-workflow publish contract validation | ✓ WIRED | The Phase 11 gate now asserts the publish guard, tag checkout, version grep, `mix verify.phase11`, dry-run publish, real publish, and post-publish verification wiring in [.github/workflows/release-please.yml](/Users/jon/projects/scrypath/.github/workflows/release-please.yml#L41). |
| `test/release/consumer_smoke_test.exs` | `README.md` | compiled clean-consumer schema mirrors the documented quick path | ✓ WIRED | The smoke schema uses `use Scrypath` with the documented fields/filterable/sortable shape in [test/release/consumer_smoke_test.exs](/Users/jon/projects/scrypath/test/release/consumer_smoke_test.exs#L81), matching the documented quick path. |
| `docs/releasing.md` | `test/scrypath/docs_contract_test.exs` | runbook section headings and concrete commands asserted in docs contract tests | ✓ WIRED | The docs define all required headings and commands in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L93), and the contract test asserts them in [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L135). |
| `lib/mix/tasks/verify.phase11.ex` | `test/release/consumer_smoke_test.exs` | Phase 11 verification runs the clean-consumer smoke automatically | ✓ WIRED | `mix verify.phase11` includes `test/release/consumer_smoke_test.exs` in [lib/mix/tasks/verify.phase11.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex#L26). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `mix.exs` | `@source_ref`, `@release_docs_url`, `package[:links]` | `@version` in [mix.exs](/Users/jon/projects/scrypath/mix.exs#L4) | Yes - release URLs are derived from the declared version and surfaced through `MixProject.project/0` | ✓ FLOWING |
| `test/release/consumer_smoke_test.exs` | `tag`, generated consumer dependency, compiled beam file | `MixProject.project()[:version]` and local `mix hex.build --unpack` in [test/release/consumer_smoke_test.exs](/Users/jon/projects/scrypath/test/release/consumer_smoke_test.exs#L6) | Yes - the test builds a real package artifact and compiles a real throwaway app | ✓ FLOWING |
| `docs/releasing.md` contract | Recovery headings, release commands, and automation workflow references | Literal runbook content enforced by [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L118) | Yes - the assertions fail if required commands, workflow references, or headings disappear | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Release metadata contract tests pass | `mix test test/release/package_metadata_test.exs` | `3 tests, 0 failures` | ✓ PASS |
| Clean-consumer smoke harness passes | `mix test test/release/consumer_smoke_test.exs` | `2 tests, 0 failures` | ✓ PASS |
| Release docs contract passes | `mix test test/scrypath/docs_contract_test.exs` | `15 tests, 0 failures` | ✓ PASS |
| Canonical Phase 11 gate passes | `mix verify.phase11` | release tests passed, docs built, hardened workflow contract validated, `hex.build --unpack` succeeded | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| REL-01 | 11-01-PLAN.md | Maintainer can publish Scrypath from the canonical GitHub release flow with aligned tag, changelog, manifest, package version, and Hex artifact state. | ? NEEDS FIRST RELEASE | The workflow now enforces version/ref alignment, `mix verify.phase11`, and `mix hex.publish --dry-run --yes` before publish in [.github/workflows/release-please.yml](/Users/jon/projects/scrypath/.github/workflows/release-please.yml#L46), but the first real publish run has not happened yet. |
| REL-02 | 11-02-PLAN.md | Maintainer can verify the published package from a clean consumer flow that confirms install, docs availability, and basic runtime usability. | ? NEEDS FIRST RELEASE | [lib/mix/tasks/verify.release_publish.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.release_publish.ex#L1) now automates the published-package install, throwaway-app compile, and versioned HexDocs checks, and [.github/workflows/verify-published-release.yml](/Users/jon/projects/scrypath/.github/workflows/verify-published-release.yml#L1) keeps re-running them after publish, but Scrypath does not yet exist on Hex. |
| REL-03 | 11-02-PLAN.md | Maintainer can recover from common release failures using documented runbooks for tag/version drift, failed publish, and published-artifact mismatch. | ✓ SATISFIED | All three runbooks are present in [docs/releasing.md](/Users/jon/projects/scrypath/docs/releasing.md#L93) and enforced by [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs#L135). |

No orphaned Phase 11 requirements were found in [.planning/REQUIREMENTS.md](/Users/jon/projects/scrypath/.planning/REQUIREMENTS.md#L47).

### Anti-Patterns Found

No blocking or warning-level anti-patterns found in the Phase 11 files scanned (`mix.exs`, `lib/mix/tasks/verify.phase11.ex`, `lib/mix/tasks/verify.release_publish.ex`, `test/release/package_metadata_test.exs`, `test/release/consumer_smoke_test.exs`, `test/scrypath/docs_contract_test.exs`, `docs/releasing.md`, `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`, `.github/workflows/verify-published-release.yml`).

### Human Verification Required

### 1. First Real Release Workflow

**Test:** Merge a real Release Please PR and let `.github/workflows/release-please.yml` run through `publish-hex`.
**Expected:** The workflow checks out `tag_name`, verifies `@version`, passes `mix verify.phase11`, passes `mix hex.publish --dry-run --yes`, publishes to Hex, and `mix verify.release_publish X.Y.Z` succeeds.
**Why human:** The first real publish still depends on GitHub Actions, Hex package visibility, and HexDocs availability outside the repo.

### Gaps Summary

No code or documentation gaps were found in the Phase 11 implementation. The remaining work is the first real publish run against GitHub Actions, Hex, and HexDocs. After that release exists, the scheduled published-release monitor takes over the ongoing checks automatically.

---

_Verified: 2026-04-16T21:05:15Z_
_Verifier: Claude (gsd-verifier)_
