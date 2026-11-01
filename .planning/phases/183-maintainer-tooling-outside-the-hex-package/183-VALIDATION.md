---
phase: "183"
slug: "maintainer-tooling-outside-the-hex-package"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-27"
---

# Phase 183 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.x in CI); `node:test` for `scripts/ci/*.test.cjs` |
| **Config file** | `test/test_helper.exs`; `mix.exs` `test_ignore_filters` + custom `test` alias |
| **Quick run command** | `mix test test/release/package_contents_test.exs --only "describe:tooling boundary"` |
| **Full suite command** | `mix test --exclude integration --exclude docs_contract` plus gates `mix verify.package`, `mix verify.core --exclude integration --exclude docs_contract`, `mix verify.repository_contracts` |
| **Measured runtime (2026-11-01)** | 0.1 s tooling boundary; 28.2 s cold Phoenix path consumer; 140.9 s package contract tests; 578.1 s full fast-suite attempt (permission failure, resolved by focused retest below) |

Local re-audit toolchain: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS="+S 4"`. Use elevated Git-metadata access for the full fast suite: its trusted-history test fetches remote history, just like the canonical repository-contracts gate.

---

## Sampling Rate

- **After every task commit:** focused test file(s) for touched files, plus `mix format --check-formatted` and `mix credo --strict`
- **After every plan wave:** `mix test --exclude integration` and `mix verify.package`
- **Before `/gsd-verify-work`:** phase gate green — `mix verify.core --exclude integration --exclude docs_contract`, `mix verify.package`, `mix verify.repository_contracts`, `node --test scripts/ci/beam_cache.test.cjs`, `MIX_ENV=test mix docs --warnings-as-errors`, `MIX_ENV=dev mix docs --warnings-as-errors`, then exact-SHA hosted CI
- **Max feedback latency:** 30 seconds for unit-only feedback; real consumer and canonical gates have the named exceptions below
- **Closeout-only gates (exempt from the 30 s budget):** the full `mix verify.core --exclude integration --exclude docs_contract`, both docs builds, the documented-command resolution loop and the exact-SHA hosted closeout. During the original execution each ran once, in 183-08 Task 1 or Task 2, not as a per-task sample; no other plan runs them as a `<verify>` command (183-07 checks the packaged-docs guard with `--only "describe:packaged docs"` and leaves both docs builds to 183-08). Per-wave sampling stays on `mix verify.package`.
- **Named per-task exceptions (may exceed the 30 s budget; original execution times remain in the SUMMARYs):**
  - Re-audit addition: the cold Phoenix path-dependency compile is now a durable, always-discovered test in `package_contents_test.exs`, run by the existing package gate and fast suite. It has a 180 s timeout and private temporary build/dependency/Hex directories. Its focused clean run took 28.2 s; archive compiles plus this test may exceed the unit feedback budget. Locked dependency resolution needs the Hex registry; no database or search service starts.
  - 183-04 Task 1, the one-time move-commit gates: the D-16 full fast suite (`MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration`), because D-16 requires every commit green and the move touches every path-coupled test; `MIX_ENV=dev mix compile --warnings-as-errors` with the ebin count, which is the only proof of D-05's packaged surface and is a full compile when `_build/dev` is cold; and the documented-command run (`mix verify.adopter && mix verify.namespace_fence && mix test test/mix/tasks/verify_adopter_test.exs`), because PKGH-02 must be proven by running the documented commands themselves.
  - 183-05 Tasks 2 and 3: focused runs of `test/release/package_contents_test.exs`, whose "unpacked archive compiles without the dev tree" describe performs two real compiles of packaged `lib/` (PKGH-02 has no cheaper proof); and Task 3's `MIX_ENV=test mix verify.package`, the single D-12 integration proof that the required lane runs the gate.
  - 183-06 Tasks 1 and 2: focused runs of `test/release/consumer_smoke_test.exs`, which builds a real archive, resolves deps over the network, compiles a fresh consumer and runs about a dozen consumer subprocesses (D-10 L2 needs a real installed consumer).
  - Not a sample: the 183-05 Task 3 pre-move evidence run (D-16 step 4) is an acceptance criterion, not a `<verify>` command, so it is outside the per-task budget.
  - `mix verify.package` was estimated at about 19 s before this phase. With the contents gate and the extended consumer smoke it may exceed 30 s; per-wave sampling still uses it, and its wall time is recorded in the 183-05 and 183-06 SUMMARYs.

---

## Per-Task Verification Map

Filled by the planner/executor; requirement → command map from RESEARCH.md § Validation Architecture:

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| PKGH-01 | Inventory under `dev/mix/tasks`; `lib/mix/tasks/verify*` empty; `dev` not in `files:` | unit (boundary guard) | `mix test test/release/package_contents_test.exs` | ✅ | ✅ green |
| PKGH-01 | Unpacked archive holds exactly the 8 public task modules + allowed top-level entries | integration | `mix test test/release/package_contents_test.exs` | ✅ | ✅ green |
| PKGH-01 | Compiled consumer has 8 public tasks, no `Elixir.Mix.Tasks.Verify.*.beam` | integration | `mix test test/release/consumer_smoke_test.exs` | ✅ | ✅ green |
| PKGH-01 | Real Phoenix path consumer compiles cold with its full `dev/` dependency tree present, exactly 8 public task beams/app modules, no verifier beams, and unchanged locks | integration (no live services) | `mix test test/release/package_contents_test.exs --only "describe:path-dependency consumer"` | ✅ | ✅ green |
| PKGH-02 | Documented verifiers do not become hidden: preserve the 27 historical hidden module identities and explicitly account for the later Phase 185 private validator | compiled documentation contract | `mix test test/release/package_contents_test.exs --only "describe:tooling boundary"` | ✅ | ✅ green |
| PKGH-02 | Every `use Mix.Task` in `dev/mix/tasks` has `:test` preferred_env | unit | `mix test test/mix/tasks/verify_capability_test.exs` | ✅ | ✅ green |
| PKGH-02 | Documented focused commands still callable | existing | `mix test test/mix/tasks/ test/scrypath/readiness_contract_test.exs` | ✅ | ✅ green |
| PKGH-02 | Unpacked archive compiles without `dev/` (`prod`, `test`, `--warnings-as-errors`) | integration | `mix test test/release/package_contents_test.exs` | ✅ | ✅ green |
| PKGH-02 | Source-reading contract tests find moved sources | unit | `mix test test/scrypath/docs_contract_test.exs test/scrypath/phase99_contract_test.exs test/mix/tasks/` | ✅ | ✅ green |
| PKGH-03 | Five leak mutations fail; control passes | integration (mutation) | `mix test test/release/package_contents_test.exs` | ✅ | ✅ green |
| PKGH-03 | Public operator tasks usable from installed package | integration | `mix test test/release/consumer_smoke_test.exs` | ✅ | ✅ green |
| PKGH-03 | Gate runs in required lane and is pinned | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ✅ green |
| D-08 | `dev/` edits change BEAM cache graph keys | node unit | `node --test scripts/ci/beam_cache.test.cjs` | ✅ | ✅ green |
| D-08 | `verify.workspace_clean`/HYG-02 cover `dev/**` | unit | `mix test test/mix/tasks/verify_workspace_clean_test.exs test/mix/tasks/workflow_wiring_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky / one-shot only (no durable regression test). Current green statuses use the re-audit evidence below; original closeout reports retain their original source identities.*

---

## Wave 0 Requirements

- [x] `test/support/repo_tooling.ex` — `Scrypath.RepoTooling` path helper (PKGH-02)
- [x] `test/support/release/package_contract.ex` — `Scrypath.Release.PackageContract` (PKGH-01, PKGH-03)
- [x] `test/release/package_contents_test.exs` — control, five mutations, boundary guard, archive compile cases
- [x] `test/mix/tasks/verify_namespace_fence_test.exs` — moved/renamed fence test
- [x] D-04 preferred_envs guard test
- [x] `scripts/ci/beam_cache.test.cjs` fixture for `dev/`

---

## Manual-Only Verifications

All phase behaviors in the map have automated verification. Both former one-shot-only gaps now run in the existing required package gate; no human verification or new CI lane was added.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Unit-only feedback stays within 30 s; real cold compiles and canonical gates use the explicit exceptions under Sampling Rate
- [x] `nyquist_compliant: true` set in frontmatter — all 14 behavior rows have durable checks; both former gaps resolved

**Validation:** compliant on 2026-11-01 — 14 durable behavior rows, no remaining one-shot-only gaps. The maintainer selected “Fix both gaps”; this is automated validation, not a new product/design approval. The 2026-10-28 partial audit remains below as history.

The maintainer authorized the milestone audit's recommended metadata reconciliation on 2026-11-01. The frontmatter now matches this sign-off and the retained positive/negative test evidence below. This correction changes no test or implementation and makes no new suite or hosted-execution claim.


## Re-audit Evidence — 2026-11-01

### Task traceability

All eight PLANs and SUMMARYs were reviewed. The two added tests close the original 183-08 Task 1 path-consumer obligation (wave 6, PKGH-01) and 183-07 Task 1 visibility-preservation obligation (wave 5, PKGH-02).

| Source tasks | Wave | Requirements | Durable regression coverage |
|---|---|---|---|
| 183-01 Task 1 | 1 | PKGH-01, PKGH-02 | Package contents, namespace-fence and capability tests |
| 183-02 Tasks 1–2 | 1 | PKGH-01, PKGH-02 | Workspace-clean/workflow-wiring tests and BEAM cache tests |
| 183-03 Tasks 1–2 | 2 | PKGH-02 | Docs/phase99 contracts and verifier task suites through RepoTooling |
| 183-04 Tasks 1–2 | 3 | PKGH-01, PKGH-02 | Tooling-boundary and preferred-env tests |
| 183-05 Tasks 1–3 | 4 | PKGH-01, PKGH-02, PKGH-03 | Classifier/drift guards, real archive mutations/compiles, package metadata and gate-wiring contracts |
| 183-06 Tasks 1–2 | 5 | PKGH-01, PKGH-03 | Real archive consumers, compiled task surfaces and CLI probes |
| 183-07 Tasks 1–2 | 5 | PKGH-01, PKGH-02 | Packaged-docs contracts and new compiled documentation-visibility guard |
| 183-08 Task 1 | 6 | PKGH-01, PKGH-02, PKGH-03 | New cold path-consumer check plus existing canonical gates |
| 183-08 Task 2 | 6 | PKGH-03 | Existing CI/release wiring contracts; historical exact-source delivery/closeout receipts remain in ACCEPTANCE and SUMMARY, not relabeled as fresh evidence |

### New behavioral checks and adversarial probes

Both checks live in `test/release/package_contents_test.exs`, already selected by `verify.phase11` → `verify.package`. They run without an integration opt-in. No implementation, gate wiring, lockfile, published surface or dependency requirement changed.

- **PKGH-01:** Stage the actual Phoenix example and source dependency in a temporary checkout preserving `path: "../.."`, including the complete `dev/` tree. Resolve its checked lock, compile from an absent build directory under `MIX_ENV=dev`, and require exactly the eight public task beams and the same eight task names in `scrypath.app`. Both source and staged locks must remain unchanged. A disposable mutation making non-test `elixirc_paths` include `dev/mix/tasks` failed specifically at `assert beams == expected`, listing leaked verifier beams. The clean focused case passed in 28.2 s.
- **PKGH-02:** Discover verifier module identities from `lib/` and `dev/` and inspect their compiled documentation chunks through `Code.fetch_docs/1`. Require the precise 27 historically hidden modules plus the explicitly separated `Mix.Tasks.Verify.UiTokens`, added in Phase 185. Thus today's total is 28; the historical 27 is not rewritten, and swapping which task is hidden cannot evade a count-only assertion. A disposable mutation replacing Adopter's real module documentation with `@moduledoc false` failed with “verifier documentation visibility changed”. The clean tooling-boundary describe passed (2 tests, 0 failures).

The first cold-consumer fixture run attempted a global Hex cache write and failed with `:eaccess`. One fixture correction added a private temporary `HEX_HOME`; the next focused run passed. No implementation bug was found or repaired. Mutation probes changed only disposable source copies and removed their checkout afterward.

### Fresh verification and limits

Test source was prepared over `db572eb132bd8098cf96d762eb967fa66d636bed` and committed unchanged as `7da41b25`. Its SHA-256 is `62a8d08224b4c45d2132316a6b08b05d84448f9d67cbd1297ae8eb27fd187680`. Later writes in this audit affect only this report. Nested snapshot-based contrast tests retained their original committed input; the new path and documentation cases ran directly against the current working tree. Historical phase closeout receipts are not claims about this new commit.

| Command/check | Actual result |
|---|---|
| `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract` | 5 properties, 1041 tests, 1 failure, 103 excluded; 578.1 s. The sole failure was the production UI literal history check being denied `.git/FETCH_HEAD` access. This attempt is **not** reported as a green full-suite command. |
| Same command with `--failed`, using authorized Git-metadata access | 1 test selected, 0 failures, 1.0 s. Resolves the sole full-suite failure; the whole suite was not repeated. |
| `mix test --warnings-as-errors test/mix/tasks/ui_literal_contract_test.exs` with required access | 3 tests, 0 failures, 31.6 s; independently confirms the permission cause. |
| `mix verify.package` | Exit 0; 110 release contract tests, 0 failures, 140.9 s, followed by successful release-wiring checks and real archive build. Includes both new cases and existing archive/consumer/docs-contract cases. |
| `mix test --warnings-as-errors test/scrypath/phase99_contract_test.exs test/scrypath/readiness_contract_test.exs` | 19 tests, 0 failures. |
| `node --test scripts/ci/beam_cache.test.cjs` | 12 tests, 0 failures. |
| `mix format --check-formatted`; `mix credo --strict`; `git diff --check` | Exit 0; no Credo issues. |
| New cases, individually | Both green; expected source-mutation assertions rejected both regressions in disposable checkouts. |
| `git diff --quiet -- lib dev mix.exs mix.lock examples/phoenix_meilisearch` | Exit 0; implementation, dependency declarations/locks and original example remained unchanged. |

The generated release-consumer lock evaluations emit existing quoted-key warnings; no warning-free claim is made for their subprocess output. Temporary logs and the mutation runner are under `/private/tmp/scrypath-phase183-validation-20261101/` (`package.log`, `fast-failed-retest.log`, `ui-literal-focused.log`, `hidden-documented-verifier.log`, `path-consumer-leak.log`, `mutation_probes.py`). The full-suite attempt's output is in this session's execution transcript.

This re-audit closes validation debt only. It does not renew a Phase 185 terminal attestation, archive the milestone, merge/release, change the retained preview stop, or infer independent aesthetic approval. Unrelated planning config and untracked milestone-audit files were preserved and excluded from commits.

## Validation Audit 2026-10-28

| Metric | Count |
|---|---|
| Gaps found | 2 |
| Resolved | 0 |
| Escalated | 2 |

## Validation Audit 2026-11-01

| Metric | Count |
|---|---|
| Gaps found | 2 |
| Resolved | 2 |
| Escalated | 0 |
