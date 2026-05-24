<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Add clear instructions in `guides/related-data-and-reindexing.md` (or a dedicated example guide) showing how to manually handle related-data updates using custom Oban jobs for child relations.
- **D-02:** Ensure the documentation is explicit that this is a temporary workaround until `related-data propagation` becomes a first-class feature.
- **D-03:** Add a bounded regression test or docs contract to ensure this workaround documentation is not accidentally removed before the first-class feature is built.
- **D-04:** Update `ROADMAP.md`, `STATE.md`, and `REQUIREMENTS.md` to officially freeze the milestone with the `related-data propagation` verdict.
- **D-05:** Conclude Phase 88 and the entire v1.23 milestone.

### the agent's Discretion
[None specified]

### Deferred Ideas (OUT OF SCOPE)
[None specified]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIX-01 | The milestone closes only evidence-backed docs/support/proof papercuts discovered through ADOPT-02, and each accepted fix lands with a bounded regression guard. | D-01, D-02, D-03 explicitly define the workaround guide and tests |
| FIX-02 | Milestone-close artifacts end with one explicit next-pull verdict: stop soon, open related-data propagation, or open tenant-safe access. | D-04, D-05 explicitly state `related-data propagation` as the verdict and dictate file updates |
</phase_requirements>

# Phase 88: Evidence-Backed Papercuts And Next-Pull Verdict - Research

**Researched:** 2026-05-24
**Domain:** Documentation, Testing, Planning Artifacts
**Confidence:** HIGH

## Summary

This phase executes the explicitly authorized conclusion to the `v1.23` milestone. It resolves a specific papercut around related-data documentation by updating `guides/related-data-and-reindexing.md` to clarify the workaround for propagating child entity changes using custom Oban jobs, explicitly noting it as a temporary workaround until `related-data propagation` becomes a first-class feature. It also guarantees this documentation stays intact via `docs_contract_test.exs` and officially freezes the milestone in `ROADMAP.md`, `STATE.md`, and `REQUIREMENTS.md` with `related-data propagation` as the next-pull verdict.

**Primary recommendation:** Update the existing `guides/related-data-and-reindexing.md` to include an explicit Oban example, add a contract test for it in `test/scrypath/docs_contract_test.exs`, and edit the `.planning/` files to finalize the milestone.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Documentation Updates | Repo Files | — | Updates to existing Markdown guides. |
| Docs Contract Testing | Unit Tests | — | ExUnit suite `test/scrypath/docs_contract_test.exs` ensures docs are not regressed. |
| Milestone Planning | Repo Files | — | Markdown and YAML/JSON metadata in `.planning` defines project state. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit | (built-in) | Testing | Standard for Elixir. |
| Markdown | — | Documentation | Standard format for `guides/` and `.planning/`. |

## Architecture Patterns

### Pattern 1: Docs Contract Testing
**What:** Ensuring critical sections of documentation exist and contain specific keywords or phrases to prevent regressions.
**When to use:** When a temporary workaround or critical explanation must not be accidentally removed or modified without intent.
**Example:**
```elixir
// Source: test/scrypath/docs_contract_test.exs
test "related-data guide explicitly mentions temporary Oban workaround" do
  content = File.read!("guides/related-data-and-reindexing.md")
  assert String.contains?(content, "temporary workaround")
  assert String.contains?(content, "Oban")
end
```

### Pattern 2: Milestone Freeze Bookkeeping
**What:** Updating the project planning files to reflect a milestone's closure.
**When to use:** At the end of a milestone (like v1.23).
**Example:**
- `ROADMAP.md`: Move `v1.23` from `active` to `shipped + archived in-repo`, adding the explicit `related-data propagation` verdict to the "Progress" section.
- `STATE.md`: Update `status` to `shipped` or `completed`, adjust progress counters, add a closing `Decisions` log entry, and set `Next Command` accordingly.
- `REQUIREMENTS.md`: Tick off all remaining checkboxes (`FIX-01`, `FIX-02`) and update the `Coverage` / `Traceability` tables.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Verification | A new bash script | `docs_contract_test.exs` | Elixir/ExUnit is the established framework for parsing and verifying markdown docs in this repo. |

## Common Pitfalls

### Pitfall 1: Missing Docs Regression
**What goes wrong:** A future PR refactors `guides/related-data-and-reindexing.md` and accidentally deletes the temporary workaround instructions.
**Why it happens:** Without a failing test, there's no CI feedback that a requirement was lost.
**How to avoid:** Add a specific test in `test/scrypath/docs_contract_test.exs` checking for strings like `custom Oban job` and `temporary workaround` in that file.

### Pitfall 2: Incomplete Milestone Freeze
**What goes wrong:** The milestone isn't cleanly closed across all tracking files, causing confusion for the next developer/agent picking up the project.
**Why it happens:** Only updating `STATE.md` but forgetting `ROADMAP.md` or `REQUIREMENTS.md`.
**How to avoid:** Methodically update all three files.

## Code Examples

### Asserting Documentation Exists
```elixir
// test/scrypath/docs_contract_test.exs
test "related-data guide has the temporary Oban workaround" do
  guide = @guides["guides/related-data-and-reindexing.md"]
  assert String.contains?(guide, "temporary workaround")
  assert String.contains?(guide, "first-class feature")
  assert String.contains?(guide, "Oban")
end
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No assumptions were made; all required steps are explicitly documented in `88-CONTEXT.md` and repo conventions. | N/A | N/A |

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/scrypath/docs_contract_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIX-01 | Regression guard for docs | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ Wave 0 |
| FIX-02 | Milestone freeze | manual-only | (Check Markdown files) | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/scrypath/docs_contract_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
None — existing test infrastructure covers all phase requirements.

## Sources

### Primary (HIGH confidence)
- `.planning/phases/88-evidence-backed-papercuts-and-next-pull-verdict/88-CONTEXT.md` - Explicit implementation decisions D-01 through D-05.
- `guides/related-data-and-reindexing.md` - Existing guide structure.
- `test/scrypath/docs_contract_test.exs` - Existing documentation contract test suite.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir ExUnit.
- Architecture: HIGH - Dictated by context.
- Pitfalls: HIGH - Straightforward process.

**Research date:** 2026-05-24
**Valid until:** 30 days
