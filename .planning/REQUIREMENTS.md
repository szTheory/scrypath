# Requirements: Scrypath — Milestone v1.14

**Defined:** 2026-04-21  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Milestone:** v1.14 — *Library QoL and operator playbooks* (**Tier B1** + **Tier B2** / **OPSUI-FUT-01**)

## v1.14 Requirements

### Evidence triage and scope discipline (B1 gate)

- [ ] **EVID-01**: Maintainer publishes a **frozen evidence list** for **B1** (issue URLs, quoted support text, or dated dogfood notes) in-repo before **LIB-*** work merges; items not on the list are out of scope for v1.14 core changes.  
  **Evidence:** `.planning/research/SUMMARY.md` (“B1 delivery confidence depends on locking an evidence list”); `.planning/milestone-candidates.md` **B1** (“only when tied to **concrete** adopter or maintainer pain”).

### Library and docs — evidence-led QoL (B1)

- [ ] **LIB-01**: For **at least one** high-friction path already called out for adopters, improve **actionable** `{:error, _}` or exception message text (and, if needed, **one** adjacent doc link) so the failure names the problem and the **next doc** is obvious.  
  **Evidence:** v1.12 milestone shipped **ONBD-04..06** pattern (`milestones/v1.12-REQUIREMENTS.md`); `guides/common-mistakes.md` exists as the pitfalls surface.

- [ ] **LIB-02**: For **at least one** library or verify path discovered during v1.14 dogfood, reduce confusion **without** new public macros — prefer clearer typespecs, `@doc`, or a **small** pure helper — and record the before/after confusion in the evidence list (**EVID-01**).  
  **Evidence:** `.planning/milestone-candidates.md` **B1**; `.planning/research/PITFALLS.md` (speculative API churn pitfall).

- [ ] **LIB-03**: Extend **doc-contract** or contributor-verify anchors so new v1.14 surfaces (playbook paths, warnings, or env flags) cannot silently drift from **README** / **CONTRIBUTING** / **`mix verify.opsui`** expectations.  
  **Evidence:** v1.12 **VRFY-03..04** and `docs_contract_test` pattern (`milestones/v1.12-REQUIREMENTS.md`).

### Operator playbooks — OPSUI-FUT-01 shaped (B2)

- [ ] **OPS-PB-01**: Define a **versioned** playbook payload (`playbook_format` / schema **v1**) that can represent **both** single-index and **`search_many/2`**-shaped runs using only options **`Scrypath`** already accepts (including federation-relevant fields where applicable), with explicit size caps consistent with **`ScrypathOps.SearchPlayground`**.  
  **Evidence:** `.planning/milestones/v1.10-REQUIREMENTS.md` **OPSUI-FUT-01**; `scrypath_ops/lib/scrypath_ops/search_playground.ex` ceilings.

- [ ] **OPS-PB-02**: Operators can **save**, **list**, **load**, and **run** a playbook from **`scrypath_ops`** search UI (or a dedicated LiveView under **`/ops`**), with the same **bounded** behaviour and warnings as the existing playground (**non-production** posture preserved).  
  **Evidence:** **OPSUI-04** / **OPSUI-05** shipped semantics (`milestones/v1.10-REQUIREMENTS.md`).

- [ ] **OPS-PB-03**: Ship **one** persistence story chosen during planning — **either** portable **export/import** of playbooks **or** durable storage inside **`scrypath_ops`** (e.g. Ecto + Postgres) — with limitations documented (single-user vs team-shared).  
  **Evidence:** `.planning/research/ARCHITECTURE.md` persistence fork; **OPSUI-FUT-01** “shared across team members” vs MVP tradeoff in **SUMMARY.md**.

- [ ] **OPS-PB-04**: Navigation and **JTBD** docs stay aligned: update **`scrypath_ops/docs/operator-ia.md`** (and router, if needed) so **`mix scrypath_ops.check_nav_contract`** and any **`operator_ia_contract_test`** expectations remain green.  
  **Evidence:** v1.11 **OPSUX-01** (`milestones/v1.11-REQUIREMENTS.md`).

- [ ] **OPS-PB-05**: Automated tests cover playbook **save/load/run** on the **stub adapter** path (no live Meilisearch required in default CI), and **`mix verify.opsui`** remains the documented contributor entry.  
  **Evidence:** **OPSUI-10**; `scrypath_ops/test/support/search_playground_stub_adapter.ex`.

### Milestone close

- [ ] **SHIP-01**: **`.planning/MILESTONES.md`**, **`.planning/PROJECT.md`** *Current State*, and **`.planning/ROADMAP.md`** milestone list agree on **v1.14** outcomes and Hex line (`scrypath` version) where applicable; requirements traceability shows **Complete** for shipped rows.  
  **Evidence:** v1.13 close pattern (`milestones/v1.13-REQUIREMENTS.md`, **RETROSPECTIVE**).

## v2+ Requirements (not in v1.14)

### Operator UI depth (deferred)

- **OPSUI-FUT-02**: Deep Meilisearch cluster observability (vendor-dashboard parity) — remains deferred per **v1.10** archive.

### Heavy CI / E2E (Tier C)

- Playwright-on-all-flows, Meilisearch-in-OPSUI CI, exhaustive visual regression — deferred per **`.planning/milestone-candidates.md`** **Tier C** until a proven failure mode.

## Out of Scope

| Item | Reason |
|------|--------|
| **OPSUI-FUT-02** | Explicitly excluded from v1.14; not required for playbook value. |
| **Tier C** CI expansion | Cost without proven gap; keep verify spine honest first. |
| **New recovery verbs** triggered from OPSUI | Same boundary as **v1.10** Out of Scope — Mix/docs own mutations. |
| **Public multi-backend** or vector/hybrid relevance | Still **`.planning/PROJECT.md` *Out of Scope*** until adoption forces the contract. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| EVID-01 | Phase 57 | Pending |
| LIB-01 | Phase 58 | Pending |
| LIB-02 | Phase 58 | Pending |
| LIB-03 | Phase 58 | Pending |
| OPS-PB-01 | Phase 59 | Pending |
| OPS-PB-02 | Phase 60 | Pending |
| OPS-PB-03 | Phase 59 | Pending |
| OPS-PB-04 | Phase 60 | Pending |
| OPS-PB-05 | Phase 61 | Pending |
| SHIP-01 | Phase 61 | Pending |

**Coverage:**

- v1.14 requirements: **10** total  
- Mapped to phases: **10**  
- Unmapped: **0** ✓  

---
*Requirements defined: 2026-04-21*  
*Last updated: 2026-04-21 after research + roadmap seed*
