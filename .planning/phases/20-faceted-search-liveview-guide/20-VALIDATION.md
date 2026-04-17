---
phase: 20
slug: faceted-search-liveview-guide
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-17
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/search_test.exs test/scrypath/options_test.exs` |
| **Full suite command** | `mix test --exclude external_meilisearch` |
| **Estimated runtime** | ~30–90 seconds (project size) |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` command from its PLAN.md.
- **After every plan wave:** Run `mix test --exclude external_meilisearch`.
- **Before `/gsd-verify-work`:** Full suite green + `mix compile --warnings-as-errors`.
- **Max feedback latency:** 120 seconds per wave

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-01-T1 | 01 | 1 | FACET-01, FACET-02 | T-20-01-01 / — | Schema compile errors contain no secrets | unit | `mix test test/scrypath/options_test.exs` | ✅ | ⬜ pending |
| 20-01-T2 | 01 | 1 | FACET-10 | T-20-01-02 | Non-goals rejected at compile or validate | unit | `mix test test/scrypath/options_test.exs` | ✅ | ⬜ pending |
| 20-02-T1 | 02 | 2 | FACET-03, FACET-04 | T-20-02-01 | `{:error, {:unknown_facet, _}}` never leaks index URL | unit | `mix test test/scrypath/search_test.exs` | ✅ | ⬜ pending |
| 20-02-T2 | 02 | 2 | FACET-05, FACET-06 | — | Decoded counts are integers from JSON only | unit | `mix test test/scrypath/search_test.exs` | ✅ | ⬜ pending |
| 20-02-T3 | 02 | 2 | FACET-09 | — | Wire payload uses Meilisearch filter grammar only | unit | `mix test test/scrypath/meilisearch/query_test.exs` (create if needed) | ⬜ W0 | ⬜ pending |
| 20-03-T1 | 03 | 3 | FACET-07 | T-20-03-01 | Settings map never embeds API key from schema | unit | `mix test test/scrypath/meilisearch/settings_test.exs` | ✅ | ⬜ pending |
| 20-04-T1 | 04 | 4 | FACET-08 | — | Guide examples compile-only; no live creds | unit | `mix test test/scrypath/docs_contract_test.exs test/support/docs/phoenix_examples_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] ExUnit + existing `FakeBackend` / `Req.Test` patterns — no new framework install.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ExDoc guide readability | FACET-08 | Prose quality | `mix docs` → open `faceted-search-with-phoenix-liveview.html`; confirm four patterns + appendix present. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
