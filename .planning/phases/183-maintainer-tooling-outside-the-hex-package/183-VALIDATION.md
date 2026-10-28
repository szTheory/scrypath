---
phase: "183"
slug: "maintainer-tooling-outside-the-hex-package"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Quick run command** | `mix test test/release/package_contents_test.exs test/release/package_metadata_test.exs` |
| **Full suite command** | `mix test --exclude integration` plus gates `mix verify.package`, `mix verify.core --exclude integration --exclude docs_contract`, `mix verify.repository_contracts` |
| **Estimated runtime** | ~25 seconds (fast suite); ~19 seconds (`mix verify.package`) |

Local shell note: set `ASDF_ELIXIR_VERSION=1.19.5-otp-28` and `ASDF_ERLANG_VERSION=28.1` (no default set).

---

## Sampling Rate

- **After every task commit:** focused test file(s) for touched files, plus `mix format --check-formatted` and `mix credo --strict`
- **After every plan wave:** `mix test --exclude integration` and `mix verify.package`
- **Before `/gsd-verify-work`:** phase gate green — `mix verify.core --exclude integration --exclude docs_contract`, `mix verify.package`, `mix verify.repository_contracts`, `node --test scripts/ci/beam_cache.test.cjs`, `MIX_ENV=test mix docs --warnings-as-errors`, `MIX_ENV=dev mix docs --warnings-as-errors`, then exact-SHA hosted CI
- **Max feedback latency:** 30 seconds
- **Closeout-only gates (exempt from the 30 s budget):** the full `mix verify.core --exclude integration --exclude docs_contract`, both docs builds, the documented-command resolution loop, the cold path-dependency consumer compile of `examples/phoenix_meilisearch` (about 13 s cold at planning time) and the exact-SHA hosted closeout. Each runs once, in 183-08 Task 1 or Task 2, not as a per-task sample; no other plan runs them as a `<verify>` command (183-07 checks the packaged-docs guard with `--only "describe:packaged docs"` and leaves both docs builds to 183-08). Per-wave sampling stays on `mix verify.package`.
- **Named per-task exceptions (may exceed the 30 s budget; each plan records its wall time in its SUMMARY):**
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
| PKGH-01 | Inventory under `dev/mix/tasks`; `lib/mix/tasks/verify*` empty; `dev` not in `files:` | unit (boundary guard) | `mix test test/release/package_contents_test.exs` | ❌ W0 | ⬜ pending |
| PKGH-01 | Unpacked archive holds exactly the 8 public task modules + allowed top-level entries | integration | `mix test test/release/package_contents_test.exs` | ❌ W0 | ⬜ pending |
| PKGH-01 | Compiled consumer has 8 public tasks, no `Elixir.Mix.Tasks.Verify.*.beam` | integration | `mix test test/release/consumer_smoke_test.exs` | ✅ extend | ⬜ pending |
| PKGH-01 | In-repo path-dep consumer `examples/phoenix_meilisearch` compiles cold with 0 Verify beams and the 8 public task beams (CONTEXT Integration Points) | integration (closeout-only) | 183-08 Task 1 path-dep gate (`mix deps.get`, then `MIX_ENV=dev mix compile` with `MIX_BUILD_PATH` set to a cold out-of-checkout dir, then `find` on its scrypath ebin) | ✅ existing app | ⬜ pending |
| PKGH-02 | No Verify module gains `@moduledoc false` (D-07): count over lib/ and dev/ stays 27 | unit (grep count) | 183-07 Task 1 preservation gate | ✅ | ⬜ pending |
| PKGH-02 | Every `use Mix.Task` in `dev/mix/tasks` has `:test` preferred_env | unit | `mix test test/mix/tasks/verify_capability_test.exs` | ❌ W0 | ⬜ pending |
| PKGH-02 | Documented focused commands still callable | existing | `mix test test/mix/tasks/ test/scrypath/readiness_contract_test.exs` | ✅ | ⬜ pending |
| PKGH-02 | Unpacked archive compiles without `dev/` (`prod`, `test`, `--warnings-as-errors`) | integration | `mix test test/release/package_contents_test.exs` | ❌ W0 | ⬜ pending |
| PKGH-02 | Source-reading contract tests find moved sources | unit | `mix test test/scrypath/docs_contract_test.exs test/scrypath/phase99_contract_test.exs test/mix/tasks/` | ✅ | ⬜ pending |
| PKGH-03 | Five leak mutations fail; control passes | integration (mutation) | `mix test test/release/package_contents_test.exs` | ❌ W0 | ⬜ pending |
| PKGH-03 | Public operator tasks usable from installed package | integration | `mix test test/release/consumer_smoke_test.exs` | ✅ extend | ⬜ pending |
| PKGH-03 | Gate runs in required lane and is pinned | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ update | ⬜ pending |
| D-08 | `dev/` edits change BEAM cache graph keys | node unit | `node --test scripts/ci/beam_cache.test.cjs` | ✅ extend | ⬜ pending |
| D-08 | `verify.workspace_clean`/HYG-02 cover `dev/**` | unit | `mix test test/mix/tasks/verify_workspace_clean_test.exs test/mix/tasks/workflow_wiring_test.exs` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/repo_tooling.ex` — `Scrypath.RepoTooling` path helper (PKGH-02)
- [ ] `test/support/release/package_contract.ex` — `Scrypath.Release.PackageContract` (PKGH-01, PKGH-03)
- [ ] `test/release/package_contents_test.exs` — control, five mutations, boundary guard, archive compile cases
- [ ] `test/mix/tasks/verify_namespace_fence_test.exs` — moved/renamed fence test
- [ ] D-04 preferred_envs guard test
- [ ] `scripts/ci/beam_cache.test.cjs` fixture for `dev/`

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s, apart from the named per-task exceptions listed under Sampling Rate
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
