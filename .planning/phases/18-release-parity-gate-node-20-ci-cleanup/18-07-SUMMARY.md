---
phase: 18-release-parity-gate-node-20-ci-cleanup
plan: 07
subsystem: docs-and-release
tags: [docs, changelog, release-please, closing-commit, hexdocs, release-parity]

# Dependency graph
requires: [18-02, 18-03, 18-04, 18-05, 18-06]
provides:
  - "docs/releasing.md §Release parity gate — HexDocs-visible maintainer prose explaining workspace_clean + release_parity gates and pointing at v1.2-MILESTONE-AUDIT.md (D-23)"
  - "CHANGELOG.md Unreleased section — names both new Mix tasks, Node 24 runtime upgrade, and v1.2 traceability bullet (D-24)"
  - "Phase 18 closing commit with D-22 feat(18): subject that release-please parses for 0.4.0 minor bump"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Keep-a-Changelog Unreleased section managed manually, promoted by release-please on publish"
    - "HexDocs extras pickup — files already in mix.exs docs.extras ship automatically, no mix.exs edit needed"
    - "Phase-close Conventional Commit as release-please signal — feat(<phase>): subject cuts minor bump on pre-1.0"

key-files:
  modified:
    - "docs/releasing.md"
    - "CHANGELOG.md"

key-decisions:
  - "[D-22]: Phase-close commit subject is feat(18): add release-parity gates + Node 20 CI cleanup — the feat: prefix is load-bearing for release-please pre-1.0 minor bump; chore/fix/docs would not cut 0.4.0, leaving Hex-vs-main divergence open."
  - "[D-23]: Insert Release parity gate section at end of docs/releasing.md (matching existing H2 hierarchy); no mix.exs docs.extras edit needed since docs/releasing.md already listed."
  - "[D-24]: CHANGELOG.md has a fresh Unreleased section added above [0.3.0]; release-please will absorb into 0.4.0 release notes on merge."
  - "[Phase 18]: Test gate shows 1 pre-existing unrelated failure in Scrypath.TelemetryTest (README doc drift from phase 12), verified as pre-existing by checking against phase-start HEAD dc5a2b4. Not a phase 18 regression."

patterns-established:
  - "Phase-close ritual: (a) write SUMMARY.md for final plan, (b) single feat(N): commit covering plan-close + SUMMARY, (c) release-please on merge opens version-bump PR, (d) merging version-PR triggers canonical publish path."

requirements-completed: [INFRA-01, INFRA-02, INFRA-03, INFRA-04]

# Metrics
duration: 8min
completed: 2026-04-17
---

# Phase 18 Plan 07: Docs + Closing Commit Summary

**Documents the Phase 18 gates in docs/releasing.md (HexDocs) and CHANGELOG.md (release-please), then closes the phase with the D-22 feat(18): commit that triggers release-please's 0.3.0 → 0.4.0 minor bump to re-align Hex with main.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-17 (Wave 4)
- **Completed:** 2026-04-17
- **Tasks:** 3 (2 automated + 1 human-verify)
- **Files modified:** 2 (docs/releasing.md, CHANGELOG.md)

## Accomplishments

- Added `## Release parity gate` section to `docs/releasing.md` with three subsections (`### mix verify.workspace_clean`, `### mix verify.release_parity X.Y.Z`, `### Historical context`) documenting what each gate catches, exit codes, and the v1.2-MILESTONE-AUDIT.md historical pointer. File ships to HexDocs via existing `mix.exs` `docs.extras` list (no mix.exs edit needed per plan).
- Added a fresh `## Unreleased` section to `CHANGELOG.md` with `### Added`, `### Changed`, `### Notes` subsections naming both new Mix tasks, the Node 24 runtime upgrade (`actions/checkout@v6`, `actions/cache@v5`), and the v1.2 traceability bullet. Released entries (`[0.3.0]`, `[0.2.0]`, `[0.1.0]`) preserved unchanged.
- Phase 18 closing commit with the load-bearing `feat(18):` subject landed so release-please will parse it for the 0.3.0 → 0.4.0 minor bump on merge to main.

## Task Commits

1. **Task 1: Add Release parity gate section to docs/releasing.md (D-23)** — `492fc1c` (docs)
2. **Task 2: Add Phase 18 deliverables to CHANGELOG.md Unreleased (D-24)** — `2719393` (docs)
3. **Task 3: Phase 18 closing commit + this SUMMARY** — final `feat(18):` commit (this one)

## Files Created/Modified

- `docs/releasing.md` — Added 42-line `## Release parity gate` section at end of file (before any terminating newline). Pre-existing sections unchanged. HexDocs visibility via existing `extras:` listing.
- `CHANGELOG.md` — Inserted 15-line `## Unreleased` block between the "Release Please manages versioned entries after this baseline." intro and the `## [0.3.0]` entry. Existing `[0.3.0]`, `[0.2.0]`, `[0.1.0]` entries untouched.
- `.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-07-SUMMARY.md` — This file.

## Decisions Made

None beyond what the plan specified. D-22 closing commit subject was taken verbatim.

## Deviations from Plan

- **CHANGELOG.md baseline state:** The plan assumed a pre-existing `## Unreleased` section to append to. In practice the file did not have one (release-please had promoted previous Unreleased content into `[0.3.0]`). Handled per plan's explicit branch: created a fresh `## Unreleased` block above `## [0.3.0]` with all three prescribed subsections. No content lost; Keep-a-Changelog structure preserved.
- **Closing-commit execution:** Plan Task 3 is a `checkpoint:human-verify` gate. The maintainer delegated creation of the `feat(18):` commit to Claude after reviewing the diff summary; the commit shape (subject + body) follows the plan's D-22 spec verbatim.

## Verification Results

Per plan `<verification>` section:

1. `mix test --exclude integration` — 191 tests, **1 pre-existing failure** in `Scrypath.TelemetryTest` (README wording drift from phase 12, confirmed pre-existing by checking against phase-start HEAD `dc5a2b4`). No phase 18 regressions.
2. `mix verify.release_parity 0.3.0` — **exit 0** (live against Hex; tag and tarball agree on lib/ + guides/ + docs/).
3. `mix verify.workspace_clean` — wired into 3 publish workflows (1 ref each verified by grep).
4. `docs/releasing.md` — `## Release parity gate` section present with all three subsections and v1.2-MILESTONE-AUDIT.md pointer.
5. `CHANGELOG.md` — Unreleased section names both tasks + Node 24 pins + v1.2 bullet; all substrings appear BEFORE the first `## N.N.N` release heading (awk check passes).
6. `mix.exs @version "0.3.0"` unchanged (release-please owns the bump).
7. `.github/ISSUE_TEMPLATE/release-parity-drift.md` present.
8. `.github/workflows/verify-published-release.yml` has release_parity step + create-an-issue step + `issues: write` permission.

## Self-Check: PASSED

- `grep -c "## Release parity gate" docs/releasing.md` → 1 ✓
- `grep -c "## Unreleased" CHANGELOG.md` → 1 ✓
- `grep -q '@version "0.3.0"' mix.exs` → true ✓
- Awk Unreleased-content ordering check → pass ✓
- Live `mix verify.release_parity 0.3.0` → exit 0 ✓

## User Setup Required

None for this plan. The closing commit pushes to main via PR; release-please will on merge open a version-bump PR (`mix.exs @version 0.3.0 → 0.4.0`). Merging the release-PR triggers the canonical publish path, which now enforces all four INFRA-0X gates.

## Next Phase Readiness

Phase 18 is complete. The v1.2-MILESTONE-AUDIT divergence is mechanized away:
- `workspace_clean` catches tag-vs-source drift at publish time (3 publish paths)
- `release_parity` catches tarball-vs-tag drift after publish (daily cron + dedup'd issue)
- Node 20 deprecation cleared (checkout@v6, cache@v5 across ci.yml)
- Docs + CHANGELOG promote both gates publicly

On merge, release-please opens the 0.4.0 PR. Merging that PR re-aligns Hex with main in the same release cycle. This is Phase 18's exit.

---
*Phase: 18-release-parity-gate-node-20-ci-cleanup*
*Plan: 07*
*Completed: 2026-04-17*
