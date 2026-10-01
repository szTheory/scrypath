# Pre-Operator UI Quality Readiness Program

**Status:** ACTIVE PROGRAM — v1.41 scope and roadmap approved 2026-09-28 after requested specialist due diligence
**Readiness:** NOT READY — Phase 167 remains the latest decision (condition 2 FAIL; condition 6 UNKNOWN) until a later dated maintainer comment is published at [issue #86](https://github.com/szTheory/scrypath/issues/86)
**Last assessment:** 2026-09-27, Phase 167 dated readiness review
**Purpose:** Identify and close worthwhile non-UI gaps before ScrypathOps becomes the next strategic focus. Establish an evidence-backed, durable gate for saying the non-UI work has reached diminishing returns.

This program remains the readiness and exit-gate authority after **v1.39 Pre-Operator UI Quality Readiness Ratchet** completed Phases 162–164. Its shipped requirements and roadmap are archived under `.planning/milestones/`. Any follow-up is a separate, owner-approved scope; the program does not itself authorize implementation or operator UI work.

## Current evidence

- **Terminal decision log:** [Pre-Operator UI readiness terminal decision log, issue #86](https://github.com/szTheory/scrypath/issues/86) is the single durable location for future dated maintainer decisions. Phase 167 remains the latest decision until a terminal comment is posted; corrections are appended and identify the decision they supersede. The issue itself makes no readiness judgment and authorizes no UI work.

- **Latest dated assessment:** [Phase 167 dated assessment](../milestones/v1.40-phases/167-dated-readiness-and-closeout/167-ASSESSMENT.md) remains the immutable latest decision: NOT READY at its cutoff, with condition 2 FAIL and condition 6 UNKNOWN. Its tracked Phoenix-lock Mint finding and pending closeout inventory describe that historical cutoff. Later Phase 168 remediation and the current Phase 170 four-graph audit inform a subsequent dated decision; the current audit is clean on the four recorded graphs with Mint 1.11.0 and the newer advisories fixed. These facts do not rewrite Phase 167. See the [current factual input ledger](../phases/170-documentation-and-readiness-closeout/170-READINESS-INPUTS.json).

- **Phase 170 delivery update (2026-10-01):** The selected docs and factual closeout tooling reached public `main` through PR [#87](https://github.com/szTheory/scrypath/pull/87), squash SHA `87d74259a9f569c6b11c8d9481f5465a172c70ba`; its five required checks passed in [run 36795877117](https://github.com/szTheory/scrypath/actions/runs/36795877117). Release Please PR [#83](https://github.com/szTheory/scrypath/pull/83) proposes 0.3.14 and passed the isolated package gate, but the maintainer-authorized normal release path is blocked by the live one-approval branch rule. No GitHub approval, 0.3.14 tag/release, or Hex publication is claimed. Phase 167 remains the latest semantic assessment; Plan 170 has not supplied new six-condition judgments.

- **v1.37 Code Quality Ratchet** covered runtime safety, internal architecture, test/verification commands, CI efficiency, supply chain/release proof, and measured performance. Its ledger found no confirmed compatible high- or medium-leverage issue in that bounded non-UI scope. It did not claim to audit every dimension of adopter or product readiness.
- **v1.38 Packaged Adopter Proof** verified package-backed Phoenix flows, exact-SHA and post-merge CI, Hex/HexDocs, clean consumer compilation, and package-to-tag parity. Scrypath 0.3.13 is published; no human UAT is pending.
- **v1.32–v1.34** provided substantial ScrypathOps operator-flow, design-system, dual-theme, and accessibility work. Additional operator UI work is intentionally sequenced after this program's exit gate and maintainer availability.
- **v1.39 historical assessment** completed the whole-product review with conditions 3 and 6 UNKNOWN. The exact final closeout later passed on `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`; remote tag `v1.39` resolves to that commit. Neither later evidence nor Phase 167 rewrites the historical decision.
- Existing evidence is an input to the baseline, not a reason to rerun every gate or assume every area is complete.

## Program sequence and follow-up

### Completed in v1.39: whole-product non-UI baseline

Review existing code, tests, documentation, planning archives, and hosted evidence. Map important adopter jobs and the failure boundaries they depend on. Assess:

1. Public API consistency, ergonomics, compatibility, and error behavior.
2. Core indexing and search correctness, including writes/deletes, inline/manual/Oban synchronization, related data, tenancy, search, facets, federation, settings, and recovery.
3. Ecto, Oban, Meilisearch, Phoenix, and packaged-consumer seams, including representative supported version/runtime combinations.
4. Operational honesty, observability, backfill/reindex safety, failure reporting, and supportability.
5. First-hour and ongoing developer experience, documentation, examples, diagnostics, and adopter issue intake.
6. Security, privacy, dependency health, configuration boundaries, and release/supply-chain integrity.
7. Architecture, readability, maintainability, measured performance, and test/CI signal-to-cost.

Use a capability-by-evidence matrix. For every area, record relevant user job, existing proof/source, whether proof is sufficient/current, gaps or uncertainty, and disposition. Do not repeat passing tests or re-run service proof without a decision-relevant reason.

### Current follow-through: approved v1.41 after upstream review

Phase 167 is completed and archived locally; its dated result remains NOT READY. v1.41's revised scope and roadmap were approved on 2026-09-28. Phases 168–170 are the approved follow-through: Phase 168 completed the dependency/security work, Phase 169 merged the bounded tenant/facet corrections and completed its PR triage, and Phase 170 is active for docs, release and readiness closeout. See [current synthesis](../research/v1.41/SUMMARY.md) and [roadmap](../ROADMAP.md).

The approved scope uses a finite terminal-decision protocol under the existing exact-SHA rule: finalize tracked inputs/cleanup, attest final source, then publish the separately dated authoritative decision outside the tested tree using all six judgments plus delivery/final receipts. Its durable location is the [Pre-Operator UI readiness terminal decision log, issue #86](https://github.com/szTheory/scrypath/issues/86). The issue establishes the location only; it does not decide readiness or authorize implementation. No READY claim precedes required evidence, and a job attestation alone is not a semantic assessment. Do not write another tracked completion record solely to record that final success.

Reuse the existing seven-dimension/24-claim baseline and explicitly named important workflows with current source-invalidator checks. Material new evidence can reopen scope; arbitrary new probes or routine bot arrivals do not automatically create another milestone. A truthful NOT READY terminal result records concrete blockers and revisit triggers without authorizing a successor or UI work.

Archived navigation: [Phase 162 baseline](../milestones/v1.39-phases/162-whole-product-evidence-baseline/162-BASELINE.md), [Phase 163 findings](../milestones/v1.39-phases/163-findings-and-bounded-follow-up/163-FINDINGS.md), and [Phase 167 assessment](../milestones/v1.40-phases/167-dated-readiness-and-closeout/167-ASSESSMENT.md). The original link text/paths inside historical assessments below remain preserved as part of those dated records.

### Mid term: evidence-ranked gap closure

For each finding, record: evidence and provenance; affected adopter/operator job; impact and frequency; likelihood/confidence; compatibility/security/data-integrity risk; implementation and regression cost; CI runtime/maintenance cost; and recommendation.

- Address critical and high-impact risks first.
- Take medium-leverage improvements when evidence supports the user value and lifecycle cost.
- Group related findings into small GSD milestones with independent outcomes and automated acceptance evidence.
- Defer low-impact, speculative, controversial, or high-churn findings with a concise reason and revisit trigger.
- Consider bounded runtime/API changes when repeated adopter evidence supports them. Review the existing scope authority explicitly; capability classes it prohibits require a separate owner-approved scope change before planning implementation.

### Long term: readiness transition and conditional strategy

When the exit gate below passes, recommend ScrypathOps as the next strategic focus. Later public backend breadth, new runtime categories, autocomplete/suggestions, vector/hybrid retrieval, personalization, analytics, or reusable UI/product surfaces remain conditional on real adopter evidence and explicit scope decisions. Do not treat them as committed roadmap items.

## Diminishing-return exit gate

Keep readiness **NOT READY** until all of the following have evidence in this record or linked artifacts:

1. Every baseline dimension above has been assessed; evidence coverage and known limits are visible.
2. Every critical, high, or medium-leverage finding is closed with verification or explicitly accepted with rationale and an owner decision. There are no unresolved findings at those levels.
3. Important adopter workflows have appropriate automated proof for the claims being made. The goal is zero routine human verification/UAT; external credentials, permissions, product decisions, or physical-world checks are the only expected handoffs.
4. Required CI remains green and lean. Recurring service/E2E proof runs in CI only where its repeat confidence justifies its runtime and maintenance cost; more expensive lower-frequency evidence may remain advisory or scheduled.
5. Remaining non-UI opportunities are low-leverage, speculative, unsupported, or more costly than their likely benefit, each with a recorded disposition.
6. Release, package, support, and planning truth are current, with no task-owned cleanup or verification debt hidden at closeout.

The discoverable pointer to the durable terminal-decision location is the [Pre-Operator UI readiness terminal decision log, issue #86](https://github.com/szTheory/scrypath/issues/86). When all six pass, publish the separately dated **READY FOR OPERATOR UI** decision there, linked to baseline/closure evidence and any accepted risks; do not edit the tracked header afterward solely to record success. Until that terminal record exists, the last dated assessment remains authoritative. This is the point to tell the owner that the non-UI work has reached the agreed diminishing-return threshold. It recommends ScrypathOps as the next focus; maintainer availability and separate scope approval still govern its start.

## Operating rules

- Keep public behavior stable by default. Any proposed compatibility or API change needs evidence, impact analysis, and explicit placement within or change to the scope guard.
- Map acceptance claims before implementation to the cheapest reliable layer: unit/property, contract/seam, integration, smoke/browser/accessibility, or exact-SHA hosted proof.
- Use property-based tests for named high-risk input spaces/invariants where they add meaningful coverage; do not add tests or CI jobs without decision value.
- Shift verification left and automate recurring checks only when recurrence, risk reduction, and diagnostics justify their cost.
- Preserve the green-main, PR-first posture for serious work; release when warranted; clean task-owned worktrees, branches, services, and artifacts.
- Reconcile this record, candidate list, milestone arc, PROJECT, STATE, and retrospective evidence at each milestone boundary. Remove stale candidates rather than building a backlog of imagined work.

## Provenance and related sources

2026-09-28: the maintainer requested parallel upstream due diligence. Current-scope text and archive navigation were refreshed from the three linked v1.41 reviews; the original six exit conditions and historical assessment/cleanup body were preserved. The maintainer approved the revised nine-requirement, three-phase roadmap on 2026-09-28; at that point Phase 168 was ready to plan. The current phase posture and terminal decision pointer are maintained above.

Owner direction captured 2026-09-25 from the adapted Scrypath milestone-ratchet request and follow-up clarification. The owner selected the exit threshold of no unresolved high/medium-leverage non-UI gaps and authorized evidence-backed bounded runtime/API work subject to explicit scope review. The 2026-09-26 follow-up refreshed the reusable milestone guidance, recorded that the owner currently has no time for operator UI, and did not approve a new milestone.

- `.planning/PROJECT.md` — product scope and automation-first verification policy.
- `.planning/STATE.md` — active/idle milestone status and next action.
- `.planning/reference/milestone-candidates.md` — evidence-gated portfolio candidates.
- `.planning/reference/MILESTONE-ARC.md` — near/mid/long posture.
- `.planning/reference/QUALITY-LEDGER.md` and `.planning/milestones/v1.37-*`, `.planning/milestones/v1.38-*` — prior evidence.
- `.planning/milestones/v1.39-REQUIREMENTS.md` and `.planning/milestones/v1.39-ROADMAP.md` — archived v1.39 scope and phase sequence.

## Phase 164 dated assessment — 2026-09-26

This assessment applies the six conditions above without changing their meanings. Evidence dates identify the source receipt or assessment; the separate assessment date records this reconciliation. The structural checker validates record shape only and does not certify source truth, semantic finding judgment, owner approval, or readiness.

| # | Approved condition | Status | Evidence date | Assessment date | Dated linked evidence / receipt + SHA | Boundary, freshness, or limitation |
|---|---|---|---|---|---|---|
| 1 | Every baseline dimension above has been assessed; evidence coverage and known limits are visible. | PASS | 2026-09-25 | 2026-09-26 | [Phase 162 baseline](../phases/162-whole-product-evidence-baseline/162-BASELINE.md) and [Phase 163 findings](../phases/163-findings-and-bounded-follow-up/163-FINDINGS.md) | The seven dimensions and 24 claims have dated evidence dispositions and visible limits. The baseline is reused within its recorded scope; the Phase 163 zero-finding result is not readiness proof. |
| 2 | Every critical, high, or medium-leverage finding is closed with verification or explicitly accepted with rationale and an owner decision. There are no unresolved findings at those levels. | PASS | 2026-09-25 | 2026-09-26 | [Phase 163 findings and disposition summary](../phases/163-findings-and-bounded-follow-up/163-FINDINGS.md) | Phase 163 found no material qualifying findings or candidates under its stated method; no owner decision was requested or inferred. Flagged semantic coverage constraints remain limitations, not owner approval. |
| 3 | Important adopter workflows have appropriate automated proof for the claims being made. The goal is zero routine human verification/UAT; external credentials, permissions, product decisions, or physical-world checks are the only expected handoffs. | UNKNOWN | 2026-09-25 | 2026-09-26 | [Phase 162 claim baseline](../phases/162-whole-product-evidence-baseline/162-BASELINE.md), [Phase 163 residual questions](../phases/163-findings-and-bounded-follow-up/163-FINDINGS.md), and [Phase 161 release evidence](../milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md) | Bounded package and exact-SHA scenarios are reusable for their recorded flows. The baseline retains no live delete-to-visibility receipt (C-09) and no complete repair-to-visible-search receipt (C-16); selected host authorization and settings scenarios also remain bounded. These gaps are not defects, but this record cannot claim all important workflows have adequate proof. |
| 4 | Required CI remains green and lean. Recurring service/E2E proof runs in CI only where its repeat confidence justifies its runtime and maintenance cost; more expensive lower-frequency evidence may remain advisory or scheduled. | PASS | 2026-09-25 | 2026-09-26 | [Successful scheduled main CI run 36105198598](https://github.com/szTheory/scrypath/actions/runs/36105198598) on `325197681c8dea96b8ddb5a46c62cb0d9f85a68f`; [CI workflow](../../.github/workflows/ci.yml) | The current workflow source matches the recorded required/advisory split: core, package, repository contracts, backend, and ecommerce-mounted are required; compatibility, deep-quality, Phoenix example, and path-scoped operator UI are advisory/path-scoped. The cited scheduled run proves only its exact main SHA and workflow execution. |
| 5 | Remaining non-UI opportunities are low-leverage, speculative, unsupported, or more costly than their likely benefit, each with a recorded disposition. | PASS | 2026-09-25 | 2026-09-26 | [Phase 163 claim triage, candidates, and residual questions](../phases/163-findings-and-bounded-follow-up/163-FINDINGS.md) | The 24-claim inventory records zero qualifying follow-up candidates and claim-local revisit triggers. This is the bounded Phase 163 disposition, not an assertion that every evidence gap is resolved. |
| 6 | Release, package, support, and planning truth are current, with no task-owned cleanup or verification debt hidden at closeout. | UNKNOWN | 2026-09-25 | 2026-09-26 | [Phase 161 release/package evidence](../milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md), [Scrypath 0.3.13 release](https://github.com/szTheory/scrypath/releases/tag/scrypath-v0.3.13), [support guide](../../guides/support-and-compatibility.md), [planning state](../STATE.md), and [Phase 164 cleanup inventory](#phase-164-cleanup-and-verification-inventory) | At this dated assessment cutoff, Phase 164's final tracking artifacts and exact-final-SHA closeout were outstanding. The condition remains UNKNOWN in this assessment and requires a separately dated reassessment to change; later closeout evidence does not retroactively change the recorded decision. |

**Unresolved Critical, High, or Medium-leverage findings:** None — Phase 163 records no findings at these ranks within its bounded method.

**Decision:** NOT READY.

The spec-less GATE-01 adjacency, empty-input, and ordering probes, and the unclassified GATE-02 and GATE-03 probes remain flagged assumptions from the plan. They do not redefine the six approved conditions. No explicit or backstop claim is made without checker evidence. P-01 remains descriptor-less and flagged-unverified; structural success is not semantic evidence.

## Phase 164 cleanup and verification inventory

The table records each inspected surface and its phase ownership or remaining debt. Unrelated local state is preserved and excluded from phase-owned debt.

| Surface | Inspection/result | Ownership/debt disposition |
|---|---|---|
| branch/worktree | Existing branch `gsd/v1.38-cleanup-merged` preserved; origin/HEAD was unresolved, so execution degraded to the main checkout; no worktree was created. | None |
| generated outputs | Fixture runs use temporary directories; generated Python cache output is removed after checks. | None |
| temporary files | Fixture temporary directories self-clean; no phase-owned temporary file remains. | None |
| services | No phase-owned service container was started; existing local services and the pre-existing temporary build cache were left untouched because ownership is pre-existing or unestablished. | None |
| verification | At the assessment cutoff, final phase tracking artifacts and the exact-final-SHA closeout were outstanding; the assessment records this debt as UNKNOWN rather than hiding it. | Open at assessment cutoff: final tracking and exact-SHA closeout |
| unrelated state | Pre-existing `.planning/config.json`, `.planning/state.json`, and `.planning/research/.cache/` are preserved. | Unrelated; preserved |

**Task 2 reconciliation:** GitHub lists Scrypath 0.3.13 as latest (published 2026-09-25); the latest observed scheduled main CI run, 36105198598, succeeded on `325197681c8dea96b8ddb5a46c62cb0d9f85a68f`. The Phase 162 source SHA is `f10a9ae0c12c436120d374774de3433ce92e668e`; no changes were found through the current green main SHA in `lib/`, `test/`, `examples/`, `guides/`, `.github/`, `docs/`, `mix.exs`, or `mix.lock`, so no named product/release/support/CI invalidator was observed. Workflow source still identifies five required gates and advisory compatibility/deep-quality/Phoenix lanes; support claims remain limited to Elixir `~> 1.17`, OTP 26–28, and Meilisearch v1.15. The full Phase 163 checker returned `PASS: findings structural contract; claims=24; material=0; candidates=0; proofs=0`; this validates document structure only and does not certify source truth, owner approval, semantic completeness, or readiness.
