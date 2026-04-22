---
phase: 64
plan: "03"
type: execute
wave: 2
depends_on:
  - "01"
  - "02"
files_modified:
  - .planning/milestones/v1.15-ROADMAP.md
  - .planning/milestones/v1.15-REQUIREMENTS.md
  - .planning/milestones/v1.15-MILESTONE-AUDIT.md
  - .planning/MILESTONES.md
  - .planning/ROADMAP.md
  - .planning/REQUIREMENTS.md
  - .planning/PROJECT.md
  - .planning/STATE.md
autonomous: true
requirements:
  - OPS2-08
---

<threat_model>
| Threat | Mitigation |
|--------|------------|
| T-64-03: Traceability theater — OPS2 rows marked Complete without evidence | Frozen **`v1.15-REQUIREMENTS.md`** lists each **OPS2-**\* row with **pointer** to merged PR / plan **SUMMARY** / verify logs; rolling **`REQUIREMENTS.md`** table updated in same commit series. |
| T-64-03: Editing frozen milestone files after close | **Executor stops** after initial freeze; typos only with rationale note in **STATE** (per **64-CONTEXT** D-09). |
| T-64-03: Silent Hex version bump | Do **not** edit root **`mix.exs`** version or **`CHANGELOG.md`** unless user explicitly expands scope — record **actual** Hex release in text fields only. |
</threat_model>

<objective>
Close **OPS2-08** by freezing **v1.15** milestone evidence (**`milestones/v1.15-*` trio**), then updating **rolling** planning truth (**`MILESTONES.md`**, **`ROADMAP.md`**, **`REQUIREMENTS.md`** traceability, **`PROJECT.md`**, **`STATE.md`**) so shipped phases **62–64** and **OPS2-**\* requirements are honest and auditable.
</objective>

<tasks>
<task id="64-03-01" type="execute">
<read_first>
- .planning/phases/64-ia-verification-and-milestone-bookkeeping/64-CONTEXT.md
- .planning/milestones/v1.14-ROADMAP.md
- .planning/milestones/v1.14-REQUIREMENTS.md
- .planning/milestones/v1.14-MILESTONE-AUDIT.md
- .planning/ROADMAP.md
- .planning/REQUIREMENTS.md
- .planning/MILESTONES.md
- .planning/PROJECT.md
- .planning/STATE.md
</read_first>
<action>
1. Create **`.planning/milestones/v1.15-ROADMAP.md`** modeled on **`v1.14-ROADMAP.md`**: archive header (**Archived / Shipped / Hex** lines), checklist for phases **62–64** marked complete with dates, milestone summary bullets for **OPSUI second slice** (capture/catalog/**63** persistence/validation/**64** IA+verify+bookkeeping). **Hex line:** use the **current** `mix.exs` **`@version`** string from repo at close time (read **`mix.exs`** — e.g. **`0.3.4`** or whatever is present) and state whether a **new Hex publish** occurred for v1.15; if unknown, write **“in-repo milestone; Hex publish tracked separately”** verbatim rather than inventing a version.
2. Create **`.planning/milestones/v1.15-REQUIREMENTS.md`** snapshot: copy **OPS2-01..OPS2-08** rows from **`.planning/REQUIREMENTS.md`** at close with **Complete** / evidence notes for shipped items; list explicit deferrals (**Tier C** items unchanged).
3. Create **`.planning/milestones/v1.15-MILESTONE-AUDIT.md`** with YAML frontmatter like **`v1.14-MILESTONE-AUDIT.md`** (`milestone: v1.15`, `status`, scores, `nyquist` blocks). Record honest gaps (e.g. any residual **Nyquist** / **SUMMARY** frontmatter issues) — use **`tech_debt`** or **`passed`** per actual audit.
4. Update **`.planning/MILESTONES.md`**: insert a **v1.15** section at the top (mirror **v1.14** section structure) summarizing phases **62–64**, key **OPS2-**\* outcomes, links to **`milestones/v1.15-*`**, and **Automation note** if **`gsd-sdk query milestone.complete`** still fails.
5. Update **`.planning/ROADMAP.md`**: mark phases **62**, **63**, **64** checkboxes **`[x]`** with **`(completed YYYY-MM-DD)`**; move **v1.15** block under **Phases (history)** wrapped in **`<details>`** like **v1.14**; set **“next milestone”** stub per existing file convention.
6. Update **`.planning/REQUIREMENTS.md`**: traceability table rows **OPS2-05**, **OPS2-06**, **OPS2-08** → **Complete** with short evidence column referencing **`mix verify.opsui`**, **`operator_ia_contract_test`**, and **`milestones/v1.15-*`** as appropriate.
7. Update **`.planning/PROJECT.md`** **Current milestone** / narrative to **v1.15 shipped** (or **in-repo complete**) consistent with **`MILESTONES.md`**.
8. Update **`.planning/STATE.md`**: **Last Activity** timestamp, status line for milestone close, and any **Deferred Items** unchanged unless this close resolves them.
</action>
<acceptance_criteria>
- `test -f .planning/milestones/v1.15-ROADMAP.md` exits **0**.
- `test -f .planning/milestones/v1.15-REQUIREMENTS.md` exits **0**.
- `test -f .planning/milestones/v1.15-MILESTONE-AUDIT.md` exits **0**.
- `grep -q 'v1.15' .planning/MILESTONES.md` exits **0**.
- `grep -qE '\\[x\\].*Phase 62' .planning/ROADMAP.md` exits **0** and the same for **`Phase 63`** and **`Phase 64`** (checkbox completed for all three **v1.15** phases).
- `grep 'OPS2-05' .planning/REQUIREMENTS.md | grep -qi complete` exits **0** and same for **`OPS2-06`** and **`OPS2-08`** in the traceability table section.
</acceptance_criteria>
</task>
</tasks>

<verification>
Read frozen trio side-by-side: no contradictions with **`64-CONTEXT`** decisions. Confirm **`.planning/`** edits did not add forbidden strings to **published** **`README.md`** (this plan should not touch README).
</verification>

<success_criteria>
**OPS2-08:** Rolling planning docs and frozen **`v1.15-*`** trio tell the same story; **OPS2-05/06/08** traceability rows reflect verified ship state.
</success_criteria>

<must_haves>
- Frozen **`v1.15-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`** exist and are self-consistent.
- **`REQUIREMENTS.md`** shows **OPS2-05**, **OPS2-06**, **OPS2-08** as **Complete** with evidence pointers.
</must_haves>

## PLANNING COMPLETE
