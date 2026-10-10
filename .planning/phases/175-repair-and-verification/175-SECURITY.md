---
phase: "175"
slug: "repair-and-verification"
status: verified
threats_open: 0
threats_open_nonblocking: 1
threats_total: 17
threats_closed: 16
asvs_level: 1
block_on: high
created: "2026-10-10"
---

# Phase 175 — Security

Independent audit and recheck at `22089e9513a14d38a252e6dc59530b6d3698ef1d`. Six plans supplied a threat register; repeated T-175-SC is deduplicated. Zero open threats at or above the high blocking threshold. This is a security-control verdict, not final hosted CI passage or host approval.

## Trust Boundaries

Untrusted URL/form selection to the allowlist; failed source records to opaque retry receipts; backend/queue/index evidence to claims; asynchronous observation to current runtime; confirmation through host authorization to one mutation; test fixture routes to production views; disposable resources and source-bound evidence to completion.

## Threat Register

| Threat | Category | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|
| T-175-01 | Spoofing | high | mitigate | OperatorSelection current allowlist; rendered non-first/invalid/removed scope tests | closed |
| T-175-02 | Repudiation | medium | mitigate | Separate sync/config result, error and checked time; independent-read tests | closed |
| T-175-03 | Spoofing | high | mitigate | RecoveryObservation + validate_recovery_job/task bind receipt/source/job/attempt/task/index/runtime | closed |
| T-175-04 | Repudiation | high | mitigate | DocumentObservation requires expected active-index upsert projection/delete absence; both browser probes | closed |
| T-175-05 | Tampering | high | mitigate | Captured recovery_runtime compared with active_runtime_opts on success/exit; stale endpoint/instance/repo/prefix/node regression | closed |
| T-175-06 | Spoofing | high | mitigate | TaskPayload.normalize and matching promotion_task_id; malformed/wrong/missing UID tests | closed |
| T-175-07 | Tampering | high | mitigate | promotion_context_current? on promotion callbacks including check exit; deliberate same-task unknown fallback | closed |
| T-175-08 | Repudiation | high | mitigate | Read-only same retained UID check; timeout recheck asserts no second swap | closed |
| T-175-09 | Elevation of privilege | high | mitigate | Gating.gate_sensitive_action plus current allowlist and fresh PromotionEligibility before POST | closed |
| T-175-10 | Tampering | high | mitigate | Exact-pair confirmation; cancel/auth-return, duplicate and mutation-time prerequisite browser assertions | closed |
| T-175-11 | Information disclosure | medium | mitigate | HEEx escaping present; example browser-only mount leaves read authorization to host | open — below high threshold |
| T-175-12 | Elevation of privilege | high | mitigate | Mix.env()==:test guards dev_router/endpoint/fixture branches; normal-route fixture isolation test | closed |
| T-175-13 | Tampering | medium | mitigate | Enumerated named scenarios, unknown rejection, process-owned Agent state | closed |
| T-175-14 | Tampering | high | mitigate | SHA/PID namespace, no-existing-resource ownership checks, scoped runner, owned label teardown | closed |
| T-175-15 | Repudiation | high | mitigate | Source SHA/diff/JUnit/probes/captures and ci_monitor exact-SHA completion control; hosted gate pending | closed |
| T-175-16 | Spoofing | high | mitigate | Exact receipt/source/replacement attempt/task/index/document effect; mounted upsert/delete/swap probes | closed |
| T-175-SC | Tampering | high | mitigate | No dependency manifest change or new package-install step | closed |

## Open Advisory

T-175-11: full technical identifiers and diagnostics are HEEx escaped, but the ecommerce example mounts `/admin/search` through a browser-only pipeline. The generic Ops macro delegates read authorization to its host application. This is an existing host-boundary issue outside Phase 175's approved authentication scope. It remains open below the configured high threshold; no risk acceptance or production authentication claim is made. Production hosts must apply their existing authorization pipeline when mounting Ops.

The summary static-route flag maps to T-175-12: `/ops/phase175` static assets are inside the endpoint's test-only guard, not enabled in all environments.

## Accepted Risks Log

No accepted risks. Existing Cloak/cloak_ecto dependency advisories are unchanged and have not been accepted or repaired by this phase.

## Verification Evidence

The first audit at `d747e6d` found blocking T-175-05 and T-175-07. Commit `22089e9` fixes them. `recovery-runtime-red.log` records the intended failing stale-endpoint test; `recovery-runtime-green.log` records 52 focused passing tests. Canonical `security-fix-ops.log`: 334 tests + 2 doctests, zero failures. `security-fix-final/`: seven browser cases, no failures/skips/retries and cleanup zero. All paths are under `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/`.

The auditor's source evidence includes SyncDriftLive callbacks/runtime checks and the current mutation path, OperatorSelection, RecoveryObservation, DocumentObservation, PromotionEligibility, Gating, guarded fixture routes/assets, and the isolated runner/probes. No implementation or report was changed by the auditor.

## Security Audit Trail

| Audit date | Total | Closed | Blocking open | Nonblocking open | Run by |
|---|---:|---:|---:|---:|---|
| 2026-10-10 initial | 17 | 14 | 2 | 1 | gsd-security-auditor |
| 2026-10-10 recheck | 17 | 16 | 0 | 1 | gsd-security-auditor |

## Sign-Off

- [x] Every planned threat has a disposition and explicit status.
- [x] Blocking threats_open is zero; the medium host-boundary advisory remains explicit.
- [x] No maintainer identity, approval, risk acceptance or manual UAT was simulated.
- [x] Status verified describes present security controls only.

Exact-final-SHA hosted closeout and independent phase verification remain pending.
