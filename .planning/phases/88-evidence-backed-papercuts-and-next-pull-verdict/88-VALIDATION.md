---
phase: 88
slug: evidence-backed-papercuts-and-next-pull-verdict
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 88 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test`, docs build via `mix docs`, plus bounded planning-file shell checks |
| **Config file** | `test/test_helper.exs` via root `mix test` |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10-30 seconds |

---

## Sampling Rate

- **After every task commit:** Run the narrowest command from the per-task map below.
- **After every plan wave:** Run `mix test test/scrypath/docs_contract_test.exs`.
- **Before `$gsd-verify-work`:** Run `mix test` and the phase-local planning grep checks.
- **Max feedback latency:** 60 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 88-01-01 | 01 | 1 | FIX-01 | T-88-02 | Guide contains custom Oban job instructions and the specific phrases "temporary workaround" and "first-class feature". | docs | `grep -i "temporary workaround" guides/related-data-and-reindexing.md && grep -i "first-class feature" guides/related-data-and-reindexing.md` | ✅ planned | ⬜ pending |
| 88-01-02 | 01 | 1 | FIX-01 | T-88-01 | The test suite passes and verifies the presence of the required strings in the guide. | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ planned | ⬜ pending |
| 88-01-03 | 01 | 1 | FIX-02 | none | All three planning files reflect the v1.23 milestone closure and explicit verdict. | planning | `grep -i "related-data propagation" .planning/STATE.md && grep -i "FIX-01" .planning/REQUIREMENTS.md | grep -i "Complete"` | ✅ planned | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing docs-contract tests can carry the new guide checks.
- [x] Phase-local evidence and verdict artifacts can be validated with bounded `grep` checks; no new harness is required.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-24
