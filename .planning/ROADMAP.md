# Roadmap: Scrypath

## Milestones

- ✅ **v1.28 Realistic Demo App & Admin UI Proof** — Phases 102-105 (shipped 2026-05-31) — see `milestones/v1.28-ROADMAP.md`
- ✅ **v1.29 Contract Repair and Proof Hardening** — Phases 106-108 (shipped 2026-05-31) — see `milestones/v1.29-ROADMAP.md`
- ✅ **v1.30 Release Trust and Evidence Maintenance** — Phases 109-112 (shipped 2026-06-01) — see `milestones/v1.30-ROADMAP.md`
- ✅ **v1.31 Adoption Evidence Demo Hardening** — Phases 113-115 (UAT passed 2026-06-01)
- ✅ **v1.32 Admin UI/UX Design System Cleanup** — Phases 116-118 (shipped 2026-06-01) — see `milestones/v1.32-ROADMAP.md`
- ✅ **v1.33 Admin UI Insane Polish** — Phases 119-127 (shipped 2026-06-03) — see `milestones/v1.33-ROADMAP.md`
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128-136 (shipped 2026-06-29; archived 2026-07-11) — see `milestones/v1.34-ROADMAP.md`
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137-143 (shipped directly 2026-06-24; archived 2026-07-11) — see `milestones/v1.35-ROADMAP.md`
- ✅ **v1.36 Dependency Security Remediation** — Phases 144-147 (shipped 2026-08-25) — see `milestones/v1.36-ROADMAP.md`
- ✅ **v1.37 Code Quality Ratchet** — Phases 148-159 (shipped 2026-08-26) — see `milestones/v1.37-ROADMAP.md`
- 🚧 **v1.38 Packaged Adopter Proof** — Phases 160-161 (planning)

## Current Posture

Active milestone: **v1.38 Packaged Adopter Proof**. It closes the package-artifact-to-live-Phoenix-example proof gap using the existing `examples/phoenix_meilisearch` application. The public runtime surface, example's normal path-dependency workflow, and lean required CI gates remain bounded as approved.

Historical phase details and evidence live under `milestones/`.

## Phases

- [ ] **Phase 160: Package-Backed Phoenix Proof** - Exercise the existing Phoenix adopter example's inline, Oban, and related-data integration scenarios against the built package artifact with deterministic setup and cleanup.
- [ ] **Phase 161: Release and Tidy Closeout** - Align adopter-facing proof truth and machine-checked contracts, verify release evidence, and clean milestone-owned resources while preserving pre-existing changes.

## Phase Details

### 🚧 v1.38 Packaged Adopter Proof (In Progress)

**Milestone Goal:** Prove that the built Scrypath package artifact supports the existing Phoenix/Ecto adopter example against real Postgres and Meilisearch services, then close with verified release evidence or an explicit release-ready disposition and tidy milestone-owned work.

#### Phase 160: Package-Backed Phoenix Proof
**Goal**: Maintainers can verify that the package artifact produced from the current checkout supports the existing Phoenix adopter example against real Postgres and Meilisearch services.
**Depends on**: Phase 159
**Requirements**: PKG-01, PKG-02, PKG-03, PROOF-01
**Success Criteria** (what must be TRUE):
  1. The package verification path builds and unpacks the artifact, and a clean consumer schema compiles against it without a repository path dependency.
  2. A deterministic maintainer command runs the existing Phoenix example's inline, Oban, and related-data integration scenarios against that artifact and reports their results.
  3. The normal Phoenix example path-dependency workflow still works, and the package-backed proof reuses the existing service prerequisites and advisory Phoenix service lane without adding or promoting a required gate.
  4. Success and injected setup, service, compile, or test failures report the failing stage and clean task-owned temporary files by default; an automated contract check catches drift among the command, CI wiring, and proof documentation.
**Plans**: 2 plans

Plans:
- [ ] 160-01-PLAN.md — Add the package-backed Phoenix proof command and cleanup contracts
- [ ] 160-02-PLAN.md — Wire advisory CI order and guard maintainer documentation

#### Phase 161: Release and Tidy Closeout
**Goal**: Adopters and maintainers can understand the package-backed proof's scope, and the milestone closes with verified release evidence or an explicit release-ready disposition and tidy repository state.
**Depends on**: Phase 160
**Requirements**: DOC-01, HYGIENE-01, REL-01, CLOSE-01
**Success Criteria** (what must be TRUE):
  1. Adopter and maintainer documentation states the exercised inline, Oban, and related-data flows, the command and real-service prerequisites, and the limits of synthetic proof; automated documentation/contract checks detect drift from executable behavior.
  2. Final review and machine checks find affected canonical documentation and example guidance consistent with the command, no stale v1.38 planning claims, and no task-owned temporary scaffolding or generated debris.
  3. Closeout records reviewed and triaged milestone PRs, green required checks on the exact final commit, and green `main` after merge; the documented Release Please/Hex/HexDocs post-publish checks confirm the package, changelog, docs, tag, and source agree. If external credentials, permissions, or services block publication, the result is explicitly `release-ready` with the blocker and exact resume action, never reported as shipped.
  4. Milestone-owned branches, worktrees, services, generated artifacts, and working-tree changes are cleaned up; the closeout record confirms unrelated or pre-existing changes were preserved and reports any external cleanup limitation.
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 160. Package-Backed Phoenix Proof | v1.38 | 0/TBD | Not started | - |
| 161. Release and Tidy Closeout | v1.38 | 0/TBD | Not started | - |
