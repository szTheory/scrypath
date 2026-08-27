---
phase: 159
slug: close-v1-37-audit-gaps-coverage-wiring-and-verification-prov
status: verified
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: 2026-08-27
---

# Phase 159 — Security

> ASVS L1 verification of the plan-authored STRIDE register for the v1.37
> evidence, CI, and exact-SHA closeout boundary.

## Trust Boundaries

| Boundary | Description | Data crossing |
|---|---|---|
| GitHub event → workflow job | Event context selects scheduled/manual advisory and exact-SHA closeout execution. | Repository ref, event name, workflow inputs |
| Repository workflow → third-party action | GitHub-hosted runners execute externally maintained actions. | Source tree, cache keys, generated artifacts |
| Coverage producer → retained artifact | Generated HTML enters short-lived hosted storage independently of upload cleanup. | Public-source coverage report |
| Local evidence commit → hosted run | Remote execution must use the intended immutable source and workflow revision. | Commit SHA, workflow SHA, job conclusions |
| Hosted run → closure verdict | A retained artifact alone cannot establish producer or required-job success. | Run identity, job results, artifact digests |
| Historical Git topology → evidence claims | Present-state tests cannot manufacture earlier characterization chronology. | Parent SHAs, focused results, bounded waivers |
| Canonical matrix → retrospective artifacts | Summaries must preserve requirement ownership, evidence class, and limitations. | Requirement IDs and provenance links |
| Dirty checkout → detached historical worktree | User-owned changes must not enter old-revision probes. | Resolved SHAs and focused test inputs |
| Workflow source → executable guard | Broad string matching must not satisfy step-local security and provenance contracts. | Parsed checkout/upload/job definitions |

## Threat Register

Duplicate numeric IDs below are qualified by their originating plan because
Plans 03–06 reused identifiers for distinct threats. No threat is dropped or
silently merged.

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
|---|---|---|---|---|---|---|
| T-159-01 | Elevation of Privilege / Information Disclosure | CI permissions and secrets | high | mitigate | `ci.yml` defaults to `contents: read`; repository contracts reject broadened permissions and secrets. | closed |
| T-159-02 | Tampering | Action references | high | mitigate | Executable action refs are immutable full SHAs; actionlint and repository contracts pass. | closed |
| T-159-03 | Repudiation / Tampering | Coverage artifact | medium | mitigate | Artifact name is source-SHA-bound, retention is seven days, and producer success is checked separately from upload success. | closed |
| T-159-04 | Denial of Service | Coverage event topology | low | accept | Coverage remains limited to the existing schedule and explicit dispatch, outside push/PR required lanes. | closed |
| T-159-SC | Tampering | Package-manager installs | high | mitigate | Phase 159 added no package-manager install task or dependency; package-legitimacy boundary was not entered. | closed |
| T-159-05 | Tampering | Detached worktrees / primary checkout | high | mitigate | Historical probes used resolved SHAs, unique temporary roots, registered-worktree checks, explicit cleanup, and before/after status preservation. | closed |
| T-159-06 | Repudiation | Historical chronology claims | high | mitigate | `historically proven` requires parent test presence and passing parent execution; four ambiguous TEST-01 probes fail closed under the bounded waiver. | closed |
| T-159-07 | Tampering / Repudiation | Canonical evidence matrix | high | mitigate | The 31-ID set and original ownership were mechanically reconciled with one bounded evidence class per row and zero orphaned IDs. | closed |
| T-159-08 | Denial of Service | Git history probes | medium | mitigate | Probes use a finite extraction candidate list and focused commands rather than unbounded history or suite scans. | closed |
| T-159-09 | Information Disclosure | Recorded commands/output | medium | mitigate | Receipts retain versions, exits, hashes, and bounded diagnostics without credentials, environment secrets, or raw logs. | closed |
| T-159-10/P03 | Repudiation | Retrospective summaries | high | mitigate | Phase 148–151 summaries carry non-contemporaneous disclaimers and canonical evidence links. | closed |
| T-159-11 | Tampering / Repudiation | TEST-01 verification | high | mitigate | Classifications come from exact-parent probes; only the four canonical historically-unprovable predicates are waived. | closed |
| T-159-12/P03 | Information Disclosure | Command receipts | medium | mitigate | Retrospective receipts contain bounded facts and versions, not raw logs, credentials, or environment secrets. | closed |
| T-159-10/P04 | Repudiation | Retrospective summaries | high | mitigate | Phase 152–155 summaries carry non-contemporaneous disclaimers and canonical evidence links. | closed |
| T-159-13/P04 | Tampering / Repudiation | CI topology evidence | high | mitigate | Phase 155 claims were reconciled with current workflow source and immutable receipts while preserving required/advisory/path-scoped classifications. | closed |
| T-159-14/P04 | Information Disclosure | Command receipts | medium | mitigate | Evidence records bounded outcomes without raw logs, credentials, or secrets. | closed |
| T-159-10/P05 | Repudiation | Retrospective summaries | high | mitigate | Phase 156–158 summaries carry non-contemporaneous disclaimers and canonical evidence links. | closed |
| T-159-13/P05 | Tampering / Repudiation | Workflow/release evidence | high | mitigate | Claims are tied to immutable receipts and current workflow source; no Hex publish or release-parity reopening occurred. | closed |
| T-159-14/P05 | Information Disclosure | Command receipts | medium | mitigate | Evidence records bounded outcomes without raw logs, credentials, or secrets. | closed |
| T-159-12/P06 | Repudiation | Per-phase validation | high | mitigate | Every validation consumes completed inputs, requirement-specific tests, limitations, and evidence-derived verdicts before compliance. | closed |
| T-159-13/P06 | Tampering | Requirement ownership/evidence class | high | mitigate | All phase requirement sets were reconciled against the archived roadmap, requirements, and canonical matrix. | closed |
| T-159-14/P06 | Tampering / Repudiation | Phase 159 validation map | high | mitigate | The validation map records the exact eight-plan dependency graph, task IDs, evidence, and hosted gates. | closed |
| T-159-15 | Spoofing / Repudiation | Hosted run identity | high | mitigate | Closeout requires exact requested SHA, `headSha`, source SHA, repository, workflow, trigger, attempt, and run URL equality. | closed |
| T-159-16 | Tampering | Workflow/action provenance | high | mitigate | Receipts bind workflow SHA to local immutable-pin and least-privilege proof before dispatch. | closed |
| T-159-17 | Tampering / Repudiation | Coverage artifact | high | mitigate | Producer success, nonempty contents, artifact identity, size, digest, and retention were independently verified. | closed |
| T-159-18 | Information Disclosure | Actions logs/receipt | high | mitigate | No permissions or secrets were added; receipts record bounded conclusions instead of raw logs. | closed |
| T-159-19 | Repudiation | Milestone chronology | high | mitigate | The final audit consumes canonical evidence classes and exact-parent probes; only the four TEST-01 predicates remain waived. | closed |
| T-159-20 | Denial of Service | Hosted polling/download | medium | mitigate | The monitor tracks one exact run, applies bounded polling, downloads named artifacts to unique paths, and fails on timeout. | closed |
| T-159-21 | Elevation of Privilege | GitHub token | high | mitigate | The existing authenticated session is used only for dispatch/read/download; workflow permissions remain least privilege. | closed |
| T-159-22 | Tampering / Repudiation | 31-row requirement disposition | high | mitigate | Requirement-ID/owner pairs match archived requirements, canonical matrix, and final audit; TEST-01 is the sole chronology limitation. | closed |
| T-159-23 | Spoofing / Repudiation | Exact-SHA hosted proof | high | mitigate | Closure evidence distinguishes producer success from retention and binds both artifacts to the exact successful run SHA. | closed |
| T-159-24 | Repudiation | Final audit verdict | high | mitigate | One active final verdict replaces superseded narratives; structural checks reject contradictory closure claims. | closed |
| T-159-25 | Tampering | TEST-01 chronology | high | mitigate | The immutable probe receipt limits the waiver to four named historically-unprovable parent probes without changing the requirement. | closed |
| T-159-28 | Tampering | TEST-05 workflow regression test | high | mitigate | Tests parse named upload and checkout steps independently, including immutable checkout source and step-local upload policy. | closed |
| T-159-29 | Spoofing / Repudiation | Corrected-audit authority | high | mitigate | The fail-closed monitor requires a newly dispatched exact-SHA run, seven successful jobs, and two live SHA-bound artifacts with digests. | closed |
| T-159-26 | Information Disclosure | Audit evidence | low | accept | The public-repository audit links bounded provenance rather than embedding raw logs or secrets. | closed |
| T-159-27 | Denial of Service | Closure verification | low | accept | Local closure uses focused suites and bounded comparisons; hosted execution is an explicit exact-SHA dispatch. | closed |

*Status values are `open` or `closed`; accepted risks are closed by documented
disposition. Only open threats at or above `high` count toward `threats_open`.*

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---|---|---|---|---|
| AR-159-01 | T-159-04 | Schedule/manual-only informational coverage has bounded runner cost and does not affect required PR/push gates. | Phase 159 plan contract | 2026-08-26 |
| AR-159-02 | T-159-26 | Evidence concerns a public repository and is deliberately bounded to provenance links and conclusions. | Phase 159 plan contract | 2026-08-26 |
| AR-159-03 | T-159-27 | Focused local verification plus one explicit exact-SHA dispatch bounds operational load. | Phase 159 plan contract | 2026-08-26 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---:|---:|---:|---|
| 2026-08-27 | 37 | 37 | 0 | Codex automated evidence audit |

## Verification Evidence

- `159-VERIFICATION.md`: 22/22 must-haves, zero behavior gaps, 69 repository-contract tests, immutable action-pin validation, and actionlint success.
- `159-CLOSURE-RECEIPT.md`: bounded local results, clean worktree isolation, least-privilege proof, exact hosted identity, producer/upload separation, and artifact inspection.
- `159-VALIDATION.md`: Nyquist-compliant task/evidence map and fail-closed exact-SHA authority.
- `v1.37-MILESTONE-AUDIT.md`: 31/31 traceability IDs accounted for, 10/10 integrations, 8/8 flows, and no unresolved implementation or evidence gaps.

ASVS L1 short-circuit applies: the register was authored at plan time, every
blocking threat has verified mitigation evidence, and `threats_open` is zero.

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks are documented.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-08-27 by automated evidence audit
