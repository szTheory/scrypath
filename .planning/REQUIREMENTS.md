# Requirements: Scrypath — Milestone v1.11

**Defined:** 2026-04-21  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.11 Requirements (Operator shell polish and JTBD verification)

Polish the optional **`scrypath_ops`** shell so it is an excellent day-to-day operator tool: hierarchy, scanability, theming, Phoenix conventions, and provable alignment with **`scrypath_ops/docs/operator-ia.md`**.

### Information architecture and JTBD

- [ ] **OPSUX-01**: **`operator-ia.md`** (personas, JTBD 1–7, nav table) matches **`router.ex`**, primary chrome labels, and route set under **`/ops`** — with a **maintainer-facing guard** (for example **`operator_ia_contract_test`** or equivalent) updated whenever nav or doc table changes.
- [ ] **OPSUX-02**: **On-call happy path** is obvious on first open: posture / health surfaces **healthy / degraded / broken** (or equivalent) with **explicit next checks** (doc links, Mix pointers, or in-UI “what to run next”) consistent with **`operator-ia.md`** job 1, without inventing new recovery semantics.

### Visual hierarchy and scanability

- [ ] **OPSUX-03**: **`/ops/posture`**, **`/ops/failed-sync`**, **`/ops/sync-drift`**, and **`/ops/search`** use **consistent page structure** (title, primary panel, secondary detail) so operators can **scan** lists, rollups, and warnings in **light and dark** themes.

### Theming and Phoenix ergonomics

- [ ] **OPSUX-04**: **System, light, and dark** theme choices work end-to-end (including first paint / persistence), respect **operating-system preference** when set to system, and remain **readable** (contrast, borders, focus rings) on all **`/ops`** screens.
- [ ] **OPSUX-05**: UI patterns follow **conventional Phoenix LiveView** expectations (layouts, flash, links, components) per **OPSUI-07** spirit — fix **inconsistencies** found during audit (for example stray default shell chrome, duplicate titles, unclear errors).

### Accessibility and verification

- [ ] **OPSUX-06**: **Basic accessibility**: logical **heading** order, **`main`** / landmark usage where appropriate, and **labels** for interactive controls on operator-critical paths (triage tables, playground controls, federation inspector toggles as applicable).
- [ ] **OPSUX-07**: **CI regression** coverage is extended for any new IA or nav contracts (and critical LiveView paths), so **OPSUI-10** discipline continues after polish — no decrease in operator wiring guarantees.

## Future requirements (deferred)

### Operator UI depth (unchanged from v1.10 archive)

- **OPSUI-FUT-01**: Editable saved queries / playbooks shared across team members.
- **OPSUI-FUT-02**: Deep Meilisearch cluster observability (vendor-dashboard parity).

## Out of scope

| Item | Reason |
|------|--------|
| New **write-side** recovery verbs or actions not backed by existing **`Scrypath`** / Mix contracts | Same boundary as **v1.10** — UI stays honest to library API. |
| **Full** E2E browser matrix, visual-diff **default** CI, or **Meilisearch inside `scrypath_ops` CI** | Explicitly deferred in **phase 47** context unless this milestone’s verification phase proves insufficient. |
| **OPSUI-FUT-*** product features | Remain deferred unless explicitly promoted from **Future requirements**. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| OPSUX-01 | Phase 48 | Pending |
| OPSUX-02 | Phase 48 | Pending |
| OPSUX-03 | Phase 49 | Pending |
| OPSUX-04 | Phase 49 | Pending |
| OPSUX-05 | Phase 49 | Pending |
| OPSUX-06 | Phase 50 | Pending |
| OPSUX-07 | Phase 50 | Pending |

**Coverage:** v1.11 requirements: **7** total · Mapped: **7** · Unmapped: **0** ✓

---
*Requirements defined: 2026-04-21 after `/gsd-new-milestone` v1.11*
