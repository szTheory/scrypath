---
phase: 172-consistent-operator-ui-and-verified-recovery
plan: "07"
subsystem: ui-acceptance
status: complete
requirements-completed: []
requirements-addressed: [OPUX-01, OPUX-02, OPUX-03, OPUX-07]
requires: [172-06]
provides:
  - Measured responsive controls, keyboard lifecycle and accessibility coverage.
  - Inspected before/after captures and resolved advisory regressions.
key-files:
  created:
    - examples/scrypath_ecommerce/e2e/helpers/operator-ui.ts
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/live/e2e_ui_fixture_live.ex
  modified:
    - examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts
    - examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts
    - examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/assets/js/ops_hooks.js
    - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
completed: 2026-10-04
plan_head_before: 0e4f033
plan_head_after: b454387
---

# Phase 172 Plan 07 summary

Completed the shared layer/type/control roles and measured five widths (320, 390, 1279, 1280, 1440), all six surfaces, explicit light/dark and system-dark, native radio/select branches, long text, real recovery, and complete file-dialog focus lifecycle. No paid judge, dependency or new required CI job was added.

## Commits and implementation

- `90c22d4`: named layer roles, actual modal90/120ms consumers and contracts.
- `4c7838b`: recorded real RED for the overlapping 390px header.
- `1b2287e`: two-row narrow header; 14px action/body and 16px card headings; 40px ordinary/44px theme targets; wrapping IDs and workspace path; labeled focusable bounded code regions; correct LiveView upload label; full modal cycles and stable filename-based row/focus identity; visible dialog validation errors; concise refresh/contract/handoff copy; readable semantic text on tinted status backgrounds.
- `b454387`: update nine old advisory expectations to the approved hierarchy/visible cause; canonical screenshot setup now owns clean settings using all_green; removed forced DOM-open and arbitrary sleep from capture.
- `76b4405`, `786f8ac`: review-discovered root corrections respectively deny cancelled/unknown target work and include deletion tasks, and expose the latest real Oban map error as the visible bounded cause. Plan08 review details these source-bounded fixes; they warrant a core patch release decision.
- `1b2287e` also resolves review findings: successful rename returns to a stable heading; modal errors are inside the active dialog; promotion read/transport/invalid/exit errors remain unconfirmed, while only exact-UID terminal failed/cancelled tasks get failure copy.

New helpers: `assertOperatorGeometry`, `assertReadableControl`, `assertDialogCycle`, `scanNonContrastA11y`; private LiveView fixture uses five constant modules and no backend/global configuration mutations. The fixture route is dev/test only. Existing token palette and 48-component catalog remain authoritative.

## Executed evidence

- Initial 390px geometry RED measured overlapping Jump/theme controls; corrected focused header passed. Tailwind utility-layer precedence was diagnosed, not suppressed.
- Focused final six-case run: five passed including both real service journeys and mobile overlay/full focus cycles; the new common-action check exposed an incorrect selector then a missing height utility. Corrected geometry/common-action/axe test passed all five widths (`phase172-07-action-boundaries2.log`, 1/1, 10.9s).
- Full shell exploratory run: 33/37 passed, four dark-theme Posture contrast failures. Corrected semantic link color and exact selector; six affected shared-surface theme/viewport cases passed (`phase172-07-shell-shared3.log`, 6/6, 27.6s).
- Rename correction: 1/1 browser pass. Dialog error RED21/2 → GREEN21/0 ExUnit; invalid-path→corrected-success browser1/1 (`phase172-07-dialog-validation.log`). Promotion unknown-state RED17/1 → GREEN17/0 (`phase172-promotion-observation-{red,green}.log`). Root target readiness RED19/2 → GREEN19/0; latest error cause RED16/2 → GREEN16/0.
- Final Ops `mix verify.ops_ui` and `mix precommit`: each **233 tests + 2 doctests, zero failures** (`phase172-08-ops-ui.log`, `phase172-08-precommit.log`). Pinned Elixir1.19.5/OTP28.5, task-local HEX_HOME, ERL_FLAGS='+S 1:1'. The pre-existing optional-dependency Sync typing warning remains; own warnings-as-errors checks passed.
- One canonical local broad run: `OPS_UI_LLM_JUDGE=0 OPS_UI_LLM_JUDGE_REQUIRED=0 KEEP_E2E_STACK=1 make -C examples/scrypath_ecommerce verify-e2e`, source **1b2287ed598ef6e9025e95f2db1b727e70eeb17f**, fresh project `scrypath_ecommerce_verify_full_1b2287ed_97290`. **95 passed, 9 failed, zero retries/skips/flakes, 283.0s browser runtime**. All38 shell checks, all three contrast scenarios, both exact recovery/promotion journeys and all40 matrix captures passed. Overall command exited1; it is not reported as a fully green run.
- All nine failures were old expectations: removed copper badge (4), removed promotion-preflight cards (4), generic queue-job-failed text (1). After source-specific test fixes, **9/9 passed in10.1s**, retries0 (`phase172-07-advisory-corrections.log`). No product source changed after the broad run. The unaffected95 plus corrected9 cover the local suite; Plan08 hosted exact-source validation must still establish its canonical all-green result.
- Broad static contrast: **0 AA failures, 36 AAA advisories**. Browser contrast incident/all_green/empty all pass; incomplete contrast findings remain in JSON. Light screenshot inventory:20/20, which checks files/widths and is not pixel parity. Paid judge was skipped by explicit flags, not reported as visual approval.

Logs live outside tracked source under `/private/tmp/phase172-*`. Canonical reports/captures: `examples/scrypath_ecommerce/test-results/docker-full/test-results/` (ignored). First failures/traces are retained. Test-only corrections ran in the separate retained debug stack, never concurrently against the canonical stack's mutable state.

## Direct visual inspection and limits

Parent directly inspected baseline390px light FailedSync/SyncDrift, current390px light six-screen captures, canonical light FailedSync and dark SyncDrift. FailedSync now exposes causes/actions above Diagnostics and reduces six tall rollups to total+five reason chips; typography is legible and primary actions wrap. SyncDrift prioritizes read-only status/contract, collapses advanced promotion, and links back to ordinary health checks. Dialog focus and naming are measured separately; screenshots alone do not establish semantics.

Before: `/private/tmp/scrypath-v142-review/`, source3c83a58, initial demo incident,390px. After: canonical1b2287e40-shot matrix plus `/private/tmp/phase172-07-final-images/`. Theme/viewport/routes match for light comparisons; timestamps/job IDs vary. SyncDrift baseline had contract not yet loaded while the canonical drift capture loads it; only hierarchy/reflow is compared across those states, not identical-data pixel parity. Both light/dark/current states have executable contrast/geometry evidence. No blanket visual-perfection claim or fabricated judge approval.

## Deviations / durable lessons

The frozen failure taxonomy has five reason classes: the old six-card wording meant total+five, now clarified in PLAN/UI-SPEC/SOURCE-AUDIT without inventing a class. Contrast uses existing measured base-content pairs; no new palette pair required. Additional owning files are the shared layouts/OpsUi, Playbooks/Posture/FailedSync/SyncDrift and their existing tests, plus example dev/test route/fixture and legacy capture/depth specs. These were necessary fixes exposed by the planned browser/review evidence.

Use actual generated CSS and rendered LiveView IDs as authority. Utility classes without a declared token emit nothing. Focus restoration must wait for patch completion and preserve object identity, with a successor when rename/delete removes the trigger. Validation errors must live inside an inert modal boundary. Polling failure is an unknown remote outcome, not a failed remote operation.

Preview4012 was refreshed without seeding/resetting and returnsHTTP200. Both named disposable stacks remain for artifact collection and must be removed during Plan08. Requirements remain open until reviewed hosted delivery; no routine human UAT is pending.

## Hosted acceptance established by Plan 08

Corrected candidate `135517b2aa7d1515a4be71c4f9d53aa8dd60c341` passed full advisory **104/104** and mounted **4/4**, with retries disabled, in run [37178388184](https://github.com/szTheory/scrypath/actions/runs/37178388184). Static AA failures: 0; light capture inventory: 20/20. This succeeds the failed local broad run without rewriting its result. The candidate receipt and directly inspected image dispositions are in `172-EVIDENCE.md`. Both disposable verifier stacks were removed after artifact collection; preview 4012 remains available without reseeding.
