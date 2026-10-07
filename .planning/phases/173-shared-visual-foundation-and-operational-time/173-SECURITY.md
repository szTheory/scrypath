---
phase: "173"
slug: "shared-visual-foundation-and-operational-time"
status: verified
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: "2026-10-07"
---

# Phase 173 — Security

All nine unique threats were authored in the four plans. Their named mitigations are present. At configured ASVS L1 and zero open threats, the workflow short-circuits before auditor dispatch; this is an orchestrator source/coverage check, not a simulated independent audit or maintainer approval.

## Trust Boundaries

Browser storage → appearance; test fixture → application environment; external backend/queue timestamp → normalized state → escaped UI/clipboard; retained observation → displayed age; LiveView eligibility → browser busy hook.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| T-173-01 | Tampering | theme storage | low | mitigate | root.html.heex normalizes only system/light/dark and guards storage reads/writes; shell denied/invalid-storage cases pass. | closed |
| T-173-02 | Information disclosure | fixture routes | medium | mitigate | Both router registrations and standalone asset plug compile only in Mix test; providers live in test/support; Compose publishes no fixture ports and uses a unique disposable project. | closed |
| T-173-03 | Tampering | timestamp normalization | medium | mitigate | State source_iso parses and matches the normalized instant; OpsUi validates again and HEEx escapes native exact text. | closed |
| T-173-04 | Repudiation | retained time | medium | mitigate | Posture last_success_refs retains source-local observed_at on fetch error; actual failed refresh advances Checked while retaining age/ISO in both routes. | closed |
| T-173-05 | Spoofing | status presentation | medium | mitigate | Production Posture/Status classifications remain authoritative; unavailable and terminal failure labels tested independently across the status matrix. | closed |
| T-173-06 | Elevation of privilege | refresh hook | medium | mitigate | updated() rereads serverDisabled; loading overlays that state; actual connected server patch leaves action disabled. | closed |
| T-173-07 | Spoofing | clipboard feedback | medium | mitigate | Await writeText; latest-attempt guard prevents stale completion from replacing a newer failure; denied/absent methods remain persistent. | closed |
| T-173-08 | Tampering | clipboard payload | medium | mitigate | Copy requires source ISO parsed to same instant; browser asserts full fractional precision and offset; no clipboard read or fallback. | closed |
| T-173-SC | Tampering | dependency installation | high | mitigate | No package/lock/dependency manifest changed from execution baseline; existing locked dependencies and Docker browser stack reused. | closed |

## Accepted Risks Log

No accepted risks. No threat flags in execution summaries.

## Security Audit

| Item | Count |
| --- | --- |
| Threats found | 9 |
| Closed | 9 |
| Open | 0 |

Checked 2026-10-07 against source `d3af57fd1f156df2d6e1deec18200ae3b1eef119`, with 34/34 connected browser cases, fresh core proof and final Ops precommit (247 tests/two doctests). Configured block threshold: high. All threats, including below-threshold items, are closed by implementation evidence.

## Separate Dependency Advisory Evidence

The hosted advisory deep-quality lane on [candidate run 37558615968](https://github.com/szTheory/scrypath/actions/runs/37558615968) flags the unchanged Ops lock graph's `cloak 1.1.4` and `cloak_ecto 1.3.0`. The package-level notices are [CVE-2026-95105](https://osv.dev/vulnerability/EEF-CVE-2026-95105) (high, AES-CTR integrity) and [CVE-2026-94206](https://osv.dev/vulnerability/EEF-CVE-2026-94206) (medium, PBKDF2 iteration handling), published 2026-10-06. Root/core and example dependency graphs report clean. No manifest or lockfile changed in Phase 173.

The nine closed items above concern this phase's authored trust-boundary mitigations, including introducing no new dependency; they do not claim the existing dependency graph is advisory-free or assess a host's cipher/hash configuration. Deployment exposure and dependency remediation need a separate follow-up. No exemption, suppression, risk acceptance, release approval, or dependency update is inferred. Per CONTRIBUTING, this lane is advisory and distinct from the required closeout gates.
