# Phase 14: Mix Tasks and Guides - Research

**Researched:** 2026-04-16 [VERIFIED: current workspace date + user prompt]  
**Domain:** Thin Mix task ergonomics and versioned operational guides on top of the existing Scrypath operator APIs, without widening the common search contract. [VERIFIED: `.planning/ROADMAP.md` + `.planning/REQUIREMENTS.md` + `.planning/STATE.md` + `README.md`]  
**Confidence:** HIGH [VERIFIED: the repo already contains the Phase 13 operator APIs and docs contract scaffolding; remaining uncertainty is mostly naming and doc layout, not architecture]

## User Constraints

No `14-CONTEXT.md` exists for this phase, so the effective constraints below are derived from the roadmap, requirements, state, and project instructions rather than copied from a phase context file. [VERIFIED: `node /Users/jon/.codex/get-shit-done/bin/gsd-tools.cjs init phase-op 14` + `.planning/ROADMAP.md` + `.planning/REQUIREMENTS.md` + `.planning/STATE.md` + `AGENTS.md`]

### Locked Decisions

- Phase 14 owns thin Mix task ergonomics and explicit operational guides; it does not own the underlying operator primitives. [VERIFIED: `.planning/ROADMAP.md` + `.planning/STATE.md`]
- The public common path remains `Scrypath.*`, and backend-native Meilisearch power remains namespaced under `Scrypath.Meilisearch.*`. [VERIFIED: `.planning/REQUIREMENTS.md` + `README.md` + `lib/scrypath.ex` + `lib/scrypath/meilisearch.ex`]
- v1.2 continues to support `:inline`, `:oban`, and `:manual` sync modes and must explain their operational tradeoffs plainly. [VERIFIED: `AGENTS.md` + `.planning/REQUIREMENTS.md` + `README.md` + `guides/sync-modes-and-visibility.md`]
- The CLI must stay thin and must not become a second product surface that bypasses Scrypath-owned APIs. [VERIFIED: `.planning/ROADMAP.md` + `.planning/STATE.md` + `README.md`]
- Maintainer-facing documentation must connect the operator surface to the release contract for early production support. [VERIFIED: `.planning/ROADMAP.md` + `docs/releasing.md` + `test/scrypath/docs_contract_test.exs`]

### Claude's Discretion

- Exact `mix scrypath.*` task names and whether Phase 14 ships four or five focused tasks are not locked by upstream artifacts. [VERIFIED: `.planning/ROADMAP.md` uses `mix scrypath.*` generically and does not enumerate exact names]
- The guide layout is open so long as it gives first-class coverage to inline, Oban, and manual workflows and keeps maintainers oriented. [VERIFIED: `OPS-04` in `.planning/REQUIREMENTS.md` + `.planning/ROADMAP.md`]
- The verification shape for this phase is open, but the repo already favors one phase-specific Mix verifier plus docs-contract coverage. [VERIFIED: `lib/mix/tasks/verify.phase10.ex` + `lib/mix/tasks/verify.phase11.ex` + `lib/mix/tasks/verify.phase13.ex`]

### Deferred Ideas (OUT OF SCOPE)

- No second public backend belongs in this phase. [VERIFIED: `.planning/REQUIREMENTS.md` + `.planning/STATE.md`]
- No universal advanced search DSL belongs in this phase. [VERIFIED: `.planning/REQUIREMENTS.md`]
- No built-in dashboard or Phoenix-only operator UI belongs in this phase. [VERIFIED: `.planning/REQUIREMENTS.md`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-04 | Operator can understand sync-mode-specific operational behavior from first-class guides covering inline, Oban, and manual workflows. [VERIFIED: `.planning/REQUIREMENTS.md`] | Extend the current operations docs into a versioned guide set that explains mode semantics, failure visibility, recovery choices, and example operator commands for each mode. [VERIFIED: `README.md` + `guides/sync-modes-and-visibility.md` + `docs/releasing.md`][CITED: https://hexdocs.pm/ex_doc/ExDoc.html][CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| SEAM-03 | Backend-native search power remains clearly namespaced and does not widen the common `Scrypath.search/3` contract in this milestone. [VERIFIED: `.planning/REQUIREMENTS.md`] | Keep Mix tasks delegating only to `Scrypath.*` operator APIs, and lock docs/tests so backend-native search examples continue to live under `Scrypath.Meilisearch.*` instead of new common-path options. [VERIFIED: `README.md` + `lib/scrypath.ex` + `lib/scrypath/meilisearch.ex` + `test/scrypath/docs_contract_test.exs`] |
</phase_requirements>

## Summary

Phase 13 already shipped the real operator surface: `Scrypath.sync_status/2`, `Scrypath.failed_sync_work/2`, `Scrypath.retry_sync_work/2`, and `Scrypath.reconcile_sync/2` all exist in the root API and project state, and their focused tests are green in the current workspace. [VERIFIED: `lib/scrypath.ex` + `lib/scrypath/operator.ex` + `test/scrypath/operator/status_test.exs` + `test/scrypath/operator/failed_work_test.exs` + `test/scrypath/operator/reconcile_test.exs` + local `mix test ...` run on 2026-04-16] That means Phase 14 should not invent new operator semantics. It should add a thin CLI skin and durable HexDocs guidance around semantics that already exist. [VERIFIED: `.planning/ROADMAP.md` + `.planning/STATE.md` + `README.md`]

The repo also already has the two structural pieces this phase should reuse: a stable ExDoc extras layout in `mix.exs`, and a docs-contract test suite that guards release and operator wording. [VERIFIED: `mix.exs` + `test/release/package_metadata_test.exs` + `test/scrypath/docs_contract_test.exs`] ExDoc supports grouping extras and version-anchored source links, while Hex publishes docs to both a versioned URL and a moving latest URL. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] That makes versioned guides the standard path here, not ad hoc README-only prose. [VERIFIED: `mix.exs` + `docs/releasing.md`][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

The plan should therefore be conservative: add focused `mix scrypath.*` tasks that parse options, call the root operator APIs, and print stable summaries; expand the existing operations docs into a mode-by-mode guide set; and add docs-contract assertions that keep backend-native search power under `Scrypath.Meilisearch.*`. [VERIFIED: `README.md` + `lib/scrypath.ex` + `lib/scrypath/meilisearch.ex` + `test/scrypath/docs_contract_test.exs` + `.planning/ROADMAP.md`]

**Primary recommendation:** Ship one focused task per operator action, backed only by existing `Scrypath.*` verbs, plus one new operator guide and one expanded sync-mode guide, then lock the boundary with a `mix verify.phase14` task and docs-contract tests. [VERIFIED: `lib/mix/tasks/verify.phase10.ex` + `lib/mix/tasks/verify.phase11.ex` + `lib/mix/tasks/verify.phase13.ex` + `mix.exs` + `README.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CLI entrypoints for status, failed work, retry, and reconcile | Mix task layer [VERIFIED: this phase is explicitly about Mix task ergonomics] | Root `Scrypath.*` API [VERIFIED: `lib/scrypath.ex`] | Tasks should parse input and format output, then delegate immediately to existing Scrypath operator APIs. [VERIFIED: `.planning/ROADMAP.md` + `lib/scrypath.ex`][CITED: https://hexdocs.pm/mix/Mix.Task.html] |
| Operator semantics and recovery behavior | Root `Scrypath.*` API [VERIFIED: `lib/scrypath.ex` + `lib/scrypath/operator.ex`] | Internal operator modules [VERIFIED: `lib/scrypath/operator/*.ex`] | Phase 14 should not reimplement operator logic in Mix tasks. [VERIFIED: `.planning/STATE.md` + `.planning/ROADMAP.md`] |
| Queue and backend inspection | Internal adapters [VERIFIED: `lib/scrypath/oban/inspect.ex` + `lib/scrypath/meilisearch/tasks.ex`] | Operator structs [VERIFIED: `lib/scrypath/operator/status.ex` + `lib/scrypath/operator/failed_work.ex`] | Backend and queue raw payloads stay behind the existing seam and are summarized before the CLI sees them. [VERIFIED: `test/scrypath/operator/status_test.exs` + `test/scrypath/operator/failed_work_test.exs`] |
| Sync-mode guidance and maintainer runbooks | ExDoc extras on HexDocs [VERIFIED: `mix.exs` + `docs/releasing.md`] | README wayfinding [VERIFIED: `README.md`] | Versioned operational guidance belongs in grouped extras, with README linking readers to the right guide set. [VERIFIED: `mix.exs` + `README.md`][CITED: https://hexdocs.pm/ex_doc/ExDoc.html][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Backend-native advanced search power | `Scrypath.Meilisearch.*` namespace [VERIFIED: `lib/scrypath/meilisearch.ex` + `README.md`] | Docs contract tests [VERIFIED: `test/scrypath/docs_contract_test.exs`] | SEAM-03 requires keeping Meilisearch-native capability out of `Scrypath.search/3` and out of the operator CLI. [VERIFIED: `.planning/REQUIREMENTS.md` + `README.md`] |

## Project Constraints (from AGENTS.md)

- Keep Scrypath Ecto-first and Phoenix-friendly. [VERIFIED: `AGENTS.md`]
- Keep Meilisearch as the public v1 backend target. [VERIFIED: `AGENTS.md`]
- Preserve the internal adapter seam without promising a public multi-backend abstraction in v1. [VERIFIED: `AGENTS.md`]
- Keep inline, Oban-backed, and manual sync modes intact. [VERIFIED: `AGENTS.md`]
- Keep operational realities explicit in docs and maintainer workflows. [VERIFIED: `AGENTS.md`]
- Do not rush public-facing quality. [VERIFIED: `AGENTS.md`]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Mix `Mix.Task` | `1.19.5` [VERIFIED: local `mix --version` + `https://hexdocs.pm/mix/Mix.Task.html`] | Custom `mix scrypath.*` commands. [CITED: https://hexdocs.pm/mix/Mix.Task.html] | Official Mix tasks map cleanly from `Mix.Tasks.*` modules to dotted command names and are the native Elixir CLI extension point. [CITED: https://hexdocs.pm/mix/Mix.Task.html] |
| Mix CLI config `def cli/0` | `1.19.5` [VERIFIED: local `mix --version` + `https://hexdocs.pm/mix/Mix.Project.html`] | Pin preferred environment for new Phase 14 verifier task(s). [CITED: https://hexdocs.pm/mix/Mix.Project.html] | Current Mix docs place `preferred_envs` in `def cli/0`, which matches the repo’s existing pattern. [VERIFIED: `mix.exs`][CITED: https://hexdocs.pm/mix/Mix.Project.html] |
| ExDoc | `0.40.1`, updated `2026-01-31` [VERIFIED: `mix hex.info ex_doc` + `https://hex.pm/packages/ex_doc`] | Versioned guide publishing, extras grouping, and source-linking. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html][CITED: https://hex.pm/packages/ex_doc] | The repo already uses ExDoc extras/groups, and ExDoc officially supports grouping and searchable extras for guide-heavy docs. [VERIFIED: `mix.exs`][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Existing root operator APIs | workspace head [VERIFIED: `lib/scrypath.ex` + `lib/scrypath/operator.ex`] | Stable programmatic surface behind the CLI. [VERIFIED: `lib/scrypath.ex`] | Phase 14 can stay thin because the operator behaviors already exist and are tested. [VERIFIED: `test/scrypath/operator/*.exs` + local `mix test ...` run] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `OptionParser` | bundled with Elixir `1.19.5` [VERIFIED: local `elixir --version` + current Mix task usage in repo] | Parse task flags and positional args. [VERIFIED: `lib/mix/tasks/verify.phase13.ex`] | Use for small, explicit task surfaces with a handful of flags. [VERIFIED: repo Mix task pattern] |
| Oban | `2.21.1`, updated `2026-03-26` [VERIFIED: `mix hex.info oban` + `https://hex.pm/packages/oban/versions`] | Explain queue-specific visibility and retry semantics in docs and examples. [CITED: https://hex.pm/packages/oban/versions][CITED: https://hexdocs.pm/oban/job_lifecycle.html] | Use only in the Oban-specific task help and guide sections; do not make it a universal operator assumption. [VERIFIED: `.planning/REQUIREMENTS.md` + `README.md`] |
| Req | `0.5.17`, updated `2026-01-05` [VERIFIED: `mix hex.info req` + `https://hex.pm/packages/req/versions`] | No new phase-specific role; included because Scrypath already owns HTTP transport internally. [VERIFIED: `mix.exs` + `README.md`] | Mention only when docs clarify that operators do not add transport dependencies for Mix task use. [VERIFIED: `README.md`] |
| NimbleOptions | `1.1.1`, published `2024-05-25` [VERIFIED: `mix hex.info nimble_options` + `https://hex.pm/packages/nimble_options/versions`] | Reuse existing option-validation discipline if task helpers share config parsing with public runtime options. [VERIFIED: `mix.exs`] | Use only if Phase 14 introduces shared option-normalization helpers; plain `OptionParser` is enough for direct Mix task argv parsing. [VERIFIED: current repo task pattern] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Focused `mix scrypath.status`, `mix scrypath.failed`, `mix scrypath.retry`, `mix scrypath.reconcile` tasks [ASSUMED] | One umbrella task with subcommands [ASSUMED] | Focused tasks fit Mix’s dotted task model and the repo’s current phase-verifier style better; a subcommand shell would add parsing and help complexity for little gain. [CITED: https://hexdocs.pm/mix/Mix.Task.html][VERIFIED: existing repo task shape] |
| ExDoc extras grouped under Operations and Maintainers [VERIFIED: `mix.exs`] | README-only operational docs [ASSUMED] | Hex publishes versioned docs automatically, while README-only guidance is harder to keep version-scoped and navigable. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Keep Meilisearch-native search under `Scrypath.Meilisearch.*` [VERIFIED: `README.md` + `lib/scrypath/meilisearch.ex`] | Add native search flags to `Scrypath.search/3` or the new Mix tasks [ASSUMED] | The alternative would violate SEAM-03 and blur the operator CLI with backend-native search power. [VERIFIED: `.planning/REQUIREMENTS.md`] |

**Installation:** No new runtime dependency is required for Phase 14 if the plan stays on Mix, ExDoc, and the existing operator modules. [VERIFIED: `mix.exs` + `lib/scrypath.ex`]

```bash
mix deps.get
```

**Version verification:** `mix hex.info ex_doc`, `mix hex.info oban`, `mix hex.info req`, and `mix hex.info nimble_options` all resolved successfully in this workspace on 2026-04-16, and Hex package pages confirm `ex_doc 0.40.1` (2026-01-31), `oban 2.21.1` (2026-03-26), `req 0.5.17` (2026-01-05), and `nimble_options 1.1.1` (2024-05-25). [VERIFIED: local `mix hex.info ...` commands + `https://hex.pm/packages/ex_doc` + `https://hex.pm/packages/oban/versions` + `https://hex.pm/packages/req/versions` + `https://hex.pm/packages/nimble_options/versions`]

## Architecture Patterns

### System Architecture Diagram

```text
operator / maintainer
  |
  v
mix scrypath.* task
  | parse argv + validate flags
  v
Scrypath.* operator API
  |  sync_status / failed_sync_work / retry_sync_work / reconcile_sync
  v
Scrypath.Operator.*
  |----> Scrypath.Meilisearch.Tasks ----> Meilisearch task history
  |
  `----> Scrypath.Oban.Inspect ---------> Oban job state (oban mode only)
  |
  v
Scrypath-owned structs
  |
  +--> terminal output for operators
  |
  `--> HexDocs examples and guide snippets

README / guide index
  |
  v
ExDoc extras + groups_for_extras
  |
  v
versioned HexDocs pages published by Hex
```

The primary data flow should always be `argv -> Scrypath.* -> Scrypath-owned struct -> formatted output`. [VERIFIED: `lib/scrypath.ex` + `lib/scrypath/operator/*.ex`] The task layer should never talk directly to Meilisearch clients or Oban jobs. [VERIFIED: Phase 13 API boundary in `lib/scrypath.ex` + `README.md`]

### Recommended Project Structure

```text
lib/
├── mix/tasks/
│   ├── scrypath.status.ex        # thin status command
│   ├── scrypath.failed.ex        # thin failed-work command
│   ├── scrypath.retry.ex         # thin retry command
│   ├── scrypath.reconcile.ex     # thin reconcile command
│   └── verify.phase14.ex         # automated phase verifier
└── scrypath/
    └── cli/                      # optional shared output/argv helpers only if duplication appears

guides/
├── sync-modes-and-visibility.md  # expand with inline / oban / manual operational paths
└── operator-mix-tasks.md         # task-centric operator guide

docs/
└── operator-support.md           # maintainer-facing release + support handoff guide [ASSUMED]

test/
├── scrypath/mix_tasks/           # focused Mix task tests
├── scrypath/docs_contract_test.exs
└── release/package_metadata_test.exs
```

The new `lib/scrypath/cli/` helper area is optional, not mandatory. [ASSUMED] Add it only if multiple tasks need the same output rendering or option normalization. [VERIFIED: repo convention favors small focused modules and avoids premature abstraction in earlier phases]

### Pattern 1: Thin Mix Task Delegates To Root API

**What:** A task should parse only the flags it owns, call one `Scrypath.*` function, and print a stable summary derived from Scrypath-owned structs. [VERIFIED: `lib/scrypath.ex` + `lib/scrypath/operator/status.ex`][CITED: https://hexdocs.pm/mix/Mix.Task.html]

**When to use:** Use for status, failed-work inspection, retry, and reconcile commands. [VERIFIED: `.planning/ROADMAP.md`]

**Example:**

```elixir
# Source: adapted from repo Mix task style + official Mix.Task docs
defmodule Mix.Tasks.Scrypath.Status do
  use Mix.Task

  @shortdoc "Prints Scrypath sync visibility for one schema"
  @moduledoc """
  Shows pending, failed, and last-successful visibility for one searchable schema.
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [sync_mode: :string, index_prefix: :string]
      )

    schema = parse_schema!(args)

    case Scrypath.sync_status(schema, normalize_opts(opts)) do
      {:ok, status} -> Mix.shell().info(render_status(status))
      {:error, reason} -> Mix.raise("scrypath.status failed: #{inspect(reason)}")
    end
  end
end
```

Source basis: repo verifier tasks use `use Mix.Task`, `Mix.Task.run("app.start")`, and `OptionParser.parse/2`; official Mix docs define `Mix.Tasks.*` naming and `run/1` behavior. [VERIFIED: `lib/mix/tasks/verify.phase13.ex`][CITED: https://hexdocs.pm/mix/Mix.Task.html]

### Pattern 2: Versioned Guide Set By User Job, Not By Internal Module

**What:** Keep the public docs organized by operator need: an operator task guide, a sync-mode guide, and a maintainer support guide. [VERIFIED: `.planning/ROADMAP.md` + `mix.exs` + `docs/releasing.md`]

**When to use:** Use when the docs must explain operational tradeoffs and production support flows rather than module internals. [VERIFIED: `OPS-04` + Phase 14 success criteria in `.planning/ROADMAP.md`]

**Example:**

```elixir
# Source: current docs metadata + ExDoc groups support
defp docs do
  [
    extras: [
      "README.md",
      "guides/sync-modes-and-visibility.md",
      "guides/operator-mix-tasks.md",
      "docs/releasing.md",
      "docs/operator-support.md"
    ],
    groups_for_extras: [
      "Getting Started": ["README.md"],
      Operations: [
        "guides/sync-modes-and-visibility.md",
        "guides/operator-mix-tasks.md"
      ],
      Maintainers: ["docs/releasing.md", "docs/operator-support.md"]
    ]
  ]
end
```

ExDoc officially supports `extras` and `groups_for_extras`, including grouped Markdown pages in the sidebar. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

### Pattern 3: Boundary-Locking Docs Contract

**What:** Use docs-contract tests to assert both the operator wording and the Meilisearch namespace boundary. [VERIFIED: `test/scrypath/docs_contract_test.exs`]

**When to use:** Use for README, guides, and package metadata whenever Phase 14 changes public wording or guide topology. [VERIFIED: existing Phase 11 and Phase 13 doc verification strategy]

**Example:**

```elixir
# Source: repo docs-contract pattern
test "docs keep Meilisearch-native search namespaced" do
  assert_contains_all(@readme, [
    "`Scrypath.Meilisearch` for backend-native operations",
    "Use `Scrypath.search/3` for text plus validated",
    "Use `Scrypath.Meilisearch.search/3` when you need native Meilisearch payloads"
  ])

  refute @readme =~ "native_search:"
end
```

This matches the repo’s existing strategy of locking public contracts through text assertions instead of relying on prose review alone. [VERIFIED: `test/scrypath/docs_contract_test.exs`]

### Anti-Patterns to Avoid

- **Direct backend calls in tasks:** Do not let `mix scrypath.*` call `Scrypath.Meilisearch.Client` or inspect raw Oban jobs directly. [VERIFIED: `lib/scrypath.ex` + `lib/scrypath/operator/*.ex`]
- **CLI-only semantics:** Do not add task behavior that exists only in the CLI and has no `Scrypath.*` equivalent. [VERIFIED: `.planning/ROADMAP.md` + `.planning/STATE.md`]
- **Guide sprawl without navigation:** Do not add new Markdown files without wiring them into ExDoc `extras` and `groups_for_extras`. [VERIFIED: `mix.exs`][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
- **Common-path search widening:** Do not add backend-native search options to `Scrypath.search/3` or operator tasks “for convenience.” [VERIFIED: `.planning/REQUIREMENTS.md` + `lib/scrypath/meilisearch.ex`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Task discovery and invocation | custom escript or bespoke CLI router [ASSUMED] | Native `Mix.Task` modules in `lib/mix/tasks/`. [CITED: https://hexdocs.pm/mix/Mix.Task.html] | Mix already gives dotted task naming, `mix help`, and standard invocation semantics. [CITED: https://hexdocs.pm/mix/Mix.Task.html] |
| Guide navigation | custom docs sidebar logic [ASSUMED] | ExDoc `extras` and `groups_for_extras`. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] | ExDoc already supports grouped extras and searchable guide pages. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Published docs routing | ad hoc “latest vs versioned” links [ASSUMED] | Hex’s built-in `mix docs` + `mix hex.publish` docs pipeline and versioned URLs. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | Hex automatically publishes docs to versioned URLs and keeps the package root redirecting to latest. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Operator semantics in CLI | a second state machine or raw payload formatter [VERIFIED: Phase 13 already solved this] | Existing `Scrypath.Operator.Status`, `FailedWork`, and `Reconcile` structs. [VERIFIED: `lib/scrypath/operator/*.ex`] | Reusing the existing structs keeps CLI behavior aligned with the library contract and avoids raw payload leakage. [VERIFIED: `test/scrypath/operator/*.exs`] |

**Key insight:** Phase 14 is a presentation-and-guidance phase. The safest implementation is to reuse Mix for task plumbing, ExDoc for guide publishing, and the Phase 13 operator structs for semantics. [VERIFIED: `lib/scrypath.ex` + `lib/scrypath/operator/*.ex` + `mix.exs`][CITED: https://hexdocs.pm/mix/Mix.Task.html][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

## Common Pitfalls

### Pitfall 1: Letting Mix Tasks Become A Second Operator API

**What goes wrong:** Task modules accumulate real business logic, backend branching, or recovery routing instead of delegating to `Scrypath.*`. [VERIFIED: this is the main risk implied by the Phase 14 goal in `.planning/ROADMAP.md`]
**Why it happens:** CLI code is tempting to extend “just a little” when tasks need formatted output. [ASSUMED]
**How to avoid:** Keep task modules as parse-and-delegate shells, and add helper modules only for formatting, not behavior. [VERIFIED: repo root API already exists in `lib/scrypath.ex`]
**Warning signs:** Task tests need to stub Meilisearch clients or Oban inspectors directly instead of stubbing `Scrypath.*` outputs. [VERIFIED: current operator tests stub at the operator boundary, not at a CLI layer]

### Pitfall 2: Over-Promising Visibility In The Guides

**What goes wrong:** The docs imply a successful task run means search visibility is complete, even in `:manual` or `:oban` mode. [VERIFIED: current docs explicitly reject this wording in `README.md` + `guides/sync-modes-and-visibility.md`]
**Why it happens:** CLI output often defaults to simplistic “success” language. [ASSUMED]
**How to avoid:** Reuse the repo’s current semantic language verbatim: accepted work is not the same thing as search visibility, and `:oban` means durable enqueue accepted. [VERIFIED: `README.md` + `guides/sync-modes-and-visibility.md`]
**Warning signs:** Guide examples say “indexed” after enqueue or backend acceptance without clarifying the mode. [VERIFIED: current docs contract guards against similar drift]

### Pitfall 3: Accidentally Widening Common Search While Adding Help Text

**What goes wrong:** New guides or task help mention Meilisearch-native query power as if it belongs on `Scrypath.search/3`. [VERIFIED: this would violate `SEAM-03` in `.planning/REQUIREMENTS.md`]
**Why it happens:** Operator docs sit near search docs, and native examples are easy to copy into the wrong section. [ASSUMED]
**How to avoid:** Keep all backend-native search examples under `Scrypath.Meilisearch.*` headings and assert that boundary in `docs_contract_test.exs`. [VERIFIED: `README.md` + `lib/scrypath/meilisearch.ex` + `test/scrypath/docs_contract_test.exs`]
**Warning signs:** Any new example introduces generic flags or opts whose only implementation would be Meilisearch-specific. [VERIFIED: common path currently documents only validated filter/sort/page/preload options in `README.md`]

### Pitfall 4: Shipping Guides Without Versioned Navigation

**What goes wrong:** Guide files exist in the repo but are missing from ExDoc extras or package metadata expectations, so HexDocs users cannot reliably find them. [VERIFIED: current docs publishing is driven by `mix.exs` extras]
**Why it happens:** Markdown files are easy to add without updating `mix.exs` or docs tests. [ASSUMED]
**How to avoid:** Update `mix.exs`, `test/release/package_metadata_test.exs`, and `test/scrypath/docs_contract_test.exs` in the same plan. [VERIFIED: Phase 11 and current docs tests already enforce this pattern]
**Warning signs:** `mix docs` succeeds locally but the sidebar or grouped extras are missing the new pages. [VERIFIED: ExDoc grouping is opt-in via config][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

## Code Examples

Verified patterns from repo code and official docs:

### Custom Mix Task Naming

```elixir
# Source: https://hexdocs.pm/mix/Mix.Task.html
defmodule Mix.Tasks.Scrypath.Reconcile do
  use Mix.Task

  @shortdoc "Shows Scrypath drift signals and recommended actions"

  @impl Mix.Task
  def run(args) do
    # ...
  end
end
```

Official Mix maps `Mix.Tasks.Scrypath.Reconcile` to `mix scrypath.reconcile`. [CITED: https://hexdocs.pm/mix/Mix.Task.html]

### Current Repo Verifier Pattern

```elixir
# Source: /Users/jon/projects/scrypath/lib/mix/tasks/verify.phase13.ex
Mix.Task.run("app.start")

{opts, _argv, _invalid} =
  OptionParser.parse(args,
    strict: [skip_integration: :boolean]
  )

Mix.Task.reenable("docs")
Mix.Task.run("docs", ["--warnings-as-errors"])
```

This is the repo’s current, working task pattern and should be reused for `verify.phase14`. [VERIFIED: `lib/mix/tasks/verify.phase13.ex`]

### ExDoc Extras Grouping

```elixir
# Source: https://hexdocs.pm/ex_doc/ExDoc.html
docs: [
  extras: [
    "README.md",
    "guides/operator-mix-tasks.md"
  ],
  groups_for_extras: [
    Operations: ["guides/operator-mix-tasks.md"]
  ]
]
```

ExDoc officially supports grouped extras in the generated sidebar. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Task-specific preferred env configured through deprecated Mix task APIs. [CITED: https://hexdocs.pm/mix/Mix.Task.html] | Configure preferred envs in `def cli/0` using `preferred_envs`. [CITED: https://hexdocs.pm/mix/Mix.Project.html] | Mix docs mark `Mix.Task.preferred_cli_env/1` deprecated in current `1.19.5` docs. [CITED: https://hexdocs.pm/mix/Mix.Task.html] | Phase 14 should keep verifier env wiring in `mix.exs`, matching current repo style. [VERIFIED: `mix.exs`] |
| README-only operational guidance for many OSS libraries. [ASSUMED] | Versioned HexDocs extras with grouped guides and version-anchored source links. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | Current ExDoc/Hex docs as of 2026-04-16. [CITED: same official docs] | Scrypath should keep operator guidance in ExDoc extras so the docs match the published package version. [VERIFIED: `mix.exs` + `docs/releasing.md`] |

**Deprecated/outdated:**

- `Mix.Task.preferred_cli_env/1` as the configuration mechanism is deprecated; configure preferred environments in `mix.exs` instead. [CITED: https://hexdocs.pm/mix/Mix.Task.html][CITED: https://hexdocs.pm/mix/Mix.Project.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The focused task set should likely be `status`, `failed`, `retry`, and `reconcile` rather than a different verb set. | Standard Stack / Architecture Patterns | Low — names can change without affecting the architecture. |
| A2 | A dedicated `docs/operator-support.md` maintainer guide is likely cleaner than folding that content into `docs/releasing.md`. | Recommended Project Structure | Low-Medium — could shift file layout and test expectations. |
| A3 | A small shared `lib/scrypath/cli/` helper area may be useful if task formatting duplicates. | Recommended Project Structure | Low — can be omitted if tasks stay tiny. |
| A4 | A one-task umbrella CLI with subcommands is technically possible but not worth the complexity here. | Alternatives Considered | Low — planner can still choose it, but it is less aligned with current repo style. |

## Open Questions (RESOLVED)

1. **What exact task names should Scrypath expose?**
   - Decision: Ship `mix scrypath.status`, `mix scrypath.failed`, `mix scrypath.retry`, and `mix scrypath.reconcile`. [RESOLVED: `14-01-PLAN.md`]
   - Rationale: These names stay close to the root operator verbs while keeping Mix task names short and readable. [VERIFIED: `lib/scrypath.ex` + `14-01-PLAN.md`]

2. **Should reindex visibility get its own task or stay under `reconcile`?**
   - Decision: Keep reindex visibility under `mix scrypath.reconcile`; do not add a separate reindex-visibility task in Phase 14. [RESOLVED: `14-01-PLAN.md`]
   - Rationale: Reconcile is already the report-first operator surface for drift and rebuild state, and a separate task would widen the CLI without a new root API contract. [VERIFIED: `.planning/ROADMAP.md` + `lib/scrypath.ex` + `14-01-PLAN.md`]

3. **Should the sync-mode content stay in one guide or split into three guides?**
   - Decision: Keep one canonical `guides/sync-modes-and-visibility.md` page with explicit sections for `:inline`, `:oban`, and `:manual`. [RESOLVED: `14-02-PLAN.md`]
   - Rationale: This keeps HexDocs navigation compact while still giving each mode first-class coverage. [VERIFIED: `mix.exs` + `14-02-PLAN.md`]

4. **Does Phase 14 need machine-readable output formats?**
   - Decision: No `--json` or machine-readable output contract in Phase 14; output is explicitly human-readable only. [RESOLVED: `14-01-PLAN.md` + `14-02-PLAN.md`]
   - Rationale: The roadmap asks for thin operator ergonomics, not a second automation surface. Machine-readable output remains follow-up work unless a current requirement demands it. [VERIFIED: `.planning/ROADMAP.md` + `14-01-PLAN.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks, tests, docs | ✓ [VERIFIED: local `elixir --version`] | `1.19.5` [VERIFIED: local `elixir --version`] | — |
| Mix | Custom task execution and verifiers | ✓ [VERIFIED: local `mix --version`] | `1.19.5` [VERIFIED: local `mix --version`] | — |
| Erlang/OTP | Runtime for Mix/Elixir | ✓ [VERIFIED: local `erl ... otp_release`] | `28` [VERIFIED: local `erl ... otp_release`] | — |
| Docker | Optional live verification parity with current release/operator workflows | ✓ [VERIFIED: local `docker --version`] | `29.3.1` [VERIFIED: local `docker --version`] | Skip live backend checks locally. [VERIFIED: current verifier supports `--skip-integration`] |
| `SCRYPATH_MEILISEARCH_URL` env | Optional live Meilisearch verification | ✗ [VERIFIED: local env probe returned empty] | — | Use docs-only and non-integration verification path. [VERIFIED: `lib/mix/tasks/verify.phase13.ex`] |

**Missing dependencies with no fallback:**

- None for planning and local non-integration verification. [VERIFIED: local `mix test ...` and `mix docs --warnings-as-errors` both succeeded on 2026-04-16]

**Missing dependencies with fallback:**

- Live Meilisearch verification input is absent in this workspace, but the repo already supports a non-integration verifier path. [VERIFIED: empty `SCRYPATH_MEILISEARCH_URL` + `lib/mix/tasks/verify.phase13.ex`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix test on Elixir `1.19.5`. [VERIFIED: local `mix help test` + local `mix --version`] |
| Config file | `test/test_helper.exs`. [VERIFIED: repo file listing] |
| Quick run command | `mix test test/scrypath/docs_contract_test.exs test/scrypath/operator/status_test.exs test/scrypath/operator/failed_work_test.exs test/scrypath/operator/reconcile_test.exs` [VERIFIED: local successful run on 2026-04-16] |
| Full suite command | `mix verify.phase14 --skip-integration` [ASSUMED for new phase] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPS-04 | Guides explain inline, Oban, and manual behavior plus recovery tradeoffs. [VERIFIED: requirement text] | docs contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ |
| OPS-04 | `mix scrypath.*` tasks expose thin operator ergonomics for status, failure inspection, retry, and reconcile visibility. [VERIFIED: Phase 14 success criteria in `.planning/ROADMAP.md`] | unit | `mix test test/scrypath/mix_tasks/*_test.exs` [ASSUMED planned path] | ❌ Wave 0 |
| SEAM-03 | Backend-native search remains namespaced outside `Scrypath.search/3` after CLI/docs changes. [VERIFIED: requirement text] | docs contract + API contract | `mix test test/scrypath/docs_contract_test.exs test/scrypath/search_test.exs` [ASSUMED combined gate] | docs ✅ / API ✅ |

### Sampling Rate

- **Per task commit:** `mix test test/scrypath/docs_contract_test.exs test/scrypath/mix_tasks/*_test.exs` [ASSUMED planned quick gate]
- **Per wave merge:** `mix verify.phase14 --skip-integration` [ASSUMED planned full gate]
- **Phase gate:** `mix verify.phase14` with live verification enabled when `SCRYPATH_MEILISEARCH_URL` is available. [ASSUMED planned live gate, aligned with current phase verifier shape]

### Wave 0 Gaps

- [ ] `lib/mix/tasks/verify.phase14.ex` — phase-specific verifier following the existing `verify.phase13` pattern. [VERIFIED: file does not exist in current repo]
- [ ] `test/scrypath/mix_tasks/` task coverage — task parsing, delegation, and output assertions. [VERIFIED: no Mix task test directory currently exists]
- [ ] `test/scrypath/docs_contract_test.exs` expansion — task help text, guide wayfinding, and SEAM-03 wording after docs edits. [VERIFIED: current file does not reference Phase 14 task docs yet]
- [ ] `test/release/package_metadata_test.exs` expansion — any new guide files must be covered in docs metadata expectations. [VERIFIED: current test only asserts current extras]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: Phase 14 is local Mix task/doc work, not an auth feature] | — |
| V3 Session Management | no [VERIFIED: same scope reasoning] | — |
| V4 Access Control | no [VERIFIED: same scope reasoning] | — |
| V5 Input Validation | yes [VERIFIED: Mix tasks accept argv and config inputs] | `OptionParser` for argv parsing plus existing runtime option validation patterns. [VERIFIED: `lib/mix/tasks/verify.phase13.ex` + `mix.exs`] |
| V6 Cryptography | no [VERIFIED: no new crypto surface is implied by Phase 14] | — |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Passing unsanitized task args into shell commands | Tampering | Do not shell out from `mix scrypath.*`; parse args with `OptionParser` and call `Scrypath.*` directly. [VERIFIED: repo verifier tasks already follow direct Mix invocation patterns] |
| Leaking raw backend or queue payloads in terminal output | Information Disclosure | Render only Scrypath-owned structs and summarized fields, matching Phase 13 public structs. [VERIFIED: `lib/scrypath/operator/*.ex` + `test/scrypath/operator/status_test.exs`] |
| Dangerous recovery wording causing accidental writes | Spoofing / Tampering | Keep reconcile report-first and make mutating recovery explicit and opt-in. [VERIFIED: `README.md` + `lib/scrypath/operator/reconcile.ex`] |

## Sources

### Primary (HIGH confidence)

- Repo artifacts: `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `AGENTS.md`, `README.md`, `mix.exs`, `docs/releasing.md`, `guides/sync-modes-and-visibility.md`, `lib/scrypath.ex`, `lib/scrypath/meilisearch.ex`, `lib/scrypath/operator/*.ex`, `lib/mix/tasks/verify.phase13.ex`, `test/scrypath/docs_contract_test.exs`, `test/release/package_metadata_test.exs`, `test/scrypath/operator/*.exs`. [VERIFIED: read directly in this session]
- Mix.Task docs: https://hexdocs.pm/mix/Mix.Task.html [CITED]
- Mix.Project docs: https://hexdocs.pm/mix/Mix.Project.html [CITED]
- ExDoc docs: https://hexdocs.pm/ex_doc/ExDoc.html [CITED]
- Hex publish docs: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html [CITED]
- Elixir writing documentation: https://hexdocs.pm/elixir/writing-documentation.html [CITED]
- Hex package pages: https://hex.pm/packages/ex_doc, https://hex.pm/packages/oban/versions, https://hex.pm/packages/req/versions, https://hex.pm/packages/nimble_options/versions [CITED]

### Secondary (MEDIUM confidence)

- Oban job lifecycle docs: https://hexdocs.pm/oban/job_lifecycle.html [CITED]

### Tertiary (LOW confidence)

- None. [VERIFIED: all recommendations here are grounded in repo evidence or official docs]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - current versions were verified from this workspace and official Hex/HexDocs sources. [VERIFIED: local commands + cited docs]
- Architecture: HIGH - the repo already contains the operator seam, ExDoc layout, and verifier pattern this phase should reuse. [VERIFIED: repo files + green local checks]
- Pitfalls: MEDIUM-HIGH - they are strongly implied by the repo’s explicit boundaries and official Mix/ExDoc behavior, but task naming/output details are still not locked. [VERIFIED: repo evidence + official docs]

**Research date:** 2026-04-16 [VERIFIED: current workspace date]  
**Valid until:** 2026-05-16 for repo-specific planning; re-check Hex package versions and Mix docs if implementation starts materially later. [VERIFIED: date-sensitive sources are Hex package pages and current docs versions]
