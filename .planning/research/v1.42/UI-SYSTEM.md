# v1.42 UI system review

**Reviewed:** 2026-10-03  
**Source:** `3c83a58c9bc5af70a204957431ff66fd9db035de`, worktree `/private/tmp/scrypath-admin-ui`  
**Scope:** shared CSS, tokens, components, layouts, and all six operator LiveView render functions, plus inspection of three current screenshots captured by the root agent. No implementation changes, browser interaction, or tests performed by this reviewer. Remaining visual hypotheses require the current preview. Historical passing reports are context, not current verification.

## Assessment

ScrypathOps already has an extensive, reusable design system: 48 `ops_*` function components, semantic light/dark surfaces, a controlled spacing/type scale, responsive navigation, state notices, keyboard shortcuts, reduced motion, and previous component/contrast/browser work. The useful next step is to close specific interaction and consistency gaps in that system, then improve the incident journey using observed friction. A new component framework, theme, or general CSS rewrite would duplicate completed work and increase regression risk.

The user's readability concern has a concrete source: the standard action button is 12px and compact recovery/file actions are 11px. Important instructions frequently use 12px secondary text. The declared 40px control height therefore does not guarantee readable labels. The source also reveals a few accessibility semantics gaps and inconsistent token consumption that screenshot comparison alone will not catch.

## Existing foundation and historical boundaries

- `scrypath_ops/assets/css/app.css` is the value authority; `DESIGN-TOKENS.md` catalogs it. `ops_ui.ex` is the component authority; `layouts.ex` owns shell navigation and themes.
- v1.32 introduced tokens/shared components and removed duplicated screen idioms. v1.33 phases 119–127 added state capture, per-touchpoint review, token/component tightening, motion, and surface polish. Phase 121 explicitly closed a 1→4 preflight column jump; the current source already has the intermediate 2-column layout.
- v1.34 phases 128–136 added the contrast harness, dark surface ladder, light/dark/system-dark coverage, and shell focus evidence. Its historical contrast report says AA passed at that cutoff. Do not reinterpret that as a guarantee for every current conditional state or newly changed component.
- Phase 146 was preservation-only. It did not approve a redesign or new framework.
- The brand book's suggested 12/16/24px radii and display fonts are broader brand guidance. The shipped operator contract deliberately uses denser 6/8/12px radii and system UI fonts. Resolve this documented distinction instead of treating every difference as a defect.
- `scrypath_ops/AGENTS.md` says to avoid introducing daisyUI, but the current implementation and design-token contract explicitly use vendored daisyUI. Preserve the established dependency and improve `OpsUi`; do not read that guidance as authorization for a migration.

## Actual token inventory

Values are expressed in pixels assuming the normal 16px root, with rem values retained in CSS for scaling.

| Dimension | Current implementation | Assessment |
|---|---|---|
| Spacing | `ops-1…6`: 4, 8, 12, 16, 20, 24; field 6; row 16; section/page-gap 24; panel 20; control-gap 8 | A usable small scale exists. Numerous raw equivalent utilities bypass it. Page shell uses raw `space-y-4` =16, while `page-gap`=24 is declared. |
| Body type | xs 11; sm 12; body 14; md 16; lg 18 | Keep metadata distinct from task instructions. Current default/compact buttons inherit 12/11px vendor sizes. |
| Headings | h1 24; h2 18; h3 16; tight line height 1.3; body 1.5 | Some real h3s use body 14 instead of h3 16. This weakens the documented hierarchy. |
| Fonts | System UI sans from Tailwind; `font-mono` vendor stack; `.ops-text-mono`, schema metadata, and signal values specify a second mono stack | No network font dependency. Consolidate mono authority if touched; loading new brand fonts is an optional later decision. |
| Controls | xs 28; sm 36; md 40; lg 44; textarea minimum 96; inline padding 10/12 | Nav items use 44; standard buttons/inputs 40; compact controls 28/36. Size roles should describe actual needs, especially primary recovery controls. |
| Radii | sm 4, md/control 6, lg/surface 8, overlay 12; pills fully rounded | Coherent dense console vocabulary. Textarea/file controls still inherit vendor radius. |
| Light surfaces | page `#faf7f2`, resting `#fffdf8`, muted/raised `#faf7f2` | Existing warm neutral scheme; no new palette required. |
| Dark surfaces | page `#0c0f14`, resting `#141923`, raised `#1b2230`, border `#2a3446` | Existing dark ramp and explicit/system-dark parity are valuable constraints. |
| Accent | light primary `#5b4ad1`, dark `#6c5ce7`, selected fill `#5b4ad1`; copper light `#a85d2e`, dark `#c17a3e` | Copper is a brand accent, never status. Preserve the selected-fill contrast fix. |
| Status | info `#5ca9e6`, success `#4fae74`, warning `#d9a441`, error `#d96262`; primary for running | Surfaces and badges generally keep dark/light body text. Tone-chip values override foreground with status hues; inspect conditional contrast. |
| Shadows | surface 1px lift; mid hover; raised 10px blur; overlay 24px blur; dark ambient border/shadow plus opt-in glow | Existing roles are sufficient. Drawer shadow is separately hardcoded; do not add more decorative elevation. |
| Layering | skip 50, flash 60, modal 70, nav 75, command 80; header 30, sidebar 35 literals | Modal component bypasses modal token; vendor `.modal` is 999 in the checked-in CSS. Catalog omits nav/command. |
| Motion | 90/120/180/200/240ms; standard/out/in-out/exit curves; global reduced-motion neutralization | Most motion is bounded and state based. Modal exit still uses `duration-200` plus JS `time:120`. |
| Layout | wide page max 80rem; default max 48rem; sidebar 17rem above 1280px; mobile drawer below | All six screens request wide layout. Meaningful content widths should be chosen within it rather than forcing every panel into columns. |

Token source locations: `app.css:127` spacing; `:140` radii/shadows; `:161` controls/layers; `:183` motion/type; `:858` text helpers; `:1254` preflight breakpoints; `:2264` dark shadow values. Generated CSS was read only to identify vendor defaults; the root's freshly built preview remains the authority for computed styles.

## Building block inventory

All 48 exported `OpsUi` components are accounted for below. Most already have the right scope; expand an existing component only when two or more call sites share the same need.

| Family | Existing components | Important behavior / gap |
|---|---|---|
| Page structure | `ops_page_header`, `ops_heading`, `ops_panel`, `ops_toolbar`, `ops_section`, `ops_scaffold` | Single h1, wrapping action rows, named sections. Some raw spacing and manually sized h3s diverge. |
| Navigation / handoff | `ops_command_hint`, `ops_trail`, `ops_handoff`, `ops_intent_card`, `ops_command_palette` | Existing keyboard and route affordances; incident context must survive handoffs. Shell also supplies grouped sidebar, drawer, theme toggle, skip link, flash. |
| Actions | `ops_button`, `ops_refresh_button`, `ops_link_button`, `ops_action_group` | Central variants and press treatment; standard and compact action text is small. Refresh control is not consistently used by screens. |
| Operational state | `ops_notice`, `ops_status`, `ops_metric`, `ops_metric_grid`, `ops_tone_chip`, `ops_badge`, `ops_verdict`, `ops_workspace_mode_indicator` | Shared semantics and status labels; neutral facts remain neutral. Tone-chip foreground needs rendered contrast coverage. |
| Empty / loading / setup | `ops_empty_state`, `ops_empty_hero`, `ops_loading`, `ops_config_empty` | Distinguishes compact guards from orienting empty states. Keep loading as a real state, without claiming recovery from a spinner or flash. |
| Forms | `ops_fieldset`, `ops_field`, `ops_text_input`, `ops_number_input`, `ops_textarea`, `ops_select`, `ops_schema_select`, `ops_segmented_control`, `ops_checkbox_list`, `ops_upload_box` | Native form foundation. Fix accessible labels, descriptions, selected-state semantics, and disabled behavior at shared boundaries. |
| Repeated content | `ops_data_card`, `ops_result_row`, `ops_object_list`, `ops_object_item`, `ops_table`, `ops_signal_table` | Lists and cards already serve most content. Tables remain mainly 2-column Sync/Drift signal snapshots; not a blanket table UI. |
| Evidence / disclosure | `ops_time`, `ops_disclosure`, `ops_code_block`, `ops_inline_code` | Bounded scroll for raw payloads, exact timestamps/copy. Plain text identifiers outside code blocks need long-content review. |
| Blocking actions | `ops_modal` | Used by Playbook delete/rename/duplicate. Semantic dialog exists but focus lifecycle is incomplete. |

CSS microcomponents include label/body/meta/mono helpers, status dot, schema radio cards, signal groups/metrics, preflight step cards, route mark, keyboard keycap, skeleton lines, disclosure chevron, flash wrapper, mobile backdrop, command result, and theme preference pill. Reuse these primitives rather than making screen-specific variants with nearly identical rules.

## Six-screen composition inventory

| Surface | Current composition | State and layout review focus |
|---|---|---|
| Control Room (`control_room_live.ex:43`) | Trust verdict or setup guard, three intent cards, orientation links | All-green/degraded/unconfigured/missing-backend; 3 intent columns begin at 768px. Recommended action must remain obvious without relying on glow. |
| Posture (`posture_live.ex:147`) | Verdict, four metric tiles, next-check list, per-schema cards with backend/queue definition lists, handoff | Mixed-success schema fleet, error reason, 0/1/many schemas, long module/index names. Signal headings are currently 11px uppercase. |
| Failed Sync (`failed_sync_live.ex:212`) | Schema radio/select, summary, six reason tiles, triage disclosure, evidence rows, retry inside row disclosure, empty hero | Repeated failures, retry availability, compact rollups, long reason text, newest-first order. Retry discoverability versus evidence-first guard needs deliberate treatment. |
| Sync/Drift (`sync_drift_live.ex:289`) | Schema picker, technical guidance notice, 4-step preflight, reconcile table, drift status/table/chips, advanced swap, handoff | Unloaded/loading/error/mismatch/clean/swapping; preflight is a summary, actual controls occur later. Incident verification and index promotion need distinct emphasis. |
| Search (`search_live.ex:761`) | Safety notice, stacked target/query/limit fieldsets, results/cards, optional evidence disclosures, save-to-playbook form | Single/multi mode, config guard, running/error/empty/partial results, large labels. Keep ordinary controls visible; raw payload/federation detail can be disclosed. |
| Playbooks (`playbook_live.ex:865`) | Workspace/list mode, object rows with grouped actions, import upload/paste, preview/run/results/save, file action modals | Read-only examples versus writable workspace, no/one/many files, long names, invalid import, running/timeout/error, destructive confirm. Five row actions need hierarchy, not indiscriminate concealment. |

## Source-confirmed findings

Severity here reflects user impact, not implementation size. **High:** blocks reliable keyboard/assistive interaction. **Medium:** confusing or unreadable interaction, or shared contract drift with broad effect. **Low:** catalog/maintenance inconsistency. Browser checks should confirm runtime consequences before a completion claim.

| ID / severity | Evidence | Finding and smallest correction |
|---|---|---|
| SYS-01 / High | `ops_ui.ex:1243`; `assets/js/app.js` hooks only cover command palette and drawer | File-action dialog has `role=dialog`, `aria-modal`, a close button with `autofocus`, and Escape, but no focus trap, focus return, or background inertness. A CSS `.modal` div cannot supply these. Implement the focus lifecycle once in `ops_modal` using the installed Phoenix primitives or a narrowly scoped hook; verify Tab/Shift-Tab/Escape and returning focus to the row action. |
| SYS-02 / Medium | `ops_ui.ex:954` | Search mode changes are styled only with selected colors. Buttons have no `aria-pressed`/selected state and the visible mode label does not name a group. Add selected-state semantics and a named group, retaining straightforward button keyboard behavior. |
| SYS-03 / Medium | `search_live.ex:814` | Config-disabled search form uses `opacity-50 pointer-events-none` but does not disable controls. Keyboard users can still enter and submit them. Use native disabled fieldset/control semantics with the visible reason; retain the backend's guard. |
| SYS-04 / Medium | `ops_ui.ex:776`, `:891`, `:704`; `playbook_live.ex:1008`, `:1024` | Generic field hints have no IDs, so consumers cannot associate them; the >4 schema select branch has a fieldset legend but no control label; upload caption is a paragraph rather than a label; paste textarea relies on placeholder/nearby disclosure text. Add persistent label and description slots/IDs centrally, then wire actual controls. |
| SYS-05 / Medium | `ops_ui.ex:179`, `:1439`; `failed_sync_live.ex:409`; generated CSS `:2911` | Default button size `:sm` inherits 12px; retry and file actions use `:xs` =11px. Control height remains 40px. Adopt a readable action-label role in the shared button contract and reserve 11/12px for short secondary metadata. Choose exact sizing with current screenshots, especially long labels and mobile wrapping. |
| SYS-06 / Medium | `app.css:140`, `:665`, `:858`, `:1559`; `ops_ui.ex:116`, `:329`, `:840`, `:1065`; `layouts.ex:289` | Declared tokens do not consistently own their dimensions: badge type/padding and nav text use equivalent literals; shared layouts use raw gaps; textarea omits `ops-form-control`; result-row h3s and Posture schema h3s render at 14px rather than h3=16. Normalize touched shared components first with equivalent tokens, then make intentional role changes. Avoid a repo-wide formatting sweep. |
| SYS-07 / Medium | `app.css:173`, `:265`, `:277`; `ops_ui.ex:1247`; generated CSS `:305` | Declared modal layer 70 is unused; vendor `.modal` uses 999, while nav and command layers are 75/80. Header/sidebar are separate literals. Define and consume the intended stack centrally, and ensure global shortcut overlays cannot steal focus underneath an active file dialog. Do not blindly lower modal to 70 without confirming intended overlay precedence. |
| SYS-08 / Low | `DESIGN-TOKENS.md`, `app.css:173`, `layouts.ex:289` | Catalog omits nav/command layers and has outdated component comments. Page-gap=24 differs from documented shell `space-y-4`=16; typography and font authority distinctions are not explained. Update the catalog alongside the chosen roles so future agents do not restart this debate. |

Additional source-confirmed design concern: `.ops-result-row:hover/:active` and `.ops-object-item:hover/:active` apply interactive elevation/scale to every row (`app.css:1431`) even when only an inner disclosure/button acts. Keep whole-card affordances for whole-card links, and inner-action affordances for passive evidence rows. This is a modest shared CSS correction only if the preview confirms a misleading interaction feel.

## Current screenshot observations

Inspected the root agent's current isolated-preview captures under `/private/tmp/scrypath-v142-review/`: `failed-sync-light-mobile.png`, `failed-sync-light-desktop.png`, and `control-room-light-desktop.png`.

- **Confirmed Medium, VIS-01 — mobile task hierarchy:** Failed Sync turns six reason counts into six full-width cards above the actual failed jobs. Together with the schema panel, summary, triage block, and guide prose, they consume well over the initial viewport before the first actionable record. Desktop's compact count row is appropriate; mobile should use a concise wrapping summary, small definition-list/count treatment, or compact optional rollup. Do not merely put all six cards into tiny columns. Source: `failed_sync_live.ex:286`, `ops_ui.ex:349`/`:1543`.
- **Confirmed Medium, VIS-02 — repeated guidance competes with work:** the large schema explanation narrates the UI's implementation ("Small allowlists stay visible..."). The repeated recovery/row guidance and raw repository paths add scroll depth before jobs. Shorten to task guidance, keep per-row explanation where decisions happen, and expose technical references as secondary help. The screen already uses list/cards successfully; replacing it with a table would not solve the hierarchy problem.
- **Confirmed scoped positive:** the 390px mobile capture shows contained panels, readable stacking, and deliberate tagline truncation; no gross horizontal overflow is visible for the seeded Product/Variant names. The reported narrow-header risk remains only for 320px, zoom, and longer content.
- **Confirmed scoped positive:** the Control Room desktop capture has clear page/verdict/intent hierarchy and calm consistent surfaces. The three-card composition fits this desktop capture. Preserve this baseline while clarifying incident copy; a new visual theme is not justified by these images.
- **Readability remains a role decision:** screenshot inspection supports improving small action/helper text, but does not establish a contrast or accessibility failure by appearance alone. Computed contrast and actual keyboard interaction still need their own automated evidence.

## Visual hypotheses to resolve in the current preview

These are not claimed regressions or automatic redesign tasks.

1. **Light-theme status text:** `.ops-tone-chip.ops-tone-success/.warning/.error .ops-tone-chip__value` uses the pure status hue (`app.css:763`). The static contrast manifest explicitly covers only the default/no-tone value (`contrast-pairs.mjs:220`). Inspect loaded contract dimensions in light/dark/system-dark, including mismatches; add conditional coverage if missing. Do not assume old contrast receipts cover the loaded state.
2. **Dimmed preflight explanation:** locked cards apply opacity 0.55 to the entire card (`app.css:1285`), including the explanation of what unlocks the step. That explanation should remain readable even if the associated action is disabled. Check actual text contrast and scanability.
3. **Long identifiers:** Posture module/index/reason text (`posture_live.ex:260`, `:332`), Playbook filenames (`playbook_live.ex:934`), and inline code (`ops_ui.ex:1230`) lack a shared wrapping policy. Test long, unbroken host-generated identifiers at 320/390px, zoom, and 0/1/many items. Preserve access to exact identifiers; do not solve by truncating every identifier.
4. **Header at narrow widths:** mobile header combines 40px menu trigger, 36px mark, title/tagline, and a 3×40px theme control (`layouts.ex:64`). The inspected 390px screenshot is contained; tagline truncates but title does not. Check 320px and text zoom before simplifying chrome.
5. **Columns based on available content width:** Control Room goes to three cards at 768px; preflight goes to four at 1024px; Failed Sync goes to six metrics at 1024px; sidebar appears at 1280px. Check 768/1024/1280px boundaries. Existing mobile stacking is present, so do not assume every grid is broken. Prefer a justified minimum card width or fewer columns when content demands it.
6. **Signal tables on mobile:** 2-column Sync/Drift tables reserve a 12rem row-header width (`app.css:1489`) within a panel that has 40px interior padding. These are key/value snapshots, so a responsive definition list is a reasonable replacement if screenshots show cramped values or avoidable horizontal scrolling. Dense genuinely comparative datasets should retain tables.
7. **Task hierarchy:** stacked technical guidance, promotion preflight, current-state checks, and advanced recovery put a great deal above the incident verification outcome. Review scroll depth during actual incident recovery; primary status/action should be prominent, advanced index promotion contextual, and raw CLI/API references available as secondary help.
8. **Row action hierarchy:** Playbooks shows load, run-without-preview, duplicate, rename, delete. Preserve common visible actions; let destructive/rare actions be quieter without inventing nested menus for every command. Confirm the incident milestone needs a change here before expanding scope.

## Smallest cohesive remediation order

1. Establish fresh captures of the current six screens and relevant recovery states. Readability/overflow/contrast hypotheses become actionable only with a reproducible state and concrete evidence. Keep one finding backlog and stable IDs; do not replay old audit phases.
2. Repair shared native semantics and dialog focus behavior. This is a small set of component-level corrections with broad value and clear acceptance.
3. Set a short role table for action labels, body/instructions, helper text, metadata, and headings. Route touched components through the existing tokens. Confirm the selected type/spacing in representative mobile and desktop screens before spreading changes.
4. Run the incident journey, then fix its specific hierarchy, context, next-action and recovery-outcome problems. Use current lists/cards/definition lists; introduce no generic "all screens become columns" layout rule.
5. Update token and component docs with the actual final behavior, reuse the current automated gates, and capture bounded before/after evidence. File any useful unrelated findings as explicit deferred work rather than repeatedly broadening the milestone.

## Regression guards and cost control

- Keep existing token-resolution, shell, IA, motion, depth and contrast suites. The current token test proves referenced tokens exist; it does **not** enforce that controls actually consume the semantic token or that every rendered state remains accessible.
- Add focused interaction assertions for dialog focus lifecycle, selected mode semantics, configuration-disabled keyboard behavior, >4-schema label, and hint associations. Prefer behavior and accessible names over brittle serialized HTML/CSS snapshots.
- Keep one deterministic incident browser journey, with task/index authority and visible outcome assertions. A toast, disappearing row, or "queued" state alone is not recovery proof.
- Add layout checks for document overflow, control bounds, and long identifiers to the existing browser state harness; compare a small representative screenshot set after token changes. The critical widths are small mobile and breakpoint edges, not a huge Cartesian product on every PR.
- Cover explicit light/dark plus a system-dark parity smoke for changed theme rules; reduced motion for changed transitions. Do not duplicate existing full matrix execution without a new reason.
- Use local deterministic screenshots and automated contrast/DOM checks. Visual inspection by the coding agent can consume those artifacts; no recurring external model API or paid screenshot-review service is required.
- Screenshot baselines should have a clear source revision, seed, viewport/theme and fresh asset build. Never approve screenshots merely because a stale server looks correct; never auto-update baselines to silence a failure.
- Treat subjective user feedback as optional direction during the preview, with implementation correctness carried by automated evidence. Do not convert it into routine post-implementation human UAT.

## Outcome of this review

This is an evidence-backed planning report, not a claim that the UI has been repaired or that all visual hypotheses are verified. Three current screenshots were inspected, with the observations and limits stated above. No source code or tests were changed. The report preserves the existing system and identifies a bounded path to a more readable, consistent operator UI without another broad polish loop.
