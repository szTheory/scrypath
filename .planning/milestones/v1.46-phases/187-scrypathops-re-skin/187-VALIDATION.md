---
phase: "187"
slug: "scrypathops-re-skin"
status: validated
nyquist_compliant: true
wave_0_complete: false
created: "2026-11-19"
---

# Phase 187 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Zero human verification: every check below is executable; rendered captures and the UI review inventory are context, not gates. Source: the Validation Architecture section of [187-RESEARCH.md](187-RESEARCH.md) and the Assertion Index of [187-UI-SPEC.md](187-UI-SPEC.md).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.0 / OTP 28 through asdf env vars), `node --test` (Node 26 local), Playwright 1.60.0 (Chromium) |
| **Config file** | `scrypath_ops/mix.exs` (test alias runs `ecto.create` and `ecto.migrate`); `examples/scrypath_ecommerce/playwright.config.ts` (testDir `./e2e`, 1 worker, 0 retries) |
| **Quick run command** | `node examples/scrypath_ecommerce/contrast-checker.mjs` (0.3 s) then `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` (6 s) |
| **Full suite command** | `mix verify.ops_ui`, `mix verify.repository_contracts`, `mix verify.core --exclude integration --exclude docs_contract`, `mix verify.ecommerce_mounted` (required lanes); hosted `ecommerce-e2e (advisory)` and `closeout-attestation` dispatched on the exact head |
| **Estimated runtime** | per-commit cheap set about 12 s; ops suite about 55 s; `verify.repository_contracts` about 180 s; mounted lane about 18 min cold; hosted e2e job capped at 30 min |

Environment: `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`; ops ExUnit uses a task-scoped `SCRYPATH_OPS_TEST_DATABASE=scrypath_ops_test_187_<plan>`, dropped afterwards. Rebuild the built CSS with `(cd scrypath_ops && ./_build/tailwind-macos-arm64 --input=assets/css/app.css --output=priv/static/assets/css/app.css)` after any `app.css` edit.

---

## Sampling Rate

- **After every task commit:** rebuild CSS (if touched), contrast checker, token test, the four ops CSS regex tests (`design_tokens_contract`, `shell_chrome_token_contract`, `surface_depth_token_contract`, `motion_contract`), plus the touched LiveView or component test file.
- **After every plan wave:** root `ui_*` tests with `--exclude contrast_child` (7 s), full ops suite (55 s) and `mix verify.ops_ui`; `mix verify.repository_contracts` once per plan on its final code SHA (escalated on first use; commit before running because `contrast_child` clones HEAD).
- **Browser lanes:** `mix verify.ecommerce_mounted` after Plans 02, 05, 06, 09, 10 and 11; disposable test-stack Playwright runs in Plans 09, 10 and 11; the whole ordinary e2e partition once locally in Plan 10 before the hosted dispatch in Plan 11; captures in Plans 01 and 11. Ports come from `${P187_PORT}` and `${P187_PREVIEW_PORT}`, never hard-coded.
- **Literal ratchet:** `test/mix/tasks/ui_literal_contract_test.exs` runs in the root `ui_*` set at every plan gate; `scripts/ci/ui-literal-baseline.json` must equal the source scan (rows move in Plans 05, 06 and 09).
- **Before `/gsd-verify-work`:** every required check, `ecommerce-e2e (advisory)` and `closeout-attestation` green on the exact PR head SHA.
- **Max feedback latency:** 30 s for the per-commit set.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Assertion | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|------------|-----------------|-----------|-------------------|-------------|--------|
| 187-01-01 | 01 | 1 | SKIN-08 | E-19 prerequisite | T-187-01 | fixture scenario only under `Mix.env() == :test` | LiveView | `mix test test/scrypath_ops_web/live/posture_live_test.exs` (from `scrypath_ops/`) | yes (edited) | ⬜ pending |
| 187-01-02 | 01 | 1 | SKIN-08 | ceilings exact (186 IN-06), wrapper names (IN-03), neutral-only state case | T-187-SC | N/A | node unit | token test; `node --test --test-reporter=tap scripts/ci/ui_state_pairs.test.cjs` (about 62 s, not per-commit) | yes (edited) | ⬜ pending |
| 187-01-03 | 01 | 1 | GATE-03, SKIN-08 | capture inventory 12/12, preflight | T-187-02, T-187-03 | captures stay in ignored dir; no tracked change outside `.planning/`; task-scoped Docker | cli | `reskin-capture.mjs --check …/phase187/before`; `PLAYWRIGHT_BASE_URL=http://127.0.0.1:${P187_PREVIEW_PORT} npm run ui:preflight` | ❌ W0 | ⬜ pending |
| 187-02-01 | 02 | 2 | SKIN-02 | N-10 (fonts), E-14 (font-face), E-15 (serving) | T-187-04, T-187-06 | AssetPlug path checks; immutable only on matching hash | node unit, ExUnit, required browser | token test; `mix test test/scrypath_ops_web/reskin_static_contract_test.exs`; `harness.spec.ts` in `verify.ecommerce_mounted` | ❌ W0 | ⬜ pending |
| 187-02-02 | 02 | 2 | SKIN-06, SKIN-02 | E-14 (glyph coverage) | — | N/A | ExUnit | `mix test …/reskin_static_contract_test.exs …/design_tokens_contract_test.exs` | ❌ W0 | ⬜ pending |
| 187-02-03 | 02 | 2 | SKIN-03 | E-13, E-15 (preload) | T-187-05 | served bytes equal pinned brand bytes | ExUnit, cli | `mix test …/reskin_static_contract_test.exs`; `MIX_ENV=test mix verify.brand` | ❌ W0 | ⬜ pending |
| 187-03-01 | 03 | 3 | SKIN-01, A11Y-01 | N-01 (interim), N-02, N-06, N-10 (parity) | T-187-08, T-187-10 | ceilings fail both ways; one reviewable commit; 46 named muted entries removed | node unit, cli, ExUnit | contrast checker; token test; root `ui_*` `--exclude contrast_child` | yes (edited) | ⬜ pending |
| 187-03-02 | 03 | 3 | A11Y-01 | N-03, N-04, N-05 (binding table) | T-187-09 | pairs read from the live stylesheet through named bindings | cli | contrast checker and `--self-test` | yes (edited) | ⬜ pending |
| 187-03-03 | 03 | 3 | SKIN-01 | allowlist shrink (docs) | T-187-08 | N/A | node unit | token test | yes (edited) | ⬜ pending |
| 187-04-01 | 04 | 4 | STAT-01 | E-01, E-02 (Failed sync) | T-187-12 | closed status atom set | ExUnit | `mix test test/scrypath_ops_web/reskin_component_contract_test.exs …/failed_sync_live_test.exs` | ❌ W0 | ⬜ pending |
| 187-04-02 | 04 | 4 | STAT-01, STAT-02, STAT-03, SKIN-07, SKIN-08 | E-02 (Search health), E-03, E-04, E-05, E-06, E-19 | T-187-13 | Clear only with an observation | ExUnit, list | posture, control room, sync drift live tests; `npx playwright test … --list` | yes (edited) | ⬜ pending |
| 187-04-03 | 04 | 4 | STAT-03, SKIN-07 | E-17, E-11 (flashes, Search failed, empty states) | T-187-11 | no raw error term in the flash | ExUnit, cli | component contract and live tests; contrast checker (manifest both ways) | yes (W0 file from 04-01) | ⬜ pending |
| 187-05-01 | 05 | 5 | SKIN-04 | E-07, E-08, E-11 (confirm labels, 1 document) | T-187-14 | consequence labels, Cancel focused | ExUnit, list, required browser | component contract and live tests; `operator.spec.ts` in `verify.ecommerce_mounted` | yes (edited) | ⬜ pending |
| 187-05-02 | 05 | 5 | SKIN-04, A11Y-01 | E-09 | — | N/A | ExUnit, cli | component contract, design tokens, shell chrome tests; contrast checker | yes (edited) | ⬜ pending |
| 187-05-03 | 05 | 5 | A11Y-02 | N-09 | T-187-15 | `html` rule scoped to the ops shell; focus binding added | node unit, cli | token test (N-09); contrast checker; literal ratchet | yes (edited) | ⬜ pending |
| 187-06-01 | 06 | 6 | SKIN-05 | E-10 | T-187-17 | N/A | ExUnit | `mix test …/reskin_static_contract_test.exs …/ops_shell_contract_test.exs` | yes (edited) | ⬜ pending |
| 187-06-02 | 06 | 6 | SKIN-05, A11Y-03 | E-16, E-11 (Refreshing…) | T-187-16 | N/A | ExUnit, required browser | component contract test; literal ratchet; `verify.ecommerce_mounted` | yes (edited) | ⬜ pending |
| 187-07-01 | 07 | 7 | SKIN-05 | retired families absent (motion contract rewritten) | T-187-18 | N/A | ExUnit, node unit | ops CSS tests; token test | yes (edited) | ⬜ pending |
| 187-07-02 | 07 | 7 | SKIN-01, SKIN-05 | N-01 (end), N-08 | T-187-18, T-187-19 | surface bindings and clone case follow the deletion | node unit, cli, ExUnit, clone | contrast checker; token test; root `ui_*`; `verify.repository_contracts` | yes (edited) | ⬜ pending |
| 187-08-01 | 08 | 8 | SKIN-05, STAT-03 | N-12, hairline rows | T-187-20 | retired tints cannot return | cli, ExUnit | checker and `--self-test`; ops CSS tests | yes (edited) | ⬜ pending |
| 187-08-02 | 08 | 8 | A11Y-01 | N-07, MUTED_PAIRS retired | T-187-20 | N/A | cli, ExUnit, clone | checker and `--self-test`; root `ui_*`; full ops `mix test`; `verify.repository_contracts` | yes (edited) | ⬜ pending |
| 187-09-01 | 09 | 9 | SKIN-05 | E-18, duration-token motion contract | — | N/A | ExUnit | motion, design tokens, static contract tests; literal ratchet | yes (edited) | ⬜ pending |
| 187-09-02 | 09 | 9 | SKIN-05, SKIN-06 | E-12, N-13 | T-187-21 | planted retired strings fail | ExUnit, node unit | static contract test; token test; literal ratchet | yes (edited) | ⬜ pending |
| 187-09-03 | 09 | 9 | SKIN-05, A11Y-03 | P-12, spec sweep | T-187-22 | task-scoped stacks removed | browser (disposable stacks), required browser | `make verify-path-motion`, `make verify-shell-wash` with `WEB_PORT=${P187_PORT}`; `verify.ecommerce_mounted` | yes (rewritten in place) | ⬜ pending |
| 187-10-01 | 10 | 10 | SKIN-01..04, SKIN-06, STAT-01, STAT-03, A11Y-01 | P-01..P-08, P-11, P-13, P-18 | T-187-23 | N/A | browser (disposable stack) | `PLAYWRIGHT_BASE_URL=http://127.0.0.1:${P187_PORT} npx playwright test e2e/ops_reskin_contract.spec.ts` | ❌ W0 | ⬜ pending |
| 187-10-02 | 10 | 10 | A11Y-02, SKIN-02, SKIN-05, STAT-03, A11Y-01, A11Y-03 | P-09, P-10, P-14, P-15 (rows, notices, verdicts), P-16, P-19, P-20, P-21 | T-187-23 | N/A | browser | same spec | ❌ W0 | ⬜ pending |
| 187-10-03 | 10 | 10 | all browser-proved reqs | whole ordinary partition plus required lane | T-187-24 | partition under its 900 s cap | browser (disposable stack), required browser | every non-preservation spec in one serial run; `verify.ecommerce_mounted` | yes | ⬜ pending |
| 187-11-01 | 11 | 11 | A11Y-04 | P-17, N-11 | T-187-25, T-187-26 | ops CSS does not change host pages; font-src 'self' suffices | browser, node unit | `npx playwright test e2e/ops_host_contract.spec.ts`; token test | ❌ W0 | ⬜ pending |
| 187-11-02 | 11 | 11 | SKIN-08, GATE-03 | capture inventory 24, preflight before and after the head refresh | T-187-27 | images never uploaded | cli | `reskin-capture.mjs --check` on both dirs; `npm run ui:preflight` twice | yes (from 01) | ⬜ pending |
| 187-11-03 | 11 | 11 | SKIN-08 | exact-head hosted gates | T-187-28 | agent never merges or marks ready | hosted CI | `gh pr checks --required`; dispatched `ci.yml` run on the head SHA | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement to assertion map

| Requirement | Assertions | Plans |
|-------------|-----------|-------|
| SKIN-01 | N-01, N-02, N-06, N-08, N-10, P-01, P-18 | 03, 07, 10 |
| SKIN-02 | N-10, E-14, E-15, P-02, P-14, P-19, P-20 | 02, 10 |
| SKIN-03 | E-13, P-11 | 02, 10 |
| SKIN-04 | E-07, E-08, E-09, P-04, P-05, P-06 | 05, 10 |
| SKIN-05 | E-10, E-12, E-16, E-18, N-12, P-12, P-15, P-21 | 06, 07, 08, 09, 10 |
| SKIN-06 | N-13, P-02 | 02, 09, 10 |
| SKIN-07 | E-05, E-11 | 04, 05 |
| SKIN-08 | E-19, capture inventory, PR gates list | 01, 04, 11 |
| STAT-01 | E-01, E-02, E-06, E-19, P-03 | 04, 10 |
| STAT-02 | E-03, E-04 | 04 |
| STAT-03 | E-06, E-17, P-15, P-18 | 04, 08, 10 |
| A11Y-01 | N-03, N-04, N-05, N-06, N-07, P-07, P-08, P-13, P-16 | 03, 05, 08, 10 |
| A11Y-02 | N-09, P-09, P-10 | 05, 10 |
| A11Y-03 | E-16, P-02, P-12, P-20 | 06, 09, 10 |
| A11Y-04 | N-11, P-17, mounted font request | 02, 11 |
| GATE-03 | `npm run ui:preflight` exit 0, `my-search.json` hash unchanged, seed-disabled start | 01, 11 |

---

## Wave 0 Requirements

- [ ] `all-statuses` scenario in both `phase173_fixture_source.ex` copies and the posture select (Plan 01, before any capture)
- [ ] `examples/scrypath_ecommerce/scripts/reskin-capture.mjs` and `reskin-capture.selftest.mjs` (Plan 01)
- [ ] `scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs` (Plan 02; extended in 06 and 09)
- [ ] `scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs` (Plan 04; extended in 05 and 06)
- [ ] request-level font check in `examples/scrypath_ecommerce/e2e/harness.spec.ts` (Plan 02, required lane)
- [ ] Dockerfile fix so Docker lanes keep the committed fonts (Plan 02)
- [ ] `examples/scrypath_ecommerce/e2e/ops_reskin_contract.spec.ts` (Plan 10) and `ops_host_contract.spec.ts` (Plan 11)
- [ ] N-08, N-09, N-10, N-11, N-13 cases in `ui-tokens.test.mjs` (Plans 07, 05, 02, 11, 09)

Framework install: none (no new package).

---

## Manual-Only Verifications

All phase behaviors have automated verification. The before and after captures and the `ui:review` inventory are review context and do not gate; aesthetic quality and independent review are explicitly not claimed.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30 s for the per-commit set
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
