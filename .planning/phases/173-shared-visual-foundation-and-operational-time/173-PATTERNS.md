# Phase 173: Shared Visual Foundation and Operational Time — Pattern Map

**Mapped:** 2026-10-06  
**Files analyzed:** 15 likely source, generated asset, and test seams  
**Analogs found:** 15 / 15 (some test-harness behavior has no current standalone analog)

## Scope and constraints

Requirements OPUX-09 through OPUX-15 in `.planning/REQUIREMENTS.md` are authoritative. Preserve the locked warm-neutral light/neutral-dark direction and existing spacing, typography, component, native-button, and hook choices from `173-CONTEXT.md` and `173-UI-SPEC.md`. Both standalone Ops and mounted Ops are in scope. No added dependency, authorization change, new route, or changed health classification is implied.

Project instructions read: root `AGENTS.md`, `scrypath_ops/AGENTS.md`. The Ops app uses Phoenix 1.8 conventions. All named source analogs below were confirmed tracked with `git ls-files`; generated `scrypath_ops/priv/static/assets/{css,js}` are tracked too. Treat `assets/` as editable build source and verify/rebuild the tracked `priv/static` output through the existing asset workflow; do not assume direct edits to generated output are authoritative.

## File Classification

| Likely file | Role / flow | Closest tracked analog | Match |
|---|---|---|---|
| `scrypath_ops/assets/css/app.css` | config/style, transform | same file; `design_tokens_contract_test.exs` | exact |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` | documentation/config | same catalog; `ops_ui.ex` exports | exact |
| `scrypath_ops/assets/js/ops_hooks.js` | hook/util, event-driven | same shared hook module | exact |
| `scrypath_ops/assets/js/app.js` | provider/entrypoint, event-driven | same Ops entrypoint | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | component, request-response/render | `ops_time`, `ops_refresh_control`, `ops_metric` in same module | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` | component, render | `theme_toggle/1` and layout shell | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex` | layout/config, pre-paint browser state | same root template | exact |
| `scrypath_ops/lib/scrypath_ops/posture.ex` | service/model, transform/snapshot | `summary/2` and `classify/1` in same module | exact |
| `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` | LiveView/controller, request-response | same Search health LiveView | exact |
| `lib/scrypath/operator/state.ex` | model/normalizer, transform | `from_backend_task/1`, `from_queue_job/1` | exact |
| `lib/scrypath/operator/status.ex` | service/summary, request-response | `summarize_backend/1`, `summarize_queue/2` | exact |
| `examples/scrypath_ecommerce/assets/js/app.js` | mounted provider/entrypoint, event-driven | same host bundle | exact; behavior currently diverges |
| `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs` | LiveView test, request-response | existing test module | exact |
| `test/scrypath/operator/status_test.exs` | unit test, transform | existing root status tests | exact |
| `examples/scrypath_ecommerce/e2e/*` and `scripts/verify-e2e.sh` | browser tests/harness, event-driven | mounted Playwright and isolated compose runner | partial; no standalone harness |

Generated mirrored assets likely affected: `scrypath_ops/priv/static/assets/css/app.css`, `scrypath_ops/priv/static/assets/js/app.js`. These are build outputs rather than source analogs.

## Pattern Assignments

### CSS tokens, action rules, and catalog

**Source:** `scrypath_ops/assets/css/app.css` (tracked, 2,422 lines); `scrypath_ops/assets/css/DESIGN-TOKENS.md`; test `scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs`.

The stylesheet owns both daisyUI theme variables and Ops component tokens. Theme and responsive selectors need paired explicit `[data-theme="dark"]` and System `@media (prefers-color-scheme: dark)` paths, with `html:not([data-theme="light"])` gating System behavior. Keep shared custom properties in `@theme` and style components using `var(--...)`; update the catalog when exports or token vocabulary change. The contract test scans template utilities and vars for defined-token coverage. Search `.ops-theme-toggle__button`, `.ops-refresh-button`, `.ops-time`, `.ops-metric`, `.ops-panel` rules before extending; avoid stacking new overrides over old declarations. UI-SPEC controls approved palette and incumbent sizing.

**Build ownership:** `scrypath_ops/assets/css/app.css` is source; `scrypath_ops/priv/static/assets/css/app.css` is a tracked generated artifact served by AssetPlug. The root layout links via `AssetPlug.asset_version/1`. Follow existing Ops asset build/sync task before including generated output; do not hand-maintain divergent copies.

### Shared Ops component and actions

**Analog:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`.

The component module centralizes typed attrs, defaults, safe class assembly, stable DOM hooks, and HTML semantics. `ops_refresh_button/1` supplies a native button with `data-ops-refresh` and `phx-hook="OpsRefreshButton"`; `ops_refresh_control/1` pairs the optional “Checked” time with that button. `ops_time/1` owns human display, `datetime`, accessible label, and optional exact-copy action. Extend this seam for timestamp/action semantics rather than introducing a parallel per-page control. Current `ops_time` truncates to seconds and computes against `DateTime.utc_now()` on every render; it is the display behavior to revise under D-15–D-20, not a precedent to preserve.

**Native theme control analog:** `layouts.ex:374-420` renders three ordinary `<button type="button">` elements with stable accessible labels and `data-phx-theme`; `root.html.heex` listens for `phx:set-theme`. UI-SPEC requires visible System/Light/Dark labels and a single preference-backed visual/`aria-pressed` selected state. Preserve native activation and Tab order; remove conflicting effective-appearance selection styling.

### Browser hook, clipboard, and entrypoints

**Analog:** `scrypath_ops/assets/js/ops_hooks.js:5-23` (`OpsRefreshButton`). Its `mounted` hook snapshots initial disabled state, observes LiveView loading classes, toggles disabled/`aria-busy`, and disconnects on destroy. This keeps nested icon/label DOM intact instead of using `phx-disable-with`; retain that behavior and server eligibility after patches.

`scrypath_ops/assets/js/app.js` imports and registers shared hooks, then handles `phx:copy_to_clipboard`. The ecommerce mounted bundle imports the same hooks but duplicates theme and clipboard listeners. Currently both bundles use direct `localStorage` access; clipboard listeners return without feedback when API is missing and swallow rejected writes. For OPUX-12/15, unify or faithfully mirror guarded preference and truthful awaited-copy semantics in both entrypoints. The root HEEx pre-paint script runs earlier to avoid theme flash; preserve that responsibility and same-origin `storage` handling while guarding access. Keep exact text selectable on clipboard failure; only success-confirm after the returned promise resolves.

**Build ownership:** Ops `assets/js/app.js` and `ops_hooks.js` are source; `priv/static/assets/js/app.js` is tracked generated output. Mounted JS source is `examples/scrypath_ecommerce/assets/js/app.js`, with a relative import into shared tracked Ops hooks. The two builds have distinct ownership: Ops Mix assets and ecommerce npm/esbuild assets. No common runtime bundle currently owns theme behavior.

### Root timestamp provenance and status summary

**Normalizer analog:** `lib/scrypath/operator/state.ex:34-68,93-124` maps backend `finishedAt` and queue `completed_at` into `%State{at: DateTime.t() | nil}`. `parse_datetime/1` accepts `%DateTime{}` or ISO text; parsing discards the original offset representation and source string. Preserve the established source fields and state normalization, but extend the model/normalization boundary if needed to retain exact ISO evidence and precision alongside the parsed instant. UI-SPEC confirms `finishedAt`/`completed_at` represent completed operational work, not document freshness.

**Summary analog:** `lib/scrypath/operator/status.ex:50-65,100-130` fetches backend and queue separately, retains observed queue distinction, and chooses the latest `:completed` history item by parsed time. Do not reinterpret `last_succeeded` as a fresh check or current document state. `test/scrypath/operator/status_test.exs` supplies injected fake clients/inspectors via config and asserts normalized pending, failed, completed, and unobserved values; extend this fixture approach for fractional precision/offset and terminal history cases.

### Snapshot and PostureLive

**Service analog:** `scrypath_ops/lib/scrypath_ops/posture.ex:44-85` creates a summary and sets `refreshed_at` at each observation, with explicit state/counts and classification. Preserve its classification. Relative success age must be tied to the snapshot that observed retained evidence, not blindly advanced on rerender or failed check; inspect refresh/error flow before modifying ownership of snapshot time.

**View analog:** `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex:36-49,88-101` handles manual refresh synchronously, emits low-cardinality telemetry, flashes outcome, and assigns the returned summary plus `refreshed_at`. The HEEx renders refresh via shared `ops_refresh_control`, metrics via `ops_metric`, and backend/queue `last_succeeded` in separate rows. Keep status facts and local cues in the existing component tree; unavailable/unused queue and zero errors remain distinct data states.

### Tests and runner

**Existing commands (defined in `173-VALIDATION.md`; not run during mapping):**

- Root status: `mix test test/scrypath/operator/status_test.exs` from repo root.
- Focused Ops: `cd scrypath_ops && mix test test/scrypath_ops_web/design_tokens_contract_test.exs test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/live/posture_live_test.exs`.
- Root Ops UI aggregate: `mix verify.ops_ui` from repo root.
- Contrast: `make -C examples/scrypath_ecommerce contrast`.
- Mounted compose gate: `make -C examples/scrypath_ecommerce verify-mounted`; broader advisory browser gate: `make -C examples/scrypath_ecommerce verify-e2e`.

`examples/scrypath_ecommerce/package.json` defines `test:e2e:admin-shell` and `test:e2e:admin-depth`; `e2e/admin_shell_chrome.spec.ts` / `admin_surface_depth.spec.ts` are mounted host-app coverage. `scripts/verify-e2e.sh` accepts only `focused|full`, creates an isolated Compose project named by scope/SHA/PID, runs compose build/up, collects logs/Playwright artifacts, then removes volumes/orphans unless `KEEP_E2E_STACK=1`. This verifies mounted ecommerce flow only; it does not create standalone Ops browser coverage or prove theme/copy behavior in both entrypoints. No standalone Ops Playwright script/harness is present. Wave 0 must create a bounded disposable standalone browser fixture/runner before claiming that coverage. Do not invent an npm script or runner command before its creating task exists.

## Shared Patterns

- **One visual authority:** CSS tokens/components in Ops assets; mirror dark rules for explicit and System paths. `design_tokens_contract_test.exs` checks token references; catalog is the human-facing inventory.
- **Patch-stable controls:** shared `OpsRefreshButton` hook owns transient loading state while server-rendered disabled eligibility remains authoritative.
- **Truthful observation:** root `Status` distinguishes backend vs queue; `Posture` distinguishes observation failure from terminal failed work. Keep labels and counts derived from these existing classifications.
- **Timestamp evidence:** source completion time and successful observation time are separate. Preserve source precision/offset; relative age uses the retained observation snapshot. Clipboard success requires resolved write; absence/rejection leaves visible selectable exact evidence.
- **Preference vs appearance:** stored/user preference selects exactly one native button; effective System appearance follows media query independently. Root pre-paint and mounted/standalone bundles must agree and tolerate storage exceptions.

## Gaps for Planning

| Gap | Planning consequence |
|---|---|
| No root `State` test file found; root `StatusTest` indirectly tests normalization. | Add focused normalization coverage for exact ISO offset/fraction and malformed/absent input in root test suite. |
| No tested snapshot-age component/unit seam identified; current component uses wall clock. | Add deterministic time/snapshot fixtures and boundary/future/failed-refresh tests before claiming OPUX-14. |
| No standalone Ops Playwright harness/script. | Assign disposable harness/fixture creation in an earlier task; existing mounted runner does not cover standalone. |
| Theme script is duplicated across root pre-paint and two JS entrypoints, with unguarded storage. | Test invalid/blocked storage, OS changes, reload, cross-tab, and LiveView patch in both entrypoints. |
| Existing browser specs are host/ecommerce focused. | Extend rendered behavior tests for clipboard promise outcomes and exact payload in mounted and standalone Ops. |

## Metadata

**Analog search scope:** root `lib/`, `test/`, `scrypath_ops/assets`, `scrypath_ops/lib`, `scrypath_ops/test`, and `examples/scrypath_ecommerce/{assets,e2e,scripts}`.  
**Tracked-source gate:** named analog source paths checked with `git ls-files`; no ignored `.gsd/capabilities` mirrors used.  
**Extraction date:** 2026-10-06.
