# Requirements: Scrypath

**Defined:** 2026-04-20  
**Milestone:** v1.9 — *Per-query relevance & tuning pipeline*  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Naming note:** v1.3 shipped declarative index settings as historical **`TUNE-01`..`TUNE-08`**. This file’s **`TUNE-PQ-*`** IDs implement the **v1.7 Future** backlog item that v1.7 called **`TUNE-01`** (**per-query runtime**). **`TUNE-PIPE-*`** implements the v1.7 **`TUNE-PIPE-01`** design prerequisite, decomposed here for traceability.

## v1.9 Requirements

### Pipeline specification (prefix: TUNE-PIPE)

- [ ] **TUNE-PIPE-01**: An authoritative written spec defines **precedence and ordering** — how per-query overrides interact with schema defaults, managed index settings, and existing **`Scrypath.search/3`** / **`search_many/2`** behavior.
- [ ] **TUNE-PIPE-02**: The same spec defines **Meilisearch request mapping** — which APIs and payload fields apply for v1.9, and which surfaces remain intentionally unsupported or deferred.
- [ ] **TUNE-PIPE-03**: The spec lists **explicit non-goals**, **expected error shapes**, and **telemetry or observability** expectations that **`TUNE-PQ-*`** implementation must honor.
- [ ] **TUNE-PIPE-04**: The spec ends with a **checklist** that maintainers can use to declare the pipeline **ready for implementation** (**`TUNE-PQ-*`**).

### Per-query runtime (prefix: TUNE-PQ) — implements backlog **TUNE-01**

- [ ] **TUNE-PQ-01**: Application code can request **per-query relevance or settings overrides** that behave exactly as the locked **`TUNE-PIPE-*`** spec describes for **`Scrypath.search/3`**, with documented rules for **`search_many/2`** when applicable.
- [ ] **TUNE-PQ-02**: Automated tests and an agreed **`mix verify.phaseNN`** (or successor slice) cover **happy paths**, **rejection paths**, and **regressions** for the per-query path.
- [ ] **TUNE-PQ-03**: Documentation plus **`docs_contract_test.exs`** (or an agreed equivalent) **anchors** the public contract so README / guides / ExDoc cannot drift silently.

## Future requirements

### Operator UI (prefix: OPSUI)

- **OPSUI-01**: Optional operator **LiveView** dashboard over **`Scrypath.*`** visibility and federation-shaped **`search_many/2`** — remains a **separate milestone** unless explicitly merged into v1.9.

## Out of Scope (v1.9)

| Item | Reason |
|------|--------|
| **OPSUI-01** delivery | Deferred to a UI-focused milestone; v1.9 is **search behavior** and **pipeline semantics**. |
| Vector / hybrid / personalization search | Still excluded per **`.planning/PROJECT.md`** Out of Scope. |
| Public multi-backend facade | Unchanged product boundary. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TUNE-PIPE-01 | Phase 42 | Pending |
| TUNE-PIPE-02 | Phase 42 | Pending |
| TUNE-PIPE-03 | Phase 42 | Pending |
| TUNE-PIPE-04 | Phase 42 | Pending |
| TUNE-PQ-01 | Phase 43 | Pending |
| TUNE-PQ-02 | Phase 43 | Pending |
| TUNE-PQ-03 | Phase 43 | Pending |

**Coverage:**

- v1.9 requirements: **7** total  
- Mapped to phases: **7**  
- Unmapped: **0** ✓

---
*Requirements defined: 2026-04-20*  
*Last updated: 2026-04-20 after `/gsd-new-milestone` (v1.9)*
