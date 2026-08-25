# Phase 135: Shell chrome polish (dual-theme) `[S]` - Context

**Gathered:** 2026-06-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 135 delivers a focused ScrypathOps **shared shell chrome** pass across all six
operator surfaces: header/nav, inline brand mark, command palette / shortcut sheet, theme
toggle, flash/toast notices, and the `.ops-shell` radial violet wash.

This is a dark-signature + dual-theme polish phase, not a screen feature phase. It should make
the shell read as a calm, premium operator console in dark while preserving the already-green
light/system behavior unless a shell-only, objective defect requires a documented exception.

**In scope:** visual depth, contrast, state clarity, shell-selector durability, and focused browser
proof for the existing shared chrome.

**Out of scope:** new runtime/library capability, new operator workflow, new navigation structure,
new LiveComponent architecture, broad light-theme redesign, palette/type/logo churn, full 40-shot
gallery, milestone audit, or human UAT. Those final milestone proof artifacts remain Phase 136.

</domain>

<decisions>
## Implementation Decisions

### 1. Light-change boundary
- **D-01:** Phase 135 is **dark-first and shell-only**. Keep light pixel-identical by default.
  Allow a light-theme change only when all of these are true: the target is explicitly shell chrome
  in this phase, the defect is objective (AA/state/focus/geometry), the change is local to shell
  selectors/components, and the planner records the rationale plus verification.
- **D-02:** Do **not** open a broad light-theme chrome redesign. v1.35 kept palette/type stable;
  Phase 134 restored light parity; reopening light aesthetics now would create milestone churn and
  blur Phase 136's final before/after evidence.
- **D-03:** If light pixels move, that is an explicit exception, not a silent pass. The plan/summary
  must say which selector moved, why it was necessary, and which gate recaptured or approved it.

### 2. Header/nav, brand mark, and shell wash
- **D-04:** Preserve the existing Phoenix structure: `ScrypathOpsWeb.Layouts.app/1` owns the ops
  shell, and `ScrypathOpsWeb.Nav.primary/1` owns the ordered primary navigation. No nav IA or shell
  variant restructuring is needed for SHELL-DARK-01.
- **D-05:** Active nav stays conventional and accessible: `aria-current="page"`, a text-bearing
  `--color-primary-strong` fill, and a restrained dark glow composed on top of existing surface lift.
  Do not use decorative gradients, pulsing, or extra path motion on ordinary nav items.
- **D-06:** The header should read as a seated, useful operator surface, not a hero bar. Use the
  existing dark ambient-shadow-plus-border recipe (`--shadow-ops-panel-dark` / overlay composition)
  where it improves separation, with both explicit dark and system-dark paths mirrored.
- **D-07:** The `.ops-shell` wash remains **one quiet top-left radial**. Tune dark/mobile strength down
  before it reads as a violet blob. No extra gradient layers, orbs, bokeh, noise, or decorative texture.
- **D-08:** Reconcile stale route-mark CSS with the v1.35 inline SVG brand mark if needed. The old
  `.ops-route-mark` selector should not remain the only proof target if no current element uses it.
  Either attach a small stable class to the inline mark or move proof to the live selector, without
  changing the brand identity.

### 3. Command palette, flash, and theme toggle
- **D-09:** Keep behavior mostly intact. The command palette remains the existing client-side
  `CommandPalette` hook; flash remains the framework-level flash component; theme preference remains
  root-script/localStorage driven. Do not redesign these into new public APIs or LiveComponents.
- **D-10:** Promote shell chrome to durable `.ops-*` selectors where useful for styling and proof:
  e.g. `ops-theme-toggle`, `ops-theme-toggle__pill`, `ops-theme-toggle__button`, and
  `ops-flash`/`ops-flash--info|error`, while preserving existing IDs used by JS and tests. This follows
  the local design-token law: reusable chrome gets component classes instead of brittle ID/utility
  styling.
- **D-11:** Minor semantic hardening is in scope when it makes an existing claim true without behavior
  redesign. Examples: selected theme buttons exposing accurate pressed/current state, command-palette
  active option state, close buttons with stable labels, and focus-return/focus-visible behavior if
  the browser proof finds a gap.
- **D-12:** If `role="dialog"` + `aria-modal="true"` stays on command palette / shortcut sheet, the
  implementation must not leave obvious modal-a11y debt unverified. Either prove enough focus behavior
  for the current bounded palette or downgrade the semantic claim to match actual behavior. Do not ship
  stronger ARIA than the UI actually honors.
- **D-13:** Flash styling should adopt the dark ambient-shadow-plus-border recipe and remain passive
  operator feedback. Do not make flashes bounce, glow, or steal focus. Keep `aria-live`/`role="alert"`
  semantics and text/icon pairing; color must not be the only signal.

### 4. Verification shape
- **D-14:** Add a focused browser proof for SHELL-DARK-01 rather than relying only on static contracts.
  Preferred shape: `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` plus an npm script such
  as `test:e2e:admin-shell`, reusing `helpers/theme-grid.ts`.
- **D-15:** The shell spec should cover `THEME_MODES` (`explicit-light`, `explicit-dark`, `system-dark`)
  and both mobile/desktop viewports for shared shell consistency. It should visit all six admin surfaces
  or use the existing scenario captures so header/nav/wash/chrome do not drift by route.
- **D-16:** The shell spec should explicitly exercise hidden/interactive chrome that contrast screenshots
  can miss: open/filter/empty/close command palette, shortcut sheet open/close, theme toggle system/light/dark
  transitions (`data-theme*`, localStorage, pill position, selected indicator), and at least one visible flash
  with computed shadow/border/background assertions.
- **D-17:** Use computed-style checks for shell visual contracts: header separation, nav active fill and
  dark glow, shell wash boundedness (prefer relative/computed checks over screenshot thresholds), command
  palette/flash overlay shadow composition, focus-ring visibility, and AA contrast via the existing axe
  matrix/contrast harness.
- **D-18:** Keep Phase 136 ownership intact. Do not move the full 40-shot recapture, v1.33->v1.34 gallery,
  milestone audit, or human UAT into Phase 135 unless Phase 136 is intentionally collapsed.

### 5. Design/JTBD principles for the planner
- **D-19:** Primary user persona is a Phoenix/Ecto operator or maintainer trying to answer, "Can I trust
  search right now, and where do I go next?" Shell chrome should orient, not decorate. The header/nav,
  palette, and flash are wayfinding aids around operational evidence.
- **D-20:** JTBD language: nouns are surfaces (`Control Room`, `Posture`, `Failed Sync`, `Sync Drift`,
  `Search`, `Playbooks`), events are navigation/theme/flash/palette interactions, verbs are jump,
  refresh, inspect, recover, explore, and close. Keep UI microcopy concrete and task-first.
- **D-21:** Design pillars to preserve: accessibility (AA hard gate, focus visible/not obscured),
  clarity (chrome never competes with evidence), consistency (same shell across six screens), performance
  (CSS/computed state, no heavy visual effects), resilience (system-dark and explicit-dark both covered),
  maintainability (named selectors and tokenized values), restraint (quiet glow, no dashboard-toy motion),
  and developer ergonomics (small components, stable tests, no new dependencies).

### Claude's Discretion
- Exact selector names may vary if they fit existing `.ops-*` vocabulary and avoid breaking JS hooks.
- Exact shell-wash alpha/extent values are left to implementation, but the final result must read quiet
  in dark mobile and desktop and must be backed by objective checks plus screenshot spot review.
- The focused shell browser spec may scope axe checks to the visible interactive chrome rather than rerun
  the whole contrast matrix inside every interaction, as long as the existing contrast gates remain part
  of the phase verification bundle.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and prior decisions
- `.planning/ROADMAP.md` — Phase 135 goal, success criteria, and Phase 136 boundary.
- `.planning/REQUIREMENTS.md` — v1.34 appendix requirements for SHELL-DARK-01 and DUALVERIFY-01.
- `.planning/STATE.md` — accumulated v1.34 context, v1.35 completion note, and current phase state.
- `.planning/phases/129-dark-theme-brand-expression-audit-s-r/129-DARK-AUDIT-BACKLOG.md` — DK-10 shell wash finding plus ramp/depth findings DK-05/DK-06 inherited by shell chrome.
- `.planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTEXT.md` — text contrast split: Phase 132 fixed readable muted/violet math; Phase 135 owns chrome/depth/styling.
- `.planning/phases/133-dark-path-motion-expression-r-g/133-CONTEXT.md` — restrained path-motion rules, no decorative loops, transform/opacity discipline, reduced-motion safety.
- `.planning/phases/134-under-iterated-surface-polish-dual-theme-s/134-CONTEXT.md` — surface-depth decisions, light parity precedent, dark ambient-shadow-plus-border recipe, verify-only defects routed to Phase 135 if found.
- `.planning/phases/134-under-iterated-surface-polish-dual-theme-s/134-03-SUMMARY.md` — Phase 134 verification results; no DK-11/DK-14/DK-15 systemic defect was filed for Phase 135.

### Live shell code
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` — ops shell layout, inline brand mark, header/nav, theme toggle, flash group.
- `scrypath_ops/lib/scrypath_ops_web/nav.ex` — ordered primary nav and route/title/group labels.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — `ops_command_palette/1`, shortcut sheet, shell-adjacent components.
- `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex` — flash/toast component and LiveView JS show/hide transition helpers.
- `scrypath_ops/assets/js/app.js` — `CommandPalette` hook, keyboard behavior, close/open timing, copy flash fallback.
- `scrypath_ops/assets/css/app.css` — live token definitions and shell chrome selectors: `.ops-header`, `.ops-shell`, `.ops-nav-*`, `#flash-group`, `.ops-cmdk*`, theme toggle selectors, dark/system-dark override blocks.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — design-token authority: surface ramp, shadow/glow recipes, motion, focus, copper rules, AA floors.

### Brand and design authority
- `brandbook/notes/decision-log.md` — v1.35 decisions: keep palette/type, formalize token tiers, no gratuitous product thrash.
- `brandbook/notes/pressure-test.md` — brand audit: quiet wayfinding, copper/violet role, biggest risk is token/theme thrash.
- `brandbook/notes/research.md` — cited brand/design-token/a11y research; prefer semantic token remapping and AA hard gates.
- `brandbook/notes/accessibility-checks.md` — product-relevant contrast rules for violet/copper/muted/focus.
- `brandbook/tokens/tokens.json`, `brandbook/tokens/tokens.css`, `brandbook/tokens/daisyui-theme.example.js` — newer brand-token package; consult before older prompt when conflicts appear.
- `prompts/scrypath-brand-book.md` — older brand strategy; still useful for dark-mode-forward, wayfinding, quiet glow, ambient-shadow-plus-border guidance when not superseded by `brandbook/`.

### Phoenix/LiveView and verification guidance
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix function component, HEEx, route, LiveView testing, and boundary guidance.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — LiveView components, hooks, JS boundaries, and testing guidance.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — system-design and Phoenix ecosystem fit.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — verification/release discipline.
- `examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts` — reusable explicit-light/explicit-dark/system-dark grid and six-screen capture helpers.
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` — AA/AAA contrast matrix and axe reporting pattern.
- `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` — computed-style depth assertions; model for shell visual contracts.
- `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` — focused browser proof precedent for motion/reduced-motion/patch safety.
- `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` — light parity gate; use for default no-light-change policy and explicit exceptions.
- `lib/mix/tasks/verify.opsui.ex` — root ops UI verification task; add static shell token/selector tripwires here only if cheap and durable.
- `scrypath_ops/assets/css/contrast-pairs.mjs` — token/selector contrast manifest; extend only for new tracked text/UI contrast pairs.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Layouts.app/1` already centralizes ops shell chrome, including header/nav, theme toggle, main shell, flash group, and command palette.
- `Nav.primary/1` already provides the ordered primary surfaces and route labels; use it rather than duplicating nav state.
- `ops_command_palette/1` already renders a global command palette plus shortcut sheet with `role="dialog"` and `aria-modal="true"`.
- `CommandPalette` JS hook already owns open/close, filter, active item, keyboard navigation, shortcut sheet, and refresh shortcut without server events.
- `--ops-surface-*`, `--shadow-ops-panel-dark`, `--shadow-ops-overlay`, `--shadow-ops-glow`, `--ops-text-muted`, and `--color-primary-strong` already encode the dark ramp, overlay depth, readable muted text, and text-bearing violet rule.
- Existing browser helpers already cover explicit light, explicit dark, system-dark, mobile 390, desktop 1440, and seeded admin surfaces.

### Established Patterns
- Custom reusable UI uses `.ops-*` classes; daisyUI classnames stay unprefixed. Do not add raw utility-only styling for durable shell chrome.
- Dark visual changes must be authored in both explicit `[data-theme="dark"]` and system-dark `@media (prefers-color-scheme: dark) html:not([data-theme="light"])` paths unless they ride semantic daisyUI tokens.
- Function components are preferred for markup reuse; LiveComponents are not introduced for stateless chrome.
- JS hooks are allowed for real browser-owned behavior, but Phase 135 should not add a new hook unless focused verification proves it is necessary.
- Motion remains restrained: under 300ms, transform/opacity/color/shadow only, reduced-motion-safe, no decorative loops or re-firing LiveView patch reveals.
- AA is a hard gate; AAA body/long-form remains advisory/report-only.

### Integration Points
- CSS edits connect through `scrypath_ops/assets/css/app.css` and must keep `DESIGN-TOKENS.md` in lockstep.
- Markup/class edits connect through `layouts.ex`, `ops_ui.ex`, and `core_components.ex`; preserve IDs used by `app.js`.
- Browser verification connects through `examples/scrypath_ecommerce/e2e/` and a source Phoenix server with rebuilt ops assets.
- Static contract checks connect through `mix verify.opsui` if a cheap selector/token assertion is added.

</code_context>

<specifics>
## Specific Ideas

- Agent research converged on the same path:
  - Light boundary: dark-first with narrow shell-only light exceptions.
  - Header/nav/wash: subtle token/CSS tune, no IA/nav restructuring, no loud branded chrome.
  - Palette/flash/theme toggle: named `.ops-*` chrome classes and small semantic hardening, not behavior/API redesign.
  - Verification: focused shell browser spec, not full Phase 136 gallery/UAT.
- External research used by the discussion:
  - Phoenix LiveView `Phoenix.Component` docs support function components with declared attrs/slots for reusable markup.
  - Phoenix LiveView JS interop docs support small hooks/JS commands for client-owned DOM behavior.
  - daisyUI theme docs support default + `prefersdark` theme behavior; Tailwind docs support data-attribute dark variants.
  - W3C WCAG 2.2 / APG docs frame AA contrast, focus visibility/not-obscured, and modal dialog expectations.
  - Playwright accessibility guidance supports interaction-before-axe and browser-level checks for CSS/media-state behavior.
  - GitHub/Linear normalize command palettes for quick navigation; the lesson is discoverable, keyboard-first navigation, not heavy visual chrome.
- The most important UX judgment: shell chrome should make the operator feel oriented and in control. It should never compete with incident evidence, status tones, tables, or code payloads.

</specifics>

<deferred>
## Deferred Ideas

- Broad light-theme shell redesign — defer to a future explicit light-theme or brand-token milestone if concrete evidence appears.
- Full command palette/combobox redesign or dependency adoption — defer unless focused Phase 135 browser proof shows the current bounded palette cannot honestly satisfy its ARIA/keyboard claims.
- New nav IA, shell variants, or operator productization — out of scope; current posture-first IA and six-screen route set are preserved.
- Full 40-shot recapture, v1.33->v1.34 before/after gallery, milestone audit, and human UAT — Phase 136 DUALVERIFY-01.
- HexDocs/website/README brand adoption follow-ups — v1.35 already handled live brand adoption; not Phase 135.

</deferred>

---

*Phase: 135-shell-chrome-polish-dual-theme-s*
*Context gathered: 2026-06-26*
