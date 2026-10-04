# v1.42 UI automation strategy

**Date:** 2026-10-03  
**Source reviewed:** `3c83a58c9bc5af70a204957431ff66fd9db035de` in `ui/operator-admin-prep`  
**Evidence class:** static inspection of existing code, tests, harnesses, and CI. No tests, browser sessions, or CI runs were performed for this report. Recommendations below are proposed coverage, not passing evidence.

## Recommendation

Build on the existing Phoenix LiveView tests, token checks, Docker browser lane, and screenshot tooling. Add one discriminating incident recovery journey and a small set of observable layout/accessibility checks. Keep the existing full screenshot/contrast matrix on its advisory schedule/manual lane. No recurring paid model calls are needed. User feedback is useful direction while the work is underway; routine acceptance should be executable and should not depend on the user inspecting every screen.

The most important prerequisite is an honest recovery oracle. The current failed-sync browser test proves triage visibility, while the swap test uses a weak historical task probe. Neither proves the proposed complete recovery journey today. Fix that gap before using screenshots or a green test run to claim recovery.

## Existing assets and their evidence limits

| Asset | Reuse | What it does not prove |
| --- | --- | --- |
| `scrypath_ops/test/scrypath_ops_web/live/*_live_test.exs` | Existing Control Room, Posture, Failed Sync, Sync/Drift, Search, and Playbooks behavior; errors, empty states, sensitive-action gates, schema allowlists, playbook lifecycle and superseded runs | Actual browser geometry, CSS readability, keyboard behavior, live backend recovery |
| `design_tokens_contract_test.exs` | Finds operator token utilities/custom properties referenced by templates without a definition | Consistent use of the palette, absence of arbitrary CSS, computed font size, readable layout |
| `ops_a11y_contract_test.exs` | Landmark/skip-link, one h1, main labeling, Search fieldset/legend contracts | Full accessibility compliance or actual focus flow |
| `operator_ia_contract_test.exs`, shell/motion/depth contracts | Existing navigation and shared component agreements | An operator actually following the complete incident route |
| `e2e/operator.spec.ts` | Existing mounted failed-sync and swap integration entry points | Recoverable retry, task identity, or cross-screen recovery outcome; see hazards below |
| `e2e/admin_shell_chrome.spec.ts` | Theme switching, shell navigation, mobile drawer, palette/shortcut interactions, flash contrast; modal focus checks when `aria-modal=true` | Full page a11y or complete tab-order testing. Existing modal helper checks one Tab step; it does not exercise an entire focus cycle |
| `e2e/admin_contrast_matrix.spec.ts` | Axe AA contrast across explicit light/dark and system-dark at 390px/1440px; per-scenario reports; AAA body advisory | Axe is configured with only `color-contrast`; absence of violations is not a general accessibility pass. `incomplete` is not a pass claim |
| `contrast-checker.mjs`, `contrast-pairs.mjs` | Fast token-pair AA gate with alpha-compositing and manifest lockstep checks | Actual cascaded styles, occlusion, all gradients/images, text size, or layout |
| `e2e/admin_screenshot_matrix.spec.ts` | 10 curated states × two themes × two widths = 40 screenshots | Visual regression comparison: it captures evidence but does not compare pixels |
| `e2e/admin-light-baseline-check.mjs` | Expected light screenshot inventory, width, and no extra filenames | Height/content/pixel parity. Its name must not be cited as proof that light visuals are unchanged |
| `e2e/light-pixel-diff.mjs` | Historical Phase 130 disposable comparison utility | A maintained general baseline gate: it depends on local `.tmp` screenshots and demands zero pixel differences |
| `e2e/admin_shell_wash.spec.ts`, `admin_surface_depth.spec.ts`, `admin_path_motion.spec.ts` | Bounded existing appearance/motion invariants | Whole-screen composition, coherent microcopy, operator comprehension, or all layout regressions |
| `e2e/ops-ui-visual-judge.mjs` | Optional explicitly enabled model review with bounded report schema | A deterministic gate or trustworthy mock approval. `--mock` produces an assumed pass; it is tooling evidence only |
| `scripts/verify-e2e.sh` + `compose.e2e.yaml` | Unique Docker project, no host ports, persistent test server, serial browser work, logs/reports collection, isolated playbook volume, cleanup trap | Stable-run evidence when a test only passes on retry; per-test isolation of global Meilisearch history |

The contrast helper has 14 configured capture entries across its three scenarios, including detail supplements. Do not infer its coverage count from the older approximate header comment. The screenshot matrix and contrast matrix currently duplicate some preparation definitions; do not create a third independent route/state catalog for this milestone.

## Recovery fixture and oracle hazards

1. **Current injected failure is not recoverable.** `E2EController.inject_failed_sync/2` writes `Elixir.NotARealBackend`, document `-1`, and a tenant-suffixed index into an Oban job. `operator.spec.ts` uses the first row, optionally clicks Retry only if visible, and accepts `/Retried|Failed sync jobs/` text. It then asserts failures remain. This is a useful historical triage case; it must not be relabeled recovery proof.
2. **Retry acceptance is not completion.** `RecoveryAction.retry/2` for Oban enqueues a new job; the original failed job is not cleared. The UI currently flashes `Retried <id>` as soon as enqueueing succeeds. Track the new job and its backend work, then prove task completion and expected document visibility. A requirement that `failed_count=0` or every dashboard indicator turns green would misrepresent current semantics and may force unwanted core scope.
3. **Index identity matters.** The demo runtime config uses `index_prefix: "ecommerce_"`; both failure injectors hardcode `scrypath_ecommerce_products_<tenant>`. Recovery validation rejects an action whose index does not match the configured index. Resolve the real schema/backend/index in the fixture instead of copying historical display-fixture literals.
4. **Old swap tasks can satisfy the current oracle.** `swap_probe/1` falls back to `recent_index_swap_succeeded?/1`, which accepts any succeeded `indexSwap` in the returned global task list. The endpoint's `active_index_visible?` only looks for an existing CyberPhone result. Record pre-action identity and assert a new task for the selected index pair plus a run-specific expected document/value. A previously successful swap and already-visible catalog must not turn a new failed swap green.
5. **The `incident` scenario is a presentation fixture.** It seeds five reason classes, some with no replay payload, parks retryable work far in the future, and removes `tenant_id` from filterable settings. A tenant-filtered probe consequently fails until the contract is restored. Its payload can replace an existing product with an “Ops Incident Lab item.” Use a dedicated recoverable scenario with explicit initial/final truth instead of requiring all demonstration failures to disappear.
6. **Global reset is destructive to the demo.** `/dev/e2e/seed` removes all catalog rows and Oban jobs in the example DB and changes shared indexes. Routes exist only in dev/test, but they are still real mutations. Run automated verification in the disposable Compose project; do not seed/reset the same preview instance while the user is inspecting it. Remain serial while fixtures share these resources.
7. **Reset does not clear all backend history.** It deletes index docs corresponding to current Product rows, swallows several index errors, and leaves historical tasks. Orphan documents or pending work can survive inadequate setup. For the new scenario, validate setup and cleanup effects and fail closed on fixture errors; bounded correlated IDs are preferable to relying on a globally empty task list.
8. **Polling must observe state.** Reuse `waitForLiveConnected`, `expect.poll`, and backend visibility helpers. Replace touched `waitForTimeout` synchronization with explicit visible/terminal conditions. Avoid increasing arbitrary sleeps or treating retries as proof of stability.

### Proposed discriminating journey

Use a unique scenario marker with the real configured schema/index, one replayable failure, and a prepared target only when a swap is actually appropriate. Capture the baseline job/task IDs and expected product state. Enter at Control Room and follow rendered navigation/actions to Posture, Failed Sync, and Sync/Drift; direct `page.goto` between each screen would bypass the UX seam being tested. Preserve the selected schema/context wherever the product supports it.

Assert the intended failed work explicitly, perform the supported retry, observe the replacement job being accepted and reaching terminal success, and check the expected change through the real search backend. If this scenario requires a swap, identify the new swap task/index pair and verify the prepared target's unique content through the active index. Revisit the relevant UI and assert that its outcome accurately distinguishes accepted, running, completed, blocked, and retained historical failure evidence. Do not manufacture a green aggregate status unsupported by the domain model.

Keep unsuccessful recovery as a focused LiveView/fixture case: failed operation keeps diagnostic evidence and exposes a usable next action; unsupported recovery has a clear reason and cannot report success. A single browser failure-path check is worthwhile if it proves behavior that only exists across the real browser/backend seam.

## Cheapest meaningful verification layers

| Layer | Concrete acceptance | Placement / cost |
| --- | --- | --- |
| Token and source contracts | Shared typography/spacing/radius/depth/z-index vocabulary resolves; no accidental missing utilities; canonical labels for repeated shared actions | Existing Ops tests. Extend only a contract that catches actual drift; avoid asserting every class string or every line of copy |
| LiveView behavior | Happy/error/empty/loading or pending/disabled states; selected schema; no premature success; retry authorization; stale evidence; sensitive action gating | Existing `mix verify.ops_ui` path. Use deterministic service stubs for boundary cases |
| Static contrast | Changed token pairs retain the existing AA agreement in both themes | `make contrast`, fast and browser-free. Consider adding this small command to the existing focused Docker lane if CSS changes demonstrate recurring value |
| Mounted incident journey | Navigation seam, specific failure identity, new accepted work, terminal task state, expected live-index content, honest UI outcome | Extend existing `operator.spec.ts` in the required `ecommerce-mounted` lane; no new CI job required |
| Layout/legibility | No page-wide horizontal overflow, critical actions visible/reachable, labels and status text not clipped, content fits at narrow width, declared body/control typography is applied | Small Playwright helper on representative screens; reuse browser already started for the journey. Assert user-visible outcomes, not specific grid implementations |
| Keyboard/accessibility | Primary route operable by keyboard, visible focus, dialog open/close/focus return, labeled inputs and controls, meaningful heading/landmark structure, no new relevant axe violations | Existing shell tests plus a small axe scan of changed journey states. Keep broader rules distinct from the existing contrast-only report |
| Visual evidence | Before/after screenshots of affected route/components, comparison of hierarchy, density, typography, whitespace, readable long values and errors | Capture during existing browser execution, inspect in the current agent session; no external model service. User can give optional design feedback |
| Broad regression evidence | Existing screenshot/contrast/motion/depth matrices, full storefront/operator smoke | Existing full advisory Docker lane on schedule/manual; run once after coherent UI changes or when shared CSS changes justify it |
| Milestone closeout | Required exact-source gates, actual scoped UI test results, honest evidence gaps, final tracking | Existing two-stage candidate/final closeout command. Full E2E is advisory and is not automatically enforced by the closeout attestation; inspect its actual step result separately for UI claims |

Do not impose a universal “minimum font size test” over every node. Establish the design contract for body, controls, supporting text, and technical identifiers first, then assert representative computed styles/legibility and inspect screenshots. A cramped two-column layout cannot be fixed merely by increasing type size. Long technical content may use an explicit, labeled scroll region; the whole page should still reflow.

## Small coverage matrix

Cover each risk once at its cheapest credible layer rather than multiplying all six routes by every state, theme, viewport, browser, and input mode.

| Scenario | Browser coverage | Other coverage |
| --- | --- | --- |
| Real incident to verified recovery | Desktop explicit dark end to end; narrow mobile explicit light through the same meaningful controls, kept serial | Correlated queue/task/index assertions |
| Healthy/empty | Representative recovery summary and no-failed-work state in opposite theme/width to main journey | LiveView empty/unconfigured cases for every affected screen |
| Error/blocked/retry unavailable | One representative browser case if layout or real interaction changes | LiveView cases for transport errors, stale evidence, invalid schema, auth/sudo restrictions, rejected action |
| Loading/in progress | Stable captured state only when delay is controllable; controls expose pending state without duplicate submissions | LiveView state transition/disabled-action tests; no timing guesses |
| Shared shell/control changes | Existing explicit light/dark/system-dark shell grid, keyboard and reduced-motion checks where applicable | Existing token and a11y contracts |
| Reflow/long content | Narrow 390px and wide 1440px reuse; add one 320px or equivalent reflow spot check and one intermediate width when shared layout changes | Long schema/index names, diagnostic text, empty values, large counts in representative fixture |
| Adjacent Search/Playbooks | Existing healthy/empty screenshot and smoke assets unless the shared component changed | Existing per-screen tests; new domain features remain outside this milestone |

Dark/light behavior and narrow/wide layout are separate risks, so cover both dimensions. Keep the existing system-dark check because it exercises a distinct CSS cascade. Do not rebuild the entire backend recovery journey for every combination merely to obtain screenshots.

## Screenshot and visual review policy

- Capture the current UI before changes in an artifact directory tied to source SHA, state, theme, viewport, and capture time. Capture after using the same settings and deterministic data. Show the user a usable preview plus representative screenshots as work proceeds.
- A screenshot directory is evidence, not an approved baseline. The current inventory checker must be described precisely. Do not “fix” a changed screenshot by blindly accepting new baselines.
- If recurrent layout regressions justify pixel comparison, start with a few shared components or stable regions in the pinned Docker Chromium environment. Stabilize fonts, animation, seeded data, and volatile timestamps. Keep comparisons out of the blocking lane until repeatability is demonstrated. Zero-pixel whole-page equality across host platforms is inappropriate here.
- Prefer automatic overflow/occlusion/focus/state checks for objective failures. Use screenshots for composition and content hierarchy that those checks miss. Review long/empty/error text, not only the pleasing populated state.
- The working agent can inspect screenshots without invoking the repository's paid judge. Leave `OPS_UI_LLM_JUDGE=0` and `OPS_UI_LLM_JUDGE_REQUIRED=0` by default. No API key or recurring model budget is a prerequisite for acceptance.
- Record concrete findings and dispositions. Aesthetic uncertainty should become an early design decision or a nonblocking follow-up with rationale; do not attach routine human UAT to completed implementation. Never describe a mock judge pass or an unrun matrix as visual approval.

## Reusable commands

Commands below already exist. Run from repository root unless a working directory is stated. This report did not run them.

```sh
# Static token contrast, no browser/server required.
make -C examples/scrypath_ecommerce contrast

# Canonical standalone operator behavior/contracts; needs the documented Postgres setup.
mix verify.ops_ui

# Required mounted browser/integration subset; Docker owns isolated services and cleanup.
make -C examples/scrypath_ecommerce verify-mounted

# Full existing advisory browser, contrast, screenshots, and inventory parity lane.
OPS_UI_LLM_JUDGE=0 OPS_UI_LLM_JUDGE_REQUIRED=0 make -C examples/scrypath_ecommerce verify-e2e

# Persistent UI preview, separate from disposable verification projects.
make -C examples/scrypath_ecommerce docker-dev

# Current UI screenshot inventory against that already-running preview.
# WARNING: screenshot scenarios reseed the selected example instance.
make -C examples/scrypath_ecommerce screenshots-matrix
```

For a prepared disposable running server, these existing focused commands are useful from `examples/scrypath_ecommerce/` with `PLAYWRIGHT_BASE_URL` set to that server:

```sh
npx playwright test e2e/operator.spec.ts --workers=1 --retries=0
npm run test:e2e:admin-shell
npm run test:e2e:admin-contrast
npm run test:e2e:admin-light-parity
```

The app's AGENTS.md requires `mix precommit` after app changes; run it from `scrypath_ops/` and inspect any lock/format changes it makes. CONTRIBUTING requires warnings-as-errors when changing test support/infrastructure. The root required gate commands and two-stage `node scripts/ci_monitor.cjs closeout --push --branch <branch> --sha <full-sha>` remain canonical for final source receipts. Do not repeatedly dispatch the full release train while only iterating on copy/CSS.

## CI cost, diagnostics, and exit conditions

The required `ecommerce-mounted` job already starts Docker and executes `harness.spec.ts` plus `operator.spec.ts`. Replace or strengthen weak assertions and add the one recovery journey there; amortize the existing startup cost. The full `ecommerce-e2e` job runs on schedule/manual with `continue-on-error: true`; adding more scenarios there does not make them merge gates. The path-scoped Ops job currently selects `scrypath_ops/`, root `lib/`, and root Mix changes on PRs; example-only files rely on the mounted lane, and manual dispatch does not automatically select Ops tests. Record results accordingly.

Existing Playwright CI retries once and records traces on the first retry. A retry pass is flaky evidence under CONTRIBUTING, not a clean stability result. For the new journey, collect the first failure's state/task identities and screenshot, use a bounded timeout, and confirm it passes without retries before promoting a completion claim. Add trace retention for failure if needed; avoid making first-failure diagnostics depend solely on a rerun. Record the measured incremental duration after implementation rather than claiming a runtime budget from static inspection.

Milestone exit requires:

1. The agreed incident journey passes with a recoverable fixture and correlated job/task/index truth; retained failed history is explained accurately.
2. Changed screens/components use the established token/component vocabulary and coherent operator language; concrete visual review findings are resolved or explicitly bounded without pending routine UAT.
3. Relevant LiveView, token/contrast, browser layout/keyboard, both-theme and narrow/wide checks pass. Full-matrix evidence is cited only when actually run, with any advisory errors visible.
4. CI placement reuses existing lanes, has a stated cost/benefit, and requires no paid LLM judge. Useful diagnostics include source SHA, test identity, viewport/theme/state, action/work IDs, and failure trace/screenshots.
5. Before/after screenshots and verification receipts are discoverable without dumping generated files into tracked source. Seven-day hosted artifacts are referenced by run/artifact identity and enduring summaries where needed.
6. Disposable containers/networks/volumes and generated playbook fixtures are cleaned; only the intentionally retained user preview remains running and its stop command is recorded. No user-owned stack or unrelated worktree is reset.
7. The feature PR and exact final source evidence are reconciled; final GSD requirements/phase/milestone tracking reflects the same outcome. Final attested source receives no later tracked writes. Historical Phase 170 is not rerun.
8. Worktrees/branches/stashes are inventoried and only task-owned temporary state is removed. Runtime/package changes determine release readiness; a UI planning milestone alone does not justify a package release.

## Source map

Primary inspected sources: `CONTRIBUTING.md`; `scrypath_ops/AGENTS.md`; `.github/workflows/ci.yml`; `scrypath_ops/mix.exs`; `scrypath_ops/test/scrypath_ops_web/`; `scrypath_ops/assets/css/contrast-pairs.mjs`; `examples/scrypath_ecommerce/Makefile`, `package.json`, `playwright.config.ts`, `compose.e2e.yaml`, `scripts/verify-e2e.sh`, `docker-playwright.sh`, `docker-e2e-entrypoint.sh`, `e2e/`, and `lib/scrypath_ecommerce_web/controllers/e2e_controller.ex`; `lib/scrypath/operator/recovery_action.ex`; `lib/scrypath/oban/upsert_worker.ex`.
