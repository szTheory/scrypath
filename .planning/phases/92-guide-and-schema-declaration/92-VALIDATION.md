---
phase: 92
slug: guide-and-schema-declaration
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-25
---

# Phase 92 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test --no-start` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run the plan-specific `mix test <file> --no-start`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 92-01-01 | 01 | 1 | TNNT-02 | T-92-01, T-92-03 | `tenant_field:` auto-adds field to `filterable:` + `fields:` idempotently; `IO.warn/2` only when `fields:` mutated; invalid value fails at compile | unit | `mix test test/scrypath/options_test.exs --no-start` | ✅ | ⬜ pending |
| 92-01-02 | 01 | 1 | TNNT-02 | — | `__scrypath__(:tenant_field)` returns declared atom or nil; existing `SearchablePost` config assertion updated for new `tenant_field: nil` key | unit | `mix test test/scrypath/schema_test.exs --no-start` | ✅ | ⬜ pending |
| 92-02-01 | 02 | 2 | TNNT-02 | T-92-10, T-92-11, T-92-12 | Post-hook merge injects tenant field when `search_document/1` omits it; no-op (no overwrite, no double-inject) when present in either atom/string key form; undeclared schemas unaffected | unit | `mix test test/scrypath/projection_test.exs --no-start` | ✅ | ⬜ pending |
| 92-03-01 | 03 | 1 | TNNT-01 | T-92-20, T-92-21, T-92-22 | Guide ships all 6 D-12 sections with real `Keyword.merge` wrong/correct footgun; no `tenant_scope:` forward reference | doc | `test -f guides/multitenancy.md && grep -c "Keyword.merge" guides/multitenancy.md` | ❌ W0 | ⬜ pending |
| 92-03-02 | 03 | 1 | TNNT-01 | — | Guide registered in ExDoc `extras:` + Getting Started group; docs-contract test asserts anchors + registration | doc | `mix test test/scrypath/docs_contract_test.exs --no-start` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `guides/multitenancy.md` (92-03-01) — net-new file; docs-contract test (`@multitenancy_guide File.read!`) fails at compile until it exists. Write the guide before the contract test asserts on it.

*Existing test infrastructure (`options_test.exs`, `schema_test.exs`, `projection_test.exs`, `docs_contract_test.exs`) covers all other phase requirements — additions only, no new framework or fixtures beyond the in-file test modules each plan defines.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guide narrative is accurate, well-structured, and usable by adopters without reading source | TNNT-01 | Content-quality judgment — correct-pattern-first ordering, prose depth, footgun clarity | Read `guides/multitenancy.md` end-to-end; confirm all 6 D-12 sections present; verify the `Keyword.merge` example shows the real last-key-wins drop (not a strawman); confirm `tenant_scope:` / Phase 93 are NOT referenced (D-09) |
| `IO.warn` advisory message is clear and actionable | TNNT-02 | Message tone/clarity is subjective | Compile a schema with `tenant_field: :tenant_id` but without `:tenant_id` in `fields:`; confirm the warning names the field, explains the auto-add, and states how to silence it |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (guides/multitenancy.md)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-25
