# Phase 175 — UI Review

**Audited:** 2026-10-10  
**Baseline:** Approved `175-UI-SPEC.md` and the ScrypathOps design tokens  
**Screenshots:** Captured and inspected from retained evidence at exact source `22089e9513a14d38a252e6dc59530b6d3698ef1d`: mounted before/after states at 390, 768, and 1440px in Light and Dark, plus System Light/Dark with reduced motion. Evidence is under `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/security-fix-final/test-results/phase175-captures/`. Port 8080 answered, but no fresh capture was made because the retained exact-source captures are sufficient and the task prohibits starting another runtime.  
**Interaction captures:** off (`interaction_capture:false`). The retained Playwright captures are existing project interaction evidence, not fresh captures from this audit's interaction-capture workflow.

This is a UI assessment, not phase completion or risk acceptance. The supplied validation records 334 Ops tests plus 2 doctests; exact-SHA HostedCI remains pending, and the security record retains one below-threshold host-authorization advisory.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Good operator-specific copy overall; visible sync refresh says “Refresh” while the contract names the action “Refresh sync and queue status.” |
| 2. Visuals | 3/4 | Clear hierarchy and responsive layout in retained captures; the promotion readiness treatment is more prominent and affirmative than the contract permits. |
| 3. Color | 2/4 | Light/Dark semantic themes hold, but “Ready for promotion” is rendered on a broad green success surface contrary to the color contract. |
| 4. Typography | 3/4 | Uses the four existing Ops size roles and wraps technical values; some long module names break mid-word on the 390px capture. |
| 5. Spacing | 3/4 | Existing panel and page rhythm is consistent; phase markup still uses raw `mt-4`/`mt-3` utilities where the spec asks to consume the Ops page rhythm without direct-child margins. |
| 6. Experience Design | 2/4 | Seven real browser cases and grouped state evidence cover key flows, but the spec’s claimed 68 element/category pairs enumerate to 67, and clipboard readback is explicitly unavailable. |

**Overall: 16/24**

---

## Top 3 Priority Fixes

1. **Remove success tint from promotion eligibility.** `Ready for promotion` currently uses `ops_status(kind: :success)`, which paints a green filled panel. Render this decision state neutrally and reserve semantic success tone for local cues, as required by the color contract.
2. **Reconcile the 68-pair UI contract.** The eight listed category rows enumerate to 67 element/category pairs. Add the missing pair or correct the asserted count, then keep evidence keyed to the corrected list.
3. **Align the sync refresh label and test copy behavior.** Make the visible and accessible label match `Refresh sync and queue status`; add an authorized-origin browser assertion for clipboard success/failure feedback and clipboard readback where the environment supports it.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING — refresh label mismatch:** [sync_drift_live.ex](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1517) passes `aria_label="Refresh sync and queue status"` to the shared refresh control. The retained screenshots show its visible label as only “Refresh.” The UI-SPEC Copywriting Contract calls for `Refresh sync and queue status`; expose that complete action label visibly, or revise the contract to explicitly permit a compact visible label with the full accessible name.
- The page title, subtitle, “No pending or failed sync work found,” `Index configuration`, “Not checked,” and promotion outcome copy are specific and avoid claiming document freshness from configuration agreement or task completion. See [sync_drift_live.ex](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1428), lines 1526–1529, 1603–1617, and 1714–1758.
- The exact selected schema can split within the final word at 390px (“Prod” / “uct” in the inspected capture). It remains readable and complete, but wrapping at a word boundary would improve scanning.
- The retained browser evidence reports seven cases, no failures/skips/retries. It explicitly reports clipboard readback unavailable on the HTTP test origin, so clipboard success cannot be claimed from that run.

### Pillar 2: Visuals (3/4)

- **WARNING — readiness hierarchy:** The primary page hierarchy is easy to scan in the inspected 390, 768, and 1440 captures: schema scope, sync status, configuration, then advanced promotion. Narrow layout stacks panels and wraps actions; desktop uses the existing Ops shell.
- The promotion task UID and terminal status render in a separate panel before the advanced disclosure, keeping active/terminal information discoverable if the disclosure is closed. The exact task identity markup is at [sync_drift_live.ex](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1709).
- The readiness state is an affirmative green panel inside Advanced, visible in the interaction capture after the operator opens it. This differs from the contract’s restrained, decision-focused treatment and competes with the primary action.
- A no-schema/empty screen, overflow adversarial text, comparison mismatch table, and modal confirmation were not all visible in the supplied static compositions; those states are supported by browser assertions and source, not visual screenshots. The synthetic long-text case is a DOM stress input, not a screenshot of the full confirmation/modal.

### Pillar 3: Color (2/4)

- **WARNING — explicit contract deviation:** [sync_drift_live.ex](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1802) maps `:eligible` to `:success`. The shared `ops_status` applies `.ops-tone-success`, whose rules set a green border and 10% green background in [app.css](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/assets/css/app.css:556). The capture confirms a large green readiness surface. The UI-SPEC says health tones should remain local and explicitly says promotion readiness must not receive success emphasis. Use a neutral surface with explicit text, or a small local cue.
- The inspected Light and Dark captures otherwise show the expected neutral page/panel hierarchy with violet reserved for selected navigation/control and focus. System appearance and reduced-motion captures are present in the retained XML manifest.
- Registry audit: `components.json` is absent; the approved UI-SPEC lists no shadcn or third-party component registries. Registry scanning is not applicable.

### Pillar 4: Typography (3/4)

- The page uses the existing Ops roles (`text-ops-sm`, `text-ops-body`, `text-ops-h2/h3`) and semibold headings. The token sheet defines four interface sizes and two intended weights. The page source uses regular/medium/semibold for copy, table row labels, and headings; `font-medium` is an extra weight beyond the UI-SPEC’s regular 400/semibold 600 rule where it appears in table labels at lines 1557, 1563, 1567, 1678, and 1682.
- Exact values use monospace and wrap-capable shared helpers; the narrow schema capture shows the module label splitting at a syllable boundary. Prefer `overflow-wrap:anywhere` only for unbroken identifiers and normal word wrapping for prose/module labels.
- The source stays with semantic Ops text tokens rather than introducing local font-size overrides.

### Pillar 5: Spacing (3/4)

- **WARNING — spacing contract drift:** The UI-SPEC says the shell already owns top-level `space-y-4` and directs this page not to add margins to direct page children. The template adds `mt-4` to the breadcrumb and most panels at lines 1433, 1435, 1445, 1712, and 1785. This is visually consistent in the captures, but contradicts the declared spacing ownership. Remove redundant top-level margins or amend the contract to describe the existing component pattern.
- The page otherwise uses existing panel components and compact `space-y-2/3`, `gap-1/2`, and `p-4` rhythms; no arbitrary pixel/rem spacing values were found in the audited page markup.

### Pillar 6: Experience Design (2/4)

- Key interaction and safety behavior is supported by rendered LiveView tests: non-first and invalid schema selection (tests at [sync_drift_live_test.exs](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:156), 192); separate partial/error observations (207, 216); comparison match/difference behavior (270, 286); exact confirmation/cancel/rechecks/authorization return (499, 575, 597, 645); exact retained UID polling and timeout without another swap (684, 765); and stale runtime/context callback rejection (790, 1030). The standalone fixture has explicit state and unavailable-scope cases at [phase175_fixture_live_test.exs](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/test/scrypath_ops_web/live/phase175_fixture_live_test.exs:49).
- The retained browser XML records seven passing cases, including mounted exact-pair promotion, retry upsert and delete effect verification, changed-prerequisite rejection, standalone sudo return, and exact-UID read-only recheck. It covers Light/Dark at 390/768/1440, System/reduced-motion at desktop, and keyboard selection of an exact value. It does not report clipboard readback, and it is not a full cross-product of every state, theme, and viewport.
- The retained standalone UI matrix exercises the eight named groups (empty, loading, error, populated, partial, overflow, zero-one-many, long-text), including nine task-state scenarios. It reports long text as a DOM-only stress input and uses the standalone production LiveView. This is useful grouped evidence but does not prove every element/category pair independently.
- **WARNING — coverage denominator mismatch:** `175-UI-SPEC.md` claims 68 explicit criteria at line 171. Counting the element lists in its eight matrix rows (lines 192–199) yields 67 pairs: 8 empty + 10 loading + 10 error + 6 populated + 8 partial + 9 overflow + 6 zero-one-many + 10 long-text. That leaves one asserted criterion without an enumerated pair. Resolve the count before treating the matrix as complete.
- The promotion disclosure is native `<details>/<summary>` and uses `JS.ignore_attributes("open")`; the confirmation actions use the shared modal. Focus style is defined globally as a 2px primary outline with 2px offset in [app.css](/private/tmp/scrypath-phase173-20261006-155750/phase174-execution/scrypath_ops/assets/css/app.css:219). A complete keyboard/focus-return and clipboard-feedback visual/browser result is not present in the retained seven-case XML.

### Element/category evidence map (all pairs enumerated by the UI-SPEC)

The table below maps each listed pair to concrete rendered surfaces and retained evidence. It intentionally preserves the discrepancy: these rows enumerate 67, although the UI-SPEC asserts 68.

| Category | Element/category pairs | Implementation and evidence |
|---|---|---|
| Empty | E1, E2, E3, E4, E5, E6, E7, E10 | E1 no-schema/unavailable rendering at `sync_drift_live.ex:1497–1508`, rendered schema tests `sync_drift_live_test.exs:192`; E2 healthy summary at `:1526–1529`, test `:207`; E3 conditional retry card at `:1445–1475`, expired handoff test `:433`; E4 unrun copy `:1632–1638`; E5 eligibility reason/action `:1802–1815`; E6 modal omitted until confirmed `:1835–1873`; E7 task panel conditional `:1709–1712`; E10 diagnostics conditional `:1596–1598`, `:1647–1649`. Browser matrix reports empty group, but does not independently exercise each element’s empty state. |
| Loading | E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 | E1 scope selection at `:1436–1442`; E2 refresh control at `:1517–1523`; E3 refresh at `:1451–1459`; E4 loading/disabled state at `:1611–1629`; E5 disclosure at `:1782–1797`; E6 submit/in-flight behavior at `:1843–1870`; E7 exact task check at `:1767–1779`; E8 shared copy helper `ops_ui.ex:1289–1337`; E9 handoff at `:1820–1832`; E10 native diagnostics disclosures at `:1596–1598`. Rendered submit/loading cases include `sync_drift_live_test.exs:597`, `:684`, `:705`; grouped matrix lists loading. |
| Error | E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 | E1 unavailable scope `sync_drift_live.ex:1501–1508` / test `sync_drift_live_test.exs:192`; E2/E4 independent errors `:1589–1599`, `:1640–1650` / tests `:216`, `:236`; E3 unknown handoff `:1460–1475` / test `:433`; E5 blocker branch `:1802–1815`; E6 changed prerequisites/cancel `:1835–1873` / tests `:575`, `:597`; E7 unconfirmed state `:1753–1779` / tests `:733`, `:765`; E8 copy helper fallback at `ops_ui.ex:1290–1337`, but browser clipboard readback is unavailable; E9 selection/sudo return tests `sync_drift_live_test.exs:192`, `:645`; E10 raw diagnostics disclosure `sync_drift_live.ex:1596–1598`, `:1647–1649`. Grouped matrix reports error states. |
| Populated | E2, E3, E4, E5, E7, E10 | E2 populated status/evidence `sync_drift_live.ex:1526–1581`; E3 handoff evidence `:1476–1493`; E4 result/table `:1652–1705`; E5 eligibility and action `:1802–1818`; E7 task result/UID outside details `:1709–1779`; E10 conditional diagnostics/evidence. Browser XML reports accepted/running/succeeded/failed/cancelled promotion and recovery upsert/delete effect probes; matrix reports populated. |
| Partial | E1, E2, E3, E4, E5, E6, E7, E10 | E1 current selected allowlist rendered in selector `sync_drift_live.ex:1436–1442`; E2 incomplete/error summary `:1380–1398`, error test `sync_drift_live_test.exs:216`; E3 exact retry evidence `:1476–1493`; E4 independent configuration result `:1603–1657`; E5 eligibility derives current prerequisite reasons and renders at `:1802–1815`; E6 fresh gate before submit tests `:597`, `:622`; E7 state mapping `:1732–1779`, malformed/wrong UID test `:733`; E10 independent diagnostics `:1596–1598`, `:1647–1649`. Browser XML reports exact upsert/delete probes; it does not independently screenshot every partial case. |
| Overflow | E1, E2, E3, E4, E5, E7, E8, E9, E10 | E1 schema label `sync_drift_live.ex:1436–1442`; E2/E3 exact values `:1476–1493`, `:1557–1575`; E4 table uses shared `ops_signal_table` (`ops_ui.ex:182`) and code values at `sync_drift_live.ex:1682–1689`; E5 disclosure copy `:1791–1807`; E7 identity `:1718–1729`; E8 inline code uses `break-all` at `ops_ui.ex:1461`; E9 handoff `:1820–1832`; E10 `ops_code_block` uses `whitespace-pre-wrap break-words` at `ops_ui.ex:1443`. Matrix’s synthetic long-text layout was DOM-only at 390px; retained mobile captures show normal names, not maximal long text. |
| Zero-one-many | E2, E3, E4, E5, E7, E10 | E2 count-aware summary helpers `sync_drift_live.ex:1360–1398`; E3 single retained recovery identity at `:1445–1493`; E4 mismatch count/table at `:1652–1705`; E5 blocker list/eligibility mapping at `:1180–1202`, `:1802–1815`; E7 one retained current UID at `:1709–1779`; E10 diagnostics are conditional at `:1596–1598`, `:1647–1649`. Grouped UI matrix includes zero-one-many, not every element scenario separately. |
| Long-text | E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 | E1 selector and E5/E6 exact schema in `sync_drift_live.ex:1436–1442`, `:1843–1855`; E2/E3/E7 exact IDs at `:1476–1493`, `:1718–1729`; E4 technical table values at `:1682–1689`; E8 shared inline code `ops_ui.ex:1461`; E9 handoff `sync_drift_live.ex:1820–1832`; E10 diagnostic block wrapping `ops_ui.ex:1443`. Browser matrix states the long-text case is a DOM-only stress input; no captured full confirmation with maximal identifiers is present. |

## Files Audited

- `.planning/phases/175-repair-and-verification/175-01-PLAN.md` through `175-06-PLAN.md` and matching summaries
- `175-UI-SPEC.md`, `175-CONTEXT.md`, `175-EVIDENCE.md`, `175-VALIDATION.md`, `175-SECURITY.md`
- `AGENTS.md`, `CONTRIBUTING.md`
- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
- `scrypath_ops/assets/css/app.css`, `scrypath_ops/assets/css/DESIGN-TOKENS.md`
- `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`
- `scrypath_ops/test/scrypath_ops_web/live/phase175_fixture_live_test.exs`
- Retained `phase175-repair.xml` and 390/768/1440 Light/Dark/System captures at the exact source SHA above
