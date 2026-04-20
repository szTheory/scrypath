---
phase: 43
slug: per-query-relevance-runtime
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-20
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/scrypath/per_query_tuning_test.exs` (after Plan 01 creates file) or `mix test path/to/touched_test.exs` |
| **Full slice command** | `mix verify.phase43` (after Plan 03 wires the task) |
| **Estimated runtime** | ~30–90 seconds for focused slice |

---

## Sampling Rate

- **After every task commit:** Run quick command covering the task’s test file(s).
- **After every plan wave:** Run `mix verify.phase43` when available; otherwise `mix test` on all Phase 43–touched tests.
- **Before `/gsd-verify-work`:** `mix verify.phase43` exits 0.
- **Max feedback latency:** Target under 120s for the focused slice.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-01-01 | 01 | 1 | TUNE-PQ-01 | T-43-01-01 | Allowlist only — no credential passthrough | unit | `mix test test/scrypath/per_query_tuning_test.exs` | ✅ W0 | ⬜ pending |
| 43-01-02 | 01 | 1 | TUNE-PQ-01 | T-43-01-02 | Debug metadata low-cardinality | unit | `mix test test/scrypath/search_test.exs` | ✅ | ⬜ pending |
| 43-02-01 | 02 | 2 | TUNE-PQ-01 | — | N/A | unit | `mix test test/scrypath/search_many_test.exs` | ✅ | ⬜ pending |
| 43-03-01 | 03 | 3 | TUNE-PQ-02, TUNE-PQ-03 | T-43-03-01 | Doc gate — no secrets in verify task | unit | `mix verify.phase43` | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scrypath/per_query_tuning_test.exs` — stubs or full tests for `:per_query` validation and payload projection (Plan 01).
- [ ] Existing infrastructure (`Mix.Tasks.Verify.Phase41` pattern) covers composer scaffolding for Plan 03.

*Wave 0 is satisfied when Plan 01 creates the primary test module.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live Meilisearch ranking-score fields | TUNE-PQ-01 (engine semantics) | CI focused slice avoids daemon | Run integration job or local Meilisearch with version ≥ project floor; one manual search with `showRankingScoreDetails` enabled. |

*If none for CI scope: "All Phase 43 PR-gate behaviors have automated verification in the focused slice."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency under target
- [ ] `nyquist_compliant: true` set in frontmatter when phase closes

**Approval:** pending
