# Phase 131: Glow, dark shadow, and copper accent system `[R] [G]` - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Add three brand-signature layers on top of the existing dark token system (shipped by Phases
128–130): **(1) ambient seated-depth panel shadow** (`--shadow-ops-panel-dark`), **(2) a quiet
opt-in violet glow** (`--shadow-ops-glow` + `.ops-glow`), and **(3) a copper 5% accent vocabulary**
(`.ops-copper-eyebrow` / `.ops-copper-badge` / `.ops-copper-node[--fill]` + `--shadow-ops-glow-copper`).

**CSS + token only.** No new Elixir components, no behavior changes, no LiveView hooks. Both-theme,
AA-safe, **light pixel-identical** (the D-11 proof bundle is the `[G]` cross-AI gate).

**Closes:** GLOW-01, COPPER-01. **Builds on** Phase 130's surface ramp + D-10 dual-path shadow
pattern. **Consumes** findings DK-06 (ambient depth), DK-07 (copper absence), DK-10 (shell wash).

</domain>

<spec_lock>
## Requirements (locked via UI-SPEC.md)

**The design contract is locked by `131-UI-SPEC.md`** (a `/gsd:ui-phase` design contract verified
by gsd-ui-checker). It pre-populates **everything** — token names/values, glow allowed-sites, copper
classes, the complete 9-pairing AA evidence table, the 10-step Implementation Checklist, the
Light-Theme Invariants table, and the DESIGN-TOKENS.md lockstep obligations. "User input: 0 — all
values pre-populated from upstream artifacts."

Downstream agents **MUST read `131-UI-SPEC.md` before planning or implementing.** Token values, AA
pairings, and allowed-application-site tables are not duplicated here.

**In scope (from UI-SPEC Scope Guard):** three token clusters added to `app.css` + `DESIGN-TOKENS.md`
— ambient dark panel depth, quiet violet glow, copper accent vocabulary. All changes leave light
pixel-identical.

**Out of scope:** any new Elixir component, behavior change, or LiveView hook; per-screen copper
*badge wiring* (deferred — see D-01); the consuming copper-glow *hover rule* (deferred — see D-03).

The discussion below resolves the three genuine HOW ambiguities the UI-SPEC left open (the spec's
"allowed application sites" tables describe where the vocabulary *may* be used, not what 131 *wires
up*; the recommended-card 3-layer composition; and whether to declare the optional copper-glow token).

</spec_lock>

<decisions>
## Implementation Decisions

Calibration: technical owner, `vendor_philosophy: opinionated` → `minimal_decisive`. Per the explicit
Phase 128/129/130 precedent, the three gray areas were locked **codebase-grounded** (the UI-SPEC's own
Implementation Checklist + the live `app.css`/`ops_ui.ex`), **not** external ecosystem research — a
CSS/token phase gains nothing from web research. All three locked to the decisive recommendation in
one pass.

### ① Application surface — ship the system + the one zero-cost in-situ proof; defer per-screen badges to 134
- **D-01:** Phase 131 ships **tokens + classes + all zero-markup CSS applications**, plus the **shared
  eyebrow re-style**, and **defers all per-screen copper-badge/node wiring to Phase 134** (SCREEN-DARK-01).
  Concretely, **131 wires up:**
  - `--shadow-ops-panel-dark` applied to `.ops-panel`, `.ops-cmdk__panel`, `#flash-group > *`,
    `.ops-intent-card` via a **dark-scoped override block** (D-10 dual-path) — pure CSS, no markup.
  - `.ops-glow` applied to `.ops-route-mark` (always in dark) and `.ops-nav-item-active` (active pill,
    dark) via dark-scoped CSS — these classes already sit on those elements, so no markup edit.
  - `.ops-intent-card--recommended` glow composition (D-02) — pure CSS.
  - Shell wash mobile tune (14%→10% alpha, 34rem→28rem extent at `max-width: 640px`) — pure CSS.
  - **Eyebrow re-style:** swap the inline `text-ops-sm font-semibold uppercase tracking-wide
    text-secondary` utilities at the **single shared `ops_page_header` slot** (`ops_ui.ex:23`) for
    `.ops-copper-eyebrow`. One edit, propagates to all 6 screens. This is a **re-style of an existing
    string/slot, not new markup** — and it is the phase's in-situ proof the copper vocabulary works.
- **D-01a:** **Declare** `.ops-copper-badge`, `.ops-copper-node`, `.ops-copper-node--fill` in
  `@layer components` (the vocabulary ships now), but **do NOT wire them into any per-screen template**
  in 131. The Search federation badge, Playbook file-type badge, and Control-Room intent-card icon node
  are **per-screen `.heex` edits across LiveViews → Phase 134.**
- **Rationale:** the UI-SPEC's own 10-step Implementation Checklist lists exactly these CSS/dark-scoped
  applications + declaring the copper classes — it does **not** list per-screen badge edits. Keeping
  per-screen markup out preserves this `[G]` gate's clean blast radius (token/CSS + light-parity proof,
  not per-screen markup) and matches the milestone ordering ("131 = systemic vocabulary; 134 = per-screen
  dividends"). The eyebrow is the lone justified in-situ application because it is one shared slot and a
  re-style.

### ② Recommended intent-card dark composition — all three layers, token refs, one dark-scoped declaration
- **D-02:** In dark, `.ops-intent-card--recommended` composes **all three** box-shadow layers in a single
  dark-scoped override, via **token references** (stays tunable), painted in this order:
  ```css
  /* dark-scoped (D-10 dual-path): [data-theme="dark"] + media-dark html:not([data-theme="light"]) */
  .ops-intent-card--recommended {
    box-shadow:
      inset 0 0 0 1px color-mix(in oklch, var(--color-primary) 45%, transparent),  /* ring — on top */
      var(--shadow-ops-panel-dark),   /* ambient seat */
      var(--shadow-ops-glow);          /* violet aura — outermost / behind */
  }
  ```
  Order is deliberate: the crisp violet inset ring reads on top, panel-dark provides the seated depth the
  rest of the intent-card family gets, and the glow sits behind as a soft halo.
- **D-02a:** **Light is untouched** — the recommended card keeps its existing
  `var(--shadow-ops-surface), inset 0 0 0 1px color-mix(primary 45%)` (current value at `app.css:866-870`).
  The 3-layer stack exists only under the dark paths.
- **Rationale:** the recommended card **is** an `.ops-intent-card`, so it should share the family's
  panel-dark seated depth rather than float differently; dropping panel-dark (the rejected alternative)
  would visually separate it from its siblings. Token refs over literal rgba so the ladder stays
  tunable from one site.

### ③ `--shadow-ops-glow-copper` — declare now, no consumer
- **D-03:** **Declare** `--shadow-ops-glow-copper` in both D-10 dark paths (`0 0 6px 1px rgba(193,122,62,0.25)`)
  with `@theme` light default `none`, per UI-SPEC checklist step 4. **No `.ops-*` class or rule consumes
  it in 131.** The consuming key-node/key-callout **hover rule is deferred to Phase 133/134.**
- **Rationale:** one line per path, zero visual/light impact with no consumer (so zero `[G]`-gate risk),
  and it means 133/134 hover work can use it without reopening the `app.css` token block. Pure upside.

### Claude's Discretion (held by researcher/planner)
- Exact authoring site/ordering of the dark-scoped override blocks within `app.css` (must follow the
  D-10 dual-path precedent at `app.css:525-533` and the Phase-130 shadow-override blocks).
- Whether the four panel-dark target overrides live in one shared dark-scoped rule block or per-selector
  blocks — provided light stays pixel-identical (`--shadow-ops-panel-dark` never declared in light).
- The precise `DESIGN-TOKENS.md` section wording (two new sections per UI-SPEC "Lockstep Obligations").
- The `mix verify.opsui` vs `mix test`/`mix opsui.test_a11y` naming question (flagged D-13 in Phase 130;
  the UI-SPEC's checklist says `mix verify.opsui` — reconcile with the real alias or add the alias).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The locked design contract (read first)
- `.planning/phases/131-glow-dark-shadow-and-copper-accent-system-r-g/131-UI-SPEC.md` — **the locked
  design contract.** Token names/values, glow allowed-sites, copper classes, the full 9-pairing AA
  evidence table, the 10-step Implementation Checklist, Light-Theme Invariants, and DESIGN-TOKENS
  lockstep obligations. This is the WHAT and most of the HOW — read it before anything else.

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 131" — goal, three success criteria, `[R] [G]` tags. (§Ordering
  Rationale confirms 131 = systemic vocabulary, 134 = per-screen dividends.)
- `.planning/REQUIREMENTS.md` → **GLOW-01, COPPER-01** + the §Traceability table.

### Tokens / surfaces being changed
- `scrypath_ops/assets/css/app.css` — the `@theme` block (declare `--shadow-ops-glow`,
  `--shadow-ops-glow-copper` = `none` light); the two daisyUI `@plugin` theme blocks; the D-10
  dual-path dark override precedent (`select.ops-form-control` chevron ~L525-533) and Phase-130's
  shadow-override blocks; `.ops-intent-card`/`--recommended` (~L842/866-870), `.ops-panel`,
  `.ops-cmdk__panel`, `#flash-group > *`, `.ops-route-mark` (~L994), `.ops-nav-item-active` (~L584),
  `.ops-shell` radial wash.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — `ops_page_header` eyebrow slot (**L23**,
  the `text-secondary` utilities to swap for `.ops-copper-eyebrow`; **verified path** — note
  `scrypath_ops_web`, not `scrypath_ops`).
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — must gain two new sections: `## Glow + dark ambient
  depth — Phase 131` and `## Copper accent vocabulary — Phase 131` (per UI-SPEC Lockstep Obligations).

### Upstream brand + audit basis
- `prompts/scrypath-brand-book.md` — §6.3 "quiet glow not loud" + 65/20/10/5 ratio, §6.5 "faint ambient
  shadow plus border", §6.7 "restrained glow around path lines", copper-with-dark-text AA rule.
- `.planning/phases/129-dark-theme-brand-expression-audit-s-r/129-DARK-AUDIT-BACKLOG.md` — DK-06
  (ambient depth), DK-07 (copper used in only 2 places), DK-10 (shell wash mobile).
- `.planning/phases/130-dark-surface-ramp-depth-tokens-g/130-CONTEXT.md` + `130-VERIFICATION.md` —
  the D-10 dual-path shadow pattern and the D-11 proof bundle this phase reuses as its gate.

### Verification substrate (the D-11 proof bundle / `[G]` gate)
- `scrypath_ops/mix.exs` — aliases (`test`, `opsui.test_a11y`; reconcile `verify.opsui` per D-13).
- `examples/scrypath_ecommerce/contrast-checker.mjs` + `scrypath_ops/assets/css/contrast-pairs.mjs` —
  the sub-second light-token AA checker (3 AA light pairs must stay unchanged).
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` — `test:e2e:admin-contrast`
  (Cluster 1 must remain 0; Cluster 3 deferred to 132).
- `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` — the light pixel-identity gate
  (**Failed pairs: 0 / 20**). Baseline: `.tmp/admin-screenshots/*light*`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **D-10 dual-path dark override pattern** (`app.css:525-533` + Phase-130 shadow blocks): the in-repo
  precedent for hand-authoring a dark-scoped rule in BOTH `[data-theme="dark"]` and
  `@media (prefers-color-scheme: dark) html:not([data-theme="light"])`. `--shadow-ops-*` are `@theme`
  custom tokens (not daisyUI keys) → they CANNOT ride the `@plugin` pass-through and MUST be
  hand-authored in both dark paths.
- **Shared `ops_page_header` eyebrow slot** (`ops_ui.ex:23`): the eyebrow is a single shared component
  slot — one edit re-styles all 6 screens. The *only* in-situ copper application 131 makes.
- **Existing recommended-card shadow** (`app.css:866-870`): `var(--shadow-ops-surface)` + violet inset
  ring (45% primary) — the light value to leave byte-unchanged; the dark override composes panel-dark +
  glow onto it.
- **Phase-128 contrast harness + light pixel-diff**: re-running these IS the both-theme + light-parity
  gate — no new tooling.

### Established Patterns
- **Light non-modification = proof of parity** (Phase 130 D-04/D-06): the only way to prove light is
  pixel-identical is to not change its inputs. `--shadow-ops-panel-dark` and `--shadow-ops-glow` are
  never declared/applied in light; all new visual layers live under dark-scoped paths.
- **Override at the token / dark-scoped rule, never the base recipe**: apply panel-dark and glow via a
  dark-scoped override block, not by editing the base `.ops-panel`/`.ops-intent-card` definitions —
  preserves light pixel-identity.
- **Copper is a brand accent, never a status tone**: `.ops-copper-*` does NOT join `tone_class/1` /
  `badge_class/1`; it carries no semantic meaning. Always use `var(--color-base-content)` for text
  inside copper badges (AA-verified); `var(--color-secondary)` is AA-safe only as eyebrow text.

### Integration Points
- The copper classes declared here (`.ops-copper-badge`, `.ops-copper-node[--fill]`) and the
  `--shadow-ops-glow-copper` token are **consumed by Phase 134** (per-screen badges) and **Phase 133/134**
  (copper-glow hover) — name and declare them stably now so those phases don't reopen `app.css`.
- The glow/panel-dark layers propagate to Phases 134/135 per-screen + shell polish "for free" once landed.

</code_context>

<specifics>
## Specific Ideas

- Owner wants the **decisive "don't make me think" path** (the Phase 128/129/130 pattern): every
  decision grounded in our own artifacts — the UI-SPEC's Implementation Checklist + the live
  `app.css`/`ops_ui.ex` — not external ecosystem research. A CSS/token phase has no external research
  surface; all three gray areas locked to the recommendation in one pass.
- The UI-SPEC is treated as **the locked contract**; this discussion's only job was disambiguating
  "allowed sites" (where the vocabulary may be used) vs "wired-up sites" (what 131 actually applies) —
  resolved at D-01 in favor of system-now / per-screen-badges-to-134.
- **Light pixel-identical is non-negotiable** on this `[G]` gate (inherited from Phase 130 D-06): every
  new layer is dark-scoped; the recommended card's light shadow is left byte-unchanged.

</specifics>

<deferred>
## Deferred Ideas

- **Per-screen copper-badge/node application** — Search federation badge, Playbook file-type badge,
  Control-Room intent-card icon node → **Phase 134** (SCREEN-DARK-01, per-screen polish). The vocabulary
  ships in 131; the per-screen `.heex` wiring does not.
- **Copper-glow consuming hover rule** (the rule that uses `--shadow-ops-glow-copper` on key-node /
  key-callout hover) → **Phase 133/134**. The token is declared in 131; nothing consumes it yet.
- **`.ops-text-meta` / header-nav / muted-text AA re-tuning** → **Phase 132** (A11Y-TOKEN-01). Cluster 3
  of the contrast harness stays deferred there, not gated in 131.
- **Full 40-shot re-capture + before/after gallery** → **Phase 136** (DUALVERIFY-01). 131 proves itself
  via the contrast clusters + light pixel-diff, not a full matrix.

These are the downstream phases this vocabulary feeds — not scope creep into 131.

</deferred>

---

*Phase: 131-glow-dark-shadow-and-copper-accent-system-r-g*
*Context gathered: 2026-06-04*
