# Phase 32 — Technical research: AUDT-01 planning hygiene

**Question:** What do we need to know to plan **AUDT-01** (triage v1.5-close deferred rows in `STATE.md`) well?

**Answer:** This phase is **evidence-led documentation triage**. No library or CI contract changes are required unless a grep audit finds a **real contradiction** between “open gap / pending triage” language and **shipped verification** (Phase 18, completed quick tasks). Locked decisions in **`032-CONTEXT.md`** already pick disposition patterns: **terminalize rows in `STATE.md` with pointer-backed reasons**, keep **`18-UAT.md`** as audit history, cite **`SUMMARY.md`** frontmatter for completed quick tasks, then flip **`REQUIREMENTS.md`** AUDT-01 + traceability without duplicating prose.

## Findings

### 1. Deferred row inventory (authoritative)

| Category | Item | Current `STATE.md` status |
|----------|------|---------------------------|
| `uat_gap` | Phase 18 — `18-UAT.md` listed under UAT gaps while phase passed | `pending_triage_v1_6` |
| `quick_task` | `260416-eoj-automate-phase-5-verification-with-live-` | `pending_triage_v1_6` |
| `quick_task` | `260416-if2-fix-mix-exs-github-urls-add-a-github-act` | `pending_triage_v1_6` |

### 2. Evidence anchors (do not delete)

- **Phase 18:** `.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-VERIFICATION.md` documents UAT/shift-left outcomes; `.planning/milestones/v1.4-MILESTONE-AUDIT.md` states Phase 18 `18-UAT.md` status **passed**.
- **Quick tasks:** `.planning/quick/260416-eoj-automate-phase-5-verification-with-live-/260416-eoj-SUMMARY.md` and `.planning/quick/260416-if2-fix-mix-exs-github-urls-add-a-github-act/260416-if2-SUMMARY.md` — confirm `status: complete` in frontmatter before terminalizing STATE rows.

### 3. Contradiction hunt (parallel “open gaps” views)

These files still **narrate** deferred / audit-open language and should be **aligned in the same hygiene commit** per **D-03** and **D-12** in `032-CONTEXT.md`:

- `.planning/MILESTONES.md` — v1.5 and v1.4 “Known deferred items at close” bullets.
- `.planning/v1.6-MILESTONE-AUDIT.md` — YAML `gaps` / `tech_debt` still cite pending STATE triage until updated post-triage.

**Suggested grep probes (executor):** `pending_triage_v1_6`, `audit-open` + `Deferred`, `UAT gap` in `.planning/` (excluding this RESEARCH file if moved to “done” notes).

### 4. Out of scope guardrails

- **No** new GitHub issues for completed quick tasks (**D-06**).
- **No** deletion of `18-UAT.md` (**D-01**).
- **No** product/runtime promise changes unless a contradiction forces a real adopter doc fix — then **separate** scoped follow-up (**D-13**).

### 5. Verification posture

Primary automated safety net for accidental doc regressions: **`mix test test/scrypath/docs_contract_test.exs`** (unchanged paths in `.planning/` edits should keep it green). Add **grep-based** acceptance on `STATE.md` / `REQUIREMENTS.md` literals for AUDT-01 closure strings.

---

## Validation Architecture

**Nyquist / Dimension 8 — sampling strategy for doc-only hygiene**

| Dimension | Approach |
|-----------|----------|
| **1–7** | N/A or satisfied by existing repo gates — no new runtime paths. |
| **8 (feedback / regression)** | After each logical doc edit batch: run **`mix test test/scrypath/docs_contract_test.exs`**; grep for forbidden stale tokens (`pending_triage_v1_6` must be **absent** from `STATE.md` after triage; `AUDT-01` checkbox must be **`[x]`** in `REQUIREMENTS.md`). |
| **Manual** | Maintainer skim: deferred table reads as **terminal** for all three rows; no duplicate “open UAT gap” narrative elsewhere without explicit waived/superseded wording. |

**Wave 0:** Not required — no new test files; reuse existing ExDoc/docs contract tests if touched paths overlap (this phase targets `.planning/` primarily).

---

Next: `032-VALIDATION.md` + `032-01-PLAN.md` for execution.

## RESEARCH COMPLETE
