# Phase 98 Research: Surface Reconciliation and Adopter Flow Clarity

**Researched:** 2026-05-27  
**Phase:** 98 - Surface Reconciliation and Adopter Flow Clarity  
**Confidence:** High (repo-grounded across current adopter-facing docs, verify tasks, and tests)

## Planning Answer

To plan Phase 98 well, treat it as a **contract-surface reconciliation pass** over a bounded set of high-risk files, with two outcomes:

1. Adopter-facing surfaces tell one coherent install/support/proof/intake story in one hop.
2. The reconciled story is guarded by a focused, service-free phase gate (`mix verify.phase98`) that checks contract tokens and routing seams without adding runtime scope.

Phase 98 should not introduce runtime capability classes, backend breadth, or new public runtime API categories. This phase is wording/flow hardening plus bounded verification wiring.

## Scope Guard (Non-Negotiable)

Phase 98 stays inside v1.27 scope guard authority:

- No autocomplete/suggestions work
- No vector/hybrid retrieval work
- No public backend broadening
- No new public runtime API categories

If any proposed "clarity" change requires runtime behavior expansion, reject it and route through the v1.27 reopen policy (outside-adopter signal or reproducible production bug plus ROADMAP/REQUIREMENTS updates first).

## Current Surface Findings That Matter for Planning

## Confirmed strengths

- `guides/support-and-compatibility.md` is already the canonical policy owner and has the right proof-boundary posture.
- `README.md` and `CONTRIBUTING.md` already route to support and intake guides (good one-hop base).
- `lib/mix/tasks/verify.adopter.ex` already encodes the fast/live split and live prerequisite honesty.
- `examples/phoenix_meilisearch/README.md` already documents CI-parity command order (`mix deps.get` then `mix test`).

## Planning-relevant drift/risk signals

- **Install/version inconsistency:** `README.md` still shows `{:scrypath, "~> 0.3"}` while intake currently frames Hex usage as `{:scrypath, "~> 1.0"}`. This directly threatens cross-surface trust.
- **Proof discoverability variance risk:** root surfaces reference `mix verify.adopter`, but "what to run now" phrasing differs and is not yet normalized into a fixed micro-contract.
- **SUP routing incompleteness risk:** intake defines classes A-D and findings buckets, but class-to-maintainer action language can still become interpretation-heavy without strict routing phrasing.
- **Gate fragility risk:** `test/scrypath/docs_contract_test.exs` is broad; Phase 98 should avoid paragraph snapshots and prefer bounded token/anchor checks for this phase's surfaces.

## Reconciliation Approaches (Without Runtime Expansion)

## Approach A (recommended): Layered authority + fixed micro-contract tokens

Use one canonical policy owner (`guides/support-and-compatibility.md`) and keep entry surfaces (`README.md`, `CONTRIBUTING.md`, intake) to concise, fixed "micro-contract" statements plus one-hop links.

Why this fits:

- Matches D-01 through D-06 from phase context.
- Improves adopter clarity quickly without broad prose duplication.
- Enables stable automated checks (token/anchor assertions).

## Approach B (complementary): Tokenized contract map for tests

Define a small set of required tokens/anchors for each surface (command names, env keys, runbook sequence, class labels, routing phrases) and validate those in focused tests.

Why this fits:

- Keeps tests robust to editorial wording changes.
- Supports anti-drift objectives without introducing noisy prose linting.

## Approach C (reject): Broad prose restatement across all docs

Do not duplicate full policy text across all entry surfaces. It raises drift risk, increases review cost, and conflicts with the single-authority model.

## Concrete File-Level Recommendations

## Primary adopter surfaces

- `README.md`
  - Keep install snippet release-backed and consistent with canonical contract.
  - Add/normalize a compact proof spine statement: `mix verify.adopter` fast path, `--live` explicit prerequisites, one-hop to example runbook.
  - Keep support policy routing to `guides/support-and-compatibility.md` (do not re-declare full matrix).

- `CONTRIBUTING.md`
  - Normalize maintainer proof language to the same micro-contract terms used in README/support guide.
  - Keep CI parity pointer explicit (`phoenix-example-integration` sequence) and route deeper live runbook detail to example README.
  - Keep phase-gate discoverability table updated once `verify.phase98` exists.

- `guides/support-and-compatibility.md` (canonical owner)
  - Keep normative support/proof policy authority here.
  - Tighten release-backed vs `main` language to be reusable verbatim by entry surfaces.
  - Keep fast-vs-live boundary exact and non-contradictory with `verify.adopter` and example runbook.

- `guides/outside-adopter-intake.md`
  - Reconcile version/install examples with release-backed truth.
  - Tighten required evidence fields into deterministic, mandatory language.
  - Strengthen class-to-routing guidance for SUP-02: bug vs docs-gap vs app-side vs environment, plus "needs information" and security-report carve-out text.

- `docs/templates/outside-adopter-evidence.md`
  - Ensure template fields exactly mirror intake required evidence list (no missing matrix/ref/path fields).
  - Add explicit first-failure and proof-path capture cues if absent/ambiguous.

- `examples/phoenix_meilisearch/README.md`
  - Keep this as live runbook authority (env, services, command sequence).
  - Ensure wording remains consistent with support guide policy but does not absorb policy ownership.

## Verification and wiring surfaces

- `lib/mix/tasks/verify.adopter.ex`
  - Keep command-family authority as executable truth for fast/live split.
  - If any phrasing changes in docs, ensure task moduledoc/help output remains aligned.

- `lib/mix/tasks/verify.phase98.ex` (new)
  - Implement as focused, service-free gate following phase verify pattern (`ensure_no_args!`, focused tests, docs build).
  - Scope to phase-98 contract surfaces only.

- `test/scrypath/readiness_contract_test.exs`
  - Extend with explicit PROOF-01/02 parity checks (discoverability + live prerequisite boundary).
  - Keep checks token-based.

- `test/scrypath/docs_contract_test.exs` and/or `test/scrypath/phase98_contract_test.exs` (new preferred)
  - Add focused cross-surface assertions for proof boundary and intake routing semantics.
  - Prefer dedicated `phase98_contract_test.exs` for new assertions to keep `docs_contract_test.exs` from becoming phase-noise-heavy.

- `test/mix/tasks/verify.phase98_test.exs` (new)
  - Mirror existing verify-task contract tests (no-args guard, focused test list markers, docs build marker).

- `test/mix/tasks/workflow_wiring_test.exs`
  - Add preferred_env registration assertion for `verify.phase98`.
  - Do not alter required PR checks yet unless phase scope explicitly includes it.

- `mix.exs`
  - Register `:"verify.phase98" => :test` in `cli.preferred_envs`.

- `CONTRIBUTING.md` (follow-up)
  - Add a concise "when to run `mix verify.phase98`" entry once gate lands.

## Sequencing Guidance (Implementation Order for the Plan)

1. **Freeze micro-contract token set** used across README/CONTRIBUTING/support/intake/example (proof command identity, live env vars, runbook command order, release-vs-main phrase, intake evidence fields).
2. **Reconcile canonical owner first** (`guides/support-and-compatibility.md`) so other surfaces can route/restatement against stable policy text.
3. **Reconcile entry surfaces next** (`README.md`, `CONTRIBUTING.md`, `guides/outside-adopter-intake.md`) using concise restatements only.
4. **Align template contract** (`docs/templates/outside-adopter-evidence.md`) with intake required fields.
5. **Confirm live runbook parity** in `examples/phoenix_meilisearch/README.md` versus `verify.adopter` and CI job command order.
6. **Add focused test coverage** for PROOF/SUP requirements in dedicated phase-98 assertions.
7. **Add `mix verify.phase98` task and tests** and wire `mix.exs` preferred env.
8. **Document gate usage** in `CONTRIBUTING.md` and run full phase verification sweep.

Do not start with gate wiring before contract tokens and authority boundaries are settled; otherwise test churn will be high.

## Requirement Mapping Coverage (Phase 98)

| Requirement | What must be true after Phase 98 | Primary files | Verification shape |
|---|---|---|---|
| `PROOF-01` | `mix verify.adopter` is discoverable within one hop from both README and CONTRIBUTING | `README.md`, `CONTRIBUTING.md`, `guides/support-and-compatibility.md` | Readiness/docs contract assertions for command discoverability and routing |
| `PROOF-02` | Fast (`mix verify.adopter`) vs live (`--live`) boundary is explicit, with live prerequisites and failure expectations | `guides/support-and-compatibility.md`, `lib/mix/tasks/verify.adopter.ex`, `CONTRIBUTING.md`, example README | Assertions for `--live` env keys, prerequisite wording, and no silent fast/live conflation |
| `PROOF-03` | Example proof instructions match canonical boundary and do not contradict root guidance | `examples/phoenix_meilisearch/README.md`, `README.md`, `CONTRIBUTING.md`, `ci.yml` (reference parity) | Cross-surface checks for command order and env variable parity |
| `SUP-01` | Intake docs define required evidence fields in actionable, deterministic terms | `guides/outside-adopter-intake.md`, `docs/templates/outside-adopter-evidence.md` | Assertions for required evidence fields presence and alignment |
| `SUP-02` | Escalation routing clearly classifies drift vs runtime bug vs app-side vs environment issue | `guides/outside-adopter-intake.md`, `guides/support-and-compatibility.md` (pointer) | Assertions for class A-D + findings buckets + routing semantics |

## Risks and Edge Cases

- **Version truth regression:** editing intake/support can reintroduce release-vs-main ambiguity or stale version snippets.
- **Policy/runbook inversion:** example README can accidentally start owning support policy text.
- **Fast/live collapse:** root docs can imply `mix verify.adopter` alone proves live behavior.
- **Class-routing ambiguity:** Class A-D labels without explicit maintainer routing can create inconsistent triage outcomes.
- **Gate overreach:** phase98 checks can become generic docs-policing and destabilize CI signal.
- **CI parity drift:** docs may claim one command path while workflow uses another sequence.

## Anti-Drift Strategy

Use a bounded "contract token matrix" for phase-98 surfaces:

- **Identity tokens:** `mix verify.adopter`, `mix verify.adopter --live`
- **Live prerequisite tokens:** `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, `SCRYPATH_MEILISEARCH_URL`
- **Runbook parity token:** `cd examples/phoenix_meilisearch && mix deps.get && mix test`
- **Authority tokens:** support guide as canonical owner; entry docs as route-and-restatement surfaces
- **Intake tokens:** class A-D, required evidence fields, first failure point, expected vs actual

Apply checks only to high-risk files from the v1.27 surface map. Do not widen to unrelated guides or runtime docs in this phase.

## Validation Architecture

Phase 98 validation should be layered so each requirement has direct evidence while keeping the gate service-free and low-noise.

### Layer 0: Contract inputs

- Phase 97 frozen statements (`CST-TRUTH-01-INSTALL`, `CST-TRUTH-02-RELEASE-MAIN`, `CST-TRUTH-03-SUPPORT-AUTHORITY`)
- v1.27 surface map and gate strategy planning docs
- Phase 98 micro-contract token matrix (defined during implementation)

### Layer 1: Surface assertions (file-level, token-based)

- `test/scrypath/readiness_contract_test.exs`: proof discoverability and fast/live boundary assertions.
- `test/scrypath/phase98_contract_test.exs` (recommended) or focused additions in `docs_contract_test.exs`: cross-surface parity and intake/evidence routing assertions.
- `test/mix/tasks/verify_adopter_test.exs`: executable truth for env prerequisites and command identity.

### Layer 2: Phase gate execution

- `lib/mix/tasks/verify.phase98.ex` runs:
  - focused phase-98 tests
  - docs build with `--warnings-as-errors`
- `test/mix/tasks/verify.phase98_test.exs` confirms gate argument contract and focused test wiring.
- `test/mix/tasks/workflow_wiring_test.exs` confirms `mix.exs` preferred-env registration.

### Layer 3: Verifiable checks for maintainers

- `mix test test/scrypath/readiness_contract_test.exs`
- `mix test test/scrypath/phase98_contract_test.exs` (or equivalent focused slice)
- `mix test test/mix/tasks/verify_adopter_test.exs`
- `mix test test/mix/tasks/verify.phase98_test.exs`
- `mix verify.phase98`

Expected pass condition: all checks green with no runtime service dependency for the phase gate itself; live proof remains explicit/advisory via `mix verify.adopter --live`.

### Layer 4: Milestone continuity

- Phase 98 produces reconciled surfaces + focused gate.
- Phase 99 consumes these outputs to finalize broader drift-gate and CI required-check enforcement (`TEST-*`, `GATE-*`).

This separation keeps Phase 98 narrowly about contract reconciliation and avoids premature PR-check policy expansion.

## Plan-Ready Recommendation

Plan Phase 98 as a **bounded reconciliation + focused gate** slice:

- Reconcile support/proof/intake language using layered authority (canonical policy owner + concise entry-surface restatements).
- Enforce parity with token-based assertions on only high-risk surfaces.
- Add `mix verify.phase98` as a service-free trust gate.
- Keep all changes explicitly within v1.27 scope guard (no runtime expansion).

## RESEARCH COMPLETE

- Use layered authority with fixed micro-contract tokens across README, CONTRIBUTING, support, intake, and example surfaces.
- Implement a focused `verify.phase98` gate plus token-based tests to lock `PROOF-01/02/03` and `SUP-01/02`.
- Keep phase scope contract-only and defer broader CI required-check enforcement to phase 99.
