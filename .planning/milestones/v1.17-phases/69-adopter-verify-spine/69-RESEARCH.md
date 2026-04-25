# Phase 69: Adopter verify spine - Research

**Researched:** 2026-04-22 [VERIFIED: system date]
**Domain:** Maintainer-facing Elixir Mix verification workflow for adopter-confidence parity [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: local repo audit] [VERIFIED: `mix test test/scrypath/docs_contract_test.exs`] [VERIFIED: `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test`]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Add one durable semantic root task named **`mix verify.adopter`**. Do **not** use **`mix verify.integration`** and do **not** make Phase 69's public outcome another phase-numbered task such as **`mix verify.phase69`**.
- **D-02:** The task name should reflect the maintainer job to be done, not milestone bookkeeping. Phase-numbered tasks remain historical/focused gates; the new command is a long-lived maintainer affordance.
- **D-03:** The task must ship with a real **`@shortdoc`** and **`@moduledoc`** and be surfaced from **README** and **CONTRIBUTING** so the Scrypath-specific noun **`adopter`** does not feel opaque.

### Fast mode contents

- **D-04:** **`mix verify.adopter`** with no flags is the **fast** default. It must stay **auth-free** and **service-free**.
- **D-05:** Fast mode must be stronger than docs contracts alone. It should verify:
  - README / CONTRIBUTING / support guide / example README adopter wayfinding
  - the canonical example proof surface for **`:inline`**, **`:manual`**, and **`:oban`**
  - the documented fast vs live distinction
  - the command-shape contract between docs and CI for the live adopter proof
- **D-06:** Fast mode must **not** run the example app's real service-backed test path. Calling a live-ish example run "fast" would violate least surprise and operational honesty.
- **D-07:** Fast mode should stay narrowly about **adopter truth**. Do **not** turn it into generic repo hygiene by absorbing unrelated release, quality, or operator verification work.

### Live mode shape

- **D-08:** Live verification should be exposed as **`mix verify.adopter --live`**, not as a separate top-level task such as **`mix verify.adopter_live`**.
- **D-09:** Flag-based mode selection is the right fit because this is one maintainer workflow with two explicit depths:
  - **fast** = bounded no-services confidence
  - **live** = real example proof
- **D-10:** **`--live`** must keep the real adopter proof path visible. It should run the example's canonical CI-shaped path:
  - **`cd examples/phoenix_meilisearch`**
  - **`mix deps.get`**
  - **`mix test`**
  with the documented env for the example/integration run.
- **D-11:** **`--live`** must **not** hide behind **`./scripts/smoke.sh`**. That script remains the local convenience harness, not the canonical CI proof path.
- **D-12:** **`--live`** must fail loudly when required env/services are missing. No silent downgrade from live to fast, and no partial-pass ambiguity.

### CI alignment style

- **D-13:** Use a **hybrid parity** model:
  - maintainers learn one root command family
  - CI keeps separate jobs with explicit service boundaries
  - CI uses the same command family where appropriate
- **D-14:** The non-service adopter gate should call **`mix verify.adopter`** (or **`mix verify.adopter --fast`** if an explicit flag is added for clarity).
- **D-15:** The service-backed adopter job should call **`mix verify.adopter --live`** while still relying on GitHub Actions for service provisioning, env setup, and job isolation.
- **D-16:** The Mix task should stay **orchestration-only**. Do **not** move service boot, readiness waits, or broader CI workflow logic into the task itself.
- **D-17:** Contract tests should pin the mapping between:
  - README / CONTRIBUTING guidance
  - the adopter verify task help and mode wording
  - the example README's canonical live path
  - the CI job that runs the live adopter proof

### Ecosystem and DX stance

- **D-18:** Follow the Elixir ecosystem pattern of **semantic durable tasks** for long-lived maintainer workflows, similar to Phoenix / Ecto / Oban command naming, instead of exposing milestone IDs as the public interface.
- **D-19:** Keep the contributor experience aligned with the repo's existing strengths:
  - one obvious root command for the common path
  - heavier live proof as an explicit opt-in
  - clear task help
  - no hidden service assumptions
- **D-20:** Preserve Scrypath's broader product posture of **operational honesty**:
  - passing fast mode does **not** mean live search behavior was proven
  - live mode is the defended proof for the real Phoenix + Postgres + Meilisearch path

### the agent's Discretion

- Whether fast mode needs its own focused ExUnit file or should extend **`test/scrypath/docs_contract_test.exs`** plus a small supporting maintainer-facing test.
- Whether to support an explicit **`--fast`** flag in addition to the default no-flag path, provided the default remains fast.
- Exact wording and output formatting of the Mix task help text, provided it clearly states what fast mode proves, what live mode proves, and what prerequisites live mode requires.

### Deferred Ideas (OUT OF SCOPE)
- Unifying every root/service-backed verify story in the repo behind one giant command — out of scope and likely harmful.
- Broader cleanup or retirement of older **`mix verify.phase*`** tasks beyond what Phase 69 needs for the new maintainer path.
- Extending the adopter verify spine into OPSUI, release, or unrelated Meilisearch smoke coverage.
- Heavy browser/E2E or additional service-backed verification breadth — remains outside this phase unless Phase 70 evidence says otherwise.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INTG-02 | Maintainers can run one root-level adopter-confidence command (fast by default, live when requested) that proves the example, docs, and support claims still agree without hunting across unrelated `mix verify.*` tasks. | Implement one semantic `mix verify.adopter` task with strict flag parsing, keep fast mode auth-free/service-free, route live mode to the exact example `mix deps.get && mix test` path, and pin README/CONTRIBUTING/example README/CI wording with bounded contract tests. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: examples/phoenix_meilisearch/README.md] [VERIFIED: .github/workflows/ci.yml] |
</phase_requirements>

## Summary

Phase 69 should be planned as an orchestration-and-contract slice, not as a new integration system. The repo already has the canonical live adopter proof in `examples/phoenix_meilisearch/README.md`, the canonical support contract in `guides/support-and-compatibility.md`, bounded drift checks in `test/scrypath/docs_contract_test.exs`, and a semantic root-task precedent in `lib/mix/tasks/verify.opsui.ex`. [VERIFIED: examples/phoenix_meilisearch/README.md] [VERIFIED: guides/support-and-compatibility.md] [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: lib/mix/tasks/verify.opsui.ex]

The planning focus should therefore be: add one durable `mix verify.adopter` task, keep the default path fast and service-free, make `--live` execute the exact example CI-shaped path, and extend contract coverage so docs, task help, example README, and CI job names cannot drift independently. That matches the phase decisions, the existing example README wording, the current `phoenix-example-integration` job, and the repo’s established “bounded contracts over prose snapshots” style. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: examples/phoenix_meilisearch/README.md] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: test/scrypath/docs_contract_test.exs]

The current machine can already execute both halves of the intended spine: `mix test test/scrypath/docs_contract_test.exs` passed locally, and the full Phoenix example `mix test` with `SCRYPATH_EXAMPLE_INTEGRATION=1`, `PGPORT=5433`, and `SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700` also passed locally. That raises confidence that the planner can treat the live path as a real maintained surface rather than a hypothetical CI-only branch. [VERIFIED: `mix test test/scrypath/docs_contract_test.exs`] [VERIFIED: `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test`]

**Primary recommendation:** Build `mix verify.adopter` as a thin semantic Mix task with strict `--live` branching, reuse `docs_contract_test.exs` for most fast-mode truth assertions, and keep service provisioning/readiness outside the task and inside CI or the human’s local environment. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: lib/mix/tasks/verify.phase5.ex] [CITED: https://hexdocs.pm/mix/1.14.5/Mix.Task.html] [CITED: https://hexdocs.pm/elixir/OptionParser.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Root maintainer command discovery | API / Backend | Browser / Client | Mix tasks are CLI/backend concerns, and official Mix task docs require `@shortdoc` and `@moduledoc` for public discoverability; README and CONTRIBUTING only surface the entrypoint. [CITED: https://hexdocs.pm/mix/1.14.5/Mix.Task.html] [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md] |
| Fast adopter-truth verification | API / Backend | Database / Storage | The fast path should run bounded ExUnit assertions from the repo root against docs, task files, and workflow files, not live services. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: test/scrypath/docs_contract_test.exs] |
| Live adopter proof execution | API / Backend | Database / Storage | The root task should orchestrate the example’s canonical `mix deps.get && mix test` path, while the actual proof depends on the example app plus Postgres and Meilisearch. [VERIFIED: examples/phoenix_meilisearch/README.md] [VERIFIED: .github/workflows/ci.yml] |
| Service provisioning and readiness | CDN / Static | API / Backend | CI currently owns service setup, env injection, and readiness waits through GitHub Actions jobs; the phase context explicitly forbids moving that glue into the Mix task. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] |
| Docs / CI / help-text drift protection | API / Backend | Browser / Client | Contract assertions belong in ExUnit because the repo already pins command ordering and canonical references there; docs remain human-facing outputs, not the enforcement mechanism. [VERIFIED: test/scrypath/docs_contract_test.exs] |

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Elixir Mix task API (`Mix.Task`) | Elixir docs verified at `1.19.5`; project support floor `~> 1.17` [CITED: https://hexdocs.pm/mix/1.14.5/Mix.Task.html] [VERIFIED: mix.exs] | Public semantic root command with `@shortdoc`, `@moduledoc`, and `run/1` | Official Mix docs define the public task surface and repo precedent already uses it for durable root verification tasks. [CITED: https://hexdocs.pm/mix/1.14.5/Mix.Task.html] [VERIFIED: lib/mix/tasks/verify.opsui.ex] |
| `OptionParser` | Elixir docs verified at `1.19.5` [CITED: https://hexdocs.pm/elixir/OptionParser.html] | Parse `--live` and optional `--fast` flags with strict validation | Official docs recommend `:strict` parsing for known switches, which fits a small stable flag surface. [CITED: https://hexdocs.pm/elixir/OptionParser.html] |
| ExUnit bounded contract tests | Built into Elixir; repo running on Mix `1.19.5` locally [VERIFIED: `mix --version`] | Fast-mode proof for docs, task help, command ordering, and CI parity | Scrypath already uses bounded doc contracts instead of snapshot-heavy doc freezing. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: lib/mix/tasks/verify.phase41.ex] [VERIFIED: lib/mix/tasks/verify.phase43.ex] |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| `System.cmd/3` orchestration pattern | Elixir stdlib in current project runtime [VERIFIED: lib/mix/tasks/verify.opsui.ex] | Run the example app’s `mix deps.get && mix test` flow from the root task with explicit `cd` and hard failure propagation | Use for `--live`, following the existing `verify.opsui` pattern instead of inventing a new orchestration layer. [VERIFIED: lib/mix/tasks/verify.opsui.ex] |
| Example README + example test suite | Current repo state [VERIFIED: examples/phoenix_meilisearch/README.md] [VERIFIED: `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test`] | Canonical live adopter proof and env contract | Use as the source of truth for `--live`; do not fork or reinterpret it. [VERIFIED: examples/phoenix_meilisearch/README.md] |
| GitHub Actions CI job split | Current workflow file [VERIFIED: .github/workflows/ci.yml] | Hybrid parity between maintainer command family and service-isolated jobs | Use for the CI half of the spine; keep service setup and waits in Actions. [VERIFIED: .github/workflows/ci.yml] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `mix verify.adopter` | `mix verify.phase69` | Rejected because the phase context explicitly wants a durable semantic maintainer affordance rather than milestone bookkeeping. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] |
| `mix verify.adopter --live` | Separate `mix verify.adopter_live` task | Rejected because the context locks one command family with explicit depth flags and less command sprawl. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] |
| Example `mix deps.get && mix test` | `./scripts/smoke.sh` | Rejected for canonical proof because the example README and CONTRIBUTING both state the smoke script is local DX only, not the CI truth path. [VERIFIED: examples/phoenix_meilisearch/README.md] [VERIFIED: CONTRIBUTING.md] |

**Installation:** None; this phase should reuse stdlib APIs plus existing repo tests, docs, and CI surfaces rather than adding new Hex dependencies. [VERIFIED: mix.exs]

**Version verification:** No new package versions are required for this phase. The relevant verified stack anchors are Elixir support floor `~> 1.17` in `mix.exs`, CI coverage on Elixir `1.17.3` and `1.19.0` with OTP `26.2.5` and `28.1`, and local execution on Elixir `1.19.5` / Mix `1.19.5`. [VERIFIED: mix.exs] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: `elixir --version`] [VERIFIED: `mix --version`]

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer / CI
    |
    v
mix verify.adopter
    |
    +--> parse flags (`OptionParser`)
            |
            +--> default / --fast
            |       |
            |       v
            |   ExUnit bounded contracts
            |       |
            |       +--> README / CONTRIBUTING / support guide / example README
            |       +--> Mix task help text / task files
            |       +--> .github/workflows/ci.yml command mapping
            |
            +--> --live
                    |
                    +--> validate env / fail loudly if missing
                    |
                    v
              cd examples/phoenix_meilisearch
                    |
                    +--> mix deps.get
                    +--> mix test
                    |
                    v
              Phoenix example + Postgres + Meilisearch proof

GitHub Actions
    |
    +--> provisions services / waits for readiness
    +--> runs mix verify.adopter or mix verify.adopter --live
```

The key boundary is that service provisioning stays outside the task, while the task owns only command selection and failure propagation. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: .github/workflows/ci.yml]

### Recommended Project Structure

```text
lib/mix/tasks/
├── verify.adopter.ex          # New semantic root maintainer task
├── verify.opsui.ex            # Existing semantic task precedent
└── verify.phase*.ex           # Historical focused gates

test/scrypath/
├── docs_contract_test.exs     # Existing bounded docs/CI contract surface
└── verify_adopter_task_test.exs  # Small task-focused help/arg/failure tests if needed

examples/phoenix_meilisearch/
├── README.md                  # Canonical live adopter proof contract
└── test/                      # Live example proof surface
```

This structure reuses existing seams instead of creating a parallel verification subsystem. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: examples/phoenix_meilisearch/README.md]

### Pattern 1: Semantic Root Task With Explicit Depth Flags

**What:** One public Mix task should own the maintainer-facing command surface, while flags choose bounded fast mode versus explicit live mode. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [CITED: https://hexdocs.pm/mix/1.14.5/Mix.Task.html]  
**When to use:** When the workflow is long-lived and semantic, but the verification depth differs by prerequisites or runtime cost. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: lib/mix/tasks/verify.phase5.ex]

**Example:**
```elixir
# Source: Mix.Task docs + repo pattern
defmodule Mix.Tasks.Verify.Adopter do
  use Mix.Task

  @shortdoc "Checks adopter-facing docs fast, or runs the live Phoenix example with --live"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    {opts, rest, invalid} = OptionParser.parse(args, strict: [live: :boolean, fast: :boolean])
    # reject rest/invalid, then branch to fast or live
  end
end
```

Source basis: official Mix tasks expose public help via `@shortdoc` / `@moduledoc`, and repo tasks already call `Mix.Task.run("app.start")` before orchestration. [CITED: https://hexdocs.pm/mix/1.14.5/Mix.Task.html] [CITED: https://hexdocs.pm/elixir/OptionParser.html] [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: lib/mix/tasks/verify.phase5.ex]

### Pattern 2: Bounded Contract Tests Over Narrative Snapshots

**What:** Keep fast-mode truth enforcement in targeted ExUnit assertions for links, job names, command ordering, env vars, and mode wording rather than snapshotting large docs blocks. [VERIFIED: test/scrypath/docs_contract_test.exs]  
**When to use:** When the planner needs drift protection for maintainer truth without freezing prose tone or structure. [VERIFIED: .planning/phases/68-example-proof-and-support-contract/68-CONTEXT.md]

**Example:**
```elixir
# Source: repo docs-contract style
assert ordered?(job_window, "cd examples/phoenix_meilisearch", "mix deps.get")
assert ordered?(job_window, "mix deps.get", "mix test")
assert String.contains?(example_readme, "SCRYPATH_EXAMPLE_INTEGRATION")
```

Source basis: current docs contracts already pin this exact example/CI command ordering and env vocabulary. [VERIFIED: test/scrypath/docs_contract_test.exs]

### Pattern 3: Hybrid CI Parity

**What:** Keep one maintainable root command family for humans while CI keeps separate jobs with service boundaries, explicit env, and readiness checks. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]  
**When to use:** When the same concept has both an auth-free fast gate and a service-backed live proof. [VERIFIED: CONTRIBUTING.md] [VERIFIED: .github/workflows/ci.yml]

**Example:**
```elixir
# Source: repo verify.opsui pattern, adapted for the example app
script = "printf 'n\\n' | mix deps.get && mix test"
{out, status} = System.cmd("bash", ["-lc", script], cd: example_dir, stderr_to_stdout: true)
```

Use this only for orchestration; keep service setup, waits, and env defaults outside the task. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: .github/workflows/ci.yml]

### Anti-Patterns to Avoid

- **Hidden live path:** Do not call `./scripts/smoke.sh` the canonical proof, because repo docs already define it as local convenience and reserve `mix deps.get && mix test` for CI-shaped truth. [VERIFIED: examples/phoenix_meilisearch/README.md] [VERIFIED: CONTRIBUTING.md]
- **Task-as-CI-runner:** Do not move Docker/service boot, readiness loops, or workflow-level branching into `mix verify.adopter`. The context explicitly forbids that and CI already owns it. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: .github/workflows/ci.yml]
- **Weak fast mode:** Do not let fast mode collapse to docs-only assertions; the phase context explicitly requires example-mode coverage and fast-vs-live contract checks too. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]
- **Public phase-numbered command:** Do not expose `mix verify.phase69` as the maintainer interface, because that conflicts with the locked command-surface decision and existing semantic-task precedent. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: lib/mix/tasks/verify.opsui.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CLI flag parsing | Ad-hoc argv parsing | `OptionParser.parse(..., strict: ...)` | Official docs already provide typed strict switches and invalid-flag reporting for this exact job. [CITED: https://hexdocs.pm/elixir/OptionParser.html] |
| Docs drift enforcement | Snapshot files or a manifest DSL | Existing ExUnit contract style in `docs_contract_test.exs` | The repo already proves command order, env vars, and canonical links this way. [VERIFIED: test/scrypath/docs_contract_test.exs] |
| Live proof harness | New orchestration script or hidden shell wrapper | Reuse the example app’s existing `mix deps.get && mix test` path | README, CONTRIBUTING, and CI already agree on that path. [VERIFIED: examples/phoenix_meilisearch/README.md] [VERIFIED: CONTRIBUTING.md] [VERIFIED: .github/workflows/ci.yml] |
| Service boot / readiness inside Mix | Docker boot code or curl loops in the task | GitHub Actions `services:` and explicit local prerequisites | The phase context locks the task to orchestration-only, and CI already contains the boot/wait logic. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: .github/workflows/ci.yml] |

**Key insight:** The planner should compose existing maintained truth surfaces into one spine, not introduce a new verification subsystem. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: examples/phoenix_meilisearch/README.md]

## Common Pitfalls

### Pitfall 1: Fast Mode That Proves Only Strings

**What goes wrong:** The root task becomes a thin alias for `docs_contract_test.exs` and misses the phase’s required fast/live command-shape assertions. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]  
**Why it happens:** The existing docs-contract suite is convenient, so planners may stop there. [VERIFIED: test/scrypath/docs_contract_test.exs]  
**How to avoid:** Extend `docs_contract_test.exs` with adopter-specific assertions and add one small task-focused test only if needed for argument/error behavior. [ASSUMED]  
**Warning signs:** Fast mode passes even if task help omits `--live`, or if CI switches to a different live command without a failure. [ASSUMED]

### Pitfall 2: Silent Downgrade From Live To Fast

**What goes wrong:** `mix verify.adopter --live` partially passes or falls back to fast mode when env vars or services are missing. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]  
**Why it happens:** It is tempting to be “helpful” and keep the command green. [ASSUMED]  
**How to avoid:** Mirror the `verify.phase5` pattern: check required env and raise loudly before running the live branch. [VERIFIED: lib/mix/tasks/verify.phase5.ex]  
**Warning signs:** Live mode succeeds without `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, or `SCRYPATH_MEILISEARCH_URL`, or it logs warnings instead of failing. [ASSUMED]

### Pitfall 3: CI Parity Drift

**What goes wrong:** README or CONTRIBUTING teaches one live command, but `.github/workflows/ci.yml` runs something else. [VERIFIED: test/scrypath/docs_contract_test.exs]  
**Why it happens:** The example README, CONTRIBUTING, task help, and workflow are separate files with overlapping truth. [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md] [VERIFIED: examples/phoenix_meilisearch/README.md] [VERIFIED: .github/workflows/ci.yml]  
**How to avoid:** Add adopter-specific contract assertions that pin job name, env vars, and `cd -> mix deps.get -> mix test` ordering against the new root task wording. [VERIFIED: test/scrypath/docs_contract_test.exs]  
**Warning signs:** A PR updates the example README or CI job but leaves task help and contributor docs unchanged. [ASSUMED]

### Pitfall 4: Scope Creep Into Generic Repo Verification

**What goes wrong:** `mix verify.adopter` starts absorbing release, OPSUI, or unrelated quality gates. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]  
**Why it happens:** The repo already has many `verify.phase*` tasks, so a new root task can become a dumping ground. [VERIFIED: CONTRIBUTING.md] [VERIFIED: .github/workflows/ci.yml]  
**How to avoid:** Keep the task limited to adopter surfaces: root docs, support contract, example proof, and fast/live distinction. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]  
**Warning signs:** The task begins running Credo, Dialyzer, release gates, or OPSUI paths unrelated to adopter confidence. [VERIFIED: CONTRIBUTING.md] [VERIFIED: .github/workflows/ci.yml]

## Code Examples

Verified patterns from official sources and current repo:

### Public Mix Task Surface

```elixir
# Source: https://hexdocs.pm/mix/1.14.5/Mix.Task.html
defmodule Mix.Tasks.Verify.Adopter do
  use Mix.Task

  @shortdoc "Fast adopter docs/example parity check; add --live for the Phoenix example proof"
  @moduledoc "Public help text shown by `mix help verify.adopter`."
end
```

Official Mix docs state that `@shortdoc` makes a task public in `mix help`, while `@moduledoc` is what `mix help my_task` shows. [CITED: https://hexdocs.pm/mix/1.14.5/Mix.Task.html]

### Strict Flag Parsing

```elixir
# Source: https://hexdocs.pm/elixir/OptionParser.html
{opts, rest, invalid} =
  OptionParser.parse(args, strict: [live: :boolean, fast: :boolean])
```

Official `OptionParser` docs prefer `:strict` when the command only accepts known switches and should reject unknown ones. [CITED: https://hexdocs.pm/elixir/OptionParser.html]

### Existing Repo Orchestration Pattern

```elixir
# Source: lib/mix/tasks/verify.opsui.ex
{out, status} =
  System.cmd("bash", ["-lc", script], cd: ops_dir, stderr_to_stdout: true)
```

Scrypath already uses this pattern to run a subordinate app from the repository root and fail on non-zero exit status. [VERIFIED: lib/mix/tasks/verify.opsui.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Historical phase-specific verify tasks as the only root-level vocabulary | Semantic root tasks for durable maintainer workflows already exist via `mix verify.opsui` | Shipped in Phase 53; documented in current README/CONTRIBUTING [VERIFIED: .planning/ROADMAP.md] [VERIFIED: README.md] [VERIFIED: CONTRIBUTING.md] | Phase 69 can follow an established repo precedent instead of inventing a new pattern. [VERIFIED: lib/mix/tasks/verify.opsui.ex] |
| Example live proof described loosely as smoke | Example README now treats `mix deps.get` then `mix test` as the canonical CI-shaped proof and `./scripts/smoke.sh` as local DX only | Phase 68 completed on 2026-04-23 per requirements/state updates [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/STATE.md] [VERIFIED: examples/phoenix_meilisearch/README.md] | `--live` should target the example’s test path directly, not the smoke script. [VERIFIED: examples/phoenix_meilisearch/README.md] |
| Compatibility truth scattered across multiple files | Dedicated `guides/support-and-compatibility.md` is now the canonical support contract | Phase 68 completed on 2026-04-23 [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: guides/support-and-compatibility.md] | Fast mode should explicitly protect this guide as part of adopter truth. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] |

**Deprecated/outdated:**
- Treating `./scripts/smoke.sh` as the canonical CI proof path is outdated; current example docs and CONTRIBUTING reserve it for local orchestration only. [VERIFIED: examples/phoenix_meilisearch/README.md] [VERIFIED: CONTRIBUTING.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Extending `docs_contract_test.exs` plus one small task-focused test is likely lower-friction than creating a wholly separate fast-mode suite. [ASSUMED] | Common Pitfalls / Open Questions | Low; planner may choose a separate suite if help/arg assertions become awkward. |
| A2 | Warnings are sufficient for “warning signs” examples even though exact failure mode will depend on the final task implementation. [ASSUMED] | Common Pitfalls | Low; affects wording, not architecture. |

## Resolved Decisions

1. **`--fast` will not be a public flag in Phase 69.**
   - Decision: keep the public surface to no-flag fast mode plus explicit `--live`.
   - Why: the phase context requires no-flag fast mode, and adding `--fast` does not add defended capability for maintainers or CI. Keeping only `mix verify.adopter` and `mix verify.adopter --live` matches the intended command family with less public surface area. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]

2. **Fast-mode truth contracts stay in `docs_contract_test.exs`, with one focused Mix-task test file for runtime behavior.**
   - Decision: keep docs/help/CI/example/support-guide parity in `test/scrypath/docs_contract_test.exs`, and add `test/mix/tasks/verify_adopter_test.exs` only for behavior that is awkward to prove via file-content assertions alone.
   - Why: the repo already centralizes maintainer-facing truth contracts in `docs_contract_test.exs`, while Mix-task runtime behavior such as arg rejection and loud missing-env failures fits the existing `test/mix/tasks/*` style better. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: test/mix/tasks/verify_workspace_clean_test.exs]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Root Mix task and tests | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | CI matrix also covers `1.17.3` and `1.19.0`. [VERIFIED: .github/workflows/ci.yml] |
| Mix | Root task execution | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | None needed. |
| Docker | Local live path setup if services are not already running | ✓ [VERIFIED: `docker --version`] | `29.3.1` [VERIFIED: `docker --version`] | CI can provision services even if a maintainer skips local Docker. [VERIFIED: .github/workflows/ci.yml] |
| Docker Compose | Example local orchestration path | ✓ [VERIFIED: `docker compose version`] | `v5.1.1` [VERIFIED: `docker compose version`] | Manual external services plus exported env vars. [VERIFIED: examples/phoenix_meilisearch/README.md] |
| `pg_isready` | Local Postgres readiness checks | ✓ [VERIFIED: `pg_isready --version`] | `14.17` [VERIFIED: `pg_isready --version`] | CI already installs `postgresql-client` before readiness checks. [VERIFIED: .github/workflows/ci.yml] |
| `curl` | Meilisearch readiness checks | ✓ [VERIFIED: `curl --version`] | `8.7.1` [VERIFIED: `curl --version`] | None needed in CI because the runner already has curl. [VERIFIED: .github/workflows/ci.yml] |
| Local Postgres service on `127.0.0.1:5433` | Immediate `--live` execution today | ✓ [VERIFIED: `pg_isready -h 127.0.0.1 -p 5433 -U postgres`] | accepting connections [VERIFIED: `pg_isready -h 127.0.0.1 -p 5433 -U postgres`] | Can be started via Docker Compose if absent. [VERIFIED: examples/phoenix_meilisearch/README.md] |
| Local Meilisearch service on `127.0.0.1:7700` | Immediate `--live` execution today | ✓ [VERIFIED: `curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7700/health`] | HTTP `200` [VERIFIED: `curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7700/health`] | Can be started via Docker Compose if absent. [VERIFIED: examples/phoenix_meilisearch/README.md] |

**Missing dependencies with no fallback:** None found during research. [VERIFIED: local environment audit]

**Missing dependencies with fallback:** None found during research. [VERIFIED: local environment audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via `mix test` [VERIFIED: `mix help test`] |
| Config file | `test/test_helper.exs` is loaded by `mix test`; project also defines a custom `test` alias in `mix.exs`. [VERIFIED: `mix help test`] [VERIFIED: mix.exs] |
| Quick run command | `mix test test/scrypath/docs_contract_test.exs` [VERIFIED: `mix test test/scrypath/docs_contract_test.exs`] |
| Full suite command | `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test` for the live adopter proof; `mix test --exclude integration` remains the repo-wide fast suite. [VERIFIED: CONTRIBUTING.md] [VERIFIED: `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INTG-02 | Fast path proves adopter docs/support/example/CI parity without services | unit / contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ [VERIFIED: test/scrypath/docs_contract_test.exs] |
| INTG-02 | Live path proves the Phoenix example via the canonical CI-shaped run | integration | `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test` | ✅ [VERIFIED: examples/phoenix_meilisearch/test] |
| INTG-02 | Root task help/arg behavior stays explicit and non-ambiguous | unit | `mix test test/scrypath/verify_adopter_task_test.exs` | ❌ Wave 0 [ASSUMED] |

### Sampling Rate

- **Per task commit:** `mix test test/scrypath/docs_contract_test.exs` [VERIFIED: current local pass]
- **Per wave merge:** `mix verify.adopter` and, when the wave touches live path wiring, `mix verify.adopter --live` once services are up. [ASSUMED]
- **Phase gate:** Fast contract slice green plus the example live path green before `/gsd-verify-work`. [VERIFIED: INTG-02 shape in .planning/REQUIREMENTS.md] [ASSUMED]

### Wave 0 Gaps

- [ ] `test/scrypath/verify_adopter_task_test.exs` — task help, invalid-arg handling, and loud `--live` prerequisite failures if these are awkward to cover through file-content contracts alone. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: fast mode must stay auth-free per context] | No auth should be added to the fast path. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] |
| V3 Session Management | no [VERIFIED: phase scope is CLI/docs/example verification] | Not applicable to a Mix-task verification slice. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] |
| V4 Access Control | no [VERIFIED: phase scope is maintainer command orchestration] | Not applicable beyond normal repo permissions. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] |
| V5 Input Validation | yes [CITED: https://hexdocs.pm/elixir/OptionParser.html] | Strict `OptionParser` switch validation and explicit rejection of unexpected args/flags. [CITED: https://hexdocs.pm/elixir/OptionParser.html] |
| V6 Cryptography | no [VERIFIED: no crypto scope in this phase] | None; do not introduce secret-handling logic into the task. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Hidden service dependency causes false confidence | Spoofing | Fail loudly in `--live` when required env/services are absent; never silently downgrade to fast mode. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: lib/mix/tasks/verify.phase5.ex] |
| Docs/CI drift causes maintainers to run the wrong proof path | Tampering | Add bounded contract tests tying task help, example README, CONTRIBUTING, and CI job text together. [VERIFIED: test/scrypath/docs_contract_test.exs] |
| Shell-based orchestration obscures the real command or swallows failure | Repudiation | Echo the exact downstream command and raise on non-zero exit, as `verify.opsui` does. [VERIFIED: lib/mix/tasks/verify.opsui.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/69-adopter-verify-spine/69-CONTEXT.md` - locked phase scope, command shape, fast/live constraints. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - `INTG-02` wording and traceability. [VERIFIED: .planning/REQUIREMENTS.md]
- `examples/phoenix_meilisearch/README.md` - canonical live proof path, env contract, and smoke-script distinction. [VERIFIED: examples/phoenix_meilisearch/README.md]
- `test/scrypath/docs_contract_test.exs` - existing bounded contract style and current example/CI ordering assertions. [VERIFIED: test/scrypath/docs_contract_test.exs]
- `lib/mix/tasks/verify.opsui.ex` and `lib/mix/tasks/verify.phase5.ex` - semantic task precedent plus loud env failure pattern. [VERIFIED: lib/mix/tasks/verify.opsui.ex] [VERIFIED: lib/mix/tasks/verify.phase5.ex]
- `.github/workflows/ci.yml` - job split, service provisioning, and canonical example commands. [VERIFIED: .github/workflows/ci.yml]
- `mix.exs` - supported Elixir floor and preferred CLI envs. [VERIFIED: mix.exs]
- `https://hexdocs.pm/mix/1.14.5/Mix.Task.html` - official Mix task discoverability and task contract. [CITED: https://hexdocs.pm/mix/1.14.5/Mix.Task.html]
- `https://hexdocs.pm/elixir/OptionParser.html` - official flag parsing guidance. [CITED: https://hexdocs.pm/elixir/OptionParser.html]

### Secondary (MEDIUM confidence)

- `https://hexdocs.pm/mix/Mix.Tasks.Cmd.html` - current shell-expansion and command-execution behavior for Mix-level command orchestration context. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Cmd.html]

### Tertiary (LOW confidence)

- None. Every material planning claim above was verified against repo state, official Elixir docs, or local command execution. [VERIFIED: research audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - uses first-party Elixir facilities plus existing repo surfaces that were directly inspected. [VERIFIED: mix.exs] [VERIFIED: lib/mix/tasks/verify.opsui.ex] [CITED: https://hexdocs.pm/mix/1.14.5/Mix.Task.html] [CITED: https://hexdocs.pm/elixir/OptionParser.html]
- Architecture: HIGH - phase context is unusually specific and current repo precedent already matches the desired task shape. [VERIFIED: .planning/phases/69-adopter-verify-spine/69-CONTEXT.md] [VERIFIED: lib/mix/tasks/verify.opsui.ex]
- Pitfalls: HIGH - repo contract tests and CI already expose the exact drift surfaces that this phase must preserve. [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: .github/workflows/ci.yml]

**Research date:** 2026-04-22 [VERIFIED: system date]
**Valid until:** 2026-05-22 for repo-shape guidance; recheck before planning if the example README, CI workflow, or verify task landscape changes. [ASSUMED]
