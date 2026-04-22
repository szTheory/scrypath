# Requirements: Scrypath — Milestone v1.16

**Defined:** 2026-04-22  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.16 Requirements

### Playbook execution (OPSUI)

- [ ] **OPS3-01**: Operator can start a saved **`playbook_format: 1`** playbook from the catalog or detail view and observe an explicit **idle → running → success** (or **failure**) lifecycle in the UI without ambiguous intermediate states.

- [ ] **OPS3-02**: When a playbook run fails, the operator sees a **structured, copy-friendly** error surface that names the failure class and links to **canonical** maintainer or adopter docs (guides, operator docs, or **`@moduledoc`** targets) within **two hops** — no orphan stack traces as the only signal.

### Runner–library contract

- [ ] **OPS3-03**: Playbook execution uses **documented, stable** result and error shapes aligned with the same **`Scrypath`** / Mix-facing contracts used outside OPSUI where applicable; **automated tests** fail if OPSUI and core diverge on representative success and failure fixtures.

### Verification, examples, and close

- [ ] **OPS3-04**: **`mix verify.opsui`** and **`docs_contract_test`** (or equivalent doc-contract anchors) cover **new execution surfaces** so LiveView, runner wiring, and contributor docs cannot drift silently.

- [ ] **OPS3-05**: **`examples/playbooks/`** ships **at least two** JTBD-shaped fixtures (for example **sync triage** and **federation / multi-search inspection**) that **agree** with guide copy and are referenced from operator or contributor docs.

- [ ] **OPS3-06**: Rolling planning artifacts (**`MILESTONES.md`**, **`PROJECT.md`**, **`ROADMAP.md`**, this file’s traceability) reflect **v1.16** close discipline: frozen **`milestones/v1.16-*`** trio prepared at milestone end; **Hex** / **`mix.exs`** narrative only when a release is in scope for the close phase.

## v2+ Requirements (not in v1.16)

### Operator UI depth (still deferred)

- **OPSUI-FUT-02** — Meilisearch cluster “vendor dashboard” parity — see **`milestones/v1.10-REQUIREMENTS.md`**.

### Heavy CI / Tier C

- Playwright-on-all-flows, Meilisearch-in-OPSUI CI — **`milestone-candidates.md`**.

## Out of Scope

| Feature | Reason |
|---------|--------|
| **OPSUI-FUT-02** vendor-style cluster observability | Explicitly deferred; not part of honest playbook execution loop. |
| **Net-new search ranking / indexing features** | v1.16 is operator-trust and contract depth, not search algorithm breadth. |
| **Mandatory Meilisearch in default OPSUI CI** | Remains **Tier C** until a proven regression gap; stub-first discipline continues. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| OPS3-01 | Phase 65 | Complete |
| OPS3-02 | Phase 65 | Complete |
| OPS3-03 | Phase 66 | Pending |
| OPS3-04 | Phase 67 | Pending |
| OPS3-05 | Phase 67 | Pending |
| OPS3-06 | Phase 67 | Pending |

**Coverage:**

- v1.16 requirements: **6** total  
- Mapped to phases: **6**  
- Unmapped: **0** ✓

---

*Requirements defined: 2026-04-22*  
*Last updated: 2026-04-22 after `/gsd-new-milestone` — v1.16 opened*
