# Phase 131: Glow, dark shadow, and copper accent system - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 3 (1 CSS, 1 Elixir 1-line, 1 markdown doc)
**Analogs found:** 3 / 3 (every change site has an in-repo precedent)

> This is a **CSS + design-token-only** phase. There are no "new files" — all work is
> additive edits to three existing files. Each edit site below is paired with a verbatim
> in-repo precedent the planner/executor must replicate. **All line numbers are the
> RESEARCH.md-verified live values** (the UI-SPEC/CONTEXT numbers have drifted — do not use
> those). Re-grep before editing if `app.css` changes between now and execution.

---

## File Classification

| File | Role | Data Flow | Closest Analog (precedent) | Match Quality |
|------|------|-----------|----------------------------|---------------|
| `scrypath_ops/assets/css/app.css` — token declarations (`--shadow-ops-panel-dark`, `--shadow-ops-glow`, `--shadow-ops-glow-copper`) | config (design tokens) | transform (static cascade) | **Precedent A** — D-10 token-redefinition block, `app.css:1298–1313` | exact |
| `scrypath_ops/assets/css/app.css` — dark-scoped *application* rules (panel-dark on 4 panels; `.ops-glow` on route-mark + active nav; recommended-card 3-layer compose) | config (component CSS) | transform (static cascade) | **Precedent B** — dark-scoped rule block, `select.ops-form-control` `app.css:531–539` + `.ops-data-card`/`.ops-result-row` `app.css:1279–1295` | exact |
| `scrypath_ops/assets/css/app.css` — `@theme` light defaults (`--shadow-ops-glow: none`, `--shadow-ops-glow-copper: none`) | config (design tokens) | transform | existing `--shadow-ops-*` ladder in `@theme`, `app.css:141–148` | exact |
| `scrypath_ops/assets/css/app.css` — new `@layer components` classes (`.ops-glow`, `.ops-copper-eyebrow`, `.ops-copper-badge`, `.ops-copper-node[--fill]`) | component (CSS) | transform | `.ops-badge` definition `app.css:418–433` (copper-badge composes with it) | role-match |
| `scrypath_ops/assets/css/app.css` — `.ops-shell` wash mobile tune (`max-width: 640px`) | config (component CSS) | transform | base `.ops-shell` radial, `app.css:240–244` + existing `@media (max-width: 640px)` at `app.css:1015` | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — eyebrow re-style (L23) | component (HEEx slot) | request-response (render) | the slot itself, `ops_ui.ex:20–35` (swap utilities → class) | exact |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` — +2 sections | documentation | n/a | existing `## Shadow` section, `DESIGN-TOKENS.md:87–93` | role-match |

---

## Pattern Assignments

### 1. Token declarations — `--shadow-ops-panel-dark`, dark `--shadow-ops-glow`, `--shadow-ops-glow-copper`

**File:** `scrypath_ops/assets/css/app.css`
**Role:** config / design tokens · **Data flow:** transform (cascade)
**Analog (Precedent A):** `app.css:1298–1313` — the D-10 token-redefinition block at end-of-file, OUTSIDE any `@layer`.

**Why these tokens use Precedent A, not the `@plugin` blocks:** `--shadow-ops-*` are `@theme`
custom tokens, **not** daisyUI semantic keys, so they cannot ride the `@plugin` dark/light
pass-through. They must be **hand-authored in BOTH** dark paths.

**Exact precedent to replicate** (`app.css:1298–1313`, verbatim from live file):
```css
/* D-10: --shadow-ops-* are @theme tokens, not daisyUI keys — must hand-author both dark paths.
   Same offsets/blur as light; color/alpha only. Cascades to all 14 shadow consumers. */
[data-theme="dark"] {
  --shadow-ops-surface: 0 1px 2px rgba(0,0,0,0.40);
  --shadow-ops-mid:     0 1px 4px rgba(0,0,0,0.45);
  --shadow-ops-raised:  0 2px 10px rgba(0,0,0,0.50);
  --shadow-ops-overlay: 0 8px 24px rgba(0,0,0,0.55);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) {
    --shadow-ops-surface: 0 1px 2px rgba(0,0,0,0.40);
    --shadow-ops-mid:     0 1px 4px rgba(0,0,0,0.45);
    --shadow-ops-raised:  0 2px 10px rgba(0,0,0,0.50);
    --shadow-ops-overlay: 0 8px 24px rgba(0,0,0,0.55);
  }
}
```

**Apply this pattern by:** appending three new lines into BOTH the `[data-theme="dark"]` block
(after `app.css:1304`) AND the `@media html:not([data-theme="light"])` block (after `app.css:1311`)
— identical in both:
```css
  --shadow-ops-panel-dark: 0 0 0 1px rgba(0,0,0,0.30), 0 1px 3px rgba(0,0,0,0.45);
  --shadow-ops-glow:        0 0 8px 2px rgba(108,92,231,0.30);
  --shadow-ops-glow-copper: 0 0 6px 1px rgba(193,122,62,0.25);
```
Keeps the whole `--shadow-ops-*` ladder in one cascade site. **Do NOT create a new block.**

---

### 2. `@theme` light defaults — `--shadow-ops-glow: none`, `--shadow-ops-glow-copper: none`

**File:** `scrypath_ops/assets/css/app.css`
**Role:** config / design tokens · **Data flow:** transform
**Analog:** the existing `--shadow-ops-*` ladder inside `@theme`, `app.css:141–148`.

**Exact precedent** (`app.css:141–148`, verbatim):
```css
  --shadow-ops-surface: 0 1px 2px color-mix(in oklch, var(--color-base-content) 8%, transparent);
  --shadow-ops-mid: 0 1px 4px color-mix(in oklch, var(--color-base-content) 9%, transparent);
  --shadow-ops-raised: 0 2px 10px color-mix(in oklch, var(--color-base-content) 10%, transparent);
  --shadow-ops-overlay: 0 8px 24px color-mix(in oklch, var(--color-base-content) 12%, transparent);
  ...
  --shadow-ops-focus: 0 0 0 3px color-mix(in oklch, var(--color-primary) 30%, transparent);
```

**Apply this pattern by:** adding two light-default lines into the `@theme` block alongside this
ladder:
```css
  --shadow-ops-glow: none;          /* light no-op — Precedent A overrides in dark */
  --shadow-ops-glow-copper: none;   /* light no-op */
```
**CRITICAL:** `--shadow-ops-panel-dark` gets **NO** `@theme` light default. It must be
**undeclared in light** — that undeclared-ness is the pixel-identity mechanism (Light-Theme
Invariants table). Declaring it `none` in light would be harmless but the spec mandates dark-only
declaration; keep it strictly out of `@theme`.

---

### 3. Panel-dark application (4 panels) + glow application (route-mark, active nav) + recommended-card 3-layer compose

**File:** `scrypath_ops/assets/css/app.css`
**Role:** config / component CSS · **Data flow:** transform (cascade)
**Analog (Precedent B):** `select.ops-form-control` at `app.css:531–539`, plus the Phase-130
`.ops-data-card`/`.ops-result-row` blocks at `app.css:1279–1295`.

**Exact precedent — single-rule shape** (`app.css:531–539`, verbatim):
```css
  [data-theme="dark"] select.ops-form-control {
    background-image: url("data:image/svg+xml,...stroke='%23a6adba'...");
  }

  @media (prefers-color-scheme: dark) {
    html:not([data-theme="light"]) select.ops-form-control {
      background-image: url("data:image/svg+xml,...stroke='%23a6adba'...");
    }
  }
```

**Exact precedent — grouped/back-to-back shape** (`app.css:1279–1295`, verbatim):
```css
/* D-05: .ops-data-card keeps light base-100 fill; dark-only surface-2 lift */
[data-theme="dark"] .ops-data-card {
  background: var(--ops-surface-2);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-data-card {
    background: var(--ops-surface-2);
  }
}
```

**CRITICAL — compose, never replace (RESEARCH F7).** Four of the target selectors already carry
a `box-shadow`. A dark override that sets `box-shadow: var(--shadow-ops-glow)` (or panel-dark
alone) **erases** the existing layer. Every dark override must list existing layer(s) first, then
the new one. Verified current values from the live file:

| Selector | Live line | Current `box-shadow` (verbatim) | Compose target (dark) |
|----------|-----------|----------------------------------|------------------------|
| `.ops-panel` | `app.css:250` | `var(--shadow-ops-surface)` | swap to `var(--shadow-ops-panel-dark)` (seated-depth swap; it otherwise inherits dark surface via Precedent A) |
| `.ops-intent-card` | `app.css:851` | `var(--shadow-ops-surface)` | `var(--shadow-ops-panel-dark)` (or compose `surface, panel-dark` per Discretion) |
| `#flash-group > *` | `app.css:1012` | `var(--shadow-ops-overlay)` | `var(--shadow-ops-overlay), var(--shadow-ops-panel-dark)` — **keep overlay** |
| `.ops-cmdk__panel` | `app.css:1067` | `var(--shadow-ops-overlay)` | `var(--shadow-ops-overlay), var(--shadow-ops-panel-dark)` — **keep overlay** |
| `.ops-route-mark` | `app.css:996` | `0 0 0 1px color-mix(... primary-content 30% ...) inset` | `<inset ring>, var(--shadow-ops-glow)` — **keep inset ring** |
| `.ops-nav-item-active` | `app.css:588` | `var(--shadow-ops-surface)` | `var(--shadow-ops-surface), var(--shadow-ops-glow)` — **keep surface lift** |

**Recommended-card 3-layer compose** (`.ops-intent-card--recommended`):
- **Light is byte-unchanged** (D-02a). Current value verbatim at `app.css:866–870`:
  ```css
  .ops-intent-card--recommended {
    box-shadow:
      var(--shadow-ops-surface),
      inset 0 0 0 1px color-mix(in oklch, var(--color-primary) 45%, transparent);
  }
  ```
- **Dark override** (D-02) goes in BOTH Precedent-B paths, painted ring→seat→glow:
  ```css
  .ops-intent-card--recommended {
    box-shadow:
      inset 0 0 0 1px color-mix(in oklch, var(--color-primary) 45%, transparent),  /* ring — on top */
      var(--shadow-ops-panel-dark),   /* ambient seat */
      var(--shadow-ops-glow);          /* violet aura — outermost / behind */
  }
  ```

**Discretion (RESEARCH Open Q2):** the four panel-dark targets split into two natural groups by
base layer — `.ops-panel` + `.ops-intent-card` (surface base) vs `#flash-group > *` + `.ops-cmdk__panel`
(overlay base). Recommend **two grouped Precedent-B blocks** (one per base layer) rather than one
shared list, since the composed `box-shadow` values differ. Route-mark / active-nav / recommended-card
are separate blocks again (each composes onto a distinct existing shadow).

---

### 4. New `@layer components` classes — `.ops-glow`, `.ops-copper-*`

**File:** `scrypath_ops/assets/css/app.css`
**Role:** component (CSS) · **Data flow:** transform
**Analog:** `.ops-badge` definition at `app.css:418–433` (the copper badge **composes with**
`.ops-badge`, inheriting its layout).

**Exact `.ops-badge` shape to compose against** (`app.css:418–433`, verbatim):
```css
  .ops-badge {
    display: inline-flex;
    min-height: 1.625rem;
    align-items: center;
    border: 1px solid color-mix(in oklch, var(--color-base-content) 12%, transparent);
    border-radius: 999px;
    padding-inline: 0.625rem;
    font-size: 0.75rem;
    line-height: 1rem;
    font-weight: 650;
    white-space: nowrap;
    transition:
      background-color var(--duration-ops-fast) var(--ease-ops-standard),
      border-color var(--duration-ops-fast) var(--ease-ops-standard),
      color var(--duration-ops-fast) var(--ease-ops-standard);
  }
```
`.ops-copper-badge` overrides only `border-color` / `background` / `color`; layout comes from
`.ops-badge` (usage: `class="ops-badge ops-copper-badge"`).

**Classes to author in `@layer components`** (color refs that intentionally **bypass** the
contrast harness — RESEARCH F8: the checker only scans base-content alpha mixes, so these raw
token refs are NOT auto-evaluated; the AA table is a static design assertion):
```css
.ops-glow {
  box-shadow: var(--shadow-ops-glow);
  transition: box-shadow var(--duration-ops-fast) var(--ease-ops-standard);
}
.ops-copper-eyebrow {
  font-size: var(--text-ops-sm);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--color-secondary);            /* AA dark 5.13:1 / light 4.84:1 on surface-1 (spec-verified) */
}
.ops-copper-badge {                          /* compose with .ops-badge for layout */
  border-color: color-mix(in oklch, var(--color-secondary) 44%, transparent);
  background:   color-mix(in oklch, var(--color-secondary) 12%, transparent);
  color: var(--color-base-content);          /* AA dark 12.07:1 / light 14.86:1 (spec-verified) */
}
.ops-copper-node       { color: var(--color-secondary); }
.ops-copper-node--fill { color: var(--color-secondary-content); background: var(--color-secondary); }
```
These are theme-agnostic (use `var(--color-*)` which already flip per theme via the `@plugin`
blocks) → **no D-10 dual-path needed** for the class bodies themselves. Only the `--shadow-ops-glow`
*token value* they reference is dark-pathed (item 1). `.ops-copper-node` / `--fill` /
`.ops-copper-badge` are **declared but not wired** in 131 (D-01a → Phase 134).

---

### 5. `.ops-shell` wash mobile tune

**File:** `scrypath_ops/assets/css/app.css`
**Role:** config / component CSS · **Data flow:** transform
**Analog:** base `.ops-shell` at `app.css:240–244` + the existing `@media (max-width: 640px)` block
that already opens at `app.css:1015`.

**Exact base value to tune** (`app.css:240–244`, verbatim):
```css
  .ops-shell {
    background:
      radial-gradient(circle at top left, color-mix(in oklch, var(--color-primary) 14%, transparent), transparent 34rem),
      linear-gradient(180deg, var(--color-base-200), var(--color-base-100));
  }
```

**Apply by:** adding (or extending the existing) `@media (max-width: 640px)` rule — `14% → 10%`
alpha, `34rem → 28rem` extent:
```css
@media (max-width: 640px) {
  .ops-shell {
    background:
      radial-gradient(circle at top left, color-mix(in oklch, var(--color-primary) 10%, transparent), transparent 28rem),
      linear-gradient(180deg, var(--color-base-200), var(--color-base-100));
  }
}
```
This is the one **both-theme** change (not dark-scoped). Light shell wash is barely perceptible at
either alpha, so light-pixel-diff risk is minimal — but it IS a light input change, so re-run the
0/20 gate (and confirm the Jun-3 baseline is still canonical — RESEARCH A1).

---

### 6. Eyebrow re-style (the lone in-situ copper application)

**File:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
**Role:** component (HEEx slot) · **Data flow:** request-response (server render)
**Analog:** the slot itself, `ops_ui.ex:20–35` — a one-line utility-class swap, not new markup.

**Exact current slot** (`ops_ui.ex:22–25`, verbatim):
```elixir
    <div class="space-y-1">
      <p class="text-ops-sm font-semibold uppercase tracking-wide text-secondary">
        Operator workspace
      </p>
```

**Apply by:** replacing the four utility classes on the `<p>` at **L23** with the single
`ops-copper-eyebrow` class. String "Operator workspace" unchanged. Path uses `scrypath_ops_web`
(verified). One edit → propagates to all 6 screens. This is COPPER-01's in-situ proof.

---

### 7. DESIGN-TOKENS.md lockstep — +2 sections

**File:** `scrypath_ops/assets/css/DESIGN-TOKENS.md`
**Role:** documentation · **Data flow:** n/a
**Analog:** the existing `## Shadow — --shadow-ops-* → shadow-ops-*` section at
`DESIGN-TOKENS.md:87–93` (prose + ladder description); section headers follow the file's
`## Token — usage` convention (see `DESIGN-TOKENS.md:43, 87, 110`).

**Exact precedent section** (`DESIGN-TOKENS.md:87–93`, verbatim):
```markdown
## Shadow — `--shadow-ops-*` → `shadow-ops-*`

Elevation ladder: `surface` (1px, resting) → `mid` (subtle hover / interactive state) →
`raised` (10px, the element lifts off the page) → `overlay` (24px, modals/flash). Use
`mid` for hover/selected feedback, `raised` only for a genuine lift (intent-card hover).
`focus` is **reserved** ...
```

**Apply by:** adding two sections (wording is Discretion; mirror this format — header + prose +
table):
- `## Glow + dark ambient depth — Phase 131` — the 3-row token table from UI-SPEC Lockstep
  Obligations (`--shadow-ops-panel-dark` dark-only, `--shadow-ops-glow` none→violet,
  `--shadow-ops-glow-copper` none→copper) + the note that `--shadow-ops-panel-dark` is a dark-only
  augmentation and light keeps `--shadow-ops-surface` vertical lift.
- `## Copper accent vocabulary — Phase 131` — allowed-use rules for `.ops-copper-eyebrow` /
  `.ops-copper-badge` / `.ops-copper-node[--fill]` + the AA pairing table + "never a status tone /
  not in `tone_class/1`" rule.

---

## Shared Patterns

### D-10 dual-path dark override (THE central cross-cutting pattern)
**Source:** Precedent A `app.css:1298–1313` (token redefinition, outside layers) and
Precedent B `app.css:531–539` / `app.css:1279–1295` (dark-scoped rule inside `@layer components`).
**Apply to:** EVERY dark-only token or rule in this phase (items 1, 3, and the dark recommended-card).
Always author **both** `[data-theme="dark"] <selector>` AND
`@media (prefers-color-scheme: dark) { html:not([data-theme="light"]) <selector> }`. Forgetting one
breaks either explicit-toggle dark or system dark (RESEARCH Pitfall 3). Use Precedent A for token
values, Precedent B for rule application.

### Light non-modification = pixel-identity proof
**Source:** Phase 130 D-04/D-06 (inherited gate).
**Apply to:** all of item 3 and the recommended card. Never edit a base `.ops-*` definition to add a
new dark shadow; always override via a dark-scoped Precedent-B block. `--shadow-ops-panel-dark` is
NEVER declared in light. The `.ops-shell` mobile tune (item 5) is the sole intentional light input
change and must clear `light-pixel-diff` 0/20.

### Compose, don't replace (box-shadow stacking)
**Source:** RESEARCH F7; verified current shadows on `.ops-route-mark` (`:996`),
`#flash-group > *` (`:1012`), `.ops-cmdk__panel` (`:1067`), `.ops-nav-item-active` (`:588`).
**Apply to:** all six already-shadowed targets in item 3. List existing layer(s) first, new layer last.

### Copper is a brand accent, never a status tone
**Source:** CONTEXT D-01a / RESEARCH project constraints.
**Apply to:** all `.ops-copper-*` classes (item 4). They do NOT join `tone_class/1` / `badge_class/1`;
no semantic meaning. Badge text is always `var(--color-base-content)` (AA-verified); eyebrow text is
`var(--color-secondary)` (AA-safe only as eyebrow on surface-1).

### Verification substrate (no new tooling — Phase 130 D-11 bundle re-run)
**Source:** RESEARCH Validation Architecture; `mix.exs:87` (`verify.opsui`).
**Apply to:** the phase gate. `mix verify.opsui` (exit 0) + `node contrast-checker.mjs` (3 AA light,
unchanged) + `npm run test:e2e:admin-contrast` (**Cluster 1 = 0**; Cluster 3 deferred to 132) +
`node e2e/light-pixel-diff.mjs` (**0 / 20**, after `mix assets.build` + re-shoot). **Copper AA is NOT
machine-checked (F8)** — the 9-pairing table is a static design assertion.

---

## No Analog Found

None. Every change site has an exact or close in-repo precedent. This phase deliberately introduces
**zero novel patterns** — it extends the existing `--shadow-ops-*` ladder, the D-10 dual-path
override, the `.ops-badge` composition, and the eyebrow slot. (One nuance: copper-vocabulary classes
have no semantic-tone analog because copper is intentionally *not* a tone — `.ops-badge` is the
correct layout-only analog, which is exactly why copper-badge composes with it.)

---

## Metadata

**Analog search scope:** `scrypath_ops/assets/css/app.css` (1313 lines), `scrypath_ops/assets/css/DESIGN-TOKENS.md`, `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`.
**Files scanned:** 3 (all targeted-read against RESEARCH-verified line ranges; no whole-file loads of the 1313-line CSS).
**Line numbers:** RESEARCH.md-verified live values (UI-SPEC/CONTEXT numbers had drifted; all re-confirmed this session against the live file).
**Pattern extraction date:** 2026-06-04
