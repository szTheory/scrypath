# Design System: Scrypath Operator UI

## Overview

ScrypathOps is an Ecto-first search operations interface for Phoenix applications. It should make the current observation, its limits, and the safe next action easy to scan. The delivered UI uses a restrained neutral shell, explicit task copy, and small local accents. Keep operational evidence and task wording authoritative; do not make every route look or read like the same dashboard.

The implementation authority is [`app.css`](scrypath_ops/assets/css/app.css), its companion [`DESIGN-TOKENS.md`](scrypath_ops/assets/css/DESIGN-TOKENS.md), and the exported functions in [`OpsUi`](scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex). This guide describes the patterns those sources demonstrate.

## Colors

The page floor is warm neutral in light (`#f7f6f3`) and dark charcoal in dark (`#111419`). Resting surfaces use white / `#191e25`; the next neutral surface uses `#efeee9` / `#222831`. Primary interaction is violet (`#5b4ad1` / `#aaa0ff`). Use the named semantic status tokens and their AA-checked foreground pairs for warnings and failures. Status color stays local to explicit text or an icon; verdict, metric, and record surfaces remain neutral.

System appearance follows the operating-system preference when no explicit theme is selected. The visible System, Light, and Dark controls represent the saved preference, not just the effective colors.

## Typography

Use the system sans-serif stack for interface copy and the technical monospace stack for exact identifiers and evidence. The established scale is 24px page title, 18px section heading, 16px subsection or record heading, and 14px body, values, labels, help, and action copy. The 11px/12px exceptions are for short timestamps, badges, eyebrows, and optional metadata only.

## Layout

The shared shell owns the top-level page rhythm with `space-y-4`; the 24px `space-y-ops-page-gap` role is used for deliberate group spacing inside selected surfaces. Keep the shell's direct children free of extra top margins. Use the responsive native controls and component spacing already defined in CSS; at the compact shell breakpoint, navigation and theme controls keep their named, reachable targets.

The six routes have different scan paths: Control Room goes from fleet observation to verdict and three task routes; Search health goes from fleet summary to worst-first schema evidence; Failed sync work goes from selected schema to eligible jobs and recovery; Sync and drift separates reconciliation, contract, freshness, recovery, and gated promotion; Search keeps target/query controls next to submitted attribution and per-index results; Playbooks separates its catalog, preview, run outcome, and import. Preserve these task-specific orders.

## Elevation & Depth

Hierarchy comes from neutral surface steps, spacing, borders, and restrained shadows. Dark panels use the named seated-depth supplement; light panels retain their existing subtle lift. Keep the shell floor flat. Reserve glow for the existing active route or path anchors; never add it to resting evidence, broad backgrounds, or status surfaces.

## Shapes

Use the existing `ops` radius roles: control, surface, and overlay. Keep buttons, fields, panels, records, and dialogs on those named radii rather than introducing one-off corner values. Focus remains the global 2px `:focus-visible` outline with a 2px offset.

## Components

`ScrypathOpsWeb.OpsUi` is the shared component authority. Use the component whose semantics fit: `ops_verdict` for a neutral decision summary, `ops_status` or `ops_notice` for explicit operational feedback, `ops_result_row` for evidence, `ops_object_item` for a managed playbook, and `ops_disclosure` / `ops_code_block` for secondary technical detail. Shared components should align shared function while each LiveView retains its own route, evidence order, and recovery language.

| Surface | Demonstrated grouping |
| --- | --- |
| Control Room | A labelled health section holds the refresh issue, observed verdict or specific setup state, Search health handoff, and three distinct intent cards. |
| Search health | A summary verdict and four metrics precede worst-first schema cards; Backend and Queue observations stay separately labelled. |
| Failed sync work | Schema selection and observation summary precede retryable job evidence, confirmation, retained details, and the recovery handoff. |
| Sync and drift | Reconciliation, contract drift, document freshness, ordinary recovery, and advanced promotion remain separate sections. |
| Search | Target mode, schemas, query, and page size lead into a labelled Results section with attributed per-index outcomes and an independent capture action. |
| Playbooks | Workspace files lead into separate preview, run outcome, Search handoff, and import tasks. |

The dynamic design-token contract requires every current `OpsUi` export to appear in `DESIGN-TOKENS.md`; it does not prescribe a fixed export count.

## Do's and Don'ts

- Do state what was observed, what is unavailable, and what an action will do; distinguish an empty result from missing configuration, a partial observation, or a failed request.
- Do keep full schema, index, task, file, and failure identities available in text, and keep controls reachable at narrow widths.
- Do pair status color with a visible label and keep action feedback attached to the action that produced it.
- Do keep Search results attributable to submitted targets and criteria, and Playbook outcomes attributable to their saved file or imported draft.
- Don't infer health or completion from zero counts, accepted dispatch, a toast alone, or a color.
- Don't merge the six scan paths into a generic card template, add decoration that competes with operational evidence, or add a dependency for a pattern that the existing LiveView and component seams already cover.
- Don't restore the earlier shell wash or sliding selection pill. The current shell is flat and the three native theme buttons expose the selected preference with `aria-pressed`.
- Don't add arbitrary top margins between direct shell children or animate layout/reflow and result-list insertion; the shared rhythm and motion rules already define those behaviors.
