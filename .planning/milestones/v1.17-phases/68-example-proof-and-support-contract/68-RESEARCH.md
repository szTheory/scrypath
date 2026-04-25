# Phase 68: Example proof and support contract - Research

**Researched:** 2026-04-22
**Domain:** Documentation architecture, example-proof verification, and support-contract publication for an Elixir OSS library
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Verbatim from `.planning/phases/68-example-proof-and-support-contract/68-CONTEXT.md` [VERIFIED: codebase grep]

> ## Implementation Decisions
>
> ### Canonical adopter proof shape
>
> - **D-01:** Keep the docs model **two-layered and idiomatic for Elixir OSS**:
>   - **`README.md`** stays short and adoption-oriented.
>   - **HexDocs guides** hold the longer walkthroughs and operational depth.
>   - The **example app README** becomes the canonical **real-app proof** surface.
> - **D-02:** Keep **`guides/golden-path.md`** as the **first-hour**, **`:inline`-only** path. Do **not** collapse the whole adoption story into the example app; that would over-rotate the library toward Phoenix-specific setup and weaken the current Ecto-first story.
> - **D-03:** Promote **`examples/phoenix_meilisearch/README.md`** from “optional live smoke” to the **single canonical adopter proof** for a real Phoenix + Ecto + Postgres + Meilisearch app.
> - **D-04:** The example proof must explicitly cover **all three supported sync modes** in one coherent runbook:
>   - **`:inline`** as the simplest first live success
>   - **`:manual`** as the explicit operator-controlled path
>   - **`:oban`** as the queue-backed production-shaped path
> - **D-05:** The example should remain **single-example, production-shaped, and minimal**. Do **not** add a second example app or an examples zoo in Phase 68. One strong proof is better than several half-maintained samples.
> - **D-06:** The example README should be written as a **proof source**, not just a Docker note:
>   - what the example proves
>   - which sync stories it covers
>   - what CI runs
>   - what local smoke proves
>   - where to go next for conceptual or operational depth
> - **D-07:** The example app itself, not just prose, must back the promise. If docs claim `:inline`, `:manual`, and `:oban` support in the canonical proof, the example must exercise or directly prove each of those paths through tests, scripted smoke, or a tightly bounded combination of both.
>
> ### Support and compatibility contract
>
> - **D-08:** Publish **one dedicated public guide-level support contract** rather than burying support truth in README, CONTRIBUTING, or operator docs.
> - **D-09:** The support contract should be a new guide with a boring explicit title, e.g. **`guides/support-and-compatibility.md`** or equivalent. The exact filename is planner discretion, but the concept is locked: **one public canonical source**.
> - **D-10:** The support contract must state the support/tested truth Scrypath can actually defend:
>   - Elixir support floor and tested range
>   - OTP support floor and tested range
>   - Phoenix/Ecto-shaped adoption posture
>   - the pinned Meilisearch minor used by CI and the example
>   - supported write-path modes: **`:inline`**, **`:manual`**, **`:oban`**
>   - explicit non-goals / non-promises where relevant
> - **D-11:** Keep the support contract **narrower than internal architecture**. Do not promise public multi-backend parity, broader framework guarantees, or runtime combinations not backed by CI, example proof, or maintainer intent.
> - **D-12:** README should include only a **short support summary** and link to the support contract. README is not the authoritative home for the full matrix.
> - **D-13:** CONTRIBUTING may still mention CI jobs and verify commands, but it should **point to** the support contract for compatibility truth instead of being the place where adopters discover supported versions by accident.
> - **D-14:** `guides/meilisearch-operations.md` should stop being an implicit support matrix. It may reference the support contract, but should stay focused on operational posture.
>
> ### Wayfinding and docs architecture
>
> - **D-15:** The onboarding path should be **linear and explicit**:
>   - **README** -> **`guides/golden-path.md`** for first-hour success
>   - **README / golden path** -> **`examples/phoenix_meilisearch/README.md`** for the canonical real-app proof
>   - **README / example / CONTRIBUTING** -> **support contract** for compatibility truth
>   - **support contract / example** -> operations and sync guides for deeper semantics
> - **D-16:** README should remain **short, copy-pasteable, and product-shaped**, more like Phoenix / Ecto / Oban than a giant all-in-one manual. Scrypath has too much operational surface area for a README-heavy strategy to age well.
> - **D-17:** The example app README should be the source of truth for:
>   - env vars and local stack details
>   - startup order
>   - CI-shaped consumer test path
>   - mode-specific proof path in the example
> - **D-18:** `CONTRIBUTING.md` should stay maintainer/contributor shaped:
>   - exact verify commands
>   - CI job mapping
>   - note that docs and example changes must stay aligned
>   It should not become the adopter-facing support matrix.
> - **D-19:** Keep the current project posture of **operational honesty** visible in the path. The user should encounter early, not late, that:
>   - accepted sync work is not the same as search visibility
>   - delete semantics deserve explicit care
>   - backfill and reindex are first-class workflows
>
> ### Docs-contract strictness
>
> - **D-20:** Stay with the repo’s existing **bounded contract** philosophy. Do **not** snapshot large prose blocks or freeze narrative wording broadly.
> - **D-21:** Extend **`test/scrypath/docs_contract_test.exs`** to lock the **Phase 68 drift surface only**:
>   - canonical adopter-proof link target
>   - canonical support-contract link target
>   - canonical “start here” link order
>   - env vars used by the example proof
>   - startup order / command order
>   - explicit mode coverage and wording shape where needed
> - **D-22:** Contracts should protect **facts and navigation**, not every sentence:
>   - source-of-truth docs
>   - command shapes
>   - env var names
>   - CI/example ordering
>   - where maintainers/adopters are told to start
> - **D-23:** Avoid introducing a manifest-driven contract system or another meta-layer in this phase. That is over-engineered for the current repo and would distract from shipping the actual support and proof surfaces.
>
> ### Example proof depth and testing philosophy
>
> - **D-24:** The canonical example must prove the public support story with **real consumer-shaped behavior**, not just snippets. The example already proves **`:inline`** and **`:oban`** against real Postgres + Meilisearch; Phase 68 should close the **`:manual`** gap instead of reworking the entire example.
> - **D-25:** Example verification should remain **boring and trustworthy**:
>   - CI-driven example proof path
>   - local smoke path for humans
>   - bounded doc contracts pinning the docs to those paths
> - **D-26:** Do not invent a heavy browser or full-system golden environment for this phase. Keep the proof near ExUnit, Mix, and the existing example smoke shape.
> - **D-27:** The example should answer “does Scrypath land cleanly in a Phoenix app?” without implying Phoenix is the only intended integration shape. The real-app proof is Phoenix-shaped; the library remains Ecto-first.
>
> ### Ecosystem and precedent lessons to adopt
>
> - **D-28:** Borrow the best parts of strong precedents:
>   - **Searchkick**: first-mile DX and obvious happy path
>   - **Laravel Scout**: clear support/engine contract and linear docs wayfinding
>   - **meilisearch-rails**: explicit compatibility near the top and a runnable app/playground shape
>   - **Phoenix / Ecto / Oban**: short README, deeper guides, clear contributor separation
> - **D-29:** Avoid the most common footguns seen in adjacent libraries:
>   - hiding write-path semantics behind “magic”
>   - letting async delete semantics stay implicit
>   - making compatibility claims broader than CI or docs can prove
>   - letting the example drift away from the docs
>   - turning the README into the entire manual

### Claude's Discretion

Verbatim from `.planning/phases/68-example-proof-and-support-contract/68-CONTEXT.md` [VERIFIED: codebase grep]

> ### the agent's Discretion
>
> - Exact section ordering in README, the support guide, and the example README, provided the canonical path above remains obvious.
> - Whether the example proves `:manual` through a dedicated smoke test, a precise README runbook plus targeted test, or a bounded hybrid, provided the claim is real and contract-testable.
> - Exact test names and doc-contract assertion wording, provided the bounded Phase 68 drift surface is covered.

### Deferred Ideas (OUT OF SCOPE)

Verbatim from `.planning/phases/68-example-proof-and-support-contract/68-CONTEXT.md` [VERIFIED: codebase grep]

> ## Deferred Ideas
>
> - Additional example apps or an examples catalog — one canonical example is the right move for this phase.
> - A manifest-driven docs contract system or generalized contract registry.
> - Heavy browser/E2E infrastructure for example verification beyond the current bounded ExUnit + smoke approach.
> - Any widening of the public feature surface, backend scope, or adapter promise.
> - Rewriting the onboarding architecture around Phoenix-only assumptions; Scrypath remains Ecto-first even if the canonical proof app is Phoenix-shaped.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INTG-01 | Phoenix example becomes the canonical adopter proof for `:inline`, `:manual`, and `:oban` in one real-app runbook and test surface. [VERIFIED: codebase grep] | Use the existing example app as the only proof surface, add one missing `:manual` proof path, and keep proof near `mix test` plus the local `./scripts/smoke.sh` harness. [VERIFIED: codebase grep] |
| INTG-03 | One canonical support / compatibility document states supported or tested expectations for Elixir, OTP, Ecto/Phoenix-shaped adoption, and the pinned Meilisearch minor used by CI and examples. [VERIFIED: codebase grep] | Publish one guide-level support contract and move README / CONTRIBUTING / example links to that authority instead of leaving version truth distributed across multiple files. [VERIFIED: codebase grep] |
| INTG-04 | README, guides, CONTRIBUTING, and the example README point to the same canonical support and adoption-proof sources, with doc-contract coverage for env vars, run order, and start-here wayfinding. [VERIFIED: codebase grep] | Extend `test/scrypath/docs_contract_test.exs` with bounded assertions for link targets, startup order, env names, and mode coverage instead of snapshotting prose. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 68 should be planned as a documentation-authority and proof-surface consolidation phase, not as a feature phase. The repository already has the right building blocks: a short README that points to guides, a runnable Phoenix example with live `:inline` and `:oban` coverage, ExDoc-published extras in `mix.exs`, and an existing bounded docs-contract suite in `test/scrypath/docs_contract_test.exs`. The missing pieces are one canonical support guide and one real `:manual` proof path in the example. [VERIFIED: codebase grep]

The planner should keep the implementation narrow: promote `examples/phoenix_meilisearch/README.md` into the canonical real-app proof, publish a new support guide under `guides/`, wire that guide into ExDoc extras and guide wayfinding, and extend the current contract suite to pin facts and navigation only. ExDoc already supports grouping and publishing extra Markdown pages, so the support guide belongs in the same published-doc pipeline rather than in a new docs system. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

The strongest proof shape for this repo is live ExUnit plus bounded docs contracts. The example already uses `@moduletag :integration` and environment-gated inclusion, which matches ExUnit’s tag/filter model, and it already runs Oban deterministically in tests with `testing: :inline`, which is consistent with Oban’s documented testing modes. That makes Phase 68 a gap-closing phase, not a tooling-invention phase. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] [CITED: https://hexdocs.pm/oban/testing.html]

**Primary recommendation:** Add one published support guide, one `:manual` example proof, and one Phase-68 extension to the existing docs-contract suite; do not add new examples, new meta-config, or browser/E2E infrastructure. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical start-here wayfinding across README, guides, CONTRIBUTING, and example README | Published docs / repo content | ExUnit contracts | These are authored Markdown surfaces, while the bounded tests enforce that the navigation stays aligned. [VERIFIED: codebase grep] |
| Support / compatibility contract | Published docs / repo content | CI workflow truth | The contract is a guide, but its facts must be limited to what `.github/workflows/ci.yml`, `mix.exs`, and the example actually defend. [VERIFIED: codebase grep] |
| Example proof for `:inline`, `:manual`, and `:oban` | Phoenix example app tests | Example README | The proof must come from real behavior in `examples/phoenix_meilisearch/test/smoke/*.exs`, while the example README explains how humans run the same path. [VERIFIED: codebase grep] |
| Startup order, env names, and CI/local command parity | Example README + smoke script | Docs contracts | The authoritative details already live in `examples/phoenix_meilisearch/README.md` and `scripts/smoke.sh`; Phase 68 should make those facts contract-testable. [VERIFIED: codebase grep] |
| Published-guide discoverability | `mix.exs` ExDoc extras/groups | Guides overview | A new support guide is not really public unless it is added to `extras:` and linked from `guides/overview.md`. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Elixir | `~> 1.17` library floor; CI tests `1.17.3` and `1.19.0`; local runtime `1.19.5` | Base language/runtime contract for docs and support truth | These are the versions already declared and exercised by the repo, so the support contract should report them instead of inferring broader support. [VERIFIED: codebase grep] [VERIFIED: local runtime] |
| OTP | CI tests `26.2.5` and `28.1`; local runtime `28` | Runtime compatibility contract | CI already expresses the tested OTP range, and the project stack guidance says support floor `26` through tested `28`. [VERIFIED: codebase grep] [VERIFIED: local runtime] |
| ExDoc extras + groups | Locked at `0.40.1` in `mix.lock` | Publish README/guides/maintainer docs as one coherent public docs site | ExDoc extras are already the shipping mechanism for docs, and ExDoc explicitly supports extra pages and `groups_for_extras`. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| ExUnit docs-contract suite | Built-in ExUnit; repo uses `test/scrypath/docs_contract_test.exs` | Enforce bounded documentation facts and wayfinding | The repo already uses this as the contract seam, and ExUnit tags/filters cleanly support fast-vs-integration splits. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] |
| Phoenix example app | Phoenix `1.8.5`, Ecto SQL `3.13.5`, Oban `2.21.1`, Bandit `1.10.4` | Canonical adopter proof app | These versions are already locked in the example and are the real consumer-shaped proof surface for this phase. [VERIFIED: codebase grep] |
| Example runtime stack | Postgres `16`, Meilisearch `v1.15` | Live example and CI-backed integration target | The example `compose.yaml` and `phoenix-example-integration` CI job both pin these service versions today. [VERIFIED: codebase grep] |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| `./scripts/smoke.sh` in the example | repo script | Local DX harness for Compose + env defaults + `mix test` | Use for human/local confidence runs; do not describe it as the GitHub Actions driver because CI runs `mix deps.get` then `mix test` directly. [VERIFIED: codebase grep] |
| Oban testing mode | `2.21.1` docs and lockfile | Deterministic queue-backed proof in the example | Keep `config :scrypath_demo, Oban, testing: :inline` for the example’s `:oban` smoke path because Oban documents `:inline` as the simple testing mode. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/testing.html] |
| Docker Compose | local `v5.1.1` | Start Postgres + Meilisearch locally with the same port shape the example docs describe | Use for local proof and contributor setup when live services are needed. [VERIFIED: local runtime] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend existing `docs_contract_test.exs` | New manifest-driven docs contract system | Rejected because the phase context explicitly forbids a new meta-layer and the repo already has the bounded-contract pattern in place. [VERIFIED: codebase grep] |
| One canonical Phoenix example | Multiple example apps | Rejected because the context locks this phase to one strong canonical proof instead of an examples zoo. [VERIFIED: codebase grep] |
| ExUnit smoke + docs contracts | Browser/E2E system | Rejected because the phase context keeps proof near Mix, ExUnit, and the current smoke shape. [VERIFIED: codebase grep] |

**Installation / dependency posture:**

```bash
mix deps.get
cd examples/phoenix_meilisearch && mix deps.get
```

The phase should use the dependencies already locked in the repo and example rather than introducing new tooling. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
README.md
  -> guides/golden-path.md
  -> examples/phoenix_meilisearch/README.md
  -> guides/support-and-compatibility.md

guides/golden-path.md
  -> first-hour inline-only path
  -> examples/phoenix_meilisearch/README.md for real-app proof

examples/phoenix_meilisearch/README.md
  -> env vars + startup order + CI/local command truth
  -> smoke tests for :inline / :manual / :oban

guides/support-and-compatibility.md
  -> Elixir/OTP/Phoenix-Ecto/Meilisearch/write-mode support truth
  -> links to sync + operations guides for semantics

test/scrypath/docs_contract_test.exs
  -> asserts README/example/support-guide/contributing/guide wayfinding
  -> asserts env names + startup order + canonical links do not drift

.github/workflows/ci.yml
  -> provides defended service/runtime matrix
  -> validates example app with Postgres + Meilisearch
```

This phase is a docs-and-proof flow where Markdown surfaces carry authority and tests police drift. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
guides/
├── overview.md                   # published guide index
├── golden-path.md                # first-hour inline-only onboarding
├── support-and-compatibility.md  # new canonical support contract
├── sync-modes-and-visibility.md  # semantics authority
└── meilisearch-operations.md     # operational posture, not support matrix

examples/phoenix_meilisearch/
├── README.md                     # canonical real-app proof
├── scripts/smoke.sh              # local smoke harness
├── config/{dev,test}.exs         # env-default truth
└── test/smoke/*.exs              # live proof for each supported mode

test/scrypath/
└── docs_contract_test.exs        # bounded drift checks
```

This structure already mostly exists; Phase 68 mainly adds one guide and one missing example smoke file/assertion path. [VERIFIED: codebase grep]

### Pattern 1: One Canonical Support Guide

**What:** Put all public compatibility/support truth in one guide under `guides/` and link to it from README, CONTRIBUTING, the example README, and any operational guide that currently implies support. [VERIFIED: codebase grep]

**When to use:** Any time support truth is currently distributed across several docs or inferred from CI. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: mix.exs docs() extras/groups [VERIFIED: codebase grep]
extras: [
  "README.md",
  "CONTRIBUTING.md",
  "guides/overview.md",
  "guides/golden-path.md",
  "guides/support-and-compatibility.md"
],
groups_for_extras: [
  "Getting Started": [
    "README.md",
    "guides/overview.md",
    "guides/golden-path.md"
  ],
  "Operations": [
    "guides/support-and-compatibility.md",
    "guides/sync-modes-and-visibility.md",
    "guides/meilisearch-operations.md"
  ]
]
```

ExDoc supports publishing extra Markdown pages and grouping them with `groups_for_extras`, so the support guide should enter the same pipeline as the existing guides. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

### Pattern 2: Bounded Contract Tests For Facts, Not Prose

**What:** Add small assertions for link targets, env var names, startup order, and command shape instead of snapshotting entire documents. [VERIFIED: codebase grep]

**When to use:** When a phase changes doc authority or wayfinding but should still allow wording edits. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: test/scrypath/docs_contract_test.exs pattern [VERIFIED: codebase grep]
test "phase 68 start-here path and example proof stay aligned" do
  assert_contains_all(@readme, [
    "guides/golden-path.md",
    "examples/phoenix_meilisearch/README.md",
    "guides/support-and-compatibility.md"
  ])

  assert ordered?(@readme, "guides/golden-path.md", "examples/phoenix_meilisearch/README.md")
  assert ordered?(@readme, "examples/phoenix_meilisearch/README.md", "guides/support-and-compatibility.md")
end
```

### Pattern 3: Example Proof Through Live ExUnit

**What:** Keep the example proof in `mix test` with `@moduletag :integration`, env-gated inclusion, and deterministic Oban behavior for queue-backed tests. [VERIFIED: codebase grep]

**When to use:** For real-adopter proof that must stay close to CI and stay cheap to maintain. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: examples/phoenix_meilisearch/test/test_helper.exs and smoke tests [VERIFIED: codebase grep]
unless System.get_env("SCRYPATH_EXAMPLE_INTEGRATION") in ["1", "true", "TRUE"] do
  ExUnit.configure(exclude: [:integration])
end

ExUnit.start()

defmodule ScrypathDemo.Smoke.MeilisearchObanStackTest do
  use ScrypathDemo.DataCase, async: false
  @moduletag :integration
end
```

ExUnit documents module tags and filtering, and Oban documents `:inline` and `:manual` testing modes for deterministic test behavior. [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] [CITED: https://hexdocs.pm/oban/testing.html]

### Anti-Patterns to Avoid

- **Scattering support truth across docs:** The repo currently makes maintainers read README, CONTRIBUTING, CI, and the example together; Phase 68 exists to end that. [VERIFIED: codebase grep]
- **Snapshotting large prose blocks:** The existing contract suite uses bounded assertions, and the phase context explicitly keeps that philosophy. [VERIFIED: codebase grep]
- **Claiming `:manual` support without live proof:** The example README and smoke tests currently cover `:inline` and `:oban`, but not `:manual`. [VERIFIED: codebase grep]
- **Forgetting the publishing path:** A new support guide is not public if it is missing from `mix.exs` `extras`, `guides/overview.md`, or doc contracts. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
- **Treating `./scripts/smoke.sh` as CI truth:** The example README and CI workflow already distinguish local smoke from the GitHub Actions driver. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Publishing a new support document | Custom docs site or hidden maintainer-only markdown | Existing ExDoc extras/groups in `mix.exs` | The repo already ships guides this way, and ExDoc natively supports extra pages and guide grouping. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Preventing docs drift | Manifest registry or prose snapshots | Existing `test/scrypath/docs_contract_test.exs` style | The phase context explicitly rejects a manifest layer and the current suite already covers doc truth by bounded assertions. [VERIFIED: codebase grep] |
| Proving sync modes in the example | Browser/E2E harness or new service test rig | Example `mix test` smoke files plus `./scripts/smoke.sh` | The example already exercises live Postgres + Meilisearch, and Oban behavior is already made deterministic in test config. [VERIFIED: codebase grep] |
| Showing multiple adoption stories | More example apps | One strengthened `examples/phoenix_meilisearch` | The phase context locks the repo to one canonical example. [VERIFIED: codebase grep] |

**Key insight:** Phase 68 should compose existing repo mechanisms into one authoritative path, not add another abstraction layer on top of them. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Support Truth Still Lives In Three Places

**What goes wrong:** A support guide gets added, but README, CONTRIBUTING, or `guides/meilisearch-operations.md` still carry independent compatibility claims. [VERIFIED: codebase grep]

**Why it happens:** Current support facts are already distributed across those files and CI, so partial cleanup looks “good enough.” [VERIFIED: codebase grep]

**How to avoid:** Make the new support guide the only authority, then replace duplicated claims elsewhere with short summaries and links. [VERIFIED: codebase grep]

**Warning signs:** README or CONTRIBUTING still mention exact version matrices instead of pointing to the support guide. [VERIFIED: codebase grep]

### Pitfall 2: `:manual` Is Documented But Not Actually Proved

**What goes wrong:** The example README says it covers `:manual`, but the example test suite still only proves `:inline` and `:oban`. [VERIFIED: codebase grep]

**Why it happens:** `:manual` is already discussed in README/guides, so it is easy to mistake product support for example-proof support. [VERIFIED: codebase grep]

**How to avoid:** Add one explicit `:manual` smoke path in the example and link to that proof from the example README. [VERIFIED: codebase grep]

**Warning signs:** No `examples/phoenix_meilisearch/test/smoke/*manual*.exs` file or equivalent targeted assertion exists. [VERIFIED: codebase grep]

### Pitfall 3: New Guide Exists But Is Not Published Or Discoverable

**What goes wrong:** The support guide lands on disk but does not appear in HexDocs navigation or the guides index. [VERIFIED: codebase grep]

**Why it happens:** Published docs are driven by `mix.exs` `extras:` and `groups_for_extras`, not by file existence alone. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

**How to avoid:** Update `mix.exs`, `guides/overview.md`, README/example/contributing links, and docs contracts in the same change. [VERIFIED: codebase grep]

**Warning signs:** `mix docs --warnings-as-errors` passes, but the guide is absent from `extras:` or the overview page. [VERIFIED: codebase grep]

### Pitfall 4: CI And Local Example Stories Drift

**What goes wrong:** The example README tells humans to run one path while CI validates another. [VERIFIED: codebase grep]

**Why it happens:** The repo already has both a local smoke harness and a CI driver, and they are intentionally not identical commands. [VERIFIED: codebase grep]

**How to avoid:** Keep the example README explicit that CI runs `mix deps.get` then `mix test`, while `./scripts/smoke.sh` is the local orchestration helper. [VERIFIED: codebase grep]

**Warning signs:** The example README or CONTRIBUTING describes `./scripts/smoke.sh` as the GitHub Actions entrypoint. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources and the current codebase:

### Published Guide Registration

```elixir
# Source: https://hexdocs.pm/ex_doc/ExDoc.html
docs: [
  extras: [
    "README.md",
    "guides/support-and-compatibility.md"
  ],
  groups_for_extras: [
    "Getting Started": ["README.md"],
    "Operations": ["guides/support-and-compatibility.md"]
  ]
]
```

ExDoc documents `:extras` and `:groups_for_extras` as the supported way to publish and organize extra pages. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

### Integration-Gated Example Smoke Test

```elixir
# Source: examples/phoenix_meilisearch/test/test_helper.exs [VERIFIED: codebase grep]
unless System.get_env("SCRYPATH_EXAMPLE_INTEGRATION") in ["1", "true", "TRUE"] do
  ExUnit.configure(exclude: [:integration])
end

ExUnit.start()
```

ExUnit’s documented tag/filter model is the official basis for this pattern. [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html]

### Deterministic Oban Example Proof

```elixir
# Source: examples/phoenix_meilisearch/config/test.exs [VERIFIED: codebase grep]
config :scrypath_demo, Oban, testing: :inline
```

Oban documents `testing: :inline` as the simple test mode and `testing: :manual` as the more explicit control mode. [CITED: https://hexdocs.pm/oban/testing.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Compatibility truth is inferred from README, CONTRIBUTING, CI, and example README together. [VERIFIED: codebase grep] | Publish one support guide as the public source of truth. [VERIFIED: codebase grep] | Phase 68 target, 2026-04-22 context. [VERIFIED: codebase grep] | Maintainers and adopters stop reconstructing support claims from scattered files. [VERIFIED: codebase grep] |
| Example app is a useful smoke artifact with `:inline` and `:oban` coverage. [VERIFIED: codebase grep] | Example app becomes the canonical adopter proof and adds a `:manual` proof path. [VERIFIED: codebase grep] | Phase 68 target, 2026-04-22 context. [VERIFIED: codebase grep] | The example becomes a defended promise rather than a nice-to-have sample. [VERIFIED: codebase grep] |
| Docs contracts already lock selected guide/README facts with bounded assertions. [VERIFIED: codebase grep] | Extend the same bounded suite to cover Phase-68 navigation and env/startup drift. [VERIFIED: codebase grep] | Existing pattern before Phase 68; extension planned now. [VERIFIED: codebase grep] | Planner can add verification without inventing a new enforcement system. [VERIFIED: codebase grep] |

**Deprecated/outdated:**

- Treating `guides/meilisearch-operations.md` as a de facto compatibility matrix is outdated for this milestone; the Phase 68 context explicitly moves that responsibility into one support guide. [VERIFIED: codebase grep]
- Treating `examples/phoenix_meilisearch/README.md` as a Docker note only is outdated for this milestone; the context promotes it to canonical adopter proof. [VERIFIED: codebase grep]

## Assumptions Log

All material claims in this research were verified from the codebase, the local environment, or official documentation in this session. No additional user confirmation is required before planning. [VERIFIED: codebase grep] [VERIFIED: local runtime] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] [CITED: https://hexdocs.pm/oban/testing.html]

## Open Questions (RESOLVED)

1. **What exact `:manual` behavior should the example prove?**
   - Resolution: Use the smallest live proof that matches the shipped public contract and existing integration patterns: assert `sync_mode: :manual` returns an accepted envelope first, then use one explicit status-driven follow-up in the example app to observe completion before asserting hydrated search visibility. [VERIFIED: codebase grep]
   - Why this choice: Existing library and live-operator tests already show the honest boundary for `:manual`: accepted work is not immediate visibility, and explicit follow-up via status/reconcile-style observation is the right closure instead of pretending the write was synchronous. [VERIFIED: codebase grep]
   - Planning impact: `68-02-PLAN.md` should require a dedicated manual smoke test that asserts the accepted return map, waits through `Scrypath.sync_status/2` or an equivalent bounded helper for completion, and only then asserts `Scrypath.search/3` returns the row. Backfill/reindex stay linked operator workflows, not the canonical first manual proof in the example. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Repo docs/tests and example app | ✓ | `1.19.5` | — [VERIFIED: local runtime] |
| Mix | All verify/test/docs commands | ✓ | `1.19.5` | — [VERIFIED: local runtime] |
| Docker Engine | Example local smoke stack | ✓ | `29.3.1` | None for live local proof; CI still provides services. [VERIFIED: local runtime] |
| Docker Compose | Example local smoke orchestration | ✓ | `v5.1.1` | Manual `docker run` would be possible but should not be the planned path. [VERIFIED: local runtime] |
| `pg_isready` client | Local Postgres readiness checks in smoke flow | ✓ | `14.17` | CI installs PostgreSQL client explicitly when needed. [VERIFIED: local runtime] [VERIFIED: codebase grep] |
| Node / npm | Phoenix asset/runtime ecosystem if example app needs it later | ✓ | `22.14.0` / `11.1.0` | Not required for the documented Phase 68 smoke path today. [VERIFIED: local runtime] |

**Missing dependencies with no fallback:**

- None detected for planning or for the documented Phase 68 proof paths. [VERIFIED: local runtime]

**Missing dependencies with fallback:**

- None. [VERIFIED: local runtime]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with repo-local Mix verify tasks and docs-contract coverage. [VERIFIED: codebase grep] |
| Config file | `test/test_helper.exs` and `examples/phoenix_meilisearch/test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/scrypath/docs_contract_test.exs`. [VERIFIED: codebase grep] |
| Full suite command | `mix test` at repo root; `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test` for live example proof. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INTG-01 | Canonical example proves `:inline`, `:manual`, and `:oban` against the real app. [VERIFIED: codebase grep] | integration | `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test` [VERIFIED: codebase grep] | Partial: `:inline` and `:oban` files exist; `:manual` proof file/assertion is missing. [VERIFIED: codebase grep] |
| INTG-03 | One support guide publishes defended compatibility truth. [VERIFIED: codebase grep] | docs contract + docs build | `mix test test/scrypath/docs_contract_test.exs && mix docs --warnings-as-errors` [VERIFIED: codebase grep] | No support guide file exists yet. [VERIFIED: codebase grep] |
| INTG-04 | README/guides/CONTRIBUTING/example stay aligned on links, env vars, and startup order. [VERIFIED: codebase grep] | docs contract | `mix test test/scrypath/docs_contract_test.exs` [VERIFIED: codebase grep] | Existing suite exists, but Phase-68 assertions do not. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** `mix test test/scrypath/docs_contract_test.exs` when editing docs or wayfinding. [VERIFIED: codebase grep]
- **Per wave merge:** `mix docs --warnings-as-errors` and `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test` after support-guide and example-proof changes land together. [VERIFIED: codebase grep]
- **Phase gate:** Repo docs contract green, docs build green, and live example proof green before `/gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `guides/support-and-compatibility.md` — missing canonical public support guide for INTG-03. [VERIFIED: codebase grep]
- [ ] `examples/phoenix_meilisearch/test/smoke/*manual*.exs` or equivalent targeted assertion path — missing example proof for `:manual` under INTG-01. [VERIFIED: codebase grep]
- [ ] `test/scrypath/docs_contract_test.exs` Phase-68 assertions — missing link/env/startup-order coverage for INTG-04. [VERIFIED: codebase grep]
- [ ] `mix.exs` ExDoc extras/groups and `guides/overview.md` — missing support-guide publication and discoverability wiring. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | This phase does not add auth flows. [VERIFIED: codebase grep] |
| V3 Session Management | no | This phase does not add session handling. [VERIFIED: codebase grep] |
| V4 Access Control | no | The work is docs/example/support-contract focused, not authorization logic. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Keep env var names, startup commands, and query examples aligned with the already-tested example/config surfaces rather than inventing new unchecked variants. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Keep support/docs narrow around Meilisearch URL/key posture and point operational guidance to the existing Meilisearch operations guide; never invent crypto advice in project docs. [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docs accidentally imply unsupported runtime or service combinations | Spoofing / Tampering | Support guide must only state combinations defended by `mix.exs`, the example, and `.github/workflows/ci.yml`. [VERIFIED: codebase grep] |
| Example docs encourage unsafe Meilisearch setup or secret handling | Information Disclosure | Keep committed docs on placeholder URLs/env names only and route deeper operational posture to `guides/meilisearch-operations.md`. [VERIFIED: codebase grep] |
| Drift between CI and local runbooks causes false confidence | Tampering | Contract-test the env names, command order, and canonical links that describe the example proof path. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- Local repo files: `README.md`, `CONTRIBUTING.md`, `mix.exs`, `.github/workflows/ci.yml`, `guides/*.md`, `examples/phoenix_meilisearch/**/*`, `test/scrypath/docs_contract_test.exs`, `.planning/phases/68-example-proof-and-support-contract/68-CONTEXT.md`. [VERIFIED: codebase grep]
- ExDoc official docs: https://hexdocs.pm/ex_doc/ExDoc.html — extras and guide grouping behavior. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
- ExUnit official docs: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html — module tags and test filtering behavior. [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html]
- Oban official docs: https://hexdocs.pm/oban/testing.html — testing modes and deterministic queue-testing guidance. [CITED: https://hexdocs.pm/oban/testing.html]
- Local environment probes: `elixir --version`, `mix --version`, `docker --version`, `docker compose version`, `pg_isready --version`, `node --version`, `npm --version`. [VERIFIED: local runtime]

### Secondary (MEDIUM confidence)

- None needed. All major recommendations were derived from primary sources in this session. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)

- None. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - The phase reuses locked repo dependencies, current CI service pins, and official docs for ExDoc/ExUnit/Oban behavior. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] [CITED: https://hexdocs.pm/oban/testing.html]
- Architecture: HIGH - The repo already contains the proof surfaces, docs pipeline, and bounded contract pattern this phase needs. [VERIFIED: codebase grep]
- Pitfalls: HIGH - The current gaps are directly observable in the codebase: no support guide and no `:manual` example proof. [VERIFIED: codebase grep]

**Research date:** 2026-04-22
**Valid until:** 2026-05-22
