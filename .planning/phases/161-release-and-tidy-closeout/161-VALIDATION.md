---
phase: "161"
slug: "release-and-tidy-closeout"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-24"
---

# Phase 161 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (root Mix test suite) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix verify.core --exclude integration --exclude docs_contract`; exact-SHA hosted closeout helper for release evidence |
| **Estimated runtime** | ~30 seconds for the focused docs contract; hosted closeout is service-backed and longer |

---

## Sampling Rate

- **After every task commit:** Run the affected focused contract or dependency check.
- **After every plan wave:** Run the focused applicable gates; use hosted exact-SHA closeout for candidate/final acceptance.
- **Before `$gsd-verify-work`:** Required exact-SHA gates must be green and the release disposition must match published evidence or an explicit `release-ready` blocker.
- **Max feedback latency:** 30 seconds for local focused checks; hosted closeout is asynchronous.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 161-01-01 | 01 | 1 | REL-01 | T-161-01 | Mint audit findings are cleared by the selected fixed dependency graph | security audit | `mix verify.deep_quality` | ✅ existing gate | ⬜ pending |
| 161-01-02 | 01 | 1 | DOC-01, HYGIENE-01 | — | Docs accurately state package proof behavior and its evidence limits | contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ extend existing | ⬜ pending |
| 161-02-01 | 02 | 2 | REL-01 | T-161-02 | Required checks and closeout evidence bind to the final candidate SHA | hosted CI | `node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"` | ✅ existing helper | ⬜ pending |
| 161-02-02 | 02 | 2 | REL-01, CLOSE-01 | T-161-03 | Published package, docs, tag, and source agree, or the exact external blocker and resume action are recorded | release workflow | Release workflow runs `mix verify.release_publish X.Y.Z` followed by `mix verify.release_parity X.Y.Z` | ✅ existing workflow | ⬜ pending |
| 161-02-03 | 02 | 2 | HYGIENE-01, CLOSE-01 | — | Milestone-owned resources are cleaned and pre-existing unrelated changes remain present | inventory | `git status --short` and `git worktree list --porcelain` | ✅ built-in Git | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Extend `test/scrypath/docs_contract_test.exs` to cover the synthetic-evidence limit required by DOC-01. Existing ExUnit and package/deep-quality gates cover all other requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Merge the reviewed release PR and authorize publication when repository permissions and the publisher secret are available | REL-01 | GitHub merge authorization and publisher credentials are external maintainer actions; automated post-publish checks verify the resulting artifacts | Use the documented Release Please flow; require successful `verify.release_publish` and `verify.release_parity` before marking shipped. If authorization is unavailable, record the named blocker and exact resume action as `release-ready`. |

---

## Validation Sign-Off

- [ ] All tasks have an `<automated>` verify or an external-action disposition.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers the only identified missing docs-contract assertion.
- [ ] No watch-mode flags.
- [ ] `nyquist_compliant: true` set after the plan assigns verifiers to all tasks.

**Approval:** pending
