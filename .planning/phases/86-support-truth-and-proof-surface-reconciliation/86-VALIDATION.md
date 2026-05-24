---
phase: 86
slug: support-truth-and-proof-surface-reconciliation
status: validated
nyquist_compliant: true
created: 2026-05-24
updated: 2026-05-24
---

# Phase 86 Validation Ledger

Append-only validation ledger for Phase 86. This file locks the proof seams the phase plans must satisfy before execution starts.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit docs/task contracts plus focused repo grep checks |
| **Config file** | `test/test_helper.exs`, `mix.exs`, and active planning markdown under `.planning/` |
| **Quick phase gate** | `mix verify.adopter` after Wave 0 repairs the fast contract |
| **Task contract command** | `mix test test/mix/tasks/verify_adopter_test.exs` |
| **Readiness contract command** | `mix test test/scrypath/readiness_contract_test.exs` |
| **Docs contract command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Docs build command** | `mix docs --warnings-as-errors` |
| **Planning truth command** | `rg -n "SearchModule|support-and-compatibility|outside-adopter evidence|defended in-repo proof" .planning/ROADMAP.md .planning/MILESTONES.md .planning/STATE.md .planning/milestones/v1.20-ROADMAP.md .planning/milestones/v1.20-MILESTONE-AUDIT.md` |

## Validation Targets

| ID | Requirement | Proof seam | Automated command | Status |
|----|-------------|------------|-------------------|--------|
| 86-VAL-01 | TRUTH-01 | One current canonical support/readiness surface exists in the checkout and maintainer/adopter docs route to it instead of relying on removed support-guide references. | `mix test test/scrypath/readiness_contract_test.exs` | planned |
| 86-VAL-02 | TRUTH-01 | The canonical support/readiness surface states only defended branch-tip truth: runtime anchors, sync-mode posture, proof command family, repo-clone vs Hex boundary, and in-repo proof vs outside-adopter evidence. | `mix test test/scrypath/readiness_contract_test.exs && mix docs --warnings-as-errors` | planned |
| 86-VAL-03 | TRUTH-02 | `mix verify.adopter` fast mode references only files that exist and stays narrow, auth-free, and service-free. | `mix test test/scrypath/readiness_contract_test.exs test/mix/tasks/verify_adopter_test.exs` | planned |
| 86-VAL-04 | TRUTH-02 | `mix help verify.adopter`, maintainer docs, the example README, and CI/live-proof wording all agree on the fast/live contract and current canonical live path. | `mix test test/scrypath/docs_contract_test.exs` | planned |
| 86-VAL-05 | TRUTH-03 | Active planning files distinguish current branch-tip truth from archive-era `Scrypath.SearchModule` claims and no longer describe the missing layer as current shipped fact. | `rg -n "SearchModule|support-and-compatibility|outside-adopter evidence|defended in-repo proof" .planning/ROADMAP.md .planning/MILESTONES.md .planning/STATE.md .planning/milestones/v1.20-ROADMAP.md .planning/milestones/v1.20-MILESTONE-AUDIT.md` | planned |
| 86-VAL-06 | TRUTH-03 | Docs and planning preserve the distinction between defended in-repo proof and reviewed outside-adopter evidence without widening into a SearchModule recovery project. | `mix test test/scrypath/docs_contract_test.exs` | planned |

## Per-Plan Verification Map

| Task ID | Plan | Wave | Requirement | Automated command | File Exists | Status |
|---------|------|------|-------------|-------------------|-------------|--------|
| 86-01-01 | 01 | 1 | TRUTH-01 | `rg -n "support-and-compatibility\\.md" README.md CONTRIBUTING.md guides/overview.md mix.exs` | ✅ / ✅ / ✅ / ✅ | planned |
| 86-01-02 | 01 | 1 | TRUTH-01 | `mix docs --warnings-as-errors` | ✅ | planned |
| 86-02-01 | 02 | 2 | TRUTH-02 | `test -f test/scrypath/readiness_contract_test.exs` | ❌ Before 86-02 | planned |
| 86-02-02 | 02 | 2 | TRUTH-02 | `mix test test/scrypath/readiness_contract_test.exs test/mix/tasks/verify_adopter_test.exs` | ❌ Before 86-02 | planned |
| 86-02-03 | 02 | 2 | TRUTH-02 | `mix verify.adopter` | ✅ | planned |
| 86-03-01 | 03 | 2 | TRUTH-03 | `rg -n "SearchModule|support-and-compatibility|outside-adopter evidence|defended in-repo proof" .planning/MILESTONES.md .planning/ROADMAP.md .planning/STATE.md` | ✅ / ✅ / ✅ | planned |
| 86-03-02 | 03 | 2 | TRUTH-01, TRUTH-02, TRUTH-03 | `mix test test/scrypath/docs_contract_test.exs` | ✅ | planned |
| 86-03-03 | 03 | 2 | TRUTH-01 | `mix docs --warnings-as-errors` | ✅ | planned |

## Baseline Notes

- The checked-out tree currently lacks `guides/support-and-compatibility.md`, even though active planning history still refers to it as if it were present.
- `lib/mix/tasks/verify.adopter.ex` still names `test/scrypath/readiness_contract_test.exs` in the fast path, but that file does not exist in the checkout.
- `test/mix/tasks/verify_adopter_test.exs` currently exercises arg guards and live prerequisite failures, but does not prove the fast branch targets only existing files.
- `mix test test/scrypath/docs_contract_test.exs` currently fails on a stale JTBD gap-map reviewed-date assertion, so it should remain the broader drift suite rather than the default fast adopter gate until Phase 86 reconciles that adjacent truth seam.
- Active planning surfaces and the `v1.20` archive still contain current-tense `Scrypath.SearchModule` claims even though the checked-out code, guides, and docs contracts treat that layer as absent.
- The repo already has one bounded docs-contract seam and one maintainer-facing task seam; Phase 86 should tighten those exact seams rather than adding a second broad truth harness.

## Manual-Only / Deferred

| Behavior | Requirement | Disposition | Notes |
|----------|-------------|-------------|-------|
| Relanding `Scrypath.SearchModule` code or guide on `main` | TRUTH-03 | deferred | Phase 86 only reconciles truth and classification; recovery is a separate future decision. |
| Broad snapshot testing of README, guides, and planning prose | TRUTH-01, TRUTH-03 | rejected | Use bounded string/order assertions and focused planning grep checks instead. |
| Service orchestration inside `mix verify.adopter` | TRUTH-02 | rejected | Live mode remains orchestration-only and GitHub Actions or local operators own services/readiness. |
| Treating outside-adopter evidence as already present | TRUTH-03 | rejected | Phase 86 must preserve the branch-tip distinction between defended in-repo proof and pending outside review. |

## Acceptance Gate

Phase 86 validation can only be marked complete when:

- `86-VAL-01` and `86-VAL-02` prove one current canonical support/readiness surface exists and the short docs route to it truthfully.
- `86-VAL-03` and `86-VAL-04` prove `mix verify.adopter` fast/live behavior matches real files, real prerequisites, and the example/CI contract.
- `86-VAL-05` and `86-VAL-06` prove active planning tells the truth about missing `SearchModule` surfaces and distinguishes current in-repo proof from outside-adopter evidence.

## Sign-Off

- [x] Requirements `TRUTH-01` through `TRUTH-03` each map to explicit proof seams
- [x] The validation ledger exists before execution so Nyquist dimension 8 has a concrete artifact
- [x] The ledger does not claim execution evidence that has not yet been produced
- [x] The highest-risk drift areas are called out directly: canonical support authority, stale fast-task targets, and archive-vs-branch-tip planning truth
