# Scrypath Logo — Options & Selection Record

Phase 138 (LOGO-DIRECTIONS-01). Records the directions explored and the owner's selection. Two iterations.

## Iteration 1 — four directions (record: `logo-options.html`, marks in `logo-options/`)

| Dir | Concept | Verdict |
|-----|---------|---------|
| A · Waypoint | routed connection stepping between copper start + violet destination nodes | viable; most literal "wayfinding"; **kept as a fallback** |
| B · Integrated typemark | route worked into the wordmark (y-descender → route node) | **fed forward** → became the iteration-2 direction |
| C · Fan-out | source node routing to two indexed waypoints (maps to `fan_outs`/federation) | strong standalone icon; **kept as alternate avatar/app-icon** |
| D · Routed S | a single flowing route tracing an "s" between two waypoints | **fed forward** → became the leading "s" of the typemark |

**Owner feedback after iter-1:** (1) drop the display font — **Space Grotesk is reserved for the sibling lib _Sigra_** (auth); pick a totally new face. (2) **Focus on integrated typemarks.** (3) **Work the routed-S into** some integrated-typemark options, ensuring it works with the new face.

## Iteration 2 — integrated typemark (record: `logo-typemarks.html`)

**Direction (locked by the pivot):** an **integrated typemark** where the **routed-S becomes the leading "s" of the wordmark** — the mark *is* the first letter, so mark + word are one object and the routed-S still stands alone as the favicon/avatar/app-icon. Inter (UI) + IBM Plex Mono (code) stay as workhorses; only the **display/wordmark face** changes.

**Two open choices for the owner:**

- **Choice 1 — display face (all OFL, none is Space Grotesk):**
  - **Sora** — geometric, technical, calm. *(designer's lean)*
  - **Schibsted Grotesk** — warmer, more character.
  - **Familjen Grotesk** — narrower, most distinctive.
- **Choice 2 — integration treatment (shown in Sora):**
  - **T1** — routed-S lead, clean.
  - **T2** — routed-S lead + copper "y" (copper threads through the word). *(designer's lean)*
  - **T3** — routed-S lead + continuing route (a copper route exits the word to a violet waypoint) — great for hero/marketing lockups.

**Designer's lean:** **Sora + T2**, with the standalone routed-S as the favicon/avatar and **T3** reserved for hero lockups. The routed-S, copper-"y", and copper exit-node make the word read as designed-as-a-unit while staying reserved.

## Iteration 3 — geometric rebuild (record: `logo-options-v3.html`)

**Owner feedback after iter-2:** the freehand routed-S typemark "looks absolutely horrible" — step back, do new directions with **great vector graphics + graphic-design fundamentals**.

**Root cause:** the iter-2 S was a freehand bézier with ball-nodes, authored blind → crude, and clashed against the clean typeface (weight/style mismatch). **Fix: construct every mark from exact geometry** (true circles, real tangent arcs, one consistent stroke weight, restrained small nodes) and self-critique each render before presenting.

Five geometric directions, each as a transparent mark + paper/night/mono + 16px + a wordmark lockup:

| Dir | Concept | Notes |
|-----|---------|-------|
| **N4 · Routed S** | two-arc geometric S + small violet/copper waypoint terminals | **designer's lean** — folds the name (S) + the route/waypoint idea into one clean mark |
| N3 · Geo-S (pure) | the same S, no nodes | most minimal/timeless |
| N1 · Route | rounded-corner path between copper origin + violet destination | most literal "wayfinding" |
| N5 · Waypoint | rounded marker-diamond with a copper center node | strongest standalone app-icon |
| N2 · Fan-out (1→3) | one source → three indexed destinations | maps to `fan_outs`/federation; busiest |

The geometric S is clean and elegant — it redeems the "routed-S" concept the owner found interesting but saw executed badly. Display face (Sora / Schibsted / Familjen) is an independent, easily-swapped choice; lockups shown in Sora.

## Iteration 4 — routed-S × wordmark integrations (record: `logo-integrations.html`)

Owner: likes the geometric routed-S **and only that**; wants it **integrated with the type** in a natural,
great-looking way — "lots of new looks." Method: weight-match the S to the type, true baseline alignment,
tuned spacing; render + self-critique each. Eight looks + 3 faces + favicon row:

1. **‘s’ is the mark — x-height, weight-matched** — subtlest; scrypath simply has a custom geometric ‘s’.
2. **solid weight-matched ‘s’** — the S reads as a true solid letter *(lean: primary)*.
3. **x-height ‘s’ + copper waypoint** — the route idea kept tiny.
4. **cap ‘s’ + copper route under the word → waypoint** — the "path" threads beneath the word *(lean: hero/marketing)*.
5. **‘y’ drops a copper waypoint** — copper at start (S) + mid-word.
6. **monoline lockup** — outline type + monoline S; wireframe/path feel.
7. **light type + cap monoline S** — deliberate weight contrast.
8. **stacked lockup** — mark over wordmark; for square avatars *(plus the standalone routed-S as the mark/favicon)*.
Then the lean look across **Sora / Schibsted / Familjen**, and the standalone glyph at 64/32/16px.

**Designer's lean:** primary wordmark = **#2 (solid weight-matched ‘s’)** in **Sora**; mark/favicon = the
**standalone routed-S + copper waypoint**; **#4** reserved for hero. Copper = the single warm accent.

## Selection — CONFIRMED (2026-06-23)

- **Primary wordmark:** look **#2** — the geometric **routed-S as a solid, weight-matched first letter** of `scrypath` (violet S + ink "crypath"; inverse = violet S + paper "crypath").
- **Display face:** **Familjen Grotesk** (SemiBold ~600). Narrower than Sora → routed-S tuned to match: **stroke ≈ 13, width ×0.88, x-height, round caps** on the 48-unit grid.
- **Standalone mark / favicon / avatar:** the **routed-S + copper waypoint** (violet stroke, copper lower terminal node).
- **Hero / marketing lockup:** look **#4** — the routed-S + a copper route threading under the word to a waypoint (separate, optional).
- **Color logic:** copper is the single warm accent (the mark's waypoint, the hero route). Inter + IBM Plex Mono stay for UI/code.

**Phase 139 build method:** the wordmark is **outlined to vector paths via fontTools** (Familjen instanced at wght 600) so the logo SVGs are font-independent and portable (README, HexDocs, anywhere); the routed-S is the tuned geometric vector. Build pipeline saved at `/tmp/scry-fam/compose_all.py` (re-runnable; fetches Familjen `[wght]` TTF from google/fonts, instances to 600, outlines via `SVGPathPen`+`TransformPen`).

## Phase 139 — DELIVERED (`brandbook/assets/`)

Full family shipped, transparent, no cage, **svgo-optimized (22.7 KB total)**, all XML-valid, verified on light+dark+16px:

| File | What | Size |
|------|------|------|
| `logo-primary.svg` | horizontal lockup, violet routed-S + ink "crypath" (no tagline) | 1.7 KB |
| `logo-primary-inverse.svg` | violet (#6C5CE7) S + paper wordmark, for dark bg | 1.7 KB |
| `logo-mark.svg` | standalone routed-S + copper waypoint (the icon) | 239 B |
| `logo-mark-mono.svg` | single-colour (currentColor) mark | 249 B |
| `favicon.svg` | heavier mark tuned for ≤32px | 239 B |
| `logo-stacked.svg` | mark over plain "scrypath" — avatar/vertical | 2.1 KB |
| `logo-with-tagline.svg` | primary + "Ecto-native search indexing" (optional/separate) | 7.9 KB |
| `logo-hero.svg` | look #4 — copper route threading under the word to a waypoint | 1.8 KB |
| `social-card.svg` | 1200×630 night OG card | 6.9 KB |

Outstanding for Phase 139 → folded into the brand book (Phase 141): written clear-space, minimum-size, one-colour, and misuse rules.

---

## ⚠️ Iteration 5 — routed-S KILLED; fresh tournament (2026-06-24)

The routed-S above (loop **and** angular forms) was **rejected by the owner** — every "a letter becomes a route" mark read as smudged/forced. **Do not revive any S-path.** A fresh tournament (`logo-tournament-fresh.html`) was run on a new principle: **keep the Familjen wordmark pristine and fully legible**, and carry the brand idea in **one exact, weight-matched additive accent + the violet/copper colour logic** (no letter surgery). Survivors: A two-tone split · B copper node seam · C copper `/` separator · D index throughline · I tracked split · J chevron lead · F y-descender route. (Culled weak: underline-tab, `a`-counter aperture, federation-nodes.)

## ✅ Selection — CONFIRMED (2026-06-24) — supersedes all above

- **Primary wordmark = direction C — the copper `/` path-separator:** `scry` + a weight-matched **copper `#C17A3E` `/`** + `path`, in **Familjen Grotesk SemiBold (~600)**, outlined to vector paths. The wordmark stays pristine; the slash *is* the logo idea — a literal path separator, instantly legible, developer-native, zero "smudge" risk. Owner: *"i love this one … let's go all in on this direction."*
- **Colour logic:** ink `#141923` letters + copper `/` on light; paper `#F4F1EA` letters + copper `/` on dark. **Copper is the single signature accent** (the slash). Violet `#5B4AD1` is carried by the **mark**, not the wordmark, so both brand colours live in the system and the copper slash is the through-line shared by word + mark.
- **Mark / favicon / avatar:** an **`s/p` monogram** — violet `s` + copper `/` + ink `p` (the wordmark compressed to its initials around the signature slash). Favicon uses the heavier weight for ≤16px legibility.
- **Display face:** **Familjen Grotesk** (SemiBold ~600; Bold 700 for the small favicon). Unchanged — not Space Grotesk (reserved for sibling lib *Sigra*).
- **Build method:** unchanged — fontTools outlines the wordmark to font-independent SVG paths; the `/` is the font's own glyph, recoloured. Pipeline at `/tmp/scry-fam/build139.py`.
