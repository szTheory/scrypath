# Phase 32 — Pattern map (AUDT-01)

**Purpose:** Closest in-repo analogs for **documentation-only** milestone hygiene and **REQ checkbox + STATE table** closure.

## Analog: adoption / verify phases (PLAN shape)

- **`.planning/phases/029-golden-path-adoption-documentation/029-01-PLAN.md`** — canonical **frontmatter** (`phase`, `plan`, `wave`, `depends_on`, `files_modified`, `autonomous`, `requirements`, `must_haves`), **`<threat_model>`** block for ASVS L1 doc threats, and **XML tasks** with `<read_first>`, `<action>`, `<acceptance_criteria>`, `<verify>`.

## Analog: requirements traceability

- **`.planning/REQUIREMENTS.md`** — checkbox + **Traceability** table row pattern used when ADPT/EXAM/VRFY rows moved to **Complete** (copy that mechanical edit style for **AUDT-01**).

## Analog: milestone audit refresh

- **`.planning/v1.6-MILESTONE-AUDIT.md`** — YAML `gaps` / `tech_debt` structure to update when AUDT-01 evidence exists (remove stale “deferred rows pending” claims; align scores with `REQUIREMENTS.md`).

## Pattern mapping complete

No `lib/` analog required — phase is `.planning/` scoped per **032-CONTEXT.md**.
