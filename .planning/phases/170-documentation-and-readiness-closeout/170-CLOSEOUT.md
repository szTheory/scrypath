# Phase 170 Closeout Freeze Contract

## Boundary

This file fixes the exact planning snapshot that Plan 08 may attest. The external freeze manifest supplies final byte digests and Git blob IDs after every listed original file has been committed. This file contains no snapshot digest, manifest checksum, final source SHA, or machine-specific absolute path.

The final evidence ref is based on refreshed public `main` and carries only this allowlisted planning snapshot. The old source commit for the 15 preserved-history entries is unavailable from GitHub, eleven of those historical files are absent from public `main`, and three Phase 168/169 tracked inputs are also absent from public `main`. The evidence branch therefore first commits the exact bytes of all 15 preserved-history files as an allowlist-only source anchor, then commits the remaining frozen snapshot with every history pin pointed at that reachable anchor. Both commits are rooted at refreshed public `main` and change only allowlisted paths. The final identity and all source fingerprints live in `SCRYPATH_PHASE170_TMP/freeze-manifest.json`. After the manifest is finalized, Plan 08 and the orchestrator must not write tracked files, create a summary, update state or roadmap, run an archive/retrospective transformation, or make a success-recording commit.

## Exact Snapshot Allowlist

The following 52 unique repository-relative paths are the complete snapshot. The list is the union of Plan 06 and Plan 07 `files_modified`, Plans 01–08, Summaries 01–05, the named Phase 170 context/research/pattern/delivery inputs, the three milestone evidence inputs, all eleven byte-pinned Phase 164 source files, three Phase 168/169 delivery receipts required by the readiness validator, and the learning extraction plus its estimate calibration output.

### Plan 06 and Plan 07 tracked outputs

- `.planning/estimation-calibration.json`
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-06-SUMMARY.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-07-SUMMARY.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-08-SUMMARY.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-LEARNINGS.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-CLOSEOUT.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-READINESS-INPUTS.json`
- `.planning/phases/170-documentation-and-readiness-closeout/170-REVIEW.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-SECURITY.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-VALIDATION.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-VERIFICATION.md`
- `.planning/reference/MILESTONE-ARC.md`
- `.planning/reference/PRE-OPERATOR-UI-READINESS.md`
- `.planning/reference/milestone-candidates.md`

### Phase 170 plans

- `.planning/phases/170-documentation-and-readiness-closeout/170-01-PLAN.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-02-PLAN.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-03-PLAN.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-04-PLAN.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-05-PLAN.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-06-PLAN.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-07-PLAN.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-08-PLAN.md`

### Earlier Phase 170 summaries

- `.planning/phases/170-documentation-and-readiness-closeout/170-01-SUMMARY.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-02-SUMMARY.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-03-SUMMARY.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-04-SUMMARY.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-05-SUMMARY.md`

### Phase 170 context and delivery inputs

- `.planning/phases/170-documentation-and-readiness-closeout/170-CONTEXT.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-DELIVERY.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-PATTERNS.md`
- `.planning/phases/170-documentation-and-readiness-closeout/170-RESEARCH.md`

### Preserved historical inputs

- `.planning/milestones/v1.39-phases/162-whole-product-evidence-baseline/162-BASELINE.md`
- `.planning/milestones/v1.39-phases/163-findings-and-bounded-follow-up/163-FINDINGS.md`
- `.planning/milestones/v1.40-phases/167-dated-readiness-and-closeout/167-ASSESSMENT.md`

### Phase 164 history pins

- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-01-PLAN.md`
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-01-SUMMARY.md`
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-CONTEXT.md`
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-DISCUSSION-LOG.md`
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-PATTERNS.md`
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-RESEARCH.md`
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-REVIEW.md`
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-VALIDATION.md`
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-VERIFICATION.md`
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/check_readiness.py`
- `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/test_check_readiness.py`

### Prior-phase delivery inputs

- `.planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md`
- `.planning/phases/169-library-fix-delivery-and-pr-triage/169-04-SUMMARY.md`
- `.planning/phases/169-library-fix-delivery-and-pr-triage/169-05-SUMMARY.md`

## Cleanup and Ownership Dispositions

| Surface | Disposition | Evidence and limit |
|---|---|---|
| PR #87 Phase 170 delivery worktree and local branch | Removed | PR #87 is merged; its worktree was clean and its tree matched refreshed public `main`. The delivery and merge receipts remain in the tracked Phase 170 delivery record. The remote branch was already absent. |
| PR #83 Release Please candidate | Retained, blocked | It remains the authorized 0.3.14 release path. The exact candidate is open, has no approving review, and must stay available for the real protected review gate. No merge, tag, GitHub Release, or Hex publication is claimed. |
| Final evidence checkout | Retained | The clean evidence ref is based on refreshed public `main` and is held for exact-source attestation and durable source links. It is not a second delivery PR or package. |
| Unrelated maintainer changes and research cache | Preserved | The pre-existing deleted debug note, Phase 160 UAT edit, ecommerce startup edit, Phase 147 test edit, resolved debug material, and research cache remain outside the snapshot and untouched. Their byte/status fingerprints are external. |
| Pre-existing services and processes | Preserved | No service was started, stopped, or cleaned by Phase 170 Plan 07. The pre-execution inventory and final comparison are external. |
| Temporary receipts | Retain with a bound | Keep the freeze manifest, pre-freeze baseline, exact-source receipt, terminal record, and publication readback until 30 days after issue #86's terminal comment is verified; then remove them. Delete other scratch output after its validation is recorded. |
| Milestone archive, tag, and retrospective | Outside this attested scope | No later archive/tag/retrospective write is promised after terminal success. Any such transformation needs a separate scope decision before it is included in a future frozen source. |

## External Digest Protocol

After all tracked originals and the final evidence checkout are committed, `freeze-manifest.json` outside both checkouts must contain one unique row per allowlisted path with its repository-relative path, SHA-256 of final whole-file bytes, and Git blob ID. It must include this file and the phase summaries and learning record, but it must not hash itself. It also records both checkouts' HEAD, index, and tracked-status fingerprints; preserved unrelated-state fingerprints; issue identity; release receipts; and cleanup dispositions. Private absolute paths and pre-redaction digests belong only in that external manifest. Seven local-path references in unpinned Phase 168/169 delivery inputs were normalized to generic external-storage descriptions without altering evidence hashes or findings. The three pinned historical references were redacted by maintainer direction, their affected pins were refreshed, and every preserved-history entry now points to a clean-main-rooted source anchor containing the exact sanitized bytes. Before push or hosted attestation, verify the complete snapshot scan is clear and every history pin resolves from the anchor.

Verify the transported snapshot against the frozen original bytes, verify that every non-`.planning` path matches refreshed public `main`, and capture final checkout fingerprints only after the snapshot is stable. Keep all seven inherited edge probes and four Phase 170 prohibitions unresolved unless real evidence supports a recorded resolution. The mechanical freeze is not a semantic readiness decision.

## No-Write Handoff

The tracked Phase 170 state remains pending until the actual maintainer supplies six judgments and Plan 08 validates the exact-source receipt. Issue [#86](https://github.com/szTheory/scrypath/issues/86) is the sole terminal decision authority. A NOT READY decision is valid and must include blockers and revisit triggers; READY requires six PASS judgments. Publication requires approval of the exact rendered record. After freeze, corrections are separately dated issue comments, never edits or commits to this snapshot.
