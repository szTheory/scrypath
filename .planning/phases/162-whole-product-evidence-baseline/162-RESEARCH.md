# Phase 162: Whole-Product Evidence Baseline — Research

**Researched:** 2026-09-25  
**Domain:** Claim-level evidence assessment for the approved non-UI Scrypath product surface  
**Confidence:** HIGH for scope and evidence architecture; MEDIUM for the eventual sufficiency of individual product claims

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use four role lenses and state each role's job in user terms: the first-hour application integrator installs/configures Scrypath and gets a first indexed/search flow working; the application feature owner chooses a sync mode, keeps projected data current, and connects search/hydration to the host context; the production operator/platform owner configures credentials, observes failures/tasks, and diagnoses or recovers drift through retry, reconcile, backfill, or reindex; the library maintainer/releaser keeps docs/support/version claims accurate and proves package/release integrity. Map claims over first-hour setup, indexing, search, failure diagnosis, recovery, upgrade, and release.
- **D-02:** Name the integration seam and claim boundary for each row. The baseline should trace package/toolchain, Ecto schema/context/Repo, Scrypath, optional Oban, Meilisearch, optional Phoenix request-edge integration, and release/support boundaries.
- **D-03:** Treat the downstream searcher as an outcome of the application feature owner's job. The host application owns user authorization, business policy, and presentation; do not imply those are Scrypath guarantees.
- **D-04:** Use a capability-by-evidence matrix linked to canonical evidence. Keep UI, arbitrary host policies, every supported-version cross-product, new runtime/backend/search capability, and capacity/disaster-recovery exercises out of the assessment unless already-backed evidence directly bears on an approved claim. Record limitations without turning them into implicit pass/fail claims or implementation scope.
- **D-05:** Judge evidence against the exact claim it supports, at the cheapest reliable layer. Record source and result, date, commit or immutable hosted receipt, environment and versions where relevant, evidence boundary, what it proves, and known limitations.
- **D-06:** Keep claim assessment separate from evidence freshness. Assess claims as supported, insufficiently supported, or unknown; describe evidence as current, reusable within its stated boundary, stale after a relevant invalidator, or unknown.
- **D-07:** Use event-triggered, claim-specific revalidation. Relevant code/test/config/documentation changes; dependency or supported-version changes; service/protocol changes; package, tag, or release changes; workflow/security changes; incidents; and time-sensitive external assertions can invalidate affected claims. Revalidate narrowly rather than rerunning the whole portfolio.
- **D-08:** Do not use blanket evidence age cutoffs, readiness scores, new required CI lanes, or routine human UAT. Missing or stale proof is not itself a product defect; disclose it as insufficient support or unknown until evidence distinguishes the cause.

### the agent's Discretion
- Choose the most readable artifact structure that preserves one canonical baseline index and links to detailed evidence instead of duplicating it.
- Choose concise identifiers and column names for roles, jobs, claims, boundaries, provenance, freshness, and limitations.
- Select only the narrow inspections or proof reruns needed to resolve a decision-relevant uncertainty, consistent with the approved scope and verification-cost policy.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| BASE-01 | A maintainer can assess every approved non-UI readiness dimension against the relevant adopter or operator jobs and record whether each claim is supported, insufficiently supported, or unknown. | Seven-dimension coverage spine and independent claim-status field below. |
| BASE-02 | A maintainer can trace each reused or newly gathered evidence item to its source, result, date, commit or hosted run and environment where applicable, claim boundary, freshness, and limitations; missing evidence remains explicit rather than being inferred as a pass or defect. | Evidence provenance contract, freshness triggers, and prior-proof limits below. |
| BASE-03 | A maintainer can review the adopter lifecycle from first-hour setup through indexing, search, failure diagnosis, recovery, upgrade, and release using a bounded set of representative roles and integration boundaries, without duplicating canonical evidence. | Four-role/lifecycle seam map and single-index architecture below. |
</phase_requirements>

## Summary

Phase 162 should produce one navigable capability-by-evidence baseline under its phase directory. The seven assessment dimensions are explicitly enumerated by the readiness program, and BASE-01 through BASE-03 are documentation/evidence outcomes rather than runtime implementation requirements. [VERIFIED: .planning/reference/PRE-OPERATOR-UI-READINESS.md:20-31] [VERIFIED: .planning/REQUIREMENTS.md:8-16] The baseline should be a claim index: one row can link several distinct evidence layers, but each row must state its own job, seam, claim, status, freshness, provenance, proof boundary, and limitation. [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:9-39]

Prior v1.37 evidence is bounded to its quality ratchet, including historical chronology limits; v1.38 evidence proves selected package-backed Phoenix flows and release integrity, but the live Phoenix lane is advisory and the package scenario omits document deletion, settings readback, index swap, task listing, facet search, and multi-search. [VERIFIED: .planning/reference/QUALITY-LEDGER.md:1-42] [VERIFIED: .planning/milestones/v1.37-phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/159-EVIDENCE-MATRIX.md:1-26] [VERIFIED: .planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/COVERAGE.md:1-18] [VERIFIED: .planning/milestones/v1.38-MILESTONE-AUDIT.md:32-68] The planner should give the executor a finite claim inventory and a narrow evidence-sufficiency pass; the assessment must not become a new acceptance suite or implementation backlog. [VERIFIED: .planning/reference/PRE-OPERATOR-UI-READINESS.md:20-41]

**Primary recommendation:** Plan a production-quality first tracer through one complete adopter flow and its evidence row, then expand the same row contract across all seven dimensions and four roles; finish with an automated coverage/links consistency check and explicit unknowns. [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:9-39]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Baseline index and claim status | Maintainer documentation | Evidence sources | The phase creates an assessment artifact and links source proof; it changes no runtime contract. [VERIFIED: .planning/REQUIREMENTS.md:8-16] |
| Ecto write, projection, and search outcome | Host application context/Repo | Scrypath, Meilisearch | Contexts own orchestration; Scrypath projects/searches; Meilisearch tasks and visibility cross an asynchronous boundary. [VERIFIED: guides/golden-path.md:77-115] [VERIFIED: guides/sync-modes-and-visibility.md:17-36] |
| Oban synchronization and failure recovery | Host queue/operator | Scrypath, Meilisearch | Queue acceptance and final search visibility require separate claims. [VERIFIED: guides/sync-modes-and-visibility.md:17-36] |
| Request-edge integration | Host Phoenix boundary | Scrypath QueryParams/Phoenix | Optional glue normalizes plain data; contexts own runtime calls, policy, and rendering. [VERIFIED: guides/request-edge-search.md:1-17] |
| Package, support, release truth | Maintainer release workflow | Hex/CI/consumer | Published artifact and exact-SHA receipts prove named outputs, not all adopter deployments. [VERIFIED: .planning/milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md:1-43] |

## Project Constraints (from AGENTS.md)

- Preserve Ecto-first APIs, Phoenix-friendly optional integrations, Meilisearch-first public backend, and the internal adapter seam. [VERIFIED: AGENTS.md:4-18]
- Keep inline, Oban-backed, and manual sync semantics and eventual-consistency, delete, backfill, and reindex boundaries explicit. [VERIFIED: AGENTS.md:12-18]
- Optimize for minimal setup and truthful operational behavior; do not make release or support claims beyond recorded proof. [VERIFIED: AGENTS.md:4-18]
- Consult relevant `prompts/` material for architecture, Elixir/Ecto/Phoenix, OSS release, and positioning; current project/context authority supersedes historical prompt recommendations. [VERIFIED: AGENTS.md:8-8] [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:41-82]
- Keep edits focused, use CONTRIBUTING's applicable checks, keep main green, prefer PR-first for serious work, use executable or exact-SHA hosted proof, and do not invent human UAT or scope. [VERIFIED: AGENTS.md:61-81]
- Relevant prompt guidance supports explicit source-of-truth/projection boundaries, Ecto context ownership, optional Phoenix glue, package consumer proof, and lean CI; these prompts are design background, not current scope authority. [VERIFIED: prompts/meileisearch best practices for scrypath deep research.md:92-105] [VERIFIED: prompts/elixir-opensource-libs-best-practices-deep-research.md:388-449] [VERIFIED: prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:93-197]

## Standard Stack

| Component | Use in this phase | Version/provenance |
|---|---|---|
| Markdown in `.planning/phases/162-whole-product-evidence-baseline/` | Canonical baseline index, linked to existing detailed evidence | Existing repository format; no package installation. [VERIFIED: .planning/research/ARCHITECTURE.md:1-29] |
| Existing Scrypath/Ecto/Oban/Meilisearch/Phoenix source, tests, guides, and CI receipts | Assessment inputs, not new dependencies | Name versions only on a claim's actual evidence receipt. [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:15-35] |
| Existing capability verification commands | Narrow revalidation if a claim-specific invalidator demands it | `mix verify.core`, `mix verify.package`, `mix verify.repository_contracts`, `mix verify.backend`, `mix verify.compatibility`, `mix verify.deep_quality`, and Phoenix path/package commands are documented, with required/advisory posture distinguished. [VERIFIED: CONTRIBUTING.md:30-41] [VERIFIED: CONTRIBUTING.md:139-154] |

**Installation / Package Legitimacy Audit:** None. This assessment should install no external package and should not modify dependency versions. [VERIFIED: .planning/REQUIREMENTS.md:22-34]

## Architecture Patterns

```text
First-hour integrator / feature owner / production operator / maintainer
    -> lifecycle job -> integration seam -> bounded claim
    -> existing source, test, guide, package, or hosted receipt
    -> claim support status + independent evidence freshness + limitation
    -> one canonical baseline index
    -> Phase 163 findings/dispositions -> Phase 164 readiness gate
```

The readiness program is the authority for seven dimensions and its six-condition gate; Phase 162 supplies evidence beneath it. Phases 163 and 164 own findings and readiness respectively. [VERIFIED: .planning/reference/PRE-OPERATOR-UI-READINESS.md:20-67] [VERIFIED: .planning/REQUIREMENTS.md:8-48]

### Seven-dimension coverage spine

Use the exact seven program categories as the row coverage checklist: public API; indexing/search correctness; ecosystem/package seams; operational support; developer experience; security/privacy/release; and architecture/performance/verification cost. This is a shorthand index of the program's verbatim 1–7 dimensions, not new product scope. [VERIFIED: .planning/reference/PRE-OPERATOR-UI-READINESS.md:21-29]

### Row contract

Each claim row should carry: stable claim ID; dimension; named role and user job; lifecycle stage; producer-to-consumer seam; precise assertion; source link and observed result; date; commit or hosted run; environment/version if relevant; evidence class and CI enforcement posture; what it proves; known limits; claim assessment (`supported`, `insufficiently supported`, `unknown`); evidence freshness (`current`, `reusable within boundary`, `stale after invalidator`, `unknown`); and next narrow evidence question if needed. The two quoted status lists are locked verbatim by D-06. [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:15-35]

Do not copy full archived matrices into the baseline. Link the v1.37 Phase 159 matrix for source/present-state/chronology class and the v1.38 coverage, verification, and release receipts for their exact-SHA package/release claims. [VERIFIED: .planning/research/ARCHITECTURE.md:1-29] [VERIFIED: .planning/milestones/v1.37-phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/159-EVIDENCE-MATRIX.md:1-26]

### Representative seam map

| Role/job | Trace through | Key boundary to assess |
|---|---|---|
| First-hour integrator: install and first indexed/search flow | Hex/package + toolchain → Ecto schema/context/Repo → Scrypath inline sync → Meilisearch → context search/hydration | Repo success, backend task success, and searchable visibility are distinct; first-hour guide explicitly says DB and search are not atomic. [VERIFIED: guides/golden-path.md:3-11] [VERIFIED: guides/golden-path.md:81-115] |
| Feature owner: keep projection current and expose search | Ecto context → inline/manual/optional Oban → Scrypath projection/search → Meilisearch → optional Phoenix QueryParams | App owns tenant authorization, policy, and presentation; Scrypath's request-edge helpers do not execute search. [VERIFIED: guides/request-edge-search.md:1-17] [VERIFIED: guides/sync-modes-and-visibility.md:104-118] |
| Operator: diagnose/recover drift | Credentials/config → status/failed work/tasks → retry/reconcile/backfill/reindex → observed search | Report-first diagnosis differs from mutation; task acceptance differs from visible results. [VERIFIED: guides/drift-recovery.md:22-50] [VERIFIED: docs/search-backend-sre.md:9-33] |
| Maintainer: upgrade/release/support | Support guide + compatibility tuples → CI/package → release tag → Hex/HexDocs → consumer | The selected tuple and exact-SHA release prove only their named environments/artifacts. [VERIFIED: CONTRIBUTING.md:139-154] [VERIFIED: .planning/milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md:1-43] |

## Don't Hand-Roll

| Problem | Avoid | Use instead |
|---|---|---|
| Evidence storage | New dashboard/database or duplicate v1.37/v1.38 ledger | One Markdown index with source links and boundary fields. [VERIFIED: .planning/research/ARCHITECTURE.md:1-29] |
| Proof generation | New test harness or broad service rerun | Existing focused tests/capability commands and immutable hosted receipts when claim-specific invalidators require them. [VERIFIED: CONTRIBUTING.md:30-41] [VERIFIED: .planning/reference/PRE-OPERATOR-UI-READINESS.md:60-67] |
| Product issue classification | Convert unknown proof into defect/fix scope | Separate unsupported/unknown assessment from Phase 163 finding disposition. [VERIFIED: .planning/REQUIREMENTS.md:8-27] |

## Common Pitfalls

1. **Milestone pass becomes universal pass:** v1.37's quality ratchet and v1.38's package proof have explicit bounded scopes; preserve per-claim limits. [VERIFIED: .planning/reference/QUALITY-LEDGER.md:1-42] [VERIFIED: .planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/COVERAGE.md:1-18]
2. **Receipt is assigned to a different SHA or environment:** Record the actual run/SHA/service tuple; do not infer current or cross-version behavior from a prior run. [VERIFIED: .planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/160-VERIFICATION.md:1-30]
3. **Advisory success becomes required-gate claim:** Phase 160/161 service proof passed on named runs, while Phoenix example remains advisory in CI. [VERIFIED: .planning/milestones/v1.38-MILESTONE-AUDIT.md:32-68]
4. **Enqueue success becomes search visibility:** Explicitly separate request/enqueue/backend acceptance/task completion/visible search. [VERIFIED: guides/sync-modes-and-visibility.md:17-36]
5. **Missing proof becomes defect or readiness:** Record insufficient/unknown; Phase 164 evaluates the gate, and the readiness program currently states `NOT READY` (verbatim). [VERIFIED: .planning/reference/PRE-OPERATOR-UI-READINESS.md:1-5] [VERIFIED: .planning/REQUIREMENTS.md:17-48]
6. **Historical prompt broadens scope:** Current project/context authority governs; prompt advice is only background. [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:41-82]

## Code Examples

No new application code is recommended. The implementation artifact is a source-linked Markdown matrix. A row's test/command cell must quote the command as recorded in its linked canonical source, not synthesize a new command. Example of an existing source command, quoted verbatim: `mix verify.phoenix_example --package`. [VERIFIED: CONTRIBUTING.md:39-39] That command's result must link the exact hosted receipt and remain bounded to the package scenarios listed in `COVERAGE.md`. [VERIFIED: .planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/COVERAGE.md:1-18]

## Environment Availability

This is an evidence/documentation phase. `gh` and Docker are present, but no live service or runtime execution is required to draft the plan. The `elixir` shim has installed versions but no active version set in this checkout, so a future claim-specific Mix rerun needs explicit toolchain selection. This is an observed command result on 2026-09-25, not a compatibility finding. [VERIFIED: command -v gh/docker; elixir --version output, 2026-09-25] Existing immutable CI receipts are available as linked evidence. [VERIFIED: .planning/milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md:1-43]

## Validation Architecture

| Requirement | Cheapest reliable check for the baseline artifact |
|---|---|
| BASE-01 | Machine-check that all seven dimension identifiers occur with at least one bounded claim and every claim has one of the three statuses; read source-linked claim meaning to judge sufficiency. [VERIFIED: .planning/reference/PRE-OPERATOR-UI-READINESS.md:21-31] |
| BASE-02 | Machine-check required provenance/freshness/limit columns and local link targets; inspect any hosted links only where a decision depends on the receipt. [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:23-35] |
| BASE-03 | Machine-check four role lenses and seven lifecycle stages in the index; inspect seam boundaries for application-owned authorization/presentation and advisory/required CI wording. [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:15-21] |

No new test file, required CI lane, live-service matrix, or package installation is justified by the assessment alone. A lightweight repository-local artifact check may be used during execution if it catches omissions with low maintenance cost. [VERIFIED: .planning/reference/PRE-OPERATOR-UI-READINESS.md:60-67] Existing executable product checks are documented in `CONTRIBUTING.md`; invoke only a focused command when a concrete invalidator makes a linked claim uncertain. [VERIFIED: CONTRIBUTING.md:30-41] The phase gate is a complete baseline index with explicit unknowns, not all product claims marked supported. [VERIFIED: .planning/REQUIREMENTS.md:8-16]

## Security Domain

ASVS 5.0 category naming below follows OWASP's current taxonomy. This is a way to route existing evidence, not a new certification claim. [CITED: https://owasp.org/projects/asvs] [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0]

| ASVS 5.0 area | Baseline relevance |
|---|---|
| Validation/business logic; API/web service | Assess external search/filter/tenant input and backend response handling at Scrypath's boundary; host authorization remains application-owned. [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0] [VERIFIED: guides/request-edge-search.md:1-17] |
| Authorization/authentication/session | Record as host-owned except Scrypath's documented tenant-scope or credential-boundary claims; no broad host security guarantee. [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0] [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:17-21] |
| Configuration/data protection/security logging | Assess API key boundaries, Oban payload persistence, telemetry/error metadata, workflow permissions, and release provenance using the v1.37/1.38 receipts within their scope. [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0] [VERIFIED: .planning/reference/QUALITY-LEDGER.md:5-20] |
| Cryptography | No new cryptographic implementation is proposed; record whether an actual Scrypath-owned claim exists before assigning proof. [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0] |

## Assumptions Log

| # | Claim | Risk if wrong |
|---|---|---|
| A1 | [ASSUMED] A lightweight static link/column check can be implemented without adding a permanent CI job. | Planner should treat it as optional if existing tooling does not support it cheaply. |

## Open Questions

1. Which individual claims have become stale after the last cited SHA? The executor should compare each source and invalidator to current HEAD, then revalidate only decision-relevant rows. [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:23-35]
2. Which important workflow rows have no direct executable or hosted proof? Mark those `insufficiently supported` or `unknown` and pass the evidence question to Phase 163; do not infer defects. [VERIFIED: .planning/REQUIREMENTS.md:8-27]

## Sources

**Primary project authority:** `162-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/reference/PRE-OPERATOR-UI-READINESS.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `AGENTS.md`. [VERIFIED: these files opened 2026-09-25]

**Canonical evidence:** `.planning/reference/QUALITY-LEDGER.md`; v1.37 audit and Phase 159 evidence matrix; v1.38 audit, Phase 160 coverage/verification, Phase 161 release evidence; `CONTRIBUTING.md`. [VERIFIED: these files opened 2026-09-25]

**Lifecycle and architecture guidance:** `guides/jtbd-and-user-flows.md`, `golden-path.md`, `sync-modes-and-visibility.md`, `request-edge-search.md`, `drift-recovery.md`, `docs/search-backend-sre.md`; `.planning/research/ARCHITECTURE.md`, `FEATURES.md`, `SUMMARY.md`; relevant `prompts/` files named in CONTEXT. [VERIFIED: these files inspected 2026-09-25]

**External security taxonomy:** [OWASP ASVS project](https://owasp.org/projects/asvs), [ASVS 5.0 taxonomy](https://cornucopia.owasp.org/taxonomy/asvs-5.0). [CITED: https://owasp.org/projects/asvs] [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0]

## Metadata

- **Confidence:** HIGH for locked scope, seven dimensions, workflow roles, and prior receipt boundaries because current in-repo authority and canonical evidence were opened. MEDIUM for sufficiency of each eventual baseline claim because this research did not perform the whole-product assessment. [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:9-39] [VERIFIED: .planning/reference/PRE-OPERATOR-UI-READINESS.md:20-31]
- **Research date:** 2026-09-25.
- **Freshness:** Event-triggered by D-07, with no blanket age expiry. [VERIFIED: .planning/phases/162-whole-product-evidence-baseline/162-CONTEXT.md:29-35]
