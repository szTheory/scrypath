# Phase 66: Runner-library contract - Research

**Researched:** 2026-04-22 [VERIFIED: local env]  
**Domain:** Scrypath playbook execution contract alignment between `ScrypathOps.Playbook.Runner`, core `Scrypath.search/3` / `search_many/2`, and downstream operator formatting surfaces [VERIFIED: 66-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: codebase grep]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Contract boundary

- **D-01:** Keep **`Runner.run_validated/3`** on a **raw Elixir tuple seam**: **`{:ok, result}`** or **`{:error, reason}`** only. Do **not** make the runner return UI-ready enriched maps.
- **D-02:** Preserve the **reason atom/tuple** as the **stable contract key**. This carries forward Phase 65 and is the parity target for Phase 66.
- **D-03:** **OPSUI enrichment** remains an **edge concern** owned by **`ScrypathOps.Playbook.RunFailure`** / LiveView-facing code. Human copy, docs links, and ticket-friendly payload shaping are **not** the runner contract.
- **D-04:** Do **not** introduce a new public typed runner error struct in Phase 66. A richer internal seam can be reconsidered later if Scrypath gains another real non-LiveView execution consumer.

### Canonical contract documentation

- **D-05:** The **single canonical execution-contract reference** should live in **`ScrypathOps.Playbook.Runner`** `@moduledoc`, under a dedicated section such as **`## Runner-library contract`**.
- **D-06:** That section should explicitly document:
  - accepted input shape after **`V1.validate/1`**
  - success shapes by mode (**`search`** → **`%Scrypath.SearchResult{}`**, **`search_many`** → **`%Scrypath.MultiSearchResult{}`**)
  - failure shape as **`{:error, reason}`**
  - the rule that **reason identity**, not UI wording, is the stable contract
  - relationship to bang APIs / Mix-facing formatting
- **D-07:** **`scrypath_ops/docs/playbook-schema-v1.md`** remains the authority for the **JSON wire format**, not the execution contract. It should link to the canonical runner contract instead of duplicating it.

### Parity test depth

- **D-08:** Phase 66 should use a **representative contract matrix**, not a giant mirrored suite and not a token smoke test.
- **D-09:** The parity matrix should cover the **main semantic seams** only:
  - **`search`** happy path
  - **`search_many`** happy path
  - one **pre-dispatch validation/config** failure
  - one **backend/runtime** failure from the underlying **`Scrypath`** path
  - one **multi-search-specific** failure or edge case that matters to operators
- **D-10:** Keep parity tests **cross-boundary** and **explicit**. Reuse helpers where useful, but avoid building a large generalized meta-test harness that duplicates the whole core suite.
- **D-11:** If a small invariant check helps, keep it narrow and structural; do **not** expand Phase 66 into broad property testing.

### Alignment scope with Scrypath and Mix paths

- **D-12:** In Phase 66, “consistent with **`Scrypath`** / Mix operator paths” means **shared semantic outcomes and stable reason shapes**, not identical human-facing strings.
- **D-13:** Mix/operator surfaces may continue to **format** those reasons separately for CLI or UI use. That formatting is a downstream presentation concern.
- **D-14:** Phase 66 must ensure there are **no silent rescue/swallow paths** that hide **`{:error, term}`** divergence from tests or operators.
- **D-15:** If future work wants stronger cross-surface consistency, the next acceptable step is a **shared internal normalization seam** for metadata. Do **not** freeze presentation strings as contract in this phase.

### the agent's Discretion

- Exact naming and placement of parity helpers / fixtures.
- Whether the canonical runner section also introduces local `@typedoc` aliases for result/failure shapes, provided the public contract remains a tuple seam.
- Exact fixture count within the recommended representative matrix, provided it stays focused and readable.

### Deferred Ideas (OUT OF SCOPE)

- Introduce a shared **internal** normalized failure metadata seam if a second real execution consumer appears.
- Promote a new public **`%RunError{}`** struct only if Scrypath genuinely needs a broader cross-surface execution API and is willing to carry that semver burden.
- Freeze human-facing wording, docs-link parity, and execution-surface doc anchors under **Phase 67** verification/doc-contract work instead of Phase 66.
- Durable runs, reconnect attachment, streaming progress, or server-owned execution records remain out of scope for this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS3-03 | Playbook execution uses documented, stable result and error shapes aligned with the same `Scrypath` / Mix-facing contracts used outside OPSUI where applicable; automated tests fail if OPSUI and core diverge on representative success and failure fixtures. | Canonical `Runner` `@moduledoc` contract, tuple-seam ownership, downstream formatting boundaries, representative parity matrix, and targeted verification commands in this document. [VERIFIED: REQUIREMENTS.md][VERIFIED: 66-CONTEXT.md] |
</phase_requirements>

## Summary

`ScrypathOps.Playbook.Runner.run_validated/3` already sits on the right public seam for this phase: it returns only `{:ok, result}` or `{:error, reason}`, with mode-specific success values delegated through `ScrypathOps.SearchPlayground`, whose default adapter calls `Scrypath.search/3` and `Scrypath.search_many/2` directly. `RunFailure` and `PlaybookLive` are already downstream presentation layers that enrich, format, and render errors after the raw reason exists. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex]

The main planning work is therefore not a redesign. It is a contract-freeze slice: document the runner seam in one canonical `@moduledoc` section, align that language with the existing `Scrypath.search/3` and `search_many/2` “errors vs raises” docs, and add a narrow parity matrix proving that representative success and failure cases stay semantically consistent across the core library path, the runner path, and downstream operator formatting boundaries. [VERIFIED: 66-CONTEXT.md][VERIFIED: lib/scrypath.ex][VERIFIED: lib/scrypath/search.ex]

The highest-risk drift today is not success handling; it is error interpretation. Core Scrypath documents raw tuple returns plus bang variants, while OPSUI currently duplicates human-facing flash strings and enrichment logic in `PlaybookLive` and `RunFailure`. Planning should preserve that formatting split but add tests that pin the stable thing underneath it: the reason atom/tuple and the result struct type. Planning should also explicitly audit the only relevant rescue point in runner-adjacent code, `module_in_allowlist/2`, so there is no hidden divergence path that converts unexpected failures into UI-only behavior. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex][VERIFIED: 66-CONTEXT.md]

**Primary recommendation:** Keep `Runner.run_validated/3` as the canonical raw tuple contract, document it in `Runner` `@moduledoc`, and add 4-5 explicit parity tests that compare runner outcomes to core `Scrypath` semantics without freezing UI copy. [VERIFIED: 66-CONTEXT.md][VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stable execution tuple contract | API / Backend | Frontend Server (SSR) | `Runner.run_validated/3` returns the machine contract and `SearchPlayground.Adapter.Scrypath` delegates into core `Scrypath` functions. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex] |
| Canonical contract documentation | API / Backend | — | The discuss-phase decision locks the canonical contract into `ScrypathOps.Playbook.Runner` `@moduledoc`. [VERIFIED: 66-CONTEXT.md] |
| UI enrichment and human-facing docs links | Frontend Server (SSR) | API / Backend | `RunFailure.enrich/2` and `PlaybookLive` build failure class, copy payloads, links, and flash messages after receiving a raw reason. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] |
| CLI/operator formatting | API / Backend | — | `Scrypath.Errors.format_reason/1` and `Scrypath.CLI.OperatorTask.error!/2` format reasons for operator text without changing the underlying reason term. [VERIFIED: lib/scrypath/errors.ex][VERIFIED: lib/scrypath/cli/operator_task.ex] |
| Parity regression tests | API / Backend | Frontend Server (SSR) | Core tests already lock result/error semantics while `scrypath_ops` tests lock runner and LiveView behavior; Phase 66 should add focused cross-boundary assertions, not another tier. [VERIFIED: test/scrypath/search_test.exs][VERIFIED: test/scrypath/search_many_test.exs][VERIFIED: scrypath_ops/test/scrypath_ops/playbook/runner_test.exs][VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 local runtime / `~> 1.17` project floor | Compile and test the root library and `scrypath_ops` app | The repo already targets Elixir `~> 1.17`, and the local machine satisfies that with 1.19.5. [VERIFIED: local env][VERIFIED: mix.exs][VERIFIED: scrypath_ops/mix.exs] |
| Ecto | 3.13.5 | Existing result/search integration surface and test environment baseline | `Scrypath` is Ecto-native and both root and ops apps lock `ecto` 3.13.5 in `mix.lock`. [VERIFIED: AGENTS.md][VERIFIED: mix.lock][VERIFIED: scrypath_ops/mix.lock] |
| Phoenix LiveView | 1.1.28 | Existing async operator path and test harness in `scrypath_ops` | Phase 65 already implemented `start_async`/`handle_async` in `PlaybookLive`; Phase 66 should extend contract assertions around that seam, not replace it. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex][VERIFIED: scrypath_ops/mix.lock] |
| Telemetry | 1.4.1 | Existing start/stop events around playbook runs and search paths | “No silent swallow” verification can piggyback on existing telemetry stop events instead of inventing a new reporting path. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex][VERIFIED: mix.lock] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | bundled with Elixir 1.19.5 | Primary phase verification framework | Use for runner parity tests and any docs-contract assertion added later. [VERIFIED: local env][VERIFIED: test/test_helper.exs][VERIFIED: scrypath_ops/test/test_helper.exs] |
| Phoenix.LiveViewTest | via Phoenix LiveView 1.1.28 | Existing async UI verification with `render_async/1` | Use only for representative UI-through-runner parity cases; keep most contract checks at module level. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs][VERIFIED: scrypath_ops/mix.lock] |
| Jason | 1.4.4 | Existing playbook wire-format decode/encode and diagnostics payload support | Reuse for fixture setup and any contract assertions involving saved playbook JSON. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/v1.ex][VERIFIED: mix.lock][VERIFIED: scrypath_ops/mix.lock] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing tuple seam on `Runner.run_validated/3` | Public `%RunError{}` struct | Explicitly rejected by discuss-phase decisions and unnecessary while LiveView is the only enriched execution consumer. [VERIFIED: 66-CONTEXT.md] |
| Focused parity matrix | Fully mirrored runner-vs-core suite | Would duplicate root search coverage already present in `search_test.exs` and `search_many_test.exs` without adding much new signal. [VERIFIED: 66-CONTEXT.md][VERIFIED: test/scrypath/search_test.exs][VERIFIED: test/scrypath/search_many_test.exs] |
| Existing formatting boundaries (`RunFailure`, `PlaybookLive`, `Scrypath.Errors`, CLI task) | Shared presentation-string contract | Discuss-phase explicitly limits Phase 66 to semantic parity, not human-string parity. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex][VERIFIED: lib/scrypath/errors.ex] |

**Installation:** No new dependencies are recommended for Phase 66; use the existing root and `scrypath_ops` applications. [VERIFIED: codebase grep]

**Version verification:** Root `mix.lock` currently pins `ecto 3.13.5`, `jason 1.4.4`, `req 0.5.17`, and `telemetry 1.4.1`; `scrypath_ops/mix.lock` additionally pins `phoenix 1.8.5` and `phoenix_live_view 1.1.28`. [VERIFIED: mix.lock][VERIFIED: scrypath_ops/mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
Saved/loaded playbook JSON
        |
        v
ScrypathOps.Playbook.V1.validate/1
        |
        v
ScrypathOps.Playbook.Runner.run_validated/3
        |
        +--> pre-dispatch config/shape checks -> {:error, reason}
        |
        +--> ScrypathOps.SearchPlayground.dispatch_search/3
        |           |
        |           v
        |   Adapter.Scrypath.search/3
        |           |
        |           v
        |      Scrypath.search/3 -> {:ok, %SearchResult{}} | {:error, reason}
        |
        +--> ScrypathOps.SearchPlayground.dispatch_search_many/2
                    |
                    v
            Adapter.Scrypath.search_many/2
                    |
                    v
           Scrypath.search_many/2 -> {:ok, %MultiSearchResult{}} | {:error, reason}
                    |
                    v
     PlaybookLive handle_async / RunFailure / flash formatting
                    |
                    v
           Operator-visible UI and diagnostics payload
```
[VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/v1.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex]

### Recommended Project Structure
```text
scrypath_ops/lib/scrypath_ops/playbook/
├── runner.ex         # Canonical execution tuple contract and dispatch seam
├── run_failure.ex    # UI/operator enrichment only
├── v1.ex             # JSON wire-format validation
└── doc_resolver.ex   # Link resolution for presentation layers

scrypath_ops/test/scrypath_ops/playbook/
├── runner_test.exs   # Phase 66 parity tests belong here first
└── run_failure_test.exs

test/scrypath/
├── search_test.exs
└── search_many_test.exs
```
[VERIFIED: codebase grep]

### Pattern 1: Raw Tuple Contract at the Runner Boundary
**What:** `Runner.run_validated/3` should expose only `{:ok, result}` and `{:error, reason}`, with success type determined by mode and no UI enrichment. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex][VERIFIED: 66-CONTEXT.md]  
**When to use:** For every caller outside the LiveView edge that needs machine-meaningful execution results. [VERIFIED: 66-CONTEXT.md]  
**Example:**
```elixir
# Source: scrypath_ops/lib/scrypath_ops/playbook/runner.ex
@spec run_validated(map() | {:ok, map()}, [module()], keyword()) ::
        {:ok, term()} | {:error, term()}

def run_validated(%{"mode" => "search"} = map, allowlist, scrypath_opts) do
  with {:ok, opts} <- build_dispatch_opts(scrypath_opts, Map.get(map, "opts") || %{}, :search) do
    SearchPlayground.dispatch_search(module_in_allowlist(Map.get(map, "schema"), allowlist), Map.get(map, "q"), opts)
  end
end
```
[VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex]

### Pattern 2: Formatting Happens Downstream
**What:** Presentation layers receive the raw reason and decide how to render or serialize it. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex][VERIFIED: lib/scrypath/errors.ex]  
**When to use:** For UI alerts, diagnostics JSON, and Mix task output. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex][VERIFIED: lib/scrypath/cli/operator_task.ex]  
**Example:**
```elixir
# Source: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
def handle_async({@playbook_run_async_key, run_id}, {:ok, {:error, reason}}, socket) do
  enriched = enrich_run_failure(reason, socket)

  {:noreply,
   socket
   |> assign(:run_error, reason)
   |> assign(:run_failure_enriched, enriched)
   |> put_flash(:error, format_run_flash(reason))}
end
```
[VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex]

### Pattern 3: Representative Cross-Boundary Parity Tests
**What:** Compare a small number of runner outcomes to the equivalent core `Scrypath` semantics and assert structural parity, not identical copy. [VERIFIED: 66-CONTEXT.md][VERIFIED: test/scrypath/search_test.exs][VERIFIED: test/scrypath/search_many_test.exs]  
**When to use:** For Phase 66 regression coverage. [VERIFIED: 66-CONTEXT.md]  
**Example:**
```elixir
# Source pattern: scrypath_ops/test/scrypath_ops/playbook/runner_test.exs
assert {:ok, %Scrypath.MultiSearchResult{} = ms} =
         Runner.run_validated(map, Schemas.allowlist(), Schemas.scrypath_opts())

assert length(ms.ordered) == 2
```
[VERIFIED: scrypath_ops/test/scrypath_ops/playbook/runner_test.exs]

### Anti-Patterns to Avoid
- **Freezing UI strings as the contract:** `PlaybookLive.format_run_flash/1` and `RunFailure.enrich/2` are downstream formatting layers; Phase 66 should not make their messages the compatibility boundary. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex]
- **Mirroring the full core search suite inside `scrypath_ops`:** root tests already cover broad search/search_many behavior, so duplicate breadth would add maintenance cost more than contract confidence. [VERIFIED: 66-CONTEXT.md][VERIFIED: test/scrypath/search_test.exs][VERIFIED: test/scrypath/search_many_test.exs]
- **Adding a public error struct prematurely:** the phase context explicitly defers that semver commitment. [VERIFIED: 66-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public execution error abstraction | `%RunError{}` or a new public normalized runner struct | Raw `{:error, reason}` from `Runner` plus `RunFailure` at the edge | The repo already has a working tuple seam and downstream enrichment boundary. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex] |
| Broad parity harness | Meta-framework that replays the full core suite through runner | 4-5 explicit representative tests in `runner_test.exs` | The root suite already covers general behavior; Phase 66 only needs contract-seam regressions. [VERIFIED: 66-CONTEXT.md][VERIFIED: test/scrypath/search_test.exs][VERIFIED: test/scrypath/search_many_test.exs] |
| Shared string formatter across all surfaces | One canonical UI/CLI message renderer | Keep `Scrypath.Errors`, CLI formatting, `RunFailure`, and `PlaybookLive` separate | Discuss decisions lock semantic parity, not presentation parity, and those boundaries already exist in code. [VERIFIED: 66-CONTEXT.md][VERIFIED: lib/scrypath/errors.ex][VERIFIED: lib/scrypath/cli/operator_task.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] |

**Key insight:** The value of Phase 66 is contract clarity, not abstraction. The code already has the right boundary pieces; planning should document and test them rather than introducing a new shared facade. [VERIFIED: codebase grep][VERIFIED: 66-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Documenting the Wire Format as If It Were the Execution Contract
**What goes wrong:** `playbook-schema-v1.md` starts carrying runner result/error semantics, which duplicates or drifts from `Runner`. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/docs/playbook-schema-v1.md]  
**Why it happens:** The schema doc already describes dispatch inputs and troubleshooting, so it is tempting to extend it further. [VERIFIED: scrypath_ops/docs/playbook-schema-v1.md]  
**How to avoid:** Put the canonical tuple contract in `Runner` `@moduledoc` and add a link from `playbook-schema-v1.md` to that section. [VERIFIED: 66-CONTEXT.md]  
**Warning signs:** The same success/error shapes appear in both docs, or tests/assertions need to update two different contract texts. [VERIFIED: 66-CONTEXT.md]

### Pitfall 2: Testing Presentation Copy Instead of Semantic Parity
**What goes wrong:** Tests become brittle because they pin `format_run_flash/1` or `RunFailure` copy rather than the stable reason/result shapes. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex]  
**Why it happens:** OPSUI currently has visible strings for many failures, and those are easier to assert than structural contracts. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs]  
**How to avoid:** Assert `%SearchResult{}` vs `%MultiSearchResult{}`, exact reason heads, and downstream ownership boundaries; leave copy-anchor contract expansion to Phase 67. [VERIFIED: 66-CONTEXT.md][VERIFIED: lib/scrypath.ex]  
**Warning signs:** Test names or failures talk about wording equality across UI, CLI, and library paths. [VERIFIED: 66-CONTEXT.md]

### Pitfall 3: Swallowing Divergence Behind Rescue or Async Normalization
**What goes wrong:** A runner-adjacent path converts failures into generic values or UI-only outcomes, hiding semantic drift from operators and tests. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex]  
**Why it happens:** `module_in_allowlist/2` rescues `ArgumentError` and LiveView normalizes async exits to `:cancelled` / `:timed_out`, so it is easy to over-generalize error handling. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex]  
**How to avoid:** Keep rescue scope narrow, add explicit parity cases for pre-dispatch failures and backend/runtime failures, and preserve telemetry stop events for cancellations/timeouts. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex]  
**Warning signs:** A new `rescue` appears in runner/adapter code, or a failure path bypasses `{:error, reason}` and lands only in flash/UI state. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from repository sources:

### Canonical Runner Contract Surface
```elixir
# Source: scrypath_ops/lib/scrypath_ops/playbook/runner.ex
@spec run_validated(map() | {:ok, map()}, [module()], keyword()) ::
        {:ok, term()} | {:error, term()}

def run_validated({:error, _}, _, _) do
  {:error, :playbook_not_validated}
end
```
[VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex]

### Core Library Errors-vs-Raises Pattern
```elixir
# Source: lib/scrypath/search.ex
def search!(schema_module, text, opts \\ []) do
  case search(schema_module, text, opts) do
    {:ok, result} -> result
    {:error, reason} -> raise Scrypath.Search.Error, reason: reason
  end
end
```
[VERIFIED: lib/scrypath/search.ex]

### Existing Async Test Pattern to Reuse
```elixir
# Source: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
running_html = render_click(view, "run", %{})
assert running_html =~ "Running playbook"

html = render_async(view)
assert html =~ "Run finished"
```
[VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Runner tuple seam existed but was only minimally documented | Phase 66 discuss scope locks `Runner` `@moduledoc` as the single canonical execution-contract reference | Locked on 2026-04-22 in Phase 66 context | Planning can treat documentation as part of the contract surface, not an afterthought. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex] |
| OPSUI run lifecycle work focused on async state, failure enrichment, and telemetry | Phase 66 is the follow-on contract freeze and parity-test slice | Phase 65 completed on 2026-04-22; Phase 66 opened the same day | The repo already has stable async/run plumbing, so this phase can stay narrow. [VERIFIED: STATE.md][VERIFIED: ROADMAP.md][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] |
| Ad hoc success smoke tests in `runner_test.exs` | Representative cross-boundary parity matrix is now required | Locked in Phase 66 context | Test work should expand depth selectively, not broadly. [VERIFIED: scrypath_ops/test/scrypath_ops/playbook/runner_test.exs][VERIFIED: 66-CONTEXT.md] |

**Deprecated/outdated:**
- Treating `playbook-schema-v1.md` as the execution-contract authority is outdated for Phase 66; it remains the JSON wire-format authority only. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/docs/playbook-schema-v1.md]

## Assumptions Log

All claims in this research were verified from repository files, lockfiles, local environment probes, or targeted test runs in this session. [VERIFIED: codebase grep][VERIFIED: local env][VERIFIED: targeted test run]

## Open Questions (RESOLVED)

1. **Should Phase 66 add local `@typedoc` aliases inside `Runner`?**
   - Resolution: treat local `@typedoc` aliases as optional polish, not a requirement of the phase. The plan should not depend on them, and any typedoc added must remain subordinate to the raw tuple seam rather than introducing new public abstraction vocabulary. [VERIFIED: 66-CONTEXT.md]
   - Planning consequence: Plan 01 centers the canonical `@moduledoc` contract text; typedocs are permitted only if they make that section clearer without changing the public contract. [VERIFIED: 66-CONTEXT.md][VERIFIED: .planning/phases/66-runner-library-contract/66-01-PLAN.md]

2. **Which multi-search edge case should occupy the single operator-relevant parity slot?**
   - Resolution: use `{:invalid_options, {:federation_merge_requires_native_search_many, %{backend: _}}}` as the operator-relevant multi-search parity case. It is a true cross-boundary tuple error, already has strong core coverage, and keeps Phase 66 focused on semantic parity rather than partial-result presentation. [VERIFIED: test/scrypath/search_many_test.exs][VERIFIED: scrypath_ops/docs/playbook-schema-v1.md]
   - Planning consequence: Plan 02 should prefer that tuple error for the multi-search-specific slot unless an equivalent existing fixture proves clearer while preserving the same contract shape. [VERIFIED: .planning/phases/66-runner-library-contract/66-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Root and `scrypath_ops` compilation/tests | ✓ | 1.19.5 | — [VERIFIED: local env] |
| OTP | Elixir runtime | ✓ | 28 | — [VERIFIED: local env] |
| Mix | All verification commands | ✓ | 1.19.5 | — [VERIFIED: local env] |
| PostgreSQL CLI/server binaries | `scrypath_ops` test alias creates/migrates the test DB | ✓ | 14.17 | Use existing local install; no code fallback needed. [VERIFIED: local env][VERIFIED: scrypath_ops/mix.exs] |
| Meilisearch | Not required for the recommended Phase 66 verification path | n/a | — | Stub adapter already covers runner/OPSUI tests. [VERIFIED: scrypath_ops/test/support/search_playground_stub_adapter.ex][VERIFIED: lib/mix/tasks/verify.opsui.ex] |

**Missing dependencies with no fallback:**
- None found for the recommended Phase 66 planning/verification path. [VERIFIED: local env][VERIFIED: targeted test run]

**Missing dependencies with fallback:**
- None. [VERIFIED: local env]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5, plus Phoenix LiveViewTest in `scrypath_ops` [VERIFIED: local env][VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] |
| Config file | No `pytest`/Jest-style config; root uses [test/test_helper.exs](/Users/jon/projects/scrypath/test/test_helper.exs:1) and ops uses [scrypath_ops/test/test_helper.exs](/Users/jon/projects/scrypath/scrypath_ops/test/test_helper.exs:1) [VERIFIED: test/test_helper.exs][VERIFIED: scrypath_ops/test/test_helper.exs] |
| Quick run command | `mix test test/scrypath/search_test.exs test/scrypath/search_many_test.exs scrypath_ops/test/scrypath_ops/playbook/runner_test.exs scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` [VERIFIED: targeted test run] |
| Full suite command | `mix test && mix verify.opsui` [VERIFIED: mix.exs][VERIFIED: lib/mix/tasks/verify.opsui.ex] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPS3-03 | `Runner.run_validated/3` returns the documented tuple seam with mode-specific success structs | unit | `mix test scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` | ✅ [VERIFIED: scrypath_ops/test/scrypath_ops/playbook/runner_test.exs] |
| OPS3-03 | Core library path preserves `{:error, reason}` vs bang semantics for `search/3` and `search_many/2` | unit | `mix test test/scrypath/search_test.exs test/scrypath/search_many_test.exs` | ✅ [VERIFIED: test/scrypath/search_test.exs][VERIFIED: test/scrypath/search_many_test.exs] |
| OPS3-03 | OPSUI keeps enrichment downstream from the raw runner reason | integration | `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | ✅ [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] |
| OPS3-03 | Mix/operator formatting remains downstream from raw reasons | unit | `mix test test/scrypath/mix_tasks/operator_tasks_test.exs` | ✅ [VERIFIED: test/scrypath/mix_tasks/operator_tasks_test.exs] |
| OPS3-03 | Canonical runner contract text remains discoverable in docs | unit/doc contract | `mix test test/scrypath/docs_contract_test.exs` | ✅, but Phase 67 is the planned place to widen this. [VERIFIED: REQUIREMENTS.md][VERIFIED: ROADMAP.md][VERIFIED: test/scrypath/docs_contract_test.exs] |

### Sampling Rate
- **Per task commit:** `mix test test/scrypath/search_test.exs test/scrypath/search_many_test.exs scrypath_ops/test/scrypath_ops/playbook/runner_test.exs scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` [VERIFIED: targeted test run]
- **Per wave merge:** `mix test test/scrypath/search_test.exs test/scrypath/search_many_test.exs test/scrypath/mix_tasks/operator_tasks_test.exs && mix test scrypath_ops/test/scrypath_ops/playbook/runner_test.exs scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` [VERIFIED: targeted test run]
- **Phase gate:** `mix test && mix verify.opsui` [VERIFIED: mix.exs][VERIFIED: lib/mix/tasks/verify.opsui.ex]

### Wave 0 Gaps
- [ ] Add Phase 66 parity cases to `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` for one pre-dispatch config failure, one backend/runtime failure, and one multi-search-specific tuple edge. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/test/scrypath_ops/playbook/runner_test.exs]
- [ ] Add one doc-presence assertion for the `Runner` contract section, likely in a phase-local test first and broader docs-contract expansion in Phase 67. [VERIFIED: ROADMAP.md][VERIFIED: 66-CONTEXT.md][VERIFIED: test/scrypath/docs_contract_test.exs]
- [ ] Add at least one boundary test proving `RunFailure`/`PlaybookLive` consume a raw reason rather than redefining it. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs][VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not in scope for this phase; no auth changes are planned. [VERIFIED: ROADMAP.md][VERIFIED: 66-CONTEXT.md] |
| V3 Session Management | no | No session behavior changes are planned; Phase 66 is contract and test depth only. [VERIFIED: ROADMAP.md][VERIFIED: 66-CONTEXT.md] |
| V4 Access Control | no | No allowlist or auth-policy broadening is planned beyond existing schema allowlist checks. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex][VERIFIED: ROADMAP.md] |
| V5 Input Validation | yes | `ScrypathOps.Playbook.V1.validate/1` rejects unknown keys and banned secrets, while runner pre-dispatch checks reject invalid config/shape cases. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/v1.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex] |
| V6 Cryptography | no | No crypto work is introduced in this phase. [VERIFIED: ROADMAP.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom exhaustion or unsafe module resolution from playbook JSON | Denial of Service | Keep JSON string-keyed, use `String.to_existing_atom/1`, and rescue only `ArgumentError` in the allowlist lookup. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/v1.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex] |
| Secret leakage in diagnostics or saved playbooks | Information Disclosure | Continue rejecting banned keys in `V1.validate/1` and allowlisting diagnostic copy keys in `RunFailure`. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/v1.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex] |
| Silent failure normalization that hides operator-visible contract drift | Repudiation | Preserve raw `{:error, reason}` paths, emit telemetry start/stop, and add explicit parity tests for cancellation/error boundaries. [VERIFIED: 66-CONTEXT.md][VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] |

## Sources

### Primary (HIGH confidence)
- `AGENTS.md` - project constraints and stack expectations checked. [VERIFIED: AGENTS.md]
- `.planning/phases/66-runner-library-contract/66-CONTEXT.md` - locked decisions, parity scope, and deferred items. [VERIFIED: 66-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - requirement text for OPS3-03. [VERIFIED: REQUIREMENTS.md]
- `.planning/ROADMAP.md` - phase goal and success criteria. [VERIFIED: ROADMAP.md]
- `.planning/STATE.md` - Phase 65 completion and Phase 66 positioning. [VERIFIED: STATE.md]
- `scrypath_ops/lib/scrypath_ops/playbook/runner.ex` - runner contract and rescue scope. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex]
- `scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex` - failure enrichment boundary. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex]
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` - downstream formatting, async normalization, and telemetry. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex]
- `scrypath_ops/lib/scrypath_ops/search_playground.ex` and `adapter.ex` - dispatch seam from runner to core `Scrypath`. [VERIFIED: scrypath_ops/lib/scrypath_ops/search_playground.ex][VERIFIED: scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex]
- `lib/scrypath.ex`, `lib/scrypath/search.ex`, `lib/scrypath/errors.ex`, `lib/scrypath/cli/operator_task.ex` - core contract, bang semantics, and formatting boundaries. [VERIFIED: lib/scrypath.ex][VERIFIED: lib/scrypath/search.ex][VERIFIED: lib/scrypath/errors.ex][VERIFIED: lib/scrypath/cli/operator_task.ex]
- `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs`, `run_failure_test.exs`, `scrypath_ops_web/live/playbook_live_test.exs`, `test/scrypath/search_test.exs`, `test/scrypath/search_many_test.exs`, `test/scrypath/mix_tasks/operator_tasks_test.exs` - current verification patterns and reusable fixtures. [VERIFIED: targeted test run][VERIFIED: codebase grep]
- `mix.lock`, `scrypath_ops/mix.lock`, `mix.exs`, `scrypath_ops/mix.exs` - version and verification command data. [VERIFIED: mix.lock][VERIFIED: scrypath_ops/mix.lock][VERIFIED: mix.exs][VERIFIED: scrypath_ops/mix.exs]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)
- None. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies are recommended and all named versions were verified from lockfiles or the local runtime. [VERIFIED: mix.lock][VERIFIED: scrypath_ops/mix.lock][VERIFIED: local env]
- Architecture: HIGH - the relevant boundaries are all present in first-party code and phase context. [VERIFIED: codebase grep][VERIFIED: 66-CONTEXT.md]
- Pitfalls: HIGH - each pitfall maps to concrete existing seams or explicit discuss-phase decisions. [VERIFIED: codebase grep][VERIFIED: 66-CONTEXT.md]

**Research date:** 2026-04-22 [VERIFIED: local env]  
**Valid until:** 2026-05-22 for repository-internal planning unless Phase 66 or adjacent files change first. [VERIFIED: local env]
