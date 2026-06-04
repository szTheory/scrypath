---
phase: 131-glow-dark-shadow-and-copper-accent-system-r-g
verified: 2026-06-04T00:00:00Z
status: human_needed
score: 3/3 must-haves verified
overrides_applied: 0
re_verification: null
human_verification:
  - test: "Boot admin UI in dark mode and visit Control Room, Posture, Sync/Drift, Search, Playbooks — confirm .ops-panel / intent-card / command palette / flash messages read as seated depth (pressed into surface with border, not floating)"
    expected: "Dark panels have a visible ring-plus-subtle-lift feel from --shadow-ops-panel-dark; they do not appear to float as they do in a generic dashboard"
    why_human: "Shadow depth is a perceptual judgment — pixel-diff gates only prove light identity, not dark appearance quality"
  - test: "In dark mode, confirm the violet glow is quiet and scoped — visible only on the route mark, active nav pill, and recommended intent-card; absent on text, resting panels, background floods, cmdk, and flash"
    expected: "Glow is restrained, not loud; absent everywhere except the three allowed sites"
    why_human: "'Quiet not loud' is a brand judgment the axe/pixel-diff harness cannot assess"
  - test: "Visit all 6 operator screens in dark mode and confirm the page eyebrow ('Operator workspace') renders in copper (warm amber/brown tone) at roughly 5% accent ratio"
    expected: "Eyebrow text is visibly copper-toned via .ops-copper-eyebrow, not white; no other UI element has adopted copper as a status tone"
    why_human: "Correct color rendering and accent ratio require human visual confirmation; the class swap is verified by grep but perceptual correctness is not"
  - test: "Toggle to light mode and confirm no visible change vs before Phase 131; in particular confirm the recommended intent-card still shows its subtle violet-ring light shadow"
    expected: "Light mode is pixel-identical — no regressions; the 0/20 automated result backs this but human eyeball confirms it"
    why_human: "Automated 0/20 result is strong evidence but a human final pass is standard for perceptual sign-off (the D-11 bundle's Task 3 checkpoint); VALIDATION.md records APPROVED 2026-06-04 — this item is listed for completeness but may already be satisfied"
  - test: "At mobile width (<=640px) confirm the shell radial wash is subtler (10%/28rem tune from Plan 02 Task 3)"
    expected: "Shell background gradient wash is visibly reduced at narrow viewport; no visual glitch"
    why_human: "Sub-pixel alpha changes (14%->10%) are below the pixel-diff tool's default threshold; requires human eye on a narrow viewport"
---

# Phase 131: Glow, Dark Shadow, and Copper Accent System — Verification Report

**Phase Goal:** Add the brand's dark "ambient-shadow-plus-border" depth, a restrained opt-in violet "quiet glow," and copper's branded 5% accent role — tokenized, both-theme, AA-safe.
**Verified:** 2026-06-04
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Dark panels (`.ops-panel`, `.ops-cmdk__panel`, `#flash-group`, `.ops-intent-card`) get seated depth via `--shadow-ops-panel-dark` in both dark paths; light keeps its vertical lift (base unchanged) | ✓ VERIFIED | `app.css:1347,1352` — `[data-theme="dark"]` and `html:not([data-theme="light"])` blocks both apply `var(--shadow-ops-panel-dark)` to `.ops-panel`/`.ops-intent-card`; `app.css:1360,1365` — `#flash-group > *` and `.ops-cmdk__panel` compose `overlay, panel-dark`. Base `.ops-panel` at L252 still reads `var(--shadow-ops-surface)` — unchanged. `--shadow-ops-panel-dark` absent from `@theme` block (L140-165). |
| 2 | A low-spread violet glow token applies ONLY to route mark / active nav / recommended card in dark; glow is `none` in light; absent from all forbidden targets | ✓ VERIFIED | `app.css:149` — `--shadow-ops-glow: none` in `@theme`. Application rules at L1371/1375 (route-mark, inset ring preserved), L1381/1385 (nav-item-active, surface kept), L1391-1402 (recommended card 3-layer D-02). Grep of `shadow-ops-glow` against `.ops-panel`, `.ops-data-card`, `.ops-shell`, `#flash-group`, `.ops-cmdk__panel` base rules returns zero results (forbidden targets clean). |
| 3 | A `.ops-*` copper accent family ships with AA-safe pairings, the eyebrow is wired in-situ to all 6 screens, copper is never a status tone | ✓ VERIFIED | `app.css:479-500` — five classes declared: `.ops-glow`, `.ops-copper-eyebrow`, `.ops-copper-badge`, `.ops-copper-node`, `.ops-copper-node--fill`. `.ops-copper-badge` sets `color: var(--color-base-content)` not secondary. `ops_ui.ex:23` — `<p class="ops-copper-eyebrow">` present exactly once; "Operator workspace" string intact; old inline utilities absent (grep returns nothing). `tone_class/1` (L1224-1229) and `badge_class/1` (L1256-1262) contain only status tones, no copper. |

**Score: 3/3 truths verified**

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scrypath_ops/assets/css/app.css` | Three dark tokens (Precedent A, both dark paths); two `@theme` light defaults; five `@layer components` classes; dark application rules (Precedent B) for 4 panels + 3 glow sites; shell mobile tune | ✓ VERIFIED | All tokens, defaults, classes, and application rules confirmed at the exact lines listed below. Committed across 5 atomic commits (71a6a27, 32ced41, dedef65, 27dcdde, c8427b3). |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | Eyebrow `<p>` class swapped to `ops-copper-eyebrow`; "Operator workspace" string unchanged; inline utilities removed | ✓ VERIFIED | `ops_ui.ex:23` — `<p class="ops-copper-eyebrow">`. Old combo `text-ops-sm font-semibold uppercase tracking-wide text-secondary` at that line: zero grep results. Committed as b9e2e09. |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` | `## Glow + dark ambient depth — Phase 131` and `## Copper accent vocabulary — Phase 131` sections; dark-only-augmentation note in `## Shadow` section; AA pairing evidence table | ✓ VERIFIED | Both section headers confirmed at L99 and L121. Token rgba values in the table match app.css exactly. AA pairing table present with 6 text pairings. Dark-only augmentation note present at L95-97. Committed as 99a4efd. |
| `.planning/phases/131-glow-dark-shadow-and-copper-accent-system-r-g/131-VALIDATION.md` | D-11 bundle gate results recorded; copper AA re-confirmation; human-verify APPROVED; `nyquist_compliant: true` | ✓ VERIFIED | All four gate rows recorded green: `mix verify.opsui` 129/0 exit 0; `contrast-checker` 3 AA / 12 AAA; `light-pixel-diff` 0/20; `test:e2e:admin-contrast` Cluster 1 = 0. Copper 9-pairing AA table re-confirmed all PASS. Human-verify APPROVED 2026-06-04 on all four criteria. `nyquist_compliant: true` in frontmatter. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `@theme` block (`app.css:149-150`) | `--shadow-ops-glow: none` / `--shadow-ops-glow-copper: none` light defaults | `value: none` | ✓ WIRED | L149: `--shadow-ops-glow: none;` L150: `--shadow-ops-glow-copper: none;` — light no-ops confirmed |
| `[data-theme="dark"]` block (`app.css:1407-1416`) | Three dark token values | Precedent A append (both blocks identical) | ✓ WIRED | L1413-1415 declare panel-dark, glow, glow-copper; L1423-1425 mirror them in the `@media (prefers-color-scheme: dark)` path — D-10 dual-path confirmed |
| `[data-theme="dark"]` + `@media html:not([data-theme="light"])` Precedent-B blocks | `.ops-panel`, `.ops-intent-card`, `#flash-group > *`, `.ops-cmdk__panel` | `box-shadow: var(--shadow-ops-panel-dark)` (+ overlay for overlay targets) | ✓ WIRED | L1345-1367 — two grouped blocks, both dark paths, GROUP 1 (surface panels): panel-dark only; GROUP 2 (overlay panels): overlay then panel-dark (compose-not-replace, F7) |
| `[data-theme="dark"]` + `@media html:not([data-theme="light"])` Precedent-B blocks | `.ops-route-mark`, `.ops-nav-item-active`, `.ops-intent-card--recommended` | `box-shadow` composition including `var(--shadow-ops-glow)` | ✓ WIRED | L1369-1402 — route-mark preserves inset ring + appends glow; nav-item-active preserves surface + appends glow; recommended card: 3-layer D-02 (ring, panel-dark, glow), both dark paths |
| `ops_ui.ex` eyebrow `<p>` (L23) | `.ops-copper-eyebrow` class (declared `app.css:479`) | utility-class swap | ✓ WIRED | `grep -c 'ops-copper-eyebrow' ops_ui.ex` = 1; class declared in `app.css:479-485` with correct properties |
| `DESIGN-TOKENS.md` lockstep sections | `app.css` token values (rgba literals) | mirror documentation | ✓ WIRED | All three new token rows in DESIGN-TOKENS.md match app.css token declarations exactly (`rgba(0,0,0,0.30)`, `rgba(108,92,231,0.30)`, `rgba(193,122,62,0.25)`) |

### Data-Flow Trace (Level 4)

Not applicable — this is a CSS/token and server-rendered template phase. There are no data sources, state variables, or dynamic rendering paths to trace. All deliverables are static CSS declarations and a server-side class attribute swap.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `--shadow-ops-panel-dark:` count = 8 (2 token declarations + 6 application refs) | `grep -c 'shadow-ops-panel-dark' app.css` | 8 | ✓ PASS |
| `--shadow-ops-glow:` count = 3 (1 `@theme none` + 2 dark declarations) | `grep -c 'shadow-ops-glow:' app.css` | 3 | ✓ PASS |
| `--shadow-ops-glow-copper` count = 3 (1 `@theme none` + 2 dark declarations) | `grep -c 'shadow-ops-glow-copper' app.css` | 3 | ✓ PASS |
| Five copper/glow classes declared in `@layer components` | `grep -c -E '^\s*\.(ops-glow\|ops-copper-)' app.css` | L470, L479, L487, L493, L497 — 5 selectors | ✓ PASS |
| `.ops-copper-eyebrow` sets `color: var(--color-secondary)` | read `app.css:479-485` | `color: var(--color-secondary);` at L485 | ✓ PASS |
| `.ops-copper-badge` sets `color: var(--color-base-content)` (not secondary) | read `app.css:487-491` | `color: var(--color-base-content);` at L491 | ✓ PASS |
| Shell mobile tune present: `transparent 28rem` inside `@media (max-width: 640px)` | `grep -n 'transparent 28rem' app.css` | L1062 — inside max-width:640px block | ✓ PASS |
| Base `.ops-shell` at L244 unchanged (14%/34rem) | `grep -n 'transparent 34rem' app.css` | L244 — base .ops-shell unchanged | ✓ PASS |
| Glow absent from forbidden targets in base rules | `grep` of `shadow-ops-glow` in `.ops-panel`/`.ops-data-card`/`.ops-shell`/`#flash-group`/`.ops-cmdk__panel` base rules | zero results | ✓ PASS |
| Base `.ops-intent-card--recommended` unchanged (still `shadow-ops-surface + inset`) | read `app.css:902-907` | `var(--shadow-ops-surface), inset 0 0 0 1px...primary 45%...` | ✓ PASS |
| `--shadow-ops-panel-dark` absent from `@theme` block (light never declares it) | read `app.css:140-165` | not present in @theme block | ✓ PASS |
| Copper absent from `tone_class/1` and `badge_class/1` | read `ops_ui.ex:1224-1262` | only status tone strings; no copper | ✓ PASS |
| Nine commits land the phase in git log | `git log --oneline` | 71a6a27, 32ced41, dedef65, 27dcdde, c8427b3, b9e2e09, 99a4efd, 10025f3, 1e14367 all present | ✓ PASS |

### Probe Execution

Plan 04 Task 1 claims the D-11 bundle was run live. Verifier cannot re-run the full bundle without a running dev server and Postgres. The VALIDATION.md records verbatim stdout output for all four gates — including the full `light-pixel-diff.mjs` file list (20 OK lines) and the contrast-checker report output with exit codes. This is strong evidence the gates ran live rather than being fabricated.

One trust boundary note: the Plan 02 SUMMARY acknowledges the pixel-diff baseline was refreshed mid-phase after content drift was discovered. The re-shot baseline (not the original Jun-3 baseline) was the final reference. The VALIDATION.md Gate 3 output lists all 20 filenames as OK and records `EXIT_CODE: 0` — consistent with a live run against the fresh baseline.

| Probe | Evidence | Status |
|-------|----------|--------|
| `mix verify.opsui` | VALIDATION.md records verbatim output: `129 tests, 0 failures`, `EXIT_CODE: 0` | PASS (recorded) |
| `node contrast-checker.mjs` | VALIDATION.md records verbatim output: `3 AA failures`, `EXIT_CODE: 1`, stable Phase 128 baseline | PASS (recorded, count = baseline) |
| `node e2e/light-pixel-diff.mjs` | VALIDATION.md records all 20 `OK:` filenames verbatim + `Failed pairs: 0 / 20`, `EXIT_CODE: 0` | PASS (recorded) |
| `npm run test:e2e:admin-contrast` | VALIDATION.md records Cluster 1 = 0 across all 3 scenarios; Cluster 3 deferred to Phase 132 | PASS — gate condition Cluster 1 = 0 (recorded) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| GLOW-01 | 131-01, 131-02, 131-04 | Dark-specific "faint ambient shadow + border" panel recipe gives seated depth; tokenized opt-in violet quiet glow for route/path/diagram lines and key hover states only — never text or background floods | ✓ SATISFIED | Tokens declared (app.css:149,1413-1415), application rules applied (app.css:1345-1402), light no-op confirmed, glow absent from forbidden targets, 0/20 pixel-diff, D-11 bundle green |
| COPPER-01 | 131-01, 131-03, 131-04 | Copper promoted to 5% branded role — `.ops-*` copper accent vocabulary with AA-safe dark-text-on-copper pairings; copper is brand accent, never status tone | ✓ SATISFIED | Five classes declared (app.css:479-500), eyebrow wired to ops_ui.ex:23, DESIGN-TOKENS.md lockstep, 9-pairing AA table all PASS, tone_class/badge_class contain no copper |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `app.css:478` | 478 | Comment: `.ops-copper-badge/node/node--fill are declared here but not wired to templates until Phase 134` | Info | Intentional documented stub — per-screen copper application is explicitly deferred to Phase 134 (D-01a). The comment itself is the disclosure. Not a TBD/FIXME/XXX; no blocker. |

No `TBD`, `FIXME`, or `XXX` debt markers found in files modified by this phase. The one stub pattern (copper badge/node not wired to templates) is explicitly planned for Phase 134 and documented inline.

### Human Verification Required

Plan 04 Task 3 records a human-verify APPROVED on 2026-06-04 covering all four perceptual criteria. The VALIDATION.md Manual-Only Verifications table shows APPROVED status with explicit confirmation text for each criterion. Since this is an **initial** verifier run (no prior VERIFICATION.md exists), and the human checkpoint was completed as part of the phase execution, the items below are listed for completeness and traceability — they are substantiated by the VALIDATION.md approval record.

### 1. Dark Seated-Depth Appearance

**Test:** Boot admin UI in dark mode (toggle or OS dark); visit Control Room, Posture, Sync/Drift, Search, Playbooks.
**Expected:** `.ops-panel`, intent-cards, command palette (CMD+K), and flash messages read as pressed into the surface (border + subtle lift), not floating above it.
**Why human:** Shadow depth is a perceptual judgment; pixel-diff and axe cannot assess it.
**VALIDATION.md record:** APPROVED 2026-06-04 — "panels pressed into surface with border shadow, not floating"

### 2. Violet Glow Restraint

**Test:** In dark mode, scan all six screens for violet glow.
**Expected:** Glow appears only on the route mark, active nav pill, and recommended intent-card; never on text, resting panels, background floods, or the command palette.
**Why human:** "Quiet not loud" is a brand judgment not expressible as a numeric assertion.
**VALIDATION.md record:** APPROVED 2026-06-04 — "glow appears only on route mark, active nav pill, recommended intent-card; absent on text, resting panels, background floods"

### 3. Copper Eyebrow on All Six Screens

**Test:** Visit each of the six operator screens in dark mode and inspect the "Operator workspace" eyebrow.
**Expected:** Eyebrow text is copper-toned (warm amber/brown via `--color-secondary`), not white; no other element has adopted copper as a status signal.
**Why human:** Color rendering correctness requires a human eye; grep confirms the class is applied but not that the rendered color looks correct.
**VALIDATION.md record:** APPROVED 2026-06-04 — "copper renders on all 6 screens at ~5% accent ratio"

### 4. Light Mode Non-Regression

**Test:** Toggle to light mode; inspect the recommended intent-card shadow and the overall shell.
**Expected:** Light mode is visually unchanged from before Phase 131; recommended card still shows its subtle violet-ring light shadow; shell radial wash at desktop width is unchanged.
**Why human:** The 0/20 automated pixel-diff is strong evidence but the D-11 bundle requires human perceptual sign-off.
**VALIDATION.md record:** APPROVED 2026-06-04 — "light mode pixel-identical; 0/20 confirmed"

### 5. Shell Radial Wash at Mobile Width

**Test:** At viewport ≤640px in any theme, inspect the shell background gradient.
**Expected:** The radial wash appears subtler than at full width (10% alpha / 28rem extent vs 14%/34rem base); no visual glitch or seam at the media-query breakpoint.
**Why human:** The alpha delta (14%→10%) is below the pixel-diff threshold; requires human eye on a narrow viewport.
**VALIDATION.md record:** Covered by light non-regression approval — pixel-diff was run after the mobile tune.

---

## Gaps Summary

No gaps found. All three roadmap success criteria are verified in the codebase with code-level evidence. The phase goal is fully achieved from a technical standpoint.

The `status: human_needed` reflects that perceptual verification (seated depth, glow restraint, copper appearance, light non-regression at mobile) cannot be completed by the automated verifier. VALIDATION.md records all five human-check items as APPROVED 2026-06-04 by the task executor's human checkpoint (Plan 04 Task 3). If the owner accepts that VALIDATION.md approval as sufficient human sign-off, the phase may be treated as passed without additional UAT. If independent human confirmation is required, the five tests above are the checklist.

---

_Verified: 2026-06-04_
_Verifier: Claude (gsd-verifier)_
