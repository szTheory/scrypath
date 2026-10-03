---
gsd_state_version: "1.0"
milestone: v1.42
milestone_name: ScrypathOps operator/admin UI
current_phase: 172
current_phase_name: Consistent Operator UI and Verified Recovery
status: planning
stopped_at: Phase 172 UI-SPEC approved; implementation planning next
last_updated: "2026-10-03T15:29:34.618Z"
last_activity: 2026-10-03
last_activity_desc: One-phase roadmap written; all eight OPUX requirements mapped exactly once
state_head: "0ba9c6268f0bb96eaf5a1cc4e3ee4ac9907207c2"
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-10-03)

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** v1.42 Phase 172 — consistent, accessible operator UI and a schema-preserving incident journey with verified recovery. The maintainer's 2026-10-03 direction authorizes OPUX-01–OPUX-08 and supersedes the earlier four proposed requirements; no repeated scope approval is pending.

## Current Position

Phase: 172 (1 of 1 in v1.42) — Consistent Operator UI and Verified Recovery
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-10-03 — One-phase roadmap written; all eight OPUX requirements mapped exactly once

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

- Current milestone: 0 plans executed; implementation plans and durations are not yet established.
- Previous milestone v1.41: 4 phases (168–171), 19 plans, 9 requirements complete.
- Historical plan timings and evidence remain in the milestone archives; no v1.42 runtime acceptance has been performed by this roadmap task.

## Accumulated Context

### Decisions

- Preserve the six existing surfaces, shell, palette, and 48 shared `OpsUi` components. Repair demonstrated semantics, typography, hierarchy, and domain-language issues; use the existing token/component authority. The three current UI reports and `reference/OPERATOR-UI-QUALITY.md` guide implementation.
- Keep the complete user outcome in Phase 172: shared controls/layout/copy, schema context, truthful recovery, meaningful regression proof, and reviewed delivery. Establish the UI contract before checked plans; add focused checks alongside changes.
- Correlate a known replayable failure with newly accepted work, terminal backend success, and the expected active-index document. Retained failure history may remain; accepted work and old successful tasks do not prove recovery. Advanced promotion remains a separate action with consistent UI/server eligibility.
- Reuse LiveView, token/contrast, and existing mounted/full-browser lanes. Inspect before/after screenshots directly, cover representative keyboard/reflow/theme boundaries, and retain diagnosable evidence. No routine human UAT, paid AI judge, new required job, or repeated full-matrix run by default.
- Use PR-first delivery and the existing two-stage candidate/final exact-SHA closeout. Commit final requirement/phase/milestone tracking before final attestation, then leave that tracked source unchanged. Decide release/no-release from delivered package changes.

### Historical Boundaries

- v1.41 is archived with 9/9 requirements, 4/4 phases, 6/6 integration paths, and 3/3 end-to-end flows complete. Its audit accepts nonblocking Nyquist validation-record debt for Phases 168–170; Phase 171 is validated.
- The original Phase 170 decision remains **NOT READY** at [issue #86 comment 5940381507](https://github.com/szTheory/scrypath/issues/86#issuecomment-5940381507). The later separate assessment is **READY** at [comment 5955742805](https://github.com/szTheory/scrypath/issues/86#issuecomment-5955742805), within its stated limits; inherited assumptions EA-167-01–EA-167-07 remain unresolved.
- Current GSD tracking records Phase 170 at 8/8 through its authorized planning-side replacement. The frozen `8c271…` snapshot remains historical 17/18 with original bytes preserved. See `milestones/v1.41-phases/170-documentation-and-readiness-closeout/170-08-TRACKING-REPLACEMENT.md` and `170-POST-FREEZE-RECONCILIATION.md`. Do not rerun Phase 170.
- Scrypath 0.3.14 publication/parity and exact-main closeout are recorded in PROJECT.md and the v1.41 archive. Those receipts and older readiness cutoffs remain source-bounded; they do not verify changed v1.42 UI behavior. Historical “What's next” statements describe archive-time posture.

### Pending Todos

None yet.

### Blockers/Concerns

- No unresolved approval blocks the established scope. Current research is source/screenshot evidence, not a runtime acceptance pass.
- The existing failed-sync display fixture is intentionally unrecoverable and old task/document probes can false-pass. Phase 172 must establish a correlated recovery oracle and preserve historical failures rather than manufacture universal green health.
- Reuse historical proof only after checking relevant source/scenario changes. Runtime, focus, responsive, and contrast claims need evidence for the changed behavior; screenshot inventory or a contrast-only scan cannot prove them all.

## Deferred Items

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| Product scope | New workflows, core APIs, backend abstraction, host authorization product, broader matrices | Separate concrete evidence and scope required | 2026-10-03 | v1.42 |
| Visual scope | Palette/framework replacement, wholesale CSS rewrite, incidental issues without material user impact | Retain the existing system; reopen only with a named invalidator | 2026-10-03 | v1.42 |
| Verification topology | New required CI job or paid visual-judge service | Existing economical lanes are the default | 2026-10-03 | v1.42 |
| Historical planning | Nyquist validation records for Phases 168–170 | Accepted nonblocking v1.41 audit debt; no phase replay | 2026-10-02 | v1.41 |

## Session Continuity

Last session: 2026-10-03T15:29:34.603Z
Stopped at: Phase 172 UI-SPEC approved; implementation planning next
Resume file: .planning/phases/172-consistent-operator-ui-and-verified-recovery/172-UI-SPEC.md
Next action: Establish the bounded Phase 172 UI contract from `.planning/research/v1.42/SUMMARY.md`, then plan Phase 172 and execute in the roadmap's recommended order. No implementation, tests, or delivery occurred in this roadmap task.

## Preview and Cleanup

- Optional feedback preview: `http://127.0.0.1:4012/admin/search`, Compose project `scrypath-ui-v142`, owned by the v1.42 task and bind-mounted from its isolated worktree. Captures are outside tracked source at `/private/tmp/scrypath-v142-review/`.
- Run destructive seed/reset verification in a separate disposable Compose project; never reset the feedback preview. Preserve unrelated services, worktrees, and stashes.
- At closeout, clean disposable task-owned verification state and document preview retention or shutdown. Stop only this preview from `examples/scrypath_ecommerce` with `COMPOSE_PROJECT_NAME=scrypath-ui-v142 WEB_PORT=4012 docker compose -f compose.yaml -f compose.dev.yaml down`; retain preview volumes while feedback still needs the demo state.
