# Phase 161 Release Evidence

## Disposition

**Pending maintainer authorization and final closeout.** Phase 161 has not shipped a new release. The 0.3.12 Hex release is the current baseline only.

## Candidate

| Field | Value |
|-------|-------|
| Candidate SHA | `febcd53b96a4ca4d981f45d9902a1abcee5bc631` |
| Main SHA | `1ccf353eb6c6e315d57903166431ec63ef1a7fab` |
| Branch | `gsd/v1.37-code-quality-ratchet` |
| Exact-SHA CI | [Run 36038210399](https://github.com/szTheory/scrypath/actions/runs/36038210399) — success |
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
| Phase 161 milestone PR | No matching open or recently closed PR; current candidate branch has no PR. | No review or PR checks exist yet. | Prepare exact title/body and stop at explicit authorization checkpoint. |
| Release Please PR | No open release PR. Latest successful Release Please workflow run: [33086313543](https://github.com/szTheory/scrypath/actions/runs/33086313543) on main SHA `1ccf353eb6c6e315d57903166431ec63ef1a7fab`. | No release PR was produced by that run. | Pending future merge/tag/release event. |

`HEX_API_KEY` is present as a GitHub Actions secret name (last updated 2026-04-16); its value was not read.

## Prepared PR submission

- Proposed title: `fix: complete Phase 161 release and package-proof closeout`
- Base: `main`
- Head: `gsd/v1.37-code-quality-ratchet`
- Source SHA: `febcd53b96a4ca4d981f45d9902a1abcee5bc631`
- Body file: `/private/tmp/scrypath-161-pr-body.md` (to be written after evidence is committed and the exact current head has a fresh closeout run)
- Authorization: pending. Do not submit without the explicit `authorize-pr` answer.

## Publication and release workflow

- Current published release: `scrypath-v0.3.12` / Hex `0.3.12` (historical baseline).
- Phase 161 release version/tag: pending Release Please after reviewed merge.
- Publish workflow run, Hex result, versioned HexDocs/consumer verification, and package-to-tag parity: pending; no new release is claimed.
- External blocker: maintainer review and explicit merge/publication authorization after the prepared PR is presented.
- Resume action: authorize or withhold PR submission; if authorized, review the real PR and checks, merge under repository policy, then follow the generated Release Please tag through publish and parity gates.

## Cleanup

Pending Plan 04. Preserve the two pre-existing Phase 134/136 UAT modifications, `.planning/research/.cache/`, `.planning/state.json`, and pre-existing branch history. Record a fresh worktree, branch, service, and status inventory before any cleanup.
