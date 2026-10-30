---
phase: "184"
slug: explicit-and-lean-dependency-graphs
status: pending_terminal_evidence
threats_open: 1
asvs_level: 1
block_on: high
created: "2026-10-30"
---

# Phase 184 — Security mitigation verification

The security auditor checked the authored register against actual implementation, tests, and raw receipts. Twenty-one mitigations are established. The final source-freeze attestation remains an open evidence gate; this record grants no security-risk acceptance and no universal security clearance.

## Trust boundaries

| Boundary | Control |
| --- | --- |
| Packaged library and consumer resolver | Actual archive dependency metadata, independent version witnesses and public HTTP/Telemetry behavior |
| Host application and optional Ops integrations | Capability-safe compilation/startup, host ownership, explicit requested-auth validation and sensitive-action denial |
| Development builder and deployed runtime | Independent dependency graphs and static-output-only transfer with image/served-byte identity |
| Repository and hosted evidence | Immutable Actions, scoped credentials/cache writers, complete audit inventory and exact-source immutable attestation |

## Threat register

| Threat ID | Category | Component | Severity | Disposition | Actual mitigation evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| T-184-01 | Tampering | archive dependency metadata | high | mitigate | `mix.exs`; `test/release/consumer_smoke_test.exs:121`; actual archive metadata and direct-declaration mutation. | closed |
| T-184-02 | Denial of service | Req compatibility consumers | medium | mitigate | `test/release/consumer_smoke_test.exs:104` and `:146`; independent Req 0.6.3/0.7.5 public behavior and shared archive receipts. | closed |
| T-184-03 | Denial of service | deleted mail/config routes | medium | mitigate | `test/mix/tasks/dependency_boundary_contract_test.exs:52`, `:67`, `:75`; removed declarations/files and mail configuration. | closed |
| T-184-04 | Denial of service | diagnostic compile/runtime boundary | high | mitigate | Ops telemetry, endpoint, dev-router and application capability guards; `test/release/ops_dependency_boundary_test.exs:35` and `:58`. | closed |
| T-184-05 | Elevation of privilege | host endpoint/Repo ownership | medium | mitigate | `scrypath_ops/lib/scrypath_ops/application.ex:37`; direct supervisor-child and router tests. | closed |
| T-184-06 | Spoofing | unavailable requested Sigra | high | mitigate | `scrypath_ops/lib/scrypath_ops/security.ex:26`; integration capability predicate; actual absent-dependency startup test. | closed |
| T-184-07 | Elevation of privilege | sensitive action context | high | mitigate | `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex:74`; malformed-context/callback sentinel tests across every configured action; future/invalid/window checks. | closed |
| T-184-08 | Repudiation | Sigra action audit identity | high | mitigate | Actual shared audit-argument construction and `Sigra.Audit.log_safe/3`; exact actor/org/sudo and single-callback test. | closed |
| T-184-09 | Tampering | asset builder→runtime handoff | high | mitigate | Independent Docker runtime targets and static-only COPY paths; handoff mutation tests reject builder dependency transfer. | closed |
| T-184-10 | Information disclosure | production boot configuration | high | mitigate | Explicit production secret/database/static-manifest inputs; unsafe configuration mutations and actual production runtime proof. | closed |
| T-184-11 | Elevation of privilege | dependency-absent auth branch | high | mitigate | Dependency-absent Gating definition blocks requested Sigra; fresh VM checks every protected callback and failed startup. | closed |
| T-184-12 | Denial of service | fresh target graphs/served bundles | high | mitigate | Runtime script independently checks graphs, applications, locked dependencies, startup and served bytes; successful final mounted receipts. | closed |
| T-184-13 | Tampering | verification stack/image identity | high | mitigate | Runtime script unique ownership, source/recipe/lock fingerprints, image labels and running-image IDs, retained-preview rejection and bounded owned cleanup. | closed |
| T-184-14 | Tampering | version resolution and metadata | high | mitigate | Four current manifest/lock hashes match raw audit identities; official release/retirement evidence and actual selected package/consumer checks. | closed |
| T-184-15 | Denial of service | Bandit/admitted tooling updates | high | mitigate | Bandit 1.14.1 in all three HTTP consumers; all four complete raw audits inspected with no Bandit finding; package/backend/Ops/matrix proofs. | closed |
| T-184-16 | Elevation of privilege | Actions runner/credentials/permissions | high | mitigate | Six immutable workflow pin sets; PR/event/permission/credential contracts and successful candidate execution plus actionlint. | closed |
| T-184-17 | Tampering | Phase182 cache and immutable action identity | high | mitigate | BEAM cache graph/environment identity, trusted-writer save policy, mutation tests and Docker cache writer serialization. | closed |
| T-184-18 | Repudiation | support and security claim boundaries | medium | mitigate | Canonical current support text and focused contracts distinguish range/witness, tuple/upstream maintenance, source/release, audit and runtime security. | closed |
| T-184-19 | Denial of service | documented build/start commands | medium | mitigate | Runbook aliases/targets/runtime inputs match manifests, Docker/config and actual verification dispatch. | closed |
| T-184-20 | Repudiation | four-graph advisory evidence | high | mitigate | Four-graph audit runner and omission/duplicate/wrong-source/continuation/lock-mutation contracts; inspected actual raw exits; independent Dialyzer success. | closed |
| T-184-21 | Tampering | final-source evidence freeze | high | mitigate | Exact-SHA closeout controls exist and the corrected isolated candidate passed. Terminal attestation of the final merged branch remains pending after all tracked report/review/completion writes. | open |
| T-184-22 | Denial of service | mail-free route/application coherence | medium | mitigate | Mail-free router/config negative mutations, canonical repository wiring, real Ops startup and mounted runtime checks. | closed |

## Accepted risks

No accepted risks. The Ops aggregate dependency audit still exits nonzero for the two known Cloak/Cloak Ecto advisories. They remain explicitly affected and unaccepted, with upstream fixed-release, advisory, reachable-use/configuration, and policy revisit triggers in the dependency ledger. Verifying this phase's evidence controls does not resolve those upstream findings.

## Auditor evidence

The configured security auditor inspected the actual raw four-graph output/exits, independently successful Dialyzer receipt, current manifest/lock fingerprints, implementation controls and executable tests. No cold builds were repeated and no files were modified by that auditor. The successful isolated candidate is [hosted run 41029783634](https://github.com/szTheory/scrypath/actions/runs/41029783634); its immutable evidence is external at `/private/tmp/scrypath-phase184-10-20261030T072352Z/receipts/candidate-2-final.json`.

## Open terminal evidence condition

T-184-21 remains open until canonical closeout verifies the final merged branch SHA, required jobs, coverage, attestation and immutable artifact identities after tracked writes finish. Existing candidate success is not terminal merged-branch proof. Necessary review, report reconciliation and bounded repairs continue within the selected phase; no next-phase advancement is authorized while this condition remains unresolved. The final terminal receipt must remain outside the checkout so recording it does not mutate the attested source.

## Audit trail

| Date | Auditor | Total | Closed | Open |
| --- | --- | ---: | ---: | ---: |
| 2026-10-30 | gsd-security-auditor; read-only authored-register audit | 22 | 21 | 1 |

No approval was requested, simulated or implied. The orchestrator owns the remaining terminal evidence check. The retained UI preview safety stop and unrelated config edit remain preserved.
