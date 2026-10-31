---
phase: "184"
slug: "explicit-and-lean-dependency-graphs"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-29"
---

# Phase 184 — Validation Strategy

> Coverage audit completed after all twelve execution plans. Automated behavior, mutation, consumer, image, and hosted checks exist for every requirement. This coverage result does not accept the remaining Ops advisories or replace terminal merged-branch closeout.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | Existing ExUnit/Mix, Node node:test, Docker/Compose and Playwright infrastructure |
| Configuration | Root and Ops mix.exs; examples/scrypath_ecommerce Docker/E2E configuration |
| Quick command | `mix test --exclude integration --exclude docs_contract` |
| Full scope | Existing `mix verify.core --exclude integration --exclude docs_contract`, `mix verify.package`, `mix verify.repository_contracts`, `mix verify.backend`, `mix verify.ecommerce_mounted`, `mix verify.ops_ui`; changed advisory compatibility/deep-quality/browser lanes |
| Toolchain | Preserve canonical 1.17/26, 1.18/27, 1.19/26 and 1.19/28 tuples; exercise Sigra on its declared Elixir 1.18+ tier separately |
| Runtime estimate | Unmeasured. Budget focused unit checks for 60 seconds; cold consumer, image, browser and hosted checks require separate bounded runs and receipts |

## Sampling Rate

- Each implementation task runs its narrow automated test/compiler predicate before commit. No three consecutive tasks may lack automated verification.
- Each wave runs its affected canonical gates; a fast root test run cannot replace consumer, independent-lock, optional-dependency or asset-image proof.
- Final execution closeout follows CONTRIBUTING.md on the exact final SHA after tracked evidence/report writes. Keep runtime receipts outside the checkout and preserve real exit/status values.
- Required merge jobs remain core, package, repository-contracts, backend and ecommerce-mounted. Do not add required jobs.
- A failed advisory audit remains failed and explicit. Collect independent analysis results so the audit cannot conceal whether Dialyzer ran. No new ignores or swallowed exits.

## Per-Task Verification Map

Final mapping: 12 plans, 24 tasks, 11 waves. Every new test is created in its owning task before its first invocation. The task rows below were reconciled against all twelve committed summaries and the corrected candidate hosted receipt. Each task has runnable automated coverage and recorded successful behavior evidence. The nonzero Ops advisory result remains explicit.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 184-01-01 | 01 | 1 | DEP-01, DEP-02 | T-184-01 | Actual metadata/direct declaration mutation and public installed search span | package integration | `MIX_ENV=test mix test test/release/consumer_smoke_test.exs test/release/package_metadata_test.exs --warnings-as-errors` | Existing; extended here | verified — [plan 01 evidence](184-01-SUMMARY.md); corrected candidate required checks passed |
| 184-01-02 | 01 | 1 | DEP-02 | T-184-02 | Independent 0.6.x/0.7.x locks and same public request/result/events | consumer integration | `mix verify.package` | Existing; extended here | verified — [plan 01 evidence](184-01-SUMMARY.md); corrected candidate required checks passed |
| 184-02-01 | 02 | 2 | DEP-03 | T-184-03 | Exact declaration/module/test source removals; compile deferred to coherent boundary | source | `python3 -c 'from pathlib import Path; import re; manifests=["scrypath_ops/mix.exs","examples/scrypath_ecommerce/mix.exs"]; leaked=[p for p in manifests if re.search(r"\{\s*:swoosh\s*,","\n".join(l for l in Path(p).read_text().splitlines() if not l.lstrip().startswith("#")))]; assert not leaked, leaked; assert not Path("scrypath_ops/lib/scrypath_ops/mailer.ex").exists(); assert not Path("scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs").exists(); print("mail-declarations-and-source-removed")'` | Existing | verified — [plan 02 evidence](184-02-SUMMARY.md); corrected candidate required checks passed |
| 184-02-02 | 02 | 2 | DEP-03 | T-184-03 | Five active Ops mail configurations removed; source/syntax only | source/config | `python3 -c 'from pathlib import Path; files=[Path("scrypath_ops/config")/n for n in ["config.exs","dev.exs","test.exs","prod.exs","runtime.exs"]]; leaked=[str(p) for p in files if any("swoosh" in line.lower() or "ScrypathOps.Mailer" in line for line in p.read_text().splitlines() if not line.lstrip().startswith("#"))]; assert not leaked, leaked; print("five-mail-configs-cleared")'` | Existing | verified — [plan 02 evidence](184-02-SUMMARY.md); corrected candidate required checks passed |
| 184-08-01 | 08 | 2 | DEP-07 | T-184-16, T-184-17 | Action runner/runtime/pins and cache trust | unit/contracts | `node --test scripts/ci/beam_cache.test.cjs` | Existing; new Actions ledger here | verified — [plan 08 evidence](184-08-SUMMARY.md); corrected candidate required checks passed |
| 184-08-02 | 08 | 2 | DEP-07 | T-184-16 | Six-workflow permissions/credentials/event preservation | unit/contracts | `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs` | Existing | verified — [plan 08 evidence](184-08-SUMMARY.md); corrected candidate required checks passed |
| 184-11-01 | 11 | 3 | DEP-03 | T-184-22 | Scoped negative mail contracts wired to repository lane | unit | `MIX_ENV=test mix test test/mix/tasks/dependency_boundary_contract_test.exs --warnings-as-errors` | NEW; created in this task | verified — [plan 11 evidence](184-11-SUMMARY.md); corrected candidate required checks passed |
| 184-11-02 | 11 | 3 | DEP-03 | T-184-22 | Actual Ops startup/test and ecommerce compile after all configuration/routes removed | compile/start | `mix verify.ops_ui`; `(cd examples/scrypath_ecommerce && MIX_ENV=test mix do deps.get + compile --warnings-as-errors)` | Existing applications; contract created by 184-11-01 | verified — [plan 11 evidence](184-11-SUMMARY.md); corrected candidate required checks passed |
| 184-03-01 | 03 | 4 | DEP-04 | T-184-04 | Diagnostic imports/modules/plug/child compile safely by capability | compile/start | `mix verify.ops_ui` | Existing | verified — [plan 03 evidence](184-03-SUMMARY.md); corrected candidate required checks passed |
| 184-03-02 | 03 | 4 | DEP-04 | T-184-04, T-184-05 | Host ownership, routes and core children remain tested | unit/runtime | `mix verify.ops_ui` | Existing | verified — [plan 03 evidence](184-03-SUMMARY.md); corrected candidate required checks passed |
| 184-04-01 | 04 | 5 | DEP-06 | T-184-06 | Unavailable requested Sigra rejected before startup | unit | `mix verify.ops_ui` | Existing; absent VM in 184-06-01 | verified — [plan 04 evidence](184-04-SUMMARY.md); corrected candidate required checks passed |
| 184-04-02 | 04 | 5 | DEP-06 | T-184-07, T-184-08 | Malformed context never invokes callback; sudo/audit identity | unit | `mix verify.ops_ui` | Existing; extended here | verified — [plan 04 evidence](184-04-SUMMARY.md); corrected candidate required checks passed |
| 184-05-01 | 05 | 6 | DEP-04, DEP-05 | T-184-09 | Dev tools/host diagnostics scoped; exact direct Req/Telemetry | unit/config | `MIX_ENV=test mix test test/mix/tasks/dependency_boundary_contract_test.exs --warnings-as-errors` | Created by 184-11-01 | verified — [plan 05 evidence](184-05-SUMMARY.md); corrected candidate required checks passed |
| 184-05-02 | 05 | 6 | DEP-05 | T-184-10 | Explicit production runtime inputs/manifest source assertions; actual digest follows handoff | unit/config | `MIX_ENV=test mix test test/mix/tasks/dependency_boundary_contract_test.exs --warnings-as-errors` | NEW prod config created here; contract from 184-11-01 | verified — [plan 05 evidence](184-05-SUMMARY.md); corrected candidate required checks passed |
| 184-12-01 | 12 | 7 | DEP-05 | T-184-09 | Output-only builder transfer and independent target compile | Docker integration | `docker build --target runtime_test -f examples/scrypath_ecommerce/Dockerfile .`; `docker build --target runtime_prod -f examples/scrypath_ecommerce/Dockerfile .`; `mix verify.ecommerce_mounted` | Existing; extended here | verified — [plan 12 evidence](184-12-SUMMARY.md); corrected candidate required checks passed |
| 184-12-02 | 12 | 7 | DEP-05 | T-184-09 | Static handoff mutation contracts reject dev-tree transfer and stale runtime generation | unit/config | `bash examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh --static-contract-only` | NEW script created before invocation here; contract from 184-11-01 | verified — [plan 12 evidence](184-12-SUMMARY.md); corrected candidate required checks passed |
| 184-06-01 | 06 | 8 | DEP-03, DEP-04, DEP-06 | T-184-11 | Real clean dev/test/prod/mounted modes and absent Sigra callbacks | consumer integration | `MIX_ENV=test mix test test/release/ops_dependency_boundary_test.exs --include integration --warnings-as-errors` | NEW test created/wired here | verified — [plan 06 evidence](184-06-SUMMARY.md); corrected candidate required checks passed |
| 184-06-02 | 06 | 8 | DEP-04, DEP-05 | T-184-12, T-184-13 | Clean test/prod graph/app/start and four served bundle digests | Docker integration | `bash examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh --runtime` | Script from 184-12-02; runtime mode added here | verified — [plan 06 evidence](184-06-SUMMARY.md); corrected candidate required checks passed |
| 184-07-01 | 07 | 9 | DEP-01, DEP-02, DEP-07 | T-184-14 | Root stable versions, tooling/properties/docs/analysis | matrix/integration | `mix verify.package; mix dialyzer` | Existing; new evidence ledger here | verified — [plan 07 evidence](184-07-SUMMARY.md); corrected candidate required checks passed |
| 184-07-02 | 07 | 9 | DEP-03, DEP-06, DEP-07 | T-184-14, T-184-15 | Three independent app locks/Bandit fix/Sigra tier | matrix/integration | `mix verify.ops_ui; mix verify.backend; mix verify.ecommerce_mounted` | Existing | verified — [plan 07 evidence](184-07-SUMMARY.md); corrected candidate required checks passed |
| 184-09-01 | 09 | 10 | DEP-01, DEP-02, DEP-06, DEP-07 | T-184-18 | Current support/security truth separate from historical records | docs/unit | `mix docs --warnings-as-errors` | Existing | verified — [plan 09 evidence](184-09-SUMMARY.md); corrected candidate required checks passed |
| 184-09-02 | 09 | 10 | DEP-04, DEP-05, DEP-07 | T-184-19 | Actual builder/runtime/capability commands centralized | docs/contracts | `mix verify.repository_contracts` | Existing | verified — [plan 09 evidence](184-09-SUMMARY.md); corrected candidate required checks passed |
| 184-10-01 | 10 | 11 | DEP-01–DEP-07 | T-184-20 | Four raw audits/all ten dispositions/support tuple identity | unit/audit/matrix | `MIX_ENV=test mix test test/mix/tasks/dependency_audit_test.exs test/mix/tasks/dependency_boundary_contract_test.exs --warnings-as-errors` | Existing; evidence tests extended here | verified — [plan 10 evidence](184-10-SUMMARY.md); corrected candidate required checks passed |
| 184-10-02 | 10 | 11 | DEP-01–DEP-07 | T-184-21 | Exact final tracked SHA after all reports; immutable hosted receipts | hosted closeout | `node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"` | Existing | verified — [plan 10 evidence](184-10-SUMMARY.md); corrected candidate required checks passed |

## Wave 0 Requirements

- Extend the existing built/unpacked package harness for independent Req 0.6.x/0.7.x consumers, actual-version assertions, public HTTP behavior and Telemetry events. Preserve no-Oban and repository-tooling exclusions.
- Extend existing Ops tests with compile/start/route boundaries, no-Sigra negative cases and total fail-closed malformed operator-context cases; avoid dependencies added solely as a harness architecture.
- Add clean test/prod asset graph and serving checks for both Ops and storefront outputs. Trace output/digest ownership before naming copy paths.
- Retain complete source/manifest/lock/toolchain identities, raw per-graph audit outputs and all ten PR dispositions; preserve existing audit semantics.
- Reuse existing toolchain/service/Docker setup. Never use dirty build caches as dependency-absence evidence.

## Manual-Only Verifications

No post-implementation human gate is part of acceptance. Rendered UI preservation review follows the repository's named-preview and full-inventory rules where applicable, remains honest about independent-review limits, and cannot replace executable checks. No retained-preview restart/reseed or unreviewed baseline update is authorized.

## Validation Sign-Off

- [x] All tasks have runnable `<automated>` verification with adjacent `<fails_when>`, or explicit Wave 0 creation dependencies.
- [x] Final plan/task/wave and unique threat mappings replace provisional IDs above.
- [x] Sampling continuity holds; missing tests are created before use.
- [x] No watch-mode commands or silent/no-op acceptance checks.
- [x] Clean installed-consumer, test/prod image and supported-tuple predicates are explicit.
- [x] Final exact-source checks and remaining audit failures are recorded at execution.
- [x] `nyquist_compliant: true` is set only after validation audit establishes compliance.

**Coverage audit:** Verified 2026-10-30 from executable tests and actual receipts; no human approval or security-risk acceptance is implied.

The corrected candidate [hosted run](https://github.com/szTheory/scrypath/actions/runs/41029783634) passed the five required jobs, coverage, closeout attestation, all four compatibility tuples, Phoenix, full ecommerce E2E, and Ops UI. Its immutable identities are recorded externally at `/private/tmp/scrypath-phase184-10-20261030T072352Z/receipts/candidate-2-final.json`. The merged checkout fast suite also passed. Terminal closeout of the final merged branch remains a distinct final step after all tracked reports.

No automated requirement is delegated to post-implementation human UAT. Current rendered review of the retained preview remains unavailable because its source preflight refuses stale provenance; this is an explicit UI evidence limit, not a passing design review. The two known Ops Cloak findings remain unaccepted and keep the aggregate audit nonzero.

## Validation Audit 2026-10-30

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Validation Audit 2026-10-31

| Metric | Count |
|---|---|
| Gaps found | 6 |
| Resolved | 6 |
| Escalated | 0 |
