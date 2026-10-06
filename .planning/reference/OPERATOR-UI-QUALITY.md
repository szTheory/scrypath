# Operator UI quality default

**Owner direction:** 2026-10-03, v1.42. Applies to later operator UI work unless the maintainer changes it.

## Product direction

Build a conventional, legible operator interface from the existing Phoenix components and design tokens. Use the principle of least surprise and established patterns from comparable operational tools. Improve the consistency of the system with each change. The maintainer can explore a running preview and give direction while work proceeds; routine acceptance must not require human UAT.

Personas: on-call engineer recovering search; search owner checking an index change; operator inspecting/saving a search; first-run operator configuring the host. Inventory all six existing surfaces and their three job loops before changing shared behavior. Start with the incident-recovery loop and fix demonstrated issues in shared controls and adjacent surfaces. Keep the existing brand and proven behaviors as the baseline.

**Named visual invalidator, 2026-10-06:** Direct maintainer feedback rejects the decorative shell gradient, broad yellow warning treatment, green zero-error metric outlines, theme picker's double visual selection, and quiet-action hover colors. Shared color/surface tokens are open for revision in the next milestone. Establish the treatment with representative light/dark comps, then apply it across the six existing surfaces. The AI-generated brand book and archived visual receipts do not override this direction. See `OPERATOR-UI-REFINEMENT.md` for timestamp/copy behavior and traceable acceptance criteria; the changes are proposed, not shipped.

## Design rules

| Area | Default |
| --- | --- |
| Hierarchy | Put the current state, affected object, and next safe action before secondary explanation. One clear page heading; meaningful section headings. |
| Layout | Choose the component for the information: lists/cards for rich records, definition lists for object facts, tables for genuine comparisons. Choose columns from available content width. Do not shrink text to fit a grid. |
| Responsive behavior | Design the task at narrow widths first, then use wider space where it improves scanning. Keep primary controls visible and reachable. Long identifiers must wrap or have an explicit accessible scroll/copy affordance; no page-wide overflow. |
| Typography | Use named roles from the shared system. Body/action labels must remain readable; small metadata is secondary. Preserve hierarchy rather than applying a global size increase. |
| Tokens | One documented authority for typography, spacing, padding, colors, radii, shadows, motion, and layering. Extend shared components before adding nearly identical screen-specific variants. |
| Controls | Use native semantics, visible labels, help/error associations, selected/disabled/busy states, visible focus, and complete dialog focus/dismissal behavior. |
| Disclosure | Keep frequent actions visible. Collapse verbose evidence or uncommon options only when it improves the task. Do not hide every action in a menu. |
| Copy | Use concise domain nouns and verb–object actions. Distinguish schema, index, queue job, backend task, check, and saved playbook. Distinguish queued/accepted/running/completed/failed/unknown. Avoid marketing language, repeated instructions, implementation narration, and raw API/path lists in the primary flow. |
| Operational truth | A successful retry can coexist with retained failure history. A task acceptance is not task completion, and a clean settings contract is not proof of document freshness. Never force a green aggregate to manufacture a success story. |
| States | Cover populated, empty, setup-missing, loading, error, partial, disabled, stale, long-content, zero/one/many, and keyboard/mobile cases where applicable. |

## Motion reference

Whenever considering or reviewing UI animation or micro-interactions, cross-reference [Emil Kowalski's design-engineering work](https://emilkowal.ski/skill) and the [emilkowalski/skills collection](https://github.com/emilkowalski/skills). Use it to sharpen decisions about whether motion helps, its timing, and how it responds to interruption; keep Scrypath's infrastructural motion style, shared tokens, and reduced-motion support as the implementation contract.

## Efficient verification and change control

1. Capture current rendering and establish a named user problem before changing a pattern. Preserve useful existing behavior and tests; do not repeat completed palette/brand work without an invalidator.
2. Use existing LiveView checks for state boundaries, fast token/contrast checks for shared styles, and browser tests for actual navigation, focus, geometry, and real service seams. Exercise changed inputs through rendered forms or controls in the same plan; direct handler calls alone cannot prove event wiring. Cross-screen tests must change the selected schema before handing off, not only enter a non-first schema directly.
3. Use a small representative matrix in the existing CI lanes. Keep the full screenshot/contrast matrix advisory. Report actual coverage rather than treating screenshot existence or a filename check as visual parity.
4. Inspect before/after screenshots in the active agent session. No paid visual-judge API calls, new AI service, or recurring model gate by default. Never auto-update a pixel baseline merely to clear a failure.
5. User feedback is design direction, not a substitute for acceptance tests. Escalate only an actual unresolved product/risk choice or external permission; record the reason.
6. Record completed findings, evidence, source identity, remaining limits, and explicit revisit triggers. Later milestones reopen only changed or invalidated claims.
7. During integration debugging, retain only the task-owned disposable stack and reload changed source without reseeding the feedback preview. Preserve first failures, use bounded action timeouts, and rerun the focused cases. Finish with the canonical fresh-stack command at committed source; repeated full image rebuilds are not the inner feedback loop.

8. Measure the generated CSS rather than assuming a token-like class exists. Check CSS layer precedence when a repair has no effect.
9. Modal focus must survive real LiveView patches and object rename/delete; use stable object IDs and a reachable successor. Keep validation errors inside the active dialog's accessibility tree.
10. Distinguish observation failure from remote operation failure. Only exact terminal evidence supports completed/failed copy; unknown outcomes retain accepted task identity.

## Clean finish

Use PR-first delivery and the existing required checks. Keep planning records and source evidence distinct without freezing completion bookkeeping. Leave task-owned files committed, generated artifacts outside tracked source, and temporary verification services removed. A preview intentionally retained for maintainer feedback has a documented URL, owner, and stop command. Preserve unrelated worktrees and stashes. Decide whether a release is warranted from the delivered package changes; never bump a version merely to close a planning milestone.

Current evidence/inventory: `research/v1.42/UI-SYSTEM.md`, `UI-STRUCTURE.md`, and `UI-AUTOMATION.md`.
