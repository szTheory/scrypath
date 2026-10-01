# Phase 170 Plan 04: Candidate Delivery Record

**Status:** Candidate prepared; awaiting the blocking PR authorization checkpoint.

## Candidate identity

- Repository: `szTheory/scrypath`
- Owned branch: `agent-170-01-docs`
- Candidate source SHA: `00f8ea1655d189c99a8eb236c2caaadf2633c169`
- Refreshed public-main base: `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`
- Delivery worktree: isolated temporary checkout (local path intentionally omitted)
- Current remote branch head matches the candidate SHA.
- Candidate diff: exactly the seven-file Plan04 allowlist; 2,306 insertions and 162 deletions.

The changed paths are `README.md`, `guides/jtbd-and-user-flows.md`,
`guides/sync-modes-and-visibility.md`, `test/scrypath/docs_contract_test.exs`,
`scripts/ci_monitor.cjs`, `test/scripts/ci_monitor_test.exs`, and
`CONTRIBUTING.md`. `lib/`, lockfiles, examples, and the preserved tutorial
boundaries are unchanged.

## Candidate review

The candidate keeps the inline-first adoption path, routes the README by adopter
job, consolidates JTBD navigation, preserves the six numbered flows and all
local destinations, and documents the conditional sync return boundary. The
guide says inline `:completed` requires a returned task handle and terminal
wait, `:oban` returns `:accepted` after durable enqueue, and acceptance does
not imply search visibility or atomicity with database writes. Detailed return
fields remain with `Scrypath.sync_record/3` and the sync guide.

The before/after inventory over README and JTBD relative routes has 31 unique
destinations on each side, zero removed or newly added routes, and zero broken
relative links. All six numbered JTBD flows remain. This is bounded structural
and semantic review of route retention; it does not decide the broader
P-170-DOC quality judgment or assign a readiness condition status.

Internal code/security review was performed by the executing Codex agent; it
was not a GitHub review. Findings and dispositions:

1. Public decision-comment rendering could interpret supplied text as Markdown
   or HTML. The renderer now escapes free text and link labels and encodes
   parentheses in link destinations; regression tests cover the boundary.
2. Readiness records now require strict nested shapes and source/history pins,
   and validate issue ownership, author, title, body digest, and live status
   before treating the issue as an input. The checks remain factual-only.
3. Two successful hosted attempts exposed distinct collector join issues:
   upload-action digests are bare hex while REST artifact metadata uses
   `sha256:` form, and the action URL is a run-page URL while REST returns an
   API URL. The collector now canonicalizes the digest and joins the URLs
   through the exact run and artifact IDs. The corrected collector successfully
   read the preceding candidate's real artifact, then passed on the final
   candidate's own exact-source attempt below.
4. A documentation-contract path outside the allowlist was restored before
   review; the final diff contains only the seven authorized paths.

No unresolved high-severity internal finding remains. No reviewer identity or
approval has been simulated.

The seven selected public files were scanned for private user paths, AWS access
keys, GitHub tokens, private-key blocks, and bearer credentials; the scan found
no matches. The readiness input validator returned `FACTUAL_ONLY_VALID` with
`semantic_decision: null`.

## Local verification

Commands were run after the candidate source was committed at
`00f8ea1655d189c99a8eb236c2caaadf2633c169`:

- `mix verify.core --exclude integration --exclude docs_contract` — passed;
  639 tests, 0 failures, 85 excluded; formatting, warnings-as-errors compile,
  Credo, and ExDoc build also passed.
- `mix verify.package` — passed; 81 tests, release-workflow contract, Hex
  package build and unpack.
- `mix verify.repository_contracts` — passed; 82 tests.
- `mix test test/scrypath/docs_contract_test.exs test/scrypath/telemetry_test.exs`
  — passed; 81 tests.
- `mix test test/scripts/ci_monitor_test.exs` — passed; 15 tests.
- `node --check scripts/ci_monitor.cjs`, `git diff --check`, and
  `validate-readiness --stage inputs` — passed.

No Hex publish or readiness decision was made.

## Hosted exact-source evidence

- Run: [36780859495](https://github.com/szTheory/scrypath/actions/runs/36780859495)
- Attempt: 1
- Candidate SHA: `00f8ea1655d189c99a8eb236c2caaadf2633c169`
- Run status: **success**; all five required jobs, coverage, closeout
  attestation, and advisory jobs completed successfully.
- The attempt-specific collector passed. Its receipt binds job IDs, coverage
  artifact `11126724737` (`sha256:4fba56d0747ebac768deb177e39cf8c4549d760605f0c1a9c61fe2f59089d2d3`),
  closeout artifact `11128600002` (`sha256:8f86c234fd377a6eb8d456c04c026b1222bf8789f07d33fd67672a300f6eaf1b`),
  archive bytes, and the attestation member.
- Exact receipt:
  external session receipt (collected `2026-09-30T21:49:17Z`; GitHub artifact
  records expire after 7 days; local path intentionally omitted).

An earlier successful run at SHA `8874f55ef8dcafea1337b90adae478886df2a809`
confirmed the new collector joins the action's raw digest and run-page URL to
the GitHub API artifact metadata. That receipt is a regression check only and
does not replace the final candidate receipt.

## Current delivery policy snapshot

Public `main` remains at the reviewed base SHA above. The branch protection
requires strict success for `backend (required)`, `core (required)`,
`ecommerce-mounted (required)`, `package (required)`, and
`repository-contracts (required)`. No minimum approving-review count is
configured in branch protection; admin enforcement is off, force pushes and
deletions are disabled, and the rulesets endpoint returned no rulesets. No PR
exists for the candidate branch.

## Proposed PR

The external title/body proposal and exact hashes were retained outside the
repository; local temporary paths are intentionally omitted.
- Title SHA-256: `8a13a01efaaf9d16d63a2d4fd79f5058ba2388fa62a6ebbf6d68eede1c195cfd`
- Body SHA-256: `bf6bd326ae230c4bd34375d785a94dd79a583f95b468e7f538a407cb96e5262c`

The proposal describes documentation and factual evidence tooling. It does not
claim that readiness conditions were assessed, set READY, authorize operator
UI work, or claim a release or package publication.

Candidate push and exact-SHA closeout dispatch were authorized by Plan04 Task 1.
That authorization did not cover opening or merging the public PR. The separate
Task 2 checkpoint received explicit authorization for this exact candidate and
the normal protected squash merge before PR #87 was opened.

## Public delivery

- PR: [#87](https://github.com/szTheory/scrypath/pull/87), titled
  `docs: clarify adoption routes and readiness evidence`.
- Candidate head: `00f8ea1655d189c99a8eb236c2caaadf2633c169`.
- PR base at open and merge: `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`.
- PR merge ref: `3f9d1bb2a8f8f6a11ecdbd5152a592c84879275b`, checked out by the
  PR CI run. Its parents are the base SHA above and the candidate head. GitHub
  no longer advertises `refs/pull/87/merge` after merge; the full SHA and parent
  identities were recovered from the PR CI checkout log and commit API.
- Squash commit on public `main`: `87d74259a9f569c6b11c8d9481f5465a172c70ba`,
  merged by `szTheory` at `2026-10-01T00:22:42Z`. The normal squash path was
  used without an admin bypass.
- The live branch policy at merge required the five listed checks, required no
  approving review, and had no repository rulesets. The PR had no submitted
  reviews or comments; the internal review above remains attributed to the
  executing Codex agent, not to GitHub.
- PR CI run [36795390253](https://github.com/szTheory/scrypath/actions/runs/36795390253),
  attempt 1, checked out merge ref `3f9d1bb2a8f8f6a11ecdbd5152a592c84879275b`.
- Push-to-main CI run
  [36795877117](https://github.com/szTheory/scrypath/actions/runs/36795877117),
  attempt 1, completed successfully on the exact squash SHA. Required jobs:
  `backend` (110159067488), `core` (110159067697), `package`
  (110159067746), `ecommerce-mounted` (110159067803), and
  `repository-contracts` (110159067809) all succeeded. At collection time,
  public `main` still resolved to the squash SHA.
- Release Please run
  [36795877136](https://github.com/szTheory/scrypath/actions/runs/36795877136)
  completed successfully; `publish-hex` was skipped. No package publication or
  readiness decision is claimed here.

## Phase 170 Plan 05: Patch release proposal — authorized, blocked at review gate

Mutable release facts were refreshed against public GitHub and Hex on
2026-10-01 UTC. The selected Phase 168/169 fixes and Phase 170 packaged docs
have not been published yet; the concrete proposal is Release Please PR
[#83](https://github.com/szTheory/scrypath/pull/83), not a hand-created version
bump.

### Current Release Please candidate

- PR #83 is open, bot-authored, titled `chore(main): release scrypath 0.3.14`.
- Exact head: `64963c7042c451f9d4932fee7850d8bf7ca93684`; its sole parent/base is
  current public `main` at `87d74259a9f569c6b11c8d9481f5465a172c70ba`.
- The generated diff changes only `.release-please-manifest.json`,
  `mix.exs`, and `CHANGELOG.md`. All version sources agree on `0.3.14`, and
  `mix.exs` points docs/source links at `v0.3.14`.
- The generated release notes cover: ecommerce setup readiness (#82, source
  `ad73b92d5883b4136fa961e134c987a95939fac2`); tenant-scoped search/facets
  (#85, source `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`); and maintained
  dependency graph security (#84, source
  `2832e91d725d70eff9ba11d08052260ba17e2747`). The exact diff contains no
  other product changes.
- PR #87's packaged README and two updated guides are in this candidate tree.
  They are included by the current `mix.exs` package file list. Each differs
  from the corresponding file in the published 0.3.13 archive.

### Evidence that release is still warranted

- Latest GitHub release is `scrypath-v0.3.13`, published 2026-09-25 at
  `2026-09-25T01:49:22Z`. Its tag points to
  `c4cee0966d000583c2b713fbe1515f60a87ae94b`; that release commit's parent is
  `9b519571dc87da6976c7370916bccaf4a2e4016d`.
- Hex reports latest version `0.3.13` (inserted
  `2026-09-25T01:50:52.946366Z`, not retired). HexDocs resolves the 0.3.13
  route. Its published archive checksum is
  `456c165d1089d1ccd1e6a6988489a1234b2cdbddd43da6eff75b18de41978cad`.
- The 0.3.13 tarball contains the relevant search modules, but its
  `Search.FacetValues` and `Search.Many` do not drop `:tenant_scope` from
  runtime options and its Meilisearch client lacks the corrected common-filter
  rendering present at #83's source. This confirms the tenant/facet fix is not
  merely a changelog/version-label difference.
- The same published tarball's `README.md`,
  `guides/jtbd-and-user-flows.md`, and
  `guides/sync-modes-and-visibility.md` differ from the updates included in
  the current candidate. Therefore neither the selected fixes nor packaged
  Phase 170 docs are already available in 0.3.13.
- Historical release `0.3.13` did use the existing chain: Release Please run
  [36083655678](https://github.com/szTheory/scrypath/actions/runs/36083655678)
  and its `publish-hex` job succeeded through workspace cleanliness, version,
  package contract, dry run, Hex publish, live release verification, and
  source parity. Latest scheduled published-release run
  [36680015047](https://github.com/szTheory/scrypath/actions/runs/36680015047)
  also succeeded, including both latest-package and release-parity steps on
  main SHA `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`.

### Candidate gates and live merge policy

- The exact PR head was cloned to an isolated temporary checkout. With the
  release workflow's Elixir 1.19.0 / OTP 28.1 and a temporary Hex cache,
  `mix verify.package` passed: 81 tests, 0 failures; the release workflow
  contract passed and Mix built/unpacked package `scrypath-0.3.14`. The
  initial attempt using the host's read-only `~/.hex` cache was discarded; the
  successful run used a temporary cache outside the checkout and did not
  modify this repository.
- The bot-created PR CI/Website events were `action_required`. The supported
  existing `CI` workflow was dispatched at the exact candidate branch. Run
  [36797983093](https://github.com/szTheory/scrypath/actions/runs/36797983093)
  checked out head `64963c7042c451f9d4932fee7850d8bf7ca93684`; all five current
  required jobs succeeded under the expected GitHub Actions app (ID 15368):
  `backend` 110165707939, `package` 110165708136, `core` 110165708226,
  `repository-contracts` 110165708236, and `ecommerce-mounted` 110165708278.
  A fresh check-run API read at 2026-10-01 01:32 UTC confirms all required and
  advisory jobs completed successfully on the unchanged head; each check-run
  record links to PR #83.
- Live `main` policy is strict and requires those five contexts plus **one
  approving GitHub review**. No rulesets were present. PR #83 currently has no
  reviews, blank `reviewDecision`, empty PR status-check rollup, and
  `mergeStateStatus=BLOCKED`; `gh pr checks --required` reported no checks on
  the branch even though the exact-SHA dispatched check-run records are green
  and linked to the PR. The current required review is an outstanding human
  gate; no review is claimed or supplied here. Recheck review and required-check
  recognition when resuming after the review is submitted.
- No `scrypath-v0.3.14` tag exists, no 0.3.14 GitHub release exists, and Hex
  remains at 0.3.13. The public release workflow
  [36795877136](https://github.com/szTheory/scrypath/actions/runs/36795877136)
  on Plan 04's main merge succeeded with `publish-hex` skipped.

### Decision boundary

This is a coherent, package-gated patch proposal; it is not a release or a
publication. At 2026-10-01 01:32 UTC, PR #83 remained open with the exact head
and base above, no reviews, blank `reviewDecision`, empty status-check rollup,
and `mergeStateStatus=BLOCKED`. On 2026-10-01, the maintainer instructed the executor to resolve
the checkpoint automatically and follow the recommendation. This authorizes
the normal protected squash merge of the exact PR #83 candidate above and the
resulting existing Release Please / `publish-hex` chain, conditional on all
repository gates. It does not waive or supply a GitHub review.

The current live policy requires one approving GitHub review in addition to
the five successful exact-source CI checks. PR #83 has no submitted review,
`reviewDecision` is blank, and `mergeStateStatus` is `BLOCKED`. The release is
therefore **authorized but blocked before merge at the required review gate**.
Gate owner: an authorized Scrypath GitHub reviewer/maintainer who can submit an
approving review on PR #83. Resume action: submit that real review on the
unchanged head `64963c7042c451f9d4932fee7850d8bf7ca93684`. The next GSD
invocation `$gsd-execute-phase 170` continues at Plan 06 because Plan 05 now has
a committed summary; it will not replay Plan 05 automatically. Plan 06 must
refresh the release facts and return to Plan 05 for the normal protected merge
and publication steps if the review clears the gate before Plan 07 freezes the
inputs. If the head changes, re-evaluate the candidate and authorization scope
before acting.

No review was synthesized, no protection was bypassed, and no 0.3.14 tag,
GitHub release, or Hex package has been created. Publication remains blocked;
it is not deferred or published.
