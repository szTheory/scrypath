---
phase: 144
slug: root-http-client-dependency-remediation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-22
---

# Phase 144 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Hex registry/solver → four checked locks | Network-sourced package metadata determines the code selected by four independent Mix graphs. | Package metadata, versions, checksums, dependency graph |
| Checked dependency state → compatibility proof | The atomic solver result becomes the input to request and telemetry compatibility tests. | Locked Req transport implementation and configuration defaults |
| Caller config → Req request | Caller options and API-key material cross into the internal HTTP client. | API key, caller headers, request options, payloads |
| Upstream response/error → telemetry | Untrusted response and failure data is normalized into bounded telemetry metadata. | Error identity, status, operation metadata; potentially sensitive request context |
| Primary candidate → detached worktree | Evidence must exercise the exact reviewed commit without mutating its lock or build state. | Candidate SHA, root lock, isolated dependency/build artifacts |
| Live Hex registry/advisory feed → evidence record | Mutable network data determines fresh versions and current advisory status. | Registry resolution and advisory results |
| Command output → committed summary | Raw logs may contain excessive or environment-specific data; only compact provenance is retained. | Commands, exit statuses, version bounds, dependency paths |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-144-01 | Tampering / Denial of Service | Mix manifests and four locks | high | mitigate | Root, ScrypathOps, and ecommerce constrain Req to `~> 0.6.1`; root test Plug is `~> 1.19.5`; all four locks contain the reviewed Req/Finch/Mint/hpax closure. Plan 01 records four successful `mix deps.get --check-locked` gates and a causal moved-row review. | closed |
| T-144-02 | Information Disclosure | `Scrypath.Meilisearch.Client` request telemetry | high | mitigate | `test/scrypath/telemetry_test.exs` asserts transport-error identity while excluding headers, body, payload, API-key values, and caller payload markers from emitted metadata. | closed |
| T-144-03 | Denial of Service | Req response decoding/decompression defaults | medium | mitigate | Production request code remained unchanged during the Req 0.6 migration; the focused Req.Test suite exercises retry-disabled transport handling, JSON responses, and task filters without changing retry, timeout, redirect, or decompression defaults. | closed |
| T-144-04 | Spoofing | API-key plus caller-header merge | medium | mitigate | The Req.Test plug-boundary regression verifies the configured `x-meili-api-key` header and caller headers coexist; `default_headers/1` is prepended without replacing caller options. | closed |
| T-144-05 | Tampering / Repudiation | Exact-candidate proof | high | mitigate | Plan 03 records candidate SHA `23b8b834e8648eb97e76561f933556a4b6b04f96`, detached-HEAD equality, isolated dependency/build paths, clean primary state, stable root-lock hash, command exits, and worktree cleanup. | closed |
| T-144-06 | Tampering | Fresh dependency resolution | high | mitigate | The detached probe removed only its root lock, selected Req 0.6.3, Plug 1.19.5, Mint 1.9.3, and hpax 1.0.4 within the required bounds, inspected their paths, and passed unsuppressed `mix hex.audit`. | closed |
| T-144-07 | Denial of Service | Registry/advisory availability | medium | accept | External registry, advisory-feed, and supplemental service availability cannot be controlled locally. Phase 144 records unavailable evidence explicitly and blocks required evidence rather than manufacturing a pass; the unavailable Meilisearch smoke remained supplemental and was not counted as proof. | closed |
| T-144-08 | Information Disclosure | Evidence capture | low | mitigate | The committed summary retains compact provenance, commands/exits, target versions, and dependency paths while excluding raw logs, advisory snapshots, disposable locks, generated trees, and secret-bearing request data. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-144-01 | T-144-07 | Hex registry, advisory-feed, and supplemental service availability are third-party operational conditions. Phase decision D-17 accepts that condition only with fail-closed evidence classification: unavailable required evidence blocks advancement, and unavailable supplemental evidence is never promoted to a pass. | Phase 144 plan / GSD security verification | 2026-08-22 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit 2026-08-22

| Metric | Count |
|--------|-------|
| Threats found | 8 |
| Closed | 8 |
| Open | 0 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-22 | 8 | 8 | 0 | Codex / gsd-secure-phase |

## Verification Evidence

| Evidence | Result |
|----------|--------|
| Three phase PLAN threat models and three execution summaries | Eight planned threats classified; no summary threat flags added |
| Plan 01 checked-lock and causal-row evidence | Four checked graphs passed; bounded Req closure recorded |
| Plan 02 focused Req.Test and telemetry evidence | 13 tests passed; no production client change required |
| Plan 03 exact-candidate detached probe | Version bounds, dependency paths, cleanup, and unsuppressed Hex audit passed |
| Fresh `mix deps.get --check-locked` in root, ScrypathOps, legacy Phoenix, and ecommerce | All four exited 0 on 2026-08-22; graph-local advisory warnings remain explicitly assigned to phases 145–147 |
| Fresh focused client and telemetry test command | 13 tests, 0 failures on 2026-08-22 |
| Fresh unsuppressed root `mix hex.audit` | No retired or security advisory packages found on 2026-08-22 |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-22
