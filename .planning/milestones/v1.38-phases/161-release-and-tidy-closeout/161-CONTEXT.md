# Phase 161: Release and Tidy Closeout - Context

**Gathered:** 2026-09-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v1.38 Packaged Adopter Proof milestone by aligning adopter and maintainer documentation with the package-backed Phoenix proof, fixing the newly surfaced Mint advisories, verifying the final change on exact-SHA CI, and completing the existing Release Please/Hex/HexDocs release path when authorized and available. If a required external permission, credential, or service prevents publication, finish all available checks and record a precise `release-ready` disposition and resume action. Clean up only milestone-owned resources and changes, preserving unrelated pre-existing work.

</domain>

<decisions>
## Implementation Decisions

### Dependency Security and Exact-SHA Proof
- **D-01:** Include remediation of the Mint advisories found in Phase 160's `deep-quality` run in Phase 161. Upgrade the dependency graph to Mint 1.10.1 or later, confirm the reported advisories are cleared, and rerun required checks on the resulting exact commit SHA.
- **D-02:** Keep the security fix scoped to dependency remediation and its evidence; do not broaden the library's runtime or public API scope.

### Release Endpoint
- **D-03:** Target an actually published release when merge and publisher authorization, secrets, and services are available. Follow the documented Release Please path and require its Hex, HexDocs, and tag/source parity evidence before describing the milestone as shipped.
- **D-04:** If an external release prerequisite blocks publication, complete all checks that can run, label the result `release-ready`, and record the specific blocker and exact resume action. Never report an unpublished release as shipped.

### the agent's Discretion
- Select the smallest compatible Mint dependency update and determine the appropriate lockfile/graph changes from repository constraints.
- Choose the verification and documentation-contract checks that provide machine-verifiable coverage of the phase requirements.
- Clean up only resources demonstrably owned by this milestone; preserve and report unrelated or pre-existing working-tree changes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract and prior evidence
- `.planning/ROADMAP.md` § Phase 161 — scope, success criteria, and release-ready fallback.
- `.planning/REQUIREMENTS.md` — DOC-01, HYGIENE-01, REL-01, and CLOSE-01 acceptance requirements.
- `.planning/phases/160-package-backed-phoenix-proof/160-VERIFICATION.md` — Phase 160 result and exact Mint advisory evidence.
- `.planning/phases/160-package-backed-phoenix-proof/160-03-SUMMARY.md` — exact-SHA package proof and remaining advisory disposition.

### Release and adopter guidance
- `docs/releasing.md` — canonical Release Please, Hex publish, HexDocs, and parity procedure.
- `CONTRIBUTING.md` — required versus advisory CI gates and maintainer verification commands.
- `examples/phoenix_meilisearch/README.md` — canonical Phoenix example setup and command guidance.
- `.github/workflows/release-please.yml` — automated release and publish workflow.
- `.github/workflows/publish-hex.yml` — explicit recovery publish workflow.
- `.github/workflows/verify-published-release.yml` — ongoing published-release verification.
- `.github/workflows/ci.yml` — exact-SHA CI and Phoenix package-proof wiring.

### Project standards and research
- `.planning/PROJECT.md` — green-main, PR-first, automation-first release policy and bounded scope.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — repository's OSS CI/CD and release engineering reference.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — repository's Elixir library release and adopter experience reference.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/verify/capability.ex` — canonical verification capability task implementation, including the Phoenix example proof entry point.
- `test/scrypath/docs_contract_test.exs` and `test/mix/tasks/verify_capability_test.exs` — existing contract/test locations that can guard documentation and command alignment.
- `examples/phoenix_meilisearch/README.md` and its smoke scripts — existing adopter setup and runnable proof guidance.
- `.github/workflows/ci.yml` — existing required and advisory gates, including package-backed Phoenix proof wiring.

### Established Patterns
- Required acceptance evidence is tied to the exact final commit SHA; optional advisory failures must be explicitly distinguished from required-gate results.
- Release Please owns versioning and tagging; publishing runs from the generated tag through the existing credential-scoped workflow.
- `mix verify.release_publish` and `mix verify.release_parity` provide post-publish Hex/HexDocs and tarball-to-tag verification.
- Repository workflow favors PR-first serious changes, a green `main`, and no simulated reviews or approvals.

### Integration Points
- The root Mix dependency graph and lockfile feed the Mint remediation and package/deep-quality audits.
- Required CI gates (`core`, `package`, `repository-contracts`, `backend`, and `ecommerce-mounted`) and the advisory Phoenix/deep-quality lanes provide implementation evidence.
- Phase closeout documentation must reconcile release status with GitHub, Hex, HexDocs, and exact-SHA evidence without claiming publication before it occurs.

</code_context>

<specifics>
## Specific Ideas

- The target is publication when authorized and operationally available, with the already-defined `release-ready` handoff used only when an external prerequisite blocks publishing.
- Mint remediation should clear the advisory set previously reported against Mint 1.9.3, using Mint 1.10.1 or later as the decision floor captured during discussion.
- Phase 160 passed its required exact-SHA gates; its advisory `mix hex.audit` failure is the concrete security follow-up entering this phase.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the Phase 161 scope.

</deferred>

---

*Phase: 161-release-and-tidy-closeout*
*Context gathered: 2026-09-24*
