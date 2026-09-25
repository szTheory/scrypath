---
phase: 111
slug: advisory-proof-stability-decision
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-31
---

# Phase 111 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (project standard) |
| **Config file** | `mix.exs` / `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/workflow_wiring_test.exs -x` |
| **Full suite command** | `mix test --exclude integration --exclude docs_contract --include requires_clean_workspace` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mix/tasks/workflow_wiring_test.exs -x`
- **After every plan wave:** Run `mix test --exclude integration --exclude docs_contract --include requires_clean_workspace`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds for the quick command

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 111-01-01 | 01 | 1 | STAB-01 | T-111-01 | Evidence-based advisory decision cannot be claimed without explicit job/run metadata and promotion criteria | contract | `mix test test/scrypath/phase111_contract_test.exs -x` | ❌ W0 | ⬜ pending |
| 111-01-02 | 01 | 1 | STAB-02 | T-111-02 | Required gate posture remains lean and branch-protection promotion is not introduced by Phase 111 | contract | `mix test test/mix/tasks/workflow_wiring_test.exs -x` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scrypath/phase111_contract_test.exs` — codify STAB-specific advisory/promotion rules, evidence-window fields, retry-as-flake classification, artifact expectations, owner response, and no branch-protection promotion.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Recent remote `phase105-e2e` job-history evidence is interpreted correctly | STAB-01 | GitHub Actions run availability is external and time-varying; local tests can only assert the decision record shape | Use `gh run list --workflow ci.yml` and `gh run view <run_id> --json jobs` to sample recent runs, then confirm the decision record names run, SHA, event, job name, conclusion, runtime, retry/flaky signal, artifact usefulness, and owner response expectation. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
