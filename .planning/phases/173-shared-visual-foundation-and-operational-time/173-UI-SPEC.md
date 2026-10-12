---
phase: "173"
slug: "shared-visual-foundation-and-operational-time"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-06"
reviewed_at: "2026-10-06T18:16:12Z"
---

# Phase 173 — UI Design Contract

This contract covers OPUX-09–OPUX-15 in v1.43. It selects shared visual treatments before implementation planning. Requirements remain pending; the static comps do not verify application behavior. CONTEXT.md decisions D-01–D-22 govern. No new framework, dependency, surface, health classification, authorization rule, or recovery flow is introduced.

## Design System

| Property | Value |
| --- | --- |
| Tool | Manual, existing ScrypathOps token/component system |
| Preset | Not applicable; Phoenix HEEx, not a React/shadcn application |
| Component library | Existing OpsUi/CoreComponents and daisyUI/Tailwind v4 |
| Icon library | Existing Heroicons through CoreComponents.icon; preserve Scrypath wordmarks |
| Font | system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif |
| Technical font | ui-monospace, Cascadia Code, Menlo, monospace |
| Authority | app.css tokens and OpsUi functions; update DESIGN-TOKENS.md alongside delivered implementation |

Keep existing imports, native buttons/details, LiveView hooks, pre-paint theme initialization, and standalone/mounted asset delivery. The stale Impeccable sidecar is a separate, nonblocking maintenance item. The researcher applied Impeccable Operate guidance using PRODUCT.md and DESIGN.md; their concrete revision direction supersedes exploratory brand-book hex values.

## Component Inventory

Enumerated by `rg -n '^  def [a-z_]+\(assigns\)' scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — 49 components — scrypath_ops@0.1.0 — 2026-10-06.

Provenance: mix.exs supplies the local package version; mix.lock resolves Phoenix 1.8.12 and LiveView 1.1.33. Source base is 52e5ebe526f33a61314b5d7f5eb6ba2083890a4b plus preserved local edits. This table is a non-exhaustive list of relevant, source-enumerated components, never a closed allowlist.

| Components | Import path | Phase use |
| --- | --- | --- |
| ops_page_header, ops_heading, ops_section, ops_toolbar, ops_panel | ScrypathOpsWeb.OpsUi | Preserve established hierarchy and spacing |
| ops_verdict, ops_status, ops_tone_chip, ops_badge | ScrypathOpsWeb.OpsUi | Local label/icon semantics on neutral surfaces |
| ops_metric, ops_metric_grid | ScrypathOpsWeb.OpsUi | Neutral zero counts, explicit unavailable evidence |
| ops_button, ops_link_button, ops_action_group | ScrypathOpsWeb.OpsUi | Shared quiet hover/pressed/focus/disabled/busy behavior |
| ops_refresh_button, ops_refresh_control | ScrypathOpsWeb.OpsUi | Keep icon and label; routine Checked metadata has no copy control |
| ops_time, ops_disclosure, ops_inline_code | ScrypathOpsWeb.OpsUi | Snapshot-relative age, selectable exact timestamp, native disclosure |
| ops_config_empty, ops_empty_state, ops_loading, ops_notice | ScrypathOpsWeb.OpsUi | Existing guards and truthful loading/error/empty feedback |
| ops_trail, ops_command_palette | ScrypathOpsWeb.OpsUi | Preserve current navigation and keyboard access |

Layout ownership stays in layouts.ex/root.html.heex. Refresh and toast lifecycle stay in assets/js/ops_hooks.js. Both assets/js/app.js and the mounted ecommerce app.js must consume the same truthful clipboard outcome contract.

## Comp Comparison and Selection

The chosen treatment is **warm-neutral light with neutral dark**. This is a delegated design decision under CONTEXT.md D-03–D-06 and Agent's Discretion, not a simulated maintainer review. Comparing identical content/geometry in warm and cooler variants showed no material scanning benefit from the cooler version. Warm light maintains identity continuity without a yellow/beige wash; neutral dark avoids the cooler candidate's blue cast. Violet stays localized to interaction; copper appears only in the existing logo detail.

Artifacts in this directory:

- 173-comps.html: warm/cool × light/dark source, representative degraded Search health and explicitly labeled review-only action, clipboard, and time specimens.
- 173-{warm,cool}-{light,dark}-{1440,390}.png: eight full-page comparisons.
- 173-warm-{light,dark}-{1279,1280}.png: four captures around the existing rail breakpoint.
- render-comps.cjs and 173-comp-evidence.json: reproducible render command and measured geometry/contrast evidence.

Render command from repository root: `node .planning/phases/173-shared-visual-foundation-and-operational-time/render-comps.cjs`. It uses installed Playwright, inlines two known logo assets, loads generated HTML in memory, blocks network requests, and writes only phase artifacts. The sandbox denied Chromium bootstrap; the maintainer explicitly authorized a scoped launch approval, which succeeded. No application or retained preview data was changed.

The orchestrator inspected desktop warm/cool and mobile warm screenshots in both themes. All 12 captures have no horizontal document overflow, no broken images, exactly one System preference selected, and no AA failures among measured text pairs. This is **static design evidence only**: buttons and specimen messages illustrate intended states, not functional theme, clipboard, drawer, or LiveView verification.

The shell rail remains 17rem from 1280px; narrower layouts retain the incumbent drawer/header pattern. Screenshot specimens are outside product scope: do not ship their review captions, multiple simultaneous toast outcomes, repeated action buttons, or illustrative fixture data. Preserve actual page copy and all schema rows; the comp is an illustrative excerpt, not a new data/row-count contract. A missing eyebrow or illustrative icon glyph does not authorize removing the actual shell affordance or replacing Heroicons.

## Visual Hierarchy

The primary anchor is the plain-language Search health state and reason. Next come relevant counts, affected schema, Backend tasks / Queue jobs, then the safe existing destination. Unknown observations and retained failures stay explicit. A last success and zero errors never establish current document freshness.

Use one neutral surface per meaningful existing grouping; no extra wrapper panel, nested diagnostic cards, whole-schema yellow borders, green zero-error outlines, or new elevation to compensate for removing semantic decoration. Headings, 24px section rhythm, proximity, and quiet tonal steps provide grouping. Preserve full schema/index/task identifiers; narrow layouts wrap them. Do not shrink required instructions or failure reasons into metadata.

## Spacing Scale

| Existing role | Value | Usage |
| --- | --- | --- |
| ops-1 | 4px | Tight inline grouping |
| ops-2 / control-gap | 8px | Adjacent controls and compact facts |
| ops-3 | 12px | Existing grouped controls and headings |
| ops-4 / row | 16px | Rows and narrow panel padding |
| ops-5 / panel | 20px | Existing desktop panel padding |
| ops-6 / section / page-gap | 24px | Sections and schema records |

Locked-system exceptions: CONTEXT.md D-06 preserves the incumbent 12px and 20px steps rather than replacing them with a generic seven-step template. The existing 6px field gap and compact control internals are inherited outside the changed layout; do not introduce new spacing values. Border widths and focus outlines are not layout spacing. Standard actions remain 40px; prominent/icon-only/theme targets remain 44px. Corners remain 4/6/8px, with 12px for overlays. Use named existing tokens/components, not stacked corrective overrides. Remove superseded gradients/status rules at their authority.

## Typography

The **four primary type roles** remain the incumbent hierarchy; no new font size or weight is introduced.

| Primary role | Size | Weight | Line height |
| --- | --- | --- | --- |
| Body/actions/failure reasons | 14px | 400 body, 600 action | 1.5 |
| Schema/subsection heading | 16px | 600 | 1.3 |
| Section/verdict heading | 18px | 600 | 1.3 |
| Page title | 24px | 600 | 1.3 |

**Locked inherited exceptions:** optional metadata/exact technical context uses the existing 11px/12px roles; incumbent nav-group typography is preserved. CONTEXT.md D-06 explicitly keeps the established font/component system. These are recorded exceptions to the generic four-size checker heuristic, not permission to add more roles or apply tiny sizing to essential copy. Preserve readable existing targets and fonts. Monospace is for identifiers/exact evidence; failure reasons, explanatory instructions, and action labels use the body family. Operational age text should remain readable at body size rather than become dense secondary evidence.

## Color

The compositional target is **60% dominant neutral page, 30% secondary neutral surfaces, up to 10% interaction accent**. This is a hierarchy budget, not a minimum amount of violet to paint. Resting summary/schema/metric backgrounds and outlines are neutral in every theme and responsive path.

| Role / token intent | Light | Dark | Usage |
| --- | --- | --- | --- |
| Dominant / ops-bg | #f7f6f3 | #111419 | Flat page/shell floor; background-image none |
| Secondary / ops-surface-1 | #ffffff | #191e25 | Resting panels, header, rail, metrics |
| Secondary / ops-surface-2 | #efeee9 | #222831 | Neutral quiet hover, restrained tonal grouping |
| Quiet border | #d9d8d2 | #353d48 | Resting separation; not the sole focus/selection cue |
| Primary text | #202124 | #f1f2f4 | Required content |
| Muted text | #55585e | #bec3ca | Readable metadata/supporting facts |
| Interaction text / focus | #5b4ad1 | #aaa0ff | Links, current navigation, copy action, focus |
| Selected soft fill | #eeebff | #302b4c | Current navigation with matching interaction text |
| Warning local text/icon | #805000 | #f2c66d | Degraded/pending attention with explicit labels |
| Failure/destructive local text/icon | #ad2922 | #ffaaa2 | Observed failures and existing danger roles |

Accent reserved for: primary committing actions, current destination/selection, actual links including Copy timestamp, and independent keyboard focus. Quiet hover/press does not acquire primary/selected violet styling. Copper remains only a small identity detail; neither brand color communicates operational state. Do not turn a successful timestamp copy into a green health signal. Existing info/success overlay tokens may remain outside these changed roles, with their contrast independently preserved.

Measured selected warm pairs on resting surfaces:

| Pair | Light ratio | Dark ratio |
| --- | --- | --- |
| Primary text | 16.10:1 | 14.95:1 |
| Muted text | 7.13:1 | 9.45:1 |
| Interaction/focus color | 6.28:1 | 7.32:1 |
| Warning text | 6.85:1 | 10.43:1 |
| Failure text | 6.74:1 | 9.19:1 |
| Selected navigation text / soft fill | 5.37:1 | 5.83:1 |

Implementation must check all actual composed pairs, including primary filled controls, raised/pressed surfaces, alpha-disabled states, focus boundaries, overlays, and System OS paths; the comp sample is not a whole-app contrast audit. Text floor is 4.5:1; essential non-text state/focus cues use 3:1. Do not make resting decorative borders darker just to manufacture a status signal. Preserve functional scroll-edge cues while removing decorative shell gradients.

## Theme Preference Contract

Keep the existing native button group with visible **System / Light / Dark** labels and stable accessible names. Tab visits native buttons; Space/Enter activates them. Do not introduce a custom radio/roving-keyboard model.

Exactly one visual backing/selection and aria-pressed=true follow **preference**. With System selected, effective appearance follows OS changes without selecting Light or Dark. If the old backing/pill remains, it follows preference only. Selected preference, effective appearance, and keyboard focus are distinct states.

Preserve pre-paint appearance, reload, navigation/LiveView patch resynchronization and same-origin cross-tab storage updates. Guard storage reads/writes; invalid stored values resolve to System. If storage is denied/unavailable, the current page retains a working in-memory preference. Do not promise reload/cross-tab persistence under unavailable storage. Narrow layouts reflow rather than hide labels or reduce targets. Existing drawer, palette, breadcrumbs, host mounting, and focus-return behavior remain intact.

## Shared Quiet Action Contract

| State | Concrete treatment |
| --- | --- |
| Resting | Neutral text; transparent or current neutral surface; consistent 40px action target |
| Hover | ops-surface-2 neutral fill; no selection/accent fill |
| Pressed | Stronger neutral mix (12% primary text into raised surface); transient while pressed |
| Focus | Separate 2px interaction-colored outline with 2px offset; visible even on hover/press/selection |
| Selected | Persistent existing explicit selected state only; never inferred from hovering |
| Disabled | Native disabled semantics plus readable eligibility explanation; no actionable hover/press response |
| Busy | aria-busy plus existing busy lifecycle; retain meaningful icon and label without nested-content replacement |

Do not override server-driven eligibility on hook completion/patching. Reuse the shared refresh preservation hook; do not make copies of the pattern per page. Keep existing reduced-motion handling; add no decorative motion. Verify state changes with motion reduced. Explanations remain visible and readable even when controls are unavailable.

## Operational Time and Exact Evidence

Source meaning verified in lib/scrypath/operator/state.ex and status.ex: backend completion time comes from **finishedAt**; queue completion time comes from **completed_at**. last_succeeded is the latest completed state in the inspected history, not proof of a currently fresh document or a newly observed completion. No new health rule is implied by presentation.

Compute age against the **successful observation snapshot associated with that retained evidence**. A theme change, unrelated LiveView patch, clipboard action, or failed refresh must not advance the reference. Keep the previous snapshot on a failed check, disclose unavailable/stale observation, and preserve failure history. There is no ticking clock or browser-time fallback.

| Age from snapshot | Human text |
| --- | --- |
| Less than 60 seconds, not future | just now |
| 60–3599 seconds | Whole minutes ago, singular/plural correct |
| 3600–86399 seconds | Whole hours ago, singular/plural correct |
| 86400–604799 seconds | Whole days ago, singular/plural correct |
| 604800 seconds or older | Human-readable absolute date/time with UTC stated |
| Source instant after snapshot | After this check · human-readable absolute UTC; no negative age or inferred clock-skew cause |
| Observed source, no completed state in inspected history | No success observed |
| Completed state with no valid source time | Success time not observed; do not conflate with no completed work |
| Source unavailable | Not observed plus available precise reason |
| Inline/manual queue unused | Queue not used |

Compare full-precision instants before flooring relative age so a future time less than one second ahead cannot render as just now. Human absolute defaults to UTC even if source evidence carries another offset. The relative age is an observation-relative reading, not a freshness guarantee.

**Lossless evidence requirement:** exact selectable/copied ISO preserves source seconds, fractional precision, and offset. Current ops_time truncates to seconds, and State.parse_datetime converts raw ISO to UTC while discarding the returned offset. Merely removing UI truncation cannot recover the original offset. Planning must preserve validated source evidence at the existing normalization seam while retaining completed-state semantics, existing struct/API shape, and instant comparison. Prefer existing metadata/internal delivery seams; no new public search API or timezone dependency. If only a DateTime representation exists, serialize its actual precision/offset and never invent a lost source offset. Raw source ISO retained for copying must correspond to the same validated completion instant, not unvalidated metadata or another event.

A source example 2026-10-04T13:02:05.123456-04:00 remains that exact string for evidence/copy; its human absolute form is Oct 4, 2026, 17:02:05 UTC. Preserve the distinct snapshot 2026-10-06T13:18:42.318-04:00. Never substitute checked time, toast time, or current browser time for completion time.

Provide a visible **Copy timestamp** action beside operational last-success values. Exact ISO and UTC absolute explanation are reachable/selectable by pointer, keyboard, and touch through the existing native disclosure pattern. A closed disclosure may keep the scan view compact; the review comp exposes evidence for inspection. Its summary must name exact timestamp access. title is supplementary only. Routine Checked metadata has no copy control. Missing/invalid success time has no misleading copy action.

## Clipboard and Feedback Contract

Call navigator.clipboard.writeText directly from user activation with the exact validated ISO string. Only a resolved write produces **Timestamp copied** through shared polite status feedback. Reuse the existing four-second info dismissal and reset it on repeated successful writes without stacking stale messages. Keep focus on the invoking control. Do not announce success on event dispatch, request clipboard-read permission, or use deprecated fallback copying.

Denied/unavailable clipboard access produces persistent, dismissible **Could not copy timestamp. Select and copy the exact value.** Keep/open the exact-value disclosure for manual selection with no loss of precision/offset. Failure must not auto-dismiss as informational success. Clear/reset stale success on later failed attempts; preserve truthful outcome on repeated clicks. Standalone and mounted handlers implement the same contract.

## Copywriting Contract

| Element | Copy / treatment |
| --- | --- |
| Representative primary action | Refresh health; accessible name identifies Search health |
| Existing recovery destination | View failed sync work; preserve schema context and actual routing |
| Theme choices | System / Light / Dark; labels are choices, not committing CTA verbs |
| Exact-value disclosure | Exact timestamp; UTC absolute explanation plus source ISO |
| Copy action / resolved write | Copy timestamp / Timestamp copied |
| Copy denied or unavailable | Could not copy timestamp. Select and copy the exact value. |
| No configuration | No search schemas configured. Configure the host application's schema allowlist to inspect search health. Existing config guard/guidance remains authoritative. |
| Observation failure | Search health could not be checked. Review the displayed reason, then refresh health to try again. Preserve available per-schema/retained evidence. |
| Partial observation | Observation unavailable on the affected source, with precise reason; preserve readable known values and identify their retained snapshot |
| Observed absence | No success observed; means this observation/history window, not all time |
| Missing completion time | Success time not observed |
| Queue unused | Queue not used |
| Future completion time | After this check · absolute UTC value |
| Disabled action | Existing concrete eligibility explanation; no generic unavailable-only replacement |
| Destructive confirmation | No new destructive action in this phase; preserve all existing safety/confirmation gates |

## State Coverage Surfaces

These prose descriptions are inputs to the workflow's post-checker UI-consideration probe.

- **E1:** Navigation/sidebar and native theme preference buttons with visible labels.
- **E2:** Search health summary and metric grid plus per-schema signal cards/list with state text and long identifiers.
- **E3:** Shared quiet refresh/link buttons with meaningful labels and state explanations.
- **E4:** Operational time text and native exact-timestamp disclosure/copy control with status feedback.
- **E5:** Existing logo and meaningful status icons with accompanying labels.

## UI Considerations

The user confirmed the proposed element kinds and explicit state rules on 2026-10-06. The compiled probe reports **26 applicable, 26 resolved explicitly, 0 unresolved, 0 unclassified, 0 backstops**. These are acceptance criteria for future implementation, not passing application tests. Copy stays in the Copywriting Contract.

Inputs: 173-ui-elements.json and 173-ui-resolutions.json. Report: 173-ui-coverage.json. Re-run from repository root: `node /Users/jon/.codex/gsd-core/bin/lib/ui-consideration-probe.cjs .planning/phases/173-shared-visual-foundation-and-operational-time/173-ui-elements.json .planning/phases/173-shared-visual-foundation-and-operational-time/173-ui-resolutions.json` (resolve the runtime path on other hosts).

Confirmed classifications: E1 navigation/interactive-control/static-content; E2 list-collection/static-content; E3 and E4 interactive-control/static-content; E5 media/static-content. No additional kind was requested. Each row below lifts as an explicit truth, without a human-verification backstop.

| Category | Element(s) | Status | Resolution / Reason |
| --- | --- | --- | --- |
| loading | E1 | ✅ covered | Navigation/theme labels and one current preference remain stable during pending navigation or reconnect. |
| error | E1 | ✅ covered | Storage denial retains functional in-memory preference; invalid values select System; navigation errors preserve shell/connection feedback. |
| overflow | E1 | ✅ covered | The 1280px rail/drawer boundary and header reflow preserve labels/targets without page overflow. |
| long-text | E1 | ✅ covered | Long navigation labels wrap/reflow and do not hide selection or essential accessible names. |
| empty | E2 | ✅ covered | Zero configured schemas uses the configuration-empty row in Copywriting Contract, not zero-valued health claims. |
| loading | E2 | ✅ covered | Refresh retains meaningful busy icon/label and the prior successful evidence snapshot. |
| error | E2 | ✅ covered | Observation-failure copy/retry path remains explicit; unknown does not become zero or remote terminal failure. |
| populated | E2 | ✅ covered | Existing summary/metrics/schema hierarchy uses neutral containers and localized state cues; zero-error values remain neutral. |
| partial | E2 | ✅ covered | Known and retained values remain visible with unavailable-source reasons and snapshot boundaries. |
| overflow | E2 | ✅ covered | Complete module/index/task identifiers wrap; changed breakpoints do not clip essential evidence or create page overflow. |
| zero-one-many | E2 | ✅ covered | Zero uses the config guard; one/many reuse the same schema component, correct counts, and 24px rhythm. |
| long-text | E2 | ✅ covered | Full identifiers/failure reasons remain readable; essential instructions stay body-sized and untruncated. |
| loading | E3 | ✅ covered | Busy controls retain icon/label; completion/patches preserve server-driven eligibility. |
| error | E3 | ✅ covered | Failures expose existing concrete recovery/retry guidance; dispatch alone never produces success feedback. |
| overflow | E3 | ✅ covered | Action groups reflow with targets, independent focus, and visible eligibility explanations intact. |
| long-text | E3 | ✅ covered | Long labels wrap/reflow without clipping icon/label or turning essential instructions into hover-only metadata. |
| loading | E4 | ✅ covered | Pending writes/refresh do not re-date snapshot-relative age or announce copy success. |
| error | E4 | ✅ covered | Clipboard failure uses persistent Copywriting Contract feedback and selectable exact evidence; failed checks retain the prior age reference. |
| overflow | E4 | ✅ covered | Disclosure/copy reflow preserves full selectable ISO precision/offset for keyboard, pointer and touch. |
| long-text | E4 | ✅ covered | Exact ISO/UTC explanation wraps without truncation or reliance on title-only access. |
| empty | E5 | ✅ covered | Without artwork, accessible product name and explicit state/action labels remain usable. |
| loading | E5 | ✅ covered | Assets retain bounded geometry and accompanying semantic labels during loading. |
| error | E5 | ✅ covered | Asset failure leaves product/state labels intact and cannot imply successful operational state. |
| populated | E5 | ✅ covered | Existing theme-specific wordmarks/Heroicons remain bounded; copper is identity-only and status is localized. |
| overflow | E5 | ✅ covered | Artwork cannot force page overflow or obscure adjacent controls at any changed breakpoint. |
| long-text | E5 | ✅ covered | Long accompanying state labels wrap beside icons and remain understandable without hue/artwork. |

## Verification Obligations for Planning

| Requirement | Executable implementation evidence required |
| --- | --- |
| OPUX-09 | Existing token/CSS checks plus rendered light/dark/System desktop/mobile and 1279/1280 geometry; all relevant overrides flat; scroll-edge cues retained |
| OPUX-10 | Component/LiveView assertions for explicit degraded/failed/unknown labels and neutral container styles; rendered current/partial/unavailable/retained-history cases |
| OPUX-11 | Zero, nonzero, and unavailable metric cases; zero uses neutral tokens and conveys no freshness claim; inspect composed semantic contrast |
| OPUX-12 | Browser activation of each native choice by keyboard/pointer; one visual/ARIA preference; OS changes while System, reload, LiveView navigation/patch, two same-origin tabs; invalid/denied storage with current-page fallback |
| OPUX-13 | Shared component/hook state tests and rendered default/hover/pressed/focus/selected/disabled/busy/reduced-motion; meaningful nested label/icon and server eligibility survive refresh/patch |
| OPUX-14 | Boundary tests at 59/60/3599/3600/86399/86400/604799/604800 seconds, microsecond-future, UTC/offset/fractional precision, missing/invalid/no-success/unavailable/unused-queue; snapshot stable across patches and failed refresh; source normalization seam covered |
| OPUX-15 | Real rendered timestamp-copy activation in standalone and mounted contexts; controlled write promise resolve/reject/unavailable outcomes, exact clipboard payload, 4s dismissal/reset, persistent failure/selectable evidence, keyboard/touch access; Checked has no copy action |

Use root `mix verify.ops_ui` for delivered Ops changes, existing focused LiveView/component tests, `make -C examples/scrypath_ecommerce contrast`, and relevant existing Playwright specs admin_shell_chrome.spec.ts/admin_surface_depth.spec.ts. Source-preservation changes in core need relevant core/operator-state tests and CONTRIBUTING's scoped gates. Update existing tests requiring rejected visual treatments. Browser fixture mutations belong in disposable stacks; never reseed preview :4012. Each slice owns executable proof and direct before/after inspection; Phase 177 does not defer Phase 173 acceptance. No new required CI lane, paid judge, human-needed backstop, or pending routine UAT is an acceptance strategy.

Static comp evidence completes palette comparison only. No Mix/application browser suite or exact-SHA hosted implementation proof is claimed by this contract. All OPUX requirements stay unchecked until delivered and verified in their owning phase. Next: `$gsd-plan-phase 173`, after checker and UI coverage completion.

## Registry Safety

| Registry | Blocks used | Safety gate |
| --- | --- | --- |
| None | None; owned existing Phoenix components only | Not applicable; no registry import or dependency added |

## References

Primary guidance informs platform/accessibility constraints; palette and time thresholds are project choices. Consult local Phoenix/brand prompts for context; current official docs govern API behavior.

- [Elixir DateTime](https://hexdocs.pm/elixir/1.17.3/DateTime.html#from_iso8601/2): parsing returns UTC plus original offset; preserve source evidence separately where needed.
- [MDN Clipboard.writeText](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText): asynchronous success/failure and secure-context boundary.
- [MDN localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage): storage access can throw; persistence has browser policy limits.
- [W3C Contrast Minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html), [Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html), [Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html), and [Button Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/button/): readable explicit states, native activation, and polite outcome feedback.

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS — locked inherited-system exceptions documented
- [x] Dimension 5 Spacing: PASS — locked inherited-system exceptions documented
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

Approval: gsd-ui-checker APPROVED on 2026-10-06, 7/7 PASS, no recommendations. The initial generic typography/spacing blocks were reassessed under the higher-priority D-06 user decision to preserve the established system; no numerical compliance or maintainer review is invented. Post-checker coverage is user-confirmed and resolved explicitly. Design contract ready for `$gsd-plan-phase 173`; Phase 173 implementation and OPUX-09–OPUX-15 remain pending.
