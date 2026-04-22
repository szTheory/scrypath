# Requirements: Scrypath — Milestone v1.15

**Defined:** 2026-04-22  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Milestone:** **v1.15** — *OPSUI second slice* (post-**OPS-PB-*** MVP, toward **OPSUI-FUT-01**)

## v1.15 Requirements

### Playground capture and playbook ergonomics

- [x] **OPS2-01**: An operator can **capture** the current **bounded Search playground** state (including **`search_many`**, federation-relevant options where already exposed in the UI, and the same ceilings/warnings as the playground) into a **`playbook_format: 1`** document and **preview → save** it into the configured playbook workspace **without** hand-writing JSON from scratch.  
  **Evidence:** **OPSUI-FUT-01** (`milestones/v1.10-REQUIREMENTS.md`); **OPS-PB-02** shipped “save/list/load/run” from hand-authored JSON (`milestones/v1.14-REQUIREMENTS.md`). **Shipped:** **`SearchLive`** capture + preview + save (**Phase 62**, 2026-04-22).

- [x] **OPS2-02**: Operators can **rename** and **duplicate** workspace playbooks with **safe basename rules** (collision handling, confirmation for destructive actions where already established in **PlaybookLive** patterns).  
  **Evidence:** **v1.14** file-catalog UX stops at import/delete; second slice needs operator-scale catalog hygiene. **Shipped:** **`Store`** rename/duplicate + **`PlaybookLive`** modals (**Phase 62**, 2026-04-22).

- [x] **OPS2-03**: Playbooks carry **operator-facing metadata** (at minimum **title** and **description**, optionally **tags**) stored **inside** the JSON payload or via a **documented `playbook_format` minor bump**—so listings are readable without opening raw JSON. **Backward compatibility** for existing workspace files must be explicit (defaults, migration note, or one-time “untitled” display).  
  **Evidence:** `.planning/research/FEATURES.md` (metadata table stakes). **Shipped:** **`V1`** optional metadata + catalog **Untitled playbook** default (**Phase 62**, 2026-04-22).

### Team-oriented persistence (bounded)

- [x] **OPS2-04**: Milestone delivers **one** explicit **team persistence** outcome, chosen without ambiguity: **(A)** strengthened **file + env + gitops** documentation and examples for shared workspace layouts, **or** **(B)** an **optional Ecto-backed** playbook catalog in **`scrypath_ops`** behind configuration, with limitations documented (single app DB, not multi-tenant SaaS). **No** silent mix of authoritative stores—precedence must be documented.  
  **Evidence:** **OPS-PB-03** chose file-only for **v1.14**; **OPSUI-FUT-01** “shared across team members” deferred past MVP (`milestones/v1.14-REQUIREMENTS.md` implementation note). **Shipped (A):** **`docs/team-playbook-persistence.md`**, schema persistence alignment, **`mix scrypath_ops.playbooks.validate`**, **`examples/playbooks/`** (**Phase 63**, 2026-04-22).

### Operator trust: IA, verification, security

- [x] **OPS2-05**: **`scrypath_ops/docs/operator-ia.md`**, router, and **`mix scrypath_ops.check_nav_contract`** / **`operator_ia_contract_test`** stay aligned for any **new routes or primary actions** introduced by this milestone.  
  **Evidence:** **OPS-PB-04** / **OPSUX-01** patterns. **Shipped:** saved-playbooks navigation + JTBD pointers to **`team-playbook-persistence.md`**; nav contract + **`operator_ia_contract_test`** green (**Phase 64**, 2026-04-22) — **`.planning/phases/64-ia-verification-and-milestone-bookkeeping/64-01-ia-nav-alignment-SUMMARY.md`**.

- [x] **OPS2-06**: **`mix verify.opsui`** (default contributor path) covers **new** LiveView or context paths using the **stub adapter** pattern—**no** mandatory live Meilisearch in default CI unless an existing gated job already covers the flow.  
  **Evidence:** **OPS-PB-05**, **VRFY-03..04**. **Shipped:** **`mix scrypath_ops.playbooks.validate`** documented in **CONTRIBUTING** / **`guides/operator-mix-tasks.md`** with **`docs_contract_test`** anchors; **`guides/meilisearch-operations.md`** restored; **`mix verify.opsui`** green (**Phase 64**, 2026-04-22) — **`64-02-verify-opsui-and-doc-contracts-SUMMARY.md`**.

- [x] **OPS2-07**: **Security posture** for shared playbooks: reaffirm **no secrets** in JSON (banned fields / scrub), document **auth implications** if a server catalog is introduced, and ensure destructive actions remain **explicitly confirmed** per **PlaybookLive** destructive-copy patterns.  
  **Evidence:** **`playbook-schema-v1.md`** security notes; `.planning/research/PITFALLS.md`. **Shipped:** threat-model subsection + **`V1`** / **`PlaybookLive`** tests (**Phase 63**, 2026-04-22).

### Milestone close

- [x] **OPS2-08**: **`.planning/MILESTONES.md`**, **`.planning/PROJECT.md`** *Current State*, and **`.planning/ROADMAP.md`** agree on **v1.15** outcomes and Hex line where applicable; **traceability** below shows **Complete** for shipped rows at milestone close.  
  **Evidence:** **SHIP-01** pattern (`milestones/v1.14-REQUIREMENTS.md`). **Shipped:** frozen **`milestones/v1.15-*`** trio + rolling docs (**Phase 64**, 2026-04-22) — **`64-03-milestone-v1-15-close-SUMMARY.md`**.

## v2+ Requirements (not in v1.15)

### Operator UI depth (still deferred)

- **OPSUI-FUT-02**: Deep Meilisearch cluster observability (vendor-dashboard parity) — remains deferred per **`milestones/v1.10-REQUIREMENTS.md`**.

### Heavy CI / E2E (Tier C)

- Playwright-on-all-flows, Meilisearch-in-OPSUI CI — deferred per **`.planning/milestone-candidates.md`** until a proven failure mode.

## Out of Scope

| Item | Reason |
|------|--------|
| **OPSUI-FUT-02** | Explicitly excluded headline work for **v1.15**. |
| **Real-time collaborative playbook editing** | Not required to satisfy **OPSUI-FUT-01** table stakes; explosion risk. |
| **New recovery / mutation verbs** from OPSUI | Same boundary as **v1.10** Out of Scope — Mix/docs own mutations. |
| **Public multi-backend** or vector/hybrid relevance | Still **`.planning/PROJECT.md` *Out of Scope*** until adoption forces the contract. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| OPS2-01 | Phase 62 | Complete |
| OPS2-02 | Phase 62 | Complete |
| OPS2-03 | Phase 62 | Complete |
| OPS2-04 | Phase 63 | Complete |
| OPS2-07 | Phase 63 | Complete |
| OPS2-05 | Phase 64 | Complete |
| OPS2-06 | Phase 64 | Complete |
| OPS2-08 | Phase 64 | Complete |
| AUDT-01 | Phase 32; gap closure 33 | Complete |

**Coverage:**

- v1.15 requirements: **8** total  
- Mapped to phases: **8**  
- Unmapped: **0** ✓

---
*Requirements defined: 2026-04-22*  
*Last updated: 2026-04-22 — **v1.15** closed in-repo; **OPS2-05**, **OPS2-06**, **OPS2-08** **Complete** after Phase **64**; frozen snapshot **`milestones/v1.15-REQUIREMENTS.md`***
