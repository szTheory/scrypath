# scrypath — brand book

The self-contained brand system for **scrypath**, an Ecto-native search-indexing library for Elixir & Phoenix.
Everything here is plain files — **no build step**. Open `index.html` in any browser (works from `file://`),
offline, with the brand fonts, tokens, and logo travelling with it.

## Preview

```
open brandbook/index.html            # the brand book (logo · color · type · tokens · components · voice)
open brandbook/examples/components.html
open brandbook/examples/landing-page-section.html
```

Use the **◐ theme** toggle (top-right) to switch light/dark; it also follows your OS preference by default.

## What's inside

```
brandbook/
  index.html                     the brand book
  README.md                      this file
  assets/
    logo-primary.svg             scry/path — ink letters + copper "/" (canonical)
    logo-primary-inverse.svg     for dark backgrounds
    logo-primary-violet.svg      violet-forward alternate
    logo-wordmark-mono.svg       one-colour (currentColor)
    logo-mark.svg / -inverse / -mono   the s/p monogram (favicon/avatar)
    favicon.svg                  s/p tuned for 16px
    logo-stacked.svg / -inverse  mark over wordmark
    logo-with-tagline.svg        + "Ecto-native search indexing" (separate/optional)
    social-card.svg              1200×630 OpenGraph card
    fonts/                       subset woff2 (Familjen Grotesk, Inter, IBM Plex Mono) + OFL licences + fonts.css
  tokens/
    tokens.css                   CSS custom properties (--sp-*), light + dark
    tokens.json                  typed DTCG brand palette plus the separate Ops theme mirror
    daisyui-theme.example.js     copyable example of the live ScrypathOps daisyUI theme
  examples/
    components.html              component reference (both themes)
    landing-page-section.html    marketing hero built from the brand
    readme-header-example.md     drop-in README header with the logo
  notes/
    research.md  pressure-test.md  decision-log.md   phase-137 audit + rationale
    logo-options.md                logo direction record (the slash, direction "C")
    accessibility-checks.md        WCAG AA contrast results + rules
    logo-final-c.html              proof sheet for the shipped logo family
```

## Using the tokens

```css
@import "tokens/tokens.css";
@import "assets/fonts/fonts.css";

.cta { background: var(--sp-primary); color: var(--sp-on-primary);
       font-family: var(--sp-font-display); border-radius: var(--sp-radius-input); }
```

Dark mode: set `<html data-theme="dark">` (or rely on `prefers-color-scheme`). The warm `--sp-*`
brand palette is separate from the live ScrypathOps interface theme; changing one does not change the
other.

## Token export and verification

`tokens/tokens.css` is the presentation source for this warm brand palette. `tokens/tokens.json` is
its typed DTCG 2025.10 export and also carries a separate `ops.light` / `ops.dark` project mirror.
Those `ops` groups are a Scrypath convention, not a standardized DTCG mode resolver.

The live Ops values are owned by
[`scrypath_ops/assets/css/app.css`](../scrypath_ops/assets/css/app.css). Each custom property is
mapped in the JSON under the `org.scrypath` extension with its CSS property name and exact source
expression. The bounded repository check supports color, dimension, number, font family and weight,
duration, cubic Bézier, and standard shadow values. It checks the complete theme property sets,
typed values, color component and hex agreement, and the muted text color's 64% alpha and base-content
reference. The CSS `none` value remains an exact string in `shadow.glow`’s namespaced
`org.scrypath.css_literals.light` extension metadata; it is not a DTCG token type.
The reader caps each input at 2 MiB, JSON nesting at 64, tokens at 4096, and alias chains at 32.
It reads only active top-level theme blocks, excluding comments and quoted examples.

Run `mix verify.repository_contracts` from the repository root to validate the export and detect
independent CSS or JSON drift. This source contract does not validate rendered UI output. The
[`daisyui-theme.example.js`](tokens/daisyui-theme.example.js) keeps a copyable JavaScript shape for
host configuration; `app.css` remains the Ops source of truth.

## The logo, in one line

The wordmark **is** the logo: pristine Familjen Grotesk letters + a weight-matched **copper `/`** path-separator.
No cage, no box. Don't recolour the slash, stretch the mark, or add a tagline to the primary lockup.
Full do/don't in `index.html`.

## Licence & credits

- **Type** — Familjen Grotesk, Inter, IBM Plex Mono, all **SIL Open Font License 1.1**
  (`assets/fonts/OFL-*.txt`). Subset woff2 are redistributed under the OFL.
- **Palette & tokens** include the separate warm brand palette and typed Ops mirror; live Ops CSS is authoritative for Ops values.
- Brand assets © the scrypath project.
