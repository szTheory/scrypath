# Phase 174 — UI state coverage decision record

Status: adopted under maintainer-authorized auto-follow recommendations on 2026-10-07T03:08:26Z. The maintainer expects review against the working UI after implementation, not a pre-implementation comp review. These are acceptance criteria, not verified application results. The UI checker passed all seven quality dimensions after completing its primary input read on 2026-10-07T03:01:00Z. The first evidence-incomplete checker response is superseded.

## Adopted kind correction

The compiled prose classifier detects E1 interactive-control, E2 unclassified, E3 list-collection/interactive-control, and E4 nav/interactive-control. Its incomplete cue match does not prove that other real kinds are absent.

| Surface | Proposed complete kinds |
| --- | --- |
| E1 | list-collection, interactive-control, static-content |
| E2 | list-collection, interactive-control, static-content |
| E3 | list-collection, form, interactive-control, static-content |
| E4 | form, nav, interactive-control, static-content |

E1's affected-scope collection/counts and E2's schema records supply list/collection behavior. E3 includes the existing delete confirmation form; E4 includes schema selection/validation. Static text accompanies each. Existing logo/theme/time capabilities inherit delivered173 contracts; no new media collection is introduced. Add any missing real kind before resolving coverage.

## Adopted explicit state rules

### E1 · empty

With no configured schemas, Control Room shows configuration-empty guidance from Copywriting Contract and no target recovery action; it does not present zero observations as healthy.

### E1 · loading

Control Room refresh keeps a meaningful icon and label with busy feedback and preserves the previous successful evidence snapshot; a request being dispatched does not change health facts.

### E1 · error

Control Room distinguishes missing runtime/setup from observation failure, states the observed source/reason and read-only refresh path, and never equates unavailable observation with a remote task failure.

### E1 · populated

Control Room leads with observed fleet state, complete affected schema scope and one read-only Review Search health destination, with verification and exploration quieter. A healthy selected A remains the recovery target while B is worse.

### E1 · partial

Control Room names unavailable or retained source observations and their evidence boundary; known fleet facts remain readable without claiming universal backend health, document freshness or promotion readiness.

### E1 · overflow

Control Room summary, affected-scope items, target identity and actions wrap or stack within the incumbent page at desktop, narrow and changed breakpoints without horizontal page overflow.

### E1 · zero-one-many

Control Room distinguishes no configuration, one affected schema and multiple affected schemas with source-backed counts and correct singular/plural copy, without changing the selected target implicitly.

### E1 · long-text

Control Room preserves complete affected module identifiers, current target and readable explanation/action labels; long values wrap at body size rather than clip or shrink.

### E2 · empty

Search health with no allowlisted schemas shows the configuration-empty guidance from Copywriting Contract and no target action; empty observed failure counts do not prove freshness or universal health.

### E2 · loading

Search health refresh retains its icon/label and busy semantics, the prior successful per-source observation and its stable time reference until a successful replacement observation exists.

### E2 · error

Search health labels the affected source and observation failure/reason with a refresh path, preserves retained known history, and does not turn unknown values into zero counts or terminal remote failure.

### E2 · populated

Search health presents existing worst-first schema records, one neutral surface per schema with full schema/index/mode, plain Backend/Queue groups, explicit local state and record-specific next checks.

### E2 · partial

Known Backend/Queue observations remain readable alongside independently unavailable or retained evidence; no success observed, success time not observed, queue unused, automatic retry and terminal failure remain distinct.

### E2 · overflow

Full schema/index/work identity and exact evidence wrap in their owning surface; Backend/Queue groups stack as content requires with 24px record rhythm, reachable actions and no horizontal page overflow.

### E2 · zero-one-many

Zero schemas uses setup guidance; one and many use the same record structure, truthful counts and correct singular/plural copy. A manual refresh may reorder records but keeps the focused schema/action identity and does not jump focus to the new worst row.

### E2 · long-text

Long full module/index identifiers, source reasons, source times and action labels remain readable without ellipsis or tiny essential copy; Phase173 exact timestamp access remains available where applicable, and routine Checked has no copy control.

### E3 · empty

Only a successful inspection with no failed work uses the Copywriting Contract empty-history message. Invalid target, missing runtime and unavailable inspection render their distinct guards and expose no recovery action from absent evidence.

### E3 · loading

Failed-work refresh/retry retains meaningful label and busy feedback; an in-flight request does not assert acceptance or completion. Selection changes invalidate confirmations/receipts/results and reject prior-generation responses.

### E3 · error

Failed-work observation/action failure displays the relevant source/reason and existing refresh/recovery path; backend task failures, queue job failures and failed observations remain distinct. No dispatched event alone creates a success receipt.

### E3 · populated

Failed-work records show source-qualified Backend task/Queue job identities, operation/index/source facts, time, bounded reason and eligibility before Diagnostics. Existing supported replay is a standard readable action; absent backend replay never gains an invented executable control.

### E3 · partial

Available inspection/history remains readable when a source is unavailable; unavailable retry has a source-backed reason or honest generic explanation. An accepted replacement queue job preserves original history and Check sync status, replaces that row’s retry control and does not assert terminal completion.

### E3 · overflow

Work records, Diagnostics, receipts and the existing delete modal reflow without clipping identifiers, confirmations or controls; the modal’s content may scroll while exact schema/index/count/IDs and confirmation controls remain keyboard/touch reachable.

### E3 · zero-one-many

Zero failures uses inspected-empty copy; one and many preserve source-qualified stable row/action/receipt/confirmation identity. Backend task501 and Queue job501 are distinct and cannot receive each other’s recovery action or receipt.

### E3 · long-text

Bounded reasons and full source IDs/schema/index/document IDs wrap at readable size. Optional verbose diagnostics use the existing selectable/scrollable evidence area; primary diagnosis does not expand raw payload/authentication detail or invent a new redaction policy.

### E4 · empty

An empty allowlist shows setup guidance with no target/action. On a schema-specific page, an absent schema parameter may select the existing first allowlisted default; a present blank/invalid/removed value never defaults to another target.

### E4 · loading

Selection, patch, navigation and reconnect preserve the URL’s validated target. Pending prior-target observations cannot change the new context; confirmation/receipt/result generations invalidate when schema changes, and labels/focus follow the existing lifecycle.

### E4 · error

Invalid or removed explicit targets show the unavailable message and no target actions. Existing host auth/sudo interruption preserves a safe return path with only validated schema context and never automatically replays a mutation.

### E4 · partial

If the selected target remains allowed while another source/schema lacks observations, fleet views retain known evidence and that selected target. If current allowlist validation removes it, actions stop without silently substituting a healthy or worse schema.

### E4 · overflow

Desktop recovery navigation, narrow drawer, palette and target selector retain reachable labels/controls at the existing1280px rail boundary without horizontal page overflow or clipped overlays.

### E4 · long-text

Full canonical schema strings and navigation labels remain readable and encoded through existing mounted path helpers. Palette recovery destinations actually update after a selector patch, and Back/reload/reconnect restore the validated target without hidden global/session/browser sticky selection.

## Review evidence limits

24 final light/dark static captures at1440/1280/1279/390px: source hash matches renderer evidence; one screen per capture; no document overflow; rail from1280px; measured visible controls>=40px. All final captures inspected. Static control/specimen content is not LiveView, mounted navigation, keyboard or mutation proof. Detector ran once: two11px review-caption warnings, and four advisory colors outside staleDESIGN palette. Those captions are review-only and not essential product copy; delivered173 UI-SPEC/currenttokens govern the unchanged palette. No inherited security/advisory exception or release approval.

## Authority and handoff

The maintainer asked to auto-follow the agent’s recommendations until the UI is implemented and ready to inspect. The agent recommended adopting these layouts, corrected kinds and all30 concrete explicit criteria, then preparing/implementing Phase174. The contract records that delegated authority honestly; no manual screenshot review or simulated reviewer approval is asserted. Persist this preference for routine design recommendations within the approved scope; material scope/irreversible/trust gates remain unchanged.

Canonical UI-SPEC and probe inputs/report are in this directory. Continue `$gsd-plan-phase 174 --auto`, then `$gsd-execute-phase 174 --auto`, bounded to174. Leave the persisted global auto-advance setting unchanged, and present the working UI when verification is complete.
