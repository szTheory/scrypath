# Requirements: Scrypath

**Defined:** 2026-05-24  
**Milestone:** v1.23 — *Outside-Adopter Evidence And Support-Truth Reconciliation*  
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.23 Requirements

### Support truth and proof surfaces

- [x] **TRUTH-01**: Maintainers can point adopters to one current canonical readiness/support surface whose files exist in the checkout and whose claims match the current public tree.
- [x] **TRUTH-02**: `mix verify.adopter` fast/live proof paths target existing files and current proof surfaces; stale references to missing test files or removed guides do not remain in maintainer workflow surfaces.
- [x] **TRUTH-03**: Planning truth explicitly distinguishes defended in-repo proof from reviewed outside-adopter evidence, and current planning/docs no longer rely on the missing `Scrypath.SearchModule` or `guides/support-and-compatibility.md` surfaces as settled shipped fact.

### Outside-adopter evidence

- [x] **ADOPT-01**: The repo ships one current outside-adopter intake and evidence-review path that tells adopters which proof command, runtime versions, sync mode, example path, and artifacts to supply.
- [x] **ADOPT-02**: Maintainers review at least two real outside-adopter attempts against current checkout truth and classify each issue as docs/onboarding gap, support-truth drift, product gap, or env/setup papercut.
- [x] **ADOPT-03**: The Phoenix + Meilisearch proof story stays defended and current, including explicit repo-clone boundaries, example assumptions, and current support scope for the core library path.

### Evidence-backed closure

- [ ] **FIX-01**: The milestone closes only evidence-backed docs/support/proof papercuts discovered through **ADOPT-02**, and each accepted fix lands with a bounded regression guard.
- [ ] **FIX-02**: Milestone-close artifacts end with one explicit next-pull verdict: stop soon, open related-data propagation, or open tenant-safe access.

## Future requirements carried forward

- [ ] **DATA-01**: Explicit related-data propagation and dependency semantics remain the first core product wedge if outside-adopter evidence shows real correctness pressure.
- [ ] **AUTH-01**: Tenant-safe search access remains the next major SaaS credibility wedge after related-data pressure is understood.
- [ ] **FACET-UX-01**: High-cardinality facet-value search remains a narrower catalog-depth follow-on, not the default next pull.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New general ergonomics breadth in the core runtime | The repo is already near diminishing returns on internal breadth without outside-adopter evidence. |
| Public multi-backend expansion | Still outside the defended v1 scope and not justified by current adopter evidence. |
| Deep OPSUI productization | Useful only if current operator proof misses real failures; not the highest-leverage adopter wedge. |
| Autocomplete, suggestions, or delight-first search UX | Visible, but still below correctness, support truth, and SaaS boundary work. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TRUTH-01 | Phase 86 | Complete |
| TRUTH-02 | Phase 86 | Complete |
| TRUTH-03 | Phase 86 | Complete |
| ADOPT-01 | Phase 87 | Complete |
| ADOPT-02 | Phase 87 | Complete |
| ADOPT-03 | Phase 87 | Complete |
| FIX-01 | Phase 88 | Pending |
| FIX-02 | Phase 88 | Pending |

**Coverage:**
- v1.23 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0

---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 after repo-grounded done-ness assessment and milestone open*
