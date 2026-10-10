# Operator UX review rubric

Maintainer direction accepted 2026-10-09: review the six existing operator surfaces
as complete tasks, use independent critique to catch confusion before human review,
and implement coherent fixes in the current UI refinement milestone. The feedback
below is a reusable acceptance rubric, not a new feature or brand milestone.

## Review each page as a task

| Surface | User question | Main next action | Scope |
| --- | --- | --- | --- |
| Control Room | Does search sync need attention? | Review overall health or choose another job | All configured schemas |
| Search health | Which schemas need attention, and why? | Expand a schema, then open its recovery workflow | All configured schemas |
| Failed sync work | What failed for this schema, and can I retry it? | Inspect the reason and retry eligible work | Visible schema selector |
| Sync and drift | Did recovery work, and does the index configuration match? | Refresh/check evidence; use eligible repair or advanced promotion when needed | Visible schema selector |
| Search | What does this query return? | Choose a schema, run once, inspect results, optionally save a check | Visible schema/mode controls |
| Playbooks | Can I reuse a saved search check? | Choose, preview, run; import or manage when needed | Visible chosen saved check/workspace |

## Required checks

1. **Purpose and next action:** The first viewport makes the current job and useful
   next action clear. Introductory copy must add information beyond the heading.
2. **Scope:** A selection is visible and changes the relevant content. Overview
   URLs, labels, controls, navigation, and results agree. No hidden global target.
3. **Healthy states:** Omit zero issue counters and redundant healthy explanations.
   Keep coverage quiet and offer optional details. Show missing or unobserved facts
   explicitly; never convert missing evidence to zero or success.
4. **Useful information:** Every prominent metric or fact must help choose an action
   or establish a necessary constraint. A tooltip does not justify irrelevant data.
5. **Language:** Use one concrete term for one concept across the complete flow.
   Avoid internal project language, vague “signals,” and implementation names as
   primary instructions. Preserve technical identity in diagnostic evidence.
6. **Hierarchy and disclosure:** State → action → decision-changing context → exact
   diagnostics. Keep rare management, advanced options, raw data, and verbose
   implementation explanations available on demand. Preserve essential failure,
   authorization, scope, and destructive-action facts before confirmation.
7. **Affordances:** Use familiar links, buttons, labels, selectors, native details,
   and shared feedback. One submit action per form/task; retries keep their exact
   work identity. Align quiet actions with the content they act on.
8. **Evidence:** Accepted/queued, running, terminal success, terminal failure, and
   unavailable/unknown are different outcomes. Index configuration agreement does
   not prove document freshness. A failed read does not prove remote task failure.
9. **Complete states:** Check first use, healthy/empty, failing, pending/retrying,
   unavailable/partial, loading, disabled, long names/IDs, and authorization return
   where applicable. Use realistic source-backed content rather than ideal mock data.
10. **Consistency and access:** Desktop/mobile, light/dark/System, keyboard/focus,
    disclosure, toast, navigation, and reload/history use the demonstrated shared
    patterns. Verify the affected behavior and rendered layout before completion.

## Decision rules

- Retain a visible fact if it changes the operator’s decision, identifies the
  current object, bounds the meaning of an outcome, or prevents an unsafe action.
- Disclose expert detail if useful during investigation but unnecessary for the
  common decision. Remove repetition and facts that serve neither purpose.
- Prefer explicit eligible actions attached to the affected object. Do not send
  a specific incident to an unscoped workflow that defaults to another schema.
- Reuse existing components, native browser controls, and dependencies. No new
  dependency is justified by styling or elementary interaction alone.
- Preserve the approved theme picker, current restrained palette, exact schema /
  index / source-qualified work IDs, and host-owned safety policy. Change product
  truth only when existing implementation evidence supports the new wording.

## Bounded workflow

Independent design and technical/rendered assessments first; synthesize priorities
against this rubric and current product facts. Record accepted recommendations in
phase preparation and the current design contract. Build the agreed fixes fully,
inspect affected screens/states in a desktop/mobile batch, and fix its findings
together. Rerun broader checks only when changed source or unresolved failures
justify it. No open-ended polishing or routine human UAT. The maintainer reviews a working result, with genuine unresolved preferences
identified explicitly rather than being asked to discover basic confusion.
