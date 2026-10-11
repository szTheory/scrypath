---
phase: "175"
slug: "repair-and-verification"
status: approved
reviewed_at: "2026-10-11T03:48:16Z"
shadcn_initialized: false
preset: none
created: "2026-10-10"
---

# Phase 175 — UI Design Contract

> Contract for OPUX-20–OPUX-22 on the existing Sync and drift surface. Phase 175 keeps
> the approved v1.43 visual system and operational boundaries. The exact labels and layout
> below are researcher recommendations adopted under the standing direction recorded in
> 175-CONTEXT.md; they are not fabricated interview answers or maintainer sign-off.

## Phase Boundary and Evidence Order

Keep the work on **Sync and drift**. Preserve current schema selection, host-owned
authorization, existing repair and promotion capabilities, explicit confirmation, and
server-side rechecks. Do not add a new route, workflow, authorization layer, dependency,
framework, or public Scrypath API.

Render the operator's evidence as distinct results in this order:

1. **Sync and queue status** — what the queue and backend report now.
2. **Index contract** — whether declared settings and fields match the selected live index.
3. **Document freshness** — whether the expected document is observed in the active index.
4. **Ordinary recovery** — the existing eligible retry path and its correlated outcome.
5. **Advanced: index promotion** — the existing disclosure and confirmation path, visually
   separated from routine checks and recovery.

The primary visual anchor is the selected schema's **Sync and queue status** result: show its
current observed or unavailable state first and give it the clearest section emphasis. Keep
index-contract and document-freshness results independently readable beside it; do not combine
them into an overall health verdict. The ordinary recovery action follows these observations,
and advanced promotion remains behind its separate disclosure.

Use the existing page header, schema selector, section, table, status, action, disclosure,
and modal primitives. Keep sections directly on the page's flat neutral background. Do not
wrap these sections in an extra dashboard panel or make them one combined green/failed
verdict. A clean contract check does not prove document freshness; queue success does not
prove active-index visibility.

Every operation result stays beside its own identity: selected schema and index, Oban job
and attempt for queued recovery, or Meilisearch task UID for backend work. Keep accepted,
running, terminal success, terminal failure/cancellation, and unknown/unavailable visually
distinct. Acceptance is not completion. A timeout, transport error, missing/malformed task,
or failed observation says **unknown / could not be checked** and keeps the exact operation
reference visible. Refresh remains observational and must re-check that same reference
without resubmitting work. Preserve prior failure history. When schema/index identity changes,
invalidate evidence and confirmations tied to the previous target; an unavailable explicit
schema target is a visible stop, never a fallback.

An eligible ordinary action stays on the common path. Keep unavailable actions disabled with
the existing concrete eligibility reason alongside them. Keep promotion under the native
`Advanced: index promotion` disclosure. Its existing confirmation names the schema, live
index, target index, and alias effect. Rendered eligibility and confirmation are explanatory
UI; the server remains responsible for current allowlist, host authorization, eligibility,
and fresh evidence checks immediately before mutation.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual, existing ScrypathOps token and component system |
| Preset | Not applicable; Phoenix LiveView / HEEx, not a React application |
| Component library | Existing OpsUi/CoreComponents with daisyUI and Tailwind CSS v4 |
| Icon library | Existing Heroicons via CoreComponents.icon |
| Font | system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif; technical values use ui-monospace, Cascadia Code, Menlo, monospace |
| Authority | `scrypath_ops/assets/css/app.css`, OpsUi components, and `DESIGN-TOKENS.md`; Phase 173's warm-neutral light / neutral dark contract |

Carry forward flat warm-neutral light and neutral dark page floors, neutral resting panels,
quiet borders, 24px major section rhythm, and no decorative shell gradient. Use status text
and a restrained local icon/badge on neutral surfaces. Zero error counts stay neutral and
never imply freshness or overall health. Use the existing native controls, LiveView async
and navigation patterns, and reduced-motion-safe shared feedback.

## Component Inventory

Enumerated by `rg -n '^  def [a-z_]+\\(assigns\\)' scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — 49 components — scrypath_ops@0.1.0 — 2026-10-10.

This source-enumerated table is a non-exhaustive list of relevant known-good components,
not a closed allowlist. Check the current exports/source before choosing any additional
component. The local app package version comes from `scrypath_ops/mix.exs`.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `ops_page_header`, `ops_trail` | `ScrypathOpsWeb.OpsUi` | Keep the current page identity and contextual breadcrumb. |
| `ops_panel`, `ops_section`, `ops_toolbar` | `ScrypathOpsWeb.OpsUi` | Use section grouping and responsive action placement without nested decorative wrappers. |
| `ops_schema_select` | `ScrypathOpsWeb.OpsUi` | Keep the allowlisted schema selection and complete readable module name. |
| `ops_signal_table`, `ops_data_card`, `ops_tone_chip`, `ops_inline_code` | `ScrypathOpsWeb.OpsUi` | Present contract and document evidence with row labels, full identifiers, and local match/mismatch cues. |
| `ops_status`, `ops_verdict`, `ops_badge` | `ScrypathOpsWeb.OpsUi` | Pair plain-language state with restrained semantic color and the next useful step. |
| `ops_button`, `ops_action_group`, `ops_refresh_control`, `ops_disclosure` | `ScrypathOpsWeb.OpsUi` | Preserve action hierarchy, concrete disabled reasons, native disclosure, and observation-only refresh. |
| `ops_empty_state`, `ops_loading`, `ops_notice`, `ops_modal` | `ScrypathOpsWeb.OpsUi` | Cover no-schema, in-flight, unavailable, and explicit promotion-confirmation states. |

## Spacing Scale

Declared values (multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label gaps and compact inline spacing |
| sm | 8px | Related labels, table cells, and compact control groups |
| md | 16px | Default element and narrow-screen panel spacing |
| lg | 24px | Major section spacing and desktop page rhythm |
| xl | 32px | Larger group separation when needed |
| 2xl | 48px | Page-level separation only where existing shell calls for it |
| 3xl | 64px | Reserved for page-level breathing room; not for dense operation evidence |

Preserve existing compact-gap and desktop-panel component patterns where they are already
implemented; they do not add spacing tokens or phase-specific spacing exceptions. Existing
shared control heights and minimum 44px prominent/icon-only touch targets are sizing
requirements, not spacing tokens. Do not invent additional phase-specific spacing values.

## Typography

Use the existing system font and heading tokens. Declare only these three text sizes for
phase content; compact monospace metadata remains secondary and must never be the only
explanation for a decision.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body and labels | 14px | 400 regular; 600 semibold for labels/actions | 1.5 |
| Section heading | 18px | 600 semibold | 1.3 |
| Page heading | 24px | 600 semibold | 1.3 |

Use exactly two weights: 400 regular and 600 semibold. Wrap schema modules, task/job IDs,
index names, failure reasons, and confirmation values; never truncate the only visible copy
of an operation identity.

## Color

Apply the Phase 173 neutral palette. The 60/30/10 proportions describe visual emphasis,
not a requirement to tint operational data.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Light `--ops-bg` `#f7f6f3`; dark `--ops-bg` `#111419` | Flat page and shell floor |
| Secondary (30%) | Light `--ops-surface-1` `#ffffff`; dark `--ops-surface-1` `#191e25` | Resting section/panel surfaces, schema selector, modal surface |
| Accent (10%) | Light `--color-primary` `#5b4ad1`; dark `--color-primary` `#aaa0ff` | Keep localized to primary action, selected navigation/control, links, and visible focus |
| Destructive | Existing semantic `error` token, light/dark `#d96262`; use only through the existing dangerous promotion-confirmation action | Explicitly confirm alias-changing promotion; never use as a general warning surface |

Accent reserved for: primary committing action, current/selected navigation or control,
links, and keyboard focus. Copper stays a small brand/eyebrow detail and never signals
health, drift, success, failure, or eligibility. Use semantic status tokens for info,
success, warning, and error with text/icon cues; keep all summary and evidence containers
neutral. Preserve the app's AA contrast gate in both themes.

## Copywriting Contract

| Element | Copy / treatment |
|---------|------------------|
| Primary CTA | **Refresh sync and queue status** — observational only; retain the specific “Check index contract” / “Refresh contract check” control for contract diagnosis. |
| Ordinary recovery action | Where failed work needs operator action, show **Review failed sync work** as the next step and preserve the selected schema in its existing route. Use the existing eligible **Retry failed work** action there. On return, label the observation control **Refresh recovery status**; do not imply that refresh resubmits a retry. |
| Empty state heading | **No schemas configured** |
| Empty state body | **Add allowlisted schemas before loading sync or drift observations.** |
| Error state | **The {check} could not be checked. Keep the last observed evidence, review the displayed reason, then refresh to try again.** Keep an observation failure unknown, not a remote task failure. |
| Unknown operation state | **Task {UID} could not be confirmed. Its outcome is unknown. Refresh checks to inspect this same task; do not submit another operation.** Retain the queue job/attempt and selected schema/index alongside the task UID when present. |
| Ineligible action | **{Action} is unavailable: {existing concrete eligibility reason}.** Keep the reason visible beside the disabled action. |
| Destructive confirmation | **Confirm index promotion** — “Meilisearch will change the live alias after its swap task completes.” Show schema, live index, target index, and “Effect: replace the live alias with the prepared target index.” Buttons: **Cancel index swap** and **Promote target index**. |
| Accepted / terminal result | Label accepted/enqueued as accepted and running as running. Say **Index swap completed** only for the matching terminal task plus applicable index evidence. Label remote failed or canceled work as a terminal non-success and preserve its task UID. |

Do not announce success from a flash, a `202 Accepted` response, a queue-only completion,
or an unrelated historical task. Keep the next safe check close to the evidence it applies
to. Do not add destructive actions beyond the existing index-promotion flow.

## Interaction, Accessibility, and Responsive Contract

- Keep the default reading order aligned with the evidence order above. Use visible section
  headings and row headers for sync/queue, index-contract, document-freshness, recovery, and
  promotion evidence.
- Use `role="status"` for non-focus-moving in-flight and accepted updates; use an alert role
  for blocking check failures. Announce only the changed result, not the whole evidence group.
  Never move focus when an async result arrives.
- Keep visible keyboard focus and native button, select, disclosure, and dialog keyboard
  behavior. The promotion dialog retains focus containment and return behavior from the
  existing modal. Confirmation states the alias effect before the committing action.
- Color never carries the only meaning. Pair every semantic state with its visible label;
  use local icons/badges and preserve text contrast on neutral surfaces.
- At narrow widths, stack sections and wrap action rows. Keep full schema/index/task/job IDs
  and failure reasons readable without page-level horizontal scrolling. A dense table may
  scroll within its existing named wrapper only when wrapping cannot preserve its columns.
- Keep desktop and narrow layouts in light and dark themes. Honor reduced motion and the
  existing brief, non-focus-moving feedback pattern.
- URL/event schema values and disabled controls are not authorization boundaries. Server
  checks remain authoritative immediately before any repair or promotion mutation.

These contracts follow the scoped requirements in OPUX-20–22 and the current Ops tokens and
components. Primary-source references: [Meilisearch Tasks API](https://specs.meilisearch.dev/specifications/text/0060-tasks-api.html),
[Meilisearch Swap Indexes specification](https://specs.meilisearch.dev/specifications/text/0191-swap-indexes-api.html),
[Phoenix LiveView 1.1.33](https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html),
[WCAG 2.2 Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html),
and [WCAG 2.2 Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html).

## UI Considerations

Explicitly resolve the applicable shape-rooted states for this surface. This is a recommended
contract synthesized from 175-CONTEXT.md, the requirements, current LiveView and OpsUi source,
and the existing Phase 173 design contract; it is not represented as user-confirmed coverage.
Copy remains in the Copywriting Contract above. **28 applicable, 28 explicitly resolved,
0 backstop, 0 unresolved, 0 unclassified.**

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | E1 Schema selector and sync/queue observations | ✅ covered | No configured schema uses the empty-state heading/body above; zero signals are never presented as a healthy result. |
| loading | E1 Schema selector and sync/queue observations | ✅ covered | Refresh retains the prior observed snapshot and keeps the action label/icon while current queue/backend checks run. |
| error | E1 Schema selector and sync/queue observations | ✅ covered | Show unavailable source and its reason; retain any prior evidence with its check time and a refresh path. |
| populated | E1 Schema selector and sync/queue observations | ✅ covered | Show queue and backend signals under separate names, with selected schema and full index identity. |
| partial | E1 Schema selector and sync/queue observations | ✅ covered | Keep known source values beside the unavailable source reason; do not turn missing observations into zeroes. |
| overflow | E1 Schema selector and sync/queue observations | ✅ covered | Wrap module/index identifiers; only the existing table wrapper may scroll locally if necessary. |
| zero-one-many | E1 Schema selector and sync/queue observations | ✅ covered | Reuse the same section for one or many configured schemas; the no-schema state uses the explicit configuration guard. |
| long-text | E1 Schema selector and sync/queue observations | ✅ covered | Full module names, index names, and reasons wrap at narrow widths; essential instructions remain body-sized. |
| empty | E2 Index-contract and document-freshness results | ✅ covered | Before either observation, state that it has not been checked; do not imply a clean contract or fresh documents. |
| loading | E2 Index-contract and document-freshness results | ✅ covered | Show a named in-flight check, keep other evidence readable, and do not change either result to success while checking. |
| error | E2 Index-contract and document-freshness results | ✅ covered | Name which observation failed, preserve its reason, and leave a distinct retry/check action available. |
| populated | E2 Index-contract and document-freshness results | ✅ covered | Present contract dimensions and expected-document observation as separate results with separate evidence. |
| partial | E2 Index-contract and document-freshness results | ✅ covered | Partial availability names the missing source and retains known values; a clean contract never substitutes for document visibility. |
| overflow | E2 Index-contract and document-freshness results | ✅ covered | Wrap field names, identifiers, and long mismatch reasons; preserve row labels and avoid page overflow. |
| zero-one-many | E2 Index-contract and document-freshness results | ✅ covered | Zero/one/many contract dimensions and documents use explicit counts and stable section structure; no count implies freshness without observation. |
| long-text | E2 Index-contract and document-freshness results | ✅ covered | Full field/document/index identities and mismatch reasons remain readable and selectable. |
| loading | E3 Recovery operation result and refresh control | ✅ covered | Expose non-focus-moving progress while preserving the accepted job/task identity; refresh observes the same operation. |
| error | E3 Recovery operation result and refresh control | ✅ covered | Observation timeout/transport/malformed/missing data is “could not be checked” / unknown with a next check, never remote failure. |
| overflow | E3 Recovery operation result and refresh control | ✅ covered | Long recovery status and reason text wraps beside the complete task/job identity without forcing page-level horizontal scrolling. |
| long-text | E3 Recovery operation result and refresh control | ✅ covered | Preserve full schema, job, attempt, task, and index identity; wrap the evidence rather than truncating it. |
| loading | E4 Advanced promotion disclosure, action, and confirmation | ✅ covered | Disable repeated promotion while pending and retain its action label; keep accepted/running status distinct from completion. |
| error | E4 Advanced promotion disclosure, action, and confirmation | ✅ covered | A blocked action keeps its concrete eligibility reason; terminal task failure/cancellation stays distinct from unknown observation. |
| overflow | E4 Advanced promotion disclosure, action, and confirmation | ✅ covered | Confirmation and result reflow or scroll within their existing named container so full identity and alias-effect text remain visible without page overflow. |
| long-text | E4 Advanced promotion disclosure, action, and confirmation | ✅ covered | Schema, live/target index, effect, task UID, and failure details wrap within the disclosure/dialog at narrow widths. |
| loading | E5 Operation status and async feedback | ✅ covered | Status changes are announced once without stealing focus or re-announcing unrelated page evidence. |
| error | E5 Operation status and async feedback | ✅ covered | Error text remains visible and actionable; observation errors never use wording or color that states the remote mutation failed. |
| overflow | E5 Operation status and async feedback | ✅ covered | Long asynchronous status and error messages wrap within the feedback region and cannot create page-level horizontal overflow or cover their related controls. |
| long-text | E5 Operation status and async feedback | ✅ covered | Operation references and failure explanations remain readable without relying on a tooltip or title attribute. |

Element kinds used: E1 `form`, `list-collection`, `interactive-control`, `static-content`; E2
`list-collection`, `interactive-control`, `static-content`; E3 `interactive-control`,
`static-content`; E4 `interactive-control`, `static-content`; E5 `interactive-control`,
`static-content`. These classifications were synthesized by the agent under the maintainer's
automatic-recommendation instruction; they were not individually user-confirmed. Open-ended
accessibility, responsive, reduced-motion, async freshness, and security concerns are covered
in the prose contracts above rather than added to the closed state taxonomy.

Inputs: `175-ui-elements.json` and `175-ui-resolutions.json`; compiled output:
`175-ui-coverage.json`. Re-run with `node /Users/jon/.codex/gsd-core/bin/lib/ui-consideration-probe.cjs .planning/phases/175-repair-and-verification/175-ui-elements.json .planning/phases/175-repair-and-verification/175-ui-resolutions.json` (resolve the installed runtime path on other hosts). The probe reports 28 applicable categories, all 28 explicitly resolved, with no backstops, unresolved items, or unclassified elements. These are explicit contract truths for downstream planning, not passing implementation tests.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None | Not applicable; Phoenix HEEx project with no shadcn or third-party component registry. |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** gsd-ui-checker approved 7/7 PASS on 2026-10-11 with no recommendations. Recommendations and coverage are agent-generated, not user-confirmed.
