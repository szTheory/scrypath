# Phase 173 — UI Review

**Audited:** 2026-10-07  
**Baseline:** Approved `173-UI-SPEC.md`, governing `173-CONTEXT.md` decisions, and repository `DESIGN.md`  
**Screenshots:** Captured in the exact-source evidence bundle at `/private/tmp/scrypath-phase173-20261006-155750/evidence/173-final/test-results/` (mounted and standalone, 390px/1440px, light/dark; status, time, and copy states also inspected). The approved static comps in the phase directory were reviewed as comparison material.  
**Interaction captures:** off (workflow.ui_interaction_capture is false); interaction findings derive from source and the committed-source Playwright suite.  
**Evidence identity:** `185832d6c863b1c84c863e1f5f4e9e2c44dbfc18`; 28 browser cases passed, 0 failures/errors/skips. The preserved 173-01 standalone original before-image is missing; later plan baselines exist, so the original standalone change cannot be compared contemporaneously.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Operational states and copy outcomes are explicit; healthy backend/queue wording still promotes observation into green “clear” status. |
| 2. Visuals | 3/4 | Clear health-first hierarchy and responsive stacking; healthy schema badges add prominent green treatment beyond the approved restrained local cue. |
| 3. Color | 2/4 | Neutral shell, metrics, selected state, and failure cues largely follow contract; healthy status badges visibly use green fill/borders despite the local-neutral status direction. |
| 4. Typography | 3/4 | Primary hierarchy and inherited metadata roles are respected; theme preference labels render at 12px although the contract specifies readable control labels at body/action scale. |
| 5. Spacing | 3/4 | Main 24px section and schema rhythm is consistent; status badge layout and long exact-time disclosure cause avoidable reflow at the 1279px rail boundary. |
| 6. Experience Design | 3/4 | Preference, refresh, time, clipboard, empty/error/disabled states have broad coverage; the persistent “Exact timestamp” disclosure leaves measured 1279px layout uneven when opened. |

**Overall: 17/24**

---

## Top 3 Priority Fixes

1. **Remove green success styling from “backend clear” and “queue observed”** — green can be read as a fleet-health guarantee even though these labels only describe observations — render these as neutral badges and reserve semantic status color for actual degraded/failure cues.
2. **Bring theme labels to the body/action text role** — the 12px labels are materially smaller than the contract’s 14px action labels and are harder to distinguish at mobile width — use the existing body/action token while preserving 44px targets and wrap/reflow behavior.
3. **Prevent open exact timestamp evidence from making a one-column signal group** — at 1279px the expanded disclosure makes one backend group stack while the adjacent queue group remains two-column — constrain disclosure width or provide a shared responsive row layout so both groups remain aligned.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The healthy labels “backend clear” and “queue observed” can imply successful health despite only indicating zero observed failures or that the queue was visible. They are rendered in every healthy schema header (`scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex:573-596`) and visually paired with green styling. Prefer descriptive neutral wording such as “no backend failures observed” and “queue observed” only as neutral telemetry, keeping the top-level verdict as the health interpretation.
- Positive contract coverage: the failure row names degraded state, cause, and next safe action; unavailable queue observations are explicitly distinguished from “Queue not used”; timestamp absence distinguishes “No success observed” and “Not observed”; clipboard success/failure copy is explicit (`posture_live.ex:431-459, 541-607`; `ops_ui.ex:1251-1290`).
- No generic “Submit”, “Click Here”, “OK”, or “Save” labels found in the audited Search health copy. The copy capture confirms “Timestamp copied” only after a resolved write.

### Pillar 2: Visuals (3/4)

- **WARNING:** The mounted desktop-light healthy capture shows two green pills per schema at the top-right. They compete with the page’s health verdict and differ from the approved treatment that keeps schema surfaces neutral and uses local explicit cues. This comes from the badge pair in `posture_live.ex:344-350` and its visible result in `173-final/test-results/phase173-captures/phase173-mounted-1440-light.png`.
- The mounted mobile-dark 390px capture shows a stable drawer header, visible theme names, wrapped full schema identifiers, and vertically stacked metrics and source groups without horizontal overflow. Desktop-light has a clear primary health verdict followed by metrics, next checks, and schema details.
- **WARNING:** In the 1279px standalone-light time capture, opening the exact timestamp causes its backend signal group to grow and wraps the disclosure’s ISO/UTC evidence to multiple lines while the sibling queue group remains compact. It is readable, but group alignment becomes uneven at the rail boundary (`173-final/test-results/phase173-time-captures/phase173-standalone-1279-light.png`; component `ops_ui.ex:1251-1255`).

### Pillar 3: Color (2/4)

- **WARNING:** Healthy schema badge states use success green on both `backend clear` and `queue observed`: `posture_live.ex:573-596` maps them to `:success`; `app.css:715-718` adds green border and fill. This directly conflicts with the contract’s restraint for healthy/observed status and its rule that status cues stay local and meaningful (`173-UI-SPEC.md:67-69, 99-114`). Remove green on these observational labels; keep green only where a verified success result warrants it.
- Positive evidence: page and schema floors are flat neutral (`#f7f6f3` / `#111419`), resting schema cards and metric tiles are neutral, current navigation is violet, and degraded/failure captures use localized amber/icon/text. These are visible in final mounted healthy and failed captures; source tokens are in `app.css:57-100`, with neutralized schema card rules at `1673-1692` and metric borders at `576-590`.
- The audit did not estimate a pixel-area 60/30/10 ratio. Its concern is the discrete status overuse above, not a claim that the palette is globally out of ratio.

### Pillar 4: Typography (3/4)

- **WARNING:** Theme preference labels are set to `font-size: 0.75rem` (12px) in `scrypath_ops/assets/css/app.css:2085-2099`, while the approved contract calls for 14px body/action control labels (`173-UI-SPEC.md:86-95`). In both 390px captures the labels remain legible, but they are noticeably smaller than the page’s standard action text. Raise them to the existing 14px action role without reducing the specified 44px targets.
- The primary scale uses 14/16/18/24px roles and preserves the documented 11/12px metadata/technical exceptions. System UI is used for explanatory copy; monospace is confined to identifiers and exact timestamp evidence. Do not apply generic “more than four sizes” heuristics to inherited metadata roles.

### Pillar 5: Spacing (3/4)

- **WARNING:** The open exact-time disclosure at 1279px produces a tall backend column whose “Last success” area diverges from the queue column; the content remains readable but the two signals no longer scan as a paired row. The spec’s 20px panel, 16px row, and 24px section steps are otherwise preserved. Consider a shared full-width evidence row or a bounded disclosure layout (`ops_ui.ex:1251-1255`; `app.css:1716-1724, 1773-1775`).
- Positive evidence: spacing tokens include the approved 4/8/12/16/20/24px roles and inherited 6px field gap (`app.css:124-136`); schema cards use a 24px list gap and 20px padding (`1673-1682`). The captured 390px layouts stack successfully, and boundary screenshots exist at both 1279 and 1280px for both entrypoints/themes.
- Arbitrary CSS spacing search found no `[...px]`/`[...rem]` overrides in the audited application CSS. Existing 2px/6px control internals, 20px padding, and 12px metadata follow the locked spec exceptions.

### Pillar 6: Experience Design (3/4)

- **WARNING:** The real Search health page has explicit fixture/refresh disabled explanations and the common refresh component preserves icon and label (`posture_live.ex:214-223`; `ops_ui.ex:221-235`). However, the `Exact timestamp` native disclosure is inline inside one of two adjacent signal groups. At 1279px, opening it pushes only the backend group taller and leaves the paired queue data top-aligned (`173-final/test-results/phase173-time-captures/phase173-standalone-1279-light.png`). Keep exact evidence keyboard/touch accessible but align its expanded presentation across both groups or give it a bounded shared disclosure row.
- Strong coverage: committed-source browser evidence reports 28/28 cases passed with no skips/errors across shell, status, time, and copy specs. The suite includes pointer and keyboard theme activation, System OS changes, blocked/invalid storage, refresh/patch stability, failed and unavailable states, copy success/rejection/unavailable, responsive widths, contrast, and 40px action target checks. This is evidence-backed behavior; interaction capture itself was off for this audit.
- The source has explicit operational error/empty labels, status feedback, server-disabled explanation, retained prior success on failed checks, and no misleading Checked copy affordance. `ops_loading/1` is a shared primitive, and this page’s refresh/loading behavior is exercised, but a separate page-level skeleton is not needed for this settled operator view.

---

## Files Audited

- `scrypath_ops/assets/css/app.css` and built `scrypath_ops/priv/static/assets/css/app.css`
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`
- `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex`
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex`
- `scrypath_ops/assets/js/app.js` and built `scrypath_ops/priv/static/assets/js/app.js`
- `examples/scrypath_ecommerce/assets/js/app.js`
- `examples/scrypath_ecommerce/assets/css/app.css`
- `examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts`
- `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts`
- `examples/scrypath_ecommerce/e2e/phase173_time.spec.ts`
- `examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts`
- `examples/scrypath_ecommerce/scripts/verify-phase173.sh`
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md`, `173-CONTEXT.md`, all four PLAN/SUMMARY pairs, `173-UI-CHECK.md`, and `173-VALIDATION.md`

Registry audit: skipped; `components.json` is absent, so this project is not initialized with shadcn registries.
