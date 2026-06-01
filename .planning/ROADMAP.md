# Roadmap: Scrypath v1.30 Release Trust and Evidence Maintenance

## Milestones

- ✅ **v1.28 Realistic Demo App & Admin UI Proof** — Phases 102-105 (shipped 2026-05-31) — see `milestones/v1.28-ROADMAP.md`
- ✅ **v1.29 Contract Repair and Proof Hardening** — Phases 106-108 (shipped 2026-05-31) — see `milestones/v1.29-ROADMAP.md`
- ◆ **v1.30 Release Trust and Evidence Maintenance** — Phases 109-112 (active)

## Phases

### Phase 109: Release Train and Package Truth Audit

**Goal:** Make the release train boring and auditable by confirming version, changelog, package shape, publish workflow, and release-parity truth all agree.

**Requirements:** REL-01, REL-02, REL-03

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 109-01-PLAN.md — Deterministic release agreement gate and artifact package proof
- [x] 109-02-PLAN.md — Restore frozen Phase 97 truth anchors for the release docs contract

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 109-03-PLAN.md — Publish workflow and release-documentation parity

**Success criteria:**

1. Release Please, `mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`, tags, and publish workflow behavior have a documented agreement check.
2. Hex package shape is verified to exclude `scrypath_ops/`, examples, website build output, planning files, `node_modules`, and Playwright artifacts.
3. The canonical publish path is confirmed to run `mix verify.phase11`, dry-run publish, Hex visibility, HexDocs reachability, clean-consumer compile, and release parity.
4. Any discovered release-truth drift is fixed as a patch-sized correction without adding new runtime surface.

### Phase 110: Support Intake and Evidence Routing

**Goal:** Keep adopter support precise by ensuring reports carry reproducible evidence and route to the right maintainer action.

**Requirements:** SUP-01, SUP-02

**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 110-01-PLAN.md — Route support/readiness authority and harden outside-adopter intake surfaces

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 110-02-PLAN.md — Add fast service-free Phase 110 contract proof to `mix verify.adopter` (completed 2026-05-31)

**Success criteria:**

1. README, CONTRIBUTING, outside-adopter intake, and related public docs route compatibility/readiness authority to `guides/support-and-compatibility.md`.
2. Outside-adopter evidence can be classified as Class A-D from the submitted template without maintainer guessing.
3. Finding buckets route clearly to bugfix, docs gap, app-side error, environment failure, or needs-info.
4. Any support-process hardening remains lightweight and does not become a new planning bureaucracy.

### Phase 111: Advisory Proof Stability Decision

**Goal:** Decide with evidence whether `phase105-e2e` remains advisory, needs hardening, or is ready for future required-check promotion.

**Requirements:** STAB-01, STAB-02

**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 111-01-PLAN.md — Harden `phase105-e2e` advisory evidence capture and workflow contracts

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 111-02-PLAN.md — Freeze the advisory decision record and wire it into the existing lean trust lane

**Success criteria:**

1. Recent `phase105-e2e` outcomes are reviewed for pass/fail reason, runtime, retry behavior, artifact usefulness, and owner response expectations.
2. Existing promotion criteria are applied directly: stable job name, low flake rate, bounded runtime, actionable artifacts, owner response, and explicit trigger rules.
3. Required gate posture remains lean unless evidence justifies promoting a heavier live/browser lane.
4. The decision record does not add runtime APIs or broaden product scope under the banner of proof.

### Phase 112: Public Website and Docs Truth Alignment

**Goal:** Keep public claims coherent across website, README, guides, and planning truth while preserving `website/` as a front door rather than a second docs site.

**Requirements:** WEB-01, WEB-02, SCOPE-01

**Success criteria:**

1. Website and public docs consistently describe Scrypath as the Ecto-native search indexing library for Phoenix and Ecto teams.
2. Public copy does not imply hosted search, AI, magic callbacks, public multi-backend v1 support, or immediate search visibility after accepted async work.
3. Website pages route users to canonical README, guides, examples, Hex, and GitHub surfaces instead of duplicating guide bodies.
4. Feature-lane reopen policy remains explicit: concrete production bug, reviewed outside-adopter evidence, or deliberate strategic decision.

## Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.28 Realistic Demo App & Admin UI Proof | 102-105 | 15/15 | Complete | 2026-05-31 |
| v1.29 Contract Repair and Proof Hardening | 106-108 | 3/3 | Complete | 2026-05-31 |
| v1.30 Release Trust and Evidence Maintenance | 109-112 | 5/7 current plans | Active | — |

## Requirement Coverage

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 109 | Complete |
| REL-02 | Phase 109 | Complete |
| REL-03 | Phase 109 | Complete |
| SUP-01 | Phase 110 | Complete |
| SUP-02 | Phase 110 | Complete |
| STAB-01 | Phase 111 | Pending |
| STAB-02 | Phase 111 | Pending |
| WEB-01 | Phase 112 | Pending |
| WEB-02 | Phase 112 | Pending |
| SCOPE-01 | Phase 112 | Pending |

**Coverage:** 10/10 requirements mapped.

## Historical Contract Anchors

- [PHASE97-SCOPE-GUARD] Phase 97/98/99 reject runtime breadth expansion unless reopen policy conditions are met. See `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`.
- [POST-V1.29-DONE-POSTURE] Scrypath is effectively complete for its stated v1 mission; default to release, maintenance, support truth, proof stability, outside-adopter evidence, or silence. See `.planning/threads/scrypath-post-v1.29-done-posture-2026-05-31.md`.

## Next

Start with **Phase 109: Release Train and Package Truth Audit**.

`$gsd-discuss-phase 109`

Also: `$gsd-plan-phase 109` — skip discussion and plan directly.
