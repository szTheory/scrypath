---
phase: 146
slug: scrypathops-web-client-remediation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-24
---

# Phase 146 — Security

> Per-phase security contract for the ScrypathOps dependency remediation and its verifier-driven test closure.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Hex registry / EEF CNA → maintainer process | Live fixed-release and advisory eligibility | Public package metadata and advisory ranges |
| Mix manifest → solver → lock | Fixed-compatible dependency selection | Package identities, constraints, versions, and checksums |
| Swoosh.ApiClient.Req → Req.Test | Production mail HTTP-client semantics | Synthetic request/response fixtures only |
| Git checkout → implementation/evidence commits | Candidate identity and user-owned worktree state | Source paths, commit SHAs, lock hashes, and compact status evidence |
| Disposable worktree → primary checkout | Fresh lockless resolution and cleanup | Temporary dependencies/build state; no credentials |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-146-01 | Tampering | Postgrex live evidence | high | mitigate | Fail-closed Hex and EEF CNA predicates before the fixed Postgrex selection | closed |
| T-146-02 | Tampering / DoS | Mix solver and lock | high | mitigate | Exact direct bounds, causal lock review, checked-lock verification | closed |
| T-146-03 | Spoofing | Swoosh compatibility test | medium | mitigate | Invoke the real `Swoosh.ApiClient.Req` through a per-test `Req.Test` plug | closed |
| T-146-04 | Information disclosure | Req test and commit | medium | mitigate | Synthetic `.example.test` data, no credentials/provider network, scoped staging | closed |
| T-146-SC-01 | Tampering | Hex package identities | high | mitigate | Existing package identities only, reviewed bounds/lock, unsuppressed audit | closed |
| T-146-05 | Repudiation | Deterministic gate evidence | high | mitigate | Exact candidate SHA plus ordered commands and exit statuses | closed |
| T-146-06 | Tampering | Primary Ops lock | high | mitigate | SHA-256 equality before and after all deterministic gates | closed |
| T-146-07 | DoS | Postgres-backed Ops gate | medium | mitigate | Canonical `mix verify.opsui` service/setup boundary; nonzero blocks | closed |
| T-146-08 | Elevation of privilege / Tampering | Scope diff | high | mitigate | Exact implementation paths and explicit no-UI/route/schema/provider review | closed |
| T-146-SC-02 | Tampering | Resolved packages | high | mitigate | Checked lock and exact candidate SHA before fresh proof | closed |
| T-146-09 | Spoofing / Repudiation | Detached candidate | high | mitigate | Detached worktree at recorded implementation SHA | closed |
| T-146-10 | Tampering | Fresh dependency selection | high | mitigate | Nine range assertions, exact Plug release predicate, unsuppressed audit | closed |
| T-146-11 | Repudiation | External evidence | high | mitigate | Live dual-source Postgrex checks, UTC window, and zero audit exit | closed |
| T-146-12 | Information disclosure | Evidence summary | medium | mitigate | Compact version/status evidence only; no raw logs, secrets, or snapshots | closed |
| T-146-13 | DoS / Tampering | Disposable cleanup | high | mitigate | Owned/non-symlink canonical path validation, exact removal, absence checks | closed |
| T-146-SC-03 | Tampering | Fresh Hex graph | high | mitigate | Existing identities, fixed bounds, exact-SHA resolution, audit | closed |
| T-146-14 | Spoofing | Raw-response contract | high | mitigate | JSON response, conflicting `decode_body: true`, exact raw-binary assertion | closed |
| T-146-15 | Tampering | Test-only closure topology | high | mitigate | `ff1531c` descends from `59d2e6a` and changes only the focused test | closed |
| T-146-16 | Repudiation | Closure evidence | high | mitigate | Exact closure SHA and focused/Ops/root gate exits in Plan 04 summary | closed |
| T-146-17 | Tampering | Manifest and lock after closure | high | mitigate | Hash equality to the dependency-remediation candidate | closed |
| T-146-SC-04 | Tampering | Post-closure supply chain | high | mitigate | Preserved checked lock and applicable unsuppressed fresh-resolution evidence | closed |
| T-146-18 | Information disclosure | Synthetic mail fixture | low | accept | Synthetic fixture intentionally proves client semantics without real provider data | closed |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-146-01 | T-146-18 | A synthetic JSON fixture cannot represent every provider payload, but it is the correct credential-free boundary for proving Swoosh/Req precedence and raw-body behavior. Provider-specific integration is outside Phase 146. | Automated phase execution under maintainer-approved `--auto` policy | 2026-08-24 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-24 | 22 | 22 | 0 | `gsd-security-auditor` + orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-24
