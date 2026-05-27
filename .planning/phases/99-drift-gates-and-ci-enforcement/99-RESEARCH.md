# Phase 99 Research: Drift Gates and CI Enforcement

**Researched:** 2026-05-27  
**Phase:** 99 - Drift Gates and CI Enforcement  
**Confidence:** High (repo-grounded across phase context, requirements, existing verify-task patterns, workflow wiring, and contract-test seams)

## Planning Answer

Plan Phase 99 as a **durable trust-enforcement slice** that converts the reconciled v1.27 contract into stable, low-noise verification gates and explicit required-check policy tokens.

The phase should produce one coherent enforcement spine:

1. A dedicated service-free trust gate (`mix verify.phase99`) for local and CI parity.
2. Focused phase-scoped contract assertions (`test/scrypath/phase99_contract_test.exs`) that validate docs/proof/CI anchors using token and command checks, not prose snapshots.
3. Explicit required-check contract wiring (`main-ci`, `repo-hygiene`, `release-truth`, plus one stable phase-99 trust job token) aligned across workflow, tests, and contributor docs.

Phase 99 remains trust-hardening only. It should not expand runtime API breadth, backend scope, or Phoenix/runtime feature surface.

## Scope Guard (Non-Negotiable)

Phase 99 must stay inside the active v1.27 scope guard:

- No new runtime capability classes
- No backend abstraction expansion
- No new live/service-heavy required CI blockers
- No redefinition of phase-97 or phase-98 contract statements

If a proposal requires runtime behavior expansion, reject it and route through the phase-97 reopen policy (outside-adopter signal or reproducible production bug plus ROADMAP/REQUIREMENTS updates first).

## Current Surface Findings That Matter for Planning

## Confirmed strengths

- `verify.phase97` and `verify.phase98` already provide a stable task pattern: no-args enforcement, focused test list, docs build with warnings-as-errors.
- `test/scrypath/phase98_contract_test.exs` shows bounded token assertions with reusable helper shape (`assert_contains_all/2`).
- `test/mix/tasks/workflow_wiring_test.exs` already owns CI/mix wiring assertions and `cli.preferred_envs` parity checks.
- `CONTRIBUTING.md` already distinguishes required vs advisory lanes and documents CI job names in a table.

## Planning-relevant drift/risk signals

- Required-check policy is currently documented as three core blockers; phase 99 needs one explicit milestone trust job token to prevent branch-protection drift.
- `mix.exs` currently registers `verify.phase97` and `verify.phase98` but not `verify.phase99`; this would leave gate-rail parity incomplete for `GATE-01`.
- `docs_contract_test.exs` is intentionally broad and should not absorb all phase-99 assertions; phase-scoped ownership is needed to avoid evergreen-suite noise.
- CI/job naming drift is likely if workflow/job labels, docs tables, and test token sets are not pinned to the same exact strings.

## Enforcement Approaches (Without Runtime Expansion)

## Approach A (recommended): Layered trust rings with one canonical command

Adopt a three-ring model:

1. **Content contract ring** (`phase99_contract_test.exs`) for docs/proof/check-name tokens.
2. **Wiring ring** (`workflow_wiring_test.exs`, `verify.phase99_test.exs`, `mix.exs`) for task/job/env registrations.
3. **Execution ring** (`mix verify.phase99`) as the canonical reproduction command used locally and in CI.

Why this fits:

- Matches locked decisions D-01 through D-15.
- Keeps failures actionable and reproducible (`mix verify.phase99`).
- Preserves deterministic signal while avoiding heavy-service gate coupling.

## Approach B (complementary): Explicit required-check name contract tokens

Use one stable trust-job token in `.github/workflows/ci.yml` and lock that token in:

- `test/mix/tasks/workflow_wiring_test.exs`
- `test/scrypath/phase99_contract_test.exs` (cross-surface parity)
- `CONTRIBUTING.md` required-check documentation row

Why this fits:

- Prevents branch-protection drift from rename-only edits.
- Avoids ambiguity in "milestone trust coverage" language by pinning exact check names.

## Approach C (reject): Path-conditional required-check logic for phase 99

Do not make required trust-check behavior path-sensitive in this milestone.

Why reject:

- Creates pending/skipped check ambiguity in branch protection.
- Undercuts deterministic required-check policy for trust-hardening.

## Concrete File-Level Recommendations

## Primary gate and test ownership surfaces

- `lib/mix/tasks/verify.phase99.ex` (new)
  - Mirror phase-97/98 structure (`ensure_no_args!`, focused test list constant, docs build).
  - Include a clear marker line for failure triage (for example: `verify.phase99: drift gates and ci enforcement checks`).
  - Keep gate service-free and deterministic; run only phase-99-focused tests plus `mix docs --warnings-as-errors`.

- `test/mix/tasks/verify.phase99_test.exs` (new)
  - Assert no-args contract (`verify.phase99 does not accept arguments`).
  - Assert task discoverability via `mix help verify.phase99`.
  - Assert source contains focused test paths and docs command token.
  - Keep assertions token-based against source content, not runtime command snapshots.

- `test/scrypath/phase99_contract_test.exs` (new)
  - Own `TEST-01`, `TEST-02`, `TEST-03` assertions for phase-specific trust surfaces.
  - Use bounded token checks (`assert_contains_all`) and ordered command checks (`ordered?`) for command chains.
  - Validate cross-surface parity for:
    - docs anchors on high-risk surfaces (`README.md`, `CONTRIBUTING.md`, `guides/support-and-compatibility.md`, plus other mapped high-risk docs),
    - proof-boundary tokens (`mix verify.adopter`, `mix verify.adopter --live`, `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, `SCRYPATH_MEILISEARCH_URL`, `cd examples/phoenix_meilisearch`, `mix deps.get`, `mix test`),
    - required-check and verify-alias parity tokens between workflow/docs/mix wiring.

- `test/mix/tasks/workflow_wiring_test.exs`
  - Add a focused describe block for phase-99 required-check wiring.
  - Assert the stable trust job token exists in `.github/workflows/ci.yml` and executes `mix verify.phase99`.
  - Assert `mix.exs` registers `"verify.phase99": :test`.
  - Assert required-check names are explicitly documented in `CONTRIBUTING.md` with exact token parity.

## CI and alias wiring surfaces

- `.github/workflows/ci.yml`
  - Add one stable service-free trust job (recommended token: `phase99-trust`).
  - Job should run checkout + setup-beam + deps cache + `mix deps.get` + `mix verify.phase99`.
  - Keep heavy/live jobs advisory unless intentionally promoted; phase-99 trust job is required-check contract glue.

- `mix.exs`
  - Add `"verify.phase99": :test` under `cli.preferred_envs`.
  - Keep phase-97/98/99 aliases visible as the trust-hardening verify spine (`GATE-01`).

## Contributor and adopter-facing policy surfaces

- `CONTRIBUTING.md`
  - Add one concise verify alias entry for `mix verify.phase99` under verification guidance.
  - Update CI job table to include the phase-99 trust job row and purpose.
  - Replace ambiguous wording with explicit required-check token list:
    - `main-ci`
    - `repo-hygiene`
    - `release-truth`
    - phase-99 trust job token (for example `phase99-trust`)

- `README.md`
  - Keep trust-lane guidance concise (one-hop pointer style); do not duplicate full CI policy matrix.
  - Ensure any maintainer verification mention references canonical commands (`mix verify.adopter`, phase verify aliases) without prose-heavy policy duplication.

- `guides/support-and-compatibility.md`
  - Preserve authority for support/proof boundaries (`mix verify.adopter` fast vs `--live` prerequisite-bound proof).
  - Avoid introducing required-check policy ownership here; this guide should remain support/proof authority, not CI policy authority.

- `examples/phoenix_meilisearch/README.md`
  - Keep command chain and env token contract stable and ordered.
  - Preserve parity with CI example job command sequence (`cd` -> `mix deps.get` -> `mix test`) for proof-boundary checks.

## Sequencing Guidance (Implementation Order for the Plan)

1. Define the exact phase-99 token matrix (required check names, verify aliases, proof command/env tokens, anchor headings).
2. Add `verify.phase99` task and `verify.phase99_test.exs` task-contract coverage.
3. Add `phase99_contract_test.exs` with requirement-owned assertion blocks (`TEST-01..03`).
4. Update `workflow_wiring_test.exs` and `mix.exs` for job/alias parity.
5. Add/update CI trust job token in `.github/workflows/ci.yml`.
6. Reconcile docs ownership (`CONTRIBUTING.md` explicit required checks; README/support/example kept concise and role-correct).
7. Run gate sweep through `mix verify.phase99` and direct focused test invocations.

Do not finalize CI required-check documentation before the trust job token is locked and asserted in tests; otherwise token drift is likely.

## Requirement Mapping Coverage (Phase 99)

| Requirement | What must be true after Phase 99 | Primary files | Verification shape |
|---|---|---|---|
| `TEST-01` | High-risk docs surfaces keep canonical install/support/proof anchors aligned | `test/scrypath/phase99_contract_test.exs`, `README.md`, `CONTRIBUTING.md`, `guides/support-and-compatibility.md` (plus mapped high-risk docs) | Token/anchor assertions (`String.contains?`, heading tokens, bounded helper checks) |
| `TEST-02` | Root docs and example docs preserve explicit fast-vs-live proof boundary parity | `test/scrypath/phase99_contract_test.exs`, `README.md`, `CONTRIBUTING.md`, `guides/support-and-compatibility.md`, `examples/phoenix_meilisearch/README.md` | Command/env token checks + ordered command chain assertions |
| `TEST-03` | CI required-check names and verify-alias references stay in sync across code/docs/workflow | `test/scrypath/phase99_contract_test.exs`, `test/mix/tasks/workflow_wiring_test.exs`, `.github/workflows/ci.yml`, `mix.exs`, `CONTRIBUTING.md` | Exact check-name and alias token assertions |
| `GATE-01` | Phase verify aliases 97-99 are defined and documented as trust-hardening spine | `mix.exs`, `CONTRIBUTING.md`, `lib/mix/tasks/verify.phase99.ex`, `test/mix/tasks/workflow_wiring_test.exs` | Alias registration checks + docs token parity |
| `GATE-02` | Required PR checks are explicitly documented and mapped to milestone gate strategy | `.github/workflows/ci.yml`, `CONTRIBUTING.md`, `test/mix/tasks/workflow_wiring_test.exs`, `test/scrypath/phase99_contract_test.exs` | Required-check token contract assertions (no ambiguous labels) |

## Risks and Edge Cases

- **Required-check rename drift:** changing job names without updating docs/tests silently breaks branch-protection expectations.
- **Pending-check ambiguity risk:** path-conditional required checks can produce skipped/pending confusion and reduce trust.
- **Gate noise regression:** broad prose snapshots will create false-positive churn and desensitize maintainers to failures.
- **Ownership blur risk:** placing all phase-99 checks into `docs_contract_test.exs` can bury actionable failures under evergreen noise.
- **Policy duplication drift:** spreading required-check policy across README/support/example docs increases contradiction risk.
- **Gate overreach risk:** adding service-backed/live checks to `verify.phase99` breaks deterministic local/CI parity.

## Anti-Drift Strategy

Use a bounded phase-99 token matrix and strict ownership boundaries:

- **Required-check tokens:** `main-ci`, `repo-hygiene`, `release-truth`, one stable phase-99 trust job token.
- **Verify-alias tokens:** `mix verify.phase97`, `mix verify.phase98`, `mix verify.phase99`.
- **Proof-boundary tokens:** `mix verify.adopter`, `mix verify.adopter --live`, `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, `SCRYPATH_MEILISEARCH_URL`, `cd examples/phoenix_meilisearch`, `mix deps.get`, `mix test`.
- **Assertion strategy:** token/anchor/order checks only; no full-paragraph equality snapshots.
- **Failure UX:** each assertion should identify the missing token and failing surface, then point to local reproduction via `mix verify.phase99`.

## Validation Architecture

Phase 99 validation should be layered so each requirement has direct, deterministic evidence without adding runtime-service coupling.

### Layer 0: Contract inputs

- Phase-97 frozen contract/scope artifacts
- Phase-98 reconciled surfaces
- Phase-99 context decisions D-01 through D-15
- Requirement IDs `TEST-01`, `TEST-02`, `TEST-03`, `GATE-01`, `GATE-02`

### Layer 1: Phase-specific content contract assertions

- `test/scrypath/phase99_contract_test.exs`
  - docs anchor parity across high-risk surfaces
  - proof-boundary command/env parity across root + example docs
  - required-check/alias token parity assertions where cross-surface checks are most valuable

### Layer 2: Wiring and task-contract assertions

- `test/mix/tasks/verify.phase99_test.exs`
  - task args contract and focused execution markers
- `test/mix/tasks/workflow_wiring_test.exs`
  - CI job token and command wiring
  - `mix.exs` `cli.preferred_envs` parity
  - required-check documentation token parity in contributor docs

### Layer 3: Gate execution

- `lib/mix/tasks/verify.phase99.ex` runs:
  - focused phase-99 trust suites
  - docs build (`mix docs --warnings-as-errors`)
- `.github/workflows/ci.yml` trust job runs `mix verify.phase99` as required-check seam

### Layer 4: Maintainer verification commands

- `mix test test/scrypath/phase99_contract_test.exs`
- `mix test test/mix/tasks/verify.phase99_test.exs`
- `mix test test/mix/tasks/workflow_wiring_test.exs`
- `mix verify.phase99`

Expected pass condition: stable required-check tokens, stable alias wiring, stable proof-boundary/doc anchors, and reproducible deterministic trust gate behavior with no live service requirement.

## Plan-Ready Recommendation

Implement Phase 99 as a **focused drift-gate and required-check contract** slice:

- Add `mix verify.phase99` as the canonical trust-hardening command.
- Keep assertions phase-scoped and token-based (`phase99_contract_test.exs` + wiring suites).
- Lock required-check names and verify aliases across workflow/docs/tests.
- Preserve release-train posture: deterministic required core, heavy/live lanes advisory by default.

## RESEARCH COMPLETE

- Phase 99 should enforce a layered trust model: content tokens, wiring tokens, and one canonical execution gate (`mix verify.phase99`).
- The highest-value anti-drift move is explicit required-check token parity across `.github/workflows/ci.yml`, `CONTRIBUTING.md`, and workflow-wiring tests.
- Main risk is CI/docs/token rename drift; avoid it with deterministic token assertions and stable job naming.
