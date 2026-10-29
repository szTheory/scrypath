---
phase: "184"
slug: "explicit-and-lean-dependency-graphs"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-29"
---

# Phase 184 — Validation Strategy

> Execution validation contract. Planning has not run implementation tests or established implementation acceptance.

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

The planner must replace provisional slice IDs with final plan/task/wave IDs and unique threat references before planning closes. Every added test path must be produced by an earlier or same task.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| consumer-slice | pending | pending | DEP-01, DEP-02 | pending | Direct mandatory Telemetry in archive; two independently resolved non-overriding Req witnesses exercise identical public HTTP/telemetry behavior | package integration | `mix verify.package` | Existing harness; extension required | pending |
| ops-boundary | pending | pending | DEP-03, DEP-04 | pending | Mounted dependency graphs omit Ops diagnostic/mail slice; clean direct dev diagnostics and core telemetry remain functional | unit/compile/start | `mix verify.ops_ui` and `mix verify.ecommerce_mounted` | Existing seams; clean consumer probes required | pending |
| asset-boundary | pending | pending | DEP-05 | pending | Both current-source bundles served from independently resolved test/prod targets; no dev deps/BEAM/config transfer | image/build/serve | `mix verify.ecommerce_mounted` plus task-owned clean target proofs | Existing Docker/E2E seams; target proof extension required | pending |
| optional-auth | pending | pending | DEP-06 | pending | Requested unavailable Sigra errors; missing/invalid context never invokes callback; sudo/impersonation/audit identity preserved | unit/isolated consumer | `mix verify.ops_ui` plus task-owned no-Sigra compile/start proof | Existing auth tests; dependency-absent probe required | pending |
| graph-updates | pending | pending | DEP-07 | pending | Four independent final locks, ten PR dispositions, audit failures and support truth retained | repo/audit/matrix | `mix verify.repository_contracts`, `mix verify.deep_quality`, `mix verify.compatibility` | Existing infrastructure; evidence extension required | pending |
| final-source | pending | pending | DEP-01–DEP-07 | pending | Exact-source hosted closeout; no pending UAT or invented approval | integration/CI | CONTRIBUTING.md exact-source closeout command | Existing collector/attestor | pending |

## Wave 0 Requirements

- Extend the existing built/unpacked package harness for independent Req 0.6.x/0.7.x consumers, actual-version assertions, public HTTP behavior and Telemetry events. Preserve no-Oban and repository-tooling exclusions.
- Extend existing Ops tests with compile/start/route boundaries, no-Sigra negative cases and total fail-closed malformed operator-context cases; avoid dependencies added solely as a harness architecture.
- Add clean test/prod asset graph and serving checks for both Ops and storefront outputs. Trace output/digest ownership before naming copy paths.
- Retain complete source/manifest/lock/toolchain identities, raw per-graph audit outputs and all ten PR dispositions; preserve existing audit semantics.
- Reuse existing toolchain/service/Docker setup. Never use dirty build caches as dependency-absence evidence.

## Manual-Only Verifications

No post-implementation human gate is part of acceptance. Rendered UI preservation review follows the repository's named-preview and full-inventory rules where applicable, remains honest about independent-review limits, and cannot replace executable checks. No retained-preview restart/reseed or unreviewed baseline update is authorized.

## Validation Sign-Off

- [ ] All tasks have runnable `<automated>` verification with adjacent `<fails_when>`, or explicit Wave 0 creation dependencies.
- [ ] Final plan/task/wave and unique threat mappings replace provisional IDs above.
- [ ] Sampling continuity holds; missing tests are created before use.
- [ ] No watch-mode commands or silent/no-op acceptance checks.
- [ ] Clean installed-consumer, test/prod image and supported-tuple predicates are explicit.
- [ ] Final exact-source checks and remaining audit failures are recorded at execution.
- [ ] `nyquist_compliant: true` is set only after validation audit establishes compliance.

**Approval:** Not requested or implied. Draft execution checks remain pending.
