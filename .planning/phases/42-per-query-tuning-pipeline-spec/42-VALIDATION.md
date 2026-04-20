---
phase: 42
slug: per-query-tuning-pipeline-spec
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-20
---

# Phase 42 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` (project default) |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30–120 seconds (machine dependent; doc tests are fast) |

## Sampling Rate

- **After every task commit touching published markdown or `@doc`:** Run `mix test test/scrypath/docs_contract_test.exs`
- **After every plan wave:** Same quick command; optional `mix test` before handoff
- **Before `/gsd-verify-work`:** `mix test` green for the surfaces this phase touched
- **Max feedback latency:** Target under 2 minutes for the quick slice

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 42-01-01 | 01 | 1 | TUNE-PIPE-01..04 | T-42-01-01 / — | N/A (static docs) | doc contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 42-02-01 | 02 | 2 | TUNE-PIPE discoverability | T-42-02-01 / — | No secrets in README | doc contract + compile | `mix test test/scrypath/docs_contract_test.exs` then `mix compile --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no Wave 0 stubs.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| HexDocs render of new guide | TUNE-PIPE discoverability | Local `mix docs` optional | Run `mix docs`, open `doc/guides/per-query-tuning-pipeline.html`, spot-check H2 spine |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or documented manual follow-up
- [ ] Sampling continuity: no three consecutive tasks without doc contract run when editing published markdown
- [ ] No watch-mode flags in planned commands
- [ ] `nyquist_compliant: true` set in frontmatter when execution completes

**Approval:** pending
