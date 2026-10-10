---
phase: "176"
slug: "search-and-playbooks"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-10"
---

# Phase 176 — UI Design Contract

> Visual and interaction contract for the Search and Playbooks operator surfaces. Requirements OPUX-23–25 remain pending; comps are static design evidence. CONTEXT.md D-01–D-27 governs scope and preserved behavior. This contract carries forward Phase 173's approved shared visual world.

## Design System

| Property | Value |
| --- | --- |
| Tool | Manual, existing ScrypathOps token/component system |
| Preset | Not applicable; Phoenix LiveView, not a React/shadcn application |
| Component library | ScrypathOps `OpsUi` / `CoreComponents`, Tailwind CSS v4 and vendored daisyUI primitives |
| Icon library | Existing Heroicons through `CoreComponents.icon`; use native text/control affordances in comps |
| Font | `system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif` |
| Technical font | `ui-monospace, "Cascadia Code", Menlo, monospace` for full filenames, module identifiers, query evidence, and JSON |
| Authority | Inherited Phase 173 contract, then `scrypath_ops/assets/css/app.css`, `DESIGN-TOKENS.md`, and existing `OpsUi` functions |
| Registry | No shadcn or third-party registry; no dependency or registry block is introduced |

Use native buttons, field controls, `<details>`, uploads, and the existing OpsModal behavior. Do not introduce another component package. The static comps use local system fonts, token-matched CSS, no downloaded assets, and blocked network requests; they do not duplicate the app shell's real brand assets.

## Component Inventory

Enumerated by `rg -n '^  def [a-z_]+\(assigns\)' scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — 49 components — scrypath_ops@0.1.0 — 2026-10-10.

Provenance: `scrypath_ops/mix.exs` supplies the local package version; `scrypath_ops/mix.lock` resolves Phoenix 1.8.12 and Phoenix LiveView 1.1.33. This is a non-exhaustive list of known-good existing exports, never a closed allowlist. Check the actual exports/source for a suitable component beyond this list before adding one.

| Component | Import path | Notes |
| --- | --- | --- |
| `ops_page_header`, `ops_heading`, `ops_toolbar`, `ops_section`, `ops_panel` | `ScrypathOpsWeb.OpsUi` | Keep one page heading and distinct sections; use 24px section rhythm without wrapper panels around every subgroup. |
| `ops_button`, `ops_link_button`, `ops_action_group` | `ScrypathOpsWeb.OpsUi` | Reuse action variants, 40px standard target, focus and busy/disabled behavior. |
| `ops_fieldset`, `ops_field`, `ops_text_input`, `ops_number_input`, `ops_textarea`, `ops_schema_select`, `ops_segmented_control`, `ops_checkbox_list` | `ScrypathOpsWeb.OpsUi` | Search target, query, page-size, capture, playbook save, and import controls. Keep labels/hints associated. |
| `ops_status`, `ops_notice`, `ops_badge`, `ops_tone_chip` | `ScrypathOpsWeb.OpsUi` | Concise truthful completed, partial, running, error, and unavailable feedback with local state cues. |
| `ops_empty_state`, `ops_empty_hero`, `ops_loading` | `ScrypathOpsWeb.OpsUi` | Not-run, zero-hit, empty-workspace, loading, and setup states; do not add an empty-state Run submit. |
| `ops_data_card`, `ops_result_row`, `ops_object_list`, `ops_object_item` | `ScrypathOpsWeb.OpsUi` | Actual returned hits and catalog rows. Keep one surface per meaningful record and filenames readable. |
| `ops_disclosure`, `ops_code_block`, `ops_inline_code` | `ScrypathOpsWeb.OpsUi` | Closed-by-default secondary JSON, raw hit/response, failure, and diagnostic evidence. |
| `ops_upload_box`, `ops_modal` | `ScrypathOpsWeb.OpsUi` | Existing bounded JSON upload/paste and file-management dialogs. Reuse the established modal hook and semantics. |

## Spacing Scale

| Existing role | Value | Usage |
| --- | --- | --- |
| `ops-1` | 4px | Tight icon/label or inline gaps |
| `ops-2`, control gap | 8px | Adjacent buttons, controls, and compact groups |
| `ops-3` | 12px | Label/help/control groupings and compact section interiors |
| `ops-4`, row | 16px | Rows, narrow panel padding, and form group gaps |
| `ops-5`, panel | 20px | Existing desktop surface interior padding |
| `ops-6`, section, page gap | 24px | Major section and page rhythm |

Exceptions: preserve Phase 173's locked existing 6px label-to-input gap; use 16px surface padding at widths up to 760px and 12px page/surface padding at widths up to 380px. Use 8px or 12px for compact gaps/insets and 16px for row padding; do not introduce 10px gaps or 14px row padding. These inherited exceptions do not authorize new arbitrary layout steps. Standard actions and fields are 40px high; icon-only, theme, or prominent controls keep the existing 44px minimum.

## Typography

| Role | Size | Weight | Line height |
| --- | --- | --- | --- |
| Body, controls, help, failure reasons | 14px | 400; labels/actions may use 600 | 1.5 |
| Subsection heading | 16px | 600 | 1.3 |
| Section heading | 18px | 600 | 1.3 |
| Page title | 24px | 600 | 1.3 |

Phase content uses exactly two text weights: 400 and 600. Inherited shell navigation group labels retain their existing 700 weight. Primary content uses only the four declared sizes. Preserve inherited 11px/12px exceptions only for compact badges and short optional metadata such as timestamps and summary field keys; required instructions, breadcrumbs, labels, code/technical evidence, and errors use the 14px body size. Use the technical font for full identifiers and exact evidence, not explanatory copy.

## Color

The inherited composition is approximately 60% dominant flat neutral page, 30% neutral surfaces, and up to 10% interaction accent. The accent is a budget, not a target fill. Continue Phase 173's warm-neutral light and neutral dark system:

| Role | Light | Dark | Usage |
| --- | --- | --- | --- |
| Dominant page | `#f7f6f3` | `#111419` | Flat shell/page floor |
| Secondary surface 1 | `#ffffff` | `#191e25` | Resting form, result, catalog, and preview surfaces |
| Secondary surface 2 | `#efeee9` | `#222831` | Muted attribution, quiet hover, and restrained grouping |
| Border | `#d9d8d2` | `#353d48` | Quiet structural separators |
| Primary text | `#202124` | `#f1f2f4` | Required copy and controls |
| Supporting text | `#55585e` | `#bec3ca` | Readable supporting copy and metadata |
| Interaction / focus | `#5b4ad1` | `#aaa0ff` | Primary action, current navigation/choice, actual links, and visible focus |
| Selected soft fill | `#eeebff` | `#302b4c` | Current navigation and selected mode only |
| Warning text/icon | `#805000` | `#f2c66d` | Local draft/replacement warning paired with text |
| Error/destructive text | `#ad2922` | `#ffaaa2` | Observed request failures, invalid form copy, final destructive action |

Accent reserved for: the single primary submit per task, selected destination or mode, conventional links/disclosure summaries, and independent keyboard focus. Do not color the whole form, result record, index card, or management group as a state. Completed responses, returned-hit counts, zero hits, and partial-result attribution remain neutral. Use only the declared warning and error colors for local warning/failure cues; name partial, failed, and unavailable states in text. Copper remains a small identity detail and is not a status color. Preserve WCAG AA contrast for actual foreground/background pairs and 3:1 non-text focus cues.

## Responsive Geometry and Layout

The composition is one vertically scrolling workspace; do not split editing and results into independently scrolling panes or make the forms a two-column editor/preview. Preserve Search's reading order: target/mode and selected indexes → query → page size → one Run search button → attributed results/hits → optional save form. On desktop, use paired fields only within a stage when labels remain obvious; query occupies the available row width. At narrow widths, all fields, result explanation, and actions take the full content width in the same order.

For Playbooks, order the page catalog → selected preview and common run/save actions → run results → import/upload/paste tools. The catalog row keeps Load preview and the clearly named Run without preview shortcut outside its closed Manage disclosure. Keep import discoverable at the catalog heading and in the empty-workspace state. The preview is not a wizard step or approval gate.

Use the inherited shell geometry: the 272px rail appears at 1280px and wider; below 1280px the existing header/drawer is used. The `:wide` content container is `max-w-7xl` (1280px). Horizontal page/header padding is 16px by default, 24px from 640px, and 32px from 1024px; it is 12px at 380px and below. Keep a 24px section rhythm at desktop and narrow widths. At 760px and below, stack paired inputs and metadata; put multi-index status beside/under each complete identifier without clipping. Let every button group wrap, retain readable control labels, and keep filenames, modules, queries, and JSON breakable at arbitrary boundaries. No horizontal document overflow is allowed.

Playbook modal width is at most 480px and otherwise viewport width minus 32px; modal height is at most viewport height minus 32px, with internal scrolling for long content. Escape, close, Cancel, and submission controls remain visible and reachable at narrow widths.

## Search Page Contract

- Use the existing `Search` page heading and concise explanation. Preserve the existing exploratory-query / no-secrets-or-PII notice and page-size cap guidance.
- One form contains the native Search mode choice (Single index / Multi index), visible index selection, query field, page-size input, and one `Run search` submit in that order. Preserve ordinary Enter submit. Multi-index selection remains bounded by the host-configured schema cap (1–10, default 10); page size remains bounded by the host-configured maximum and library ceiling of 50. Missing allowlist/backend uses native disabled semantics and an adjacent concrete configuration explanation; retain the normal action label while busy and block duplicate submit through the existing guard.
- Results lead with the actual last submission: mode, all submitted target index names, exact query, page size, and run identity/time where available. If editable form fields/URL criteria change while the old response remains visible, label that response as the last run and preserve its own submitted criteria. Never label it from current controls. A new run clears/replaces run-specific result/capture state according to current ownership; a mode change retains existing capture invalidation. No run history product is added.
- Distinguish not run, running, completed response, completed zero hits, partial response, request failure, missing runtime/backend, and absent allowlist. A zero-hit result is a successful result. A multi-index result with any per-index failures is partial; show each returned/no-hit/failed index, a concise failure reason and next useful check in the open page flow. Failure details may be disclosed, but the partial state and recovery sentence remain visible. Announce the concise outcome/count through the existing status semantics; do not make the entire hit list a live region or move focus on normal submit.
- Keep raw hit payloads, raw per-index responses, merge traces, and federation metadata in closed, explicitly named native disclosures. Keep the federation limitation visible: merged order is not one global relevance score. Disclosure changes presentation, not evidence access. Preserve current query-safety notice; do not add logging/export claims.
- Do not add a second `Run current search` control to the initial/empty result state. The no-run empty state instructs the operator to use the form above. Keep raw diagnostics optional and hit summaries/counts readable.
- `Save as playbook` appears only when the submitted response meets existing actual-response eligibility. It opens a compact progressive form associated with that last run. A successful zero-hit single-index response and eligible partial multi-index response may be saved. Save the run's validated criteria and optional metadata, never result documents, a frozen response, or a promise that every selected index succeeded. Keep exact JSON preview optional. Search capture rejects an occupied filename; explain `Choose a new .json filename; Search capture cannot replace an existing file.` beside the filename field.

## Playbooks Page Contract

- Use the existing page vocabulary and a single vertically staged workspace. A loaded workspace file is attributed by its actual workspace filename; a read-only example by its example filename; an import by `Imported draft · not saved` plus the supplied/source filename. Importing or loading resets selected-file/draft attribution together. Never show the previously selected saved name as the origin of an imported draft.
- In each catalog row, `Load preview` is the common action. Preserve `Run without preview` as a clearly labeled quiet expert shortcut with the current validate-and-run behavior. Put Duplicate, Rename, and Delete inside a closed native disclosure named `Manage file actions`; keep full filename visible and wrapping. File-management buttons carry the row identity in accessible name or adjacent context. Management expands in normal document flow, not a popup/kebab menu. Omit mutations for read-only example rows and keep the reason visible.
- A valid preview has one primary `Run playbook` action, including an imported unsaved draft. Keep `Save playbook to workspace` reachable as an adjacent secondary action and independent of run state or result count. A compact summary shows mode, query, page size/limit, selected full index names, draft provenance, and persistence status. Explain missing backend/schema configuration next to the disabled run action.
- Run result state (running, error, timeout, cancellation, complete/partial) is bound to the actual run id, source filename or imported-draft identity, and criteria captured for that run. A new preview/import cannot relabel old results. If an earlier result is retained, label it `Earlier run` / `Last completed run` and repeat its actual source and submitted mode/targets/query/page size. Successful save updates only current draft persistence provenance; it does not rewrite historical run provenance. A multi-index response with failures is labeled partial. Preserve one active-run guard, timeout, Cancel run, supersede and late-reply suppression semantics. Cancellation does not claim to roll back backend work. Search handoff refers to the captured run/query; do not add a Playbook hit browser.
- Show `Filename` with a `.json` hint. Preserve optional `Search title` and `Description` values from the loaded/imported draft as visible summary metadata and unchanged JSON fields on save; this contract does not add metadata editing controls. Before Playbook save, show `Saving a workspace playbook replaces a file with the same filename. Rename and duplicate require an unused destination.` This is informational disclosure of existing policy; do not add an overwrite-confirmation policy. Workspace configured does not promise writable permissions or successful persistence.
- `Import JSON` is visible at the catalog heading and in `No playbooks yet`. After common preview work, keep the import section with direct native file upload and a native `Or paste JSON` disclosure. File choice alone does not import, save, or run. Uploaded JSON and pasted text each allow at most 256,000 bytes (256 KB decimal); reject 256,001 bytes, accept 256,000 bytes, and report the bound beside both controls. Preserve current JSON validation; runtime/allowlist validation happens at execution. Import errors are attached to the relevant filename/JSON/upload control, preserve entered values where practical, and say whether a prior valid preview remains. Correct the stale “export a playbook JSON” wording; no download/export is available from Search.

## File Dialog and Focus Contract

Use the existing `OpsModal` for Duplicate, Rename, and Delete; do not make hiding actions an authorization boundary. Keep host authorization and all configured-workspace, basename/path, collision, and server-side eligibility checks intact. Preserve these exact persistence policies: Search capture rejects existing names; Playbook save replaces an existing destination through the existing store; Rename and Duplicate reject occupied destinations. Delete requires the exact filename.

On open, close the invoking Manage disclosure, record a visible return target, make the background inert, and contain Tab/Shift+Tab. Rename/Duplicate initially focus the editable filename; Delete initially focuses Cancel. Keep close button, Escape dismissal, visible Cancel, and associated inline validation. Invalid submission preserves the dialog and entered value and focuses the invalid field; ordinary LiveView patches do not repeatedly steal focus. On close/cancel return to the same file's Manage summary; after successful duplicate return to the source row's summary; after rename prefer the renamed row's summary and fall back to the catalog heading; after delete focus the existing logical next-row primary control or catalog heading. Never focus a connected hidden control or a DOM node reused for another file. Verify return behavior through actual LiveView patches and rendered controls.

## Copywriting Contract

| Element | Copy / treatment |
| --- | --- |
| Search primary CTA | `Run search` (one form submit only) |
| Playbook primary CTA | `Run playbook` (applies to saved and imported unsaved drafts) |
| Catalog actions | `Load preview`; `Run without preview`; closed disclosure `Manage file actions` |
| Search not-run empty heading/body | `Run a search to see results` / `Choose an index, enter a query, inspect the answer, then save a useful check.` No second submit button. |
| Zero-hit heading/body | `No matching documents` / `Widen or simplify the query, raise the page size, or choose another index, then run search again.` |
| Search failure | `Search could not run.` Show the concrete returned reason, then `Fix the query options or operator config, then run search again.` |
| Partial multi-index response | `Some indexes did not return results.` / `Failures are per index and do not cancel the whole response. Next: open failure details, adjust entries or backend, then run search again.` Pair with returned/no-hit/failed status per index. |
| Search setup unavailable | `Search is unavailable.` / `Configure the host application's schema allowlist and Scrypath backend to enable search.` State the specific missing prerequisite adjacent to the disabled form/action. |
| Search allowlist empty | `No schemas configured` / `Add allowlisted schema modules with schema_allowlist under :scrypath_ops or SCRYPATH_OPS_SCHEMAS, then reload this screen.` Keep existing README destination. |
| Search complete | `Search completed` with submitted target, query, and readable count. Do not imply freshness. |
| Playbook empty workspace | `No playbooks yet` / `Save a useful search check, or import a JSON file below.` Keep `Import JSON` and `Open Search` where existing behavior supports them. |
| Imported origin | `Imported draft · not saved` followed by the source filename. A run is not implied. |
| Playbook replacement disclosure | `Saving a workspace playbook replaces a file with the same filename. Rename and duplicate require an unused destination.` Place before Save playbook submission. |
| Search capture collision | `That playbook name is already in use — pick another basename.` Preserve the typed value. |
| Import error | `Could not import playbook JSON.` Give the specific validation/recovery detail beside the responsible control and say whether the previous valid preview remains. |
| Save error | `Could not save playbook to workspace.` Keep the actual reason and entered values. Missing setup: `Configure a playbook workspace directory, then retry saving.` Write failure: `Check the workspace directory's permissions and available disk space, then retry saving.` Do not infer a specific cause from a generic write error or announce persistence before the write succeeds. |
| Playbook save field | `Filename` with hint `Use a filename ending in .json.` Preserve optional title and description from the draft as summary metadata and in the saved JSON. |
| Playbook run error | `Playbook run could not complete.` Keep the actual run's reason and existing troubleshooting destination visible. |
| Read-only examples | `Examples (read-only)` / `Examples can be previewed and run. Configure a playbook workspace directory to enable saving and file changes.` |
| Delete dialog | `Delete playbook file`; `This permanently deletes {filename} from the playbook workspace. This cannot be undone.` Label field `Type Filename to confirm`; hint `Enter the exact filename shown above to confirm this irreversible deletion.` |
| Invalid delete confirmation | `Confirmation must match the filename exactly.` Keep dialog open and focus the field. |
| Destructive action | `Delete` only inside Manage; final `Confirm delete` gets destructive emphasis. Cancel, close, and typed exact-filename confirmation remain required. |

All copy is source-grounded and may be tightened only if the same state, provenance, and next safe step remain explicit. Do not introduce stronger guarantees than the visible backend response or filesystem write confirms. The maintainer approved the concrete save-error recovery guidance on 2026-10-10 after the automatic revision cap; verification is rerun rather than force-approved.

## Static Comp Evidence

Realistic static comps are stored in `176-comps.html`. Captures cover Search and Playbooks in both inherited themes at desktop (1440px) and narrow (390px); separate delete-dialog captures cover both themes and widths. Search shows multi-index partial results, the exact submitted criteria, per-index hits/zero/failure, closed raw evidence, progressive save fields and collision disclosure, plus not-run/running/zero/complete/failure/setup/empty-allowlist states. Playbooks shows long catalog filenames, an expanded in-flow Manage disclosure, imported unsaved draft, retained historical run tied to a different saved filename/query, replacement warning, independent save fields, upload/paste validation, and read-only behavior. The separate native dialog capture shows typed-name validation with the filename control focused.

Re-render from repository root with `node .planning/phases/176-search-and-playbooks/render-comps.cjs`. It uses the installed Playwright Chromium, loads the static document in memory, aborts every request, starts no Phoenix app, and writes only `176-*.png` and `176-comp-evidence.json` in this phase directory. The current renderer records 20 static captures with no horizontal overflow, representative controls at least 40px, full filename wrapping, Manage closed by default and rendered open separately, and dialog bounds checked at both widths/themes. Initial delete confirmation focuses Cancel; the separate invalid-confirmation state retains the value/error and focuses the filename. The researcher directly inspected Search and Playbooks in both themes and widths plus both dialog states. These comps demonstrate proposed hierarchy and geometry only; they do not verify application behavior, accessible tree/contrast of production components, LiveView state/patch behavior, async provenance, authorization, or persistence.

## State Coverage Surfaces

These canonical surface descriptions feed the post-checker UI-consideration probe. The maintainer confirmed the proposed kind additions and explicit state rules on 2026-10-10; the UI Considerations section records the validated result.

- **E1 — Search query form (form, list-collection, interactive-control, static-content):** Native single/multi mode choice, complete index selection, query input, page-size field and sole submit; not-run, valid, missing-backend/allowlist disabled, busy, validation/failure, and long-index/query behavior.
- **E2 — Search result summary and hit collection (list-collection, interactive-control, static-content):** Submitted mode/index/query/page-size attribution; populated hits; zero hits; complete, partial, and failed responses; per-index missing/failure explanations; raw payload/response disclosures; long module names and values.
- **E3 — Save-as-playbook capture form (form, interactive-control, static-content):** Eligible submitted-run criteria and metadata, optional JSON disclosure, successful zero-hit/partial eligibility, occupied filename rejection, malformed field/save error, preserved values, and long filename.
- **E4 — Playbook catalog collection (list-collection, interactive-control, static-content):** Empty/one/many files, workspace versus read-only example row, long filename wrapping, Load preview/Run without preview, Manage disclosure and hidden mutation eligibility.
- **E5 — Selected Playbook preview and save form (form, list-collection, interactive-control, static-content):** Workspace file/read-only example/imported unsaved provenance; populated and invalid preview; single Run playbook action; missing configuration; independent save fields and replacement behavior.
- **E6 — Playbook run outcome and Search handoff (list-collection, nav, interactive-control, static-content):** Running/error/timeout/cancel/success/partial; actual run id, source and submitted criteria; retained earlier run beside a different current imported draft; long identifiers and optional diagnostics.
- **E7 — Playbook import controls (form, interactive-control, static-content):** Native upload and paste disclosure, empty selection, in-flight/error/invalid/oversized input, retained prior valid preview explanation, and read-only workspace guidance.
- **E8 — Playbook file action dialog (form, interactive-control, static-content):** Rename/duplicate/delete dialogs, long/exact filename, invalid typed confirmation, disabled or failed action, focus containment, Escape/cancel, LiveView patch and logical focus return.

## UI Considerations

Maintainer-confirmed on 2026-10-10 after checker verification. The compiled probe reports **58 applicable, 58 resolved explicitly, 0 unresolved, 0 unclassified, 0 backstops**. These are future implementation acceptance criteria, not passing application tests or a substitute for the Copywriting Contract.

Confirmed classifications cover forms, target/result/preview collections, interactive controls and readable text/disclosures. E6 also covers the existing Search handoff as navigation. Shell, theme and existing media behavior inherit Phase 173. Collection classification does not authorize a new Playbook hit browser.

Inputs: `176-ui-elements.json` and `176-ui-resolutions.json`. Report: `176-ui-coverage.json`. Re-run from the repository root: `node /Users/jon/.codex/gsd-core/bin/lib/ui-consideration-probe.cjs .planning/phases/176-search-and-playbooks/176-ui-elements.json .planning/phases/176-search-and-playbooks/176-ui-resolutions.json` (resolve the installed runtime path on other hosts). Each row below lifts as an explicit truth; no held-out/human-needed backstop is asserted.

| Category | Element | Status | Resolution / Reason |
| --- | --- | --- | --- |
| empty | E1 | ✅ covered | An empty query remains a valid exploratory query. An absent allowlist or backend shows the specific setup guidance in Copywriting Contract beside the unavailable action; no duplicate Run button appears in the empty result state. |
| loading | E1 | ✅ covered | The sole Run search action retains its label and busy semantics while the existing guard prevents duplicate submission; the dispatched mode, targets, query and page size are captured together. |
| error | E1 | ✅ covered | Invalid input or request/setup failure retains editable criteria and presents the actual reason plus the Copywriting Contract recovery path; failure is not announced as a completed response. |
| populated | E1 | ✅ covered | Single and multi-index modes use labeled native controls, complete target identifiers, query and page-size fields followed by one Run search submit in the declared reading order. |
| partial | E1 | ✅ covered | Missing required targets or invalid page-size/options receive associated validation without dispatching incomplete criteria; an intentionally blank query is not treated as incomplete. |
| overflow | E1 | ✅ covered | At desktop, narrow and changed breakpoints, this surface reflows without horizontal document overflow; full identifiers, criteria and exact JSON remain readable through wrapping or bounded internal evidence scrolling, with controls and focus targets reachable. |
| zero-one-many | E1 | ✅ covered | Zero eligible schemas uses setup guidance; one and many use the existing selection controls and actual configured multi-index cap, with complete identifiers and truthful selected counts. |
| long-text | E1 | ✅ covered | Long filenames, module names, query values, errors and action labels wrap/reflow with complete accessible context; required instructions and the only visible error stay at 14px body size rather than becoming clipped, hover-only or small metadata. |
| empty | E2 | ✅ covered | Not run and successful zero-hit responses use their distinct Copywriting Contract rows. Zero hits remain a successful response and retain the actual submitted criteria. |
| loading | E2 | ✅ covered | A new submission clears or replaces run-specific results and capture under the existing ownership rules; pending response copy stays tied to the dispatched criteria, never later form edits. |
| error | E2 | ✅ covered | Whole-request failure and per-index failure expose the actual reason and recovery step; a failed index does not erase returned results or become zero hits. |
| populated | E2 | ✅ covered | Returned hit summaries and counts lead; attribution shows actual submitted mode, targets, query and page size. Raw hit/per-index/merge evidence remains available in closed labeled disclosures. |
| partial | E2 | ✅ covered | A response with any failed index is visibly partial; returned, zero-hit and failed indexes remain distinguishable while the failure reason and next check stay visible with diagnostics closed. |
| overflow | E2 | ✅ covered | At desktop, narrow and changed breakpoints, this surface reflows without horizontal document overflow; full identifiers, criteria and exact JSON remain readable through wrapping or bounded internal evidence scrolling, with controls and focus targets reachable. |
| zero-one-many | E2 | ✅ covered | Zero hits uses the zero-hit state; one or many hits use correct counts and the same result pattern. Single/multi responses preserve per-index identity without implying one global relevance score. |
| long-text | E2 | ✅ covered | Long filenames, module names, query values, errors and action labels wrap/reflow with complete accessible context; required instructions and the only visible error stay at 14px body size rather than becoming clipped, hover-only or small metadata. |
| empty | E3 | ✅ covered | Before an eligible actual response there is no available capture form. An eligible zero-hit single response or partial multi response can expose Save as playbook; required filename validation remains visible. |
| loading | E3 | ✅ covered | Pending save retains the submitted-run criteria and typed metadata; success feedback follows the actual completed write rather than the button event. |
| error | E3 | ✅ covered | Occupied filenames are rejected for Search capture. Validation/configuration/write errors retain field values and associated reasons plus the approved save recovery guidance in Copywriting Contract. |
| partial | E3 | ✅ covered | Optional title and description may remain blank. A partial response captures its validated query criteria rather than returned documents or a promise that every index succeeded; mode changes preserve capture invalidation. |
| overflow | E3 | ✅ covered | At desktop, narrow and changed breakpoints, this surface reflows without horizontal document overflow; full identifiers, criteria and exact JSON remain readable through wrapping or bounded internal evidence scrolling, with controls and focus targets reachable. |
| long-text | E3 | ✅ covered | Long filenames, module names, query values, errors and action labels wrap/reflow with complete accessible context; required instructions and the only visible error stay at 14px body size rather than becoming clipped, hover-only or small metadata. |
| empty | E4 | ✅ covered | No files uses the empty-workspace Copywriting Contract row with visible Import JSON and the existing Search route; read-only examples retain their actual workspace explanation. |
| loading | E4 | ✅ covered | Catalog refresh or file action feedback retains meaningful file/action context; a pending operation does not announce that a file was saved, renamed, duplicated or deleted. |
| error | E4 | ✅ covered | Load/run/file-operation failures retain the actual affected filename and reason, keep unaffected catalog work reachable, and never advertise the failed file as a valid ready preview. |
| populated | E4 | ✅ covered | Catalog rows show full filenames with Load preview and Run without preview outside a closed in-flow Manage disclosure. Read-only rows omit mutation controls and explain why. |
| partial | E4 | ✅ covered | A failed file load or operation remains attributable to its row while other available files stay reachable; do not fabricate a complete catalog or ready preview from unavailable evidence. |
| overflow | E4 | ✅ covered | At desktop, narrow and changed breakpoints, this surface reflows without horizontal document overflow; full identifiers, criteria and exact JSON remain readable through wrapping or bounded internal evidence scrolling, with controls and focus targets reachable. |
| zero-one-many | E4 | ✅ covered | Zero files uses the empty state; one/many share the same row controls, correct counts and spacing. Occasional mutations stay within the same-file disclosure regardless of catalog size. |
| long-text | E4 | ✅ covered | Long filenames, module names, query values, errors and action labels wrap/reflow with complete accessible context; required instructions and the only visible error stay at 14px body size rather than becoming clipped, hover-only or small metadata. |
| empty | E5 | ✅ covered | Without a valid draft the selected-preview task stays empty with load/import guidance and cannot claim a runnable or saved playbook. Missing workspace/runtime setup uses concrete adjacent guidance. |
| loading | E5 | ✅ covered | Loading/importing/saving retains truthful current draft provenance; a configured workspace enables an attempted write, not a writable-permissions or successful-persistence guarantee. |
| error | E5 | ✅ covered | Invalid preview and failed save retain the responsible draft/filename and entered values where practical, with associated actual reasons and the approved configuration/write recovery copy. |
| populated | E5 | ✅ covered | The preview shows workspace/example/imported-unsaved provenance and structured mode/query/page-size/target facts. Run playbook leads; Save remains a separate reachable persistence task. |
| partial | E5 | ✅ covered | Optional draft metadata may be absent. Valid drafts can save independently of execution; runtime/allowlist eligibility governs running. Missing facts do not become invented saved or run status. |
| overflow | E5 | ✅ covered | At desktop, narrow and changed breakpoints, this surface reflows without horizontal document overflow; full identifiers, criteria and exact JSON remain readable through wrapping or bounded internal evidence scrolling, with controls and focus targets reachable. |
| zero-one-many | E5 | ✅ covered | Zero selected targets reflects actual draft validity, not an invented ready state; single/multi previews show the real target collection and correct counts using the same structured summary. |
| long-text | E5 | ✅ covered | Long filenames, module names, query values, errors and action labels wrap/reflow with complete accessible context; required instructions and the only visible error stay at 14px body size rather than becoming clipped, hover-only or small metadata. |
| empty | E6 | ✅ covered | Before execution, the outcome region states that no run exists; a retained earlier outcome is explicitly earlier and never attributed to a new unrun preview. |
| loading | E6 | ✅ covered | Running output and Cancel retain captured run id, source and criteria. One-run, timeout, supersede and late-reply guards remain authoritative through preview/import changes. |
| error | E6 | ✅ covered | Error, timeout and cancellation remain distinct, attached to the actual run and its existing recovery guidance. Cancellation never claims remote rollback; stale replies cannot apply to the current run. |
| populated | E6 | ✅ covered | Completed summaries show captured source and criteria with truthful counts; the Search handoff uses that run. Saving changes current draft provenance only and does not relabel earlier execution. |
| partial | E6 | ✅ covered | Any per-index failure makes the run summary partial. Returned and failed indexes remain distinguishable through the existing summary/diagnostics without adding a Playbook hit browser. |
| overflow | E6 | ✅ covered | At desktop, narrow and changed breakpoints, this surface reflows without horizontal document overflow; full identifiers, criteria and exact JSON remain readable through wrapping or bounded internal evidence scrolling, with controls and focus targets reachable. |
| zero-one-many | E6 | ✅ covered | Zero, one and many returned hits/index outcomes use truthful counts and partial/failed distinctions; zero hits does not imply execution failure or prevent an otherwise valid independent save. |
| long-text | E6 | ✅ covered | Long filenames, module names, query values, errors and action labels wrap/reflow with complete accessible context; required instructions and the only visible error stay at 14px body size rather than becoming clipped, hover-only or small metadata. |
| empty | E7 | ✅ covered | File selection and paste start with labeled empty controls; no file choice or pasted content automatically imports, saves or runs a playbook. |
| loading | E7 | ✅ covered | Pending import keeps the chosen source and current preview identity truthful; the existing native upload/submit flow consumes the file only through its explicit import action. |
| error | E7 | ✅ covered | Malformed or oversized JSON shows associated concrete validation and recovery feedback, retains inputs where practical and explicitly says whether the previous valid preview remains; upload and paste reject 256,001 bytes. |
| partial | E7 | ✅ covered | Incomplete JSON remains an invalid input, not a ready or saved draft. Optional valid metadata can be absent; accepted input stays within the exact 256,000-byte bound and runtime validation occurs at execution. |
| overflow | E7 | ✅ covered | At desktop, narrow and changed breakpoints, this surface reflows without horizontal document overflow; full identifiers, criteria and exact JSON remain readable through wrapping or bounded internal evidence scrolling, with controls and focus targets reachable. |
| long-text | E7 | ✅ covered | Long filenames, module names, query values, errors and action labels wrap/reflow with complete accessible context; required instructions and the only visible error stay at 14px body size rather than becoming clipped, hover-only or small metadata. |
| empty | E8 | ✅ covered | An empty required destination or deletion confirmation cannot mutate files and retains the visible filename/hint; Delete initially focuses Cancel, Rename/Duplicate the editable destination. |
| loading | E8 | ✅ covered | The active dialog retains file identity, focus containment and background inertness through submission and ordinary patches; do not repeatedly steal field focus or announce premature success. |
| error | E8 | ✅ covered | Invalid confirmation, collision, configuration or write failure keeps the dialog and entered value, exposes the actual associated reason, and focuses the relevant invalid field as declared. |
| partial | E8 | ✅ covered | Incomplete/mismatched exact-filename deletion confirmation remains in the dialog without deleting. Server basename/path/authorization and occupied-destination checks remain effective regardless of hidden controls. |
| overflow | E8 | ✅ covered | At desktop, narrow and changed breakpoints, this surface reflows without horizontal document overflow; full identifiers, criteria and exact JSON remain readable through wrapping or bounded internal evidence scrolling, with controls and focus targets reachable. |
| long-text | E8 | ✅ covered | Long filenames, module names, query values, errors and action labels wrap/reflow with complete accessible context; required instructions and the only visible error stay at 14px body size rather than becoming clipped, hover-only or small metadata. |

## Registry Safety

| Registry | Blocks used | Safety gate |
| --- | --- | --- |
| None | None | Not applicable; this Phoenix phase adds no registry or dependency. |

## Verification Obligations for Planning

| Requirement | Executable implementation evidence required |
| --- | --- |
| OPUX-23 — Search hierarchy and outcome truth | LiveView/component assertions for one submit and no empty-state duplicate; target/query/page-size order; Enter submit; concrete native disabled/busy behavior; exact submitted-criteria attribution after control/URL changes; state distinction for not-run/running/zero/complete/partial/failure/setup; status announcement without result-list live region/focus theft; responsive direct-render evidence in light/dark at 1440px/390px and changed intermediate widths; no horizontal overflow or clipped full identifiers. |
| OPUX-23 — multi-index detail/capture | Per-index returned/no-hit/failure presentation; partial message and next check stay visible with diagnostics closed; raw hit/per-index/merge/federation disclosures stay labeled and available; federation limitation remains visible; capture derives from the dispatched run, remains invalidated by mode changes, handles successful zero and eligible partial results, preserves criteria/metadata on failure, rejects occupied filename and saves no result documents/response. |
| OPUX-24 — preview, run, save, import | Assertions for catalog → preview → run result → import reading order; one `Run playbook` for saved/imported draft; Run without preview retains validate/run; read-only examples run but omit mutations; workspace save replaces same filename and warns before submission; rename/duplicate still reject collisions; save independent of run/result; imported unsaved draft never inherits previous selected filename; successful save changes current provenance only. |
| OPUX-24 — async and provenance | Controlled LiveView async cases for running, error, timeout, cancellation, supersede, stale/late reply, one-run guard and patch transitions; retained old run stays bound to captured run id/source/query/mode/targets/page size after a different load/import/save; multi-result failures remain partial; cancellation copy does not claim backend rollback; Search handoff uses the actual run criteria. |
| OPUX-24 — import | Rendered native file submit and paste disclosure; no auto-import/save/run on file choice; empty upload, malformed JSON, exact 255,999/256,000/256,001-byte boundaries for upload and paste, runtime/allowlist validation at run, prior-preview retention truth, associated errors and retained field values; fix stale export wording without adding export capability. |
| OPUX-25 — management | Manage disclosure starts closed, expands inline, remains outside common Load/Run actions; full filenames wrap; read-only examples omit mutations; each action carries file context; preserve server authorization/path/basename/eligibility and exact collision policies; delete exact-filename confirmation. |
| OPUX-25 — modal accessibility/focus | Actual browser/LiveView evidence for native close, Cancel, Escape, Tab and Shift+Tab containment, background inertness, rename/duplicate initial filename focus, delete initial Cancel focus, invalid value and field focus, non-repeated focus on ordinary patch, disclosure close on open, return to same/renamed/duplicate/deleted logical visible target after cancel/success/delete (including hidden/deleted/reused-node cases). |
| Shared visual contract | Token and composed-pair AA checks for both themes, input/action/control and focus states; before/after direct render inspection at desktop/narrow and a changed breakpoint; check long filenames/query/module/diagnostic values, content scrolling, busy/disabled, read-only, missing setup and dialogs; honor reduced-motion; keep existing Operations app entrypoints and no dependency. |

Use existing Ops LiveView tests, app/component/browser lanes and `CONTRIBUTING.md` verification gates for delivered code. Run mutating fixtures only in a disposable stack; never seed or mutate preview `http://127.0.0.1:4012/admin/search`. Static comp output is never implementation acceptance or a replacement for executable tests and exact-source evidence. Keep OPUX-23, OPUX-24, and OPUX-25 independently pending until their owning implementation slices meet their evidence obligations.

## References

- `.planning/phases/176-search-and-playbooks/176-CONTEXT.md` — locked D-01–D-27 decisions, scope and accepted discretion.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md` — approved shared tokens, surface, responsive, and interaction contract.
- `.planning/research/v1.43/SCOPE.md` — comp-first sequence, shared scope and preserved operational truth.
- `.planning/reference/OPERATOR-UI-REFINEMENT.md` and `.planning/reference/OPERATOR-UI-QUALITY.md` — operator jobs and durable interaction/quality expectations.
- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` and `playbook_live.ex` — current Search and Playbooks state, copy, validation, submit/run, and persistence seams.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`, `assets/css/app.css`, and `assets/css/DESIGN-TOKENS.md` — existing component and visual authorities.
- `scrypath_ops/lib/scrypath_ops/playbook/store.ex` — actual save/replace, rename/duplicate collision, and delete persistence behavior.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `CONTRIBUTING.md` — requirement ownership, phase ordering, and verification gates.
- W3C [Disclosure Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/), [Modal Dialog Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/), and [Focus Order](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html) — native disclosure and modal keyboard/focus expectations.

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS — locked Phase 173 values and documented exceptions apply
- [x] Dimension 5 Spacing: PASS — locked Phase 173 values and documented exceptions apply
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** `gsd-ui-checker` APPROVED on 2026-10-10, 7/7 PASS, no recommendations. After two automatic revisions, the maintainer explicitly authorized the concrete save-error recovery fix and a fresh verification; no force approval was used. The maintainer then confirmed all eight proposed classifications and explicit state rules. The side-tab hook finding was fixed in the comp with no suppression. This is design-contract approval only: OPUX-23–25 implementation and application acceptance remain pending. Next: `$gsd-plan-phase 176`; execution still follows 173 → 174 → 175 → 176.
