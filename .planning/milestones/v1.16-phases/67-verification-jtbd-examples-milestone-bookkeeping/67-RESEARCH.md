# Phase 67: Verification, JTBD examples, milestone bookkeeping - Research

**Researched:** 2026-04-22  
**Domain:** OPSUI execution-surface verification, playbook example fixtures, and milestone-close bookkeeping for Scrypath v1.16. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]  
**Confidence:** HIGH for verification/examples guidance; MEDIUM for exact close sequencing because `v1.16` is still open at research time. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/ROADMAP.md]

<user_constraints>
## User Constraints (from CONTEXT.md)

The following sections are copied verbatim from `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md`. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]

### Locked Decisions

#### Verification contract depth

- **D-01:** Use a **layered, bounded contract** for execution verification. Keep **`mix verify.opsui`** as the umbrella entrypoint only; do **not** turn the Mix task into a contract parser or a second source of truth.
- **D-02:** Put execution-surface contract tests in **`scrypath_ops`**, close to the code they protect:
  - a bounded **LiveView** contract test for stable execution selectors / phrases
  - a **`DocResolver`** contract test for path + fragment mapping and on-disk anchor existence
  - a fixture contract test that validates shipped playbooks and checks doc references
- **D-03:** Extend root **`test/scrypath/docs_contract_test.exs`** only for maintainer-facing contracts: contributor instructions, the presence of **`mix verify.opsui`**, the **`mix scrypath_ops.playbooks.validate examples/playbooks`** path, and the exact shipped example filenames referenced from docs.
- **D-04:** Freeze only the **bounded execution contract**, not all prose. Stable items for Phase 67:
  - running-state presence
  - success summary prefix **`Run finished`**
  - failure panel selector
  - **`Cancel run`**
  - **`Copy diagnostics`**
  - **`RunFailure`** response shape fields and **`DocResolver`** anchor mappings
- **D-05:** Leave flexible any support text that is not the operator contract: import/load flashes, helper configuration text, detailed success summaries after the stable prefix, and visual phrasing outside existing test ids / nav contracts.
- **D-06:** Do **not** freeze full absolute documentation URLs from **`DocResolver`**. Freeze relative doc paths + fragments and assert those anchors exist on disk; the base URL remains configurable.
- **D-07:** Do **not** duplicate Phase 66 runner semantics in Phase 67 docs tests. The raw tuple seam and reason identity are already locked; Phase 67 verifies the operator-facing execution surface above that seam.

#### JTBD example fixture shape

- **D-08:** Ship **narrative JTBD fixtures** as the canonical **`examples/playbooks/`** examples for Phase 67. Do **not** rely on bare minimal schema envelopes as the main shipped examples, and do **not** escalate to a full production-like golden workspace.
- **D-09:** The two primary shipped fixtures should represent distinct operator jobs:
  - **single-search triage**
  - **multi-search / federation inspection**
- **D-10:** Use explicit, job-shaped filenames rather than transport-shaped filenames. Recommended names:
  - **`sync_triage_posts_recent.json`**
  - **`federation_inspect_posts_and_comments.json`**
- **D-11:** Each shipped fixture should include operator-meaningful metadata when supported by the current wire format:
  - **`title`**
  - **`description`**
  - optional **`tags`**
  - bounded, valid **`opts`**
  - filenames that describe the job being saved
- **D-12:** Keep the examples small, importable, and validation-friendly. They are **input fixtures**, not backend output snapshots, and they must remain cheap to validate through **`mix scrypath_ops.playbooks.validate examples/playbooks`**.
- **D-13:** Keep **`playbook-schema-v1.md`** as the wire-format authority with minimal structural snippets. Put the operator narrative around why to run these fixtures in operator / contributor docs, not in the schema spec itself.
- **D-14:** Keep the schema references illustrative and portable. Continue using bounded example modules such as **`MyApp.Post`** / **`MyApp.Comment`** unless a stronger canonical demo domain is intentionally introduced elsewhere.
- **D-15:** Avoid backend-specific or stub-hostile options in the primary shipped fixtures. The examples should teach operator intent, not force deeper backend semantics or special-case weighting behavior.

#### Milestone bookkeeping discipline

- **D-16:** Phase 67 should **prepare the v1.16 freeze and update rolling traceability immediately**, but it should **not** claim a release, archive, or Hex narrative that is not actually happening in the same change.
- **D-17:** Update rolling planning truth when the work is complete:
  - **`.planning/REQUIREMENTS.md`** traceability for **OPS3-04**..**OPS3-06**
  - **`.planning/ROADMAP.md`** Phase 67 completion state
  - **`.planning/PROJECT.md`** and **`.planning/STATE.md`** current-state text
- **D-18:** Prepare the frozen milestone trio for **v1.16**:
  - **`milestones/v1.16-ROADMAP.md`**
  - **`milestones/v1.16-REQUIREMENTS.md`**
  - **`milestones/v1.16-MILESTONE-AUDIT.md`**
  These should reflect real status only. If the audit is not actually complete yet, do not label it as passed.
- **D-19:** Touch **`.planning/MILESTONES.md`** only when **v1.16** is genuinely closed. Until then, preserve the distinction between active milestone truth and historical shipped milestones.
- **D-20:** Do **not** touch **`mix.exs`** versioning, **`CHANGELOG.md`** release narrative, or Hex-facing claims unless a real publish is in scope for the same close.
- **D-21:** Maintain the repo’s existing separation between “milestone shipped / archived in planning” and “Hex package released.” Scrypath’s public package truth comes from the actual release path, not from planning closure alone.

### Claude's Discretion

- Exact test module names and placement inside **`scrypath_ops/test/`**, provided the layered split above is preserved.
- Whether the old minimal example filenames are replaced, retained as secondary schema-only examples, or redirected via docs, provided the two JTBD fixtures become the canonical shipped examples.
- Exact wording of bounded docs-contract assertions, provided they freeze the required filenames, commands, and honest execution anchors without snapshotting all prose.

### Deferred Ideas (OUT OF SCOPE)

- A centralized manifest file for strings / anchors / fixtures — over-engineered for this phase.
- Full snapshot-style freezing of PlaybookLive copy or HTML.
- Production-like golden workspace trees or deeper example catalogs.
- Any version bump, release note change, or Hex-publish narrative not backed by a real release event.
- Durable run history, richer playbook transport semantics, or broader OPSUI execution features beyond the bounded verification / examples / bookkeeping close.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS3-04 | `mix verify.opsui` and `docs_contract_test` must cover execution surfaces so LiveView, runner wiring, and contributor docs cannot drift silently. [VERIFIED: .planning/REQUIREMENTS.md] | Add one bounded `PlaybookLive` contract test module, one `DocResolver` anchor/path test, one shipped-fixture contract test under `scrypath_ops/test/`, then extend root `test/scrypath/docs_contract_test.exs` only for contributor command text and canonical example filenames. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] [VERIFIED: test/scrypath/docs_contract_test.exs] |
| OPS3-05 | `examples/playbooks/` must ship at least two JTBD-shaped fixtures aligned with docs and referenced from operator or contributor docs. [VERIFIED: .planning/REQUIREMENTS.md] | Replace or demote the current minimal examples and make two named fixtures canonical in docs: one single-search triage fixture and one federation/multi-search inspection fixture. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] [VERIFIED: scrypath_ops/examples/playbooks/search_minimal.json] [VERIFIED: scrypath_ops/examples/playbooks/search_many_minimal.json] |
| OPS3-06 | Rolling planning artifacts must reflect v1.16 close discipline and prepare the frozen `v1.16-*` trio without false Hex/release claims. [VERIFIED: .planning/REQUIREMENTS.md] | Follow the v1.15 manual close pattern for `ROADMAP`, `REQUIREMENTS`, `PROJECT`, `STATE`, and milestone archives, but do not update `.planning/MILESTONES.md` or Hex narrative until v1.16 is genuinely closed. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] [VERIFIED: .planning/milestones/v1.15-ROADMAP.md] [VERIFIED: .planning/milestones/v1.15-REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md] |
</phase_requirements>

## Summary

The codebase already has the execution seam that Phase 67 should protect rather than redesign: `PlaybookLive` renders a bounded run lifecycle with `Running playbook`, `Cancel run`, `Run finished`, `Copy diagnostics`, and `data-testid="run-failure-panel"`, while `RunFailure` and `DocResolver` centralize failure metadata and documentation links above the Phase 66 raw tuple contract. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex]

The missing work is layered verification and honest packaging around that seam. Today, `mix verify.opsui` is still only a thin `cd scrypath_ops && mix deps.get && mix test` umbrella, root `docs_contract_test.exs` only guards maintainer-facing verify text, the shipped playbook examples are still transport-shaped minimal envelopes, and no `v1.16-*` milestone files exist yet. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: scrypath_ops/examples/playbooks/search_minimal.json] [VERIFIED: scrypath_ops/examples/playbooks/search_many_minimal.json] [VERIFIED: local command ls -1 .planning/milestones | sort | rg '^v1\\.16-']  

**Primary recommendation:** Plan Phase 67 as three slices only: `67-01` bounded execution-surface contracts, `67-02` JTBD examples plus docs references, and `67-03` rolling traceability plus truthful `v1.16` freeze preparation. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-PATTERNS.md] [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]

## Recommended Plan Slices

1. **Slice 67-01: Bounded execution-surface contracts.** Add OPSUI-local contract tests for the exact stable surface already chosen in context: run-state presence, `Run finished` prefix, `Cancel run`, `Copy diagnostics`, failure-panel selector, and `RunFailure`/`DocResolver` shape checks. Keep `mix verify.opsui` orchestration-only. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] [VERIFIED: lib/mix/tasks/verify.opsui.ex]
2. **Slice 67-02: JTBD fixtures and docs alignment.** Replace or demote `search_minimal.json` and `search_many_minimal.json` as primary shipped examples, create two narrative fixtures under `scrypath_ops/examples/playbooks/`, validate them through `mix scrypath_ops.playbooks.validate examples/playbooks`, and reference those exact filenames from operator or contributor docs. [VERIFIED: scrypath_ops/examples/playbooks/search_minimal.json] [VERIFIED: scrypath_ops/examples/playbooks/search_many_minimal.json] [VERIFIED: scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex] [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]
3. **Slice 67-03: Traceability and milestone freeze.** Update rolling `ROADMAP`, `REQUIREMENTS`, `PROJECT`, and `STATE` when Phase 67 lands, create the `v1.16-*` trio using the v1.15 archive pattern, and leave `.planning/MILESTONES.md`, `mix.exs`, and release narrative untouched unless the same change genuinely closes the milestone. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/milestones/v1.15-ROADMAP.md] [VERIFIED: .planning/milestones/v1.15-REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Playbook execution UI contract | Frontend Server (SSR) | API / Backend | `PlaybookLive` owns the rendered lifecycle and async event flow, while `Runner` remains the raw result/error seam underneath it. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Failure-doc resolution contract | API / Backend | CDN / Static | `RunFailure` and `DocResolver` generate machine-readable failure metadata, but the truth they point at is markdown content and anchors on disk. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] |
| Shipped example-fixture truth | CDN / Static | Frontend Server (SSR) | The examples are static JSON artifacts that docs and OPSUI catalog flows should reference consistently. [VERIFIED: scrypath_ops/examples/playbooks/search_minimal.json] [VERIFIED: scrypath_ops/examples/playbooks/search_many_minimal.json] [VERIFIED: scrypath_ops/docs/team-playbook-persistence.md] |
| Rolling traceability and milestone freeze | CDN / Static | — | The close discipline is carried in planning markdown, not runtime code, and prior milestones preserve a clear active-vs-archived split. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/milestones/v1.15-ROADMAP.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | Runtime available: `1.19.5`; project floor `~> 1.17`. [VERIFIED: local command elixir -v] [VERIFIED: mix.exs] [VERIFIED: scrypath_ops/mix.exs] | Primary language and test runner host for both root and OPSUI phases. [VERIFIED: mix.exs] [VERIFIED: scrypath_ops/mix.exs] | Phase 67 is entirely inside existing Elixir/Mix workflows; no new tooling stack is needed. [VERIFIED: lib/mix/tasks/verify.opsui.ex] |
| Phoenix LiveView | `~> 1.1.0` in `scrypath_ops`. [VERIFIED: scrypath_ops/mix.exs] | Existing async lifecycle and LiveView test surface for bounded execution contracts. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] | `start_async/3`, `handle_async/3`, `cancel_async/3`, and `render_async/2` are the official primitives already used by the current run flow and test style. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| ExUnit | Bundled with Elixir; current suites live at root and under `scrypath_ops/test/`. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] | Contract, docs, and fixture validation. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs] | The repository already uses ExUnit for docs contracts, LiveView integration, and Mix-task validation; planner should extend that pattern instead of adding a snapshot or browser-only framework. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Mix.Tasks.Verify.Opsui` | Repo-local task. [VERIFIED: lib/mix/tasks/verify.opsui.ex] | Umbrella execution entrypoint for OPSUI verification from repo root. [VERIFIED: lib/mix/tasks/verify.opsui.ex] | Use as the outer command only; keep contract intelligence inside tests. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] |
| `ScrypathOps.Playbook.DocResolver` | Repo-local module. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] | Central map from failure doc refs to path/fragment targets. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] | Use whenever OPSUI or tests need stable doc-link semantics. Do not duplicate path construction in templates or tests. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] |
| `Mix.Tasks.ScrypathOps.Playbooks.Validate` + `ScrypathOps.Playbook.V1` | Repo-local task and validator. [VERIFIED: scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/v1.ex] | Cheap no-backend validation for shipped JSON fixtures. [VERIFIED: scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex] | Use for canonical example directories and fixture-contract tests; do not create a second fixture parser. [VERIFIED: scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Bounded ExUnit contract tests. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] | Full HTML snapshots. [ASSUMED] | Snapshot coverage would freeze too much copy and violates D-04/D-05; current repo style is behavioral/contracts, not snapshots. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] [VERIFIED: test/scrypath/docs_contract_test.exs] |
| JTBD-named shipped examples. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] | Keep only `search_minimal.json` and `search_many_minimal.json`. [VERIFIED: scrypath_ops/examples/playbooks/search_minimal.json] [VERIFIED: scrypath_ops/examples/playbooks/search_many_minimal.json] | Minimal envelopes validate the schema but do not satisfy the docs-aligned operator-job requirement in OPS3-05. [VERIFIED: .planning/REQUIREMENTS.md] |
| Truthful archive preparation with no release claim. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] | Update `mix.exs`, `CHANGELOG.md`, or `.planning/MILESTONES.md` preemptively. [VERIFIED: mix.exs] [VERIFIED: .planning/MILESTONES.md] | That would collapse the repo’s current distinction between active planning close and actual Hex release truth. [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md] |

**Installation:**
```bash
mix deps.get
cd scrypath_ops && mix deps.get
```

No new dependencies are recommended for this phase. [VERIFIED: mix.exs] [VERIFIED: scrypath_ops/mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer edits UI/docs/examples/planning files
  -> root docs_contract_test.exs
    -> verifies README/CONTRIBUTING/verify text and exact example filenames
  -> scrypath_ops contract tests
    -> PlaybookLive bounded UI phrases/selectors
    -> DocResolver path+fragment mapping
    -> on-disk anchor existence in markdown docs
    -> examples/playbooks validation and doc references
  -> mix verify.opsui
    -> cd scrypath_ops
    -> mix deps.get
    -> mix test
  -> milestone close slice
    -> update rolling ROADMAP/REQUIREMENTS/PROJECT/STATE
    -> write milestones/v1.16-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md
    -> update MILESTONES.md only if v1.16 is actually closed
```

The existing runtime execution path remains unchanged: operator action enters `PlaybookLive`, async execution runs through `Runner.run_validated/3`, failures are enriched by `RunFailure`, and docs links are resolved by `DocResolver`. Phase 67 should verify that path, not rewrite it. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex]

### Recommended Project Structure

```text
test/
└── scrypath/
    └── docs_contract_test.exs          # Root maintainer-facing docs and command truth

scrypath_ops/test/
├── scrypath_ops_web/live/              # LiveView bounded execution contract tests
├── scrypath_ops/playbook/              # DocResolver and fixture contract tests
└── scrypath_ops/mix/                   # playbooks.validate task coverage

scrypath_ops/examples/playbooks/        # Canonical JTBD fixtures referenced by docs
.planning/milestones/                   # Frozen milestone snapshots once close is truthful
```

This structure matches the current repo split between root maintainer docs contracts and OPSUI-local behavior tests. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] [VERIFIED: scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs]

### Pattern 1: Layered contract tests, not parser logic in `mix verify.opsui`

**What:** Keep `mix verify.opsui` as orchestration and place all execution-surface contracts in ExUnit modules close to the OPSUI code. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]  
**When to use:** Any assertion about execution UI phrases, doc-ref mappings, or shipped fixture names. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]  
**Example:**
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#start_async/3
def mount(%{"id" => id}, _, socket) do
  {:ok, socket |> start_async(:my_task, fn -> fetch_org!(id) end)}
end

def handle_async(:my_task, {:ok, result}, socket) do
  {:noreply, assign(socket, :result, result)}
end

def handle_async(:my_task, {:exit, reason}, socket) do
  {:noreply, assign(socket, :error, reason)}
end
```

### Pattern 2: Event-driven async assertions with `render_async/2`

**What:** Exercise LiveView async flows with event calls and await completion using `render_async/2` instead of sleeping or snapshotting. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]  
**When to use:** `run`, `run_now`, supersede, cancel, and failure-panel contract coverage. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs]  
**Example:**
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html#render_async/2
render_click(view, "run", %{})
assert render_async(view) =~ "Run finished"
```

### Pattern 3: Freeze relative doc targets plus on-disk anchors

**What:** Assert `DocResolver` returns the correct repo-relative path+fragment targets and separately prove those anchors exist in markdown files on disk. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex]  
**When to use:** Any Phase 67 docs-link contract. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]  
**Example:** The current forced-failure test hard-codes absolute GitHub URLs; Phase 67 should move that assertion to relative path/fragment plus anchor existence because `DocResolver` already has a configurable base URL. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex]

### Anti-Patterns to Avoid

- **Parsing contract rules inside `mix verify.opsui`:** The task is intentionally a shell wrapper around `scrypath_ops` tests, and D-01 says it must remain an umbrella entrypoint only. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]
- **Freezing all PlaybookLive prose:** The current context explicitly keeps helper text and non-contract copy flexible. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]
- **Hard-coding absolute docs URLs in tests:** `DocResolver` has a configurable base URL, so absolute URL assertions are unnecessarily brittle. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs]
- **Treating minimal schema examples as canonical operator examples:** OPS3-05 requires named JTBD fixtures aligned with docs. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: scrypath_ops/examples/playbooks/search_minimal.json] [VERIFIED: scrypath_ops/examples/playbooks/search_many_minimal.json]
- **Claiming milestone close before archives and traceability are real:** v1.15 archives and `MILESTONES.md` show the repo preserves a strict active-vs-archived distinction. [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/milestones/v1.15-ROADMAP.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Execution-surface contract registry | A custom manifest file for phrases, selectors, anchors, and fixtures. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] | Small ExUnit modules in `scrypath_ops/test/` plus root docs contracts. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] | The context explicitly defers a centralized manifest, and the repo already validates similar truth via focused tests. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] |
| UI doc-link construction | Inline URL strings in templates or tests. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] | `ScrypathOps.Playbook.DocResolver`. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] | Base URL is configurable, and the resolver already owns path/fragment mapping. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] |
| Fixture validation | Ad hoc JSON parsing or hand-maintained schema comments. [VERIFIED: scrypath_ops/test/fixtures/playbooks/README.md] | `mix scrypath_ops.playbooks.validate` backed by `ScrypathOps.Playbook.V1.validate/1`. [VERIFIED: scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex] [VERIFIED: scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs] | The task already gives a cheap no-backend validation path and matches contributor docs. [VERIFIED: CONTRIBUTING.md] [VERIFIED: scrypath_ops/docs/team-playbook-persistence.md] |

**Key insight:** The codebase already has the right seams; Phase 67 should increase coverage density around them instead of introducing new abstractions. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/runner.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex]

## Common Pitfalls

### Pitfall 1: Resolver points at anchors the docs do not define

**What goes wrong:** `DocResolver` currently maps `playbook_schema_invalid_entries` and `playbook_schema_invalid_entry_shape`, but `playbook-schema-v1.md` only exposes troubleshooting headings for `no_schema`, `invalid_query`, and `page_size_out_of_range`. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] [VERIFIED: scrypath_ops/docs/playbook-schema-v1.md]  
**Why it happens:** Phase 65 added more reason mappings than the markdown troubleshooting section currently names. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex] [VERIFIED: scrypath_ops/docs/playbook-schema-v1.md]  
**How to avoid:** Make the Phase 67 `DocResolver` contract test check every mapped path/fragment against on-disk markdown anchors, then either add the missing troubleshooting sections or remap those reasons truthfully. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]  
**Warning signs:** A resolver test passes path construction but a docs grep cannot find the fragment heading. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] [VERIFIED: scrypath_ops/docs/playbook-schema-v1.md]

### Pitfall 2: Absolute GitHub URL assertions make base-URL configuration useless

**What goes wrong:** The current forced-failure LiveView test asserts full GitHub URLs, even though `DocResolver` composes them from a configurable base. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex]  
**Why it happens:** The first failure-panel regression was written as a simple end-to-end proof, not as a configurable contract. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs]  
**How to avoid:** Assert relative path+fragment in a resolver test and keep the LiveView test focused on affordances and presence of links, not the exact absolute host prefix. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]  
**Warning signs:** A harmless docs-host or branch-base change breaks OPSUI tests without any operator-facing regression. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex]

### Pitfall 3: Example fixtures stay schema-valid but doc-useless

**What goes wrong:** `search_minimal.json` and `search_many_minimal.json` are valid, but no maintainer or operator docs currently name any canonical example filenames. [VERIFIED: scrypath_ops/examples/playbooks/search_minimal.json] [VERIFIED: scrypath_ops/examples/playbooks/search_many_minimal.json] [VERIFIED: local command rg -n "search_minimal\\.json|search_many_minimal\\.json|sync_triage_posts_recent\\.json|federation_inspect_posts_and_comments\\.json" README.md CONTRIBUTING.md scrypath_ops/docs scrypath_ops/README.md]  
**Why it happens:** Phase 63 established examples as a directory and validation path, but not as JTBD narrative examples referenced from docs. [VERIFIED: .planning/milestones/v1.15-REQUIREMENTS.md] [VERIFIED: scrypath_ops/docs/team-playbook-persistence.md]  
**How to avoid:** Update docs and root docs contracts to point at exact canonical filenames and keep the examples small enough for `mix scrypath_ops.playbooks.validate`. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] [VERIFIED: scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex]  
**Warning signs:** Docs talk about examples generically, but a grep for the shipped filenames returns no hits in user-facing docs. [VERIFIED: local command rg -n "search_minimal\\.json|search_many_minimal\\.json|sync_triage_posts_recent\\.json|federation_inspect_posts_and_comments\\.json" README.md CONTRIBUTING.md scrypath_ops/docs scrypath_ops/README.md]

### Pitfall 4: Milestone-close language outruns the actual close

**What goes wrong:** Updating `.planning/MILESTONES.md`, Hex narrative, or archive wording before `v1.16` is actually closed would contradict the repo’s established active-vs-archived discipline. [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]  
**Why it happens:** Phase 67 mixes rolling truth updates with archive preparation, and the two steps are easy to conflate. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]  
**How to avoid:** Treat rolling file updates and frozen archive creation as allowed in this phase, but treat `.planning/MILESTONES.md` and any release language as gated on real close status only. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] [VERIFIED: .planning/milestones/v1.15-ROADMAP.md]  
**Warning signs:** `ROADMAP` still shows `v1.16 in progress` while `MILESTONES.md` or an audit file already implies it shipped. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/MILESTONES.md]

## Code Examples

Verified patterns from official sources and the current codebase:

### Async LiveView contract pattern

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#start_async/3
def mount(%{"id" => id}, _, socket) do
  {:ok, socket |> start_async(:my_task, fn -> fetch_org!(id) end)}
end

def handle_async(:my_task, {:ok, fetched}, socket) do
  {:noreply, assign(socket, :result, fetched)}
end

def handle_async(:my_task, {:exit, reason}, socket) do
  {:noreply, assign(socket, :error, reason)}
end
```

### Awaiting current async work in LiveView tests

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html#render_async/2
render_click(view, "run", %{})
assert render_async(view) =~ "Run finished"
```

### Current repo pattern for bounded success summary

```elixir
# Source: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
defp run_result_summary(%SearchResult{} = r), do: "Run finished — hits: #{length(r.hits)}"

defp run_result_summary(%MultiSearchResult{} = r),
  do: "Run finished — #{length(r.ordered)} schema(s)."
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Sleep-based or snapshot-heavy UI verification. [ASSUMED] | Phoenix LiveView provides event-driven async testing through `render_async/2`, and this repo already uses event-driven `render_click` plus `render_async`. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] | Available in current LiveView docs and already adopted in ScrypathOps by 2026-04-22. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] | Phase 67 should continue the event-driven style instead of broad snapshots. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] |
| Treat example JSON as validator smoke only. [VERIFIED: scrypath_ops/examples/playbooks/search_minimal.json] [VERIFIED: scrypath_ops/examples/playbooks/search_many_minimal.json] | Treat shipped examples as doc-referenced JTBD fixtures that still pass the same validator. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex] | Required by OPS3-05 in v1.16. [VERIFIED: .planning/REQUIREMENTS.md] | Examples become part of the contributor/operator contract rather than just incidental sample files. [VERIFIED: .planning/REQUIREMENTS.md] |
| Manual milestone close with truthful archive wording and explicit non-release notes. [VERIFIED: .planning/milestones/v1.15-ROADMAP.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md] | Same pattern should continue for v1.16 unless a real release is also happening. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] | Established at least through v1.15. [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/milestones/v1.15-ROADMAP.md] | Planner should not invent a new release/bookkeeping coupling for Phase 67. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] |

**Deprecated/outdated:**

- Full absolute-URL assertions for OPSUI docs links are outdated for this phase because they ignore `DocResolver` base configurability. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex]
- Treating `search_minimal.json` and `search_many_minimal.json` as the primary shipped examples is outdated once OPS3-05 lands. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: scrypath_ops/examples/playbooks/search_minimal.json] [VERIFIED: scrypath_ops/examples/playbooks/search_many_minimal.json]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Snapshot-heavy UI verification is an "old approach" worth avoiding. [ASSUMED] | State of the Art | Low; planner guidance still stands because the repo and context already prefer bounded behavioral contracts. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] |

## Open Questions (RESOLVED)

1. **Resolved: retain the current minimal example filenames as secondary schema-only examples.**
   - Decision: `search_minimal.json` and `search_many_minimal.json` remain on disk as low-level wire-format examples, but they are no longer treated as the canonical shipped examples for docs or contract tests. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]
   - Why: The context explicitly allows retention as secondary examples, and `playbook-schema-v1.md` remains the right place for structural reference while OPS3-05 requires two JTBD fixtures to become canonical. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] [VERIFIED: scrypath_ops/docs/playbook-schema-v1.md]

2. **Resolved: Phase 67 planning uses a conditional close path for `v1.16`.**
   - Decision: The execution plan prepares the truthful `v1.16-*` archive trio and updates rolling traceability in all cases, but `.planning/MILESTONES.md` is updated only if the same change objectively closes `v1.16` with matching evidence. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]
   - Why: The active milestone is still `v1.16`, `.planning/MILESTONES.md` is historical-only, and D-19 forbids promoting an active milestone into history before the close is real. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Root docs contracts and Mix tasks. [VERIFIED: test/scrypath/docs_contract_test.exs] | ✓ [VERIFIED: local command elixir -v] | `1.19.5`. [VERIFIED: local command elixir -v] | — |
| Mix | `mix verify.opsui`, root `mix test`, and `mix scrypath_ops.playbooks.validate`. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex] | ✓ [VERIFIED: local command mix --version] | `1.19.5`. [VERIFIED: local command mix --version] | — |
| PostgreSQL server | `scrypath_ops` test alias runs `ecto.create`, `ecto.migrate`, then `test`, and `verify.opsui` shells into `mix test` under `scrypath_ops`. [VERIFIED: scrypath_ops/mix.exs] [VERIFIED: lib/mix/tasks/verify.opsui.ex] | ✗ local listener response not detected. [VERIFIED: local command pg_isready] | Client `psql 14.17`; server unavailable on `/tmp:5432` at research time. [VERIFIED: local command psql --version] [VERIFIED: local command pg_isready] | Root docs-contract tests and some pure unit tests can still run without DB, but full `mix verify.opsui` has no real fallback. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: scrypath_ops/mix.exs] |

**Missing dependencies with no fallback:**

- A responding PostgreSQL service for full local `mix verify.opsui`. [VERIFIED: local command pg_isready] [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: scrypath_ops/mix.exs]

**Missing dependencies with fallback:**

- None for the full OPSUI suite; limited docs/unit coverage remains runnable without Postgres. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit under root and `scrypath_ops`, with Phoenix LiveViewTest for OPSUI. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] |
| Config file | Root `mix.exs` and `scrypath_ops/mix.exs` aliases control test entrypoints; no separate `pytest`-style config file exists. [VERIFIED: mix.exs] [VERIFIED: scrypath_ops/mix.exs] |
| Quick run command | `mix test test/scrypath/docs_contract_test.exs -x` for root docs contracts, and `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs -x` for targeted OPSUI flows. [VERIFIED: mix.exs] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] |
| Full suite command | `mix verify.opsui` plus the relevant root docs contract slice. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: test/scrypath/docs_contract_test.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPS3-04 | Bounded execution UI strings/selectors and maintainer docs commands stay aligned. [VERIFIED: .planning/REQUIREMENTS.md] | LiveView + docs contract | `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs -x` and `mix test test/scrypath/docs_contract_test.exs -x` | Existing files exist, but new contract modules are still needed. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] [VERIFIED: test/scrypath/docs_contract_test.exs] |
| OPS3-04 | DocResolver path/fragment targets and anchor existence stay aligned. [VERIFIED: .planning/REQUIREMENTS.md] | Unit/contract | `mix test scrypath_ops/test/scrypath_ops/playbook/doc_resolver_test.exs -x` | ❌ Wave 0. No such test exists yet. [VERIFIED: local command find scrypath_ops/test -maxdepth 3 -type f | sort | rg 'playbook|doc_resolver|fixture|contract'] |
| OPS3-05 | Canonical JTBD fixtures validate and are referenced from docs. [VERIFIED: .planning/REQUIREMENTS.md] | Mix-task + docs contract | `cd scrypath_ops && mix scrypath_ops.playbooks.validate examples/playbooks` and `mix test test/scrypath/docs_contract_test.exs -x` | Validator coverage exists; filename-reference coverage does not. [VERIFIED: scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs] [VERIFIED: test/scrypath/docs_contract_test.exs] |
| OPS3-06 | Rolling traceability and archive trio reflect truthful close language. [VERIFIED: .planning/REQUIREMENTS.md] | Manual file audit + narrow contract grep | `rg -n "OPS3-0[4-6]|v1\\.16|Hex" .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/PROJECT.md .planning/STATE.md .planning/MILESTONES.md` | Partial; no `v1.16-*` files exist yet. [VERIFIED: local command ls -1 .planning/milestones | sort | rg '^v1\\.16-'] |

### Sampling Rate

- **Per task commit:** Run the narrow file-level tests touched by the slice. [VERIFIED: mix.exs] [VERIFIED: scrypath_ops/mix.exs]
- **Per wave merge:** Run `mix verify.opsui` and the relevant root docs-contract slice. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: test/scrypath/docs_contract_test.exs]
- **Phase gate:** `mix verify.opsui` plus root docs-contract coverage for contributor/example-name truth should be green before `/gsd-verify-work`. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]

### Wave 0 Gaps

- [ ] `scrypath_ops/test/scrypath_ops/playbook/doc_resolver_test.exs` — path/fragment mapping plus on-disk anchor existence for every resolver entry used by `RunFailure`. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex]
- [ ] `scrypath_ops/test/scrypath_ops/playbook/examples_contract_test.exs` or equivalent — asserts the canonical shipped example filenames validate and are referenced from docs. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]
- [ ] Root `test/scrypath/docs_contract_test.exs` additions — exact example filenames and `mix scrypath_ops.playbooks.validate examples/playbooks` command path. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] [VERIFIED: test/scrypath/docs_contract_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no for this phase’s code changes. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] | Existing `/ops` auth guidance stays in `operator-ia.md` and `docs/SECURITY.md`; Phase 67 does not widen auth behavior. [VERIFIED: scrypath_ops/docs/operator-ia.md] [VERIFIED: scrypath_ops/README.md] |
| V3 Session Management | no for this phase’s primary scope. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] | No new session mechanics are planned; maintain current LiveView/session boundary. [VERIFIED: scrypath_ops/docs/operator-ia.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |
| V4 Access Control | no direct access-control changes. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] | Keep `/ops` authorization host-owned and avoid implying broader guarantees in docs. [VERIFIED: scrypath_ops/docs/operator-ia.md] |
| V5 Input Validation | yes. [VERIFIED: scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex] | `ScrypathOps.Playbook.V1.validate/1` remains the canonical validator for shipped fixture JSON. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/v1.ex] |
| V6 Cryptography | no. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] | No crypto primitives are introduced; phase scope is verification/docs/bookkeeping only. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Documentation links point to wrong or missing remediation guidance. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] [VERIFIED: scrypath_ops/docs/playbook-schema-v1.md] | Tampering | Contract-test resolver targets and anchor existence on disk. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] |
| Shipped playbook examples encourage secrets or backend-specific settings. [VERIFIED: scrypath_ops/docs/playbook-schema-v1.md] | Information Disclosure | Keep examples small, validator-friendly, and aligned with the schema doc’s banned-key guidance. [VERIFIED: scrypath_ops/docs/playbook-schema-v1.md] [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] |
| Planning artifacts imply a release or close that did not occur. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/MILESTONES.md] | Repudiation | Preserve the repo’s current separation between active milestone truth, archived milestone truth, and Hex release truth. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md] [VERIFIED: .planning/milestones/v1.15-ROADMAP.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md` - locked decisions, discretion, and bookkeeping boundaries. [VERIFIED: .planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md]
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/MILESTONES.md` - active milestone truth and close expectations. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/MILESTONES.md]
- `.planning/milestones/v1.15-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md` - archive format and wording discipline for the most recent comparable close. [VERIFIED: .planning/milestones/v1.15-ROADMAP.md] [VERIFIED: .planning/milestones/v1.15-REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.15-MILESTONE-AUDIT.md]
- `lib/mix/tasks/verify.opsui.ex`, `test/scrypath/docs_contract_test.exs`, `scrypath_ops/lib/...`, and `scrypath_ops/test/...` - current verification surface and gaps. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs]
- Phoenix LiveView official docs - async lifecycle, `cancel_async/3`, and `render_async/2`. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]

### Secondary (MEDIUM confidence)

- None. All material recommendations were derived from the codebase or official Phoenix docs. [VERIFIED: test/scrypath/docs_contract_test.exs] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Tertiary (LOW confidence)

- None beyond the single explicit assumption logged in the State of the Art section. [VERIFIED: /Users/jon/projects/scrypath/.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-RESEARCH.md]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - the phase stays entirely inside the repo’s current Elixir/Phoenix/ExUnit stack. [VERIFIED: mix.exs] [VERIFIED: scrypath_ops/mix.exs]
- Architecture: HIGH - the relevant seams already exist in `PlaybookLive`, `RunFailure`, `DocResolver`, and the existing docs/test split. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] [VERIFIED: test/scrypath/docs_contract_test.exs]
- Pitfalls: HIGH - the current codebase already exposes the main drift points, especially resolver anchors, absolute URL assertions, generic examples, and close-language risks. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex] [VERIFIED: scrypath_ops/docs/playbook-schema-v1.md] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs] [VERIFIED: .planning/MILESTONES.md]

**Research date:** 2026-04-22  
**Valid until:** 2026-04-29 because milestone truth and phase status are fast-moving. [VERIFIED: .planning/STATE.md]
