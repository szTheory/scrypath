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
| 159-01-01 | 01 | 1 | TEST-05 / D-01–D-06 | T-159-01 | Workflow remains read-only, SHA-pinned, advisory, and free of new secrets | structural ExUnit + workflow lint | `mix test test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors && actionlint .github/workflows/ci.yml` | ❌ W0 extension needed | ⬜ pending |
| 159-02-01 | 02 | 1 | TEST-01 / D-07–D-12 | Detached probes cannot mutate the primary worktree or launder present-state proof into history | Git topology + focused test execution | bounded parent-SHA probe commands recorded with exact commits and exits | ❌ W0 evidence inventory needed | ⬜ pending |
| 159-03-01 | 03 | 2 | Original 31 requirements / D-13–D-17 | Matrix and phase-local indexes preserve evidence class, limitations, and original ownership | Markdown integrity + GSD validation | matrix cardinality/link checks plus per-phase `$gsd-validate-phase` results | ❌ W0 artifacts needed | ⬜ pending |
| 159-04-01 | 04 | 3 | Closure / D-18–D-22 | Closure binds local and hosted evidence to the exact source revision and does not expose secrets | local integration + hosted CI receipt | D-18 command bundle followed by exact-SHA `ci.yml` run and artifact inspection | ❌ execution receipt needed | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `test/mix/tasks/workflow_wiring_test.exs` with job-scoped assertions for the coverage event guard, advisory posture, canonical command, always-upload behavior, `cover/` path, and seven-day retention.
- [ ] Create the canonical Phase 159 31-requirement evidence matrix and its field/link integrity check.
- [ ] Inventory exact production commits, parent revisions, candidate characterization tests, and bounded probe commands before assigning any TEST-01 historical verdict.
- [ ] Create retrospective `SUMMARY.md` and `VERIFICATION.md` inputs for Phases 148–158 before running their real Nyquist validation pass.

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
