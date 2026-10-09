---
phase: "174"
slug: "recovery-entry-and-diagnosis"
status: approved
checker_status: approved
checker_reviewed_at: "2026-10-07T03:01:00Z"
reviewed_at: "2026-10-07T03:08:26Z"
recommendations_authority: maintainer-auto-follow
shadcn_initialized: false
preset: none
created: "2026-10-06"
---

# Phase 174 — UI Design Contract

> Visual and interaction contract for OPUX-16–OPUX-19. Phase 174 extends the approved Phase 173 ScrypathOps visual system across Control Room, Search health, Failed sync work, and only the existing recovery context seams required to preserve a selected schema. User-adopted decisions in `174-CONTEXT.md` are binding. No new surface, framework, dependency, auth policy, public API, or automated recovery capability is introduced.

> **2026-10-09 feedback supersession:** The maintainer rejected selected-schema context on an all-schema overview. Control Room and Search health now have no selection or filter, normalize old schema queries with history replacement, and use explicit row links to enter scoped recovery. Health destinations are always unscoped. This supersedes D-19 and the older overview-target provisions below; scoped selectors, identity, authorization, and safe return rules remain. See `../../reference/ALL-SCHEMA-HEALTH-2026-10-09.md` and the current `DESIGN.md` / operator IA. Historical comp and closeout evidence remains dated to its original source.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual; existing ScrypathOps tokens and Phoenix components |
| Preset | Not applicable; Phoenix HEEx/LiveView, no React or shadcn |
| Component library | Existing ScrypathOps `OpsUi` / `CoreComponents`, daisyUI and Tailwind v4 |
| Icon library | Existing Heroicons through `CoreComponents.icon`; preserve Scrypath wordmarks |
| Font | `system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif`; `ui-monospace, Cascadia Code, Menlo, monospace` for identifiers and exact evidence |

Use the delivered Phase 173 neutral palette, native controls, theme preference, shared quiet-action states, snapshot-stable time treatment, and app-owned layout. Do not repair Impeccable sidecars/config as incidental work. Keep the established labels, nav groupings, shell, and mount behavior.

## Component Inventory

Enumerated by `rg -n '^  def [a-z_]+\(assigns\)' scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — 49 components — `scrypath_ops`@`0.1.0` — 2026-10-06.

The command is re-runnable from the repository root; `mix.exs` resolves the local package name/version. This table is a non-exhaustive list of relevant known-good components, never a closed allowlist.

| Components | Import path | Phase use |
|-----------|-------------|-----------|
| `ops_page_header`, `ops_heading`, `ops_section`, `ops_toolbar`, `ops_panel` | `ScrypathOpsWeb.OpsUi` | Preserve the existing page and section hierarchy |
| `ops_verdict`, `ops_status`, `ops_tone_chip`, `ops_badge` | `ScrypathOpsWeb.OpsUi` | Local source state with readable text and restrained cues |
| `ops_metric`, `ops_metric_grid` | `ScrypathOpsWeb.OpsUi` | Fleet summary and neutral zero values |
| `ops_button`, `ops_link_button`, `ops_action_group`, `ops_refresh_control` | `ScrypathOpsWeb.OpsUi` | Standard actions, explicit scope, stable focus/loading states |
| `ops_empty_state`, `ops_config_empty`, `ops_notice`, `ops_disclosure`, `ops_inline_code` | `ScrypathOpsWeb.OpsUi` | Truthful empty/unavailable states, collapsed diagnostics, exact identifiers |
| `ops_schema_select`, `ops_time`, `ops_trail`, `ops_command_palette`, `ops_modal` | `ScrypathOpsWeb.OpsUi` | Selected-target choice, operational evidence, recovery navigation and existing confirmation |

Check the source for additional exported components when implementing; the inventory is evidence, not a component restriction.

## Comp Comparison and Selection

The chosen structure stays within Phase 173's warm-neutral light and neutral dark world. It uses one summary surface for Control Room, one neutral surface per schema on Search health, and one source-qualified work record per failure on Failed sync work. Backend and Queue remain plain diagnostic groups inside their owning schema/work record. No visual redesign or concept tournament is opened.

Static review source and renderer are in this phase directory:

- `174-comps.html` contains representative Control Room, Search health, and Failed sync work fixtures, including full schema/index/work IDs, selected Product while Variant has worse fleet signals, equal numeric Backend task / Queue job identities, source-aware unknown/retained evidence, retry eligibility, receipt, and exact delete-confirmation facts. The separate accepted-receipt/delete specimens are labelled alternate states; they are not simultaneous live controls. Invalid-target behavior is specified separately rather than mixed into a valid-target specimen.
- `render-comps.cjs` adapts the Phase 173 Playwright renderer. It blocks network requests and writes only phase screenshots and `174-comp-evidence.json`; requested widths are 1440, 1280, 1279, and 390 in light and dark, yielding 24 captures when the local browser launch is available.
- The initial sandbox capture could not launch Chromium. A scoped local-browser launch subsequently succeeded with the reviewed network-blocking renderer, producing all 24 captures in light/dark at 1440, 1280, 1279 and 390px. `174-comp-evidence.json` records one active screen per capture, zero horizontal document overflow, visible control sizes, identifiers and the rail/drawer boundary. The orchestrator inspected the captures; a bounded correction/confirmation pass aligns widths, readable identity text, standard targets and review-only alternate state labels.

All fixture controls are static specimens, not executable product verification. Their values are illustrative and do not assert current runtime state, a changed auth policy, new eligibility rules, risk acceptance, full-matrix success, or extension of any historical exact-source receipt. Preserve the existing command palette keyboard/focus lifecycle and the 17rem rail at 1280px; the rail becomes the existing mobile drawer at 1279px and below.

## Visual Hierarchy

### Control Room — OPUX-16

Lead with current observed fleet state, affected allowed-schema scope, then exactly one connected next safe read-only step. Put quieter verification/exploration destinations after that summary. Do not repeat the same recovery explanation or offer equally weighted duplicate controls. Keep direct navigation and the command palette available.

Show the current recovery target separately from fleet evidence. A selected Product target remains Product even while Variant is worst-first; label the recovery CTA's schema/fleet scope. Do not infer document freshness, universal backend health, promotion readiness, or remote failure from zero failures or an unavailable observation.

### Search health — OPUX-17

Retain existing worst-first schema ordering and classification. Give each schema one neutral meaningful surface with the complete schema module name, complete index name, sync mode, and readable times. Put plain Backend and Queue diagnostic groups inside it. Keep a schema-specific next check beside its evidence, name that destination's explicit schema, and make choosing another schema a deliberate target-changing link.

Keep “observation unavailable,” retained older observation, “no success observed,” “queue not used,” queue retrying, and observed terminal failure distinct. Zero counts remain neutral. Do not add a fleet table, nested decorative panel, filter, pagination, new severity rule, or routine Checked-time copy control.

### Failed sync work — OPUX-18

Within each work record, show source/type and full source-qualified ID first; then selected schema, operation, relevant index/source facts, source time, concise bounded failure reason, and manual recovery availability/reason. This reading order must be complete before the collapsed Diagnostics disclosure. Use standard readable per-row controls for an action supported by existing recovery data. Resolve source-qualified internal row keys against the current selected schema and inspection for action lookup, receipts, and delete confirmations; equal numeric backend task and queue job IDs must remain distinct. A Backend task with no in-page replay has no retry action. Automatic Oban retry and Scrypath manual replay remain separate facts.

Keep retained failure history visible after a replacement job is accepted. The accepted receipt replaces that original row’s retry control under the existing duplicate-acceptance guard, without a cross-session exactly-once claim. The receipt must say that acceptance is not completion and leave terminal status unknown until observed. Preserve the existing delete confirmation and host gates; show schema, index, document count, and exact document IDs before confirmation.

## Selected Schema and Navigation Contract — OPUX-19

The canonical, validated `schema` query parameter is the recovery target authority. Resolve only allowlisted module strings through existing helpers; never create atoms from URL/user input. A present allowed value wins over worst-first recommendations. Preserve first-allowlist default only when the schema parameter is absent on an existing schema-specific route. Blank, malformed, hostile, removed, or otherwise invalid explicit targets render “That schema is unavailable” with no target action and no fallback selection. An empty allowlist is a setup state with no selected target and no recovery action.

Control Room and Search health stay fleet-wide while visibly identifying the selected recovery target. Carry its encoded query through rendered recovery links, refresh/reconnect, browser Back, desktop/mobile navigation, command palette targets after selector patches, Sync and drift handoff/return, and the existing sudo authorization interruption/return. Preserve safe return-path handling and host-owned authorization; do not forward arbitrary query data or replay a mutation on return.

Changing selection updates URL/history. Invalidate schema-bound inspection results, confirmations, receipts and stale asynchronous responses when the target changes. Never carry an open delete confirmation or successful observation from Schema A into Schema B. Preserve focus and the operator's current record/action context if refresh reorders worst-first rows.

## Spacing Scale

Preserve the delivered Phase 173 spacing tokens (from `174-CONTEXT.md` D-10 and `173-UI-SPEC.md`):

| Token | Value | Usage |
|-------|-------|-------|
| ops-1 | 4px | Icon gaps, compact inline separation |
| ops-2 | 8px | Controls, field/control groups |
| ops-3 | 12px | Compact local groups |
| ops-4 | 16px | Default row and narrow-panel spacing |
| ops-5 | 20px | Existing desktop panel padding |
| ops-6 | 24px | Sections, schema/work records, page gap |
| ops-8 | 32px | Major layout gaps |
| ops-12 | 48px | Large page separation |
| ops-16 | 64px | Page-level separation where the incumbent layout uses it |

Inherited scale exceptions: preserve the existing 6px control-internal field gap and compact sizing; do not introduce a generic replacement scale. Standard actions are 40px tall; prominent or icon-only targets are at least 44px. Preserve 4/6/8px corners and 12px overlay corners.

## Typography

Preserve the incumbent font system and primary type roles. Identifiers and exact source evidence use the existing technical mono stack; explanatory copy and failure reasons use body sans.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body, action, reason | 14px | 400; actions 600 | 1.5 |
| Schema/subsection heading | 16px | 600 | 1.3 |
| Section/verdict heading | 18px | 600 | 1.3 |
| Page title | 24px | 600 | 1.3 |

Inherited metadata/technical-context exceptions at 11px and 12px and incumbent navigation sizing stay as already implemented; never use them for essential instructions, retry eligibility, or failure reasons. No new size or weight is introduced. Use tabular numerals for measured IDs/times and wrap complete identifiers rather than shrinking or clipping them.

## Color

Preserve the compositional target of 60% dominant neutral page, 30% secondary neutral surfaces, and up to 10% interaction accent. The percentage is a hierarchy budget, not a requirement to add violet.

| Role | Light | Dark | Usage |
|------|-------|------|-------|
| Dominant (60%) | `#f7f6f3` | `#111419` | Flat page/shell floor |
| Secondary (30%) | `#ffffff`, `#efeee9` | `#191e25`, `#222831` | Rail/header, schema/work records, restrained quiet grouping |
| Accent (up to 10%) | `#5b4ad1` | `#aaa0ff` | Primary committing action, current destination/explicit target, actual links, independent keyboard focus |
| Warning | `#805000` | `#f2c66d` | Local degraded/pending source state with text |
| Failure/destructive | `#ad2922` | `#ffaaa2` | Observed failure and existing danger confirmation only |

Accent is reserved for primary committing actions, current destination/selection, links, and visible keyboard focus. Copper remains a logo detail and never signals health. Status always has explicit nearby text; neutral zero/unavailable observations do not inherit a warning/failure cue. Maintain the delivered ≥4.5:1 text and ≥3:1 essential non-text/focus contrast floors for actual composed pairs across light, dark, and System.

## Copywriting Contract

| Element | Copy / treatment |
|---------|------------------|
| Control Room primary CTA | “Review Search health” — read-only fleet diagnosis, carrying the current validated recovery target |
| Search health primary action | “Refresh health” — keep icon/label while busy and preserve the last observation |
| Failed work primary eligible action | “Retry queue job” or existing source-appropriate label, only when existing recovery data and current server rules allow it |
| Empty configuration | “No search schemas configured. Configure the host application's schema allowlist to inspect search health.” No zero-valued health claim or target action. |
| Empty failed-work state | “No failed sync work for this schema.” Add the existing next step only when inspection evidence supports it. |
| Missing runtime/backend | “Runtime not configured.” Keep the existing host configuration guidance and read-only refresh path; expose no retry from unavailable inspection. |
| Failed-work observation error | “Failed sync work could not be checked.” Show the source/reason and “Refresh failed work” path; do not claim an empty history from a failed lookup. |
| Error/invalid target | “That schema is unavailable. Select an allowlisted schema to continue.” Keep actions disabled; never switch targets silently. |
| Partial source observation | Name the source and state “Observation unavailable”; give the displayed reason and identify any retained observation time. Never render unavailable as zero or terminal failure. |
| Unavailable retry | Name the source and state the known reason, such as “Backend tasks have no supported in-page replay action.” If the cause is unknown, explain only that recovery is unavailable under current observed facts. |
| Accepted replacement | “Replacement accepted — queue job {full job ID}. Terminal completion has not been observed.” Keep the original failure history and existing “Check sync status” handoff; backend task identity appears only when source evidence supports it. |
| Destructive confirmation | Preserve “Confirm delete sync work”; show selected schema, index, document count, and every exact ID; preserve the existing explicit “Retry delete sync work” confirmation action and host/server gates. |
| Time and history | Preserve Phase 173 snapshot-relative time and exact-value access where applicable; do not add routine Checked copy controls or rewrite source time as current freshness. |

## Responsive, Focus, and State Contract

- At 1280px and above, preserve the existing 17rem navigation rail. At 1279px and below, use the existing labeled mobile drawer/header. Keep desktop and mobile nav destinations, selected schema context, palette links, and focus-return behavior consistent.
- Keep a logical reading and keyboard order through refresh/reordering. Do not move focus to the newly worst record after a manual refresh. Focus remains visibly independent of hover, pressed, selected, and status color.
- At narrow and intermediate widths, stack Backend/Queue groups and action groups as space requires; wrap complete schema/index/task/job IDs and reasons. Keep actions reachable, preserve body/action type size, and prevent horizontal page overflow.
- During loading, retain the icon and label, show a meaningful busy state, and keep prior successful observations/time intact. During error or partial observation, retain useful known/retained evidence and name the source and reason; dispatch alone never creates a success receipt.
- Cover no configured schemas, zero/one/many schema records, normal populated records, unavailable/retained source observations, queue unused/retrying/terminal failure, empty failed-work history, disabled retry, supported retry, accepted-but-not-terminal receipt, long identifiers/reasons, invalid target, allowlist removal during confirmation, stale prior-schema results, duplicate/stale clicks, palette after selector patch, refresh reordering, and safe auth return. These are future implementation acceptance cases, not current pass claims.
- Use native controls and existing motion/reduced-motion behavior. No extra dependency or custom keyboard model is needed.

## State Coverage Surfaces

Proposed element surfaces for the parent workflow's UI-consideration probe; these identify the scope only and do not pre-populate probe classifications or resolutions.

- **E1:** Control Room current-state summary, affected-schema scope, and the single safe read-only recovery entry action.
- **E2:** Fleet-wide Search health summary and worst-first per-schema records with source-local Backend and Queue groups, complete identities, times, and schema-specific next checks.
- **E3:** Failed sync work list records with source-qualified work identity, reason, eligibility, standard retry control, collapsed Diagnostics, accepted replacement receipt, and exact delete confirmation.
- **E4:** Recovery-target selection and its URL-driven continuity through Control Room/Search health links, navigation, command palette patches, refresh/Back, Sync and drift, and authorization return; includes invalid/unavailable no-fallback state.

## UI Considerations

The maintainer instructed the agent to follow its recommendations automatically through preparation and implementation, reserving visual review for the working UI. This authorizes the proposed complete kinds and concrete state rules; no manual comp inspection or reviewer identity is claimed. The initial heuristic omitted real record/form/text kinds, corrected explicitly below.

The compiled probe reports **30 applicable, 30 explicitly resolved, 0 unresolved, 0 unclassified, 0 backstops**. These are future implementation acceptance criteria, not passing product tests. Inputs: `174-ui-elements.json` and `174-ui-resolutions.json`; report: `174-ui-coverage.json`. Re-run: `node /Users/jon/.codex/gsd-core/bin/lib/ui-consideration-probe.cjs .planning/phases/174-recovery-entry-and-diagnosis/174-ui-elements.json .planning/phases/174-recovery-entry-and-diagnosis/174-ui-resolutions.json` (resolve the installed runtime path on other hosts).

Confirmed agent-selected kinds under the maintainer’s auto-follow direction:

| Surface | Kinds |
| --- | --- |
| E1 | list-collection, interactive-control, static-content |
| E2 | list-collection, interactive-control, static-content |
| E3 | list-collection, form, interactive-control, static-content |
| E4 | form, nav, interactive-control, static-content |

| Category | Element(s) | Status | Resolution / Reason |
| --- | --- | --- | --- |
| empty | E1 | ✅ covered | With no configured schemas, Control Room shows configuration-empty guidance from Copywriting Contract and no target recovery action; it does not present zero observations as healthy. |
| loading | E1 | ✅ covered | Control Room refresh keeps a meaningful icon and label with busy feedback and preserves the previous successful evidence snapshot; a request being dispatched does not change health facts. |
| error | E1 | ✅ covered | Control Room distinguishes missing runtime/setup from observation failure, states the observed source/reason and read-only refresh path, and never equates unavailable observation with a remote task failure. |
| populated | E1 | ✅ covered | Control Room leads with observed fleet state, complete affected schema scope and one read-only Review Search health destination, with verification and exploration quieter. A healthy selected A remains the recovery target while B is worse. |
| partial | E1 | ✅ covered | Control Room names unavailable or retained source observations and their evidence boundary; known fleet facts remain readable without claiming universal backend health, document freshness or promotion readiness. |
| overflow | E1 | ✅ covered | Control Room summary, affected-scope items, target identity and actions wrap or stack within the incumbent page at desktop, narrow and changed breakpoints without horizontal page overflow. |
| zero-one-many | E1 | ✅ covered | Control Room distinguishes no configuration, one affected schema and multiple affected schemas with source-backed counts and correct singular/plural copy, without changing the selected target implicitly. |
| long-text | E1 | ✅ covered | Control Room preserves complete affected module identifiers, current target and readable explanation/action labels; long values wrap at body size rather than clip or shrink. |
| empty | E2 | ✅ covered | Search health with no allowlisted schemas shows the configuration-empty guidance from Copywriting Contract and no target action; empty observed failure counts do not prove freshness or universal health. |
| loading | E2 | ✅ covered | Search health refresh retains its icon/label and busy semantics, the prior successful per-source observation and its stable time reference until a successful replacement observation exists. |
| error | E2 | ✅ covered | Search health labels the affected source and observation failure/reason with a refresh path, preserves retained known history, and does not turn unknown values into zero counts or terminal remote failure. |
| populated | E2 | ✅ covered | Search health presents existing worst-first schema records, one neutral surface per schema with full schema/index/mode, plain Backend/Queue groups, explicit local state and record-specific next checks. |
| partial | E2 | ✅ covered | Known Backend/Queue observations remain readable alongside independently unavailable or retained evidence; no success observed, success time not observed, queue unused, automatic retry and terminal failure remain distinct. |
| overflow | E2 | ✅ covered | Full schema/index/work identity and exact evidence wrap in their owning surface; Backend/Queue groups stack as content requires with 24px record rhythm, reachable actions and no horizontal page overflow. |
| zero-one-many | E2 | ✅ covered | Zero schemas uses setup guidance; one and many use the same record structure, truthful counts and correct singular/plural copy. A manual refresh may reorder records but keeps the focused schema/action identity and does not jump focus to the new worst row. |
| long-text | E2 | ✅ covered | Long full module/index identifiers, source reasons, source times and action labels remain readable without ellipsis or tiny essential copy; Phase173 exact timestamp access remains available where applicable, and routine Checked has no copy control. |
| empty | E3 | ✅ covered | Only a successful inspection with no failed work uses the Copywriting Contract empty-history message. Invalid target, missing runtime and unavailable inspection render their distinct guards and expose no recovery action from absent evidence. |
| loading | E3 | ✅ covered | Failed-work refresh/retry retains meaningful label and busy feedback; an in-flight request does not assert acceptance or completion. Selection changes invalidate confirmations/receipts/results and reject prior-generation responses. |
| error | E3 | ✅ covered | Failed-work observation/action failure displays the relevant source/reason and existing refresh/recovery path; backend task failures, queue job failures and failed observations remain distinct. No dispatched event alone creates a success receipt. |
| populated | E3 | ✅ covered | Failed-work records show source-qualified Backend task/Queue job identities, operation/index/source facts, time, bounded reason and eligibility before Diagnostics. Existing supported replay is a standard readable action; absent backend replay never gains an invented executable control. |
| partial | E3 | ✅ covered | Available inspection/history remains readable when a source is unavailable; unavailable retry has a source-backed reason or honest generic explanation. An accepted replacement queue job preserves original history and Check sync status, replaces that row’s retry control and does not assert terminal completion. |
| overflow | E3 | ✅ covered | Work records, Diagnostics, receipts and the existing delete modal reflow without clipping identifiers, confirmations or controls; the modal’s content may scroll while exact schema/index/count/IDs and confirmation controls remain keyboard/touch reachable. |
| zero-one-many | E3 | ✅ covered | Zero failures uses inspected-empty copy; one and many preserve source-qualified stable row/action/receipt/confirmation identity. Backend task501 and Queue job501 are distinct and cannot receive each other’s recovery action or receipt. |
| long-text | E3 | ✅ covered | Bounded reasons and full source IDs/schema/index/document IDs wrap at readable size. Optional verbose diagnostics use the existing selectable/scrollable evidence area; primary diagnosis does not expand raw payload/authentication detail or invent a new redaction policy. |
| empty | E4 | ✅ covered | An empty allowlist shows setup guidance with no target/action. On a schema-specific page, an absent schema parameter may select the existing first allowlisted default; a present blank/invalid/removed value never defaults to another target. |
| loading | E4 | ✅ covered | Selection, patch, navigation and reconnect preserve the URL’s validated target. Pending prior-target observations cannot change the new context; confirmation/receipt/result generations invalidate when schema changes, and labels/focus follow the existing lifecycle. |
| error | E4 | ✅ covered | Invalid or removed explicit targets show the unavailable message and no target actions. Existing host auth/sudo interruption preserves a safe return path with only validated schema context and never automatically replays a mutation. |
| partial | E4 | ✅ covered | If the selected target remains allowed while another source/schema lacks observations, fleet views retain known evidence and that selected target. If current allowlist validation removes it, actions stop without silently substituting a healthy or worse schema. |
| overflow | E4 | ✅ covered | Desktop recovery navigation, narrow drawer, palette and target selector retain reachable labels/controls at the existing1280px rail boundary without horizontal page overflow or clipped overlays. |
| long-text | E4 | ✅ covered | Full canonical schema strings and navigation labels remain readable and encoded through existing mounted path helpers. Palette recovery destinations actually update after a selector patch, and Back/reload/reconnect restore the validated target without hidden global/session/browser sticky selection. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None; existing owned Phoenix components only | Not applicable; no registry import or dependency added |

## Verification Boundaries for Planning

Static comps are design evidence only. Phase implementation plans must extend the existing selected-schema Playwright proof through Control Room, fleet recovery destinations, updated command-palette links after a patch, and authorization return. Use focused LiveView/component state and rendered-event checks for source-qualified equal IDs, invalid/removed target, retry eligibility, receipt-versus-terminal state, confirmation invalidation and stale-result guards. Use rendered desktop/narrow/intermediate geometry, keyboard/focus, light/dark/System and reduced-motion checks for changed seams. Run mutating browser fixtures in a disposable stack; never reseed the retained feedback preview at `http://127.0.0.1:4012/admin/search`.

Do not claim all matrices green, accept inherited risks, add human UAT as a completion backstop, create a new required CI/paid judge, or extend an exact-SHA receipt from this design contract. OPUX-16–OPUX-19 remain pending until their owned code and executable evidence pass.

## References

- `.planning/phases/174-recovery-entry-and-diagnosis/174-CONTEXT.md` — maintainer-adopted decisions and explicit scope boundaries.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md` and `scrypath_ops/assets/css/DESIGN-TOKENS.md` — delivered tokens, component patterns, visual and time contracts.
- `.planning/reference/OPERATOR-UI-QUALITY.md` and `.planning/reference/OPERATOR-UI-REFINEMENT.md` — operator hierarchy and comp-first review constraints.
- Phoenix LiveView navigation and security model, W3C Focus Order/Reflow/Use of Color/Status Messages, Oban job lifecycle, and Meilisearch async task semantics are linked in `174-CONTEXT.md`; these inform implementation constraints but do not add product policy.

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** UI checker passed all seven dimensions at 2026-10-07T03:01:00Z with no recommendations; its earlier evidence-incomplete response is superseded. At 2026-10-07T03:08:26Z the contract/probe were finalized under the maintainer’s explicit instruction to follow the agent’s recommendations until the implemented UI is ready for review. The maintainer did not inspect/approve the static comps individually. No product implementation or application verification is claimed by this contract.
