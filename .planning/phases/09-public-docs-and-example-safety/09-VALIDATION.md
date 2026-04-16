---
phase: 09
slug: public-docs-and-example-safety
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-16
---

# Phase 09 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs test/support/docs/phoenix_examples_test.exs -x` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/docs_contract_test.exs test/support/docs/phoenix_examples_test.exs -x`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | DOCS-01 | T-09-01 / — | README install snippet exposes only Scrypath and keeps optional/runtime setup out of the base dependency fence | unit | `mix test test/scrypath/docs_contract_test.exs -x` | ✅ | ⬜ pending |
| 09-01-02 | 01 | 1 | DOCS-01 | T-09-02 / — | Install-adjacent guides do not reintroduce transport or optional queue dependencies as mandatory base setup | unit | `mix test test/scrypath/docs_contract_test.exs -x` | ✅ | ⬜ pending |
| 09-02-01 | 02 | 2 | DOCS-02 | T-09-03 / T-09-04 | JSON examples normalize invalid page params to `1` without raising on malformed request input | unit | `mix test test/support/docs/phoenix_examples_test.exs test/scrypath/docs_contract_test.exs -x` | ✅ | ⬜ pending |
| 09-02-02 | 02 | 2 | DOCS-02 | T-09-04 / — | Fixture-backed docs tests lock the safe page-normalization contract for missing, malformed, zero, and negative values | unit | `mix test test/support/docs/phoenix_examples_test.exs -x` | ✅ | ⬜ pending |
| 09-03-01 | 03 | 3 | DOCS-03 | T-09-05 / — | LiveView/context publish examples accept realistic nested string-key params | unit | `mix test test/support/docs/phoenix_examples_test.exs -x` | ✅ | ⬜ pending |
| 09-03-02 | 03 | 3 | DOCS-03 | T-09-06 / — | Narrow request-shape smoke test proves Plug/Phoenix-style nested params match fixture expectations | unit | `mix test test/support/docs/phoenix_request_shape_smoke_test.exs test/support/docs/phoenix_examples_test.exs -x` | ➜ task output | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README and guide copy still read clearly in rendered HexDocs order | DOCS-01 / DOCS-02 / DOCS-03 | ExUnit can prove contract strings and behavior, but not overall reading flow in rendered docs | Run `mix docs`, open the README and Phoenix guide pages, and confirm the install path stays concise and the controller/LiveView examples still read as one context-first story |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-16
