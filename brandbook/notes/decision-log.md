# Scrypath Brand — Decision Log

Decision-matrix records for the v1.35 brand milestone. Each entry: options, pros/cons, ecosystem lessons,
implications, and an explicit **ship / reject / defer + confidence**. Logo *direction* is intentionally left
to the owner (Phase 138 checkpoint) — this log fixes everything around it.

---

## D1 — Keep vs. refine the color palette

**Decision:** Keep all hues; refine only token tiering.
**Options:** (A) keep palette as-is · (B) keep hues + formalize primary/primary-strong/on-accent/focus tokens · (C) re-hue to differentiate from Elixir purple.

| | Pros | Cons |
|---|---|---|
| A keep as-is | zero thrash | leaves the documented violet-on-white AA near-miss implicit |
| **B keep + formalize** | zero hue thrash; closes the AA gap explicitly; gives buildout `on-accent`/`focus-ring` tokens | small token-doc work |
| C re-hue | could distance from Elixir | huge thrash: re-opens the AA gate, repaints the live ops UI + website, throws away implemented work |

**Ecosystem lesson:** copper + warm-paper is the real differentiator (no devtool owns it); violet's "Elixir-ness" is offset by the *pairing*, not by changing the hue. Three-tier tokens (Primer/M3) make text-vs-accent a naming rule, not a guess.
**Implications:** the live `contrast-pairs.mjs` gate already encodes `--color-primary-strong` `#5B4AD1`; we're documenting reality, not inventing.
**→ SHIP B. Confidence: High.**

## D2 — Keep vs. refine typography

**Decision:** Keep the three families; craft a custom wordmark instead of using raw Space Grotesk.
**Options:** (A) keep families, wordmark = raw Space Grotesk · (B) keep families, wordmark = custom-tuned outlines with the path motif worked in · (C) swap Space Grotesk for a less-trendy display face.

| | Pros | Cons |
|---|---|---|
| A raw font wordmark | trivial | "logo is just type in a Google font"; dates with the font; not what the owner asked |
| **B custom wordmark** | unified mark+type; defensible/ownable; future-proof against the font's trend cycle; satisfies the integrated-typemark ask | more design effort (this milestone's point) |
| C swap display face | dodges trend risk | thrash in live UI; loses a good, distinctive face for a speculative gain |

**Ecosystem lesson:** premium dev brands (Linear/Vercel/Stripe) are wordmark-led; the strongest integrations reshape real letterforms (FedEx, Plausible), they don't bolt on an icon.
**→ SHIP B. Confidence: High.**

## D3 — Logo architecture

**Decision:** Replace the caged abstract-S with a **route/waypoint** system; provide a unified wordmark + a standalone glyph; show the owner 3–5 concrete directions and let them pick. **Reject** the rectangular cage and the abstract-S monogram outright.
**Why this frame (not the pick itself):**
- The mark must (a) signify **path** (the safe, non-mystical half of the name), (b) be able to *become* a letterform for the integrated typemark, (c) reduce to one high-contrast glyph at 16px.
- Transparent by default; background tiles are previews only.
- Primary lockup carries **no subtitle**; a tagline lockup is a separate optional file; mark sits *close* to the wordmark.

**Ecosystem lesson:** ship a *family* (Fly/Tailwind/Oban), design the favicon as a separate glyph (≤2 chars, ≤3 colors, high contrast), share concepts publicly to build buy-in (Plausible).
**→ SHIP the framework; owner picks the direction at the Phase 138 checkpoint. Confidence: High (framework); owner-dependent (pick).**

## D4 — Token expression / format

**Decision:** Ship all three — DTCG `tokens.json` (interop) + `tokens.css` (CSS custom properties) + `daisyui-theme.example.js` (copy-paste adoption mirroring `scrypath_ops`).
**Options:** (A) CSS vars only · (B) daisyUI theme only · (C) DTCG JSON + CSS + daisyUI example.

| | Pros | Cons |
|---|---|---|
| A CSS only | simplest | not tool-portable; doesn't match how ops adopts (daisyUI) |
| B daisyUI only | matches live adoption | not portable to non-Tailwind consumers (website, future docs) |
| **C all three** | interop (DTCG stable 2025.10) + direct CSS use + 1:1 ops adoption path | minor duplication, single-sourced from the JSON |

**Ecosystem lesson:** DTCG reached first stable version 2025.10; three-tier primitive→semantic→component keeps dark mode a value remap.
**→ SHIP C. Confidence: High.**

## D5 — Fonts: embedding strategy

**Decision:** Self-host **subset woff2** for all three families with `@font-face` + bundled `OFL.txt`.
**Options:** (A) CDN · (B) system fallback only · (C) subset woff2 checked in.

| | Pros | Cons |
|---|---|---|
| A CDN | zero repo weight | not self-contained offline; third-party dependency/privacy |
| B system only | zero weight | book doesn't show the real brand type — defeats the purpose |
| **C subset woff2** | self-contained offline, full fidelity, small with subsetting | adds a controlled, small binary footprint |

**Ecosystem lesson:** all three faces are SIL OFL 1.1 (subset+self-host allowed; subsetting strips the Reserved Font Name → name subset files generically, bundle `OFL.txt`); woff2-only is ~97% supported; `font-display: swap`.
**→ SHIP C (owner-confirmed). Confidence: High.**

## D6 — Adoption scope

**Decision:** Build the `brandbook/` package **and** adopt the chosen identity across `scrypath_ops` (logo+favicon), `website/` (brand-mark + OG), and the root README — keeping the `contrast-pairs.mjs` AA gate green.
**Rejected alternative:** artifacts-only (defer rollout) — owner chose build+adopt for "really nail it."
**Implication:** Phase 142 is gated on the AA contrast harness staying green; any token refinement (D1) lands in the live daisyUI theme under that gate.
**→ SHIP. Confidence: High.**

## D7 — Sequencing vs. the in-flight v1.34 milestone

**Decision:** Open v1.35 now at phase 137; **pause** v1.34 at phase 133 (5/9 complete); v1.34 resumes after v1.35 ships.
**Rejected:** finish v1.34 first (delays the owner-prioritized brand work); fold brand into v1.34 (muddies the dark-mode milestone theme).
**Implication:** any v1.35 brand-token refinement feeds forward into v1.34's remaining dark-polish phases (133–135), so doing brand first is also *less* total rework.
**→ SHIP. Confidence: High.**

---

## Deferred (explicitly not this milestone)

- **Full favicon raster set (ico/180/192/512 PNGs)** — ship `favicon.svg` now; generate the raster set during adoption only if a target surface needs it (avoid premature binary bloat). *Defer to Phase 142, conditional.*
- **HexDocs ExDoc theming (custom CSS, 64×64 `docs: [logo:]`)** — the brand book outputs the 64×64 glyph; wiring it into `mix.exs` `:docs` is a small follow-on. *Defer (note in next-steps).*
- **Animated/motion logo** — the static system first; any line-draw animation rides on v1.34's DARKMOTION-01 work. *Defer.*
