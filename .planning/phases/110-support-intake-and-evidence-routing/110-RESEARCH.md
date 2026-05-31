# Phase 110: Support Intake and Evidence Routing - Research

**Researched:** 2026-05-31
**Domain:** Support-intake docs contracts, evidence classification, and service-free verification wiring in an Elixir OSS library
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Evidence Template Shape
- **D-01:** Keep the current Markdown issue template model for Phase 110. Do not migrate to GitHub Issue Forms yet.
- **D-02:** Add a compact required `Evidence Block` to `.github/ISSUE_TEMPLATE/outside-adopter-evidence.md` while preserving short narrative sections for context.
- **D-03:** The evidence block should make Class A-D and routing inputs obvious from the submitted issue. It should include at least path (`repo-clone` vs `hex-package`), runtime support-matrix status, reporter class guess, reporter finding guess, exact Scrypath ref or Hex version, first failing command step, and logs/artifacts.
- **D-04:** Keep reporter burden low. Required structure should reduce back-and-forth, not make early outside adopters feel like they are filing an enterprise support ticket.

### Classification and Routing
- **D-05:** Add a compact routing table or checklist to `guides/outside-adopter-intake.md` that maps evidence class plus finding bucket to maintainer action.
- **D-06:** Classification remains Class A-D:
  - Class A: exact failure on the repo-clone live example path.
  - Class B: Hex-package integration failure inside the explicitly supported runtime matrix.
  - Class C: integration attempt outside the supported runtime matrix.
  - Class D: incomplete evidence, missing context, missing ordered commands, or missing logs.
- **D-07:** Finding buckets remain: Bug in Scrypath, Doc or Contract Gap, App-Side Error, Environment Failure, and Needs Information.
- **D-08:** Maintainer actions should route as follows: Bug in Scrypath to patch-sized bugfix issue; Doc or Contract Gap to docs correction linked to the offending surface; App-Side Error to correction guidance and close as user integration issue; Environment Failure to environment fix request and rerun; Class D or missing proof to needs-info response.
- **D-09:** Mirror the routing vocabulary in the issue template maintainer review block so maintainers can complete review without inventing labels ad hoc.

### Verification Boundary
- **D-10:** Prefer a dedicated `test/scrypath/phase110_contract_test.exs` for SUP-01/SUP-02 assertions.
- **D-11:** Wire the Phase 110 contract test into the existing fast, service-free support verification path, most likely `mix verify.adopter`, rather than adding a new required CI lane.
- **D-12:** Do not add `mix verify.phase110` unless the planner finds that this repo's phase-local command pattern materially improves clarity without gate sprawl. If added, it must stay service-free and must not become a new routine required CI blocker by default.
- **D-13:** Phase 110 verification should assert route authority, absence of duplicated compatibility tuple values on non-owner surfaces, Class A-D coverage, finding bucket coverage, maintainer action coverage, and issue-template evidence block headings.

### Public Surface Scope
- **D-14:** Phase 110 owns core support-routing surfaces: `README.md`, `CONTRIBUTING.md`, `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md`, and `.github/ISSUE_TEMPLATE/outside-adopter-evidence.md`.
- **D-15:** Phase 110 may do a tightly bounded route-only coherence sweep on website/operator entrypoints where support routing is visible, especially `website/src/pages/docs.html`, `website/src/pages/operators.html`, and `docs/operator-support.md`.
- **D-16:** Defer broad website narrative, homepage claim alignment, brand copy rewrites, support-baseline prose rewrites, and any "website as docs site" restructuring to Phase 112.
- **D-17:** Keep `guides/support-and-compatibility.md` as the single compatibility/readiness authority. Other surfaces should link to it and avoid restating version tuple matrices.

### the agent's Discretion
- Planner may choose exact Markdown wording, table layout, and test helper organization as long as the result is concise, deterministic, service-free, and easy for maintainers and adopters to follow.
- Planner may decide whether `test/scrypath/phase110_contract_test.exs` is invoked directly by `verify.adopter` or through another existing support/trust verification alias, provided no new required live/external gate is introduced.
- Planner may include minimal website/operator route-only edits when they remove misleading support-routing ambiguity, but should defer any broader public truth cleanup to Phase 112.

### Deferred Ideas (OUT OF SCOPE)
- Migrating to GitHub Issue Forms is deferred until outside-adopter volume or maintainer load proves Markdown templates are insufficient.
- Adding a new `mix verify.phase110` command is deferred unless planning finds that phase-local command clarity outweighs verify-task sprawl.
- Broad website narrative, homepage claim alignment, public brand copy rewrites, and "website as route map vs second docs site" cleanup belong to Phase 112.
- Any feature-lane reopen, new public runtime surface, autocomplete/suggestions, multi-backend broadening, or proof-lane promotion remains out of scope for Phase 110.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SUP-01 | Adopter-facing docs route support/readiness truth to `guides/support-and-compatibility.md` instead of duplicating compatibility matrices. | File-level route authority assertions and anti-duplication contract checks in `phase110_contract_test.exs`; route-only update scope for README/CONTRIBUTING/intake/operator/website docs. |
| SUP-02 | Maintainer can classify outside-adopter reports as Class A-D and route each finding to bugfix, docs gap, app-side error, environment failure, or needs-info. | Required Evidence Block headings in issue template + explicit Class A-D x finding-bucket routing table/checklist in intake guide + maintainer review block vocabulary parity tests. |
</phase_requirements>

## Summary

Phase 110 should be implemented as a docs-contract hardening slice, not as a new product or CI governance lane. Current repo patterns already support this: support/readiness authority is centralized in `guides/support-and-compatibility.md`, evidence intake is centralized in `guides/outside-adopter-intake.md` plus `.github/ISSUE_TEMPLATE/outside-adopter-evidence.md`, and fast service-free support verification is already established under `mix verify.adopter`. [VERIFIED: codebase grep]

The planner should minimize moving parts: update five core support surfaces, optionally apply route-only wording fixes in website/operator entrypoints, add one new focused contract test file, and wire it into `mix verify.adopter` fast mode. Do not create a new required CI job and do not pull broad website truth alignment from Phase 112. [VERIFIED: codebase grep]

**Primary recommendation:** implement `SUP-01`/`SUP-02` by adding `test/scrypath/phase110_contract_test.exs` and extending `verify.adopter` fast test list to include it, while keeping docs route-first and compatibility matrix single-sourced. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Keep Scrypath Ecto-first and Phoenix-friendly; ecosystem fit is central. [CITED: ./AGENTS.md]
- Preserve Meilisearch-first v1 positioning and avoid public multi-backend abstraction promises. [CITED: ./AGENTS.md]
- Keep inline, Oban-backed, and manual sync support explicit in docs posture. [CITED: ./AGENTS.md]
- Prioritize minimal setup and Phoenix ergonomics without hiding operational realities. [CITED: ./AGENTS.md]
- Keep operational semantics explicit (eventual consistency, deletes, backfills, reindex). [CITED: ./AGENTS.md]
- Keep release quality high; avoid rushed, low-quality surface changes. [CITED: ./AGENTS.md]
- Follow CONTRIBUTING verification posture and lean required gates on green `main`. [CITED: ./AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Route authority for support/readiness docs | Documentation layer (repo markdown) | Test layer | Source-of-truth ownership is doc content, enforced by contracts. |
| Evidence intake normalization (Class A-D inputs) | GitHub issue template | Intake guide docs | Reporter-provided structure comes from template; semantics come from guide. |
| Finding-bucket to maintainer-action routing | Intake guide docs | Template maintainer block | Routing taxonomy is maintainer policy text mirrored in template. |
| Drift prevention for support claims | ExUnit contract tests | `mix verify.adopter` mix task | Existing service-free fast lane already owns support contract checks. |
| Public route-only coherence (website/operator entrypoints) | Website/static docs pages | Canonical support/intake guides | Entry pages should link to canonical surfaces, not duplicate policy matrices. |

## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| Elixir | 1.19.5 (local), support floor `~> 1.17` | Test/mix task execution for contract checks | Existing project baseline and support contract authority. [VERIFIED: codebase grep] |
| ExUnit | bundled with Elixir | Contract assertions on docs/template tokens and ordering | Existing phase/readiness/docs contract pattern uses ExUnit file-read assertions. [VERIFIED: codebase grep] |
| Mix task `verify.adopter` | repo-local | Fast service-free adopter support contract gate | Already established support verification surface; avoids new lane sprawl. [VERIFIED: codebase grep] |

### Supporting
| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| GitHub markdown issue template | repo-local `.github/ISSUE_TEMPLATE` | Structured adopter evidence intake | Use for required Evidence Block + maintainer review vocabulary parity. [VERIFIED: codebase grep] |
| Existing contract suites (`readiness`, `phase98`, `phase99`, `docs_contract`) | repo-local | Pattern references for token and route assertions | Reuse helper style and assertion shape for `phase110_contract_test.exs`. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend `verify.adopter` fast tests | Add `mix verify.phase110` | Extra command and potential gate sprawl; conflicts with locked preference for minimal process unless clarity gain is proven. [VERIFIED: codebase grep] |
| Markdown template + required Evidence Block | GitHub Issue Forms | Better structured UI but deferred by locked decision D-01/D-04 for low-bureaucracy early adopter flow. [CITED: .planning/phases/110-support-intake-and-evidence-routing/110-CONTEXT.md] |

## Package Legitimacy Audit

Not applicable for Phase 110: no new third-party package installation is required to satisfy `SUP-01`/`SUP-02`. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Outside adopter report
        |
        v
Issue template (required Evidence Block) ---> Missing fields? ---> Class D -> Needs-info response
        |                                                |
        | complete evidence                              v
        v                                       rerun with required evidence
Classify A/B/C + finding bucket
        |
        v
Routing table in outside-adopter-intake guide
        |
        +--> Bug in Scrypath ------> patch-sized bugfix issue
        +--> Doc/Contract Gap -----> docs correction issue
        +--> App-Side Error -------> guidance + close
        +--> Environment Failure --> env fix request + rerun
        |
        v
Contract tests assert wording/routing parity
        |
        v
mix verify.adopter (fast, service-free) enforces drift gate
```

### Recommended Project Structure

```text
guides/
├── support-and-compatibility.md      # single support/readiness authority
├── outside-adopter-intake.md         # class/bucket/routing policy
.github/ISSUE_TEMPLATE/
└── outside-adopter-evidence.md       # evidence intake form
test/scrypath/
└── phase110_contract_test.exs        # SUP-01/SUP-02 enforcement
lib/mix/tasks/
└── verify.adopter.ex                 # fast gate wiring for phase110 contract
```

### Pattern 1: Route-First Authority With Contract Assertions
**What:** Non-authority surfaces (README/CONTRIBUTING/website/operator docs) link to canonical support/intake guides instead of restating matrices or class/routing policy.  
**When to use:** Any public wording update touching support claims or adopter troubleshooting.  
**Example:** token-based assertions in `test/scrypath/readiness_contract_test.exs` and `test/scrypath/phase99_contract_test.exs` that verify route links and fast/live command parity. [VERIFIED: codebase grep]

### Pattern 2: Thin Verify Task, Explicit Test List
**What:** Mix task orchestrates explicit test files, rejects argument drift, and keeps fast vs live behavior explicit.  
**When to use:** Support-truth checks that must stay deterministic and service-free by default.  
**Example:** `@fast_tests` in `lib/mix/tasks/verify.adopter.ex` currently lists readiness + task tests; Phase 110 should append phase110 contract test there. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid

- Duplicating compatibility tuple matrices outside `guides/support-and-compatibility.md`. [CITED: .planning/REQUIREMENTS.md]
- Adding a mandatory new CI job/phase task for support-hardening when existing fast gate can absorb checks. [CITED: .planning/phases/110-support-intake-and-evidence-routing/110-CONTEXT.md]
- Pulling homepage/website narrative rewrites from Phase 112 into this phase. [CITED: .planning/ROADMAP.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Support verification orchestration | New custom gate pipeline/job | Existing `mix verify.adopter` fast path | Existing lane is already service-free and documented; lower maintenance and no gate sprawl. [VERIFIED: codebase grep] |
| Evidence taxonomy | New ad hoc labels per issue | Existing Class A-D + finding buckets | Taxonomy already codified in intake guide and tests; preserve consistency. [VERIFIED: codebase grep] |
| Compatibility authority duplication | Multi-surface matrix copy | Single-source support guide links | Reduces drift and contradictory claims across surfaces. [VERIFIED: codebase grep] |

**Key insight:** This phase succeeds by tightening current contracts, not by introducing new workflow machinery. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Taxonomy Drift Between Intake Guide and Issue Template
**What goes wrong:** Maintainer review fields and reporter inputs use mismatched terms, forcing manual interpretation.  
**Why it happens:** Template edits without paired contract tests.  
**How to avoid:** Assert required Evidence Block headings and maintainer review vocabulary in `phase110_contract_test.exs`; keep same token set as intake routing table.  
**Warning signs:** Terms like `needs-info` appear in one surface but not the other.

### Pitfall 2: Route Authority Erosion
**What goes wrong:** README/CONTRIBUTING/website start restating compatibility tuples, creating drift risk.  
**Why it happens:** Convenience edits on entrypoint docs.  
**How to avoid:** Assert route links to `guides/support-and-compatibility.md` and assert absence of tuple duplication on non-owner surfaces.  
**Warning signs:** Version tuple edits required in >1 file for support policy changes.

### Pitfall 3: Verify Task Proliferation
**What goes wrong:** Adds `verify.phase110` despite no operational need, increasing maintenance burden.  
**Why it happens:** Phase-number symmetry bias.  
**How to avoid:** Keep phase110 tests under `verify.adopter` fast tests unless a concrete clarity gap is demonstrated.  
**Warning signs:** New command appears without corresponding required-check policy.

## Code Examples

### Fast adopter verify wiring pattern
```elixir
@fast_tests [
  "test/scrypath/readiness_contract_test.exs",
  "test/mix/tasks/verify_adopter_test.exs"
]
```
Source: `lib/mix/tasks/verify.adopter.ex` [VERIFIED: codebase grep]

### Contract assertion style for support routes
```elixir
assert String.contains?(@readme, "guides/support-and-compatibility.md")
assert String.contains?(@contributing, "guides/support-and-compatibility.md")
```
Source: `test/scrypath/readiness_contract_test.exs` [VERIFIED: codebase grep]

### Classification/routing token anchors
```elixir
assert_contains_all(@intake_guide, [
  "Class A",
  "Class B",
  "Class C",
  "Class D",
  "Bug in Scrypath",
  "Doc or Contract Gap",
  "App-Side Error",
  "Environment Failure"
])
```
Source: `test/scrypath/phase98_contract_test.exs` [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ad hoc support guidance spread across surfaces | Single support/readiness authority + route-first docs contracts | Prior trust-hardening phases through 99 | Lower drift risk and clearer maintainer/adopter routing. [VERIFIED: codebase grep] |
| Broad docs quality checks without explicit adopter lane command | Explicit `mix verify.adopter` fast/live split | Existing current baseline | Keeps default support checks service-free while preserving live proof path. [VERIFIED: codebase grep] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `website/src/pages/index.html` does not require Phase 110 edits because current support/intake routing is not misleading. [ASSUMED] | Common Pitfalls / scope fences | Could miss a small route-only ambiguity that should be fixed now. |

## Open Questions

1. **Should `phase110_contract_test.exs` also be listed in any phase-local verify task?**
   - What we know: locked decision prefers `verify.adopter` integration and avoids new required lane.
   - What's unclear: whether maintainers still want an optional `verify.phase110` convenience command.
   - Recommendation: plan for `verify.adopter` integration only; add optional `verify.phase110` only if planner can justify no-sprawl ergonomics.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Running contract tests | ✓ | 1.19.5 | — |
| Mix | Running verify task and tests | ✓ | 1.19.5 | — |
| Git | Repo diff/verification workflows | ✓ | 2.41.0 | — |

**Missing dependencies with no fallback:**
- none

**Missing dependencies with fallback:**
- none

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/scrypath/phase110_contract_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SUP-01 | Route support/readiness authority to canonical guide; prevent tuple duplication drift on non-owner docs | unit (docs contract) | `mix test test/scrypath/phase110_contract_test.exs -x` | ❌ Wave 0 |
| SUP-02 | Evidence block and class/bucket/action routing classification is fully inferable without maintainer guessing | unit (docs/template contract) | `mix test test/scrypath/phase110_contract_test.exs -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/scrypath/phase110_contract_test.exs`
- **Per wave merge:** `mix verify.adopter`
- **Phase gate:** `mix verify.adopter` green

### Wave 0 Gaps
- [ ] `test/scrypath/phase110_contract_test.exs` - SUP-01/SUP-02 assertions
- [ ] `lib/mix/tasks/verify.adopter.ex` - append phase110 contract test in `@fast_tests`
- [ ] `test/mix/tasks/verify_adopter_test.exs` - assert `@fast_tests` includes phase110 test token

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A (docs/test-only phase) |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A |
| V5 Input Validation | yes | Required evidence fields and explicit classification vocabulary in template/guide contracts |
| V6 Cryptography | no | N/A |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Incomplete/misleading bug reports | Tampering | Required Evidence Block + Class D needs-info routing |
| Misclassification due to ambiguous intake language | Repudiation | Canonical Class A-D and finding bucket tokens asserted by contract tests |
| Policy drift across docs surfaces | Information disclosure / integrity drift | Single-source authority links + anti-duplication assertions |

## Sources

### Primary (HIGH confidence)
- `./.planning/phases/110-support-intake-and-evidence-routing/110-CONTEXT.md` - locked decisions, scope, deferred ideas
- `./.planning/REQUIREMENTS.md` - SUP-01/SUP-02 normative requirement text
- `./.planning/ROADMAP.md` - Phase 110 goal/success criteria and Phase 112 boundary
- `./lib/mix/tasks/verify.adopter.ex` - fast/live verify wiring pattern
- `./test/scrypath/readiness_contract_test.exs` - current support route contract assertions
- `./test/scrypath/phase98_contract_test.exs` - class/bucket token assertions
- `./guides/support-and-compatibility.md` - support/readiness authority posture
- `./guides/outside-adopter-intake.md` - class/bucket/routing semantics
- `./.github/ISSUE_TEMPLATE/outside-adopter-evidence.md` - current intake fields and maintainer block
- `./README.md`, `./CONTRIBUTING.md`, `./docs/operator-support.md`, `./website/src/pages/docs.html`, `./website/src/pages/operators.html`, `./website/src/pages/index.html` - current public route surfaces

### Secondary (MEDIUM confidence)
- `./prompts/elixir-opensource-libs-best-practices-deep-research.md` - OSS library design posture references
- `./prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - lean-gate and release-process posture references
- `./prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - system design posture references
- `./prompts/scrypath-brand-book.md` - voice/route-first communication posture

### Tertiary (LOW confidence)
- none

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies; direct reuse of existing mix/test/doc stack.
- Architecture: HIGH - decisions are locked in CONTEXT and reinforced by existing code patterns.
- Pitfalls: HIGH - based on existing contract tests and prior phase trust-hardening pattern.

**Research date:** 2026-05-31  
**Valid until:** 2026-06-30

