# Phase 98 Pattern Guidance: Surface Reconciliation and Adopter Flow Clarity

## Candidate files

| Target file | Likely change | Why in Phase 98 |
|---|---|---|
| `README.md` | modify | Keep one-hop micro-contract for install/support/proof without policy duplication. |
| `CONTRIBUTING.md` | modify | Keep maintainer proof routing coherent; add `mix verify.phase98` usage note. |
| `guides/support-and-compatibility.md` | modify | Canonical policy owner for support/proof/install-release wording. |
| `guides/outside-adopter-intake.md` | modify | Tighten admissibility fields and class-to-routing semantics. |
| `docs/templates/outside-adopter-evidence.md` | modify | Keep evidence template 1:1 with intake required fields. |
| `examples/phoenix_meilisearch/README.md` | modify | Canonical live runbook authority and CI parity wording. |
| `lib/mix/tasks/verify.adopter.ex` | modify (only if needed) | Keep executable fast/live boundary and env token truth in sync with docs wording. |
| `lib/mix/tasks/verify.phase98.ex` | **new** | Focused, service-free gate for phase-98 contract surfaces. |
| `test/scrypath/readiness_contract_test.exs` | modify | Assert proof discoverability and fast/live boundary tokens. |
| `test/scrypath/docs_contract_test.exs` | modify (minimal) | Cross-surface anchor/token checks and ordering parity. |
| `test/scrypath/phase98_contract_test.exs` | **new (preferred)** | Keep phase-98 assertions isolated from broad docs contract noise. |
| `test/mix/tasks/verify.phase98_test.exs` | **new** | Verify task argument contract, focused test list markers, docs step marker. |
| `test/mix/tasks/workflow_wiring_test.exs` | modify | Assert `verify.phase98` is registered in `mix.exs` `preferred_envs`. |
| `mix.exs` | modify | Register `"verify.phase98": :test` in `cli().preferred_envs`. |

## Existing analogs

| Target file | Closest analog already in repo | Reuse directly |
|---|---|---|
| `lib/mix/tasks/verify.phase98.ex` | `lib/mix/tasks/verify.phase97.ex` | Same `ensure_no_args!/1`, `@focused_tests`, and docs build with `--warnings-as-errors`. |
| `test/mix/tasks/verify.phase98_test.exs` | `test/mix/tasks/verify.phase97_test.exs` | Same no-args assert + source marker checks for focused tests/docs step. |
| `test/mix/tasks/workflow_wiring_test.exs` update | existing `verify.phase97` env assertion block in same file | Add one assertion in same style: `envs[:"verify.phase98"] == :test`. |
| `mix.exs` update | `cli().preferred_envs` phase aliases near `"verify.phase97": :test` | Insert adjacent `"verify.phase98": :test` entry. |
| `test/scrypath/phase98_contract_test.exs` | `test/scrypath/readiness_contract_test.exs` + token helpers style in `test/scrypath/docs_contract_test.exs` | Prefer string/token assertions + order checks, not prose snapshots. |
| `README.md` update | current `README.md` one-hop bullets under Installation | Keep compact routing style (`Support and readiness`, `Outside integrations and evidence`) and avoid matrix duplication. |
| `CONTRIBUTING.md` update | existing Phase 94/96/97 verify alias paragraphs | Mirror concise pattern: "when to run", "what it protects", "narrower than full suite". |
| `guides/support-and-compatibility.md` update | existing "single current support and readiness authority" posture | Keep normative ownership here; other docs restate briefly and link. |
| `guides/outside-adopter-intake.md` update | existing Class A-D + findings buckets + required evidence list | Tighten mandatory evidence language and maintainer routing outcomes. |
| `docs/templates/outside-adopter-evidence.md` update | existing evidence sections ordering | Keep deterministic order (context, env, ref, proof path, sync mode, commands, expected/actual, first failure, logs). |
| `examples/phoenix_meilisearch/README.md` update | current CI parity section in same file + CI workflow command order | Keep canonical sequence `cd ... && mix deps.get && mix test` and env names exact. |
| `lib/mix/tasks/verify.adopter.ex` update | existing `@required_live_envs`, moduledoc fast/live split | Keep command identity tokens and no silent downgrade from live to fast. |
| `test/scrypath/readiness_contract_test.exs` update | existing discoverability/live-prereq tests in same file | Extend existing `String.contains?` checks for new Phase 98 micro-contract tokens. |
| `test/scrypath/docs_contract_test.exs` update | existing `assert_contains_all/2` and `ordered?/3` helpers | Add bounded phase-98 checks only on high-risk surfaces. |

### Concrete snippet references to reuse

```elixir
# lib/mix/tasks/verify.phase97.ex
def run(args) do
  Mix.Task.run("app.start")
  ensure_no_args!(args)
  run_test!(@focused_tests, "Phase 97 trust-hardening verification")
  Mix.Task.reenable("docs")
  Mix.Task.run("docs", ["--warnings-as-errors"])
end
```

```elixir
# test/mix/tasks/verify.phase97_test.exs
assert_raise Mix.Error, ~r/verify\.phase97 does not accept arguments, got: stray/, fn ->
  Mix.Task.reenable("verify.phase97")
  Mix.Task.run("verify.phase97", ["stray"])
end
```

```elixir
# test/mix/tasks/workflow_wiring_test.exs
envs = Scrypath.MixProject.cli()[:preferred_envs]
assert envs[:"verify.phase97"] == :test
```

```elixir
# lib/mix/tasks/verify.adopter.ex
@required_live_envs [
  "SCRYPATH_EXAMPLE_INTEGRATION",
  "PGPORT",
  "SCRYPATH_MEILISEARCH_URL"
]
```

```elixir
# test/scrypath/readiness_contract_test.exs
assert String.contains?(@contributing, "mix verify.adopter")
assert String.contains?(@contributing, "mix verify.adopter --live")
assert String.contains?(@example_readme, "SCRYPATH_EXAMPLE_INTEGRATION")
```

```elixir
# test/scrypath/docs_contract_test.exs
assert ordered?(job_head, "cd examples/phoenix_meilisearch", "mix deps.get")
assert ordered?(job_head, "mix deps.get", "mix test")
```

## Reusable patterns and gotchas

- Keep **layered authority** strict: canonical policy wording in `guides/support-and-compatibility.md`; root surfaces keep micro-contract + one-hop link only.
- Preserve frozen statement IDs from phase 97 (`CST-TRUTH-01-INSTALL`, `CST-TRUTH-02-RELEASE-MAIN`, `CST-TRUTH-03-SUPPORT-AUTHORITY`) as immutable anchors.
- Use **token/shape assertions** (commands, env names, anchor links, class labels, ordering) instead of paragraph equality in tests.
- Keep proof boundary explicit everywhere: `mix verify.adopter` is fast/service-free; `mix verify.adopter --live` is prerequisite-bound.
- Enforce CI/example parity tokens exactly: `cd examples/phoenix_meilisearch`, then `mix deps.get`, then `mix test`.
- Fix version-truth drift as part of reconciliation (current risk: `README.md` shows `~> 0.3` while intake says `~> 1.0`).
- Keep phase gate bounded to high-risk files only; do not broaden into generic docs linting.
- Do not introduce runtime scope changes (backend breadth/new API categories) while editing phase-98 surfaces.

### `verify.phase98` task + tests + wiring pattern

1. Add `lib/mix/tasks/verify.phase98.ex` by copying the `verify.phase97` structure:
   - `@moduledoc false`, `use Mix.Task`, `@shortdoc`
   - `ensure_no_args!/1`
   - `@focused_tests` list for phase-98 files
   - `Mix.Task.run("docs", ["--warnings-as-errors"])`
2. Add `test/mix/tasks/verify.phase98_test.exs` mirroring `verify.phase97_test.exs`:
   - no-args failure message check
   - source marker assertions for focused test file paths
   - marker assertion for docs command
3. Wire `mix.exs`:
   - add `"verify.phase98": :test` in `cli().preferred_envs`
4. Extend `test/mix/tasks/workflow_wiring_test.exs`:
   - add one assertion for `verify.phase98` preferred env registration
5. Prefer adding `test/scrypath/phase98_contract_test.exs` for new cross-surface checks and keep `docs_contract_test.exs` small.

## Suggested plan grouping by wave

### Wave 1 - Canonical wording and entry-surface reconciliation

- `guides/support-and-compatibility.md` (canonical truth first)
- `README.md` and `CONTRIBUTING.md` (micro-contract restatements + one-hop routing)
- Lock release-backed vs `main` phrasing and proof discoverability tokens.

### Wave 2 - Intake/runbook coherence

- `guides/outside-adopter-intake.md`
- `docs/templates/outside-adopter-evidence.md`
- `examples/phoenix_meilisearch/README.md`
- `lib/mix/tasks/verify.adopter.ex` (only if wording/help tokens drift from docs)

### Wave 3 - Gate, tests, and wiring

- Add `lib/mix/tasks/verify.phase98.ex`
- Add `test/mix/tasks/verify.phase98_test.exs`
- Add `test/scrypath/phase98_contract_test.exs` (preferred) and minimal deltas in `test/scrypath/readiness_contract_test.exs` / `test/scrypath/docs_contract_test.exs`
- Update `mix.exs` and `test/mix/tasks/workflow_wiring_test.exs`
- Verify with focused runs, then `mix verify.phase98`

## PATTERN MAPPING COMPLETE
