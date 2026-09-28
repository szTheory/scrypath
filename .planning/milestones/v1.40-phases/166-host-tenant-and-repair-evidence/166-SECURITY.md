---
phase: "166"
slug: "host-tenant-and-repair-evidence"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-27"
---

# Phase 166 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Synthetic principal to Phoenix host context | The scenario supplies an already-authenticated synthetic actor; persisted identity and membership select the tenant. | Actor ID, selected tenant ID, allowlisted query inputs |
| Host context to Scrypath and Meilisearch | The host constructs tenant scope and filter inputs; backend configuration is kept in the separate server-owned runtime argument. | Search query, filter, facet request |
| Raw hits to host hydration | Search hits are retained as raw evidence; database hydration independently filters by authorized tenant and returned IDs. | Synthetic document IDs and projected fields |
| Operator selection to repair execution | The Ecto query selects the explicit IDs; each returned backend task is checked before the same query is used to confirm visibility. | Synthetic source IDs, task UID, index UID |
| Evidence to accepted closeout claim | Scenario markers are tied to candidate source, hosted run/job identity, and their recorded claim limits. | Sanitized IDs, task state, source/run metadata |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-166-H1 | Spoofing / Elevation | Blog membership lookup | high | mitigate | Persisted actor/member join and selected-tenant ownership checks; positive and negative recorder cases in `blog_tenant_search_test.exs`. | closed |
| T-166-H2 | Tampering | Blog params/options | high | mitigate | Strict string-key allowlist; scope, filter, and runtime overrides reject before backend dispatch. | closed |
| T-166-H3 | Information disclosure | Raw search, counts, facets, hydration | high | mitigate | Symmetric tenant A/B raw IDs, counts, categories, facet values, and independently tenant-and-ID-scoped hydration in the live host scenario. | closed |
| T-166-H4 | Denial of service | Test service calls | medium | mitigate | Unique owned indexes, bounded task/visibility waits, serialized integration repository, and owned cleanup. | closed |
| T-166-H5 | Repudiation | Host scenario evidence | medium | mitigate | Success-only scenario marker and run/job/source provenance in `166-EVIDENCE.md` and `.json`. | closed |
| T-166-H6 | Spoofing | Upstream login/session | medium | transfer | Production authentication remains host-owned; the fixture explicitly assumes an already-authenticated synthetic principal and makes no session-security claim. | closed |
| T-166-R1 | Tampering | Backfill scope | high | mitigate | Explicit Ecto ID predicate, one-document batch result, source-only sentinel, and unchanged visible control. | closed |
| T-166-R2 | Tampering | Reconcile report | high | mitigate | Calibrated request observer records reads and rejects mutation methods; task-history snapshots and raw results remain unchanged. | closed |
| T-166-R3 | Repudiation | Completion oracle | high | mitigate | Returned task UID, terminal success, expected index, and subsequent exact raw ID/projection are asserted independently. | closed |
| T-166-R4 | Denial of service | Service/repository lifecycle | medium | mitigate | Existing unique prefixes, bounded waits, per-module integration execution, and task-owned cleanup. | closed |
| T-166-R5 | Information disclosure | Failure/receipt output | medium | mitigate | Scenario output contains synthetic IDs, task/index state, and required projections; environment secrets are omitted. | closed |
| T-166-E1 | Repudiation | Host/package/repair provenance | high | mitigate | Match implementation SHA, run/attempt/job identities, and named scenario markers; advisory Phoenix evidence was independently inspected. | closed |
| T-166-E2 | Tampering | C-09 reuse | high | mitigate | Relevant-path two-tree comparison accounts for all 16 changes and records a semantic reason for each before reusing only the bounded hard-delete claim. | closed |
| T-166-E3 | Information disclosure | Receipt/log excerpts | medium | mitigate | Store sanitized synthetic values and digests; omit credentials and environment dumps. | closed |
| T-166-E4 | Elevation of privilege | Scope/CI/readiness claims | medium | mitigate | Local artifact consumption is distinguished from Hex publication; advisory posture and host ownership remain explicit. | closed |
| T-166-E5 | Denial of service | Verification resources | low | accept | Keep existing required/advisory lanes and bounded scenario scope; no new service matrix is introduced. | closed — accepted below the blocking threshold |

*Only open threats at or above the configured `high` threshold count toward `threats_open`.*

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-166-E5 | T-166-E5 | The approved phase reuses existing required/advisory lanes and intentionally avoids expanding the service matrix. This is a low-severity scope choice, not a claim that every service tuple was tested. | Phase 166 plan disposition | 2026-09-27 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-27 | 16 | 16 | 0 at or above high | Codex orchestrator, inline evidence audit |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed at ASVS L1
- [x] `status: verified` set in frontmatter

**Approval:** Security gate verified from the phase threat registers, automated validation map, and exact-source evidence on 2026-09-27. This does not certify production host authentication or broader recovery behavior.
