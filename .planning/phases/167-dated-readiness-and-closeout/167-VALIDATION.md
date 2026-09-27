---
phase: "167"
slug: "dated-readiness-and-closeout"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-27"
---

# Phase 167 — Validation Strategy

> Draft validation contract mapped to the user-approved three-plan outline. Planning coverage is not runtime evidence or Nyquist sign-off.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Python standard-library `unittest` for the current-phase structural contract; existing ExUnit for the readiness documentation contract if its source changes |
| **Config file** | None; follow the archived standalone checker and fixture pattern |
| **Quick run command** | `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .planning/phases/167-dated-readiness-and-closeout -p 'test_*.py' -v` |
| **Full suite command** | Focused Python contract suite plus the complete record CLI below; existing candidate/final hosted closeout supplies external machine acceptance |
| **Estimated runtime** | Target under 10 seconds for local Python checks; measure during execution. Hosted exact-source closeout is a separate external gate with longer latency. |

---

## Sampling Rate

- **After every task commit:** Run the task's fast local record/fixture command from the map after Task 167-01-01 creates the checker and fixtures. Hosted dispatch is reserved for the two ordered acceptance stages below.
- **After every plan wave:** Run the focused suite and applicable evidence/complete record CLI. No support guide change is planned; if that scope changes, use the existing readiness documentation contract.
- **Before `$gsd-verify-work`:** Confirm local contract checks and the applicable candidate/final-source closeout evidence.
- **Local feedback target:** Under 10 seconds for each task's local command; actual timing remains unmeasured until execution. Hosted acceptance is mandatory and outside this target; asynchronous polling keeps progress visible without reducing its latency.

---

## Per-Task Verification Map

Task IDs are plan number plus one-based task order. All six tasks have a fast local automated command and a sibling failure direction in their PLAN. Plan 03 also has two separate mandatory external acceptance entries, each with its own immediate failure direction. New commands become runnable in the stated task before its verification step; they are not claimed to exist or pass during planning.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Fast Local Automated Feedback | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 167-01-01 | 01 | 1 | CLOSE-03, VERIFY-02 | T-167-01, T-167-02, T-167-03 | Pinned raw-byte history guard; exact source/scenario/job joins; safe links | unit + real-record tracer | `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .planning/phases/167-dated-readiness-and-closeout -p 'test_*.py' -v` plus Evidence CLI | Created by this task | ✅ passed (8 tests; evidence CLI) |
| 167-01-02 | 01 | 1 | CLOSE-03, VERIFY-02 | T-167-02, T-167-04 | All eight software requirements join to bounded evidence; complete C-09 comparison | unit + source/receipt inspection | Focused suite plus Evidence CLI with `--require-all-claims` | Created by 167-01-01; expanded here | ✅ passed (8 tests; source comparison) |
| 167-02-01 | 02 | 2 | GATE-04, CLOSE-03, VERIFY-02 | T-167-05, T-167-06, T-167-07 | Six exact conditions, truthful same-day dates, fail-closed arithmetic, history preservation and visible verification debt | unit + full-record tracer | Focused suite plus Complete CLI | Complete CLI created by this task | ✅ passed (14 tests; complete CLI) |
| 167-02-02 | 02 | 2 | GATE-04, CLOSE-03, VERIFY-02 | T-167-05, T-167-07, T-167-08 | Independent condition reasoning, exact Mint lock/source disposition and ownership-limited cleanup | source/record contract + semantic evidence review | Complete CLI with `--compare-source "$(git rev-parse HEAD)"` then `git diff --check` | Created by 167-02-01 | ✅ passed (14 tests; dated NOT READY decision; diff check) |
| 167-03-01 | 03 | 3 | CLOSE-03, VERIFY-02, GATE-04 | T-167-09, T-167-10, T-167-12, T-167-13 | Candidate SHA and immutable artifacts, independent actual named Phoenix outcomes, sanitized receipt capture | unit; external candidate acceptance below | Focused suite | Existing fixture harness; metadata fixtures added here | ✅ candidate accepted (18 tests; exact-source hosted retry; path + package advisory observations) |
| 167-03-02 | 03 | 3 | CLOSE-03, VERIFY-02, GATE-04 | T-167-09, T-167-11, T-167-12, T-167-13 | Every tracked write precedes final attestation; final freshness; no later tracked receipt edits | unit; external final-source acceptance below | Focused suite | Fixture harness created in prior tasks | ⏳ local preparation passed; final-source continuation pending parent tracking |

### Exact commands used by the map

### Execution observations (2026-09-27)

- Plan 01 tasks passed their focused suite and evidence/source checks; the Plan 01 summary records 8 passing tests.
- Plan 02 tasks passed the focused suite and complete checker; the Plan 02 summary records 14 passing tests. The dated assessment remains NOT READY: conditions 1, 3, 4, and 5 PASS; condition 2 FAIL because the tracked Phoenix consumer lock retains vulnerable Mint 1.9.3 with an unresolved High advisory; condition 6 was UNKNOWN at the assessment cutoff.
- Plan 03 Task 1 passed 18 focused tests. Candidate `441a7e75367e3d354a2da66261850530363cf1f4` passed hosted closeout on retry run `36347716269`; the first same-source attempt `36347003052` failed only the mounted-service readiness check and is recorded as a flake. The actual advisory path and package commands each emitted the named authorized-tenant search/facet success marker and passed 16 tests. Candidate artifacts and observations are recorded in `167-EVIDENCE.json` and the append-only section of `167-CLOSEOUT.md`.
- Plan 03 Task 2's local complete checker and receipt validation pass at candidate HEAD, and the focused suite passes 18 tests. The final-source continuation is still pending parent-owned review/security/verification and normal tracking commits. Therefore the final hosted row above remains pending; no candidate result is represented as final-source acceptance.

Focused suite observed for Plan 03: 18 tests passed in 1.821 seconds (local feedback target: under 10 seconds). The candidate receipt, expected SHA, complete record, and current-source comparison also passed together. Nyquist validation remains unsigned: the validation strategy stays `status: draft`, `nyquist_compliant: false`, and no Nyquist checkbox is inferred from these runs.

The assessment's source, cutoff, condition 6 UNKNOWN, and NOT READY conclusion are unchanged by later candidate evidence.

**Focused suite:**

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .planning/phases/167-dated-readiness-and-closeout -p 'test_*.py' -v
```

**Evidence CLI:**

```sh
PYTHONDONTWRITEBYTECODE=1 python3 .planning/phases/167-dated-readiness-and-closeout/check_readiness.py --root . --scope evidence --evidence .planning/phases/167-dated-readiness-and-closeout/167-EVIDENCE.json
```

**Complete CLI:**

```sh
PYTHONDONTWRITEBYTECODE=1 python3 .planning/phases/167-dated-readiness-and-closeout/check_readiness.py --root . --scope complete --evidence .planning/phases/167-dated-readiness-and-closeout/167-EVIDENCE.json --assessment .planning/phases/167-dated-readiness-and-closeout/167-ASSESSMENT.md --closeout .planning/phases/167-dated-readiness-and-closeout/167-CLOSEOUT.md
```

### Mandatory external acceptance stages

Both stages are required by D-08 and CONTRIBUTING's candidate/final-source topology. They follow successful local feedback and remain pending until their actual hosted observations pass. They are excluded from the local feedback-latency target.

| Order | Task | Preconditions | Automated acceptance | Additional required evidence |
|---|---|---|---|---|
| 1 — Candidate | 167-03-01 | Focused suite passes; candidate implementation/assessment/checker changes are committed | Hosted closeout command below, once for that candidate; reuse the action's captured result | Independently successful named Phoenix path/package outcomes, exact source/run/attempt/job identities and candidate C-09 freshness disposition |
| 2 — Final source | 167-03-02 | Candidate accepted; all task and orchestrator tracking writes committed; semantic C-09 inspection at captured final SHA complete | Complete CLI with `--compare-source "$(git rev-parse HEAD)"`, then `git diff --exit-code`, then `git diff --cached --exit-code`, then Hosted closeout command, as chained in Plan 03 | External receipt checked against captured final HEAD and artifact identities; unchanged HEAD and clean tracked state afterward; no later tracked edit |

**Hosted closeout command** (verbatim existing repository topology; invoked once at each ordered stage):

```sh
node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"
```

**Inherited final C-09 inspection command** (verbatim prior-phase command):

```sh
git diff dc400b2b57aec0ca6b0ef16c9477d266fd41a433 HEAD -- lib examples config test/support .github/workflows mix.exs mix.lock
```

A successful Git diff only produces comparison data. Review every relevant delta semantically; the checker validates complete recorded dispositions without approving their reasoning. Hosted closeout is longer than the local feedback budget: launch asynchronously and poll, preserving exit status and reporting actual hosted latency separately. Polling does not shorten the gate. Its required job list does not include Phoenix; inspect the actual named advisory path/package scenario result independently. The external-stage table and PLAN verification entries describe the same two dispatches; reuse their receipts without duplicate candidate execution.

Task 167-03-02's final command is a mandatory execute-phase continuation **after all normal tracked completion artifacts are committed**. While the orchestrator still owns tracking writes, this task is pending final machine acceptance. Do not label an earlier candidate run final. Final receipt metadata is retained externally and checked against captured final HEAD; no tracked update follows success.

---

## Wave 0 Requirements

- [ ] 167-01-01 creates the current-phase checker and focused standard-library fixture harness in the leading tracer. This satisfies the scaffold prerequisite before any new command is invoked; there is no separate execution Wave 0 plan.
- [ ] 167-01-01 covers independent pinned historical-byte preservation and exact source/receipt identity mutation cases; 167-01-02 expands all-claim and C-09 comparison coverage.
- [ ] 167-02-01 adds six-condition shape/arithmetic, truthful same-day timestamp and owned-inventory fixtures; 167-03-01 adds exact closeout metadata mutation fixtures.
- [ ] All modes retain structural-only output and fail closed on malformed input; semantic evidence judgment and hosted attestation remain separate.

---

## Manual-Only Verifications

All software acceptance claims use automated scenario evidence or exact-SHA hosted evidence; routine human UAT is not required. The six-condition semantic assessment remains a maintainer evidence judgment and must cite its sources and claim limits; the structural checker cannot approve it.

---

## Validation Sign-Off

- [x] All six accepted plan tasks have `<automated>` verification, concrete creation order and `<fails_when>` failure direction.
- [x] Sampling continuity: every task has fast local automated feedback; candidate and final-source hosted acceptance remain separately mandatory and ordered.
- [x] New fixture/CLI commands are created by the named tasks before use; no dangling MISSING reference is planned.
- [x] No interactive watch-mode test runner is planned; hosted monitor execution is polled asynchronously.
- [ ] Feedback latency is under 10 seconds for focused local checks.
- [ ] Set `nyquist_compliant: true` only after the strategy is validated against the accepted plans.

**Outline approval:** user approved three plans with two tasks each. **Validation sign-off:** pending actual Nyquist review and execution evidence; `status: draft`, `nyquist_compliant: false` and `wave_0_complete: false` intentionally remain unchanged.
