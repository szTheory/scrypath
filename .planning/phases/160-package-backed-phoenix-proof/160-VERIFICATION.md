---
phase: 160-package-backed-phoenix-proof
verified: 2026-09-24T03:13:57Z
status: gaps_found
score: 2/4 must-haves verified
covered_files:
  - .github/workflows/ci.yml
  - .planning/REQUIREMENTS.md
  - .planning/phases/160-package-backed-phoenix-proof/160-01-PLAN.md
  - .planning/phases/160-package-backed-phoenix-proof/160-01-SUMMARY.md
  - .planning/phases/160-package-backed-phoenix-proof/160-02-PLAN.md
  - .planning/phases/160-package-backed-phoenix-proof/160-02-SUMMARY.md
  - CONTRIBUTING.md
  - examples/phoenix_meilisearch/README.md
  - lib/mix/tasks/verify.adopter.ex
  - lib/mix/tasks/verify/capability.ex
  - lib/mix/tasks/verify/phoenix_example/package.ex
  - test/mix/tasks/verify_capability_test.exs
  - test/mix/tasks/verify_phoenix_example_package_test.exs
  - test/scrypath/docs_contract_test.exs
covered_digest: "v1:sha256:11db341ace094506f789accbb722267560c83e2b9586ac9ac880bea71079a1bf"
behavior_unverified: 1
overrides_applied: 0
gaps:
  - truth: "The package-backed Phoenix proof passes all four real-service integration scenarios on the exact candidate SHA."
    status: failed
    reason: "No successful exact-SHA hosted run or equivalent local package-backed live-service run is available. The phase validation map and STATE record explicitly leave this acceptance open; GitHub API access was unavailable during verification."
    artifacts:
      - path: ".planning/phases/160-package-backed-phoenix-proof/160-VALIDATION.md"
        issue: "Records the package-backed integration acceptance as still requiring an exact-SHA service run."
      - path: ".planning/STATE.md"
        issue: "Records local Meilisearch unavailability and invalid GitHub CLI authentication/API reachability as the current blocker."
    missing:
      - "After the current package provenance changes are committed, obtain the phoenix-example hosted run for that exact SHA and confirm package build, dependency resolution, consumer compilation, and all four integration scenarios pass."
behavior_unverified_items:
  - truth: "The no-argument live Phoenix proof succeeds in the existing shared-service CI job."
    test: "Run the path-backed command in the phoenix-example job on the final candidate SHA."
    expected: "The existing path dependency flow completes against Postgres and Meilisearch before package mode starts."
    why_human: "Source and CI wiring show the command order, but no exact-SHA live service result is available; this is an automated hosted acceptance, not a request for human UAT."
decision_coverage:
  honored: 7
  total: 7
  not_honored: []
---

# Phase 160: Package-Backed Phoenix Proof Verification Report

**Phase Goal:** Maintainers can verify that the package artifact produced from the current checkout supports the existing Phoenix adopter example against real Postgres and Meilisearch services.
**Verified:** 2026-09-24T03:13:57Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The package path builds and unpacks the artifact, resolves a clean consumer to its exact local artifact tag without a path dependency, and compiles it. | ✓ VERIFIED | `package.ex` runs `mix hex.build --unpack`, tags the unpacked artifact, stages the example without `deps`/`_build`, checks that its manifest has no Scrypath `path:` dependency, verifies the Scrypath lock entry's URL and tag, then invokes `mix compile`. Current validation records **6/6** package tests, **11/11** package+capability tests, and a **572/0** fast suite (80 excluded); the provenance regression now uses realistic string-key / four-element Git lock syntax. The existing release consumer smoke test also covers a package artifact and clean consumer schema. |
| 2 | The deterministic command completes the existing inline, Oban, and related-data scenarios against that artifact and reports their results. | ✗ FAILED | The code stages the existing four `@moduletag :integration` smoke modules and invokes `mix test` with `SCRYPATH_EXAMPLE_INTEGRATION=1`, but no passing live package run exists for the current candidate. `.planning/phases/160-package-backed-phoenix-proof/160-VALIDATION.md` says the exact-SHA service run remains required. The current checkout is `07b801f655d8171c370a1033e5c08f7a012a511a`; package provenance changes are also present as working-tree edits, so this tree has no hosted SHA-bound acceptance yet. `gh auth status` reported an invalid token and the API request failed to connect. |
| 3 | The normal no-argument path workflow and the package proof remain ordered in the same advisory Phoenix service lane, with the example's path dependency unchanged. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `capability.ex` routes `[]` to `verify.adopter --live`; `.github/workflows/ci.yml` keeps `continue-on-error: true`, its Postgres 16 / Meilisearch v1.15 services, and runs the path command before `--package`. The ordinary example dependency is still `{:scrypath, path: "../.."}`. The docs contract passed **71/71** and checks the same order and prerequisites. Runtime success of the path-backed service proof has not been confirmed on the exact candidate SHA. |
| 4 | Success and injected setup, service, compile, or test failures report the failing stage and clean owned temporary files by default; automated checks guard command, CI, and docs drift. | ✓ VERIFIED | `package.ex` has stage-specific failures and a shared `try/after` cleanup boundary. The current lifecycle tests cover success cleanup, service preflight, artifact failure cleanup, injected dependency/compile/test failures, and opt-in retention. The docs contract checks CI order, advisory status, services, prerequisites, and the unchanged path dependency; validation records 71 passing tests. |

**Score:** 2/4 truths verified (1 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/mix/tasks/verify/capability.ex` | Strict package dispatch while preserving no-argument path mode | ✓ VERIFIED | `phoenix_example!([])` delegates to `verify.adopter --live`; package mode rejects stray options and dispatches to `Package.run/1`. |
| `lib/mix/tasks/verify.adopter.ex` | Reusable service preflight | ✓ VERIFIED | Public `ensure_live_prerequisites!/0` validates required environment values and Postgres/Meilisearch TCP reachability before package work. |
| `lib/mix/tasks/verify/phoenix_example/package.ex` | Artifact build, fail-closed consumer provenance, compile/live test execution, diagnostics, lifecycle | ✓ VERIFIED | Substantive orchestration is present and connected to the CLI. Lock verification parses the Mix lock AST and matches the Scrypath string key, Git URL, revision slot, and tag options. Exact live acceptance remains a separate failed truth. |
| `test/mix/tasks/verify_phoenix_example_package_test.exs` | Provenance and failure lifecycle contracts | ✓ VERIFIED | Current focused package run passed 6 tests. The tests cover realistic lock provenance, preflight/redaction, success cleanup, artifact and later-stage failures, and opt-in retention. |
| `.github/workflows/ci.yml` | Ordered path and package commands in current advisory service job | ✓ VERIFIED | Both commands are under the existing `phoenix-example` job with its existing services and advisory setting. |
| `CONTRIBUTING.md`, `examples/phoenix_meilisearch/README.md` | Maintainer and adopter runbook | ✓ VERIFIED | Both command modes and the service prerequisites are documented. |
| `test/scrypath/docs_contract_test.exs` | Automated docs/CI/path-dependency drift checks | ✓ VERIFIED | Job-scoped assertions cover command order, advisory status, service versions, prerequisites, and normal path dependency. Validation map records 71 tests with no failures. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `Mix.Tasks.Verify.Capability.phoenix_example!/1` | `Package.run/1` | `--package` dispatch; `[]` retains `verify.adopter --live` | WIRED | Direct function call and preserved default branch in `capability.ex`. |
| Unpacked artifact | Staged `mix.exs` and `mix.lock` | Local Git tag and `file://` dependency | WIRED | The staged manifest is rewritten only in the temporary copy. The lock check now parses the actual string-key map entry and requires the expected artifact URL and tag on Scrypath itself. Focused provenance test passed. |
| Staged Phoenix example | Existing integration smoke modules | `mix test` with integration environment enabled | WIRED | Staged test tree includes the example's four integration modules; test helper excludes integration tests unless the flag is set. No live result is available. |
| `phoenix-example` CI job | Path then package command | Same advisory job/service block | WIRED | Workflow source confirms order, service declarations, and `continue-on-error: true`. |
| Runbooks | Executable command and prerequisites | Contract assertions | WIRED | Docs use the same command and environment variable names; ordinary path dependency is asserted unchanged. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Package runner | `artifact` | `mix hex.build --unpack --output` from current checkout | Yes, package files are passed through local Git tagging and a staged dependency resolution | FLOWING in source; exact live package run absent |
| Staged dependency | Scrypath lock entry | `mix deps.get` against `file://<workspace>/artifact` | Yes, lock parser validates source URL and tag on the Scrypath key | FLOWING; focused provenance test passed |
| Example integration tests | Postgres / Meilisearch | Example Repo and configured Meilisearch endpoint | Would exercise real services and indexed records | NOT OBSERVED for current candidate; exact-SHA hosted acceptance is blocking |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Package provenance and injected lifecycle contracts | `ASDF_ERLANG_VERSION=28.5 ASDF_ELIXIR_VERSION=1.19.5-otp-28 asdf exec mix test test/mix/tasks/verify_phoenix_example_package_test.exs` | Orchestrator reran in an isolated sequence: 6 tests, 0 failures | ✓ PASS |
| Capability and package contracts | `mix test test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_phoenix_example_package_test.exs` | 11 tests, 0 failures | ✓ PASS |
| Documentation contract | `mix test test/scrypath/docs_contract_test.exs` | 71 tests, 0 failures | ✓ PASS |
| Fast service-free suite | Orchestrator-reported `asdf exec mix test --exclude integration --exclude docs_contract` | 572 tests, 0 failures; 80 excluded | ✓ PASS |
| Package-backed Phoenix live proof | `SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.phoenix_example --package` | Not run in this verification; validation map records unavailable local service and requires exact-SHA hosted proof | ? BLOCKED |

### Probe Execution

No phase-declared or conventional probe applies; Phase 160 is a Mix task/CI integration change and declares no `probe-*.sh` command.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| PKG-01 | 160-01 | Build package artifact and compile a clean consumer without a path dependency | SATISFIED | Artifact build, isolated Git-tag dependency, exact lock provenance, and compile invocation are wired; focused provenance test passed. |
| PKG-02 | 160-01 | Run the existing Phoenix inline, Oban, and related-data live flows against the package artifact | BLOCKED | No exact-SHA successful hosted or equivalent local live-service run. |
| PKG-03 | 160-01 | Isolated temporary files, actionable failures, cleanup on success/failure | SATISFIED | Owned-root cleanup is exercised on success and artifact/dependency/compile/test failures; service preflight, stage output/status, redaction, and opt-in retention are covered by the focused tests. |
| PROOF-01 | 160-02 | Documented command, existing prerequisites, advisory CI order, automated drift checks | SATISFIED | Workflow and docs are wired; validation map records the contract suite passing. |

No Phase 160-mapped requirement is orphaned. DOC-01, HYGIENE-01, REL-01, and CLOSE-01 map to later Phase 161 and are not Phase 160 requirements.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---:|---|---|
| `test/mix/tasks/verify_phoenix_example_package_test.exs` | PKG-01, PKG-03 | Yes | 0 found | 0 found | Value / behavior for lock source, redaction, failure status, cleanup, and retention; no exact live integration assertion | PARTIAL |
| `test/mix/tasks/verify_capability_test.exs` | PKG-01, PROOF-01 | Yes | 0 found | 0 found | Behavior for strict option acceptance; source/dispatch assertions are limited | PASS for covered contract |
| `test/scrypath/docs_contract_test.exs` | PROOF-01 | Yes | 0 found | 0 found | Value assertions over job-scoped config and documentation | PASS for drift contract |

Disabled requirement tests and circular expected-value generation were not found in the linked test files. The service-backed integration outcome remains the unproven contract; lifecycle and documentation drift tests pass.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|

No TODO/FIXME/XXX/placeholder or empty-implementation markers were found in the Phase 160 implementation, CI, docs, or contract files scanned.

### Decision Coverage

All 7 trackable decisions in `160-CONTEXT.md` are honored by shipped artifacts. This gate is non-blocking.

### Human Verification Required

None. The remaining acceptance is the automated `phoenix-example` hosted lane on the final exact SHA, not human UAT.

### Gaps Summary

The package command, artifact provenance check, CI wiring, documentation, and tested cleanup lifecycle are present. Focused package and capability tests, documentation contracts, and the service-free fast suite pass. Phase 160 remains blocked solely because the defining outcome—successful execution of the packaged Phoenix example against real Postgres and Meilisearch—has no exact-SHA hosted result. During this verification, GitHub CLI authentication was invalid and the GitHub API was unreachable. After the current provenance changes are committed, obtain the `phoenix-example` run for that exact commit and confirm package stage markers plus all four integration modules pass. This is automated hosted evidence, not human UAT.

---

_Verified: 2026-09-24T03:13:57Z_
_Verifier: the agent (gsd-verifier)_
