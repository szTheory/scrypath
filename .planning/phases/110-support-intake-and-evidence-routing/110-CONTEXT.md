# Phase 110: Support Intake and Evidence Routing - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 110 delivers support-intake and evidence-routing hardening only: it should make adopter reports carry enough reproducible evidence for maintainers to classify Class A-D and route findings to the correct next action without guessing.

This phase may tighten README, CONTRIBUTING, the support guide, the outside-adopter intake guide, the outside-adopter issue template, and minimal route-only entrypoints that point adopters into those authorities. It must not create a heavyweight support workflow, duplicate compatibility matrices outside `guides/support-and-compatibility.md`, add new product/runtime surface, or pull broad public website claim alignment forward from Phase 112.

</domain>

<decisions>
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 110 goal, SUP-01/SUP-02 requirements, success criteria, and Phase 112 boundary.
- `.planning/REQUIREMENTS.md` - v1.30 support-intake requirements and out-of-scope constraints.
- `.planning/PROJECT.md` - maintenance-and-evidence mode, canonical adopter contract, support/proof policy, and feature-lane guardrails.
- `.planning/STATE.md` - active position and prior decisions around lean gates, outside-adopter evidence, and support truth.
- `.planning/phases/109-release-train-and-package-truth-audit/109-CONTEXT.md` - prior release-truth decisions, especially lean required gates, route-first docs, and no heavyweight process.

### Support and Intake Surfaces
- `README.md` - root adopter entrypoint and support/readiness routing.
- `CONTRIBUTING.md` - maintainer/contributor gate documentation and support-intake routing.
- `guides/support-and-compatibility.md` - single compatibility, install, readiness, support, and verification authority.
- `guides/outside-adopter-intake.md` - evidence classes, evidence requirements, finding buckets, and maintainer routing.
- `.github/ISSUE_TEMPLATE/outside-adopter-evidence.md` - outside-adopter evidence issue template to harden.
- `docs/operator-support.md` - maintainer operator support guide; only route-only support-intake alignment is in scope.

### Existing Verification Code
- `lib/mix/tasks/verify.adopter.ex` - existing fast/live adopter verification task and likely integration point for Phase 110 contract proof.
- `lib/mix/tasks/verify.phase98.ex` - prior support/readiness reconciliation gate.
- `lib/mix/tasks/verify.phase99.ex` - prior drift-gate trust lane.
- `test/scrypath/readiness_contract_test.exs` - existing support/readiness route assertions.
- `test/scrypath/phase98_contract_test.exs` - existing proof boundary and intake token assertions.
- `test/scrypath/phase99_contract_test.exs` - existing install/support/proof truth parity assertions.
- `test/scrypath/docs_contract_test.exs` - broad docs contract anchors for support/readiness and outside-adopter evidence.
- `test/mix/tasks/workflow_wiring_test.exs` - existing verify alias and CI wiring assertions.
- `mix.exs` - verify alias registration and ExDoc extras grouping for support/intake guides.

### Route-Only Public Entrypoints
- `website/src/pages/docs.html` - public docs route map containing support and intake links.
- `website/src/pages/operators.html` - public operator route map containing support/intake language.
- `website/src/pages/index.html` - homepage support/intake references; Phase 110 should avoid broad claim work here unless routing is actively misleading.

### Prompt Research
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` - OSS library expectations around explicit docs, low magic, stable contracts, and maintainer trust.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - lean required gates, docs-as-product, Release Please/Hex trust, and service-free CI guidance.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - ecosystem guidance around functions-first library design, operational clarity, and avoiding unnecessary process weight.
- `prompts/scrypath-brand-book.md` - brand posture: calm, exact, technical, trustworthy, route-first, and operationally honest.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `guides/support-and-compatibility.md` already owns compatibility tuples, install guidance, support/readiness posture, and fast/live verification split.
- `guides/outside-adopter-intake.md` already defines Class A-D, evidence checklist items, finding buckets, maintainer routing, and the issue template link.
- `.github/ISSUE_TEMPLATE/outside-adopter-evidence.md` already asks for environment matrix, Scrypath ref or Hex version, chosen path, sync mode, ordered commands, expected versus actual outcome, first failure/confusion point, logs, and a maintainer review block.
- `test/scrypath/readiness_contract_test.exs`, `test/scrypath/phase98_contract_test.exs`, and `test/scrypath/phase99_contract_test.exs` already assert many support/intake anchors and are good examples for Phase 110 contract assertions.
- `Mix.Tasks.Verify.Adopter` already runs fast support contract tests and has a live mode with explicit prerequisites; it is the natural place to include service-free Phase 110 proof.

### Established Patterns
- Support/readiness truth is single-sourced in `guides/support-and-compatibility.md`; route surfaces should link rather than duplicate matrices.
- Required gates stay lean and service-free; live or external checks remain explicit and prerequisite-bound.
- Contract tests use direct file reads and token/ordering assertions for docs truth surfaces.
- Verification tasks are thin orchestration wrappers around explicit test files and reject stray arguments.
- Public docs and website should be route-first rather than duplicating detailed guide bodies.

### Integration Points
- Harden `.github/ISSUE_TEMPLATE/outside-adopter-evidence.md` with a structured evidence block and clearer maintainer block.
- Add routing table/checklist detail in `guides/outside-adopter-intake.md` and keep it aligned with the template.
- Add focused ExUnit proof in `test/scrypath/phase110_contract_test.exs`.
- Update `lib/mix/tasks/verify.adopter.ex` and its tests if Phase 110 proof is added to the fast support path.
- Touch route-only references in `website/src/pages/docs.html`, `website/src/pages/operators.html`, or `docs/operator-support.md` only if current wording weakens the support/intake authority path.

</code_context>

<specifics>
## Specific Ideas

The user explicitly requested all four gray areas be considered with subagent-backed research and a single cohesive recommendation set emphasizing ecosystem fit, lessons from successful OSS libraries and other ecosystems, low-friction adopter DX, maintainer ergonomics, principle of least surprise, and Scrypath's product vision.

The coherent recommendation set is:

1. Use a hybrid Markdown issue template: narrative context plus a compact required evidence block.
2. Add a docs-first routing table/checklist for Class A-D plus finding buckets.
3. Add a dedicated Phase 110 contract test and wire it into an existing fast support verification path instead of creating a new required gate.
4. Keep Phase 110 focused on support/intake routing surfaces plus route-only public entrypoints; defer broad public website truth alignment to Phase 112.

Recommended evidence block shape:

```markdown
## Evidence Block (required)

| Field | Value |
|---|---|
| Path | `repo-clone` / `hex-package` |
| Runtime vs support matrix | `inside` / `outside` |
| Reporter class guess | `A` / `B` / `C` / `D` |
| Reporter finding guess | `bugfix` / `docs-gap` / `app-side` / `environment` / `needs-info` |
| Scrypath ref or Hex version | `...` |
| First failing command step | `#...` |
| Logs/artifacts | `<paste or link>` |
```

Subagent research compared freeform templates, structured GitHub Issue Forms, and hybrid Markdown. It recommended the hybrid because it borrows reproducible-evidence discipline from stricter ecosystems without making Scrypath's early adopter support feel bureaucratic.

</specifics>

<deferred>
## Deferred Ideas

- Migrating to GitHub Issue Forms is deferred until outside-adopter volume or maintainer load proves Markdown templates are insufficient.
- Adding a new `mix verify.phase110` command is deferred unless planning finds that phase-local command clarity outweighs verify-task sprawl.
- Broad website narrative, homepage claim alignment, public brand copy rewrites, and "website as route map vs second docs site" cleanup belong to Phase 112.
- Any feature-lane reopen, new public runtime surface, autocomplete/suggestions, multi-backend broadening, or proof-lane promotion remains out of scope for Phase 110.

</deferred>

---

*Phase: 110-Support Intake and Evidence Routing*
*Context gathered: 2026-05-31*
