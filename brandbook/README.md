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
    tokens.json                  the same tokens as data
    daisyui-theme.example.js     copy-paste mirror of the live scrypath_ops daisyUI theme
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

Dark mode: set `<html data-theme="dark">` (or rely on `prefers-color-scheme`). The palette mirrors the
live `scrypath_ops` theme, so `tokens/daisyui-theme.example.js` drops straight into the product.

## The logo, in one line

The wordmark **is** the logo: pristine Familjen Grotesk letters + a weight-matched **copper `/`** path-separator.
No cage, no box. Don't recolour the slash, stretch the mark, or add a tagline to the primary lockup.
Full do/don't in `index.html`.

## Licence & credits

- **Type** — Familjen Grotesk, Inter, IBM Plex Mono, all **SIL Open Font License 1.1**
  (`assets/fonts/OFL-*.txt`). Subset woff2 are redistributed under the OFL.
- **Palette & tokens** mirror the live `scrypath_ops` design system.
- Brand assets © the scrypath project.
