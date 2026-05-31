# Requirements: Scrypath v1.30 Release Trust and Evidence Maintenance

**Defined:** 2026-05-31
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.30 Requirements

### Release Truth

- [x] **REL-01**: Maintainer can confirm Release Please, `mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`, tags, and publish workflows agree on the canonical release path.
- [x] **REL-02**: Maintainer can verify the Hex package contains only the intended root library artifact and excludes `scrypath_ops/`, examples, website build output, planning files, `node_modules`, and Playwright artifacts.
- [x] **REL-03**: Maintainer can verify the publish path mechanically proves `mix verify.phase11`, dry-run publish, Hex visibility, HexDocs reachability, clean-consumer compile, and release parity.

### Support Intake

- [ ] **SUP-01**: Adopter-facing docs route support/readiness truth to `guides/support-and-compatibility.md` instead of duplicating compatibility matrices.
- [ ] **SUP-02**: Maintainer can classify outside-adopter reports as Class A-D and route each finding to bugfix, docs gap, app-side error, environment failure, or needs-info.

### Proof Stability

- [ ] **STAB-01**: Maintainer can make an evidence-based `phase105-e2e` advisory/required decision using recent outcomes, flake/runtime signal, artifact usefulness, and owner-response expectations.
- [ ] **STAB-02**: Routine required gates remain lean unless evidence justifies promoting a heavier live/browser check.

### Public Truth

- [ ] **WEB-01**: Public website and docs consistently present Scrypath as the Ecto-native search indexing library without implying hosted search, AI, magic callbacks, or public multi-backend v1 support.
- [ ] **WEB-02**: Public website remains a route map into README, guides, examples, Hex, and GitHub rather than a second docs site.
- [ ] **SCOPE-01**: Feature-lane reopen policy remains explicit and evidence-gated.

## Future Requirements

Deferred unless backed by concrete production bugs, reviewed outside-adopter evidence, or an explicit strategic product decision.

### Feature Wedges

- **AUTO-01**: User can use first-class autocomplete or suggestion flows through Scrypath.
- **OPSUI-01**: Operator can use productized saved-query/team-playbook workflows beyond the current bounded operator UI.
- **BACKEND-01**: User can rely on public multi-backend support beyond the Meilisearch-first v1 contract.

### Proof Expansion

- **E2E-REQ-01**: Maintainer can treat `phase105-e2e` as a required merge gate after sustained low-flake, bounded-runtime evidence.
- **OPSUI-E2E-01**: Maintainer can run real-backend OPSUI browser proof when a failure mode proves stub and LiveView tests are insufficient.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New runtime APIs or schema-generated search verbs | v1.30 is maintenance/evidence work, not a product-surface expansion. |
| Autocomplete, suggestions, vector, hybrid, analytics, or personalization | Existing scope guard requires outside-adopter evidence or a deliberate strategic reopen. |
| Public multi-backend abstraction | v1 remains Meilisearch-first with an internal adapter seam. |
| Promoting `phase105-e2e` to required by default | Promotion requires stability and owner-response evidence, not milestone ambition. |
| Turning `website/` into a HexDocs replacement | The website is a front door and route map, not a second docs system. |
| Heavy process or evidence bureaucracy | Support intake should reduce back-and-forth, not discourage reports. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 109 | Complete |
| REL-02 | Phase 109 | Complete |
| REL-03 | Phase 109 | Complete |
| SUP-01 | Phase 110 | Pending |
| SUP-02 | Phase 110 | Pending |
| STAB-01 | Phase 111 | Pending |
| STAB-02 | Phase 111 | Pending |
| WEB-01 | Phase 112 | Pending |
| WEB-02 | Phase 112 | Pending |
| SCOPE-01 | Phase 112 | Pending |

**Coverage:**
- v1.30 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-05-31*
*Last updated: 2026-05-31 after v1.30 milestone initialization*
