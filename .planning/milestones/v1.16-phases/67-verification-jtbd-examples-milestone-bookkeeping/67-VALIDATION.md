---
phase: 67
slug: verification-jtbd-examples-milestone-bookkeeping
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 67 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveViewTest |
| **Config file** | `test/test_helper.exs`, `scrypath_ops/test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs scrypath_ops/test/scrypath_ops/playbook/doc_resolver_test.exs scrypath_ops/test/scrypath_ops/playbook/examples_contract_test.exs scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` |
| **Full suite command** | `mix test test/scrypath/docs_contract_test.exs && mix verify.opsui` |
| **Estimated runtime** | ~90 seconds plus local PostgreSQL availability for `scrypath_ops` test runs |

---

## Sampling Rate

- **After every task commit:** Run the narrowest task command from the table below.
- **After every plan wave:** Run `mix test test/scrypath/docs_contract_test.exs` plus the affected `scrypath_ops` tests.
- **Before `$gsd-verify-work`:** Run `mix verify.opsui` and the root docs-contract slice.
- **Max feedback latency:** 90 seconds once PostgreSQL is available locally for `scrypath_ops`.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 67-02-01 | 02 | 1 | OPS3-05 | T-67-04 | Canonical JTBD fixtures remain portable, validation-friendly, and free of backend-only knobs | unit | `cd scrypath_ops && mix scrypath_ops.playbooks.validate examples/playbooks` | ✅ | ⬜ pending |
| 67-02-02 | 02 | 1 | OPS3-05 | T-67-05 | Docs and validation coverage point at the exact canonical fixture filenames and command | unit | `mix test scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs` | ✅ | ⬜ pending |
| 67-01-01 | 01 | 2 | OPS3-04 | T-67-02 | `DocResolver` path/fragment mappings and schema-guide anchors stay truthful and `RunFailure` preserves bounded fields | unit | `mix test scrypath_ops/test/scrypath_ops/playbook/doc_resolver_test.exs scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs` | ✅ | ⬜ pending |
| 67-01-02 | 01 | 2 | OPS3-04 | T-67-01, T-67-03 | Bounded PlaybookLive affordances and maintainer-facing docs/fixture truth stay aligned without expanding `mix verify.opsui` | integration | `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs scrypath_ops/test/scrypath_ops/playbook/examples_contract_test.exs && mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 67-03-01 | 03 | 3 | OPS3-06 | T-67-07 | Rolling planning files reflect the real post-phase state and remove stale pre-plan wording | unit | `rg -n "OPS3-04|OPS3-05|OPS3-06|Phase 67|v1.16" .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/PROJECT.md .planning/STATE.md` | ✅ | ⬜ pending |
| 67-03-02 | 03 | 3 | OPS3-06 | T-67-08, T-67-09 | `v1.16-*` archives exist with truthful wording and `.planning/MILESTONES.md` changes only if `v1.16` is genuinely closed | unit | `test -f .planning/milestones/v1.16-ROADMAP.md && test -f .planning/milestones/v1.16-REQUIREMENTS.md && test -f .planning/milestones/v1.16-MILESTONE-AUDIT.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.
- [x] Validation distinguishes root docs-contract execution from delegated `scrypath_ops` tests.
- [x] PostgreSQL prerequisite is explicit for `scrypath_ops` test commands and `mix verify.opsui`.

---

## Manual-Only Verifications

- Confirm whether `v1.16` genuinely closed before editing `.planning/MILESTONES.md`; if not, leave historical milestone tracking untouched.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s once PostgreSQL is available
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-22
