# Phase 169: Library Fix Delivery and PR Triage - Context

**Gathered:** 2026-09-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the confirmed tenant-option and facet keyword-filter corrections, with coherent regression and selected host/repair proof, through reviewed changes to verified public `main`. Compare the unpublished owned delta with a refreshed public-main source, give each remaining owned change a coherent delivery path or evidence-based disposition, and disposition the finite Dependabot cohort frozen at this phase's start. A prepared PR is not completed delivery; the accumulated local branch is never the delivery unit.

The phase start snapshot recorded public `main` at `2832e91d725d70eff9ba11d08052260ba17e2747` and the open Dependabot cohort as #65 and #68–76. Release Please PR #83 is outside this cohort and belongs to Phase 170. Recheck PR heads, bases, and current evidence before acting. Newly arriving routine bot PRs remain in maintenance. Phase 170 owns the focused docs closeout, warranted patch decision, and terminal readiness record.

</domain>

<decisions>
## Implementation Decisions

### Frozen Dependabot cohort
- **D-01:** Apply one evidence gate per frozen PR. Keep or update a PR when current evidence demonstrates a concrete security or supported-compatibility need, or a material adopter, workflow-reliability, or maintainer-quality benefit that warrants the verification cost. A green check alone is not sufficient reason to merge an update.
- **D-02:** Close or defer updates without that demonstrated value. Record an evidence-based reason and a specific revisit trigger for deferrals. No disposition should be inferred from PR age or `BEHIND` status alone; refresh its head/base, release notes, and checks before action.
- **D-03:** Do not make clearing the inbox a goal. New routine updates stay in normal maintenance; material new security or compatibility evidence can reopen the scope. Keep the existing required/advisory verification split and avoid a broad upgrade or new required CI job.
- **D-04:** The frozen cohort is #65 `actions/cache`, #68 `dependency-review-action`, #69 `stream_data`, #70 `actions/setup-node`, #71 `actions/checkout`, #72 `actions/deploy-pages`, #73 `req`, #74 `ex_doc`, #75 `dialyxir`, and #76 `oban`. The discussion-time heads/bases are preserved below as baseline identifiers only; these are not valid evidence for a later action without refresh.
  - #65 head `6b70b673347ec3e31af22f044aecbab6fe6c3a98`, base `40c9978c975dbfb42db75511f44ff0369c8d7d88`
  - #68 head `949fafb68635b2fee2c0ac5ff4b6cc4a2eb116dd`, base `40c9978c975dbfb42db75511f44ff0369c8d7d88`
  - #69 head `b4bd46d244fa3db8e1bb6a35e651bf1250372c1d`, base `40c9978c975dbfb42db75511f44ff0369c8d7d88`
  - #70 head `a7695881de49fe4e812435d3a148d56b37e633d7`, base `40c9978c975dbfb42db75511f44ff0369c8d7d88`
  - #71 head `a46d9db1e8ffae1499c13fff1a8091d7cd22c267`, base `40c9978c975dbfb42db75511f44ff0369c8d7d88`
  - #72 head `2bb02e546a0ea685a873bf09e0f104f466d28cfd`, base `2832e91d725d70eff9ba11d08052260ba17e2747`
  - #73 head `f6feeb157527e4ac1d58cecdd7a58bcb84975968`, base `2832e91d725d70eff9ba11d08052260ba17e2747`
  - #74 head `ecb00d502c8800c79581e769904c75520c71fcb4`, base `2832e91d725d70eff9ba11d08052260ba17e2747`
  - #75 head `b3b5f495cf9f6adb34612b7da31c5a555dee842c`, base `2832e91d725d70eff9ba11d08052260ba17e2747`
  - #76 head `cc40b53b0009eb404c75258ab44b210fb064d9f4`, base `2832e91d725d70eff9ba11d08052260ba17e2747`

### Owned planning-only delta
- **D-05:** Use current planning authority plus a compact, source-linked inventory to explain what is selected, what reached which source identity, what evidence applies, and how each remaining owned change is disposed. Keep the inventory in the existing canonical planning records; do not create a competing summary or import the accumulated planning history wholesale.
- **D-06:** Carry historical archive material into reviewed public delivery only when it is needed to understand a current decision or proof. Use a separate bounded archive change when that makes review clearer, and do not make archive review a prerequisite for the runtime fixes.
- **D-07:** Preserve dated historical assessments and receipts as written. Record current status and pointers in current authority; never transfer an old run's identity to a rewritten or new source SHA.
- **D-08:** Maintain separate identities for candidate source, PR merge ref, squash-merged `main`, locally built package, and published package. Phase 169 records the rationale for a normal patch; Phase 170 owns the release decision and publication/parity evidence.

### the agent's Discretion
- Refresh the frozen PR metadata and evidence before each candidate action, then make candidate-specific dispositions under D-01–D-03 with explicit reasons and revisit triggers.
- Choose a coherent PR grouping and the smallest reliable verification for each changed surface. Reuse prior semantic evidence only after relevant-source comparison; preserve the limits of each historical receipt.
- Build the dated owned-change inventory from refreshed public `main`, preserving unrelated worktree state and selecting only planning records needed by current maintainer jobs.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, product posture, and delivery authority
- `.planning/ROADMAP.md` — Phase 169 boundary, success criteria, and Phase 170 ownership.
- `.planning/REQUIREMENTS.md` — DELIV-02 and TRIAGE-01 acceptance contracts.
- `.planning/PROJECT.md` — product scope, green-main release train, automation-first evidence policy, and maintainer direction.
- `.planning/STATE.md` — preserved worktree status, milestone posture, and current handoff; keep unrelated local changes untouched.
- `.planning/research/v1.41/SUMMARY.md` — approved v1.41 decisions, alternatives, evidence limits, and downstream discretion.
- `.planning/research/v1.41/DELIVERY-REVIEW.md` — dated source/PR inventory, confirmed fixes, delivery constraints, and viable PR slices.
- `.planning/phases/168-dependency-security-and-reliable-verification/168-CONTEXT.md` — public-main delivery, source identity, exact-SHA proof, and no-history-bulk-import decisions carried forward.

### Historical tenant, facet, and repair evidence
- `.planning/milestones/v1.40-phases/165-public-tenant-and-facet-contracts/165-CONTEXT.md` — public tenant/facet input contract and host-versus-library boundary.
- `.planning/milestones/v1.40-phases/165-public-tenant-and-facet-contracts/165-02-SUMMARY.md` — reproduced facet keyword-filter serializer defect, compatible correction, and evidence limits.
- `.planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-CONTEXT.md` — approved host membership, raw-search/hydration, and bounded-repair proof boundaries.
- `.planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.md` and `.planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-VERIFICATION.md` — source-specific host, package, repair receipts and claim limits; reuse only after relevant-source comparison.
- `.planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-03-SUMMARY.md` — evidence identities and source-comparison pattern.
- `.planning/milestones/v1.40-phases/167-dated-readiness-and-closeout/167-ASSESSMENT.md` and `.planning/milestones/v1.40-phases/167-dated-readiness-and-closeout/167-CLOSEOUT.md` — historical dated readiness assessment and its immutable evidence boundaries.
- `.planning/milestones/v1.40-MILESTONE-AUDIT.md` — archived milestone outcome and accepted audit debt.

### Contributor, release, and local ecosystem guidance
- `CONTRIBUTING.md` — canonical verification commands, PR-first and green-main workflow, and automation-first closeout.
- `docs/releasing.md` — Release Please ownership, patch-first/squash semantics, package and publication evidence.
- `prompts/scrypath-milestone-ratchet-roadmap.txt` — evidence-gated maintenance, review cost, repository hygiene, and durable context principles.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — Elixir OSS CI/release guidance, subordinate to current repository policy.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Elixir library maintenance and adopter guidance, subordinate to current repository policy.

### Relevant implementation and proof surfaces
- `lib/scrypath/search/single.ex`, `lib/scrypath/search/many.ex`, and `lib/scrypath/search/facet_values.ex` — search-only option filtering at runtime configuration boundaries.
- `lib/scrypath/meilisearch/client.ex` — Meilisearch facet-filter payload serialization.
- `test/scrypath/tenant_scope_contract_test.exs` — recording-backend contracts for tenant filters, validation, and all public search paths.
- `test/scrypath/search_within_facet_test.exs` — Req.Test request-body contract for scoped facet composition.
- `examples/phoenix_meilisearch/test/scrypath_demo/blog_tenant_search_test.exs` and `examples/phoenix_meilisearch/README.md` — named host-owned tenant adopter scenario and consumer entrypoint.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/scrypath/tenant_scope_contract_test.exs` already exercises single, many, and facet public search paths against a recording backend, including tenant-filter composition and invalid-input rejection.
- `test/scrypath/search_within_facet_test.exs` uses `Req.Test` to assert serialized Meilisearch filters in the request body.
- The Phoenix consumer and root repair proof from Phase 166 provide the selected host/repair evidence pattern; reuse is conditional on comparing relevant source, workflow, fixture, and dependency inputs.

### Established Patterns
- Public search options are validated/composed before dispatch. `tenant_scope` remains a search input and is removed from strict runtime configuration by `Single`, `Many`, and `FacetValues`.
- Meilisearch facet filters use the existing query filter renderer for keyword input; regression proof should assert the emitted request grammar rather than duplicate a serializer.
- The named Phoenix proof derives tenant scope from persisted host membership, checks raw search hits separately from host hydration, and constrains hydration by tenant and returned IDs. The repair proof is bounded by an explicit Ecto ID predicate and terminal task completion.
- Phase verification should map each acceptance claim to the cheapest reliable automated or exact-SHA hosted evidence; service-backed evidence remains tied to its named scenario and source.

### Integration Points
- Tenant-option correction connects `Scrypath.Search.Single`, `Many`, and `FacetValues` to the existing validated search-filter path.
- Facet keyword-filter correction connects `Scrypath.Meilisearch.Client.facet_search/5` to the existing Meilisearch query renderer.
- End-to-end adopter proof connects the existing Phoenix path/package harness and root repair test surface; consult `CONTRIBUTING.md` for the applicable capability commands and keep existing advisory/required lane boundaries.

</code_context>

<specifics>
## Specific Ideas

- User approved the per-PR evidence gate and the compact source-linked planning inventory as a coherent pair: protect security, compatibility, adopter behavior, and maintainability while keeping the release train and public history reviewable.
- At the phase-start snapshot, Dependabot PRs #65 and #68–76 formed the frozen cohort. Public `main` was `2832e91d725d70eff9ba11d08052260ba17e2747`; #65 and #68–71 were based on the preceding public-main SHA `40c9978c975dbfb42db75511f44ff0369c8d7d88`, while #72–76 were based on the phase-start main. Refresh before any action. Release Please #83 is not a Dependabot disposition.
- The maintainer's JTBD is to decide which changes reduce real risk or improve library upkeep, then show the evidence without making each update a bespoke investigation. A future contributor's JTBD is to understand what landed, why, and what remains from a compact canonical record. Adopters need release-backed behavior and useful task-focused docs, not internal workflow history.
- Mature Elixir projects such as Ecto and Phoenix make release history version- and change-oriented. Apply that lesson to public release/docs surfaces; keep GSD planning material in the maintainer record and link only what is needed to explain current decisions or proof.
- No screen, operator UI, visual design, brand, public API, or backend expansion is in this phase.
- Research references: [GitHub Dependabot version-update guidance](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates), [GitHub update grouping/cooldown guidance](https://docs.github.com/en/code-security/tutorials/secure-your-dependencies/optimizing-pr-creation-version-updates), [Mix `deps.update`](https://mix.hexdocs.pm/Mix.Tasks.Deps.Update.html), [Ecto changelog](https://github.com/elixir-ecto/ecto/blob/master/CHANGELOG.md), [Phoenix changelog](https://github.com/phoenixframework/phoenix/blob/main/CHANGELOG.md), [Google ADR guidance](https://docs.cloud.google.com/architecture/architecture-decision-records), and [SLSA source requirements](https://slsa.dev/spec/v1.2/source-requirements).
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the approved Phase 169 boundary.
</deferred>

---

*Phase: 169-library-fix-delivery-and-pr-triage*
*Context gathered: 2026-09-28*
