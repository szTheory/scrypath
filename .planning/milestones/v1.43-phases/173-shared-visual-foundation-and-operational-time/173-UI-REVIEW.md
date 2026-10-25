# Phase 173 — UI Review

**Audited:** 2026-10-13

**Source:** `5f6cb2f62bea579cdc92857efa79cf6c3a80d4eb` (`5f6cb2f` stacks retained evidence below 480px and applies the body font to retained explanation copy)

**Baseline:** Approved [173-UI-SPEC.md](173-UI-SPEC.md), with the documented compact-header follow-up in [175-03-SUMMARY.md](../175-repair-and-verification/175-03-SUMMARY.md)

**Screenshots:** Captured by exact-source Phase 173 browser lanes and inspected. Mounted and standalone 390px unavailable-state screenshots are from audited SHA `5f6cb2f` at `/private/tmp/scrypath-phase173-candidate-artifacts/scrypath-phase173/scrypath_phase173_status_5f6cb2f6_71711/screenshots/`. Status passed 6/6 at this SHA, including the responsive column and computed body-font assertions. Time, shell, and copy screenshots remain from `422670f` under `scrypath_phase173_time_422670f2_77019/screenshots/`, `scrypath_phase173_shell_422670f2_79505/screenshots/`, and `scrypath_phase173_copy_422670f2_81614/screenshots/`; the retained-copy style does not affect those states. The contrast run at `422670f` reported zero AA failures and 43 AAA advisories; `5f6cb2f` changes no color rules.
**Interaction captures:** off (workflow.ui_interaction_capture is absent; default is false)

The exact-source browser receipts report status 6/6 at `5f6cb2f`, time 8/8, shell 14/14, and copy 10/10 at `422670f`; contrast reported zero AA failures. These receipts supplement, but do not replace, visual inspection. No localhost capture was attempted because the supplied exact-source artifacts cover both production entrypoints and ambient port 8080 is unrelated. Status screenshots visibly include the test-only “Fixture scenario” control; it is excluded from the shipped-interface score.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Empty-state guidance now matches the host allowlist contract; unavailable and clipboard outcomes are explicit and sanitized. |
| 2. Visuals | 4/4 | The unavailable-state evidence now stacks at mobile width with a clear, scannable source order. |
| 3. Color | 4/4 | Neutral surfaces/local status cues follow the palette contract; contrast gate reports no AA failures. |
| 4. Typography | 4/4 | Retained explanations use the 14px body role and body font, with a computed-font assertion in the exact-source status lane. |
| 5. Spacing | 4/4 | The retained evidence stacks at 390px and keeps the full-width reading measure without disrupting the desktop two-column layout. |
| 6. Experience Design | 4/4 | Status semantics and recovery context remain explicit; retained evidence is now scannable on mobile. |

**Overall: 24/24**

No remaining actionable UI finding was identified against the approved contract and documented later responsive resolution. No product source was changed during this re-audit.

## Priority Fixes

No remaining priority fix. The narrow retained-evidence layout and its body-font treatment are both resolved and asserted by the exact-source status lane.

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- The no-schema state now says “No search schemas configured” and tells the host developer to configure the schema allowlist ([control_room_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex#L132), [ops_ui.ex](../../../scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex#L815)).
- Search-health failures retain a concise retry instruction and sanitized cause ([posture_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex#L441), `fetch_error_copy/1` at line 567). Browser proof asserts generic exception details do not leak.
- Operational absence states distinguish “No success observed,” “Queue not used,” and unavailable retained evidence. Clipboard feedback says “Timestamp copied” only on success and gives manual-copy guidance on failure. These match the approved Copywriting Contract.

### Pillar 2: Visuals (4/4)

- Mounted and standalone screenshots show a consistent Search health focal point, neutral summary/metric/schema grouping, explicit local severity cues, readable schema identifiers, and visible failed-work navigation. Mobile 320/390 and the 1279/1280 rail transition remain within the viewport.
- The updated mounted and standalone 390px unavailable-state screenshots show backend and queue retention evidence stacked at full reading width. Both keep the source label, “No success observed,” and retained-check explanation together without horizontal overflow. The E2E spec checks two columns on desktop and one at 390px.
- **Documented compact-header exception:** Phase 175 recorded that visible theme labels and the command control clipped at 320/390px, then hid theme labels through 420px while retaining button accessible names and 44px targets. This remains a divergence from Phase 173's visible-label preference, but it is an explicit later responsive resolution with its own rendered proof; it is not raised as a new defect here.

### Pillar 3: Color (4/4)

- Light and dark captures use flat neutral page/shell floors and neutral resting cards. Violet stays on navigation selection and links; warning/failure meaning uses localized icon/value/badge cues and explicit text rather than a whole-card fill.
- `make -C examples/scrypath_ecommerce contrast` passed with zero AA failures and 43 AAA advisories on the audited candidate source. The advisories do not include an AA defect.

### Pillar 4: Typography (4/4)

- Page and section headings preserve the existing hierarchy. Essential explanatory and failure text uses the 14px body role; operational age and copy actions also use the body/action role. Exact timestamps and identifiers retain the technical monospace role.
- `.ops-time__retained` uses `var(--font-sans)` and the 14px body role ([app.css](../../../scrypath_ops/assets/css/app.css#L1019)). The exact-source status E2E asserts its computed `font-family` equals the page body font, and both new mobile screenshots show the explanatory copy in the proportional body face. Monospace remains on identifiers and exact timestamp evidence as intended.

### Pillar 5: Spacing (4/4)

- Main Search health sections and schema cards keep the contract's named spacing tokens and 24px schema rhythm; action targets remain usable in the reviewed mobile and desktop captures. The earlier fractional status-cue offset is now the named `ops-1` token.
- The retained-state grid now uses one column at viewport widths of 480px and below and keeps two columns on desktop ([app.css](../../../scrypath_ops/assets/css/app.css#L1759)). The exact-source browser assertion verifies the desktop/mobile column counts, and the new 390px screenshots confirm the full-width source explanations.

### Pillar 6: Experience Design (4/4)

- The source-backed browser lanes exercise mounted and standalone status, time, shell, and clipboard paths, including error/unknown states, theme/storage behavior, keyboard/touch disclosure and copy, clipboard failure feedback, and responsive breakpoints. Screenshot evidence confirms the copy fixes: the exact ISO and UTC explanation remain selectable and legible on mobile.
- The unavailable state retains the prior evidence and labels its observation boundary while keeping retry guidance in the summary. The reflow improves mobile scanability without changing source meaning or dropping either data group.
- Interaction capture was off; no interaction screenshot is claimed. Interaction behavior above is supported by the recorded Playwright receipts and source-derived assertions.

## Registry Safety

`components.json` is absent and the approved UI spec sets `shadcn_initialized: false`; no third-party component registry is used. Registry audit skipped.

## Files Audited

- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md`
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-CONTEXT.md`
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-01-PLAN.md` through `173-04-PLAN.md`
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-01-SUMMARY.md` through `173-04-SUMMARY.md`
- `.planning/phases/175-repair-and-verification/175-03-SUMMARY.md` (compact-header exception)
- `scrypath_ops/assets/css/app.css` and `scrypath_ops/priv/static/assets/css/app.css`
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex`
- `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`
- `examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts`
- `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts`
- `examples/scrypath_ecommerce/e2e/phase173_time.spec.ts`
- `examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts`
- Current mounted and standalone screenshots under `/private/tmp/scrypath-phase173-candidate-artifacts/scrypath-phase173/`.
