# Phase 137 — Brand pressure-test & research `[R]`

**Milestone:** v1.35 Brand System & Logo Identity
**Requirement:** BRAND-AUDIT-01
**Status:** In progress

## Goal

Audit `prompts/scrypath-brand-book.md` against a full expert-lens decision-point sweep and produce the
research + decision foundation the rest of v1.35 builds on. No product changes.

## Background snapshot (from milestone intake)

- **scrypath** = OSS Elixir/Phoenix library for Ecto-native search indexing (Hex `scrypath`, v0.3.10).
  Brand posture: calm, exact, technical, "wayfinding through data"; never gimmicky.
- **Existing brand book** (`prompts/scrypath-brand-book.md`) is strategically complete: locked voice;
  palette = violet `#5B4AD1`/`#6C5CE7` + copper `#C17A3E`/`#A85D2E` over warm neutrals (`#FAF7F2`/`#0C0F14`
  ramps) + semantics; type = Space Grotesk (display) / Inter (body) / IBM Plex Mono (code); 8px spacing;
  radius 12/16/24; motion `cubic-bezier(0.2,0.8,0.2,1)` 120/180/240ms; "path-S monogram" logo concept;
  detailed iconography/imagery do/don't.
- **Palette + type are already implemented live** in `scrypath_ops` (Tailwind v4 + daisyUI, two themes) per
  `scrypath_ops/assets/css/DESIGN-TOKENS.md`, guarded by `scrypath_ops/assets/css/contrast-pairs.mjs`
  (AA hard gate, both themes green as of Phase 132). Changing core palette/type = product thrash.
- **Existing logos are the problem:** `scrypath_ops/priv/static/images/logo.svg` and
  `website/src/assets/brand-mark.svg` are a path-S mark inside a `<rect rx="12">` dark cage — the exact
  rectangular-background look the owner dislikes. Replace, don't reuse.

## Deliverables (this phase)

- `brandbook/notes/pressure-test.md` — scored audit + dark-spots/footguns across the decision points.
- `brandbook/notes/research.md` — cited current references (spawned to a research subagent).
- `brandbook/notes/decision-log.md` — decision-matrix (ship/reject/defer + confidence) for keep-vs-refine
  palette, keep-vs-refine type, logo architecture, token expression.

## Constraints carried forward

No rectangular cage · unified mark+logotype · no subtitle on primary · ≥1 integrated typemark · show
options/owner picks · self-contained `brandbook/` · subset woff2 · svgo all SVG · keep the AA gate green ·
bias-to-keep palette/type · Phase 97 runtime scope guard still holds.
