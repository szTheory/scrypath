# Phase 112: Public Website and Docs Truth Alignment - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 112 delivers public truth alignment across `website/`, README, guides, and scope-policy surfaces. It should keep Scrypath positioned as the Ecto-native search indexing library for Phoenix and Ecto teams, keep `website/` as a curated front door into canonical docs rather than a second docs site, and make feature-lane reopen policy explicit and evidence-gated.

This phase may edit public copy, add one canonical scope/reopen policy guide, link route surfaces into that guide and existing authorities, and add focused service-free contract proof. It must not add product breadth, runtime APIs, public multi-backend v1 promises, hosted-search positioning, AI/vector/hybrid positioning, magic callback claims, or duplicated website guide bodies.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 112 goal, WEB-01/WEB-02/SCOPE-01 requirements, success criteria, and v1.30 maintenance/evidence boundary.
- `.planning/REQUIREMENTS.md` - active public-truth requirements and out-of-scope constraints.
- `.planning/PROJECT.md` - current maintenance-and-evidence mode, canonical adopter contract, public website posture, and scope guard authority.
- `.planning/STATE.md` - active position and prior decisions around website/docs truth, support routing, proof stability, and lean gates.

### Prior Decisions
- `.planning/phases/109-release-train-and-package-truth-audit/109-CONTEXT.md` - release-truth decisions, especially lean always-on gates and route-first docs.
- `.planning/phases/110-support-intake-and-evidence-routing/110-CONTEXT.md` - support routing, single-source compatibility authority, and deferral of broad website narrative to Phase 112.
- `.planning/phases/111-advisory-proof-stability-decision/111-CONTEXT.md` - advisory/required proof discipline, lean required gates, and contract-test posture.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md` - canonical scope guard authority banning unsupported capability classes.

### Public Website and Docs Surfaces
- `README.md` - root public positioning, route-first docs map, Meilisearch-first v1 statement, and sync visibility warnings.
- `website/src/pages/index.html` - homepage positioning, install/status strip, product jobs, and route list.
- `website/src/pages/docs.html` - docs route map into guides, examples, support, and intake surfaces.
- `website/src/pages/evaluate.html` - fit/non-fit positioning and likely place for concise scope-policy routing.
- `website/src/pages/operators.html` - operator route map, sync-mode visibility language, support/intake links.
- `guides/overview.md` - guide index and high-level docs routing.
- `guides/support-and-compatibility.md` - support/readiness authority and release-backed guidance.
- `guides/outside-adopter-intake.md` - evidence lane for outside-adopter reports and feature-lane signals.
- `guides/sync-modes-and-visibility.md` - canonical sync semantics and accepted-work versus visibility truth.
- `docs/operator-support.md` - maintainer operator support routing.
- `docs/jtbd-gap-map.md` - current jobs-to-be-done gaps, website route-map note, and deferred feature-wedge context.

### Existing Verification Code
- `test/scrypath/phase110_contract_test.exs` - nearest pattern for route-only public entrypoint and support/intake authority assertions.
- `test/scrypath/phase111_contract_test.exs` - nearest pattern for policy consistency and negative promotion-language assertions.
- `test/scrypath/docs_contract_test.exs` - broader docs truth anchors.
- `test/mix/tasks/workflow_wiring_test.exs` - verify alias and CI wiring assertion patterns.
- `lib/mix/tasks/verify.phase108.ex` - focused truth-alignment verify task pattern.
- `lib/mix/tasks/verify.phase99.ex` - drift-gate trust lane and docs build pattern.

### Prompt Research
- `prompts/scrypath-brand-book.md` - canonical brand posture, descriptor-on-first-mention guidance, avoided claim language, website design posture, and non-AI/non-hosted positioning.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` - Elixir OSS expectations around explicit APIs, docs as product, stable public surfaces, low magic, and maintainer trust.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - docs-as-product, ExDoc/HexDocs expectations, lean required gates, and service-free verification.
- `prompts/elixir-search-lib-deep-research.md` - search-library DX lessons from Searchkick, Laravel Scout, Haystack, meilisearch-rails, and typesense-rails; especially no magic callbacks and operational honesty.
- `prompts/meileisearch best practices for scrypath deep research.md` - Meilisearch async task semantics, accepted-work versus visibility, and search projection mental model.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - Phoenix/Ecto operational architecture, context boundaries, and explicit function-first library behavior.
- `prompts/phoenix-best-practices-deep-research.md` - Phoenix context boundaries, routing clarity, and web-layer/domain-layer separation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `website/src/pages/index.html` already presents Scrypath as Ecto-native search for Phoenix apps and routes to docs, operators, Evaluate, GitHub, and examples.
- `website/src/pages/docs.html` already behaves as a docs map with guide and example links rather than a duplicated tutorial.
- `website/src/pages/evaluate.html` already has concise fit/non-fit language for hosted search, magic callbacks, and public multi-backend v1.
- `website/src/pages/operators.html` already distinguishes accepted work from visible search and routes support/intake links.
- `README.md` already states Meilisearch-first v1, internal backend seam, accepted-work visibility warnings, and route-first guide authorities.
- `test/scrypath/phase110_contract_test.exs` and `test/scrypath/phase111_contract_test.exs` provide direct file-read contract-test patterns for public truth and policy assertions.

### Established Patterns
- Public truth is kept route-first: README and website summarize and route; canonical details live in guides/docs.
- Support/readiness truth is single-sourced in `guides/support-and-compatibility.md` and linked from other surfaces.
- Required gates stay lean and service-free; live/browser/external checks remain advisory or explicit.
- Contract tests use direct file reads with positive token assertions, ordering checks, and targeted negative assertions.
- Scrypath copy favors operational honesty over magic: accepted work is not the same as search visibility, and the app owns search state.

### Integration Points
- Add or update `guides/scope-and-reopen-policy.md` as the canonical policy authority.
- Link the policy guide from `README.md`, `website/src/pages/evaluate.html`, and likely `guides/outside-adopter-intake.md` or `guides/support-and-compatibility.md`.
- Add `test/scrypath/phase112_contract_test.exs` to assert claim envelope, route-map links, scope-policy links, and absence of misleading public claims.
- Add `lib/mix/tasks/verify.phase112.ex` and a matching task test if following the current phase-local verify command pattern.
- Optionally update `website/src/pages/index.html`, `website/src/pages/docs.html`, `website/src/pages/operators.html`, and `website/src/pages/evaluate.html` to tighten copy against the claim envelope.

</code_context>

<specifics>
## Specific Ideas

The user requested that all four gray areas be researched with subagent-backed advisor analysis, ecosystem lessons, prompt-corpus context, deep pros/cons/tradeoffs, DX emphasis, least surprise, and one cohesive recommendation set.

Four advisor researchers independently converged on this coherent recommendation:

1. Use a fixed claim envelope: canonical first mention everywhere, page-specific supporting copy inside controlled vocabulary, and no misleading hosted/AI/magic/public-multi-backend/immediate-visibility claims.
2. Keep website depth as curated journey pages with short summaries and deep links, not rich standalone docs.
3. Add one canonical `guides/scope-and-reopen-policy.md` and link it from public surfaces instead of spreading full policy text across the website.
4. Add focused Phase 112 contract proof using existing phase contract-test patterns, not a broad noisy scanner and not manual checklist only.

Ecosystem lessons applied:

- Elixir/Phoenix/HexDocs culture rewards exact package docs and low-surprise public claims. The website should help users find the right canonical doc, not compete with HexDocs/guides.
- Searchkick, Laravel Scout, meilisearch-rails, and typesense-rails show the value of good DX and clear integration paths, but Django Haystack is the warning label against magical signal/callback sync and hidden operational cost.
- Meilisearch's async task model makes accepted-work versus visible-search language a public truth requirement, not an implementation detail.
- Strong OSS projects use evidence/reproduction gates for support and feature pressure; Scrypath should route reopen requests through existing outside-adopter evidence rather than adding preference-driven roadmap churn.

</specifics>

<deferred>
## Deferred Ideas

- Rich standalone website docs are deferred. If demand appears, revisit only with a synchronization strategy that does not undermine README/guides/HexDocs authority.
- Broad repo-wide public-claim scanners are deferred because false positives and allowlists would likely create lower-signal maintainer friction than focused contract tests.
- Website visual redesign, new landing-page information architecture, and SEO expansion are deferred; Phase 112 is truth alignment, not marketing-site expansion.
- New product breadth remains deferred: hosted search, AI/vector/hybrid positioning, autocomplete/suggestions as a first-class product surface, public multi-backend v1 support, magic callback runtime, new public runtime APIs, and framework facade behavior.

</deferred>

---

*Phase: 112-Public Website and Docs Truth Alignment*
*Context gathered: 2026-06-01*
