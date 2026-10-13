---
phase: "177"
slug: "shared-patterns-and-delivery-proof"
status: blocked
threats_open: 1
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
| T-177-05 | Tampering | Requirement trace, review links, check-run SHA fields | high | mitigate | Verify actual hosted check and closeout evidence against the exact source; disclose any separate formal-review waiver without representing it as a review. | open — blocking |
| T-177-06 | Denial of service | Compose cleanup and retained preview | medium | mitigate | Record task-owned project/container identities; stop only those projects and preserve the 4012 preview and volumes. | open — below high threshold (non-blocking) |
| T-177-SC | Tampering | Package installation | high | mitigate | Preserve the no-dependency boundary; require package-legitimacy review and a human gate if install scope changes. | closed |

**Historical verification evidence:** A follow-up audit verified all seven unique threats closed at exact source `dd0f89ebdb21e991b3831b98ba84713d3460fb1a`. That result is superseded for current-source gating. A later audit at `1174a53f87d73c4e658029866a49c41d345452d9` reopened T-177-05 because hosted checks did not yet cover that source. The current exact-source audit is recorded below at `715179afa9530ae370701d7b6c388e13da350841`.

**T-177-01 resolution:** Corrected `DESIGN.md` to identify the shell's top-level gap as `space-y-4`, matching `layouts.ex:278–279`; the 24px token is described only for the deliberate inner grouping where it is used. The auditor confirmed the System-dark capture assertion and source/route/state/theme/viewport image metadata. This mismatch is closed.

**T-177-05 current status:** PR #98 head `83cc3dfda33a30ba38ece7e0bbfc13383c01edc7` merged as `32193307418c00cd83d14d55c208ae145ca51eb3`; the branch and merge commits have the same tree. [Run 38339367275](https://github.com/szTheory/scrypath/actions/runs/38339367275) passed all five required jobs and closeout attestation at the exact branch SHA. [Run 38340671440](https://github.com/szTheory/scrypath/actions/runs/38340671440) passed the same gates at the exact merge SHA and produced closeout artifact `11785854024`. These records close the exact-source check and final-attestation parts of the mitigation. The live PR review API returns `[]`: there is no review decision or reviewed SHA. The owner's narrow formal-review waiver is recorded as a waiver, not a review, and does not satisfy the plan's declared reviewed-source evidence. T-177-05 therefore remains open and blocking. The earlier `deep-quality` failure and skipped `ecommerce-e2e` were advisory; the current threat finding is the missing review record, not missing required checks or closeout attestation. The user-directed mounted Scrypath favicon uses the existing bundled SVG/ICO and traversal-safe static asset plug; its focused host-render/asset test passed 5/5.

**T-177-06 current status:** The Plan 177-02 cleanup record identifies project `phase177-shared-after`, its retained volume, and the cleanup command, but does not retain the stack's full container IDs. The baseline project IDs are recorded, while the after-stack IDs are absent from the contemporaneous cleanup record; current Docker inventory shows no Phase 177 resources and preserves the retained preview. The missing historical identity record remains an open medium-severity gap below the configured blocking threshold; it is not accepted as a risk.

## Accepted Risks Log

No accepted risks. The formal-review waiver is a narrow process waiver and is not an accepted technical risk or a claim of a formal review.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-12 | 7 | 5 | 2 (1 blocking, 1 non-blocking) | gsd-security-auditor |
| 2026-10-12 | 7 | 7 | 0 | gsd-security-auditor (follow-up at `dd0f89e`; historical source) |
| 2026-10-13 | 7 | 5 | 2 (1 blocking, 1 non-blocking) | gsd-security-auditor (first current-source pass at `1174a53`) |
| 2026-10-13 | 7 | 6 | 1 (0 blocking, 1 non-blocking) | gsd-security-auditor (candidate exact-source pass at `715179a`) |
| 2026-10-13 | 7 | 5 | 2 (1 blocking, 1 non-blocking) | gsd-security-auditor (source snapshot `4c0f91c`; superseded by later local commits) |

## Unregistered Flags

None in the five Phase 177 summaries' `## Threat Flags` sections.

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [ ] `threats_open: 0` confirmed — one high-severity threat remains open
- [ ] `status: verified` set in frontmatter — phase is blocked pending reviewed-source evidence for T-177-05

**Approval:** blocked — exact-source required checks and branch/merge closeout attestations now pass, but T-177-05 remains open because the live PR review API has no review decision or reviewed SHA. The owner's waiver is procedural only and is not represented as a review or accepted risk. T-177-06 remains an open medium-severity recordkeeping gap below the configured high-severity threshold; it is not accepted as a risk.

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

## Security Audit 2026-10-13

| Metric | Count |
|---|---|
| Threats found | 7 |
| Closed | 5 |
| Open | 2 |

This audit covers branch SHA `83cc3dfda33a30ba38ece7e0bbfc13383c01edc7`. Exact branch run 38339367275 and exact merge run 38340671440 both passed the five required jobs and closeout attestation; the merge run produced artifact `11785854024`. The branch and merge trees match. T-177-05 remains the sole blocking threat because the live review API returned no review decision or reviewed SHA. T-177-06 remains open below the `high` blocking threshold. No summary declared an unregistered threat flag.
