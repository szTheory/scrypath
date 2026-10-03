---
phase: "172"
slug: "consistent-operator-ui-and-verified-recovery"
status: approved
reviewed_at: "2026-10-03"
shadcn_initialized: false
preset: none
created: "2026-10-03"
---

# Phase 172 — UI Design Contract

Visual and interaction contract for Consistent Operator UI and Verified Recovery. This is an implementation specification, not runtime acceptance evidence. The independent checker approved all seven dimensions on 2026-10-03; the conventional Cancel dismissal exception is explicit.

## Scope and Authority

Implement OPUX-01–OPUX-08 across the existing Control Room, Posture, Failed Sync, Sync/Drift, Search, and Playbooks surfaces. Preserve their shell, navigation groups, fonts, palette, Phoenix architecture, and public core/host authorization boundaries. Ordinary incident recovery must complete without index promotion.

Sources, in precedence order:

1. `172-CONTEXT.md`: ten locked decisions, including autonomous execution, optional preview feedback, retained failed history, existing-system preservation, and automated acceptance.
2. `.planning/REQUIREMENTS.md` and `.planning/reference/OPERATOR-UI-QUALITY.md`: eight requirements and the standing task-first quality contract.
3. `.planning/research/v1.42/{SUMMARY,UI-STRUCTURE,UI-SYSTEM,UI-AUTOMATION}.md`: existing inventory, source-confirmed findings, measured-evidence limitations, and bounded implementation direction.
4. `scrypath_ops/assets/css/app.css`, `DESIGN-TOKENS.md`, `components/ops_ui.ex`, and `docs/operator-ia.md`: actual values, component behavior, and product vocabulary. Update their authority documentation with implementation changes.

Phase-specific defaults below resolve the remaining role, wording, and composition choices. They do not authorize a generic scale migration. Preserve existing exceptions explicitly identified here; incidental visual hypotheses require a reproduced user impact before becoming additional work. No subjective choice or repeated user approval is pending.

Additional locked user feedback during authoring: Control Room repeats the command-palette shortcut guidance three times. Keep one discoverable shortcut hint beside the actual jump control and remove repeated onboarding/help narration. Review all six surfaces for repeated instructions, obvious explanations, and competing labels; retain guidance only where it changes the operator's decision.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual, existing Phoenix `OpsUi` design system |
| Preset | Not applicable |
| Component library | `ScrypathOpsWeb.OpsUi`, local `scrypath_ops` application; preserve existing vendored daisyUI 5.0.35 beneath shared components |
| Styling | Existing Tailwind v4 and `scrypath_ops/assets/css/app.css`; CSS is the value authority, `DESIGN-TOKENS.md` is its catalog |
| Icon library | Existing Heroicons through the imported `icon` component; no new icon dependency |
| Font | Existing system UI sans; existing `ui-monospace, "Cascadia Code", Menlo, monospace` for technical identifiers; no network fonts |
| Shell | Existing 80rem wide page maximum, 17rem desktop sidebar at 1280px, mobile drawer below; keep established chrome |
| shadcn gate | Not applicable: Phoenix/LiveView application, no `components.json`, no React/Next/Vite migration |
| Source boundary | Baseline reviews refer to `3c83a58c9bc5af70a204957431ff66fd9db035de`; this contract was checked against the current worktree source on 2026-10-03 |

The inherited app guideline against introducing daisyUI does not require removing the established dependency. Extend OpsUi in place. No third-party blocks, package downloads, generated images, new fonts, or framework initialization are needed.

## Component Inventory

Enumerated by `python3 -c 'import pathlib,re; p=pathlib.Path("scrypath_ops"); names=re.findall(r"^  def (ops_\w+)\(", (p/"lib/scrypath_ops_web/components/ops_ui.ex").read_text(), re.M); print("\n".join(names)); print("components:",len(names)); print("scrypath_ops version:", re.search(r"version: \"([^\"]+)\"", (p/"mix.exs").read_text())[1])'` — 48 components — scrypath_ops@0.1.0 — 2026-10-03.

Run from repository root. This is an in-repository Elixir component module, not an installed npm package: `0.1.0` is its exact local application version in `scrypath_ops/mix.exs`, not a dependency range or an inferred upstream version. The command enumerates actual function declarations. The table accounts for all 48 current exports and is a non-exhaustive list of known-good building blocks, never a closed allowlist; check actual source before using another component.

All rows use `ScrypathOpsWeb.OpsUi` from `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`, imported through `ScrypathOpsWeb`.

| Components | Import path | Contract |
|------------|-------------|----------|
| `ops_page_header`, `ops_heading`, `ops_panel`, `ops_toolbar`, `ops_section`, `ops_scaffold` | `ScrypathOpsWeb.OpsUi` | One h1; h2 task sections; h3 record headings; wrapping action rows and token spacing |
| `ops_command_hint`, `ops_trail`, `ops_handoff`, `ops_intent_card`, `ops_command_palette` | Same module | Native navigation; schema-preserving recovery handoffs; palette remains an accelerator |
| `ops_button`, `ops_refresh_button`, `ops_link_button`, `ops_action_group` | Same module | Readable 14px action role; clear primary/secondary/danger hierarchy; busy and disabled semantics |
| `ops_notice`, `ops_status`, `ops_metric`, `ops_metric_grid`, `ops_tone_chip`, `ops_badge`, `ops_verdict`, `ops_workspace_mode_indicator` | Same module | Text accompanies tone; known/unknown and current/historical remain distinct |
| `ops_empty_state`, `ops_empty_hero`, `ops_loading`, `ops_config_empty` | Same module | Setup, empty, loading, and failed reads receive distinct presentations |
| `ops_fieldset`, `ops_field`, `ops_text_input`, `ops_number_input`, `ops_textarea`, `ops_select`, `ops_schema_select`, `ops_segmented_control`, `ops_checkbox_list`, `ops_upload_box` | Same module | Persistent names and descriptions, native disabled state, named selection groups |
| `ops_data_card`, `ops_result_row`, `ops_object_list`, `ops_object_item`, `ops_table`, `ops_signal_table` | Same module | Rich failures use rows/cards; facts use definition lists; comparison data retains tables |
| `ops_time`, `ops_disclosure`, `ops_code_block`, `ops_inline_code` | Same module | Exact identifiers/time accessible; verbose evidence secondary; contained technical scrolling |
| `ops_modal` | Same module | Complete focus lifecycle, named dialog, background inertness, clear mutation consequence |

## Spacing Scale

Retain the existing compact scale. Declared layout values are multiples of 4; do not introduce the template's unused 32/48/64px spacing merely to fill a table.

| Token | Value | Usage |
|-------|-------|-------|
| `ops-1` | 4px | Inline icon/text separation and tight related metadata |
| `ops-2`, `ops-control-gap` | 8px | Related controls and compact reason-count list gaps |
| `ops-3` | 12px | Compact inner blocks and normal control horizontal padding |
| `ops-4`, `ops-row` | 16px | Record/body spacing and narrow panel padding |
| `ops-5`, `ops-panel` | 20px | Default panel padding at 640px and above |
| `ops-6`, `ops-section`, `ops-page-gap` | 24px | Major task sections and page stack |

Phase default: make touched page/section stacks consume their named 24px gap role; use 16px panel padding below 640px and 20px above. Related labels and controls remain compact. This is a bounded component change, not a repository-wide raw-class replacement.

Inherited exceptions: `ops-field` is 6px; compact control horizontal padding is 10px. Preserve those existing component-internal values. Radii, borders, and font line heights are separate dimensions and are not subject to the layout-spacing multiple rule.

| Dimension | Contract |
|-----------|----------|
| Controls | Standard action/input/select min-height 40px; prominent recovery actions and icon-only shell/dialog controls min-height 44px; 44px minimum width for icon-only targets |
| Compact actions | `size=:xs` may retain compact horizontal padding but must not reduce actionable label text below 14px or row action target height below 40px |
| Multiline controls | Textarea min-height 96px; consume shared form radius/type; labels may wrap without fixed-height clipping |
| Radius | Preserve 4px small, 6px control, 8px surface, 12px overlay, fully rounded pills |
| Elevation | Preserve existing `surface`, `mid`, `raised`, `overlay` shadow tokens and dark variants; no decorative escalation |
| Motion | Preserve 90/120/180/200/240ms vocabulary and global reduced-motion behavior; modal exit animation and JS removal use the same 120ms value |
| Layers | Name and document header 30, sidebar 35, skip link 50, flash 60, nav drawer 75, command palette 80, modal 90; change the existing modal token to 90 and consume it so vendored modal 999 cannot bypass the authority |

Only one modal overlay owns focus at a time. A file dialog closes an open drawer/palette before opening and suppresses their shortcuts while active. Restore focus correctly on close. Do not lower the dialog beneath a still-active command palette.

## Typography

Four primary task sizes, two weights: 14, 16, 18, 24px and 400/600. Use rem values at the normal 16px root. These are role assignments onto the established scale, not a global restyling of every metadata node.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body, instructions, actionable reason, help/error needed for a decision | `text-ops-body`, 14px | 400 | 1.5 |
| Action and form label | `text-ops-body`, 14px | 600 | 1.5 |
| Input value | `text-ops-body`, 14px | 400 | 1.5 |
| Card/subsection heading | `text-ops-h3`, 16px | 600 | 1.3 |
| Section heading | `text-ops-h2`, 18px | 600 | 1.3 |
| Page heading | `text-ops-h1`, 24px | 600 | 1.3 |

Inherited metadata exceptions: existing 11px/12px tokens remain available for short timestamps, badges, eyebrows, and optional technical metadata. Existing metric/brand treatments are preserved unless a named finding requires repair. Do not use these exceptions for buttons, form labels, failure reasons, blocked-action explanations, or the only available copy of a required instruction. Essential schema/index identifiers use 14px monospace; secondary full-module metadata may retain 12px with access to the exact value. Touched primary role consumers use 400/600; there is no whole-system sweep of existing 500/650/700 metric/brand treatments.

Fix the shared button's vendor 12/11px defaults centrally, including compact retry/file actions. Correct touched result-row and schema-card h3s to the 16px heading role. Do not shrink type to fit a grid. Native inputs must remain usable under browser text scaling.

## Color

Preserve the existing light/dark themes. The 60/30/10 allocation is a composition guide, not a pixel quota or a request to recolor the console.

| Role | Light / dark value | Usage |
|------|--------------------|-------|
| Dominant (60%) | `--ops-bg`: `#faf7f2` / `#0c0f14` | Page and major neutral canvas |
| Secondary (30%) | `--ops-surface-1`: `#fffdf8` / `#141923`; raised dark `#1b2230` | Resting cards, sidebar, grouped controls; existing surface ladder |
| Accent (10% ceiling) | Primary `#5b4ad1` / `#6c5ce7`; selected fill `#5b4ad1` | Primary local action, selected schema/mode/theme, active route, focus indicator, running state where already defined |
| Body text | `--color-base-content`: `#141923` / `#f4f1ea` | Readable primary text; preserve existing muted token with measured contrast |
| Destructive/error | `#d96262` with existing semantic surfaces/content | Destructive confirm emphasis and actual error status; always name the action/problem |
| Status | Info `#5ca9e6`, success `#4fae74`, warning `#d9a441` | Existing labeled state accents; never bare color as the only meaning |
| Copper | `#a85d2e` / `#c17a3e` | Preserve existing restrained brand eyebrow/file-type/key-node sites; never assign status or a false federation claim |

Accent reserved for the explicitly named sites above. Ghost actions and ordinary body text remain neutral. Preserve the historical copper restraint within the existing composition; do not introduce an additional 10% color field. Remove the Control Room “Federated” badge when its only condition is fleet degradation.

Status color must not lower the text contrast of conditional tone-chip values or blocked/preflight explanations. Use base-content on tinted surfaces when raw status-colored small text fails the existing contrast requirement. Disabled action opacity must not dim the reason explaining how to proceed. Apply every changed semantic override to explicit dark and system-dark paths. Extend the existing contrast manifest for changed pairs.

## Composition and Flow Contract

| Surface | Required order and primary task | Bounded changes |
|---------|---------------------------------|-----------------|
| Control Room | Heading and refresh; scoped search-health verdict with checked time; existing Recover/Change/Explore intent cards | Preserve proven desktop composition; cause-accurate degraded copy; recovery enters Posture; one shortcut hint beside the jump control, no repeated shortcut guidance |
| Posture | Fleet observation; concise next action; worst-first schema cards containing backend/queue facts | Each affected schema exposes `Inspect failed work` with its schema parameter; avoid duplicated verdict prose; inline/manual queue absence is neutral |
| Failed Sync | Heading/refresh; schema; one total/retryable summary; compact reason counts; failed-work rows; optional technical guidance; sync handoff | Replace six stacked mobile metric cards with a wrapping count list; row cause, source, operation, and recovery availability are visible before opening Diagnostics |
| Sync/Drift | Heading/schema; current recovery/sync observation and refresh; explicit contract check; return to search health; advanced promotion below | Ordinary verification is the leading task; move API/path references into secondary help; no promotion wizard above incident checks; setup guard when required runtime is absent |
| Search | Mode and target selection; query/limit; Run search; scoped/partial results; optional save and diagnostics | Preserve current flow; semantic disabled controls, associated labels/help, meaningful mode selection; common controls remain visible |
| Playbooks | Workspace authority; catalog and visible preview/run actions; import; selected draft/preview/run/result/save | Preserve scope and current useful actions; readable file controls, labeled upload/paste, full dialog lifecycle; draft versus saved copy follows actual persistence |

Use sentence-case visible names consistently: `Control Room`, `Posture`, `Failed sync work`, `Sync and drift`, `Search`, `Playbooks`. Existing route paths remain unchanged. Use “Queue job” for Oban and “Backend task” for Meilisearch, “Filename” for a stored JSON basename, and “Last success” instead of “Last OK”. Contract match describes settings/declared fields only; it never establishes document freshness.

Schema context is URL state validated against the current allowlist. Posture's per-schema action, Failed Sync selection, and Sync/Drift handoff use the same canonical schema string. Browser refresh/back restores it. Validate without converting arbitrary input to atoms. A missing query may select the documented first schema; an invalid or removed explicit query shows the invalid-selection message and requires a valid selection before any mutation. Never silently act on the first schema after rejecting an explicit selection. Reset cached checks and in-flight association when selection changes; late results cannot overwrite another schema's view.

Failure rows remain rich records, not an all-purpose table. Show a concise readable reason and a visible `Retry sync work` action when replay is supported. The visible reason/source/operation constitutes the required pre-action context; raw payload stays in `Diagnostics`. Unsupported recovery shows the reason and no enabled retry. For delete work, require the confirmation below with affected IDs/count and scope; do not add an extra confirm to ordinary replayable upsert retries.

At 390px with the existing two-schema/six-reason fixture, the reason-count summary consumes at most 160px excluding the schema selector and page header. Technical help is below the first work row or collapsed. Keep the existing desktop summary density where useful. At 320px and 390px, no page-wide horizontal scroll is allowed; action groups wrap, identifiers use `overflow-wrap:anywhere`, and full names remain available. Raw JSON may scroll inside a labeled bounded region. One long identifier must not impose the width of the page.

Keep one primary action per local task. An initial contract check offers `Check index contract`; once loaded it offers `Refresh contract check` in the same place, without a duplicate CTA in the empty panel. The ordinary flow ends with `Recheck search health` linking to Control Room; retained failures or unknown observations remain visible. Advanced promotion may be disclosed separately but its availability reason stays readable when opened.

## Control and Accessibility Contract

| Control | Required behavior |
|---------|-------------------|
| Fields | Visible label linked by `for`/`id`; help and errors have stable IDs included in `aria-describedby`; invalid input exposes `aria-invalid` and retains the entered value |
| Schema picker | Up to four choices preserve native labeled radios and fieldset legend; more than four uses a native select with an explicit `Schema` label; selected/disabled state is semantic |
| Search mode | Named group `Search mode`; native buttons with one `aria-pressed=true`; normal Tab and Space/Enter behavior; no tablist role without its full keyboard model |
| Missing runtime | Native disabled fieldset/controls plus visible setup reason; CSS opacity/pointer-events alone is insufficient; server guard remains |
| Submit/refresh/retry | Native button; busy copy and `aria-busy` on affected region; disabled duplicate submission while its request is active; accepted work is displayed durably near its object |
| Upload/paste | Label the file input `Import playbook file` and textarea `Playbook JSON`; associate format/size/validation help; placeholder is supplemental |
| Dialog | Named `role=dialog`, `aria-modal=true`, title/description IDs; focus enters, Tab and Shift-Tab wrap, Escape/Cancel close, background is inert, focus returns to triggering control |
| Dialog defaults | Rename focuses Filename; Duplicate focuses new Filename; Delete/retry-delete focuses Cancel. On successful delete, focus the next row's primary action or catalog heading if no rows remain |
| Navigation | Links navigate and buttons act; active destination has `aria-current`; shell skip link and visible navigation remain available; command palette is optional |
| Status/errors | Nonurgent asynchronous status uses a polite live region; rejected mutation/load error is announced once; no repeated announcements on every poll; technical diagnostics remain inspectable |
| Focus | Preserve visible 2px primary outline with 2px offset; no clipping behind sticky chrome or inside overflow regions; keyboard access does not require hover |

Preserve native semantics over custom ARIA substitutes. If multiple overlays could open, the shared dialog lifecycle is the authority, including focus return after LiveView patches. Keyboard tests must cycle through every focusable element in both directions, not assert only one Tab step.

## Recovery and Promotion State Contract

Recovery observations are scoped to the selected schema, actual index, source failure, and newly accepted work. IDs are operational evidence, never inferred from “latest successful task” alone. No new public core API or persistent recovery-history product is required; use existing work/task APIs and bounded UI-owned correlation. If a boundary cannot establish correlation, expose unknown instead of claiming success.

| State | Visible truth and next action |
|-------|-------------------------------|
| Ready to retry | Original failure reason/source/operation visible; supported Retry action; unsupported case explains missing replay input/authority |
| Submitting | `Requesting retry…`; prevent duplicate request for this record |
| Accepted | `Retry accepted`; show new queue job/backend task reference, original failure reference, and affected schema/index; completion remains unverified |
| Running | `Recovery in progress`; show observed new-work status and checked time; keep diagnostics and refresh available |
| Queue completed only | `Queue job completed; backend verification pending`; this is not final recovery |
| Verified | `Recovery verified` only with correlated terminal backend success and expected document/value in the selected active index; original failed history remains labeled |
| Failed | `Recovery failed`; retain new-work reference and cause; expose the next supported inspection/retry action |
| Timed out | `Recovery check timed out`; keep reference and `Refresh recovery status`; timeout does not cancel or prove failure of remote work |
| Unknown/stale | `Recovery not verified` or `Previous check is stale`; retain last checked time and known evidence, disable any success-dependent action, offer refresh |

Changing schema, starting a mutation, failing a check refresh, or disconnecting invalidates the corresponding current-success claim. Previous data may remain readable as an explicitly dated stale snapshot. Reconnection/refresh must reobserve task truth; no success reconstructed solely from a URL parameter or prior flash. A polling deadline yields timed out; retrying observation must not submit another mutation.

Advanced `Swap indexes` is a separate consequential action. One UI/server predicate must require: allowed schema and configured supported backend; identified distinct live/target indexes; successful current reconcile and contract reports for that same schema/index; no latest check error or in-flight check; zero contract mismatches; no pending backend, queue/retrying, reindex, or cutover work; available target observation without failed target work; no unresolved failed-work signal. With existing reports alone, a failed-work signal blocks advanced promotion until it can be explained by reliable scoped evidence. This conservative promotion gate does not prevent ordinary recovery from being verified while historical failures remain.

Current means both checks belong to the selected context and were obtained after its last relevant mutation/invalidation. Re-fetch authoritative prerequisites in the server handler immediately before calling swap; reject forged direct events and changed prerequisites. Do not introduce an arbitrary time-to-live as proof of freshness. Preserve the existing sensitive-action authorization/audit gate. Missing/unknown prerequisite evidence fails closed with its reason. These checks establish bounded eligibility, not complete target-document correctness.

The swap confirmation names schema, live index, target index, and effect. After submission, display `Index swap accepted` with the returned task ID; observe that exact task until terminal state. Only terminal success displays `Index swap completed`. Failure and timeout retain the task ID and next refresh action. Any active-index visibility claim additionally requires the expected scoped content; an older swap task or an already-present generic product cannot prove the new operation.

## Copywriting Contract

The copy below defines consistent decision-bearing phrases. Tests should protect truthful state and semantic names without freezing whole explanatory paragraphs. Interpolated names/IDs are escaped and retain access to their complete value.

Existing-system exception for secondary dismissal: retain the conventional visible `Cancel` label to preserve familiar dialog behavior and the user's principle-of-least-surprise direction. Give each button the contextual accessible name specified below through `aria-label`; each accessible name includes the visible word `Cancel`. The named dialog supplies visible action/object context. This exception applies only to dismissal: primary and destructive actions retain explicit verb–object labels. Cancel closes the dialog without applying its mutation and returns focus as specified above.

| Element | Copy |
|---------|------|
| Primary recovery CTA | `Retry sync work` |
| Retry pending | `Requesting retry…` |
| Posture schema action | `Inspect failed work` |
| Failed Sync refresh | `Refresh failed work` |
| Recovery handoff | `Check sync status` |
| Sync refresh | `Refresh sync status` |
| Contract check / refresh | `Check index contract` / `Refresh contract check` |
| Ordinary completion handoff | `Recheck search health` |
| Failure empty heading | `No failed sync work` |
| Failure empty body | `No failed work was returned for {schema}. Check sync status for current queue and backend activity.` |
| Setup: no schemas | `No schemas configured` — `Add a schema to the operator allowlist, then refresh this page.` |
| Setup: no backend | `Search backend is not configured` — `Configure the host search backend, then refresh this page.` |
| Invalid schema | `That schema is unavailable. Select an allowed schema to continue.` |
| Failed load | `Could not load failed work for {schema}. Refresh failed work to try again.` |
| Failed sync check | `Could not check sync status for {schema}. Refresh sync status to try again.` |
| Contract not run | `Index contract has not been checked. Check it to compare declared settings with the live index.` |
| Contract failed | `Could not check the index contract. Check the backend connection, then refresh the contract check.` |
| Contract clean | `Index contract matches` — `Declared settings match this check. This does not verify document freshness.` |
| Partial observation | `Some observations are unavailable. Review the affected source and refresh its check.` |
| Queue not used | `Queue not used in {inline/manual} mode` |
| Queue unknown | `No queue observations available` |
| Retry accepted | `Retry accepted` — `New work was created for {schema}. Backend completion is not yet verified.` |
| Retry rejected | `Retry was not accepted. {reason}. Review the failed work before trying again.` |
| Unsupported retry | `Retry unavailable: {reason}.` |
| Recovery verified | `Recovery verified` — `The new backend work succeeded and the expected document is visible in {index}.` |
| Retained history | `Original failure retained as history` — `A successful retry does not remove the original failed record.` |
| Recovery failed | `Recovery failed. Review the new work and its failure reason before retrying.` |
| Timeout | `Recovery check timed out. The work may still be running. Refresh recovery status to check again.` |
| Stale check | `Previous check is stale. Refresh this check before relying on its result.` |
| Advanced section | `Advanced: index promotion` |
| Swap unavailable | `Index swap unavailable: {specific prerequisite reason}.` |
| Swap confirmation | `Swap indexes for {schema}?` — `Swap live index {live} with target index {target}. Search will use the target contents after the backend task succeeds.`; buttons `Cancel` (accessible name `Cancel index swap`) / `Swap indexes` |
| Swap accepted / terminal | `Index swap accepted` / `Index swap completed` / `Index swap failed` / `Index swap check timed out` |
| Delete retry confirmation | `Retry deletion for {schema}?` — `Retry deletion of {count} document(s) from {index}. Review the document IDs before continuing.`; display IDs; buttons `Cancel` (accessible name `Cancel deletion retry`) / `Retry deletion`; render proper singular/plural |
| Playbook deletion | `Delete {filename}?` — `This removes the saved playbook from this workspace. This cannot be undone here.`; buttons `Cancel` (accessible name `Cancel playbook deletion`) / `Delete playbook` |
| Playbook rename | `Rename playbook`; label `Filename`; buttons `Cancel` (accessible name `Cancel playbook rename`) / `Rename playbook`; validation retains input and explains supported naming rules |
| Playbook duplication | `Duplicate playbook`; label `Filename`; buttons `Cancel` (accessible name `Cancel playbook duplication`) / `Duplicate playbook` |
| Search run / empty | `Run search`; `No matching documents` — `Try another query or check the selected index.` |
| Search partial | `Some indexes could not be searched. Results from available indexes are shown below.` |
| Playbook empty | `No saved playbooks` — `Import a playbook or save a search to create one.` |
| Draft run | `Run playbook` for an unsaved draft; reserve `Run saved playbook` for a persisted selection |
| File input / paste | `Import playbook file` / `Playbook JSON` |
| Secondary evidence | `Diagnostics` and `Operator reference` |
| Command palette hint | One `⌘K`/platform-appropriate `Ctrl+K` keycap beside the actual jump control; accessible control name `Jump to surface`; remove duplicated “Jump fast” and “Press … to jump” sentences elsewhere |

Use singular/plural counts rather than literal “job(s)” or “dimension(s)”. Raw backend errors remain available in Diagnostics after the readable problem and next action. No error flash may announce completed work solely because a request was accepted. Across all six surfaces, remove repeated instructions, narration of obvious controls, and alternate labels for the same action; place each useful explanation once at the relevant decision. A shared shell hint and a page-local duplicate still count as repetition.

## UI Considerations

Post-checker compiled probe run 2026-10-03. Agent-authored kinds cover E1 shell/handoffs, E2 fleet/schema cards, E3 failed work, E4 sync/recovery/promotion, E5 Search, E6 Playbooks, and E7 dialogs. No media is introduced. These are implementation acceptance truths, not runtime pass claims. Every applicable element/category pair is represented below; detailed local report: `/private/tmp/scrypath-v142-review/ui-probe.json`.

| Category | Elements | Status | Verification | Acceptance truth |
| --- | --- | --- | --- | --- |
| empty | E2, E3, E4, E5, E6, E7 | resolved | explicit | Empty collections use their named Copywriting Contract state; missing schema/backend configuration uses a setup state and native disabled controls, never a healthy empty result. |
| loading | E1, E2, E3, E4, E5, E6, E7 | resolved | explicit | Pending navigation, checks and mutations retain current context and input, show scoped pending state, prevent duplicate mutation submission, and discard results from superseded contexts. |
| error | E1, E2, E3, E4, E5, E6, E7 | resolved | explicit | A failed read or mutation names its affected object and next supported action; prior observations become visibly stale; failed navigation retains usable route controls and the selected context. |
| populated | E2, E3, E4, E5, E6 | resolved | explicit | Populated cards and rows expose object identity, scoped state and the common action; failure reason/source/operation remain visible without opening Diagnostics. |
| partial | E2, E3, E4, E5, E6, E7 | resolved | explicit | Available observations/results remain visible beside named unavailable sources; no queue use differs from unknown queue state; incomplete job/task/document correlation cannot claim recovery verified. |
| overflow | E1, E2, E3, E4, E5, E6, E7 | resolved | explicit | At 320px and 390px there is no page-wide horizontal scroll; identifiers wrap, action groups wrap and raw JSON scrolls only inside a labeled bounded region. |
| zero-one-many | E2, E3, E4, E5, E6 | resolved | explicit | Zero items use an empty state, one item uses singular copy, many items preserve usable order/scrolling; both radio and greater-than-four schema select branches are checked; six-reason summary is at most 160px at 390px. |
| long-text | E1, E2, E3, E4, E5, E6, E7 | resolved | explicit | Long field labels, filenames, schema/index identifiers, errors and navigation labels remain fully accessible through wrapping or a labeled contained region without reducing actionable text below 14px. |

## Automated Acceptance and Evidence

These checks are required implementation outcomes, not checks run by this specification task. Reuse the existing test harnesses and CI lanes; do not add a paid judge or a new required CI job. Pair each assertion with source SHA, state, theme, viewport, and relevant work IDs.

| Contract / requirements | Measurable acceptance | Existing lane |
|-------------------------|-----------------------|---------------|
| Roles and catalog; OPUX-01 | All 48 components accounted for; touched roles resolve to named tokens; representative body/action labels compute to 14px, h3 to 16px, standard controls at least 40px; metadata exceptions are scoped | Token contracts plus representative browser styles; update token/component docs |
| Layout; OPUX-01/03 | `documentElement.scrollWidth <= clientWidth + 1` at 320/390/1440px; essential controls are unclipped/reachable; six-reason summary at 390px is no taller than 160px; long schema/index/file/reason content remains accessible | Existing browser harness with small reusable geometry helper |
| Native controls; OPUX-02 | Radio/select branches, selected mode, help/error associations, native disabled Search, labeled upload/paste; mutation server guards remain enforced | Component/LiveView tests in `mix verify.ops_ui` |
| Concise guidance; OPUX-03 | Each rendered surface exposes one shortcut hint beside the actual jump control, without duplicate shortcut onboarding prose; six-surface copy review records removed repeated instructions and competing action labels | Shared render/IA assertion plus direct screenshot/copy inspection |
| Dialogs; OPUX-02 | Every focusable control cycles in both directions; Escape/Cancel restore trigger; background and global overlay shortcuts cannot steal focus; delete restores a valid successor target | Existing shell browser tests, one representative file action plus focused component cases |
| Schema context; OPUX-04 | Non-first failing schema survives rendered Posture → Failed Sync → Sync/Drift controls, selection changes, refresh/back; invalid/removed explicit schema cannot cause a mutation on another schema | LiveView and mounted browser journey |
| Truthful states; OPUX-05 | Accepted, running, queue-only completion, backend failure, timeout, stale/unknown, and terminal success are distinct; failed refresh cannot retain a current ready verdict; direct ineligible swap event is rejected | Focused LiveView service-boundary cases |
| Real recovery; OPUX-06 | Unique replayable failure using actual configured schema/backend/index; record pre-action IDs and expected changed document; require new accepted job/task identity, terminal correlated backend success, exact run-specific document/value in active index, and honest visible result with original failure retained | Extend `e2e/operator.spec.ts` in existing required `ecommerce-mounted` lane |
| Advanced swap; OPUX-05/07 | Eligible UI and server share predicate; current revalidation rejects changed prerequisites; accepted swap cannot show completed; if browser swap runs, require exact new task/index pair and unique target content | LiveView plus strengthened existing swap scenario, separate from ordinary recovery |
| Themes/contrast; OPUX-07 | Changed text pairs meet existing 4.5:1 text and 3:1 applicable UI/large-text thresholds; loaded tone values and blocked reasons covered; explicit light/dark and system-dark cascade checked | Existing fast contrast manifest and bounded browser contrast states; AAA advisory |
| Screenshots/finish; OPUX-07/08 | Before/after captures directly inspected; findings resolved or bounded with revisit trigger; actual tests and traceability recorded; no unrun matrix/mock-judge pass presented as approval | Existing advisory screenshots/full lane and final phase evidence |

Minimum representative browser coverage: real journey at 1440px explicit dark and meaningful narrow controls at 390px explicit light; a 320px long-content/reflow spot check; one intermediate width where changed shared grids encounter sidebar/column boundaries; opposite-theme healthy/empty state; one system-dark shared-style smoke. Use deterministic LiveView cases for remaining state boundaries instead of a full Cartesian browser matrix. Add a focused non-contrast accessibility scan for changed journey states; the existing contrast-only scan is not a general accessibility pass.

Use actual state polling, not arbitrary sleeps. The browser follows rendered links/actions between incident surfaces; direct route visits are reserved for URL restoration/error tests. Existing historical failure fixtures and generic successful-task probes are inadequate recovery proof. Test setup must fail closed, use a unique marker and real resolved index, and isolate old tasks/documents. Do not require zero aggregate failed history or every dashboard indicator to turn green.

Screenshots in `/private/tmp/scrypath-v142-review/` are the visual starting point. This author directly inspected `failed-sync-light-mobile.png` and `sync-drift-light-mobile.png`: stacked summary/preflight content delays actionable rows/checks. Captures establish hierarchy findings, not contrast or runtime correctness. Match seed/theme/viewport/assets in after captures and record actual source identity. The screenshot inventory checker proves filenames/width, not pixel parity.

Run seeded/reset automation only in a disposable Compose project. Preserve the optional feedback preview at `http://127.0.0.1:4012/admin/search` (`scrypath-ui-v142`). Keep `OPS_UI_LLM_JUDGE=0` and `OPS_UI_LLM_JUDGE_REQUIRED=0`. Required checks, reviewed PR delivery, final tracking before exact-source attestation, release/no-release rationale, and task-owned cleanup remain governed by CONTRIBUTING and the phase plan. No routine human UAT is deferred.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | Existing local Phoenix components only | Not applicable — no shadcn/third-party registry inclusion; source inventory inspected 2026-10-03 |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** approved 2026-10-03 by the independent UI checker, following one targeted copy revision.
