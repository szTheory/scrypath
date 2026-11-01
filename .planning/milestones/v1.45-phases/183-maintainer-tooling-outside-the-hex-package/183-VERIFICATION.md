---
phase: 183-maintainer-tooling-outside-the-hex-package
verified: 2026-10-28T16:30:00Z
status: passed
score: 3/3 roadmap success criteria verified (PKGH-01, PKGH-02, PKGH-03 all satisfied)
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-01-PLAN.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-01-SUMMARY.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-02-PLAN.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-02-SUMMARY.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-03-PLAN.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-03-SUMMARY.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-04-PLAN.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-04-SUMMARY.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-05-PLAN.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-05-SUMMARY.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-06-PLAN.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-06-SUMMARY.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-07-PLAN.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-07-SUMMARY.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-08-PLAN.md"
  - ".planning/phases/183-maintainer-tooling-outside-the-hex-package/183-08-SUMMARY.md"
  - "CONTRIBUTING.md"
  - "dev/mix/tasks/verify.namespace_fence.ex"
  - "dev/mix/tasks/verify.phase11.ex"
  - "dev/mix/tasks/verify/package.ex"
  - "mix.exs"
  - "scripts/ci/beam_cache.cjs"
  - "test/mix/tasks/verify_capability_test.exs"
  - "test/release/consumer_smoke_test.exs"
  - "test/release/package_contents_test.exs"
  - "test/support/release/package_contract.ex"
  - "test/support/repo_tooling.ex"
covered_digest: "v4:sha256:f15ebda2d1dff661b133244be83f31f980af6b6bd6540a898f9ac181385d02f1"
behavior_unverified: 0
overrides_applied: 0
advisory:
  - finding: "WR-04: website pages (index.html:173, operators.html:45, docs.html:131-132) still tell adopters/operators to run `mix verify.adopter`"
    category: other
    reason: "Not part of PKGH-01..03 or the Hex package; currently accurate for published 0.3.17, becomes false at the next Hex release. Fix (qualify as source-checkout-only, update phase110/112 contract pins) before that release."
    evidence_status: "reproduced by grep; no executable failure today"
  - finding: "WR-01/WR-02/WR-03 guard weaknesses (elixirc_paths non-test env not pinned by a unit test; preferred_envs guard selects by `Verify` name not location; L1 AST scan misses aliased/Elixir.-prefixed/atom module names)"
    category: other
    reason: "Each is a hardening gap in a secondary guard. The primary gate still holds: consumer_smoke L2 (scrypath.app module list + beam count) backstops WR-01 and WR-03, and I re-verified prod/dev compiles produce 0 Verify beams."
    evidence_status: "review probe for WR-03 reported by 183-REVIEW.md; backstop confirmed by reading consumer_smoke_test.exs:95-135"
---

# Phase 183: Maintainer tooling outside the Hex package - Verification Report

**Phase Goal:** Contributors retain their verification workflow, and installed consumers receive a clean package without repository-only tooling or missing development-path dependencies.
**Verified:** 2026-10-28
**Status:** passed
**Re-verification:** No, initial verification
**Verified at:** branch `planning/v1.45-foundation-ci`, HEAD `4a3d8288` (planning-docs-only commits on top of `9fb1ec35`, the PR #123 head and hosted closeout SHA). All local checks below were re-run by the verifier, not copied from SUMMARY/ACCEPTANCE.

## Goal Achievement

### Observable Truths (ROADMAP success criteria, the contract)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Audited task/support-module inventory lives under unpackaged `dev/mix/tasks`; neither the archive nor a compiled consumer contains repository-only verifier modules (PKGH-01) | VERIFIED | `git ls-files dev` lists 53 files (41 top-level `verify*.ex` plus 12 under `verify/`); `git ls-files lib/mix/tasks` lists only the 8 `scrypath.*` public tasks. `grep Verify lib` (outside the scrypath tasks) is empty. `mix hex.build --unpack` under `MIX_ENV=prod`: top level is exactly ARCHITECTURE.md, CHANGELOG.md, CONTRIBUTING.md, LICENSE, README.md, SECURITY.md, docs, guides, hex_metadata.config, lib, mix.exs; `lib/mix/tasks` holds only the 8 public task files; `grep "Mix.Tasks.Verify"` over the unpack matches only CHANGELOG.md history. Independent compiles with `MIX_BUILD_PATH` outside the checkout: `MIX_ENV=prod` and `MIX_ENV=dev` both exit 0 with 0 `Elixir.Mix.Tasks.Verify*.beam` and 8 `Elixir.Mix.Tasks.Scrypath.*.beam`. |
| 2 | Documented canonical/historical source-checkout commands remain callable in their intended environments; an unpacked package compiles with no development tree (PKGH-02) | VERIFIED | From the default env (no `MIX_ENV`): `mix verify.adopter` exit 0 (25 tests, 0 failures), `mix verify.namespace_fence` exit 0, `mix verify.workspace_clean` exit 0 (17 pathspecs). `mix.exs` `elixirc_paths(:test) -> ["lib","dev/mix/tasks"]`, `elixirc_paths(_) -> ["lib"]`; `cli/0` `preferred_envs` routes every verify task (including `verify.core`, `verify.package`, `verify.repository_contracts`, `verify.namespace_fence`) to `:test`, and `verify_capability_test.exs` passes in the fast suite. `describe "unpacked archive compiles without the dev tree"` (prod and test, warning-free, exactly the public task beams) ran inside my `MIX_ENV=test mix verify.package` (exit 0, 104 tests, 0 failures). Fast suite: `mix test --exclude integration` exit 0, 5 properties, 1059 tests, 0 failures. `mix format --check-formatted` exit 0. No workflow runs a verify task under a non-test `MIX_ENV`. `verify.release_parity` still compares only `lib/ guides/ docs/` between tag and tarball, so the move does not break release parity. |
| 3 | The package/parity gate inspects actual archive/consumer behavior, fails if maintainer tooling leaks back, and proves supported public operator tasks remain usable (PKGH-03) | VERIFIED | `dev/mix/tasks/verify.phase11.ex` runs `package_contents_test.exs` and `consumer_smoke_test.exs` as part of `verify.package` (the required `package` CI job and both publish workflows). `Scrypath.Release.PackageContract` (test/support, never packaged) parses the real `hex.build --unpack` output: forbidden top-level entries, unexpected `Mix.Tasks.*` modules, and missing public tasks each produce a tagged failure line. `package_contents_test.exs` holds a control plus five mutations on real unpack output (extra `scrypath.*` task, `verify.sneaky`, hidden task in an ordinary lib file, `dev` in `files:`, deleted public task). `consumer_smoke_test.exs:95-135` compiles a release-like consumer, asserts 0 Verify beams, asserts the `scrypath.app` module list equals the 8 public tasks, and asserts `mix verify.package` is "could not be found" in the consumer. Orchestrator mutation probe (dropping `Mix.Tasks.Verify.ZzProbe` into `lib/`) produced an `[unexpected-task]` failure; the verifier's own run confirms the test lines that implement it. |

**Score:** 3/3 truths verified; 0 behavior-unverified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `dev/mix/tasks/**` (53 files) | Full maintainer task tree outside the package | VERIFIED | Present; none under `lib/mix/tasks/verify*`; `dev` not in `package[:files]` (asserted by `tooling boundary` test). |
| `mix.exs` | Env-keyed `elixirc_paths`, `preferred_envs` | VERIFIED | Read directly; matches truth 2. |
| `test/support/release/package_contract.ex` | Fail-closed archive contract | VERIFIED | 161 lines, real classifier plus AST walker, not a stub. |
| `test/release/package_contents_test.exs` | Classifier, drift, boundary, packaged-docs, real-archive, compile tests | VERIFIED | 490 lines; all describes ran green in `verify.package`. |
| `test/release/consumer_smoke_test.exs` | Compiled-consumer behavior | VERIFIED | 333 lines; ran green. |
| `test/support/repo_tooling.ex` | Location-independent repo root helper | VERIFIED | Exercised by the green fast suite. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `verify.package` / `verify.phase11` | `package_contents_test.exs`, `consumer_smoke_test.exs` | `run_test!` list in `dev/mix/tasks/verify.phase11.ex` | WIRED | Lines 28-33; pinned by docs_contract_test. |
| CI `package (required)` job | `mix verify.package` | `.github/workflows/ci.yml:158`, both publish workflows | WIRED | Hosted run 40702781515: `package (required)` success. |
| `mix.exs` `package[:files]` | `PackageContract.@allowed_top_level` | drift-guard test | WIRED | `allowed_top_level mirrors ...` test green. |
| `cli/0` `preferred_envs` | every `use Mix.Task` under `dev/mix/tasks` named `Verify*` | `verify_capability_test.exs` | WIRED | Green (but see WR-02 advisory on name-based selection). |

### Data-Flow Trace (Level 4)

Not applicable: build/packaging tooling, no rendered dynamic data.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Package gate end to end | `MIX_ENV=test mix verify.package` | exit 0, `104 tests, 0 failures`, tarball built | PASS |
| Unpacked archive contents | `MIX_ENV=prod mix hex.build --unpack` plus find/grep | 8 public task files only; no Verify source | PASS |
| Prod and dev compile leak check | `MIX_ENV={prod,dev} MIX_BUILD_PATH=<scratch> mix compile` | exit 0; 0 Verify beams; 8 Scrypath task beams | PASS |
| Path-dependency consumer | `examples/phoenix_meilisearch`: `mix deps.get`, cold `MIX_ENV=dev MIX_BUILD_PATH=<scratch> mix compile` | exit 0; 0 Verify beams; 8 Scrypath task beams; example tracked files unchanged | PASS |
| Documented commands | default-env `mix verify.adopter` / `verify.namespace_fence` / `verify.workspace_clean` | exit 0 each (25 tests / fence passed / 17 pathspecs) | PASS |
| Fast suite and format | `mix test --exclude integration`; `mix format --check-formatted` | 1059 tests, 0 failures; format clean | PASS |
| Repository contracts | `mix verify.repository_contracts` | 98 tests, 0 failures | PASS |
| BEAM cache script | `node --test scripts/ci/beam_cache.test.cjs` | 10 pass, 0 fail | PASS |

### Probe Execution

No phase-declared `probe-*.sh` scripts. SKIPPED (not applicable).

### Hosted Evidence (exact SHA)

`gh run view 40702781515`: run SHA `9fb1ec35c8908f4771399ae1ed47d333711ebd45`, event `workflow_dispatch`, conclusion success. Required jobs `core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted` all success; `closeout-attestation` success; all compatibility, `coverage`, `phoenix-example`, `ecommerce-e2e` advisory jobs success. Only `deep-quality (advisory)` failed. I confirmed the orchestrator's claim from the job log: the root graph audit is `status=clean`; the failure is `dependency-audit graph=examples/phoenix_meilisearch status=affected` with `bandit 1.13.1 VULNERABLE` (EEF-CVE-2026-111101 HIGH and others) in the example lockfiles. That is the pre-existing dependency-audit debt the roadmap assigns to Phase 184, unrelated to packaging. HEAD differs from `9fb1ec35` only by `.planning/` documentation commits (verified from git log; source identity unchanged).

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|--------------|-------------|--------|----------|
| PKGH-01 | 183-01, 183-04, 183-05, 183-06, 183-08 | No repository-only verify task source or support modules in archive or compiled dependency; inventory under `dev/mix/tasks` | SATISFIED | Truth 1 |
| PKGH-02 | 183-01, 183-02, 183-03, 183-04, 183-05, 183-07, 183-08 | Documented canonical and historical verification commands work from a checkout; unpacked package compiles without the dev tree | SATISFIED | Truth 2 |
| PKGH-03 | 183-05, 183-06, 183-08 | Package/parity gate proves actual unpacked archive excludes tooling, retains public tasks, fails on leaks | SATISFIED | Truth 3 |

All three IDs appear in REQUIREMENTS.md (lines 32-34, traceability rows 123-125, Phase 183) and map to this phase's plans. No orphaned requirements: REQUIREMENTS.md assigns only PKGH-01..03 to Phase 183.

### Anti-Patterns Found

Debt-marker scan (TBD/FIXME/XXX) over phase-modified implementation files found no unreferenced markers that gate the goal. No stubs; the PackageContract and tests are substantive.

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| website pages (see WR-04) | Stale `mix verify.adopter` adopter copy | Warning | Not part of PKGH requirements or the package; accurate for published 0.3.17; must be fixed before the next release |
| `test/support/release/package_contract.ex` | L1 AST scan misses aliased/`Elixir.`-prefixed/atom names (WR-03) | Warning | Backstopped by L2 in consumer_smoke (module list and beam count); no leak today |
| `test/mix/tasks/verify_capability_test.exs` | Guard selects by `Verify` prefix, not location (WR-02) | Warning | Hardening; no current task is missed (PKGH-02 holds for all 53 files today, including `verify.namespace_fence`) |
| `mix.exs` | No unit test pinning `elixirc_paths(non-test)` (WR-01) | Warning | Leak would be caught by consumer_smoke L2; my prod/dev compiles show 0 Verify beams |

### Weighing the advisory artifacts

- **183-SECURITY.md** (`threats_open: 0`, `status: verified`): supports the goal; no blocker.
- **183-VALIDATION.md** (`nyquist_compliant: false`): two gaps are one-shot evidence, not missing behavior: the cold path-dep compile of `examples/phoenix_meilisearch` (I re-ran it independently: 0 Verify beams, 8 public beams) and the D-07 `@moduledoc false` count (27 present in `dev/`, docs builds clean in the closeout per ACCEPTANCE). Neither undermines a PKGH requirement; both are optional durable-test follow-ups.
- **183-REVIEW.md** (0 critical, 4 warnings, 5 info; all dispositions `open`): none is a failed must-have. WR-01/02/03 are guard-hardening items whose backstops I confirmed; WR-04 is out-of-package website copy. Recommended before the next Hex release, not before closing this phase.

### Human Verification Required

None. Every truth is backed by executable evidence re-run in this verification or by the exact-SHA hosted run (AGENTS.md policy).

### Gaps Summary

No gaps. The goal holds: the 53-file maintainer task tree lives in `dev/mix/tasks` and compiles only under `MIX_ENV=test`; the actual unpacked archive and compiled `:prod`/`:dev` dependency builds contain exactly the 8 public operator tasks and no Verify modules; the documented contributor commands run from a source checkout via `preferred_envs`; and the required `package` gate, which fails closed on leakage, is green locally and at the exact hosted SHA. Known limits (stated honestly in ACCEPTANCE): published 0.3.17 and its HexDocs still contain the verifiers until a separate maintainer-confirmed release, `mix help verify.*` needs `MIX_ENV=test`, and the `verify.release_parity` contents-check attachment is a deferred follow-up. Open review items (WR-01..04, IN-01..05) should be triaged, with WR-04 fixed before the next release.

---

_Verified: 2026-10-28_
_Verifier: Claude (gsd-verifier)_
