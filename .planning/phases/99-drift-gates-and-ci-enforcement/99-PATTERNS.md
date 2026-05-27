# Phase 99 Pattern Guidance: Drift Gates and CI Enforcement

## Scope guard for this pattern map

Phase 99 is **trust-hardening only**:

- lock cross-surface contract tokens (docs, workflow, aliases, required checks),
- enforce them via deterministic tests and one canonical gate command,
- avoid runtime feature expansion (no new backend/runtime API breadth, no new service-coupled required lane).

## Target files, roles, and data flow

| Target file | Role in Phase 99 | Data flow ownership | Closest analog(s) |
|---|---|---|---|
| `lib/mix/tasks/verify.phase99.ex` (new) | Canonical deterministic gate command (`mix verify.phase99`) | `focused trust tests + docs build -> one reproducible command -> local + CI parity` | `lib/mix/tasks/verify.phase98.ex`, `lib/mix/tasks/verify.phase97.ex` |
| `test/mix/tasks/verify.phase99_test.exs` (new) | Task contract guard (no args, focused markers, docs command marker) | `task source tokens -> test assertions -> actionable gate failures` | `test/mix/tasks/verify.phase98_test.exs`, `test/mix/tasks/verify.phase97_test.exs` |
| `test/scrypath/phase99_contract_test.exs` (new) | Phase-owned token contract assertions for `TEST-01`/`TEST-02`/`TEST-03` | `docs/workflow/mix token sources -> bounded token checks -> drift detection` | `test/scrypath/phase98_contract_test.exs`, helper style in `test/scrypath/docs_contract_test.exs` |
| `test/mix/tasks/workflow_wiring_test.exs` (modify) | Wiring parity for alias registration and required-check token/job routing | `mix.exs + ci.yml + contributor docs -> parity assertions` | existing `verify.phase97`/`verify.phase98` preferred-env assertions in same file |
| `mix.exs` (modify) | `cli.preferred_envs` trust-spine registration | `verify task name -> preferred env contract -> predictable CLI behavior` | existing `"verify.phase97": :test` and `"verify.phase98": :test` entries |
| `.github/workflows/ci.yml` (modify) | Required trust check job token + `mix verify.phase99` execution seam | `required-check name token -> CI job -> canonical command` | existing required jobs `main-ci`/`repo-hygiene`/`release-truth`, service-free `adopter-verify` job structure |
| `CONTRIBUTING.md` (modify) | Human-readable required-check contract authority for contributors | `workflow job tokens + verify aliases -> explicit required/advisory policy` | current required-check table and phase-97/98 verify alias guidance in same file |
| `README.md` (possible modify, only if drift found) | Root micro-contract pointer surface (not policy owner) | `entrypoint wording -> links to canonical support/proof docs` | existing support/readiness and outside-adopter one-hop bullets |
| `guides/support-and-compatibility.md` (possible modify, only if drift found) | Canonical fast/live proof boundary authority | `proof command/env tokens -> phase99 contract tests` | existing `mix verify.adopter` vs `mix verify.adopter --live` token lines |
| `examples/phoenix_meilisearch/README.md` (possible modify, only if drift found) | Canonical example proof command/env sequence | `example command/env tokens -> docs/test/ci parity checks` | existing CI-parity command chain in same file |

## Concrete analog anchors to copy

### 1) Gate task shape (`verify.phase99`)

Use the existing phase gate skeleton directly:

```elixir
# lib/mix/tasks/verify.phase98.ex
@focused_tests [
  "test/scrypath/phase98_contract_test.exs",
  "test/scrypath/readiness_contract_test.exs",
  "test/scrypath/docs_contract_test.exs",
  "test/mix/tasks/verify.phase98_test.exs"
]

def run(args) do
  Mix.Task.run("app.start")
  ensure_no_args!(args)
  run_test!(@focused_tests, "Phase 98 trust-hardening verification")
  Mix.Task.reenable("docs")
  Mix.Task.run("docs", ["--warnings-as-errors"])
end
```

Also preserve the strict no-args contract pattern:

```elixir
# lib/mix/tasks/verify.phase97.ex
defp ensure_no_args!(args) do
  Mix.raise("verify.phase97 does not accept arguments, got: #{Enum.join(args, " ")}")
end
```

### 2) Verify-task test shape (`verify.phase99_test`)

Mirror marker-based source checks (not command-output snapshots):

```elixir
# test/mix/tasks/verify.phase98_test.exs
source = File.read!("lib/mix/tasks/verify.phase98.ex")
assert source =~ ~S|"test/scrypath/phase98_contract_test.exs"|
assert source =~ ~S|Mix.Task.run("docs", ["--warnings-as-errors"])|
assert source =~ "verify.phase98: surface reconciliation and adopter-flow checks"
```

### 3) Phase contract suite style (`phase99_contract_test`)

Reuse bounded token helpers:

```elixir
# test/scrypath/phase98_contract_test.exs
defp assert_contains_all(content, snippets) do
  Enum.each(snippets, fn snippet ->
    assert String.contains?(content, snippet),
           "expected phase-98 contract token #{inspect(snippet)}"
  end)
end
```

And ordering checks for command chains:

```elixir
# test/scrypath/docs_contract_test.exs
assert ordered?(job_head, "cd examples/phoenix_meilisearch", "mix deps.get")
assert ordered?(job_head, "mix deps.get", "mix test")
```

### 4) Workflow wiring parity style

Extend the existing preferred-env checks:

```elixir
# test/mix/tasks/workflow_wiring_test.exs
envs = Scrypath.MixProject.cli()[:preferred_envs]
assert envs[:"verify.phase97"] == :test
assert envs[:"verify.phase98"] == :test
```

Match the alias registration style:

```elixir
# mix.exs
"verify.phase97": :test,
"verify.phase98": :test,
```

### 5) Required-check token anchors

Current required check token style in contributor docs:

```md
# CONTRIBUTING.md
| **`main-ci`** | Required merge gate: ... |
| **`repo-hygiene`** | Required merge gate: ... |
| **`release-truth`** | Required merge gate: ... |
```

Current required jobs in workflow:

```yaml
# .github/workflows/ci.yml
jobs:
  main-ci:
  repo-hygiene:
  release-truth:
```

Phase 99 should add **one stable trust job token** (for example `phase99-trust`) and assert that exact token across:

- `.github/workflows/ci.yml`,
- `CONTRIBUTING.md`,
- `test/mix/tasks/workflow_wiring_test.exs`,
- `test/scrypath/phase99_contract_test.exs`.

## Deterministic implementation notes (anti-drift)

1. Assert **tokens and ordering**, not full paragraphs:
   - command tokens (`mix verify.phase99`, `mix verify.adopter --live`),
   - env tokens (`SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, `SCRYPATH_MEILISEARCH_URL`),
   - required-check tokens (`main-ci`, `repo-hygiene`, `release-truth`, `<phase99-job-token>`),
   - ordered command chain (`cd examples/phoenix_meilisearch` -> `mix deps.get` -> `mix test`).
2. Keep assertions **surface-local and explicit**:
   - failure message should include missing token and source surface,
   - gate failure should point to `mix verify.phase99` for local reproduction.
3. Keep docs ownership layered:
   - `CONTRIBUTING.md` owns required-check table truth,
   - `README.md` remains one-hop routing/micro-contract only,
   - support/example docs remain proof-boundary authorities.
4. Prefer small helper lists/constants (token matrices) over prose matching; this reduces CI churn from harmless copy edits.
5. Do not add path-conditional required-check logic in this phase (avoid skipped/pending ambiguity in branch protection).

## Recommended implementation sequence (trust rings)

1. **Execution ring:** add `verify.phase99` task + `verify.phase99_test.exs`.
2. **Content ring:** add `phase99_contract_test.exs` with token/ordering checks for `TEST-01..03`.
3. **Wiring ring:** update `mix.exs`, `workflow_wiring_test.exs`, `.github/workflows/ci.yml`, and `CONTRIBUTING.md` with one stable phase-99 trust job token.
4. Reconcile root/support/example docs only where tokens drift; avoid broad copy rewrites.

## Phase 99 target map summary

- Primary gate surfaces: `lib/mix/tasks/verify.phase99.ex`, `test/mix/tasks/verify.phase99_test.exs`
- Contract drift surfaces: `test/scrypath/phase99_contract_test.exs`, `CONTRIBUTING.md`, `.github/workflows/ci.yml`, `mix.exs`
- Proof-boundary token sources (read/adjust only if drift): `README.md`, `guides/support-and-compatibility.md`, `examples/phoenix_meilisearch/README.md`

## PATTERN MAPPING COMPLETE
