# Design System: Scrypath Operator UI

## Overview

ScrypathOps is an Ecto-first search operations interface for Phoenix applications. It should make the current observation, its limits, and the safe next action easy to scan. The delivered UI uses a restrained neutral shell, explicit task copy, and small local accents. Keep operational evidence and task wording authoritative; do not make every route look or read like the same dashboard.

The implementation authority is [`app.css`](scrypath_ops/assets/css/app.css), its companion [`DESIGN-TOKENS.md`](scrypath_ops/assets/css/DESIGN-TOKENS.md), and the exported functions in [`OpsUi`](scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex). This guide describes the patterns those sources demonstrate.

## Colors

The page floor is cool neutral in light (`#f3f5f8`) and dark charcoal in dark (`#111419`). Resting surfaces use white / `#191e25`; the next neutral surface uses `#edf1f5` / `#222831`. Primary interaction is violet (`#5b4ad1` / `#aaa0ff`), with active navigation on a soft selected fill. The System/Light/Dark picker uses a neutral selected surface. Use the named semantic status tokens and their AA-checked foreground pairs for warnings and failures. Status color stays local to explicit text or an icon; verdict, metric, and record surfaces remain neutral.

System appearance follows the operating-system preference when no explicit theme is selected. The visible System, Light, and Dark controls represent the saved preference, not just the effective colors.

## Typography

Use the system sans-serif stack for interface copy and the technical monospace stack for exact identifiers and evidence. The established scale is 24px page title, 18px section heading, 16px subsection or record heading, and 14px body, values, labels, help, and action copy. The 11px/12px exceptions are for short timestamps, badges, contextual notes/help, and optional metadata only.

## Layout

The shared shell owns the top-level page rhythm with `space-y-4`; the 24px `space-y-ops-page-gap` role is used for deliberate group spacing inside selected surfaces. Keep the shell's direct children free of extra top margins. Use the responsive native controls and component spacing already defined in CSS; at the compact shell breakpoint, navigation and theme controls keep their named, reachable targets.

Navigation is a flat list with Search directly after Control Room. The six task routes have distinct purposes: Control Room gives a concise sync summary and entry points; Search puts schema, query and result limit together before attributed results; Search health prioritizes exceptions and separates Meilisearch tasks from background jobs; Failed sync work shows failed and retrying operations with eligible actions; Sync and drift loads read-only settings automatically and shows actual declared/live differences, with operation-specific recovery only when applicable; Saved searches separates saved inputs, a loaded or imported draft, and each run's results. A quiet Help destination at the bottom of navigation explains these tasks inside the installed app. Existing task routes and Playbook APIs/JSON remain unchanged; Help adds `/help` under the configured mount.

## Elevation & Depth

Hierarchy comes from neutral surface steps, spacing, borders, and restrained shadows. Dark panels use the named seated-depth supplement; light panels retain their existing subtle lift. Keep the shell floor flat. Reserve glow for the existing active route or path anchors; never add it to resting evidence, broad backgrounds, or status surfaces.

## Shapes

Use the existing `ops` radius roles: control, surface, and overlay. Keep buttons, fields, panels, records, and dialogs on those named radii rather than introducing one-off corner values. Focus remains the global 2px `:focus-visible` outline with a 2px offset.

## Components

Use visible native radio rows for schema choices and plain context for a single schema. Page headings stand on their own without a repeated “Operator workspace” kicker. Action groups, diagnostic subgroups, and disclosures do not add another card around a button, row, or existing task surface. Prefer headings, spacing, and separators; preserve real danger feedback and protected confirmation behavior.

`ScrypathOpsWeb.OpsUi` is the shared component authority. Use the component whose semantics fit: `ops_verdict` for a neutral decision summary, `ops_status` or `ops_notice` for explicit operational feedback, `ops_result_row` for evidence, `ops_object_item` for a managed playbook, and `ops_disclosure` / `ops_code_block` for secondary technical detail. Shared components should align shared function while each LiveView retains its own route, evidence order, and recovery language.

| Surface | Demonstrated grouping |
| --- | --- |
| Control Room | A short problem/scope/action summary, followed by Try a search and Check sync and settings. |
| Search health | A cause-specific summary and worst-first schemas. Positive work counts stay visible; empty sources use one neutral statement. Unknown and retained evidence remain explicit. |
| Failed sync work | Native schema selection, compact cohort summary, source-qualified IDs, error and eligible Retry. Retry queued is distinct from completion; delete confirmation remains protected. |
| Sync and drift | Header Refresh checks sync and settings. Settings load automatically with bounded generation-scoped reads; real differences use declared/live columns. Correlated document/retry sections appear only with applicable evidence; promotion remains advanced and confirmed. |
| Search | A compact form contains schemas, query and result limit. Results stay attributed to submitted criteria. Saving preserves inputs, never returned documents. |
| Saved searches | A flat catalog offers Preview and Run, with secondary file actions. Storage folder is secondary context. Draft, saved file and run provenance remain separate. |

Timestamps are single, keyboard-accessible copy buttons with restrained text styling and a small clipboard affordance. UTC is the default; one Time control beside theme preferences switches display to the browser's local zone and persists that choice. Each absolute time names its zone; the original source precision is copied unchanged. Copy feedback waits for the browser outcome and uses the shared overlay toast without changing page geometry or moving focus. Failure feedback persists with selectable exact source content. Unknown times have no copy control. Retained observations keep their source identity and original check time.

The dynamic design-token contract requires every current `OpsUi` export to appear in `DESIGN-TOKENS.md`; it does not prescribe a fixed export count.

## Do's and Don'ts

- Do state what was observed, what is unavailable, and what an action will do; distinguish an empty result from missing configuration, a partial observation, or a failed request.
- Do keep full schema, index, task, file, and failure identities available in text, and keep controls reachable at narrow widths.
- Do pair status color with a visible label and keep action feedback attached to the action that produced it.
- Do keep Search results attributable to submitted targets and criteria, and Playbook outcomes attributable to their saved file or imported draft.
- Don't infer health or completion from zero counts, accepted dispatch, a toast alone, or a color.
- Don't merge distinct scan paths into a generic card template, add decoration that competes with operational evidence, or add a dependency for a pattern that the existing LiveView and component seams already cover.
- Don't restore the earlier shell wash or sliding selection pill. The current shell is flat and the three native theme buttons expose the selected preference with `aria-pressed`.
- Don't add arbitrary top margins between direct shell children or animate layout/reflow and result-list insertion; the shared rhythm and motion rules already define those behaviors.

## Follow-up interaction contracts

Search uses a flat form: mode and schema choices precede query and result limit, with privacy guidance beside the query. The limit bounds the combined response in multi-schema mode; Previous and Next use supported page/offset requests. Keep the default request budget of 50 and allow the host to choose a positive budget independently of the core multi-query per-entry guard.

Readable results use returned data only, with modest title/description heuristics and explicit scalar, nested and missing-value treatment. Never infer associations from identifier suffixes or fetch database records for presentation. Exact complete Elixir payloads remain inspectable and copyable. Use one compact primary list in backend combined order. Keep full typed fields and raw inspection available; no-hit source projections do not establish no matches.

Submitted criteria stay quiet while controls match. Show the last-run context when draft controls differ; results and saved inputs still belong to the submitted run. Put Save search beside Run search, disabled while inputs differ from the submitted run and explain the server-side Saved searches destination. Readiness flags do not need visible narration.

Use a restrained `ops_help_link` for task-adjacent Help in a new tab; meaningful fragment headings remain visible below the sticky shell. Use native Help for task explanations and optional external developer docs for deeper setup. Health distinguishes Schema module, Meilisearch index, document tasks and configured synchronization method. Use consistent icons for pending, retrying and failed activity; reserve error color for failures. pending work alone is not a failure. Native selects inherit the shared chevron spacing instead of overriding their background image or end padding.
