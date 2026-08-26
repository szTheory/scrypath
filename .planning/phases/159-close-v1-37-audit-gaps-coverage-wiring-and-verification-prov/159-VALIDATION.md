---
phase: 159
slug: close-v1-37-audit-gaps-coverage-wiring-and-verification-prov
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-26
---

# Phase 159 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

**Execution graph:** seven plans across five waves: Plan 01 → Plan 02 → parallel Plans 03/04/05 → Plan 06 → Plan 07.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix, structural repository-contract tests, Git topology probes, and GSD validation artifacts |
| **Config file** | `mix.exs` and `.planning/config.json` |
| **Quick run command** | `mix test test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors` |
| **Full suite command** | `mix verify.core --exclude integration --exclude docs_contract` |
| **Estimated runtime** | Quick check under 30 seconds; full closure bundle measured and recorded during execution |

---

## Sampling Rate

- **After every task commit:** Run the task's focused automated command; use `mix test test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors` whenever workflow wiring changes.
- **After every plan wave:** Run `mix verify.core --exclude integration --exclude docs_contract` plus the wave's evidence-integrity checks.
- **Before `$gsd-verify-work`:** Run the complete D-18 local bundle and retain one exact-SHA hosted workflow receipt satisfying D-19.
- **Max feedback latency:** 30 seconds for the focused wiring test; long-running closure checks are isolated to wave and phase gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 159-01-01 | 01 | 1 | TEST-05 / D-01–D-06 | T-159-01–04 | Workflow remains read-only, SHA-pinned, advisory, and free of new secrets | structural ExUnit + workflow lint + real report | `mix test test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors && actionlint .github/workflows/ci.yml && mix verify.coverage` | ❌ W0 extension needed | ⬜ pending |
| 159-01-02 | 01 | 1 | TEST-05 / D-05–D-06 | T-159-01–04 | Contributor language cannot promote informational coverage into a merge/percentage gate | repository contract | `mix verify.repository_contracts` | ✅ existing gate | ⬜ pending |
| 159-02-01 | 02 | 2 | TEST-01 / D-07–D-12 | T-159-05–09 | Detached probes cannot mutate the primary worktree or launder present-state proof into history | bounded Git topology + focused test execution | finite parent-SHA probe commands recorded with exact commits and exits | ❌ W0 evidence inventory needed | ⬜ pending |
| 159-02-02 | 02 | 2 | Original 31 requirements / D-13, D-16–D-17 | T-159-07–09 | Canonical matrix preserves exact ID set, evidence class, limitations, and original ownership | Markdown set/link integrity | `mix run -e` 31-ID equality check from Plan 02 | ❌ W0 matrix needed | ⬜ pending |
| 159-03-01 | 03 | 3 | Phase 148–151 original requirements / D-07, D-10–D-17 | T-159-10–12 | Early-phase retrospective indexes preserve TEST-01 limits and canonical authority | Markdown pair/link/cardinality | phase 148–151 pair/link loop from Plan 03 | ❌ W0 artifacts needed | ⬜ pending |
| 159-04-01 | 04 | 3 | Phase 152–155 original requirements / D-07, D-10, D-14–D-17, D-20 | T-159-10, T-159-13–14 | Middle-phase indexes remain phase-specific and preserve CI topology | Markdown pair/link/cardinality | phase 152–155 pair/link loop from Plan 04 | ❌ W0 artifacts needed | ⬜ pending |
| 159-05-01 | 05 | 3 | Phase 156–158 original requirements / D-07, D-10, D-14–D-17, D-20–D-21 | T-159-10, T-159-13–14 | Late-phase indexes bound supply-chain, performance, and closeout claims | Markdown pair/link/cardinality | phase 156–158 pair/link loop from Plan 05 | ❌ W0 artifacts needed | ⬜ pending |
| 159-06-01 | 06 | 4 | Phase 148–153 original requirements / D-14–D-16 | T-159-12–14 | Nyquist verdicts derive from completed inputs and preserve TEST-01/TEST-05 pending limits | per-phase validation review | phase 148–153 triple/link/verdict loop from Plan 06 | ❌ post-input artifacts needed | ⬜ pending |
| 159-06-02 | 06 | 4 | Phase 154–158 + Phase 159 map / D-14–D-17, D-19, D-22 | T-159-12–14 | Later validations are evidence-derived and the seven-plan/five-wave map is exact | validation + plan-map integrity | phase 154–158 triple loop plus `159-07-03` map assertion from Plan 06 | ❌ post-input artifacts needed | ⬜ pending |
| 159-07-01 | 07 | 5 | Closure / D-18 | T-159-16, T-159-18–19 | Local closure binds every deterministic command and environment to one committed evidence SHA | local integration bundle | complete D-18 command chain from Plan 07 | ❌ execution receipt needed | ⬜ pending |
| 159-07-02 | 07 | 5 | TEST-05 + closure / D-19–D-22 | T-159-15–21 | Hosted proof binds required jobs and producer/artifact metadata to the exact candidate SHA before audit | GitHub Actions + artifact inspection + milestone audit | `gh run view` receipt check plus final audit link assertions | ❌ hosted receipt needed | ⬜ pending |
| 159-07-03 | 07 | 5 | Closure / D-19, D-22 | T-159-15, T-159-17, T-159-19 | Human independently confirms hosted run/artifact identity and narrow TEST-01 waiver | blocking external provenance review | manual checkpoint steps in Plan 07 | ❌ external review needed | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `test/mix/tasks/workflow_wiring_test.exs` with job-scoped assertions for the coverage event guard, advisory posture, canonical command, always-upload behavior, `cover/` path, and seven-day retention.
- [ ] Create the canonical Phase 159 31-requirement evidence matrix and its field/link integrity check.
- [ ] Inventory exact production commits, parent revisions, candidate characterization tests, and bounded probe commands before assigning any TEST-01 historical verdict.
- [ ] Create retrospective `SUMMARY.md` and `VERIFICATION.md` inputs in parallel Plans 03–05 before Plan 06 performs the real Nyquist validation pass.
- [ ] Reconcile this validation map to exactly seven plans across five waves, with Plan 06 depending on Plans 03–05 and Plan 07 depending on Plan 06.
- [x] Spec-less probe fallback skipped: Phase 159 has no newly mapped requirement IDs, so no probe-derived predicates were generated or invented.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hosted coverage evidence is retained for the exact closing commit | TEST-05 / D-19 | Requires GitHub Actions infrastructure and artifact metadata unavailable to local ExUnit | Dispatch or observe the scheduled `ci.yml` run for the closing SHA; record run URL, trigger, attempt, workflow/source SHA, required-job conclusions, coverage artifact name/path, digest, and retention |
| Historically irrecoverable characterization chronology is waived narrowly | TEST-01 / D-11 | Git cannot prove an unrecorded earlier action | Review each failed parent-SHA probe, confirm the evidence class is `historically unprovable`, and approve only a requirement-scoped waiver that does not convert present-state proof into historical proof |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Focused feedback latency under 30 seconds
- [ ] `nyquist_compliant: true` set only after real Phase 148–159 evidence inputs exist and validation passes

**Approval:** pending
