---
phase: "182"
slug: "reliable-full-browser-verification-and-ci-caches"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-26"
---

# Phase 182 — Validation Strategy

Planning contract only; no implementation, test pass, cache hit or hosted acceptance is claimed.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing ExUnit repository contracts, Node built-in checks and Playwright Chromium |
| Config | `mix.exs`, `test/test_helper.exs`, `examples/scrypath_ecommerce/playwright.config.ts` |
| Quick command | `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_capability_test.exs` |
| Full contract command | `MIX_ENV=test mix verify.repository_contracts` |
| Browser command | `make -C examples/scrypath_ecommerce verify-e2e` |
| Estimated runtime | Measure during execution; hosted full job including finalization must stay within 1,800 seconds |

Use the configured BEAM tuple explicitly if the shell has no active tool version. The researcher observed Docker availability but no selected local Elixir/Mix version. Tool availability is separate from passing verification.

## Sampling Rate

- After each task, run its focused behavior checks and compile changed test infrastructure with warnings as errors.
- After each wave, run `MIX_ENV=test mix verify.repository_contracts`.
- Before phase completion, run the CONTRIBUTING warning-as-error suite and affected canonical gates, plus the real Docker and exact-source hosted acceptance below.
- Target fast contract feedback within 120 seconds; measure actual runtime. Long browser/cache runs are explicit integration acceptance, never substitutes for quick contracts.
- Every task must have an automated check and stated observable failure signal. No three consecutive tasks may lack fast feedback.

## Per-Task Verification Map

Actual task IDs match the XML `id` attributes in 182-NN-PLAN.md. Every command has an immediate observable `fails_when` in its task. Status remains pending/unvalidated until execution. Relative paths resolve from the executor's absolute checkout root.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 182-01-01 | 01 | 1 | BROW-01 | T-182-01 | Full/focused model and both real fixture routes | Node behavior + real Docker | `node --test scripts/ci/ecommerce_lifecycle.test.cjs; bash examples/scrypath_ecommerce/scripts/verify-e2e.sh full --readiness-only` | Harness exists; test/flag created here | pending |
| 182-01-02 | 01 | 1 | BROW-01, BROW-03 | T-182-02 | Owned cleanup and original status | Node behavior | `node --test scripts/ci/ecommerce_lifecycle.test.cjs` | Created by 182-01-01 | pending |
| 182-02-01 | 02 | 2 | BROW-02 | T-182-03 | Hostname guard refuses preview before mutation | Node behavior | `node --test scripts/ci/ecommerce_target.test.cjs` | Created here | pending |
| 182-02-02 | 02 | 2 | BROW-02, BROW-03 | T-182-04 | Decoder semantics; required behavior-test reachability | Node + ExUnit | `node --test scripts/ci/ecommerce_lifecycle.test.cjs scripts/ci/ecommerce_target.test.cjs; MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_capability_test.exs` | Existing ExUnit; Node prerequisite | pending |
| 182-03-01 | 03 | 2 | BROW-02, BROW-03 | T-182-05 | Complete distinct identity/attempt set; empty/order edges | Node behavior | `node --test scripts/ci/ecommerce_evidence.test.cjs` | Created here | pending |
| 182-03-02 | 03 | 2 | BROW-03 | T-182-06 | One aggregate; source/raw/path validation | Node behavior | `node --test scripts/ci/ecommerce_evidence.test.cjs` | Created by 182-03-01 | pending |
| 182-04-01 | 04 | 3 | BROW-01, BROW-02, BROW-03 | T-182-07, T-182-09 | Fresh owned files, copy failures and deadlines | Node behavior | `node --test scripts/ci/ecommerce_lifecycle.test.cjs scripts/ci/ecommerce_evidence.test.cjs scripts/ci/ecommerce_target.test.cjs` | Prerequisite suites extended | pending |
| 182-04-02 | 04 | 3 | BROW-03 | T-182-08, T-182-09 | Raw step/SHA/upload and 30-minute budget | ExUnit + required lane | `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_capability_test.exs test/scrypath/phase108_contract_test.exs test/scrypath/phase111_contract_test.exs; MIX_ENV=test mix verify.repository_contracts` | Existing ExUnit/capability | pending |
| 182-05-01 | 05 | 4 | CACHE-01, BROW-03 | T-182-10 | Compose/Bake graph/source/image no-build parity | Node behavior | `node --test scripts/ci/ecommerce_build.test.cjs scripts/ci/ecommerce_lifecycle.test.cjs` | Build suite created here | pending |
| 182-05-02 | 05 | 4 | CACHE-01 | T-182-11, T-182-12 | Trusted exporter and recipe scopes | Node + ExUnit | `node --test scripts/ci/ecommerce_build.test.cjs; MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs` | Created prerequisite + existing ExUnit | pending |
| 182-06-01 | 06 | 5 | CACHE-02 | T-182-13, T-182-14 | Strict compiled boundary; download-only fallback | Node behavior | `node --test scripts/ci/beam_cache.test.cjs` | Created here | pending |
| 182-06-02 | 06 | 5 | CACHE-02 | T-182-13, T-182-15 | Path graphs, PLTs and unconditional commands | Node + ExUnit | `node --test scripts/ci/beam_cache.test.cjs; MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs` | Created prerequisite + existing ExUnit | pending |
| 182-07-01 | 07 | 6 | BROW-03, CACHE-01, CACHE-02 | T-182-16 | Exact hosted run/artifact/raw-source joins | Node behavior | `node --test scripts/ci/phase182_acceptance.test.cjs` | Created here | pending |
| 182-07-02 | 07 | 6 | CACHE-01, CACHE-02 | T-182-17 | Fresh builder/no imports; owned lock/cache probes | Node + ExUnit | `node --test scripts/ci/phase182_acceptance.test.cjs scripts/ci/beam_cache.test.cjs scripts/ci/ecommerce_build.test.cjs; MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs` | Created prerequisite + existing ExUnit | pending |
| 182-08-01 | 08 | 7 | CACHE-01, CACHE-02 | T-182-18 | Actual warm/cold/fallback/lock proof | Hosted integration | `phase182_acceptance run modes docker-warm, docker-cold, beam-fallback, beam-lock-change, beam-cold; validate --mode caches (exact commands below)` | CLI created by 182-07 | pending |
| 182-08-02 | 08 | 7 | BROW-01, BROW-02, BROW-03 | T-182-19 | Complete changed-source full proof and final closeout | Docker + hosted integration | `make -C examples/scrypath_ecommerce verify-e2e; warning-as-error suite; repository contracts; phase182_acceptance run/validate full; ci_monitor closeout (exact commands below)` | Existing canonical commands; collector prerequisite | pending |

### Exact integration commands for 182-08

These commands are created/wired by 182-07 before 182-08 begins. Both hosted tasks require existing ci.yml workflow_dispatch capability at the owned candidate ref and read access to run attempts, jobs, logs and artifacts; gh auth status or read-only access alone is insufficient. Any needed push is limited to the owned branch with existing permission. Denied capability stops through a dynamic auth gate without new secrets, scope elevation or assumed approval; workflow token permissions remain least-privilege.

The SHA-specific --output-dir is a candidate-session root bound by a manifest to repository, branch, SHA and the explicit --session-id. Every invocation, including a repeated mode, allocates exclusive fresh per-mode/invocation and run/attempt subdirectories and preserves all attempts/failures. Only source-checked manifest-listed receipts may enter atomic root aggregates; stale loose files and wrong SHA/ref/session cannot contribute. A changed candidate needs a new session/root. The named temporary output root is an intentional runtime artifact, not a source-file path. 182-07-01 tests repeated modes, source/session mismatch, stale-file exclusion, aggregate serialization and denied dispatch/read operations.

Task 182-08-01:

```sh
node scripts/ci/phase182_acceptance.cjs run --mode docker-warm --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)" --session-id "phase182-$(git rev-parse HEAD)" --output-dir "${TMPDIR:-/tmp}/scrypath-phase182-acceptance/$(git rev-parse HEAD)"
node scripts/ci/phase182_acceptance.cjs run --mode docker-cold --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)" --session-id "phase182-$(git rev-parse HEAD)" --output-dir "${TMPDIR:-/tmp}/scrypath-phase182-acceptance/$(git rev-parse HEAD)"
node scripts/ci/phase182_acceptance.cjs run --mode beam-fallback --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)" --session-id "phase182-$(git rev-parse HEAD)" --output-dir "${TMPDIR:-/tmp}/scrypath-phase182-acceptance/$(git rev-parse HEAD)"
node scripts/ci/phase182_acceptance.cjs run --mode beam-lock-change --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)" --session-id "phase182-$(git rev-parse HEAD)" --output-dir "${TMPDIR:-/tmp}/scrypath-phase182-acceptance/$(git rev-parse HEAD)"
node scripts/ci/phase182_acceptance.cjs run --mode beam-cold --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)" --session-id "phase182-$(git rev-parse HEAD)" --output-dir "${TMPDIR:-/tmp}/scrypath-phase182-acceptance/$(git rev-parse HEAD)"
node scripts/ci/phase182_acceptance.cjs validate --mode caches --input "${TMPDIR:-/tmp}/scrypath-phase182-acceptance/$(git rev-parse HEAD)/cache-acceptance.json"
```

Each exits nonzero on the missing-proof/no-op/status/source/budget conditions stated immediately after its command in 182-08-PLAN.md.

Task 182-08-02:

```sh
make -C examples/scrypath_ecommerce verify-e2e
MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract
MIX_ENV=test mix verify.repository_contracts
node scripts/ci/phase182_acceptance.cjs run --mode full --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)" --session-id "phase182-$(git rev-parse HEAD)" --output-dir "${TMPDIR:-/tmp}/scrypath-phase182-acceptance/$(git rev-parse HEAD)"
node scripts/ci/phase182_acceptance.cjs validate --mode full --input "${TMPDIR:-/tmp}/scrypath-phase182-acceptance/$(git rev-parse HEAD)/full-acceptance.json"
node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"
```

Each exits nonzero on the missing-proof/no-op/status/source/budget conditions stated immediately after its command in 182-08-PLAN.md.

### Planning-only state

- Eight plans, sixteen tasks, seven waves. Wave 2 plans 182-02/03 have disjoint file ownership; subsequent shared workflow/verifier edits are sequenced.
- First task is a real production full-stack readiness tracer. Diagnostic mode is never accepted as full-browser proof.
- No separate framework scaffold is needed; new behavior suites are created test-first in their producing tasks and wired through existing workflow_wiring_test.exs.
- ASVS Level 1; high/critical threats block completion. T-182-SC is the shared reserved supply-chain ID; T-182-01 through T-182-19 are unique.
- The BROW-02 adjacency/empty/ordering probe items become explicit truths in 182-03. Four unclassified rows (BROW-01/BROW-03/CACHE-01/CACHE-02) stay flagged unresolved assumptions, with concrete existing-contract proof; none is auto-dismissed.
- Descriptor-less fallback prohibitions remain flagged-unverified, without inventing human acceptance tasks. Routine security canon is referred to $gsd-secure-phase.
- No implementation, source tests, preview work or hosted acceptance ran during planning.


## Wave 0 Requirements

- Extend existing repository-contract infrastructure with behavior tests for full/focused scope, route readiness, preview refusal, original exit preservation, copy errors and owned cleanup.
- Add small synthetic inventory/report fixtures for missing/duplicate identities, empty/malformed reports, expected-failure masking, retries and reasoned skips.
- Add executable cache boundary checks over graph/manifests/locks, exact tuple, environment, target/profile, source refresh and trusted writer policy.
- Use existing test frameworks and lanes. Do not relocate maintainer tasks, install a cache abstraction, change support tuples or activate the paid judge.

## Integration Acceptance

All behaviors have executable acceptance; none relies on post-implementation human UAT.

- Full Docker verification exercises mounted and standalone fixture routes and intended follow-up/iteration-3 cases. Focused verification retains its existing service scope.
- Changed-source scheduled/manual hosted full verification completes within the 30-minute total budget, with raw verifier success, complete inventory reconciliation and required bounded artifacts, seven-day retention, image/checkout/event identity and successful owned cleanup.
- Docker warm restore/export and a genuinely fresh builder with cache import disabled produce separate receipts. BEAM compatible download fallback, lock invalidation and representative cold execution produce separate receipts. Shared caches are not deleted.
- A retry pass is not clean stability evidence. Advisory job conclusions, synthetic reports and cache configuration alone cannot establish these integration claims.

## Validation Sign-Off

- [x] Actual task IDs, waves and threat references mapped after planning (execution remains unvalidated)
- [ ] All tasks have automated verification and immediate failure signals
- [ ] New behavior checks exist before dependent implementation tasks
- [ ] No three consecutive tasks lack automated feedback
- [ ] Full inventory, hosted proof and separate warm/cold acceptance are executable
- [ ] No watch-mode commands or pending UAT used as completion evidence
- [ ] Actual runtime measured and feedback/deadline margins recorded
- [ ] `nyquist_compliant: true` set only after validation confirms compliance

**Approval:** pending; this draft records no maintainer approval or independent review.
