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
| T-177-01 | Tampering | `DESIGN.md`, `DESIGN-TOKENS.md`, screenshot matrix, six-surface audit | medium | mitigate | Derive docs from source; assert System-dark capture and record each image's route/state/theme/viewport, source SHA, and path. | open — below high threshold (non-blocking) |
| T-177-02 | Tampering | Shared status/action components and token CSS | high | mitigate | Limit edits to audited findings; run Ops behavior tests and inspect changed consumers. | closed |
| T-177-03 | Tampering | Four surface-specific LiveViews and action links | high | mitigate | Preserve exact identity/action gates; run named LiveView tests and mounted proof for changed recovery handoffs. | closed |
| T-177-04 | Tampering | Search/Playbooks rendering, tests, and image evidence | high | mitigate | Preserve submitted/file identity; record matched image paths and full source SHAs. | closed |
| T-177-05 | Tampering | Requirement trace, review links, check-run SHA fields | high | mitigate | Verify actual hosted review/check evidence against the exact source; unresolved records block OPUX-28 completion. | open |
| T-177-06 | Denial of service | Compose cleanup and retained preview | medium | mitigate | Record task-owned project/container identities; stop only those projects and preserve the 4012 preview and volumes. | closed |
| T-177-SC | Tampering | Package installation | high | mitigate | Preserve the no-dependency boundary; require package-legitimacy review and a human gate if install scope changes. | closed |

**Verification evidence:** The security auditor found T-177-02 through T-177-04, T-177-06, and T-177-SC closed. Evidence is recorded in the auditor result: CSS diff and contract tests; existing identity/action assertions and focused suites; the Search/Playbooks identity assertions and source-bounded image inventory; the cleanup ledger and retained preview inventory; and no package manifest or lockfile changes.

**T-177-01 finding:** `DESIGN.md:21` described the shell's top-level gap as the 24px `space-y-ops-page-gap`; `layouts.ex:278–279` uses `space-y-4`, as `DESIGN-TOKENS.md:99` states. System-dark capture and image metadata requirements were otherwise present. This medium-severity documentation mismatch is non-blocking and will be corrected before re-audit.

**T-177-05 finding:** PR #98 required checks passed on exact head `39e6a44c4a16084ec0738de5ea29a5e61b18b842`, while its formal review list is empty and `closeout-attestation` is skipped on PR runs. The user-approved prior merge authorization waives only the formal-review gate; it is not a review record. The final exact-source closeout attestation has not run, so this threat remains blocking. `177-05-SUMMARY.md` and `REQUIREMENTS.md` currently mark OPUX-28 complete prematurely and must be corrected until the terminal attestation succeeds.

## Accepted Risks Log

No accepted risks. The formal-review waiver is a narrow process waiver and is not an accepted technical risk or a claim of a formal review.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-12 | 7 | 5 | 2 (1 blocking, 1 non-blocking) | gsd-security-auditor |

## Unregistered Flags

None in the five Phase 177 summaries' `## Threat Flags` sections.

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [ ] `threats_open: 0` confirmed
- [ ] `status: verified` set in frontmatter

**Approval:** blocked — 1 high-severity threat remains open.
