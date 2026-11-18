---
phase: "184"
slug: explicit-and-lean-dependency-graphs
status: secured
threats_open: 0
asvs_level: 1
block_on: high
created: "2026-10-30"
---

# Phase 184 — Security mitigation verification

The security auditor checked the authored register against actual implementation, tests, and raw receipts. All twenty-two implemented mitigations are established at the repaired-root audit cutoff. The exact final planning successor still requires its mandatory terminal rerun; this record grants no security-risk acceptance and no universal security clearance.

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
| T-184-21 | Tampering | final-source evidence freeze | high | mitigate | Repaired-root run 41153254156 attests actual source `779c13312de1f2a774d39ad6928aac60d2eecfac`, required jobs and immutable artifacts; wrapper proves unchanged HEAD. CONTRIBUTING enforces final tracking successor then a new terminal rerun with no later tracked writes. Verified as an exercised mitigation; future source is not pre-attested. | closed |
| T-184-22 | Denial of service | mail-free route/application coherence | medium | mitigate | Mail-free router/config negative mutations, canonical repository wiring, real Ops startup and mounted runtime checks. | closed |

## Accepted risks

No accepted risks. The Ops aggregate dependency audit still exits nonzero for the two known Cloak/Cloak Ecto advisories. They remain explicitly affected and unaccepted, with upstream fixed-release, advisory, reachable-use/configuration, and policy revisit triggers in the dependency ledger. Verifying this phase's evidence controls does not resolve those upstream findings.

## Auditor evidence

The configured security auditor inspected the actual raw four-graph output/exits, independently successful Dialyzer receipt, current manifest/lock fingerprints, implementation controls and executable tests. No cold builds were repeated and no files were modified by that auditor. The successful isolated candidate is [hosted run 41029783634](https://github.com/szTheory/scrypath/actions/runs/41029783634); its immutable evidence is external at `/private/tmp/scrypath-phase184-10-20261030T072352Z/receipts/candidate-2-final.json`.

## Mandatory final acceptance condition

The auditor rechecked current repair controls, the fresh four-graph raw audit, current stable locks and the actual repaired-root candidate receipt. It returned SECURED with 22/22 implemented mitigations verified and no new flags. This supersedes the earlier open T-184-21 evidence finding: the actual integrated root SHA now has a successful, immutable source/run/artifact join. The result does not attest a future planning successor.

This report, goal verification and phase tracking form a separately identified planning successor under CONTRIBUTING's two-stage rule. The orchestrator must commit all of them, run canonical terminal closeout at that exact new HEAD, and preserve its receipt externally before claiming phase acceptance. Any later tracked change requires a new terminal run. No next phase, merge, publication or risk acceptance follows from this mitigation verdict.

Candidate receipt: `/private/tmp/scrypath-phase184-execution/candidate-root-repaired-result.json`; [run 41153254156](https://github.com/szTheory/scrypath/actions/runs/41153254156). Coverage artifact `13023504806`, digest `sha256:21bd6e9ce0dad8142b530eba49d2cbabf0e8ebd531afa91af1ec3141301303ad`; attestation artifact `13025026532`, digest `sha256:30b62993032bc0d65dcff7b4e8a5336f8a2f754918e528bf2128d7a08f75266f`. Repository, branch, event, full SHA, required-job set and unchanged completed HEAD were checked.

Fresh audit at the same source: `current-root-audit.term`, `.log`, `.exit`. Every graph is complete with unchanged current lock hashes, Hex 2.5.1 and empty default ignores. Only the two known Cloak findings remain; the new Phoenix.HTML advisory was repaired with compatible 4.4.0 and is absent from both local and hosted audit findings. Canonical Ops cold/direct suite and owned Postgres cleanup passed (`phoenix-html-full-ops.log`, `phoenix-html-postgres.json`). Source re-review found no remaining findings.

## Audit trail

| Date | Auditor | Total | Closed | Open |
| --- | --- | ---: | ---: | ---: |
| 2026-10-30 | gsd-security-auditor; initial read-only authored-register audit | 22 | 21 | 1 |
| 2026-10-31 | gsd-security-auditor; repaired-root source/audit/artifact recheck | 22 | 22 | 0 |

No approval was requested, simulated or implied. The orchestrator owns the remaining terminal evidence check. The retained UI preview safety stop and unrelated config edit remain preserved.
