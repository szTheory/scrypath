---
phase: "193"
slug: hexdocs-regroup-and-guards
status: validated
nyquist_compliant: true
wave_0_complete: true
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

One row per task; the full commands and failure signals are the `<verify>` blocks of the plans. Every mix command is prefixed with `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5 &&`.

| Task | Requirement | Automated command (short form) | Fails when |
|------|-------------|--------------------------------|------------|
| 193-01 T1 (tracer) | DOCS-01 | `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs`; `mix docs --warnings-as-errors`; rename check `git diff --diff-filter=DR --name-only origin/main -- guides docs ARCHITECTURE.md CONTRIBUTING.md README.md` empty | a config-shape, built-sidebar or planted grouping test fails; a docs warning; any renamed or deleted guide |
| 193-01 T2 | DOCS-02 | the 13-file doc-pin set; `mix compile --warnings-as-errors && mix docs --warnings-as-errors`; overview at most 320 words | a carried overview pin, owner-map test or README cap fails; a warning; the word ceiling is exceeded |
| 193-02 T1 (tracer) | GUARD-02, GUARD-01 | `mix test test/release/install_line_contract_test.exs test/release/package_metadata_test.exs test/release/shipped_docs_contract_test.exs test/scrypath/readme_contract_test.exs`; releasing readers; `mix docs --warnings-as-errors` | a real install line off the version series, a floor or planted case fails, or a TRUTH-03 link test fails |
| 193-02 T2 | GUARD-03 (parity, same-PR rule) | `mix test --warnings-as-errors test/release/snippet_parity_contract_test.exs test/scrypath/readme_contract_test.exs test/release/shipped_docs_contract_test.exs`; the CONTRIBUTING readers list | a planted parity case, a rewired README test, the CONTRIBUTING rule test or a CONTRIBUTING reader fails; a compile warning |
| 193-02 T3 | GUARD-03 (phrases) | `mix test --warnings-as-errors test/release/forbidden_phrases_contract_test.exs test/release/snippet_parity_contract_test.exs test/scrypath/readme_contract_test.exs`; probe prints `violations=0` and `targets` at least 20 | a real phrase hit, faithfulness, no-weakening or planted case fails; the probe reads too few files |

GUARD-01 adds no new test: its evidence is the existing TRUTH-03 tests in `Scrypath.Release.BuiltDocsBrandTest`, mapped in `193-PIN-INVENTORY.md` "GUARD-01 evidence".

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

**Approval:** validated 2026-11-21 by the phase verifier (193-VERIFICATION.md, 20/20, mutation battery M1-M13)
