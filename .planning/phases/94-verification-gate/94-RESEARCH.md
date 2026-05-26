# Phase 94: Verification Gate - Research

**Researched:** 2024-05-26 (or current date)
**Domain:** Elixir Mix Tasks / CI Verification Pipeline
**Confidence:** HIGH

## Summary

This research confirms the specific test files required to build `mix verify.phase94` for validating all tenant-safety surfaces (TNNT-05 requirement). Through codebase analysis, we identified that the exact files governing `tenant_field:` behavior, `schema_capabilities/1` reflection, `tenant_scope:` injection, and `multitenancy.md` guide anchors are already present in the test suite as implemented during phases 92 and 93.

**Primary recommendation:** Use the specific test files identified below in the `@focused_tests` attribute of the `Mix.Tasks.Verify.Phase94` task to ensure hermetic and targeted regression testing in CI and locally.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Goal**: All tenant-safety surfaces are regression-guarded by a single hermetic task that contributors and CI can run to confirm nothing has drifted
- **Depends on**: Phase 93
- **Requirements**: 
  - **TNNT-05**: User can run `mix verify.phase94` to confirm that `guides/multitenancy.md` guide anchors, `tenant_field:` auto-merge behavior, `schema_capabilities/1` `:tenant` reflection, and `tenant_scope:` injection are all coherent and regression-guarded; gate is registered in the CI `quality` job and CONTRIBUTING guidance

### Success Criteria (what must be TRUE)
1. `mix verify.phase94` runs without errors and exercises guide anchor assertions, `tenant_field:` auto-merge behavior, `schema_capabilities/1` `:tenant` reflection, and `tenant_scope:` injection in a single hermetic pass
2. `mix verify.phase94` is registered in the CI `quality` job so a pull request that breaks any tenant-safety contract fails CI
3. CONTRIBUTING guidance references `mix verify.phase94` so contributors know the gate exists and how to run it
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TNNT-05 | User can run `mix verify.phase94` to confirm that `guides/multitenancy.md` guide anchors, `tenant_field:` auto-merge behavior, `schema_capabilities/1` `:tenant` reflection, and `tenant_scope:` injection are all coherent and regression-guarded | We've isolated the specific `.exs` test files for these features to populate `@focused_tests`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Verification Task | Mix Tooling | CI/CD | Implemented as an Elixir Mix Task that is invoked by GitHub Actions during the quality check stage |
| Focused Testing | Mix Tooling | — | Mix test runner executes a subset of tests focused on tenant-safety |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Mix.Task` | Elixir Core | Command-line task | Native standard for extending project commands |
| `ExUnit` | Elixir Core | Test execution | Native testing library run by `mix test` |

## Code Examples

### Test Files to Target (`@focused_tests`)
Based on `grep` searches in the `test/` directory, the required tenant safety features are verified in the following files:

1. **`guides/multitenancy.md` guide anchors**
   - File: `test/scrypath/docs_contract_test.exs`
   - Verified via: `test "multitenancy guide contains required section anchors (TNNT-01)"`

2. **`tenant_field:` auto-merge behavior**
   - Files: `test/scrypath/schema_test.exs`, `test/scrypath/options_test.exs`, `test/scrypath/projection_test.exs`
   - Verified via: Configuration warnings, reflection, and document injection logic.

3. **`schema_capabilities/1` `:tenant` reflection**
   - File: `test/scrypath/metadata_test.exs`
   - Verified via: `test "schema_capabilities/1 reflects tenant_field when declared"`

4. **`tenant_scope:` injection**
   - File: `test/scrypath/options_test.exs`
   - Verified via: `describe "tenant_scope: search option"` tests.

Thus, `@focused_tests` must include:
```elixir
  @focused_tests [
    "test/scrypath/schema_test.exs",
    "test/scrypath/metadata_test.exs",
    "test/scrypath/options_test.exs",
    "test/scrypath/projection_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]
```

## Architecture Patterns

### Pattern 1: Hermetic Mix Task Runner
**What:** Creating a dedicated alias-like mix task in `lib/mix/tasks/` rather than relying on `mix.exs` aliases alone.
**When to use:** When verification involves running `mix test` with specific files, followed by additional assertions or tasks (like building docs with warnings as errors).
**Example:**
```elixir
defmodule Mix.Tasks.Verify.Phase94 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs focused tenant-safety and multitenancy verification (Phase 94)"

  @focused_tests [ ... ]

  @impl true
  def run(args) do
    # ...
  end
end
```

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified. CI relies on standard Elixir environment)

## Sources

### Primary (HIGH confidence)
- Codebase Grep (`test/scrypath/*_test.exs`) - Confirmed location of test assertions.
- `.planning/phases/94-verification-gate/94-PATTERNS.md` - Verified analog approach to `verify.phase91`.
- `.planning/phases/94-verification-gate/94-CONTEXT.md` - Confirmed TNNT-05 requirement criteria.
