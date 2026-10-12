# Phase 173 — UI Review

**Audited:** 2026-10-10  
**Source:** `/Users/jon/projects/scrypath/.claude/worktrees/agent-p173-01-retry-1791665855` at `5d8d7e4bdd415538d2af8f2896d8ecdbd1e3b7a0`  
**Baseline:** Approved [173-UI-SPEC.md](173-UI-SPEC.md), `173-CONTEXT.md`, four phase plans and four execution summaries  
**Screenshots:** Captured and reviewed from the exact source SHA: status and copy sets listed under Files Audited  
**Interaction captures:** No separate post-interaction screenshot set. Exact-SHA Playwright proof reports status 6/6 and timestamp copy 10/10 across mounted and standalone entrypoints; those interaction outcomes are test evidence, not screenshot claims.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Search health actions, state labels, timestamp feedback, and recovery copy match the approved contract. |
| 2. Visuals | 4/4 | Neutral grouping keeps the verdict and affected schema legible across desktop and mobile captures. |
| 3. Color | 4/4 | Healthy badges and the Search health success icon are neutral; warning and failure color stays local. |
| 4. Typography | 4/4 | Operational age and Copy timestamp use the specified 14px body/action role; compact type is limited to supporting metadata. |
| 5. Spacing | 4/4 | The reviewed layouts wrap without page overflow; verification asserts the 24px schema rhythm and 40px action targets. |
| 6. Experience Design | 4/4 | Theme, status, operational time, and clipboard flows have current-source coverage in both entrypoints. |

**Overall: 24/24**

## Top 3 Priority Fixes

No priority fixes remain for the audited Phase 173 scope. The three findings in the previous review are resolved at this SHA:

1. **Healthy backend and queue badges:** now neutral; warning and failure badges remain semantic and localized.
2. **Operational age and copy typography:** now use the 14px body/action role.
3. **Healthy Search health verdict icon:** now neutral-scoped without changing success treatment on other Ops verdicts.

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- Visible controls use specific labels, including “Refresh”, “Copy timestamp”, and “Exact timestamp”. Timestamp success/failure feedback uses the contract’s exact copy. The operational copy button and polite status region are rendered in [ops_ui.ex](../../../scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1237).
- Search health preserves distinct wording for unavailable observations, no observed success, missing success time, and an unused queue. The current scenarios are covered in [phase173_status_actions.spec.ts](../../../examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts:45) and [phase173_copy.spec.ts](../../../examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts:169).
- No generic “Submit”, “OK”, or equivalent action label was found on the audited Search health path.

### Pillar 2: Visuals (4/4)

- Exact-SHA light desktop and dark mobile captures show a clear Search health verdict, summary metrics, next checks, and per-schema evidence in the expected order. Failure badges remain beside the affected schema; the neutral grouping does not obscure degraded labels or recovery links.
- The reviewed 390px captures preserve theme labels and wrap the long schema identifier, ISO value, and UTC explanation. The 1440px capture keeps backend and queue details side by side. No clipping or horizontal overflow is visible.
- The earlier healthy-badge competition finding is resolved: the current healthy copy capture shows neutral “backend clear” and “queue observed” badges.

### Pillar 3: Color (4/4)

- **Resolved from the previous audit:** `backend_badge_kind/1` now returns `:neutral` when no backend failures exist; the ordinary observed queue state also returns `:neutral` ([posture_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex:629)). The current screenshots show neutral healthy badges. Warning and error variants remain available for actual unavailable, retrying, and failed states.
- **Resolved from the previous audit:** the Search health success icon is scoped to `var(--color-base-content)` by `.ops-posture-verdict .ops-verdict__icon--success`, while generic Ops success verdicts retain their existing treatment ([app.css](../../../scrypath_ops/assets/css/app.css:607)). The status browser spec asserts the Search health icon matches its headline color and healthy badges are not success-colored ([phase173_status_actions.spec.ts](../../../examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts:51)).
- Neutral surfaces dominate the page; violet appears on selection, links, and copy actions, and warning/error hues stay with local status cues. The phase contrast gate is recorded as passing with zero AA failures in [173-04-SUMMARY.md](173-04-SUMMARY.md).

### Pillar 4: Typography (4/4)

- **Resolved from the previous audit:** `.ops-time--operational` now uses `var(--text-ops-body)` and `.ops-time__copy` uses the body size with weight 600 ([app.css](../../../scrypath_ops/assets/css/app.css:918), [copy action rule](../../../scrypath_ops/assets/css/app.css:972)). This matches the UI-SPEC’s 14px operational age/body-action role.
- The exact timestamp and optional supporting labels retain the contract’s compact technical/metadata roles. Essential state, copy action, and explanation remain body sized and wrap in the mobile captures.
- The copy E2E asserts both `ageFontSize` and `button.fontSize` are 14px and the copy action weight is 600 ([phase173_copy.spec.ts](../../../examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts:130)).

### Pillar 5: Spacing (4/4)

- The UI-SPEC’s 24px schema-record rhythm and standard 40px action target are preserved. Phase status proof covers 390, 1279, 1280, and 1440px in light and dark; the copy proof asserts the target is at least 40px and exact evidence fits its container ([phase173_status_actions.spec.ts](../../../examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts:128), [phase173_copy.spec.ts](../../../examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts:138)).
- Reviewed mobile and desktop screenshots show the metric grid reflowing, schema groups stacking at narrow widths, and exact ISO text wrapping without document overflow.

### Pillar 6: Experience Design (4/4)

- The phase’s exact-SHA status matrix passed 6/6 cases and timestamp-copy matrix passed 10/10 cases across mounted and standalone entrypoints. The updated status assertions cover neutral healthy treatment, explicit failed/unavailable/unknown/unused/empty/partial states, and server-driven refresh eligibility ([phase173_status_actions.spec.ts](../../../examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts:45)).
- Timestamp-copy coverage checks exact validated ISO payload, user activation, success only after promise resolution, persistent denial/unavailable guidance, manual selection, focus retention, repeated success timing, keyboard and touch use, and both entrypoints ([phase173_copy.spec.ts](../../../examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts:47)).
- No remaining blocker or warning was found in this Phase 173 scope. `needs_human_review: false`; the approved contract and exact-SHA rendered/test evidence leave no unresolved subjective item.

## Files Audited

- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md`
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-CONTEXT.md`
- `173-01-PLAN.md` through `173-04-PLAN.md` and `173-01-SUMMARY.md` through `173-04-SUMMARY.md`
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex`
- `scrypath_ops/assets/css/app.css`
- `scrypath_ops/assets/js/ops_hooks.js`, `scrypath_ops/assets/js/app.js`, and `examples/scrypath_ecommerce/assets/js/app.js`
- `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`
- `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts` and `phase173_copy.spec.ts`
- Exact-SHA status screenshots: `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-phase173/scrypath_phase173_status_5d8d7e4b_47751/screenshots/`
- Exact-SHA timestamp-copy screenshots: `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-phase173/scrypath_phase173_copy_5d8d7e4b_51739/screenshots/`
- Registry audit skipped: `components.json` is absent; the approved UI-SPEC also states that shadcn and third-party registries are not in use.
