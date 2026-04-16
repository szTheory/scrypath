---
phase: 06-phoenix-ergonomics-and-public-facing-polish
plan: 06-04
subsystem: infra
tags: [github-actions, hex, docs, phoenix, release-quality]
requires:
  - phase: 06-phoenix-ergonomics-and-public-facing-polish
    provides: release automation, public docs surface, and fixture-backed Phoenix examples from 06-03
provides:
  - Auth-free CI package verification for release-quality checks
  - Release-only Hex publish dry-run guidance with explicit authentication requirements
  - README and Phoenix guide contracts locked to public-release and integer pagination examples
affects: [ci, release-process, readme, phoenix-guides, docs-tests]
tech-stack:
  added: []
  patterns: [auth-free-ci-package-gate, release-only-publish-validation, fixture-backed-docs-contracts]
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - docs/releasing.md
    - README.md
    - guides/phoenix-controllers-and-json.md
    - test/scrypath/docs_contract_test.exs
    - test/support/docs/phoenix_examples_test.exs
key-decisions:
  - "Kept the always-on CI release gate auth-free by validating package metadata and unpack behavior instead of publish credentials."
  - "Moved Hex publish dry-run validation into maintainer-only release docs behind an explicit HEX_API_KEY requirement."
  - "Locked the Phoenix JSON page normalization contract in both public docs and fixture-backed tests so copied examples stay valid."
patterns-established:
  - "Public release checks belong in unattended CI only when they are auth-free and deterministic."
  - "Phoenix guide snippets that cross type boundaries should be enforced by fixture-backed contract tests, not syntax checks alone."
requirements-completed: [PHNX-01, PHNX-02]
duration: 3 min
completed: 2026-04-16
---

# Phase 6 Plan 06-04 Summary

**Auth-free CI release checks, release-only publish validation docs, and a fixture-locked Phoenix JSON pagination contract**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-16T16:11:00Z
- **Completed:** 2026-04-16T16:13:51Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Removed publish-auth coupling from the always-on CI quality gate and kept package verification on `mix test test/release/package_metadata_test.exs` plus `mix hex.build --unpack`.
- Reframed `docs/releasing.md` so `mix hex.publish --dry-run --yes` is a release-only maintainer step gated by `HEX_API_KEY`, while the README now advertises a versioned Hex dependency.
- Updated the Phoenix JSON guide to normalize `params["page"]` before passing `page.number`, then enforced that contract in docs and fixture-backed tests.

## Verification

- `sh -c "rg -n 'mix hex.build --unpack|mix test test/release/package_metadata_test.exs' .github/workflows/ci.yml && ! rg -n 'mix hex.publish --dry-run' .github/workflows/ci.yml"` -> pass
- `rg -n 'mix hex.publish --dry-run --yes|HEX_API_KEY' docs/releasing.md` -> pass
- `sh -c "rg -n '\\{:scrypath, \"~> [0-9]+' README.md && ! rg -n 'path: \"\\.\\./scrypath\"' README.md"` -> pass
- `rg -n 'page_number =|String.to_integer|page: \\[number: page_number, size: 20\\]' guides/phoenix-controllers-and-json.md test/support/docs/phoenix_example_case.ex` -> pass
- `mix test test/scrypath/docs_contract_test.exs` -> pass (`9 tests, 0 failures`)
- `mix test test/support/docs/phoenix_examples_test.exs` -> pass (`7 tests, 0 failures`)

## Task Commits

1. **Task 1: Make the release gate and install path public-release accurate** - `4e1eb59` (`fix`)
2. **Task 2: Lock the Phoenix JSON example to integer page normalization** - `5f73cf2` (`fix`)

## Files Created/Modified

- `.github/workflows/ci.yml` - replaced the publish dry-run CI step with package metadata verification and kept package unpack checks.
- `docs/releasing.md` - separated the auth-free package gate from maintainer-only publish credential validation.
- `README.md` - changed the installation snippet to a versioned Hex dependency.
- `guides/phoenix-controllers-and-json.md` - normalized JSON controller page params before building `page.number`.
- `test/scrypath/docs_contract_test.exs` - added direct assertions for the release gate, README dependency, and JSON pagination guide contract.
- `test/support/docs/phoenix_examples_test.exs` - added fixture-backed assertions for JSON page normalization.

## Decisions Made

- Kept CI on release-quality artifact checks that do not require publisher credentials.
- Documented publish dry-run as a release-only command instead of pretending it is part of unattended CI.
- Treated page param normalization as a public docs contract because Phoenix controller params arrive as strings.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix test` commands briefly contended on the shared `_build` lock during parallel verification, but both completed successfully without code changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The remaining Phase 6 public-surface gaps from verification and review are closed.
- CI, maintainer docs, README install guidance, and Phoenix JSON docs now agree on the supported release and request-param contracts.

## Self-Check

PASSED

- FOUND: `.planning/phases/06-phoenix-ergonomics-and-public-facing-polish/06-04-SUMMARY.md`
- FOUND: `4e1eb59`
- FOUND: `5f73cf2`
