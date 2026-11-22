---
gsd_state_version: "1.0"
milestone: v1.49
milestone_name: Catalog foundation
current_phase: 196
current_phase_name: Fixtures and three adopters
status: planning
stopped_at: Phase 196 planned (5 plans); ready to execute
last_updated: "2026-11-22T01:23:15.028Z"
last_activity: 2026-11-21
last_activity_desc: Phase 196 planned (5 plans)
state_head: 5aaf94f983c57e98934b4163e9c87b0c04d65f77
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 17
  completed_plans: 3
  percent: 20
---

# Project State

## Project Reference

See [PROJECT](PROJECT.md), updated 2026-11-21.

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current focus:** v1.49 Catalog foundation: Phase 195 (Mount and prove) is complete; Phase 196 (Fixtures and three adopters) is next. The run stops after Phase 197 for the maintainer's storybook look.

## Current Position

Phase: 196 (Fixtures and three adopters) — READY TO EXECUTE
Plan: Not started
Status: Ready to execute
Last activity: 2026-11-21 — Phase 195 complete, transitioned to Phase 196


## Performance Metrics

**v1.46 plans:** 16 across Phases 186 (3), 187 (11) and 188 (2).
**v1.47 plans:** 8 done (188.1: 1, 189: 3, 190: 2, 191: 2).
**v1.48 plans:** 6 done (192: 4, 193: 2).
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 195 P01 | 12 min | 3 tasks | 16 files |
| Phase 195 P02 | 13 min | 3 tasks | 17 files |
| Phase 195 P03 | 95min | 3 tasks | 4 files |

## Accumulated Context

### Decisions

Full decision log lives in PROJECT.md, [V1.46-PREP.md](research/brand-and-catalog/V1.46-PREP.md) and the [v1.47 prep notes](research/v1.47-prep/). Standing decisions:

- v1.48 Discovery and onboarding (opened 2026-11-21 as recommended; [v1.48 prep notes](research/v1.48-prep/), D is the tie-breaker): 192 docs truth and README, 193 HexDocs regroup plus guards, an entry-point checkpoint (record GitHub traffic referrers and hex.pm downloads; decides 194), optional 194 website content. Cut line after 193. The catalog is v1.49 (renumbered at its opening); the earlier "catalog is v1.48, Phases 192-196" wording in v1.47 notes is superseded. Hex 0.3.20 after Phase 192 needs the maintainer's explicit yes.
- v1.49 Phase 195 (2026-11-21): storybook mounted dev/test-only and merged (PRs #171, #172). The cold `ops-ui` trigger tripped (620 s on the first main run against the 548 s line) and the maintainer chose to continue; see [GO-NO-GO.md](phases/195-mount-and-prove/GO-NO-GO.md). The plan's measure-then-merge order could not see the main-run cold number, so future gates should measure on the main-run cold sample after merge.
- v1.47 was the small "Brand completion" milestone: 189 website, 190 wording, 191 cleanup (done).
- GATE-02 is mapped to Phase 189 and stays a standing rule for every phase. Gate budget: 8 of 12 used at the start of v1.47; Phase 189's static contract takes row 9. `build-and-check` stays non-required (decided in the gap pass; re-open trigger in SITE-05).
- Phase 189 merges only after `build-and-check` is green on the exact PR head (checked with `gh api`), because merging deploys the site and that job is not a required check.
- Gap pass 2026-11-20 ([research/v1.47-gap-pass/](research/v1.47-gap-pass/)): the three website hexes shared with `brandbook/` join the deny set in Phase 191; the Cancel-focus assertion lives in the required-lane `operator.spec.ts`; the kickoff chore is tracked as Phase 188.1 (CI-01); the picker light-only fallback is pre-decided in SITE-02.
- Ops stays System-default for theme; light default applies to website, README and docs only. Bricolage is not shipped in ops. No type-scale reflow.
- No human UAT: every success criterion is an executable check. Hex releases need the maintainer's explicit yes. Green PRs are squash-merged without asking (standing instruction 2026-11-19, see AGENTS.md).
- [Phase 195]: Catalog route flag is read with Application.get_env at expansion, not Macro.expand of compile_env, and the guard sits outside the quote — Macro.expand of a compile_env call yields a call AST that is always truthy, which would make the guard vacuous
- [Phase 195]: Test-env catalog_routes flag is off when PHX_SERVER=true so the Docker runtime_test image never mounts /storybook — That image binds 0.0.0.0; the flag must imply a loopback bind
- [Phase 195]: Planted storybook endpoint is a full request pipeline (Plug.Parsers and render_errors), and render-all crash results carry their cause — Without a parser the query string is dropped and every plant renders the first variation with no theme; without render_errors every crash reads as a missing error view. Pinning the cause per plant keeps a mistyped route from passing as the planted failure.
- [Phase 195]: Fifth primitive story is ops_sync_status, not the form-field class; the form-field story moves to Phase 197's patterns tier — ops_field is mostly phx-hook behavior that a server-side render-all cannot exercise, so a story for it would claim more than its test proves.
- [Phase 195]: Continue with the storybook on the maintainer's choice against a tripped cold sample (not a pass): PR cold ops-ui 517 s, first main run after the merge 620 s (over the 548 s line), warm 378 s; the cold excess is mostly the lock-change root-graph cache miss, the storybook's own marginal cost is about +36 s

### Pending Todos
- Phase 197 discuss takes the deferred fidelity probe (a local, non-gating computed-style comparison of a story against the real ops screen, light and dark) from the Phase 195 go/no-go record.

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

Last session: 2026-11-21T21:47:33.673Z
Stopped at: Phase 195 complete, ready to plan Phase 196
Acting next: verify Phase 195 (all three plans are done; PR #171 is merged and the go/no-go record is in docs PR #172), then Phase 196 (fixtures). A Hex release still needs the maintainer's explicit yes.
Resume file: None

## Operator Next Steps


- Start the next milestone with /gsd-new-milestone
