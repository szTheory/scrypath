---
phase: 183-maintainer-tooling-outside-the-hex-package
plan: "01"
subsystem: release-packaging
tags: [mix, hex-package, namespace-fence, elixirc_paths, tracer]
requires: []
provides:
  - "dev/mix/tasks tree (unpackaged, compiled only under :test)"
  - "Mix.Tasks.Verify.NamespaceFence (task verify.namespace_fence)"
  - "mix.exs elixirc_paths/1 keyed on Mix.env()"
affects: [183-03, 183-04, 183-05]
tech-stack:
  added: []
  patterns:
    - "env-keyed elixirc_paths (:test adds dev/mix/tasks) with preferred_envs routing"
key-files:
  created:
    - dev/mix/tasks/verify.namespace_fence.ex
    - test/mix/tasks/verify_namespace_fence_test.exs
  modified:
    - mix.exs
    - lib/mix/tasks/verify/capability.ex
    - test/mix/tasks/verify_capability_test.exs
  removed:
    - lib/mix/tasks/scrypath.namespace_fence.ex
    - test/mix/tasks/scrypath/namespace_fence_test.exs
decisions:
  - "D-03: renamed scrypath.namespace_fence to verify.namespace_fence with no compatibility alias"
  - "D-05: elixirc_paths(:test) includes dev/mix/tasks; every other env compiles lib only"
  - "D-06: MIX_ENV=dev cannot find the task"
metrics:
  tasks: 1
status: complete
actuals:
  tokens: 2500
  tasks: 1
  commits: 1
plan_head_before: ccb50a05874176b5d9f5083328dba7d431287586
plan_head_after: 2c45a8621514be5288e504557eb930dbf8cc8df0
commits: 1
completed: 2026-10-28
---

# Phase 183 Plan 01: Tracer, namespace fence relocated to dev/mix/tasks Summary

The Sigra namespace fence now lives at `dev/mix/tasks/verify.namespace_fence.ex`, compiles only under `:test` through an env-keyed `elixirc_paths/1`, and is absent from the built Hex archive.

## Tracer commit

- `2c45a862` (full SHA `2c45a8621514be5288e504557eb930dbf8cc8df0`), `refactor(183-01): move Sigra namespace fence to dev/mix/tasks as verify.namespace_fence`.
- Phase base for later history checks is that commit's parent: `ccb50a05874176b5d9f5083328dba7d431287586`.
- Git records both moved files as renames (`R095`).

## What changed

- `mix.exs`: `elixirc_paths: elixirc_paths(Mix.env())` in `project/0`; `defp elixirc_paths(:test), do: ["lib", "dev/mix/tasks"]` and `defp elixirc_paths(_env), do: ["lib"]`; `"verify.namespace_fence": :test` in `preferred_envs`.
- Fence renamed to `Mix.Tasks.Verify.NamespaceFence`; only the module name and the argument-guard message changed.
- `lib/mix/tasks/verify/capability.ex`: the three references now name `verify.namespace_fence`.
- Tests: fence test moved to `test/mix/tasks/verify_namespace_fence_test.exs` as `Mix.Tasks.Verify.NamespaceFenceTest`; both fence tuples in `verify_capability_test.exs` updated. No assertion weakened or removed.

## Verification run (all passing)

| Command | Result |
|---|---|
| `mix verify.namespace_fence` (no MIX_ENV) | exit 0, `==> Namespace fence passed` |
| `MIX_ENV=dev mix verify.namespace_fence` | exit 1, `The task "verify.namespace_fence" could not be found` |
| `mix hex.build --unpack` | no `dev/` entry, no `*namespace_fence*` file, 40+ `lib/mix/tasks/verify*` sources still present |
| `git grep` for old task name / old module outside `.planning` | no matches |
| `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors` on the two touched suites | 11 tests, 0 failures |
| `mix format --check-formatted` and `mix credo --strict` | clean, no issues |
| `MIX_ENV=test mix test --warnings-as-errors --exclude integration` | 5 properties, 1035 tests, 0 failures (27 excluded) |

## Deviations from Plan

None to the plan's scope. One environment note: the fresh worktree had no `deps/`, so I ran `mix deps.get` to fetch the locked versions. `mix.lock` is unchanged and no package was added or substituted.

## Known Stubs

None.

## Threat Flags

None. T-183-01 is mitigated: the old scrypath-prefixed name is gone from every tracked file outside `.planning/`, and the built archive omits the fence.

## Self-Check: PASSED

- `dev/mix/tasks/verify.namespace_fence.ex` and `test/mix/tasks/verify_namespace_fence_test.exs` exist.
- Commit `2c45a862` is an ancestor of HEAD; `git ls-files test/mix/tasks/scrypath` is empty.
