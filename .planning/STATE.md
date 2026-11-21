---
gsd_state_version: "1.0"
milestone: v1.49
milestone_name: Catalog foundation
status: planning
last_updated: "2026-11-21T20:03:22.969Z"
last_activity: 2026-11-21
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See [PROJECT](PROJECT.md), updated 2026-11-21.

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current focus:** v1.49 Catalog foundation (opened 2026-11-21): requirements and roadmap being defined; phases 195 to 198 per [catalog-prep/SYNTHESIS.md](research/catalog-prep/SYNTHESIS.md).

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-11-21 — Milestone v1.49 started


## Performance Metrics

**v1.46 plans:** 16 across Phases 186 (3), 187 (11) and 188 (2).
**v1.47 plans:** 8 done (188.1: 1, 189: 3, 190: 2, 191: 2).
**v1.48 plans:** 6 done (192: 4, 193: 2).

## Accumulated Context

### Decisions

Full decision log lives in PROJECT.md, [V1.46-PREP.md](research/brand-and-catalog/V1.46-PREP.md) and the [v1.47 prep notes](research/v1.47-prep/). Standing decisions:

- v1.48 Discovery and onboarding (opened 2026-11-21 as recommended; [v1.48 prep notes](research/v1.48-prep/), D is the tie-breaker): 192 docs truth and README, 193 HexDocs regroup plus guards, an entry-point checkpoint (record GitHub traffic referrers and hex.pm downloads; decides 194), optional 194 website content. Cut line after 193. The catalog is v1.49 (renumbered at its opening); the earlier "catalog is v1.48, Phases 192-196" wording in v1.47 notes is superseded. Hex 0.3.20 after Phase 192 needs the maintainer's explicit yes.
- v1.47 was the small "Brand completion" milestone: 189 website, 190 wording, 191 cleanup (done).
- GATE-02 is mapped to Phase 189 and stays a standing rule for every phase. Gate budget: 8 of 12 used at the start of v1.47; Phase 189's static contract takes row 9. `build-and-check` stays non-required (decided in the gap pass; re-open trigger in SITE-05).
- Phase 189 merges only after `build-and-check` is green on the exact PR head (checked with `gh api`), because merging deploys the site and that job is not a required check.
- Gap pass 2026-11-20 ([research/v1.47-gap-pass/](research/v1.47-gap-pass/)): the three website hexes shared with `brandbook/` join the deny set in Phase 191; the Cancel-focus assertion lives in the required-lane `operator.spec.ts`; the kickoff chore is tracked as Phase 188.1 (CI-01); the picker light-only fallback is pre-decided in SITE-02.
- Ops stays System-default for theme; light default applies to website, README and docs only. Bricolage is not shipped in ops. No type-scale reflow.
- No human UAT: every success criterion is an executable check. Hex releases need the maintainer's explicit yes. Green PRs are squash-merged without asking (standing instruction 2026-11-19, see AGENTS.md).

### Pending Todos

- Phase 192 starts with an inventory of every test pin on `verify.adopter` and the shipped-docs wording (claim or wiring); none is weakened to reach green.
- At the checkpoint (after Phase 193) record `gh api repos/szTheory/scrypath/traffic/{referrers,popular/paths,views,clones}` (14-day window; 4 views from 3 uniques when last read) and hex.pm downloads (1,782 all time, 89 in the last 7 days when last read).

### Blockers/Concerns

None blocking. Standing conditions (not blockers):

- `deep-quality` stays an advisory red with one known cause (cloak and cloak_ecto via optional sigra) until sigra ships without a hard `cloak_ecto` requirement; the audit stays fail-closed with no exception.
- The retained UI preview (`.planning/UI-PREVIEW.json`) records pre-squash commits; refresh to current main before the first phase that needs rendered ops evidence (expected v1.48). v1.47's checks do not need it.
- Housekeeping before v1.48 (2026-11-21): #157 fixed the axe `label-content-name-mismatch` markup (command hint and timestamp copy buttons now take their accessible name from visible text), the vacuous `operator.spec.ts` regex and two unqualified doc lines; #158 fixed the README HexDocs self-links. Dependabot #129 (axe 4.14.0, verified green locally on a merge with #157), #150 and #151 merge one at a time on green.
- Unrelated dirty `.planning/config.json` and `.planning/state.json` edits stay out of owned commits.

## Carried forward from v1.45

v1.44 and v1.45 landed on main (PRs #123, #124, #126) and `scrypath` 0.3.18 is released. The v1.45 archive keeps its `tech_debt` audit, its documented debt and the maintainer-authorized historical overrides; see [closeout](milestones/v1.45-CLOSEOUT.md) and the [audit](milestones/v1.45-MILESTONE-AUDIT.md). The old closeout cursor under `/private/tmp/scrypath-v145-closeout/` no longer exists and is not a resume target. Original 61 held-out pairs keep their recorded identities; no independent or aesthetic approval is inferred.

## Deferred Items

No new artifact acknowledgment was made. Two prior v1.44 acknowledgments remain suppressed; their unresolved meanings are retained below and in the [prior audit](milestones/v1.44-MILESTONE-AUDIT.md#closeout-disposition--2026-10-26).

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| verification_gaps | Archived Phase 124 owner gate | human_needed; prior acknowledgment retained | 2026-10-26 | v1.44 |
| deferred_items | Archived Phase 173 shell-contract note | deferred; prior acknowledgment retained | 2026-10-26 | v1.44 |

Three phase-freshness overrides (182–184) were explicitly authorized for the v1.45 closeout; no audit suppression markers or original report statuses were rewritten.

## Session Continuity

Last session: 2026-11-20
Stopped at: Milestone v1.48 archived; awaiting the maintainer's choice of the next milestone.
Acting next: the maintainer picks the next milestone from the v1.49 prep notes; a Hex release carrying the Phase 193 regroup needs the maintainer's explicit yes. Phase 192 shipped as PR #160 and Hex 0.3.20 was published 2026-11-21.

## Operator Next Steps


- Start the next milestone with /gsd-new-milestone
