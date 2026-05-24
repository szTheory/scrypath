# Phase 87: Outside-Adopter Intake And Evidence Review - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 87 defines one current outside-adopter intake path for the defended Phoenix + Meilisearch story, reviews at least two real adopter attempts against branch-tip truth, and turns that evidence into an honest milestone-direction input. This phase does not broaden Scrypath's public support matrix or reopen generic feature work. It clarifies how outside evidence is collected, what counts as admissible, how findings are classified, and how reviewed evidence can or cannot move the current "stop soon unless one major wedge is proven" posture.

</domain>

<decisions>
## Implementation Decisions

### Intake surface and authority split
- **D-01:** Add exactly one new canonical intake guide for this phase. Do not turn `README.md` or `CONTRIBUTING.md` into a second intake authority.
- **D-02:** Keep support truth and intake truth separate:
  - `guides/support-and-compatibility.md` owns what Scrypath currently defends.
  - the new outside-adopter intake guide owns how an adopter should attempt, capture, and submit evidence.
  - `examples/phoenix_meilisearch/README.md` remains the authoritative live Phoenix + Meilisearch runbook.
- **D-03:** `README.md` stays the public front door and should route to the intake guide when a reader wants to try the defended real-app path or report outside-adopter evidence.
- **D-04:** `CONTRIBUTING.md` stays maintainer-facing and should only map the proof-command family, CI parity, and maintainer review workflow. It should not duplicate the intake checklist or live runbook.
- **D-05:** The new intake guide should be calm and contract-shaped, not marketing copy. It should explain the defended path, proof command family, required evidence bundle, admissibility classes, finding buckets, and review/closeout rubric.

### Canonical proof path and runtime posture
- **D-06:** The canonical proof command family remains `mix verify.adopter` and `mix verify.adopter --live`.
- **D-07:** The defended outside-adopter path for admissible evidence is explicitly the current Phoenix + Meilisearch repo-clone path, not a generic Hex-only story.
- **D-08:** The intake surface must state the repo-clone versus Hex-package boundary plainly so outside adopters know when they are on the defended path versus a near-path or off-path attempt.
- **D-09:** The intake guide should name the runtime assumptions that matter for review: Elixir/OTP, Phoenix/Ecto when applicable, Meilisearch version, sync mode, and whether the example app or host app path is under test.

### Required evidence package
- **D-10:** The canonical evidence package should be a repo-owned guided checklist/template, not a freeform report and not a GitHub form as the only authority.
- **D-11:** Each adopter attempt must include a small command-output bundle in addition to the template so maintainers can distinguish product truth from anecdote.
- **D-12:** Required evidence for an admissible attempt is:
  - adopter context and goal
  - environment matrix
  - exact Scrypath ref or Hex version
  - chosen proof path and sync mode
  - exact commands run in order
  - expected versus actual outcome
  - first failure/confusion point
  - supporting logs or failing output
  - maintainer review block
- **D-13:** Screenshots should be optional and only requested when docs navigation or UI confusion matters. Raw archives should not be the only required payload.
- **D-14:** The maintainer review block must classify each reviewed finding as exactly one of:
  - docs/onboarding gap
  - support-truth drift
  - product gap
  - env/setup papercut

### Admissibility and evidence classes
- **D-15:** Use a tiered evidence-bucket policy rather than a strict-only or broad-anecdotal policy.
- **D-16:** Evidence classes are:
  - **Class A: defended evidence** — current repo clone, current docs, documented versions, canonical example path, required artifacts present
  - **Class B: near-path evidence** — same product shape with one bounded deviation, such as Hex install or adjacent minor versions
  - **Class C: off-path evidence** — multiple deviations, unsupported topology/backend/runtime mix, or partial artifacts
  - **Class D: non-evidence** — missing repro steps, versions, logs, or only opinion
- **D-17:** Only Class A evidence can change defended support/readiness conclusions or strongly influence the "stop soon vs reopen one wedge" verdict.
- **D-18:** Class B evidence can justify docs/onboarding/setup follow-up and may motivate reproduction on the defended path, but it cannot widen current support claims by itself.
- **D-19:** Class C evidence is directional only. It may inform backlog ranking or future research, but it cannot count against branch-tip support/readiness truth.
- **D-20:** Class D should be logged as intake noise, not treated as reviewed evidence.

### Review rubric and milestone-close decision rule
- **D-21:** Use a JTBD-gated severity/frequency rubric tied to the already locked next-pull ranking instead of a loose qualitative call or a pseudo-precise weighted matrix.
- **D-22:** Review every finding in this order:
  1. classify into one of the four finding buckets
  2. if it is a product gap, map it to the concrete adopter job it blocks or degrades
  3. score only `severity` (`blocker`, `painful workaround`, `minor`) and `frequency` (`one adopter`, `repeated`)
  4. apply the locked ranking as tie-breaker and scope guard
- **D-23:** The common gate for any non-stop verdict is:
  - the signal comes from reviewed outside-adopter evidence on the defended path
  - the issue survives triage as a product gap
  - the issue blocks or seriously degrades a concrete adopter job
  - Phase 88 cannot clear it with a bounded papercut fix
  - the verdict memo names the winning evidence and why higher-ranked alternatives did not win
- **D-24:** `stop soon` remains the default if reviewed failures are mostly docs/support/env issues, or if any remaining product gaps are single-adopter, niche, or clearly below the locked ranking.
- **D-25:** Reopen **related-data propagation** only when reviewed evidence shows repeated correctness/trust failures caused by associated-data changes, denormalized projections, or unclear dependency-triggered reindexing.
- **D-26:** Reopen **tenant-safe access** only when reviewed evidence shows a real shared-index SaaS boundary failure and related-data did not meet its threshold more strongly.
- **D-27:** High-cardinality facet-value search may be recorded as later evidence, but it must not displace `stop soon`, `related-data propagation`, or `tenant-safe access` in Phase 87/88.

### Workflow preference for this phase and adjacent planning
- **D-28:** For this phase, and for downstream planning unless a branch is truly high-impact, prefer research-first synthesis over iterative questioning.
- **D-29:** Ask the user again only on materially consequential forks that cannot be resolved from repo truth, prompt research, or reviewed evidence. Small implementation-shape choices should be decided by the agent and documented clearly.
- **D-30:** Keep recommendations cohesive with Scrypath's established posture: small explicit public surfaces, low magic, one authority per concern, operational honesty, and high developer trust.

### the agent's Discretion
- Exact filename and placement of the new intake guide and evidence template.
- Whether the optional structured submission transport is a GitHub issue form, discussion template, or plain markdown file, as long as the repo-owned guide/template remains canonical.
- Exact wording of the admissibility examples and verdict memo format.
- How much of the command-output bundle is pasted inline versus linked as attachments, as long as required facts remain reviewable without guesswork.

</decisions>

<specifics>
## Specific Ideas

- The best docs architecture here mirrors the best OSS integrations in adjacent ecosystems: thin front door, one canonical contract per concern, and the live operational runbook isolated where it belongs.
- Searchkick, Laravel Scout, Meilisearch Rails, and Hibernate Search all point to the same product lesson: support boundaries and sync/reindex truth should be explicit, not implied by “easy mode” marketing.
- The correct tone is composed and exact. The intake path should help outside adopters succeed without pretending every path is supported equally.
- The milestone-close rubric must actively resist maintainers rationalizing another feature milestone from one vivid anecdote.
- Evidence quality matters more than evidence volume. Two well-structured adopter attempts are more valuable than many informal impressions.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and scope truth
- `.planning/ROADMAP.md` — Phase 87 goal, plans `87-01` through `87-03`, and dependency on Phase 86.
- `.planning/REQUIREMENTS.md` — `ADOPT-01` through `ADOPT-03` define the acceptance targets for this phase.
- `.planning/STATE.md` — current active-milestone posture, outside-adopter guardrail, and ranking constraints.
- `.planning/PROJECT.md` — project-level scope, boundary discipline, and v1.23 posture.
- `.planning/threads/scrypath-doneness-assessment-2026-05-24.md` — the current "stop soon unless evidence proves one wedge" rule.

### Prior phase context that stays locked
- `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md` — support-truth reconciliation decisions that Phase 87 must build on.
- `.planning/phases/85-real-app-proof-and-drift-gates/85-CONTEXT.md` — the flagship proof-flow and docs-architecture posture that informs outside-adopter review.

### Current support, proof, and maintainer surfaces
- `README.md` — public front door and current routing to support/proof surfaces.
- `CONTRIBUTING.md` — maintainer-facing proof command family and CI-parity wording.
- `guides/support-and-compatibility.md` — single current support/readiness authority.
- `examples/phoenix_meilisearch/README.md` — canonical live Phoenix + Meilisearch runbook.
- `lib/mix/tasks/verify.adopter.ex` — fast/live proof command contract.
- `test/scrypath/readiness_contract_test.exs` — current bounded proof-surface guard.
- `docs/jtbd-gap-map.md` — current leverage ranking and gap framing.

### Prompt corpus and research lenses
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Elixir OSS API/docs ergonomics and public-surface discipline.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — explicit runtime boundaries, OTP/process discipline, and Phoenix/Ecto fit.
- `prompts/search-lib-use-cases-deep-research.md` — concrete adopter jobs and leverage ranking for search-library work.
- `prompts/elixir-search-lib-deep-research.md` — search-library ecosystem lessons, wedge ranking, and anti-abstraction guidance.
- `prompts/scrypath-brand-book.md` — product voice and posture constraints for public guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `guides/support-and-compatibility.md`: already owns the defended branch-tip support truth and the in-repo proof versus outside-evidence distinction.
- `examples/phoenix_meilisearch/README.md`: already owns the live operational runbook and exact env/command story; the new intake surface should route to it rather than restate it.
- `lib/mix/tasks/verify.adopter.ex`: already encodes the fast/live proof command family that the intake flow should anchor to.
- `test/scrypath/readiness_contract_test.exs`: existing focused drift gate pattern that can likely protect the new intake contract with bounded additions.

### Established Patterns
- Scrypath consistently prefers one canonical guide per concern plus thin routing from README and maintainer docs.
- Public surfaces stay explicit, low-magic, and honest about operational boundaries.
- Focused verification commands and narrow docs-contract tests are preferred over broad prose-locking or giant aggregate gates.
- Current planning posture explicitly separates defended in-repo proof from reviewed outside-adopter evidence.

### Integration Points
- The new intake guide must route cleanly from `README.md`, `CONTRIBUTING.md`, and `guides/support-and-compatibility.md`.
- The evidence template and review rubric should align exactly with `mix verify.adopter` fast/live semantics and the Phoenix example README.
- Phase 87 review artifacts must feed Phase 88 without re-litigating the current next-pull ranking or broadening the support matrix.

</code_context>

<deferred>
## Deferred Ideas

- Treating GitHub issue forms or other submission tooling as the canonical intake authority.
- Broadening support claims beyond the defended Phoenix + Meilisearch path during this phase.
- Reopening generic ergonomics work, SearchModule recovery, backend expansion, or deeper Phoenix helper breadth.
- Letting high-cardinality facet-value search displace related-data propagation or tenant-safe access in the current decision hierarchy.
- Making a global GSD workflow-profile change beyond the scope of this phase; the preference is captured here for this phase and adjacent planning first.

</deferred>

---

*Phase: 87-outside-adopter-intake-and-evidence-review*
*Context gathered: 2026-05-24*
