---
phase: 40
slug: all-expansion
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-20
---

# Phase 40 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` (test env) |
| **Quick run command** | `mix test test/scrypath/multi_search/entries_test.exs` |
| **Full suite command** | `mix test test/scrypath/multi_search test/scrypath/search_many_test.exs` |
| **Estimated runtime** | ~30–90 seconds (local; depends on parallel load) |

---

## Sampling Rate

- **After every task commit:** Run the **quick** command when the task touched `Entries`; otherwise `mix test test/scrypath/search_many_test.exs` for `Search` tasks.
- **After every plan wave:** Run **full suite command** above.
- **Before `/gsd-verify-work`:** `mix compile --warnings-as-errors` and full suite green.
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 40-01-01 | 01 | 1 | FED-02 | T-40-01-01 / — | No user-controlled module load from strings | unit | `mix test test/scrypath/multi_search/entries_test.exs` | ✅ | ⬜ pending |
| 40-01-02 | 01 | 1 | FED-02 | T-40-01-02 / — | Errors are atoms/tuples; no echo of raw lists in logs from tests | unit | `mix test test/scrypath/search_many_test.exs` | ✅ | ⬜ pending |
| 40-02-01 | 02 | 1 | FED-02 | — | N/A | unit | `mix test test/scrypath/search_many_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] ExUnit + `mix test` — existing infrastructure covers the phase.

*Wave 0: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| *None* | — | — | — |

*All phase behaviors have automated verification (FakeBackend / unit paths).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
