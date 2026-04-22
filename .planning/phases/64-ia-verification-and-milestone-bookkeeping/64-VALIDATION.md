---
phase: 64
slug: ia-verification-and-milestone-bookkeeping
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-22
---

# Phase 64 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir **1.17+**) |
| **Config file** | `scrypath_ops/config/test.exs` + root `config/test.exs` |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops_web/operator_ia_contract_test.exs` |
| **Full suite command** | `mix verify.opsui` (repo root) |
| **Estimated runtime** | ~2–6 minutes (machine-dependent; includes `deps.get` in ops app) |

## Sampling Rate

- **After every task touching `scrypath_ops/`:** Run `mix verify.opsui` from repo root **or** scoped `cd scrypath_ops && mix test` for touched test paths.
- **After IA / nav doc edits:** Run `cd scrypath_ops && mix scrypath_ops.check_nav_contract` then `mix test test/scrypath_ops_web/operator_ia_contract_test.exs`.
- **After root `CONTRIBUTING.md` / `docs_contract_test.exs` edits:** Run `mix test test/scrypath/docs_contract_test.exs` from repo root.
- **After every plan wave:** `mix verify.opsui` when any wave touched `scrypath_ops/` or root verify/docs.
- **Before `/gsd-verify-work`:** `mix verify.opsui` green; root `docs_contract_test` green if those files changed.
- **Max feedback latency:** Target under 10 minutes per full `verify.opsui` on CI-class hardware.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 64-01-01 | 01 | 1 | OPS2-05 | T-64-01 | Doc links stay host-owned / single persistence authority | unit + mix task | `cd scrypath_ops && mix scrypath_ops.check_nav_contract && mix test test/scrypath_ops_web/operator_ia_contract_test.exs` | ✅ | ⬜ pending |
| 64-02-01 | 02 | 1 | OPS2-06 | T-64-02 | No live Meilisearch on default path | integration | `mix verify.opsui` (repo root) | ✅ | ⬜ pending |
| 64-02-02 | 02 | 1 | OPS2-06 | — | N/A | unit | `mix test test/scrypath/docs_contract_test.exs` (root) | ✅ | ⬜ pending |
| 64-03-01 | 03 | 2 | OPS2-08 | — | N/A | manual + grep | `test -f .planning/milestones/v1.15-ROADMAP.md` | ✅ after W2 | ⬜ pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no Wave 0 install tasks.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Frozen milestone trio reads as coherent archive | OPS2-08 | Human judgment on narrative | Open `milestones/v1.15-*.md` and confirm phases 62–64, OPS2 rows, and deferrals match shipped work. |

## Validation Sign-Off

- [ ] All tasks have automated verify commands or explicit manual rows above
- [ ] Sampling continuity: IA tasks run `check_nav_contract` + contract tests
- [ ] No watch-mode flags in commands
- [ ] `nyquist_compliant: true` set in frontmatter after wave sign-off

**Approval:** pending
