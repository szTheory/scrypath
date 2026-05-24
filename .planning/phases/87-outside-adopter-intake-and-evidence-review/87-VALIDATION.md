---
phase: 87
slug: outside-adopter-intake-and-evidence-review
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 87 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test`, docs build via `mix docs`, plus bounded planning-file shell checks |
| **Config file** | `test/test_helper.exs` via root `mix test` |
| **Quick run command** | `mix test test/scrypath/readiness_contract_test.exs test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix verify.adopter && mix docs --warnings-as-errors && mix test --exclude integration --exclude docs_contract` |
| **Estimated runtime** | ~90-180 seconds |

---

## Sampling Rate

- **After every task commit:** Run the narrowest command from the per-task map below.
- **After every plan wave:** Run `mix test test/scrypath/readiness_contract_test.exs test/scrypath/docs_contract_test.exs`.
- **Before `$gsd-verify-work`:** Run `mix verify.adopter`, `mix docs --warnings-as-errors`, and the phase-local planning grep checks.
- **Max feedback latency:** 180 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 87-01-01 | 01 | 1 | ADOPT-01, ADOPT-03 | T-87-01 | One canonical outside-adopter intake guide exists, routes live runbook detail back to the example README, and states the defended proof path, runtime assumptions, repo-clone boundary, and evidence requirements | contract | `mix verify.adopter && mix test test/scrypath/docs_contract_test.exs` | ✅ planned | ⬜ pending |
| 87-01-02 | 01 | 1 | ADOPT-01, ADOPT-03 | T-87-02 | README/support/contributing/example wayfinding routes to the intake guide without duplicating authority | docs | `mix docs --warnings-as-errors` | ✅ planned | ⬜ pending |
| 87-02-01 | 02 | 2 | ADOPT-02 | T-87-03 | Two exact source submissions exist at `87-SUBMISSION-01.md` and `87-SUBMISSION-02.md`, and both are imported into phase-local attempt files with source and provenance markers before review starts | unit | `test -f .planning/phases/87-outside-adopter-intake-and-evidence-review/87-SUBMISSION-01.md && test -f .planning/phases/87-outside-adopter-intake-and-evidence-review/87-SUBMISSION-02.md && test -f .planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-01.md && test -f .planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-02.md && rg -n "^## Provenance|outside adopter|submitted by|date received" .planning/phases/87-outside-adopter-intake-and-evidence-review/87-SUBMISSION-01.md .planning/phases/87-outside-adopter-intake-and-evidence-review/87-SUBMISSION-02.md && rg -n "^Source artifact: .*87-SUBMISSION-0[12]\\.md$|^## Provenance|outside adopter|submitted by|date received" .planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-01.md .planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-02.md` | ✅ planned | ⬜ pending |
| 87-02-02 | 02 | 2 | ADOPT-02 | T-87-03 | A human reviewer confirms both attempt files are genuine outside-adopter submissions before review continues | unit + manual | `test -f .planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-01.md && test -f .planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-02.md && rg -n "^## Provenance|^Source artifact:|outside adopter|submitted by|date received" .planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-01.md .planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-02.md` | ✅ planned | ⬜ pending |
| 87-02-03 | 02 | 2 | ADOPT-02 | T-87-03 | Two reviewed adopter attempts exist with admissibility class, finding buckets, and evidence bundle fields present | unit | `rg -n "Class [ABCD]|docs/onboarding gap|support-truth drift|product gap|env/setup papercut|first failure/confusion point|commands run" .planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-01.md .planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-02.md` | ✅ planned | ⬜ pending |
| 87-02-04 | 02 | 2 | ADOPT-02 | T-87-03, T-87-04 | The review ledger summarizes both attempts, keeps non-evidence separate, and ends with an explicit defended-path gate that either passes or escalates the phase | unit | `test -f .planning/phases/87-outside-adopter-intake-and-evidence-review/87-EVIDENCE-REVIEW.md && rg -n "Attempt 01|Attempt 02|Class A|Class B|Class C|Class D|docs/onboarding gap|support-truth drift|product gap|env/setup papercut|^Defended-path gate: (PASS|FAIL - escalate)$" .planning/phases/87-outside-adopter-intake-and-evidence-review/87-EVIDENCE-REVIEW.md` | ✅ planned | ⬜ pending |
| 87-03-01 | 03 | 3 | ADOPT-02, ADOPT-03 | T-87-05 | The defended-path gate passes before verdict work begins, the verdict memo names exactly one final outcome, non-`stop soon` remains Class-A-only, and rolling planning truth mirrors that same active verdict | unit | `rg -n "^Defended-path gate: PASS$" .planning/phases/87-outside-adopter-intake-and-evidence-review/87-EVIDENCE-REVIEW.md && test -f .planning/phases/87-outside-adopter-intake-and-evidence-review/87-VERDICT.md && test "$(sed -n 's/^Final verdict: //p' .planning/phases/87-outside-adopter-intake-and-evidence-review/87-VERDICT.md | wc -l | tr -d ' ')" = "1" && rg -n "^Final verdict: (stop soon|related-data propagation|tenant-safe access)$|^Decision gate: non-stop-soon requires Class A defended-path evidence$" .planning/phases/87-outside-adopter-intake-and-evidence-review/87-VERDICT.md && test "$(rg -n "^Active next-pull verdict: (stop soon|related-data propagation|tenant-safe access)$" .planning/PROJECT.md .planning/STATE.md | wc -l | tr -d ' ')" = "2"` | ✅ planned | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing docs-contract and readiness-contract tests can carry the intake-guide routing checks.
- [x] Existing docs build already validates published-guide structure and link hygiene.
- [x] Phase-local evidence and verdict artifacts can be validated with bounded `test -f` and `rg` checks; no new harness is required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Confirm the two reviewed attempts are real outside-adopter runs rather than maintainer reconstructions | ADOPT-02 | Repo checks can verify artifact completeness, but they cannot prove who performed the attempt or whether it reflects genuine external usage | Read both attempt files during Task `87-02-02`, confirm provenance and notes match real outside-adopter activity, and reject maintainer-written mock attempts |
| Confirm the final verdict memo does not over-weight docs/env papercuts as product wedges | ADOPT-02, ADOPT-03 | The wedge decision is judgment-heavy even when the supporting artifacts exist | Read `87-VERDICT.md` after the ledger is complete and verify the chosen verdict matches the classified evidence strength and locked ranking |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-24
