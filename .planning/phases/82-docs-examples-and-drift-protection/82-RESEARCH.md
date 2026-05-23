# Phase 82: Docs, examples, and drift protection - Research

**Researched:** 2026-05-23
**Domain:** Public docs architecture, Phoenix request-edge wayfinding, example-proof posture, and narrow drift protection for the v1.21 toolkit story.
**Confidence:** HIGH. Based on the checked-out docs, tests, CI workflow, example README, and locked context from Phases 80 and 81.

<user_constraints>
## User Constraints

- Keep `Scrypath.search/3` as the canonical runtime and keep contexts as the application boundary.
- Keep `Scrypath.QueryParams` as the public plain-data edge seam and `Scrypath.Phoenix` as optional request-edge glue only.
- Do not expose `%Scrypath.Query{}` as public API.
- Do not turn the example app, Phoenix wrappers, or docs into a framework facade.
- Prefer one clear canonical adoption story with explicit optional Phoenix guidance and bounded drift protection.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | Guides and examples make the boundary explicit: contexts stay canonical, helpers are wrappers, and no schema-generated runtime verbs or UI layer ship in this milestone. | Add one narrow canonical request-edge guide, then route README, root moduledoc, overview, and Phoenix guides into it without duplicating the same explanation everywhere. |
| VRFY-01 | Tests and contract coverage fail on drift around plain-data toolkit output, field-scoped errors, helper optionality, and canonical runtime delegation. | Keep verification targeted: assert the v1.21 public spine, compile-check the fixture examples, and lock example README / CI / local smoke contract surfaces without snapshotting entire prose blocks. |
</phase_requirements>

## Summary

The checked-out code already ships the phase-81 runtime surfaces: `Scrypath.QueryParams.normalize/1`, `QueryParams.to_search_args/1`, and `Scrypath.Phoenix` now exist, and the Phoenix guides already mention them. The remaining problem is public-story coherence. The root docs still describe `QueryParams` with phase-80-era wording in `lib/scrypath.ex`, the README does not give v1.21 one obvious request-edge lane, and the guide set lacks a single canonical page that explains the full boundary from params to context search. [VERIFIED: `lib/scrypath.ex`] [VERIFIED: `README.md`] [VERIFIED: `guides/overview.md`]

The guide cluster is close to the desired shape, but it currently spreads the same request-edge explanation across multiple Phoenix pages. `guides/phoenix-contexts.md`, `guides/phoenix-controllers-and-json.md`, `guides/phoenix-liveview.md`, and `guides/faceted-search-with-phoenix-liveview.md` each reference `Scrypath.Phoenix`, but there is no one canonical guide for the shared mental model: browser params normalize once, helpers stay at the edge, contexts still call `Scrypath.search/3`, and Phoenix remains optional. Phase 82 should create that guide and convert the existing Phoenix docs into role-specific consumers of it. [VERIFIED: `guides/phoenix-contexts.md`] [VERIFIED: `guides/phoenix-controllers-and-json.md`] [VERIFIED: `guides/phoenix-liveview.md`] [VERIFIED: `guides/faceted-search-with-phoenix-liveview.md`]

The example app already plays the right role: it is a real Postgres + Meilisearch + Oban proof harness with explicit CI and local smoke commands. That is valuable, but it should stay an operational proof surface rather than becoming the primary teaching artifact for the request-edge contract. Phase 82 should make the split explicit: HexDocs teaches the public boundary, while `examples/phoenix_meilisearch` proves the real-service path and stays aligned with CI and local smoke instructions. [VERIFIED: `examples/phoenix_meilisearch/README.md`] [VERIFIED: `.github/workflows/ci.yml`]

The current docs-contract suite already uses bounded string assertions rather than giant snapshots, which is the right posture for this phase. The missing piece is focus: Phase 82 should add targeted assertions for the v1.21 public spine and example/CI parity, not freeze broad editorial prose. The compile-checked fixture seam and request-shape smoke tests are already the correct executable proof path for controller and LiveView examples. [VERIFIED: `test/scrypath/docs_contract_test.exs`] [VERIFIED: `test/support/docs/phoenix_example_case.ex`] [VERIFIED: `test/support/docs/phoenix_examples_test.exs`] [VERIFIED: `test/support/docs/phoenix_request_shape_smoke_test.exs`]

**Primary recommendation:** plan Phase 82 in two slices:
1. Publish one canonical request-edge guide and rewire root wayfinding plus Phoenix guides around it.
2. Lock narrow contract tests for the public story, example README / CI / smoke alignment, and root-module drift.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical request-edge mental model | HexDocs guide | README / root moduledoc / overview | One guide should own the explanation so the rest can point to it instead of drifting. |
| Phoenix role-specific usage | Phoenix guides | Compile-checked fixtures | Controllers and LiveView should keep only the details specific to those surfaces. |
| Real-service proof and smoke runbook | Example README | CI workflow | The example exists to prove the operational path, not to become the canonical public tutorial. |
| Drift protection | Focused docs-contract assertions | Fixture tests + smoke tests | The public story should fail on boundary drift, not on ordinary editorial edits. |
| Runtime authority | Contexts calling `Scrypath.search/3` | `QueryParams` / `Scrypath.Phoenix` | The public docs must keep preparation and execution separate. |

## Standard Stack

### Core

| Library / Module | Purpose | Why Standard |
|------------------|---------|--------------|
| `README.md` | Root wayfinding and adoption triage | First entry point for GitHub readers and Hex package visitors. |
| `lib/scrypath.ex` | Root moduledoc and public runtime discovery | ExDoc lobby surface must match the shipped v1.21 story. |
| `guides/overview.md` | Guide index and route map | Best place to insert one new canonical request-edge guide without rebuilding IA. |
| `guides/phoenix-*` | Role-specific integration docs | Already the canonical Phoenix adoption cluster. |

### Supporting

| Library / Module | Purpose | When to Use |
|------------------|---------|-------------|
| `test/scrypath/docs_contract_test.exs` | Narrow prose-contract assertions | For public-boundary and example/CI parity assertions. |
| `test/support/docs/phoenix_example_case.ex` | Compile-checked code examples | For executable controller/LiveView boundary proof. |
| `test/support/docs/phoenix_examples_test.exs` | Fixture behavior tests | For helper-only boundary and context-owned search flow proof. |
| `test/support/docs/phoenix_request_shape_smoke_test.exs` | Plug-decoded request-shape proof | For edge grammar parity. |
| `examples/phoenix_meilisearch/README.md` | Real-service runbook | For CI and local smoke parity. |
| `.github/workflows/ci.yml` | Canonical GitHub CI job definitions | For example README command and env alignment. |

## Architecture Patterns

### Pattern 1: One canonical request-edge guide, many narrow references

Create one short guide that explains the v1.21 lane from browser params to context-owned search. README, `Scrypath` moduledoc, `guides/overview.md`, and the Phoenix guide cluster should summarize or link, not restate the whole story.

### Pattern 2: Core-first, Phoenix-second information architecture

Present `Scrypath.QueryParams` and the plain-data contract first, then `Scrypath.Phoenix` as optional glue. This matches the shipped code and avoids giving Phoenix wrappers conceptual parity with the runtime.

### Pattern 3: Example app as proof harness, not the teaching surface

Keep the example README focused on real services, commands, env vars, and CI parity. Cross-link it from the docs as proof, but do not force adopters to reverse-engineer the public contract from example code.

### Pattern 4: Contract-shaped drift protection

Prefer assertions like “README routes to the canonical guide,” “root moduledoc no longer claims phase-80-only nested-param behavior,” “Phoenix docs say helpers do not execute search,” and “example README / CI share the same job, env, and command story.” Avoid broad prose snapshots.

## Recommended Plan Slices

### Slice 1: Canonical guide and wayfinding rewrite

- Add one new request-edge guide under `guides/`.
- Update `README.md`, `lib/scrypath.ex`, and `guides/overview.md` to route readers into that guide.
- Update `guides/getting-started.md`, `guides/golden-path.md`, and the Phoenix guides so they teach role-specific usage while linking back to the canonical request-edge explanation.

### Slice 2: Example-proof alignment and docs drift protection

- Refine `examples/phoenix_meilisearch/README.md` so it explicitly describes itself as the proof/runbook surface.
- Add or tighten docs-contract assertions around the v1.21 public spine, `%Scrypath.Query{}` non-public status, Phoenix optionality, and example README / CI / local smoke alignment.
- Reuse the fixture and smoke tests as the executable proof path for controller and LiveView examples.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Canonical public story | A long README section duplicating multiple guides | One dedicated request-edge guide + short wayfinding pointers | Reduces drift and keeps the mental model sharp. |
| Example teaching surface | A second tutorial hidden in `examples/phoenix_meilisearch/README.md` | HexDocs as the teaching surface, example README as proof/runbook | Preserves the operational/example split. |
| Drift protection | Full-document snapshots or line-by-line prose freezing | Bounded contract assertions and compile-checked examples | Maintainer-friendly and specific to public promises. |
| Phoenix positioning | Repeating loud warnings on every page | Calm selective reminders in root docs and role-specific guides | Keeps the docs precise without sounding defensive. |

## Common Pitfalls

### Pitfall 1: Leaving phase-80 wording in root docs

`lib/scrypath.ex` still says `QueryParams` only normalizes the top-level envelope and requires runtime-compatible nested values. Leaving that text in place would directly contradict the checked-out Phase 81 surface.

### Pitfall 2: Teaching Phoenix wrappers as a second runtime

If docs imply `Scrypath.Phoenix` executes search, owns LiveView lifecycle, or replaces contexts, the public story drifts away from the actual code and milestone boundary.

### Pitfall 3: Letting the example README become the only complete story

If users need the example app to understand the request-edge contract, the public library docs have failed their job and Phoenix optionality gets blurred.

### Pitfall 4: Over-broad docs contracts

If `docs_contract_test.exs` starts freezing headings, paragraph wording, or large snippets, Phase 82 will create contributor-hostile maintenance cost instead of useful drift protection.

### Pitfall 5: Forgetting CI/example/local command parity

The example README, CI job name, env vars, and local smoke instructions must agree. Otherwise adopters and contributors will trip over stale proof steps even if the library API docs are correct.

## Validation Architecture

### Test Framework

- `ExUnit` via targeted `mix test` commands for docs contracts and docs fixtures
- `mix docs --warnings-as-errors` for the published docs build
- Existing example README / CI workflow assertions in `test/scrypath/docs_contract_test.exs`

### Phase Requirements -> Test Map

| Requirement | Validation Strategy |
|-------------|---------------------|
| DOC-01 | Assert the root docs and Phoenix guides route readers through one canonical request-edge guide while preserving context-owned `Scrypath.search/3`, optional Phoenix wrappers, and `%Scrypath.Query{}` non-public status. |
| VRFY-01 | Add narrow docs-contract assertions plus fixture-level tests that fail if helper APIs drift into a second runtime or if example README / CI / smoke instructions diverge. |

### Wave 0 Gaps

- No Phase 82 research artifact existed before this run.
- No Phase 82 validation ledger existed before this run.
- The root moduledoc still contains phase-80-only wording that Phase 82 should explicitly remove.

## Security Domain

### Applicable Concerns

- Public docs overstating the capabilities or authority of optional wrappers
- Example instructions drifting from the CI path contributors actually use
- Published docs accidentally exposing internal `%Scrypath.Query{}` details as public contract

### Mitigation Direction

- Keep the request-edge contract plain-data and root it in one canonical guide
- Pin the example README / CI / smoke parity with targeted assertions
- Keep `%Scrypath.Query{}` mentioned only as a non-public boundary reminder where necessary

## Open Questions (RESOLVED)

1. **Should the new guide live under Phoenix-specific docs?**
   - Recommendation: no. It should be a shared request-edge guide because `QueryParams` is framework-light and Phoenix is optional.

2. **Should the example app become the canonical teaching path for v1.21?**
   - Recommendation: no. It should remain the proof/runbook surface, with HexDocs owning the public teaching lane.

3. **Should docs drift protection snapshot the full public docs corpus?**
   - Recommendation: no. Keep it contract-shaped and targeted to the v1.21 public spine.

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/phases/82-docs-examples-and-drift-protection/82-CONTEXT.md`
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md`
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-RESEARCH.md`
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-PATTERNS.md`
- `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-VALIDATION.md`
- `.planning/phases/80-public-query-toolkit-contract/80-RESEARCH.md`
- `.planning/phases/80-public-query-toolkit-contract/80-PATTERNS.md`
- `.planning/phases/80-public-query-toolkit-contract/80-VERIFICATION.md`
- `README.md`
- `CONTRIBUTING.md`
- `lib/scrypath.ex`
- `lib/scrypath/query_params.ex`
- `lib/scrypath/phoenix.ex`
- `guides/overview.md`
- `guides/getting-started.md`
- `guides/golden-path.md`
- `guides/phoenix-walkthrough.md`
- `guides/phoenix-contexts.md`
- `guides/phoenix-controllers-and-json.md`
- `guides/phoenix-liveview.md`
- `guides/faceted-search-with-phoenix-liveview.md`
- `examples/phoenix_meilisearch/README.md`
- `test/scrypath/docs_contract_test.exs`
- `test/scrypath/phoenix_test.exs`
- `test/scrypath/query_params_test.exs`
- `test/support/docs/phoenix_example_case.ex`
- `test/support/docs/phoenix_examples_test.exs`
- `test/support/docs/phoenix_request_shape_smoke_test.exs`
- `.github/workflows/ci.yml`

## RESEARCH COMPLETE
