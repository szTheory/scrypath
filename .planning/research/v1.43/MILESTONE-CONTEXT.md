# Consumed v1.43 milestone input

The original 2026-10-06 input below is preserved verbatim for continuity. The maintainer accepted the recommended v1.43 scope and inventory reuse on 2026-10-06. Its pre-initialization status and next-command statements are historical; current status is in ../../STATE.md and ../../ROADMAP.md.

---

# Next milestone context: ScrypathOps UI refinement

**Captured:** 2026-10-06
**Status:** Maintainer feedback and proposed scope for the new-milestone workflow. Requirements and roadmap still need agreement. This file does not activate a milestone or approve a phase.

## Read first

- `reference/OPERATOR-UI-REFINEMENT.md`: concrete feedback, proposed sequence, preserved behavior, and acceptance criteria. This is the durable detailed brief.
- `PRODUCT.md` and `DESIGN.md` at the repository root: personas, product boundaries, incumbent design, and explicit revision direction.
- `reference/OPERATOR-UI-QUALITY.md`, `PROJECT.md`, and `STATE.md`: quality rules, archived work, preview, and continuity.
- Relevant v1.42 UI inventories listed in the detailed brief: reuse existing knowledge and verification lanes.

## Goals to scope

Improve the existing six operator surfaces around inspect → recover → verify. Engineers integrating search and operators keeping it healthy are co-primary. Start with the shared visual foundation, then recovery pages, Sync and drift, Search/Playbooks, and consolidation of demonstrated shared patterns.

Explicit requirements to carry forward:

- Flat neutral page backgrounds; remove the decorative shell gradient.
- Calm neutral surfaces and restrained local status cues; revise the broad yellow warning treatment and green zero-error metric outlines.
- Exactly one visually selected theme preference. System follows OS appearance while only System looks selected.
- Consistent, deliberate shared hover/focus/pressed/disabled/busy treatment in both themes.
- Human-readable operational last-success times; retain exact evidence and provide accessible copying with brief confirmation after actual clipboard success. Keep routine checked-time metadata free of copy controls and avoid ticking displays.
- Clear hierarchy, concise consistent domain language, useful next actions, and fewer decorative containers throughout the existing UI.

## GSD and Impeccable together

Use the installed `impeccable` skill for the UI design work. GSD owns requirements, roadmap, phase context, implementation plans, verification, and delivery bookkeeping. Impeccable supplies visual direction, representative comps, and applicable design/interaction guidance within that scope.

- Product/design initialization is already done. Read the existing files; do not restart the persona interview or run init again without a concrete missing decision.
- `.impeccable/config.json` records `buildPath: comp`. Substantial visual changes begin with realistic light/dark comps using the current data and states. Operator pages use Impeccable's Operate guidance. Preserve accepted decisions as work moves between agents/sessions.
- Put the selected visual direction and component/state decisions in the frontend phase's GSD `UI-SPEC.md` before implementation planning. Plans must reference that contract and the feedback requirements. Keep `DESIGN.md` and the implemented token/component documentation consistent with delivered decisions.
- Both `workflow.ui_phase` and `workflow.ui_safety_gate` are enabled. After discussing the first frontend phase, generate its UI contract with `gsd-ui-phase` before `gsd-plan-phase`; do not skip that step as a shortcut. The new-milestone command alone does not automatically invoke Impeccable.
- Existing brand-book details and rejected styling are open to revision. Keep the Scrypath identity, operational truth, and useful existing behaviors. Add no dependency without a concrete need. Cross-reference Emil Kowalski when considering motion.

## Continuity

- Last completed phase: **172 — Consistent Operator UI and Verified Recovery**, v1.42 archived. No phase is active; next unused number is 173.
- Work from `/Users/jon/projects/scrypath`, branch `planning/next-milestone-handoff`. Preserve current uncommitted product/design/UI work and intentional adaptive model routing.
- Feedback preview: `http://127.0.0.1:4012/admin/search`. Preserve its data; run mutating verification in a disposable stack.
- Reuse relevant existing automated checks and inspect representative renders. Passing behavioral tests alone does not establish visual quality. Keep post-archive evidence separate from the archived source receipt.

Next command: `$gsd-new-milestone ScrypathOps UI refinement`.
