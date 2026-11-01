---
phase: 183-maintainer-tooling-outside-the-hex-package
plan: "05"
subsystem: release-gates
tags: [hex-package, package-contract, mix-tasks, ast-scan, mutation-tests, verify-phase11, pkgh-03]
requires:
  - phase: 183-04
    provides: "dev/mix/tasks holds the 53 maintainer files; lib/mix/tasks holds exactly the 8 public tasks; test/release/package_contents_test.exs with the tooling boundary describe"
provides:
  - "Scrypath.Release.PackageContract: fail-closed allowlist plus AST task scan over real hex.build --unpack output"
  - "Hermetic control and five mutation tests with exact violation lines"
  - "Prod and test compile proofs of the unpacked archive without dev/"
  - "verify.phase11 runs the gate, so mix verify.package (required package job, release-please, publish-hex) executes it"
affects: [183-06, 183-07, 183-08]
tech-stack:
  added: []
  patterns:
    - "Pure classify/2 plus thin check/1 runner over unpacked hex.build output"
    - "Nested-aware defmodule resolver over Code.string_to_quoted!/1, names via Mix.Task.task_name/1"
    - "System.cmd mix subprocesses always pass explicit MIX_ENV, isolated MIX_BUILD_PATH and HEX_OFFLINE=1"
key-files:
  created:
    - test/support/release/package_contract.ex
  modified:
    - test/release/package_contents_test.exs
    - dev/mix/tasks/verify.phase11.ex
    - test/scrypath/docs_contract_test.exs
    - test/release/package_metadata_test.exs
key-decisions:
  - "Hermetic tests use System.tmp_dir! plus on_exit cleanup instead of the :tmp_dir tag, which would leave an untracked tmp/ in the checkout"
  - "Prod archive compile runs deps.compile as a separate step so Oban's own compiler warnings cannot trip the warning check on scrypath sources; the test build reuses the checkout's compiled deps"
  - "Missing-task and unexpected-task lines carry tag, task, module, path and a fix: hint naming both remedies"
requirements-completed: [PKGH-01, PKGH-02, PKGH-03]
status: complete
commits: 4
plan_head_before: 0083877ddd881bad90497191f00d8e11da5a6aee
plan_head_after: b999b21d2228c1a36dcf7f3e2d99268cebbf5140
actuals:
  tokens: 6500
  tasks: 3
  commits: 4
duration: 35min
completed: 2026-10-28
coverage:
  - id: D1
    description: "PackageContract classifier returns :ok for the allowlist and exact sorted tagged lines for forbidden, unexpected and missing entries"
    requirement: PKGH-03
    verification:
      - kind: unit
        ref: "test/release/package_contents_test.exs#classifier"
        status: pass
    human_judgment: false
  - id: D2
    description: "Drift guards pin allowed_top_level to mix.exs package files, public_task_entries to the repo's own lib Mix.Tasks modules, and every public task to the packaged docs"
    requirement: PKGH-03
    verification:
      - kind: unit
        ref: "test/release/package_contents_test.exs#drift guards"
        status: pass
    human_judgment: false
  - id: D3
    description: "Real hex.build --unpack control returns :ok and the five leak shapes (scrypath.repo_only, verify.sneaky, hidden module in lib/scrypath, dev in files:, deleted scrypath.status) fail with exact lines"
    requirement: PKGH-03
    verification:
      - kind: integration
        ref: "test/release/package_contents_test.exs#real archive"
        status: pass
    human_judgment: false
  - id: D4
    description: "The unpacked archive compiles with --warnings-as-errors under MIX_ENV=prod and MIX_ENV=test with dev/ absent, each ebin holding exactly the 8 public Mix.Tasks beams"
    requirement: PKGH-02
    verification:
      - kind: integration
        ref: "test/release/package_contents_test.exs#unpacked archive compiles without the dev tree"
        status: pass
    human_judgment: false
  - id: D5
    description: "verify.phase11 runs package_contents_test.exs and the wiring is pinned; package files refute dev"
    requirement: PKGH-03
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix verify.package"
        status: pass
      - kind: unit
        ref: "test/scrypath/docs_contract_test.exs#verify.phase11 keeps the release gate auth-free and complete"
        status: pass
      - kind: unit
        ref: "test/release/package_metadata_test.exs#package file allowlist only targets root library surfaces"
        status: pass
    human_judgment: false
---

# Phase 183 Plan 05: Package contents gate Summary

**Fail-closed `Scrypath.Release.PackageContract` (allowlist plus AST scan over real `hex.build --unpack` output) proven by a control and five mutations, prod/test archive compiles without `dev/`, and wired into `verify.phase11` so the required package lane runs it.**

## Performance

- **Duration:** about 35 min
- **Tasks:** 3 (Task 1 TDD, RED then GREEN)
- **Commits:** 4 production commits, plus the SUMMARY commit
- **Files:** 1 created, 4 modified

## Task Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 RED | `368a7d32` | test(183-05): add failing classifier and drift-guard tests for PackageContract |
| 1 GREEN | `0cec1adb` | test(183-05): implement PackageContract fail-closed classifier |
| 2 | `403d4c94` | test(183-05): prove the gate on real hex.build output and compile the archive |
| 3 | `b999b21d` | ci(183-05): run the package contents gate in verify.phase11 and pin it |

## RED and GREEN record (Task 1)

RED: `test/support/release/package_contract.ex` was a stub (every accessor empty, `check/1` and `classify/2` returning `:ok`, `collect_task_modules/1` returning `[]`). `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/release/package_contents_test.exs` ran 13 tests, 9 failures, every one an assertion on the planned behavior (for example `left: :ok, right: {:error, ["[forbidden-path] dev fix: ..."]}` and `left: [], right: [{"verify.hidden", Mix.Tasks.Verify.Hidden, ...}]`). No compile errors, no zero-test discovery. Semantic assessment: the targets executed and failed on the planned assertions for the intended reason.

GREEN: the real module made all 13 pass (0 failures, 0.6 s), then `mix format --check-formatted` and `mix credo --strict` were clean (one credo `map_join` suggestion in the test was fixed first).

## Mutation results on real hex.build output (Task 2)

| Case | Exact returned value |
|------|----------------------|
| Control (unmutated copy) | `:ok` |
| `lib/mix/tasks/scrypath.repo_only.ex` | `{:error, ["[unexpected-task] scrypath.repo_only Mix.Tasks.Scrypath.RepoOnly lib/mix/tasks/scrypath.repo_only.ex fix: move the file to dev/mix/tasks/, or add the task to @public_tasks and document it in guides/operator-mix-tasks.md"]}` |
| `lib/mix/tasks/verify.sneaky.ex` | same shape, `[unexpected-task] verify.sneaky Mix.Tasks.Verify.Sneaky lib/mix/tasks/verify.sneaky.ex fix: ...` |
| Top-level `defmodule Mix.Tasks.Verify.Hidden` appended to the first `lib/scrypath/*.ex` | `[unexpected-task] verify.hidden Mix.Tasks.Verify.Hidden lib/scrypath/<first file>.ex fix: ...` (names the ordinary file) |
| `~w(lib ` replaced by `~w(dev lib ` in the copy's mix.exs, plus `dev/mix/tasks/verify.probe.ex` | `{:error, ["[forbidden-path] dev fix: remove it from package files: in mix.exs; maintainer tooling stays outside the Hex archive"]}` (the test first does `refute mutated == original`) |
| `scrypath.status.ex` deleted | exactly one line: `[missing-task] scrypath.status Mix.Tasks.Scrypath.Status lib/mix/tasks/scrypath.status.ex fix: restore lib/mix/tasks/scrypath.status.ex (move it back from dev/mix/tasks/ if it was moved there), or remove the task from @public_tasks and from guides/operator-mix-tasks.md` |

## Archive compile (PKGH-02)

The control archive has no `dev/` entry; `mix.lock` is copied in; `Mix.Project.deps_path()` is shared.

- `MIX_ENV=prod`: `mix compile --warnings-as-errors` exit 0, no `warning:` in the scrypath compile output, ebin holds exactly `Elixir.Mix.Tasks.Scrypath.{Failed, Index.ContractDrift, Reconcile, Retry, Settings.Diff, Settings.HotApply, Settings.Read, Status}.beam`, zero `Elixir.Mix.Tasks.Verify*`.
- `MIX_ENV=test` (dev/mix/tasks named in `elixirc_paths` but absent): same, exit 0, same 8 beams, zero Verify beams.

## Wall times (Nyquist named exceptions)

| Run | Wall time |
|-----|-----------|
| Six real-archive cases (control plus five mutations), each | 0.40 to 0.61 s (about 2.8 s total) |
| Prod archive compile (includes cold deps.compile) | 5.8 s and 14.2 s on two runs |
| Test archive compile (reused dep builds) | 2.0 to 2.3 s |
| Whole `test/release/package_contents_test.exs` (21 tests) | 20.3 s |
| Task 3 focused run (package_metadata + package_contents + docs_contract, 100 tests) | about 13 s |
| `MIX_ENV=test mix verify.package` (exit 0; 'Release contract tests' step ran 102 tests, 0 failures, then release contract greps and hex.build) | 20 s |
| Full fast suite `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration` (5 properties, 1057 tests, 0 failures, 27 excluded) | 34 s |

## Pre-move evidence (D-16 step 4, recorded, not a red commit)

Phase base = parent of `2c45a862` (the 183-01 fence rename), which still holds every verifier under `lib/`. A fresh `hex.build --unpack` of that tree (isolated build path, `HEX_OFFLINE=1`) checked with the new `PackageContract.check/1`:

```
unexpected=53 missing=0
```

Wall time for the extract, build and check: a few seconds (the checker itself under 1 s after VM boot). Optional published-package run, `mix hex.package fetch scrypath 0.3.17 --unpack`, same checker:

```
unexpected=52 missing=0
```

Both match research F4 (the published tarball predates `verify.postgres`). Sample first violation: `[unexpected-task] scrypath.namespace_fence Mix.Tasks.Scrypath.NamespaceFence lib/mix/tasks/scrypath.namespace_fence.ex fix: ...`.

## Acceptance checks

- `grep -n 'Code.string_to_quoted!' ...` and `grep -n 'Mix.Task.task_name' ...` on package_contract.ex print lines; `grep -n '~r'` prints nothing.
- The full missing-task line (module, expected path, both remedies) is asserted literally in the test file.
- `HEX_OFFLINE`, `"--output"` and `refute mutated == original` each present.
- No `lib/mix/tasks/scrypath.repo_only.ex`, `lib/mix/tasks/verify.sneaky.ex` or `dev/mix/tasks/verify.probe.ex` in the real tree after the suite; `git status` clean.
- In verify.phase11, `package_contents_test.exs` sits on line 31, between `package_metadata_test.exs` (30) and `consumer_smoke_test.exs` (32).
- `git diff --quiet <phase base> -- .github/workflows/release-please.yml .github/workflows/publish-hex.yml` exit 0 (D-12) and `cmp` of `verify.release_parity.ex` against the phase base exit 0 (D-13).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prod archive compile tripped on dependency warnings**
- **Found during:** Task 2 first run
- **Issue:** `mix compile --warnings-as-errors` in a cold `MIX_ENV=prod` build also compiles Oban, which prints its own "clause never used" warnings, so `refute output =~ "warning:"` failed on code the package does not own.
- **Fix:** Prod runs `mix deps.compile` first (exit checked, output not scanned), then the scrypath compile whose output is scanned. The test build skips `deps.compile` because it reuses the checkout's compiled deps; running it there recompiled every dependency and cost about 22 s.
- **Files modified:** test/release/package_contents_test.exs
- **Commit:** 403d4c94

**2. [Rule 3 - Blocking] tmp dir source**
- **Found during:** Task 2 design
- **Issue:** ExUnit's `:tmp_dir` tag writes to `tmp/` inside the checkout, which is not gitignored and is never cleaned.
- **Fix:** Used the plan's allowed fallback, `System.tmp_dir!/0` plus `on_exit` cleanup.
- **Commit:** 403d4c94

**3. [Environment] Pre-move evidence command run as split steps**
- The tool sandbox refused the single compound command, so the same operations ran as separate commands with the checker script saved under the scratchpad directory. Same inputs, same checker, same result.

**Total deviations:** 3 (1 bug fix, 1 blocking, 1 environment note). **Impact:** none on behavior or scope.

### Toolchain note
Per the orchestrator, mix ran under `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` (not the plan's 1.19.5/28.1); deps/ and _build/test were copied from the main checkout (gitignored).

## Issues Encountered

None beyond the deviations above.

## Known Stubs

None.

## Threat Flags

None. No new network or auth surface: subprocesses are offline (`HEX_OFFLINE=1`), build into tmp dirs, and the docs_contract pin still refutes `HEX_API_KEY` in verify.phase11. T-183-07 mitigated by the allowlist plus AST scan with exact-line mutations; T-183-09 by `refute mutated == original` and the post-suite real-tree leak check. T-183-SC: no installs; `hex.package fetch` only read the already-published scrypath 0.3.17.

## Self-Check: PASSED

- test/support/release/package_contract.ex: FOUND
- test/release/package_contents_test.exs, dev/mix/tasks/verify.phase11.ex, test/scrypath/docs_contract_test.exs, test/release/package_metadata_test.exs: FOUND, modified
- Commits 368a7d32, 0cec1adb, 403d4c94, b999b21d: FOUND in HEAD ancestry
- `MIX_ENV=test mix verify.package` exit 0; fast suite 1057 tests, 0 failures

## Next Phase Readiness

The contents gate runs in the required lane. 183-06 can add the compiled-consumer L2 assertions to `consumer_smoke_test.exs` (the AST scan's documented backstop for dynamically generated task modules) and 183-07 can add the "packaged docs" describe to the same test file.
