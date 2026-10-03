# Requirements: v1.42 ScrypathOps operator/admin UI

**Defined:** 2026-10-03
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding operational reality.
**Scope authority:** The maintainer's 2026-10-03 UI cleanup direction expands the earlier incident-only proposal to demonstrated shared consistency, accessibility, hierarchy, and language repairs across the six existing operator surfaces. It authorizes automated investigation and delivery with a live preview for optional feedback. The earlier four proposed requirements were not approved verbatim and are superseded by this set.

## Current requirements

### Consistent, usable operator UI

- [ ] **OPUX-01:** Operators can read and use the existing six surfaces at narrow and desktop widths with consistent shared type, spacing, control, color, radius, shadow, and layer roles. The component/token catalog accounts for the actual shipped components; selected fixes address current source or screenshot evidence, including undersized action labels and excessive mobile summary depth.
- [ ] **OPUX-02:** Operators can use the affected forms, modes, schema selectors, and file-action dialogs with a keyboard and assistive technology: controls have names and descriptions, selection and disabled states are exposed, focus is visible, and modal focus remains contained and returns to its trigger.
- [ ] **OPUX-03:** Operators see coherent domain terms and a clear action hierarchy across Control Room, Posture, Failed Sync, Sync/Drift, Search, and Playbooks. Common actions remain visible; verbose evidence and technical references are secondary. Error, setup-empty, and partial states explain the next supported action.

### Honest incident recovery

- [ ] **OPUX-04:** Operators retain their selected, allowed schema across Posture → Failed Sync → Sync/Drift handoffs, refresh and back navigation. Invalid or unavailable selections fall back safely without silently acting on a different target.
- [ ] **OPUX-05:** Operators can distinguish accepted recovery work, terminal success, failure, timeout, stale/unknown checks, and retained failure history. Index promotion stays a separate advanced action with the same current eligibility rules in the UI and server handler; no completed message is emitted merely because a backend task was accepted.
- [ ] **OPUX-06:** One deterministic browser journey follows rendered controls from Control Room through Posture, Failed Sync and Sync/Drift, recovers a known replayable failure, and correlates newly created work with terminal backend success and the expected document in the active index. The visible final state accurately reflects remaining historical evidence; universal green/zero failed history is not required.

### Regression protection and finish

- [ ] **OPUX-07:** Automated checks cover the changed behavior, meaningful responsive/keyboard/layout boundaries, and both-theme contrast through existing test/CI lanes. Before/after screenshots receive direct agent inspection, with failures diagnosable from retained artifacts. Routine acceptance uses no paid AI judge and leaves no pending human UAT.
- [ ] **OPUX-08:** The milestone closes with requirement-to-evidence traceability, reviewed PR-first delivery and current required CI evidence, an explicit release/no-release decision, committed task-owned work, and documented cleanup or intentional retention of the preview. Prior phase evidence is reused within its limits and Phase 170 is not rerun.

## Future requirements

New workflows, visual directions, public core APIs, authorization products, or broader platform matrices require concrete evidence and separate scope. Existing incidental issues without material user impact may be recorded with a revisit trigger instead of expanding the milestone.

## Out of scope

| Item | Reason |
| --- | --- |
| New component framework, wholesale CSS rewrite, palette/brand replacement | Existing token and component system is substantial and current screenshots support retaining it. |
| New Scrypath core API, backend strategy, host authorization model | This milestone improves existing operator behavior and proof. |
| Clearing failure history or claiming global health to make a test pass | Contradicts current domain semantics and would hide operational evidence. |
| New paid visual review service or full screenshot matrix on every commit | Existing deterministic checks and direct screenshot inspection meet the cost/maintenance intent. |
| Reopening v1.41 or replaying Phase 170 | Closed, source-bounded evidence and post-freeze tracking reconciliation remain valid. |

## Traceability

| Requirement | Phase | Status |
| --- | --- | --- |
| OPUX-01 | Pending roadmap | Not started |
| OPUX-02 | Pending roadmap | Not started |
| OPUX-03 | Pending roadmap | Not started |
| OPUX-04 | Pending roadmap | Not started |
| OPUX-05 | Pending roadmap | Not started |
| OPUX-06 | Pending roadmap | Not started |
| OPUX-07 | Pending roadmap | Not started |
| OPUX-08 | Pending roadmap | Not started |

**Coverage:** 8 requirements, mapping pending.
