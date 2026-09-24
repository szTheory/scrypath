# Requirements: Scrypath — v1.38 Packaged Adopter Proof

**Defined:** 2026-09-23
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.38 Requirements

### Package Artifact

- [x] **PKG-01**: A maintainer can build the library package artifact from the current checkout and compile a clean consumer schema against that artifact, without a path dependency.
- [x] **PKG-02**: A maintainer can run the existing Phoenix adopter example’s selected real-service integration flows against the built package artifact, including its existing inline, Oban, and related-data scenarios, without changing the example’s normal path-dependency workflow.
- [x] **PKG-03**: The package-backed example proof uses isolated temporary files and reports setup, service, and test failures clearly; successful and failed runs clean up task-owned temporary resources by default.

### Verification and Documentation

- [x] **PROOF-01**: A documented, deterministic maintainer command exposes the package-backed Phoenix proof and uses the existing example and service prerequisites; the command, CI wiring, and documentation are guarded against drift by automated checks.
- [x] **DOC-01**: Adopter-facing and maintainer documentation accurately states what package-backed proof exercises, how to run it, its service prerequisites, and what synthetic evidence does and does not establish.
- [x] **HYGIENE-01**: Milestone changes remain idiomatic and self-documenting; affected canonical docs and examples match executable behavior, and final review finds no stale planning narration, temporary scaffolding, or task-owned generated debris.

### Release and Closeout

- [ ] **REL-01**: Before the milestone is reported shipped, milestone PRs are reviewed and triaged, required checks pass on the exact final commit, `main` is verified green after merge, and the documented Release Please/Hex/HexDocs path confirms the released package, changelog, docs, tag, and source agree through post-publish verification.
- [ ] **CLOSE-01**: Milestone-owned branches, worktrees, service stacks, generated artifacts, and working-tree changes are cleaned up; unrelated or pre-existing user changes are preserved and reported. If a release dependency blocks publication, all available checks finish and the milestone is reported as release-ready with the specific blocker and resume action, never as shipped.

## Future Requirements

None identified for this bounded milestone.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New adopter application or duplicate test harness | The existing Phoenix + Postgres + Meilisearch example is the smallest suitable proof surface. |
| Scrypath runtime API, dependency, or backend expansion | The evidence gap concerns package-to-example verification, not product capabilities. |
| Promotion of the full ecommerce/browser E2E lane or new required CI job | Existing lean required gates remain authoritative; reuse the current Phoenix example service lane unless planning evidence requires otherwise. |
| Public multi-backend support, autocomplete, vector/hybrid retrieval, or UI expansion | Existing product scope guards remain in force and this proof wedge does not justify reopening them. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PKG-01 | Phase 160 | Complete |
| PKG-02 | Phase 160 | Complete |
| PKG-03 | Phase 160 | Complete |
| PROOF-01 | Phase 160 | Complete |
| DOC-01 | Phase 161 | Complete |
| HYGIENE-01 | Phase 161 | Complete |
| REL-01 | Phase 161 | Pending |
| CLOSE-01 | Phase 161 | Pending |

**Coverage:**

- v1.38 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0 ✓

---
*Requirements defined: 2026-09-23*
*Last updated: 2026-09-23 after v1.38 scope approval*
