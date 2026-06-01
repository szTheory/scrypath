# Roadmap: Scrypath

## Milestones

- ✅ **v1.28 Realistic Demo App & Admin UI Proof** — Phases 102-105 (shipped 2026-05-31) — see `milestones/v1.28-ROADMAP.md`
- ✅ **v1.29 Contract Repair and Proof Hardening** — Phases 106-108 (shipped 2026-05-31) — see `milestones/v1.29-ROADMAP.md`
- ✅ **v1.30 Release Trust and Evidence Maintenance** — Phases 109-112 (shipped 2026-06-01) — see `milestones/v1.30-ROADMAP.md`
- ✅ **v1.31 Adoption Evidence Demo Hardening** — Phases 113-115 (UAT passed 2026-06-01)
- ◆ **v1.32 Admin UI/UX Design System Cleanup** — Phases 116-118 (active)

## Phases

### Phase 116: OPSUI Asset Contract and Design Tokens

**Goal:** Make mounted `/admin/search/*` styling explicit and replace Phoenix-default visual residue with Scrypath operator tokens.

**Requirements:** ASSET-01, TOKEN-01, BRAND-01

**Status:** Active

### Phase 117: Shared Ops Component System

**Goal:** Move repeated admin UI primitives into project-owned components so screen polish is consistent and testable.

**Requirements:** COMP-01, A11Y-01

**Status:** Pending

### Phase 118: Admin Screen UX Cleanup

**Goal:** Apply the quiet ops console system across posture, failed sync, sync/drift, search/federation, and playbooks.

**Requirements:** SCREEN-01, SCREEN-02, VERIFY-01

**Status:** Pending

## Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.28 Realistic Demo App & Admin UI Proof | 102-105 | 15/15 | Complete | 2026-05-31 |
| v1.29 Contract Repair and Proof Hardening | 106-108 | 3/3 | Complete | 2026-05-31 |
| v1.30 Release Trust and Evidence Maintenance | 109-112 | 11/11 | Complete | 2026-06-01 |
| v1.31 Adoption Evidence Demo Hardening | 113-115 | 3/3 phases complete | UAT passed | 2026-06-01 |
| v1.32 Admin UI/UX Design System Cleanup | 116-118 | implementation pass complete, DB-backed verification pending | Active | — |

## Requirement Coverage

| Requirement | Phase | Status |
|-------------|-------|--------|
| ASSET-01 | Phase 116 | Implemented; DB-backed test rerun pending |
| TOKEN-01 | Phase 116 | Implemented; scan/compile passed |
| BRAND-01 | Phase 116 | Implemented; scan/compile passed |
| COMP-01 | Phase 117 | Implemented; DB-backed test rerun pending |
| A11Y-01 | Phase 117 | Implemented; DB-backed test rerun pending |
| SCREEN-01 | Phase 118 | Implemented; DB-backed test rerun pending |
| SCREEN-02 | Phase 118 | Implemented; DB-backed test rerun pending |
| VERIFY-01 | Phase 118 | In progress; compile passed, focused tests blocked by local Postgres saturation |

**Coverage:** 8/8 requirements mapped.

## Historical Contract Anchors

- [PHASE97-SCOPE-GUARD] Phase 97/98/99 reject runtime breadth expansion unless reopen policy conditions are met. See `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`.
- [POST-V1.29-DONE-POSTURE] Scrypath is effectively complete for its stated v1 mission; default to release, maintenance, support truth, proof stability, outside-adopter evidence, or silence. See `.planning/threads/scrypath-post-v1.29-done-posture-2026-05-31.md`.

## Next

Clear local Postgres connection pressure, rerun focused ScrypathOps and mounted e-commerce tests, then close or polish based on findings.
