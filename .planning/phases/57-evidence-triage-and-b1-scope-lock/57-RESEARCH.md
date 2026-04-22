# Phase 57 — Technical research

**Question:** What do we need to know to plan **Evidence triage and B1 scope lock** well?

## Summary

Phase 57 is **documentation and governance only**: no library behavior changes. Deliverables follow **`57-CONTEXT.md`**: a canonical frozen ledger at **`.planning/EVID-01-b1-v1.14.md`**, contributor-facing pointers in **`CONTRIBUTING.md`**, a **GitHub PR template** that asks for **`Evidence: EVID-57-NN`**, optional **`CODEOWNERS`** on **`lib/scrypath/`** (and optionally **`test/scrypath/`**), and normative updates to **`.planning/REQUIREMENTS.md`** + **`.planning/STATE.md`** so **EVID-01** and **B1 frozen** have a single auditable story. **`.planning/ROADMAP.md`** should reference **EVID-01** by ID without duplicating the table.

**Repo gaps today:** No **`.github/pull_request_template.md`**, no **`CODEOWNERS`**. **`CONTRIBUTING.md`** already documents verify commands and CI jobs but does not mention the B1 evidence ledger.

**LIB-01..LIB-03 triage:** Success criteria require each line item to map to **≥1** evidence row **or** be **cut**/**deferred** with written rationale. The ledger should include a short traceability subsection (table or bullets) that names **LIB-01**, **LIB-02**, **LIB-03** and points to **`EVID-57-*`** rows or states **cut** / **defer → milestone** per **D-06..D-09**.

**Risk:** Over-scoping **Phase 58** work into **57** — keep automated CI regex gates explicitly out of scope (**D-12**, **D-17**).

## Implementation notes

| Topic | Recommendation |
|-------|----------------|
| PR template | Use `.github/pull_request_template.md` (repository default). Include commented guidance so external contributors know when the token applies (B1 / **LIB-*** / core paths). |
| Evidence rows | Use **`EVID-57-01`**, **`EVID-57-02`**, … with columns **ID \| Claim \| Evidence \| LIB mapping** (mapping may reference future **LIB-*** implementation; triage column answers ship/cut/defer). |
| Freeze semantics | First content after title: **freeze date** + **append-only after freeze** per **D-04**. |
| REQUIREMENTS | Update **EVID-01** bullet or traceability row to link **`EVID-01-b1-v1.14.md`**; do not mark **LIB-*** complete in Phase 57. |

## Pitfalls

- **Silent edits** to frozen rows — forbidden; use new rows or explicit supersede flags (**D-04**).
- **Duplicating** the full evidence table in **STATE.md** — mirror only one line (**D-14**).

## Validation Architecture

This phase validates through **deterministic doc checks** rather than new ExUnit modules.

**Dimension 1 — Artifact existence:** **`EVID-01-b1-v1.14.md`** exists under **`.planning/`** and contains **`EVID-57-01`** and **`EVID-57-02`** as stable row IDs.

**Dimension 2 — LIB coverage:** File contains an explicit subsection or table rows proving **LIB-01**, **LIB-02**, and **LIB-03** are each **mapped**, **cut (v1.14)**, or **deferred** with target milestone text.

**Dimension 3 — Cross-links:** **`CONTRIBUTING.md`** contains the substring **`EVID-01-b1-v1.14.md`**. **`.github/pull_request_template.md`** contains **`Evidence:`** and **`EVID-57`**.

**Dimension 4 — Normative SSOT:** **`.planning/REQUIREMENTS.md`** references the canonical evidence file path or **EVID-01** ledger by repo-relative path.

**Dimension 5 — STATE mirror:** **`.planning/STATE.md`** **Decisions** includes a dated line mentioning **B1** frozen and pointing at **EVID-01** / **`.planning/EVID-01-b1-v1.14.md`**.

**Dimension 6 — Roadmap:** **`.planning/ROADMAP.md`** Phase 57 section references **EVID-01** and the ledger filename or path once (no third copy of the full freeze prose).

**Dimension 7 — Automation (light):** After edits, run **`mix format --check-formatted`** on touched Markdown where applicable and **`grep`** / file-read verification for required strings (no new **`mix test`** requirement for Phase 57 unless a task touches compilable code).

**Dimension 8 — Sampling continuity:** Each plan task specifies **`grep`**-able acceptance strings so `/gsd-execute-phase` can verify without subjective review.

---

## RESEARCH COMPLETE
