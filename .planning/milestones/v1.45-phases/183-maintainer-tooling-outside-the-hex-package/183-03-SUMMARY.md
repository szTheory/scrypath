---
phase: 183-maintainer-tooling-outside-the-hex-package
plan: "03"
subsystem: test-support
tags: [exunit, repo-tooling, path-decoupling, hyg-02]
requires: ["183-01"]
provides:
  - "Scrypath.RepoTooling (tasks_root/0, task_path/1, task_source!/1) with root still lib/mix/tasks"
  - "13 test files reading verifier source through the helper, no literal verifier path in test/"
  - "HYG-02 scans cover dev/**/*.ex"
affects: [183-04]
tech-stack:
  added: []
  patterns:
    - "single-constant root for repo-only tooling location (@tasks_root)"
key-files:
  created:
    - test/support/repo_tooling.ex
  modified:
    - test/scrypath/docs_contract_test.exs
    - test/scrypath/phase99_contract_test.exs
    - test/mix/tasks/workflow_wiring_test.exs
    - test/mix/tasks/verify.phase97_test.exs
    - test/mix/tasks/verify.phase98_test.exs
    - test/mix/tasks/verify.phase99_test.exs
    - test/mix/tasks/verify.phase106_test.exs
    - test/mix/tasks/verify.phase107_test.exs
    - test/mix/tasks/verify.phase108_test.exs
    - test/mix/tasks/verify.phase112_test.exs
    - test/mix/tasks/verify_adopter_test.exs
    - test/mix/tasks/verify_phoenix_example_package_test.exs
    - test/mix/tasks/verify_capability_test.exs
key-decisions:
  - "D-14: module is Scrypath.RepoTooling in test/support; File.read!/1 makes a wrong root raise File.Error"
  - "D-08: both workflow_wiring HYG-02 scans flat-map lib/**/*.ex and dev/**/*.ex"
  - "D-15: no test file moved or renamed; no asserted string changed"
requirements-completed: [PKGH-02]
status: complete
commits: 2
plan_head_before: b975e62801d3eee21937ab11a9960bacedbb1a5b
plan_head_after: 9e023aa2cd3d82a3392f69503cb67b4e4f7c1ccc
actuals:
  tokens: 3500
  tasks: 2
  commits: 2
completed: 2026-10-28
---

# Phase 183 Plan 03: Decouple verifier source reads from the verifier tree location Summary

Every test that reads verifier source now goes through `Scrypath.RepoTooling`, whose root is still `lib/mix/tasks`, so 183-04 relocates all reads by changing one constant.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | 7b0946d9 | test(183-03): add Scrypath.RepoTooling and convert compile-time and wiring reads |
| 2 | 9e023aa2 | test(183-03): route remaining verifier source reads through RepoTooling |

## Conversion grep line counts (`grep -rn "lib/mix/tasks" test`)

| Point | Lines |
|-------|-------|
| Before Task 1 | 32 (13 files) |
| After Task 1 (before adding helper file's own comment/constant) | 11 outside the 3 converted files, all in Task 2's 10 files |
| After Task 2 | 2 lines, both inside `test/support/repo_tooling.ex` (a comment and `@tasks_root`) |

`grep -rn 'lib/mix/tasks/verify' test` prints nothing after Task 2.

## What changed

- `test/support/repo_tooling.ex`: `@moduledoc false`, `@tasks_root "lib/mix/tasks"`, `tasks_root/0`, `task_path/1` (`Path.join`), `task_source!/1` (`File.read!`).
- 19 compile-time attributes in `docs_contract_test.exs` plus the attribute in `phase99_contract_test.exs` use `task_source!/1`; `@verify_task` in `workflow_wiring_test.exs` uses `task_path/1`.
- Both HYG-02 scans in `workflow_wiring_test.exs` now iterate `["lib/**/*.ex", "dev/**/*.ex"]` via `Enum.flat_map(&Path.wildcard/1)`; the `>= 3` Oban assertion is unchanged.
- Nine in-test reads in `verify.phase{97,98,99,106,107,108,112}_test.exs`, `verify_adopter_test.exs`, `verify_phoenix_example_package_test.exs` use `task_source!/1`.
- `verify_capability_test.exs`: both `File.exists?` paths use `task_path/1`, and each is paired with `assert Mix.Task.get("verify.#{task}")`. The 183-01 fence tuples are untouched.

## Verification run (all passing)

| Command | Result |
|---------|--------|
| Task 1 grep gates (no literal verifier path in 3 files; `dev/**/*.ex` count >= 2) | pass |
| `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors` on docs_contract, phase99_contract, workflow_wiring | 146 tests, 0 failures |
| `grep -rn 'lib/mix/tasks/verify' test` | empty |
| Same compile+test on the 12 Task 2 suites | 59 tests, 0 failures |
| `mix format --check-formatted` | clean |
| `mix credo --strict` | no issues (267 files) |
| `grep -rln "Scrypath.RepoTooling" test \| grep -v support \| wc -l` | 13 |
| Deleted test files since the fence move's parent (`git diff -M --diff-filter=D`) | 0 |
| `MIX_ENV=test mix test --warnings-as-errors --exclude integration` | 5 properties, 1035 tests, 0 failures (27 excluded) |

The "artifact failed" line in test output comes from an existing negative-path test in `verify_phoenix_example_package_test.exs` (suite reports 0 failures).

## Deviations from Plan

None - plan executed exactly as written. The `Mix.Task.get/1` assertion is the Claude's Discretion item the plan called for.

Environment notes: the fresh worktree had no `deps/` or `_build/`, so I copied the main checkout's gitignored copies (no package installed, `mix.lock` unchanged). Used `ASDF_ELIXIR_VERSION=1.19.0-otp-28`, `ASDF_ERLANG_VERSION=28.5` per the orchestrator note instead of the plan's versions.

## Known Stubs

None.

## Threat Flags

None. T-183-02 is mitigated: `task_source!/1` uses `File.read!/1` and the repo-wide grep gate shows no literal verifier path remains.

## Next

Ready for 183-04: flip `@tasks_root` to `dev/mix/tasks` inside the pure-rename move commit.

## Self-Check: PASSED

- `test/support/repo_tooling.ex` exists with `@tasks_root "lib/mix/tasks"`.
- Commits 7b0946d9 and 9e023aa2 are ancestors of HEAD; no test file deleted.
