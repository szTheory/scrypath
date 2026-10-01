# Phase 170 Preterminal Security and Mitigation Audit

**Scope:** Threat models in Plans 01–08, reviewed against the recorded delivery and current Phase 170 inputs on 2026-10-01. This is a preterminal audit; Plan 07 freeze controls and Plan 08 terminal-record controls remain future checks.

## Review result

No unresolved high-severity software defect was found in the completed Plan 01–06 tooling/docs delivery. The factual validator preserves source and history boundaries and returns no semantic decision. Release risk is represented as a real block: PR #83 cannot merge or publish until an authorized GitHub reviewer submits an actual approval and current required-check recognition is refreshed. No branch protection was bypassed, no approval was synthesized, and no publication claim was made.

## Threat register

| Threat IDs | Mitigation evidence and current disposition |
|---|---|
| T-170-01A, T-170-01C | Docs ownership/route assertions and bounded semantic review are recorded. The broader subjective documentation judgment remains for the maintainer; tests do not decide it. |
| T-170-01B | Plan 04 scanned the exact seven-file public PR allowlist for private paths and credential patterns; no matches were reported. |
| T-170-02A, T-170-02E | Delivered collector joins explicit repository, SHA, run, attempt, job, artifact and digest identities. Archive size/member restrictions, subprocess argument arrays, and positive/negative cases are covered by the closeout-tool tests (15/0 on the release-candidate source). |
| T-170-02B | Validators require supplied judgments and provenance, validate author/body identity, and do not infer READY or approval. Current input result is FACTUAL_ONLY_VALID with semantic_decision null. |
| T-170-02C | Compact factual outcomes and source identities are retained in tracked planning inputs; dated corrections are append-only at issue #86. Final receipt retention remains Plan 08 work. |
| T-170-02D, T-170-03C | Allowlisted records and value-suppressing privacy behavior avoid auth/environment dumps. Public PR scan passed. Plan 06 scans the new current reports/input before commit; historical Phase 164 bytes retain a prior absolute temporary-cache pathname. That historical pathname is non-secret evidence and remains byte-pinned; this report does not reproduce it. |
| T-170-03A | Historical files and Phase 164 suffix remain pinned; validator checks the required byte hashes. Plan 06 changes only the live prefix and records exact main/source comparisons. |
| T-170-03B | Issue #86 was created with explicit authorization and read back from the actual repository. It is a decision location, not authorization for readiness or UI work. |
| T-170-04A | PR candidate, merge-ref, squash-main, and exact-source CI identities are recorded separately. Exact-main run 36795877117 matches the squash SHA. |
| T-170-04B | PR #87 used ordinary protected squash merge after the user's exact-action authorization and required checks. No admin bypass or simulated reviewer was used. |
| T-170-04C | Exact seven-file PR allowlist was reviewed and scanned; no private path or credential pattern was found. |
| T-170-05A | PR #83 package gate passed 81/0 and built/unpacked 0.3.14 from its exact head. Package/source and published/tag identities remain distinct. |
| T-170-05B | User authorization is recorded for the normal release chain, conditional on repository policy. The real required review is absent; merge and publication remain blocked. |
| T-170-05C | 0.3.14 is not represented as published: 0.3.13 remains the latest tag/package and the Release Please publish job was skipped. |
| T-170-05D | Public evidence records contain no credential/environment dump. Release execution reuses existing scoped workflow credentials; no alternate manual publish path was used. |
| T-170-06A, T-170-06B | Plan 06 reconciles all 24 claims, seven dimensions, eight named workflows, source identities, and current invalidators. Reports state exact observed results and pending external predicates. |
| T-170-06C | Unrelated local changes are explicitly preserved and remain outside the staged Phase 170 file set. Plan 07 still owns the declared delivery-worktree cleanup and closeout inventory. |
| T-170-06D | Plan 06 input/report scan passed; private temporary locations are omitted from current text, and pinned history remains byte-preserved. Historical pinned bytes remain unchanged. |
| T-170-07A–T-170-07D | Pending Plan 07: complete snapshot allowlist, external digests, final-tree comparison, selective cleanup, and final-source privacy review must pass before attestation. |
| T-170-08A–T-170-08E | Pending Plan 08: exact SHA/run/attempt/artifact joins, actual maintainer judgments/approval, durable receipt, privacy review, and no-post-attestation-write guard must all be enforced. |

## Residual security limits

- The four-graph Mint audit is bounded to those graphs and its recorded source. Current main's deep-quality job succeeded in run 36795877117 and reported no retired or advisory packages. PR #87 changed no lockfiles. This is not a deployment-wide vulnerability certification or proof that adopter graphs were refreshed.
- The newest exact-main push skipped the path-scoped E2E workflow; the latest named full E2E proof remains on 933ad30645c41df9f21dd4ddfd2d5b93fbd48620. Relevant paths were unchanged by PR #87, but no fresh full E2E run on current main is claimed.
- Final frozen-source and terminal-comment protections have not run. No security approval for Phase 170 completion is implied.
