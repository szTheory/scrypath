# Phase 9: Public Docs and Example Safety - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Scrypath's public adoption path copy-paste safe by removing misleading install guidance, hardening the Phoenix JSON example around real request shapes, and tightening the example-test surface so public docs model realistic Phoenix inputs without turning the library into a Phoenix app template.

</domain>

<decisions>
## Implementation Decisions

### Install contract
- **D-01:** The primary README install path should list only direct public dependencies. For Phase 9, that means `{:scrypath, "~> x.y"}` only in the canonical install snippet.
- **D-02:** Do not ask users to add `:req` directly in public install guidance. `Req` is an internal transport dependency, not part of the intended consumer contract.
- **D-03:** Keep Meilisearch-first positioning explicit in usage/setup guidance, but express it as runtime configuration and usage examples, not as a requirement to pin Scrypath's transport stack manually.
- **D-04:** Optional integrations should be documented as optional. If Oban setup is mentioned in install-adjacent docs, it must be clearly separated as "only for `sync_mode: :oban`", not blended into the base install path.

### Phoenix JSON pagination example
- **D-05:** The public JSON controller example should parse `params["page"]` safely and never use `String.to_integer/1` directly on untrusted request input.
- **D-06:** Missing, malformed, zero, and negative `page` params should normalize to page `1` in the primary docs example.
- **D-07:** Keep pagination normalization local to the request/example layer in the docs. The example should teach that controllers handle request-shape concerns and contexts own search orchestration.
- **D-08:** Do not make strict `400` invalid-query handling the primary Scrypath docs path. It can be mentioned as an advanced application-level option, but the copy-paste-safe default should be lenient normalization.

### Phoenix example realism and safety tests
- **D-09:** Fixture-backed docs tests should model real Phoenix string-keyed request shapes consistently across controllers, LiveView, and publish/update examples.
- **D-10:** Public examples should prefer web-realistic nested attr payloads such as `%{"post" => %{"title" => ...}}` where that is the real Phoenix shape, instead of teaching atom-keyed attrs that users are unlikely to receive from requests.
- **D-11:** Keep the existing fixture-module and docs-contract approach as the main documentation safety harness; do not expand the repo into a full embedded Phoenix example app.
- **D-12:** Add one narrow real Phoenix smoke path only where it materially increases trust for copied examples, especially around the string-keyed publish/LiveView path that the current plain fixtures can mis-model.

### the agent's Discretion
- Exact sectioning between `README.md` and guides, as long as the base install contract stays focused on direct dependencies and optional integrations remain clearly optional.
- Exact helper name and implementation shape for safe page normalization, provided the docs example stays non-raising and clearly 1-based.
- Whether the narrow real Phoenix smoke path is controller-focused, LiveView-focused, or one combined happy-path check, provided it stays minimal and targeted at the known request-shape footgun.

</decisions>

<specifics>
## Specific Ideas

- The canonical install snippet should move from:
  `{:scrypath, "~> 0.1.0"}, {:req, "~> 0.5"}`
  to a Scrypath-only dependency snippet, with backend/runtime details shown separately in usage docs.
- The JSON example should use a safe helper based on `Integer.parse/1` and treat invalid input as page `1`, avoiding a 500-prone `String.to_integer/1` example.
- The docs suite should keep proving the context-first Phoenix boundary while also proving that copied examples use realistic string-keyed request payloads.
- The guiding DX posture for this phase is least surprise: a Phoenix team copying the docs should not accidentally pin the wrong dependency surface, crash on malformed page params, or learn an attr shape that differs from real request payloads.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase definition
- `.planning/ROADMAP.md` — Phase 9 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — `DOCS-01`, `DOCS-02`, and `DOCS-03`.
- `.planning/PROJECT.md` — v1.1 launch-readiness posture, DX priorities, and public trust constraints.
- `.planning/STATE.md` — current milestone position and Phase 6/8 decisions that still constrain public docs language.
- `.planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md` — latest locked decisions around operational wording, explicit contracts, and phase discipline.

### Current public docs and fixtures
- `README.md` — current install snippet and public adoption path.
- `guides/getting-started.md` — current quick-start flow and install-adjacent guidance.
- `guides/phoenix-walkthrough.md` — canonical context-first Phoenix adoption story.
- `guides/phoenix-contexts.md` — locked context-first boundary that Phase 9 must preserve.
- `guides/phoenix-controllers-and-json.md` — JSON controller example with current page-normalization footgun.
- `guides/phoenix-liveview.md` — LiveView example that must keep realistic request/attr boundaries.
- `guides/sync-modes-and-visibility.md` — optional async guidance and visibility wording that should remain explicit.
- `test/scrypath/docs_contract_test.exs` — public-docs contract assertions that Phase 9 will need to extend.
- `test/support/docs/phoenix_example_case.ex` — fixture-backed Phoenix example source of truth.
- `test/support/docs/phoenix_examples_test.exs` — fixture behavior tests currently validating copied examples.

### Library contracts relevant to the examples
- `lib/scrypath/query.ex` — current pagination/result contract surface that the docs examples should reflect.
- `lib/scrypath/options.ex` — nested common-path pagination option shape.
- `test/scrypath/search_test.exs` — current pagination validation expectations on the library side.

### Local research context
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Elixir OSS public API and docs-surface guidance.
- `prompts/elixir-best-practices-deep-research.md` — explicit non-raising API and least-surprise guidance.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — library/runtime boundary guidance for Phoenix/Ecto systems.
- `prompts/phoenix-best-practices-deep-research.md` — controller/context boundary guidance.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — LiveView/context and request-shape guidance.
- `prompts/elixir-search-lib-deep-research.md` — search-library DX and operational lessons relevant to Scrypath's public posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/support/docs/phoenix_example_case.ex` already centralizes the public Phoenix example contract and is the right place to tighten request-shape realism.
- `test/support/docs/phoenix_examples_test.exs` already proves docs snippets stay executable and is the natural place to add page-normalization and string-key shape assertions.
- `test/scrypath/docs_contract_test.exs` already guards wording and snippet presence across README and guides, so Phase 9 can extend that contract rather than inventing a separate docs test architecture.

### Established Patterns
- Scrypath's docs already teach a context-first Phoenix boundary; Phase 9 should preserve that instead of introducing heavier controller or LiveView orchestration.
- Public docs and tests already treat examples as executable contracts, which supports tightening realism rather than rewriting the whole docs system.
- Prior phases locked explicit, operationally honest wording; Phase 9 should keep the docs practical and safe without hiding tradeoffs behind magic setup.

### Integration Points
- README install guidance, Getting Started, and sync-mode docs need to line up so the direct dependency contract and optional Oban guidance do not drift.
- The JSON controller guide, fixture source, and docs tests must all agree on safe page parsing behavior.
- LiveView/context publish examples and any added smoke coverage must agree on string-keyed request attrs so copied examples stay trustworthy.

</code_context>

<deferred>
## Deferred Ideas

- A stricter application-level API validation example that returns `400 Bad Request` for malformed pagination params; useful later as advanced guidance, but not the primary Phase 9 copy-paste path.
- A larger embedded Phoenix fixture app or broad end-to-end browser-style docs harness; out of scope for this phase because it would shift the repo toward template maintenance.
- Broader docs restructuring or new Phoenix feature surfaces beyond the current safety and example-hardening scope.

</deferred>

---

*Phase: 09-public-docs-and-example-safety*
*Context gathered: 2026-04-16*
