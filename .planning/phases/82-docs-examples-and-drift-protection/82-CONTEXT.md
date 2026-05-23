# Phase 82: Docs, examples, and drift protection - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Lock the public v1.21 story for the query-param toolkit and optional Phoenix edge helpers so adopters understand exactly what shipped, what did not, and how to use it without crossing the boundary.

This phase is about documentation architecture, example strategy, and verification contracts for the already-defined Phase 80 and 81 surfaces. It does not add a second runtime, does not broaden the public API, does not move search orchestration out of contexts, and does not turn the Phoenix helpers or example app into a framework facade.

</domain>

<decisions>
## Implementation Decisions

### Canonical doc shape
- **D-01:** Phase 82 should use a hybrid doc shape: add one short canonical request-edge guide for the v1.21 story, then update existing Phoenix guides, walkthroughs, and root wayfinding to point into it rather than duplicating its explanation.
- **D-02:** The new guide should stay narrow and explicit: browser params enter at the web edge, `Scrypath.QueryParams` owns plain-data normalization, `Scrypath.Phoenix` is optional request-edge glue, `QueryParams.to_search_args/1` feeds the app context, and `Scrypath.search/3` remains the canonical runtime path.
- **D-03:** The new guide must not become a long Phoenix subsystem guide. Controllers, LiveView, and walkthrough docs should stay role-specific and link back to the shared edge guide for the common mental model.
- **D-04:** README and root module docs should summarize the contract and route readers to the canonical guide; they should not become the canonical explanation themselves.

### Example strategy
- **D-05:** The canonical teaching surface for v1.21 should stay in HexDocs-style guides and compile-checked snippets, not in the runnable example app.
- **D-06:** `examples/phoenix_meilisearch` should remain the proof/runbook surface for real Postgres + Meilisearch + Oban integration, CI parity, and smoke commands, but not the primary teaching artifact for the public request-edge contract.
- **D-07:** Docs snippets should show the intended controller and LiveView boundaries with thin request-edge glue and context-owned search orchestration. The runnable example should prove those same patterns under real services.
- **D-08:** The public story must say this split explicitly: guides teach the boundary and API shape; the example app proves the operational path.

### Drift protection scope
- **D-09:** Phase 82 should lock targeted story contracts, not broad prose contracts. Tests should fail on boundary drift, canonical command drift, example/CI/env drift, and request-edge API drift, but should not freeze ordinary editorial wording.
- **D-10:** Keep compile-checked docs fixtures and request-shape smoke tests as the primary guard for controller/LiveView examples and accepted Plug-decoded param grammar.
- **D-11:** Add or refine docs-contract assertions only for the v1.21 public spine:
  - contexts remain canonical
  - `Scrypath.search/3` is the only runtime path
  - `Scrypath.Phoenix` is optional and pure request-edge glue
  - `%Scrypath.Query{}` is not public API
  - example README, CI job, and local smoke instructions stay aligned
- **D-12:** Do not promote the entire broad `docs_contract_test.exs` prose suite into default CI unchanged. If Phase 82 adds a new verify surface, keep it contract-shaped and contributor-friendly.

### Phoenix optionality and doc hierarchy
- **D-13:** Root docs and "start here" flows should present the core toolkit and context boundary first, with Phoenix wrappers clearly second and optional.
- **D-14:** Phoenix-specific guides should carry one concise repeated reminder that helpers normalize params/forms/URLs only, contexts remain canonical, and Phoenix is optional.
- **D-15:** Do not give `Scrypath.Phoenix` visual or conceptual parity with `Scrypath.search/3` or `Scrypath.QueryParams`.
- **D-16:** Avoid banner-heavy repetition. The right posture is core-first information architecture with selective explicit reminders, not defensive warnings on every page.

### Decision cadence
- **D-17:** Carry this preference forward in planning and implementation: default to decisive, coherent recommendations that preserve least surprise and public boundary honesty. Only escalate choices back to the user when they materially affect public API shape, milestone scope, or long-term semver cost.

### the agent's Discretion
- Exact guide filename and guide placement in the overview, as long as it is explicit about request-edge purpose and does not imply a second runtime.
- Exact wording of the repeated Phoenix-optional reminder, as long as it stays concise, calm, and non-defensive.
- Exact verify task shape and test file layout, as long as the gates stay narrow, contract-based, and contributor-friendly.
- Exact doc snippet examples and fixture naming, as long as they preserve context-owned orchestration and `handle_params/3`-first LiveView flow.

</decisions>

<specifics>
## Specific Ideas

- The ideal public mental model is: params normalize once at the edge, contexts still call `Scrypath.search/3`, Phoenix stays optional, and helpers only remove repetitive glue.
- The docs should feel like a native Elixir OSS library: one clear canonical guide, small explicit APIs, great copy-paste snippets, and no framework magic.
- The example app should function like a proof harness, not like the product surface. Readers should learn the boundary from HexDocs and verify it with the example when they want runtime proof.
- The verification posture should copy the spirit of compile-checked examples and contract tests from strong OSS ecosystems, but avoid freezing every sentence or heading in maintainer-hostile ways.
- Useful precedents to learn from:
  - Searchkick and Laravel Scout: one obvious adoption story and sharp wayfinding
  - Algolia / Meilisearch Rails: convenience docs are valuable, but callback-style magic and wrapper overreach create boundary confusion
  - Phoenix contexts and LiveView docs: web layer stays thin, URL/`handle_params/3` owns shareable state, contexts own feature logic
- Product voice should stay calm, exact, and specific. Explain the edge contract plainly; do not market it like a mini Phoenix framework.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone guardrails
- `.planning/ROADMAP.md` — Phase 82 scope and success criteria for docs, examples, and drift protection
- `.planning/REQUIREMENTS.md` — `DOC-01` and `VRFY-01`
- `.planning/PROJECT.md` — v1.21 guardrails, optional Phoenix posture, and public boundary constraints
- `.planning/STATE.md` — current milestone state and narrow-balanced framing for v1.21

### Prior phase decisions
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md` — locked decisions for browser grammar, error contract, Phoenix wrappers, and LiveView flow
- `.planning/phases/80-public-query-toolkit-contract/80-RESEARCH.md` — phase 80 toolkit contract research
- `.planning/phases/80-public-query-toolkit-contract/80-PATTERNS.md` — request-edge and docs pattern map
- `.planning/phases/80-public-query-toolkit-contract/80-VERIFICATION.md` — public plain-data contract and runtime-parity verification baseline
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-RESEARCH.md` — phase 81 research for optional wrappers and request grammar
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-PATTERNS.md` — controller/LiveView helper and docs pattern map
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-VALIDATION.md` — current docs/helper validation surface
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-01-SUMMARY.md` — normalized request-edge contract summary
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-02-SUMMARY.md` — optional Phoenix wrapper and docs-contract summary

### Existing public docs and code surfaces
- `README.md` — current root wayfinding and Phoenix narrative placement
- `lib/scrypath.ex` — root moduledoc and public runtime/toolkit discovery surface
- `lib/scrypath/query_params.ex` — public plain-data toolkit surface
- `lib/scrypath/phoenix.ex` — optional pure Phoenix wrapper surface
- `guides/overview.md` — current guide IA and entry ordering
- `guides/getting-started.md` — concept-first onboarding
- `guides/golden-path.md` — linear first-hour path and current place in root onboarding
- `guides/phoenix-walkthrough.md` — end-to-end Phoenix adoption path
- `guides/phoenix-contexts.md` — context boundary authority
- `guides/phoenix-controllers-and-json.md` — controller request-edge guidance
- `guides/phoenix-liveview.md` — `handle_params/3`-first LiveView guidance
- `guides/faceted-search-with-phoenix-liveview.md` — current URL-state and helper-aligned facet guidance
- `examples/phoenix_meilisearch/README.md` — runnable Phoenix proof path and CI/env runbook

### Existing verification and example seams
- `test/scrypath/docs_contract_test.exs` — current docs-contract suite and Phoenix boundary assertions
- `test/scrypath/phoenix_test.exs` — helper contract tests
- `test/scrypath/query_params_test.exs` — query-param contract tests
- `test/support/docs/phoenix_example_case.ex` — compile-checked docs fixture for controller and LiveView flows
- `test/support/docs/phoenix_examples_test.exs` — fixture-level docs behavior tests
- `test/support/docs/phoenix_request_shape_smoke_test.exs` — accepted Plug-decoded request-shape smoke tests
- `.github/workflows/ci.yml` — current example-app CI path and command order
- `CONTRIBUTING.md` — verify matrix and current docs-contract posture

### Prompt corpus constraints
- `prompts/elixir-best-practices-deep-research.md` — Elixir API clarity and data-first library guidance
- `prompts/ecto-best-practices-deep-research.md` — context-boundary and orchestration guidance
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS library DX and docs expectations
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — boundary, optional-process, and architecture guidance across Elixir/Plug/Ecto/Phoenix
- `prompts/phoenix-best-practices-deep-research.md` — context-first Phoenix architecture guidance
- `prompts/phoenix-live-view-best-practices-deep-research.md` — `handle_params/3`, URL-state, and LiveView ergonomics guidance
- `prompts/elixir-search-lib-deep-research.md` — cross-ecosystem search-library product/ops lessons
- `prompts/search-lib-use-cases-deep-research.md` — use-case and category-shaping guidance
- `prompts/scrypath-brand-book.md` — calm, exact, non-hype product voice and descriptor guidance

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `guides/overview.md`: existing guide map that can absorb one new request-edge guide without re-architecting the docs corpus
- `test/support/docs/phoenix_example_case.ex`: compile-checked fixture seam for controller and LiveView edge flows
- `test/support/docs/phoenix_examples_test.exs`: behavior-level guardrails for the thin-helper story
- `test/support/docs/phoenix_request_shape_smoke_test.exs`: accepted Plug-decoded param shapes already locked in executable tests
- `examples/phoenix_meilisearch/README.md`: existing real-service proof/runbook surface that should stay operational rather than doctrinal
- `test/scrypath/docs_contract_test.exs`: existing place to add narrow v1.21 story assertions

### Established Patterns
- Public Scrypath surfaces stay explicit, function-based, and low-magic
- README points to canonical guides rather than duplicating entire guides inline
- Contexts own search orchestration; controllers and LiveView stay thin
- LiveView request-edge guidance is already `handle_params/3`-first and URL-state-first
- Optional integrations in this repo are documented as add-ons, not equal peers to the core runtime surface

### Integration Points
- The new request-edge guide should connect root wayfinding, toolkit API docs, and Phoenix-specific guides into one coherent lane
- The phase should reuse existing fixture-based docs validation rather than inventing a whole new verification philosophy
- Example README, CI job documentation, and local smoke instructions should remain intentionally aligned and testable

</code_context>

<deferred>
## Deferred Ideas

- Reusable Phoenix UI widgets, generated components, or form-builder abstractions over the request-edge toolkit
- Controller macros, `use Scrypath.Phoenix`, or any helper that executes search or owns socket/controller lifecycle
- A broader docs-information-architecture rewrite beyond what is needed to make the v1.21 edge story coherent
- Public composition/presets or stronger UI metadata layers over the toolkit surface

</deferred>

---

*Phase: 82-docs-examples-and-drift-protection*
*Context gathered: 2026-05-23*
