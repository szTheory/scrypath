---
phase: "172"
slug: consistent-operator-ui-and-verified-recovery
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-03"
---

# Phase 172 — Validation Strategy

## Test Infrastructure

Existing ExUnit/Phoenix LiveView tests, static token and contrast contracts, Playwright mounted/full suites, and Docker Compose verifiers. Read CONTRIBUTING.md and `.planning/research/v1.42/UI-AUTOMATION.md` for canonical commands and actual proof boundaries. No framework installation or new required CI job.

## Sampling Rate

- After each behavior task, run focused existing/new ExUnit or browser assertions for that behavior.
- After each coherent wave, run `mix verify.ops_ui` (or its documented container equivalent); shared CSS also runs fast contrast/token checks.
- Final: existing required checks and `make verify-mounted` from `examples/scrypath_ecommerce`, plus one appropriate advisory visual run. No full matrix after every commit.
- Tests must fail on nonzero exit or no selected tests; arbitrary sleeps, optional Retry branches, prior successful tasks and generic existing documents do not prove recovery.

## Per-Task Verification Map

Each task owns its test additions; existing files are extended in place. New test/helper files are explicitly listed in their owning plan and created before its command. Commands execute at repository root. All checks reject nonzero exits and missing/zero selected required scenarios; no runtime pass is claimed here.

| Task | Requirements | Exact automated command(s) | Test paths / infrastructure | Threat Ref | Runtime |
| --- | --- | --- | --- | --- | --- |
|172-01-1|OPUX-01, OPUX-03, OPUX-07|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/control_room_live_test.exs`|`scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs`|T-172-01|pending|
|172-01-2|OPUX-01, OPUX-03, OPUX-07|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/design_tokens_contract_test.exs`<br>`make -C examples/scrypath_ecommerce contrast`|`scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs`|T-172-01|pending|
|172-02-1|OPUX-01, OPUX-02, OPUX-03|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/search_live_test.exs test/scrypath_ops_web/ops_a11y_contract_test.exs`|`scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/ops_a11y_contract_test.exs`|T-172-02, T-172-03|pending|
|172-02-2|OPUX-01, OPUX-02, OPUX-03|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/playbook_live_test.exs test/scrypath_ops_web/ops_a11y_contract_test.exs`|`scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`<br>`examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts`|T-172-02, T-172-03|pending|
|172-03-1|OPUX-03, OPUX-04|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops/operator_selection_test.exs`|`scrypath_ops/test/scrypath_ops/operator_selection_test.exs`|T-172-04, T-172-05|pending|
|172-03-2|OPUX-03, OPUX-04|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/failed_sync_live_test.exs test/scrypath_ops_web/live/posture_live_test.exs test/scrypath_ops_web/operator_ia_contract_test.exs`|`scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs`|T-172-04, T-172-05|pending|
|172-04-1|OPUX-04, OPUX-05, OPUX-06|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops/recovery_observation_test.exs test/scrypath_ops_web/live/failed_sync_live_test.exs`|`scrypath_ops/test/scrypath_ops/recovery_observation_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs`|T-172-06, T-172-07, T-172-08, T-172-09|pending|
|172-04-2|OPUX-04, OPUX-05, OPUX-06|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops/document_observation_test.exs test/scrypath_ops/recovery_observation_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs`|`scrypath_ops/test/scrypath_ops/document_observation_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`|T-172-06, T-172-07, T-172-08, T-172-09|pending|
|172-05-1|OPUX-03, OPUX-05, OPUX-07|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops/promotion_eligibility_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs`|`scrypath_ops/test/scrypath_ops/promotion_eligibility_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`|T-172-10, T-172-11|pending|
|172-05-2|OPUX-03, OPUX-05, OPUX-07|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/sync_drift_live_test.exs test/scrypath_ops_web/live/posture_live_test.exs test/scrypath_ops_web/operator_ia_contract_test.exs`|`scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`<br>`scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`|T-172-10, T-172-11|pending|
|172-06-1|OPUX-04, OPUX-05, OPUX-06, OPUX-07|`make -C examples/scrypath_ecommerce verify-mounted`|`examples/scrypath_ecommerce/e2e/helpers/e2e.ts`<br>`examples/scrypath_ecommerce/e2e/operator.spec.ts`|T-172-12, T-172-13, T-172-14|pending|
|172-06-2|OPUX-04, OPUX-05, OPUX-06, OPUX-07|`make -C examples/scrypath_ecommerce verify-mounted`|`examples/scrypath_ecommerce/e2e/operator.spec.ts`<br>`examples/scrypath_ecommerce/e2e/helpers/e2e.ts`|T-172-12, T-172-13, T-172-14|pending|
|172-07-1|OPUX-01, OPUX-02, OPUX-03, OPUX-07|`cd scrypath_ops && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/design_tokens_contract_test.exs test/scrypath_ops_web/ops_a11y_contract_test.exs`<br>`make -C examples/scrypath_ecommerce contrast`|`scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs`|T-172-15, T-172-16|pending|
|172-07-2|OPUX-01, OPUX-02, OPUX-03, OPUX-07|Prepared task-owned disposable server via `PLAYWRIGHT_BASE_URL` (never preview4012): `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --workers=1 --retries=0`<br>`OPS_UI_LLM_JUDGE=0 OPS_UI_LLM_JUDGE_REQUIRED=0 make -C examples/scrypath_ecommerce verify-e2e`|`examples/scrypath_ecommerce/e2e/helpers/operator-ui.ts`<br>`examples/scrypath_ecommerce/e2e/operator.spec.ts`<br>`examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts`<br>`examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts`<br>`examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts`|T-172-15, T-172-16|pending|
|172-08-1|OPUX-07, OPUX-08|`mix verify.ops_ui`<br>`cd scrypath_ops && mix precommit`|existing closeout/check infrastructure; planning artifacts authored in task|T-172-17, T-172-18, T-172-19|pending|
|172-08-2|OPUX-07, OPUX-08|`node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"`|existing closeout/check infrastructure; planning artifacts authored in task|T-172-17, T-172-18, T-172-19|pending|
|172-08-3|OPUX-07, OPUX-08|`node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"`<br>`git diff --exit-code HEAD`|existing closeout/check infrastructure; planning artifacts authored in task|T-172-17, T-172-18, T-172-19|pending|

The eight explicit UI truths in Plan07 cover all50pairs; 172-SOURCE-AUDIT.md maps each category and all7classified edges/5flagged classifier assumptions. Focused ExUnit cases include zero/one/many, Unicode identity, invalid/removed schemas, pending/errors/partial data, superseded generations and exact receipt joins. Browser cases own geometry/full keyboard cycles and the real service seam.

New paths created with behavior: `scrypath_ops/test/scrypath_ops/operator_selection_test.exs` (03-1), `recovery_observation_test.exs` (04-1), `document_observation_test.exs` (04-2), `promotion_eligibility_test.exs` (05-1) under that same directory; example `e2e_recovery.ex` (06-1) and `e2e/helpers/operator-ui.ts` (07-2). Existing test infrastructure is present; no empty scaffold qualifies as evidence. Commands involving service boot/hosted closeout may exceed60seconds and should yield while running. Cheap focused tests are the per-task feedback path.
## Wave 0 Requirements

Existing infrastructure is available. New tests/fixtures must be introduced with their owning behavior, listed explicitly by the planner; no empty stubs treated as coverage.

## Manual-Only Verifications

None. Direct agent screenshot inspection is part of the implementation review. Maintainer feedback is optional design direction, not pending acceptance.

## Validation Sign-Off

- [ ] Every planned task has an executable check and observable failure direction.
- [ ] Missing test/fixture paths are created by an explicit dependency.
- [ ] Sampling has no three consecutive tasks without automated verification.
- [ ] Runtime evidence covers each listed behavior at the changed source.
- [ ] Nyquist compliance audited after implementation; no planning-time pass claim.
