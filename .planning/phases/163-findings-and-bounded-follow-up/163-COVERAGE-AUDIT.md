# Phase 163 Planning Coverage Audit

This is the planning coverage and probe record. It is not a findings ledger or product evidence. Phase 162 remains the canonical evidence index; execution writes the source-linked decisions to 163-FINDINGS.md. Phase 164 alone decides readiness.

## Discovery and sizing

Level 0: existing Markdown evidence patterns and Python standard-library parsing suffice. Research and pattern mapping are complete; no external package, product API, schema push, service stack, frontend, or UI-SPEC is needed. No project-local skills or knowledge graph were found; agent_skills is empty. Source patterns were read from check_baseline.py, the quality ledger, Phase 162 summaries, and Phase 161 remediation/validation/release receipts. Relevant prompts were consulted for Ecto/host ownership, asynchronous visibility, source-of-truth, idiomatic library scope, and release/verification posture. Historical prompt recommendations do not override current scope.

Calibration result: factor 1, sample_count 0, confidence low. Raw and calibrated estimates are equal: 29,000 / 22,000 / 19,000 tokens. Each plan has two tasks; no task modifies more than four files. No irreversible decision is introduced. Tracer first; MVP enrichment disabled.

## Dependency and ownership graph

| Task | Needs | Creates / expands | Checkpoint |
|---|---|---|---|
| 163-01-01 | Phase 162 baseline and Phase 160/161 receipts | C-21 end-to-end decision, canonical amendment, complete checker grammar and focused fixtures | No |
| 163-01-02 | Tracer document/checker | C-15/C-16/C-17 reconciliation and residual gaps | No |
| 163-02-01 | Reconciled inventory and checker | All remaining claim triage and any evidenced F cards/rank factors | No |
| 163-02-02 | Complete triage | Source-backed ranks and accountable dispositions | No |
| 163-03-01 | Material disposition set | Qualified K/P cards or explicit zero result, initial complete handoff | No |
| 163-03-02 | Complete decision artifact | Actual validation, semantic source audit, final handoff | No |

Waves: 163-01 → 163-02 → 163-03. Shared writes to 163-FINDINGS.md and the canonical baseline make these dependencies necessary. There are no parallel file or mutable-state races. Validation's Wave 0 is included in the first production tracer; it is not a separate foundation-only plan.

## Multi-source coverage audit

| Source | ID | Feature / constraint | Plan/task | Status |
|---|---|---|---|---|
| GOAL | Phase 163 | Evidence-led material decisions and only qualifying future work with automated acceptance | 01–03 | COVERED |
| REQ | FIND-01 | Defect, gap, opportunity and source attribution remain distinct | 01-01/02, 02-01 | COVERED |
| REQ | FIND-02 | Independent impact/exposure/confidence/risk/cost with qualitative severity | 02-01/02 | COVERED |
| REQ | FIND-03 | All material dispositions, owner acceptance, event triggers | 02-02 | COVERED |
| REQ | CLOSE-01 | Bounded authorized milestone/patch or explicit nonqualification | 03-01 | COVERED |
| REQ | CLOSE-02 | Cheapest reliable claim-local automation and justified changed CI posture | 03-01/02 | COVERED |
| RESEARCH | R-01 | One canonical baseline; no competing receipt ledger | 01-01, 02-01, 03-02 | COVERED |
| RESEARCH | R-02 | Reconcile C-21 against later Mint root-graph remediation; no universal audit claim | 01-01 | COVERED |
| RESEARCH | R-03 | Match C-17 mounted terminal swap and visible-search oracle to an exact receipt/source | 01-02 | COVERED |
| RESEARCH | R-04 | C-15/C-16 retry interaction does not establish repaired state | 01-02 | COVERED |
| RESEARCH | R-05 | C-09/C-11 package opt-outs do not invalidate narrower existing proof | 02-01 | COVERED |
| RESEARCH | R-06 | C-10 application authorization stays host-owned; examine actual Scrypath seam | 02-01 | COVERED |
| RESEARCH | R-07 | C-19 upgrade needs named transition; C-23 optimization needs observed workload | 02-01 | COVERED |
| RESEARCH | R-08 | Assess full inventory including API/request-edge/onboarding claims | 02-01 | COVERED |
| RESEARCH | R-09 | Historical chronology waiver cannot become a present fabricated historical pass | 02-01 | COVERED |
| RESEARCH | R-10 | All F factors distinct; severe consequences survive cost/low-frequency tradeoffs | 02-01/02 | COVERED |
| RESEARCH | R-11 | Actual owner authority; disposition is not gate closure | 02-02, 03-02 | COVERED |
| RESEARCH | R-12 | K outcome/scope/owner/proof grouping, milestone-versus-patch rationale, zero allowed | 03-01 | COVERED |
| RESEARCH | R-13 | Claim-local proof cards, real versus future receipts, CI economics only for changed posture | 03-01 | COVERED |
| RESEARCH | R-14 | Standard-library checker, six discriminating negative fixtures, true positive controls | 01-01, 03-02 | COVERED |
| RESEARCH | R-15 | Checker establishes completeness/linkage only; source review establishes judgment | 01-01, 02-02, 03-02 | COVERED |
| RESEARCH | R-16 | No product-suite reruns for prose; existing baseline checker only for amendments | All task verification | COVERED |
| RESEARCH | R-17 | Existing candidate/final exact-SHA closeout; final tracked edits precede attestation | 03 verification/output and outer executor | COVERED |
| RESEARCH | R-18 | Secret-safe provenance, data-only checker inputs, no package installation | 01 threat model/actions; all plans | COVERED |
| RESEARCH | R-19 | Environment limits: Mix unavailable; use bounded existing receipts and preserve unavailable links | 01-02, 02-01, 03-01 | COVERED |
| CONTEXT | D-01 | Materiality requires observed defect or specifically evidenced Scrypath-owned risk | 01-01/02, 02-01 | COVERED |
| CONTEXT | D-02 | Gaps stay linked/unranked; investigate only decision-changing uncertainty | 01-01/02, 02-01/02 | COVERED |
| CONTEXT | D-03 | Confidence independent from impact/severity | 01-01, 02-01/02 | COVERED |
| CONTEXT | D-04 | Critical / High / Medium-leverage / Low without score | 01 interfaces, 02-01/02 | COVERED |
| CONTEXT | D-05 | Independent risk and cost factors; cost never lowers severity | 02-01/02 | COVERED |
| CONTEXT | D-06 | Qualitative costs, measured evidence where available, no speculative hours | 02-01/02 | COVERED |
| CONTEXT | D-07 | Explicit disposition, real owner acceptance, owner/event deferral, Phase 164 boundary | 01-01/02, 02-02, 03-02 | COVERED |
| CONTEXT | D-08 | Group only shared outcome/scope/proof; split risk/owner/oracle differences | 03-01 | COVERED |
| CONTEXT | D-09 | Coordinated outcome milestone versus contained patch | 03-01 | COVERED |
| CONTEXT | D-10 | Evidence/outcome/scope/automation eligibility; value-cost and scope guard | 03-01 | COVERED |
| CONTEXT | D-11 | Nonqualification beside C-ID; no standing backlog; deferred owner/event retained | 01-01/02, 02-01/02, 03-01 | COVERED |
| CONTEXT | D-12 | Proof stays with selected finding/candidate | 03-01 | COVERED |
| CONTEXT | D-13 | Cheapest reliable observable proof layer | 03-01 | COVERED |
| CONTEXT | D-14 | CI promotion only with justified recurring confidence/cost and diagnosis | 03-01 | COVERED |
| CONTEXT | D-15 | Full compact proof contract and no routine human UAT | 01 interfaces, 03-01/02 | COVERED |

Exclusions: no deferred ideas were listed. Phase 164 gate/reconciliation requirements and later product implementation are outside this phase. No item is omitted because of difficulty. Broader PROJECT/portfolio/readiness-record inconsistencies belong to Phase 164 reconciliation; they are not permission to expand this phase.

## Spec-less edge probe: all 11 supplied items retained

No phase SPEC exists. The orchestrator's exact report has two unclassified rows plus three generic prompts for each of FIND-02, FIND-03, and CLOSE-02. Generic categories are specialized to the document contract, never turned into unrelated product behavior. Unclassified rows remain unresolved assumptions as required by specless-probe-fallback.md.

| Probe | Requirement | Supplied shape | Resolution / explicit acceptance or flagged assumption | Location |
|---|---|---|---|---|
| E-01 | FIND-01 | unclassified | **UNRESOLVED assumption:** baseline support/freshness and finding class are separate; no automated shape inference can establish semantic materiality. D-01/D-02 plus source-linked review govern. | 01/02 actions; handoff retains limitation |
| E-02 | CLOSE-01 | unclassified | **UNRESOLVED assumption:** ranked materiality does not grant roadmap eligibility; evidence/outcome/scope/feasible acceptance determine qualification and zero is valid. | 03-01; handoff retains limitation |
| E-03 | FIND-02 | adjacency | Resolved / explicit: rank factors/evidence bind to the actual F and C IDs; adjacent findings cannot donate their evidence or lower severity. | 02 truths; 01 checker links |
| E-04 | FIND-02 | empty-input | Resolved / explicit: complete claim triage may have zero material findings; empty/missing claim inventory fails. No fictional F card. | 02 truths; 01 fixture controls |
| E-05 | FIND-02 | ordering | Resolved / explicit: stable-ID relationships and rank do not depend on Markdown row order. | 02 truths; 01 reorder fixture |
| E-06 | FIND-03 | adjacency | Resolved / explicit: each F has its own disposition basis; another finding's acceptance cannot supply owner approval. | 02 truths/action; 01 checker |
| E-07 | FIND-03 | empty-input | Resolved / explicit: zero findings has explicit linked rationale; a material F without disposition is rejected. | 02 truths/actions |
| E-08 | FIND-03 | ordering | Resolved / explicit: ID-linked treatment and derived counts survive row/card reordering; receipt chronology follows source/run identity. | 01/02 truths/actions |
| E-09 | CLOSE-02 | adjacency | Resolved / explicit: each proof belongs to its selected parent claim; adjacent or cross-owned P links fail. | 03 truths; 01 checker |
| E-10 | CLOSE-02 | empty-input | Resolved / explicit: no selected candidate allows no proposed acceptance; a selected candidate with no proof/observable oracle fails. | 03 truths; 01 negative fixture |
| E-11 | CLOSE-02 | ordering | Resolved / explicit: proof ownership/eligibility is stable by IDs; work-unit ordering follows actual dependency, not presentation. | 03 truths/actions; 01 reorder fixture |

Accounting: 11 surfaced = 9 explicit must-have predicates + 2 flagged unresolved assumptions. No dismissal, no fabricated product-edge scope, no implicit backstop green.

## Adversarial prohibition recall and precision

Question applied separately to each requirement: What could this feature silently become that the author would not want, but the requirement does not fully forbid?

| Requirement | Raw recall candidates | Precision result |
|---|---|---|
| FIND-01 | Gap becomes defect; old proof becomes current; source becomes execution; adjacent proof becomes universal claim; host policy becomes library defect; secret logs copied; unsafe path access; malformed IDs; duplicate rows; stale links | Keep the evidence-attribution intent constraint P-01. Path/secret concerns are canon-referral. IDs/rows/links are ordinary contract correctness. |
| FIND-02 | Cost hides severity; low confidence erases impact; low exposure erases severe consequence; invented hour estimates; severity treated as score; arbitrary rank sorting; empty matrix error; duplicated field; missing column; generic biased label | Keep independent-consequence intent P-02. Rank vocabulary/cost representation already have D-03–D-06 checks. Table mechanics are ordinary correctness; generic bias is canon-referral. |
| FIND-03 | Agent forges owner acceptance; deferral becomes closure; rejected remedy erases risk; green checker becomes owner approval; hidden unresolved risk; mismatched owner link; missing event; repeated card ID; bad disposition enum; no-card crash | Keep accountable-treatment intent P-03. Link/event/enum/empty mechanics are contract checks. Consolidate overlapping accountability variants into P-03. |
| CLOSE-01 | Gaps manufacture work; rank creates authority; speculative standing backlog; product implementation starts during assessment; UI readiness inferred; broad scope smuggled through grouping; duplicate candidate ID; orphan source; missing outcome; sorting changes eligibility | Keep scope/strategic-ownership intent P-04. Candidate integrity/order mechanics are contract checks. Grouping authority variants consolidate into P-04. |
| CLOSE-02 | Expensive proof treated as inherently better; required CI grows without value; UAT replaces automation; source masquerades as receipt; commands presented as already executed; click substitutes for outcome; arbitrary manifest proliferation; invalid command path; shell injection; cleanup handle leak | Keep proportional automated-proof intent P-05. Evidence variants consolidate with P-01. Path/cleanup mechanics are ordinary checks; injection is canon-referral. |

Canon-referral: path traversal, injection, secret disclosure, and generic bias are canon — refer to $gsd-secure-phase and applicable static/security tooling; do not mint bespoke prohibitions. The proportional plan threat models still mitigate the actual evidence/checker boundaries. No new eslint or security framework is introduced into this Python/Markdown phase.

The five kept items were serialized through the installed probe-core.cjs projectProhibitions function, then copied into the owning plans' must_haves.prohibitions as flat scalar fields. They have status unresolved, no fabricated check descriptor, and no claimed verification tier. They remain flagged-unverified semantic intent constraints, even though focused structural fixtures enforce narrower necessary conditions.

| ID | Requirement | Owning plan | Bespoke statement / resolution |
|---|---|---|---|
| P-01 | FIND-01 | 163-01 | Absent/stale/adjacent/source-only evidence must not become a defect, repaired outcome, or universal safety claim. Unresolved semantic attribution; source review required. |
| P-02 | FIND-02 | 163-02 | Cost, low frequency, or low confidence must not hide credible severe consequence. Unresolved semantic ranking; separate factors and evidence review required. |
| P-03 | FIND-03 | 163-02 | Owner decisions must not be simulated, and deferred/rejected remedies must not erase risk. Unresolved authority judgment; real decision sources required. |
| P-04 | CLOSE-01 | 163-03 | Gaps or rank must not manufacture scope, a backlog, or readiness. Unresolved scope judgment; eligibility and Phase 164 authority retained. |
| P-05 | CLOSE-02 | 163-03 | Expensive proof, CI growth, or human UAT must not substitute for claim-specific automation. Unresolved contextual judgment; claim-local rationale retained. |

Accounting: 5 kept = 5 descriptor-less must_haves.prohibitions, all carried into execution source review and handoff. Ordinary contract checks and canon referrals are documented precision drops, not silently omitted unresolved prohibitions. These flags do not introduce a routine human UAT gate, ask for simulated approval, or predetermine an actual finding.

## Execution limits and closeout ownership

All artifact acceptance uses the focused standard-library checker plus discriminating fixtures. Baseline amendments use the existing checker verbatim. Historical receipt inspection does not become a new product execution claim. No new recurring lane is commissioned. Existing CONTRIBUTING candidate/final exact-SHA closeout remains the outer executor's responsibility, once per stage after the relevant commits; final tracked edits must precede final attestation. Phase 164 owns the six-condition readiness decision and broad release/package/support/planning reconciliation.
