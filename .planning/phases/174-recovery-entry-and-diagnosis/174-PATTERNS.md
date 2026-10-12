# Phase 174: Recovery Entry and Diagnosis - Pattern Map

**Mapped:** 2026-10-10  
**Files analyzed:** 8 existing target files; no new production files expected  
**Analogs found:** 8 / 8

All source analog paths below were verified with `git ls-files` from the `scrypath_ops` submodule root for library/test sources and from the worktree root for example E2E sources. Each is tracked. Do not use root-checkout or ignored capability mirrors as implementation sources.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` | component (LiveView) | request-response | same file, `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` | exact |
| `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` | component (LiveView) | request-response | same file, `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` | exact |
| `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` | component (LiveView) | CRUD/action + request-response | same file, `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` (`OpsUi`) | component | transform/presentation | same file, `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | exact |
| `scrypath_ops/lib/scrypath_ops/operator_selection.ex` (`OperatorSelection`) | utility | transform/navigation | same file, `scrypath_ops/lib/scrypath_ops/operator_selection.ex` | exact |
| `scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs` | test | request-response | same file | exact |
| `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs` and `failed_sync_live_test.exs` | test | request-response/action | same files | exact |
| `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts` (extend mounted sequence) | test | browser navigation/history | `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts`; helpers in `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` and `operator-ui.ts` | role-match |

## Pattern Assignments

### `ControlRoomLive` — concise posture and single safe route

**Analog:** `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` (tracked in submodule).

- **Imports/setup and shell:** lines 11–27 use the app LiveView macro, a focused domain alias, mount assigns, and summary loading. HEEx begins with `<Layouts.app>` and composes `ops_toolbar`, `ops_page_header`, and `ops_refresh_control` at lines 46–67; retain this wrapper and shared geometry.
- **State/read order:** lines 69–94 render setup/missing-backend states separately from `:ok`/`:degraded` verdict. The verdict gives headline/evidence before metrics; line 83 currently provides its health link. Reorder/prune content to the contract's state → affected scope → one **Inspect Search health** route; do not make setup states look retryable.
- **Secondary intents:** lines 96–139 contain incident, change verification, exploration, and guide intents. Reuse `ops_intent_card`; keep secondary routes secondary and remove duplicative incident prompts if required by D-01.
- **Refresh behavior:** lines 30–38 reload summary and report refresh. Match shared status conventions if replacing flash feedback; no new alert or focus movement for normal refresh.

### `PostureLive` — worst-first schema records and contextual handoff

**Analog:** `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` (tracked in submodule).

- **HEEx record order/shared components:** lines 347–380 create one `<article>` per `{mod, row}`, show complete `inspect(mod)` and index, then local backend/queue state. Lines 383–419 use plain labelled Backend and Queue sections with definition lists. Keep one surface per schema; avoid extra card nesting. Lines 489–495 put the schema-specific failed-work link at its evidence row.
- **Data ordering:** `posture_rows_worst_first/1` and related ranking helpers are in this same file (search by function name); preserve fetch errors → backend failures → unknown/failing/retrying queue → clean, with current tie-break. The row renderer is the best excerpt for the target record; preserve the separate Failed sync newest-evidence ordering.
- **Unknown versus zero and time/accessibility:** lines 414–420 gate queue metrics on `status.queue.observed?`; use the existing explicit unobserved branch immediately following. Backend and queue headings are labelled sections; timestamps use `ops_time` with source snapshot/state text (lines 398–408). Keep those distinctions and native `<section>`, `<dl>`, `<dt>`, `<dd>` semantics.
- **Navigation:** lines 489–495 use `OperatorSelection.path(@mount_path, "failed-sync", mod)` for exact schema handoff. Avoid unqualified handoffs from a schema record.
- **Page order/config states:** lines 277–345 show summary before per-schema section and explicit empty/missing-backend components. The mount and `handle_params` at lines 14–54 and 110–130 establish the current page route behavior; preserve route aliases/prefixes.

### `FailedSyncLive` — allowlisted URL state, action gates, evidence before diagnostics

**Analog:** `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` (tracked in submodule).

- **Selector and URL state:** lines 79–127 resolve selector values using `OperatorSelection.resolve/2`, patch via `OperatorSelection.path/3`, and clear state for unavailable selection. Lines 129–169 invalidate receipts, advance context generation, clear inspections and delete confirmation. Preserve this reset as a unit when a valid schema changes or an explicit schema becomes unavailable.
- **Server revalidation/action gate:** lines 145–152 resolve the selected canonical identity against the *current* allowlist. Lines 218–245 check selection and current row before retry; recovery action passes through `Gating.gate_sensitive_action/3`. Keep UI visibility as discoverability only; retain host authorization and live eligibility at event time.
- **Refresh/data errors:** lines 171–215 recheck selection/backend before inspection and represent errors separately from empty inspection. Reuse this branch structure for unavailable/setup states; do not manufacture empty/zero evidence after a fetch failure.
- **Failure row order and shared semantics:** lines 616–676 use `ops_result_row`; row subtitle carries source and attempt time, reason appears at 628–633, supported Retry action at 634–648, accepted receipt with `role="status"` and retained source failure at 649–665, then native Diagnostics disclosure at 667–676. Keep reason/identity/time/eligibility before optional metadata and receipt adjacent to original evidence.
- **Delete confirmation:** lines 697 onward reuse `ops_modal`, explicit cancel event and first-focus selector. Preserve existing dialog's host gate, semantics and exact copy; do not add another destructive flow.
- **Mounted path/query:** lines 382–393 encode schema plus existing recovery handle/generation on the Sync and drift handoff; line 688–694 uses `OperatorSelection.path/3` for the generic selected-schema handoff. Preserve `@mount_path` and exact canonical schema on every selected-schema navigation.

### `OpsUi` — shared components and accessible control pattern

**Analog:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` (tracked in submodule).

- `ops_page_header/1` and `ops_heading/1`: lines 11–36 and 62–93 establish one h1, visible heading hierarchy and token-based sizes.
- `ops_panel/1`, `ops_toolbar/1`, `ops_section/1`: lines 95–153 establish existing panel padding, responsive wrap, labelled section semantics, and constrained text widths. Prefer these over local duplicate wrappers.
- `ops_refresh_control/1`: lines 225–275 pairs `ops_time` with a labelled button that retains icon and text; use it for refresh and keep existing busy behavior.
- `ops_link_button/1`, `ops_notice/1`, `ops_status/1`: lines 277–361 provide native LiveView link semantics, explicit title/body, and optional `role="status"`. Use status for non-focus-moving accepted/refresh results; use persistent visible alert/error conventions only for correction-required failures.
- `ops_metric_grid/1` and `ops_metric/1`: lines 363–411 provide neutral rollups and cue-plus-text tones. Avoid presenting unavailable values as zeros.
- `OpsUi` also owns `ops_verdict`, `ops_result_row`, `ops_disclosure`, `ops_schema_select`, `ops_inline_code`, `ops_config_empty`, and `ops_modal`; inspect their current definitions before changing markup. Extend a shared primitive only for a repeated visible need.

### `OperatorSelection` — canonical untrusted query resolution

**Analog:** `scrypath_ops/lib/scrypath_ops/operator_selection.ex` (tracked in submodule).

Lines 4–9 canonicalize loaded modules; lines 11–29 distinguish absent `schema` (existing first-allowlisted default) from present invalid value (`:unavailable`) by matching against allowlist strings. Lines 31–39 encode the canonical selection and retain mount prefix in paths. Copy/use these functions; never parse user input into atoms, silently fallback after explicit invalid input, or build schema-specific links by ad hoc string concatenation.

### LiveView tests — render, patch, and safety assertions

**Analogs:** all listed tests are tracked from `scrypath_ops/`.

- `test/scrypath_ops_web/live/control_room_live_test.exs`: tests use `ConnCase`, `Phoenix.LiveViewTest`, configured host stubs and deterministic setup. Helpers `card_fragment/2` and `assert_before/3` (lines 167–177) assert visible reading order. Extend with state matrix/one-safe-link assertions, not a duplicate test setup.
- `test/scrypath_ops_web/live/posture_live_test.exs`: lines 130–167 assert rendered row, failure-first data, labelled Backend/Queue/Last success, and cue semantics. Lines 210–253 verify retained evidence and schema-specific link. Add full identity, unknown queue, record order and context handoff assertions using rendered markup.
- `test/scrypath_ops_web/live/failed_sync_live_test.exs`: lines 141–150 exercise the real schema form and `assert_patch`, then inspect selected assign. Lines 152–175 assert reason/action precede Diagnostics; lines 177–207 cover empty and no-schema states. Reuse its controlled fake backend/Oban fixtures and setup/cleanup. Add explicit invalid/stale allowlist cases and assert cleared state/no operation on another schema. Retry action tests should assert the existing server gate and retained failure behavior.

### Mounted Playwright spec / verification harness

**Analog:** `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts` (tracked at worktree root); shared helpers `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` and `operator-ui.ts` are also tracked.

- The spec's `Entry` list and `visit` helper (lines 7–36) cover both mounted `/admin/search/...` and standalone prefixes and wait for LiveView connectivity. Add Phase 174's real selector → non-first schema → rendered handoff → refresh → Back/Forward scenario to the existing mounted lane (or a narrowly scoped sibling spec in the same tracked directory); annotate exact source SHA as current specs do.
- `phase173_status_actions.spec.ts` lines 150–195 test long content and page/row overflow at small and rail widths; lines 197–240 test keyboard focus outline, busy action, reduced motion, and server eligibility. Adapt assertions for 320/390px and long schema/index/work/reason values.
- For cross-route setup/mount evidence, `examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts` lines 7–32 declares mounted prefix and standalone entry, while 83–105 verifies loaded app and row identity. `waitForLiveConnected` in `helpers/e2e.ts` lines 5–24 is the interaction prerequisite. `helpers/operator-ui.ts` lines 11–22 checks no document/body overflow; lines 76–101 contain reusable dialog keyboard cycling. Reuse these; no new browser stack or dependency.

## Shared Patterns

### Identity, navigation, and fail-closed behavior

**Sources:** `OperatorSelection` lines 11–39; `FailedSyncLive` lines 79–169 and 382–393; `PostureLive` lines 489–495.  
Resolve URL/event schema values against the live allowlist at parameter load and again before sensitive actions. Use `push_patch` within the view and `push_navigate` between views; schema-specific links carry the canonical `schema` under the existing mount prefix. Explicit invalid or newly removed schemas render unavailable, clear schema-bound evidence/receipts/selection, and expose no action. Browser history and reload reconstruct the displayed selection from the URL.

### Host authorization and recovery evidence

**Sources:** `FailedSyncLive` lines 218–269, 649–665; `OpsUi` lines 326–359.  
The retry row is a UI affordance; server-side allowlist, current failed row/eligibility and host `Gating` remain decisive. Accepted work remains beside the original failure and is a polite status, never a success/terminal receipt. Keep metadata in native disclosure.

### HEEx, responsive order, and accessibility

**Sources:** `ControlRoomLive` lines 46–94; `PostureLive` lines 347–419; `OpsUi` lines 11–36, 95–153, 277–359; E2E `phase173_status_actions.spec.ts` lines 150–240.  
Begin each LiveView template with `<Layouts.app>`; retain shared components, semantic heading/section/article/list/form/link/button/disclosure/dialog markup and visible labels. DOM order must match state → scope → action, and reason → identity/time → eligibility → diagnostics. Keep existing token geometry/focus ring, wrap long values, meet 44px for touch/icon-only targets, and prevent page-level horizontal overflow. Pair status hue with text and local cue.

### No new production file/dependency indicated

Phase 174 is a refinement of the existing three LiveViews, `OpsUi`, and `OperatorSelection`. Research and validation point to extending the three current LiveView tests and existing mounted Playwright lane/helpers. No new production component/module, route, test framework, browser dependency, or CI service is indicated. A new focused `.spec.ts` is only a discretionary test organization choice; prefer extending the existing mounted recovery/navigation lane unless a separate spec materially improves readability.

## No Analog Found

None. The page-specific source and test files are their own exact analogs; the mounted Playwright test has a strong same-domain Phase 173 analog.

## Metadata

**Analog search scope:** `scrypath_ops/lib/scrypath_ops_web/live/`, `scrypath_ops/lib/scrypath_ops_web/components/`, `scrypath_ops/lib/scrypath_ops/`, `scrypath_ops/test/scrypath_ops_web/live/`, `examples/scrypath_ecommerce/e2e/`  
**Tracked-source verification:** `git ls-files` from the submodule root for all `scrypath_ops` paths and from the worktree root for E2E paths; each named source returned a tracked path.  
**Pattern extraction date:** 2026-10-10
