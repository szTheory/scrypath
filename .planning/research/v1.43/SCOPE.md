# v1.43 scope and reused evidence

**Date:** 2026-10-06
**Milestone:** v1.43 — ScrypathOps UI refinement
**Agreement:** The maintainer accepted the proposed scope/version and recommended reuse of existing UI inventories. The maintainer explicitly approved all 20 requirements and Phases 173–177 at the final review gate on 2026-10-06.

## Job and boundaries

Ecto/Phoenix integrators and production search owners are co-primary. Refine the existing inspect → recover → verify workspace across Control Room, Search health, Failed sync work, Sync and drift, Search, and Playbooks. The concrete 2026-10-06 feedback reopens shared visual foundations and task hierarchy. Preserve useful power-user access, product truth, exact evidence, safe-action gates, and all supported operations.

The approved scope is in `../../reference/OPERATOR-UI-REFINEMENT.md`. The consumed canonical input is preserved in `MILESTONE-CONTEXT.md`; its pre-start status is historical. The milestone adds no new core API, backend abstraction, infrastructure automation, auth product, UI surface, framework, required CI lane, or paid visual service. Add no dependency without a demonstrated need. Milestone version v1.43 is separate from Hex semver; initialization does not authorize a package version bump.

## Research choice and reuse limits

Skip fresh domain/ecosystem research for this milestone. Reuse these existing local inventories as orientation:

| Input | Reuse | Limit |
| --- | --- | --- |
| `../v1.42/UI-SYSTEM.md` | Shared token/component, theme, control, and layout inventory | Source review predates completed Phase 172 and local follow-ups; recheck touched source. Old color recommendations are superseded by the explicit refinement feedback. |
| `../v1.42/UI-STRUCTURE.md` | Six surfaces, user jobs, domain vocabulary, and context/evidence boundaries | Prior findings may already be fixed; do not create requirements to replay them. |
| `../v1.42/UI-AUTOMATION.md` | Existing LiveView, contrast, browser, mounted recovery, capture, isolation, and closeout lanes | Old oracle/fixture findings are historical. Actual current coverage/results must be inspected during the relevant phase. |
| `../../milestones/v1.42-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md` | Completed behavior and exact-source evidence boundaries | v1.42 receipts do not verify changed v1.43 source. Do not replay Phase 172 or Phase 170. |
| Root `PRODUCT.md`, `DESIGN.md` | Existing audience, product boundaries, design baseline, and explicit revision direction | Detailed exploratory brand colors and metaphors are not binding. No new adoption/performance claims. |
| `../../reference/OPERATOR-UI-QUALITY.md` | Conventional interactions, direct visual review, economical proof, and clean delivery | A capture inventory or passing behavior suite alone does not prove visual quality. |

This choice does not modify `workflow.research`, adaptive model routing, UI generation, or UI safety gates. Phase-specific research can resolve a named implementation uncertainty. No new external research or fresh product verification is claimed by this note.

## Design lifecycle

1. Discuss approved Phase 173 next. Use the installed Impeccable skill in Operate mode with existing PRODUCT/DESIGN context and `buildPath: comp`; initialization is already complete.
2. Before broad visual implementation, compare realistic light/dark Search health comps showing degraded state, zero/error/unknown metrics, a schema with queue failures, long diagnostic values, operational times, quiet-action states, and the theme selector. Resolve the visual direction early; do not defer it to routine UAT.
3. Run `$gsd-ui-phase 173` before `$gsd-plan-phase 173`. The UI contract records palette/surfaces, hierarchy, component/state rules, and responsive/keyboard behavior. Plans reference it and the feedback requirements. Subsequent frontend phases refine their UI contracts within the selected visual world.
4. Each delivery slice includes representative before/after render inspection and executable proof. Consolidation does not postpone acceptance from earlier slices. Update DESIGN.md and the implemented token/component catalog with delivered decisions; remove superseded rules rather than piling on overrides.

No palette hex values, motion, or alternate layout concepts are selected by this milestone setup. Existing native controls and function components remain the starting point. Consult relevant `prompts/` references when phase decisions touch Phoenix/LiveView, Ecto, search semantics, brand, or release engineering. The initial scope review consulted the local LiveView and brand references; their exploratory details do not override product facts or maintainer direction. Cross-reference Emil Kowalski when considering motion.

Impeccable context loaded successfully on 2026-10-06. It reported that `.impeccable/design.json` predates DESIGN.md edits. This is a nonblocking mention-only finding: DESIGN.md and the explicit brief govern this scope; offer the skill's `document` command to refresh the sidecar only if the maintainer asks. Do not repair it incidentally.

## Acceptance carried into every phase

- Name the exact visible defect, operator job, selected structure, and preserved behavior. Exercise applicable populated, healthy, degraded, setup-empty/missing-backend, loading, error, partial/unknown, disabled/busy, and long-content states.
- Inspect representative before/after renders in light/dark at desktop/mobile widths; check an intermediate width when changed layout crosses a breakpoint. Measure gaps, hit areas, overflow, and diagnostic visibility. Preserve reduced-motion behavior and keyboard/focus order.
- Use existing LiveView/component checks for changed state/event wiring, token AA contrast for shared styling, and focused browser proof for real geometry, theme behavior, focus, and rendered handoffs. Broaden to mounted recovery/promotion when those flows change. Update old assertions that require rejected decoration.
- Keep accepted/running/terminal/unknown states honest. Correlate an operation with its actual task/index/document evidence; retain failure history. No universal green-dashboard promise.
- Run mutating fixtures in a disposable stack. Never reseed `http://127.0.0.1:4012/admin/search`. Keep existing preview volumes and unrelated services intact.
- No new required CI job, recurring paid judge, mock reviewer approval, or routine human UAT. Attach findings and dispositions to real source/scenario evidence; use the existing two-stage closeout process at delivery.

## Working-tree continuity

Work from `/Users/jon/projects/scrypath` on `planning/next-milestone-handoff`. Preserve pre-existing uncommitted UI/design changes; milestone setup owns planning files only. Inventory and source evidence for local follow-ups are in STATE.md, distinct from the archived v1.42 receipt. The mounted preview bind-mounts this checkout; its state is intentionally retained. Implementation plans must account for the current local baseline rather than resetting to the archive.

The complete requirements and five-phase roadmap were presented together at the final new-milestone gate. The maintainer selected “1” (Approve) on 2026-10-06, explicitly approving both. Milestone setup is complete; Phase 173 is ready for discussion, with no execution started.

