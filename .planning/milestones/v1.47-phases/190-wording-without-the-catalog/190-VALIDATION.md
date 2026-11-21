---
phase: "190"
slug: "wording-without-the-catalog"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-20"
---

# Phase 190 — Validation Strategy

> Sampling summary seeded from the "Validation Architecture" section of [190-RESEARCH.md](190-RESEARCH.md); that table is the detailed source.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19 / OTP 28) for ScrypathOps and root contracts; Playwright for the required-lane spec; `node:test` for fixture scripts |
| **Config file** | none new; Wave 0 creates `scrypath_ops/test/support/copy_rules.json`, `copy_rules.ex` and `copy_rules_contract_test.exs` |
| **Quick run command** | `cd scrypath_ops && MIX_ENV=test mix test <changed files>` |
| **Full suite command** | `cd scrypath_ops && MIX_ENV=test mix test`; root `mix test test/mix/tasks/workflow_wiring_test.exs`; one `mix verify.repository_contracts` per committed SHA |
| **Estimated runtime** | quick about 1 s; ops suite about 26 s; wiring test about 5 s |

## Sampling Rate

- **After every task commit:** the changed ExUnit file and `mix format --check-formatted`
- **After every plan:** whole ScrypathOps suite, `workflow_wiring_test.exs`, `node --test scripts/ci/ui_preservation.test.cjs`, `node --test examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs`, `playwright test --list`
- **Phase gate:** six required contexts green on the exact PR head, then the `ci.yml` dispatch on that head (record both run ids); the first dispatch on current `main` gives the clean baseline
- **Max feedback latency:** quick checks under 30 s

## Per-Task Verification Map

| Criterion | Requirement | Automated check | Lane | Status |
|-----------|-------------|-----------------|------|--------|
| SC1 glossary block and wording rules proved on the table's surfaces; pinned strings unchanged | COPY-01 | `copy_rules_contract_test.exs` rows; in-place LiveView assertions; `git diff` check of the pinned `operator.spec.ts` strings | `ops-ui` (required), `ecommerce-mounted` | ✅ local green; hosted on the exact head pending by design |
| SC2 "Control room" sentence case; whole-tree scan clean; four exact-match Playwright sites updated; `aria-current` and title proved | COPY-02 | row `control-room-casing`; `ops_shell_contract_test.exs`; `playwright test --list`; the two node tests | `ops-ui` | ✅ local green; hosted on the exact head pending by design |
| SC3 the table scans and renders; planted failures fail; missing field fails; refutes repaired; path regex and wiring test cover the scanned paths; ledger consistent | COPY-03 | planted-failure tests; behavioural regex test and `source_scope` check in `workflow_wiring_test.exs` | `ops-ui`, `core` | ✅ local green; hosted on the exact head pending by design |
| SC4 Cancel focused on open; `ops_modal` default and destructive dialogs pinned; `page_controller_test.exs` passes; `ecommerce-e2e` green on the exact head | COPY-04 | `operator.spec.ts` line; ExUnit pins; local demo test; `gh workflow run ci.yml --ref <branch>` | `ecommerce-mounted` (required); hosted dispatch (advisory) | ✅ local green; hosted on the exact head pending by design |
| GATE-02 | GATE-02 | whole CI Node step locally (`app.css` changed); one `mix verify.repository_contracts` per SHA; squash title `chore(...)`; ledger within 12 | `repository-contracts` | ✅ local green; hosted on the exact head pending by design |

## Wave 0 Requirements

- [x] `scrypath_ops/test/support/copy_rules.json`, `copy_rules.ex`, `scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs`
- [x] Shared fixture helpers for the registered surfaces (extract from the LiveView tests, do not copy)
- [x] Framework install: none (`Jason`, `LazyHTML`, `Phoenix.LiveViewTest` already present)

## Manual-Only Verifications

All phase behaviors have automated verification. Not proved: rendered quality or aesthetics (no preview capture or `ui:review` runs; the phase record says no design pass was done), browsers other than Chromium, real screen readers.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] No watch-mode flags
- [x] Feedback latency for quick checks under 30 s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** seeded 2026-11-20 by the orchestrator; `validated` when the phase verifier passes.
