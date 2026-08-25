# Phase 134: Under-iterated surface polish (dual-theme) - Context

**Gathered:** 2026-06-25
**Status:** Ready for planning

<domain>
## Phase Boundary

A per-screen **application** pass that brings three v1.33 under-iterated `scrypath_ops`
surfaces to dark-signature + light-parity quality across all seed states:

1. **Search** — result rows (DK-17)
2. **Sync/Drift** — drift-chips + preflight depth (DK-16)
3. **Playbooks** — empty + populated workspace cards (DK-18)

Plus a verify-and-tune sweep of four cross-screen items (DK-11/13/14/15) that inherit the
systemic ramp from Phases 130–132.

**Adds NO new tokens, NO new components, NO new JS hooks, NO new keyframes.** It only *applies*
the already-shipped design system (Phases 119–133). Closes `129-DARK-AUDIT-BACKLOG.md` rows
DK-11 → DK-18. Hard invariants: **light stays pixel-identical**; **AA gate green in light, dark,
AND system-dark**; copper stays ~5% "earned," never a status tone.

**Not this phase:** shell/header/nav chrome (Phase 135 SHELL-DARK-01); full 40-shot re-capture
+ AA report + before/after gallery as the milestone gate (Phase 136 DUALVERIFY-01); any new
brand-token refinement (none shipped in v1.35 — tokens inherited unchanged).

</domain>

<spec_lock>
## Requirements (locked via UI-SPEC.md)

**The design contract is locked** in `134-UI-SPEC.md` (status: approved). Downstream agents MUST
read it before planning or implementing — the per-surface visual contract, token assignments,
spacing/typography/color scales, copywriting contract, and verification gates are authoritative
and are NOT duplicated here.

**In scope (from UI-SPEC):** apply existing surface-2 ramp + earned copper/glow vocabulary to the
three target surfaces and the DK-11→18 backlog rows; dark hover-border perceptibility; section/card
elevation depth; both themes; all seed scenarios.
**Out of scope (from UI-SPEC):** new primitives/tokens/components/hooks/keyframes; any light-theme
change (must stay pixel-identical); shell chrome (135); brand-token refinement.

This `<decisions>` section captures ONLY the implementation judgment calls the UI-SPEC left open —
resolved via parallel ecosystem/brand/a11y/DX research (see DISCUSSION-LOG).

</spec_lock>

<decisions>
## Implementation Decisions

### Earned-copper scope (success criterion 3)
- **D-01:** Apply copper to **exactly one** site this phase — the Control Room **recommended**
  intent-card (DK-12), via `.ops-copper-badge` (compose `class="ops-badge ops-copper-badge"`) on a
  federation / key-callout badge inside the card head. It layers on top of the existing violet
  ring+seat+glow recommended treatment, reading "Scrypath brand," not generic ops. This is the
  single highest-signal "what do I do next" moment → copper is genuinely *earned* there.
- **D-02:** **HOLD** the optional Sync/Drift preflight copper key-callout. The preflight is wall-to-wall
  `tone_class/1` status chips (`:success`/`:warning`/`:neutral`); dropping copper into that neighborhood
  is the most likely place a user mis-reads it as a status tone (violates the hard "copper is NEVER a
  status tone" law) and pushes past the ~5% budget on a dense screen. DK-16's mandate is depth, not copper.
- **D-03:** Copper badge text color MUST be `var(--color-base-content)` (already baked into
  `.ops-copper-badge`) — never `--color-secondary` as label text (light label-on-tint fails AA at 4.15:1).
  AA for this pairing is **pre-cleared** in DESIGN-TOKENS (base-content on copper-badge tint: dark
  12.07:1 / light 14.86:1 PASS). No new pairing introduced → contrast gate stays green.
- **D-04:** Copper is theme-agnostic (consumes `--color-secondary`, remaps light `#a85d2e` / dark
  `#c17a3e`) — no hand-authored dual-path block needed for the badge itself.

### Cross-screen tune — fix-here vs verify-only (DK-11/13/14/15)
- **D-05:** **DK-11 (Control Room verdict panel): verify-only, no edit.** `.ops-verdict-neutral`
  already routes to `--ops-surface-2` (current `app.css:377`) → resolved systemically. If a dark
  shot still reads coplanar, that is a *systemic ramp* defect → file for **Phase 135**, do NOT patch
  the verdict locally.
- **D-06:** **DK-14 (Posture verdict hero): verify-only, do NOT layer a shadow.** The "warm halo"
  precondition is gone — `--shadow-ops-raised` is already dark-redefined to cool `rgba(0,0,0,0.50)`
  (current `app.css:~1526/1536`), not the warm cream `base-content 10%` the audit feared. If still
  ambiguous, that is a systemic shadow-recipe change (ripples to all consumers) → defer to **Phase 135**.
- **D-07:** **DK-15 (Failed Sync triage notice): verify-only, no edit.** Separation rides the systemic
  surface-2 ramp. If the info-tone notice doesn't read distinct, the fix routes `.ops-notice-surface`
  systemically → defer to **Phase 135**.
- **D-08:** **DK-13 (Posture table row separators): the ONLY in-pass-eligible tune, behind an OBJECTIVE
  trigger.** Replace the SPEC's subjective "if rows still read faint" with a measured threshold: at the
  dark 390px posture-incident shot, compute the contrast ratio between the per-schema table row-border
  color and the surface-2 row fill (`#1b2230`). **If < 1.20:1 → boost dark-only**
  `border-color: color-mix(in oklch, var(--color-base-content) 18%, transparent)` on the live posture
  table row selector, in BOTH dark paths; light row border stays 12% (pixel-identical). **If ≥ 1.20:1 →
  leave 12%**, verify passes with the recorded ratio as the audit artifact. NOTE: the Phase-129 anchor
  `app.css:719` is **stale** (file shifted ~700 lines) — grep the *current* posture/per-schema table
  row-border selector before editing.
- **D-09:** Rationale (blast radius): DK-14/11/15 edit *systemic* tokens consumed on screens this phase
  isn't screenshotting → light-pixel-diff + AA risk on un-captured surfaces. DK-13 is a *leaf*
  (one dark-only alpha on the posture table) → safe in a per-screen pass. This is the same edit-shape
  as the greenlit hover boost (D-12), so it is consistent, not a new category.

### Binding verification gate (success criteria 1 & 2; 0-human-UAT)
- **D-10:** The binding gate is a **new Playwright computed-style spec**
  `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts`, modeled on the existing
  `admin_path_motion.spec.ts` glow idiom (`getComputedStyle(el).backgroundColor / .borderColor /
  .boxShadow`). It runs across the same `{explicit-light, explicit-dark, system-dark} × {mobile 390,
  desktop 1440}` grid and reuses `helpers/e2e` + `THEME_MODES` / `assertSystemDarkInvariants` from
  `admin_contrast_matrix.spec.ts`. Add npm script `test:e2e:admin-depth`.
- **D-11:** **Assertions (selector → computed prop → expected, dark + system-dark):**
  - `.ops-result-row` / `.ops-data-card` / `.ops-muted-panel` `backgroundColor` === `rgb(27,34,48)`
    (`--ops-surface-2`) **AND** sRGB rel-luminance exceeds the shell `--ops-bg` `rgb(12,15,20)` floor
    by a fixed delta (elevation proof, e.g. ≥ 0.015) — this is what would have caught the original
    coplanar DK-16/17/18 bug (a pixel-diff threshold silently passes it).
  - `.ops-preflight__card--locked` `backgroundColor` steps **above** `.ops-preflight__card` (`#141923`).
  - `.ops-result-row:hover` **and** `.ops-object-item:hover` `borderColor` resolve to `primary 55%` in
    dark and **differ** from resting (proves D-12 on BOTH surfaces).
  - `.ops-object-item-active` `boxShadow` contains the glow RGB `108,92,231` in dark; `none` in light.
  - `.ops-copper-badge` (Control Room recommended card) `color`/tint resolves to `--color-secondary`
    copper (proves D-01 applied); **negative assertion:** no `tone_class`/`badge_class` status chip
    computes to copper (proves D-02 / "never a status tone").
- **D-12:** **Mandatory seed matrix** (each a CI-failing assertion, dark + system-dark): Search
  {`results`, `zero-results`} × Sync-Drift {`drift`} × Playbooks {`empty-workspace`, `populated`}.
  Maps 1:1 to DK shot keys (`06-search…results`, `08-search…zero-results`, `03-sync-drift…drift`,
  `09-playbooks…empty-workspace`, `12-playbooks…populated`). Both viewports run (390 = DK-13 border-alpha
  risk; 1440 = where DK-16/18 coplanarity manifests).
- **D-13:** **Light parity** is pinned by the existing `light-pixel-diff.mjs` at threshold 0 — do NOT
  duplicate light depth checks. A **static token tripwire** is added to `mix verify.opsui`'s `.ops-*`
  CSS contract (`--ops-surface-2: #1b2230`; raised-surface recipes reference the token; dark hover =
  `primary 55%`) as a cheap pre-flight — never the sole gate. The **40-shot matrix stays
  human-spot-review only** for aesthetic reads (halo, "earned copper feel") that resist a threshold.
- **D-14:** CI **MUST build ops assets first** (Phase-133 lesson: the ecommerce dev server does NOT
  live-reload the `scrypath_ops` path-dep; restart `mix phx.server` / build assets or LiveView styles
  never apply). Spec runs against a booted, seeded ops server, never the stale baked image.

### Hover-border boost — Search rows only vs object-items too (DK-17)
- **D-15:** **Parity — apply the dark `primary 32%→55%` hover-border boost to BOTH `.ops-result-row`
  AND `.ops-object-item`.** They already share ONE selector (`app.css:~979-983`) on the same dark
  surface-2, so "Search-only" would require *splitting* the shared rule and actively re-introducing the
  DK-17 faintness on Playbooks. Parity = current behavior + the SPEC Color section verbatim
  ("result rows AND object items on :hover"). Both are list-scan/pick JTBDs.
- **D-16:** Implement as a **dark-only override on the paired selector** (both dark paths); keep the base
  shared rule at `primary 32%` (= the light value, pixel-identical, and dark fallback). The paired
  selector is the drift guard (no shared `--hover-border` var exists and none may be added this phase).
- **D-17:** Hover vs active stay on **different axes** → rest < hover < active is unambiguous: hover =
  border 55% + `--shadow-ops-mid` (neutral, NO glow); active (`.ops-object-item-active`) = border 55% +
  inset `primary 20%` ring + violet `--shadow-ops-glow`. The active item is the only one glowing; no
  box-shadow conflict.
- **D-18:** a11y: hover border is a **non-text affordance (3:1 floor, not 4.5:1)** and is independent of
  the global `:focus-visible` keyboard ring. **55% is strictly more contrast than the already-passing
  32%**, so parity cannot introduce an AA regression — it only makes Playbook hover *more* perceptible.

### Claude's Discretion
- Exact luminance-delta floor and the 1.20:1 DK-13 trigger value (D-08/D-11) are starting points; the
  planner/executor may tune to the smallest value that reliably distinguishes raised-from-floor without
  flaking — but the trigger MUST stay an objective measured number, never a subjective read.
- Precise copper-badge label/content on the recommended intent-card (e.g. "Federated" vs a key-scope
  callout) is the executor's call, provided it's a genuine key fact on the scan path.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract & requirements
- `.planning/phases/134-under-iterated-surface-polish-dual-theme-s/134-UI-SPEC.md` — **LOCKED** design
  contract (per-surface visual contract, color/spacing/type scales, copywriting, verification gates).
  Read FIRST.
- `.planning/phases/129-dark-theme-brand-expression-audit-s-r/129-DARK-AUDIT-BACKLOG.md` rows
  **DK-11 → DK-18** — the findings this phase closes (with original file anchors; note several are stale).

### Design system / tokens (authority)
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — token authority: surface-1/2/bg triplets, `.ops-copper-*`
  defs + AA pre-clearances, glow/shadow recipes, the two governing laws.
- `scrypath_ops/assets/css/app.css` — live CSS. Key anchors (verify line numbers — file has shifted):
  shared hover `~979-983`; result-row `~961-974`; object-item `~711-729`; dark surface-2 fills
  data-card `~1424-1431` / result-row `~1434-1441`; active-item glow `~1495-1502`; verdict-neutral
  `~377`; dark raised-shadow `~1526/1536`.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — `.ops-*` function components
  (`ops_intent_card` ~496-516, `ops_data_card`, `ops_result_row`, `ops_notice`, `tone_class/1`).

### Brand (NEWER — prefer over the old prompt)
- `brandbook/notes/decision-log.md`, `brandbook/notes/research.md`, `brandbook/notes/pressure-test.md`,
  `brandbook/notes/accessibility-checks.md`, `brandbook/tokens/` — newer brand book (v1.35). §6.5: dark
  1px borders "slightly blue-gray slate" (`#2A3446`) — informs the DK-13 18% target.
- `prompts/scrypath-brand-book.md` — older brand prompt; consult only for original copper-vocabulary intent.

### Verification harness to EXTEND (do not invent a new one)
- `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` (`:196-216` glow computed-style idiom;
  `:179-194` LiveView-patch safety probe) — the template for the new depth spec.
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` (`THEME_MODES`,
  `assertSystemDarkInvariants`, seed/index map) — reuse the theme grid + seed scenarios.
- `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` — light-parity gate (threshold 0).
- `mix verify.opsui` task — static `.ops-*` CSS contract + MotionContractTest + light pixel-diff
  (add the token tripwire here).

### Ecosystem research (lenses applied during discussion)
- `prompts/phoenix-live-view-best-practices-deep-research.md`,
  `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — Phoenix/LiveView idiom.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.ops-copper-badge` (app.css, shipped Phase 131): theme-agnostic copper badge, AA pre-cleared —
  consume directly for D-01; no new token.
- Shared hover selector `.ops-result-row:hover, .ops-object-item:hover` (app.css ~979-983): ONE rule
  already governs both lists → boost rides it (D-15/16); no selector split.
- `.ops-object-item-active` (app.css ~1495-1502, Phase 133): patch-safe active glow — orthogonal to hover.
- `admin_path_motion.spec.ts` glow probes + `admin_contrast_matrix.spec.ts` theme grid: the exact
  `getComputedStyle` + `THEME_MODES` harness the new depth spec extends (D-10).
- Dark surface-2 fills for `.ops-data-card` / `.ops-result-row` already wired (resting fill done) —
  remaining work is hover (D-15), section/card depth verification, copper (D-01), and DK-13 (D-08).

### Established Patterns
- Both-themes invariant: every dark change authored in BOTH `[data-theme="dark"]` and
  `@media (prefers-color-scheme: dark) html:not([data-theme="light"])` paths; light untouched.
- daisyUI classnames unprefixed; custom classes `.ops-` BEM-ish; never hardcode a raw Tailwind step
  when an `-ops-` token / named floor exists.
- Deterministic computed-style assertions over subjective visual reads (Phase 133 precedent;
  `make verify-path-motion` shape).

### Integration Points
- New `admin_surface_depth.spec.ts` runs against the booted seeded ops server (build ops assets first,
  D-14) and plugs into the same CI lane as `test:e2e:admin-contrast` / `admin_path_motion`.

</code_context>

<specifics>
## Specific Ideas

- The "one earned copper moment" model mirrors how Linear/Vercel/Stripe anchor a scarce accent on the
  single recommended affordance; the documented ecosystem footgun is accent *inflation* — exactly why
  D-02 holds the second copper site.
- DK-13's objective trigger (measured border↔surface contrast < 1.20:1) is the "convert a subjective
  UAT read into a CI-enforced number" pattern the owner prefers (0-human-UAT), feeding Phase 136.

</specifics>

<deferred>
## Deferred Ideas

- **Sync/Drift preflight copper key-callout** — held this phase (D-02); revisit only if a later brand
  pass finds the preflight needs a brand moment AND it can be kept off status surfaces.
- **Systemic dark shadow-recipe re-layering (DK-14) / notice-surface routing (DK-15) / verdict coplanar
  fix (DK-11)** — if verify-only finds a real gap, these are systemic (cross-screen ripple) → **Phase 135
  SHELL-DARK-01**, where the dark ambient-shadow recipe and chrome are in scope and get full-matrix re-verify.
- **Extracting a shared `--hover-border-dark` token** so the two hover surfaces can never drift — not this
  phase (no new tokens allowed); candidate for a future token-hygiene pass.
- **Full 40-shot re-capture + AA report + before/after gallery as the milestone gate** — **Phase 136
  DUALVERIFY-01**.

</deferred>

---

*Phase: 134-under-iterated-surface-polish-dual-theme-s*
*Context gathered: 2026-06-25*
