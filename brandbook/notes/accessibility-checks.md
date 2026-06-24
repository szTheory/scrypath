# Accessibility checks — scrypath brand book (v1.35)

Contrast measured per **WCAG 2.1**, relative-luminance ratios, **sRGB compositing** (matches axe-core
and the product's `contrast-pairs.mjs` gate). Thresholds: **AA text 4.5:1**, **AA large/non-text 3.0:1**.

## Color-pair results

| Pair | Ratio | Floor | Verdict |
|------|------:|-------|---------|
| Ink `#141923` on Canvas `#FAF7F2` (body, light) | 16.47:1 | 4.5 | ✅ AAA |
| Muted `#475066` on Canvas (light) | 7.54:1 | 4.5 | ✅ AAA |
| Violet-600 `#5B4AD1` on Canvas (link/primary, light) | 5.87:1 | 4.5 | ✅ AA |
| Copper-600 `#A85D2E` on Canvas (accent **text**, light) | 4.60:1 | 4.5 | ✅ AA |
| Copper-500 `#C17A3E` slash on Canvas (**non-text** graphic) | 3.21:1 | 3.0 | ✅ AA |
| Paper `#F4F1EA` on Violet-600 (button label, light) | 5.57:1 | 4.5 | ✅ AA |
| Paper `#F4F1EA` on Night `#0C0F14` (body, dark) | 17.02:1 | 4.5 | ✅ AAA |
| Mist `#B3BDCF` muted on Night (dark) | 10.14:1 | 4.5 | ✅ AAA |
| Copper-500 `#C17A3E` on Night (accent text, dark) | 5.59:1 | 4.5 | ✅ AA |
| Paper on Ink surface `#141923` (dark) | 15.60:1 | 4.5 | ✅ AAA |
| Violet-500 `#6C5CE7` on Night (dark) | 3.95:1 | 3.0 (non-text/large) | ⚠️ see note |

## Notes & rules that follow from the numbers

1. **Copper as text uses Copper-600 `#A85D2E` on light** (4.60:1), never Copper-500 (which is ~3.2:1 — below
   AA text). Copper-500 is reserved for **graphics** (the logo slash, focal nodes, borders) where the 3.0
   non-text floor applies, and for **text on dark** (5.59:1, fine).
2. **Violet-500 `#6C5CE7` on dark is AA-large / non-text only (3.95:1).** Do **not** set body-size links in raw
   Violet-500 on Night. On dark, primary actions are **buttons** (Paper label on a violet fill) and links use
   Paper + underline or the brighter primary. This matches the live ops theme, where `--color-primary` on dark
   is used as a fill, not as small body text.
3. **Muted text** is the product's tracked risk: `--ops-text-muted` = a 64% mix of `base-content`. At that alpha
   it still clears AA in both themes; every such usage is registered in `scrypath_ops/.../contrast-pairs.mjs`
   (the D-15 lockstep gate). This brand work changes **no color tokens**, so that gate stays green.
4. **Focus**: a single global `:focus-visible` ring — `2px var(--sp-focus)` (`#6C5CE7`) at `2px` offset — visible
   on every interactive element in both themes (demonstrated on the brand-book buttons/input). No per-element
   removal of outlines.
5. **States**: alerts/badges never rely on color alone — they carry text and a shape/border cue (left-border on
   alerts, outline on badges) so they read without color perception.
6. **Non-color**: wordmark legible to ≥18px and the favicon tuned for 16px; the logo carries an `aria-label` when
   embedded as inline SVG; decorative separators are `aria-hidden`.

_Re-run the numbers any time with the snippet in the milestone log; product enforcement lives in
`scrypath_ops` via `contrast-pairs.mjs`._
