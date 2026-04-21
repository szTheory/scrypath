# Requirements: Scrypath — Milestone v1.10 (OPSUI)

**Defined:** 2026-04-20  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.10 Requirements (Operator admin UI)

### Packaging & boundaries

- [x] **OPSUI-09**: Operator UI is delivered **outside** the core **`scrypath`** Hex package (dedicated Phoenix application under the repo or a sibling package) with **clone-and-run** (or path-dep) instructions for maintainers and early adopters.

### Personas, jobs-to-be-done, and UX quality

- [x] **OPSUI-06**: Primary **operator personas** and their **jobs-to-be-done** are documented in-repo, and the **primary navigation order** reflects those priorities (highest-frequency triage paths first).
- [x] **OPSUI-07**: The UI follows **conventional Phoenix LiveView** patterns (routing, layouts, flash/errors, components) so an experienced Phoenix developer finds structure and naming **unsurprising** (principle of least surprise).
- [x] **OPSUI-08**: The **security model** for OPSUI is explicit and documented (for example: development-only default, required authentication plug contract for non-dev, or separate deploy posture)—operators must not discover auth by accident.

### Operator visibility surfaces

- [x] **OPSUI-01**: An operator can open a **dashboard landing** that summarizes **per-schema (or per-index) posture** for sync and search health using **`Scrypath.*`** visibility APIs (read-mostly; no new recovery semantics).
- [x] **OPSUI-02**: An operator can **triage failed sync work** with lists and rollups that match **`Scrypath.failed_sync_work/2`** semantics (including **`reason_class`** and related metadata the library already exposes).
- [x] **OPSUI-03**: An operator can inspect **sync status** and **read-only reconcile/drift context** where the library already exposes it (for example drift attachments or contract drift tooling), with clear linkage to operator docs and Mix tasks for actions.

### Search and federation honesty

- [x] **OPSUI-04**: An operator can run **bounded exploratory search** from the UI (single-index and, where configured, multi-index) with warnings appropriate to **non-production** or **privileged** use—no unbounded production query logging by default.
- [x] **OPSUI-05**: An operator can inspect **`search_many/2` / federation-shaped** results with **explicit** representation of **merge order**, **federation weights**, **partial failures**, and **`:all` expansion** behavior consistent with shipped library semantics and guides.

### Verification

- [ ] **OPSUI-10**: A **maintainer-facing automated check** (for example Phoenix **`LiveViewTest`** or fast integration smoke) covers critical OPSUI wiring so regressions fail in CI for the chosen packaging path.

## v2+ Requirements (deferred)

### Operator UI depth

- **OPSUI-FUT-01**: Editable saved queries / playbooks shared across team members.
- **OPSUI-FUT-02**: Deep Meilisearch cluster observability (vendor-dashboard parity) — intentionally out of scope for v1.10.

## Out of Scope

| Item | Reason |
|------|--------|
| Shipping LiveView inside the core **`scrypath`** Hex artifact | Widens dependencies and consumer surprise; **OPSUI-09** keeps the boundary clean. |
| New write-side recovery verbs “because the UI needs a button” | Operational actions stay on documented **`Scrypath`** / Mix paths until explicitly designed as library API. |
| High-cardinality telemetry or per-query production logging in UI | Violates **`docs/search-backend-sre.md`** discipline and privacy expectations. |
| Vector / hybrid / personalization analytics | Same product boundary as core **Out of Scope** in **`.planning/PROJECT.md`**. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUDT-01 | Phase 32 (gap closure 33 follow-ups) | Complete — planning hygiene & doc-contract Nyquist invariants |
| OPSUI-09 | Phase 44 | Complete |
| OPSUI-06 | Phase 44 | Complete |
| OPSUI-07 | Phase 44 | Complete |
| OPSUI-08 | Phase 44 | Complete |
| OPSUI-01 | Phase 45 | Complete |
| OPSUI-02 | Phase 45 | Complete |
| OPSUI-03 | Phase 45 | Complete |
| OPSUI-04 | Phase 46 | Complete |
| OPSUI-05 | Phase 46 | Complete |
| OPSUI-10 | Phase 47 | Pending |

**Coverage:**

- v1.10 requirements: **10** total  
- Mapped to phases: **10**  
- Unmapped: **0** ✓  

---
*Requirements defined: 2026-04-20*  
*Last updated: 2026-04-20 after `/gsd-new-milestone` + roadmap*
