# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans — [archive](milestones/v1.0-ROADMAP.md)
- [x] `v1.1` shipped on 2026-04-16 — 3 phases, 9 plans — [archive](milestones/v1.1-ROADMAP.md)
- [x] `v1.2` shipped on 2026-04-17 — 7 phases, 13 plans — [archive](milestones/v1.2-ROADMAP.md)
- [x] `v1.3` shipped on 2026-04-17 — 6 phases (18–23), 18 plans — [archive](milestones/v1.3-ROADMAP.md)
- [x] `v1.4` shipped on 2026-04-17 — 3 phases (24–26), 8 plans — [archive](milestones/v1.4-ROADMAP.md)
- [x] `v1.5` shipped in-repo (2026-04-18) — 2 phases (27–28), 5 plans — [archive](milestones/v1.5-ROADMAP.md)
- [x] `v1.6` shipped in-repo (2026-04-19) — 7 phases (29–35), 7 plans — [archive](milestones/v1.6-ROADMAP.md)
- [x] `v1.7` shipped in-repo (2026-04-20) — 3 phases (36–38), 7 plans — [archive](milestones/v1.7-ROADMAP.md)
- [x] `v1.8` shipped in-repo (2026-04-20) — 3 phases (39–41), 6 plans — [archive](milestones/v1.8-ROADMAP.md)
- [x] `v1.9` shipped in-repo (2026-04-20) — 2 phases (42–43), 5 plans — [archive](milestones/v1.9-ROADMAP.md)
- [x] `v1.10` shipped in-repo (2026-04-21) — 4 phases (44–47), 14 plans — [archive](milestones/v1.10-ROADMAP.md)
- [x] `v1.11` shipped in-repo (2026-04-21) — 3 phases (48–50), 11 plans — [archive](milestones/v1.11-ROADMAP.md)
- [x] `v1.12` shipped in-repo (2026-04-22) — 3 phases (51–53), 9 plans — [archive](milestones/v1.12-ROADMAP.md)
- [x] `v1.13` shipped + archived in-repo (2026-04-22) — 3 phases (54–56), 5 plans — [archive](milestones/v1.13-ROADMAP.md)
- [x] `v1.14` shipped + archived in-repo (2026-04-22) — 5 phases (57–61), 10 plans — [archive](milestones/v1.14-ROADMAP.md)
- [x] `v1.15` shipped + archived in-repo (2026-04-22) — 3 phases (62–64), 8 plans — [archive](milestones/v1.15-ROADMAP.md)
- [x] `v1.16` shipped + archived in-repo (2026-04-22) — 3 phases (65–67), 6 plans — [archive](milestones/v1.16-ROADMAP.md)
- [x] `v1.17` shipped + archived in-repo (2026-04-23) — 3 phases (68–70), 6 plans — [archive](milestones/v1.17-ROADMAP.md)
- [x] `v1.18` shipped + archived in-repo (2026-04-26) — 3 phases (71–73), 10 plans — [archive](milestones/v1.18-ROADMAP.md)
- [x] `v1.19` shipped + archived in-repo (2026-04-28) — 3 phases (74–76), 8 plans — [archive](milestones/v1.19-ROADMAP.md)
- [x] `v1.20` shipped + archived in-repo (2026-05-08) — 3 phases (77–79), 8 plans — [archive](milestones/v1.20-ROADMAP.md)
- [x] `v1.21` shipped + archived in-repo (2026-05-23) — 3 phases (80–82), 8 plans — [archive](milestones/v1.21-ROADMAP.md)
- [x] `v1.22` shipped + archived in-repo (2026-05-24) — 3 phases (83–85), 12 plans — [archive](milestones/v1.22-ROADMAP.md)
- [x] `v1.23` shipped + archived in-repo (2026-05-24) — 3 phases (86–88), 8 plans — [archive](milestones/v1.23-ROADMAP.md)
- [ ] **`v1.24` OPEN** — *Related-Data and Dependency Propagation* — phases **89–91**, **7** requirements — [requirements](v1.24-REQUIREMENTS.md)

## Current Milestone

**Current milestone:** v1.24 Related-Data and Dependency Propagation

### Phase 89: Related-Data Propagation Contract and API

**Goal:** Establish the public, explicit API and metadata structures required to declare and invoke related-data fan-out (e.g. `Scrypath.sync_related/3`) without hidden Ecto callback magic.
**Depends on:** none
**Requirements:** DATA-01, DATA-02
**Plans:** 3 plans

Plans:
- [ ] 89-01: Design the `Scrypath.sync_related/3` entrypoint and underlying capability struct for associating parent-child schemas.
- [ ] 89-02: Update core execution runtime to explicitly accept and validate related-data fan-out intents.
- [ ] 89-03: Establish baseline hermetic tests ensuring explicit orchestration overrides auto-magic execution.

### Phase 90: Async Execution and Error Propagation

**Goal:** Provide an out-of-the-box Oban worker pattern for large blast radii and ensure midway failures yield actionable errors rather than silent partial drops.
**Depends on:** Phase 89
**Requirements:** DATA-03, EXEC-01
**Plans:** 2 plans

Plans:
- [x] 90-01-PLAN.md — Update RelatedWorker for explicit error propagation and cancellation.
- [x] 90-02-PLAN.md — Add integration tests for RelatedWorker error propagation behavior.

### Phase 91: Integration, Guides, and Verification

**Goal:** Update `guides/related-data-and-reindexing.md` to remove "temporary workaround" language, clearly document the new API, and lock those assertions in the docs-contract pipeline.
**Depends on:** Phase 90
**Requirements:** EXEC-02, TEST-01, TEST-02
**Plans:** 3 plans

Plans:
- [ ] 91-01: Rewrite the related-data guide to adopt `Scrypath.sync_related/3` and the official Oban pattern as canonical.
- [ ] 91-02: Build `mix verify.phase91` to enforce explicit-only boundaries and assert new non-goals (e.g., no callback magic).
- [ ] 91-03: Final polish of the Phoenix example app to use the new related-data sync feature across an association.

**Working assumptions locked at milestone open:**

- Scrypath continues to value explicit developer orchestration. We do not provide "magic" Ecto listeners or deep preloading behind the scenes.
- The new Oban worker support must be strictly opt-in and configurable; users not using Oban can still use `sync_related/3` synchronously.
- Tenant-safe access remains the highest priority for the subsequent milestone.
