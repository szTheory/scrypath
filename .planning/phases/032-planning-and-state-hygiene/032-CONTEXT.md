# Phase 32: Planning and state hygiene - Context

**Gathered:** 2026-04-18  
**Status:** Ready for planning

<domain>
## Phase Boundary

Close **AUDT-01** by giving every **v1.5-close deferred row** in **`.planning/STATE.md`** a **terminal disposition** and **one-line reason**, without opening new product scope. Work may include **small doc edits** elsewhere only when they remove a **contradiction** (e.g. a list that still implies open UAT when verification says passed).

Out of scope: new verify tasks, library features, or GitHub issues unless a row represents **real, owned** follow-up work.

</domain>

<decisions>
## Implementation Decisions

### 1. UAT gap row (Phase 18 / `18-UAT.md`)

- **D-01:** Treat **`18-UAT.md`** and **`18-VERIFICATION.md`** as the **evidence artifacts** for Phase 18. Do **not** delete `18-UAT.md`; it documents shift-left automation and is part of the audit story.
- **D-02:** The `STATE.md` row is **bookkeeping debt**, not product debt: resolve it by **terminalizing the row** (e.g. `obsolete` or `resolved`) with a **one-line pointer** to the passing narrative and artifacts (e.g. `18-VERIFICATION.md` UAT shift-left note, `v1.4-MILESTONE-AUDIT.md` “passed” line, path to `18-UAT.md`).
- **D-03:** If **any other doc or table** still lists Phase 18 under “UAT gaps” or open human verification, **edit that list** in the same hygiene pass (reclassify or remove the row, add closure pointer). **Rule:** no parallel “open gaps” view may contradict phase **passed** without an explicit `waived` / `obsolete` / `superseded by` explanation.

### 2. Quick-task rows (`260416-eoj`, `260416-if2`)

- **D-04:** Both tasks already show **`status: complete`** in their **`SUMMARY.md`** frontmatter — authoritative closure lives **in-repo under** `.planning/quick/.../`.
- **D-05:** Close matching **`STATE.md` deferred rows** in the same triage pass with terminal status **`obsolete`** or **`resolved`** and one line citing the **exact relative path** to each `SUMMARY.md` (not a second narrative).
- **D-06:** **Keep** the existing quick-task directories on the default branch as **audit-friendly artifacts** (ADR-like permanence, explicit status in frontmatter). **Do not** open GitHub issues solely to mirror completed work — that creates **phantom debt** for adopters and triage noise for maintainers.
- **D-07:** Optional later cleanup: if `.planning/quick/` volume grows, introduce an **`archive/`** subtree and a short index — **not** required for AUDT-01 if frontmatter and `STATE` are honest.

### 3. Where terminal reasons live (STATE vs REQUIREMENTS)

- **D-08:** **`.planning/STATE.md` deferred table** is the **canonical triage ledger** for milestone-close deferrals: every row gets a **terminal status** + **one-line reason** understandable in ~30 seconds.
- **D-09:** **`.planning/REQUIREMENTS.md`**: when AUDT-01 is satisfied, flip **`AUDT-01`** checkbox and the **traceability table** cell to **Complete** with **no long prose duplication** — at most a short pointer (“closed per `STATE.md` deferred table”) if you want cross-file navigation.
- **D-10:** **GitHub Issues** only for items that need **discussion, assignment, or cross-release tracking**. Rows that are “listing noise” or “completed quick stubs” **close in-repo**; do not use the issue tracker as a dump for triaged noise.

### 4. Milestone close sequencing (v1.6)

- **D-11:** Prefer **one atomic commit (or PR)** for AUDT-01 closure: `STATE.md` row terminalizations + `REQUIREMENTS.md` AUDT-01 completion + any **minimal** doc list fix that removes contradiction.
- **D-12:** **`.planning/v1.6-MILESTONE-AUDIT.md`** (or equivalent audit artifact): refresh in the **same hygiene window** so milestone evidence matches `REQUIREMENTS` — avoids “audit says open, STATE says closed” drift.
- **D-13:** **Adopter-facing honesty:** anything that changes **runtime promises** belongs in **CHANGELOG / README / ExDoc**, not only internal tables. This phase’s edits are planning noise triage; if triage discovers a **real** user-visible gap, **file follow-up** as a scoped phase or issue — do not smuggle product work into AUDT-01.

### Ecosystem and DX principles (why this coheres)

These choices mirror what works in **mature Hex-era OSS**: **executable checks and verification docs establish reality**; **STATE** is for **maintainer routing** at boundaries; **REQUIREMENTS** is for **traceability**, not duplicate storytelling. Same spirit as **Searchkick/Scout-style honesty** about sync and operational reality — but applied here to **planning artifacts** so internal checklists never contradict shipped truth (**principle of least surprise** for the next maintainer or auditor).

### Claude's Discretion

None for disposition — user requested a single coherent playbook. Planner may choose exact terminal status **labels** (`obsolete` vs `resolved`) as long as they are **terminal**, **mutually consistent**, and **pointer-backed**.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — AUDT-01 definition; v1.6 scope; phase 32 success criteria
- `.planning/ROADMAP.md` — Phase 32 row and milestone context
- `.planning/STATE.md` — Deferred items table to triage

### Evidence for deferred rows

- `.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-UAT.md` — Phase 18 UAT / shift-left map
- `.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-VERIFICATION.md` — Verification narrative including UAT shift-left
- `.planning/milestones/v1.4-MILESTONE-AUDIT.md` — External audit line on Phase 18 UAT status
- `.planning/quick/260416-eoj-automate-phase-5-verification-with-live-/260416-eoj-SUMMARY.md` — Completed quick task evidence
- `.planning/quick/260416-if2-fix-mix-exs-github-urls-add-a-github-act/260416-if2-SUMMARY.md` — Completed quick task evidence

### Hygiene / audit

- `.planning/v1.6-MILESTONE-AUDIT.md` — Milestone audit to align after AUDT-01
- `.planning/PROJECT.md` — Vision, constraints, v1.6 intent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Planning artifacts:** Existing phase verification and quick-task **`SUMMARY.md`** files are the **reusable closure pattern** — cite paths instead of rewriting history.

### Established Patterns

- **Report-first / additive ops discipline** (Scrypath product) extends to **planning**: terminalize deferrals with **pointers**, avoid silent deletes, avoid duplicate “open” lists.

### Integration Points

- **`STATE.md` ↔ `REQUIREMENTS.md` ↔ milestone audit:** single hygiene commit keeps these aligned; no library `lib/` changes expected unless triage uncovers a doc bug outside `.planning/`.

</code_context>

<specifics>
## Specific Ideas

User requested **subagent research** and a **one-shot coherent recommendation set**; decisions above consolidate OSS maintainer patterns (single owner for open vs closed, close with evidence/pointers, keep completed quick-task trees, avoid phantom GitHub issues).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within AUDT-01 hygiene.

</deferred>

---

*Phase: 032-planning-and-state-hygiene*  
*Context gathered: 2026-04-18*
