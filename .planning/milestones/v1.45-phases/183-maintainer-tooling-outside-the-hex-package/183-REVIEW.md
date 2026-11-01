---
phase: 183-maintainer-tooling-outside-the-hex-package
reviewed: 2026-10-28T14:36:28Z
depth: standard
files_reviewed: 85
files_reviewed_list:
  - .credo.exs
  - .formatter.exs
  - .github/workflows/ci.yml
  - CODEOWNERS
  - CONTRIBUTING.md
  - README.md
  - dev/mix/tasks/verify.adopter.ex
  - dev/mix/tasks/verify.all.ex
  - dev/mix/tasks/verify.coverage.ex
  - dev/mix/tasks/verify.ex
  - dev/mix/tasks/verify.meilisearch_smoke.ex
  - dev/mix/tasks/verify.namespace_fence.ex
  - dev/mix/tasks/verify.no_optional_deps.ex
  - dev/mix/tasks/verify.ops_ui.ex
  - dev/mix/tasks/verify.phase10.ex
  - dev/mix/tasks/verify.phase106.ex
  - dev/mix/tasks/verify.phase107.ex
  - dev/mix/tasks/verify.phase108.ex
  - dev/mix/tasks/verify.phase11.ex
  - dev/mix/tasks/verify.phase112.ex
  - dev/mix/tasks/verify.phase13.ex
  - dev/mix/tasks/verify.phase14.ex
  - dev/mix/tasks/verify.phase20.ex
  - dev/mix/tasks/verify.phase22.ex
  - dev/mix/tasks/verify.phase26.ex
  - dev/mix/tasks/verify.phase28.ex
  - dev/mix/tasks/verify.phase36.ex
  - dev/mix/tasks/verify.phase37.ex
  - dev/mix/tasks/verify.phase38.ex
  - dev/mix/tasks/verify.phase41.ex
  - dev/mix/tasks/verify.phase43.ex
  - dev/mix/tasks/verify.phase5.ex
  - dev/mix/tasks/verify.phase8.ex
  - dev/mix/tasks/verify.phase82.ex
  - dev/mix/tasks/verify.phase83.ex
  - dev/mix/tasks/verify.phase84.ex
  - dev/mix/tasks/verify.phase85.ex
  - dev/mix/tasks/verify.phase91.ex
  - dev/mix/tasks/verify.phase94.ex
  - dev/mix/tasks/verify.phase96.ex
  - dev/mix/tasks/verify.phase97.ex
  - dev/mix/tasks/verify.phase98.ex
  - dev/mix/tasks/verify.phase99.ex
  - dev/mix/tasks/verify.postgres.ex
  - dev/mix/tasks/verify.release_parity.ex
  - dev/mix/tasks/verify.release_publish.ex
  - dev/mix/tasks/verify.workspace_clean.ex
  - dev/mix/tasks/verify/backend.ex
  - dev/mix/tasks/verify/capability.ex
  - dev/mix/tasks/verify/compatibility.ex
  - dev/mix/tasks/verify/core.ex
  - dev/mix/tasks/verify/deep_quality.ex
  - dev/mix/tasks/verify/ecommerce_e2e.ex
  - dev/mix/tasks/verify/ecommerce_mounted.ex
  - dev/mix/tasks/verify/package.ex
  - dev/mix/tasks/verify/phoenix_example.ex
  - dev/mix/tasks/verify/phoenix_example/lock_graph.ex
  - dev/mix/tasks/verify/phoenix_example/package.ex
  - dev/mix/tasks/verify/repository_contracts.ex
  - docs/releasing.md
  - guides/outside-adopter-intake.md
  - guides/support-and-compatibility.md
  - mix.exs
  - scripts/ci/beam_cache.cjs
  - scripts/ci/beam_cache.test.cjs
  - test/mix/tasks/verify.phase106_test.exs
  - test/mix/tasks/verify.phase107_test.exs
  - test/mix/tasks/verify.phase108_test.exs
  - test/mix/tasks/verify.phase112_test.exs
  - test/mix/tasks/verify.phase97_test.exs
  - test/mix/tasks/verify.phase98_test.exs
  - test/mix/tasks/verify.phase99_test.exs
  - test/mix/tasks/verify_adopter_test.exs
  - test/mix/tasks/verify_capability_test.exs
  - test/mix/tasks/verify_namespace_fence_test.exs
  - test/mix/tasks/verify_phoenix_example_package_test.exs
  - test/mix/tasks/verify_workspace_clean_test.exs
  - test/mix/tasks/workflow_wiring_test.exs
  - test/release/consumer_smoke_test.exs
  - test/release/package_contents_test.exs
  - test/release/package_metadata_test.exs
  - test/scrypath/docs_contract_test.exs
  - test/scrypath/phase99_contract_test.exs
  - test/support/release/package_contract.ex
  - test/support/repo_tooling.ex
findings:
  critical: 0
  warning: 4
  info: 5
  total: 9
status: issues_found
---

# Phase 183: Code Review Report

**Reviewed:** 2026-10-28T14:36:28Z
**Depth:** standard
**Files Reviewed:** 85
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

Scope: all 85 files in the phase diff (`2a0f1428..HEAD`, `.planning/` excluded). For the 49 pure `R100` renames I checked only for breakage caused by the move: `__DIR__`, `Path.expand` and `File.cwd!` usage, sibling-file reads, hard-coded `lib/mix/tasks` paths, `MIX_ENV` subprocess routing, and self-referencing fence allowlists. All of them resolve paths relative to the repository cwd, and none of them hard-codes its own location. No `lib/mix/tasks/verify*` reference survives outside `.planning/`. Nothing in `lib/`, `scrypath_ops/` or `examples/` references a `Mix.Tasks.Verify*` module. The path dependencies (`scrypath_ops`, both examples) use the default `:prod` dep env, so they do not compile `dev/`.

I found no blockers. The env-keyed `elixirc_paths` design, the `preferred_envs` routing, and the wiring of the gate into `verify.phase11` are correct as shipped. The defects are in the phase's own guards, which are weaker than the decisions they claim to enforce:

- No test catches a leak of `dev/mix/tasks` into non-test builds (WR-01).
- The D-04 preferred-env guard classifies tasks by name, not by location (WR-02).
- The L1 AST scan misses three ordinary ways of naming a module (WR-03). I proved this with a probe.
- Adopter-facing website copy still tells package installers to run a task that is no longer shipped (WR-04).

## Warnings

### WR-01: Nothing guards against `dev/mix/tasks` leaking into `:prod`/`:dev` builds (path and git consumers)

**File:** `test/release/package_contents_test.exs:216` (guard), `mix.exs:112-113` (subject)
**Issue:** The D-17 boundary guard asserts only the positive half: `"dev/mix/tasks" in project[:elixirc_paths]`. It evaluates under `Mix.env() == :test`, so a regression to `defp elixirc_paths(_env), do: ["lib", "dev/mix/tasks"]` passes it.

Every other layer misses that regression too:
- Both the L0/L1 archive checks and the L2 consumer compile work on the `hex.build --unpack` output, which never contains `dev/`.
- Mix tolerates a missing `elixirc_paths` entry. The `MIX_ENV=test` archive compile in this same file depends on that and proves it.
- `verify.no_optional_deps` compiles the real checkout in `:prod`, but it asserts only that optional deps are absent and never looks at the task surface.

Under that regression, `scrypath_ops`, both `examples/*` (`path: "../.."`) and every adopter using `git:` against GitHub would compile all 53 verifier tasks again. That is the exact leak PKGH-01 and D-05 exist to stop, and no test would fail.
**Fix:** Pin the non-test envs. The function is private, but `project/0` reads `Mix.env()`, so:
```elixir
for env <- [:dev, :prod] do
  previous = Mix.env()
  try do
    Mix.env(env)
    refute "dev/mix/tasks" in MixProject.project()[:elixirc_paths],
           "dev/mix/tasks compiles in #{env}; path/git consumers would receive maintainer tasks"
  after
    Mix.env(previous)
  end
end
```
Alternatively, have `verify.no_optional_deps` assert that its isolated `:prod` ebin has no `Elixir.Mix.Tasks.Verify*.beam` and holds exactly `PackageContract.public_task_entries()`.

### WR-02: The D-04 preferred-env guard classifies by module name, not by location under `dev/mix/tasks`

**File:** `test/mix/tasks/verify_capability_test.exs:79-83`
**Issue:** D-04 requires that "every `use Mix.Task` module under `dev/mix/tasks` has a matching `:test` entry". The guard filters `:application.get_key(:scrypath, :modules)` by the prefix `"Elixir.Mix.Tasks.Verify"`. Suppose a maintainer task with any other name is added under `dev/mix/tasks/`, for example `dev/mix/tasks/scrypath.lint.ex` defining `Mix.Tasks.Scrypath.Lint`. The guard ignores it. Without a `preferred_envs` entry, plain `mix scrypath.lint` then reports "could not be found". That is the PKGH-02 break the guard exists to prevent. D-09 cites `scrypath.namespace_fence` as proof that a non-`verify` name inside maintainer tooling is a real case, and this guard repeats the namespace assumption the phase rejected.
**Fix:** Select tasks by source location:
```elixir
maintainer_tasks =
  "dev/mix/tasks/**/*.ex"
  |> Path.wildcard()
  |> Enum.map(&{&1, File.read!(&1)})
  |> Scrypath.Release.PackageContract.collect_task_modules()
  |> Enum.filter(fn {_name, mod, _path} ->
    Code.ensure_loaded?(mod) and
      Mix.Task in Keyword.get(mod.module_info(:attributes), :behaviour, [])
  end)
  |> Enum.map(&elem(&1, 0))
```

### WR-03: The L1 AST scan misses aliased, `Elixir.`-prefixed and atom-literal module names

**File:** `test/support/release/package_contract.ex:131-160` (`defined_modules/2`, `resolve_module/2`); the limit is documented at lines 16-18
**Issue:** The resolver claims to prefix nested modules "exactly as the compiler does". It does not expand aliases, it treats a leading `Elixir.` as relative, and it ignores atom names. I ran a probe on Elixir 1.19 against the real module. In each case `collect_task_modules/1` returned `[]` while `Code.compile_string/1` defined `Mix.Tasks.Verify.*`:
- `alias Mix.Tasks, as: T` followed by `defmodule T.Verify.AliasHidden` was missed. The same applies to `alias Mix.Tasks` inside a parent module followed by `defmodule Tasks.Verify.X`.
- `defmodule Elixir.Mix.Tasks.Verify.AbsHidden` nested inside `Scrypath.Holder` was resolved to `Scrypath.Holder.Elixir.Mix...` and missed. The compiler defines the absolute `Mix.Tasks.Verify.AbsHidden`.
- `defmodule :"Elixir.Mix.Tasks.Verify.AtomHidden"` was missed.

The L2 `scrypath.app` module-list check in `consumer_smoke_test.exs:115-125` runs in the same `verify.phase11` lane and does catch all three, so nothing leaks today. But:
- The documented limit names only `Module.create/3` and unquoted names, so it understates the gap.
- All five "real archive" mutation tests exercise L1 only.

A maintainer who trusts L1, or runs `package_contents_test.exs` by itself, gets a false `:ok`.
**Fix:** Handle the cases the compiler handles. Treat a leading `:"Elixir"` segment as absolute (`Module.concat(rest)`). Accept atom names (`when is_atom(name)`). Track `alias` forms in the walk, or fail closed whenever a `defmodule` name's first segment matches an alias in scope. At minimum, extend the comment at lines 16-18 to list aliases, `Elixir.`-prefixed names and atom literals. Also add one mutation test (for example, the aliased form) that runs through `check/1` and is caught by the consumer L2 path, so the backstop claim is tested.

### WR-04: The website still tells package installers and operators to run `mix verify.adopter`, which the package no longer ships

**File:** `website/src/pages/index.html:173`, `website/src/pages/operators.html:45`, `website/src/pages/docs.html:131-132` (outside the review list, but this phase made them wrong)
**Issue:** D-18 qualified every packaged-doc mention of `mix verify.adopter`, but the adopter-facing website was not updated:
- `index.html:173` says "Install the package, wire one schema, and run `mix verify.adopter`".
- `operators.html:45` lists "Run `mix verify.adopter`" as an operator step next to `mix scrypath.status`.

Since this phase, an adopter or operator following that copy in their own app gets `The task "verify.adopter" could not be found`. The consumer smoke test now asserts exactly that outcome for `verify.package`. This is user-visible guidance that is now false.
**Fix:** Apply the same qualifier used in README and the guides. For example: "From a source checkout of the Scrypath repository (not part of the Hex package), run `mix verify.adopter`…". In `operators.html`, either drop the step or point operators at `mix scrypath.status`. Update any website contract pins in `test/scrypath/phase110_contract_test.exs` and `phase112_contract_test.exs` in the same change.

## Info

### IN-01: The `verify.workspace_clean` moduledoc still describes only `test/**`

**File:** `dev/mix/tasks/verify.workspace_clean.ex:3-4`
**Issue:** The `@doc` for `build_pathspecs/0` and the inline comment were updated to say `dev` and `test`. The `@moduledoc`, which `mix help verify.workspace_clean` shows, still says "pathspecs that ship in the Hex tarball plus `test/**`".
**Fix:** Change it to "plus `dev/**` and `test/**`".

### IN-02: CONTRIBUTING says "Command names and focused test paths are unchanged", but this phase renamed one of each

**File:** `CONTRIBUTING.md:28`
**Issue:** This phase renamed `scrypath.namespace_fence` to `verify.namespace_fence`, and moved its test from `test/mix/tasks/scrypath/namespace_fence_test.exs` to `test/mix/tasks/verify_namespace_fence_test.exs` (D-03). The claim is true for the documented commands only.
**Fix:** Change it to "Documented command names and focused test paths are unchanged; the internal namespace fence is now `mix verify.namespace_fence`."

### IN-03: The README qualifier refers to "this task" before naming any task

**File:** `README.md:196`
**Issue:** "From a source checkout (this task is not part of the Hex package), you can use Docker Compose locally". The antecedent `mix verify.meilisearch_smoke` first appears in the code block below this sentence, so the parenthetical reads as if it describes Docker Compose.
**Fix:** Change it to "From a source checkout, you can use Docker Compose locally (`mix verify.meilisearch_smoke` is not part of the Hex package):". This keeps the pinned command strings unchanged.

### IN-04: Double-negative assertion

**File:** `test/release/consumer_smoke_test.exs:110`
**Issue:** `refute verify_beams != []` is a harder-to-read form of `assert verify_beams == []`. It also loses ExUnit's left/right diff on failure.
**Fix:** Use `assert verify_beams == [], "..."`.

### IN-05: A parse failure in a packaged file does not report the file

**File:** `test/support/release/package_contract.ex:122`
**Issue:** `Code.string_to_quoted!(source)` is called without `file:`. A syntax error in any packaged `lib/**/*.ex`, including an injected mutation, raises `SyntaxError` with `nofile`, which hides which archive file broke the gate.
**Fix:** Use `Code.string_to_quoted!(source, file: path)`.

---

_Reviewed: 2026-10-28T14:36:28Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
