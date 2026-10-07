# Phase 173: Shared Visual Foundation and Operational Time - Context

**Gathered:** 2026-10-06
**Status:** Discussion complete; ready for the comp-first UI contract
**Decision authority:** The maintainer selected all areas by delegating specialist fan-out, primary-source research, adversarial synthesis, and automatic adoption of the resulting recommendations. These are delegated decisions, not a simulated interview or reviewer approval.

<domain>
## Phase Boundary

Deliver OPUX-09–OPUX-15 in the existing operator shell and representative Search health view: flat neutral surfaces, truthful local status cues, neutral zero-error metrics, one selected theme preference, coherent quiet-action states, readable operational last-success times, and honest exact-timestamp copying in standalone and mounted Ops.

Keep the existing six surfaces, components, native controls, host authorization, safety gates, data semantics, and retained evidence. Phase 174 owns recovery-page hierarchy and schema handoffs; Phases 175–177 own later workflow refinement and consolidation. This discussion does not implement or verify product changes.
</domain>

<decisions>
## Implementation Decisions

### Research, design, and dependency posture

- **D-01:** Use bounded fan-out on relevant decisions, then synthesize one coherent recommendation. Consider operator/product, design/accessibility, Phoenix/browser state, operational truth, security, and maintenance perspectives. Add an adversarial pass for plausible failure modes; stop when further research would not change the recommendation. Do not enumerate irrelevant specialties or reopen completed milestones.
- **D-02:** Prefer small owned code, including modest repetition, over another external dependency. Reuse proven internal components/modules where they already solve the task. No new dependency is recommended for this phase; an exception needs a concrete capability or correctness gap and a proportionate maintenance/security benefit. This is a preference, not permission to copy unreviewed third-party code.
- **D-03:** Apply Impeccable Operate guidance with existing PRODUCT.md and DESIGN.md. The next command is `$gsd-ui-phase 173`; compare realistic degraded Search health light/dark comps and record the chosen treatment in `173-UI-SPEC.md` before `$gsd-plan-phase 173`. Automatic adoption of these recommendations does not bypass the UI contract or authorize an implementation chain.

### Neutral palette and accent balance

- **D-04:** Start the comps with restrained warm-neutral light surfaces and a neutral dark counterpart, preserving identity continuity without preserving the rejected gradients or status treatments. Warmth is a subtle neutral bias, not a beige/yellow wash. Exact hue, luminance, borders, and elevation remain comp decisions; compare a cooler alternative if it materially improves scanning or contrast.
- **D-05:** Use violet for primary interaction, current selection, links, and focus; copper remains a small identity detail. Brand accents do not communicate operational success/failure. Keep shell backgrounds flat in explicit light/dark, System appearance, and responsive overrides; preserve functional scroll-edge cues.
- **D-06:** Summary, schema, and metric surfaces use neutral fills and quiet borders. Tone steps, proximity, and headings provide grouping. Do not compensate for lost colored outlines with new nested cards, shadows, tiny text, or low-contrast metadata. Keep the established font, spacing, and component system.

### Warning, failure, and unknown cues

- **D-07:** Summaries pair explicit state text with a restrained local icon. Repeated schema signals may use existing compact semantic badges; secondary facts use plain text. Avoid duplicate status labels that add no information. Severity must remain understandable without color.
- **D-08:** Zero-error metrics are ordinary neutral counts. Nonzero failures can emphasize the relevant value/local icon and cause, without coloring the whole metric or schema. Unavailable observations are explicit text, never zero. Distinguish Queue not used, observations unavailable, pending/retrying work, and confirmed terminal failure; preserve the existing classification rather than inventing new health rules through CSS.
- **D-09:** An observation/fetch failure means the check is unavailable, not proof that remote work failed. Zero errors, a last success, or an observed queue do not establish current document freshness. Reserve success emphasis for a meaningful observed outcome within its existing evidence boundary; retain failure history and full identifiers.

### Quiet actions and theme control

- **D-10:** Keep the existing group of native buttons, adding visible System / Light / Dark labels and stable accessible names. Preserve normal Space/Enter activation and the existing Tab model. Do not introduce a custom radio keyboard implementation or another control library. Keep labels and usable targets at narrow widths through layout reflow.
- **D-11:** Exactly one visual and `aria-pressed` selection follows the current preference. System stays selected while effective appearance follows OS changes. Remove the competing selection cue whose pill follows effective appearance; if a selected backing remains, it follows preference only. Effective light/dark appearance is separate state, not a second selected option.
- **D-12:** Preserve pre-paint appearance, navigation/LiveView patch resynchronization, reload persistence, and same-origin cross-tab preference updates when storage is available. Guard storage access and retain an in-memory preference if unavailable; the control must still work for the current page. Do not promise reload/cross-tab persistence when the browser prevents storage. Invalid stored preferences resolve to System.
- **D-13:** Quiet actions use neutral surface-aware hover and a stronger transient pressed treatment. Keyboard focus is independently visible; persistent selection, disabled, and busy states remain distinct. Primary/selected accent styling must not appear merely on hover. Keep disabled explanations readable and action targets consistent with the existing system.
- **D-14:** Busy actions keep their meaningful icon and label and expose busy state without replacing nested content. Reuse the shared refresh/hook pattern, preserving server-driven eligibility after patches. No new decorative motion is needed; retain reduced-motion support and verify state transitions with motion reduced.

### Operational time and exact evidence

- **D-15:** Use relative-first last-success text: just now below one minute; whole minutes below one hour; hours below one day; days below seven days; human-readable absolute UTC thereafter. These thresholds are project choices, not external standards. Show absolute UTC for a timestamp after the check reference, with a truthful indication that it is ahead of that check; do not assert a clock-skew cause or present a negative age.
- **D-16:** Calculate relative age against the observation/check snapshot and keep it stable until that evidence is checked again. An unrelated patch, theme switch, or clipboard action must not change the age. A failed check must not silently make retained evidence appear newly observed. Do not add a ticking clock or use the relative label as a freshness guarantee.
- **D-17:** Preserve the source timestamp's precision and offset when serializing full ISO evidence. Human absolute display defaults to UTC with the timezone stated. Do not truncate seconds/microseconds or substitute check time, toast time, or browser time for the recorded success. Preserve the existing meaning of the source time; research must verify that meaning before changing its presentation.
- **D-18:** Observed data with no success uses No success observed; an unavailable source uses Not observed or the existing precise reason. Queue not used remains distinct. A bare dash alone is insufficient to explain these states. Do not claim that no success has ever occurred when the evidence only covers an observation/history window.
- **D-19:** Provide a dedicated, discoverable Copy timestamp control beside operational last-success values. Exact ISO and timezone must also be reachable and selectable through pointer, keyboard, and touch; use the existing disclosure pattern if needed. A hover-only `title` is supplementary, not the sole exact-value access. Routine Checked metadata has no copy control.
- **D-20:** Copy through the browser clipboard API directly from user activation. Show Timestamp copied through shared polite feedback only after `writeText()` resolves. Reuse the existing four-second info dismissal; reset feedback for repeated successful copies without stacking stale messages. On denied/unavailable access, give explicit persistent feedback and keep the exact value selectable for manual copying. Do not request clipboard-read permission, use deprecated fallback copying, or announce success on dispatch alone. Cover both standalone and mounted handlers.

### Evidence and agent discretion

- **D-21:** Each implementation slice includes direct before/after inspection and relevant executable proof: shared token contrast, component/LiveView state wiring, and focused rendered browser geometry/keyboard/theme/copy checks. Cover desktop/mobile and a changed breakpoint, light/dark/System, long values, disabled/busy, absent/unknown/future times, precision, and clipboard rejection/unavailability. Mounted and standalone copy behavior must both be exercised. Preserve existing economical CI lanes; no paid judge or routine pending human UAT.
- **D-22:** Preserve the uncommitted local UI/design baseline and the feedback preview at `http://127.0.0.1:4012/admin/search`. Mutating fixtures belong in disposable verification stacks. Archived v1.42 receipts do not verify changed source. Record OPUX-09–OPUX-15 individually with phase evidence when delivered; this discussion completes no roadmap requirement.

### Agent's Discretion

Choose exact token values, icon shapes, local badge details, exact-value disclosure placement, and bounded implementation/test structure within these decisions and the ensuing UI contract. Use existing stack and source evidence. Comp selection must resolve material visual choices before broad implementation; do not repeat the product/scope interview or treat that step as routine post-implementation UAT.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read the relevant references before planning or implementing.**

### Scope and lifecycle

- `.planning/PROJECT.md` — current product truth, verification and UI lifecycle defaults.
- `.planning/STATE.md` — current local baseline, preserved preview, exact-source limits, and session continuity.
- `.planning/ROADMAP.md` — Phase 173 boundary and later phase ownership.
- `.planning/REQUIREMENTS.md` — OPUX-09–OPUX-15 and milestone acceptance.
- `.planning/research/v1.43/SCOPE.md` — approved scope, inventory reuse, comp-first sequence, and preservation rules.
- `.planning/reference/OPERATOR-UI-REFINEMENT.md` — explicit rejected treatments and traceable time/copy feedback.
- `.planning/reference/OPERATOR-UI-QUALITY.md` — durable operator design and economical verification rules.
- `CONTRIBUTING.md` — scoped verification and PR-first release-train gates.

### Existing product and visual system

- `PRODUCT.md` — co-primary integrator/operator roles and actual capabilities.
- `DESIGN.md` — incumbent vocabulary and the explicit 2026-10-06 revision direction.
- `.impeccable/config.json` — existing comp-first build preference.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — delivered token/component authority; revise rejected rules with implementation.
- `.planning/research/v1.42/UI-SYSTEM.md` — historical component inventory; recheck current source, do not replay fixes.
- `.planning/research/v1.42/UI-AUTOMATION.md` — existing proof lanes and their limits.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — local Phoenix/LiveView context; current official documentation governs API details.
- `prompts/scrypath-brand-book.md` — exploratory identity reference, not a binding palette contract.

### Primary guidance informing the synthesis

These inform accessibility/platform constraints and comparable patterns; our palette, time thresholds, and control choice are project-specific inferences.

- [W3C Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html) and [Contrast Minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum) — readable cues beyond hue.
- [W3C Button Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/button/) and [Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html) — stable labels/states and feedback without moving focus.
- [W3C Content on Hover or Focus](https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html) — exact evidence cannot depend solely on pointer hover.
- [Carbon Status Indicators](https://www.carbondesignsystem.com/building-blocks/core/patterns/status-indicators) — local label/icon semantics for scanning.
- [MDN Clipboard writeText](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText), [localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage), and [storage event](https://developer.mozilla.org/en-US/docs/Web/API/Window/storage_event) — actual browser success/failure and persistence boundaries.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — shared actions, refresh/check metadata, time, badges, verdicts, metrics, and disclosure components.
- `scrypath_ops/assets/js/ops_hooks.js` — shared standalone/mounted refresh preservation and four-second informational toast lifecycle.
- `scrypath_ops/assets/css/app.css` — shared theme/surface/action/status authority; remove superseded gradients and broad status rules rather than piling on overrides.

### Established Patterns

- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` and `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex` — native theme buttons, pre-paint preference/effective appearance, OS and storage listeners. The current pill follows appearance while accessible selection follows preference; storage is currently unguarded.
- The shared time component already formats human/exact values and optional copying, but computes age from current render time, truncates ISO precision, and exposes exact evidence primarily through a title.
- `scrypath_ops/lib/scrypath_ops/posture.ex` — existing summary classification and operational evidence; preserve these semantics rather than treating visual neutralization as a change to health logic.

### Integration Points

- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` — representative Search health state; backend/queue last success currently uses local timestamp formatting and zero-error metrics use success tone.
- `scrypath_ops/assets/js/app.js` and `examples/scrypath_ecommerce/assets/js/app.js` — both clipboard event handlers currently ignore unavailable/denied writes; align their actual outcomes through the existing shared delivery seam.
- `scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs`, `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs`, current LiveView tests, token contrast checks, and `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` / `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` — extend only relevant assertions; retire assertions requiring rejected decoration.
</code_context>

<specifics>
## Specific Ideas

The maintainer's generic fan-out prompt is adapted to a bounded specialist pass with primary guidance and explicit adverse examples, followed by one synthesis. The dependency preference is “another copy and paste is better than another dep,” with justified exceptions allowed. The first realistic light/dark comp includes degraded data, zero/nonzero/unknown metrics, queue failures, long identifiers, operational times, quiet-action states, and the theme preference control.
</specifics>

<deferred>
## Deferred Ideas

No new capability was approved. A local-time preference setting, continuous age updates, new UI framework, infrastructure automation, broader CI services, and incidental workflow redesign are outside this phase. Exact palette/composition is a required next UI-contract decision, not unresolved runtime acceptance. Pre-existing Impeccable sidecar drift remains a nonblocking separate maintenance item.
</deferred>

---

*Phase: 173-shared-visual-foundation-and-operational-time*
*Next: `$gsd-ui-phase 173`, then `$gsd-plan-phase 173`.*
