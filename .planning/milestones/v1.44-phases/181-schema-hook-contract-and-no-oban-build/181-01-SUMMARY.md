---
phase: 181-schema-hook-contract-and-no-oban-build
plan: 01
subsystem: build-hygiene
status: complete
tags: [oban, optional-deps, verify, ci, elixir-1.19]
requires: []
provides:
  - "Isolated, self-checking mix verify.no_optional_deps"
  - "Scrypath.Oban.Enqueue.job_changeset/4 (@doc false)"
  - "Mix.Tasks.Verify.Capability.run_core/1,2"
affects: [verify.core, core (required) CI job, Scrypath.Sync.RelatedEnqueue]
tech-stack:
  added: []
  patterns: ["MIX_BUILD_PATH isolation for optional-dep compile", "post-compile absence proof", "injectable task_runner for capability sequencing"]
key-files:
  created:
    - test/mix/tasks/verify_no_optional_deps_test.exs
  modified:
    - lib/mix/tasks/verify.no_optional_deps.ex
    - lib/scrypath/oban/enqueue.ex
    - lib/scrypath/sync/related_enqueue.ex
    - lib/mix/tasks/verify/capability.ex
    - test/mix/tasks/verify_capability_test.exs
    - test/mix/tasks/workflow_wiring_test.exs
    - CONTRIBUTING.md
    - .planning/PROJECT.md
    - .planning/reference/ROLLING-ROADMAP.md
decisions:
  - "Isolated no-Oban compile runs under MIX_ENV=prod in _build/no_optional_deps (A2; reversible)"
  - "verify.core composes verify then verify.no_optional_deps; deep-quality keeps its own copy; ci.yml unchanged"
  - "RelatedEnqueue builds jobs via the shared runtime-guarded Enqueue.job_changeset/4 instead of a compile-time Oban branch"
metrics:
  duration: "~25 min"
  completed: 2026-10-26
requirements_completed: [HYG-02]
actuals:
  tokens: 9000
  tasks: 3
  commits: 5
plan_head_before: ad978c892deec1b75520bdbdb078bcc665e753f1
plan_head_after: 01e1d41ada4ed09385b4270c7c90dfcc18f44ec2
---

# Phase 181 Plan 01: Schema Hook Contract and No-Oban Build Summary

`mix verify.no_optional_deps` now compiles into an isolated `_build/no_optional_deps` under `MIX_ENV=prod` and checks afterwards that Oban never reached the build. The old no-Oban `RelatedEnqueue` stub always raised, which gave a real Elixir 1.19 type warning at `sync.ex:74`. It is replaced by the shared runtime-guarded job builder, and the check now runs inside `mix verify.core`, so the required core CI job runs it.

## RED evidence

Observed after the task fix (commit b219ee8a) and before the source fix (commit 8f1f2b30), on Elixir 1.19.0 / OTP 28. `mix verify.no_optional_deps` exited 1:

```
==> scrypath
Compiling 148 files (.ex)
    warning: incompatible types given to decorate_result/2:

        decorate_result(
          (&Scrypath.Sync.RelatedEnqueue.enqueue(schema_module, records, fan_out_key, &1)).(
            Scrypath.Config.ensure_oban_ready!(config)
          ),
          config
        )

    given types:

        -none()-, dynamic()

    the 1st argument is empty (often represented as none()), most likely because it is the result of an expression that always fails, such as a `raise` or a previous invalid call. This causes any function called with this value to fail
    ...
    typing violation found at:
    │
 74 │         |> decorate_result(config)
    │            ~
    │
    └─ lib/scrypath/sync.ex:74:12: Scrypath.Sync.do_sync_related/6

Compilation failed due to warnings while using the --warnings-as-errors option

** (Mix) root compile without optional dependencies failed
```

After the fix (8f1f2b30) the output has no `warning:` lines and ends with `==> Verified optional dependencies absent from isolated build: oban`, exit 0.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | Tracer: isolated, self-proving no-Oban build; RED at sync.ex:74; RelatedEnqueue fix | 76de943b (test RED), b219ee8a (task fix), 8f1f2b30 (source fix) |
| 2 | Run the no-Oban build in verify.core; pin no blanket suppression | 964a366d |
| 3 | CONTRIBUTING, PROJECT.md, ROLLING-ROADMAP; full core gate | 01e1d41a |

## Verification (local, Elixir 1.19.0 / OTP 28.1)

- Task 1 test set (verify_no_optional_deps, related, related_worker, enqueue_unique, sync, oban): 87 tests, 0 failures
- `mix verify.no_optional_deps`: exit 0, 0 `warning:` lines, absence-verified line printed
- `mix compile --warnings-as-errors --force` (with Oban): clean
- `mix test test/mix/tasks/verify_capability_test.exs test/mix/tasks/workflow_wiring_test.exs`: 57 tests, 0 failures
- `mix verify.core --exclude integration --exclude docs_contract`: exit 0. "Standard Maturity Gate: PASSED", then "verify capability delegates to mix verify.no_optional_deps" and "Verified optional dependencies absent from isolated build: oban". 937 tests, 0 failures. The `warning: [scrypath] tenant_field ...` lines in the output are expected runtime log output from existing tests, not compiler warnings.
- docs_contract + package_metadata: 79 tests, 0 failures
- `.github/workflows/ci.yml` and `test/scrypath/sync/related_test.exs` unchanged
- Still due: exact-SHA hosted CI evidence from the core (required) job at the PR

## TDD Gate Compliance

- Task 1: RED test commit 76de943b (6 of 7 seam tests failed as undefined; the arg guard already existed), then GREEN in b219ee8a (task) and 8f1f2b30 (source). The plan's behavioral RED (the compile warning) is recorded above.
- Task 2: tests and implementation were committed together in 964a366d. The `run_core` sequence test cannot pass without `run_core/2`. The three suppression tests are guards that pass on the current, clean tree.

## Deviations from Plan

None in scope. Environment setup only: the fresh worktree had no `deps/`, so I ran `mix deps.get` against the existing `mix.lock`. No packages were added and `mix.lock` is unchanged. Commands ran with `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1`, as the plan's shell note says.

## Known Stubs

None.

## Self-Check: PASSED

- Created/modified files exist; commits 76de943b, b219ee8a, 8f1f2b30, 964a366d, 01e1d41a are ancestors of HEAD.
