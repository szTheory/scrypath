# Domain Pitfalls: Pre-Operator UI Quality Readiness Ratchet

**Domain:** Whole-product quality and adopter-readiness assessment for a mature, pre-1.0 Elixir OSS library
**Researched:** 2026-09-25
**Confidence:** HIGH for repository-specific evidence and process failure modes; MEDIUM for general audit-program tradeoffs

This assessment applies the approved readiness program and the concrete evidence limits recorded in v1.37 and v1.38. It is not a new finding that Scrypath currently has any of these defects; these are failure modes the v1.39 baseline and closure process must guard against.

## Critical Pitfalls

### Pitfall 1: Treating old evidence as current, complete, or independent proof

**What goes wrong:** A milestone report or passing command is carried forward as proof that the same claim holds for the current source, every adopter path, and the whole product. Historical coverage is either rerun without a decision-relevant reason or accepted wholesale without checking the claim, source SHA, environment, age, and limitations.

**Why it happens:** Large audits contain many linked artifacts, repeated command names, and different evidence classes. The v1.37 audit distinguishes prior committed support, present-state verification, exact-SHA hosted evidence, and historical chronology; v1.38's package proof also explicitly opts out of document deletion, index swapping, facets, task listing, and other capabilities outside its scenarios.

**Prevention:** Build one capability-by-evidence matrix. For each user job and claim, link the narrowest authoritative evidence and record source SHA/date, environment, evidence class, relevant scope, freshness/currentness, and known limit. Reuse a passing artifact only for the exact claim it supports. Mark stale or absent proof as a gap or uncertainty, not as failure and not as a pass. Do not rerun a gate unless it answers a decision-relevant freshness, coverage, or regression question.

**Detection:** A claim says “all workflows” while its cited test covers only an upsert; it relies on a prior receipt without identifying its source SHA; a broad matrix duplicates source rows instead of linking to one canonical ledger; or a current test is used to imply historical chronology.

### Pitfall 2: Turning synthetic or source-only proof into real-boundary assurance

**What goes wrong:** Unit stubs, compile checks, workflow-source assertions, or generated artifacts are described as proof of live backend behavior, hosted CI success, external service compatibility, package installation, or historical behavior.

**Why it happens:** Synthetic tests are cheap and valuable but their seam is easy to overstate. Phase 159 records that workflow source cannot prove a hosted successful run, and source/current-state tests cannot reconstruct a pre-extraction test chronology. Phase 160 separates lifecycle-contract assertions from actual package-backed Phoenix scenarios against Postgres and Meilisearch.

**Prevention:** Label evidence by boundary: source/static, unit/property, contract/seam, integration with real service, browser/E2E, or exact-SHA hosted evidence. State exactly what each proves and excludes. Use a more realistic boundary only when the adopter claim crosses it; for published package or release claims, require artifact-backed consumer or exact-SHA hosted evidence where the program says so. Never synthesize evidence for unavailable history, external systems, or user decisions.

**Detection:** A mock-only suite is cited for network/service behavior; workflow YAML assertions are called “CI passed”; local success is presented as exact-SHA hosted proof; or later green tests are used to claim tests passed before an earlier refactor.

### Pitfall 3: Closing important findings without an explicit severity disposition

**What goes wrong:** A Critical, High, or Medium-leverage issue disappears into narrative, is relabeled low without evidence, or remains “known” at closeout without verification or an explicit owner acceptance. This makes a “READY FOR OPERATOR UI” decision unauditable.

**Why it happens:** A readiness program mixes implementation findings, uncertainty, polish ideas, and process limitations. They are easy to conflate, especially when a long candidate list becomes a backlog rather than a disposition ledger.

**Prevention:** Give every confirmed finding an ID, affected adopter job, evidence/provenance, impact/frequency, confidence, compatibility/security/data-integrity risk, implementation/regression/CI cost, severity/leverage, owner, and disposition. Critical/High/Medium findings must be closed with verification or explicitly accepted with rationale and an owner decision before the exit gate passes. Accepted-at-risk does not mean unresolved, and the rationale and decision-maker must remain visible. Give deferred low/speculative items a revisit trigger; delete stale candidates.

**Detection:** The final audit contains open rows without owners or decisions; a severity changes but the evidence does not; an item is deferred “for later” without trigger; or the readiness marker changes while any high/medium-leverage item is unresolved.

## Moderate Pitfalls

### Pitfall 4: Growing the audit into an unbounded cleanup or product expansion

**What goes wrong:** “Whole product” is interpreted as a mandate to fix every rough edge, add new feature families, refactor architecture speculatively, or polish ScrypathOps UI during this non-UI milestone.

**Prevention:** Keep baseline breadth separate from implementation breadth. Assess each named dimension, but plan only evidence-backed, worthwhile non-UI gaps in small independent milestones. Use the explicit scope guard for any candidate runtime/API work; banned capability classes require a separate owner-approved scope change. Leave operator UI work outside this milestone. Preserve a defer/no-change disposition where the case is weak.

**Warning signs:** A candidate is justified only by possibility or taste; an audit row becomes a feature request without adopter evidence; a “completeness” pass starts changing public surface or UI; or the milestone grows without an independent outcome.

### Pitfall 5: Making every useful check a required CI gate

**What goes wrong:** The matrix closes only after all service-backed, browser, compatibility, security, performance, and deep-quality checks run on every change. CI becomes slow, costly, flaky, and less informative, weakening the signal of required gates.

**Why it happens:** A passing run feels like stronger assurance, while setup and maintenance costs are less visible. The project's existing policy deliberately keeps repeatable service/E2E proof advisory or scheduled where the incremental confidence does not warrant merge-blocking cost.

**Prevention:** Map claims to the cheapest reliable layer first. Promote a check to required only when recurrence, risk reduction, stability, and diagnostic value justify runtime and maintenance cost. Otherwise run it locally, on exact-SHA release candidates, scheduled, or advisory. For service checks, automate setup, health checks, isolation, timeouts, diagnostics, and teardown. Record why the lane is required/advisory and what its result means.

**Warning signs:** CI adds overlapping suites with the same claim; long service setup runs before cheap deterministic failures can surface; repeated flakes are retried without diagnosis; or gate promotion is justified by “more testing” without a cost or risk argument.

### Pitfall 6: Leaving routine software acceptance as human-UAT debt

**What goes wrong:** Plans close with “verify manually,” a pending UAT checklist, or a blanket approval checkpoint for routine behavior already testable through deterministic automation. This contradicts the approved zero-routine-human-verification goal and makes milestone completion depend on post-implementation judgment.

**Prevention:** Map every acceptance claim to executable automated evidence before implementation. Use unit/property and contract tests first, then integration, browser/accessibility automation, API probes, or exact-SHA hosted proof as needed. Keep only irreducible external actions (credentials, permissions, unresolved product decisions, physical-world checks) as handoffs. Resolve subjective decisions before implementation or keep them nonblocking; do not simulate a reviewer or approval.

**Warning signs:** UAT rows say “looks good” without a defined oracle; plans require maintainer click-through for repeatable software behavior; a task is considered done before automation is green; or a handoff has no external prerequisite.

### Pitfall 7: Reporting counts and green checks without explaining evidence limits

**What goes wrong:** High requirement/phase counts create confidence while narrow waivers, opt-outs, advisory status, historical artifact overrides, or bounded coverage exclusions are hidden in prose. Readers mistake “30/31 plus waiver” for 31 fully proven requirements or treat “coverage report generated” as adequate test assurance.

**Prevention:** Put limitations next to the score and in each evidence row. Separate requirement coverage from phase artifact completeness, cross-phase integration, representative flows, and hosted proof. Name any waiver precisely, cap its scope, explain why it cannot be reconstructed, and state what it does not claim. Keep the readiness gate fail-closed on unknowns until assessed; do not turn an explicit boundary into a universal guarantee.

**Warning signs:** Summaries have only a numerator; waiver details are buried; evidence classes are collapsed to “supported”; or opt-outs vanish between coverage and milestone audit.

## Minor Pitfalls

### Pitfall 8: Letting the evidence ledger become a permanent speculative backlog

**What goes wrong:** Old candidates survive after their trigger disappears, every audit adds more ideas, and closure becomes an endless polish program rather than a diminishing-return decision.

**Prevention:** Reconcile candidate rows at each milestone boundary against current adopter evidence, release state, and scope. Remove stale entries. Retain deferred items only with a concise reason and a concrete revisit trigger; classify unsupported or low-leverage ideas explicitly.

### Pitfall 9: Duplicating canonical evidence in several artifacts

**What goes wrong:** A copied evidence table drifts from its source and later readers cannot tell which result or limitation controls.

**Prevention:** Maintain one canonical evidence matrix/ledger per assessment and link to it from retrospective indexes, summaries, and audits. Allow summaries to aggregate, but not silently mutate evidence rows. Reconcile cross-references at closeout.

## Phase-Specific Warnings

| Phase topic | Likely pitfall | Mitigation |
|---|---|---|
| Whole-product baseline | Treating v1.37/v1.38 as complete coverage, or rerunning all gates indiscriminately | Map every named dimension and adopter job; reuse only evidence that directly covers the claim; run fresh checks only where decision-relevant. |
| Gap ranking | Mixing confirmed defects, uncertainty, and aspirational features | Maintain separate evidence-ranked findings and opportunity dispositions; use explicit impact, confidence, risk, and cost. |
| Bounded closure | Expanding into public API or banned capability classes | Review scope authority before planning implementation; require evidence and owner approval for scope changes. |
| Verification/CI | Requiring every expensive service/browser check on every PR | Apply cheapest-reliable-layer mapping and recurring-value cost review; preserve advisory/scheduled status when appropriate. |
| Readiness closeout | Hiding accepted risk, waivers, proof gaps, or human-UAT debt behind a green label | Verify all six program exit conditions; leave NOT READY until every dimension is assessed and no Critical/High/Medium-leverage item is unresolved. |

## Sources

- `.planning/reference/PRE-OPERATOR-UI-READINESS.md` — approved sequence, evidence-ranked disposition fields, six-part exit gate, operating rules.
- `.planning/PROJECT.md` — zero-routine-human-verification policy, cheapest reliable evidence layer, CI cost posture, scope guard, v1.37/v1.38 outcomes.
- `.planning/reference/QUALITY-LEDGER.md` — v1.37 finding/risk/churn/verification/disposition ledger and measured diminishing-return boundary.
- `.planning/milestones/v1.37-MILESTONE-AUDIT.md` — bounded 30/31 coverage with a narrow TEST-01 chronology waiver, evidence-class limits, retrospective artifact-shape override, and a corrected hosted lookup false negative.
- `.planning/milestones/v1.37-phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/159-EVIDENCE-MATRIX.md` and `159-CLOSURE-RECEIPT.md` — canonical evidence classes, source/SHA limits, hosted/local boundaries, and exact-SHA closeout.
- `.planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/COVERAGE.md` — explicit integration/opt-out boundary for package-backed Phoenix scenarios.
- `.planning/milestones/v1.38-MILESTONE-AUDIT.md` — package and release flow evidence, exact-SHA and service proof, advisory lane and process notes.
