# Phase 109: Release Train and Package Truth Audit - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 109 delivers release-train and package-truth hardening only: it should make Scrypath's version, changelog, Release Please manifest/config, git tag behavior, Hex package shape, publish workflow, post-publish verification, and release parity auditable as one boring maintainer path.

This phase may fix discovered release-truth drift as patch-sized corrections. It must not add new runtime API surface, widen product scope, promote unrelated CI lanes, or turn release operations into heavyweight process.

</domain>

<decisions>
## Implementation Decisions

### Release Agreement
- **D-01:** Keep Release Please manifest mode as the canonical release contract. Do not replace it with a tag-first bespoke release system, Changesets, or manual maintainer-cut releases.
- **D-02:** Harden the existing contract rather than re-architect it: `mix.exs` `@version`, `.release-please-manifest.json`, `release-please-config.json`, `CHANGELOG.md`, Release Please tag checkout, and publish workflow guards should be mechanically checked for agreement.
- **D-03:** Prefer semantic checks where practical over brittle grep-only checks. Existing grep assertions in `verify.phase11` are acceptable as anchors, but planner should look for low-risk ways to parse JSON/YAML or otherwise make drift failures more diagnostic.
- **D-04:** Preserve the current squash-merge/PR-title release train semantics from `docs/releasing.md` and `CONTRIBUTING.md`; do not impose contributor-heavy commit ritual beyond the existing Release Please flow.

### Hex Package Shape
- **D-05:** Treat root `mix.exs` `package.files` as the source of package intent, but treat the unpacked Hex artifact as the proof surface. REL-02 is satisfied by what actually ships, not merely by what the whitelist says.
- **D-06:** Use a hybrid package proof: artifact-first allowlist assertions for expected shipped path families plus explicit deny assertions for high-risk directories and generated artifacts.
- **D-07:** High-risk exclusions must include at least `scrypath_ops/`, `examples/`, `website/` build output, `.planning/`, `node_modules`, Playwright reports/results/artifacts, and other non-root-library outputs discovered during implementation.
- **D-08:** Avoid a large checked-in package snapshot unless implementation evidence proves it is needed. Snapshot workflows can become rote churn; a focused normalized artifact assertion is the better fit for this repo's maintenance lane.

### Publish Proof Chain
- **D-09:** Keep `mix verify.phase11` as the lean always-on required release-truth gate. It should remain auth-free and suitable for PR/main CI.
- **D-10:** Keep live registry/docs checks out of routine PR gates. Hex visibility, HexDocs reachability, and published-package consumer compile belong in post-publish workflows because they depend on external state and credentials.
- **D-11:** The canonical publish path should remain layered: Release Please creates the release/tag, the publish job checks out the tag, verifies workspace cleanliness, verifies version agreement, runs `mix verify.phase11`, performs `mix hex.publish --dry-run --yes`, publishes, runs `mix verify.release_publish X.Y.Z`, then runs `mix verify.release_parity X.Y.Z`.
- **D-12:** The manual `publish-hex.yml` recovery workflow should mirror the canonical proof chain from an explicit reviewed tag/ref and version. It is a break-glass replay path, not a second release system.
- **D-13:** Retain scheduled published-release verification as ongoing trust evidence, with retries and issue dedupe to avoid transient-noise churn.

### the agent's Discretion
- Planner may choose the exact implementation shape for parsing workflow/config files, package artifact normalization, and test organization as long as the resulting checks are deterministic, service-free for `verify.phase11`, and easy for maintainers to diagnose.
- Planner may consolidate checks into existing release tests/tasks or add a focused release-truth helper module if that improves clarity without creating new public API.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` — Phase 109 goal, requirements REL-01 through REL-03, and success criteria.
- `.planning/REQUIREMENTS.md` — v1.30 release-truth requirements and out-of-scope boundaries.
- `.planning/PROJECT.md` — current maintenance-and-evidence mode, release train posture, and scope guard authority.
- `.planning/STATE.md` — active phase position and prior decisions around lean gates and advisory proof posture.

### Release Train and Publish Surfaces
- `docs/releasing.md` — maintainer source of truth for Release Please, `mix verify.phase11`, publish checks, recovery, and parity workflows.
- `CONTRIBUTING.md` — contributor-facing release train, required/advisory CI lanes, and local verification guidance.
- `mix.exs` — package metadata, `@version`, `@source_ref`, docs extras, and `package.files` whitelist.
- `release-please-config.json` — Release Please Elixir manifest-mode configuration and pre-1.0 bump policy.
- `.release-please-manifest.json` — current Release Please version authority for the root package.
- `CHANGELOG.md` — human-facing release narrative managed by Release Please.
- `.github/workflows/release-please.yml` — canonical Release Please and Hex publish workflow.
- `.github/workflows/publish-hex.yml` — manual recovery publish workflow.
- `.github/workflows/verify-published-release.yml` — scheduled/manual published-release verification workflow.

### Existing Verification Code
- `lib/mix/tasks/verify.phase11.ex` — always-on release-alignment gate that runs release tests, docs warnings-as-errors, workflow checks, manifest/version agreement, and `mix hex.build --unpack`.
- `lib/mix/tasks/verify.release_publish.ex` — live post-publish proof for Hex package visibility, clean-consumer compile, and versioned HexDocs reachability.
- `lib/mix/tasks/verify.release_parity.ex` — published Hex tarball versus git tag path parity check.
- `lib/mix/tasks/verify.workspace_clean.ex` — publish workflow workspace cleanliness check.
- `test/release/package_metadata_test.exs` — existing package metadata and docs metadata assertions.
- `test/release/consumer_smoke_test.exs` — existing packaged consumer smoke coverage.
- `test/scrypath/docs_contract_test.exs` — release workflow and documentation contract coverage.
- `test/mix/tasks/verify_release_parity_test.exs` — existing release parity behavior coverage.
- `test/mix/tasks/workflow_wiring_test.exs` — workflow wiring and release-documentation assertions.

### Prompt Research
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Elixir OSS library expectations around explicit APIs, docs, package hygiene, and maintainer trust.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — GitHub Actions, Release Please, Hex publishing, ExDoc, lean required matrices, and release automation recommendations.
- `prompts/elixir-best-practices-deep-research.md` — general Elixir implementation discipline for clear, testable, idiomatic code.
- `prompts/scrypath-brand-book.md` — brand posture: calm, exact, technical, trustworthy, and operationally honest.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Verify.Phase11` already provides the auth-free release gate and runs `mix hex.build --unpack`; Phase 109 should extend this path rather than create a parallel always-on gate.
- `Mix.Tasks.Verify.ReleasePublish` already models retryable live checks for Hex visibility, consumer compile, and HexDocs reachability; reuse its retry semantics and environment-variable pattern where live checks are involved.
- `Mix.Tasks.Verify.ReleaseParity` already validates semver input, fetches Hex package contents, compares against tagged git paths, and exposes pure helpers for unit testing.
- Existing release tests under `test/release/` and workflow tests under `test/mix/tasks/` are the natural homes for additional release-truth assertions.

### Established Patterns
- Required gates stay lean and service-free where possible; live/external checks run in explicit publish or advisory/scheduled contexts.
- Maintainer docs avoid duplicating large matrices; `docs/releasing.md` owns release mechanics and `CONTRIBUTING.md` indexes CI/local commands.
- Release automation favors explicit, reviewable, PR-driven Release Please flow over bespoke manual release commands.
- Verification tasks should produce actionable failure messages because release drift is an operational issue, not a cosmetic mismatch.

### Integration Points
- Extend `verify.phase11` only with deterministic, credential-free checks.
- Keep `.github/workflows/release-please.yml` and `.github/workflows/publish-hex.yml` aligned so recovery mirrors canonical publish proof.
- Update `docs/releasing.md` and any affected contract tests when release proof semantics become stricter.
- If package artifact checks need unpacked paths, normalize paths from the `mix hex.build --unpack` output rather than relying on local checkout state.

</code_context>

<specifics>
## Specific Ideas

The user explicitly requested subagent-backed research across all gray areas and asked for one coherent recommendation set that emphasizes Elixir/Phoenix/Ecto ecosystem fit, lessons from successful libraries and other package ecosystems, footguns, DX, principle of least surprise, and Scrypath's product vision.

The coherent recommendation set is:

1. Keep Release Please manifest mode and harden it.
2. Prove actual Hex artifact shape, not just declared package intent.
3. Keep `verify.phase11` lean and auth-free.
4. Put live Hex/HexDocs/consumer proof in post-publish and scheduled workflows.
5. Keep manual recovery as a mirrored replay path, not a second release authority.

</specifics>

<deferred>
## Deferred Ideas

- Replacing Release Please with Changesets or a custom tag-first release system is deferred. It may be reconsidered only if Scrypath develops multi-artifact governance needs that outweigh the current Elixir-native Release Please flow.
- Adding a large checked-in package manifest snapshot is deferred unless focused artifact assertions prove insufficient.

</deferred>

---

*Phase: 109-Release Train and Package Truth Audit*
*Context gathered: 2026-05-31*
