---
phase: 147
slug: ecommerce-mounted-ops-remediation-and-closure-evidence
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-25
---

# Phase 147 — Validation Strategy

> Per-phase validation contract for ecommerce dependency remediation and four-graph closure evidence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Phoenix; Playwright for advisory browser proof |
| **Config file** | `examples/scrypath_ecommerce/mix.exs`; `playwright.config.ts` |
| **Quick run command** | `cd examples/scrypath_ecommerce && mix test test/scrypath_ecommerce_web/controllers/page_controller_test.exs` |
| **Full suite command** | `cd examples/scrypath_ecommerce && mix precommit` plus the required root suite from `CONTRIBUTING.md` |
| **Estimated runtime** | To be measured and recorded with the closure receipts |

---

## Sampling Rate

- **After the Plan 01 dependency edit:** Inspect the ecommerce manifest/lock diff and run isolated checked-lock and canonical mounted-path receipts.
- **Before the Plan 01 commit:** Run the complete deterministic and required-service gate bundle and stop on any drift or failure.
- **Wave 2:** Run exact-SHA detached proof and cleanup before classifying the focused browser subset.
- **Wave 3:** Capture the four-graph same-window closure rows before changing requirement/todo closure state.
- **Before `$gsd-verify-work`:** Required deterministic and service evidence must pass; browser evidence must be classified truthfully as passed, failed, or unavailable.
- **Max feedback latency:** Record measured command durations; no three consecutive implementation tasks may lack automated evidence.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 147-01-01 | 01 | 1 | SEC-04, COMPAT-01 | T-147-01, T-147-02, T-147-06 | Six approved bounds, causal lock, canonical mounted sources, ecommerce gates, required service preparation, and root gates pass before the atomic commit | tracer/resolver/integration | Checked lock; `Mix.Project.deps_paths/0`; `mix test test/scrypath_ecommerce_web/controllers/page_controller_test.exs`; `mix precommit`; `mix e2e.prepare`; unsuppressed audit; named root gates | ✅ existing Mix/ExUnit commands | ✅ green |
| 147-02-01 | 02 | 2 | SEC-04 | T-147-02, T-147-04, T-147-05 | Exact implementation SHA fresh-resolves in range, uses canonical mounted paths, passes required proof, and cleans up safely | resolver/integration/evidence | Detached lockless `mix deps.get`; nine-package range assertion; mounted-path assertion; focused/full/service/audit gates; cleanup/preservation assertions | ✅ receipt authored in task | ✅ green |
| 147-02-02 | 02 | 2 | COMPAT-03 | T-147-03, T-147-05 | Browser proof is separately classified and never upgraded from unavailable or retry-flaky to clean passing | browser/classification | `npx playwright test e2e/harness.spec.ts e2e/operator.spec.ts --workers=1` when exact-SHA prerequisites exist; deterministic ledger-structure check always runs | ✅ specs/config exist | ✅ green |
| 147-03-01 | 03 | 3 | COMPAT-01, EVID-01, EVID-02 | T-147-03, T-147-05 | Four ordered graph rows are nonempty/audit-clean and the topology names four batches with exact commit roles | repository/evidence | `mix deps.get --check-locked && mix hex.audit` in root, legacy, Ops, ecommerce; `git merge-base --is-ancestor`; `git diff-tree`; ledger structure check | ✅ receipt authored in task | ✅ green |
| 147-03-02 | 03 | 3 | EVID-02 | T-147-03, T-147-07 | Closure truth and todo state advance only after every ledger predicate passes | planning/evidence | File-location, ordered-batch wording, requirement-checkbox, protected-file, and ledger closure assertions | ✅ existing planning files | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] No new test scaffold is required: `page_controller_test.exs` is the inspected narrow route/asset/link contract.
- [x] Plan 01 defines the non-persistent two-variable isolation receipt and stop ordering.
- [x] Plans 02-03 define the compact `147-CLOSURE-EVIDENCE.md` schema, exact-SHA cleanup receipt, four-graph matrix, and topology ledger.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | Every required phase predicate has an automated command or fail-closed evidence assertion; browser availability is classified by the executor rather than manually approved | — |

---

## Validation Sign-Off

- [x] All five tasks have `<automated>` verification
- [x] Sampling continuity: every task has automated evidence
- [x] Wave 0 covers receipt, focused-test, ledger, and topology references
- [x] No watch-mode flags
- [x] Feedback latency is measured in task summaries; required long gates are sequenced after causal checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-08-25

---

## Validation Audit 2026-08-25

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Current audit evidence:

- Root, legacy Phoenix, ScrypathOps, and ecommerce each passed checked-lock resolution and an unsuppressed Hex audit.
- The Compose model validated and the Phase 147 workflow/CI contract suite passed with 47 tests and 0 failures.
- The closure ledger contains the four graph rows in order, every constituent remediation commit, and exactly one honest focused-browser classification.
- Live `main` protection includes `ecommerce-mounted-smoke` as a strict required status context.
- `make -C examples/scrypath_ecommerce verify-mounted` passed 4 focused Chromium tests on the first run and removed all owned containers, network, and volume.
- The required `ecommerce-mounted-smoke` PR job passed on a clean GitHub runner in 3m29s after the Compose health contract gained a five-minute cold-initialization period; run `32893006895`, job `97949120013`.
