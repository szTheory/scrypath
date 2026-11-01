---
phase: 183-maintainer-tooling-outside-the-hex-package
plan: "02"
subsystem: maintainer-tooling
tags: [ci, credo, formatter, beam-cache, workspace-gate, codeowners]
requires: []
provides:
  - "formatter, credo, workspace gate and CODEOWNERS cover dev/"
  - "BEAM cache graph keys fingerprint dev/ for all four graphs"
  - "ops-ui-path CI filter matches dev/ diffs"
affects: [183-04]
tech-stack:
  added: []
  patterns: ["additive coverage edits each paired with a check that can fail"]
key-files:
  created: []
  modified:
    - .formatter.exs
    - .credo.exs
    - lib/mix/tasks/verify.workspace_clean.ex
    - test/mix/tasks/verify_workspace_clean_test.exs
    - CODEOWNERS
    - scripts/ci/beam_cache.cjs
    - scripts/ci/beam_cache.test.cjs
    - .github/workflows/ci.yml
key-decisions:
  - "D-08: every coverage tool keyed on lib/ also covers dev/ before the bulk move"
requirements-completed: [PKGH-01, PKGH-02]
duration: 20 min
completed: 2026-10-28
status: complete
commits: 3
plan_head_before: ccb50a05874176b5d9f5083328dba7d431287586
plan_head_after: c93b65ae2f62154b9ecfe8a29a5425efb8792155
actuals:
  tokens: 4000
  tasks: 2
  commits: 3
---

# Phase 183 Plan 02: Extend coverage tooling to dev/ Summary

Formatter, credo, the pre-publish workspace gate, CODEOWNERS, all four BEAM cache graph keys and the ops-ui path filter now cover `dev/`, each with a check that fails when `dev/` is not covered.

## Accomplishments

- `.formatter.exs` input glob is `{config,lib,dev,test}`; `.credo.exs` includes `dev/`. Probe files prove both reject violations under `dev/`.
- `Mix.Tasks.Verify.WorkspaceClean.build_pathspecs/0` returns `package_files ++ ["dev", "test"]`, pinned by a new `assert "dev" in pathspecs`.
- `CODEOWNERS` gains `/dev/ @szTheory`.
- `sourceRoots` of root, ops, ecommerce and phoenix-example graphs in `scripts/ci/beam_cache.cjs` list `dev` after `lib`.
- ci.yml ops-ui-path filter regex is `^(scrypath_ops/|lib/|dev/|mix\.exs|mix\.lock)`; exactly one line changed.

## Commits

| Task | Commit | Type |
|------|--------|------|
| 1 | e5dd85a5 | chore(183-02): extend formatter, credo, workspace gate and CODEOWNERS to dev/ |
| 2 RED | 0020c3db | test(183-02): add failing test for dev/ BEAM cache fingerprinting |
| 2 GREEN | c93b65ae | ci(183-02): key BEAM cache and ops-ui path filter on dev/ |

## Probe results (never committed; created and removed in the verify command)

| Probe | Command | Exit | Meaning |
|-------|---------|------|---------|
| Malformatted `dev/mix/tasks/zz_format_probe.ex` | `mix format --check-formatted` | 1 | rejected, formatter covers dev/ (real tree: exit 0) |
| `IO.inspect` in `dev/mix/tasks/zz_credo_probe.ex` | `mix credo --strict` | 16 | rejected; credo reports `There should be no calls to IO.inspect/1` at `dev/mix/tasks/zz_credo_probe.ex:3:17`, and the file count rose 266 to 267 (real tree: exit 0, 266 files) |

`git status --porcelain -- dev` was empty after both probes.

## TDD record for the node test (Task 2)

- **RED** (before the `sourceRoots` edit): `node --test scripts/ci/beam_cache.test.cjs` reported 9 pass, 1 fail. The target test "dev maintainer sources fingerprint every graph" failed on its planned assertion: `AssertionError: root source_files should include dev/mix/tasks/verify.ex` (`actual: false, expected: true`). Semantic assessment: the target executed and failed for the intended reason (dev/ not in `sourceRoots`), not a syntax, load or fixture fault.
- **GREEN** (after the edit): 10 pass, 0 fail. Every graph's `source_files` contains the dev file and `resolved_key` and `plt_key` both rotate after the append.

## Verification commands run (all exit 0 unless noted)

- `mix format --check-formatted`
- `mix credo --strict` (266 files, no issues)
- `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/verify_workspace_clean_test.exs` (5 tests, 0 failures, 1 excluded)
- `node --test scripts/ci/beam_cache.test.cjs` (10 pass)
- `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs` (59 tests, 0 failures)
- `MIX_ENV=test mix verify.repository_contracts` (98 tests, 0 failures)
- Acceptance greps: formatter 1, credo 1, workspace_clean 1, test assertion 1, CODEOWNERS 1; ci.yml diff is one line; `sourceRoots: ["lib", "dev", "test"` appears 4 times with no remaining `["lib", "test"` graph.

## Deviations from Plan

None - plan executed exactly as written.

Environment note (not a deviation in code): the fresh worktree had no `deps/` or `_build/`, so credo and ExUnit could not run. I copied the main checkout's gitignored `deps/` and `_build/` into the worktree; no packages were installed or changed and neither directory is tracked.

## Known Stubs

None.

## Threat Flags

None. No new network, auth or file-access surface; the one CI change is a path-filter regex.

## Notes

- The single one-time rotation of all four BEAM cache keys is the expected outcome; no shared cache was deleted or bypassed.
- 183-04 can now move `lib/mix/tasks/verify.workspace_clean.ex` as a pure rename, because this content edit landed first (D-16 step 2).

## Self-Check: PASSED

- All 8 modified files exist and carry the described edits (acceptance greps pass).
- Commits e5dd85a5, 0020c3db and c93b65ae are ancestors of HEAD.
