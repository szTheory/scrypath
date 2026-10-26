---
phase: 181-schema-hook-contract-and-no-oban-build
verified: 2026-10-26T00:00:00Z
status: passed
score: 15/15 must-haves verified
covered_files:
  - ".planning/phases/181-schema-hook-contract-and-no-oban-build/181-01-PLAN.md"
  - ".planning/phases/181-schema-hook-contract-and-no-oban-build/181-01-SUMMARY.md"
  - ".planning/phases/181-schema-hook-contract-and-no-oban-build/181-02-PLAN.md"
  - ".planning/phases/181-schema-hook-contract-and-no-oban-build/181-02-SUMMARY.md"
  - "CONTRIBUTING.md"
  - "lib/mix/tasks/verify.no_optional_deps.ex"
  - "lib/mix/tasks/verify/capability.ex"
  - "lib/scrypath/oban/enqueue.ex"
  - "lib/scrypath/schema.ex"
  - "lib/scrypath/sync/related_enqueue.ex"
  - "test/mix/tasks/verify_capability_test.exs"
  - "test/mix/tasks/verify_no_optional_deps_test.exs"
  - "test/mix/tasks/workflow_wiring_test.exs"
  - "test/scrypath/schema_test.exs"
covered_digest: "v3:sha256:00dd65f2e59eba1dc3c2c7f31757e82719838c216733ead3b7dac5c41c3fc9e7"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 181: Schema hook contract and no-Oban build Verification Report

**Phase Goal:** Adopters see and get compiler checks for the schema hooks they can implement, and apps without Oban compile Scrypath with zero warnings.
**Verified:** 2026-10-26 (worktree at HEAD b9b11d53, Elixir 1.19.0 / OTP 28.1)
**Status:** passed
**Re-verification:** No, this is the first verification.

## Goal Achievement

### Roadmap Success Criteria

| # | Success criterion | Status | Evidence |
|---|-------------------|--------|----------|
| SC1 | Hooks are declared `@optional_callbacks` on a behaviour that appears in HexDocs, and a test or compile check flags a wrong-arity hook | VERIFIED | `lib/scrypath/schema.ex` declares 3 `@callback`s with `@optional_callbacks [search_document: 1, search_document_id: 1, search_records: 2]`. `mix docs --warnings-as-errors` exits 0, and `doc/Scrypath.Schema.html` has the anchors `c:search_document/1`, `c:search_document_id/1` and `c:search_records/2` under Callbacks. `__before_compile__/1` sends `IO.warn` at the def line. It is pinned by `schema_test.exs:171` and passes. |
| SC2 | A no-Oban build compiles with `--warnings-as-errors`, with no blanket suppression, inside an existing CI lane | VERIFIED | `mix verify.no_optional_deps` exits 0. The isolated `_build/no_optional_deps/lib` has no `oban` directory and no `UpsertWorker.beam`. In `lib/`, `no_warn_undefined` appears only at 3 Oban-only sites, and there is no `elixirc_options`, no `Code.put_compiler_option` and no `put_attribute(:compile)`. The call chain is `ci.yml` core (required) → `mix verify.core` → `Capability.run_core/2` → `verify.no_optional_deps`. `.github/` is unchanged since f21cd4b1. |

### Observable Truths (PLAN must_haves)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | HYG-02: isolated MIX_BUILD_PATH, prod, `--no-optional-deps --warnings-as-errors`, exits 0 on 1.19.0/OTP 28.1 | VERIFIED | I ran it: EXIT=0, "Compiling 148 files", "Verified optional dependencies absent from isolated build: oban". `compile_env/1` returns `MIX_ENV=prod` plus `MIX_BUILD_PATH`. |
| 2 | Anti-false-green: raises if `lib/oban` or `UpsertWorker.beam` is present | VERIFIED | `assert_optional_deps_absent!/2` is called after the compile. Seam tests `verify_no_optional_deps_test.exs:32` and `:41` pass. |
| 3 | RED proof that names `lib/scrypath/sync.ex:74` | VERIFIED | Recorded in 181-01-SUMMARY "RED evidence". I also reproduced it myself in a throwaway worktree at b219ee8a: RED_EXIT=1, `incompatible types given to decorate_result/2 ... lib/scrypath/sync.ex:74:12`. |
| 4 | RelatedEnqueue is one unconditional module using `Enqueue.job_changeset/4`; same worker, queue, max_attempts and unique | VERIFIED | `related_enqueue.ex` has no compile-time branch and calls `Enqueue.job_changeset(..., @worker = "Scrypath.Sync.RelatedWorker", config, [])`. The builder sets queue `to_string(Config.oban_queue)`, max_attempts and `unique: unique_opts()`. Tests in `related_test.exs` pass. |
| 5 | `run(:core, args)` runs `verify(args)` then `verify.no_optional_deps([])`; ci.yml is unchanged | VERIFIED | `capability.ex` `run_core/2`. The test `verify_capability_test.exs:71` passes. `git diff f21cd4b1 HEAD -- .github` is empty. |
| 6 | No blanket suppression contract test | VERIFIED | The 3 tests at `workflow_wiring_test.exs:11-45` pass. My own grep of `lib/` and `mix.exs` confirms only Oban `no_warn_undefined` tuples (see WR-03 below for the guard's blind spots). |
| 7 | Oban absent at runtime: `:oban` raises the same ArgumentError | VERIFIED | I observed it directly in the no-Oban build (`MIX_BUILD_PATH=_build/no_optional_deps mix run`). `Code.ensure_loaded?(Oban.Job)` is false, and `Enqueue.job_changeset/4` raises `ArgumentError: Oban dependency is required for sync_mode :oban. Add {:oban, "~> 2.21", optional: true} to your deps.` On the public path, `Config.ensure_oban_ready!/1` raises the same message first. |
| 8 | HYG-01: `behaviour_info(:optional_callbacks)` equals the three hooks | VERIFIED | `schema_test.exs:145` passes |
| 9 | HYG-01 HexDocs: `fetch_docs` has callback entries with docs; `mix docs --warnings-as-errors` passes | VERIFIED | `schema_test.exs:159` passes. `mix docs --warnings-as-errors` gives DOCS_EXIT=0, and the callback anchors are in the rendered HTML. |
| 10 | `use Scrypath` injects `@behaviour Scrypath.Schema` | VERIFIED | `__using__/1` quote. `schema_test.exs:150` passes. |
| 11 | Wrong-arity `search_records/1` gives exactly one warning at the def line | VERIFIED | `schema_test.exs:171` and `:257` pass |
| 12 | No false positives (correct hooks, no hooks, `@impl`, helper at another arity) | VERIFIED | `schema_test.exs:190, 205, 216, 224` pass |
| 13 | A `defp` hook gives Elixir's own diagnostic and no Scrypath one | VERIFIED | `schema_test.exs:238` passes |
| 14 | Drift guard: `function_exported?` probes equal the callback list | VERIFIED | `schema_test.exs:276` passes. `lib/` probes are projection.ex:19,28, loader.ex:42 and identity.ex:20. The variable-name caveat is review IN-05. |
| 15 | Runtime dispatch is unchanged | VERIFIED | `identity.ex`, `projection.ex` and `loader.ex` are not in the phase diff. The full suite `mix test --warnings-as-errors --exclude integration --exclude docs_contract` gives 948 tests, 5 properties, 0 failures. |

**Score:** 15/15 truths verified (0 present-but-behavior-unverified). Both roadmap SCs are verified.

### Prohibitions (judgment tier, with deterministic enforcement evidence)

| Req | Prohibition | Disposition | Enforcement evidence |
|-----|-------------|-------------|----------------------|
| HYG-02 | No diagnostic suppression or type-checker dodges | Holds | The wiring tests (truth 6) and a grep of `lib/` find no `elixirc_options`, `put_compiler_option`, keyword-form `no_warn_undefined` or `put_attribute(:compile)`. The fix is a real type fix: the always-raising stub was removed and the shared builder is guarded at runtime by `Code.ensure_loaded?`. No `apply/3` was added (the `apply` calls in related_worker and upsert_worker are earlier resolver/backend dispatch). |
| HYG-02 | A green run must prove optional deps were absent | Holds | `assert_optional_deps_absent!/2` runs after the compile, and its seam tests pass |
| HYG-02 | No new CI lane and no ci.yml edit | Holds | `.github/` diff is empty, and the check rides the core (required) job |
| HYG-01 | Hooks stay optional and runtime defaults are unchanged | Holds | No-hooks schema compiles silently (`schema_test.exs:216`). Runtime modules are untouched. Full suite is green. |
| HYG-01 | No hard fail without `--warnings-as-errors` | Holds | The check uses `IO.warn` (no raise or CompileError). Tests capture it as a `:warning` diagnostic while compilation succeeds. |

None of these is left unflagged. Each has executable evidence, so none goes to human review.

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `lib/mix/tasks/verify.no_optional_deps.ex` | VERIFIED | Substantive (MIX_BUILD_PATH, seam functions). Wired from `Capability.run_core/2` and the deep_quality sequence. |
| `test/mix/tasks/verify_no_optional_deps_test.exs` | VERIFIED | 7 seam tests pass |
| `lib/scrypath/sync/related_enqueue.ex` | VERIFIED | Uses `Enqueue.job_changeset`. Called from `sync.ex:73`. |
| `lib/scrypath/oban/enqueue.ex` | VERIFIED | `@doc false def job_changeset/4` at line 227 |
| `lib/mix/tasks/verify/capability.ex` | VERIFIED | `def run_core(args, opts \\ [])` |
| `lib/scrypath/schema.ex` | VERIFIED | Has the callbacks, `@optional_callbacks`, `__before_compile__/1`, `__using__` injection and the Hooks moduledoc |
| `test/scrypath/schema_test.exs` | VERIFIED | `describe "hook contract"` with 11 tests, all passing |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `verify/core.ex` | `verify/capability.ex` | `Capability.run(:core, args)` → `run_core` → `"verify.no_optional_deps"` | WIRED |
| `sync.ex` | `related_enqueue.ex` | `RelatedEnqueue.enqueue/4` at sync.ex:73, which type-checks without Oban (the isolated compile is green) | WIRED |
| `related_enqueue.ex` | `oban/enqueue.ex` | `Enqueue.job_changeset(...)` | WIRED |
| `scrypath.ex` → `schema.ex` | `@behaviour Scrypath.Schema` and `@before_compile` | `__using__/1` | WIRED |
| `schema.ex` | loader/identity/projection probes | drift guard test | WIRED |
| `ci.yml` core (required) | `mix verify.core` | ci.yml:35 | WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| No-Oban build is green and self-proving | `mix verify.no_optional_deps` | exit 0, oban absent from isolated build | PASS |
| RED before the fix | same task in a worktree at b219ee8a | exit 1, warning at `sync.ex:74:12` | PASS (fails as expected) |
| Oban-absent runtime error | `MIX_ENV=prod MIX_BUILD_PATH=_build/no_optional_deps mix run -e ...` | ArgumentError, expected message | PASS |
| Hooks render in HexDocs | `mix docs --warnings-as-errors` + anchor grep | exit 0, 3 callback anchors | PASS |
| Phase test files | `mix test` on schema, verify_no_optional_deps, verify_capability, workflow_wiring and related tests | 98 tests, 0 failures | PASS |
| Full non-integration suite (run once) | `mix test --warnings-as-errors --exclude integration --exclude docs_contract` | 948 tests, 5 properties, 0 failures | PASS |

### Probe Execution

None declared. Step 7c: not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| HYG-01 | 181-02 | Hooks declared `@optional_callbacks` on a behaviour, shown in HexDocs, compiler-checked | SATISFIED | Truths 8-15, SC1 |
| HYG-02 | 181-01 | No-Oban build compiles with `--warnings-as-errors`, has a CI check, no blanket suppression | SATISFIED | Truths 1-7, SC2 |

REQUIREMENTS.md maps only HYG-01 and HYG-02 to Phase 181, so there are no orphaned requirements. The traceability rows (REQUIREMENTS.md:77-78) still say `Pending` and the checkboxes are unticked. Closing them is milestone bookkeeping, not a gap.

### Code-Review Findings vs Must-Haves

| Finding | Contradicts a must-have or the goal? | Classification |
|---------|--------------------------------------|----------------|
| WR-01: the `search_document_id/1` doc says `{:error, :search_records_required}`, but `Loader.ensure_loadable!/2` raises `ArgumentError` (confirmed at loader.ex:69-77) | No. Truth 9 needs a non-empty doc, and that holds. But the published callback contract is factually wrong about a hook adopters implement, which weakens "adopters see" the hooks correctly. | WARNING. Fix before release (doc change plus a test that pins the raise). |
| WR-02: the injected `@behaviour` adds new `@impl` warnings for adopters who use `@impl` elsewhere, and there is no CHANGELOG or upgrade note | No. This is a consequence the moduledoc acknowledges. It is a release-notes concern. | WARNING (release notes) |
| WR-03: the `no_warn_undefined` guard regex misses the keyword and multi-line forms | No. Truth 6 names the tuple form, and the tree is clean today (I grepped independently). It is a future-regression blind spot. | WARNING (guard hardening) |
| IN-01 to IN-05 | No | Info |

### Anti-Patterns Found

No TBD, FIXME, XXX or TODO markers in the phase-modified source or test files. No stubs. The old always-raising no-Oban `RelatedEnqueue` stub was removed.

### Human Verification Required

None. Every truth is backed by a test I ran or by behavior I observed. Exact-SHA hosted evidence from the `core (required)` job comes at the phase PR under the ship gate. The CI wiring is already fixed in code and covered by a test, so this is not a UAT item.

### Gaps Summary

No blocking gaps. Phase 181 achieves its goal:
- **Hooks:** the three schema hooks are a documented, compiler-checked optional-callback behaviour.
- **No-Oban build:** it compiles warnings-clean under `--warnings-as-errors` inside the existing required core lane. The check proves Oban was absent from the build and suppresses nothing.

Three review warnings remain open in 181-REVIEW-DISPOSITION.md. WR-01 is the most material, because it misstates a public hook's failure mode. It should be fixed or explicitly dispositioned before release.

---

_Verified: 2026-10-26_
_Verifier: Claude (gsd-verifier)_
