---
phase: 69
slug: adopter-verify-spine
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 69 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` |
| **Config file** | `test/test_helper.exs` via `mix test`; root `mix.exs` also defines the test alias |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test` |
| **Estimated runtime** | ~30-90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/docs_contract_test.exs`
- **After every plan wave:** Run `mix verify.adopter`
- **Before `$gsd-verify-work`:** Fast contract slice green plus `mix verify.adopter --live` with services up
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 69-01-01 | 01 | 1 | INTG-02 | T-69-01 | `mix verify.adopter` stays service-free by default and documents `--live` explicitly | unit | `mix test test/mix/tasks/verify_adopter_test.exs` | ✅ planned | ⬜ pending |
| 69-01-02 | 01 | 1 | INTG-02 | T-69-02 | CLI registration and task runtime behavior fail loudly on unexpected args or missing live prerequisites | unit | `mix test test/mix/tasks/verify_adopter_test.exs` | ✅ planned | ⬜ pending |
| 69-02-01 | 02 | 2 | INTG-02 | T-69-03 | live path mirrors the canonical example `mix deps.get` + `mix test` contract | integration | `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test` | ✅ | ⬜ pending |
| 69-02-02 | 02 | 2 | INTG-02 | T-69-04 | CI/docs/task wording remain pinned to the same fast/live command family | unit / contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer help text is understandable at the CLI | INTG-02 | Output clarity is partly semantic, not just structural | Run `mix help verify.adopter`; confirm it explains fast default, `--live`, and required services/env without implying silent fallback |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-22
