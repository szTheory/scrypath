---
phase: "186"
slug: "ingest-pin-and-guard"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-18"
---

# Phase 186 — Validation Strategy

> Per-phase validation contract. Zero human verification: every check is executable. Source: the Validation Architecture section of [186-RESEARCH.md](186-RESEARCH.md).

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19) for Mix tasks and contract tests; `node:test` for the token test and TOK-04 |
| **Config file** | `test/test_helper.exs`; none for Node |
| **Quick run command** | `node examples/scrypath_ecommerce/contrast-checker.mjs` then `MIX_ENV=test mix test <new files> --exclude contrast_child` |
| **Full suite command** | `mix verify.repository_contracts` and `mix verify.core --exclude integration --exclude docs_contract` (CI) |
| **Estimated runtime** | quick about 5 s; full about 14 min in CI |

Local toolchain: `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`.

## Sampling Rate

- **After every task commit:** contrast checker, ops regex tests, the three root `ui_*` tests with `--exclude contrast_child`, and any new Node or brand test file.
- **After every plan wave:** `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/dependency_boundary_contract_test.exs test/mix/tasks/verify_capability_test.exs`; `node --test scripts/ci/ui_state_pairs.test.cjs` once TOK-04 lands.
- **Before `/gsd-verify-work`:** one full CI run on the exact head SHA (core, package, repository-contracts, ops-ui green); commit a fix before any `contrast_child` rerun.
- **Max feedback latency:** 30 s for per-commit checks.

## Per-Task Verification Map

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| TOK-01/02 | live-token health | cli | `node examples/scrypath_ecommerce/contrast-checker.mjs` and `--self-test` | yes | ⬜ pending |
| TOK-01 | parity both ways, applied rows vs `brand/tokens.json`, system-dark vs built CSS, token-level freshness | node unit | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | ❌ W0 | ⬜ pending |
| TOK-02 | deny-list, shrink-only allowlist, six planted failures plus accept cases | node unit | same file | ❌ W0 | ⬜ pending |
| TOK-03 | ops pure-regex lifts | unit | `cd scrypath_ops && mix test test/scrypath_ops_web/{surface_depth_token_contract,design_tokens_contract,shell_chrome_token_contract,motion_contract}_test.exs` | yes (edited) | ⬜ pending |
| TOK-03 | root lifts | unit | `MIX_ENV=test mix test test/mix/tasks/ui_contrast_contract_test.exs test/mix/tasks/ui_tokens_contract_test.exs test/mix/tasks/ui_literal_contract_test.exs --exclude contrast_child` | yes (edited) | ⬜ pending |
| TOK-03 | recolor projection | throwaway script | scratch `git archive` copy, recolor plus mirror remap, run the root lifts line | not committed | ⬜ pending |
| PIN-01/02/03 | offline verify, tamper and update refusals, Hex `files:` | unit | `MIX_ENV=test mix test test/mix/tasks/brand_pin_contract_test.exs` | ❌ W0 | ⬜ pending |
| GATE-01 | six required contexts, CONTRIBUTING names, static storybook boundary | unit | `MIX_ENV=test mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/dependency_boundary_contract_test.exs test/mix/tasks/verify_capability_test.exs` | yes (edited) | ⬜ pending |
| GATE-01 | branch protection lists `ops-ui (path-scoped)` | read-only API | `gh api repos/szTheory/scrypath/branches/main/protection` | n/a | ⬜ pending |
| TOK-04 | calibrated accept and reject, existing checks intact | node unit | `node --test scripts/ci/ui_state_pairs.test.cjs` | yes (edited) | ⬜ pending |
| PIN-03 (package) | real Hex archive has no `brand/` or `brandbook/` | integration | `mix verify.package` | yes | ⬜ pending |
| GATE-02 | evidence-only checkpoint recorded; one full gate per SHA | artifact check | recorded in the Plan 02 summary and the final CI receipt | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [ ] `test/mix/tasks/brand_pin_contract_test.exs`, `dev/mix/tasks/verify/brand.ex`, `dev/mix/tasks/brand/update.ex`, `preferred_envs` entries
- [ ] `brand/` tree, `brand/brand.pin.json`, font and OFL files
- [ ] `scrypath_ops/assets/css/token-map.json` (37 rows) and `examples/scrypath_ecommerce/ui-tokens.test.mjs`
- [ ] `test/support/ui_tokens.ex` helper

## Manual-Only Verifications

All phase behaviors have automated verification. The online re-download check (`mix brand.update`) is a local maintainer action by locked decision, not a verification gate.

## Validation Sign-Off

- [ ] All tasks have an automated verify or Wave 0 dependency
- [ ] No 3 consecutive tasks without an automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Per-commit feedback latency under 30 s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
