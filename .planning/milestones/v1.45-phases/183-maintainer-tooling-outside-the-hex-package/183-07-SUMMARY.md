---
phase: 183-maintainer-tooling-outside-the-hex-package
plan: "07"
subsystem: release-packaging
tags: [docs, exdoc, hex-package, contributing]
requires:
  - phase: 183-05
    provides: package_contents_test.exs gate describes and Scrypath.Release.PackageContract
provides:
  - "describe \"packaged docs\" guard: no Mix.Tasks.Verify in ExDoc extras or lib"
  - "Unfiltered docs/0 with an explanatory comment (D-07 as amended)"
  - "Source-checkout qualifiers in CONTRIBUTING, README, two guides, releasing doc"
affects: [183-08]
tech-stack:
  added: []
  patterns: ["hermetic docs guard instead of an ExDoc module filter"]
key-files:
  created: []
  modified:
    - test/release/package_contents_test.exs
    - mix.exs
    - CONTRIBUTING.md
    - README.md
    - guides/support-and-compatibility.md
    - guides/outside-adopter-intake.md
    - docs/releasing.md
key-decisions:
  - "D-07 as amended 2026-10-28: docs/0 stays unfiltered; a hermetic guard replaces the module filter"
requirements-completed: [PKGH-01, PKGH-02]
status: complete
commits: 2
plan_head_before: 193b0be864109392cc5cf580faf430241eb4d4a5
plan_head_after: bbaa8d99b531639639b3bc29e64e4f5cd3e5e931
actuals:
  tokens: 3500
  tasks: 2
  commits: 2
duration: 15min
completed: 2026-10-28
---

# Phase 183 Plan 07: Packaged-docs guard and source-checkout boundary docs Summary

Applied amended D-07 (docs/0 left unfiltered, with a hermetic guard that keeps Verify module names out of ExDoc extras and lib) and told readers that the `mix verify*` commands run from a source checkout and are not part of the Hex package.

## D-07 decision source

183-CONTEXT.md D-07, "Amended 2026-10-28 (maintainer-approved)": "Leave `docs/0` unchanged, with no `filter_modules`. Add a hermetic guard that packaged docs (every ExDoc extra) and packaged `lib/**/*.ex` never reference `Mix.Tasks.Verify`." The original text is kept in CONTEXT for history. The `@moduledoc false` prohibition still applies.

## Docs builds not run here

Neither `MIX_ENV=test mix docs --warnings-as-errors` nor `MIX_ENV=dev mix docs --warnings-as-errors` was run in this plan. Both are closeout-only gates (183-VALIDATION.md) and are proven once in 183-08 Task 1. If either fails there, the repair lands as a new commit in this plan's files.

## Task results

1. **Task 1 (f2de8cdb):** added `describe "packaged docs"` (reads every `docs[:extras]` entry, string or `{path, opts}`, plus `lib/**/*.ex`, and asserts none contains `Mix.Tasks.Verify`; fails if the file list is empty). Added a two-line comment above `extras:` in `mix.exs docs/0`. Preservation gates: no `filter_modules` in mix.exs, 53 files under lib/ and dev/ define a Verify module, 27 of them carry `@moduledoc false` (baseline unchanged). Guard test: 1 test, 0 failures.
2. **Task 2 (bbaa8d99):** doc sentences below. Four pinned contract suites: 95 tests, 0 failures. Guard re-run green. All six anchor greps pass. `mix verify.adopter --live` still present in README and both guides; `mix verify.meilisearch_smoke` still present twice in README.

## Doc sentences added

- CONTRIBUTING.md (new paragraph before "Use capability-named commands for new work."): "Repository-only `mix verify*` tasks live in `dev/mix/tasks/` and are not part of the Hex package; public operator tasks (`mix scrypath.*`) stay in `lib/mix/tasks/`. Command names and focused test paths are unchanged. Verifier tasks compile only under `MIX_ENV=test`, which `preferred_envs` selects automatically; `MIX_ENV=dev mix verify.adopter` (or `mix help verify.adopter` without `MIX_ENV=test`) reports that the task could not be found."
- README.md: "From a source checkout (these tasks are not part of the Hex package), run `mix verify.adopter` locally ..." and "From a source checkout (this task is not part of the Hex package), you can use Docker Compose locally (from the repo root):".
- guides/support-and-compatibility.md and guides/outside-adopter-intake.md: "These verification commands run from a source checkout of the Scrypath repository; they are not part of the Hex package."
- docs/releasing.md: "The gate also builds and unpacks the real Hex archive, and fails if the archive contains any top-level entry outside the package allowlist or any Mix task other than the public `mix scrypath.*` operator tasks. Repository-only verifiers live in `dev/mix/tasks/` and are never packaged."

## D-19 PR title

`fix(package): keep repository-only verify tasks out of the Hex package` (used by 183-08 when opening the PR). CHANGELOG.md is untouched.

## Deviations from Plan

None - plan executed exactly as written. The toolchain used `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` per the orchestrator note, instead of the plan's 1.19.5/28.1 values; deps/ and _build/ were copied from the main checkout (gitignored).

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- mix.exs, test/release/package_contents_test.exs, CONTRIBUTING.md, README.md, both guides and docs/releasing.md modified and committed.
- Commits f2de8cdb and bbaa8d99 are ancestors of HEAD.
