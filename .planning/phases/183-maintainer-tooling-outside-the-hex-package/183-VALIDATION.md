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

---

## Per-Task Verification Map

Filled by the planner/executor; requirement → command map from RESEARCH.md § Validation Architecture:

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| PKGH-01 | Inventory under `dev/mix/tasks`; `lib/mix/tasks/verify*` empty; `dev` not in `files:` | unit (boundary guard) | `mix test test/release/package_contents_test.exs` | ❌ W0 | ⬜ pending |
| PKGH-01 | Unpacked archive holds exactly the 8 public task modules + allowed top-level entries | integration | `mix test test/release/package_contents_test.exs` | ❌ W0 | ⬜ pending |
| PKGH-01 | Compiled consumer has 8 public tasks, no `Elixir.Mix.Tasks.Verify.*.beam` | integration | `mix test test/release/consumer_smoke_test.exs` | ✅ extend | ⬜ pending |
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
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
