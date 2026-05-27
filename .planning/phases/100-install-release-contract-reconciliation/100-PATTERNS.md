# Phase 100 Pattern Map: Install/Release Contract Reconciliation

Mapped: 2026-05-27  
Inputs: `100-CONTEXT.md`, `100-RESEARCH.md`  
Lane baseline: phases 97-99 trust-hardening patterns (token/anchor checks, deterministic verify task flow, route-first docs ownership).

## 1) Likely file set from context + research

| Target file | Expected action | Confidence | Why |
|---|---|---|---|
| `guides/support-and-compatibility.md` | modify | high | Canonical owner for install/version token policy and release-vs-`main` wording (D-01..D-08). |
| `README.md` | modify | high | Entry surface must route to canonical owner and avoid conflicting install/version literals (D-03, D-09). |
| `guides/outside-adopter-intake.md` | modify | high | Currently carries install drift risk; owns evidence admissibility and package-vs-repo boundary wording (D-04, D-10). |
| `CONTRIBUTING.md` | modify | medium-high | Maintainer routing surface must stay route-first and avoid becoming policy authority (D-11). |
| `docs/templates/outside-adopter-evidence.md` | modify | medium | Must preserve exact-version/exact-ref evidence language parity with intake guide (D-04). |
| `test/scrypath/phase99_contract_test.exs` | modify | high | Primary trust-lane seam for phase-scoped semantic parity assertions (D-12..D-15). |
| `test/scrypath/docs_contract_test.exs` | modify (minimal) | medium | Evergreen docs invariants; add only narrow install/release parity checks if phase99 file would become noisy. |
| `lib/mix/tasks/verify.phase99.ex` | likely unchanged (or small modify) | medium | Keep canonical deterministic gate; touch only if focused test paths change. |
| `test/mix/tasks/verify.phase99_test.exs` | likely unchanged (or small modify) | medium | Update only if verify task markers/focused list change. |
| `test/mix/tasks/workflow_wiring_test.exs` | likely unchanged | low-medium | Only needed if alias/check-token wiring is touched indirectly. |

## 2) Target file pattern assignments

### `guides/support-and-compatibility.md`

- **Role:** single normative owner for install/version contract and release-backed vs branch-tip truth.
- **Closest analogs:**
  - `guides/support-and-compatibility.md` (existing single-authority framing)
  - `97-CONTRACT-STATEMENTS.md` (`CST-TRUTH-*` ownership model)
  - `README.md` + `CONTRIBUTING.md` (reference-surface routing style)
- **Conventions to mirror:**
  - Keep owner-language explicit and singular.
  - State command family and proof boundaries without duplicating intake rubric.

```md
This guide is the single current support and readiness authority for Scrypath.
...
- `mix verify.adopter` is the fast, service-free contract check
- `mix verify.adopter --live` is prerequisite-bound live proof
```

```md
## CST-TRUTH-03-SUPPORT-AUTHORITY
...
Owner surface: `guides/support-and-compatibility.md`
Reference surfaces:
- `README.md`
- `CONTRIBUTING.md`
- `guides/outside-adopter-intake.md`
```

- **Verification implications:**
  - Phase 100 assertions should treat this file as install/release truth source.
  - Non-owner files should be validated as route surfaces, not competing policy text.

### `README.md`

- **Role:** first-hop onboarding and routing only; no competing install/support policy body.
- **Closest analogs:**
  - existing `README.md` "Support and readiness" + "Outside integrations and evidence" bullets
  - phase 98 route-first edits validated by `test/scrypath/phase98_contract_test.exs`
- **Conventions to mirror:**
  - Keep compact one-hop links and explicit command tokens.
  - Keep install snippet literal and release-backed.

```md
## Installation
...
{:scrypath, "~> 0.3"}
...
**Support and readiness:** ... [guides/support-and-compatibility.md](guides/support-and-compatibility.md).
**Outside integrations and evidence:** ... [guides/outside-adopter-intake.md](guides/outside-adopter-intake.md).
```

- **Verification implications:**
  - Add/extend parity checks ensuring README install token cannot diverge from canonical policy.
  - Ensure README keeps routing markers to support/intake guides and does not grow matrix text.

### `guides/outside-adopter-intake.md`

- **Role:** evidence admissibility + triage workflow; must preserve package-vs-repo truth boundary.
- **Closest analogs:**
  - existing `guides/outside-adopter-intake.md` classing/routing structure
  - `docs/templates/outside-adopter-evidence.md` heading contract
  - `test/scrypath/phase98_contract_test.exs` intake-template parity assertions
- **Conventions to mirror:**
  - Keep explicit boundary language and class taxonomy.
  - Correct install token drift to release-backed reality while preserving boundary semantics.

```md
### Repo-clone versus Hex-package Boundary
- **Hex-package:** When you add `{:scrypath, "~> 1.0"}` ...
- **Repo-clone:** The defended proof path is a repo-clone workflow.
```

```elixir
# test/scrypath/phase98_contract_test.exs
assert_contains_all(@evidence_template, [
  "## Scrypath Ref or Hex version",
  "## Chosen Proof Path",
  "## Ordered Commands"
])
```

- **Verification implications:**
  - Phase 100 should add explicit drift guards for conflicting install literals on non-owner surfaces.
  - Assertions should require exact package version or exact git ref/commit wording parity with evidence template.

### `CONTRIBUTING.md`

- **Role:** maintainer workflow + CI/gate mapping; route to canonical support/intake policy.
- **Closest analogs:**
  - existing top section under "First hour and canonical docs"
  - phase 99 trust-lane section style (`mix verify.phase99`, required checks table)
- **Conventions to mirror:**
  - Maintain concise "run this verify alias when..." style.
  - Keep authority delegation explicit; do not duplicate install/support matrix.

```md
- Current support/readiness truth lives in [`guides/support-and-compatibility.md`]
...
- ... refer to [`guides/outside-adopter-intake.md`]. Do not duplicate the intake checklist...
```

```md
| **`phase99-trust`** | Required merge gate: `mix verify.phase99` ... |
```

- **Verification implications:**
  - Token checks should confirm support/intake routing survives wording changes.
  - If release/main micro-contract text is added here, keep it short and parity-tested against owner semantics.

### `docs/templates/outside-adopter-evidence.md`

- **Role:** required intake payload shape; preserves package-vs-repo traceability facts.
- **Closest analogs:**
  - existing template heading order
  - `test/scrypath/phase98_contract_test.exs` template section assertions
- **Conventions to mirror:**
  - Keep deterministic heading names/order used by contract tests.
  - Tighten "exact version/ref" wording without adding policy prose.

```md
## Scrypath Ref or Hex version
*State the exact commit hash if using a repo-clone, or the Hex package version.*
```

```md
## Ordered Commands
1.
2.
3.
```

- **Verification implications:**
  - Keep heading tokens stable to avoid brittle test churn.
  - Add parity assertion for exact Hex version OR exact git ref/commit language with intake guide.

### `test/scrypath/phase99_contract_test.exs`

- **Role:** primary phase-owned trust assertions (preferred home for Phase 100 parity checks).
- **Closest analogs:**
  - `test/scrypath/phase99_contract_test.exs` existing TEST-01/02/03 layout
  - `test/scrypath/phase98_contract_test.exs` token-list helper style
  - phase 97 contract statement IDs (`CST-TRUTH-*`) as semantic anchors
- **Conventions to mirror:**
  - Use explicit top-level file reads (`@readme`, `@support_guide`, ...).
  - Organize by named contract block (`describe "TEST-.." do`).
  - Use token assertions + ordering checks; avoid paragraph snapshots.

```elixir
describe "TEST-01 docs contract anchors" do
  test "high-risk surfaces keep canonical ... tokens" do
    assert_contains_all(@readme, [...])
    assert_contains_all(@contributing, [...])
  end
end
```

```elixir
defp assert_contains_all(content, snippets) do
  Enum.each(snippets, fn snippet ->
    assert String.contains?(content, snippet),
           "expected phase-99 contract token #{inspect(snippet)}"
  end)
end
```

- **Verification implications:**
  - Add install token parity + conflicting-token refutes across high-risk non-owner surfaces.
  - Add release-backed default + `main` unreleased branch-tip semantic token checks.
  - Keep failure messages actionable by naming missing token and surface.

### `test/scrypath/docs_contract_test.exs`

- **Role:** evergreen cross-milestone docs guardrail suite (secondary seam for phase 100).
- **Closest analogs:**
  - existing support/readiness discoverability tests
  - existing ordered command chain checks
- **Conventions to mirror:**
  - Keep broad helper style (`assert_contains_all/2`, `ordered?/3`).
  - Add only bounded, stable invariants that are not phase-local noise.

```elixir
assert_contains_all(@readme, [
  "guides/support-and-compatibility.md",
  "mix verify.adopter"
])
```

```elixir
assert ordered?(job_head, "cd examples/phoenix_meilisearch", "mix deps.get")
assert ordered?(job_head, "mix deps.get", "mix test")
```

- **Verification implications:**
  - If phase99 contract test gets too dense, place one or two evergreen install/release invariants here.
  - Keep checks token-based; avoid brittle prose-equality assertions.

### `lib/mix/tasks/verify.phase99.ex` (conditional touch)

- **Role:** canonical deterministic trust-lane gate command (`mix verify.phase99`).
- **Closest analogs:**
  - `lib/mix/tasks/verify.phase99.ex` current implementation
  - `lib/mix/tasks/verify.phase98.ex` and `verify.phase97.ex` no-args + focused-tests shape
- **Conventions to mirror:**
  - Preserve standardized task skeleton (`app.start`, `ensure_no_args!`, `@focused_tests`, docs warnings-as-errors).

```elixir
@focused_tests [
  "test/scrypath/phase99_contract_test.exs",
  "test/mix/tasks/verify.phase99_test.exs",
  "test/mix/tasks/workflow_wiring_test.exs"
]
...
Mix.Task.run("docs", ["--warnings-as-errors"])
```

- **Verification implications:**
  - Only update this file if focused test membership changes.
  - Preserve deterministic, service-free execution and existing task marker text style.

### `test/mix/tasks/verify.phase99_test.exs` (conditional touch)

- **Role:** verify-task contract test for args, markers, and focused path tokens.
- **Closest analogs:**
  - existing `test/mix/tasks/verify.phase99_test.exs`
  - `test/mix/tasks/verify.phase98_test.exs` same structure
- **Conventions to mirror:**
  - Keep marker-based source assertions over command-output snapshots.
  - Keep strict arg-rejection regex.

```elixir
assert_raise Mix.Error, ~r/verify\.phase99 does not accept arguments, got: stray/, fn ->
  Mix.Task.reenable("verify.phase99")
  Mix.Task.run("verify.phase99", ["stray"])
end
```

- **Verification implications:**
  - If `verify.phase99` focused test list changes, update this file in lockstep.
  - Preserve check for docs build step marker.

### `test/mix/tasks/workflow_wiring_test.exs` (usually unchanged)

- **Role:** alias/wiring parity and required-check token seam.
- **Closest analogs:**
  - existing `mix.exs cli.preferred_envs` parity tests
  - existing `phase99 required-check wiring parity` tests
- **Conventions to mirror:**
  - Keep explicit string token assertions for CI job names and command routing.
  - Keep phase-alias parity assertions grouped in one describe block.

```elixir
envs = Scrypath.MixProject.cli()[:preferred_envs]
assert envs[:"verify.phase97"] == :test
assert envs[:"verify.phase98"] == :test
assert envs[:"verify.phase99"] == :test
```

```elixir
assert ci =~ "\n  phase99-trust:\n"
assert ci =~ "run: mix verify.phase99"
```

- **Verification implications:**
  - No change expected for pure Phase 100 docs parity work.
  - Touch only if trust-lane wiring tokens or alias registration are modified.

## 3) Cross-file conventions to keep strict in Phase 100

1. **Owner vs reference surfaces:** keep full normative install/release policy in `guides/support-and-compatibility.md`; all other surfaces route.
2. **Tokenized drift checks:** assert install literals and release/main semantics with small token sets and ordered checks; avoid full-paragraph snapshots.
3. **Naming continuity:** preserve `PhaseNN` task and test naming (`verify.phase99`, `Phase99ContractTest`, `TEST-01..03` describe group style) unless a strong reason exists.
4. **Deterministic trust lane:** keep enforcement in existing `mix verify.phase99` flow; avoid adding new required gates for this phase.
5. **Actionable failures:** maintain helper error message pattern that includes the missing token and failing surface.

## 4) Verification command implications for planning

- Required closure path remains:
  - `mix test test/scrypath/phase99_contract_test.exs`
  - `mix test test/scrypath/docs_contract_test.exs` (if touched)
  - `mix verify.phase99`
- If no verify task/wiring files are edited, avoid unnecessary changes to `verify.phase99` and workflow wiring tests.
- Phase 100 assertions should fail specifically on:
  - install token mismatch across owner/reference surfaces,
  - conflicting install literals on non-owner files,
  - missing release-backed default + `main` unreleased distinction,
  - missing exact Hex-version or exact git-ref/commit evidence boundary wording.
