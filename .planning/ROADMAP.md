# Roadmap: Scrypath

## Milestones

- ✅ **v1.28 Realistic Demo App & Admin UI Proof** — Phases 102-105 (shipped 2026-05-31) — see `milestones/v1.28-ROADMAP.md`
- ✅ **v1.29 Contract Repair and Proof Hardening** — Phases 106-108 (shipped 2026-05-31) — see `milestones/v1.29-ROADMAP.md`
- ✅ **v1.30 Release Trust and Evidence Maintenance** — Phases 109-112 (shipped 2026-06-01) — see `milestones/v1.30-ROADMAP.md`
- ✅ **v1.31 Adoption Evidence Demo Hardening** — Phases 113-115 (UAT passed 2026-06-01)
- ✅ **v1.32 Admin UI/UX Design System Cleanup** — Phases 116-118 (shipped 2026-06-01) — see `milestones/v1.32-ROADMAP.md`
- ◆ **v1.33 Admin UI Insane Polish** — Phases 119-127 (active) — see `milestones/v1.33-ROADMAP.md`

## Phases

Active milestone: **v1.33 Admin UI Insane Polish**. Owner-initiated, screenshot-backed polish wedge that deliberately overrides idle posture. Full phase detail in `milestones/v1.33-ROADMAP.md`. Legend: `[R]` research · `[S]` screenshot-loop · `[G]` gate.

- ✅ **Phase 119** — Audit harness + seed-scenario coverage `[S]` — HARNESS-01, SEED-01
- **Phase 120** — Per-touchpoint audit pass `[S]` — AUDIT-01
- **Phase 121** — Design-system tightening: tokens `[G]` — TOKEN-01
- **Phase 122** — Design-system tightening: components `[G]` — COMP-01
- **Phase 123** — Micro-animation layer `[R] [G]` — MOTION-01
- **Phase 124** — IA + Control Room front-door `[S]` — IA-01, COPY-01
- **Phase 125** — Recover screens polish (Posture, Failed Sync, Sync/Drift) `[S]` — RECOVER-01
- **Phase 126** — Explore screens polish (Search/Federation, Playbooks) `[S]` — EXPLORE-01
- **Phase 127** — Shell coherence + milestone verification & UAT `[S] [G]` — SHELL-01, VERIFY-01

## Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.28 Realistic Demo App & Admin UI Proof | 102-105 | 15/15 | Complete | 2026-05-31 |
| v1.29 Contract Repair and Proof Hardening | 106-108 | 3/3 | Complete | 2026-05-31 |
| v1.30 Release Trust and Evidence Maintenance | 109-112 | 11/11 | Complete | 2026-06-01 |
| v1.31 Adoption Evidence Demo Hardening | 113-115 | 3/3 phases complete | UAT passed | 2026-06-01 |
| v1.32 Admin UI/UX Design System Cleanup | 116-118 | 3/3 phases complete | Complete | 2026-06-01 |
| v1.33 Admin UI Insane Polish | 119-127 | 1/9 phases complete | Active | — |

## Historical Contract Anchors

- [PHASE97-SCOPE-GUARD] Phase 97/98/99 reject runtime breadth expansion unless reopen policy conditions are met. See `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`.
- [POST-V1.29-DONE-POSTURE] Scrypath is effectively complete for its stated v1 mission; default to release, maintenance, support truth, proof stability, outside-adopter evidence, or silence. See `.planning/threads/scrypath-post-v1.29-done-posture-2026-05-31.md`.

## Next

Plan and execute **Phase 120** (per-touchpoint audit pass — 9 read-only subagent audits → one ranked, fix-class-tagged backlog; no code changes). Phase 119 landed the seed scenarios + screenshot matrix and a 40-shot baseline in `.tmp/admin-screenshots/`. v1.33 is an owner-initiated polish wedge; see `milestones/v1.33-{ROADMAP,REQUIREMENTS}.md` for full scope, methodology, and locked design decisions.
