---
phase: "188"
slug: "readme-header-and-hexdocs"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: validated
nyquist_compliant: true
wave_0_complete: false
created: "2026-11-19"
---

# Phase 188 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. There are no human checks. How the header and logo look is subjective and is not a gate. Code colors are proven by stylesheet rules bound to `brand/tokens.json` and to ExDoc's built CSS. No browser renders them in this phase (see 188-RESEARCH.md Residuals).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (root suite) and `node:test` (deny-list) |
| **Config file** | `test/test_helper.exs` (excludes `:integration`, `:requires_clean_workspace`, `:postgres`) |
| **Quick run command** | `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/release/package_metadata_test.exs && node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` |
| **Full suite command** | `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5 mix verify.core --exclude integration --exclude docs_contract` |
| **Estimated runtime** | quick about 5 s; full about 5 min |

---

## Sampling Rate

- **After every task commit:** the quick run command
- **After every plan:** `mix docs --warnings-as-errors`, the docs_contract family (`MIX_ENV=test mix test --include docs_contract test/scrypath/docs_contract_test.exs test/scrypath/phase108_contract_test.exs test/scrypath/phase111_contract_test.exs test/scrypath/phase112_contract_test.exs`), and `mix verify.brand`. The full gates (`mix verify.package`, the full suite, and one escalated `mix verify.repository_contracts`) run once, in Plan 02, on the phase's final code commit
- **Before `/gsd-verify-work`:** the full suite green on the final code commit
- **Max feedback latency:** 10 seconds for the quick command

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 188-01-01 | 01 | 1 | BDOC-01 | T-188-01, T-188-03 | README and built-docs image paths resolve to committed or built files; no Pages URL | contract (real `mix docs` build) | `MIX_ENV=test mix test test/release/package_metadata_test.exs` and `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | ✅ (extends existing file) | ⬜ pending |
| 188-01-02 | 01 | 1 | BDOC-02 | T-188-02 | stylesheet and assets are same-origin files from the pinned brand or `dev/docs`; head order asserted | contract (real build) | `MIX_ENV=test mix test test/release/package_metadata_test.exs` | ✅ | ⬜ pending |
| 188-01-03 | 01 | 1 | BDOC-02 | T-188-02 | rules are derived from the pin; colors bound to `brand/tokens.json`; specificity beats ExDoc | contract (stylesheet rules) | `MIX_ENV=test mix test test/release/package_metadata_test.exs` and `mix docs --warnings-as-errors` | ✅ | ⬜ pending |
| 188-02-01 | 02 | 2 | BDOC-01 | T-188-04 | allowlist only shrinks; exact ceilings; no retired directory name in README, PRODUCT or extras | contract and deny-list | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` and `MIX_ENV=test mix test test/release/package_metadata_test.exs` | ✅ | ⬜ pending |
| 188-02-02 | 02 | 2 | BDOC-01, BDOC-02 | — | release doc records the fallback, the residuals and the derivation; pinned phrases stay green | docs contract | docs_contract family command above and `mix docs --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The built-docs contract extends `test/release/package_metadata_test.exs`, which runs in `core` and in `mix verify.package`. It adds no gate (ledger stays 8 of 12).

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
