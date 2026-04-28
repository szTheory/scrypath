# Requirements: Scrypath

**Defined:** 2026-04-28
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.19 Requirements

### Production readiness contract

- [x] **PRDY-01**: Maintainers can point adopters to one canonical production-readiness document that states what Scrypath v1 actively proves today, which runtime/backend/example assumptions that proof depends on, and which operational responsibilities remain on the host application.
- [x] **PRDY-02**: Maintainers can run one root-level production proof command family that makes the fast-vs-live distinction explicit and proves the defended support story without hunting across unrelated `mix verify.*` tasks.

### Example and integration proof

- [x] **PRDY-03**: The canonical Phoenix + Meilisearch adoption proof covers at least one production-shaped path beyond first-hour setup, including bootstrap or backfill expectations, a real sync flow, and operator-facing recovery or verification guidance.
- [x] **PRDY-04**: The optional Sigra-flavored OPSUI proof is folded into the same readiness story with explicit boundaries about when teams need it, what it proves, and what it does not widen in `scrypath` core.
- [x] **PRDY-05**: README, CONTRIBUTING, support docs, operations guides, and example READMEs all point to the same canonical readiness and proof sources, with bounded contract coverage that fails on drift.

### Adopter evidence and hardening

- [x] **PRDY-06**: The repo ships a bounded adopter-feedback intake path that asks for runtime versions, sync mode, proof command used, observed failure, and supporting artifacts so real integration reports are actionable instead of anecdotal.
- [x] **PRDY-07**: The milestone closes only evidence-backed production-adoption papercuts discovered through the proof runs or feedback intake, and every fix lands with a regression test, contract test, or example assertion.
- [x] **PRDY-08**: Milestone-close artifacts end with a clear readiness checkpoint on whether Scrypath should seek broader outside production adoption before opening another feature or integration-expansion milestone.

## v2 Requirements

### Broader expansion

- **EXP-01**: Public multi-backend support beyond the current Meilisearch-first contract.
- **EXP-02**: New search capabilities such as vectors, hybrid retrieval, or personalization.
- **EXP-03**: Deeper OPSUI workflows or dashboard breadth that are not directly required by production adoption proof.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New search feature breadth in v1.19 | The current leverage is proving and hardening the shipped product, not widening the API surface again. |
| Core auth or org-scoping changes in `scrypath` | Optional integrations may be documented and proven, but the core library remains auth-agnostic until evidence demands otherwise. |
| Maintainer-only planning-tooling fixes as the milestone headline | Useful when blocking, but they do not materially improve adopter production readiness on their own. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PRDY-01 | Phase 74 | Complete |
| PRDY-02 | Phase 74 | Complete |
| PRDY-03 | Phase 75 | Complete |
| PRDY-04 | Phase 75 | Complete |
| PRDY-05 | Phase 74 | Complete |
| PRDY-06 | Phase 75 | Complete |
| PRDY-07 | Phase 76 | Complete |
| PRDY-08 | Phase 76 | Complete |

**Coverage:**
- v1.19 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-28*
*Last updated: 2026-04-28 after closing v1.19 Production adoption proof and hardening as a readiness checkpoint*
