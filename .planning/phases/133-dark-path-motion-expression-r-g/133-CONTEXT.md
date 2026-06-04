# Phase 133: Dark/path motion expression `[R] [G]` - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 133 delivers the DARKMOTION-01 motion vocabulary for the existing ScrypathOps admin UI: restrained Scrypath path-expression patterns where they serve an operator JTBD, tuned for dark, safe in light/system, and implemented through the existing motion tokens.

This is not a new product surface, not a broad animation pass, and not a re-opening of Phase 134/135 per-screen or shell chrome polish. It must honor Phase 123's A3 precedent: no per-LiveView-patch re-firing reveals, transform/opacity only, no bounce, under 300ms, and reduced-motion neutralized.

</domain>

<decisions>
## Implementation Decisions

### 1. Target Boundary - Small Named JTBD Anchor Set
- **D-01:** Phase 133 should introduce a small, named, opt-in path-motion vocabulary and apply it only to stable JTBD anchors.
- **D-01a:** Allowed initial anchors: the existing route mark; the recommended Control Room intent card; Search federation/merge trace affordances; the Playbook active item/path marker; and optionally the breadcrumb/current path.
- **D-01b:** Interpret DK-19's "route/diagram only" rule as "path semantics only," not "logo only." The phase should pay a design-system dividend without broad animation.
- **D-01c:** Do not animate result-list entry/reveal, broad nav state, ordinary row state, panels, text, buttons, or background washes. No list staggers.
- **Rationale:** Route-mark-only would under-deliver DARKMOTION-01 and leave future screens to invent their own motion rules. Broad animation would violate the restrained ops-console posture and create LiveView patch/flicker risk.

### 2. Primitive Shape - CSS-First Hybrid
- **D-02:** Use a CSS-first hybrid. Motion classes/keyframes live in `scrypath_ops/assets/css/app.css`, are documented in `scrypath_ops/assets/css/DESIGN-TOKENS.md`, and are consumed directly only for stable state or hover effects.
- **D-02a:** Add HEEx primitives only where the DOM has reusable meaning, such as an `ops_path_*` or node/route primitive. Do not wrap every visual effect in a component.
- **D-02b:** Avoid new JS hooks for Phase 133. JS is reserved for already-interactive lifecycle gates or future cases that cannot be made patch-safe with stable CSS state.
- **D-02c:** If a line-draw/reveal effect is needed, fake it with pseudo-elements using `transform: scaleX()` plus opacity. Do not use SVG `stroke-dashoffset`, filters, background-position shimmer, or layout properties.
- **Rationale:** This matches Phase 123's successful pattern: CSS + existing LiveView transition mechanisms only, no behavior change, and no new dependency or hook lifecycle surface for a visual-only phase.

### 3. Node Pulse and Glow - Active Path Only
- **D-03:** Node pulse is allowed only for active path/key-node states. It must not become a decorative loop.
- **D-03a:** Copper node glow may be used where it signals a key route/callout, consuming Phase 131's reserved copper vocabulary (`.ops-copper-node`, `.ops-copper-node--fill`, `--shadow-ops-glow-copper`).
- **D-03b:** Violet glow remains reserved for route/path/diagram emphasis. Do not apply glow to text, resting panels, ordinary buttons, broad backgrounds, or status surfaces.
- **Rationale:** The brand book calls for routed lines, nodes, active paths, and quiet glow. In ScrypathOps, that should read as "operator flow is highlighted," not "the dashboard is animated."

### 4. Code-Block Shimmer - Explicit Opt-In Hover Glint Only
- **D-04:** Ship code-block shimmer only as an explicit opt-in hover glint, e.g. a `shimmer={true}` API or `.ops-code-block--shimmer` class. Do not enable it by default on `ops_code_block`.
- **D-04a:** Never animate code text, JSON payloads, logs, failed-sync reasons, raw result payloads, or anything that reads as operational evidence.
- **D-04b:** The shimmer effect must be a pseudo-element border/overlay glint using opacity/transform only, under hover-capable devices and reduced-motion-safe. No infinite loop, no mount-time shimmer, no background-position animation.
- **D-04c:** Suitable uses are preview/non-critical surfaces, not incident evidence panes. Search and Failed Sync evidence must remain calm and readable.
- **Rationale:** The brand book names "code block shimmer on hover," but ScrypathOps code blocks often hold evidence. Moving the payload itself would imply data is changing or loading and would damage operator trust.

### 5. Verification - Motion-Specific Gate, Not Milestone Gallery
- **D-05:** Phase 133 should lock a motion-specific proof bundle: `mix verify.opsui`, asset rebuild/host compile, static CSS checks for transform/opacity and tokenized durations under 300ms, focused Playwright reduced-motion and interaction checks, a LiveView patch/re-run check proving no re-fire flicker, and a small targeted screenshot set for affected surfaces.
- **D-05a:** The focused Playwright proof should exercise each shipped DARKMOTION-01 site in dark and light, including hover/code shimmer, active-path tracing/node pulse, and at least one LiveView patch/re-run path.
- **D-05b:** Use contrast/light pixel gates only if Phase 133 changes color-bearing shimmer/glow end states. Do not make them the primary motion gate.
- **D-05c:** Defer full 40-shot recapture, before/after gallery, full contrast matrix attachment, and human milestone UAT to Phase 136 (DUALVERIFY-01).
- **Rationale:** A `[G]` motion phase needs browser proof, but duplicating Phase 136 would blur ownership and slow iteration. Screenshots are useful at rest/interaction endpoints; they do not prove transient motion alone.

### 6. Forbidden Footguns
- **D-06:** No result-list or row reveal staggers; Phase 123 already rejected CSS-only result reveal because LiveView patches would re-fire it.
- **D-07:** No motion that carries status meaning without accompanying text/ARIA-readable state.
- **D-08:** No spring, bounce, playful easing, count-up tickers, layout/reflow animation, focus-ring animation, or decorative infinite loops.
- **D-09:** Every new motion must be neutralized by the existing global reduced-motion rule or an equally explicit local guard.

### Agent Discretion
- Exact class names and HEEx API names are left to the planner/executor, but they should follow the existing `.ops-*` vocabulary and keep component APIs small.
- Exact anchor count can be trimmed if implementation or verification shows one anchor is noisy or not clearly JTBD-backed.
- Exact Playwright file names and helper reuse are left to planning, but the proof bundle above is locked.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Locked Requirements
- `.planning/ROADMAP.md` -- Phase 133 goal, DARKMOTION-01 requirement mapping, and success criteria.
- `.planning/REQUIREMENTS.md` -- DARKMOTION-01; milestone locked motion rule: restrained, JTBD-serving, transform/opacity only, under 300ms, reduced-motion-safe, deliberate not playful.
- `.planning/STATE.md` -- Phase 123 motion precedent and accumulated v1.34 context, including the A3 no-re-fire decision.

### Brand and Audit Basis
- `prompts/scrypath-brand-book.md` -- Motion section: line draw/reveal, node pulse, active path tracing, code-block shimmer on hover; visual system: routed lines, nodes, quiet glow, dark-mode-forward brand.
- `.planning/phases/129-dark-theme-brand-expression-audit-s-r/129-DARK-AUDIT-BACKLOG.md` -- DK-19 path-motion finding and boundary: route/path/diagram elements only; no panels, text, or background floods.

### Prior Decisions Feeding This Phase
- `.planning/phases/130-dark-surface-ramp-depth-tokens-g/130-CONTEXT.md` -- light parity and dark token proof patterns; verification scope discipline.
- `.planning/phases/131-glow-dark-shadow-and-copper-accent-system-r-g/131-CONTEXT.md` -- glow/copper vocabulary, quiet glow boundary, reserved copper glow token.
- `.planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTEXT.md` -- AA gate discipline and contrast/light-baseline proof ownership.

### Current Code Surfaces
- `scrypath_ops/assets/css/app.css` -- existing motion tokens, keyframes, reduced-motion neutralization, route mark, glow/copper classes, row/verdict motion, code-block styling.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` -- motion token documentation, Phase 123 A1/A2/A4 rules, A3 rejection, glow/copper token catalog.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` -- shared components: `ops_page_header`, `ops_trail`, `ops_verdict`, `ops_intent_card`, `ops_result_row`, `ops_object_item`, `ops_code_block`.
- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` -- recommended intent-card anchor and route/flow JTBD.
- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` -- federation/merge trace, search result/code-block surfaces, LiveView patch/re-run risk.
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` -- active playbook item and preview code-block surfaces.
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` -- evidence code blocks that must not shimmer by default.

### Verification Substrate
- `lib/mix/tasks/verify.opsui.ex` -- root ops UI verification task.
- `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` -- existing screenshot harness and deterministic theme/scenario setup.
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` -- AA/AAA browser contrast matrix; use if color-bearing endpoints change.
- `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` -- light baseline diff gate; use only if Phase 133 intentionally touches light end states and needs parity proof.
- `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` -- seeded/admin helper patterns for focused Playwright proof.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `--duration-ops-*` and `--ease-ops-*` in `app.css` -- already provide the timing/easing authority for restrained motion.
- Existing keyframes `ops-fade-in`, `ops-fade-out`, `ops-modal-in`, `ops-modal-out`, and `ops-pulse` -- show the local CSS pattern and reduced-motion handling.
- `.ops-glow`, `--shadow-ops-glow`, and `--shadow-ops-glow-copper` -- already define the quiet dark glow vocabulary Phase 133 should consume sparingly.
- `.ops-copper-node` and `.ops-copper-node--fill` -- reserved Phase 131 node primitives that Phase 133 can now apply to path/key-node semantics.
- `ops_code_block/1` -- central place for opt-in shimmer API/class if shipped.
- `ops_trail/1`, `ops_intent_card/1`, `ops_result_row/1`, `ops_object_item/1` -- existing shared components where stable path/active-state classes can be added without per-screen duplication.

### Established Patterns
- Light parity is protected by either no-op/light-quiet defaults or explicit proof when light end states change.
- Dark-specific visual expression is mirrored through both `[data-theme="dark"]` and system-dark media paths where token overrides are needed.
- Presentation changes live in CSS/design tokens first; HEEx components stay small and semantic.
- Existing reduced-motion safety is centralized through a global `@media (prefers-reduced-motion: reduce)` rule.
- Phase 123 rejected CSS-only result reveal/stagger because LiveView DOM patches would replay it.

### Integration Points
- Route mark: `.ops-route-mark` already exists and carries the approved violet/copper gradient plus dark glow.
- Control Room: recommended intent card is a stable JTBD anchor for "what path should I take next?"
- Search: federation metadata and merge trace are natural "path through results" anchors; raw result payloads are evidence and should stay calm.
- Playbooks: active/selected playbook item can carry a path marker; preview JSON should not shimmer unless explicitly opted into a non-evidence preview state.
- Failed Sync: evidence code blocks are explicitly excluded from default shimmer.

</code_context>

<specifics>
## Specific Ideas

- One coherent design direction: "path motion as operator flow," not generic animation.
- Prefer reusable `.ops-path-*` or similarly named classes so Phase 134/135 can reuse the vocabulary without re-deciding motion semantics.
- Shimmer, if present, should read as an inspectable-surface glint on hover, never as data movement.
- Verification should include a patch-refire regression because LiveView patch semantics are the main phase-specific motion risk.

</specifics>

<deferred>
## Deferred Ideas

- Full 40-shot recapture, before/after gallery, full contrast matrix attachment, milestone audit, and human UAT remain Phase 136 (DUALVERIFY-01).
- Broad per-screen visual polish remains Phase 134.
- Shell chrome-wide motion/glow polish remains Phase 135 unless a Phase 133 anchor is already in the shared shell path vocabulary.
- Marketing/docs hero code shimmer or richer public-site diagrams are outside ScrypathOps Phase 133.

</deferred>

---

*Phase: 133-Dark/path motion expression `[R] [G]`*
*Context gathered: 2026-06-04*
