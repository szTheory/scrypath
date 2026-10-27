---
phase: "182"
slug: reliable-full-browser-verification-and-ci-caches
status: verified
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: "2026-10-27"
---

# Phase 182 — Security

The eight authored plan threat models contain twenty unique threats, including the shared T-182-SC. ASVS L1 mitigation discovery found controls for all twenty; the secure-phase documented L1 short-circuit applies. This is orchestrator code/test inspection, not an independent security audit or blanket inherited-risk acceptance.

## Trust boundaries

| Boundary | Control |
| --- | --- |
| Maintainer preview to disposable verifier | Preview target refusal precedes mutation; unique Compose project scopes disposal. |
| Source to Compose/Bake/runtime images | Checked graph, source labels and exact built/runtime IDs. |
| PR/fork to shared cache writer | Event/repository/branch policy denies untrusted export; observations retain the actual configured policy. |
| Download archives to compiled outputs | Compatible downloads only; strict ABI/graph/lock resolved keys. |
| GitHub run/artifact to acceptance | Pinned run attempt, exact ref/SHA/session/namespace, raw outcome and immutable digest. |
| Output paths to archive and cleanup | Run-owned allowlists, containment checks, project-label filtering and bounded finalization. |

## Threat register

Paths below resolve under `scripts/ci/` unless otherwise stated. Test line references identify executable mitigation checks; the complete source and exact hosted evidence are covered by the final phase verification.

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| T-182-01 | Tampering | Compose scope and readiness | high | mitigate | ecommerce_lifecycle.test.cjs:313,347,468; six hosted receipts and local full prove both routes | closed |
| T-182-02 | Denial of service | EXIT ownership and status | high | mitigate | ecommerce_lifecycle.test.cjs:488,506,528,535,552; project-scoped cleanup and original status | closed |
| T-182-SC | Tampering | Tool supply chain | high | mitigate | No lockfile/package-manager dependency or Dockerfile changes from ba624a74; all actions retain immutable 40-hex pins, Docker actions retain first-party namespace and signed-release pins; existing least-privilege permissions preserved | closed |
| T-182-03 | Tampering | Preview target guard | high | mitigate | ecommerce_target.test.cjs:29,38,54; verification-target.mjs refuses preview before guarded action | closed |
| T-182-04 | Repudiation | Browser expected state and test reachability | medium | mitigate | ecommerce_target.test.cjs:54; workflow_wiring_test.exs and required Node CI step preserve counted test reachability | closed |
| T-182-05 | Repudiation | Case/attempt reconciliation | high | mitigate | ecommerce_evidence.test.cjs:70,97,105,118,127,147; composite identities and strict first attempts | closed |
| T-182-06 | Tampering | Receipt provenance and file inputs | high | mitigate | ecommerce_evidence.test.cjs:473,491,533; ecommerce_evidence.cjs source/status checks and symlink/path containment | closed |
| T-182-07 | Information disclosure | Artifact ownership/copy | high | mitigate | ecommerce_lifecycle.test.cjs:410,506; ecommerce_evidence.test.cjs:533,567; fresh run directory and upload allowlist | closed |
| T-182-08 | Repudiation | Raw outcome and event SHA | high | mitigate | phase182_acceptance.test.cjs:278,295,993,1040; raw-step outcome, workflow ref, SHA and immutable artifact joins | closed |
| T-182-09 | Denial of service | Job budget and finalization | medium | mitigate | ecommerce_lifecycle.test.cjs:398; verify-e2e.sh bounded deadlines; six hosted jobs 762–952s including upload/disposal | closed |
| T-182-10 | Tampering | Prebuilt graph and image handoff | high | mitigate | ecommerce_build.test.cjs:296,314,537,574,595,615; checked graph, source and runtime IDs with no second build | closed |
| T-182-11 | Elevation of privilege | Trusted GHA cache writer | high | mitigate | ecommerce_build.test.cjs:261,376,398,420,514; trusted event/repository writer policy with recipe-scoped v2 caches | closed |
| T-182-12 | Information disclosure | Exported image layers | high | mitigate | ecommerce_build.test.cjs:498; .dockerignore excludes env/private output; unchanged Dockerfiles; actual cache log proofs contain scoped build progress | closed |
| T-182-13 | Tampering | BEAM compiled/cache identity | high | mitigate | beam_cache.test.cjs:82,104,120,180; strict tuple/environment/target/profile/graph/lock key boundaries | closed |
| T-182-14 | Information disclosure | Cache path selection | high | mitigate | beam_cache.test.cjs:59,132; beam_cache.cjs explicit archive and resolved-output allowlists exclude credentials and isolated probes | closed |
| T-182-15 | Repudiation | Cache hit versus command execution | medium | mitigate | beam_cache.test.cjs:149; workflow unconditional deps.get/compile/verifier; real fallback/lock/cold command outcomes in cache receipts | closed |
| T-182-16 | Repudiation | Hosted run and artifact collection | high | mitigate | phase182_acceptance.test.cjs:860,878,919,942,964,1021,1040; pinned-attempt metadata, pagination and source/digest/session joins | closed |
| T-182-17 | Tampering | Probe controls and lock copy | high | mitigate | phase182_acceptance.test.cjs:341,684,796,1061; isolated builder, bounded inputs and comment-only owned lock checkout; no shared cache deletion | closed |
| T-182-18 | Repudiation | Cache acceptance claims | high | mitigate | phase182_acceptance.test.cjs:357,380,416,570; current five-mode cache validator eligible; observations cannot grant strict warm acceptance | closed |
| T-182-19 | Repudiation | Final full-browser source/budget/cleanup | high | mitigate | phase182_acceptance.test.cjs:306,1290; current full aggregate eligible189/189, clean disposal, measured timings and exact-head closeout | closed |

## Accepted risks

No accepted risks. The known deep-quality dependency audit debt is scoped to Phase 184 and is not waived by this report. No open blocking threat is hidden by transfer or approval.

## Audit trail

2026-10-27 — GSD orchestrator, L1 code/test discovery: twenty authored threats; twenty controls found; zero open. Node behavior checks, repository contracts and exact-source hosted/local acceptance supply execution evidence. No new dependencies, secrets, workflow-token elevation or public API change.

## Sign-off

- [x] All twenty unique threats have mitigation dispositions and observed controls.
- [x] No accepted-risk or human-review identity was fabricated.
- [x] `threats_open: 0` and `status: verified`.

## Security Audit 2026-10-27

| Metric | Count |
|---|---|
| Threats found | 20 |
| Closed | 20 |
| Open | 0 |
