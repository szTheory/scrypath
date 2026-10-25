---
phase: "174"
slug: "recovery-entry-and-diagnosis"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-10"
---

# Phase 174 — UI Design Contract

> Visual and interaction contract for OPUX-16–OPUX-19. CONTEXT.md D-01–D-05 and Phase 173's approved foundation are binding. This phase refines only Control Room, Search health, Failed sync work, and schema continuity between them. It adds no surface, recovery capability, dependency, authorization policy, backend/core API, infrastructure behavior, or Phase 175/176 work.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual; existing ScrypathOps token/component system |
| Preset | Not applicable; Phoenix HEEx, not React/shadcn |
| Component library | Existing OpsUi/CoreComponents function components, Tailwind CSS v4 utilities and local CSS; no new UI package |
| Icon library | Existing Heroicons through CoreComponents.icon / OpsUi; every operational icon is paired with visible text |
| Font | `system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`; technical identifiers use `ui-monospace, "Cascadia Code", Menlo, monospace` |

Preserve shared shell/layout ownership, native forms, `<details>` disclosures, LiveView navigation, light/dark/System support, standalone and mounted route prefixes, and existing host authorization. URL parameters and event values remain public untrusted input; always use `OperatorSelection` and current action eligibility/authorization checks.

## Component Inventory

Enumerated by `rg -n '^  def [a-z_]+\(assigns\)' scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — 49 components — scrypath_ops@0.1.0 — 2026-10-10.

This is a non-exhaustive list of known-good components, not a closed allowlist. Check the current module before adding a component or a new variant.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `ops_page_header`, `ops_heading`, `ops_section`, `ops_toolbar`, `ops_panel` | `ScrypathOpsWeb.OpsUi` | Maintain page hierarchy and one meaningful schema surface; do not add an outer summary panel or nested diagnostic cards. |
| `ops_verdict`, `ops_status`, `ops_badge`, `ops_tone_chip`, `ops_metric`, `ops_metric_grid` | `ScrypathOpsWeb.OpsUi` | Pair state text with a restrained icon/tone; zero and unknown metrics stay neutral and distinct. |
| `ops_button`, `ops_link_button`, `ops_action_group`, `ops_refresh_control` | `ScrypathOpsWeb.OpsUi` | Use shared focus/busy/disabled states. Retain the refresh icon and label and keep refresh in the toolbar. |
| `ops_schema_select`, `ops_inline_code`, `ops_result_row`, `ops_disclosure`, `ops_code_block`, `ops_empty_state`, `ops_empty_hero`, `ops_config_empty`, `ops_trail`, `ops_handoff` | `ScrypathOpsWeb.OpsUi` | Preserve native schema choice, complete IDs, concise row-first recovery, collapsed verbose diagnostics, truthful setup/empty states and established navigation. |

## Screen and Interaction Contract

### Control Room — state → affected scope → one safe destination

1. Keep the `Control Room` page title and shared `Refresh health` control in the toolbar. Refresh busy feedback keeps its icon and label and the last successful observation remains the evidence reference if refresh fails.
2. Show one health verdict, then its state/reason and affected scope. Use the existing shared verdict and summary; do not duplicate the same explanation in a separate next-steps block or repeat the per-schema ledger here.
3. For `degraded`, state the affected scope in the verdict and show one primary route: **Inspect Search health**. The destination remains the generic `/health` entry; only retain its current no-parameter first-allowlisted behavior because it is an existing generic entry.
4. For `ok`, say what was observed and its scope without implying document freshness. Keep schema details reachable through **Inspect Search health** as the one health route. “No current sync or backend failures were observed across {N} schemas. This check does not prove document freshness.” Use only the observations the summary actually contains; when a signal is unavailable, render its unknown state instead of substituting zero or this healthy copy.
5. Keep **Verify a change** and **Explore search** as secondary intent cards below the health verdict. They must not look like competing incident actions. Keep the operator guide as a quiet tertiary link.
6. For no configured schemas, use the existing setup state: **No search schemas configured.** “Configure the host application's schema allowlist to inspect search health.” For missing backend, use **Search backend not configured.** “Configure the Scrypath runtime in the host application before checking search health.” Neither state offers retry/recovery or presents zero as a health result.

### Search health — worst-first schema diagnosis

1. Keep `Search health`, the concise existing subtitle, and **Refresh health** in the shared toolbar; the rendered accessibility name is **Refresh Search health**. Keep the page trail.
2. Present the aggregate verdict/metrics only when configured observations exist. Metrics say **Schemas**, **Schema check errors**, **Failed backend tasks**, and **Queues observed**. Zero remains an ordinary neutral number. Unavailable observation reads **Unknown** or **Not observed**, never `0`; neither zero errors nor a last success claims fresh documents.
3. Keep one semantic schema article/surface per allowlisted schema in this fixed ordering: schema fetch errors; backend failures; queue unobserved/failures/retrying signals; clean records. Equal-ranked schemas remain alphabetical by full module name. Never sort by color or latest refresh alone.
4. Within each record, order information as complete module identity; index and sync mode; explicit local status; **Backend tasks** group; **Queue jobs** group or exact unavailable/unused sentence; observed last-success evidence and its time; one contextual next-check link. Use plain groups inside the schema surface, not nested cards or extra enclosing wrappers.
5. Preserve complete schema module, index, job/task identifiers, failure reason and timestamp. Allow wrapping at any separator; never truncate or downsize essential content. Keep last-success age/evidence, unknown queue data, and retained failure evidence under Phase 173's timestamp contract. Preserve precise source/reason and the observation snapshot for retained evidence.
6. Place **Inspect failed sync work for {schema}** beside the evidence it acts on and build its href with that exact canonical schema using `OperatorSelection.path`. Do not emit this schema-specific handoff without an explicit schema. Keep full names visible even when the clickable label wraps. If there is no relevant failed work, do not create an artificial recovery incident or extra CTA.
7. When a schema fetch fails, retain visible module identity, **Search health could not be checked: {reason}. Refresh health to try again.** and any prior retained evidence labelled with its source/snapshot. Do not relabel an old failure as current. A refresh result is a new observation only after it succeeds.

### Failed sync work — reason and eligibility before diagnostics

1. Keep title **Failed sync work**, existing explanatory subtitle, toolbar refresh, and trail. The native schema form label is **Schema** with hint **Choose a schema to inspect its failed sync work.** Keep the full module name as the selected value.
2. For a valid selected schema, show the schema identity, dominant reason and total/retryable counts before the list. Within each row, the reading and tab order is: source-specific work identity; operation/source and last attempt; visible failure reason; current retry eligibility and next step; optional **Diagnostics** disclosure. Keep newest evidence first.
3. Eligible common retry is an ordinary visible button labelled **Retry sync work** inside its originating failure row. Do not hide it in Diagnostics or a menu. At event time, resolve the current schema/work row, re-check eligibility, and use the existing host sensitive-action gate. UI state never substitutes for those checks.
4. Ineligible work shows exact status **Retry unavailable. This work item does not expose a supported retry.** If a concrete current eligibility reason is available, show that reason adjacent to the status. Point operators to the row's source and failure reason; do not render a disabled-looking action that appears eligible or invent a reason that the server did not observe.
5. A retry request error keeps the failure row and says **Retry failed: {reason}. Refresh failed sync work and review the current eligibility before trying again.** If revalidation finds the work is no longer retryable, say **Retry unavailable. This job no longer exposes a retry action. Refresh failed sync work and review its current state.** Keep unexpected authorization denials visible using the existing host-provided message; do not reinterpret them as success.
6. On accepted retry, show **Retry accepted** and **Queue job {replacement_job} · {operation} · {index}. Original failure #{failed_job} retained.** Keep this receipt in the original row and keep the row's failure reason/history. Acceptance is not execution, completion, or searchable-document proof. A receipt/history lookup that is stale or unavailable is **Status not confirmed. The retry was accepted, but its current outcome is unknown.** Never change it into completed/failed without authoritative current evidence.
7. Keep verbose payload/metadata under the existing native **Diagnostics** disclosure. Keep **No failed sync jobs** with body **Nothing needs retry for this schema. If you are confirming recovery, check sync drift before changing indexes.** The existing downstream handoff remains as-is; this phase does not redesign Sync and drift.
8. Keep configuration-empty state **No schemas configured.** “Add allowlisted schema modules with `schema_allowlist` in `:scrypath_ops`, then refresh failed sync jobs.” Keep missing backend as **Runtime not configured** with the existing setup path. Keep explicit invalid selection state **That schema is unavailable. Select an allowlisted schema to continue.** Clear selected identity, rows, reason, eligibility, receipts and confirmations in that state; expose no retry action.
9. Preserve the existing delete-retry confirmation flow without expanding it: title **Confirm delete sync work**; description **Retry deletion of {count} documents for {schema} in {index}.**; buttons **Keep failed work and close** and **Retry delete sync work**. The dismissal action closes the dialog while leaving the current failed work available. Keep full schema/index/document IDs, native dialog focus containment, initial focus on **Keep failed work and close**, Escape dismissal and focus return. Do not treat confirmation as a completion receipt.

## URL, Handoff, and History Contract

- The `schema` query parameter is the canonical durable identity after the operator selects a schema. Use `push_patch` for a selector change within the current LiveView, `push_navigate` for a cross-LiveView handoff, and retain the existing mount prefix.
- Every schema-specific link emitted after a rendered selection carries the exact canonical selected schema. The schema row handoff from Search health and all existing Failed sync recovery/navigation links preserve that identity. Generic cold entry may omit `schema` only where the current page already applies the first-allowlisted default.
- Resolve parameters against the current allowlist in `handle_params/3`; revalidate on every sensitive action. Never create atoms from the parameter. Explicit invalid, hostile, removed, or newly unavailable schema values render **That schema is unavailable. Select an allowlisted schema to continue.** Keep the requested URL visible, clear schema-bound evidence and pending retry state, and do not fall back to first/another schema or permit an action.
- When a valid selection changes, update the URL and form selection together; clear/invalidate prior schema observations, pending receipts, retry confirmations and row selection before loading the new schema. Do not flash success for a selection event.
- Reload and browser Back/Forward reconstruct the same rendered selected schema from the URL. A stale history URL whose schema has since left the allowlist resolves to unavailable with no action. Re-selecting a currently allowlisted schema is the explicit recovery from that stop state.
- Do not announce normal selection/navigation as an alert. Refresh/retry result messages that do not move focus use the existing polite `role="status"` feedback; errors that require correction stay visible as an alert. Do not auto-focus refresh results or interrupt every time/metric update.

## Responsive and Accessibility Contract

- Preserve Phase 173's 17rem desktop rail at 1280px and incumbent drawer/header behavior below its breakpoint. Reuse current content widths, component geometry, panel padding, and section/schema-record rhythm. Keep all controls visible and reachable when columns stack.
- At 320 CSS px and 390px, stack verdict/actions and schema facts in DOM reading order; allow long module names, reasons, timestamps and IDs to wrap. No page-wide horizontal overflow. Only existing genuinely two-dimensional diagnostic payload may use its current contained code surface; provide its native disclosure and full text.
- Preserve native link, button, select/form, heading, article/section, definition-list, disclosure and dialog semantics. Labels identify each action and link destination. Keep DOM order aligned with visual state → scope → action and reason → identity/time → eligibility → diagnostics sequence.
- Keyboard users can reach and activate every route, selector, retry, refresh and disclosure with native keyboard behavior. Preserve the shared 2px visible focus outline with 2px offset in both themes; focus remains distinct from selected, hover and error styling. Touch/icon-only targets remain at least 44px; standard labeled controls remain 40px.
- Pair every state hue with plain text and a local shape/icon cue. Meet WCAG AA text contrast (4.5:1) and essential non-text/focus contrast (3:1) on actual light/dark/System composed surfaces. Degraded/failed is restrained local warning/error text; clean and zero are neutral. Copper is identity-only.
- Keep refresh, retry, and status motion within existing shared patterns. Busy action retains icon and label; respect `prefers-reduced-motion`. Selection updates do not steal focus. Results are exposed politely without focus movement or repeated live announcements; durable errors remain visible until corrected/dismissed.

## Spacing Scale

Any spacing introduced by Phase 174 uses only this scale. Existing components, shared layout, field gaps, control internals, panel padding, and section/schema-record rhythm retain their Phase 173 token-backed values unchanged; Phase 174 does not redeclare their numeric exceptions or override component geometry.

| Phase-owned spacing | Value | Usage |
|---------------------|-------|-------|
| Tight | 4px | New inline icon/text gap |
| Compact | 8px | New compact facts and adjacent controls |
| Row | 16px | New row or group separation |
| Section | 24px | New major section separation |
| Extended | 32px | New separation where section rhythm requires more room |
| Large | 48px | New separation between distinct page regions |
| Maximum | 64px | New separation between major page regions |

Shared labeled controls remain 40px high; prominent and icon-only targets remain 44px. Preserve existing corner roles through shared components.

## Typography

| Role | Size | Weight | Line height |
|------|------|--------|------------|
| Body, reason, supporting copy, ordinary action | 14px | 400; action 600 | 1.5 |
| Schema/subsection heading | 16px | 600 | 1.3 |
| Section/verdict heading | 18px | 600 | 1.3 |
| Page title | 24px | 600 | 1.3 |

Phase 174 uses four phase-owned sizes and two weights only. Shared metadata, timestamps, badges, compact technical values, and navigation retain their existing Phase 173 typography roles and component rendering; Phase 174 adds no inherited-size overrides or new roles. Never use a secondary role for failure reason, eligibility, affected scope, or the sole status explanation. Identifiers use the existing monospace role and may wrap; labels/instructions remain system sans-serif.

## Color

Composition: approximately 60% flat page background, 30% neutral secondary surfaces, and no more than 10% interaction accent. Accent is a limited budget, not a quota to paint. Use Phase 173 tokens and theme variables rather than screen-specific hex overrides.

| Role | Light | Dark | Usage |
|------|-------|------|-------|
| Dominant page (`ops-bg`) | `#f7f6f3` | `#111419` | Flat page and shell floor |
| Secondary resting surface (`ops-surface-1`) | `#ffffff` | `#191e25` | Meaningful panels, row/shell surfaces |
| Secondary quiet surface (`ops-surface-2`) | `#efeee9` | `#222831` | Neutral tonal groups and quiet hover |
| Accent / interaction (`color-primary`) | `#5b4ad1` | `#aaa0ff` | Listed uses below only |
| Warning state text (`ops-warning-text`) | `#805000` | `#f2c66d` | Local degraded/retrying labels with text/icon |
| Failure state text (`ops-error-text`) | `#ad2922` | `#ffaaa2` | Local failure/unavailable labels with text/icon |
| Destructive action (`color-error`) | Existing token | Existing token | Existing confirmed delete-retry action only |

Accent reserved for: primary **Retry sync work** action when eligible; actual links including **Inspect Search health** and schema-specific failed-work links; current navigation/selection; and the shared keyboard focus indicator. Do not accent all clickable/quiet actions. Do not use warning/error colors as full card fills/outlines, or copper as status. Keep neutral zero metrics and explicit neutral unknown values.

## Copywriting Contract

| Element | Exact copy / rule |
|---------|-------------------|
| Control Room primary health route | **Inspect Search health** |
| Control Room healthy statement | “No current sync or backend failures were observed across {N} schemas. This check does not prove document freshness.” Use only when both relevant observations succeeded. |
| Control Room degraded statement | “Search health needs attention.” Follow with the exact observed affected-schema/error/task scope; route **Inspect Search health**. |
| Control Room configuration empty | Heading **No search schemas configured.** Body “Configure the host application's schema allowlist to inspect search health.” |
| Control Room missing backend | Heading **Search backend not configured.** Body “Configure the Scrypath runtime in the host application before checking search health.” |
| Empty failed-work list | Heading **No failed sync jobs**. Body “Nothing needs retry for this schema. If you are confirming recovery, check sync drift before changing indexes.” |
| No schema configuration on Failed sync | Heading **No schemas configured.** Body “Add allowlisted schema modules with `schema_allowlist` in `:scrypath_ops`, then refresh failed sync jobs.” |
| Invalid/removed schema | **That schema is unavailable.** “Select an allowlisted schema to continue.” Clear actions and schema-bound state. |
| Schema fetch error | “Search health could not be checked: {reason}. Refresh health to try again.” Retain and identify older evidence separately. |
| Row retry available | **Retry sync work** |
| Row retry unavailable | “Retry unavailable. This work item does not expose a supported retry.” Add the current concrete eligibility reason when observed. |
| Accepted retry | Status title **Retry accepted**. Body “Queue job {replacement_job} · {operation} · {index}. Original failure #{failed_job} retained.” |
| Accepted, current status unknown | **Status not confirmed. The retry was accepted, but its current outcome is unknown.** Keep queue job and failed record identity. |
| Retry request rejected as no longer eligible | “Retry unavailable. This job no longer exposes a retry action. Refresh failed sync work and review its current state.” |
| Retry operation failed | “Retry failed: {reason}. Refresh failed sync work and review the current eligibility before trying again.” |
| Diagnostics disclosure | **Diagnostics** |
| Empty schema/queue observation | **Queue observations unavailable; no queue counts are reported as zero.** For unused inline/manual queue: **Queue not used.** |
| Destructive confirmation | Title **Confirm delete sync work**; description “Retry deletion of {count} documents for {schema} in {index}.”; actions **Keep failed work and close** / **Retry delete sync work**. The dismissal keeps the failed work available. |
| Refresh success | **Search health refreshed.** on Control Room/Search health; **Failed sync work refreshed.** on Failed sync work. |
| No new destructive action | Preserve existing confirmation, host authorization, and action eligibility; do not introduce another action or confirmation flow. |

Keep required meaning in visible body text, not title-only text, tooltips, or color. Interpolate observed values through existing HEEx-safe components; never render reasons or metadata as raw HTML. Distinguish zero from unknown, accepted from complete, retained failure from current result, and generic first-schema entry from explicit selected-schema handoff.

## UI Considerations

All state cases below are explicit implementation truths and must remain covered by rendered assertions and the existing mounted/browser verification seam where stated. Copy references the Copywriting Contract above to avoid drift.

Elements: E1 Control Room health verdict and intents (`static-content`, `nav`, `interactive-control`); E2 Search health summary and per-schema signal collection (`list-collection`, `static-content`); E3 Failed sync schema selector (`form`, `interactive-control`); E4 Failed sync work rows/retry receipts/Diagnostics (`list-collection`, `interactive-control`, `static-content`); E5 schema handoff/history and refresh (`nav`, `interactive-control`).

Applicable state considerations resolved: 29 covered, 0 backstop, 0 unresolved.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | E1, E2, E3, E4 | ✅ covered | Configuration empty and no failed-work rows use the exact Copywriting Contract states; zero configured schemas never render as healthy zero metrics. |
| loading | E1, E2, E3, E4, E5 | ✅ covered | Shared busy control retains icon/label; prior successful evidence remains the snapshot through pending or failed refresh; schema choice/history remain URL reconstructible. |
| error | E1, E2, E3, E4, E5 | ✅ covered | Observation, retry, invalid-target, and stale-history errors use explicit copy and a supported next step; invalid target clears actions. |
| populated | E1, E2, E4 | ✅ covered | Verdict → scope → one health route; schema records stay worst-first; failure reason/identity/time/eligibility precede Diagnostics. |
| partial | E1, E2, E4 | ✅ covered | Preserve known source values and timestamped retained failures while labelling unavailable observations; accepted retry stays beside the original failed row. |
| overflow | E2, E4, E5 | ✅ covered | Full schema/index/work IDs wrap; contained code evidence remains disclosed; at 320/390px there is no document-level horizontal overflow. |
| zero-one-many | E2, E4 | ✅ covered | Zero schemas is configuration-empty; one and many schemas share one record pattern; zero failed jobs uses the explicit empty row; singular/plural counts match actual counts. |
| long-text | E1, E2, E3, E4, E5 | ✅ covered | Long labels, schema module names, failure reasons, timestamps, work IDs, and eligibility explanations wrap/reflow without truncation or undersized essential copy. |

Explicit state transitions also cover: accepted retry; accepted but unknown current result; retry rejected because current eligibility changed; stale/forged/removed schema; valid non-first schema selection; history entry after selection; refresh; back/forward; action state cleared on schema change; full failure retained after acceptance. Verify real rendered interaction, not only direct event calls. The mounted sequence changes selection to a non-first schema, follows its schema-specific handoff, refreshes, presses Back/Forward, and asserts the same selected identity; unknown/removed targets assert unavailable and no mutation reaches another schema. Include long identifiers/reasons at narrow width and keyboard focus visibility in both themes. Use current ExUnit/LiveView tests and mounted Playwright lane; no new test framework or CI service.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None; existing Phoenix/OpsUi code only | Not applicable; no registry import or dependency |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** GSD UI checker approved on 2026-10-10, 7/7 PASS.
