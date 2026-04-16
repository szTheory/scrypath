# Phase 9: Public Docs and Example Safety - Research

**Researched:** 2026-04-16
**Domain:** Public docs contract hardening for README install guidance, Phoenix JSON request handling, and fixture-backed example realism [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Install contract
- **D-01:** The primary README install path should list only direct public dependencies, which for Phase 9 means `{:scrypath, "~> x.y"}` only in the canonical install snippet [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- **D-02:** Public install guidance must not ask users to add `:req` directly because `Req` is an internal transport dependency, not part of the intended consumer contract [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- **D-03:** Meilisearch-first positioning should remain explicit, but as runtime configuration and usage guidance rather than install-time dependency pinning [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- **D-04:** Optional integrations such as Oban must remain clearly optional and separated from the base install path [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].

### Phoenix JSON pagination example
- **D-05:** The public JSON controller example must never use `String.to_integer/1` on untrusted request input [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- **D-06:** Missing, malformed, zero, and negative `page` params should normalize to page `1` in the primary docs path [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- **D-07:** Request-shape normalization belongs in the docs example layer while contexts continue to own search orchestration [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md] [VERIFIED: guides/phoenix-contexts.md].
- **D-08:** Strict `400` handling is deferred; the primary copy-paste-safe docs path should be lenient and non-raising [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].

### Phoenix example realism and safety tests
- **D-09:** Fixture-backed docs tests should use real Phoenix-style string-keyed request shapes across controllers, LiveView, and publish/update examples [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- **D-10:** Public examples should prefer nested attr payloads such as `%{"post" => %{"title" => ...}}` where that matches Phoenix request reality [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- **D-11:** The existing fixture-module and docs-contract approach remains the primary safety harness; this phase should not introduce a full embedded Phoenix app [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- **D-12:** Add one narrow request-shape smoke path only where it materially increases trust for copied examples, especially the string-keyed publish/LiveView path [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].

### the agent's Discretion
- Exact section placement between `README.md` and guides, as long as the public dependency contract stays narrow and optional integrations remain clearly optional [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- Exact helper naming for safe page normalization, provided it stays non-raising and 1-based [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- Whether the narrow smoke path is Plug-shaped or fixture-shaped, provided it proves realistic string-key request payloads without adding Phoenix as a project dependency [VERIFIED: mix.exs] [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].

### Deferred Ideas (OUT OF SCOPE)
- Advanced `400 Bad Request` API validation examples for malformed pagination [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- A full embedded Phoenix example app or browser-style docs harness [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
- Broad docs IA changes beyond copy-paste safety and example realism [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | Phoenix developer can install Scrypath from the README without copying unnecessary direct dependencies or misleading setup steps. | The current README still tells users to add `{:req, "~> 0.5"}` directly, so Phase 9 must tighten README plus install-adjacent docs and guard the contract in docs tests [VERIFIED: README.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: test/scrypath/docs_contract_test.exs]. |
| DOCS-02 | Phoenix developer can copy the JSON controller pagination example and get safe handling for invalid page params instead of a 500-prone example. | The current guide and fixture both use `String.to_integer/1`, and the fixture tests explicitly codify that unsafe behavior, so the phase must update docs, fixtures, and tests together [VERIFIED: guides/phoenix-controllers-and-json.md] [VERIFIED: test/support/docs/phoenix_example_case.ex] [VERIFIED: test/support/docs/phoenix_examples_test.exs] [VERIFIED: .planning/REQUIREMENTS.md]. |
| DOCS-03 | Phoenix developer can copy the LiveView and context examples knowing the fixture-backed docs tests model real Phoenix string-keyed parameter shapes. | The current publish fixture reads atom keys from `%{title: ...}` even though the docs show `%{\"post\" => attrs}` event payloads, so the phase should align the fixture and add one narrow request-shape smoke test without turning the repo into a Phoenix app [VERIFIED: guides/phoenix-liveview.md] [VERIFIED: test/support/docs/phoenix_example_case.ex] [VERIFIED: test/support/docs/phoenix_examples_test.exs] [VERIFIED: .planning/REQUIREMENTS.md]. |
</phase_requirements>

## Summary

The codebase already has the right public-docs safety harness for this phase: `README.md` and the Phoenix guides are treated as executable contracts through `test/scrypath/docs_contract_test.exs` and the fixture-backed `test/support/docs/phoenix_examples_test.exs` suite [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: test/support/docs/phoenix_examples_test.exs]. Phase 9 should strengthen those existing seams instead of adding a second docs framework [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].

The highest-risk hazard is public contract drift. The README currently tells consumers to pin `:req` directly even though the library itself already depends on `Req`, and the current docs tests only assert that `{:scrypath, "~> 0.1.0"}` is present rather than proving the transport dependency is absent from the install path [VERIFIED: README.md] [VERIFIED: mix.exs] [VERIFIED: test/scrypath/docs_contract_test.exs]. That kind of drift is exactly the sort of copy-paste footgun Elixir OSS guidance warns against: public APIs should stay small, explicit, and stable, with internal details hidden behind the library boundary [VERIFIED: prompts/elixir-opensource-libs-best-practices-deep-research.md].

The second hazard is exception-driven request parsing in the JSON example. Both the guide and the fixture normalize `page` with `String.to_integer/1`, and the fixture tests assert that exact code path, which means the current safety harness is preserving a crash-prone example instead of rejecting it [VERIFIED: guides/phoenix-controllers-and-json.md] [VERIFIED: test/support/docs/phoenix_example_case.ex] [VERIFIED: test/support/docs/phoenix_examples_test.exs]. Phoenix and general Elixir guidance both push request parsing and validation to the web boundary and recommend non-raising control flow for expected invalid input [VERIFIED: prompts/phoenix-best-practices-deep-research.md] [VERIFIED: prompts/elixir-best-practices-deep-research.md].

The final gap is fixture realism. The LiveView docs show `%{"post" => attrs}` request payloads, but the fixture’s `publish_post/2` implementation only reads atom keys and the test calls `handle_event/3` with `%{"post" => %{title: "Published"}}`, a shape Phoenix would not produce from a real browser form [VERIFIED: guides/phoenix-liveview.md] [VERIFIED: test/support/docs/phoenix_example_case.ex] [VERIFIED: test/support/docs/phoenix_examples_test.exs]. Because the repo intentionally does not depend on Phoenix, the right correction is a narrow Plug-shaped or string-keyed request smoke path rather than a full Phoenix harness [VERIFIED: mix.exs] [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].

**Primary recommendation:** Split Phase 9 into three plans: one for the public install contract across README and install-adjacent docs, one for safe JSON pagination examples plus fixture/test alignment, and one for string-keyed LiveView/context publish realism with a narrow request-shape smoke test [VERIFIED: README.md] [VERIFIED: guides/getting-started.md] [VERIFIED: guides/phoenix-controllers-and-json.md] [VERIFIED: guides/phoenix-liveview.md].

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|-----------|--------------|----------------|-----------|
| Public dependency contract | Docs shell | Docs contract tests | README and getting-started pages define the first-copy install path, while `docs_contract_test.exs` should lock the contract against future drift [VERIFIED: README.md] [VERIFIED: guides/getting-started.md] [VERIFIED: test/scrypath/docs_contract_test.exs]. |
| Safe request-page normalization | Phoenix JSON guide + fixture | Fixture behavior tests | Request parsing belongs in the controller example layer and needs executable fixture coverage so the docs stay non-raising over time [VERIFIED: guides/phoenix-controllers-and-json.md] [VERIFIED: test/support/docs/phoenix_example_case.ex] [VERIFIED: test/support/docs/phoenix_examples_test.exs]. |
| String-keyed publish/update realism | LiveView guide + fixture boundary | Narrow request-shape smoke test | The docs already teach the context-first boundary; the missing piece is realistic string-key request payload coverage for copied examples [VERIFIED: guides/phoenix-liveview.md] [VERIFIED: guides/phoenix-contexts.md] [VERIFIED: test/support/docs/phoenix_example_case.ex]. |
| Runtime pagination contract fidelity | Library pagination options/search tests | Docs examples | The docs should normalize request input to the library’s existing 1-based positive pagination contract instead of widening the library surface [VERIFIED: lib/scrypath/query.ex] [VERIFIED: lib/scrypath/options.ex] [VERIFIED: test/scrypath/search_test.exs]. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.17` floor, local project baseline [VERIFIED: mix.exs] | Docs fixtures and ExUnit harnesses | The phase only needs plain functions, pattern matching, and fixture tests; no additional runtime abstraction is justified [VERIFIED: mix.exs] [VERIFIED: prompts/elixir-best-practices-deep-research.md]. |
| ExUnit | bundled | Documentation contract verification | Existing docs safety already runs through ExUnit and should remain the phase’s primary guardrail [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: test/support/docs/phoenix_examples_test.exs]. |
| Plug | `~> 1.18`, test-only dependency [VERIFIED: mix.exs] | Optional narrow request-shape smoke path | Plug is already available in test scope and can model form/query decoding without adding Phoenix to the library [VERIFIED: mix.exs] [VERIFIED: prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md]. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExDoc extras | project docs config [VERIFIED: mix.exs] | Ordered public docs shell | Keep README and guides aligned with the existing extras ordering rather than restructuring docs wholesale [VERIFIED: mix.exs]. |
| NimbleOptions | `~> 1.1` [VERIFIED: mix.exs] | Existing pagination contract backing | No direct changes expected, but Phase 9 should respect the existing positive page-number constraints already enforced by runtime options [VERIFIED: lib/scrypath/options.ex] [VERIFIED: test/scrypath/search_test.exs]. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing fixture-backed docs tests [VERIFIED: test/support/docs/phoenix_examples_test.exs] | Add a full Phoenix fixture app [ASSUMED] | Much higher maintenance cost and a direct violation of D-11’s “no embedded app” constraint [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md]. |
| Plug-based request-shape smoke path [VERIFIED: mix.exs] | Add Phoenix as a test dependency [ASSUMED] | Unnecessary dependency weight for a library whose docs safety can be proven with string-keyed request inputs and Plug helpers [VERIFIED: mix.exs]. |
| Narrow docs-contract assertions [VERIFIED: test/scrypath/docs_contract_test.exs] | Manual review of README/guides each release [ASSUMED] | Manual review will miss copy-paste hazards that executable docs tests can catch deterministically [VERIFIED: test/scrypath/docs_contract_test.exs]. |

## Architecture Patterns

### Pattern 1: Public Install Contract Anchored In README + Contract Tests
**What:** Keep the canonical dependency snippet in `README.md`, keep install-adjacent guide wording aligned, and lock the contract in `docs_contract_test.exs` [VERIFIED: README.md] [VERIFIED: guides/getting-started.md] [VERIFIED: test/scrypath/docs_contract_test.exs].  
**When to use:** Any time a public snippet exposes dependencies, required setup, or optional integrations [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].  
**Example:**
```elixir
# Source: /Users/jon/projects/scrypath/README.md
def deps do
  [
    {:scrypath, "~> 0.1.0"}
  ]
end
```

### Pattern 2: Lenient Request Normalization At The Example Boundary
**What:** Normalize request params locally in the controller example before handing validated positive pagination data to the context [VERIFIED: guides/phoenix-controllers-and-json.md] [VERIFIED: lib/scrypath/options.ex].  
**When to use:** Public controller examples that accept user-controlled query params [VERIFIED: prompts/phoenix-best-practices-deep-research.md].  
**Example:**
```elixir
defp normalize_page(page) when is_integer(page) and page > 0, do: page

defp normalize_page(page) when is_binary(page) do
  case Integer.parse(page) do
    {number, ""} when number > 0 -> number
    _ -> 1
  end
end

defp normalize_page(_page), do: 1
```

### Pattern 3: Fixture Modules As Docs Source Of Truth
**What:** Keep one plain Elixir fixture module that mirrors the public docs boundary, then verify the docs and fixture behavior against each other [VERIFIED: test/support/docs/phoenix_example_case.ex] [VERIFIED: test/support/docs/phoenix_examples_test.exs].  
**When to use:** Public guides whose code fences should remain compile-trustworthy and behaviorally realistic without needing framework runtime [VERIFIED: .planning/STATE.md].  
**Example:**
```elixir
def handle_event("publish", %{"id" => id, "post" => attrs}, socket) do
  post = Content.get_post!(id)
  {:ok, _post} = Content.publish_post(post, attrs)

  socket
end
```

### Pattern 4: Narrow Request-Shape Smoke Test
**What:** Use Plug helpers or direct string-key maps to prove nested request shapes stay realistic without bringing Phoenix into the dependency graph [VERIFIED: mix.exs].  
**When to use:** When fixture code can drift from actual request payloads even though the public boundary looks correct on paper [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].  
**Example:**
```elixir
params = Plug.Conn.Query.decode("post[title]=Published&page=-3")

assert %{"post" => %{"title" => "Published"}, "page" => "-3"} = params
```

### Anti-Patterns To Avoid
- **Leaking internal dependencies into public setup:** The README currently leaks `Req` into the consumer contract even though the library already owns that dependency internally [VERIFIED: README.md] [VERIFIED: mix.exs].
- **Using `String.to_integer/1` on user input in docs:** The current JSON example turns malformed request params into runtime exceptions rather than a safe default [VERIFIED: guides/phoenix-controllers-and-json.md] [VERIFIED: test/support/docs/phoenix_example_case.ex].
- **Teaching atom-key request attrs in Phoenix-facing examples:** `%{title: "Published"}` is a fixture convenience, not the real browser/request shape users receive [VERIFIED: test/support/docs/phoenix_examples_test.exs] [VERIFIED: guides/phoenix-liveview.md].
- **Solving docs trust with a new framework harness:** Phase 9 should deepen the existing contract tests, not widen repo scope into a demo app [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Framework realism | A full Phoenix example application [ASSUMED] | Existing fixtures plus a narrow Plug-shaped smoke test [VERIFIED: mix.exs] [VERIFIED: test/support/docs/phoenix_example_case.ex] | The repo already has executable docs fixtures and only needs request-shape realism, not a full web stack [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md]. |
| Pagination parsing | Regexes or exception-driven integer conversion [ASSUMED] | `Integer.parse/1` plus positive-number guards [VERIFIED: prompts/elixir-best-practices-deep-research.md] | Expected invalid input should stay non-raising and local to the example boundary. |
| Contract drift detection | Ad hoc human review [ASSUMED] | `docs_contract_test.exs` and `phoenix_examples_test.exs` assertions [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: test/support/docs/phoenix_examples_test.exs] | Existing test seams are already the project’s docs safety harness. |

## Common Pitfalls

### Pitfall 1: Public README Drifts Away From The Real Consumer Contract
**What goes wrong:** Users copy internal or optional setup into their base install path and learn the wrong dependency boundary [VERIFIED: README.md].  
**Why it happens:** The README is optimized for helpfulness and can gradually accrete backend/runtime details into the install snippet [VERIFIED: README.md] [VERIFIED: guides/getting-started.md].  
**How to avoid:** Keep the install code fence to `{:scrypath, "~> 0.1.0"}`, move backend/runtime notes into explanatory prose, and assert the absence of `:req` in install-specific docs tests [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].  
**Warning signs:** Docs tests only assert presence of `Scrypath` and never refute `Req` or other transport/setup leakage [VERIFIED: test/scrypath/docs_contract_test.exs].  

### Pitfall 2: Safe Docs Fixture Still Preserves Unsafe Parsing
**What goes wrong:** The docs look polished, but malformed `page` input still crashes because the fixture copied `String.to_integer/1` verbatim [VERIFIED: guides/phoenix-controllers-and-json.md] [VERIFIED: test/support/docs/phoenix_example_case.ex].  
**Why it happens:** The fixture suite currently asserts the unsafe helper name and implementation rather than the intended safe behavior [VERIFIED: test/support/docs/phoenix_examples_test.exs].  
**How to avoid:** Update the fixture and its tests together so behavior assertions cover `"abc"`, `"-3"`, `"0"`, and missing values normalizing to `1` [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-CONTEXT.md].  
**Warning signs:** A test still checks for `String.to_integer(page)` or only exercises `"2"` as the happy path [VERIFIED: test/support/docs/phoenix_examples_test.exs].  

### Pitfall 3: LiveView Publish Examples Hide Real Request Shapes
**What goes wrong:** The docs show `%{"post" => attrs}` but the fixture logic only succeeds for atom-key maps, so copied examples are less trustworthy than the docs claim [VERIFIED: guides/phoenix-liveview.md] [VERIFIED: test/support/docs/phoenix_example_case.ex].  
**Why it happens:** Plain Elixir fixture modules make it easy to accidentally use internal maps instead of browser/request payloads [VERIFIED: test/support/docs/phoenix_example_case.ex].  
**How to avoid:** Keep `handle_event/3` string-keyed, make `publish_post/2` accept realistic string-key attrs or normalize them locally, and add one Plug-shaped smoke test for nested request decoding [VERIFIED: mix.exs] [VERIFIED: prompts/phoenix-live-view-best-practices-deep-research.md].  
**Warning signs:** Tests pass `%{title: "Published"}` or assert only atom-key updates in the publish path [VERIFIED: test/support/docs/phoenix_examples_test.exs].  

## Validation Architecture

Phase 9 should keep one fast feedback loop centered on docs and fixture tests. The quick verification command should run `test/scrypath/docs_contract_test.exs`, `test/support/docs/phoenix_examples_test.exs`, and any added narrow request-shape smoke test in one pass. That gives low-latency protection against README drift, unsafe page normalization, and string-key fixture regressions [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: test/support/docs/phoenix_examples_test.exs].

Wave 0 is effectively already complete because ExUnit and Plug test helpers are present today [VERIFIED: mix.exs]. The only new verification artifact needed is the narrow request-shape smoke test file if Plan 03 adds it. No additional framework or CI harness work is required for this phase [VERIFIED: mix.exs].

## Code Examples

Verified patterns from repo and local research inputs:

### Existing Unsafe Pattern To Replace
```elixir
# Source: /Users/jon/projects/scrypath/test/support/docs/phoenix_example_case.ex
defp normalize_page(page) when is_integer(page), do: page
defp normalize_page(page) when is_binary(page), do: String.to_integer(page)
```

### Recommended Safe Pattern
```elixir
defp normalize_page(page) when is_integer(page) and page > 0, do: page

defp normalize_page(page) when is_binary(page) do
  case Integer.parse(page) do
    {number, ""} when number > 0 -> number
    _ -> 1
  end
end

defp normalize_page(_page), do: 1
```

### Realistic Request-Shape Pattern
```elixir
params = %{"id" => "1", "post" => %{"title" => "Published"}}

assert socket == PostLive.handle_event("publish", params, socket)
```

## RESEARCH COMPLETE

Phase 9 should stay narrowly focused on three seams: the README install contract, the JSON controller’s page normalization, and the fixture-backed realism of LiveView/context request payloads. The main risk is preserving current docs-test drift, because the existing harness still encodes the unsafe `String.to_integer/1` path and atom-keyed publish attrs.
