---
phase: 18
slug: release-parity-gate-node-20-ci-cleanup
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-17
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (stdlib — no framework install needed) |
| **Config file** | `test/test_helper.exs` (excludes `:integration` tag unless `SCRYPATH_INTEGRATION=1` is set) |
| **Quick run command** | `mix test test/mix/tasks/ --exclude integration` |
| **Full suite command** | `mix test --exclude integration` |
| **Estimated runtime** | ~5s quick · ~30s full |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mix/tasks/ --exclude integration` (target: < 5s)
- **After every plan wave:** Run `mix test --exclude integration` (target: ~30s)
- **Before `/gsd-verify-work`:** Full suite must be green AND `mix verify.workspace_clean` green AND `mix verify.release_parity 0.3.0` green (D-21 canary) AND manual `workflow_dispatch` of `verify-published-release.yml` green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

Task IDs are placeholders — the planner will finalize them per-plan. Mapping is by requirement + behavior so plans can attach each task to one or more rows below.

| # | Plan (expected) | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|-----------------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1 | workspace_clean | 1 | INFRA-01 | V5 input | Pathspec derivation from `mix.exs package.files` + `test` | unit | `mix test test/mix/tasks/verify_workspace_clean_test.exs:test "derives pathspecs"` | ❌ W0 | ⬜ pending |
| 2 | workspace_clean | 1 | INFRA-01 | — | Clean tree exits 0 | unit | `mix test test/mix/tasks/verify_workspace_clean_test.exs:test "clean tree"` | ❌ W0 | ⬜ pending |
| 3 | workspace_clean | 1 | INFRA-01 | — | Dirty tree raises with offending paths | unit | `mix test test/mix/tasks/verify_workspace_clean_test.exs:test "raises on dirty tree"` | ❌ W0 | ⬜ pending |
| 4 | workflow_wiring | 1 | INFRA-01 | V4 access | `workspace_clean` step present in `ci.yml` quality job | unit (YAML grep) | `grep -nF 'mix verify.workspace_clean' .github/workflows/ci.yml` | ❌ W0 | ⬜ pending |
| 5 | workflow_wiring | 1 | INFRA-01 | V4 access | `workspace_clean` step present in `publish-hex.yml` | unit (YAML grep) | `grep -nF 'mix verify.workspace_clean' .github/workflows/publish-hex.yml` | ❌ W0 | ⬜ pending |
| 6 | workflow_wiring | 1 | INFRA-01 | V4 access | `workspace_clean` step present in `release-please.yml` publish-hex job | unit (YAML grep) | `grep -nF 'mix verify.workspace_clean' .github/workflows/release-please.yml` | ❌ W0 | ⬜ pending |
| 7 | release_parity | 2 | INFRA-02 | V5 input | Path-set diff detects drift (stubbed fetch + stubbed git output) | unit | `mix test test/mix/tasks/verify_release_parity_test.exs:test "detects drift"` | ❌ W0 | ⬜ pending |
| 8 | release_parity | 2 | INFRA-02 | — | Exit code 0 parity / 2 drift / 1 runtime error | unit + subprocess | `System.cmd/3` subprocess assertion on exit code | ❌ W0 | ⬜ pending |
| 9 | release_parity | 2 | INFRA-02 | — | `--json` output matches documented shape | unit | `assert Jason.decode!(out) == %{"version" => ..., "status" => "drift", "only_in_git" => [...], "only_in_hex" => [...]}` | ❌ W0 | ⬜ pending |
| 10 | release_parity | 2 | INFRA-02 | — | CDN retry: fail once → succeed halts loop | unit | Stub fetch to fail once then succeed | ❌ W0 | ⬜ pending |
| 11 | release_parity | 2 | INFRA-02 | V12 file | tmp_dir created under `System.tmp_dir!/0`, cleaned up in `after` | unit | Stub + assert `File.exists?(tmp)` is `false` after run | ❌ W0 | ⬜ pending |
| 12 | release_parity | 2 | INFRA-02 | V5 input | Version arg rejects non-semver (injection guard) | unit | `mix test test/mix/tasks/verify_release_parity_test.exs:test "rejects malformed version"` | ❌ W0 | ⬜ pending |
| 13 | release_parity | 2 | INFRA-02 | — | `release_parity` step present in `verify-published-release.yml` | unit (YAML grep) | `grep -nF 'mix verify.release_parity' .github/workflows/verify-published-release.yml` | ❌ W0 | ⬜ pending |
| 14 | ci_pins | 1 | INFRA-03 | — | `actions/checkout@v6` present ≥ 4× in `ci.yml` | unit (YAML grep) | `grep -c 'actions/checkout@v6' .github/workflows/ci.yml` ≥ 4 | ❌ W0 | ⬜ pending |
| 15 | ci_pins | 1 | INFRA-03 | — | `actions/cache@v5` present in `ci.yml` | unit (YAML grep) | `grep -c 'actions/cache@v5' .github/workflows/ci.yml` ≥ 1 | ❌ W0 | ⬜ pending |
| 16 | ci_pins | 1 | INFRA-03 | — | No remaining `@v4` refs for checkout/cache in `ci.yml` | unit (YAML grep) | `! grep -E 'actions/(checkout\|cache)@v4' .github/workflows/ci.yml` | ❌ W0 | ⬜ pending |
| 17 | cron_wiring | 2 | INFRA-04 | — | Scheduled cron wires `release_parity` in `verify-published-release.yml` | unit (YAML grep) | Confirm `schedule:` + `cron:` + `release_parity` co-exist | ❌ W0 | ⬜ pending |
| 18 | cron_wiring | 2 | INFRA-04 | V4 access | `create-an-issue` guarded on `failure() && github.event_name == 'schedule'` | unit (YAML grep) | `grep -nF "failure() && github.event_name == 'schedule'" .github/workflows/verify-published-release.yml` | ❌ W0 | ⬜ pending |
| 19 | cron_wiring | 2 | INFRA-04 | — | `update_existing: true` in `create-an-issue` step (per-version dedup) | unit (YAML grep) | `grep -nF 'update_existing: true' .github/workflows/verify-published-release.yml` | ❌ W0 | ⬜ pending |
| 20 | mix_preferred_envs | 1 | INFRA-01..04 | — | New tasks listed in `mix.exs` `cli.preferred_envs` | unit | Assert `Scrypath.MixProject.cli()[:preferred_envs]` contains both keys | ❌ W0 | ⬜ pending |
| 21 | release_parity | 2 | INFRA-02 | — | D-21 canary: `mix verify.release_parity 0.3.0` returns 0 against live Hex | integration | `SCRYPATH_INTEGRATION=1 mix test --only integration` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Nyquist Dimension 8 Coverage

Minimum test counts per dimension (from RESEARCH.md §Validation Architecture):

| Dimension | Coverage | Minimum Tests |
|-----------|----------|---------------|
| 1. Task-level unit (each Mix task in isolation, mocked dependencies) | Pathspec derivation, clean/dirty, error formatting (workspace_clean); path-diff logic, JSON shape, exit-code branches, retry, tmp-dir cleanup (release_parity) | 8 |
| 2. Workflow-level integration (each workflow YAML parseable + referenced task runs) | `ci.yml`, `release-please.yml`, `publish-hex.yml`, `verify-published-release.yml` each parse and hold the required step | 4 |
| 3. Cross-workflow contract (workspace_clean gate appears in all 3 publish paths per D-14) | Grep presence in `ci.yml` quality job, `release-please.yml` publish-hex job, `publish-hex.yml` | 3 |
| 4. Post-publish monitoring (daily cron actually fires + issue dedup works) | Manual `workflow_dispatch` run triggers `release_parity` against 0.3.0 (passes by D-21); dry-run `create-an-issue` via subprocess | 2 |
| 5. Subprocess integration (actually invoking `mix verify.release_parity 0.3.0` against live Hex) | One integration test tagged `@tag :integration`, runs only with `SCRYPATH_INTEGRATION=1` | 1 |

**Total: 18 automatable tests + 1 manual `workflow_dispatch` verification at phase close.**

---

## Wave 0 Requirements

Wave 0 must create (before Wave 1 task execution):

- [ ] `test/mix/tasks/verify_workspace_clean_test.exs` — covers INFRA-01 task-level unit
- [ ] `test/mix/tasks/verify_release_parity_test.exs` — covers INFRA-02 unit + `@tag :integration` canary
- [ ] `test/mix/tasks/workflow_wiring_test.exs` — centralizes YAML-grep assertions for INFRA-01 cross-workflow + INFRA-03 pin grep + INFRA-04 scheduled wiring grep. Mirrors the `validate_release_contract!/0` helper pattern from `verify.phase11.ex:43-138` in test form. Single point of assertion so grep logic is not duplicated across multiple files.

Shared fixtures: **none** — tests are self-contained (stubs for `System.cmd` via injectable function; no integration ceremony beyond `SCRYPATH_INTEGRATION` gating).

Framework install: **none** — ExUnit is stdlib.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Daily cron fires `verify-published-release.yml` without human intervention after Phase 18 ships | INFRA-04 | The cron runs on GitHub's schedule — no way to simulate its trigger synchronously from CI. Manual `workflow_dispatch` proves the workflow body runs correctly; wall-clock scheduling is GitHub's responsibility. | (1) After merging `feat(18):` to main, wait 24h. (2) Observe a scheduled run in the Actions tab. (3) Run completes green. (4) Confirm no issue was auto-filed (because 0.3.0 is in parity per D-21). One-time verification, not a repeat regression test. |
| Zero Node 20 deprecation warnings in `ci.yml` runs after pin bump | INFRA-03 | Warnings surface in GitHub Actions log output, not in `mix` or exit codes. YAML grep proves the pins are present; visual log inspection proves the warnings are gone. | After merge, open any PR that triggers `ci.yml`. In the Actions tab, open each job's log, search for "deprecated", confirm zero matches for `actions/checkout` or `actions/cache`. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all 3 MISSING test files
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter (set after plans pass checker)

**Approval:** pending
