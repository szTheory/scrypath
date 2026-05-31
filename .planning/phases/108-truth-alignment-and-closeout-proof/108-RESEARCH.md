# Phase 108: Truth Alignment and Closeout Proof - Research

**Researched:** 2026-05-31  
**Domain:** Documentation-truth reconciliation and focused verification gate design for v1.29 closeout  
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Present `use Scrypath, fan_outs:` as the ordinary path for searchable schemas. Phase 106 repaired generated `__scrypath__(:fan_outs)`, so docs should stop treating hand-written fan-out reflection as the normal copy-paste path.
- **D-02:** Keep hand-written `__scrypath__/1` documented as a supported low-level escape hatch for unusual owner-only schemas that intentionally do not `use Scrypath`; do not label it deprecated.
- **D-03:** Preserve the two main related-data footgun warnings: `sync_mode: :oban` means durably queued, not searchable now; resolvers must handle both inline record lists and Oban document-id lists.
- **D-04:** Explicitly avoid advertising deferred fan-out breadth as shipped contract: no `Scrypath.FanOuts` owner-only macro, no public `schema_fan_outs/1` helper, and no duplicate/nil fan-out validation tightening in this phase.
- **D-05:** Use a bounded truth set, not a broad docs sweep. Phase 108 should reconcile `guides/related-data-and-reindexing.md`, `docs/jtbd-gap-map.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, and line-level `CONTRIBUTING.md` verification posture if needed.
- **D-06:** Keep authority boundaries intact: runtime and related-data semantics live in guides; milestone intent and closure live in `.planning/*`; verification-gate posture lives in `CONTRIBUTING.md`; README and overview stay route maps unless a direct contradiction is found.
- **D-07:** Do not rewrite stable root docs into second authorities for policy, support, proof, or related-data semantics.
- **D-08:** Add a focused, service-free `mix verify.phase108` gate for TRUTH-01 rather than relying only on a one-time audit or broad docs-contract coverage.
- **D-09:** Keep `verify.phase108` narrow: a new `test/scrypath/phase108_contract_test.exs`, a task contract test such as `test/mix/tasks/verify.phase108_test.exs`, and only dedicated docs-contract tagging if needed.
- **D-10:** The gate must not run Meilisearch, Playwright, the ecommerce example service stack, or full broad docs snapshots. Use stable tokens and anchors rather than brittle paragraph equality.
- **D-11:** Do not create a new required GitHub Actions job for Phase 108 by default. Keep `phase105-e2e` advisory unless release policy explicitly promotes it.
- **D-12:** Close v1.29 decisively as repair complete, then return Scrypath to maintenance-and-evidence mode.
- **D-13:** Use this closeout posture: v1.29 repairs declaration-backed fan-out reflection, guards tenant-preserving ecommerce readiness, aligns planning/JTBD truth, keeps `phase105-e2e` advisory, and reopens future feature breadth only with reviewed outside-adopter evidence or a concrete production bug.
- **D-14:** Avoid vague "near-done" framing unless the remaining open evidence is named. The remaining confidence gap is outside adoption/proof stability, not another in-repo feature wedge.

### the agent's Discretion
- Exact wording, section names, and assertion helper names may be chosen by the planner/executor as long as the ordinary-vs-advanced fan-out split, bounded truth surface list, service-free gate shape, and repair-complete closeout posture remain intact.
- The planner may decide whether Phase 108 assertions live entirely in new phase-specific tests or share a small tagged section in existing docs-contract tests, provided the local reproduction command remains `mix verify.phase108` and the scope stays low-noise.

### Deferred Ideas (OUT OF SCOPE)
- Owner-only fan-out declaration macro (`Scrypath.FanOuts`) remains deferred.
- Public fan-out reflection helper (`Scrypath.schema_fan_outs/1`) remains deferred.
- Duplicate/nil fan-out validation tightening remains deferred.
- Deeper cross-tenant Playwright fixture expansion remains deferred.
- Promotion of `phase105-e2e` to required CI remains deferred until explicit release policy and stability evidence justify it.
- Broader feature categories remain evidence-gated: autocomplete/suggestions, vector or hybrid retrieval, public backend broadening, tenant-token helpers, and OPSUI productization.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRUTH-01 | Related-data docs and planning/JTBD truth describe the repaired contract and keep deferred breadth out of v1.29. | Bounded truth-surface edits + focused `verify.phase108` token assertions + explicit advisory `phase105-e2e` posture checks. |

## Summary

Phase 108 is a bounded truth-reconciliation and closeout-proof phase, not a feature phase. The required outcome is consistency across specific authority surfaces: related-data guide contract wording, v1.29 roadmap/requirements/project/JTBD truth, and verification posture that keeps `phase105-e2e` advisory. [VERIFIED: codebase grep]

The existing repo already has the correct implementation seams: phase-scoped service-free verify Mix tasks (`verify.phase99`, `verify.phase106`, `verify.phase107`), task contract tests, and token/anchor contract tests (`phase99_contract_test`). Reusing these patterns is the standard path and avoids broad noisy docs snapshots. [VERIFIED: codebase grep]

**Primary recommendation:** Implement `mix verify.phase108` as a focused, service-free truth gate and limit doc updates to the bounded authority list in D-05, while preserving `phase105-e2e` as advisory. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Preserve Scrypath’s Ecto-first, Phoenix-friendly OSS library positioning and avoid architecture that conflicts with that adoption shape. [CITED: /Users/jon/projects/scrypath/AGENTS.md]
- Keep v1 public backend scope Meilisearch-first while preserving internal adapter seam; avoid premature public backend abstraction. [CITED: /Users/jon/projects/scrypath/AGENTS.md]
- Keep write-path support explicit across inline, Oban-backed, and manual sync modes. [CITED: /Users/jon/projects/scrypath/AGENTS.md]
- Prioritize minimal setup and Phoenix ergonomics without hiding operational realities. [CITED: /Users/jon/projects/scrypath/AGENTS.md]
- Keep operational semantics explicit (eventual consistency, deletes, backfills, reindex workflows). [CITED: /Users/jon/projects/scrypath/AGENTS.md]
- Do not lower release quality bar; roadmap/docs should reflect completeness over speed. [CITED: /Users/jon/projects/scrypath/AGENTS.md]
- Follow `CONTRIBUTING.md` merge/verification posture and keep required CI gates green. [CITED: /Users/jon/projects/scrypath/AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Related-data contract wording alignment | Documentation/Planning | Test suite | Canonical semantics live in guides/planning docs; tests enforce anchor truth. |
| v1.29 roadmap/JTBD closeout truth | Documentation/Planning | — | Milestone and scope truth is owned in `.planning/*` and JTBD docs. |
| Verification posture assertion (`phase105-e2e` advisory) | Test suite + contributor docs | CI workflow references | Merge-gate policy is documented in CONTRIBUTING and reflected in workflow names. |
| Focused local proof command (`mix verify.phase108`) | Mix task layer | ExUnit contract tests | Existing phase verify commands are implemented as thin Mix task wrappers around focused tests. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.17` floor (project policy) | Task and test implementation language | Existing verify tasks and contract tests are Elixir/ExUnit-first. [VERIFIED: codebase grep] |
| ExUnit | bundled with Elixir | Truth token/anchor assertions | Current phase contract tests use ExUnit token assertions and helper functions. [VERIFIED: codebase grep] |
| Mix tasks | bundled with Elixir | Focused gate entrypoint (`mix verify.phase108`) | Existing phases follow this deterministic no-args command pattern. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Existing docs/test helpers (`assert_contains_all`, ordering checks patterns) | repo-local | Stable token assertions over prose snapshots | When proving truth alignment with low brittleness. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Focused phase gate (`verify.phase108`) | Broad `docs_contract_test` sweep | Broad sweep is noisier and exceeds bounded closeout scope. [VERIFIED: codebase grep] |
| Service-free proof | Real-service/browser CI lane | Violates D-10 scope and slows truth-only closeout loop. [VERIFIED: codebase grep] |

## Architecture Patterns

### System Architecture Diagram

```text
Authoritative files (guides/.planning/CONTRIBUTING)
        |
        v
Phase 108 edit set (bounded truth surfaces only)
        |
        v
Token/anchor assertions (phase108_contract_test + verify.phase108_test)
        |
        v
mix verify.phase108 (service-free local gate)
        |
        +--> pass: planner can mark TRUTH-01 complete and close v1.29
        |
        +--> fail: drift surfaced with explicit file/token mismatch
```

### Recommended Project Structure

```text
lib/mix/tasks/
  verify.phase108.ex            # focused phase gate task
test/mix/tasks/
  verify.phase108_test.exs      # no-args + task marker + focused path contract
test/scrypath/
  phase108_contract_test.exs    # bounded token truth assertions
guides/
  related-data-and-reindexing.md
docs/
  jtbd-gap-map.md
.planning/
  ROADMAP.md, REQUIREMENTS.md, PROJECT.md
```

### Pattern 1: Focused Phase Verify Task
**What:** Mix task that enforces no args, starts app, runs only focused tests, and prints deterministic markers. [VERIFIED: codebase grep]  
**When to use:** Small phase-specific contract proof without service dependencies.

### Pattern 2: Token Anchor Contract Assertions
**What:** Assert required/forbidden strings and ordering anchors across bounded files rather than full-paragraph equality. [VERIFIED: codebase grep]  
**When to use:** Truth-drift prevention where wording may evolve but contract tokens must remain.

### Anti-Patterns to Avoid
- **Broad docs snapshot locking:** brittle and noisy for a bounded closeout phase.
- **Policy duplication into root docs:** creates second authorities and future drift.
- **Promoting advisory CI lanes by implication:** `phase105-e2e` must stay explicitly advisory unless policy changes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Phase closeout proof | New custom harness outside Mix/ExUnit | Existing `verify.phaseNN` + ExUnit contract-test pattern | Reuses proven deterministic repo pattern with low maintenance. |
| Drift checks | Paragraph-diff scripts | Token/anchor assertions | More stable and aligned with existing trust gates. |
| CI promotion policy | New required job for 108 | Existing required-gate posture (`main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust`) | Avoids scope creep and preserves explicit advisory status of `phase105-e2e`. |

**Key insight:** This phase should prove truth alignment by constraining authoritative tokens, not by expanding test or CI breadth.

## Common Pitfalls

### Pitfall 1: Turning route-map docs into policy authorities
**What goes wrong:** README/overview starts owning details already owned by guides/planning docs.  
**Why it happens:** Convenience edits during truth refresh.  
**How to avoid:** Keep authority boundaries from D-06; edit root docs only for contradiction fixes.  
**Warning signs:** Same policy text appears in multiple root surfaces with slight wording divergence.

### Pitfall 2: Brittle prose-equality assertions
**What goes wrong:** Minor copy edits break tests with no real contract drift.  
**Why it happens:** Snapshot-style assertions in docs tests.  
**How to avoid:** Use stable tokens and ordered anchors.  
**Warning signs:** Frequent test churn for punctuation/reflow-only edits.

### Pitfall 3: Accidental CI scope promotion
**What goes wrong:** `phase105-e2e` appears required by wording or workflow changes.  
**Why it happens:** Incomplete alignment between CONTRIBUTING and CI references.  
**How to avoid:** Assert advisory wording tokens and leave required-gate list unchanged.  
**Warning signs:** Required gate list mentions `phase105-e2e` or removes “advisory” framing.

## Code Examples

### Focused Verify Task Shape (Phase Pattern)
```elixir
defmodule Mix.Tasks.Verify.Phase108 do
  @moduledoc false
  use Mix.Task

  @focused_tests [
    "test/scrypath/phase108_contract_test.exs",
    "test/mix/tasks/verify.phase108_test.exs"
  ]

  def run(args) do
    ensure_no_args!(args)
    Mix.Task.run("app.start")
    Mix.Task.reenable("test")
    Mix.Task.run("test", @focused_tests)
  end
end
```
Source pattern: `lib/mix/tasks/verify.phase99.ex`, `verify.phase106.ex`, `verify.phase107.ex`. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-written `__scrypath__(:fan_outs)` treated as common path | `use Scrypath, fan_outs:` is ordinary path; hand-written reflection remains escape hatch | 2026-05-31 (Phase 106) | Docs and planning truth must reflect repaired contract shape. [VERIFIED: codebase grep] |
| Broad “next feature” pull after milestones | Bounded repair closeout + maintenance/evidence default | 2026-05-31 (v1.29 scope) | Planner should avoid reopening deferred breadth in Phase 108. [VERIFIED: codebase grep] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No project-defined skills directory (`.codex/skills` / `.agents/skills`) contributes additional constraints for this phase. [ASSUMED] | Project constraints intake | Low; affects only supplemental conventions, not locked decisions. |

## Open Questions

1. **Should `phase108` anchors live only in new tests or partially in `docs_contract_test`?**
   - What we know: Both are allowed by D-09 if scope stays narrow.
   - What's unclear: Preferred maintenance locus for future truth checks.
   - Recommendation: Default to standalone `phase108_contract_test` + task test for isolation.

## Environment Availability

Step 2.6: SKIPPED (no new external runtime/service dependencies identified for this docs-and-service-free verification phase).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (via Mix test) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix verify.phase108` |
| Full suite command | `mix test --exclude integration --exclude docs_contract` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TRUTH-01 | Related-data + planning/JTBD + verification-posture truth aligned and bounded | contract/unit | `mix verify.phase108` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix verify.phase108`
- **Per wave merge:** `mix test --exclude integration --exclude docs_contract`
- **Phase gate:** `mix verify.phase108` green before closeout claim

### Wave 0 Gaps
- [ ] `test/scrypath/phase108_contract_test.exs` — TRUTH-01 token assertions
- [ ] `lib/mix/tasks/verify.phase108.ex` — focused gate task
- [ ] `test/mix/tasks/verify.phase108_test.exs` — task contract checks
- [ ] `mix.exs` `cli.preferred_envs` mapping for `"verify.phase108": :test`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A (no auth-surface change) |
| V3 Session Management | no | N/A (no session-surface change) |
| V4 Access Control | no | N/A (no access-control logic change) |
| V5 Input Validation | yes | Strict no-args contract in verify task (`ensure_no_args!`) |
| V6 Cryptography | no | N/A (no crypto-surface change) |

### Known Threat Patterns for Elixir docs/verification phases

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Truth drift between policy surfaces | Tampering | Token-anchor contract tests over bounded authority files |
| Accidental CI posture change | Tampering | Assert required-gate list and advisory wording explicitly |
| Over-broad verify command hidden side effects | Denial of service | Keep phase gate focused and service-free |

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/scrypath/.planning/phases/108-truth-alignment-and-closeout-proof/108-CONTEXT.md` - locked decisions and bounded scope
- `/Users/jon/projects/scrypath/.planning/ROADMAP.md` - phase goal, success criteria, dependency
- `/Users/jon/projects/scrypath/.planning/REQUIREMENTS.md` - TRUTH-01 and deferred breadth boundaries
- `/Users/jon/projects/scrypath/.planning/PROJECT.md` - milestone closeout posture and advisory gate framing
- `/Users/jon/projects/scrypath/guides/related-data-and-reindexing.md` - ordinary vs escape-hatch fan-out contract wording
- `/Users/jon/projects/scrypath/docs/jtbd-gap-map.md` - post-v1.28 priority/closeout truth
- `/Users/jon/projects/scrypath/CONTRIBUTING.md` - required vs advisory CI/verify posture
- `/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase99.ex` - focused gate pattern
- `/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase106.ex` - focused gate pattern
- `/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase107.ex` - focused gate pattern
- `/Users/jon/projects/scrypath/test/scrypath/phase99_contract_test.exs` - token/anchor assertion pattern
- `/Users/jon/projects/scrypath/test/mix/tasks/verify.phase99_test.exs` and phase106/107 task tests - task contract pattern
- `/Users/jon/projects/scrypath/mix.exs` - `cli.preferred_envs` wiring seam
- `/Users/jon/projects/scrypath/.github/workflows/ci.yml` - current CI job names including advisory `phase105-e2e`
- `/Users/jon/projects/scrypath/AGENTS.md` - project constraints

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing repo patterns are explicit and repeated across adjacent phases.
- Architecture: HIGH - ownership boundaries are directly specified in 108 context and current docs.
- Pitfalls: HIGH - inferred from current drift risks and explicit scope guards across planning artifacts.

**Research date:** 2026-05-31  
**Valid until:** 2026-06-30

