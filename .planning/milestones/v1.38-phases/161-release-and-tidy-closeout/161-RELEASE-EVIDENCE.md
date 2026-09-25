# Phase 161 Release Evidence

## Disposition

**Shipped as Scrypath 0.3.13 on 2026-09-25.** The release was merged through the Release Please PR and published by the repository's credential-scoped workflow. Main CI, Hex visibility, versioned HexDocs, consumer compile, and package-to-tag parity all passed.

## Merge and exact-SHA evidence

| Gate | Evidence | Result |
|-------|----------|--------|
| Phase 161 candidate | PR [#77](https://github.com/szTheory/scrypath/pull/77), head `4f020835deaaef2d3fbe5ff237f25511fa629c8d`, merged as `465aef9bc6c9c05fb021b5aa3d5b6b584aed568d` | Squash-merged after the maintainer authorized merge once CI passed. No GitHub review object was submitted. |
| Candidate exact-SHA proof | [Run 36080380783](https://github.com/szTheory/scrypath/actions/runs/36080380783) | Success on exact PR head; required jobs, coverage, ecommerce E2E, and closeout attestation passed. Receipt: `/private/tmp/scrypath-161-final-closeout.json`. |
| Main after Phase 161 merge | [Run 36081908742](https://github.com/szTheory/scrypath/actions/runs/36081908742) | Success on merge commit `465aef9bc6c9c05fb021b5aa3d5b6b584aed568d`. |
| Release Please PR | PR [#78](https://github.com/szTheory/scrypath/pull/78), head `34f749ea2169616fd37affaeeda0ef3c97252ab2`, merged as `28d3877a05479f2cc104754fc24ab0c9d545c01b` | Generated version, manifest, and changelog for 0.3.13 agree. Pull-request CI run [36083342047](https://github.com/szTheory/scrypath/actions/runs/36083342047) passed all five required jobs and active advisories on the exact PR head. The exact-SHA dispatch run [36082426093](https://github.com/szTheory/scrypath/actions/runs/36082426093) also passed coverage and ecommerce E2E. Maintainer authorized squash merge after checks passed; no GitHub review object was submitted. |
| Main after release merge | [Run 36083655506](https://github.com/szTheory/scrypath/actions/runs/36083655506) | Success on `28d3877a05479f2cc104754fc24ab0c9d545c01b`. |

## Publication and parity

| Field | Evidence |
|-------|----------|
| Version | `0.3.13` |
| Git tag / GitHub release | [`scrypath-v0.3.13`](https://github.com/szTheory/scrypath/releases/tag/scrypath-v0.3.13), published 2026-09-25 |
| Release workflow | [Run 36083655678](https://github.com/szTheory/scrypath/actions/runs/36083655678), conclusion `success` |
| Publish job | `publish-hex`, job 107910798515, conclusion `success` |
| Ordered checks | Workspace clean, version, `mix verify.package`, Hex dry-run, Hex publish, `mix verify.release_publish 0.3.13`, and `mix verify.release_parity 0.3.13` all passed. |
| Published outputs | Hex package visibility, documented clean-consumer compile, and versioned HexDocs availability passed in `verify.release_publish`; the published tarball matched the release tag in `verify.release_parity`. |

`HEX_API_KEY` was used only by the scoped publish job; its value was not read.

## PR triage

- PR #77 carried the Phase 161 implementation and evidence. Required and advisory checks passed on the exact head; the maintainer authorized squash merge after those checks passed.
- PR #78 was the sole Release Please version PR. Its 0.3.13 manifest, `mix.exs`, and changelog values matched; the pull-request checks passed before squash merge.
- Earlier release-train PRs #63, #61, and #59 remain historical context: #63 and #61 merged, and #59 was a duplicate closed unmerged. No further v1.38 release PR remains open.

## Ownership and workspace cleanup

- The Phase 161 cleanup inventory found no milestone-owned temporary worktree or service stack. Package-proof temp paths and generated ExDoc output were removed; other projects' containers and temporary directories were preserved.
- The original worktree's unrelated modified Phase 134 and Phase 136 UAT files, `.planning/research/.cache/`, `.planning/state.json`, and the pre-existing untracked `.planning/v1.38-MILESTONE-AUDIT.md` were preserved. The milestone archive was prepared separately from the shipped `main` commit.
- CI service containers terminated with their jobs. The release workflow verified its own clean checkout before publishing.

## Final result

All Phase 161 and REL-01 gates are satisfied. Scrypath 0.3.13 is **published and verified**; there is no remaining release blocker or human UAT item.
