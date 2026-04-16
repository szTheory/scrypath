---
phase: 06-phoenix-ergonomics-and-public-facing-polish
plan: 06-03
subsystem: infra
tags: [release-please, hex, hexdocs, github-actions, package-metadata]
requires:
  - phase: 06-phoenix-ergonomics-and-public-facing-polish
    provides: public README and Phoenix guide surface from 06-01 and 06-02
provides:
  - Release Please manifest-mode automation for Scrypath releases
  - Hex package metadata and docs/source trust signals locked by test
  - CI-visible release gate with dry-run publish and unpacked package inspection
affects: [release-process, hex-package, hexdocs, ci, public-docs]
tech-stack:
  added: []
  patterns: [release-please-manifest-mode, mix-project-metadata-contract-test, unpacked-hex-package-inspection]
key-files:
  created:
    - .github/workflows/release-please.yml
    - release-please-config.json
    - .release-please-manifest.json
    - CHANGELOG.md
    - docs/releasing.md
    - test/release/package_metadata_test.exs
  modified:
    - .github/workflows/ci.yml
    - mix.exs
key-decisions:
  - "Used Release Please's native elixir release type in manifest mode so versioning and changelog updates stay on the standard path."
  - "Kept the human release checklist short and pushed repeatable docs/package checks into CI and Mix commands."
  - "Included guides and the maintainer release note in Hex package metadata so the published tarball matches the docs quality bar."
patterns-established:
  - "Release quality is checked through mix docs, package metadata tests, dry-run hex publish, and unpacked package inspection before any tag is cut."
  - "Public package trust signals are asserted directly from Mix project config instead of depending on prose drift."
requirements-completed: [PHNX-01, PHNX-02]
duration: 5 min
completed: 2026-04-16
---

# Phase 6 Plan 06-03 Summary

**Release Please automation, Hex package trust metadata, and a CI-visible dry-run release gate for the public Scrypath docs surface**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-16T15:50:32Z
- **Completed:** 2026-04-16T15:55:38Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added a dedicated Release Please workflow with manifest/config files and a changelog baseline for future public releases.
- Upgraded `mix.exs` so Hex/HexDocs expose stronger homepage, source, and package-link metadata and include the guide/release docs in the published package.
- Added a focused package metadata test and made CI run the non-publishing release gate: docs build, dry-run Hex publish, and unpacked package inspection.

## Task Commits

1. **Task 1: Add release automation and a changelog baseline** - `82306a8` (`feat`)
2. **Task 2: Upgrade package metadata and document the short release gate** - `226bbf4` (`feat`)

## Files Created/Modified

- `mix.exs` - added homepage/source metadata, maintainer docs extras, stronger package links, and explicit package contents
- `CHANGELOG.md` - added the release baseline for future Release Please entries
- `.github/workflows/ci.yml` - added release workflow config validation, dry-run publish, and unpacked package inspection
- `.github/workflows/release-please.yml` - added dedicated Release Please automation in manifest mode
- `release-please-config.json` - configured the repo for Release Please's Elixir releaser
- `.release-please-manifest.json` - recorded the current package baseline version
- `docs/releasing.md` - documented the short release gate and human-only follow-up checks
- `test/release/package_metadata_test.exs` - locked required package/docs metadata into focused assertions

## Decisions Made

- Used Release Please `elixir` manifest mode instead of inventing custom version bump logic.
- Kept release docs maintainers-focused and free of credential-handling instructions.
- Validated the unpacked Hex package tree directly because that is the concrete artifact reviewers inspect before publishing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed the Hex package inspection path after verification**
- **Found during:** Task 2
- **Issue:** The initial CI/release-doc check assumed `mix hex.build --unpack` left `contents.tar.gz` in the repo root, which is not how Hex 2.4 unpacks the package here.
- **Fix:** Switched the inspection to validate the unpacked `scrypath-<version>/` tree and updated the maintainer docs to use the same command.
- **Files modified:** `.github/workflows/ci.yml`, `docs/releasing.md`
- **Verification:** `mix test test/release/package_metadata_test.exs && mix docs --warnings-as-errors && mix hex.publish --dry-run && mix hex.build --unpack && find scrypath-* -maxdepth 3 -type f | grep -E '^scrypath-[^/]+/(README.md|CHANGELOG.md|ARCHITECTURE.md|docs/releasing.md|guides/|lib/|mix.exs)'`
- **Committed in:** `226bbf4`

---

**Total deviations:** 1 auto-fixed (1 rule-1 bug)
**Impact on plan:** The fix stayed inside the planned release gate and made the CI/package inspection commands match actual Hex behavior.

## Issues Encountered

- `mix hex.publish --dry-run` printed a local Hex key authorization warning in this environment, but still exited `0` and completed the local dry-run checks required by the plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 6 now ends with a public-release-quality package surface: guides, README, changelog, release automation, package metadata, and CI-visible release checks.
- The remaining work after this plan is normal maintainer operation: review Release Please PRs and publish from the verified package flow when the project is ready.

## Self-Check

PASSED

- FOUND: `.planning/phases/06-phoenix-ergonomics-and-public-facing-polish/06-03-SUMMARY.md`
- FOUND: `82306a8`
- FOUND: `226bbf4`

---
*Phase: 06-phoenix-ergonomics-and-public-facing-polish*
*Completed: 2026-04-16*
