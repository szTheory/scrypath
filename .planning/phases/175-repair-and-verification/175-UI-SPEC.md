---
phase: "175"
slug: "repair-and-verification"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-10"
reviewed_at: "2026-10-10 12:04 UTC"
---

# Phase 175 — UI Design Contract

> Visual and interaction contract for OPUX-20–OPUX-22. Follows accepted Phase 175 decisions and the current ScrypathOps design system; this contract does not claim implementation or requirement completion.

## Design System

| Property | Value |
|----------|-------|
| Tool | none — source-owned manual Phoenix/HEEx system (`OpsUI` and `ops-*` tokens) |
| Preset | not applicable |
| Component library | Phoenix LiveView / HEEx with existing ScrypathOps components and daisyUI semantic tokens |
| Icon library | Existing Heroicons dependency; use only established local icon patterns |
| Font | System UI sans-serif for interface; `ui-monospace` for exact technical values |

Source: `DESIGN.md`, `scrypath_ops/assets/css/DESIGN-TOKENS.md`, `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`. This is an existing manual design system, not a shadcn project. No new library, registry, or component inventory is introduced.

## Spacing Scale

Phase-authored composition follows this 4px base scale. Use an existing compatible Ops token/utility where available; do not create tokens or hardcode a raw Tailwind step when a named Ops token exists. Values 32px and above are scale anchors for future composition only; Phase 175 does not require adding aliases or using larger gaps.

| Scale value | Usage |
|---------------|-------|
| 4px | Icon-to-label and inline code spacing |
| 8px | Adjacent controls and compact status grouping |
| 16px | Default phase-authored grouping |
| 24px | Existing page/major-section gap |
| 32px | Reserved scale anchor; no new token in this phase |
| 48px | Reserved scale anchor; no new token in this phase |
| 64px | Reserved scale anchor; no new token in this phase |

Continue to consume existing source-owned component dimensions without redefining them as the phase scale: `--spacing-ops-3` (compact/form rhythm), `--spacing-ops-panel` (panel padding), `--spacing-ops-row`, `--spacing-ops-section`, and `--spacing-ops-control-gap`. These tokens retain the catalog values; this contract preserves their current values and uses them through existing components. The shell already applies top-level `space-y-4`; do not add margins to direct page children. The schema selector and subsequent sections use the existing 24px page rhythm. Exceptions: existing 40px standard controls; 44px prominent/touch targets; compact disclosure summary may use the existing 28px control token. These component/control dimensions remain owned by the existing system and are not phase-authored scale entries.

## Typography

Use exactly two interface weights: regular 400 and semibold 600. Keep the four existing interface sizes. Phase-authored exact identifiers and evidence use the 14px Body size and wrap; source-owned diagnostic components retain their current sizing without a Phase 175 override.

| Role | Size | Weight | Line height |
|------|------|--------|-------------|
| Body / actions | 14px | 400 / 600 for action labels | 1.5 |
| Object / subsection heading | 16px | 600 | 1.3 |
| Section heading | 18px | 600 | 1.3 |
| Page title | 24px | 600 | 1.3 |

These line heights are the current `--leading-ops-body` and `--leading-ops-tight` values. Exact IDs, task UIDs, index names, and raw errors use monospace while retaining the declared Body size and wrapping. Do not shrink primary explanatory or failure copy to fit.

## Color

Follow the current neutral 60/30/10 composition as a visual balance, not as a requirement to compute literal screen-area percentages. Use semantic theme tokens so Light, Dark, and System stay coherent.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (about 60%) | `--ops-bg` / light `#f5f6f8`, dark `#111419` | Flat page background and open space |
| Secondary (about 30%) | `--ops-surface-1` / light `#fff`, dark `#191e25`; raised `--ops-surface-2` / light `#edeff2`, dark `#222831` | Existing panels, disclosures, muted diagnostic grouping |
| Accent (about 10%) | Violet `primary` / light `#5b4ad1`, dark `#6c5ce7` | Primary action, selected navigation/control, links and focus treatment only |
| Destructive / failure | Existing semantic `error` `#d96262`; warning `#d9a441`; success `#4fae74`; info `#5ca9e6` | Local status text/icon/badge and the existing confirmation danger action; never a broad status fill |

Copper (`secondary`, light `#a85d2e`, dark `#c17a3e`) remains a small brand accent and never signals health or failure. Keep panels and metric/status surfaces neutral. Every state includes explicit text; color and icon are secondary cues. A zero count or matching configuration never receives success emphasis that could imply fleet health, document freshness, or promotion readiness.

Accent reserved for: the existing primary action, selected navigation/schema control, ordinary links, and keyboard focus. Do not color every interactive element or use violet/copper to encode operational state.

## Copywriting Contract

Use natural operator language. Keep the title “Sync and drift”; call the comparison “Index configuration”; retain `index_contract_drift` and other API names only in code or diagnostics. Show only decision-changing counts, blockers, uncertainty, selected schema/index, exact task identity, and the next useful action. Successful comparison tables, raw flags, and framework details remain disclosed. Do not imply a repair occurred from a read-only check.

| Element | Copy |
|---------|------|
| Primary ordinary CTA | `Check index configuration` before a comparison; `Refresh configuration check` after one exists. Sync refresh control is labeled `Refresh sync and queue status`. |
| Healthy sync | `No pending or failed sync work found` with no zero counters or redundant reassurance. |
| Empty setup | Heading: `No schemas configured`. Body: `Add the Ecto schemas you want to manage to Scrypath’s configuration, then refresh this page.` |
| Error state | `Sync status is unavailable. Refresh to try again. If the check keeps failing, review the backend and queue configuration.` Keep any valid independent configuration result visible. When a source read is incomplete, say `Sync status is incomplete: {source} could not be checked.` Do not show the healthy summary unless the required observations completed. |
| Unavailable scope | `That schema is unavailable. Choose an available schema to continue.` Keep host allowlist terminology in technical/safety explanation only. |
| Destructive confirmation | `Promote target index`: `Confirm index promotion` names the full schema, exact live index and target index, and says `This swaps the selected indexes' documents, primary keys, settings, and task history so the prepared target becomes live.` Actions: `Cancel index swap` and `Promote target index`. Require the existing modal, host authorization, current scope validation and immediate prerequisite rechecks. |

### State and action copy

| State | Visible state copy | Safe next action / placement |
|-------|--------------------|-----------------------------|
| Normal clear visit | Only after required sync and queue observations complete with no pending or failed work, show `No pending or failed sync work found.` `Index configuration` starts as `Not checked`. A normal visit with no retry handoff omits Retry status. | Keep `Refresh sync and queue status` beside Sync status and `Check index configuration` beside Index configuration. Advanced promotion stays in its own closed disclosure. |
| Partial sync observation | `Sync status is incomplete: {source} could not be checked.` Keep any independently valid observations visible and do not show `No pending or failed sync work found`. | `Refresh sync and queue status`; retain the failed source and reason. Do not represent unknown values as zero. |
| Active retry handoff | If a retry handoff is present, render `Retry status` even when its receipt is invalid, expired, or unavailable. Show known operation/source, full schema/index, replacement queue job and attempt; show matching Meilisearch task UID when known. Mark missing evidence unknown. | `Refresh recovery status` observes this exact retry and never submits work. Do not silently remove the card or replace its identity. Place the outcome before ordinary sync summary. |
| Retry accepted / queued | `Retry accepted` — `The queue accepted this retry. Backend and document results are still being checked.` | Keep exact queue job, attempt, source failure and schema visible. Offer `Refresh recovery status`; do not add a retry action here. |
| Retry authoritatively running | `Retry running` only when the matching queue or backend task reports active work. | Show which system reports running. The observer's own `Checking…` state is separate and never establishes remote running. |
| Observer busy | `Checking recovery status…`, `Refreshing sync and queue status…`, or `Comparing index configuration…` with the relevant control busy/disabled. | No second submission while the same observation is in flight. This is local read activity, not remote task state. |
| Queue complete, effect pending | `Queue job completed; backend task or document effect is not confirmed.` Keep the missing evidence named. | `Refresh recovery status`; preserve task UID if present. Do not say “Recovery verified.” |
| Retry verified | `Recovery verified` only when matching authoritative queue/task and active-index expected document effect are both established; for delete, expected absence is required. | Present queue job/attempt, task UID, schema/index, operation, effect observation, and checked time in compact details. A generic search result or historic success does not qualify. |
| Retry terminal failure / cancellation | `Recovery failed` or `Retry canceled` only from the matching authoritative work result. | Link to `Review failed sync work` for the selected schema. Preserve failure reason and exact source identity. |
| Retry observation unavailable | `Recovery status is unknown` or `Recovery check timed out`. `The observation could not confirm what happened; this does not mean the remote task failed.` | Safe read-only `Refresh recovery status`. If receipt/task identity is missing or expired, say which evidence is unavailable; never turn a failed read into zero or a remote failure. |
| Sync pending | `Sync work is pending` or `Reindex work is pending`. | `Refresh sync and queue status` to check progress. Do not imply that the observer is the backend task. |
| Sync failure | `Sync failures need attention` with the reason/count only when positive and decision-relevant. | Link to `Review failed sync work` for the selected schema. |
| Sync observation failure | `Sync status is unavailable` plus the error-state copy above. | `Refresh sync and queue status`; retain independent valid configuration results. Diagnostics are a compact `Check diagnostics` disclosure. |
| Configuration unrun | `Not checked`. Supporting line: `Check whether declared fields and search settings match the live index.` | `Check index configuration`. No warning state or stale result implied. |
| Configuration loading | `Comparing index configuration…` | Keep action busy. Do not replace sync status or claim a backend task is running. |
| Configuration match | `Index configuration matches`. | Keep comparison table in closed `Comparison details`; say this does not establish document freshness. |
| Configuration mismatch | `Index configuration differs` and `{N} configuration difference(s) found.` | Open `Comparison details` by default and show affected dimensions first. Point to the existing runbook as needed; do not offer automatic repair. |
| Configuration observation failure | `Index configuration could not be checked. Refresh the configuration check to try again. You can still check sync status above.` | Keep valid Sync status. Put raw read diagnostics in `Check diagnostics`; do not describe the documents or fields as mismatched. |
| Promotion disclosure closed, no operation | Summary: `Advanced: index promotion`. Keep eligibility reason and status unnecessary outside the collapsed path when there is no operation. | Native disclosure; manual expansion is retained through LiveView patches. |
| Promotion blocked | `Promotion unavailable: {specific reason}.` Use the existing reason mapping, e.g. `resolve failed sync work first`, `wait for queued work to finish`, or `check the index configuration`. | Keep disabled `Promote target index` inside the expanded disclosure beside the reason. State schema/index scope; show blockers, not a pile of successful prerequisite diagnostics. |
| Promotion eligible | `Ready for promotion` — `Current checks are clear for this schema and index pair.` | `Promote target index` opens confirmation. Eligibility is specific to the selected allowed schema and observed live/target pair. |
| Promotion confirmation | `Confirm index promotion`; full schema, `Live index: {exact id}`, `Target index: {exact id}`, and the index-swap effect. | `Cancel index swap` returns focus to the trigger. `Promote target index` proceeds only through existing host authorization and immediate prerequisite/allowlist rechecks. Auth return restores this context without replay. |
| Promotion accepted | `Index swap accepted` — `The backend accepted this swap. Waiting for its terminal result.` Keep the exact returned task UID. | Keep status and UID visible outside any closed advanced content. Offer `Check swap status` for that exact UID; it is read-only, busy/disabled only while that same task check is active, and never resubmits the swap. Do not call acceptance completion. |
| Promotion authoritatively running | `Index swap running` only if a read of the same returned task UID reports an active state. | `Check swap status` re-reads that UID; its local `Checking swap status…` indicator is observer activity, not remote progress. |
| Promotion terminal success | `Index swap completed` only for the matching task's terminal success. Keep task completion separate from current index configuration and document-effect observations. | `Refresh index checks` reads current index/configuration state; it is not task polling. Do not imply document freshness from swap completion. |
| Promotion terminal failure/cancellation | `Index swap failed` or `Index swap canceled` only for the matching terminal task. Show concise reason and exact UID. | `Refresh index checks` reads current index/configuration state. The terminal task result remains tied to its UID; no automatic second submission. |
| Promotion unknown / timeout | `Index swap outcome unconfirmed` — `The task result could not be confirmed. The returned task UID is {uid}; no second swap was submitted.` | Preserve exact UID and state outside a closed disclosure. Offer `Check swap status` to re-read that exact UID; do not label current-index/config refresh as task polling. |
| Promotion missing UID | `Index swap outcome unconfirmed. The task ID is unavailable, so this task cannot be checked directly.` Preserve any known submission context; never fabricate an ID. | Offer the existing safe `Refresh index checks` diagnostic route and keep the result unconfirmed. Do not submit another swap to recover a missing UID. |
| Invalid/removed schema | `That schema is unavailable. Choose an available schema to continue.` | Keep selector visible; clear or reject stale context safely. Never fall back to another schema. |

## Page Composition and Interaction Contract

### Desktop, normal clear state

Render the existing wide Ops shell with the shared page header `Sync and drift`, concise subtitle `Check sync progress and compare index configuration.`, breadcrumb, and a visible labeled schema selector. The selected full module name is readable and wrap-capable. Then place two simple neutral sections in order:

1. `Sync status`: compact current summary first, refresh control and checked time beside the heading, optional `Review failed sync work` link only when failures exist, and a native `Sync details` disclosure for exact index/mode/work observations.
2. `Index configuration`: short freshness boundary in the subtitle, explicit check/refresh button, quiet `Not checked` until requested, and a compact result. Differences open `Comparison details`; a match leaves details closed. A config read failure does not erase Sync status.

Place `Advanced: index promotion` after ordinary checks in a separate native disclosure. Keep the all-schema `Search health` handoff unscoped; Control Room and Search health always return to all schemas. Do not repeat the selected schema as an overview filter.

### Narrow viewport and intermediate widths

At 640px and below, stack header and section controls, selector, summary, evidence, and actions in that order. Let button groups wrap; do not force side-by-side status/actions or a horizontal page scroll. Keep standard controls at 40px and touch/prominent/icon targets at 44px per the shared contract. Tables may scroll inside their named/focusable evidence region; full schema, index, source, attempt and task IDs wrap and remain selectable/copyable through existing exact-value controls. Do not ellipsize identities. Existing panels retain their source-owned responsive padding; do not redefine those component values as local phase spacing.

### State composition examples

| Composition | Compact rendered order |
|-------------|------------------------|
| Clear state | Header + schema selector → after complete sync/queue reads, `Sync status` / “No pending or failed sync work found” / refresh checked-time → `Index configuration` / “Not checked” / “Check index configuration” → closed `Advanced: index promotion` → all-schema Search health handoff |
| Partial sync read | Header + selected schema → explicit unavailable source/reason and any independently valid sync evidence → `Refresh sync and queue status` → Index configuration retains its own result. Never show the healthy summary for an incomplete observation. |
| Active or expired retry handoff | Header + selected schema → `Retry status` with accepted/running/terminal/unknown outcome and known exact source/job/attempt/task/index identity → `Refresh recovery status` → ordinary Sync status → Index configuration. Preserve the card and known identity even when the receipt expired; no duplicate retry CTA. |
| Pending or unknown | State sentence with source and current evidence → read-only refresh named for the observed source → exact task/queue identity and checked time → independent Sync/config sections retain their own results. |
| Configuration mismatch | Sync summary remains first → Index configuration mismatch count and freshness boundary → open comparison table with only mismatched fields promoted → runbook link if needed → advanced promotion reflects its independent eligibility result. |
| Promotion eligible | Closed advanced disclosure until requested → eligibility statement → `Promote target index` → confirmation with full schema and exact live/target pair. |
| Promotion blocked | Advanced disclosure summarizes the single actionable blocker and disabled promotion action → optional grouped evidence when the operator needs to inspect it. Never hide the reason in a tooltip. |
| Promotion accepted/running/unknown | Render status, exact task UID, and `Check swap status` in a persistent compact status row outside the disclosure's collapsible body; retain the advanced summary/action/details below. The control re-reads only that UID and is busy/disabled only during that exact observation. |
| Promotion terminal | Render matching terminal task outcome and UID persistently. Keep `Refresh index checks` separate; it checks current index/configuration, not task history. |

### Disclosure, focus, and keyboard

Use native `details/summary` through the established disclosure component. A human's manually opened or closed state survives LiveView patches. Automatically open `Comparison details` when actionable differences are present. For advanced promotion, remain closed before any action and never repeatedly force `open` on ordinary patches. When promotion starts or changes outcome, the state/UID remains visible outside the disclosure, so even a deliberately closed disclosure cannot hide active accepted/running/unknown work or a terminal error. Provide a keyboard-operable disclosure summary and a clear focus target for any jump to its details; do not steal focus during refresh or patch.

Use the shared 2px focus outline with offset, distinct from hover/pressed/disabled colors. Keep focus on the invoking action through async updates. Modal confirmation uses the existing focus containment and return behavior; Escape/cancel closes without mutation. Busy state is announced as observation activity, retains a meaningful label/icon, and disables duplicate activation only while that same request is active.

### State truth and identity rules

- `Accepted/queued` means the write was accepted or queued. `Running` requires authoritative status from the exact queue job or exact Meilisearch task. A local observer busy state and elapsed wait are not remote progress.
- Queue job completion alone is intermediate. Recovery verification requires a matching queue/task and the expected effect on the active index; delete verification requires expected absence. Preserve the schema, index, source failure, operation, attempt, replacement queue job, and matching task UID where known.
- A task terminal result is about that task only. Promotion completion requires terminal success for the returned UID. Current index state and any document effect remain separate observations.
- Failed, timed-out, inaccessible, missing, expired, restarted, stale, wrong-context, or superseded reads are `unknown` / `unconfirmed`; they do not establish remote failure, success, or zero work. Preserve prior independent valid observations and failure history.
- Rechecks are read-only and idempotent. For a retained promotion UID, `Check swap status` re-reads that exact task, including after a timeout, and never puts a second `swap_indexes` submission behind refresh. Busy/disabled applies only while that exact read is active. `Refresh index checks` is separately named for current index/configuration reads and is never presented as task polling. If the UID is missing, preserve `unconfirmed` and use the supported current-index diagnostic route without inventing a task.
- Keep full identifiers visible, line-wrapped and selectable; use existing copy affordances where available. Do not use abbreviated IDs as the only identity.
- Configuration agreement means declared settings/fields match the live index. It does not mean documents are fresh. A zero count, queue completion, accepted flash, or task completion alone says nothing broader.

### Mutation and eligibility boundary

The selected-schema workflow's only promotion mutation is the existing live/target `swap_indexes` action. Ordinary retry remains attached to the inspected source-qualified record in Failed sync work; this page displays its receipt and provides observation only. No generic repair, automatic retry/reindex/backfill, or new mutation is added. Preserve existing fail-closed eligibility: allowlisted schema, supported backend, current same-context reports, distinct observed live and target indexes, observed reindex/cutover state, no unresolved pending or failed work, and matching configuration. Retained historical failures continue to block under current policy. Recheck all prerequisites immediately before submission and retain host authorization/sudo and duplicate/in-flight guards.

Current Meilisearch documentation describes asynchronous acceptance as an enqueued task with a task UID, and distinguishes processing from succeeded/failed/canceled. The current swap endpoint describes a swap of the requested pair. These references support precise copy only; implementation follows the pinned backend/library semantics and adds no newer optional API. [Meilisearch task lifecycle](https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations), [Meilisearch swap indexes](https://www.meilisearch.com/docs/reference/api/indexes/swap-indexes). GOV.UK's native-details guidance supports placing uncommon supporting information behind a disclosure while keeping decision-critical status visible: [GOV.UK details component](https://design-system.service.gov.uk/components/details/).

## UI Considerations

Applicable state considerations resolved: **68 explicit design criteria; 0 backstop; 0 unresolved; 0 unclassified**, across ten authored surfaces. These are required implementation truths, not passing runtime tests.

Computed with the installed `ui-consideration-probe.cjs` after independent checker approval, then re-run with authored classifications and explicit resolutions. The agent reviewed the lossy detected kinds, added missed schema/confirmation controls and the unclassified advanced disclosure, and removed incidental prose matches (declared fields are not automatically forms; mentioning icons does not create an image/media surface). The maintainer's existing recommendation-following instruction and D-01–D-20 govern these refinements; no new user answer, non-interactive flag, safety approval, or dismissal is invented.

| Surface | Probe detected | Authored classification |
|---------|----------------|-------------------------|
| E1: Schema selector | nav, static-content | form, nav, interactive-control, static-content |
| E2: Sync status and evidence | list-collection, interactive-control, static-content | list-collection, interactive-control, static-content |
| E3: Retry status and evidence | list-collection, interactive-control | list-collection, interactive-control, static-content |
| E4: Index configuration comparison | form, list-collection, interactive-control | list-collection, interactive-control, static-content |
| E5: Advanced promotion disclosure and eligibility | unclassified | list-collection, interactive-control, static-content |
| E6: Promotion confirmation | media, static-content | form, interactive-control, static-content |
| E7: Promotion outcome and task check | form, list-collection, static-content | list-collection, interactive-control, static-content |
| E8: Exact identifiers and copy controls | list-collection, media, interactive-control, static-content | static-content, interactive-control |
| E9: Scoped workflow and overview navigation | interactive-control | nav, static-content |
| E10: Diagnostics and evidence disclosures | form, list-collection, static-content | list-collection, interactive-control, static-content |

The grouped rows below cover every applicable element/category pair. Copy refers to the named rows in Copywriting Contract; implementation must provide executable evidence for these truths, including held-out adverse states.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | E1, E2, E3, E4, E5, E6, E7, E10 | ✅ covered | E1: zero configured schemas renders the Empty setup copy and no observations or promotion. E2: a complete zero-work check renders the Healthy sync copy without zero counters; an unavailable check uses Error state instead. E3: a normal visit omits Retry status; an explicit invalid or expired handoff remains visibly unknown rather than silently disappearing. E4: an unrun comparison renders Configuration unrun without warnings or an empty table. E5: missing prerequisites render the specific Promotion blocked reason, never readiness. E6: missing scope or either index prevents confirmation/submission. E7: without a submitted swap, omit its task outcome row. E10: omit empty diagnostic lists; keep decision-changing uncertainty visible. |
| loading | E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 | ✅ covered | Each observation control names its own checking activity and prevents duplicate activation only while that read is active. E1/E9: selecting/navigating replaces the current scope without rendering old results as the new scope. E2/E3/E4/E7 retain the exact prior identity and distinguish local checking from authoritative remote running. E5/E10 native disclosure toggles remain synchronous and preserve manual expansion. E6 submission is in flight only once; all current authorization and prerequisite checks run server-side. E8 clipboard work gives the existing polite copy feedback without replacing the exact value. |
| error | E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 | ✅ covered | Use the source-specific error/unknown rows in Copywriting Contract. E1 never substitutes another schema for an invalid requested one. E2 and E4 failures preserve independently valid observations; failed reads never become zero or mismatches. E3 names expired/missing/wrong-context receipts and preserves known identity without enabling another retry here. E5 exposes the blocker and safe next step. E6 authorization denial or changed prerequisites submits no swap and preserves safe context. E7 a timed-out or failed read retains the returned UID and offers Check swap status, querying that exact task without resubmission; only its matching terminal failure supports Index swap failed. E8 copy failure leaves the full value selectable and gives existing feedback. E9 failed/auth-return navigation cannot silently select another schema or replay a mutation. E10 raw errors remain escaped and available behind diagnostics while the actionable summary stays visible. |
| populated | E2, E3, E4, E5, E7, E10 | ✅ covered | E2/E3 render one compact current scoped summary followed by optional evidence; positive failures or pending work surface their appropriate actions. E4 matching comparison stays quiet with optional closed details; differing dimensions open the comparison. E5 renders either specific blockers or eligible confirmation entry within Advanced: index promotion. E7 shows the exact current task UID/outcome outside collapsible content, including accepted, running, terminal, and unconfirmed states. E10 presents the requested technical facts grouped by source and keeps successful flags secondary. No state claims document freshness from configuration agreement or acceptance. |
| partial | E1, E2, E3, E4, E5, E6, E7, E10 | ✅ covered | E1/E6 require a valid current allowlisted schema and full observed index pair before mutation; missing fields cannot be filled from a stale report. E2/E4/E10 preserve valid source results and explicitly name unavailable facts rather than zero. E3 queue completion without matching task/active-index upsert or delete evidence remains intermediate or unknown; a superseded attempt, wrong host/runtime, historic task, or stale callback cannot verify recovery. E5 incomplete current prerequisites block promotion under existing policy, including retained history. E7 missing task outcome retains the exact known UID as unconfirmed; a terminal task, current index state, and document effect are reported as separate facts. |
| overflow | E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 | ✅ covered | E1/E2/E3/E4/E5/E7/E8/E9/E10 keep the page free of horizontal overflow at narrow and intermediate widths. Full module/index/source/job/attempt/task identifiers and error text wrap; technical values are never clipped or ellipsized as their only representation. Comparison tables may scroll inside their named keyboard-accessible evidence region. Buttons and navigation wrap with a readable label. Large diagnostics stay in their disclosure and do not expand the page width. |
| zero-one-many | E2, E3, E4, E5, E7, E10 | ✅ covered | E2 zero work uses the quiet Healthy sync row; one or many pending/failures use grammatical counts only when actionable, with all exact source records accessible. E3 renders one current retry and treats retained unrelated history separately, never combines multiple attempts into one success. E4 zero differences uses the match row; one or many differences show singular/plural copy and their affected dimensions in open details. E5 groups multiple blockers while promoting the first useful safe step; no blockers alone is insufficient for readiness without all current prerequisites. E7 renders only the current returned task outcome; unrelated/historic task results cannot replace it. E10 omits zero diagnostics and groups one/many facts without repetitive empty cards. |
| long-text | E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 | ✅ covered | E1/E2/E3/E4/E5/E6/E7/E8/E9/E10 preserve full long schema/index/task/source values, long error reasons, and long control labels with wrapping and responsive stacking. Confirmation shows the entire exact live/target pair without truncation; controls remain reachable by keyboard and touch. Supporting diagnostics can be disclosed, but the concise state, blocker, uncertainty, and safe action remain visible. Copy feedback does not obscure the value or move focus. No unexplained abbreviation replaces an operational identity. |

## Implementation Verification Contract

The following are required future proofs for Phase 175; this spec change did not run them and OPUX-20–22 remain pending.

| Requirement | Required executable evidence |
|-------------|-----------------------------|
| OPUX-20 — scope and meaning | Drive the rendered schema selector, scoped handoffs, browser navigation/history, and forms/modal with real clicks/submits rather than handler-only calls. Cover a non-first schema, unavailable/removed selection, explicit retry handoff and return to all-schema Control Room/Search health. Prove complete healthy reads are quiet, partial sync/config reads remain explicit, configuration mismatch opens affected details, config errors preserve independent sync results, and configuration agreement never asserts freshness. |
| OPUX-21 — exact observation | Exercise accepted/queued versus authoritative running, terminal success/failure/cancellation, and unknown/unavailable reads. Cover exact returned task UID; old/historic/wrong task; stale/superseded callback; wrong host/runtime/endpoint/Oban/repo/prefix; inaccessible/expired receipt; and missing UID. Verify queue completion alone remains intermediate, matching active-index upsert content and expected delete absence are required for recovery verification, and failed reads cannot become remote failure, zero, or success. A promotion timeout must be followed by `Check swap status` for the exact same UID, with no second swap; distinguish observer busy from remote task state. |
| OPUX-22 — mutation gates and outcome | Use actual rendered confirmation and authorization controls on owned disposable mutation stacks. Cover exact full schema/live/target pair, host authorization/sudo return without replay, cancel/focus return, double submission, and prerequisite or allowlist change immediately before submit. Prove retained failure-history blockers, current fail-closed eligibility, matching task terminal result, and separate current-index/config/document observations. Exercise both standalone and mounted Ops entry points; do not mutate the retained feedback preview. |
| OPUX-20–22 — rendered design | Capture affected before/after compositions in Light and Dark at 390px, a relevant 768px intermediate width, and 1440px desktop; include System appearance, reduced motion, keyboard/focus, disclosure persistence, wrapping/overflow and copy feedback. Use existing focused browser/mounted lanes and token contrast checks. Use current project lanes; add no dependency, required service, paid judge, or routine manual-UAT condition. Preserve retained previews, the original dirty checkout, frozen Phase 173 source, and unrelated resources. |

These criteria define future phase evidence; they do not state that tests, screenshots, hosted CI, or verification have passed.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | Not applicable; no shadcn or third-party registry is used |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS (manual system; installed inventory omitted)

**Approval:** approved 2026-10-10 (UI-SPEC VERIFIED APPROVED; checker reviewed_at `2026-10-10 12:04 UTC`; provenance: final checker result, all 7 dimensions PASS)
