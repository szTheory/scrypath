# Continue — Scrypath UI baseline

## Last action

Captured the maintainer's non-exhaustive home/navigation/health/failed-work/Sync-and-drift feedback, traced its domain semantics, and scoped a systematic implementation pass in `.planning/reference/UI-BASELINE-PLAN.md`. New recommendations remain unimplemented. The latest retained-preview preflight passed at source `e4fef536`; rerun it now rather than assuming freshness.

## Next action

Read `.planning/UI-PREVIEW.json` and work in its canonical checkout (the root shell checkout is different and dirty). Run `npm run ui:preflight` from that checkout's `examples/scrypath_ecommerce`. Read `.planning/reference/UI-BASELINE-PLAN.md`, `.planning/reference/OPERATOR-UI-QUALITY.md` and `.planning/UI-FEEDBACK.md`. Capture/critique the whole current inventory and primary journeys, identify unreported defects, then implement batch 1 and continue through batches 2–3 with tests and rendered confirmation. Produce reviewable product changes, not another planning-only cycle. Use the existing UI-review protocol; read applicable design/writing skills without stacking contradictory visual directions.

## Why

The maintainer has supplied enough direction: prioritize task hierarchy, clear domain language, good controls and visual consistency within the existing brand. Trying search is primary; health and exact recovery remain important. Their examples reveal systemic causes, not a complete checklist. Personas/JTBD already exist as maintained hypotheses; no new workshop or brand refresh is needed. The finish criteria are the three tasks and whole-app checks in the plan, not an aesthetic score or an old phase receipt.

## Open threads

- New feedback and recommendations are planning only; do not report them as fixed. Whole-app visual acceptance remains open. Older captures are historical/pending and become stale after relevant source changes.
- Batch 2 includes consistent time display/copy, meaningful retry rows/receipts, settings autoload/details and the entire lower Sync/drift journey. Keep real Oban IDs, separate task/job/state/category/replay meanings, and never infer freshness from absence of failures.
- Latest completed delivery: PRs #102/#103/#104; lessons/preflight PR #104 merged at `bd4c7b91`. Check actual main when resuming. Required-CI-green squash-merge permission was given earlier; no independent reviewer identity or historical waiver may be invented. Existing advisory dependency audit failures remain separately disclosed.

## Do not

- Do not replay completed Phases 173–177 or route from the historical phase-174 frontmatter in STATE. No new numbered phase or active GSD slice was created for this follow-up.
- Do not edit/reset/stash the dirty root checkout, copy old files wholesale, reseed/replace retained preview data, or run destructive preview teardown. Use seed-disabled documented preview Compose and disposable verification stacks.
- Do not optimize only the maintainer's strings, add endless cards/pills/disclosures, redesign the brand, auto-accept screenshots, or call capture success a design pass. Preserve exact scope/provenance, unknown/stale states, delete/promotion guards and accepted-versus-completed outcomes.
- Keep artifacts under `ui-review-artifacts/`, outside Playwright cleanup. Respect explicit absolute command working directories. Checkpoint owned changes before any worktree transition.
