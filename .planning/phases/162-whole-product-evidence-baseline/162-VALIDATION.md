---
phase: "162"
slug: "whole-product-evidence-baseline"
status: draft
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-25"
---

# Phase 162 — Validation Strategy

This is a planned documentation-artifact validation contract. `nyquist_compliant: true` means every planned task has an observable local check; `status: draft` means execution has not produced or run the baseline checker yet. Phase 162 makes claim assessments and records proof boundaries. It does not require product tests, a new CI lane, service reruns, or routine human UAT (D-04, D-08).

## Artifact Check Infrastructure

| Property | Value |
|----------|-------|
| Framework | Python 3 standard library; local Markdown matrix parser, created by 162-01-01 |
| Checker | `.planning/phases/162-whole-product-evidence-baseline/check_baseline.py` |
| Baseline | `.planning/phases/162-whole-product-evidence-baseline/162-BASELINE.md` |
| Quick command | `python3 .planning/phases/162-whole-product-evidence-baseline/check_baseline.py --through N` where N is the last base claim ID added by the task |
| Final command | `python3 .planning/phases/162-whole-product-evidence-baseline/check_baseline.py --through 24 --full-coverage` |
| Expected feedback | Under 5 seconds for local Markdown parsing and link existence; confirm during execution |

`--through N` parses every present claim row and requires each base ID through N exactly once. It checks the fixed matrix columns, nonempty reason-bearing fields, distinct D-06 assessment and freshness enums, local Source links, explicit absent-proof/result markers, duplicate assertions, and that a supported row has a dated direct source and observed result. `--full-coverage` additionally derives dimension tokens `1`–`7`, role tokens `integrator`/`feature owner`/`operator`/`maintainer`, and the seven lifecycle stage tokens from actual rows. It must fail on missing row-level evidence fields or coverage even when the missing words appear in headings. The checker reports the offending claim ID and field; it does not judge whether a source semantically supports a claim.

## Sampling

- After each task: run that task's `--through` command and inspect the claim group against its cited canonical evidence; the source/result inspection is the evidence assessment, not a user acceptance checkpoint.
- After Waves 1 and 2: run the last task's `--through` command for that wave and `git diff --check` on the baseline and checker.
- After Wave 3: run the final `--full-coverage` command, `git diff --check`, and inspect each row's source/result and D-07 freshness basis. Document absent proof as insufficiently supported or unknown and send the evidence question to Phase 163.
- Do not rerun broad product or live-service suites for the document itself. A concrete claim invalidator may justify the narrow existing command named in the claim row and its observed result must be recorded (D-05, D-07).

## Per-Task Verification Map

| Task ID | Wave | Requirement | Threat | Artifact check | Evidence assessment | Status |
|---------|------|-------------|--------|----------------|---------------------|--------|
| 162-01-01 | 1 | BASE-01, BASE-02, BASE-03 | T-162-01 to T-162-03 | `python3 .planning/phases/162-whole-product-evidence-baseline/check_baseline.py --through 1` | Check C-01 against Phase 160/161 receipts and host ownership boundary. | planned |
| 162-01-02 | 1 | BASE-01, BASE-02, BASE-03 | T-162-02, T-162-03 | `python3 .planning/phases/162-whole-product-evidence-baseline/check_baseline.py --through 6` | Inspect C-02–C-06 source/result, selected tuple, and package opt-outs. | planned |
| 162-02-01 | 2 | BASE-01, BASE-02, BASE-03 | T-162-04 | `python3 .planning/phases/162-whole-product-evidence-baseline/check_baseline.py --through 12` | Inspect C-07–C-12 write, queue, backend, and visibility boundaries. | planned |
| 162-02-02 | 2 | BASE-01, BASE-02, BASE-03 | T-162-05, T-162-06 | `python3 .planning/phases/162-whole-product-evidence-baseline/check_baseline.py --through 17` | Inspect C-13–C-17 diagnosis, chosen repair, and observed outcome separately. | planned |
| 162-03-01 | 3 | BASE-01, BASE-02, BASE-03 | T-162-07, T-162-08 | `python3 .planning/phases/162-whole-product-evidence-baseline/check_baseline.py --through 24` | Inspect C-18–C-24 release, support, security, and quality receipt limits. | planned |
| 162-03-02 | 3 | BASE-01, BASE-02, BASE-03 | T-162-09 | `python3 .planning/phases/162-whole-product-evidence-baseline/check_baseline.py --through 24 --full-coverage` | Compare every row's source/result and invalidator with current HEAD; record stale and absent-proof rows explicitly. | planned |

## Wave 0 and Handoff

No Wave 0 dependency, new test file, or framework installation is required. The Phase 162 tracer creates the local checker with its first baseline row. The final coverage map and claim-specific open evidence questions live in `162-BASELINE.md`; Phase 163 owns findings and Phase 164 owns readiness.

## Validation Sign-Off

- [x] Every planned task has a row-level automated artifact check.
- [x] The final command checks per-row completeness plus dimension, role, and stage coverage.
- [x] No watch mode, required CI promotion, or routine human UAT is planned.
- [ ] Execute the six checks as their tasks complete and record results in the plan summaries.

**Design approval:** planned 2026-09-25; execution evidence pending.
