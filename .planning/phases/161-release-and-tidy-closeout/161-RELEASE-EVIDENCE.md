# Phase 161 Release Evidence

## Disposition

**Release-ready; not shipped.** Maintainer authorization to create PR #77 was received and the PR is open. The current 0.3.12 Hex release remains the baseline; no Phase 161 release has been published.

## Candidate

| Field | Value |
|-------|-------|
| Initial merge-candidate SHA | `febcd53b96a4ca4d981f45d9902a1abcee5bc631` |
| PR source / reviewed candidate SHA | `3053efcf06bf574d599e3969385dfd904d31ca53` |
| Main SHA | `1ccf353eb6c6e315d57903166431ec63ef1a7fab` |
| Branch | `gsd/v1.37-code-quality-ratchet` |
| Exact-SHA CI | [Run 36039689035](https://github.com/szTheory/scrypath/actions/runs/36039689035) — success on the PR source SHA |
| Required gates | core, package, repository-contracts, backend, ecommerce-mounted — all passed |
| Coverage and attestation | Passed; immutable artifacts and digests recorded in [161-VALIDATION.md](161-VALIDATION.md) |
| Mint/deep quality | Mint 1.10.1; hosted deep-quality passed with 0 Dialyzer errors; local Hex audit found no retired packages |
| Current release metadata | Version `0.3.12`, tag `scrypath-v0.3.12`; manifest, mix.exs, and changelog agree |

## PR inventory and triage

| PR | Scope / state | Review and checks | Disposition |
|----|---------------|-------------------|-------------|
| [#63](https://github.com/szTheory/scrypath/pull/63) | Milestone v1.37; merged 2026-08-27 | No submitted reviews or comments; required core/package/repository-contracts/backend/ecommerce-mounted checks succeeded on its own historical SHA. | Completed historical milestone; not the Phase 161 PR. |
| [#61](https://github.com/szTheory/scrypath/pull/61) | Release Please `scrypath 0.3.12`; merged 2026-08-25 | No submitted reviews; release checks succeeded; GitHub Actions comment links the created `scrypath-v0.3.12` tag. | Completed historical release baseline. |
| [#59](https://github.com/szTheory/scrypath/pull/59) | Duplicate Release Please `scrypath 0.3.12`; closed unmerged 2026-08-25 | No submitted reviews. Repository owner explained it was spurious because #41 recovered the prior release body. | Closed duplicate; not actionable. |
| [#77](https://github.com/szTheory/scrypath/pull/77) | Phase 161 milestone PR; open; base `main`; head `gsd/v1.37-code-quality-ratchet`; PR_CREATED_SHA = PR_REVIEW_SHA = `3053efcf06bf574d599e3969385dfd904d31ca53`. | No GitHub review or comments submitted. [PR check run 36046106195](https://github.com/szTheory/scrypath/actions/runs/36046106195): core, package, repository-contracts, backend, and ecommerce-mounted passed; deep-quality/Phoenix and other active advisories passed; coverage and full E2E skipped on pull_request. The exact-SHA workflow_dispatch run 36039689035 passed coverage and E2E too. Merge state is clean. | Authorized PR created; not merged. Awaiting actual maintainer review and merge authorization. |
| Release Please PR | No open release PR. Latest successful Release Please workflow run: [33086313543](https://github.com/szTheory/scrypath/actions/runs/33086313543) on main SHA `1ccf353eb6c6e315d57903166431ec63ef1a7fab`. | No release PR was produced by that run. | Pending future merge/tag/release event. |

`HEX_API_KEY` is present as a GitHub Actions secret name (last updated 2026-04-16); its value was not read.

## PR submission and review

- Exact approved title and body were submitted to [PR #77](https://github.com/szTheory/scrypath/pull/77).
- Base: `main`; head: `gsd/v1.37-code-quality-ratchet`; PR_CREATED_SHA: `3053efcf06bf574d599e3969385dfd904d31ca53`.
- Authorization to create was explicitly received. No merge authorization was given.
- Checks passed on the exact PR head. No maintainer review, approval, or review comments are recorded. Do not merge or claim the release shipped until the actual review/merge and publication gates pass.

## Publication and release workflow

- Current published release: `scrypath-v0.3.12` / Hex `0.3.12` (historical baseline).
- Phase 161 release version/tag: pending Release Please after the reviewed PR merges.
- Publish workflow run, Hex result, versioned HexDocs/consumer verification, and package-to-tag parity: pending; no new release is claimed.
- **Published:** no.
- **Blocker:** PR #77 has no actual maintainer review or merge decision; subsequent Release Please review/merge and tag publication are also pending.
- **Resume action:** obtain and record a real maintainer review of PR #77, merge it only under repository policy after exact-head checks remain green, then review/merge the generated Release Please PR under policy and follow its tag through Hex/HexDocs publish and parity gates.

## Ownership cleanup (Plan 04)

- Before/after `git worktree list --porcelain`: only `/Users/jon/projects/scrypath`, on the pre-existing `gsd/v1.37-code-quality-ratchet` branch; no temporary v1.38 worktree was created.
- The feature branch and its remote ref predated this execution. The authorized candidate push updated that existing ref; it is retained while PR #77 is open.
- Local and remote branch inventory showed no v1.38-owned disposable branch. Older unrelated/stale branches were preserved.
- Docker inventory showed no Scrypath-owned local service. Other projects' containers were left running. GitHub Actions service containers terminated with their jobs.
- Package proof tests left no `scrypath-phoenix-package-*` temp directories. Task-created `/private/tmp/scrypath-161-hex` and `/private/tmp/scrypath-gh-cache` were removed. Generated ExDoc output `doc/` from `mix docs` was removed. Other pre-existing `/private/tmp/scrypath-build-1.19.0` and `scrypath-namespace-fence-*` directories were left untouched because ownership was not established.
- The unrelated modified Phase 134 and 136 UAT files, untracked `.planning/research/.cache/`, and untracked `.planning/state.json` remain present and unstaged.
- No external cleanup limitation remains for resources proven to be owned by this execution.

## Final closeout SHA

Pending the commit that contains the Plan 03/04 summaries and final evidence updates. Run `node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"` after that commit and retain its exact SHA, run URL, five required jobs, coverage/attestation IDs and digests in the external final receipt and final response. Do not edit tracked files after that run.
