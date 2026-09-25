---
phase: 109-release-train-and-package-truth-audit
verified: 2026-05-31T20:32:41Z
status: passed
score: 13/13 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 12/13
  gaps_closed:
    - "Maintainer docs and contributor guidance describe `mix verify.phase11` as the deterministic always-on gate and keep live Hex/HexDocs/consumer proof on the post-publish path only."
  gaps_remaining: []
  regressions: []
---

# Phase 109: Release Train and Package Truth Audit Verification Report

**Phase Goal:** Make the release train boring and auditable by confirming version, changelog, package shape, publish workflow, and release-parity truth all agree.
**Verified:** 2026-05-31T20:32:41Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Release Please, `mix.exs`, manifest, changelog, tags, and publish workflow have documented agreement checks. | ✓ VERIFIED | `mix verify.phase11` validates version/source/changelog agreement and workflow anchors; tests pass. |
| 2 | Hex package shape excludes non-library output (`scrypath_ops/`, examples, website output, planning, `node_modules`, Playwright artifacts). | ✓ VERIFIED | `test/release/consumer_smoke_test.exs` inspects unpacked artifact and refutes forbidden prefixes; suite passes. |
| 3 | Canonical publish path proves `mix verify.phase11` -> dry-run publish -> publish -> release visibility/parity checks. | ✓ VERIFIED | `.github/workflows/release-please.yml` and `.github/workflows/publish-hex.yml` contain ordered chain; `workflow_wiring_test.exs` asserts order. |
| 4 | Release-truth drift is fixed patch-sized without runtime-surface expansion. | ✓ VERIFIED | Modified files are workflows/docs/tests/planning and verify task; no new runtime API surfaced. |
| 5 | `mix verify.phase11` fails explicitly when local release sources disagree. | ✓ VERIFIED | `validate_release_agreement/1` returns file-specific mismatch messages; covered by `verify_phase11_test.exs`. |
| 6 | `mix verify.phase11` remains deterministic and service-free. | ✓ VERIFIED | Task runs local tests/docs/grep/build only; no Hex publish or live network verification in the gate body. |
| 7 | Unpacked artifact proof enforces root-library-only shipping. | ✓ VERIFIED | Artifact built via `mix hex.build --unpack`; allow/deny assertions executed in release tests. |
| 8 | Frozen Phase 97 anchors exist at expected path and are loaded by docs contract tests. | ✓ VERIFIED | `docs_contract_test.exs` `File.read!` anchors resolve and suite passes. |
| 9 | Reconstructed Phase 97 scope guard retains `SCOPE-01` and reopen policy. | ✓ VERIFIED | `97-SCOPE-GUARD.md` contains banned capability classes and reopen policy tokens. |
| 10 | Current planning pointers to Phase 97 scope guard resolve. | ✓ VERIFIED | `.planning/PROJECT.md` and `.planning/ROADMAP.md` still reference `97-SCOPE-GUARD.md`; anchor file exists. |
| 11 | Canonical and recovery publish workflows run the same ordered proof chain (tag/version source aside). | ✓ VERIFIED | Workflow YAMLs and `workflow_wiring_test.exs` parity assertions present and passing. |
| 12 | Published-release monitor verifies published version visibility/parity without publishing. | ✓ VERIFIED | `verify-published-release.yml` resolves latest version then runs `verify.release_publish` + `verify.release_parity`; no `mix hex.publish --yes`. |
| 13 | Maintainer/contributor release guidance stays truth-aligned on what gates run where. | ✓ VERIFIED | `docs/releasing.md` now states `mix opsui.test_a11y` runs nav contract + DB create/migrate + `mix test --only opsui_a11y` and explicitly routes release/package truth to `mix verify.phase11`; this matches `scrypath_ops/mix.exs` `opsui_test_a11y/1`. |

**Score:** 13/13 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mix/tasks/verify.phase11.ex` | Semantic release agreement gate | ✓ VERIFIED | Exists, substantive, wired via workflow/tests. (`verify.artifacts` false export warning appears to be parser false-positive; `def run(args)` exists.) |
| `test/mix/tasks/verify_phase11_test.exs` | Agreement regression coverage | ✓ VERIFIED | Exists with mismatch and pass-path tests. |
| `test/release/package_metadata_test.exs` | Package metadata assertions | ✓ VERIFIED | Exists with allowlist/denylist intent checks. |
| `test/release/consumer_smoke_test.exs` | Unpacked artifact + clean consumer compile | ✓ VERIFIED | Builds unpacked artifact, asserts excluded paths, compiles throwaway consumer. |
| `97-CONTRACT-STATEMENTS.md` | Phase 97 truth anchors | ✓ VERIFIED | Contains `CST-TRUTH-01/02/03` tokens. |
| `97-CONTRACT-TRACEABILITY.md` | Phase 97 truth trace rows | ✓ VERIFIED | Contains `TRUTH-01/02/03` rows. |
| `97-SCOPE-GUARD.md` | Scope guard authority | ✓ VERIFIED | Contains `SCOPE-01` and reopen policy criteria. |
| `.github/workflows/release-please.yml` | Canonical publish chain | ✓ VERIFIED | Ordered proof chain including publish + post-publish verify tasks. |
| `.github/workflows/publish-hex.yml` | Recovery replay chain | ✓ VERIFIED | Mirrors canonical chain with `inputs.release_version`. |
| `.github/workflows/verify-published-release.yml` | Publish-free monitor | ✓ VERIFIED | Version-resolve + verify tasks; schedule-only drift issue dedupe. |
| `test/mix/tasks/workflow_wiring_test.exs` | Workflow chain assertions | ✓ VERIFIED | Contains ordering and monitor guard assertions. |
| `docs/releasing.md` | Maintainer authority | ✓ VERIFIED | Corrected OPSUI a11y alias semantics and explicit release/package gate routing to `mix verify.phase11` (commit `60c4ebd`). |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `mix.exs` | `.release-please-manifest.json` | Semantic comparison in `verify.phase11` | WIRED | `release_sources!/0` reads both and compares versions/source_ref. |
| `verify.phase11.ex` | `release-please-config.json` | Config validation | WIRED | Reads JSON and checks `release-type` + `include-v-in-tag`. |
| `consumer_smoke_test.exs` | `mix hex.build --unpack` | Artifact build helper | WIRED | `build_packaged_artifact!/2` runs unpack command. |
| `docs_contract_test.exs` | Phase 97 archive files | `File.read!` anchors | WIRED | Compile-time anchor reads present and passing. |
| `release-please.yml` | `mix verify.phase11` | Publish job step | WIRED | Explicit step present. |
| `publish-hex.yml` | `docs/releasing.md` | Recovery contract parity | WIRED | Docs describe same ordered chain and explicit inputs. |
| `verify-published-release.yml` | `workflow_wiring_test.exs` | Monitor assertions | WIRED | Test asserts publish-free monitor + dedupe behavior. |
| `docs/releasing.md` | `scrypath_ops/mix.exs` | `mix opsui.test_a11y` behavior text | WIRED | Docs now match exact alias steps and boundary (OPSUI-only) in `scrypath_ops/mix.exs`. |
| `docs/releasing.md` | `lib/mix/tasks/verify.phase11.ex` | release/package gate routing | WIRED | Docs instruct `mix verify.phase11` for release/package truth; task runs release contract tests + docs + contract validation + unpack build. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `verify.phase11.ex` | `release_sources` map | `mix.exs`, manifest, release config, changelog files | Yes | ✓ FLOWING |
| `consumer_smoke_test.exs` | `artifact_paths` | `mix hex.build --unpack` output directory | Yes | ✓ FLOWING |
| `verify-published-release.yml` | resolved `version` | Hex package API + `jq` parse | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused docs/workflow wiring tests pass (gap closure target) | `mix test test/scrypath/docs_contract_test.exs test/mix/tasks/workflow_wiring_test.exs` | 104 tests, 0 failures | ✓ PASS |
| Deterministic release gate runs end-to-end | `mix verify.phase11` | Passes; release contract checks + docs build + unpack build succeed | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| Step 7c | probe discovery (`find scripts -path '*/tests/probe-*.sh'`) | No probes declared or discovered for this phase | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| REL-01 | 109-01/109-02/109-03 | Release sources and workflow agree on canonical path | ✓ SATISFIED | `docs/releasing.md` corrected to mirror `scrypath_ops/mix.exs` alias behavior and route release/package truth to `mix verify.phase11`; workflows/tests remain aligned. |
| REL-02 | 109-01 | Hex package excludes non-library payload | ✓ SATISFIED | Unpacked artifact denylist assertions in `consumer_smoke_test.exs`; gate passes. |
| REL-03 | 109-02/109-03 | Publish path proves phase11, dry-run, visibility, docs reachability, consumer compile, parity | ✓ SATISFIED | Release/recovery/monitor workflows and wiring tests encode required chain; `mix verify.phase11` passed locally. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/mix/tasks/workflow_wiring_test.exs` | `assert_ordered_steps/2` matcher | First-occurrence token matching can be brittle | ⚠️ Warning | Could permit false positives/negatives if duplicate/commented tokens appear earlier. |
| `lib/mix/tasks/verify.phase11.ex` | workflow anchor checks scope | Does not directly assert `release_parity` anchor/publish-hex wiring | ⚠️ Warning | Covered elsewhere by workflow wiring tests, but split authority increases drift risk. |

---

_Verified: 2026-05-31T20:32:41Z_  
_Verifier: the agent (gsd-verifier)_
