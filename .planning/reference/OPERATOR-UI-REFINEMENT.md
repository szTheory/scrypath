# ScrypathOps UI refinement

**Captured:** 2026-10-06
**Status:** Maintainer feedback and proposed next-milestone brief. No active phase or approved roadmap is created by this document.

## Intent

Make the existing operator UI feel deliberately designed: clear domain language, an obvious reading order, consistent actions and feedback, and appropriate grouping. Improve the inspect → recover → verify journey used by Phoenix/Ecto engineers and production search owners. Preserve useful power-user access and operational truth.

The maintainer's direct visual feedback is the evidence for reopening layout and hierarchy work. Passing behavioral tests and screenshot inventories have not prevented awkward content hierarchy, redundant actions, and decorative card nesting. The exploratory AI-generated brand book is not binding; use the existing implemented brand/tokens as a starting point, and make changes serve a concrete task.

## Evidence and current correction

- Search health had full explanatory sentences rendered as underlined links, adjoining section panels with no gap, and a section panel containing schema cards containing diagnostic cards.
- The earlier Impeccable live session left duplicate preview wrappers in the shared `ops_panel` component. These interfered with direct-sibling spacing and must be removed from shipped source, not papered over with margins.
- The current local correction restores the panel component, gives Search health a 24px section rhythm, makes Next checks a plain list of short shared navigation controls with supporting prose, removes the outer schema section panel, and keeps one surface per schema with plain Backend/Queue groups. Full identifiers, worst-first ordering, unknown queue observations, and schema-specific handoffs remain explicit. Long timestamps wrap.
- Update browser style contracts that previously required the redundant inner borders. The existing token catalog must cover every exported component without pinning an arbitrary component count. Earlier shared refresh/toast changes also require current hook and notification-role assertions.
- These are post-archive changes. They do not alter archived Phase 172 or its verified source receipts. Local validation is recorded separately in STATE.md.

## Proposed delivery sequence

| Slice | Surfaces | Concrete outcome |
| --- | --- | --- |
| Shared visual foundation | Operator shell and representative Search health comp | Establish flat page backgrounds, neutral surfaces, restrained status cues, coherent interaction colors, and one selected theme preference. Revise shared tokens before propagating the treatment across all six surfaces. |
| Recovery entry and diagnosis | Control Room, Search health, Failed sync work | State, affected schema/work, and next safe action have a clear priority. Fix duplicate explanations, awkward handoffs, misplaced controls, and redundant containers. Keep selected schema across links. |
| Repair and verification | Sync and drift | Clarify contract drift versus document freshness, separate observation from repair/promotion, and make accepted/running/terminal/unknown outcomes readable. Preserve existing confirmation and safety gates. |
| Search and saved checks | Search, Playbooks | Review duplicated run actions, form/result hierarchy, preview versus execution, and the prominence of rename/duplicate/delete actions. Keep common actions discoverable without making rare actions compete. |
| Shared pattern consolidation | Patterns demonstrated by the slices above | Consolidate page rhythm, section/object grouping, navigation actions, state presentation, and feedback in the existing component/token system. Update its documentation and remove superseded styling. |

These are proposed work slices, not assigned GSD phase numbers. Requirements and phase boundaries are agreed by the new-milestone workflow.

## Explicit visual and interaction feedback — 2026-10-06

The maintainer rejects the current decorative page gradient, yellow warning fills/outlines, green outlines around zero-error metrics, theme picker's double visual selection, and quiet-button hover backgrounds. This is named evidence reopening shared color/surface tokens. Do not preserve these treatments merely because an archived milestone or the exploratory brand book approved them. Preserve the Scrypath identity and operational behavior; choose the revised palette using representative light/dark comps rather than selecting isolated hex values.

| Issue | Direction and acceptance |
| --- | --- |
| Gradient behind every page | Use a flat neutral operator-page background. Remove the decorative shell wash in every explicit/system theme and responsive override. Functional scroll-edge cues are a separate pattern, not part of this rejection. |
| Yellow summary and schema outlines | Start with neutral surfaces and quiet borders. Convey degraded/failed/unknown states through explicit text and restrained local icon/badge cues; compare warning treatments in the comp. Avoid large yellow fills and whole-record status outlines. Preserve severity and the next safe action. |
| Green outlines on “Schema check errors” and “Failed backend tasks” | Zero-error counts use ordinary neutral metric styling. A zero count does not establish overall search health or document freshness. Reserve success emphasis for a meaningful confirmed outcome; keep nonzero and unavailable values distinguishable. |
| System/light/dark picker shows two selections | Exactly one option looks selected: the stored preference. Choosing System highlights System only, even while the OS changes between light and dark. Appearance still follows the OS. Keyboard/accessibility state and visual selection agree; preserve reload, navigation, and cross-tab behavior. |
| Ugly hover background on “View failed sync work” and related controls | Define shared quiet-action hover/pressed colors against the actual light/dark surfaces. Keep hover, keyboard focus, selected, disabled, and busy states distinct. Apply the pattern across existing uses, not through a one-off page override. |
| Dense “Last success” timestamp | Use a human-readable shared time treatment (for example “2 days ago”), with the exact timestamp and timezone available. Keep the display stable between checks rather than adding a ticking clock. Operational last-success evidence may be clicked/copied with a discoverable keyboard-accessible action; copy the full ISO timestamp and confirm briefly with “Timestamp copied” only after clipboard success. Explain unavailable/denied clipboard access honestly. Keep absent/unobserved success distinct, and keep routine “Checked” timestamps free of copy controls. |

Current source confirms these are shared-pattern problems: `.ops-shell` repeats gradients across responsive/theme rules; `.ops-tone-warning`, `.ops-metric-success`, and `.ops-schema-signal-card--*` apply broad status coloration. Theme CSS positions `#theme-toggle-pill` using `data-theme-effective`, while the selection outline/ARIA follow `data-theme-preference`. Search health formats last success locally instead of using the shared time component. The generic clipboard listener currently has no success feedback and swallows failure; review both standalone and mounted handlers when introducing shared copy feedback.

The first comp must show realistic degraded Search health data, zero/error/unknown metrics, a schema with queue failures, diagnostic timestamps, a quiet action's hover/focus states, and the theme preference control. Include light and dark versions. Agree the overall treatment before coding a broad visual change, then carry it through Control Room, Search health, Failed sync work, Sync and drift, Search, and Playbooks. Audit shared-pattern usages and remove superseded rules instead of accumulating CSS overrides.

## Working rules

1. Start a substantial visual change with a representative comp using real copy and states, as requested by the maintainer. Choose the structure before implementing it. Small corrections to a demonstrated defect can follow the existing visual world directly.
2. Assess task hierarchy and language before adding decoration. State and the next safe action lead; diagnostics support them. Keep full schema/index/task identifiers available.
3. Use proximity, headings, and quiet dividers before adding another panel. An independent operational object can earn its own surface; subgroups within it normally share that surface.
4. Navigation actions use concise destination/action labels and a clear click target. Links embedded in ordinary prose retain their recognizable text-link treatment. Do not remove global underlines to fix an action-list problem.
5. Preserve light, dark, and system-theme behavior; keyboard/focus order; mobile reflow; and reduced-motion support. Cross-reference Emil Kowalski whenever considering motion, per `OPERATOR-UI-QUALITY.md`.
6. Reuse native controls, existing dependencies, shared components, and tokens. Extract a new abstraction when concrete repeated usage justifies it.
7. Do not reopen core search APIs, add backend abstractions, automate infrastructure operations, or create new required CI/paid-judge services as incidental UI work.

## Acceptance and efficient verification

- Each slice names the user job, exact visible defect, chosen structure, and preserved behavior. Check populated, healthy, degraded, missing configuration/backend, loading, error, partial/unknown, disabled, and long-content cases where applicable.
- Carry every row of the explicit feedback table into a traceable milestone requirement and plan. Close it against the relevant rendered pages/states; do not treat a token rename, screenshot inventory, or passing behavior suite alone as proof of visual quality.
- Review representative before/after renders in light and dark on desktop and mobile, with an intermediate-width check when the changed layout crosses a breakpoint. Measure gaps, hit areas, overflow, and diagnostic values rather than trusting class names.
- Run existing LiveView/component contracts for changed behavior and shared wrappers; run token contrast for shared styling; use focused browser checks for actual layout, focus, and navigation. Broaden to the existing mounted recovery/promotion lane when its flow changes.
- Run mutating browser fixtures in a disposable verification stack. Never reseed the maintainer's feedback preview at `http://127.0.0.1:4012/admin/search`.
- Screenshot captures are evidence, not proof of visual parity. Existing full screenshot/contrast matrices remain advisory; update any assertions that encode discarded decoration rather than a user need.
- Finish each slice with code, representative visual evidence, passing relevant checks, documented limitations, and committed bookkeeping. Aesthetic feedback guides direction; it is not pending routine UAT at phase closeout.

## Continuity and next command

### GSD and Impeccable

GSD's canonical `MILESTONE-CONTEXT.md` points to this brief and explicitly requires the installed Impeccable skill for UI design work. GSD owns the lifecycle and acceptance requirements; Impeccable supplies representative comps and applicable Operate/design guidance. Existing `PRODUCT.md` and `DESIGN.md` remain the starting context; initialization is complete. `.impeccable/config.json` records the maintainer's comp-first preference.

Carry chosen visual/component/state decisions into each frontend phase's `UI-SPEC.md`, then its implementation plans and delivered token/component documentation. The new-milestone command does not automatically invoke Impeccable. With both GSD UI settings enabled, the frontend lifecycle is discuss → UI contract → plan → execute/verify. Include Impeccable context and the relevant brief/spec as required reading when delegating UI work; do not assume a child inherits every chat detail.

Last completed phase: **172 — Consistent Operator UI and Verified Recovery**, archived in v1.42. No active phase exists. The next unused phase number is 173; do not replay 172.

Next lifecycle command:

```text
$gsd-new-milestone ScrypathOps UI refinement
```

Read `MILESTONE-CONTEXT.md`, this brief, `PRODUCT.md`, `DESIGN.md`, `STATE.md`, and `OPERATOR-UI-QUALITY.md` when scoping. Carry the maintainer's purposeful adaptive model routing forward. After the workflow agrees a roadmap, route to its first phase's discussion, then UI contract and planning commands.

## Supporting context

- `.planning/research/v1.42/UI-SYSTEM.md`, `UI-STRUCTURE.md`, `UI-AUTOMATION.md`: existing component, hierarchy, and proof inventories. Reuse them; check current source rather than assuming archive observations still apply.
- `PRODUCT.md` and `docs/jtbd-gap-map.md`: engineer/operator audiences and current capability boundaries.
- `DESIGN.md`, `scrypath_ops/assets/css/DESIGN-TOKENS.md`, and `.planning/reference/OPERATOR-UI-QUALITY.md`: incumbent design vocabulary and durable quality rules.
