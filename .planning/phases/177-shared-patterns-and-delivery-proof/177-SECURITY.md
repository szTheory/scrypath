---
phase: "177"
slug: "shared-patterns-and-delivery-proof"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-12"
---

# Phase 177 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| LiveView output → design documentation | Documentation can overstate status or component semantics if it is not derived from rendered behavior. | Rendered states, component/token semantics, screenshot metadata |
| Disposable Compose project → retained preview | A mistaken project or port identity could stop or seed the user's preserved preview. | Project, container, port, bind mount, and volume identities |
| Browser theme/viewport setup → baseline image audit | A capture could be mislabeled or render an explicit theme instead of the system preference. | Route, state, theme mode, viewport, image path, source SHA |
| Local verification → hosted PR/check evidence | Local reports, review records, and check runs may refer to different source revisions. | Full source and check-run SHAs, review decision, run URLs |
| Phase workspace → external final-source attestation | Any tracked write after attestation changes the source that it covers. | Full source SHA and immutable workflow/artifact identity |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-177-01 | Tampering | `DESIGN.md`, `DESIGN-TOKENS.md`, screenshot matrix, six-surface audit | medium | mitigate | Derive docs from source; assert System-dark capture and record each image's route/state/theme/viewport, source SHA, and path. | closed |
| T-177-02 | Tampering | Shared status/action components and token CSS | high | mitigate | Limit edits to audited findings; run Ops behavior tests and inspect changed consumers. | closed |
| T-177-03 | Tampering | Four surface-specific LiveViews and action links | high | mitigate | Preserve exact identity/action gates; run named LiveView tests and mounted proof for changed recovery handoffs. | closed |
| T-177-04 | Tampering | Search/Playbooks rendering, tests, and image evidence | high | mitigate | Preserve submitted/file identity; record matched image paths and full source SHAs. | closed |
| T-177-05 | Tampering | Requirement trace, review links, check-run SHA fields | high | accept | Exact-source hosted checks and closeout evidence passed; the project owner accepts the missing independent-review record for PR #98 as a one-time waiver, without representing it as a review. | accepted — review gap waived |
| T-177-06 | Denial of service | Compose cleanup and retained preview | medium | mitigate | Record task-owned project/container identities; stop only those projects and preserve the 4012 preview and volumes. | open — below high threshold (non-blocking) |
| T-177-SC | Tampering | Package installation | high | mitigate | Preserve the no-dependency boundary; require package-legitimacy review and a human gate if install scope changes. | closed |
| T-177-07 | Tampering | Follow-up PR review/check identities and OPUX trace | high | accept | Scope the owner's one-time waiver to PR #101; preserve the empty review API and exact check/head identities, and never represent owner authorization as independent approval. | accepted — PR #101 only |
| T-177-08 | Repudiation | Pre-transition and terminal closeout identities | high | mitigate | Keep Stage A explicitly provisional; require a second exact-SHA closeout after verification, phase completion, and the full post-completion transition, with no later tracked writes. | mitigated by enforced two-stage gate; Stage B pending |

**Historical verification evidence:** A follow-up audit verified all seven unique threats closed at exact source `dd0f89ebdb21e991b3831b98ba84713d3460fb1a`. That result is superseded for current-source gating. A later audit at `1174a53f87d73c4e658029866a49c41d345452d9` reopened T-177-05 because hosted checks did not yet cover that source. The current exact-source audit is recorded below at `715179afa9530ae370701d7b6c388e13da350841`.

**T-177-01 resolution:** Corrected `DESIGN.md` to identify the shell's top-level gap as `space-y-4`, matching `layouts.ex:278–279`; the 24px token is described only for the deliberate inner grouping where it is used. The auditor confirmed the System-dark capture assertion and source/route/state/theme/viewport image metadata. This mismatch is closed.

**T-177-05 current status:** PR #98 head `83cc3dfda33a30ba38ece7e0bbfc13383c01edc7` merged as `32193307418c00cd83d14d55c208ae145ca51eb3`; the branch and merge commits have the same tree. [Run 38339367275](https://github.com/szTheory/scrypath/actions/runs/38339367275) passed all five required jobs and closeout attestation at the exact branch SHA. [Run 38340671440](https://github.com/szTheory/scrypath/actions/runs/38340671440) passed the same gates at the exact merge SHA and produced closeout artifact `11785854024`. These records verify the exact-source checks and final-source attestation for the merged implementation. The live PR review API returned `[]`: there is no independent review decision or reviewed SHA. Per the project owner's explicit direction on 2026-10-13 to use the prior merge approval as a waiver and unblock the phase, this one-time review-evidence gap is accepted as a process risk. No independent review is claimed, and this waiver does not apply to future changes. `deep-quality (advisory)` and `ecommerce-e2e (advisory)` failed on those runs; the five required jobs and closeout attestation passed. The user-directed mounted Scrypath favicon uses the existing bundled SVG/ICO and traversal-safe static asset plug; its focused host-render/asset test passed 5/5.

**T-177-06 current status:** The Plan 177-02 cleanup record identifies project `phase177-shared-after`, its retained volume, and the cleanup command, but does not retain the stack's full container IDs. The baseline project IDs are recorded, while the after-stack IDs are absent from the contemporaneous cleanup record; current Docker inventory shows no Phase 177 resources and preserves the retained preview. The missing historical identity record remains an open medium-severity gap below the configured blocking threshold; it is not accepted as a risk.

## Accepted Risks Log

| Risk ID | Scope | Accepted by | Basis and limits |
|---|---|---|---|
| AR-177-01 | Missing independent formal-review decision and reviewed SHA for PR #98 (T-177-05) | Project owner, 2026-10-13 | The owner directed that prior merge approval serve as a one-time waiver and asked to unblock the phase. Exact branch and merge required checks and closeout attestations passed. No independent review is claimed. Future changes still require their applicable review gate. |
| AR-177-02 | Missing independent formal-review decision for PR #101 (T-177-07) | Project owner, 2026-10-13 | The owner authorized marking PR #101 ready and squash-merging if required CI was green. All five required jobs passed at exact head `431d2d3265ae0d77c565baf169ed95ba018f0d16`; the review API returned no reviews. This waiver applies only to PR #101; no independent review is claimed. |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-12 | 7 | 5 | 2 (1 blocking, 1 non-blocking) | gsd-security-auditor |
| 2026-10-12 | 7 | 7 | 0 | gsd-security-auditor (follow-up at `dd0f89e`; historical source) |
| 2026-10-13 | 7 | 5 | 2 (1 blocking, 1 non-blocking) | gsd-security-auditor (first current-source pass at `1174a53`) |
| 2026-10-13 | 7 | 6 | 1 (0 blocking, 1 non-blocking) | gsd-security-auditor (candidate exact-source pass at `715179a`) |
| 2026-10-13 | 7 | 5 | 2 (1 blocking, 1 non-blocking) | gsd-security-auditor (source snapshot `4c0f91c`; superseded by later local commits) |
| 2026-10-13 | 7 | 6 | 1 (0 blocking, 1 non-blocking) | gsd-security-auditor; T-177-05 accepted by project-owner waiver, T-177-06 remains below threshold |

## Unregistered Flags

None in the five Phase 177 summaries' `## Threat Flags` sections.

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed — no blocking threats remain; T-177-06 stays open below threshold
- [x] `status: verified` set in frontmatter — the narrowly scoped T-177-05 review-evidence gap is accepted

**Approval:** verified with one accepted process risk. T-177-05's exact-source checks and branch/merge closeout attestations passed; the owner accepted only the missing independent-review evidence as a one-time waiver. No review is claimed. T-177-06 remains an open medium-severity recordkeeping gap below the configured high-severity threshold and is not accepted as a risk.

## Security Audit 2026-10-12

| Metric | Count |
|---|---|
| Threats found | 7 |
| Closed | 7 |
| Open | 0 |

## Security Audit 2026-10-13 — first current-source pass at `1174a53`

| Metric | Count |
|---|---|
| Threats found | 7 |
| Closed | 5 |
| Open | 2 |

## Security Audit 2026-10-13 — candidate exact source `715179afa9530ae370701d7b6c388e13da350841` (superseded for current-HEAD gating)

| Metric | Count |
|---|---|
| Threats found | 7 |
| Closed | 6 |
| Open | 1 (0 blocking, 1 below threshold) |

At candidate SHA `715179afa9530ae370701d7b6c388e13da350841`, T-177-05 was closed by the exact-HEAD PR checks and closeout attestation linked above. This result does not cover current HEAD `4c0f91c66934345b7393f0937c87c60b1600d597`; terminal merged-source attestation remains pending. T-177-06 remains open because the after-stack container IDs were not retained in the contemporaneous cleanup record; the current Docker inventory shows the retained preview and no Phase 177 resources. This is a medium recordkeeping gap, is not accepted, and is below `block_on: high`. The exact-source run's `deep-quality` and `ecommerce-e2e` advisory jobs failed; both are outside the required gate and remain disclosed. No unregistered threat flags were found.

## Historical Security Audit — 2026-10-13 at `4c0f91c66934345b7393f0937c87c60b1600d597`

| Metric | Count |
|---|---|
| Threats found | 7 |
| Closed | 5 |
| Open | 2 (1 blocking, 1 below threshold) |

This audit snapshot predates the favicon and Phase 174 closeout commits and is not a current-source security verdict. At that snapshot, `T-177-01` was closed because `DESIGN.md:21` matched the 16px `space-y-4` shell spacing, while T-177-05 remained open for missing hosted checks and terminal attestation. T-177-06 remains open below threshold because the after-stack container IDs were not retained. No unregistered threat flags were found.

## Security Audit 2026-10-13 — branch and merge source review

| Metric | Count |
|---|---|
| Threats found | 7 |
| Closed | 5 |
| Open | 2 |

This audit covers branch SHA `83cc3dfda33a30ba38ece7e0bbfc13383c01edc7` and merge SHA `32193307418c00cd83d14d55c208ae145ca51eb3`; their trees match. Exact branch run 38339367275 and exact merge run 38340671440 passed the five required jobs and closeout attestation; the merge run produced artifact `11785854024`. The review API returned no independent review decision or reviewed SHA. The project owner accepted that narrowly scoped review-evidence gap as a one-time waiver; no review is claimed. T-177-06 remains open below the `high` blocking threshold. No summary declared an unregistered threat flag.

## Security Audit 2026-10-13

| Metric | Count |
|---|---|
| Threats found | 7 |
| Closed | 6 |
| Open | 1 |

T-177-05 is accepted only for the missing independent-review record, as documented in AR-177-01. Exact branch and merge required checks and closeout attestations passed. T-177-06 is the only remaining open threat and is medium severity, below the configured high blocking threshold. The latest `main` exact-SHA run, [38395852546](https://github.com/szTheory/scrypath/actions/runs/38395852546) at `017c7389544291b30146d25b73239ed33296d7b7`, also passed the five required jobs, coverage, and closeout attestation (artifact `11812741735`); `deep-quality` and `ecommerce-e2e` advisory jobs failed. This later `main` run is supplemental repository evidence, not a substitute for PR review. No independent review is claimed, and no summary declared an unregistered threat flag.

## Current-source Security Audit — 2026-10-13, PR #101 closeout

Plan 177-06 adds T-177-07 and T-177-08 to the existing register. T-177-07 is accepted under AR-177-02 only for PR #101: the five required jobs passed at candidate head `431d2d3265ae0d77c565baf169ed95ba018f0d16`, the review API was empty, and the owner authorized the conditional squash merge. No independent review is claimed.

Stage A run [38427260705](https://github.com/szTheory/scrypath/actions/runs/38427260705) is explicitly provisional at `05e8eea34feb985ce5112f3a4c0abb420b77bc39`. The five required jobs, coverage, and `closeout-attestation` succeeded at that SHA. Coverage artifact `11829386332` has digest `sha256:87083b515e351d6a2d7809b048fa27bb0b27d1545ca4d71cb2f160c3c10c4427`; closeout artifact `11829895992` has digest `sha256:ec4802eb9ec4f0a2ea076d168f9f1ab6e50360a0f1fc8494b96f78a9e60c2fc5`. At capture, the overall workflow was still running because `ecommerce-e2e (advisory)` had not completed; `deep-quality (advisory)` failed. The exact jobs and artifacts are preserved in `/private/tmp/phase177-stage-a-provisional-05e8eea34feb985ce5112f3a4c0abb420b77bc39.json`. This run is not terminal evidence.

T-177-08 is mitigated by the enforced sequence, not by the provisional artifact: Stage B remains a required post-transition gate and cannot be described as complete until its own exact-SHA jobs and immutable receipt pass. T-177-06 remains the only open threat; its medium-severity historical container-ID gap is below the configured high blocking threshold and remains unaccepted. Current register: 9 unique threats, 8 closed or explicitly accepted, 1 open below threshold, 0 blocking. The `threats_open: 0` frontmatter therefore remains the blocking-threat count.

## Security Audit 2026-10-13

| Metric | Count |
|---|---|
| Threats found | 9 |
| Closed | 8 |
| Open | 1 |
