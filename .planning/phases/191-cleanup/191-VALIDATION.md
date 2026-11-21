---
phase: "191"
slug: "cleanup"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-20"
---

# Phase 191 — Validation Strategy

> Sampling summary built from the ROADMAP Phase 191 success criteria and [191-RESEARCH.md](191-RESEARCH.md). Every criterion is an executable check; none is a human review.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (root and `scrypath_ops`), `node:test` for `examples/scrypath_ecommerce/ui-tokens.test.mjs` and `scripts/ci/*.test.cjs` |
| **Config file** | none new |
| **Quick run command** | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` (about 1 s) and the changed ExUnit file |
| **Full suite command** | `mix verify.repository_contracts` once per committed state (it clones HEAD), `mix verify.core --exclude integration --exclude docs_contract` once on the final head |
| **Estimated runtime** | quick about 5 s; long gates about 15 min each (run in the background) |

## Sampling Rate

- **After every task commit:** focused checks (the ui-tokens node test, the changed ExUnit files, `mix format --check-formatted`)
- **Per deletion commit (favicon, readers, data):** `mix verify.repository_contracts` once on that committed state, because the gate reads committed HEAD. *Superseded by the gate-run budget in 191-01 and 191-02: two runs only (after commit 2 and on the final head); the other four code commits (1, 3, A, B) are covered by focused checks, with reasons and revisit triggers recorded in the plans.*
- **Phase gate:** six required contexts green on the exact PR head; one `mix verify.core` on the final code head; receipt in the 189 and 190 format
- **Max feedback latency:** quick checks under 10 s

## Per-Task Verification Map

| Criterion | Requirement | Automated check | Lane | Status |
|-----------|-------------|-----------------|------|--------|
| SC1 demo favicon byte-identical to `brand/assets/icon/favicon-light.svg`; allowlist entry removed | CLEAN-01 | root-level test in `core`; ceilings 5/197 to 4/194 | `core` | ✅ local green; hosted on the exact head pending by design |
| SC2 `ui_tokens.ex`, its contract test, the `verify.phase99` entry and the `verify.ui_tokens` `preferred_envs` line gone; no reader of `brandbook/` remains; `mix verify.repository_contracts` passes; deleted-to-surviving assertion map recorded | CLEAN-02 | scan for readers; `mix verify.repository_contracts` on the committed state; ceilings to 2/178 | `repository-contracts`, `core` | ✅ local green; hosted on the exact head pending by design |
| SC3 `brandbook/` and its `ci.yml` regex entry deleted with their allowlist entries and ceilings; allowlist 0 entries and 0 hits; three shared hexes join the deny set; planted retired value and planted retired path still fail; docs never spell the retired path | CLEAN-03 | `ui-tokens.test.mjs` planted and accept cases; `workflow_wiring_test` | `core`, `repository-contracts` | ✅ local green; hosted on the exact head pending by design |
| SC4 12 px floor, arbitrary-size, `uppercase`, `infinite` and `size: :xs` invariants each fail a planted case and accept valid cases on ops-authored source only; floor count and test names rise; docs say these are source checks | CLEAN-04 | planted and accept cases in `ui-tokens.test.mjs`; `@min_token_test_calls` raised in the same commit | `core` | ✅ local green; hosted on the exact head pending by design |
| SC5 unthemed-favicon tripwire and consumer scan (path and bytes) pass on `main` and fail their planted cases; upstream report draft in the phase record; ledger reworded per CLEAN-06 with `brand/tokens.json` named as the single token authority; `workflow_wiring_test` green | CLEAN-05, CLEAN-06 | tripwire and scan tests; `workflow_wiring_test` | `core`, `repository-contracts` | ✅ local green; hosted on the exact head pending by design |
| GATE-02 | GATE-02 | one full gate run per SHA; squash title `chore(...)`; no new required gate (budget 10 of 12 stays or falls) | `repository-contracts` | ✅ local green; hosted on the exact head pending by design |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements: the deny-list, `RETIRED_DIR` tripwire and planted/accept machinery already live in `ui-tokens.test.mjs`.

## Manual-Only Verifications

All phase behaviors have automated verification. Not proved: rendered size or appearance (the invariants are source checks), browsers, screen readers. No design pass or aesthetic claim is made.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency for quick checks under 10 s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** seeded 2026-11-20 by the orchestrator; `validated` when the phase verifier passes.
