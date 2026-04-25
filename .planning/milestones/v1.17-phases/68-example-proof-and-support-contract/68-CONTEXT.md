# Phase 68: Example proof and support contract - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the first adopter-confidence slice for **v1.17** by making **`examples/phoenix_meilisearch/`** the canonical real-app proof for Scrypath adoption, publishing one explicit support / compatibility contract, and tightening README / guides / CONTRIBUTING / example wayfinding plus doc contracts so maintainers and adopters do not need to reconstruct the story from scattered sources.

This phase is about **proof, support truth, and documentation contract** only. It does **not** widen Scrypath’s public search/indexing feature surface, add more examples, or invent a new verification system beyond bounded contracts that protect the new canonical sources.

</domain>

<decisions>
## Implementation Decisions

### Canonical adopter proof shape

- **D-01:** Keep the docs model **two-layered and idiomatic for Elixir OSS**:
  - **`README.md`** stays short and adoption-oriented.
  - **HexDocs guides** hold the longer walkthroughs and operational depth.
  - The **example app README** becomes the canonical **real-app proof** surface.
- **D-02:** Keep **`guides/golden-path.md`** as the **first-hour**, **`:inline`-only** path. Do **not** collapse the whole adoption story into the example app; that would over-rotate the library toward Phoenix-specific setup and weaken the current Ecto-first story.
- **D-03:** Promote **`examples/phoenix_meilisearch/README.md`** from “optional live smoke” to the **single canonical adopter proof** for a real Phoenix + Ecto + Postgres + Meilisearch app.
- **D-04:** The example proof must explicitly cover **all three supported sync modes** in one coherent runbook:
  - **`:inline`** as the simplest first live success
  - **`:manual`** as the explicit operator-controlled path
  - **`:oban`** as the queue-backed production-shaped path
- **D-05:** The example should remain **single-example, production-shaped, and minimal**. Do **not** add a second example app or an examples zoo in Phase 68. One strong proof is better than several half-maintained samples.
- **D-06:** The example README should be written as a **proof source**, not just a Docker note:
  - what the example proves
  - which sync stories it covers
  - what CI runs
  - what local smoke proves
  - where to go next for conceptual or operational depth
- **D-07:** The example app itself, not just prose, must back the promise. If docs claim `:inline`, `:manual`, and `:oban` support in the canonical proof, the example must exercise or directly prove each of those paths through tests, scripted smoke, or a tightly bounded combination of both.

### Support and compatibility contract

- **D-08:** Publish **one dedicated public guide-level support contract** rather than burying support truth in README, CONTRIBUTING, or operator docs.
- **D-09:** The support contract should be a new guide with a boring explicit title, e.g. **`guides/support-and-compatibility.md`** or equivalent. The exact filename is planner discretion, but the concept is locked: **one public canonical source**.
- **D-10:** The support contract must state the support/tested truth Scrypath can actually defend:
  - Elixir support floor and tested range
  - OTP support floor and tested range
  - Phoenix/Ecto-shaped adoption posture
  - the pinned Meilisearch minor used by CI and the example
  - supported write-path modes: **`:inline`**, **`:manual`**, **`:oban`**
  - explicit non-goals / non-promises where relevant
- **D-11:** Keep the support contract **narrower than internal architecture**. Do not promise public multi-backend parity, broader framework guarantees, or runtime combinations not backed by CI, example proof, or maintainer intent.
- **D-12:** README should include only a **short support summary** and link to the support contract. README is not the authoritative home for the full matrix.
- **D-13:** CONTRIBUTING may still mention CI jobs and verify commands, but it should **point to** the support contract for compatibility truth instead of being the place where adopters discover supported versions by accident.
- **D-14:** `guides/meilisearch-operations.md` should stop being an implicit support matrix. It may reference the support contract, but should stay focused on operational posture.

### Wayfinding and docs architecture

- **D-15:** The onboarding path should be **linear and explicit**:
  - **README** -> **`guides/golden-path.md`** for first-hour success
  - **README / golden path** -> **`examples/phoenix_meilisearch/README.md`** for the canonical real-app proof
  - **README / example / CONTRIBUTING** -> **support contract** for compatibility truth
  - **support contract / example** -> operations and sync guides for deeper semantics
- **D-16:** README should remain **short, copy-pasteable, and product-shaped**, more like Phoenix / Ecto / Oban than a giant all-in-one manual. Scrypath has too much operational surface area for a README-heavy strategy to age well.
- **D-17:** The example app README should be the source of truth for:
  - env vars and local stack details
  - startup order
  - CI-shaped consumer test path
  - mode-specific proof path in the example
- **D-18:** `CONTRIBUTING.md` should stay maintainer/contributor shaped:
  - exact verify commands
  - CI job mapping
  - note that docs and example changes must stay aligned
  It should not become the adopter-facing support matrix.
- **D-19:** Keep the current project posture of **operational honesty** visible in the path. The user should encounter early, not late, that:
  - accepted sync work is not the same as search visibility
  - delete semantics deserve explicit care
  - backfill and reindex are first-class workflows

### Docs-contract strictness

- **D-20:** Stay with the repo’s existing **bounded contract** philosophy. Do **not** snapshot large prose blocks or freeze narrative wording broadly.
- **D-21:** Extend **`test/scrypath/docs_contract_test.exs`** to lock the **Phase 68 drift surface only**:
  - canonical adopter-proof link target
  - canonical support-contract link target
  - canonical “start here” link order
  - env vars used by the example proof
  - startup order / command order
  - explicit mode coverage and wording shape where needed
- **D-22:** Contracts should protect **facts and navigation**, not every sentence:
  - source-of-truth docs
  - command shapes
  - env var names
  - CI/example ordering
  - where maintainers/adopters are told to start
- **D-23:** Avoid introducing a manifest-driven contract system or another meta-layer in this phase. That is over-engineered for the current repo and would distract from shipping the actual support and proof surfaces.

### Example proof depth and testing philosophy

- **D-24:** The canonical example must prove the public support story with **real consumer-shaped behavior**, not just snippets. The example already proves **`:inline`** and **`:oban`** against real Postgres + Meilisearch; Phase 68 should close the **`:manual`** gap instead of reworking the entire example.
- **D-25:** Example verification should remain **boring and trustworthy**:
  - CI-driven example proof path
  - local smoke path for humans
  - bounded doc contracts pinning the docs to those paths
- **D-26:** Do not invent a heavy browser or full-system golden environment for this phase. Keep the proof near ExUnit, Mix, and the existing example smoke shape.
- **D-27:** The example should answer “does Scrypath land cleanly in a Phoenix app?” without implying Phoenix is the only intended integration shape. The real-app proof is Phoenix-shaped; the library remains Ecto-first.

### Ecosystem and precedent lessons to adopt

- **D-28:** Borrow the best parts of strong precedents:
  - **Searchkick**: first-mile DX and obvious happy path
  - **Laravel Scout**: clear support/engine contract and linear docs wayfinding
  - **meilisearch-rails**: explicit compatibility near the top and a runnable app/playground shape
  - **Phoenix / Ecto / Oban**: short README, deeper guides, clear contributor separation
- **D-29:** Avoid the most common footguns seen in adjacent libraries:
  - hiding write-path semantics behind “magic”
  - letting async delete semantics stay implicit
  - making compatibility claims broader than CI or docs can prove
  - letting the example drift away from the docs
  - turning the README into the entire manual

### the agent's Discretion

- Exact section ordering in README, the support guide, and the example README, provided the canonical path above remains obvious.
- Whether the example proves `:manual` through a dedicated smoke test, a precise README runbook plus targeted test, or a bounded hybrid, provided the claim is real and contract-testable.
- Exact test names and doc-contract assertion wording, provided the bounded Phase 68 drift surface is covered.

</decisions>

<specifics>
## Specific Ideas

- The cleanest user experience is:
  - **README** says “start here”
  - **golden path** gets the first indexed document and first search working fast
  - **example README** proves the real app shape for all supported modes
  - **support contract** answers “what do you actually support?”
- The example should feel like Scrypath’s **canonical adopter proof**, not just “a smoke script we happen to ship.”
- The support contract should be intentionally boring. If a maintainer has to say “it depends, check three files,” the contract failed.
- Scrypath should prefer the DX clarity of **Searchkick** and the support-contract discipline of **Scout** / **meilisearch-rails**, while keeping Elixir-native docs structure closer to **Phoenix**, **Ecto**, and **Oban**.
- The public promise should stay narrower than the internal seams. This phase is about making the real promise legible and provable, not widening it.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase scope

- `.planning/ROADMAP.md` — Phase 68 scope, success criteria, and milestone framing.
- `.planning/REQUIREMENTS.md` — **INTG-01**, **INTG-03**, and **INTG-04** requirement text and traceability.
- `.planning/PROJECT.md` — project principles: Ecto-first ergonomics, Meilisearch-first v1, operational honesty, release quality.
- `.planning/STATE.md` — current milestone state and next-phase framing.

### Prior phase decisions that constrain Phase 68

- `.planning/phases/65-playbook-run-lifecycle-opsui/65-CONTEXT.md` — recent pattern of bounded contracts over prose freeze.
- `.planning/phases/66-runner-library-contract/66-CONTEXT.md` — stable contract boundary discipline.
- `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md` — explicit choice to protect stable affordances and doc truth with bounded tests, not snapshot-style freezing.

### Current canonical adopter and documentation surfaces

- `README.md` — current public onboarding and product narrative.
- `guides/golden-path.md` — current first-hour path and inline-only onboarding story.
- `guides/sync-modes-and-visibility.md` — canonical sync semantics and operational honesty language.
- `guides/meilisearch-operations.md` — current Meilisearch posture and version-alignment references.
- `CONTRIBUTING.md` — maintainer verify matrix, CI job mapping, and current example guidance.
- `examples/phoenix_meilisearch/README.md` — current example runbook that should become the canonical real-app proof.

### Example proof implementation anchors

- `examples/phoenix_meilisearch/scripts/smoke.sh` — local smoke orchestration path and startup-order truth.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs` — current inline integration proof.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_oban_stack_test.exs` — current Oban integration proof.
- `examples/phoenix_meilisearch/config/dev.exs` — example runtime defaults, including local Postgres port shape.
- `examples/phoenix_meilisearch/config/test.exs` — test-mode runtime and Oban testing shape.
- `examples/phoenix_meilisearch/compose.yaml` — local Postgres + Meilisearch stack contract.

### Documentation contract surface

- `test/scrypath/docs_contract_test.exs` — existing bounded docs-contract suite that should be extended for Phase 68.
- `.github/workflows/ci.yml` — current CI truth for example integration job names, service versions, and command order.

### Ecosystem and precedent references

- `prompts/elixir-best-practices-deep-research.md` — Elixir OSS / docs / DX framing.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS library release and docs expectations.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — Phoenix / Ecto / Plug ecosystem fit.
- `prompts/elixir-search-lib-deep-research.md` — search-library product and architecture framing.
- `prompts/search-lib-use-cases-deep-research.md` — adopter use-case framing.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`examples/phoenix_meilisearch/README.md`** already contains most of the stack/env/CI truth needed for a canonical example proof; it needs repositioning and mode-completeness more than reinvention.
- **`meilisearch_stack_test.exs`** and **`meilisearch_oban_stack_test.exs`** already provide real live proof for two of the three supported sync stories.
- **`test/scrypath/docs_contract_test.exs`** already embodies the repo’s preferred bounded contract-testing style for doc truth and wayfinding.

### Established Patterns

- Scrypath prefers a **compact README** with deeper guide authority rather than duplicating every guide inline.
- The repo already treats **guide authority** and **docs contract tests** as first-class product surfaces.
- Prior phases explicitly favored **stable truth contracts** over snapshotting broad prose.
- The example app is already **CI-backed**, which makes promoting it into the canonical proof much safer than creating a new example.

### Integration Points

- Phase 68 should extend the existing example README/tests/docs-contract suite rather than create a second proof mechanism.
- The new support contract should become a linked authority from README, the example README, `CONTRIBUTING.md`, and relevant guides.
- `docs_contract_test.exs` is the correct place to freeze Phase 68 wayfinding and drift-sensitive facts.

</code_context>

<deferred>
## Deferred Ideas

- Additional example apps or an examples catalog — one canonical example is the right move for this phase.
- A manifest-driven docs contract system or generalized contract registry.
- Heavy browser/E2E infrastructure for example verification beyond the current bounded ExUnit + smoke approach.
- Any widening of the public feature surface, backend scope, or adapter promise.
- Rewriting the onboarding architecture around Phoenix-only assumptions; Scrypath remains Ecto-first even if the canonical proof app is Phoenix-shaped.

</deferred>

---

*Phase: 68-example-proof-and-support-contract*
*Context gathered: 2026-04-22*
