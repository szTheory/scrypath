---
phase: 168-dependency-security-and-reliable-verification
verified: 2026-09-29T01:01:39Z
status: passed
score: 17/17 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 168: Dependency Security and Reliable Verification — Verification Report

**Phase Goal:** Maintained repository graphs no longer resolve known affected Mint, and reliable automated evidence proves the actual graphs delivered to public `main`.
**Verified:** 2026-09-29T01:01:39Z
**Status:** passed

## Goal Achievement

The verification target was the source candidate `c2072c15e48993d09b9ea97204b248ab6c0e99e5` plus its exact delivery evidence. The candidate checkout at `/private/tmp/scrypath-phase168-task2/scrypath` is clean and names that SHA. Candidate, PR merge-ref, and squash-main trees were compared in the delivery receipt; the main push run names `2832e91d725d70eff9ba11d08052260ba17e2747`.

The candidate implementation paths were intentionally verified in that isolated source checkout. They are absent from the maintainer checkout, so GSD cannot compute a project-root `verification.fingerprint` over this report's combined planning and source inputs without copying candidate files into the dirty maintainer tree. The immutable candidate SHA and matching merge-ref/main tree identities above bound the source evidence; this report uses GSD's legacy summary freshness check.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Root, Phoenix, ecommerce, and Ops resolve an available fixed Mint 1.11.0+ with compatible HPAX and no advisory-ignore workaround. | ✓ VERIFIED | Four candidate lockfiles resolve Mint 1.11.0 and HPAX 1.1.0; the graph receipt links the refreshed Hex/OSV evidence and records empty default ignore values and clean strict audit rows. Candidate locks are delivered in main tree `cbd9633f`. No adopter-lock update is claimed. |
| 2 | The mounted startup correction is regression-tested, mounted-tested, delivered from a clean public-main base, and excludes unrelated local changes. | ✓ VERIFIED | `PHX_SERVER=false` scopes both finite setup commands; persistent `exec env ... mix phx.server` remains. The contract has assertions for both setup commands and final launch. PR #82 receipt records red/green focused proof, four mounted Playwright checks, clean refreshed base, exact two-path patch, required PR checks, and post-merge run. |
| 3 | Root/backend, both Phoenix modes, mounted ecommerce, and standalone Ops have source-specific proof; package staging identifies resolved dependencies and rejects unapproved lock drift. | ✓ VERIFIED | Candidate receipt records root (610 tests), backend, mounted, Ops, Phoenix path and package results. Phoenix package code compares all non-Scrypath lock entries and asserts artifact URL, tag, and reported commit before compile/tests. PR and main job logs report Phoenix identities; exact candidate, merge-ref, and main source identities are distinct. |
| 4 | The existing advisory audit checks the full four-graph inventory, reports incomplete/ignored outcomes, preserves locks, and measures incremental cost without a new required lane or duplicate root scan. | ✓ VERIFIED | `dependency_audit.ex` defines all four graphs, compares tracked `mix.lock` paths, attempts rows independently under exception capture, checks lock hashes and records audit/ignore metadata. Tests cover omission, failures, ignored findings, mutation and attempt-all behavior. CI retains the advisory `deep-quality` job and invokes the four-graph script once before the no-audit quality seam. Cold/reused timings are recorded in the joined receipt. |
| 5 | Selected changes merge through required candidate checks and green post-merge main, with the named advisory and path-selected proof passing; blocked delivery is not reported complete. | ✓ VERIFIED | PR #82 and PR #84 are recorded as ordinarily merged; PR #84 was head-matched. Runs 36502225556, 36502764736 and 36503602888 report the required checks successful; named deep-quality, Phoenix, and Ops proof passed for their applicable sources. Merge-ref/main trees match candidate. Receipts explicitly say no candidate Hex artifact was published. |
| 6 | The startup fix has exactly the intended setup/readiness behavior and preserves the persistent launch. | ✓ VERIFIED | Candidate source lines 18, 34, 37 and `phase147_e2e_contract_test.exs` assert both finite commands use `PHX_SERVER=false` and the final persistent launch remains. Recorded focused test: 3 tests, 0 failures; mounted result: 4 Playwright checks passed. |
| 7 | Startup delivery uses refreshed public main and does not mix the original dirty workspace into the PR. | ✓ VERIFIED | `168-01-DELIVERY.md` identifies clean base `40c9978c...`, candidate `e7858cd9...`, PR #82, merge-ref, main `ad73b92d...`, and exact two-file patch. Original checkout snapshot and preserved unrelated state are recorded. |
| 8 | Candidate and integrated-main required checks name the tested source, and the correction is only called complete after merge. | ✓ VERIFIED | PR #82 candidate and push run `36481236762` are SHA-bound in the startup receipt; main required jobs passed at `ad73b92d...`. Later security delivery also has matched candidate, merge-ref, main identities and successful post-merge proof. |
| 9 | Four maintained graphs resolve the fixed release and the selected lock changes are traceable to resolver and advisory evidence. | ✓ VERIFIED | Four Mint/HPAX lock entries exist in candidate source. `168-02-GRAPHS.md` documents Hex/OSV refresh, per-graph solver outcomes, compatible HPAX closure, bounded Sigra retirement correction, lazy_html remediation, and candidate lock hashes. No broader manifest changes are in the 21-path manifest. |
| 10 | Root/backend, ecommerce, and Ops results identify the updated source and lock identities. | ✓ VERIFIED | `168-02-GRAPHS.md` binds the local root/backend, mounted and Ops evidence to the updated graph checkpoint and records graph hashes; the joined receipt records candidate and main results and per-graph lock SHA-256 values. |
| 11 | Phoenix package proof rejects unapproved graph changes before compile/tests and allows only the expected Scrypath artifact substitution. | ✓ VERIFIED | `LockGraph.assert_package!/5` parses literal locks, rejects malformed/duplicate maps, compares all entries except Scrypath, then validates the actual artifact revision, tag and URL. The package task calls it after resolution and before compilation. Focused test names cover allowed substitution, graph drift and artifact revision; recorded focused result is 30 tests, 0 failures. |
| 12 | Phoenix path proof preserves source lock bytes and reports resolved identity before consumer tests. | ✓ VERIFIED | `Verify.Adopter.run_live!/1` runs `deps.get --check-locked`, asserts byte identity, prints sorted graph identity and checks the source lock again after consumer tests/failure paths. Recorded Phoenix path proof passed 10 tests with the maintained graph hash. |
| 13 | Both Phoenix proof modes expose source/mode, lock hashes and sorted package versions including Mint/HPAX without endpoint secrets. | ✓ VERIFIED | Shared lock identity requires Mint and HPAX, sorts package/version output, and emits lock SHA. Path/package runners redact endpoint credentials. Candidate local path/package results and hosted Phoenix job outputs record the resolved hashes/package identities. |
| 14 | The audit inventory cannot silently omit any maintained tracked Mix lock. | ✓ VERIFIED | `inventory/0` has the exact four projects and `tracked_lock_files/1` compares tracked lock basenames to expected inventory. Active tests cover missing/unexpected locks, omitted/duplicate inventory rows. |
| 15 | Audit continues across graph failures and returns aggregate non-clean status for affected, ignored, unavailable, malformed or incomplete results. | ✓ VERIFIED | Per-row exception handling returns an incomplete row and continues enumeration; strict result/parser paths reject nonzero child commands, invalid output, ignores, warnings, unavailable tools, and lock drift. Active tests cover fetch failure, runner/graph exceptions, ignored and malformed output, and all-row attempt. |
| 16 | Audit fetch/audit preserve locks and emit source, ignore state, and separate elapsed costs; CI performs one inventory-owned root audit then retains quality checks. | ✓ VERIFIED | Code records before/after lock SHA and per-child durations, selected Hex ignore metadata and source identity. Test output includes lock-mutation and sequencing cases. Workflow step runs `elixir scripts/ci/dependency_audit.exs` once, then `run_deep_quality_without_audit`; a new required job or matrix is absent. |
| 17 | The combined security candidate proves all graph/mode/audit paths, measured costs, both PR deliveries, and explicitly leaves a real blocked delivery incomplete. | ✓ VERIFIED | Candidate receipt joins graph/mode/audit identities, cold/reused timing table, PR #82 and #84 merges, candidate/merge-ref/main IDs, required and named jobs, closeout artifacts and publication limits. The conditional block rule is honored: both selected PRs are shown as merged, with no fabricated approval. |

The five roadmap criteria are covered by truths 1–5 above. All 17 plan-frontmatter truths were checked against actual source and/or the SHA-bound receipts; summaries were used to locate claims, not as implementation evidence. No prior verification existed, so this is an initial verification.

**Score:** 17/17 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `mix.lock`, `examples/phoenix_meilisearch/mix.lock`, `examples/scrypath_ecommerce/mix.lock`, `scrypath_ops/mix.lock` | Four maintained resolved graphs | ✓ VERIFIED | Present in candidate and integrated-main tree; each contains Mint 1.11.0 and HPAX 1.1.0. Candidate SHA-256 values are in `168-DELIVERY.md`; CI audit reports clean complete rows. |
| `examples/scrypath_ecommerce/docker-e2e-entrypoint.sh`, `test/scrypath/phase147_e2e_contract_test.exs` | Setup readiness correction and regression | ✓ VERIFIED | Source implementation and assertions are present and connected; focused and mounted outcomes are SHA-bound in `168-01-DELIVERY.md`. |
| `lib/mix/tasks/verify/phoenix_example/lock_graph.ex`, `lib/mix/tasks/verify/phoenix_example/package.ex`, `lib/mix/tasks/verify.adopter.ex` | Semantic lock validation wired into both Phoenix modes | ✓ VERIFIED | Literal parser, comparator, post-resolution package guard, path byte assertions and graph identity reporting are substantive and invoked from the active proof paths. |
| `test/mix/tasks/verify_lock_graph_test.exs`, `test/mix/tasks/verify_phoenix_example_package_test.exs`, `test/mix/tasks/verify_adopter_test.exs` | Positive and adversarial Phoenix proof coverage | ✓ VERIFIED | Test cases assert drift rejection, lock preservation, artifact revision and safe output; recorded focused run passed. |
| `scripts/ci/dependency_audit.ex`, `scripts/ci/dependency_audit.exs`, `test/mix/tasks/dependency_audit_test.exs` | Strict repository audit and executable CLI | ✓ VERIFIED | Inventory, orchestration, audit child, parser, failure aggregation and timing/report fields are implemented; recorded focused and live four-graph runs passed. |
| `lib/mix/tasks/verify/capability.ex`, `.github/workflows/ci.yml`, `test/mix/tasks/verify_capability_test.exs`, `test/mix/tasks/workflow_wiring_test.exs` | Existing advisory lane wired once to inventory and remaining checks | ✓ VERIFIED | The workflow runs one inventory scan then the no-audit seam. Tests cover one audit standalone, zero in seam, retained checks and scoped wiring. |
| `.planning/phases/168-dependency-security-and-reliable-verification/168-01-DELIVERY.md`, `168-DELIVERY.md` | Startup and joined security delivery receipts | ✓ VERIFIED | Both exist and distinguish candidate, merge-ref, main, run/job, graph, artifact, cost and publication identities. |

**Artifacts:** 7/7 grouped artifact sets verified.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Ecommerce entrypoint | Ecommerce `config/test.exs` | `PHX_SERVER=false` in finite setup processes | ✓ WIRED | The environment override is command-local; final server process is retained. Focused contract and mounted proof passed. |
| `mix verify.ecommerce_mounted` | `.github/workflows/ci.yml` | Existing required mounted job | ✓ WIRED | Workflow invokes the existing verifier in `ecommerce-mounted (required)`; candidate and main job passed. |
| Phoenix package task | `LockGraph` | Snapshot then full post-fetch graph comparison | ✓ WIRED | Task invokes semantic comparison before compile/tests, passing local artifact URL/tag/commit. |
| Phoenix adopter live branch | `LockGraph` | Byte preservation and graph identity before consumer tests | ✓ WIRED | Fetch and tests are bracketed by exact lock assertions, with graph report before consumer tests. |
| Four-graph audit inventory | `git ls-files -z` | Exact tracked `mix.lock` set comparison | ✓ WIRED | Missing, duplicate and unexpected tracked graph paths become errors. |
| CI `deep-quality` advisory job | `dependency_audit.exs` | Single inventory-owned scan | ✓ WIRED | The existing advisory job invokes the CLI once, then uses the no-audit capability seam. |
| No-audit capability seam | Existing deep-quality checks | Optional dependency, namespace fence, PLT and Dialyzer | ✓ WIRED | Candidate and main deep-quality steps passed; source contains the explicit seam. |
| Plans 02/03/04 selected changes | PR #84 from refreshed main | Selected manifest and source tree identity | ✓ WIRED | Candidate path manifest is exactly the recorded 21 selected files; clean base is `ad73b92d...`. |
| PR #82 / PR #84 | Required candidate and main jobs | Exact-SHA hosted runs and ordinary squash merge | ✓ WIRED | Candidate/merge-ref/main are distinct and tree-equal where appropriate; post-merge push run succeeded. |

**Wiring:** 9/9 connections verified.

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Dependency audit | Per-graph status, lock hashes, ignore state, durations | `mix deps.get --check-locked`, pinned Hex 2.5.1 audit child, tracked Git inventory and monotonic clock | Yes; candidate output has four clean complete rows and unchanged lock hashes | ✓ FLOWING |
| Phoenix path/package proof | Resolved package/version list and lock digest | Actual consumer `mix.lock` after resolver/package staging | Yes; recorded source/resolved hashes and Phoenix package artifact identity | ✓ FLOWING |
| Mounted readiness | Startup command environment and mounted server result | Actual entrypoint plus Docker mounted verifier/browser assertions | Yes; recorded focused regression and four Playwright checks | ✓ FLOWING |

### Behavioral Spot-Checks

No commands were rerun during verification, as directed. Exact-source prior executions and hosted results were examined against the candidate code:

| Behavior | Recorded command/evidence | Result | Status |
|---|---|---|---|
| All maintained locks remain fixed, clean and complete through audit | `elixir scripts/ci/dependency_audit.exs`; local cold/reused candidate audits; PR run 36502225556 and main run 36503602888 | Four clean rows, empty default ignore values, equal before/after hashes; recorded CI success | ✓ PASS |
| Phoenix package graph admits only exact Scrypath substitution | `mix verify.phoenix_example --package`; PR/main Phoenix path | Candidate local 10 tests, 0 failures; actual artifact commit/revision and lock identity reported; hosted steps passed | ✓ PASS |
| Phoenix path locks remain byte-identical | `mix verify.phoenix_example`; PR/main Phoenix path | Candidate local 10 tests, 0 failures; source/resolved SHA matches; hosted steps passed | ✓ PASS |
| Mounted readiness setup cannot advertise a transient server | `mix test --no-start test/scrypath/phase147_e2e_contract_test.exs`; `mix verify.ecommerce_mounted`; PR #82 and later PR/main jobs | Focused 3 tests, 0 failures; 4 mounted browser checks passed; required mounted job passed on main | ✓ PASS |
| Four-graph attempt-all and failure aggregation | `mix test test/mix/tasks/dependency_audit_test.exs test/mix/tasks/verify_capability_test.exs test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors` | Recorded 67 tests, 0 failures. Tests explicitly cover fetch failure, graph exception continuation, lock changes and ignored/malformed outcomes. | ✓ PASS |

### Probe Execution

No `probe-*.sh`, PASS-marker, or stage-marker probe is declared in the phase plans/summaries. The recorded mounted verifier and audit CLI are the named executable proofs; no separate probe substitution was made.

| Probe | Command | Result | Status |
|---|---|---|---|
| None declared | N/A | N/A | N/A |

### Requirements Coverage

| Requirement | Source plan | Description | Status | Evidence |
|---|---|---|---|---|
| MINT-01 | 02, 05 | Four maintained graphs resolve fixed Mint/HPAX and correction reaches main | ✓ SATISFIED | Four locks, current advisory refresh, strict clean audit; PR #84 merged and main run 36503602888 successful. |
| MINT-02 | 02, 03, 05 | Source-specific root/backend, Phoenix path/package, mounted and Ops proof; graph drift rejected | ✓ SATISFIED | Candidate local results and PR/main named outputs with exact graph identities; package comparator checked before compile/tests. |
| MINT-03 | 04, 05 | Strict four-graph audit in existing lane, lock preservation, omission guard and measured cost | ✓ SATISFIED | Inventory/runner/tests/CI wiring inspected; clean candidate audit; cold/reused cost receipt; no added required lane/cache. |
| DELIV-01 | 01, 05 | Mounted readiness fix delivered through coherent PR with focused and mounted proof, excluding unrelated edits | ✓ SATISFIED | PR #82 receipt has clean base/two-path manifest, merged main and successful candidate/main required checks; original worktree preserved. |

**Coverage:** 4/4 requirements satisfied. No phase-mapped requirement is orphaned.

### Test Quality Audit

Requirement-linked ExUnit files were inspected for active assertions and disabled-test markers. The tracked focused runs recorded in plan receipts passed at their named source; no test was rerun for this audit. `File.write!` uses create temporary locks/package fixtures or deliberately mutate them for preservation/failure tests; tests do not generate expected results by running the system under test.

| Test File | Linked requirement | Active/skipped | Circular | Strongest assertion | Verdict |
|---|---|---:|---|---|---|
| `test/scrypath/phase147_e2e_contract_test.exs` | DELIV-01 | Active / 0 disabled | No | Value and workflow wiring assertions | PASS; recorded 3 tests, 0 failures and mounted proof |
| `test/mix/tasks/verify_lock_graph_test.exs` | MINT-02 | Active / 0 disabled | No | Exact graph value, rejection and byte equality | PASS; recorded in focused run |
| `test/mix/tasks/verify_phoenix_example_package_test.exs` | MINT-02 | Active / 0 disabled | No | Behavioral sequencing and graph drift rejection | PASS; recorded in focused run |
| `test/mix/tasks/verify_adopter_test.exs` | MINT-02 | Active / 0 disabled | No | Lock mutation prevents tests; failure-path assertions | PASS; recorded in focused run |
| `test/mix/tasks/dependency_audit_test.exs` | MINT-03 | Active / 0 disabled | No | Attempt-all, aggregate fail, exact lock and output assertions | PASS; recorded 15-test suite and 67-test combined focused run |
| `test/mix/tasks/verify_capability_test.exs` | MINT-03 | Active / 0 disabled | No | Call count and retained quality sequence | PASS; recorded 67-test combined focused run |
| `test/mix/tasks/workflow_wiring_test.exs` | MINT-03 | Active / 0 disabled | No | Workflow invocation and ordering | PASS; recorded 67-test combined focused run |

**Disabled tests on requirements:** 0. **Circular patterns detected:** 0. **Insufficient assertions:** 0 identified.

### Decision Coverage

All 6 trackable decisions from `168-CONTEXT.md` are honored by shipped artifacts. The decision coverage gate reported no unhonored decisions (non-blocking).

### Anti-Patterns Found

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in the 21 changed implementation paths. The heuristic scan's match in the ecommerce lock was package metadata text, not a code TODO/stub. No placeholder implementation, empty feature body, disabled requirement test, or unwired planned artifact was identified.

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| None | — | — | — | — |

**Anti-patterns:** 0 blockers, 0 warnings.

### Human Verification Required

N/A — this is an infrastructure/library-maintenance phase with no user-facing feature or UI acceptance. All success criteria have automated source-specific or hosted evidence; no manual UAT is pending.

### Advisory Notes

- `mix verify.ops_ui` emitted existing nonfatal Dialyzer warnings; the named Ops capability passed. The warning is recorded in the delivery receipt and does not invalidate its successful task result.
- No candidate Hex package was published. The locally built archive and package tag are proof inputs only; this phase makes no release or publication claim.
- The root `REQUIREMENTS.md` still shows Phase 168 rows as Pending because phase closeout has not yet updated planning metadata. This verification covers their implementation state; the orchestrator should mark them complete through the GSD phase-completion workflow after accepting this report.

### Gaps Summary

**No gaps found.** All roadmap success criteria, all plan must-haves, and all four mapped requirements are verified. Candidate `c2072c1`, tested PR merge-ref `a0b22c6`, and integrated `main` `2832e91` have the same source tree. Ready for GSD phase closeout.

---

_Verified: 2026-09-29T01:01:39Z_  
_Verifier: the agent (gsd-verifier)_
