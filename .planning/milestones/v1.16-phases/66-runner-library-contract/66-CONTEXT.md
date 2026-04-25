# Phase 66: Runner-library contract - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **OPS3-03** for playbook execution: **`ScrypathOps.Playbook.Runner`** and adjacent execution code must use a **documented, stable** success/error contract that stays aligned with the underlying **`Scrypath.search/3`** / **`search_many/2`** and Mix-facing operator paths where applicable. Phase 66 also adds **automated parity tests** that fail if OPSUI execution diverges from the core library contract on representative fixtures.

**Explicitly not in this phase:** expanding **`mix verify.opsui`** or **`docs_contract_test`** for execution UI strings and doc anchors (**Phase 67**); freezing human-facing **copy**, **doc links**, or LiveView presentation wording as part of the execution contract; introducing durable run records, Oban-owned execution, reconnect attachment, or streaming run logs.

</domain>

<decisions>
## Implementation Decisions

### Contract boundary

- **D-01:** Keep **`Runner.run_validated/3`** on a **raw Elixir tuple seam**: **`{:ok, result}`** or **`{:error, reason}`** only. Do **not** make the runner return UI-ready enriched maps.
- **D-02:** Preserve the **reason atom/tuple** as the **stable contract key**. This carries forward Phase 65 and is the parity target for Phase 66.
- **D-03:** **OPSUI enrichment** remains an **edge concern** owned by **`ScrypathOps.Playbook.RunFailure`** / LiveView-facing code. Human copy, docs links, and ticket-friendly payload shaping are **not** the runner contract.
- **D-04:** Do **not** introduce a new public typed runner error struct in Phase 66. A richer internal seam can be reconsidered later if Scrypath gains another real non-LiveView execution consumer.

### Canonical contract documentation

- **D-05:** The **single canonical execution-contract reference** should live in **`ScrypathOps.Playbook.Runner`** `@moduledoc`, under a dedicated section such as **`## Runner-library contract`**.
- **D-06:** That section should explicitly document:
  - accepted input shape after **`V1.validate/1`**
  - success shapes by mode (**`search`** → **`%Scrypath.SearchResult{}`**, **`search_many`** → **`%Scrypath.MultiSearchResult{}`**)
  - failure shape as **`{:error, reason}`**
  - the rule that **reason identity**, not UI wording, is the stable contract
  - relationship to bang APIs / Mix-facing formatting
- **D-07:** **`scrypath_ops/docs/playbook-schema-v1.md`** remains the authority for the **JSON wire format**, not the execution contract. It should link to the canonical runner contract instead of duplicating it.

### Parity test depth

- **D-08:** Phase 66 should use a **representative contract matrix**, not a giant mirrored suite and not a token smoke test.
- **D-09:** The parity matrix should cover the **main semantic seams** only:
  - **`search`** happy path
  - **`search_many`** happy path
  - one **pre-dispatch validation/config** failure
  - one **backend/runtime** failure from the underlying **`Scrypath`** path
  - one **multi-search-specific** failure or edge case that matters to operators
- **D-10:** Keep parity tests **cross-boundary** and **explicit**. Reuse helpers where useful, but avoid building a large generalized meta-test harness that duplicates the whole core suite.
- **D-11:** If a small invariant check helps, keep it narrow and structural; do **not** expand Phase 66 into broad property testing.

### Alignment scope with Scrypath and Mix paths

- **D-12:** In Phase 66, “consistent with **`Scrypath`** / Mix operator paths” means **shared semantic outcomes and stable reason shapes**, not identical human-facing strings.
- **D-13:** Mix/operator surfaces may continue to **format** those reasons separately for CLI or UI use. That formatting is a downstream presentation concern.
- **D-14:** Phase 66 must ensure there are **no silent rescue/swallow paths** that hide **`{:error, term}`** divergence from tests or operators.
- **D-15:** If future work wants stronger cross-surface consistency, the next acceptable step is a **shared internal normalization seam** for metadata. Do **not** freeze presentation strings as contract in this phase.

### the agent's Discretion

- Exact naming and placement of parity helpers / fixtures.
- Whether the canonical runner section also introduces local `@typedoc` aliases for result/failure shapes, provided the public contract remains a tuple seam.
- Exact fixture count within the recommended representative matrix, provided it stays focused and readable.

</decisions>

<specifics>
## Specific Ideas

- Think of the contract like **Ecto changeset errors** or **LiveView async results**: the core returns structured machine-meaningful data, and the edge decides how to render it.
- A good maintainer answer to “what does a playbook run return?” should be: “Read **`ScrypathOps.Playbook.Runner`** — that section is the contract.”
- Search-library precedents reinforce the split:
  - **Searchkick** keeps multi-search errors inspectable per query rather than collapsing everything into one presentation shape.
  - **Laravel Scout** keeps engine/app contracts narrow and pushes queue/UI handling outward.
  - **meilisearch-rails** shows the footgun of convenience modes that suppress failures too easily; Scrypath should keep operator-visible failure semantics explicit.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase scope

- `.planning/ROADMAP.md` — Phase 66 goal and observable success criteria for **OPS3-03**.
- `.planning/REQUIREMENTS.md` — v1.16 requirement text for runner-library contract alignment.
- `.planning/PROJECT.md` — project principles: operational honesty, least surprise, release quality.
- `.planning/phases/65-playbook-run-lifecycle-opsui/65-CONTEXT.md` — prior locked decision that runner **reason** atoms/tuples remain the stable key.

### Current execution contract and enrichment code

- `scrypath_ops/lib/scrypath_ops/playbook/runner.ex` — execution entry point whose tuple contract becomes canonical.
- `scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex` — UI-facing failure enrichment that must stay outside the raw runner contract.
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` — current async run handling and where enrichment is consumed.
- `scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex` — current docs-link resolution used by presentation layers.

### Library and Mix reference paths

- `lib/scrypath/search.ex` — canonical **`search/3`** and **`search_many/2`** success/error shapes.
- `lib/scrypath.ex` — public API docs that explain non-bang vs bang search behavior.
- `lib/scrypath/search/error.ex` — raised exception for bang search helpers.
- `lib/scrypath/errors.ex` — stable single-line formatting for tagged error reasons.
- `lib/scrypath/cli/operator_task.ex` — Mix/operator formatting boundary for failures.

### Existing tests to align and extend

- `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` — current runner behavior tests.
- `scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs` — enriched failure payload coverage.
- `test/scrypath/search_many_test.exs` — representative multi-search success/failure shapes in core.
- `test/scrypath/docs_contract_test.exs` — existing docs-contract patterns likely extended in Phase 67, not widened here.

### Wire-format docs

- `scrypath_ops/docs/playbook-schema-v1.md` — playbook JSON schema authority; should link to runner contract, not duplicate it.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`ScrypathOps.Playbook.Runner`** already returns **`{:ok, term()} | {:error, term()}`** and is close to the desired seam.
- **`ScrypathOps.Playbook.RunFailure`** already provides the enrichment boundary for failure class, message, copy, and docs.
- **`PlaybookLive`** already consumes raw async results and enriches failures afterward, which matches the recommended direction.
- **`Scrypath.Errors.format_reason/1`** and **`Scrypath.Search.Error`** show the existing library pattern: raw reasons first, formatting/raising layered on top.

### Established Patterns

- Core **Scrypath** APIs favor **stable tuple returns** with optional bang variants.
- Presentation-specific formatting already happens in **Mix** and **OPSUI** layers, not inside the underlying library functions.
- Current code already treats **`search`** and **`search_many`** differently at the result type level while preserving a shared tuple contract.

### Integration Points

- Add canonical contract docs directly to **`scrypath_ops/lib/scrypath_ops/playbook/runner.ex`**.
- Add representative parity tests around **`Runner.run_validated/3`** versus underlying **`Scrypath`** semantics.
- Ensure **`RunFailure`** and LiveView layers consume raw reasons without redefining the execution contract.

</code_context>

<deferred>
## Deferred Ideas

- Introduce a shared **internal** normalized failure metadata seam if a second real execution consumer appears.
- Promote a new public **`%RunError{}`** struct only if Scrypath genuinely needs a broader cross-surface execution API and is willing to carry that semver burden.
- Freeze human-facing wording, docs-link parity, and execution-surface doc anchors under **Phase 67** verification/doc-contract work instead of Phase 66.
- Durable runs, reconnect attachment, streaming progress, or server-owned execution records remain out of scope for this phase.

</deferred>

---

*Phase: 66-runner-library-contract*  
*Context gathered: 2026-04-22*
