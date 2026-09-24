---
phase: 161-release-and-tidy-closeout
verified: 2026-09-24T20:44:00Z
status: gaps_found
score: 14/17 must-haves verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
  - .planning/STATE.md
  - .planning/phases/161-release-and-tidy-closeout/161-01-PLAN.md
  - .planning/phases/161-release-and-tidy-closeout/161-01-SUMMARY.md
  - .planning/phases/161-release-and-tidy-closeout/161-02-PLAN.md
  - .planning/phases/161-release-and-tidy-closeout/161-02-SUMMARY.md
  - .planning/phases/161-release-and-tidy-closeout/161-03-PLAN.md
  - .planning/phases/161-release-and-tidy-closeout/161-03-SUMMARY.md
  - .planning/phases/161-release-and-tidy-closeout/161-04-PLAN.md
  - .planning/phases/161-release-and-tidy-closeout/161-04-SUMMARY.md
  - .planning/phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md
  - .planning/phases/161-release-and-tidy-closeout/161-VALIDATION.md
  - CONTRIBUTING.md
  - docs/releasing.md
  - examples/phoenix_meilisearch/README.md
  - lib/mix/tasks/verify/phoenix_example/package.ex
  - mix.lock
  - test/scrypath/docs_contract_test.exs
covered_digest: "v1:sha256:0bef08e3292ce4480bddc19cf82a1c60b7e7beffdae24012ebf6d414e48b51ea"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The final committed closeout has successful exact-SHA CI and digest-bearing closeout artifacts for the current HEAD."
    status: failed
    reason: "The latest exact-SHA workflow_dispatch receipt is for 3e895a6bf78edca487b17b8ffcc431b955bc4e8f, while the checked-out HEAD is 18d63fd17249e7a576209f6beadfd15310a79768. Four commits follow the attested SHA; the plan requires fresh closeout after later tracked edits."
    artifacts:
      - path: .planning/phases/161-release-and-tidy-closeout/161-VALIDATION.md
        issue: "The final-SHA receipt is absent and there is no digest-bearing receipt for current HEAD."
      - path: .planning/phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md
        issue: "The claimed external final receipt is unavailable and its exact SHA is not recorded."
    missing:
      - "Run the existing closeout workflow on current HEAD and retain its run URL, required-job results, and immutable artifact digests."
      - "Update validation/release evidence to name that SHA and receipt, then ensure no tracked edits follow."
---

# Phase 161: Release and Tidy Closeout Verification Report

**Phase Goal:** Adopters and maintainers can understand package-backed proof scope, and the milestone closes with verified release evidence or an explicit release-ready disposition and tidy repository state.  
**Verified:** 2026-09-24T20:44:00Z  
**Status:** gaps_found  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Documentation states tested flows, command, real-service prerequisites, synthetic proof limits, and contracts guard drift. | ✓ VERIFIED | Inspected README, CONTRIBUTING, release docs, and docs contract. They name inline, Oban, both related-data scenarios, required env/services, and limits. Hosted run 36048572240 also passed package and repository-contracts at its SHA. |
| 2 | Canonical docs/examples match executable behavior; no stale v1.38 claims or owned debris remain. | ✓ VERIFIED | Inspected docs and evidence; ownership record lists removed temporary/generated resources and preserved unrelated changes. No debt markers/stubs in implementation files. |
| 3 | PRs are triaged, exact-final-SHA checks pass, and publication or explicit release-ready blocker is recorded. | ✗ FAILED | PR #77 is open/unreviewed; blocker and resume action are specific. Exact closeout is stale for current HEAD, so this criterion is incomplete. |
| 4 | Owned resources are cleaned and unrelated changes preserved/reported. | ✓ VERIFIED | Release evidence inventories cleanup and preserved dirt; current status retains the named unrelated UAT edits, Phase 160 verification edit, research cache, and state.json. |
| 5 | Adopter runbook contains exact command, service setup, and scenario classes. | ✓ VERIFIED | README names package/path commands, `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, `SCRYPATH_MEILISEARCH_URL`, reachable Postgres/Meilisearch, and four scenario classes. |
| 6 | Maintainer docs distinguish advisory/live proof and pre-/post-publish evidence. | ✓ VERIFIED | CONTRIBUTING and `docs/releasing.md` link to the runbook and distinguish `verify.package`/docs contracts from `verify.release_publish` and `verify.release_parity`. |
| 7 | Docs contracts detect drift in claims and CI order. | ✓ VERIFIED | Assertions in `test/scrypath/docs_contract_test.exs` cover commands, prerequisites, scenarios, evidence boundaries, and CI sequence. Candidate hosted package/repository-contract jobs passed. |
| 8 | Lock graph resolves Mint >=1.10.1 and clears the named advisories. | ✓ VERIFIED | Inspected Mint 1.10.1/hpax 1.1.0 lock entries; phase audit evidence clears EEF-CVE-2026-82672, EEF-CVE-2026-82729, EEF-CVE-2026-82728. |
| 9 | Dependency change is minimal with no runtime/public API expansion. | ✓ VERIFIED | Plan 02 records Mint/hpax lock changes and a `no_return()` typespec; source/lock inspected. |
| 10 | Package and deep-quality gates pass on the remediated graph. | ✓ VERIFIED | Summary records local passes; run 36048572240 at 3e895a6 passed package and deep-quality. |
| 11 | PR/release inventory records review, checks, merge state, and empty release PR result. | ✓ VERIFIED | Queried GitHub: PR #77 open, clean merge state, no review decision; evidence records no open Release Please PR. `main` remains 1ccf353e. |
| 12 | Candidate commit has five required checks and SHA-bound closeout artifacts. | ✗ FAILED | Exact run 36048572240 and all five required jobs/attestation passed for 3e895a6, but current HEAD is 18d63fd and has no receipt. |
| 13 | “Shipped” requires post-publish checks; release-ready has a concrete blocker/resume action. | ✓ VERIFIED | Release record says unpublished/release-ready and specifies review, merge, Release Please, publish, and parity sequence. GitHub confirms PR remains open. |
| 14 | Only owned resources are removed; unrelated work remains. | ✓ VERIFIED | Ownership inventory and current worktree status agree; later Phase 160 verification edit is also preserved. |
| 15 | Final disposition is shipped only with publication parity and green main; otherwise release-ready. | ✓ VERIFIED | No shipped claim; explicit pending external release gates. |
| 16 | Final committed artifacts have fresh exact-SHA closeout; later tracked edits trigger another run. | ✗ FAILED | Four commits follow attested SHA 3e895a6. No run for current HEAD 18d63fd. |
| 17 | Missing milestone PR was prepared and submitted only after explicit maintainer authorization. | ✓ VERIFIED | PR #77 has the recorded conventional title and expected scope; phase summary/evidence record explicit maintainer authorization before creation and the PR URL/source SHA. |

**Score:** 14/17 truths verified (0 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `examples/phoenix_meilisearch/README.md` | Canonical runbook | ✓ VERIFIED | Substantive, commands/prerequisites/scenarios present. |
| `CONTRIBUTING.md` | Maintainer entry point | ✓ VERIFIED | Links runbook and states evidence boundary. |
| `docs/releasing.md` | Release evidence boundary | ✓ VERIFIED | Separates pre-publish and post-publish checks. |
| `test/scrypath/docs_contract_test.exs` | Executable docs contract | ✓ VERIFIED | Assertions cover claims and wiring/order. |
| `mix.lock` | Fixed Mint graph | ✓ VERIFIED | Mint 1.10.1, hpax 1.1.0. |
| `161-VALIDATION.md` | Candidate/final SHA and receipts | ⚠️ PARTIAL | Candidate receipt valid for 3e895a6; no receipt for current HEAD. |
| `161-RELEASE-EVIDENCE.md` | PR/cleanup/disposition record | ⚠️ PARTIAL | Specific disposition exists; final SHA receipt missing. |
| `lib/mix/tasks/verify/phoenix_example/package.ex` | Package proof implementation | ✓ VERIFIED | Non-stub implementation; hosted package gate passed on candidate. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Runbook | Docs contract | Assertions | WIRED | Test reads canonical docs and checks relevant claims. |
| CONTRIBUTING | Runbook | Markdown link | WIRED | Direct link exists. |
| Candidate SHA | GitHub CI | Exact SHA/jobs/artifacts | PARTIAL | 36048572240 matches 3e895a6, not local HEAD 18d63fd. |
| Release tag | Hex/HexDocs | Publish, release_publish, parity | WIRED / pending | Documented workflow; no Phase 161 tag because PR is unmerged. |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Real data | Status |
|---|---|---|---|---|
| Docs contracts | File/workflow contents | Repository files | Yes | FLOWING |
| Release evidence | SHA/run/artifact fields | GitHub | Yes for 3e895a6, absent for current HEAD | PARTIAL |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Current HEAD has final closeout evidence | `gh run list --workflow ci.yml --branch gsd/v1.37-code-quality-ratchet --limit 8 --json databaseId,headSha,event,status,conclusion,url,createdAt` | Latest successful dispatch 36048572240 is for 3e895a6; local HEAD is 18d63fd | ✗ FAIL |
| Attested SHA has required jobs and attestation | `gh run view 36048572240 --json headSha,jobs` | Five required jobs and closeout-attestation succeeded at 3e895a6 | ✓ PASS for that SHA |

## Probe Execution

No phase-declared shell probes were found. This phase's checks are docs contracts, dependency gates, and hosted exact-SHA closeout.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| DOC-01 | 161-01 | Accurate proof documentation and synthetic evidence limits | ✓ SATISFIED | Runbook, maintainer docs, contract assertions inspected. |
| HYGIENE-01 | 161-01, 161-04 | Self-documenting changes and ownership-scoped cleanup | ✓ SATISFIED | Docs align with executable behavior; cleanup and preservation record corroborated. |
| REL-01 | 161-02, 161-03, 161-04 | Exact final checks and published release verification before shipped claim | ✗ BLOCKED | Candidate gates pass, but current HEAD has no exact-SHA receipt; PR remains unmerged. |
| CLOSE-01 | 161-03, 161-04 | Clean owned resources, preserve unrelated work, release-ready blocker/action | ✓ SATISFIED | Blocker/action and cleanup inventory are specific and current. |

Every requirement ID from PLAN frontmatter is accounted for; no additional Phase 161 requirement is orphaned in REQUIREMENTS.md.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | None confirmed | — | Raw `TBD` grep matches `JTBD` prose only; no actual debt markers or stubs found. |

## Human Verification Required

No user-facing UAT is required. The outstanding maintainer review/merge remains an external release gate. The missing current-SHA receipt is a verification gap.

## Gaps Summary

Docs, Mint remediation, candidate checks, and cleanup are substantively supported. However, the latest exact-SHA closeout is for `3e895a6bf78edca487b17b8ffcc431b955bc4e8f`; current HEAD is `18d63fd17249e7a576209f6beadfd15310a79768`. Four commits follow the attested SHA, and `/private/tmp/scrypath-161-final-closeout.json` is absent. Re-run the existing closeout on current HEAD, record the run and immutable artifact digests, then make no tracked edits. PR #77 remains open without a review; after exact-head checks, a maintainer must review and merge it and follow Release Please through Hex, HexDocs, and parity. Do not report the milestone as shipped.

---

_Verified: 2026-09-24T20:44:00Z_  
_Verifier: the agent (gsd-verifier)_
