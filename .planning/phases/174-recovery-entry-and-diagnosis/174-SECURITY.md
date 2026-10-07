---
phase: "174"
slug: recovery-entry-and-diagnosis
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-07"
register_authored_at_plan_time: true
---

# Phase 174 — Security

The 14 unique threats authored in the eight plans have implementation controls and executable regression coverage. This is the configured ASVS L1 verification of that register, with `security_block_on: high`. The canonical clean-register L1 short-circuit applies; no deeper auditor result or human risk acceptance is claimed.

## Trust Boundaries

| Boundary | Control |
| --- | --- |
| Browser schema and work identifiers → server selection/inspection | Canonical strings resolve through the allowlist; identifiers select only current inspected source/schema/full-ID records. |
| Current inspection → host authorization/recovery | Existing Gating, current selection, generation and delete scope apply before recovery dispatch. |
| Server navigation manifest → ignored palette DOM | Server Nav destinations own encoded hrefs; the existing hook copies those values and disconnects its observer. |
| Prior/partial observations → fleet UI | Source unavailability and retained success remain explicit; accepted queue work does not assert terminal completion. |
| Test fixture → ordinary routes and retained preview | Routes and fixture sources require test environment and fixture live action; disposable projects publish no original preview port. |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| T-174-01 | Spoofing | recovery schema query | high | mitigate | `OperatorSelection.resolve/2` uses exact canonical allowlist membership without atom creation; invalid/removed query journey and native browser cases refuse rows/actions. | closed |
| T-174-02 | Tampering | retry event and receipt | high | mitigate | FailedSyncLive checks current generation/selection, finds the current inspected work record, uses Gating/RecoveryAction, and distinguishes replacement acceptance from terminal completion. Failed-work/journey tests and real retry browser case pass. | closed |
| T-174-03 | Spoofing | OnMount target | high | mitigate | OnMount derives the target from canonical URL selection and the active server allowlist; absent fleet context stays nil. Shell tests and dual-entrypoint manifest/history/invalid-selection browser cases pass. | closed |
| T-174-04 | Tampering | palette destination | medium | mitigate | Layouts renders the canonical Nav manifest; CommandPalette observes only its server href attributes and copies them into existing anchors. Native hook and actual LiveView patch/filter/clear/Escape/focus tests pass. | closed |
| T-174-05 | Spoofing | sudo return_to | high | mitigate | Gating rejects nonlocal, cross-host, protocol-relative, encoded separator and backslash paths, and revalidates selected schema against the current host allowlist. Gating tests and real stale-sudo scoped-return browser cases pass without approval or replay. | closed |
| T-174-06 | Tampering | async result and confirmation | high | mitigate | SyncDriftLive rejects old generation/handle and removed-schema responses; FailedSyncLive rechecks generation, current selection, current work key and delete confirmation. Stale/removal regressions pass. | closed |
| T-174-07 | Repudiation | Control Room health claim | medium | mitigate | ControlRoom/Posture summaries retain source errors and prior success; copy bounds claims to observed fleet evidence. Zero, unavailable and retained tests pass; native retained/error/no-success browser sequence executes green. | closed |
| T-174-08 | Tampering | row next-check href | medium | mitigate | Row actions use each allowlisted module with `OperatorSelection.path/3`; sorting does not choose the target. Native selected healthy A/worse B, deliberate row navigation and schema-keyed reorder/focus tests pass. | closed |
| T-174-09 | Tampering | work ID/action lookup | high | mitigate | `ui_work_key/2` qualifies schema, source and full ID; lookup recomputes keys over current inspection rather than decoding/trusting client data. Equal-ID, wrong-source, stale-allowlist and exact delete-scope cases pass. | closed |
| T-174-10 | Information Disclosure | failure diagnosis | medium | mitigate | Primary diagnosis uses translated reason/facts, existing queue-reason 500-character bound and escaped text; verbose source metadata stays in collapsed Diagnostics. Native long-reason/ID/index/delete-modal sequence and disclosure-order tests pass. | closed |
| T-174-11 | Repudiation | accepted receipt | medium | mitigate | Receipt names original and replacement Queue IDs, retains original failure, and states terminal completion is unobserved. Real pending retry issues no receipt before the server response; accepted receipt/status handoff tests pass. | closed |
| T-174-12 | Elevation of Privilege | fixture routes | high | mitigate | DevRouter registers Phase174 routes only under `Mix.env() == :test`; view fixture helpers also require test environment and `:phase174`. Normal-route regression and actual stale Sigra Gating cases pass; no normal-route auth bypass was introduced. | closed |
| T-174-13 | Denial of Service | disposable Compose cleanup | medium | mitigate | Source/scope-owned project namespace, EXIT trap, `down --volumes`, residue assertion and unpublished original port are present. Disposable runner cleanup reports 0; browser container is removed. The separately named review preview on4014 is intentionally retained and documented, while4012 remains unchanged. | closed |
| T-174-SC | Tampering | package installations | high | mitigate | Existing locked dependencies/images were bootstrapped; no new project dependency or lockfile change was introduced. Build volumes remain separate per app. | closed |

## Accepted Risks Log

No accepted risks. The unchanged locked Cloak/CloakEcto advisories inherited from Phase173 remain outside this register and are not accepted, remediated, or assessed for deployment exposure here. This report does not claim host login/sudo approval, global dependency security, release readiness, or hosted final-SHA attestation.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
| --- | --- | --- | --- | --- |
| 2026-10-07 | 14 | 14 | 0 | Codex orchestrator, configured ASVS L1 source/register verification |

## Sign-Off

- [x] All threats have a mitigation disposition and source/test evidence.
- [x] No risk acceptance or reviewer identity was fabricated.
- [x] `threats_open: 0` for the planned register.
- [x] `status: verified` at configured L1 depth.

Evidence: final native browser11/11 in `174-FINAL-BROWSER.xml`; source identities and limits in `174-FINAL-EVIDENCE.json`; Ops272tests+2doctests/0 and root661tests+4properties/0. Product source is `d4395f2`; test/fixture follow-up is `024a450`. Subsequent tracking commits do not add a security mitigation.

## Security Audit 2026-10-07

| Metric | Count |
|---|---|
| Threats found | 14 |
| Closed | 14 |
| Open | 0 |
