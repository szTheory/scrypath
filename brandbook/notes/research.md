# Scrypath Brand Book — Research Brief

Cited research for the scrypath visual identity, design-token, accessibility, and packaging systems. Every
non-obvious claim carries a source URL verified via live web research (June 2026). Scope: a calm, technical
"wayfinding through data" brand — violet + copper over warm-neutral, set in Space Grotesk / Inter / IBM Plex Mono.

---

## 1. Distinctive OSS devtool / Elixir-ecosystem brand & logo systems

- **Fly.io ships a full lockup *system*, not a single mark** — a "color landscape" logo (custom brandmark + serif wordmark) as the preferred form, plus monochrome-portrait and brandmark-alone variants reserved for "extremely small dimensions," all codified on a public brand page with explicit do/don't rules. The *serif* wordmark is itself a differentiator in a sea of geometric-sans devtools. Source: https://fly.io/docs/about/brand/
  - **Lesson:** Ship a small *family* (integrated wordmark + standalone glyph for ≤24px/favicon) on a public brand page with plain do/don't rules — not one orphan logo.

- **Vercel proves a pure symbol can carry a devtool brand** — the ▲ is a real Unicode character (U+25B2), "should only be used where there is not enough room to display the full logo," with clear-space defined by the symbol's own height; it works at 16px and inverts cleanly. Source: https://vercel.com/geist/brands
  - **Lesson:** Define the standalone glyph's clear-space by its *own* height and reserve it strictly for cramped/favicon contexts; the integrated wordmark is the default.

- **Astro deliberately rejected the generic-devtool look** — "not looking like every other devtool" was an explicit goal: dark-mode site, unusual palette, original illustration, a display face plus a distinct code face, and a mascot. Source: https://astro.build/blog/welcome-world/
  - **Lesson:** Treat the calm/"wayfinding" angle and the violet+copper + Plex Mono code voice as a *deliberate* anti-generic stance — that's the credibility signal, not decoration.

- **Tailwind distributes identity as modular, separable assets** — "Mark" (icon) and "Logotype" (wordmark) shipped separately in dark/light SVG, behind trademark rules. Source: https://tailwindcss.com/brand
  - **Lesson:** Even an integrated wordmark should ship as separable, theme-aware SVGs (light/dark, full/glyph).

- **The premium developer-brand tier is wordmark-led** — Linear (Inter), Vercel (Geist), Stripe (Söhne) anchor on one typeface family plus mono, used with systemic scale/weight/spacing — "company names set in carefully chosen typefaces rather than separate symbols." Source: https://mantlr.com/blog/stripe-linear-vercel-premium-ui
  - **Lesson:** The Space Grotesk / Inter / IBM Plex Mono trio *is* the brand spine; disciplined scale and tracking read as credible more than adding an icon.

- **Oban and Supabase show the data-infra packaging norm** — Oban distributes all logo variants as one downloadable SVG+PNG package on a dedicated brand-assets page; Supabase pairs a lightning logomark with developer-first type and a strict "never modify" trademark stance, in light/dark SVGs. Sources: https://oban.pro/brand-assets , https://supabase.com/brand-assets
  - **Lesson:** Package assets as a single download with light/dark variants and a one-line "don't modify / don't imply endorsement" clause.

*(Phoenix bird-mark + wordmark lockup reference: https://www.phoenixframework.org/ .)*

---

## 2. Integrated typemark / custom wordmark craft

- **The FedEx arrow is the canonical integrated lettermark** — Lindon Leader (1994) blended Univers 67 + Futura Bold and tightened tracking until the "E"/"x" gap formed a white arrow; the motif was "discovered, not invented," left subtle, and has won 40+ awards. Sources: https://www.logohistories.com/p/fedex-logo-design-1994-landor-lindon-leader , https://www.designermurat.com/post/the-fedex-logo-a-masterclass-in-simplicity-and-hidden-genius
  - **Lesson:** The strongest integration is quiet — a "path/wayfinding" arrow hidden in a letter gap rewards the second look without shouting. Don't over-signal it.

- **A successful embedded motif must *complete* a letterform, not decorate it** — SHARP (knife between R–P), SLOW (snail in L–O), EXPLODE (mushroom cloud in O–D), each exploiting existing gaps in a bold sans so the imagery feels essential to reading the word. Source: https://digitalsynopsis.com/design/negative-space-logos-with-meanings/
  - **Lesson:** Start from Space Grotesk's natural counters/gaps and find where a path/index/search motif can *be* a letter, rather than appending an icon.

- **Standard workflow: set the name in a bold sans, then hunt negative space** with Pen/Shape Builder, keeping the inserted element subtle enough to "complement, not distract from, the text." Source: https://digitalsynopsis.com/design/negative-space-logos-with-meanings/
  - **Lesson:** Prototype by manipulating actual Space Grotesk outlines (extend a stroke, reshape one counter) rather than fusing a separately designed icon.

- **Integrated combination marks are memorable *and* more defensible** — incorporating a symbol within the logotype is "an unusual and delightful surprise," generally easier to trademark than a bare pictorial mark, while still maximizing name recognition. Source: https://www.freelogodesign.org/blog/2023/11/07/what-s-the-best-option-a-combination-mark-logo-or-wordmark-logo
  - **Lesson:** Baking the motif *into* the wordmark gets name-recognition (people must read "scrypath") and a distinctive, defensible mark in one move.

- **Favicon scale is where integrated wordmarks break** — at 16–32px most full logos are illegible; "one or two characters are most readable," low-contrast elements vanish, guidance is ≤3 colors. Source: https://www.letteringworks.com/blog/faviconfix
  - **Lesson:** Design the favicon as a standalone single-letter/monogram glyph from a 512px master at full violet+copper contrast — never the shrunken wordmark.

- **Plausible's 2023 refresh is a direct precedent** — committed to a purple letter "P" and explicitly set out to "combine the letter with some symbolism related to the product," iterating four concepts publicly. Sources: https://dribbble.com/shots/23723226-Plausible-Branding , https://x.com/PlausibleHQ/status/1759861128396411218
  - **Lesson:** A single anchor letter ("s"/"p") fused with a product motif (a search path / index line) is a proven, ownable pattern — and sharing 3–4 concepts publicly builds community buy-in.

---

## 3. Logo usage-system standards

- **Clear space is a *derived unit of the logo itself*** (a cap-height or letterform), kept free of type, imagery, patterns, and surface edges — e.g. Johns Hopkins Medicine sets it to the height of the capital "H." Source: https://brand.hopkinsmedicine.org/brand/branding-guidelines/logo-guidelines/clear-space-and-minimum-size
  - **Lesson:** Define clear space as a multiple of the "s" glyph (or full mark height) so it scales at any size.

- **Every logo needs a published minimum size** in px (digital) and mm/in (print). Source: same as above.
  - **Lesson:** Publish a dual minimum (full lockup ~120px/24mm; glyph ~16px) and ship the glyph-only mark below the wordmark floor.

- **Misuse rules are a finite, enumerable "don't" list** — no stretch/squash/skew, no rotate/flip, no recolor or transparency changes, no low-contrast/busy backgrounds, no cropping, no font substitution; rendered as labeled ✗. Source: https://www.logotouse.com/post/brand-logo-guidelines-designers-should-know
  - **Lesson:** Render a misuse grid of ✗ thumbnails — designers scan, not read.

- **Mono and reversed/inverse variants are required.** Source: https://www.solid-run.com/brand-guidelines/
  - **Lesson:** Ship full-color, mono-black, mono-white/reversed, and 1-color copper so the mark survives dark-mode UI, single-color print, and merch.

- **Favicons in 2025 are a small fixed file set** — multi-res `favicon.ico` (16/32/48), 32×32 PNG, 180×180 `apple-touch-icon`, 192×192 and 512×512 PNGs, with SVG as the resolution-independent primary. Sources: https://favicon.im/blog/complete-favicon-size-format-guide-2025 , https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs
  - **Lesson:** Generate the glyph-only mark as SVG + ico + 180/192/512 PNGs.

- **OpenGraph does NOT mandate 1200×630** — `ogp.me` defines `og:image` (required) plus optional width/height/alt; 1200×630 (1.91:1) is the FB/LinkedIn convention, X uses 1200×675. The spec advises `og:image:alt` whenever you set `og:image`. Sources: https://ogp.me/ , https://www.krumzi.com/blog/open-graph-image-sizes-for-social-media-the-complete-2026-guide
  - **Lesson:** Ship one 1200×630 social card and always emit `og:image:width/height/alt`.

- **HexDocs (ex_doc) has a narrow logo contract** — project logo must be PNG/JPEG in docs assets, rendered at **64×64 px**; richer branding via `before_closing_head_tag`/`before_closing_body_tag`. GitHub READMEs have no enforced size — convention is a centered top `<img>` (~200–400px) with a `prefers-color-scheme` `<picture>` swap. Sources: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html , https://hexdocs.pm/ex_doc/readme.html
  - **Lesson:** Provide a purpose-built 64×64 glyph for the HexDocs `logo:` field and a `<picture>` light/dark README pair.

---

## 4. Design tokens

- **DTCG Design Tokens Format reached its first stable version (2025.10)** — JSON-based, media type `application/design-tokens+json`, `.tokens`/`.tokens.json` extensions; every token requires `$value` + optional `$type`/`$description`/`$extensions`/`$deprecated`; reserved props are `$`-prefixed; aliases use `{group.token}`. Sources: https://www.designtokens.org/tr/drafts/format/ , https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/
  - **Lesson:** Author tokens in DTCG `.tokens.json`, then compile to CSS custom properties.

- **Best practice is a three-tier architecture** — primitive/"reference" (raw, never used directly) → semantic/functional (meaning) → component (element-scoped). Material 3 distills to ~141 system tokens. Source: https://m3.material.io/foundations/design-tokens/overview
  - **Lesson:** `--scry-violet-500` (primitive) → `--scry-color-accent`/`--scry-surface-2` (semantic) → `--scry-button-bg` (component); forbid components referencing primitives directly.

- **GitHub Primer makes tiering concrete** — base (raw, never direct), functional (text/border/bg/shadow, mode-aware), few component tokens. Sources: https://github.com/primer/primitives/blob/main/DESIGN_TOKENS_GUIDE.md , https://primer.style/product/primitives/token-names/
  - **Lesson:** Prefer functional tokens in product code — making the v1.34 dark surface-ramp fix a token-remap, not a per-component rewrite.

- **Light/dark theming = semantic remapping, not logic changes** (M3 pattern; CSS `light-dark()`). Sources: https://m3.material.io/foundations/design-tokens/overview , https://muz.li/blog/dark-mode-design-systems-a-complete-guide-to-patterns-tokens-and-hierarchy/
  - **Lesson:** One set of semantic names, two value maps — this is exactly how the `#1B2230` surface-2 ramp gap gets fixed.

- **Salesforce SLDS 2 shows tokens as namespaced "styling hooks"** — `--[namespace]-g-[category]-[property]-[role]-[state]-[range]`. Sources: https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/styling_hooks.htm
  - **Lesson:** Namespace every token (`--scry-`/existing `--ops-`) so tokens are collision-proof when embedded in a host app (the ops/ecommerce embedding case).

---

## 5. WCAG 2.1 / 2.2 contrast & focus (exact, W3C-cited)

- **AA text contrast — 4.5:1 normal, 3:1 large (SC 1.4.3, AA).** Large = ≥18pt / ≥14pt bold (~24px / ~18.66px bold). Source: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum
- **Non-text / UI contrast — 3:1 (SC 1.4.11, AA, new in 2.1).** UI components, states, meaningful graphics ≥3:1; disabled exempt. Source: https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html
  - **Lesson:** Copper used as button fills, focus rings, input outlines, and icons must hit 3:1 against its surface.
- **AAA text contrast — 7:1 normal, 4.5:1 large (SC 1.4.6, AAA).** Source: https://www.w3.org/WAI/WCAG21/Understanding/contrast-enhanced.html
- **Focus Visible = AA (2.4.7); Focus Not Obscured (Minimum) = AA (2.4.11, new in 2.2); Focus Appearance = AAA (2.4.13, new in 2.2).** Sources: https://www.w3.org/TR/WCAG22/ , https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html

> **Correction to the inflated prompt's framing:** 2.4.13 Focus Appearance is **AAA**, not AA. The AA focus criteria are **2.4.7 Focus Visible** and **2.4.11 Focus Not Obscured (Minimum)**. (Verified against https://www.w3.org/TR/WCAG22/.) The brand book's a11y section uses this corrected numbering.

---

## 6. OSS README / HexDocs / Hex package presentation

- **`mix hex.publish` ships package + docs together; ExDoc runs via `mix docs`.** Sources: https://hex.pm/docs/publish , https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html
- **ExDoc supports a docs logo, source/homepage URLs, theming under `:docs`** — `docs: [logo: "path/to/logo.png", ...]` + custom CSS. Source: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
  - **Lesson:** Set `docs: [logo: "priv/logo.png"]` (the 64×64 glyph) and carry violet+copper into docs via ExDoc custom CSS.
- **High-trust Elixir READMEs lead with logo + a shields badge row** (Oban: logotype then Hex Version, Hex Docs, CI, License). Sources: https://github.com/oban-bg/oban , https://hex.pm/packages/oban
- **Req / Bandit / Tesla confirm install-then-quickstart above the fold**, README doubling as the HexDocs landing page (`extras: ["README.md"]`). Sources: https://hexdocs.pm/req/readme.html , https://hexdocs.pm/bandit/readme.html
  - **Lesson:** One README that doubles as the HexDocs front page; `[Hex version][Hex docs][CI][License]` shields via `img.shields.io/hexpm/v/scrypath`.

---

## 7. Self-contained webfont embedding (subsetting, @font-face, OFL)

- **`pyftsubset` (fontTools CLI) is the canonical subsetter and emits WOFF2 directly** — `--flavor=woff2` (needs Brotli), `--unicodes=`, `--layout-features=`. Source: https://fonttools.readthedocs.io/en/latest/subset/
- **`glyphhanger` automates unicode-range discovery and wraps fonttools.** Sources: https://github.com/zachleat/glyphhanger
  - **Lesson:** Use whitelist/string mode to subset to the brand book's known glyph set (Latin + the few arrows/symbols) — tiny and deterministic.
- **`font-display`** — `swap` (text never invisible), `fallback`, `optional` (best CLS). Source: https://developer.mozilla.org/en-US/docs/Web/CSS/@font-face/font-display
  - **Lesson:** `swap` for Inter/Space Grotesk; `optional` acceptable for IBM Plex Mono code blocks.
- **WOFF2 is royalty-free, ~97% support.** Source: https://caniuse.com/woff2 — ship WOFF2 only.
- **OFL permits self-hosting and subsetting, but subsetting IS "modification" and strips the Reserved Font Name** (OFL-FAQ Q2.6). Source: https://openfontlicense.org/ofl-faq/
  - **Lesson:** Self-hosting subset WOFF2s is allowed — name internal `@font-face`/files generically (e.g. `Inter Subset`) and don't redistribute under the bare RFN; bundle each `OFL.txt`.
- **All three faces are confirmed SIL OFL 1.1.** Inter: https://github.com/rsms/inter/blob/master/LICENSE.txt ; Space Grotesk: https://github.com/floriankarsten/space-grotesk ; IBM Plex: https://github.com/IBM/plex/blob/master/LICENSE.txt
  - **Lesson:** Vendor each `OFL.txt` next to the WOFF2s and list all three (with copyright lines) in the fonts folder.

---

## Top 10 lessons for the scrypath brand book

1. **Ship a family, not a logo.** Integrated wordmark (default) + standalone glyph for ≤24px/favicon, in light/dark mono + reversed, packaged with do/don't rules.
2. **Bake the "path/wayfinding" motif *into* a letterform**, FedEx-style, by reshaping actual Space Grotesk outlines — quiet, discoverable, defensible (Plausible precedent).
3. **Design the favicon as a separate single-letter glyph** at full contrast — never a shrunk wordmark.
4. **Define clear space as a glyph-derived unit**; publish dual minimum sizes; render misuse as a ✗ grid.
5. **Author tokens in DTCG `.tokens.json`** (stable 2025.10) → compile to namespaced CSS custom properties.
6. **Three-tier token model** (primitive → semantic → component); components never touch primitives → dark mode is a value remap.
7. **WCAG AA is a hard gate, AAA a documented flex:** 4.5:1 body / 3:1 large+UI; a thick high-contrast copper/violet focus ring can claim AAA 2.4.13; mind 2.4.11 on sticky UI. (2.4.13 is AAA, not AA.)
8. **Make hexdocs.pm a first-class brand surface:** 64×64 glyph in `docs: [logo:]`, ExDoc custom CSS.
9. **One README that doubles as the HexDocs landing page** — header logo, auto-updating shields, install + 5-line quickstart above the fold.
10. **Self-host subset WOFF2-only fonts** (`pyftsubset`/glyphhanger, `font-display: swap`); all three faces SIL OFL 1.1 — bundle each `OFL.txt`.
