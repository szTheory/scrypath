# Requirements: Scrypath v1.27 — Adopter Contract Hardening

**Defined:** 2026-05-27
**Core Value:** Keep Scrypath trustworthy by making install, support, and proof semantics coherent across adopter-facing surfaces, then lock that truth with drift gates.

## v1.27 Requirements

### Contract Truth

- [x] **TRUTH-01**: A new adopter sees one consistent install/version contract across `README.md`, support guide, contributor guide, and adopter-intake surfaces. *(Reopened by v1.27 audit; reassigned to Phase 100)*
- [x] **TRUTH-02**: All primary surfaces clearly distinguish release-backed guidance from unreleased `main` branch behavior. *(Reopened by v1.27 audit; reassigned to Phase 100)*
- [ ] **TRUTH-03**: Support-lifecycle wording and compatibility boundaries are discoverable in one canonical support surface and referenced consistently from other entry points. *(Reopened by v1.27 audit; reassigned to Phase 101)*

### Proof Boundary and Flow Clarity

- [x] **PROOF-01**: A maintainer can identify the canonical proof command (`mix verify.adopter`) in one hop from README and CONTRIBUTING surfaces.
- [x] **PROOF-02**: Fast proof and live proof paths are explicitly separated, including live prerequisites and failure expectations.
- [x] **PROOF-03**: Example-app proof instructions remain aligned with the canonical proof boundary and do not contradict root-level guidance.

### Support and Intake Contract

- [x] **SUP-01**: Outside-adopter intake documentation defines required evidence fields and flow classification in actionable terms.
- [x] **SUP-02**: Support-escalation routing is explicit so maintainers can classify contract drift vs runtime bug vs environment issue.

### Drift Protection and Verification

- [ ] **TEST-01**: Docs-contract tests lock canonical install/support/proof anchors across all high-risk surfaces listed in the v1.27 contract-surface map. *(Reopened by v1.27 audit; reassigned to Phase 101)*
- [x] **TEST-02**: Verification coverage asserts proof-boundary consistency between root docs and example-app docs.
- [x] **TEST-03**: Verification coverage asserts CI/verify alias references stay aligned with documented required checks.
- [x] **GATE-01**: Milestone-specific verify gate aliases for phases 97-99 are defined and documented as the trust-hardening verification spine.
- [x] **GATE-02**: Required PR CI checks for this milestone are explicitly documented and map to the milestone gate strategy.

### Scope Discipline

- [x] **SCOPE-01**: Milestone docs explicitly state and enforce no runtime feature expansion (no autocomplete/suggestions, vector/hybrid, backend broadening, or new public runtime APIs). *(Completed in Phase 97)*

## Future Requirements (deferred)

### Feature-depth follow-ons

- **FUT-01**: Any post-v1.27 runtime feature wedge must be evidence-gated by reviewed outside-adopter signal or concrete production bug.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Autocomplete/suggestions runtime work | v1.27 is trust-surface hardening only; no new search breadth. |
| New public runtime APIs or backend abstractions | Milestone is contract coherence, not runtime expansion. |
| `scrypath_ops` feature expansion | Out of scope unless required to maintain adopter contract truth. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TRUTH-01 | Phase 100 | Complete |
| TRUTH-02 | Phase 100 | Complete |
| TRUTH-03 | Phase 101 | Pending |
| PROOF-01 | Phase 98 | Complete |
| PROOF-02 | Phase 98 | Complete |
| PROOF-03 | Phase 98 | Complete |
| SUP-01 | Phase 98 | Complete |
| SUP-02 | Phase 98 | Complete |
| TEST-01 | Phase 101 | Pending |
| TEST-02 | Phase 99 | Complete |
| TEST-03 | Phase 99 | Complete |
| GATE-01 | Phase 99 | Complete |
| GATE-02 | Phase 99 | Complete |
| SCOPE-01 | Phase 97 | Complete |
| FUT-01 | Post-v1.27 | Deferred |

**Coverage:**

- v1.27 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0
- Complete: 10
- Pending: 4

---
*Requirements defined: 2026-05-27 after v1.27 scope approval*
