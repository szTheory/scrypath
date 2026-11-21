---
phase: "193"
slug: hexdocs-regroup-and-guards
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-21"
---

# Phase 193 — Validation Strategy

> Per-phase validation contract. Derived from the Validation Architecture section of `193-RESEARCH.md`; the planner fills the per-task map.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.0); `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` first |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/release/package_metadata_test.exs test/scrypath/readme_contract_test.exs` plus the new guard test files |
| **Full suite command** | `mix verify.core --exclude integration --exclude docs_contract`, then `mix verify.package`; the 13-file doc-pin set including `docs_contract_test.exs` |
| **Estimated runtime** | quick about 15 s; doc-pin set about 3 s; core about 6 min; package about 2 min |

## Sampling Rate

- **After every task commit:** the new and edited test files plus `mix format --check-formatted`
- **After every plan:** `scripts/ci/pre_push.sh`, the doc-pin set, `mix docs --warnings-as-errors`
- **Before verify-work:** `mix verify.core --exclude integration --exclude docs_contract` and `mix verify.package` green on the committed head
- **Max feedback latency:** 20 s for the per-task run

## Per-Task Verification Map

Filled by the planner: one row per task, each with a runnable `<automated>` command and a stated failure signal.

## Wave 0 Requirements

- [ ] `test/support/release/install_line.ex` and `test/release/install_line_contract_test.exs` — GUARD-02
- [ ] `test/support/release/snippet_parity.ex` and its planted-case test — GUARD-03 parity
- [ ] `test/support/release/forbidden_phrases.ex`, its data file and `test/release/forbidden_phrases_contract_test.exs` — GUARD-03 phrases
- [ ] Config-shape and built-sidebar tests in `test/release/package_metadata_test.exs` — DOCS-01
- [ ] `193-PIN-INVENTORY.md` — overview and group-shape pins with a fate log

## Manual-Only Verifications

All phase behaviors have automated verification. Explicitly unproven and not claimed: that the grouping matches how readers look for things, live HexDocs and hex.pm rendering (docs publish only through a Hex release), and how the shrunk overview reads.

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] No 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set after the plan checker passes

**Approval:** pending
