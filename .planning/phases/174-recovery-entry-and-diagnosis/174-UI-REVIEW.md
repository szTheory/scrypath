# Phase 174 — UI Review

**Audited:** 2026-10-07  
**Baseline:** Approved [174-UI-SPEC.md](174-UI-SPEC.md), including its 30 resolved UI criteria  
**Screenshots:** 48 final captures inspected from `examples/scrypath_ecommerce/test-results/phase174-parent-final/phase174-captures/` (mounted and standalone; Control Room, Search health, Failed sync work; 1440, 1280, 1279, and 390px; light and dark).  
**Interaction captures:** off (workflow.ui_interaction_capture is false)

The review used the actual final capture matrix plus the native final browser report (`174-FINAL-BROWSER.xml`: 11/11, no failures/errors/skips), source and CSS. Visual observations below come from screenshots/source; behavior observations come from the recorded executable browser and test results. The code at this audit checkout is branch `gsd/phase-174-recovery-entry-and-diagnosis`, HEAD `211e8b7`; the reported product source is `d4395f2`, with fixture/spec follow-up `024a450`. This is local evidence, not exact-SHA hosted attestation. Original pre-Phase-174 screenshots are missing; the archived “before” set is from `54c623e` immediately before the 44px correction and is not used as a full-phase baseline.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Page-specific actions and recovery states use contract language; no generic primary CTA found. |
| 2. Visuals | 3/4 | Clear hierarchy and usable reflow; the compact shell breaks canonical schema names mid-word. |
| 3. Color | 4/4 | Neutral surfaces dominate, violet is reserved for interaction, and final contrast run reports 0 AA failures. |
| 4. Typography | 4/4 | Contract type roles and readable 14px essential copy are retained across captured widths. |
| 5. Spacing | 4/4 | Existing spacing/control tokens hold; measured 40px standard and 44px prominent targets meet contract. |
| 6. Experience Design | 4/4 | Required recovery, invalid/retained/error/loading and focus states have passing native browser and Ops evidence. |

**Overall: 23/24**

## Top 3 Priority Fixes

1. **Avoid mid-word breaks for the selected schema in the desktop rail and mobile recovery target strip** — operators must visually reassemble canonical identifiers — let the rail use a readable truncation with an accessible full value, and allow the mobile strip to wrap at module separators before falling back to arbitrary breaks. Warning; visual polish, no navigation or recovery failure observed.
2. **Keep compact entrypoint-specific recovery copy under periodic visual review** — mounted and standalone fixture copy is intentionally different, and narrow screens make the diagnosis page long — retain the current source-qualified copy while checking future edits against the same 390px matrix. Warning; no contract defect found in the captured states.
3. **Review the low-priority AAA contrast advisories when changing theme tokens** — AA is clean, while `make contrast` records 35 advisory pairs below AAA — inspect the actual composed pairs before changing shared tokens. Warning; AA floors pass and this is not a ship blocker.

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- The Control Room uses the exact “Review Search health” primary recovery entry and labels it as a read-only next step in [control_room_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex:179). The page leads with observed fleet state and explicitly directs operators to queue triage rather than declaring green.
- Search health labels per-schema evidence and next checks; unavailable, retained and “No success observed” source states remain distinguishable in [posture_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex:671).
- Failed work uses “No failed sync work for this schema”, “Retry queue job”, source-specific unavailable recovery explanations, and the accepted-but-not-terminal receipt wording in [failed_sync_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex:763). The final native sequence covers retained/error/unknown/no-success/empty/long-value and exact delete scope.
- Generic “Submit”, “Click Here”, and “OK” primary patterns are absent from the three audited LiveViews. “Cancel” occurs only on the explicitly labeled delete-confirmation control.
- No copywriting blocker or required contract copy deviation found.

### Pillar 2: Visuals (3/4)

- Final desktop captures show a clear focal progression: Control Room verdict and single health entry; Search health summary then neutral per-schema cards; Failed sync work row with identity, evidence, eligibility and action before collapsed Diagnostics. The failed-work screen does not bury the action beneath diagnostics.
- At 1280px the existing 17rem rail is present; at 1279px and 390px the mobile header/drawer layout is used. Cards and backend/queue groups stack at narrow widths; screenshots show no horizontal document overflow. Focus/reorder behavior is verified by native browser case “real Search health refresh reorders records without moving focus to a different action.”
- **WARNING:** at 1440px the persistent rail renders the selected `ScrypathEcommerce.Catalog.Product` as `...Pro` / `duct` across lines; the 390px target strip similarly breaks canonical strings at arbitrary character boundaries. `layouts.ex` uses `break-all` for the shell code and the mobile strip has the same narrow available width. The value is technically present but slower to scan. Prefer wrapping at module separators and preserve an accessible full value if the rail is truncated.
- The contrast between card surfaces and page background is restrained and the primary/selected target is visually obvious. No icon-only action without an accessible label was found in the audited views; shell icon controls carry aria-labels in [layouts.ex](../../../scrypath_ops/lib/scrypath_ops_web/components/layouts.ex:77).

### Pillar 3: Color (4/4)

- `app.css` defines the contract neutral floors and accent tokens: light `#f7f6f3` / white / `#efeee9` and violet `#5b4ad1`; dark `#111419` / `#191e25` / `#222831` and `#aaa0ff` (lines 32–100). Screenshots show the neutral page/surfaces dominate while violet marks current navigation, actual links, primary retry, theme selection and focus.
- Warning and failure tones are local, paired with readable text (“Degraded”, “transport”, “failed”) and not used for neutral zero/unavailable values. The Control Room indicator and Search health source states remain text-labeled.
- The final `make contrast` evidence in `174-08-SUMMARY.md` and `174-VALIDATION.md` reports **0 AA failures / 35 AAA advisory pairs**. AAA findings remain recommendations and do not lower the AA-based pillar score.
- There is no shadcn `components.json`; the approved Registry Safety table lists no third-party registry entries. Registry scan is not applicable.
- No color blocker found.

### Pillar 4: Typography (4/4)

- `app.css` defines the inherited 11/12px metadata exceptions, 14px body/action, 16px subsection, 18px section and 24px page roles at lines 188–203. The audited views use these `ops-*` semantic utilities rather than an uncontrolled set of Tailwind sizes.
- Full schema/index/work identities use the existing monospace stack, while body explanations and failure reasons remain sans serif. The browser evidence asserts essential text at 14px and full identifiers without clipping or horizontal page overflow.
- Compact metadata is small but remains limited to labels/timestamps rather than the primary reason, eligibility, or CTA. The arbitrary line breaks noted under Visuals affect word grouping, not font size or clipping.
- No typography blocker found.

### Pillar 5: Spacing (4/4)

- The CSS spacing tokens preserve the approved 4/8/12/16/20/24/32/48/64px scale with documented 6px internal-field exception. The three LiveViews primarily use `ops-*` spacing utilities and the component CSS; no arbitrary pixel/rem spacing class was found in their rendered markup.
- Captures retain deliberate breathing room between verdict, next checks and schema/work records. At 390px the groups stack without squeezing action text; the modal and long-content cases are covered by native browser evidence.
- CSS control tokens are 40px standard and 44px prominent. Native browser assertions measured the Control Room “Review Search health” action at 44px after the in-phase correction; standard controls meet 40px. Tap targets are confirmed by the geometry cases.
- No spacing blocker found.

### Pillar 6: Experience Design (4/4)

- Required interaction behavior is evidenced by `174-FINAL-BROWSER.xml`: **11 Chromium cases passed, 0 failures, 0 skipped**. It covers selected A while B is worse, actual mounted recovery and scoped retry, standalone real Gating interruption/return without automatic replay, invalid target, history, palette destinations after selector patch, mobile drawer, equal numeric source IDs, retained/error/unknown/no-success/empty/long-value/delete-scope states, and focus retention after refresh reorder.
- The final evidence records Ops `272 tests + 2 doctests / 0 failures`, core `661 tests + 4 properties / 0 failures`, and contrast `0 AA / 35 AAA`. The full phase native browser result supersedes earlier incomplete runs. Refresh busy state is based on a delayed real source response and retry pending state holds the real WebSocket response; neither receipt is inferred from event dispatch.
- Source checks confirm current selection and inspection gates, selected-schema invalidation, explicit unavailable state, disabled/no-action guards, accepted replacement distinct from terminal success, and exact delete-scope confirmation. The runner and phase security summary report test-only fixture routes and cleanup of the disposable browser stack.
- Trust boundary: the standalone case reaches the actual Gating return path but does not perform or claim host login/sudo approval. These results are local executable evidence; they do not establish exact-SHA hosted checks, global dependency safety, broad advisory ecommerce E2E status, human approval, phase completion, or release readiness.
- No required behavior blocker found. Interaction capture status is **off**; interaction claims above derive from the supplied native test report and source, never from this audit's static captures.

## Files Audited

- `.planning/phases/174-recovery-entry-and-diagnosis/174-UI-SPEC.md`, `174-CONTEXT.md`, all eight `174-01`–`174-08` PLAN/SUMMARY files, `174-SOURCE-AUDIT.md`, `174-VALIDATION.md`, `174-SECURITY.md`, `174-FINAL-BROWSER.xml`, `174-FINAL-EVIDENCE.json`, `174-ui-elements.json`, `174-ui-resolutions.json`, and `174-ui-coverage.json`.
- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex`, `posture_live.ex`, `failed_sync_live.ex`, `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`, and `scrypath_ops/assets/css/app.css`.
- Final mounted and standalone capture matrix under `examples/scrypath_ecommerce/test-results/phase174-parent-final/phase174-captures/`; representative desktop light/dark and mobile light/dark images inspected across Control Room, Search health and Failed sync work.
- `AGENTS.md`, `scrypath_ops/AGENTS.md`, and the native `gsd-ui-auditor` role bundle.
