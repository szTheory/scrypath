# Scrypath Brand — Pressure Test

A critical audit of `prompts/scrypath-brand-book.md` and the live implemented brand, through nine expert
lenses. Each finding is scored **Keep / Refine / Fix** with severity. The headline: *the strategy and system
are strong; the logo is the one genuinely weak artifact, and the name carries a latent tension worth steering.*

Severity key: 🟥 blocker · 🟧 structural · 🟨 polish · 🟩 strength (keep).

---

## 1. Brand strategy & positioning — mostly strength

- 🟩 **Category and anti-positioning are crisp.** "Ecto-native search indexing," explicitly *not* an AI/vector/SaaS product. This is the hardest thing to get right and it's done. Keep verbatim.
- 🟩 **"Wayfinding through data" is an ownable metaphor** in the Elixir space — no incumbent owns it. It also gives the visual system a non-clichéd engine (routes, waypoints, nodes) that dodges the banned magnifying-glass/database-cylinder tropes.
- 🟧 **Latent name tension: "scry" = divination.** The name's first syllable connotes crystal-ball/mysticism — which the brand *explicitly forbids* in imagery ("no fortune tellers, crystal balls, spellbooks"). The brand book even flags the naming-collision risk. **Steer:** let the identity lean almost entirely on **"path"** (wayfinding, route, index trail), treating "scry" as "to see clearly / discern," not divination. The logo motif should be a *route/waypoint*, never an eye or orb. This turns a liability into the core idea.
- 🟨 **Brand promise is one sentence but slightly abstract** ("declarative search, observable sync, dependable results"). Fine for a values doc; the HTML book should pair it with a concrete 5-line code+sync example so the promise is *shown*.

## 2. Distinctiveness & category fit — strength with one risk

- 🟩 **Warm-paper light neutral (`#FAF7F2`) instead of cold white** is a real, uncommon differentiator vs. the blue-white devtool norm. Keep.
- 🟩 **Copper (`#C17A3E`) is the true differentiator.** Almost no devtool uses an earthy copper accent; the field is cyan/blue/teal/green (Supabase green, Prisma teal, Phoenix orange). Copper + warm paper is the ownable combination. Lean *harder* on copper as the brand's fingerprint.
- 🟧 **Violet risks reading as "just Elixir."** Elixir's own brand is purple; Fly.io is purple-ish. Scrypath violet (`#6C5CE7`) alone could look derivative. **Mitigation (not a palette change):** the *pairing* with copper + the route-motif identity is what separates it — don't drop violet, but make copper carry equal visual weight in brand moments (the 65/20/10/5 ratio already allows this; the logo should use copper as a co-lead, not a minor accent).

## 3. Logo system — the one real weakness 🟥

- 🟥 **Rectangular cage.** Both `scrypath_ops/.../logo.svg` and `website/src/assets/brand-mark.svg` wrap the mark in `<rect rx="12" fill="#0C0F14">`. This is the AI-default the owner explicitly rejects, forces a dark tile onto every surface, and breaks on light backgrounds. **Replace.**
- 🟥 **Abstract-S monogram reads as "two curves and three dots."** It doesn't legibly signify a path, an S, or anything; it's generic. The "S for Scrypath" rationale is invisible to a viewer.
- 🟧 **No logotype integration.** There is a mark concept but no wordmark, no lockup, no integrated typemark. The owner specifically wants a *unified* mark+type and at least one fully-worked-in type treatment.
- 🟧 **Fails the favicon test.** Two thin strokes + three small dots turn to mud at 16–32px. Research confirms ≤2 chars / ≤3 colors / high contrast is the favicon rule — the current mark violates all three.
- ✅ **Direction:** a **route/waypoint** system — nodes joined by a deliberate routed line — that (a) literally draws "path," (b) can *become* a letterform for the integrated typemark, and (c) reduces to a single high-contrast glyph for the favicon. This is Phase 138's job; the owner picks among concrete options.

## 4. Color — strength; one formalization to ship

- 🟩 Palette, semantics, light/dark ramps, and the 65/20/10/5 ratio are well-specified and already implemented + AA-gated in `scrypath_ops`. Keep the hues.
- 🟧 **Formalize primary vs. primary-strong.** The live work already found plain violet `#6C5CE7` text/fills land ~4.3:1 on white (AA near-miss) and introduced `--color-primary-strong` (`#5B4AD1`) for text-bearing fills (Phases 128/132). The brand book doesn't document this two-tier rule. **Refine:** the token package must encode "violet `#6C5CE7` = accent/large/non-text; violet `#5B4AD1` = text-bearing/small," plus explicit `on-accent` text and `focus-ring` tokens. This is a documentation/token fix, not a hue change.

## 5. Typography — strength; one craft opportunity

- 🟩 Space Grotesk (display) / Inter (body) / IBM Plex Mono (code) is a current, distinctive, license-clean trio. IBM Plex Mono dodges the ubiquitous JetBrains/Fira mono. Keep.
- 🟨 **Space Grotesk is slightly trendy** (peaked 2021–24) and could date. Mitigation: use it only for display + the *wordmark*, and make the wordmark a **custom-tuned** treatment (reshaped outlines), not raw Google-font type — that's the integrated-typemark opportunity and it future-proofs the mark against the font's trend cycle.

## 6. Layout, tokens & motion — strength

- 🟩 Spacing (8px base), radius (12/16/24), motion (`cubic-bezier(0.2,0.8,0.2,1)`, 120/180/240ms) are specified and implemented. The brand book should *mirror* the live `DESIGN-TOKENS.md`, not reinvent. No change.

## 7. Components, voice & microcopy — gaps to fill in the book

- 🟧 **No concrete microcopy examples.** Voice *principles* are strong but the book has no good/bad copy pairs and no error-message pattern (what happened / why / how to fix). Fill in Phase 141.
- 🟧 **No component-state coverage as artifacts.** Hover/focus/active/disabled/loading/empty/error/skeleton exist in the live ops UI but aren't shown in the brand book. The HTML book must render them in both themes so the book is *useful for buildout*, not just vibes.

## 8. OSS / Elixir DX — gaps to fill

- 🟧 **The brand book ignores the OSS surface system.** No spec for README header, HexDocs 64×64 logo, shields badge row, OG/social card, favicon set. Research gives the exact contracts (ExDoc 64×64 PNG, `<picture>` README swap, 1200×630 OG). The logo system (Phase 139) must output these explicitly, and adoption (Phase 142) must wire them.

## 9. Repo hygiene / red-team

- 🟩 Current assets are small SVGs — good. 🟧 **The only real bloat risk is fonts** → mitigated by subset woff2 (Phase 140).
- 🟥 **Biggest red-team risk = thrash.** The palette/type are *live and AA-gated*; gratuitous change ripples into the ops UI and re-opens the contrast gate. **Discipline:** bias-to-keep; refine only the two documented items (primary/primary-strong tiering; custom wordmark). Everything else is additive (logo family, book, tokens package, fonts).
- 🟨 Secondary risks: violet-as-Elixir (mitigated by copper co-lead + route identity); Space Grotesk dating (mitigated by custom wordmark); "scry"=mysticism (mitigated by path-only motif).

---

## Verdict

| Area | Verdict |
|------|---------|
| Brand strategy, positioning, voice principles | **Keep** |
| Palette hues, type families, spacing/radius/motion | **Keep** |
| Primary vs primary-strong + on-accent + focus-ring tokens | **Refine** (document/encode; no hue change) |
| Custom-tuned wordmark vs raw Space Grotesk | **Refine** (craft the wordmark) |
| Logo mark + cage + lockup + integrated typemark | **Fix / replace** (Phase 138 options → owner picks) |
| Microcopy examples, component states, OSS surface system | **Fill** (additive, Phases 139–142) |

The creative budget goes to the **logo** and the **HTML book**; the palette/type stay put. This maximizes
fidelity while minimizing product thrash — exactly the owner's "don't cause thrash for no reason" constraint.
