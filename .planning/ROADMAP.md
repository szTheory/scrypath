# Roadmap: Scrypath

## Milestones

- ✅ **v1.48 Discovery and onboarding** — Phases 192–193 (2 phases, 6 plans, 13 of 16 requirements; Phase 194 and SITE-07 to SITE-09 cut at the entry-point checkpoint; shipped to `main` 2026-11-21 via PRs #160, #163, #164; `tech_debt`; Hex 0.3.20 carries Phase 192, the Phase 193 regroup waits for the next release) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.47 Brand completion** — Phases 188.1, 189–191 (4 phases, 8 plans, 18 of 18 requirements; shipped to `main` 2026-11-20 via PRs #149, #152, #153, #154; `tech_debt`; not released to Hex; website deployed) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.46 Brand foundation and re-skin** — Phases 186–188 (3 phases, 16 plans, 27 of 29 requirements; shipped to `main` 2026-11-19 via PRs #137, #138, #139, #143; `tech_debt`; not released to Hex; Phases 189 and 190 landed in v1.47) — [archive](milestones/v1.46-ROADMAP.md)
- ✅ **v1.45 Foundation and CI** — Phases 182–185 (archived locally 2026-11-01; qualified `tech_debt` closeout; final-source acceptance external; merge/publication separate) — [archive](milestones/v1.45-ROADMAP.md)
- ✅ **v1.44 Sync correctness** — Phases 178–181 (4 phases, 17 plans, 45 tasks; archived locally 2026-10-26; `tech_debt` carried forward; PR #122 merge/publication pending) — [archive](milestones/v1.44-ROADMAP.md)
- ✅ **v1.43 ScrypathOps UI refinement** — Phases 173–177 (5 phases, 21 plans; archived 2026-10-25; first shipped in `scrypath` 0.3.16) — [archive](milestones/v1.43-ROADMAP.md)
- ✅ **v1.42 ScrypathOps operator/admin UI** — Phase 172 (1 phase, 8 plans; archived2026-10-04) — [archive](milestones/v1.42-ROADMAP.md)
- ✅ **v1.41 Readiness Gate Follow-Through** — Phases 168–171 (4 phases, 19 plans; archived 2026-10-02; `tech_debt` accepted; original Phase 170 decision remains NOT READY at its cutoff; later separate readiness assessment is READY) — [archive](milestones/v1.41-ROADMAP.md)
- ✅ **v1.40 Readiness Evidence Closure** — Phases 165–167 (archived locally 2026-09-27; no Hex release; assessment remains NOT READY) — [archive](milestones/v1.40-ROADMAP.md)
- ✅ **v1.39 Pre-Operator UI Quality Readiness Ratchet** — Phases 162–164 (archived locally 2026-09-26) — [archive](milestones/v1.39-ROADMAP.md)
- ✅ **v1.38 Packaged Adopter Proof** — Phases 160–161 (shipped 2026-09-25; `scrypath 0.3.13`) — [archive](milestones/v1.38-ROADMAP.md)
- ✅ **v1.37 Code Quality Ratchet** — Phases 148–159 (shipped 2026-08-26) — [archive](milestones/v1.37-ROADMAP.md)
- ✅ **v1.36 Dependency Security Remediation** — Phases 144–147 (shipped 2026-08-25) — [archive](milestones/v1.36-ROADMAP.md)
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137–143 (shipped 2026-06-24) — [archive](milestones/v1.35-ROADMAP.md)
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128–136 (shipped 2026-06-29) — [archive](milestones/v1.34-ROADMAP.md)

## Current Posture

v1.48 Discovery and onboarding is complete and archived ([audit](milestones/v1.48-MILESTONE-AUDIT.md), `tech_debt`, no unsatisfied requirement; the optional website phase was cut at the entry-point checkpoint because traffic is effectively nil, see [research/v1.48-prep/CHECKPOINT.md](research/v1.48-prep/CHECKPOINT.md)). There is no active milestone: the next one is chosen at the milestone boundary from the prepared options in [research/v1.49-prep/](research/v1.49-prep/) and [reference/ROLLING-ROADMAP.md](reference/ROLLING-ROADMAP.md). Hex 0.3.20 (2026-11-21) is the latest release; the Phase 193 sidebar regroup and guards reach HexDocs only with the next release, which needs the maintainer's explicit yes.

`deep-quality` stays an advisory red with one known cause (cloak and cloak_ecto via optional sigra) until sigra ships without a hard `cloak_ecto` requirement; the audit stays fail-closed. The v1.45 archive keeps its documented debt and historical verification overrides.

## Phases

<details>
<summary>✅ v1.48 Discovery and onboarding (Phases 192-193) — SHIPPED 2026-11-21</summary>

- [x] Phase 192: Docs truth and README (4/4 plans) — PR #160, Hex 0.3.20
- [x] Phase 193: HexDocs regroup and guards (2/2 plans) — PR #163
- [x] Checkpoint: entry-point signal — PR #164 (cut Phase 194)
- [~] Phase 194: Website content — cut at the checkpoint; SITE-07 to SITE-09 moved to the backlog

Archive: [v1.48-ROADMAP.md](milestones/v1.48-ROADMAP.md), [audit](milestones/v1.48-MILESTONE-AUDIT.md).

</details>

<details>
<summary>✅ v1.47 Brand completion (Phases 188.1, 189-191) — SHIPPED 2026-11-20</summary>

- [x] Phase 188.1: CI path classifier (1/1 plans) — PR #149
- [x] Phase 189: Website re-skin (3/3 plans) — PR #152
- [x] Phase 190: Wording that does not need the catalog (2/2 plans) — PR #153
- [x] Phase 191: Cleanup (2/2 plans) — PR #154

Archive: [v1.47-ROADMAP.md](milestones/v1.47-ROADMAP.md), [audit](milestones/v1.47-MILESTONE-AUDIT.md).

</details>

<details>
<summary>✅ v1.46 Brand foundation and re-skin (Phases 186-188) — SHIPPED 2026-11-19</summary>

See [v1.46-ROADMAP.md](milestones/v1.46-ROADMAP.md).

</details>
