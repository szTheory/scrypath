---
phase: 145
slug: legacy-phoenix-and-ecto-decimal-remediation
status: verified
# Count of OPEN threats at or above workflow.security_block_on severity.
threats_open: 0
asvs_level: 1
created: 2026-08-24
---

# Phase 145 — Security

> Per-phase security contract for the legacy Phoenix and Ecto dependency remediation.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Hex resolver metadata → tracked manifest/lock | Network-origin package metadata determines the executable dependency cohort. | Package identities, versions, checksums, and dependency constraints |
| Test input → Phoenix endpoint/session/parser pipeline | Malformed cookies and unmatched JSON requests cross the request-processing boundary. | Untrusted HTTP path, headers, cookies, and parser input |
| Test process → Postgres SQL Sandbox | Repo calls and supervised processes must remain within the explicit owner lifetime. | Test records, SQL connections, and ownership state |
| Loopback client → ephemeral Bandit listener | A real socket is exposed briefly and must remain loopback-only with deterministic teardown. | Local HTTP request/response and request telemetry |
| Completed Plan 145-01 history → recovery commit | The recovery must extend, not rewrite, the completed compatibility implementation. | Commit identity, reviewed source, and dependency intent |
| Recovery candidate → deterministic commands | Required gates must exercise the exact post-recovery graph in binding order. | Source SHA, command status, and test results |
| Primary worktree → detached probe | Network resolution must not mutate or borrow primary-worktree state. | Lockfile, dependency/build paths, and unrelated workspace files |
| Registry/advisory feed → evidence summary | Mutable audit results must not be reported as deterministic proof when unavailable or failed. | Advisory status and package provenance |
| Postgres/Meilisearch services → supplemental status | Service-dependent evidence remains distinct from required graph and audit proof. | Service health and integration-test status |
| Command output → committed summary | Only compact, non-secret provenance may enter versioned evidence. | Versions, hashes, paths, exit classifications, and bounded status |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-145-01 | Tampering / Information disclosure / DoS | Dependency cohort and lock | high | mitigate | Fixed-compatible direct bounds, checked causal lock, exact-version assertions, and unsuppressed audit recorded in Plans 01–02 and Summary 02. | closed |
| T-145-02 | Denial of service | Parser/session endpoint boundary | medium | mitigate | `endpoint_compatibility_test.exs` sends unmatched JSON and a malformed signed-session cookie through the real endpoint and asserts the stable 404 JSON response. | closed |
| T-145-03 | Denial of service / Repudiation | Sandbox and listener test harness | medium | mitigate | DataCase owner lifecycle plus `start_supervised!/1`, port 0, loopback binding, telemetry message synchronization, detachment, and supervised teardown. | closed |
| T-145-04 | Elevation of privilege / Tampering | Scope boundary | medium | mitigate | Implementation commits are limited to the reviewed manifest/lock and two compatibility tests; no route, socket, migration, public API, endpoint-policy change, override, service, or CI surface was added. | closed |
| T-145-10 | Tampering / Repudiation | Completed and recovery commit history | high | mitigate | Plan 01 commit `e50fbd5694c75ff5f25c2a07046185f35c107dd9` remains an ancestor of the distinct recovery commit `4e2abed28feaef10a1f1d9b3be0fe0d236c9e478`; both roles are recorded in Summary 02. | closed |
| T-145-11 | Tampering / Information disclosure / DoS | Direct Plug bound and causal lock | high | mitigate | The manifest directly bounds Plug `~> 1.19.5`, retains the reviewed Phoenix/Bandit/Ecto SQL/Postgrex bounds, and keeps Ecto/Decimal transitive; the lock selects Plug 1.19.5. | closed |
| T-145-12 | Repudiation / Tampering | Deterministic rerun | high | mitigate | Summary 02 records checked-lock, manifest/lock preflight, clean-database tests, test-environment migration no-op, precommit, root regression, boundary-matrix exits, and tracked cleanliness for the recovery SHA. | closed |
| T-145-13 | Tampering / Information disclosure / DoS | Detached Hex resolution and audit | high | mitigate | Summary 02 records exact-SHA isolated resolution/build paths, all ten version assertions, warnings-as-errors compilation, dependency-path inspection, and an unsuppressed successful `mix hex.audit`. | closed |
| T-145-14 | Repudiation | Supplemental service evidence | medium | mitigate | Summary 02 records explicit Postgres/Meilisearch prerequisites and classifies the separate live smoke as supplemental passed with 10 tests. | closed |
| T-145-15 | Information disclosure | Evidence retention | low | accept | Retain only compact non-secret versions, hashes, paths, and statuses; exclude raw logs, advisory snapshots, full dependency trees, service artifacts, and disposable paths. | closed |
| T-145-16 | Denial of service / Tampering | Disposable worktree cleanup | high | mitigate | Summary 02 records removal/pruning of the detached worktree, isolated dependency/build cleanup, identical primary-lock SHA-256, clean tracked state, and preservation of the unrelated untracked audit file. | closed |
| T-145-SC | Tampering | Existing Hex package supply chain | high | mitigate | No new package identity was introduced; known package provenance, bounded requirements, checked lock, exact-SHA fresh resolution, causal review, and unsuppressed Hex audit are recorded. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

*Severity: critical > high > medium > low — only open threats at or above the configured high threshold count toward `threats_open`.*

*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-145-01 | T-145-15 | Compact non-secret provenance is necessary to make the dependency remediation reproducible and auditable. Exposure is bounded by explicitly excluding raw output, secrets, full trees, advisory snapshots, service artifacts, and disposable paths. | Plan 145-02 recorded disposition | 2026-08-22 |

*Accepted risks do not resurface in future audit runs.*

---

## Verification Evidence

- The current example manifest retains Phoenix `~> 1.8.9`, Plug `~> 1.19.5`, Ecto SQL `~> 3.14.0`, Postgrex `~> 0.22.4`, and Bandit `~> 1.12.1`; Ecto and Decimal remain transitive.
- The current lock selects Phoenix 1.8.9, Bandit 1.12.5, Ecto 3.14.2, Ecto SQL 3.14.0, Postgrex 0.22.4, Decimal 3.1.1, and Plug 1.19.5.
- `ecto_compatibility_test.exs` covers changeset rejection, real inserts, query/preload behavior, associations, and timestamps through SQL Sandbox.
- `endpoint_compatibility_test.exs` covers malformed-cookie stability and a supervised loopback-only port-0 Bandit request with stop telemetry and deterministic cleanup.
- Summary 02 records the exact recovery SHA, deterministic gate exits, isolated fresh resolution, boundary checks, unsuppressed advisory audit, live smoke classification, cleanup, primary-lock identity, and unrelated-file preservation.

Audit basis: both plan files contained parseable threat models (`register_authored_at_plan_time: true`). With ASVS L1, a high blocking threshold, and no open high-or-critical threat after the L1 evidence pass, the secure-phase short-circuit applied; no deeper L2/L3 auditor run was required.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-24 | 12 | 12 | 0 | Codex (`gsd-secure-phase`) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-24
