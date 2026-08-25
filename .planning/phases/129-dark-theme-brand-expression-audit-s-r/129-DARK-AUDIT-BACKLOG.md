---
generated: 2026-06-04
phase: 129
inputs:
  - .planning/phases/128-contrast-gate-harness-dark-seed-coverage-s-g/128-CONTRAST-REPORT.md
  - .tmp/admin-screenshots/ (40 shots — 6 screens × light/dark × mobile 390/desktop 1440 × seed scenarios)
  - prompts/scrypath-brand-book.md
method: >
  6 dark-specific DD dimensions (DD1–DD6), 0–3 scale per dimension (0 = worst).
  DD6 AA pass/fail promoted directly from 128-CONTRAST-REPORT.md — not re-derived.
  DD1–DD5 brand-expression gaps scored from the 20-shot dark matrix overlaid against
  prompts/scrypath-brand-book.md dark-signature rules (4-step midnight ramp, 65/20/10/5
  ratio, quiet glow, ambient-shadow-plus-border depth, path-line glow restraint).
  Severity: DD6 fail → blocker (D-07); DD1–DD5 by blast-radius: ≥3 screens → structural;
  single screen → polish. Sort: blocker→structural→polish, systemic first, score 0 worst.
---

# Phase 129 — Dark-Theme Brand-Expression Audit Backlog (DARKAUDIT-01)

**Status:** FINDING #1 ANCHORED — `#1B2230` surface-2 ramp gap (DK-01) confirmed as
finding #1 by construction (systemic AA blocker + DD1 ramp violation + DD4 depth absence,
all 6 screens).

> Raw audit substrates: `.tmp/admin-screenshots/` (gitignored), `128-CONTRAST-REPORT.md`
> (committed baseline), `prompts/scrypath-brand-book.md`. This file is the committed,
> diffable evidence — the single input for phases 130–135.

---

## Executive summary

**Total findings: 19** — by severity: **blocker 4**, **structural 6**, **polish 9**.

By fix-class: **token 10**, **component 3**, **screen 4**, **motion 1**, **seed 1**.

**Systemic promotion count:** 7 findings promoted to systemic (≥3 screens), routing to
phases 130–132. The three 128-CONTRAST-REPORT.md clusters (`.leading-4` 1.08:1, dark form
inputs 1.19:1, `pre` code block 1.3:1) are fully absorbed into the backlog as DD6/blocker
rows. The four additional systemic promotions are brand-expression gaps (DD1 ramp flatness,
DD4 depth absence, DD2 copper absence, DD2 neutral-ratio dominance).

**Finding #1 summary:** DK-01 — the `#1B2230` surface-2 ramp gap — is simultaneously the
`.leading-4` 1.08:1 systemic AA blocker (128-report cluster 1), a DD1 ramp adherence
failure (raised surfaces collapse to Night `#0c0f14` instead of lifting to surface-2
`#1B2230`), and a DD4 depth failure (ambient shadow cannot create depth when surface bg =
page bg). A single dark surface-2 token introduction resolves all 3 dimensions across all
6 screens. This is the single most impactful fix in the milestone.

**Plan-hypothesis verification:** All 6 brand-book dark-signature rules inspected. Four
confirmed as gaps (DD1 ramp, DD2 copper absence, DD4 depth, DD6 AA). DD3 glow and DD5
path-line glow: no violations found (shell wash is restrained; no path diagram elements
exist on these screens). Two brand-book rules are satisfied — both confirm "do not fix."

---

## Ranked consolidated backlog

> Score = the audited dimension's 0–3 rating (0 worst). DD = dark-brand dimension. SYS = promoted systemic.

### Blockers (any DD6 = AA fail, per D-07)

| ID | Alt | Touchpoint | Dim | Score | Sev | Scope | Evidence | Proposed fix | Fix-class | Phase | Req |
|----|-----|-----------|-----|-------|-----|-------|----------|--------------|-----------|-------|-----|
| DK-01 SYS | element | All screens, raised/muted surfaces — `.leading-4` text on collapsed surface-2 | DD1+DD4+DD6 | 0 | blocker | systemic | `00-control-room--dark--desktop--incident`, `02-failed-sync--dark--desktop--populated`, `06-search--dark--desktop--results`, `09-playbooks--dark--desktop--empty-workspace`; app.css:28-29 (dark base-100=#141923, base-200=#0c0f14 — surface-2 #1B2230 absent); 128-report cluster 1 (`.leading-4` fg `#1f2933` bg `#1d222c` 1.08:1, systemic, screens: failed-sync, search, playbooks) | Introduce the missing `#1B2230` surface-2 elevation step in the dark daisyUI theme; route `.ops-*` raised-surface fill recipes to the new token so dark steps up in elevation rather than flattening. Light stays pixel-identical. | token | 130 | DARKTOKEN-01 |
| DK-02 SYS | element | Search + Playbooks dark form inputs — `#search_q`, `#capture_title`, `#phx-*` inputs | DD6 | 0 | blocker | systemic | `06-search--dark--mobile--results`, `08-search--dark--mobile--zero-results`, `09-playbooks--dark--mobile--empty-workspace`; app.css:506-533 (`.ops-form-control` — no dark override for text color); 128-report cluster 2 (fg `#1f2933` bg `#141923` 1.19:1, systemic) | Fix the dark input text token and/or input background token so form field text has ≥4.5:1 contrast against the dark input surface in both `[data-theme=dark]` and `@media (prefers-color-scheme: dark)` paths. | token | 132 | A11Y-TOKEN-01 |
| DK-03 | element | Search screen — `pre` code block in dark | DD6 | 0 | blocker | per-screen | `06-search--dark--mobile--results`; app.css:993-995 (`ops_code_block` variant=`:default` uses `bg-base-200` = `#0c0f14` in dark; text `#1f2933` on bg `#0c0f14`); 128-report priority 3 (`pre` 1.3:1 fg `#1f2933` bg `#0c0f14`, local) | Provide a dark override for `ops_code_block`'s background in dark mode — the `:default` variant's `bg-base-200` renders Night (darker than the surface) instead of a raised surface. Use the new surface-2 token from DK-01. | token | 132 | A11Y-TOKEN-01 |
| DK-04 | element | Search screen — `.bg-primary` run-search button near-miss | DD6 | 1 | blocker | per-screen | `08-search--dark--mobile--zero-results`; app.css:579-583 (`.ops-nav-item-active` uses `var(--color-primary)` = `#6c5ce7` in dark, also `.ops-btn` primary variant); 128-report cluster 3 (`.bg-primary` fg `#f4f1ea` bg `#6c5ce7` 4.3:1, local, 0.2:1 gap) | Lighten the dark `--color-primary` token slightly (or darken `primary-content`) to clear 4.5:1 AA. Gap is 0.2:1 — a minimal token adjustment. | token | 132 | A11Y-TOKEN-01 |

### Structural (brand-fidelity systemic gaps, DD1–DD5, ≥3 screens)

| ID | Alt | Touchpoint | Dim | Score | Sev | Scope | Evidence | Proposed fix | Fix-class | Phase | Req |
|----|-----|-----------|-----|-------|-----|-------|----------|--------------|-----------|-------|-----|
| DK-05 SYS | element | All 6 screens — dark ramp flatness: `.ops-panel`, `.ops-muted-panel`, `.ops-data-card`, `.ops-verdict-neutral`, `.ops-notice-surface` all blend toward base-200 (Night) in dark | DD1 | 0 | structural | systemic | `00-control-room--dark--desktop--incident` (intent cards flat), `01-posture--dark--mobile--incident` (metric tiles indistinguishable from bg), `03-sync-drift--dark--desktop--drift` (preflight panel blends into shell), `09-playbooks--dark--desktop--empty-workspace` (data-card invisible against bg); app.css:243 (`ops-panel` bg `color-mix(base-100 96%)` = Ink 96% = #141923 in dark; app.css:256 (`ops-muted-panel` bg `color-mix(base-200 64%)` = Night 64% = #0c0f14 — darker than bg); app.css:262 (`ops-data-card` bg `color-mix(base-100 92%)`) | After DK-01 introduces the surface-2 token, re-route `.ops-panel`/`.ops-muted-panel`/`.ops-data-card`/`.ops-notice-surface` fill recipes to use theme-scoped elevation tokens (surface vs surface-2 vs bg) so raised surfaces are visibly lighter than the page bg in dark. | token | 130 | DARKTOKEN-01 |
| DK-06 SYS | element | All 6 screens — ambient-shadow depth absent in dark: panels carry correct CSS shadow but ramp collapse defeats it | DD4 | 0 | structural | systemic | `00-control-room--dark--desktop--incident` (verdict hero looks flat despite `shadow-ops-raised`); `01-posture--dark--desktop--incident` (Fleet posture panel blends with shell bg); `04-control-room--dark--desktop--all-green` (intent cards no depth separation); app.css:244 (`ops-panel` `shadow-ops-surface`); app.css:364 (`ops-verdict--hero` `shadow-ops-raised`); app.css:135-138 (shadow values use `color-mix(base-content N%, transparent)` — cream-on-dark shadows technically present but invisible when surface bg = bg) | After DK-01/DK-05 fix the ramp, add a dark-specific ambient shadow recipe: a low-spread, dark-inward shadow (e.g. `0 1px 3px rgba(0,0,0,0.4)`) alongside the existing `border` on raised surfaces so panels read as seated depth in dark independent of the ramp fix. Reference brand book §6.5: "faint ambient shadow plus border." | token | 130 | DARKTOKEN-01 |
| DK-07 SYS | element | All 6 screens — copper/secondary absent in dark: brand prescribes 5% copper role; actual usage is ~1-2% (only eyebrow label + route-mark gradient) | DD2 | 1 | structural | systemic | `00-control-room--dark--desktop--incident` (no copper accents on intent cards, badges, or callout nodes); `06-search--dark--desktop--results` (no copper on result-row counts or federation badge); `09-playbooks--dark--desktop--empty-workspace` (no copper on workspace file cards or import notice); ops_ui.ex:23 (`text-secondary` eyebrow only); app.css:989 (`ops-route-mark` gradient — reserved, not a UI accent) | Introduce a `.ops-copper-*` accent vocabulary (eyebrow labels, key-callout badges, diagram/route node emphasis) available in both themes per COPPER-01. Copper is a brand accent, never a status tone. Ensure AA-safe dark-text-on-copper pairings. | component | 131 | COPPER-01 |
| DK-08 SYS | element | All 6 screens — 65/20/10/5 neutral ratio: in dark all surfaces collapse to the same Night–Ink band, making the ratio effectively 90% neutral / 5% violet / 5% status; violet and copper are under-weighted | DD2 | 1 | structural | systemic | `04-control-room--dark--desktop--all-green` (fully neutral — no violet or copper accents beyond the primary nav pill); `05-posture--dark--desktop--all-green` (entire screen in midnight gray-blue band); `03-sync-drift--dark--desktop--drift` (preflight and panels all same shade); app.css:28-55 (dark theme: base-100=#141923, base-200=#0c0f14, primary=#6c5ce7 — only 3 distinct surface tones, all in the same blue-gray band with no ramp lift) | After DK-01 restores the ramp, ensure the violet primary (10%) is used at strategic anchor points (active nav, key CTAs, route mark) and copper (5%) lands on accents/eyebrows so the palette reads as intentional — not accidentally monochromatic. Coordinate with DK-07 (copper vocabulary). | token | 130 | DARKTOKEN-01 |
| DK-09 SYS | element | Failed Sync + Search + Playbooks — dark code-block background inverted: `ops_code_block :default` uses `bg-base-200` which in dark = Night (#0c0f14), making code blocks darker than surrounding content (inverted hierarchy) | DD1 | 1 | structural | systemic | `02-failed-sync--dark--desktop--populated` (triage code blocks appear as dark wells, not raised); `06-search--dark--desktop--results` (raw-hit preview area darker than surrounding card); `09-playbooks--dark--mobile--empty-workspace` (playbook JSON preview invisible against dark shell bg); ops_ui.ex:994 (`@variant == :default && "max-h-96 bg-base-200 p-ops-3"`) | Provide a dark-theme override for the code-block surface token so `:default` reads as a raised surface (use surface-2 from DK-01) and `:compact`/`:embedded` variants also step correctly in dark. Light stays pixel-identical. | token | 130 | DARKTOKEN-01 |
| DK-10 | element | Shell chrome — `.ops-shell` radial violet wash: currently `color-mix(primary 14%, transparent)` — adequate at desktop but overly prominent at mobile where it covers more relative viewport area | DD3 | 2 | structural | per-screen | `00-control-room--dark--mobile--incident` (violet wash feels heavier at 390px relative to content); `01-posture--dark--mobile--incident` (same wash dominates the narrow viewport); app.css:235-238 (`.ops-shell` radial gradient with `color-mix(primary 14%)` and `34rem` extent) | Reduce the shell wash extent or alpha at mobile breakpoints (e.g. `12%` or `28rem`) so it reads as a quiet signature mark rather than a visible background treatment at small screens. Brand book §6.3: "quiet glow, not loud glow." | token | 131 | GLOW-01 |

### Polish (brand-fidelity per-screen gaps, DD1–DD5, single screen)

| ID | Alt | Touchpoint | Dim | Score | Sev | Scope | Evidence | Proposed fix | Fix-class | Phase | Req |
|----|-----|-----------|-----|-------|-----|-------|----------|--------------|-----------|-------|-----|
| DK-11 | element | Control Room (incident) — verdict panel: "Degraded" notice surface has correct amber tone-border but the raised panel bg disappears in dark (ramp collapse makes `.ops-verdict` and `.ops-notice-surface` coplanar) | DD1+DD4 | 1 | polish | per-screen | `00-control-room--dark--desktop--incident`, `00-control-room--dark--mobile--incident`; app.css:349-358 (`.ops-verdict` and `.ops-verdict-neutral` bg `color-mix(base-200 64%)` — in dark = Night 64%, coplanar with shell bg); app.css:270-280 (`.ops-notice-surface`) | After DK-01/DK-05 restore the ramp, verify the Control Room verdict panel reads as raised above the shell in both desktop and mobile dark viewports. No separate fix needed if systemic ramp token fix propagates correctly. | screen | 134 | SCREEN-DARK-01 |
| DK-12 | element | Control Room — intent cards: "Something looks broken / I'm shipping / Explore & capture" cards have no visible copper accent or path-node visual motif in dark | DD2 | 1 | polish | per-screen | `00-control-room--dark--desktop--incident`, `04-control-room--dark--desktop--all-green`; ops_ui.ex:836-900 (`.ops-intent-card` with Heroicon — no copper/secondary color applied to icon or card elements); app.css:836-864 (intent card uses `base-100 94%` bg + `primary 40%` hover border — no copper) | After DK-07 establishes copper vocabulary, apply a copper accent to the intent-card icon or key-callout element so the card reads as "Scrypath brand" not generic ops console. | screen | 134 | SCREEN-DARK-01 |
| DK-13 | flow | Posture (incident) — per-schema table in dark mobile: row separators nearly invisible (table uses `ops-table-scroll` with `overflow-x-auto`; row borders are `color-mix(base-content 12%)` = cream at 12% on dark = very low contrast row separation) | DD4 | 1 | polish | per-screen | `01-posture--dark--mobile--incident` (per-schema table rows barely distinguishable); app.css:719 (`.ops-table` row border `color-mix(base-content 12%)`) | After DK-01 restores ramp, evaluate if row borders still need a dark-specific alpha boost (e.g. 18%) to read clearly at mobile. Brand book §6.5: "1px borders — slightly blue-gray slate on dark mode." | screen | 134 | SCREEN-DARK-01 |
| DK-14 | element | Posture — fleet posture verdict hero: `.ops-verdict--hero` `shadow-ops-raised` (`0 2px 10px cream 10%`) is semantically correct but in dark the warm cream shadow on a dark-navy surface may read as a faint halo rather than seated depth | DD4 | 2 | polish | per-screen | `01-posture--dark--desktop--incident` (fleet posture verdict appears to float slightly but depth is ambiguous); app.css:363-365 (`.ops-verdict--hero` `shadow-ops-raised`); app.css:137 (`shadow-ops-raised: 0 2px 10px color-mix(base-content 10%)`) | After DK-06 adds the dark ambient-shadow recipe, verify the verdict hero reads as the most elevated element on the screen in dark. If the warm cream shadow is too subtle, use a dark-inward ambient shadow layered with the existing one. | screen | 134 | SCREEN-DARK-01 |
| DK-15 | element | Failed Sync — triage guidance notice (`ops-notice-surface` info tone) background is nearly invisible in dark against the shell | DD1 | 1 | polish | per-screen | `02-failed-sync--dark--desktop--populated`, `07-failed-sync--dark--desktop--empty`; app.css:270-280 (`.ops-notice-surface` — no explicit bg, inherits transparent; in dark the panel bg = shell bg = Night/Ink blend); ops_ui.ex:525 (`ops_notice` renders `.ops-notice-surface` + tone class) | After DK-05 routes notice surfaces to elevation tokens, verify the info-tone triage guidance reads as a distinct surface from the shell in dark. | screen | 134 | SCREEN-DARK-01 |
| DK-16 | element | Sync/Drift — preflight step chips and "index contract" section: alternating `:success`/`:warning`/`:neutral` tone chips visible but background panels separating sections are coplanar in dark | DD1 | 2 | polish | per-screen | `03-sync-drift--dark--desktop--drift` (promotion preflight section header and index contract header appear at same elevation as content); `03-sync-drift--dark--mobile--drift`; app.css:256 (`ops-muted-panel bg-base-200 64%` = Night 64% in dark) | After DK-05 fixes muted-panel bg, verify Sync/Drift sections read with clear visual hierarchy in dark — the "read-only checks" header, promotion preflight, and index contract panels should appear as distinct sections. | screen | 134 | SCREEN-DARK-01 |
| DK-17 | element | Search — result rows: `ops_result_row` hover state uses `shadow-ops-mid` and border-color transition; in dark the hover is barely perceptible because the delta between resting and hover bg is minimal (ramp collapse) | DD4 | 2 | polish | per-screen | `06-search--dark--desktop--results` (result rows visually flat; hover feedback imperceptible without ramp); app.css:845-860 (`.ops-result-row` resting `shadow-ops-surface`, hover `shadow-ops-raised`; also `border-color` + `color-mix(base-content 12%)` resting → `primary 40%` hover) | After DK-01/DK-05 restore ramp, verify result row hover is perceptible in dark. If needed, boost the hover border-color alpha in dark to `primary 55%`. | screen | 134 | SCREEN-DARK-01 |
| DK-18 | element | Playbooks — workspace file data-cards: three data-cards (empty-result/federated/single-index) in dark show nearly no elevation distinction from the muted-panel background | DD1 | 1 | polish | per-screen | `09-playbooks--dark--desktop--empty-workspace` (three workspace cards nearly invisible against the page bg); `09-playbooks--dark--mobile--empty-workspace` (same); ops_ui.ex:816 (`ops_data_card` applies `p-ops-3`; app.css:259-263 bg `base-100 92%` in dark = Ink 92% = #141923 — same as surface) | After DK-05 routes `ops-data-card` bg to an elevation token, verify the three workspace file cards read as distinctly raised surfaces. | screen | 134 | SCREEN-DARK-01 |
| DK-19 | flow | Path-motion dark expression: DARKMOTION-01 requires path-line glow and line-draw/reveal patterns tuned for dark. No current path-line glow exists on any admin screen (no route diagrams in these views) — this is a gap-to-fill for Phase 133, not a regressions | DD5 | 2 | polish | per-screen | `00-control-room--dark--desktop--incident` (`.ops-route-mark` logo gradient = approved path-line mark, app.css:988-990); no other path/route diagram elements in any of the 6 screens | Phase 133 (DARKMOTION-01) should introduce opt-in path-line glow on the route mark and any future diagram elements. Reserve it for those elements only — do not apply to panels, buttons, or text. Existing shell wash is the only background glow and should stay restrained. | motion | 133 | DARKMOTION-01 |

---

## Systemic cluster analysis

For each cluster: IDs, phase, anchor file:line. Criteria: same token/recipe failing on ≥3 distinct screens.

| # | Cluster name | Finding IDs | Phase target | Anchor file:line | Root token/recipe |
|---|-------------|-------------|--------------|-----------------|-------------------|
| **1 (finding #1)** | **`#1B2230` surface-2 ramp collapse** | DK-01, DK-05, DK-06, DK-08, DK-09 | 130 (token) + 132 (AA) | app.css:28-29 (`--color-base-100: #141923`, `--color-base-200: #0c0f14` — surface-2 `#1B2230` missing); 128-report cluster 1 | `base-100`/`base-200` dark theme values; raised-surface fill recipes blending to `base-200` (Night) instead of `#1B2230` |
| 2 | Dark form inputs invisible | DK-02 | 132 (A11Y) | app.css:506-533 (`ops-form-control`); 128-report cluster 2 | `--color-base-content` used as input text color; `--color-base-100` as input bg — both too close in dark |
| 3 | Copper/secondary absence | DK-07, DK-08 | 131 (COPPER) | ops_ui.ex:23 (`text-secondary` eyebrow only); app.css:989 (`ops-route-mark` gradient) | `--color-secondary` (#c17a3e) is defined but only used in 2 places; no `.ops-copper-*` vocabulary |
| 4 | Dark ambient depth absent | DK-06 | 130 (GLOW/token) | app.css:135-138 (shadow ladder uses cream at 8-12%); app.css:244, 280, 364 | Shadows are cream-on-dark (technically present) but ramp collapse makes them invisible as depth cues |
| 5 | Code-block bg inverted | DK-09 | 130 (token) | ops_ui.ex:994 (`bg-base-200` for `:default` variant) | `bg-base-200` = Night in dark → code blocks darker than surrounding content (inverted visual hierarchy) |
| 6 | DD6 `.bg-primary` near-miss | DK-04 | 132 (A11Y) | app.css:28 (`--color-primary: #6c5ce7`); 128-report cluster 3 | Violet 500 at 4.3:1 vs cream — 0.2:1 under the AA wire |

---

## Prioritized fix list for phases 130–135

| Phase | Req | Finding IDs | Fix description |
|-------|-----|-------------|----------------|
| 130 | DARKTOKEN-01 | DK-01, DK-05, DK-06, DK-08, DK-09 | **Surface ramp + depth tokens.** Introduce `#1B2230` as the dark surface-2 elevation step in the daisyUI theme block. Re-route `.ops-panel`, `.ops-muted-panel`, `.ops-data-card`, `.ops-verdict-neutral`, `.ops-notice-surface`, `ops_code_block :default` fill recipes to theme-scoped elevation tokens. Add a dark-specific ambient-shadow recipe (dark-inward low-spread) so panels seat visually without relying on cream-on-dark. Light stays pixel-identical. Estimated: 1 token change + N recipe re-routes in `app.css`. |
| 131 | GLOW-01 | DK-10 | **Shell wash + glow vocabulary.** Tune `.ops-shell` radial wash alpha/extent at mobile breakpoints. Introduce tokenized opt-in "quiet glow" class for route/path/diagram emphasis. |
| 131 | COPPER-01 | DK-07, DK-08 | **Copper accent vocabulary.** Introduce `.ops-copper-*` CSS classes (eyebrow badge, key-callout chip, diagram node emphasis) consuming `--color-secondary` (#c17a3e dark). Verify AA-safe dark-text-on-copper pairing. Apply copper to intent-card icons (DK-12) and eyebrow surfaces in both themes. |
| 132 | A11Y-TOKEN-01 | DK-02, DK-03, DK-04 | **AA remediation.** Fix dark form input text token (fg/bg for `.ops-form-control` in `[data-theme=dark]` + `@media prefers-color-scheme`). Fix `ops_code_block :default` dark bg (supersedes DK-03 if DK-09 token is already repaired in Phase 130). Lighten dark `--color-primary` by ~2% to clear 4.5:1. Run CONTRAST-HARNESS-01 to verify 0 AA failures. |
| 133 | DARKMOTION-01 | DK-19 | **Path-motion expression.** Introduce path-line glow and line-draw/reveal patterns for route mark and any future diagram elements. Reserve glow for path/route/diagram elements only — no panels, text, or background floods. Tune for dark-signature expression; reduced-motion-safe. |
| 134 | SCREEN-DARK-01 | DK-11, DK-12, DK-13, DK-14, DK-15, DK-16, DK-17, DK-18 | **Per-screen polish.** After Phase 130 ramp fix, verify and tune per-screen dark-expression on all 6 screens: Control Room (verdict depth, intent-card copper), Posture (table row borders, verdict hero shadow), Failed Sync (notice surface separation), Sync/Drift (section depth), Search (result row hover), Playbooks (data-card elevation). Re-capture 40-shot matrix after Phase 130–132 land. |
| 135 | SHELL-DARK-01 | (no new DK IDs — shell chrome inherits DK-01/DK-05 ramp fix) | **Shell chrome polish.** After Phase 130, audit header/nav, command palette, flash, theme toggle in dark. Confirm `.ops-shell` violet wash reads as quiet mark. Verify nav-item dark hover contrast. Confirm palette/flash adopt dark ambient-shadow recipe. |
