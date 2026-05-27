# Phase 101 Pattern Map: CI Compatibility Truth and Drift Guard Completion

Mapped: 2026-05-27  
Scope: `TRUTH-03` and `TEST-01` only  
Lane posture: trust-surface hardening only (no runtime feature breadth, no backend expansion)

## Scope guard for this pattern map

- Keep all enforcement under the existing trust lane: `mix verify.phase99`.
- Keep required-check identity stable: `main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust`.
- Put semantic compatibility parity checks in `test/scrypath/phase99_contract_test.exs`.
- Keep job-name / required-check wiring assertions in `test/mix/tasks/workflow_wiring_test.exs`.
- Keep compatibility matrix ownership in `guides/support-and-compatibility.md`; non-owner docs route to it.

## Likely file set (from 101 context + research)

| Target file | Expected action | Role | Data flow | Closest analog |
|---|---|---|---|---|
| `guides/support-and-compatibility.md` | modify | canonical compatibility owner | `declared support boundary + ci-verified tuples -> downstream route surfaces + contract tests` | Same file section `## What the repo actively proves` + phase-100 owner-language pattern in this file |
| `.github/workflows/ci.yml` | modify | executable CI tuple truth | `workflow lanes/setup-beam versions -> executed tuple facts -> parity assertions` | Existing required jobs + `phase99-trust` job wiring in this file |
| `test/scrypath/phase99_contract_test.exs` | modify | semantic parity enforcement seam | `support guide facts + ci facts + mix floor -> normalized assertions + actionable failures` | Existing `TEST-01/02/03` + `TRUTH-01/02` sections and helper style in this file |
| `test/mix/tasks/workflow_wiring_test.exs` | modify | required-check and trust-lane wiring guard | `ci.yml + CONTRIBUTING.md + mix.exs tokens -> wiring parity assertions` | Existing `describe "phase99 required-check wiring parity"` block |
| `CONTRIBUTING.md` | optional/minimal modify | maintainer required-check contract surface | `required-check table + lane descriptions -> contributor routing + wiring test tokens` | Existing CI table row style and "Treat ... as required blockers" sentence |
| `README.md` | optional/minimal modify | entry routing surface (non-owner) | `route-only support token -> canonical support authority` | Existing "Support and readiness" one-hop bullet style |
| `guides/outside-adopter-intake.md` | optional/minimal modify | intake route surface (non-owner) | `route token to support authority -> no competing compatibility matrix` | Existing canonical routing section at top |
| `mix.exs` | read-only expected | floor policy source | `elixir floor (~> 1.17) -> parity assertion input` | Existing `elixir: "~> 1.17"` in `project/0` |
| `lib/mix/tasks/verify.phase99.ex` | likely unchanged | trust-lane entrypoint | `focused trust suites + docs build -> deterministic phase lane` | Existing phase99 task shape used by phases 99-100 |
| `test/mix/tasks/verify.phase99_test.exs` | likely unchanged | trust-lane task contract test | `task source markers -> prevent lane drift` | Existing source-marker assertions in this file |

## Pattern assignments to reuse directly

### 1) Phase contract test layout stays in `phase99_contract_test`

Use the existing file-level read-and-assert shape:

```elixir
@support_guide File.read!("guides/support-and-compatibility.md")
@mix_exs File.read!("mix.exs")
@ci_workflow File.read!(".github/workflows/ci.yml")

describe "TEST-01 docs contract anchors" do
  test "..." do
    assert_contains_all(@readme, [...])
  end
end
```

Why: phases 99-100 already centralized trust-surface assertions here; phase 101 should extend this seam rather than adding a new gate surface.

### 2) Assertion helper style: token-first, bounded, actionable

Keep helper style consistent with phases 98-100:

```elixir
defp assert_contains_all(content, snippets) do
  Enum.each(snippets, fn snippet ->
    assert String.contains?(content, snippet),
           "expected phase-99 contract token #{inspect(snippet)}"
  end)
end
```

Use this for stable anchors, then add small semantic helpers for compatibility tuple normalization (not paragraph snapshots).

Recommended helper shape for phase 101 additions:

- `extract_support_ci_tuples/1` -> parse support-guide "GitHub Actions exercises" tuples.
- `extract_ci_tuples/1` -> parse CI lane/setup-beam tuples intended as compatibility evidence.
- `assert_tuple_parity!/2` -> compare normalized sets and print expected vs actual.
- `assert_floor_covered!/2` -> ensure at least one tuple proves the `~> 1.17` line.

### 3) Workflow wiring style: preserve required checks, assert trust-lane continuity

Follow current wiring test idiom:

```elixir
assert ci =~ "\n  phase99-trust:\n"
assert ci =~ "run: mix verify.phase99"
assert contributing =~ "**`main-ci`**"
assert contributing =~ "**`repo-hygiene`**"
assert contributing =~ "**`release-truth`**"
assert contributing =~ "**`phase99-trust`**"
```

Phase-101-specific extension pattern:

- Assert required check tokens remain unchanged.
- Assert compatibility evidence lane tokens/tuples exist (if new lane is added), without promoting it to required-check list.

### 4) Docs ownership pattern: canonical owner + route-only satellites

Reuse phase 97/98/100 ownership model:

- Owner: `guides/support-and-compatibility.md` holds compatibility semantics and CI-evidence tuples.
- Satellites: `README.md`, `CONTRIBUTING.md`, `guides/outside-adopter-intake.md` keep route tokens only.
- Do not add competing compatibility tables outside the owner surface.

Current route-token analogs to preserve:

- README support bullet linking `guides/support-and-compatibility.md`.
- CONTRIBUTING "single authority" language for support/readiness.
- Intake canonical routing bullets at the top of the guide.

### 5) CI workflow wiring style: copy existing job skeleton

When adding/updating compatibility evidence lanes, mirror existing CI job skeleton:

- `actions/checkout@v6`
- `erlef/setup-beam@v1` with explicit `elixir-version` + `otp-version`
- `actions/cache@v5`
- `mix deps.get`
- explicit run step

This keeps lane topology consistent with phases 99-100 and reduces noise in wiring assertions.

## Practical implementation recipe (planner/executor)

1. Update `guides/support-and-compatibility.md` compatibility section to reflect final claimed tuples and range/evidence wording.
2. Update `.github/workflows/ci.yml` so executed tuples match those claims exactly (especially floor/head evidence).
3. Extend `test/scrypath/phase99_contract_test.exs` with phase-101 semantic parity assertions:
   - support claimed tuples == CI executed tuples
   - floor policy and head coverage are explicitly evidenced
   - non-owner surfaces keep route-only ownership
4. Extend `test/mix/tasks/workflow_wiring_test.exs` only for wiring-level guarantees:
   - required-check token set unchanged
   - trust lane still routes through `mix verify.phase99`
   - compatibility evidence lane does not mutate required-check contract
5. Touch `CONTRIBUTING.md` only if lane naming or maintainer routing text must be clarified.

## Anti-patterns to avoid (phase 101)

- Adding runtime capability checks or backend matrix expansion.
- Creating a new verify alias (`verify.phase101`) or new required check names.
- Moving compatibility semantics into `README.md` or `CONTRIBUTING.md`.
- Snapshot-testing long prose paragraphs instead of token/tuple semantics.
- Mixing wiring assertions into phase semantic tests (or vice versa).

## Validation command path for this phase

- `mix test test/scrypath/phase99_contract_test.exs`
- `mix test test/mix/tasks/workflow_wiring_test.exs`
- `mix verify.phase99`

These are the same trust-lane commands established in phases 99-100 and are the expected closure path for `TRUTH-03` and `TEST-01`.
