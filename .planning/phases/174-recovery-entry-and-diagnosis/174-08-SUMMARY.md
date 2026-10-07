---
phase: 174-recovery-entry-and-diagnosis
plan: 08
subsystem: recovery-acceptance
tags: [playwright, liveview, ops-ui, recovery, compose]
dependency_graph:
  requires: [174-05, 174-06, 174-07]
  provides: [phase174-dual-entrypoint-browser-proof, validated-standalone-recovery-target, scoped-compose-cleanup]
  affects: [mounted-ops, standalone-ops, recovery-navigation]
tech_stack:
  added: []
  patterns: [isolated-dual-entrypoint-compose-runner, source-named-playwright-captures, active-allowlist-target-resolution]
key_files:
  created:
    - examples/scrypath_ecommerce/compose.phase174.yaml
    - examples/scrypath_ecommerce/scripts/phase174-standalone-entrypoint.sh
    - examples/scrypath_ecommerce/scripts/verify-phase174.sh
    - examples/scrypath_ecommerce/e2e/phase174_recovery.spec.ts
    - .planning/phases/174-recovery-entry-and-diagnosis/174-08-RED-EVIDENCE.md
  modified:
    - examples/scrypath_ecommerce/docker-playwright.sh
    - scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex
    - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - scrypath_ops/assets/css/app.css
decisions:
  - Resolve the shell recovery target against the LiveView's active validated allowlist, falling back to the host-configured allowlist when no route assignment exists.
  - Configure the Phase174 standalone test host with its two fixture schemas; keep that test-only allowlist out of ordinary runtime configuration.
  - Give the prominent Control Room health action the existing medium link treatment and the existing 44px touch token locally.
metrics:
  duration: 126m
  completed_date: 2026-10-07
  tasks: 2
  files: 10
  commits: 5
  plan_head_before: 42b342e0d16ef3c64a31aa2f60128efcb0c10ac6
  plan_head_after: d197656594fd727880ebdd4ed578a90e0b68dd58
  status: complete
actuals:
  tokens: 8075
  tasks: 2
  commits: 5
---

# Phase 174 Plan 08: Dual-entrypoint recovery proof Summary

Mounted and standalone Ops recovery now have an isolated executable browser lane proving schema-bound recovery navigation, explicit Gating return behavior, and responsive operator controls.

## Delivered

- Added a unique, task-owned Compose runner and standalone Ops entrypoint, a dedicated `phase174-recovery` browser dispatch, artifact collection, and scoped cleanup. The stack uses separate web dependency and standalone Ops build volumes to avoid concurrent Mix compilation collisions; it publishes no port 4012.
- The mounted browser journey selects a non-first target while another schema has worse posture, follows rendered health and failed-work links, retries eligible work, and checks the accepted replacement receipt without claiming terminal completion. It also verifies Back/reload, invalid target handling, focus, theme, and palette href changes.
- The standalone journey patches selection from A to B and asserts all three rendered palette destinations contain B. It exercises the real Gating interruption and return URL, confirms the selected allowlisted schema survives, returns without replay, and reaches the gate again only after a second deliberate click. This does not prove host login or sudo approval.
- Added a narrow `OnMount` regression fix: the recovery target now resolves against the validated allowlist assigned by the active LiveView, falling back to the configured host allowlist. The standalone fixture modules are exposed only through its Phase174 test-host environment. Gating's canonical validation remains in force.
- The actual mounted and standalone Control Room primary health action measured 40px before the fix, below the UI-SPEC's 44px prominent target. A focused browser geometry assertion failed on both entrypoints, then the action was moved to the existing medium size and given the existing 44px token through a local selector. Standard command and theme controls remain asserted at 40px.

## Task Commits

1. **Task 1: Isolated browser runner and standalone manifest proof** — `c9f8c23` (already-green runner baseline), `c34c9dd` (standalone manifest RED), `54d8244` (manifest GREEN).
2. **Task 2: Dual-entrypoint prominent-action proof** — `54c623e` (44px RED), `d197656` (44px GREEN).
3. **Task 1: Parent integration follow-ups within Phase174** — `e8db6a8` (shared Oban test fixture), `0b09182` (supervised fixture cleanup), `5c48f3e` (mixed-source copy RED), `08f0d07` (mixed-source copy GREEN).
4. **Task 2: Parent Nyquist follow-up** — `1020ace` (expanded browser/fixture coverage and native focus RED), `d4395f2` (schema-keyed render; native focus GREEN). `024a450` corrects fixture marker preservation, complete success timestamps, long reason fixtures, native LiveView readiness, truthful bounded-reason assertions, and transport-independent pending-refresh proof. The expanded lane passes 11/11 after these corrections.
5. **Task 2: Parent review and regression follow-up** — `a738577` adds connected removal and status handoff regression tests; `973813d` qualifies receipt/expected-effect identity by source and ID and resolves current shell allowlists; `e286962` makes test fixture allowlist reads side-effect free; `8721014` / `85afb35` / `50b3310` align prior operator/browser selectors with the approved labels and observed metric presentation. Original task history and the Phase173 checkout remain unchanged.


Original plan task count and five task commits above remain the original executor ledger; additional parent integration and validation follow-ups are named separately and do not assert a new plan or fabricated RED history. Commit labels now use the runtime owner's `**Task N:` grammar so the phase evaluation scope includes the actual source, tests, and harness rather than silently dropping RED/GREEN-labelled rows.

## Verification

- Final browser command: `PATH=/Users/jon/.asdf/installs/elixir/1.19.5-otp-28/bin:/Users/jon/.asdf/installs/erlang/28.4.1/bin:$PATH HEX_HOME=/private/tmp/scrypath-phase173-20261006-155750/hex-home MIX_ENV=test MIX_TEST_PARTITION=174_wave1 DOCKER_CONFIG=/private/tmp/scrypath-phase173-20261006-155750/docker-config DOCKER_HOST=unix:///Users/jon/.docker/run/docker.sock PHASE174_PROJECT_ID=scrypath_phase174_54c623ee35_recovery_final2 ./scripts/verify-phase174.sh recovery` — **4 Chromium tests passed, 0 failed, 0 skipped** (20.2 seconds). The browser checks include the three hard palette href assertions in each entrypoint, selected-schema updates, real recovery and Gating paths, 14px essential text, standard 40px and prominent 44px targets, no horizontal overflow, keyboard focus, light/dark/System preference, and reduced motion.
- Captures: `examples/scrypath_ecommerce/test-results/phase174-recovery-54c623ee35/test-results/phase174-captures/` contains 48 PNGs (Control Room, Search health, Failed sync work × mounted/standalone × 1440/1280/1279/390 × light/dark). Representative mounted desktop and standalone 390px dark captures were visually inspected after the final 44px correction; browser geometry checks cover the entire capture matrix.
- Runner metadata: `source-sha.txt` records `54c623ee35724935f5632b63a55afef5ad65b66c`; `worktree-diff-sha256.txt` records `366518eaa3dc2c1467adae783c466a9a70bc455d1347d7943aba4a2b83edd19f`, which matches the final production commit's content diff from that source HEAD (`d197656594fd727880ebdd4ed578a90e0b68dd58`). `cleanup.txt` reports `cleanup_status=0` for project `scrypath_phase174_54c623ee35_recovery_final2`.
- `mix verify.ops_ui` passed **2 doctests + 272 tests, 0 failures**. `cd scrypath_ops && mix precommit` passed the same **2 doctests + 272 tests, 0 failures**. Both used a disposable PostgreSQL container on port 55493 after an initial parallel attempt hit the shared local PostgreSQL `too_many_connections` limit. The isolated database and network were removed after the checks.
- `make contrast` passed with **0 AA failures** and **35 AAA advisory findings**.
- Docker audit after cleanup found no Phase174-named containers, volumes, or networks. `scrypath-ui-v142-web-1` remains on port 4012; the original preview was preserved.

## TDD Gate Compliance

- The mounted palette baseline was already green (1/1) on source `42b342e`; Plan 174-07's `Layouts.app` wiring already forwarded the target and rendered the server-owned manifest. Earlier apparent failure was a harness/locator setup mistake, not missing `Layouts.app` production wiring.
- The standalone manifest target test produced a separate intentional RED before the `OnMount` fix: selector and URL settled on `ScrypathOps.Test.OpsPostB` while the validated server manifest and palette href remained unscoped. The native result was 1 failed target test; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`. Test/evidence commit: `c34c9dd`; production fix: `54d8244`.
- The prominent-action assertion produced an additional intentional RED: JUnit recorded 4 tests, 2 passed and 2 failed on the expected 40px measured height (0 skipped). Its record also classified `RED_EVIDENCE_OK`. Test/evidence commit: `54c623e`; production adjustment: `d197656`.
- The earlier standalone Gating failure was a test-host fixture mismatch: its Phase174 view had an A/B test allowlist while the standalone application host was configured with none. The production Gating behavior correctly rejected the target. The host now receives the same fixture allowlist via test-only environment configuration; no raw-query bypass or production Gating weakening was added.

## Deviations from Plan

**1. [Rule 1 - Bug] Resolve recovery targets against the active validated allowlist**
- **Found during:** T1 standalone manifest proof.
- **Issue:** `Live.OnMount` used the global schema allowlist instead of the current LiveView's validated fixture allowlist, dropping B from the server-owned manifest.
- **Fix:** Prefer the route-assigned validated allowlist and retain configured allowlist fallback; add a focused standalone regression.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex`, `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs`, `examples/scrypath_ecommerce/compose.phase174.yaml`, `examples/scrypath_ecommerce/e2e/phase174_recovery.spec.ts`, and the Phase174 browser dispatch/runner files.
- **Commit:** `54d8244`.

**2. [Rule 1 - UI contract] Raise the prominent Control Room health action to 44px**
- **Found during:** T2 final rendered geometry matrix.
- **Issue:** The primary health action rendered at 40px despite the 44px prominent-target contract.
- **Fix:** Use the existing medium link size and apply the existing large control-height token only to this action; assert it in both entrypoints.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex`, `scrypath_ops/assets/css/app.css`, `examples/scrypath_ecommerce/e2e/phase174_recovery.spec.ts`.
- **Commit:** `d197656` (test/evidence commit `54c623e`).

## Verification Boundaries

The final focused browser run covers the plan's dual-entrypoint recovery and geometry matrix; it does not assert each of the 30 UI-SPEC state rows individually in the browser, so this summary does not claim a separate browser proof for every row. The canonical Ops test suite passed. The standalone return test does not verify host authentication or approval, and this work does not claim the broader advisory ecommerce browser lane, Cloak advisory remediation, hosted exact-SHA evidence, phase completion, or release readiness. Existing warnings during Ops verification included the `Scrypath.Sync.sync_related/3` type warning and the locked `cloak` / `cloak_ecto` advisories; they were outside this plan's source scope.

## Self-Check: PASSED

The task commits are present, the summary path exists, the final successful JUnit has four cases with zero failures/skips, the capture directory contains 48 images, and all task-owned Docker resources were removed. Phase-level requirements and independent verification remain pending.

## Parent validation closeout evidence

The expanded final lane passes 11 native Chromium cases, zero failures/errors/skips (40.8s), with 48 actual AFTER captures. `174-FINAL-BROWSER.xml` and `174-FINAL-EVIDENCE.json` preserve the native report and exact local source boundary. Schema-keyed rendering passes the previously failing real refresh/reorder focus assertion. Retained/error/unknown/no-success/empty/long states, exact delete scope, real pending refresh/retry, target/history, drawer, and palette filter/clear assertions execute. Pending refresh uses a deliberately delayed real source observation; pending retry holds the actual WebSocket response. Neither uses fabricated browser DOM or a fake hook. Parent Ops precommit and root `mix verify.ops_ui` each pass272tests+2doctests/0; core regression passes661tests+4properties/0; contrastAA0/AAA35. Full hosted final-source closeout remains pending.

## Final review follow-up

Independent code review found CR-01 retry-handoff identity collision and WR-01 stale shell allowlists; both are fixed with behavioral regressions. Final-source Ops precommit: 275 tests + 2 doctests, zero failures. Root verify.ops_ui at 973813d: same count; the later e286962 fixture change passes Ops precommit and the actual 11/11 browser lane, with 48 AFTER captures in the updated final evidence. Core regression at 973813d: 661 tests + 4 properties, zero failures (85 excluded). The initial rerun used an older cached browser spec, then a fresh rerun exposed doubled fixture observation consumption; both failed reports are retained separately and not counted as final success. Independent goal verification and hosted two-stage closeout remain pending.

Prior-phase regression: 34 unique cases have passing evidence across a native 32/34 full run and a 2/2 focused rerun after aligning the removed queue-observed prose assertion with all three observed zero queue metrics. Exact full/focused reports and case identity reconciliation are retained in 174-REGRESSION-EVIDENCE.json; no single green 34-case report is claimed. The actual mounted retry reaches Recovery verified from its exact replacement job, backend task and document.
