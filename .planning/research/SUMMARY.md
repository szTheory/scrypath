# Project Research Summary

**Project:** Scrypath — v1.39 Pre-Operator UI Quality Readiness Ratchet  
**Domain:** Whole-product non-UI quality and adopter-readiness assessment for an established Ecto-native Elixir search library  
**Researched:** 2026-09-25  
**Confidence:** HIGH for approved scope and repository evidence provenance; MEDIUM for current claim sufficiency pending the baseline.

## Executive Summary

Scrypath v1.39 is an audit and readiness milestone over the existing product. It should establish a traceable baseline across the approved non-UI dimensions, reuse v1.37 and v1.38 evidence only for the claims those artifacts actually support, and rank confirmed gaps separately from uncertainty and opportunities. This milestone does not itself authorize feature development, new runtime or public API surface, new infrastructure, or operator UI work. Research documents are guidance, not baseline evidence.

Keep the current Elixir/Ecto/Phoenix/Oban/Meilisearch stack and verification toolchain. Start with a capability-by-evidence index linked to canonical artifacts, then create a distinct evidence-ranked findings/disposition register. For any accepted closure work, define automated acceptance before implementation and choose the cheapest reliable proof for each claim. The main risks are overstating stale or narrow evidence, mistaking missing proof for a product defect, and expanding the assessment into unbounded cleanup. Keep readiness `NOT READY` until all program exit conditions are evidenced and every material finding is closed or explicitly accepted with an owner decision.

## Key Findings

### Recommended Stack

No technology or dependency change is recommended. Retain the current supported Elixir and OTP contract, Ecto-first library boundary, optional Oban integration, Meilisearch v1 target, Mix/ExUnit verification tasks, built-in coverage, GitHub Actions, and existing service/browser proof where a claim needs those boundaries. Do not raise the support floor or promote expensive checks to required CI as a side effect of the audit.

**Core technologies:**
- **Elixir / OTP:** Existing library/runtime contract — preserve the declared support floor and current CI tuples; assess compatibility only where a gap is decision-relevant.
- **Ecto:** Primary persistence and schema integration — central to the product's adopter contract.
- **Meilisearch:** Public v1 backend target — reuse existing backend evidence without broadening the backend promise.
- **Oban:** Optional asynchronous synchronization path — retain the existing optional integration and adopter proof.
- **Mix, ExUnit, StreamData, GitHub Actions:** Existing verification stack — use focused tests, selected properties, and current required/advisory lanes; line coverage is diagnostic rather than a readiness verdict.
- **PostgreSQL, Docker-backed services, Playwright:** Boundary-specific proof — use only for claims that cannot be established at a cheaper reliable layer.

See [STACK.md](STACK.md) for versions, lane details, alternatives, and source provenance.

### Expected Features

For this milestone, “features” are assessment dimensions and evidence practices, not product capabilities to add. The seven named non-UI dimensions cover public API and ergonomics; indexing/search lifecycle; ecosystem and package seams; operations and recovery; adopter experience; security/privacy/dependency/release integrity; and architecture/performance/verification quality. A capability-by-evidence ledger and explicit exit-gate decision connect those assessments to evidence.

**Must have (table stakes):**
- Assess every named dimension and representative adopter job with claim-level evidence, freshness, scope, and limitations.
- Distinguish confirmed defects from uncertainty, accepted risk, deferred or rejected opportunities, and unsupported ideas.
- Rank confirmed candidates by adopter impact, confidence, risk, implementation/regression cost, and recurring CI cost.
- Tie selected acceptance claims to executable automated evidence and preserve the program's fail-closed readiness gate.

**Should have (competitive):**
- Selectively reuse v1.37/v1.38 evidence while retaining its provenance and limits.
- Prefer lifecycle-oriented evidence mapping and evidence-weighted dispositions over a broad quality score or speculative backlog.
- Match verification depth and CI frequency to claim boundary, risk, and cost.

**Defer (v2+):**
- New public APIs, runtime behavior, backend/retrieval breadth, broad CI promotion, and ScrypathOps UI implementation. None is authorized by this research or established as a readiness requirement.

See [FEATURES.md](FEATURES.md) for the full scope inventory and the six-condition gate.

### Architecture Approach

Treat readiness as an evidence and decision architecture over the existing codebase, not a runtime restructuring. Maintain one capability-by-evidence index that links to authoritative source artifacts and a separate findings register. The durable readiness program remains scope and gate authority; bounded closure milestones own only selected, evidence-backed fixes and their automated acceptance. Closeout reconciles results and dispositions to the readiness record without duplicating canonical evidence or creating a competing backlog.

**Major components:**
1. **Readiness program record** — approved dimensions, scope guard, exit conditions, and current status.
2. **Capability-by-evidence baseline** — adopter job, claim/boundary, proof class, source/date/SHA/environment, what it proves, freshness, and limits.
3. **Finding register** — only substantiated gaps, ranked by impact, confidence, risk, churn, and verification cost; includes owner and explicit disposition.
4. **Bounded closure milestone** — selected finding IDs, requirements, and cheapest reliable automated acceptance.
5. **Closeout reconciliation** — update readiness status and candidate dispositions while preserving source history.

See [ARCHITECTURE.md](ARCHITECTURE.md) for data flow, evidence seams, and patterns.

### Critical Pitfalls

1. **Treating prior or stale evidence as universal proof** — map each current claim to its narrow supporting artifact and record freshness, SHA/date, evidence class, and limits; reuse only when the claim matches.
2. **Overstating synthetic, source-only, or advisory proof** — distinguish source/static, unit/property, contract, service integration, browser, and exact-SHA hosted evidence; record outcome separately from enforcement posture.
3. **Closing material findings without explicit disposition** — retain IDs, owners, rationale, and verification; do not pass the exit gate with unresolved critical/high/medium-leverage findings.
4. **Growing the audit into product expansion or endless cleanup** — separate breadth of assessment from breadth of implementation; require evidence and scope review before planning runtime/API changes; keep UI outside v1.39.
5. **Making every check a required CI gate or leaving routine UAT to people** — require only checks whose repeat confidence pays for cost, and map software acceptance to deterministic automation before implementation.

The additional risks—count-only readiness summaries, a permanent speculative backlog, and duplicated evidence ledgers—are covered in [PITFALLS.md](PITFALLS.md).

## Implications for Roadmap

The requirements and roadmap should stage assessment before any remediation. These are suggested work groupings, not pre-approved product implementation scope; formal requirements must derive from the approved readiness program and concrete baseline findings.

### Phase 1: Whole-Product Evidence Baseline
**Rationale:** Gap ranking is meaningful only after all named dimensions and representative adopter jobs have an explicit assessed/unassessed state.  
**Delivers:** A concise capability-by-evidence index linked to canonical evidence, with proof class, freshness, coverage, and limits; reuse v1.37/v1.38 only claim by claim.  
**Addresses:** Whole-product assessment, ecosystem and lifecycle seams, adopter experience, security/release, architecture/performance/verification evidence.  
**Avoids:** Treating milestone completion as universal readiness, indiscriminate reruns, duplicated ledgers, and synthetic proof inflation.

### Phase 2: Findings, Ranking, and Dispositions
**Rationale:** Separate confirmed gaps from missing evidence and speculative opportunities before selecting work.  
**Delivers:** A linked, auditable register with adopter impact/frequency, confidence, relevant risk, implementation/regression and CI cost, owner, and close/accept/defer/reject disposition.  
**Addresses:** Evidence-ranked bounded gap closure and the explicit diminishing-return decision record.  
**Avoids:** Turning uncertainty into features, hiding material findings, and maintaining stale backlog candidates.

### Phase 3: Bounded Evidence-Backed Closure (conditional)
**Rationale:** Only after Phase 2 establishes a worthwhile confirmed gap should implementation be scoped; cluster work by shared cause while preserving finding-level acceptance.  
**Delivers:** One or more small closure slices with automated acceptance mapped before implementation; any runtime/API change receives explicit scope-guard review and authority.  
**Uses:** Existing stack and verification lanes first; service/browser/exact-SHA evidence only where required by the claim.  
**Avoids:** Feature expansion, excess required CI, routine human-UAT debt, and claiming more than the evidence proves.

### Phase 4: Readiness Gate and Reconciliation
**Rationale:** The strategic decision follows baseline and selected closures, and must expose remaining risk and evidence limits.  
**Delivers:** Evaluation of all six program exit conditions, reconciliation of dispositions and release/support/planning truth, and a `READY FOR OPERATOR UI` recommendation only when the gate passes. Passing recommends the next focus; it does not automatically start UI work.  
**Avoids:** Green labels with hidden waivers, unresolved material findings, incomplete dimensions, or pending routine UAT.

### Phase Ordering Rationale

- The evidence baseline precedes ranking because absence of proof is not itself a software defect.
- Findings and dispositions precede implementation to keep scope bounded and evidence-led.
- Automated acceptance is defined before each closure implementation; costly integration evidence is reserved for real boundaries.
- Closeout updates the durable readiness record and links canonical evidence instead of copying it into competing artifacts.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1:** Only narrow, claim-specific research where current support combinations, external service behavior, or evidence freshness cannot be established from repository sources; do not commission a generic ecosystem survey.
- **Phase 3:** For each confirmed finding that implies a dependency, runtime/API change, service proof, or materially changed CI lane, research that specific implementation seam and scope authority.

Phases with standard patterns (skip research-phase):
- **Phase 2:** The existing v1.37 ledger and approved readiness rubric provide disposition and prioritization patterns.
- **Phase 4:** The approved program supplies its exit gate; closeout is primarily reconciliation and evidence checking.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Checked-in dependency/tooling evidence and prior milestone artifacts support retention; upstream documentation details are secondary and do not authorize changes. |
| Features | HIGH | Scope and gate come from the owner-approved readiness program; whether existing proof is sufficient remains to be assessed. |
| Architecture | HIGH | Evidence workflow follows canonical v1.37/v1.38 records; completeness of product evidence is not independently certified by this research. |
| Pitfalls | HIGH | Repository-specific provenance and process limitations are documented; general audit tradeoffs have medium confidence. |

**Overall confidence:** HIGH for process, boundaries, and evidence-handling recommendations; MEDIUM for any claim about present-day whole-product readiness, which remains `NOT READY` pending baseline assessment.

### Gaps to Address

- **Current whole-product coverage and sufficiency:** Research is not evidence. Assess each approved dimension against current source, tests, docs, and hosted proof, recording unassessed areas explicitly.
- **Evidence freshness and support combinations:** Recheck exact-SHA, dependency, service, and version claims only where the readiness decision relies on them; do not infer full matrix support from selected tuples.
- **Confirmed findings and remedy authority:** No specific product defect is established by this landscape. Requirements and closure scope must be derived from baseline evidence; any scope-guarded change needs the required owner decision.
- **Readiness exit gate:** Keep status `NOT READY` until all six conditions in the program record have linked evidence and material findings are resolved or explicitly accepted under its rules.

## Sources

### Primary (HIGH confidence)
- `.planning/reference/PRE-OPERATOR-UI-READINESS.md` — approved dimensions, operating rules, prioritization, and six-condition exit gate.
- `.planning/MILESTONE-CONTEXT.md` and `.planning/PROJECT.md` — milestone scope and existing project boundaries.
- `.planning/reference/QUALITY-LEDGER.md`, `.planning/milestones/v1.37-MILESTONE-AUDIT.md`, and Phase 159 evidence matrix/closure receipt — v1.37 findings, provenance classes, chronology limits, and dispositions.
- `.planning/milestones/v1.38-MILESTONE-AUDIT.md`, Phase 160 coverage/verification, and Phase 161 release evidence — package/release claims, exact-SHA proof, exclusions, and advisory-lane limitation.
- `.planning/reference/MILESTONE-ARC.md` and `.planning/reference/milestone-candidates.md` — evidence-gated sequencing and candidate selection/closeout posture.
- `mix.exs`, `.github/workflows/ci.yml`, and `CONTRIBUTING.md` — checked-in dependency, workflow, and contributor-command configuration; workflow source alone does not prove hosted execution.

### Secondary (MEDIUM confidence)
- [Mix 1.19.5 coverage task documentation](https://hexdocs.pm/mix/Mix.Tasks.Test.Coverage.html) — behavior and limits of line coverage.
- [GitHub Actions workflow syntax documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — scheduled workflow and permissions semantics.

### Tertiary (LOW confidence)
- None used. The research intentionally relies on local project authority rather than broad external comparison.

---
*Research completed: 2026-09-25*  
*Ready for requirements/roadmap: yes, with the scope caveat that this is an audit/readiness milestone and remediation remains conditional on findings.*
