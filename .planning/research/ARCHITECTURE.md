# Architecture Patterns

**Domain:** Whole-product non-UI adopter-readiness assessment for an Ecto-native Elixir search library  
**Researched:** 2026-09-25  
**Confidence:** HIGH for the planning/evidence architecture; MEDIUM for completeness of prior product evidence

## Recommended Architecture

Treat v1.39 as an evidence and decision architecture over the existing product, not as a runtime restructuring project. Use a single capability-by-evidence baseline as the index across adopter jobs and the seven readiness dimensions. Each row should identify the adopter job, capability/boundary, current evidence links, evidence class and freshness, what the evidence actually proves, known limits, and disposition. Link existing v1.37/v1.38 evidence rather than copying its claims. Keep implementation findings in a separate linked register so an assessed capability is not conflated with a confirmed gap or a planned fix.

The durable readiness program remains the authority for scope and the exit gate. The milestone baseline should add evidence and dispositions beneath that policy, then each bounded closure milestone should own its requirements, plans, automated acceptance, and audit. At each closeout, reconcile the closure result back into the readiness record and milestone candidate list. This avoids creating a second competing product backlog or treating a milestone audit as the whole-product readiness decision.

```text
Adopter jobs and lifecycle boundaries
             |
             v
Capability-by-evidence baseline -----> Prior evidence (v1.37, v1.38, source, CI)
             |                              [linked with limits/freshness]
             v
Evidence-ranked finding register
       |                 |
       v                 v
Bounded closure      Disposition with rationale/revisit trigger
milestones                |
       |                  |
       +-------> readiness record / exit-gate decision
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|---|---|---|
| Readiness program record | Owns approved scope, baseline dimensions, exit criteria, and current readiness status | Baseline index, closure evidence, milestone arc |
| Capability-by-evidence baseline | Records assessment coverage and the strength, recency, and limits of proof for each adopter-facing capability | Existing test/source/CI artifacts; finding register |
| Finding register | Captures only evidence-backed candidate gaps and ranks impact, confidence, risk, churn, and recurring verification cost | Baseline rows; bounded milestone requirements or documented dispositions |
| Bounded GSD milestone | Owns implementation requirements and cheapest reliable automated acceptance for a selected set of findings | Finding IDs, repo checks, exact-SHA hosted evidence if needed |
| Closeout reconciliation | Updates readiness evidence and terminal dispositions without erasing source history | Readiness record, candidate list, milestone audit |

### Data Flow

Start from named adopter jobs, including install/first-use, indexing and search, synchronization and deletion, operational recovery, upgrade/release, and support diagnosis. Map each job to relevant capabilities and failure boundaries. For each capability, inspect existing implementation, tests, docs, package proof, and hosted CI receipts; classify evidence precisely and record gaps in coverage. Only a demonstrated defect, inadequate proof for an important claim, or material adopter friction becomes a finding. Rank such findings before selecting implementation scope. Close each selected finding with automated evidence, then reconcile accepted/deferred low-leverage opportunities and any accepted risks into the readiness gate.

The architecture should preserve three distinct states: **not assessed**, **assessed with sufficient evidence**, and **assessed with a finding/disposition**. A passing bounded audit is not equivalent to a whole-product assessment. Missing evidence is an uncertainty to investigate, not automatically a runtime defect.

## Evidence and Integration Seams

| Seam | Reusable evidence | Boundary that must stay explicit |
|---|---|---|
| Runtime safety, internal architecture, command/CI topology, supply chain, measured performance | v1.37 quality ledger and its phase 159 canonical evidence matrix | v1.37 states its bounded code-quality scope; it does not assess every adopter or product dimension. Its rows distinguish committed/present-state evidence from historically unprovable chronology. |
| Package-backed Phoenix integration and release truth | v1.38 phase 160 verification, phase 161 release evidence, and v1.38 milestone audit | Phase 160's API coverage matrix is explicit about excluded capabilities: settings inspection, index swap, document delete, task listing, facet search, and multi-search. Do not imply those flows were exercised by package proof. |
| Live-service confidence | Exact-SHA v1.38 package/path Phoenix runs and release CI receipts | The Phoenix service lane remains advisory in CI even though the final candidate passed. The readiness baseline should record both observed success and gate strength. |
| Compatibility | v1.37's four curated CI tuples and v1.38 clean consumer compile | These prove only their named runtime/version tuple and consumer shape; do not extrapolate to all supported combinations or downstream deployments. |
| ScrypathOps operator UX | v1.32–v1.34 records and accessibility evidence | The pre-UI program intentionally assesses non-UI product readiness; existing UI evidence is context and is not a reason to add UI work to v1.39. |

## Patterns to Follow

### Pattern 1: Claim-to-evidence rows with explicit limits
**What:** Give each readiness claim a stable identifier and attach the direct source, test/command, immutable receipt or exact-SHA hosted run that supports it. State the evidence class, date/SHA/environment where applicable, and what it does not prove.  
**When:** For baseline rows, findings, and exit-gate claims.  
**Example:** v1.37 Phase 159's `159-EVIDENCE-MATRIX.md` separates historically proven, present-state verified, supported by prior committed evidence, and historically unprovable; it also records a limitation and disposition per requirement. Reuse this discipline, not necessarily its detailed chronology schema for every baseline row.

### Pattern 2: Explicit producer-consumer and end-to-end seam maps
**What:** Trace important claims across actual boundaries and name the producer artifact, consumer, trigger, and result.  
**When:** For package/build/release flow, adopter integration, asynchronous sync, and operations/recovery claims.  
**Example:** v1.38's audit traces package proof from CI services through staging, dependency provenance, clean consumer compile, and live scenarios; release proof proceeds from Release Please through CI, tag, Hex, HexDocs, and package parity. This gives the baseline a proven format for connecting artifacts without duplicating them.

### Pattern 3: Findings are evidence-derived and separately dispositioned
**What:** Keep coverage inventory distinct from the ranked list of confirmed issues; include a closed/deferred rationale and a trigger for revisiting deferred items.  
**When:** After enough of the baseline has been assessed to compare gaps by adopter impact and cost.  
**Example:** v1.37's quality ledger records evidence, benefit, churn, verification, and disposition; the milestone candidates guide requires concrete signal before new roadmap scope. Extend the fields only as the approved readiness rubric requires.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Treating prior milestone status as universal readiness
**What:** Marking a broad dimension complete because a prior milestone passed or an audit had no integration gaps.  
**Why bad:** Audits are bounded by their requirements and test surfaces; a connected set of phase outputs is not proof that every important adopter workflow has been examined.  
**Instead:** Map each v1.37/v1.38 artifact to the specific claims it covers and record untested capabilities and runtime combinations.

### Anti-Pattern 2: One giant duplicated readiness ledger
**What:** Copying all archived requirements, test results, and current backlog candidates into a new omnibus table.  
**Why bad:** Evidence goes stale and conflicting copies emerge; the v1.37 audit already demonstrates that source rows, chronology limits, and retrospective indexes need clear ownership.  
**Instead:** Keep the baseline as an index with links and concise claim/limit fields. Preserve detailed phase evidence in its source artifact and keep finding dispositions distinct.

### Anti-Pattern 3: Converting uncertainty directly into implementation
**What:** Adding APIs, runtime changes, broad test suites, or required CI jobs because a dimension has thin evidence.  
**Why bad:** Thin evidence could mean an assessment gap rather than a product defect; unnecessary runtime or CI surface increases maintenance and may cross the existing scope guard.  
**Instead:** First choose the cheapest discriminating inspection or automated proof. Plan product changes only for evidence-backed adopter value, with explicit scope-guard review.

### Anti-Pattern 4: Collapsing advisory and required proof
**What:** Reporting a live-service check as a merge gate when CI classifies it as advisory, or treating local source/test evidence as an exact-SHA hosted result.  
**Why bad:** This overstates release and integration guarantees. v1.38 explicitly records a successful service run and its advisory status as separate facts.  
**Instead:** Record execution outcome and enforcement posture independently; cite immutable run and SHA for hosted claims.

## Scalability Considerations

| Concern | At current project scale | As evidence/findings grow | At broad adopter scale |
|---|---|---|---|
| Baseline size | One markdown capability-by-evidence index linked to canonical artifacts | Split by lifecycle or dimension only when navigation becomes difficult; keep one index of coverage and status | Avoid a custom database/dashboard unless maintainers cannot keep source-linked markdown accurate |
| Evidence freshness | Record dates, commits, supported versions, and hosted run IDs for unstable evidence | Reassess evidence when code, CI contract, or support matrix changes | Automate freshness checks only for stable machine-readable claims that warrant recurring CI cost |
| Finding throughput | Rank a small register and create bounded milestones only for worthwhile confirmed gaps | Group findings by shared cause, but retain separate adopter impact and closure criteria | Use incoming reproducible adopter reports to refresh candidates; do not prepopulate speculative work |
| Verification cost | Prefer existing service-free and capability gates; use exact-SHA hosted proof at real integration seams | Measure runtime and maintenance cost before promotion to required CI | Keep expensive confidence runs scheduled/advisory until evidence supports blocking merges |

## Sources

- [Pre-Operator UI Quality Readiness Program](../reference/PRE-OPERATOR-UI-READINESS.md) — dimensions, baseline shape, prioritization fields, exit gate, and operating rules.
- [v1.39 Requirements](../REQUIREMENTS.md) and [Roadmap](../ROADMAP.md) — approved scope and phase sequence for the active milestone.
- [v1.37 Quality Evidence Ledger](../reference/QUALITY-LEDGER.md) — existing bounded findings, evidence, churn, verification, and dispositions.
- [v1.37 Milestone Audit](../milestones/v1.37-MILESTONE-AUDIT.md) and [Phase 159 Evidence Matrix](../milestones/v1.37-phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/159-EVIDENCE-MATRIX.md) — evidence ownership, provenance classes, limitations, and integration coverage.
- [v1.38 Milestone Audit](../milestones/v1.38-MILESTONE-AUDIT.md), [Phase 160 API Coverage](../milestones/v1.38-phases/160-package-backed-phoenix-proof/COVERAGE.md), [Phase 160 Verification](../milestones/v1.38-phases/160-package-backed-phoenix-proof/160-VERIFICATION.md), and [Phase 161 Release Evidence](../milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md) — package and release seams, exact-SHA evidence, test boundaries, and advisory lane caveats.
- [Milestone Candidates](../reference/milestone-candidates.md) and [Milestone Arc](../reference/MILESTONE-ARC.md) — evidence-gated roadmap posture and selection/closeout rules.

## Caveats

- This is architecture guidance for the readiness assessment and evidence flow; it does not establish that any particular quality dimension is already assessed or sufficient.
- The readiness program remains `NOT READY` pending baseline evidence. Do not treat a research document as baseline evidence or change that status from this analysis.
- The archive was inspected as planning evidence; this document does not independently rerun tests, re-query hosted workflows, review all source modules, or certify current runtime behavior.
- Exact-SHA, dependency-version, and service-backed claims age. Recheck only when the baseline depends on them for a current readiness decision.
