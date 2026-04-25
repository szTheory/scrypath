# Phase 70: Papercuts and readiness checkpoint - Research

**Researched:** 2026-04-22 [VERIFIED: system date]  
**Domain:** Adopter-friction reduction and milestone-close readiness bookkeeping for the shipped integration-confidence surface [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]  
**Confidence:** HIGH [VERIFIED: local repo audit]

<user_constraints>
## User Constraints

- Phase 70 is scoped to **INTG-05** and **INTG-06** only. [VERIFIED: .planning/REQUIREMENTS.md]
- Close no more than **three** papercuts. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md]
- Every papercut fix must land with a regression test, contract test, or example assertion. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md]
- Milestone close must be framed as a **readiness checkpoint**, not automatic breadth expansion. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/PROJECT.md]
- Changes may touch docs, example, warnings, verify flows, and planning artifacts, but must remain adoption-proof, support-contract, or friction-reduction work. [VERIFIED: user prompt] [VERIFIED: .planning/PROJECT.md]
- Phase 70 must **not widen the public search/indexing surface**. [VERIFIED: user prompt] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INTG-05 | The milestone closes at most three concrete adopter-friction papercuts surfaced by the current docs, example, warnings, or dogfood flows, and each fix lands with a regression test or doc-contract anchor. [VERIFIED: .planning/REQUIREMENTS.md] | Plan three or fewer contract-backed fixes drawn from current docs/example/verify friction, not new API work. [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md] [VERIFIED: guides/golden-path.md] [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: lib/mix/tasks/verify.adopter.ex] |
| INTG-06 | Rolling planning artifacts and milestone-close notes explicitly treat v1.17 as a readiness checkpoint, not another breadth milestone, and end with a clear reassessment of whether external integration feedback should replace further in-repo polish. [VERIFIED: .planning/REQUIREMENTS.md] | Use the existing milestone archive trio plus rolling file updates, but add an explicit readiness verdict and “outside feedback next?” decision to the close artifacts. [VERIFIED: .planning/milestones/v1.16-MILESTONE-AUDIT.md] [VERIFIED: .planning/milestones/v1.16-ROADMAP.md] [VERIFIED: .planning/milestone-candidates.md] |
</phase_requirements>

## Summary

Phases 68 and 69 already established the three big v1.17 pillars: one canonical Phoenix example proof, one support contract, and one semantic adopter verify command family. [VERIFIED: .planning/phases/68-example-proof-and-support-contract/68-RESEARCH.md] [VERIFIED: .planning/phases/69-adopter-verify-spine/69-RESEARCH.md] Phase 70 should therefore stay narrow: remove the remaining friction in how adopters find and interpret those surfaces, then close the milestone with an explicit readiness verdict instead of continuing polish by default. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md]

The highest-leverage papercuts still visible in the repo are not missing features. They are boundary and wayfinding issues in shipped surfaces: the runnable example is referenced from public docs even though `examples/` is not shipped in the Hex package, the support contract still makes readers infer concrete Ecto/Phoenix expectations from `mix.exs` files, and contributor verification guidance still surfaces older specialist tasks before the new canonical adopter path. [VERIFIED: mix.exs] [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md] [VERIFIED: guides/golden-path.md] [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: examples/phoenix_meilisearch/mix.exs]

**Primary recommendation:** Plan exactly three papercuts: clarify the repo-vs-package boundary for the Phoenix example, add explicit Ecto/Phoenix expectation wording to the support contract, and reorder maintainer verification guidance so `mix verify.adopter` is unmistakably the default integration-confidence entrypoint. [VERIFIED: mix.exs] [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md] [VERIFIED: guides/golden-path.md] [VERIFIED: guides/support-and-compatibility.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public adopter wayfinding | Browser / Client | API / Backend | The friction is experienced in README and guides, but the authoritative truth is enforced from repo docs and ExUnit contracts. [VERIFIED: README.md] [VERIFIED: guides/golden-path.md] [VERIFIED: test/scrypath/docs_contract_test.exs] |
| Maintainer verify entrypoint clarity | API / Backend | Browser / Client | `mix verify.adopter` and other `mix verify.*` tasks are backend CLI surfaces; README and CONTRIBUTING only explain which one is canonical. [VERIFIED: lib/mix/tasks/verify.adopter.ex] [VERIFIED: CONTRIBUTING.md] |
| Support-contract specificity | Browser / Client | API / Backend | The support guide is the public contract, but the defended version facts come from the library and example `mix.exs` files plus CI pins. [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: mix.exs] [VERIFIED: examples/phoenix_meilisearch/mix.exs] [VERIFIED: .github/workflows/ci.yml] |
| Milestone readiness closeout | API / Backend | Browser / Client | The decision is recorded in planning artifacts, then surfaced as the project’s next-step truth. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/STATE.md] |

## Phase Boundary

- In scope: docs/example/verify/planning changes that reduce adopter confusion without changing Scrypath’s public indexing or search API. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- Out of scope: new ranking/indexing features, backend expansion, broader CI breadth, heavy E2E, or retirement of old phase verify tasks beyond what Phase 70 needs for wayfinding. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]
- Success shape: at most three papercuts, each pinned by a regression/doc/example contract, plus a milestone close that explicitly answers whether more outside integration feedback should now displace further in-repo polish. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/PROJECT.md]

## Findings

### Finding 1: The Phoenix example is treated as canonical public proof, but the Hex package does not ship `examples/`

- Public docs repeatedly route readers to `examples/phoenix_meilisearch/README.md` as the canonical runnable proof. [VERIFIED: README.md] [VERIFIED: guides/golden-path.md] [VERIFIED: guides/support-and-compatibility.md]
- The Hex package file list excludes `examples/`, so adopters consuming the package or HexDocs cannot expect that directory to exist locally. [VERIFIED: mix.exs]
- `guides/golden-path.md` still tells readers to `cd path/to/examples/phoenix_meilisearch`, which is placeholder wording rather than a concrete repo-or-GitHub instruction. [VERIFIED: guides/golden-path.md]
- This is a real adopter-friction edge because the milestone intentionally made the example the single reference integration. [VERIFIED: .planning/PROJECT.md]

### Finding 2: The support guide is canonical, but concrete Ecto/Phoenix expectations still require inference from code

- `guides/support-and-compatibility.md` calls itself the single public support contract and names Elixir, OTP, Meilisearch, and sync-mode posture. [VERIFIED: guides/support-and-compatibility.md]
- The same guide describes “Ecto-first and Phoenix-friendly” adoption posture, but it does not state any explicit Ecto or Phoenix version expectations. [VERIFIED: guides/support-and-compatibility.md]
- The current defended version anchors exist in code: root `mix.exs` pins `{:ecto, "~> 3.13"}`, while the example app pins `{:phoenix, "~> 1.8.5"}`, `{:phoenix_ecto, "~> 4.5"}`, and `{:ecto_sql, "~> 3.13"}`. [VERIFIED: mix.exs] [VERIFIED: examples/phoenix_meilisearch/mix.exs]
- INTG-03 already framed the support contract as covering Ecto/Phoenix-shaped expectations, so this is residual clarity debt rather than new product work. [VERIFIED: .planning/REQUIREMENTS.md]

### Finding 3: The canonical adopter verify path exists, but contributor wayfinding still leads readers through older specialist gates first

- README now surfaces `mix verify.adopter` and `mix verify.adopter --live` as the maintainer-facing adopter verification family. [VERIFIED: README.md]
- CONTRIBUTING’s Verification section still introduces `mix verify.phase5` and its skip path before the adopter verify family. [VERIFIED: CONTRIBUTING.md]
- README also still contains a dedicated `mix verify.meilisearch_smoke` section later in the document. [VERIFIED: README.md]
- That means the repo has the semantic entrypoint Phase 69 wanted, but the surrounding wayfinding still asks maintainers to distinguish among old phase gates, smoke tasks, and the new adopter flow. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: CONTRIBUTING.md] [VERIFIED: README.md]

## Recommended Scope

### Plan now

1. **Papercut A: clarify example availability and repo boundary**. Add explicit wording anywhere public docs route to the Phoenix example that it is a repo/GitHub proof surface, not part of the Hex package payload, and replace placeholder/example-relative wording with a concrete repo path or GitHub source link. [VERIFIED: mix.exs] [VERIFIED: guides/golden-path.md] [VERIFIED: README.md]
2. **Papercut B: tighten the support contract with explicit Ecto/Phoenix expectations**. Keep the claims narrow and posture-shaped, but state the currently defended Ecto and Phoenix anchors so adopters do not need to inspect `mix.exs` files. [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: mix.exs] [VERIFIED: examples/phoenix_meilisearch/mix.exs]
3. **Papercut C: make `mix verify.adopter` the obvious default maintainer path**. Reorder README/CONTRIBUTING verification guidance so specialized legacy or smoke tasks are clearly secondary to the adoption-confidence loop. [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md] [VERIFIED: lib/mix/tasks/verify.adopter.ex]

### Defer

- Do not add new live CI breadth, browser E2E, or OPSUI coupling; the milestone requirement explicitly keeps heavy verification breadth deferred unless a proven gap appears. [VERIFIED: .planning/REQUIREMENTS.md]
- Do not retire or rename old `mix verify.phase*` tasks wholesale; Phase 69 already deferred broad cleanup there, and it is not necessary to close the remaining wayfinding debt. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]
- Do not improve the live task into a service provisioner or readiness manager; that would violate the orchestration-only boundary established in Phase 69. [VERIFIED: lib/mix/tasks/verify.adopter.ex] [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]

## Candidate Papercuts

| Rank | Candidate | Repo Evidence | Recommend | Why |
|------|-----------|---------------|-----------|-----|
| 1 | Example repo/package boundary is unclear | Canonical example references in README/golden-path/support guide; `mix.exs` package excludes `examples/`; golden path uses placeholder `path/to/examples/...`. [VERIFIED: README.md] [VERIFIED: guides/golden-path.md] [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: mix.exs] | **Now** | Highest leverage because the example is the milestone’s primary real-app proof, yet current wording can mislead Hex/HexDocs readers about where it actually lives. [VERIFIED: .planning/PROJECT.md] |
| 2 | Support contract lacks explicit Ecto/Phoenix anchors | Support guide claims canonical status but only posture-level wording; concrete pins live in root/example `mix.exs`. [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: mix.exs] [VERIFIED: examples/phoenix_meilisearch/mix.exs] | **Now** | Adopters evaluating fit still need code spelunking for version expectations, which weakens the support-contract promise. [VERIFIED: .planning/REQUIREMENTS.md] |
| 3 | Verify wayfinding still over-surfaces specialist tasks | README advertises adopter verify but also `mix verify.meilisearch_smoke`; CONTRIBUTING leads with `mix verify.phase5` before `mix verify.adopter`. [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md] | **Now** | This is the cleanest remaining maintainer-friction issue after Phase 69 and can be fixed with wording/order plus doc contracts only. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] |
| 4 | `mix verify.adopter --live` help does not point directly to the example runbook | Task help points to `CONTRIBUTING.md`, while the env table and local proof path live in the example README. [VERIFIED: lib/mix/tasks/verify.adopter.ex] [VERIFIED: examples/phoenix_meilisearch/README.md] | Defer | Real but lower leverage than the three above; the docs already contain the answer, and a direct pointer can be folded into Papercut C only if it remains small. [VERIFIED: CONTRIBUTING.md] |
| 5 | CI proof path block in example README duplicates command shape | The CI section shows `mix verify.adopter --live` and then the raw `cd ... && mix deps.get && mix test` path. [VERIFIED: examples/phoenix_meilisearch/README.md] | Defer | The paragraph below already explains the relationship, so this is a polish issue, not a high-leverage blocker. [VERIFIED: examples/phoenix_meilisearch/README.md] |

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| ExUnit docs/task contract tests | Elixir stdlib in current repo runtime. [VERIFIED: mix.exs] | Pin README, guide, verify-task, and CI wording against drift. [VERIFIED: test/scrypath/docs_contract_test.exs] | The repo already uses bounded contract tests for maintainer truth rather than snapshot-heavy prose freezing. [VERIFIED: test/scrypath/docs_contract_test.exs] |
| Mix task help + semantic verify entrypoints | `mix verify.adopter` on current checkout. [VERIFIED: lib/mix/tasks/verify.adopter.ex] [VERIFIED: `mix help verify.adopter`] | Keep the maintainer-facing entrypoint discoverable and explicit. [VERIFIED: lib/mix/tasks/verify.adopter.ex] | Phase 69 intentionally established one semantic root command family instead of another phase-numbered task. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] |
| Rolling planning artifacts + milestone archive trio | Current planning scheme in `.planning/` plus `milestones/v1.16-*` precedent. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/milestones/v1.16-ROADMAP.md] [VERIFIED: .planning/milestones/v1.16-REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.16-MILESTONE-AUDIT.md] | Record the readiness verdict without inventing a new closeout system. [VERIFIED: .planning/milestones/v1.16-MILESTONE-AUDIT.md] | The repo already closes milestones through rolling-file updates plus a frozen archive trio. [VERIFIED: .planning/milestones/v1.16-ROADMAP.md] |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| `examples/phoenix_meilisearch/README.md` | Current repo state. [VERIFIED: examples/phoenix_meilisearch/README.md] | Canonical live proof and env/run-order contract. [VERIFIED: examples/phoenix_meilisearch/README.md] | Use as the single runnable proof reference; do not create a second example or duplicate full env tables elsewhere. [VERIFIED: .planning/PROJECT.md] [VERIFIED: examples/phoenix_meilisearch/README.md] |
| `guides/support-and-compatibility.md` | Current repo state. [VERIFIED: guides/support-and-compatibility.md] | Canonical support and compatibility contract. [VERIFIED: guides/support-and-compatibility.md] | Use for explicit support posture rather than widening version claims in README or CONTRIBUTING. [VERIFIED: CONTRIBUTING.md] |
| `.planning/milestone-candidates.md` | Current repo state. [VERIFIED: .planning/milestone-candidates.md] | Carries the “outside feedback before more breadth” recommendation into future milestone selection. [VERIFIED: .planning/milestone-candidates.md] | Update only at milestone close, after the readiness verdict is known. [VERIFIED: .planning/milestone-candidates.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Three bounded doc/verify/planning papercuts | Broader “final polish” sweep | Rejected because INTG-05 hard-caps the work and v1.17 is explicitly not another breadth milestone. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/PROJECT.md] |
| Reusing the milestone archive trio | Creating a new standalone readiness artifact family | Rejected because the repo already has a working archive pattern; the missing piece is an explicit readiness verdict inside it. [VERIFIED: .planning/milestones/v1.16-MILESTONE-AUDIT.md] |
| Reordering maintainer docs around `mix verify.adopter` | Retiring specialist verify tasks | Rejected because broad task retirement was already deferred and is unnecessary to solve the current confusion. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] |

**Installation:** No new Hex dependencies should be introduced in this phase. [VERIFIED: mix.exs]  
**Version verification:** The relevant pinned surfaces are already in-repo: Elixir `~> 1.17`, Ecto `~> 3.13`, example Phoenix `~> 1.8.5`, `phoenix_ecto ~> 4.5`, and Meilisearch `v1.15` in CI/example docs. [VERIFIED: mix.exs] [VERIFIED: examples/phoenix_meilisearch/mix.exs] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: guides/support-and-compatibility.md]

## Architecture Patterns

### System Architecture Diagram

```text
Adopter / maintainer reads README or HexDocs
        |
        v
Canonical wayfinding layer
README -> golden path -> support guide -> example README
        |                    |                 |
        |                    |                 +--> live proof commands / env
        |                    +--> defended version/support claims
        |
        +--> mix verify.adopter / --live
                           |
                           v
                  docs/task/CI contract tests
                           |
                           v
                rolling planning + milestone archive closeout
                           |
                           v
            explicit readiness verdict: outside feedback next?
```

This phase should adjust only the wayfinding, support-contract wording, and milestone closeout around the already-shipped integration surfaces. [VERIFIED: .planning/PROJECT.md] [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md]

### Recommended Project Structure

```text
README.md                               # Top-level wayfinding and maintainer pointers
guides/golden-path.md                   # First-hour path and example handoff
guides/support-and-compatibility.md     # Canonical support contract
examples/phoenix_meilisearch/README.md  # Canonical live proof runbook
lib/mix/tasks/verify.adopter.ex         # Semantic maintainer verify entrypoint
test/scrypath/docs_contract_test.exs    # Drift contracts for docs/CI/task wording
.planning/{PROJECT,ROADMAP,REQUIREMENTS,STATE}.md
.planning/milestones/v1.17-*.md         # Milestone close snapshot and readiness verdict
```

### Pattern 1: Fix friction by tightening authority boundaries, not by adding new surfaces

**What:** Improve wording and contracts around the existing canonical surfaces rather than introducing new commands, guides, or examples. [VERIFIED: .planning/PROJECT.md]  
**When to use:** When the milestone is explicitly about integration confidence and remaining friction is interpretive rather than functional. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**
```elixir
# Source: test/scrypath/docs_contract_test.exs
assert String.contains?(readme, "mix verify.adopter")
assert String.contains?(support_guide, "single public support contract")
refute String.contains?(published_package_files, "examples/")
```

### Pattern 2: Use doc contracts for user-facing truth, not freeform prose promises

**What:** Every papercut fix should land with a bounded assertion that fails when the confusion reappears. [VERIFIED: .planning/REQUIREMENTS.md]  
**When to use:** For doc wording, example path discoverability, verify ordering, or support-claim drift. [VERIFIED: test/scrypath/docs_contract_test.exs]

**Example:**
```elixir
# Source: existing docs contract style
assert ordered?(contributing, "mix verify.adopter", "mix verify.phase5")
assert String.contains?(support_guide, "Phoenix")
assert String.contains?(support_guide, "Ecto")
```

### Anti-Patterns to Avoid

- **Breadth disguised as papercuts:** Do not add new runtime APIs, new adapters, or new search features under the label of “readiness.” [VERIFIED: .planning/REQUIREMENTS.md]
- **New authority files:** Do not create a second support guide, second example, or second readiness system when the repo already has canonical surfaces and milestone archives. [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: examples/phoenix_meilisearch/README.md] [VERIFIED: .planning/milestones/v1.16-ROADMAP.md]
- **Unpinned polish:** Do not accept doc cleanup without a regression/doc/example assertion, because INTG-05 explicitly requires recurrence protection. [VERIFIED: .planning/REQUIREMENTS.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| New milestone closeout system | A bespoke readiness framework | Existing milestone archive trio plus explicit readiness subsection in the audit | The repo already has a stable closeout pattern; only the readiness verdict is missing. [VERIFIED: .planning/milestones/v1.16-MILESTONE-AUDIT.md] |
| New docs enforcement mechanism | Custom linter or snapshot suite | `test/scrypath/docs_contract_test.exs` and small focused Mix-task tests | Existing bounded contract tests already protect the relevant drift surfaces. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: test/mix/tasks/verify_adopter_test.exs] |
| New example distribution path | Additional packaged examples | Explicit repo/GitHub boundary language | The current package intentionally excludes `examples/`; changing distribution is larger than the papercut itself. [VERIFIED: mix.exs] |

**Key insight:** The remaining issues are authority and discoverability problems, so the correct implementation tool is tighter contracts around existing surfaces, not new product surface area. [VERIFIED: .planning/PROJECT.md] [VERIFIED: test/scrypath/docs_contract_test.exs]

## Common Pitfalls

### Pitfall 1: Fixing “example discoverability” by widening package contents

**What goes wrong:** The planner may treat example confusion as a packaging problem and try to ship `examples/` in the Hex tarball. [VERIFIED: mix.exs]  
**Why it happens:** The docs point to the example heavily, so the missing boundary note can look like a distribution bug. [VERIFIED: README.md] [VERIFIED: guides/golden-path.md]  
**How to avoid:** Clarify the repo/GitHub boundary in docs and add contract coverage; do not change the package file list in this phase. [VERIFIED: mix.exs] [VERIFIED: .planning/REQUIREMENTS.md]  
**Warning signs:** A proposed plan edits `package.files` or adds new example packaging tasks. [VERIFIED: mix.exs]

### Pitfall 2: Turning support clarity into a broad compatibility promise

**What goes wrong:** The support guide can accidentally broaden from “tested / defended expectations” into “full version matrix support.” [VERIFIED: guides/support-and-compatibility.md]  
**Why it happens:** The repo has concrete Phoenix/Ecto pins in code, and adding them incautiously can sound more expansive than the current posture. [VERIFIED: mix.exs] [VERIFIED: examples/phoenix_meilisearch/mix.exs]  
**How to avoid:** Phrase the additions as current tested anchors or example-backed expectations, consistent with the guide’s existing narrow contract language. [VERIFIED: guides/support-and-compatibility.md]  
**Warning signs:** New wording starts claiming wide Phoenix/Ecto compatibility beyond the current example and CI evidence. [VERIFIED: .github/workflows/ci.yml]

### Pitfall 3: “Canonical verify path” drift caused by additive wording only

**What goes wrong:** `mix verify.adopter` stays technically canonical, but contributor docs still teach specialist tasks first. [VERIFIED: CONTRIBUTING.md]  
**Why it happens:** Older verify tasks remain valuable, so docs accumulate rather than prioritize. [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md]  
**How to avoid:** Reorder by default path first, specialist tasks second, and pin the ordering in docs contracts. [VERIFIED: test/scrypath/docs_contract_test.exs]  
**Warning signs:** README or CONTRIBUTING opens the Verification section with `mix verify.phase5` or `mix verify.meilisearch_smoke` ahead of `mix verify.adopter`. [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md]

## Code Examples

Verified patterns from current repo sources:

### Canonical fast/live maintainer split
```elixir
# Source: lib/mix/tasks/verify.adopter.ex
{opts, argv, invalid} =
  OptionParser.parse(args, strict: [fast: :boolean, live: :boolean])

if opts[:live] do
  run_live!()
else
  run_fast!()
end
```

### Existing doc-contract enforcement style
```elixir
# Source: test/scrypath/docs_contract_test.exs
assert_contains_all(@ci_workflow, [
  "adopter-verify:",
  "mix verify.adopter",
  "phoenix-example-integration:",
  "mix verify.adopter --live"
])
```

## Readiness-Checkpoint Bookkeeping

### Required milestone-close artifacts

1. Update rolling `.planning/REQUIREMENTS.md` so `INTG-05` and `INTG-06` are checked complete and the traceability table marks Phase 70 complete. [VERIFIED: .planning/REQUIREMENTS.md]
2. Update rolling `.planning/ROADMAP.md` and `.planning/PROJECT.md` so v1.17 is no longer “in progress” and the milestone summary states it ended as a readiness checkpoint rather than a breadth milestone. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/PROJECT.md]
3. Update `.planning/STATE.md` with the readiness verdict, the papercuts actually closed, and the explicit next action: seek outside integration feedback or justify why not. [VERIFIED: .planning/STATE.md]
4. Create the standard frozen archive trio: `.planning/milestones/v1.17-ROADMAP.md`, `.planning/milestones/v1.17-REQUIREMENTS.md`, and `.planning/milestones/v1.17-MILESTONE-AUDIT.md`. [VERIFIED: .planning/milestones/v1.16-ROADMAP.md] [VERIFIED: .planning/milestones/v1.16-REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.16-MILESTONE-AUDIT.md]
5. In `v1.17-MILESTONE-AUDIT.md`, add an explicit subsection such as **Readiness verdict** with a binary answer to: “Is Scrypath ready to prioritize outside integration feedback over further in-repo polish?” [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/PROJECT.md]
6. Update `.planning/milestone-candidates.md` after the close with the checkpoint result, so future milestone selection reflects whether more breadth is still blocked by missing outside evidence. [VERIFIED: .planning/milestone-candidates.md]

### Recommended readiness verdict format

- **Verdict:** `ready_for_external_feedback` or `not_ready_for_external_feedback`. [ASSUMED]
- **Why:** 2-4 evidence bullets naming the example proof, support contract, adopter verify path, and which papercuts were closed. [VERIFIED: .planning/PROJECT.md]
- **Remaining known friction:** list deferred papercuts that did not make the top three. [VERIFIED: Candidate Papercuts section]
- **Next milestone policy:** either “do not open another polish milestone until feedback arrives” or the narrow reason that an additional internal milestone is still justified. [VERIFIED: .planning/milestone-candidates.md] [VERIFIED: .planning/PROJECT.md]

## Risks

- The biggest planning risk is scope drift from “papercuts” into generalized documentation or verification cleanup. [VERIFIED: .planning/REQUIREMENTS.md]
- The second risk is accidental widening of the support contract while trying to add Ecto/Phoenix clarity. [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: examples/phoenix_meilisearch/mix.exs]
- The closeout risk is treating v1.17 as “another shipped milestone” without recording the reassessment decision that INTG-06 explicitly requires. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/PROJECT.md]

## Canonical References

- `README.md` — top-level adopter and maintainer wayfinding. [VERIFIED: README.md]
- `guides/golden-path.md` — first-hour path and current handoff to the example. [VERIFIED: guides/golden-path.md]
- `guides/support-and-compatibility.md` — canonical support contract. [VERIFIED: guides/support-and-compatibility.md]
- `examples/phoenix_meilisearch/README.md` — canonical live proof and env/run-order contract. [VERIFIED: examples/phoenix_meilisearch/README.md]
- `lib/mix/tasks/verify.adopter.ex` — canonical maintainer verify task. [VERIFIED: lib/mix/tasks/verify.adopter.ex]
- `test/scrypath/docs_contract_test.exs` — existing drift contract surface. [VERIFIED: test/scrypath/docs_contract_test.exs]
- `.github/workflows/ci.yml` — current CI job mapping for fast/live adopter verification. [VERIFIED: .github/workflows/ci.yml]
- `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/milestone-candidates.md` — rolling truth and checkpoint bookkeeping targets. [VERIFIED: listed files]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase-numbered or specialist verification discovery | Semantic root adopter verify family plus specialist tasks beneath it. [VERIFIED: lib/mix/tasks/verify.adopter.ex] [VERIFIED: CONTRIBUTING.md] | Phase 69. [VERIFIED: .planning/ROADMAP.md] | Remaining work is wayfinding polish, not a new verification system. [VERIFIED: CONTRIBUTING.md] |
| Support truth inferred across multiple files | One canonical support guide plus example/CI proof. [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: examples/phoenix_meilisearch/README.md] | Phase 68. [VERIFIED: .planning/ROADMAP.md] | Remaining work is specificity at the contract edges. [VERIFIED: guides/support-and-compatibility.md] |

**Deprecated/outdated:**
- Treating older `mix verify.phase*` tasks as the default path for adopter-confidence verification is outdated for v1.17’s maintainer story, even though those tasks still exist for specialist coverage. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: CONTRIBUTING.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The readiness verdict labels `ready_for_external_feedback` / `not_ready_for_external_feedback` are a good fit for the archive wording. [ASSUMED] | Readiness-Checkpoint Bookkeeping | Low; the archive can use different exact labels while keeping the same binary decision. |

## Open Questions (RESOLVED)

1. **Should the example boundary be explained with repo-relative wording only, or with explicit GitHub links from public docs?**
   - Resolution: keep the plan neutral on exact link format, but require the shipped docs to make the repo/package boundary explicit using repository-path wording at minimum. GitHub links are optional, not required.
   - Why: `mix.exs` excludes `examples/`, while README and the guides already route readers into the repo example surface. The must-have is boundary clarity plus a docs contract, not a specific URL scheme. [VERIFIED: mix.exs] [VERIFIED: README.md] [VERIFIED: guides/golden-path.md]

2. **How explicit should the Ecto/Phoenix support wording be?**
   - Resolution: use “current defended expectation” language anchored to the root and example `mix.exs` files, not a broad “fully supported matrix” framing.
   - Why: the current evidence is concrete but narrow: Ecto `~> 3.13` in the library and Phoenix `~> 1.8.5`, `phoenix_ecto ~> 4.5`, `ecto_sql ~> 3.13` in the example app. That supports explicit anchors without overpromising breadth beyond current proof. [VERIFIED: mix.exs] [VERIFIED: examples/phoenix_meilisearch/mix.exs] [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: .github/workflows/ci.yml]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix. [VERIFIED: mix.exs] |
| Config file | none; standard Mix/ExUnit layout. [VERIFIED: mix.exs] |
| Quick run command | `mix test test/scrypath/docs_contract_test.exs test/mix/tasks/verify_adopter_test.exs` [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: test/mix/tasks/verify_adopter_test.exs] |
| Full suite command | `mix test --exclude integration` [VERIFIED: CONTRIBUTING.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INTG-05 | Closed papercuts stay bounded and do not recur in docs/verify/example truth. [VERIFIED: .planning/REQUIREMENTS.md] | docs contract / focused task test | `mix test test/scrypath/docs_contract_test.exs test/mix/tasks/verify_adopter_test.exs` [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: test/mix/tasks/verify_adopter_test.exs] | ✅ |
| INTG-06 | Milestone close artifacts explicitly record readiness-checkpoint truth. [VERIFIED: .planning/REQUIREMENTS.md] | manual artifact review plus optional docs contract if strings are mirrored in rolling docs. [VERIFIED: .planning/milestones/v1.16-MILESTONE-AUDIT.md] | `mix test test/scrypath/docs_contract_test.exs` for any mirrored doc strings; archive file review remains manual. [VERIFIED: test/scrypath/docs_contract_test.exs] | ✅ / manual |

### Sampling Rate

- **Per task commit:** `mix test test/scrypath/docs_contract_test.exs`
- **Per wave merge:** `mix test test/scrypath/docs_contract_test.exs test/mix/tasks/verify_adopter_test.exs`
- **Phase gate:** `mix test --exclude integration` before `/gsd-verify-work`

### Wave 0 Gaps

- None — the existing docs contract suite and focused adopter-task tests are sufficient for this bounded phase. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: test/mix/tasks/verify_adopter_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | None; this phase does not change auth surfaces. [VERIFIED: .planning/REQUIREMENTS.md] |
| V3 Session Management | no | None; this phase does not change session surfaces. [VERIFIED: .planning/REQUIREMENTS.md] |
| V4 Access Control | no | None; this phase is docs/verify/planning only. [VERIFIED: .planning/REQUIREMENTS.md] |
| V5 Input Validation | yes | Keep strict CLI arg/env validation on `mix verify.adopter` and avoid docs that imply silent live fallback or unsafe command ambiguity. [VERIFIED: lib/mix/tasks/verify.adopter.ex] [VERIFIED: CONTRIBUTING.md] |
| V6 Cryptography | no | None; no crypto changes are in scope. [VERIFIED: .planning/REQUIREMENTS.md] |

### Known Threat Patterns for docs/verify closeout work

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silent downgrade from live proof to fast proof | Repudiation | Preserve explicit `--live` prereq failures and docs that describe live mode as opt-in, not implicit. [VERIFIED: lib/mix/tasks/verify.adopter.ex] [VERIFIED: guides/support-and-compatibility.md] |
| Misleading support claims beyond tested posture | Tampering | Keep the support guide narrow and tie any new Ecto/Phoenix wording to current `mix.exs` and example evidence. [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: mix.exs] [VERIFIED: examples/phoenix_meilisearch/mix.exs] |

## Sources

### Primary (HIGH confidence)

- `.planning/PROJECT.md` - milestone goal, phase boundary, and reassessment intent. [VERIFIED: .planning/PROJECT.md]
- `.planning/ROADMAP.md` - Phase 70 success criteria and milestone status. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - authoritative `INTG-05` and `INTG-06` requirements. [VERIFIED: .planning/REQUIREMENTS.md]
- `README.md` - current adopter and maintainer entrypoint wording. [VERIFIED: README.md]
- `CONTRIBUTING.md` - current verification ordering and CI mapping. [VERIFIED: CONTRIBUTING.md]
- `guides/golden-path.md` - first-hour handoff to the example. [VERIFIED: guides/golden-path.md]
- `guides/support-and-compatibility.md` - canonical support contract wording. [VERIFIED: guides/support-and-compatibility.md]
- `examples/phoenix_meilisearch/README.md` - canonical live proof wording. [VERIFIED: examples/phoenix_meilisearch/README.md]
- `mix.exs` and `examples/phoenix_meilisearch/mix.exs` - package contents and current Ecto/Phoenix dependency anchors. [VERIFIED: mix.exs] [VERIFIED: examples/phoenix_meilisearch/mix.exs]
- `lib/mix/tasks/verify.adopter.ex` and `mix help verify.adopter` - current help/discovery surface. [VERIFIED: lib/mix/tasks/verify.adopter.ex] [VERIFIED: `mix help verify.adopter`]
- `test/scrypath/docs_contract_test.exs` and `test/mix/tasks/verify_adopter_test.exs` - existing contract enforcement surface. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: test/mix/tasks/verify_adopter_test.exs]
- `.github/workflows/ci.yml` - current fast/live CI job mapping. [VERIFIED: .github/workflows/ci.yml]

### Secondary (MEDIUM confidence)

- `.planning/milestone-candidates.md` - current recommendation that further breadth should wait for outside adopter evidence. [VERIFIED: .planning/milestone-candidates.md]
- `.planning/milestones/v1.16-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md` - milestone-close archive pattern to reuse. [VERIFIED: .planning/milestones/v1.16-ROADMAP.md] [VERIFIED: .planning/milestones/v1.16-REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.16-MILESTONE-AUDIT.md]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - this phase reuses existing repo docs/test/planning primitives rather than introducing new libraries. [VERIFIED: mix.exs] [VERIFIED: test/scrypath/docs_contract_test.exs]
- Architecture: HIGH - the authority boundaries and milestone-close pattern are explicit in current files. [VERIFIED: README.md] [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: .planning/milestones/v1.16-MILESTONE-AUDIT.md]
- Pitfalls: HIGH - the main failure modes are directly visible in current docs ordering, package contents, and support wording. [VERIFIED: mix.exs] [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md]

**Research date:** 2026-04-22 [VERIFIED: system date]  
**Valid until:** 2026-05-22 for repo-local planning truth unless Phase 70 lands first. [ASSUMED]
