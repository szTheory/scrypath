# Phase 175 — UI Review

**Audited / rechecked:** 2026-10-10 at checkout `209f3cb78e15cfc9701b2af07901db20d65aad59`; UI source and captures are bound to `ce60384aa95235376fae8fe4381005c36ece3725`.
**Baseline:** Approved `175-UI-SPEC.md` and the ScrypathOps design tokens
**Screenshots:** Captured and inspected from retained evidence at exact source `ce60384aa95235376fae8fe4381005c36ece3725`: mounted before/after states at 390, 768, and 1440px in Light and Dark, plus System Light/Dark with reduced motion. Evidence is under `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/final-ui-browser/test-results/phase175-captures/`.
**Interaction captures:** off (`interaction_capture:false`). These are existing project Playwright captures, not new captures from this audit's interaction-capture workflow.

This is a UI assessment, not phase completion or risk acceptance. The supplied final evidence records 334 Ops tests plus 2 doctests and 7 browser cases with no failures/skips; HostedCI has not yet been dispatched, and the security record retains one below-threshold host-authorization advisory.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Visible refresh and terminal cancellation copy now match the approved contract. |
| 2. Visuals | 3/4 | Responsive hierarchy holds; the readiness notice has a sharper outline than neighboring panels. |
| 3. Color | 4/4 | Neutral readiness now omits semantic tone classes; Light and Dark captures show no green/blue status fill. |
| 4. Typography | 4/4 | The page now uses only the specified regular/semibold weights and shared Ops size tokens; technical values remain selectable and wrap. |
| 5. Spacing | 4/4 | Direct-child margins were removed and existing shell/page rhythm is used. |
| 6. Experience Design | 4/4 | Seven browser cases pass; focus return, exact UID selection/Ctrl+C, and grouped state coverage are evidenced. OS clipboard readback is explicitly unavailable and not claimed. |

**Overall: 23/24**

---

## Top 3 Priority Fixes

1. **Align the readiness notice outline with neighboring neutral panels.** It now has no semantic tint, but the neutral `ops_status` surface lacks an explicit neutral border token and appears more sharply outlined than the surrounding panels.
2. **Add a visual artifact for the long-text stress state if that state needs pixel-level review.** The current matrix validates a synthetic long identifier as a DOM-only 390px stress input; its geometry is covered, but the stressed composition is not captured.
3. **Preserve the evidence boundary in future closeout notes.** The UID is selected and Ctrl+C is invoked, but clipboard readback is unavailable; the retained screenshot matrix is not a full state × theme × viewport cross-product.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- The visible sync refresh label reads “Refresh sync and queue status” ([sync_drift_live.ex](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1517)); terminal copy uses “Index swap canceled” and “was canceled” per contract (lines 1212 and 1742).
- The page title, subtitle, “No pending or failed sync work found,” `Index configuration`, “Not checked,” and promotion outcome copy are specific and avoid claiming document freshness from configuration agreement or task completion. See [sync_drift_live.ex](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1428), lines 1526–1529, 1603–1617, and 1714–1758.
- The retained browser evidence reports seven cases, no failures/skips/retries. The task UID is rendered through the shared selectable `ops_inline_code` helper; the browser annotation records selecting it and Ctrl+C, while explicitly noting OS clipboard readback was unavailable on the HTTP test origin. Existing Phase 173 timestamp-copy browser tests inject and verify resolved, rejected, and unavailable `writeText` behavior with feedback; they do not claim an OS clipboard readback.

### Pillar 2: Visuals (3/4)

- The primary page hierarchy is easy to scan in the inspected 390, 768, and 1440 captures: schema scope, sync status, configuration, then advanced promotion. Narrow layout stacks panels and wraps actions; desktop uses the existing Ops shell.
- The promotion task UID and terminal status render in a separate panel before the advanced disclosure, keeping active/terminal information discoverable if the disclosure is closed. The exact task identity markup is at [sync_drift_live.ex](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1709).
- **WARNING — stronger outline:** The final captures show a neutral, unfilled readiness notice, fixing the prior blue fallback. Its border appears darker/brighter than adjacent panel borders because neutral skips tone classes while `.ops-notice-surface` sets border width/style but no neutral border color. A shared `border-base-300` or Ops neutral border token would match surrounding panels more closely.
- A no-schema/empty screen, overflow adversarial text, comparison mismatch table, and modal confirmation were not all visible in the supplied static compositions; those states are supported by browser assertions and source, not visual screenshots. The synthetic long-text case is a DOM stress input, not a screenshot of the full confirmation/modal.

### Pillar 3: Color (4/4)

- The final implementation explicitly allows `:neutral` on `ops_status/1` and omits `tone_class/1` for that value ([ops_ui.ex](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:346)); inspected Light and Dark captures show the readiness surface unfilled. Other colors follow the UI-SPEC's semantic roles.
- **Minor visual refinement:** `.ops-notice-surface` has a 1px border but no explicit neutral border color ([app.css](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/assets/css/app.css:538)); the no-tone surface therefore takes a high-contrast current-color border. A shared neutral border token would reduce the nested card's visual weight.
- System appearance and reduced-motion captures are present in the retained XML manifest.
- Registry audit: `components.json` is absent; the approved UI-SPEC lists no shadcn or third-party component registries. Registry scanning is not applicable.

### Pillar 4: Typography (4/4)

- The page uses the existing Ops roles (`text-ops-sm`, `text-ops-body`, `text-ops-h2/h3`) and semibold headings. The corrected table row labels now use `font-semibold`; the page uses the specified regular/semibold weights and shared size tokens without local font-size overrides.
- Exact values remain selectable monospace text. Breaking identifiers at narrow widths is permitted by the contract’s full-identity wrapping rule.

### Pillar 5: Spacing (4/4)

- Direct children now rely on the shell's existing page rhythm, and former top-level `mt-4` utilities were removed. Nested groups continue to use existing `space-y-2/3`, `gap-1/2`, and `p-4` patterns; no arbitrary pixel/rem spacing values were found in the audited page markup.

### Pillar 6: Experience Design (4/4)

- Key interaction and safety behavior is supported by rendered LiveView tests: non-first and invalid schema selection (tests at [sync_drift_live_test.exs](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:156), 192); separate partial/error observations (207, 216); comparison match/difference behavior (270, 286); exact confirmation/cancel/rechecks/authorization return (499, 575, 597, 645); exact retained UID polling and timeout without another swap (684, 765); and stale runtime/context callback rejection (790, 1030). The standalone fixture has explicit state and unavailable-scope cases at [phase175_fixture_live_test.exs](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/test/scrypath_ops_web/live/phase175_fixture_live_test.exs:49).
- The current retained browser XML at the exact source SHA records seven passing cases, including mounted exact-pair promotion, retry upsert/delete effect verification, changed-prerequisite rejection, standalone sudo return, and exact-UID read-only recheck. It covers Light/Dark at 390/768/1440, System/reduced-motion at desktop, and selection/Ctrl+C for the exact UID. Clipboard readback is explicitly unavailable; the UID is selectable plain text, while the shared timestamp copy control has existing success/failure/unavailable feedback assertions in `phase173_copy.spec.ts:82–109`, `145–160`, and `217–254`.
- The Phase 175 real-browser test at [phase175_repair.spec.ts](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/examples/scrypath_ecommerce/e2e/phase175_repair.spec.ts:98) asserts the dialog starts focused on Cancel, cycles through close/cancel/confirm, closes on Escape, and returns focus to the trigger. My previous audit incorrectly described this focus evidence as absent.
- The retained standalone UI matrix exercises the eight named groups (empty, loading, error, populated, partial, overflow, zero-one-many, long-text), including nine task-state scenarios. It reports long text as a DOM-only stress input and uses the standalone production LiveView. This is useful grouped evidence but does not prove every element/category pair independently.
- The UI-SPEC's eight matrix rows list **68 pairs**, because overflow includes E1 through E10. The final review maps E6 overflow to the full schema/live/target confirmation values. The grouped coverage is not a full state × theme × viewport cross-product.
- The promotion disclosure is native `<details>/<summary>` and uses `JS.ignore_attributes("open")`; the confirmation actions use the shared modal. Focus style is defined globally as a 2px primary outline with 2px offset in [app.css](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/assets/css/app.css:219). Modal keyboard cycle/Escape/focus return are explicitly asserted as above. The long-text matrix input is DOM-only, so its visual wrapping is not independently shown in a capture.

### Element/category evidence map (all pairs enumerated by the UI-SPEC)

The table below maps all 68 listed pairs to concrete rendered surfaces and retained evidence. Grouped evidence does not imply a full state × theme × viewport cross-product.

| Category | Element/category pairs | Implementation and evidence |
|---|---|---|
| Empty | E1, E2, E3, E4, E5, E6, E7, E10 | E1 no-schema/unavailable rendering at `sync_drift_live.ex:1497–1508`, rendered schema tests `sync_drift_live_test.exs:192`; E2 healthy summary at `:1526–1529`, test `:207`; E3 conditional retry card at `:1445–1475`, expired handoff test `:433`; E4 unrun copy `:1632–1638`; E5 eligibility reason/action `:1802–1815`; E6 modal omitted until confirmed `:1835–1873`; E7 task panel conditional `:1709–1712`; E10 diagnostics conditional `:1596–1598`, `:1647–1649`. Browser matrix reports empty group, but does not independently exercise each element’s empty state. |
| Loading | E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 | E1 scope selection at `:1436–1442`; E2 refresh control at `:1517–1523`; E3 refresh at `:1451–1459`; E4 loading/disabled state at `:1611–1629`; E5 disclosure at `:1782–1797`; E6 submit/in-flight behavior at `:1843–1870`; E7 exact task check at `:1767–1779`; E8 shared copy helper `ops_ui.ex:1289–1337`; E9 handoff at `:1820–1832`; E10 native diagnostics disclosures at `:1596–1598`. Rendered submit/loading cases include `sync_drift_live_test.exs:597`, `:684`, `:705`; grouped matrix lists loading. |
| Error | E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 | E1 unavailable scope `sync_drift_live.ex:1501–1508` / test `sync_drift_live_test.exs:192`; E2/E4 independent errors `:1589–1599`, `:1640–1650` / tests `:216`, `:236`; E3 unknown handoff `:1460–1475` / test `:433`; E5 blocker branch `:1802–1815`; E6 changed prerequisites/cancel `:1835–1873` / tests `:575`, `:597`; E7 unconfirmed state `:1753–1779` / tests `:733`, `:765`; E8 copy helper fallback at `ops_ui.ex:1290–1337`, but browser clipboard readback is unavailable; E9 selection/sudo return tests `sync_drift_live_test.exs:192`, `:645`; E10 raw diagnostics disclosure `sync_drift_live.ex:1596–1598`, `:1647–1649`. Grouped matrix reports error states. |
| Populated | E2, E3, E4, E5, E7, E10 | E2 populated status/evidence `sync_drift_live.ex:1526–1581`; E3 handoff evidence `:1476–1493`; E4 result/table `:1652–1705`; E5 eligibility and action `:1802–1818`; E7 task result/UID outside details `:1709–1779`; E10 conditional diagnostics/evidence. Browser XML reports accepted/running/succeeded/failed/cancelled promotion and recovery upsert/delete effect probes; matrix reports populated. |
| Partial | E1, E2, E3, E4, E5, E6, E7, E10 | E1 current selected allowlist rendered in selector `sync_drift_live.ex:1436–1442`; E2 incomplete/error summary `:1380–1398`, error test `sync_drift_live_test.exs:216`; E3 exact retry evidence `:1476–1493`; E4 independent configuration result `:1603–1657`; E5 eligibility derives current prerequisite reasons and renders at `:1802–1815`; E6 fresh gate before submit tests `:597`, `:622`; E7 state mapping `:1732–1779`, malformed/wrong UID test `:733`; E10 independent diagnostics `:1596–1598`, `:1647–1649`. Browser XML reports exact upsert/delete probes; it does not independently screenshot every partial case. |
| Overflow | E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 | E1 schema label `sync_drift_live.ex:1436–1442`; E2/E3 exact values `:1476–1493`, `:1557–1575`; E4 table uses shared `ops_signal_table` (`ops_ui.ex:182`) and code values at `sync_drift_live.ex:1682–1689`; E5 disclosure copy `:1791–1807`; E6 full schema/live/target modal values at `:1835–1859`; E7 identity `:1718–1729`; E8 inline code uses `break-all` at `ops_ui.ex:1461`; E9 handoff `:1820–1832`; E10 `ops_code_block` uses `whitespace-pre-wrap break-words` at `ops_ui.ex:1443`. Matrix’s synthetic long-text layout was DOM-only at 390px; retained mobile captures show normal names, not maximal long text. |
| Zero-one-many | E2, E3, E4, E5, E7, E10 | E2 count-aware summary helpers `sync_drift_live.ex:1360–1398`; E3 single retained recovery identity at `:1445–1493`; E4 mismatch count/table at `:1652–1705`; E5 blocker list/eligibility mapping at `:1180–1202`, `:1802–1815`; E7 one retained current UID at `:1709–1779`; E10 diagnostics are conditional at `:1596–1598`, `:1647–1649`. Grouped UI matrix includes zero-one-many, not every element scenario separately. |
| Long-text | E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 | E1 selector and E5/E6 exact schema in `sync_drift_live.ex:1436–1442`, `:1843–1855`; E2/E3/E7 exact IDs at `:1476–1493`, `:1718–1729`; E4 technical table values at `:1682–1689`; E8 shared inline code `ops_ui.ex:1461`; E9 handoff `sync_drift_live.ex:1820–1832`; E10 diagnostic block wrapping `ops_ui.ex:1443`. Browser matrix states the long-text case is a DOM-only stress input; no captured full confirmation with maximal identifiers is present. |

## Initial audit disposition (historical, superseded by this recheck)

The first review scored 16/24. At `fcf0e68`, the corrected score was 19/24: the sync label, direct-child spacing, and table weights had been corrected, and modal keyboard/focus coverage was documented. That intermediate review correctly identified a real blue info fallback after `:neutral` was first introduced. At final source `ce60384`, `ops_status/1` now explicitly permits neutral and skips semantic tone classes for it; terminal copy also matches “canceled.” The intermediate 19/24 disposition is superseded by the current 23/24 score. Earlier audit errors about the 68-pair denominator and missing focus assertions are retained here for traceability and corrected in the findings above.

## Files Audited

- `.planning/phases/175-repair-and-verification/175-01-PLAN.md` through `175-06-PLAN.md` and matching summaries
- `175-UI-SPEC.md`, `175-CONTEXT.md`, `175-EVIDENCE.md`, `175-VALIDATION.md`, `175-SECURITY.md`
- `AGENTS.md`, `CONTRIBUTING.md`
- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
- `scrypath_ops/assets/css/app.css`, `scrypath_ops/assets/css/DESIGN-TOKENS.md`
- `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`
- `scrypath_ops/test/scrypath_ops_web/live/phase175_fixture_live_test.exs`
- `examples/scrypath_ecommerce/e2e/phase175_repair.spec.ts`, `phase173_copy.spec.ts`, and `helpers/operator-ui.ts`
- Retained `final-ui-browser/test-results/phase175-repair.xml`, cleanup receipt, and 390/768/1440 Light/Dark/System captures at the exact source SHA above
