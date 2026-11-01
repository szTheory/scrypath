---
phase: 183-maintainer-tooling-outside-the-hex-package
plan: "06"
subsystem: testing
tags: [hex, release, consumer-smoke, mix-tasks, package-contract]
requires:
  - phase: 183-maintainer-tooling-outside-the-hex-package
    provides: "183-05 Scrypath.Release.PackageContract (check/1, public_tasks/0)"
provides:
  - "setup_all-built release-like consumer (archive, git-tagged artifact, deps.get and compile once per module)"
  - "L0 allowlist check on the real hex.build archive, run before the test's own git init"
  - "L2 compiled-consumer proof: no Verify* beams, scrypath.app Mix.Tasks == public_tasks(), verify.package unresolvable, scrypath.status usage path, mix help for all 8 public tasks, in-VM Mix.Task probe"
affects: [183-08]
status: complete
commits: 2
plan_head_before: 193b0be864109392cc5cf580faf430241eb4d4a5
plan_head_after: 842ae23be8754da912012716fa56f768afd5bf21
actuals:
  tokens: 4200
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns:
    - "setup_all builds the expensive consumer once; tests read it from the ExUnit context"
    - "Capture a contract check result in setup_all and assert it in a test so failures are reported against a test"
key-files:
  created: []
  modified:
    - test/release/consumer_smoke_test.exs
key-decisions:
  - "PackageContract.check/1 runs in setup_all after build_packaged_artifact! and before the git init, so the test's own .git is never a violation; .git stays out of the allowlist"
  - "Subprocesses go through a non-asserting run_consumer/3 helper reusing the isolated HEX_HOME/MIX_HOME/MIX_ENV=dev env; probe task names pass via SCRYPATH_PUBLIC_TASKS built from PackageContract.public_tasks()"
requirements-completed: [PKGH-01, PKGH-03]
duration: 25 min
completed: 2026-10-28
---

# Phase 183 Plan 06: Consumer smoke proves the compiled task surface Summary

The release-like consumer is now built once per module and proves, from a real installed archive, that an adopter compiles exactly the 8 public operator tasks, cannot resolve maintainer tasks, and can run each public task's help path.

## Accomplishments

- Moved archive build, consumer scaffold, `deps.get` and `compile` into `setup_all` (one call site each). The prefix denylist is gone; `PackageContract.check(artifact_dir)` runs on the unpacked archive before the git init and its result is asserted in the first test with the violation lines in the failure message.
- Added test "the installed package exposes only the public operator tasks" covering all six L2 behaviors.
- Existing assertions (positive artifact paths, git-dep mix.exs, no path deps, compiled `ConsumerUsage.Post.beam`, "never falls back to path deps") are unchanged in behavior.

## Evidence

Consumer ebin `Elixir.Mix.Tasks.*` beams (8, no `Verify*`): `Scrypath.Failed`, `Scrypath.Index.ContractDrift`, `Scrypath.Reconcile`, `Scrypath.Retry`, `Scrypath.Settings.Diff`, `Scrypath.Settings.HotApply`, `Scrypath.Settings.Read`, `Scrypath.Status`.

| Probe | Status | Output excerpt |
|---|---|---|
| `mix verify.package` | 1 | `** (Mix) The task "verify.package" could not be found` |
| `mix scrypath.status` | 1 | `** (Mix) expected one schema module argument, for example \`SearchablePost\`` |
| `mix help scrypath.failed` | 0 | 654 bytes |
| `mix help scrypath.index.contract_drift` | 0 | 1329 bytes |
| `mix help scrypath.reconcile` | 0 | 516 bytes |
| `mix help scrypath.retry` | 0 | 478 bytes |
| `mix help scrypath.settings.diff` | 0 | 603 bytes |
| `mix help scrypath.settings.hot_apply` | 0 | 801 bytes |
| `mix help scrypath.settings.read` | 0 | 335 bytes |
| `mix help scrypath.status` | 0 | 476 bytes |
| `mix run --no-start -e <probe>` | 0 | `public-tasks-ok` |

- RED observation: with the module-set expectation temporarily set to `public_tasks() ++ ["verify.package"]` the test failed with the `left`/`right` mismatch (the extra `verify.package` on the right); restored before committing, no temporary change committed. The evidence IO.puts were likewise temporary.
- Operator-smoke path: `mix scrypath.status` ran its own `run/1` usage path (exit 1, usage error) in the bare consumer, so the preferred path carried scrypath.status. `mix help scrypath.status` is additionally checked in the 8-task loop.
- Wall time: consumer smoke suite 10.4 s (3 tests, `setup_all` build once); first-task-only shape was 6.6 s, so the L2 test plus 8 help calls added about 4 s. `MIX_ENV=test mix verify.package` exit 0.

## Deviations from Plan

None - plan executed exactly as written. (Toolchain: used the orchestrator's `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` rather than the plan's 1.19.5/28.1 values; copied deps/ and _build/ from the main checkout.)

## Known Stubs

None.

## Self-Check: PASSED

- `test/release/consumer_smoke_test.exs` present; commits a89bd8a4 and 842ae23b are ancestors of HEAD.
- Verify greps pass (no `forbidden_prefixes`, one `deps.get` call site in setup_all, `PackageContract.check(` precedes the git-init call site, all L2 strings present); `mix format --check-formatted` clean; focused suite 3 tests, 0 failures with `--warnings-as-errors`.
