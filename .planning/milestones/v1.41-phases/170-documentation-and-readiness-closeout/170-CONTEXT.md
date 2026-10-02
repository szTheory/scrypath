# Phase 170: Documentation and Readiness Closeout - Context

**Gathered:** 2026-09-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver focused adopter documentation cleanup, the warranted patch through the existing release/publication/parity process, and a separately dated terminal decision against the six approved readiness conditions. The decision must use final-source and delivery evidence, remain discoverable outside the tested tree, preserve historical assessments, and report NOT READY with specific blockers and revisit triggers unless all six conditions pass. This phase does not add product capabilities, start operator UI work, or authorize it through a READY result.

</domain>

<decisions>
## Implementation Decisions

### Adopter documentation and wayfinding
- **D-01:** Keep README focused on the adopter's first useful result: a short mode-selection summary, the acceptance-versus-visibility caveat, and links to the canonical sync guide and `Scrypath.sync_record/3` API contract. Keep detailed lifecycle and return semantics at their existing guide/API owners. This preserves first-hour context without making the README a competing contract source.
- **D-02:** Consolidate repeated README/JTBD positioning and navigation into a clear route map while retaining unique useful destinations. Preserve the README installation/schema example and the golden path's inline-first sequence. Correct the sync guide heading that currently describes accepted manual/Oban work as completed work. Update only documentation assertions superseded by this consolidation; do not restore a broad required docs-contract suite.
- **D-03:** Treat documentation as the adopter-facing experience. Optimize for the Phoenix/Ecto engineer's first-hour job, plain task-oriented language, clear next steps, low navigation cost, and accurate operational promises. This is a non-UI phase; visual redesign and brand work remain out of scope.

### Terminal readiness authority and evidence
- **D-04:** Retain the terminal six-condition decision in a dedicated GitHub issue as a separately dated maintainer comment. Add a discoverable pointer in `.planning/reference/PRE-OPERATOR-UI-READINESS.md` before final-source attestation; publish the terminal decision only after final tracked inputs and cleanup are frozen and the final source is attested. Include the six judgments, final source SHA, exact-SHA run/attempt and artifact identifiers or digests, delivery receipt or explicit release disposition, blockers, and revisit triggers. If correction is needed, append a dated correction rather than rewriting the terminal decision.
- **D-05:** Use the existing exact-SHA CI attestation as evidence for job and artifact outcomes, not as a substitute for semantic readiness judgments. Preserve candidate, final source, post-merge `main`, and published-package identities. Do not create a tracked write solely to record terminal success after attestation. A blocked or explicitly deferred publication remains distinct from a published release.
- **D-06:** Keep Phase 167's historical assessment unchanged. Reuse the approved seven-dimension/24-claim baseline and named workflows, assess concrete current source invalidators, and avoid broad reruns of unchanged passing scenarios. READY requires all six conditions to pass and recommends later ScrypathOps focus only; maintainer availability and a separate scope decision still govern UI work.

### Automation and maintainer accountability
- **D-07:** Apply an automation-first, shift-left approach to factual evidence: automate receipt collection, source/run/attempt matching, required-field and link checks, and record-shape validation as early as the existing workflow permits. Keep the six semantic judgments, any risk acceptance, and the final READY/NOT READY decision accountable to the maintainer; do not infer approval or semantic readiness from green jobs. Reuse existing lanes, and add no new required CI lane without evidence that its recurring confidence justifies its cost.

### the agent's Discretion
- Choose the smallest maintainable mechanism to collect and validate factual receipt fields, and identify where existing workflow outputs can be reused.
- Choose focused documentation assertion updates that preserve useful behavioral contracts while removing copy-specific duplication.
- Choose plan decomposition and verification commands within `CONTRIBUTING.md` and the approved release/readiness gates. Keep mutable release and GitHub facts fresh during execution.
- Preserve unrelated working-tree changes and accepted historical limits; clean or disposition only task-owned artifacts.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Approved scope and current decisions
- `.planning/ROADMAP.md` — Phase 170 boundary, success criteria, sequencing, and explicit planning decisions.
- `.planning/REQUIREMENTS.md` — DOC-03, GATE-05, and CLOSE-04 acceptance contracts.
- `.planning/PROJECT.md` — product scope, release posture, and automation-first evidence principles.
- `.planning/STATE.md` — carried-forward decisions, source/evidence limits, and unrelated local state to preserve.
- `.planning/research/v1.41/SUMMARY.md` — approved milestone decisions and rationale.
- `.planning/research/v1.41/ADOPTION-REVIEW.md` — confirmed documentation duplication, adopter jobs, scoped alternatives, and terminal-record protocol.
- `.planning/research/v1.41/DELIVERY-REVIEW.md` — final delivery, source identity, and release constraints.

### Adopter journey and canonical documentation owners
- `README.md` — installation, Quick Path, first-result route, current wayfinding, and copy that is being consolidated.
- `guides/golden-path.md` — inline-first tutorial from setup through first search.
- `guides/jtbd-and-user-flows.md` — adopter jobs and task-oriented guide routes; merge duplicates without losing unique destinations.
- `guides/sync-modes-and-visibility.md` — canonical sync semantics, visibility caveats, lifecycle, and recovery guidance.
- `lib/scrypath.ex` — canonical API documentation for `Scrypath.sync_record/3` return contracts.
- `test/scrypath/docs_contract_test.exs` — current documentation assertions; update only assertions made obsolete by the approved consolidation.

### Readiness, provenance, and release process
- `.planning/reference/PRE-OPERATOR-UI-READINESS.md` — live readiness authority, current navigation, and pointer to the future terminal record.
- `.planning/milestones/v1.39-phases/162-whole-product-evidence-baseline/162-BASELINE.md` — approved seven-dimension/24-claim baseline.
- `.planning/milestones/v1.39-phases/163-findings-and-bounded-follow-up/163-FINDINGS.md` — prior dispositions and claim limits.
- `.planning/milestones/v1.40-phases/167-dated-readiness-and-closeout/167-ASSESSMENT.md` — immutable prior readiness result and evidence boundary.
- `.github/workflows/ci.yml` — exact-SHA closeout attestation contents and current artifact retention.
- `.github/workflows/release-please.yml` — existing Release Please-owned publication path and post-publication checks.
- `docs/releasing.md` — package gate, publication, consumer, and parity procedures.
- `CONTRIBUTING.md` — canonical verification commands and capability matrix.

### Project research and durable guidance
- `prompts/scrypath-milestone-ratchet-roadmap.txt` — evidence-gated scope, documentation UX, CI cost, release truth, and repository hygiene.
- `prompts/search-lib-use-cases-deep-research.md` — adopter/operator jobs and first-use priorities; current approved scope takes precedence over speculative suggestions.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — Elixir OSS CI and release guidance, subordinate to current repo policy.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Elixir library maintenance and adopter guidance, subordinate to current repo policy.

### External documentation and provenance exemplars
- [Ecto Getting Started](https://ecto.hexdocs.pm/getting-started.html), [Phoenix contexts](https://phoenix.hexdocs.pm/contexts.html), and [ExDoc](https://ex-doc.hexdocs.pm/ExDoc.html) — progressive setup, framework boundaries, and guide/API-reference organization.
- [Searchkick README](https://github.com/ankane/searchkick#readme) — example of leading with installation, declaration, indexing, and querying; do not copy its Rails-specific integration choices.
- [GitHub artifact retention](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/remove-workflow-artifacts), [immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases), and [issue comment API](https://docs.github.com/en/rest/issues/comments) — retention, release immutability options, and record mutability constraints.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `README.md` already has a first-result Quick Path and routes the copy-paste flow to `guides/golden-path.md`.
- `guides/golden-path.md` provides a linear first-hour sequence using one Ecto schema, context-owned sync/search, and `:inline` mode.
- `guides/sync-modes-and-visibility.md` owns detailed consistency, mode, lifecycle, and recovery semantics; `lib/scrypath.ex` owns the public return contract.
- `guides/jtbd-and-user-flows.md` captures six adopter jobs and distinct follow-on routes that should survive navigation consolidation.
- `.github/workflows/ci.yml` emits a source-bound exact-SHA attestation with run/attempt and coverage artifact identifiers/digest. The current seven-day artifact is evidence input, not durable storage for the semantic decision.

### Established Patterns
- README is intended to be a concise route map; guides own detailed behavior and API docs own exact function contracts. Current README copy repeats sync details despite stating that it does not duplicate the sync guide.
- The release train is Release Please-owned and already verifies package contents, published visibility, consumer compilation, and tag/package parity. Preserve those identities and checks.
- Readiness distinguishes adopter support from the later operator-UI investment gate. Historical assessments remain dated and immutable; a new assessment joins final-source and delivery receipts.
- `docs_contract_test.exs` includes phrase assertions requiring lifecycle and return details in README as well as canonical docs. Those copy-specific assertions may need focused updates; retain meaningful docs validation without broadening required CI.

### Integration Points
- README/JTBD consolidation touches their navigation and sync wording, `guides/sync-modes-and-visibility.md`, API documentation in `lib/scrypath.ex`, and focused assertions in `test/scrypath/docs_contract_test.exs`.
- The terminal pointer belongs in the live readiness authority before final attestation; the semantic decision belongs in the external issue comment after attestation.
- Final docs/code changes and cleanup feed the frozen tracked source, exact-SHA attestation, post-merge receipt, Release Please outcome, and terminal record. Preserve the unrelated dirty working-tree files already documented in `.planning/STATE.md`.

</code_context>

<specifics>
## Specific Ideas

- The maintainer asked for recommendation-led research across relevant expert perspectives and emphasized strong developer ergonomics, coherent trade-offs, and an automation-first/shift-left DevOps bias.
- Apply automation to factual receipt gathering and validation; keep semantic assessment and maintainer approval explicit. Reuse Ecto/Phoenix's linear learning and boundary conventions and successful library documentation patterns only where they fit Scrypath's Ecto-first product.
- No visual/UI design decision applies to this phase. Documentation wayfinding and operational microcopy remain user-experience concerns.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the approved Phase 170 scope.
</deferred>

---

*Phase: 170-documentation-and-readiness-closeout*
*Context gathered: 2026-09-29*
