---
name: ScrypathOps
description: A clear, calm workspace for operating search in Phoenix and Ecto applications.
colors:
  primary: "#5b4ad1"
  primary-dark: "#6c5ce7"
  copper: "#a85d2e"
  copper-dark: "#c17a3e"
  page: "#f5f6f8"
  surface: "#ffffff"
  surface-dark: "#141923"
  text: "#141923"
  text-dark: "#f4f1ea"
  border: "#d7dbe1"
  border-dark: "#2a3446"
  info: "#5ca9e6"
  success: "#4fae74"
  warning: "#d9a441"
  error: "#d96262"
typography:
  title:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "1.5rem"
    fontWeight: 600
    lineHeight: 1.3
  section:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: 1.5
  action:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 600
    lineHeight: 1.5
  code:
    fontFamily: "ui-monospace, Cascadia Code, Menlo, monospace"
    fontSize: "0.75rem"
    fontWeight: 400
    lineHeight: 1.5
rounded:
  sm: "4px"
  md: "6px"
  control: "6px"
  surface: "8px"
  overlay: "12px"
spacing:
  1: "4px"
  2: "8px"
  3: "12px"
  4: "16px"
  5: "20px"
  6: "24px"
  field: "6px"
  row: "16px"
  section: "24px"
  panel: "20px"
  page-gap: "24px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#f4f1ea"
    typography: "{typography.action}"
    rounded: "{rounded.control}"
    padding: "0 12px"
    height: "40px"
  button-quiet:
    backgroundColor: "transparent"
    textColor: "{colors.text}"
    typography: "{typography.action}"
    rounded: "{rounded.control}"
    padding: "0 12px"
    height: "40px"
  panel:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.surface}"
    padding: "20px"
---

# Design System: ScrypathOps

## Whole-workflow review — 2026-10-09

The [operator UX rubric](.planning/reference/OPERATOR-UX-RUBRIC.md) carries the maintainer's feedback into every remaining UI phase. Review all six surfaces as tasks: purpose, scope, state, useful next action, then optional diagnostics. A tooltip does not justify an irrelevant metric. Quiet healthy states must still distinguish missing evidence from success.

Use these terms consistently in interface copy:

| Term | Meaning |
| --- | --- |
| Schema | A type of application record indexed for search, such as Product; usually backed by a database. Preserve its full module name in technical evidence. |
| Index | The search backend's collection of searchable documents for a schema. |
| Queue job | Work waiting or running in the application's background job queue. |
| Backend task | Work accepted by Meilisearch; acceptance alone does not establish completion. |
| Index configuration | Declared fields and search settings compared with the live index. Agreement does not establish document freshness. |
| Playbook | A saved, repeatable search check. File management is secondary to choosing, previewing, and running it. |

Prefer task language in headings and instructions; keep framework names, raw errors, exact timestamps, and IDs in diagnostic evidence. Keep essential failure and safety facts visible. Native disclosures should hold uncommon options, management controls, and detailed successful checks, without adding dependencies.

## Maintainer feedback — 2026-10-08

The current refinement uses a neutral gray light page (`#f5f6f8`), white panels, and a cool neutral muted surface (`#edeff2`). Violet interaction, copper brand accents, and dark surfaces retain their existing roles.

- Control Room and Search health always show all configured schemas, with no selected-schema context or filter. Normalize old overview schema queries to the unscoped URL, replacing the current history entry. Each schema’s recovery link chooses that exact schema on a workflow with a visible selector. Preserve selection between Failed sync work and Sync and drift; sidebar, mobile navigation, palette, and handoffs return to unscoped Search health. Full module names remain readable and wrap at namespace separators.
- Label the summary “Search health”; the healthy headline says “No sync failures found” and offers Search health. Detailed counts and source evidence live on that diagnostic page. This does not establish drift-free indexes or promotion readiness. Failures and unavailable observations remain explicit.
- Search health counts schemas, incomplete checks, failed backend tasks, and failed queue jobs. Queue visibility belongs in each schema's diagnostic group rather than a misleading fleet count of “queues observed.” Optional information icons explain terms and consequences on hover, keyboard focus, or tap. Connect schemas to the app's records, usually stored in a database; avoid internal app names and observation jargon. Explanations stay readable under the pointer, dismiss with Escape or an outside click, and stay within the viewport. Keep failure and unavailable states visible without opening help.
- Show issue cards only for positive counts. Schema coverage is quiet metadata beside “Per-schema health.” Schemas with no pending or failed work start as compact native disclosures; pending, retrying, failed, or unavailable checks open their details by default. Suppress zero work counters inside details while retaining last-success evidence and deliberate drill-in. An unused queue in inline/manual mode is not an unavailable check. Failed sync work also omits zero reason counts and its duplicate healthy rollup; adjacent check tables use “Check” and “Sync status” rather than “Signal.”
- Click the human-readable operational timestamp to copy its exact source value. Show a brief, accessible toast after clipboard success; keep copy failures and selectable exact evidence visible. Routine checked times remain plain metadata.

## Maintainer revision direction — 2026-10-06

The tokens above describe the implementation baseline. The following direction is captured for the next UI milestone and has not yet been implemented:

- Use flat neutral page backgrounds; remove the decorative operator-shell gradient.
- Keep metric and schema surfaces neutral. Zero errors do not need green outlines; warnings should use restrained local text/icon cues rather than large yellow fills or colored card outlines.
- Reconsider shared surface, status, and quiet-action interaction colors together in light/dark comps. Existing hex values and the exploratory brand book are open to revision.
- Theme selection shows exactly one chosen preference. System remains the sole selected option when it follows the OS appearance.
- Operational last-success timestamps use human-readable text with exact evidence available to copy and truthful brief feedback. Routine checked-time metadata remains free of copy controls; time displays do not tick continuously.

See [.planning/reference/OPERATOR-UI-REFINEMENT.md](.planning/reference/OPERATOR-UI-REFINEMENT.md) for the concrete feedback, scope, and acceptance criteria. Use this direction when designing the next comp; do not reproduce the rejected treatments from the baseline.

## Overview

**Creative North Star: “The Operator’s Signal Desk”** — a working description inferred from the current product and UI, not a ratified public brand line.

ScrypathOps is a task workspace for engineers who need to understand and operate search over time. Its visual language should make the current state easy to read, put the next safe action close to that state, and keep advanced or exploratory work available without making it compete with incident response.

The current system pairs neutral surfaces with dark, neutral text and a restrained violet action color. Copper adds a small brand accent. System sans-serif keeps the interface familiar; monospace is reserved for exact technical identifiers and values. Aim for calm, legible, and deliberate. The detailed AI-generated brand book is exploratory; product facts and the implemented tokens take precedence.

**Key Characteristics:**
- Task-first hierarchy: state, affected object, next action.
- Compact, scannable operational information with readable instructions.
- Neutral light surfaces and a carefully matched dark theme.
- Violet for interaction; copper for brand detail; semantic colors for status.
- Shared controls and language across the operator surfaces.

## Colors

The palette is mostly neutral, with violet for action and selection, copper for restrained brand detail, and distinct semantic status colors.

### Primary
- **Scrypath Violet** (`#5b4ad1`, dark theme `#6c5ce7`): selected navigation, primary actions, links, and focus indicators.

### Secondary
- **Copper** (`#a85d2e`, dark theme `#c17a3e`): small brand accents and eyebrow labels. Copper is never a health or failure status.

### Neutral
- **Neutral page** (`#f5f6f8`): light-theme page background.
- **White surface** (`#ffffff`): light-theme resting panels and cards.
- **Dark page** (`#0c0f14`): dark-theme page background.
- **Dark surface** (`#141923` / `#1b2230`): resting and raised dark-theme surfaces.
- **Primary text** (`#141923` / `#f4f1ea`): readable content in light and dark themes.
- **Borders** (`#d7dbe1` / `#2a3446`): separation and control boundaries in light and dark themes.
- **Status** (`#5ca9e6`, `#4fae74`, `#d9a441`, `#d96262`): info, success, warning, and error respectively; pair each with explicit text and shape cues.

**The Status Is Not Branding Rule.** Violet and copper do not substitute for info, success, warning, or error. Copper is decorative brand detail only.

## Typography

**Display Font:** system UI sans-serif (with platform fallbacks)  
**Body Font:** system UI sans-serif  
**Label/Mono Font:** `ui-monospace`, Cascadia Code, Menlo, monospace

**Character:** Familiar and direct, with a clear size and weight hierarchy. Technical values may use monospace, but instructions, failure reasons, and action labels stay in the readable body scale.

### Hierarchy
- **Page title** (600, 24px, 1.3): one clear title for each operator surface.
- **Section heading** (600, 18px, 1.3): the next meaningful group of information or actions.
- **Card/subsection heading** (600, 16px): a record, schema, or grouped task.
- **Body** (400, 14px, 1.5): explanations, failure reasons, and operating instructions.
- **Action and field label** (600 / 500, 14px): controls and primary instructions.
- **Metadata** (11–12px): short timestamps, badges, eyebrows, and secondary technical context only.

**The Small Text Is Secondary Rule.** Do not use metadata sizing for the only explanation needed to choose an action or understand a failure.

## Layout

Use a 4/8/12/16/20/24px spacing family, with 24px between major page sections and 20px panel padding (16px on narrow screens). Keep page content within the established 48rem default and 80rem wide bounds. At 1280px, the 17rem navigation rail sits beside the content; at narrower widths, the navigation becomes a drawer and page sections stack.

Organize each surface around the operator’s current job. Keep recovery ahead of exploration in navigation. Use direct links and the command palette for frequent users; keep guidance contextual rather than turning the app into a wizard. Show schema choices as one visible, vertically stacked native radio group, with the short name first and the full module name readable beside it. Do not change control type at an arbitrary number of options.

## Elevation & Depth

The interface uses quiet borders, tonal surface steps, and small shadows. The revised direction uses flat page backgrounds and low-lift panels in both themes. Reserve the strongest elevation for overlays and moments that need attention; keep status cues localized and meaningful.

### Shadow Vocabulary
- **Resting surface** (`0 1px 2px` with a low-contrast content tint): ordinary panels and cards.
- **Raised surface** (`0 2px 10px` with a low-contrast content tint): focused summary or hover elevation.
- **Overlay** (`0 8px 24px` with a low-contrast content tint): modal, command palette, and transient flash.

**The Grouping Earns Its Surface Rule.** Add a panel or card when it groups a distinct task or state. Avoid wrapping compact cards inside decorative containers that add no new grouping or meaning.

## Shapes

Use modest 4px, 6px, and 8px corners for controls and surfaces; 12px belongs to overlays. Borders are quiet and functional. Pills are reserved for compact status or category tags. Keep selectable schema rows simple rather than styling every radio option as a separate card.

## Components

### Buttons
- **Shape:** 6px radius, shared 40px standard height; prominent and icon-only targets may be 44px.
- **Primary:** Violet fill for the main committing or submitting action.
- **Quiet:** Transparent or low-emphasis surface treatment for refresh, navigation, and secondary actions.
- **States:** Use the shared visible focus outline and restrained hover/press response. Loading feedback must retain the icon and label; reduced-motion preferences disable decorative motion.

### Cards / Containers
- **Shape:** 8px corners with a quiet border and low resting lift.
- **Use:** Group information that belongs together; do not add another card layer around every section or metric.
- **Hierarchy:** A warning summary should keep the health result and the next safe action visually connected without letting unrelated controls appear to belong inside the warning.

### Inputs and Schema Choices
- **Inputs:** 40px control height, clear label, 6px corners, and the shared violet focus outline.
- **Schema choices:** Use native radios in a single visible list; keep the complete module name available and wrap it instead of truncating it.

### Navigation
- **Desktop:** Persistent left rail with grouped Home, Recover, and Explore destinations. The current destination uses the selected violet state.
- **Narrow screens:** The rail becomes a drawer. Preserve the same labels and grouping.
- **Page trail:** Show only the current group and current page; the landing page has no trail.

### Status and feedback
- **Health:** Pair a plain-language status with a short reason and useful next step. Do not make operators infer status from color alone.
- **Refresh:** Use the shared icon-and-label control, keep placement consistent within each page type, and show brief confirmation when new state has been checked.
- **Toast:** Informational confirmations are short-lived and polite; errors remain visible until dismissed.
- **Time:** Show when data was checked, but do not add copy controls unless copying the exact timestamp supports a real task.

## Do's and Don'ts

### Do:
- **Do** put the operational answer and next safe action before secondary diagnostics.
- **Do** use one shared component for repeated controls and status patterns.
- **Do** preserve selected schema, task identity, and exact diagnostic evidence across recovery handoffs.
- **Do** make success, partial results, unavailable observations, and empty configuration visibly distinct.
- **Do** use existing tokens and native controls before adding new dependencies or custom interaction patterns.
- **Do** keep light/dark theme behavior and reduced-motion behavior in parity.

### Don't:
- **Don't** repeat the same explanation in both a summary and a next-steps block.
- **Don't** let decorative nested cards compete with the information inside them.
- **Don't** say that a job is complete when it has only been accepted or queued.
- **Don't** truncate the only visible identifier for a schema, index, or task.
- **Don't** use copper as a status color or add brand metaphors to operational labels.
- **Don't** add motion, controls, badges, or dependencies without a clear user task they serve.
