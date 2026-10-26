---
phase: "181"
slug: "schema-hook-contract-and-no-oban-build"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-26"
---

# Phase 181 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.0 / OTP 28.1), `Code.with_diagnostics/1` |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/scrypath/schema_test.exs test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_no_optional_deps_test.exs test/scrypath/sync/related_worker_test.exs` |
| **Full suite command** | `mix verify.core --exclude integration --exclude docs_contract` + `mix verify.package` |
| **Estimated runtime** | ~120 seconds (quick ~20s; no-Oban isolated build ~60s) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command plus `mix verify.no_optional_deps`
- **After every plan wave:** `mix compile --warnings-as-errors --force`, `mix credo --strict`, `mix format --check-formatted`, `mix verify.no_optional_deps`, `mix docs --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green, plus green `core (required)` on the PR's exact SHA
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Req | Behavior | Test Type | Automated Command | Failing direction | File Exists | Status |
|-----|----------|-----------|-------------------|-------------------|-------------|--------|
| HYG-01 | Three hooks are `@optional_callbacks` on `Scrypath.Schema` | unit | `mix test test/scrypath/schema_test.exs` | `behaviour_info/1` undefined today | ✅ extend | ⬜ pending |
| HYG-01 | Callbacks present in docs chunk | unit | same | no `{:callback, …}` docs today | ✅ extend | ⬜ pending |
| HYG-01 | `use Scrypath` modules carry `@behaviour Scrypath.Schema` | unit | same | attribute missing today | ✅ extend | ⬜ pending |
| HYG-01 | Wrong-arity hook flagged at compile | unit | same (`Code.with_diagnostics`) | `[]` diagnostics today | ✅ extend | ⬜ pending |
| HYG-01 | Correct hooks → zero diagnostics | unit | same | guards over-eager check | ✅ extend | ⬜ pending |
| HYG-01 | HexDocs build warning-free | docs | `mix docs --warnings-as-errors` | broken `c:` links | ✅ existing | ⬜ pending |
| HYG-02 | No-Oban build compiles with `--warnings-as-errors` | build | `mix verify.no_optional_deps` | fails at `lib/scrypath/sync.ex:74:12` once task is isolated | ✅ fix | ⬜ pending |
| HYG-02 | Task proves Oban absent (no false green) | unit | `mix test test/mix/tasks/verify_no_optional_deps_test.exs` | fake build dir with `lib/oban` → `Mix.Error` | ❌ W0 | ⬜ pending |
| HYG-02 | `verify.core` runs the no-Oban build | unit | `mix test test/mix/tasks/verify_capability_test.exs` | sequence assertion fails until composed | ✅ extend | ⬜ pending |
| HYG-02 | No blanket suppression | contract | `mix test test/mix/tasks/workflow_wiring_test.exs` (or new contract test) | adding `elixirc_options` / `put_compiler_option` fails it | ✅/❌ | ⬜ pending |
| HYG-02 | Related Oban enqueue unchanged | unit | `mix test test/scrypath/sync/related_worker_test.exs test/scrypath/sync_test.exs test/scrypath/oban_test.exs` | job-shape / unique assertions | ✅ existing | ⬜ pending |
| HYG-02 | Runs on phase PR in a required lane | hosted | `core (required)` log shows the no-optional-deps compile | exact-SHA PR run | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/verify_no_optional_deps_test.exs` — seam tests for build-path isolation, env, and optional-dep absence guard (pure function, no subprocess compile)
- [ ] Injectable runner for `Capability.run(:core, …)` so the sequence is testable without running the real gate

---

## Manual-Only Verifications

All phase behaviors have automated verification (hosted CI evidence is exact-SHA, not human UAT).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
