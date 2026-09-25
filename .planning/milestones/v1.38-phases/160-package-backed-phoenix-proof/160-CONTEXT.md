# Phase 160: Package-Backed Phoenix Proof - Context

**Gathered:** 2026-09-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 160 proves that the Scrypath package artifact built from the current checkout supports the existing `examples/phoenix_meilisearch` application against real Postgres and Meilisearch services. The proof covers the existing inline, Oban, and related-data integration scenarios and reports deterministic outcomes with setup, service, package/compile, and test failures attributable to their stage.

Keep the example's ordinary repository path-dependency workflow working. Reuse its existing service prerequisites and the advisory Phoenix service lane; do not add or promote a required CI gate. Isolate task-owned temporary files and clean them on both success and failure by default. No runtime API, backend, application, or UI capability expansion is in scope.

</domain>

<decisions>
## Implementation Decisions

### Maintainer command and adopter workflow
- **D-01:** Expose package-backed execution as `mix verify.phoenix_example --package`. Preserve the no-argument `mix verify.phoenix_example` path-backed behavior. Keep the package mode on the live Phoenix proof command rather than adding another top-level task or mixing it into the service-free `verify.adopter` default.
- **D-02:** Keep package-mode setup behind the maintainer command. The command should reuse the existing Phoenix example and its documented Postgres/Meilisearch prerequisites; consumers should not need to edit the example's normal `path: "../.."` dependency or learn temporary artifact wiring.

### CI coverage and service use
- **D-03:** Run the existing path-backed Phoenix proof and then the package-backed proof in the same existing advisory `phoenix-example` CI job. Reuse its Postgres and Meilisearch services, preserve per-run/test isolation, and retain the advisory status. Do not replace the path proof or create a separate service-backed job without new evidence that job-level isolation is needed.

### Results and diagnostics
- **D-04:** Report recognizable progress and pass/fail outcomes for the proof stages. On failure, identify the failing stage, command, and exit status, preserve the child process output, and return a failing task exit status. Keep ordinary output useful in both local terminals and CI logs; do not add a machine-readable report artifact or verbosity mode absent a concrete cross-run triage need.
- **D-05:** Keep diagnostics actionable without exposing environment variable values or secrets. The task should make the service prerequisites and failure stage clear while leaving the temporary dependency implementation as an internal detail.

### Temporary files and debug recovery
- **D-06:** Use a unique isolated temporary workspace for task-owned package/example artifacts and clean it after both successful and failed runs by default. Do not leave success artifacts behind.
- **D-07:** Provide an explicit `--keep-temp-on-failure` opt-in for local debugging. When selected and a run fails, retain only that failed run's task-owned workspace and print its full location; successful runs still clean up. Keep credentials and secret material out of the retained workspace.

### the agent's Discretion
- Choose the implementation details for presenting the unpacked artifact to a clean copy of the existing example, provided the proof demonstrably uses the built package artifact and cannot silently fall back to a repository path dependency.
- Choose helper/module boundaries, exact progress labels, subprocess handling, temporary-directory naming, and the contract-test structure while preserving the command, diagnostics, CI, and cleanup decisions above.
- Keep generated reports or CI artifact retention out of scope unless a concrete Phase 160 requirement cannot be met with deterministic task output and exit status.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope, project posture, and requirements
- `.planning/ROADMAP.md` — Phase 160 goal, success criteria, dependency, and explicit reuse of the advisory Phoenix service lane.
- `.planning/REQUIREMENTS.md` — Locked PKG-01, PKG-02, PKG-03, and PROOF-01 requirements and v1.38 scope boundaries.
- `.planning/PROJECT.md` — Approved v1.38 proof wedge, canonical adopter contract, green-main release-train posture, and out-of-scope product expansion.
- `.planning/STATE.md` — Current milestone/phase position and session state.

### Phoenix adopter example and verification entrypoints
- `examples/phoenix_meilisearch/README.md` — Authoritative service prerequisites, environment variables, normal path-based flow, and existing integration scenarios.
- `examples/phoenix_meilisearch/AGENTS.md` — Local Phoenix/Ecto/Elixir implementation and verification guidance.
- `examples/phoenix_meilisearch/mix.exs` — Current example dependency declaration and aliases; preserve its normal path-dependency workflow.
- `lib/mix/tasks/verify.phoenix_example.ex` — Existing capability task that owns the Phoenix-example verification entrypoint.
- `lib/mix/tasks/verify/capability.ex` — Capability dispatch and current `verify.phoenix_example` behavior.
- `lib/mix/tasks/verify.adopter.ex` — Existing live-mode service checks, subprocess orchestration, and failure-reporting precedent.
- `.github/workflows/ci.yml` — Existing `phoenix-example (advisory)` service job and its command wiring.
- `CONTRIBUTING.md` — Contributor-facing required/advisory gate distinctions and canonical Phoenix example command guidance.

### Package, isolation, and live integration patterns
- `test/release/consumer_smoke_test.exs` — Existing `mix hex.build --unpack` artifact flow, clean consumer schema compilation without a path dependency, isolated Mix/Hex homes, and temporary workspace cleanup.
- `lib/mix/tasks/verify.phase11.ex` — Existing package/release verification orchestration and package unpack behavior.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs` — Inline real-service proof, unique index prefix, and index cleanup pattern.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_oban_stack_test.exs` — Oban-backed real-service proof pattern.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_related_inline_stack_test.exs` — Inline related-data fan-out scenario.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs` — Oban related-data fan-out and deterministic in-process job behavior.

### Project research guidance
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Hex package shape, consumer ergonomics, and library proof guidance.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — Required versus advisory CI gates, deterministic CI, and release-proof guidance.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — Elixir/Phoenix/Ecto architecture and library-versus-host application boundaries.
- `prompts/elixir-best-practices-deep-research.md` — Elixir testing and runtime conventions.
- `prompts/ecto-best-practices-deep-research.md` — Ecto and database-backed test-isolation guidance.
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix application and test conventions.
- `prompts/elixir-search-lib-deep-research.md` — Search-library domain and adopter workflow guidance.
- `prompts/meileisearch best practices for scrypath deep research.md` — Meilisearch service, task, test-isolation, and operational proof considerations.

No separate phase SPEC or ADR is present; scope and requirements are locked by ROADMAP.md and REQUIREMENTS.md.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix verify.phoenix_example` delegates through `Mix.Tasks.Verify.Capability` to the canonical live adopter flow and already runs in the advisory Phoenix CI lane.
- `mix verify.package` reaches Phase 11 package verification, and `test/release/consumer_smoke_test.exs` already builds/unpacks the Hex package and compiles a clean consumer schema without a repository path dependency.
- The Phoenix example already has integration tests for inline sync, Oban sync, inline related-data fan-out, and Oban related-data fan-out. Its README is the detailed service and command runbook.
- The existing package smoke test creates an isolated temp root and isolated `HEX_HOME` / `MIX_HOME`, then removes task-owned files with `on_exit/1`; release verification tasks also clean temporary roots.

### Established Patterns
- The example's live tests are gated by `SCRYPATH_EXAMPLE_INTEGRATION`, use real Postgres and Meilisearch, and use unique Meilisearch index prefixes with cleanup to isolate runs.
- Oban integration tests configure inline testing so workers execute deterministically in-process while exercising the real service path.
- Root verification exposes semantic `mix verify.*` capabilities and prints stage-oriented output; the package and Phoenix service checks are separate capabilities.
- Existing CI explicitly distinguishes required merge gates from the advisory Phoenix integration job. This phase preserves that topology and status.

### Integration Points
- The package mode connects `Mix.Tasks.Verify.PhoenixExample` / `Mix.Tasks.Verify.Capability` with the existing example integration tests and package artifact build path.
- Contract coverage must keep the command, `.github/workflows/ci.yml` advisory job, and proof documentation aligned.
- The package-mode example execution must be isolated from the checked-out path dependency and from the preceding path-backed run while using the same live service prerequisites.

</code_context>

<specifics>
## Specific Ideas

- Preferred command: `mix verify.phoenix_example --package`, with the current no-argument path-backed proof left intact.
- CI runs the path-backed proof first and the package-backed proof afterward in the same advisory job and service environment.
- Show stage progress and useful failure output in the terminal; keep cleanup on by default and expose failed-workspace retention only as an explicit debugging option.
- This is a maintainer CLI/CI experience, not a visual UI phase. Apply user-centered affordances through predictable command behavior, clear prerequisites, readable text output, useful exit status, and no leaked secrets.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the Phase 160 package-backed proof boundary.

</deferred>

---

*Phase: 160-package-backed-phoenix-proof*
*Context gathered: 2026-09-23*
