# Phase 112: Public Website and Docs Truth Alignment - Research

**Researched:** 2026-06-01  
**Domain:** Public claim governance, route-first documentation architecture, and service-free docs contract verification for an Elixir OSS library [CITED: .planning/ROADMAP.md]  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Public Claim Envelope
- **D-01:** Use a fixed public claim envelope across website, README, guides, and public docs. The canonical first mention should be equivalent to: `Scrypath, the Ecto-native search indexing library`.
- **D-02:** Allow page-specific supporting copy only inside a controlled vocabulary: Ecto-native, Phoenix/Ecto teams, search indexing, search orchestration, Meilisearch-first v1, explicit sync, inline/Oban/manual sync modes, operational visibility, drift/recovery, route map, README, guides, examples, Hex, and GitHub.
- **D-03:** Public copy must not imply hosted search, AI search, magic callbacks, public multi-backend v1 support, hidden automatic sync, or immediate search visibility after accepted async work.
- **D-04:** Prefer plain, precise OSS library language over softer marketing copy plus disclaimers. Disclaimers are not a substitute for truthful headings and first-screen claims.

### Website Route-Map Depth
- **D-05:** Keep `website/` as curated journey pages with short summaries and deep links. The website should help evaluators choose the right route by job-to-be-done, not reproduce guide bodies.
- **D-06:** Existing pages such as `website/src/pages/index.html`, `website/src/pages/docs.html`, `website/src/pages/operators.html`, and `website/src/pages/evaluate.html` are the right shape: route/decision surfaces that point to README, guides, examples, Hex, GitHub, and support authorities.
- **D-07:** Do not add rich standalone website docs or long tutorials. If implementation needs more detail than a short summary, put it in README, a guide, docs, HexDocs, or an example README and link to it.
- **D-08:** Route-map copy should stay user-friendly and useful: short "what this is for", "when to use it", and "where to go next" text is allowed; step-by-step operational instructions belong in canonical docs.

### Scope Guard and Reopen Policy
- **D-09:** Add one canonical scope/reopen policy guide, recommended path `guides/scope-and-reopen-policy.md`, and link to it from README, `website/src/pages/evaluate.html`, and relevant support/intake surfaces.
- **D-10:** Keep website fit/non-fit language concise and factual. Avoid turning the homepage or Evaluate page into the full policy authority.
- **D-11:** The policy guide should state that future feature-lane work reopens only for one of three triggers: concrete production bug, reviewed outside-adopter evidence, or deliberate strategic product decision.
- **D-12:** The policy guide should explicitly preserve current out-of-scope classes: hosted search, AI/vector/hybrid positioning, autocomplete/suggestions as a first-class product surface, public multi-backend v1 support, magic callbacks, framework facade behavior, and new public runtime API categories.
- **D-13:** Reopen decisions should route through the existing outside-adopter evidence lane where possible, so policy stays evidence-backed instead of preference-driven.

### Verification Shape
- **D-14:** Add focused Phase 112 contract proof rather than a broad repo-wide negative-token scanner or checklist-only policy.
- **D-15:** Preferred implementation: `test/scrypath/phase112_contract_test.exs` plus a service-free `mix verify.phase112` task, following Phase 110 and Phase 111 contract-test patterns.
- **D-16:** Contract proof should assert positive route/claim tokens across the targeted public surfaces and refute specific misleading claim families on those same surfaces.
- **D-17:** Keep assertions precise enough to avoid noisy false positives. Target public surfaces and canonical policy docs; do not scan historical planning archives, quoted issue text, or unrelated implementation tests.

### the agent's Discretion
- Planner may choose exact wording, file organization, and token assertions as long as the claim envelope, route-map boundary, scope policy, and service-free proof are preserved.
- Planner may decide whether `mix verify.phase112` is standalone or also wired into an existing lean truth gate, provided it does not introduce live services, browser automation, or external credentials.
- Planner may update website page text where current wording drifts from the claim envelope, but broad visual redesign and new website information architecture are out of scope.

### Deferred Ideas (OUT OF SCOPE)
- Rich standalone website docs are deferred. If demand appears, revisit only with a synchronization strategy that does not undermine README/guides/HexDocs authority.
- Broad repo-wide public-claim scanners are deferred because false positives and allowlists would likely create lower-signal maintainer friction than focused contract tests.
- Website visual redesign, new landing-page information architecture, and SEO expansion are deferred; Phase 112 is truth alignment, not marketing-site expansion.
- New product breadth remains deferred: hosted search, AI/vector/hybrid positioning, autocomplete/suggestions as a first-class product surface, public multi-backend v1 support, magic callback runtime, new public runtime APIs, and framework facade behavior.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WEB-01 | Public website/docs consistent Ecto-native positioning; no misleading claims | Claim-family contract matrix and negative assertions scoped to public surfaces |
| WEB-02 | Website remains route map, not second docs site | Route-depth boundary and front-door copy rules per page |
| SCOPE-01 | Reopen policy remains explicit and evidence-gated | Canonical `scope-and-reopen-policy` authority and link-routing plan |
</phase_requirements>

## Summary

Current public surfaces are already close to target shape: README and website pages mostly use Ecto-native language, Meilisearch-first boundaries, and accepted-work visibility honesty. Drift risk is not “missing architecture”; it is gradual copy drift and authority drift across multiple route surfaces. [CITED: README.md] [CITED: website/src/pages/index.html] [CITED: website/src/pages/evaluate.html] [CITED: website/src/pages/operators.html]

Phase 112 should be implemented as a focused docs-contract slice: tighten wording where needed, add one canonical scope/reopen policy guide, and lock the claim envelope with a service-free contract test plus `mix verify.phase112`. Reuse existing Phase 110/111 patterns: direct file reads, positive token checks, targeted negative checks, and no broad scanners. [CITED: test/scrypath/phase110_contract_test.exs] [CITED: test/scrypath/phase111_contract_test.exs] [CITED: lib/mix/tasks/verify.phase108.ex]

**Primary recommendation:** Implement a narrow, high-signal Phase 112 contract suite that checks explicit claim families and route links only on canonical public files, then run it through `mix verify.phase112` with no service dependencies. [CITED: .planning/phases/112-public-website-and-docs-truth-alignment/112-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public positioning copy governance | Documentation/content files | Website static pages | Truth is authored in markdown/html artifacts, not runtime code paths |
| Route-map behavior (front door vs duplicated docs) | Website static pages | README/guides authority docs | Website should link out; canonical detail remains in guides/README |
| Scope-reopen policy authority | Guides (`guides/`) | README/evaluate/support route links | Single source avoids fragmented policy text |
| Regression protection for public-claim drift | ExUnit contract tests | Mix verify task orchestration | Existing repo pattern uses file-read tests + phase verify wrapper |

## Project Constraints (from AGENTS.md)

- Keep Scrypath positioned as an Elixir OSS library with Ecto-first APIs and Phoenix-friendly ergonomics. [CITED: AGENTS.md]
- Preserve Meilisearch-first public v1 posture and avoid public multi-backend abstraction promises. [CITED: AGENTS.md]
- Preserve supported write-path framing: inline, Oban-backed, and manual sync with explicit tradeoffs. [CITED: AGENTS.md]
- Keep operational honesty explicit (eventual consistency, delete semantics, backfills, reindex workflows). [CITED: AGENTS.md]
- Maintain maintenance/evidence-mode scope guard; do not reopen feature breadth without explicit evidence triggers. [CITED: .planning/PROJECT.md] [CITED: .planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.17` support floor | docs/test/verify implementation surface | Existing repo floor and contributor tooling already centered on this |
| ExUnit | bundled | contract tests for docs/public surfaces | Existing phase contract pattern uses ExUnit file-read assertions |
| Mix tasks | bundled | focused phase verification command | Existing `verify.phase*` tasks are thin orchestration wrappers |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExDoc (`mix docs`) | `~> 0.37` (dev/test dep) | docs warnings-as-errors follow-up | Include only if phase task is intended to gate docs build as in prior truth tasks |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Focused phase contract test | repo-wide scanner | Scanner has high false-positive noise and requires brittle allowlists |
| `verify.phase112` narrow suite | only `docs_contract_test` expansion | Global docs suite is broader/slower and obscures phase-specific failures |

## Architecture Patterns

### System Architecture Diagram

```text
Public files (README + website + guides + docs)
        |
        v
Phase 112 contract test (positive tokens + negative claim-family checks + route-link checks)
        |
        v
mix verify.phase112 (service-free task wrapper)
        |
        v
Contributor/CI execution as focused truth gate
```

### Recommended Project Structure

```text
guides/
  scope-and-reopen-policy.md   # canonical policy authority (new)
website/src/pages/
  evaluate.html                # concise policy route link
  index.html/docs.html/operators.html  # route-map language alignment
test/scrypath/
  phase112_contract_test.exs   # focused claim + route assertions
lib/mix/tasks/
  verify.phase112.ex           # phase wrapper task
test/mix/tasks/
  verify.phase112_test.exs     # task wiring self-test
```

### Pattern 1: Focused Public Claim Contract
**What:** Direct file-read assertions across a bounded list of public surfaces.  
**When to use:** Any maintenance phase enforcing truth alignment without runtime changes.  
**Example:**
```elixir
@readme File.read!("README.md")
@evaluate File.read!("website/src/pages/evaluate.html")

test "rejects misleading claim families on public surfaces" do
  refute String.contains?(@readme, "AI search")
  assert String.contains?(@evaluate, "hosted search")
end
```
Source pattern: [CITED: test/scrypath/phase110_contract_test.exs]

### Pattern 2: Thin `verify.phase*` Orchestration Task
**What:** No-args task that starts app, runs focused tests, and reports one phase-specific label.  
**When to use:** Add deterministic phase verification without introducing CI sprawl.  
**Example:** [CITED: lib/mix/tasks/verify.phase108.ex]

### Anti-Patterns to Avoid

- **Repo-wide negative token scanning:** catches unrelated archives/tests and becomes noisy. [CITED: .planning/phases/112-public-website-and-docs-truth-alignment/112-CONTEXT.md]
- **Website-doc duplication:** turning `website/` into long-form docs creates drift against guides. [CITED: .planning/REQUIREMENTS.md]
- **Policy text fragmentation across pages:** weakens scope guard and reopen discipline.

## Don’t Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public truth drift detection | custom scanner engine | ExUnit file-read contract tests | Existing, proven, deterministic project pattern |
| Phase gate orchestration | bespoke scripts | Mix `verify.phase*` task module | Matches current contributor ergonomics and CI style |
| Reopen-policy distribution | repeated policy prose everywhere | one canonical guide + links | Keeps authority single-sourced and maintainable |

## Current State and Drift Points

1. Core position already present in README first mention (`Scrypath, the Ecto-native search indexing library`). [CITED: README.md]
2. Website pages already function as concise route maps, not full tutorials. [CITED: website/src/pages/docs.html]
3. Evaluate page already rejects hosted search/magic callbacks/multi-backend-v1 expectations. [CITED: website/src/pages/evaluate.html]
4. Operators page already encodes accepted-work-vs-visibility truth. [CITED: website/src/pages/operators.html]
5. Highest-likelihood drift points: adjective creep in hero text, duplicated policy snippets, and inconsistent reopen trigger language across README/evaluate/support/intake surfaces. [ASSUMED]

## Public Claim Families (Assert Positively and Negatively)

### Positive families (must be present on targeted surfaces)

- **Identity family:** Ecto-native search indexing library for Phoenix/Ecto teams. [CITED: README.md]
- **Backend family:** Meilisearch-first v1; internal backend seam not public multi-backend promise. [CITED: README.md] [CITED: guides/support-and-compatibility.md]
- **Sync honesty family:** inline/manual/Oban modes and accepted-work != visible-search semantics. [CITED: guides/sync-modes-and-visibility.md] [CITED: website/src/pages/operators.html]
- **Route-map family:** website routes to README/guides/examples/Hex/GitHub instead of duplicating guide bodies. [CITED: website/src/pages/index.html] [CITED: website/src/pages/docs.html]
- **Scope policy family:** explicit feature-lane reopen triggers and out-of-scope guardrails via canonical policy guide. [CITED: .planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md]

### Negative families (must be absent from targeted surfaces unless explicitly negated as “not”)

- Hosted/SaaS search product implication.
- AI/vector/hybrid positioning implication.
- Magic callbacks/hidden automatic sync implication.
- Public multi-backend v1 parity implication.
- Immediate visibility implication after async acceptance/enqueue.

Negative checks should be phrase-targeted and surface-scoped to avoid false positives from quoted cautions or historical artifacts. [CITED: .planning/phases/112-public-website-and-docs-truth-alignment/112-CONTEXT.md]

## Scope/Reopen Policy Boundaries and Linking

- Create `guides/scope-and-reopen-policy.md` as canonical authority containing:
  - three reopen triggers;
  - current banned capability classes;
  - routing through outside-adopter evidence lane. [CITED: .planning/phases/112-public-website-and-docs-truth-alignment/112-CONTEXT.md] [CITED: guides/outside-adopter-intake.md]
- Link to this guide from:
  - README (compact “scope and reopen policy” pointer);
  - `website/src/pages/evaluate.html` (fit/non-fit decision continuity);
  - `guides/outside-adopter-intake.md` and/or `guides/support-and-compatibility.md` (evidence-routing continuity). [CITED: .planning/phases/112-public-website-and-docs-truth-alignment/112-CONTEXT.md]

## Website-as-Front-Door Guidance

- Keep website copy at “decision summary” depth: what this is for, when to use, where next.
- Route anything procedural (setup, troubleshooting, operational sequence) to canonical docs/guides/examples.
- Preserve page roles:
  - `index.html`: positioning + top routes;
  - `docs.html`: guide map by task;
  - `operators.html`: recovery/visibility route;
  - `evaluate.html`: fit/non-fit and scope expectations. [CITED: website/src/pages/index.html] [CITED: website/src/pages/docs.html] [CITED: website/src/pages/operators.html] [CITED: website/src/pages/evaluate.html]

## Reusable Verification Patterns for Phase 112

1. **Direct file module attributes + helper assertions** from Phase 110 contract style. [CITED: test/scrypath/phase110_contract_test.exs]
2. **Policy consistency checks across planning/docs/contributor surfaces** from Phase 111 style. [CITED: test/scrypath/phase111_contract_test.exs]
3. **Focused mix task wrapper with `ensure_no_args!`** from `verify.phase108`. [CITED: lib/mix/tasks/verify.phase108.ex]
4. **Task-wiring test style** under `test/mix/tasks/*` for alias/preferred_env/command presence. [CITED: test/mix/tasks/workflow_wiring_test.exs]

Recommended `mix verify.phase112` focused tests:

- `test/scrypath/phase112_contract_test.exs`
- `test/mix/tasks/verify.phase112_test.exs`

Optional inclusion decision:

- Keep standalone for clarity, or include inside `verify.phase99` only if scope trust lane ownership is intentionally expanded. [CITED: lib/mix/tasks/verify.phase99.ex]

## Risks and Pitfalls

### Pitfall 1: Noisy “forbidden words” scanner
**What goes wrong:** hits historical/planning/test text and blocks unrelated work.  
**How to avoid:** scope checks to explicit public files only and pair negatives with required positive truths.

### Pitfall 2: Authority drift
**What goes wrong:** reopen policy exists in multiple slightly different phrasings.  
**How to avoid:** single canonical policy guide + link assertions.

### Pitfall 3: Website content inflation
**What goes wrong:** guide-like procedural text creeps into `website/`.  
**How to avoid:** front-door budget per page (summary + route links only).

## Recommended Plan Split / Waves (for planner)

1. **Wave 1: Canonical policy and copy alignment**
   - Add scope/reopen guide.
   - Patch README + evaluate/support/intake route links.
   - Tighten any drift language on website pages.
2. **Wave 2: Contract proof**
   - Add `phase112_contract_test`.
   - Add `verify.phase112` + self-test + `preferred_envs` registration.
3. **Wave 3: Wiring and guard confirmation**
   - Decide standalone invocation vs inclusion in existing trust lane.
   - Run focused verification command and confirm deterministic output.

Rationale: content authority should land before tests, so assertions reflect intended canon rather than locking drift. [ASSUMED]

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified). Phase 112 is docs/website copy plus service-free ExUnit/Mix task work in existing toolchain. [CITED: .planning/ROADMAP.md]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Mix test) |
| Config file | `test/test_helper.exs` (project standard) [ASSUMED] |
| Quick run command | `mix test test/scrypath/phase112_contract_test.exs test/mix/tasks/verify.phase112_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WEB-01 | Public claim envelope consistent and misleading claim families rejected | unit/docs-contract | `mix test test/scrypath/phase112_contract_test.exs` | ❌ Wave 0 |
| WEB-02 | Website remains route map with canonical doc links | unit/docs-contract | `mix test test/scrypath/phase112_contract_test.exs` | ❌ Wave 0 |
| SCOPE-01 | Reopen policy authority + trigger language explicit | unit/docs-contract | `mix test test/scrypath/phase112_contract_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/scrypath/phase112_contract_test.exs`
- **Per wave merge:** `mix verify.phase112`
- **Phase gate:** `mix verify.phase112` green

### Wave 0 Gaps
- [ ] `test/scrypath/phase112_contract_test.exs`
- [ ] `lib/mix/tasks/verify.phase112.ex`
- [ ] `test/mix/tasks/verify.phase112_test.exs`
- [ ] `mix.exs` preferred env registration for `verify.phase112`

## Security Domain

Phase 112 is low-risk content/test infrastructure work, but security-relevant truth boundaries still apply.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A |
| V5 Input Validation | yes | precise token assertions prevent misleading public security/operational claims |
| V6 Cryptography | no | N/A |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Misleading operational claim (“accepted” interpreted as “visible”) | Tampering (truth surface) | Assert explicit sync semantics and rejection of immediate-visibility implication |
| Scope creep via docs wording | Elevation of privilege (scope) | Canonical scope-policy guide + contract tests for reopen trigger language |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Docs duplication across surfaces | Route-first authority model (website as front door) | Established by v1.30 posture | Lower drift and clearer maintainer ownership |
| Manual truth review | Phase-scoped contract tests + verify tasks | Phases 110/111 patterns | Deterministic checks, less review ambiguity |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Highest future drift is wording creep, not structural routing gaps | Current State and Drift Points | May under-prioritize structural edits |
| A2 | `test/test_helper.exs` is existing test config anchor | Validation Architecture | Minor command/docs mismatch |
| A3 | Wave ordering (content first, then tests) is optimal | Recommended Plan Split | Slight rework if implementation flow differs |

## Open Questions (RESOLVED)

1. **RESOLVED: Should `verify.phase112` be standalone only or folded into `verify.phase99`?**
   - What we know: `verify.phase99` already carries trust-lane contracts through Phase 111.
   - Decision: keep `verify.phase112` standalone for Phase 112 execution and contributor discovery.
   - Rationale: Phase 112 is a public website/docs truth-alignment proof with its own focused file-read contract. Folding it into `verify.phase99` would broaden the existing trust-lane gate before there is maintainer signal that Phase 112 should become part of that lane.
   - Follow-up: composition into `verify.phase99` may be considered later only as a deliberate maintainer decision, not as part of this phase.

## Sources

### Primary (HIGH confidence)
- [CITED: .planning/phases/112-public-website-and-docs-truth-alignment/112-CONTEXT.md] - locked decisions, boundaries, verification shape
- [CITED: .planning/ROADMAP.md] - Phase 112 goal/requirements/success criteria
- [CITED: .planning/REQUIREMENTS.md] - WEB-01/WEB-02/SCOPE-01 and out-of-scope constraints
- [CITED: .planning/PROJECT.md] - maintenance/evidence mode and scope guard authority
- [CITED: .planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md] - reopen triggers and banned capability classes
- [CITED: README.md] - public claim envelope and sync/visibility language
- [CITED: website/src/pages/index.html]
- [CITED: website/src/pages/docs.html]
- [CITED: website/src/pages/evaluate.html]
- [CITED: website/src/pages/operators.html]
- [CITED: guides/support-and-compatibility.md]
- [CITED: guides/outside-adopter-intake.md]
- [CITED: guides/sync-modes-and-visibility.md]
- [CITED: test/scrypath/phase110_contract_test.exs]
- [CITED: test/scrypath/phase111_contract_test.exs]
- [CITED: test/mix/tasks/workflow_wiring_test.exs]
- [CITED: lib/mix/tasks/verify.phase108.ex]
- [CITED: lib/mix/tasks/verify.phase99.ex]
- [CITED: lib/mix/tasks/verify.adopter.ex]
- [CITED: AGENTS.md]

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- [ASSUMED] Small implementation-sequencing and drift-likelihood inferences noted in Assumptions Log.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - directly inferred from existing repo toolchain and tasks.
- Architecture: HIGH - established route-first and phase-contract patterns are explicit in current files.
- Pitfalls: HIGH - explicitly called out in 112 context and reinforced by prior phase verifier shape.

**Research date:** 2026-06-01  
**Valid until:** 2026-07-01
