# Phase 8: Reliability and Contract Hardening - Research

**Researched:** 2026-04-16
**Domain:** Elixir contract hardening for shared sync orchestration, Meilisearch task normalization, and reliability-focused verification [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Task payload hardening
- **D-01:** Treat malformed Meilisearch task payloads as explicit errors, never as implicit success.
- **D-02:** Normalize enqueue responses and polled task responses through strict tuple-returning boundary functions that validate required fields and recognized statuses before shared sync orchestration uses them.
- **D-03:** Use a stable error family for malformed task payloads:
  `{:error, {:invalid_task_payload, %{stage: :initial | :poll, task_uid: integer() | nil, problems: keyword(), payload: map()}}}`.
- **D-04:** Preserve the current explicit terminal error families for real backend outcomes:
  `{:error, {:task_failed, task}}`, `{:error, {:cancelled, task}}`, and `{:error, {:timeout, task}}`.
- **D-05:** Accept current Meilisearch task statuses as `:enqueued`, `:processing`, `:succeeded`, `:failed`, and `:cancelled`. If compatibility support for `"queued"` is retained internally, collapse it to `:enqueued`; do not emit `:queued` as a normalized public status.

### Empty batch semantics
- **D-06:** `Scrypath.sync_records/3` and `Scrypath.delete_documents/3` must treat `[]` as valid input, not as caller error.
- **D-07:** Handle empty batch input in the shared Scrypath entrypoints before backend dispatch and before Oban enqueueing.
- **D-08:** Empty batches return a shared explicit no-op envelope across `:inline`, `:manual`, and `:oban`:
  `{:ok, %{mode: mode, status: :noop, document_ids: [], document_count: 0}}`.
- **D-09:** No-op results must not include backend-native task metadata or Oban job metadata.
- **D-10:** Telemetry should still fire for no-op paths, with `document_count: 0`, the selected `mode`, and `status: :noop`.

### Reliability test boundary
- **D-11:** Phase 8 should use a mixed test boundary: keep contract semantics in fast unit/contract tests and keep live Meilisearch coverage narrow, tagged, and intentional.
- **D-12:** Fast contract tests should cover task normalization, malformed payload handling, timeout/cancel/failure mapping, empty-batch no-op behavior, manual vs inline vs Oban result envelopes, and transport error propagation.
- **D-13:** Live Meilisearch tests should stay limited to a small number of real end-to-end flows that prove the real backend seam still works: one inline write-and-wait path, one settings/reindex or cutover path, and one custom ID preservation path.
- **D-14:** Do not push malformed payload or empty-batch semantics into live backend tests; those are Scrypath contract responsibilities and should stay deterministic.

### the agent's Discretion
- Whether to split enqueue-response normalization and polled-task normalization into separate internal helpers or one shared parser with stage-aware validation.
- Exact `problems` key shape inside `:invalid_task_payload`, as long as it stays stable, inspectable, and testable.
- Exact placement of new contract tests across existing test modules, provided the phase keeps the mixed test boundary above.

### Deferred Ideas (OUT OF SCOPE)
- Broader backend-adapter contract expansion beyond the current Meilisearch-first Phase 8 scope.
- More ambitious transport- or backend-fault injection infrastructure than what is needed for these hardening contracts.
- Additional operator tooling or dashboard work; those belong to later phases once the contract surface is hardened.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HARD-01 | Developer can rely on inline Meilisearch task waiting to report success, timeout, cancellation, malformed payloads, and backend failure through stable explicit result shapes. | Strict stage-aware normalization at the Meilisearch boundary, explicit invalid-payload error tuples, and focused `Tasks` contract tests cover this path [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/scrypath/meilisearch/tasks.ex] [VERIFIED: test/scrypath/meilisearch/tasks_test.exs] |
| HARD-02 | Developer can run shared sync and delete batch entrypoints with empty inputs and receive a defined no-op result instead of ambiguous behavior. | Shared empty-batch short-circuit belongs in `Scrypath.Sync`, before backend dispatch and Oban enqueue, with telemetry preserved through the existing span wrapper [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/scrypath/sync.ex] [VERIFIED: lib/scrypath/telemetry.ex] |
| HARD-03 | Developer can trust the Meilisearch-backed workflow tests to cover the edge cases that previously left release confidence in doubt. | Existing fast contract harnesses and tagged live verification already exist; Phase 8 should extend them rather than inventing a new test architecture [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: test/scrypath/sync_test.exs] [VERIFIED: test/scrypath/meilisearch/tasks_test.exs] [VERIFIED: test/scrypath/live_meilisearch_verification_test.exs] |
</phase_requirements>

## Summary

The current code already has the right ownership boundaries for Phase 8: `Scrypath.Sync` owns the shared public sync/delete contract, `Scrypath.Meilisearch` owns enqueue-response normalization, `Scrypath.Meilisearch.Tasks` owns inline wait semantics, and `Scrypath.Telemetry` owns public stop metadata shaping [VERIFIED: lib/scrypath/sync.ex] [VERIFIED: lib/scrypath/meilisearch.ex] [VERIFIED: lib/scrypath/meilisearch/tasks.ex] [VERIFIED: lib/scrypath/telemetry.ex]. The planner should keep the phase narrowly inside those seams instead of introducing a new abstraction layer [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md].

The main technical risk is that task normalization is currently permissive: `Tasks.wait_for_task/2` normalizes with `Map.get` and falls through to `{:ok, task}` for any unknown terminal status, while `Scrypath.Meilisearch.normalize_task/1` accepts missing `uid` or raw string status without validation [VERIFIED: lib/scrypath/meilisearch/tasks.ex] [VERIFIED: lib/scrypath/meilisearch.ex]. That means malformed backend payloads can currently look successful unless Phase 8 inserts explicit boundary validation before orchestration [VERIFIED: lib/scrypath/meilisearch/tasks.ex].

The verification posture should stay mixed, not broadened: fast unit/contract tests already pass in 0.2s for the relevant files, the live suite is already isolated behind `:integration`, and the local machine currently has Elixir/OTP/Docker available but no running Meilisearch endpoint configured for integration tests [VERIFIED: mix test test/scrypath/meilisearch/tasks_test.exs test/scrypath/sync_test.exs] [VERIFIED: test/test_helper.exs] [VERIFIED: local env].

**Primary recommendation:** Add strict, tuple-returning task normalization helpers at the existing Meilisearch seams and add a shared empty-batch no-op fast path in `Scrypath.Sync`; verify with expanded contract tests plus the existing narrow live suite pattern [VERIFIED: lib/scrypath/meilisearch/tasks.ex] [VERIFIED: lib/scrypath/meilisearch.ex] [VERIFIED: lib/scrypath/sync.ex] [VERIFIED: test/scrypath/live_meilisearch_verification_test.exs].

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Task enqueue payload normalization | API / Backend | — | Meilisearch responses enter the library through backend modules, so validation belongs at the backend boundary before the shared sync layer consumes task maps [VERIFIED: lib/scrypath/meilisearch.ex]. |
| Inline task wait state machine | API / Backend | — | `Scrypath.Meilisearch.Tasks` already owns polling, timeout, and terminal mapping for inline mode [VERIFIED: lib/scrypath/meilisearch/tasks.ex]. |
| Empty batch no-op semantics | API / Backend | — | `Scrypath.Sync` is the public entrypoint for `sync_records/3` and `delete_documents/3`; only that layer can guarantee identical behavior across inline, manual, and Oban modes [VERIFIED: lib/scrypath/sync.ex]. |
| No-op and task-wait telemetry | API / Backend | — | Telemetry spans and stop metadata are emitted from library code, not from Meilisearch or Oban, and `Scrypath.Telemetry.stop_metadata/2` already shapes the common contract [VERIFIED: lib/scrypath/telemetry.ex]. |
| Contract edge-case tests | API / Backend | Frontend Server (SSR) | ExUnit + Req.Test contract tests are library-owned; live verification is also library-owned but exercised against an external Meilisearch service [VERIFIED: test/scrypath/meilisearch/tasks_test.exs] [VERIFIED: test/scrypath/sync_test.exs] [VERIFIED: test/scrypath/live_meilisearch_verification_test.exs]. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.17` floor in project, local `1.19.5` verified [VERIFIED: mix.exs] [VERIFIED: local env] | Language/runtime for the library | Phase 8 only needs language-native pattern matching, tagged tuples, and ExUnit; no extra runtime abstraction is justified [VERIFIED: mix.exs] [VERIFIED: prompts/elixir-best-practices-deep-research.md]. |
| Ecto | `3.13.5` (lockfile) / package page updated Mar 12, 2026 [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/ecto] | Existing schema/projection integration surface | Scrypath is already Ecto-first and Phase 8 should stay on the shared contract instead of adding schema-side callbacks or another persistence layer [VERIFIED: mix.exs] [VERIFIED: .planning/PROJECT.md]. |
| Req | `0.5.17` / package page updated Mar 22, 2026 [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/req] | HTTP transport and contract-test harness via `Req.Test` | The codebase already uses `Req.Test.stub/2`, `Req.Test.json/2`, and transport-error shaping in the Meilisearch path; reusing that harness keeps tests deterministic and concurrent-safe [VERIFIED: test/scrypath/sync_test.exs] [VERIFIED: test/scrypath/meilisearch_test.exs] [CITED: https://hexdocs.pm/req/Req.Test.html]. |
| Telemetry | `1.4.1` / package page updated Mar 09, 2026 [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/telemetry] | Stable span-based metadata for sync and backend events | Phase 8 explicitly requires no-op telemetry and should extend the existing low-cardinality span contract rather than inventing a parallel event surface [VERIFIED: lib/scrypath/telemetry.ex] [VERIFIED: test/scrypath/telemetry_test.exs]. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban | `2.21.1` / package page updated Mar 26, 2026 [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/oban] | Optional durable async path for `sync_mode: :oban` | Keep Oban in scope only for shared no-op envelope parity; empty batches must short-circuit before enqueueing work [VERIFIED: lib/scrypath/oban/enqueue.ex] [VERIFIED: test/scrypath/sync_test.exs]. |
| Plug | `1.19.1` / package page updated Dec 09, 2025 [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/plug] | Test-only conn helpers used by `Req.Test` | Use only inside deterministic HTTP contract tests; no phase work should couple production logic to Plug [VERIFIED: mix.exs] [VERIFIED: test/scrypath/sync_test.exs]. |
| ecto_sqlite3 | `0.22.0` (lockfile) [VERIFIED: mix.lock] | Integration test repo backing the live verification helper | Reuse the current SQLite-backed integration harness for live Meilisearch flows; no new DB test rig is needed for Phase 8 [VERIFIED: test/support/meilisearch_integration.ex]. |
| NimbleOptions | `1.1.1` / package page updated May 25, 2024 [VERIFIED: mix.exs] [CITED: https://hex.pm/packages/nimble_options] | Existing option validation dependency | Only relevant if internal helper options need validation; Phase 8 does not need a new options schema unless helper signatures widen [VERIFIED: mix.exs]. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `Req.Test` plus inline fake client modules [VERIFIED: test/scrypath/sync_test.exs] [VERIFIED: test/scrypath/meilisearch/tasks_test.exs] | Add Mox or a new HTTP mock layer [ASSUMED] | Higher setup cost for no clear gain; the current harness already supports concurrent stubs and transport-error simulation [CITED: https://hexdocs.pm/req/Req.Test.html]. |
| Shared contract tests plus narrow live verification [VERIFIED: test/test_helper.exs] [VERIFIED: test/scrypath/live_meilisearch_verification_test.exs] | Move malformed payload and empty-batch semantics into live tests [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md] | That would make contract responsibilities flaky and environment-dependent, which directly contradicts D-14 [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md]. |
| Harden current Meilisearch seams [VERIFIED: lib/scrypath/meilisearch.ex] [VERIFIED: lib/scrypath/meilisearch/tasks.ex] | Introduce a new public backend-agnostic task facade [VERIFIED: .planning/PROJECT.md] | It adds API surface and abstraction pressure outside the v1.1 scope [VERIFIED: .planning/PROJECT.md]. |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Verify phase-relevant package versions against `mix.lock` and current Hex package pages before planning implementation detail tied to a release:
```bash
rg -n 'ecto|req|telemetry|oban|plug|nimble_options' mix.lock
open https://hex.pm/packages/ecto
open https://hex.pm/packages/req
open https://hex.pm/packages/telemetry
open https://hex.pm/packages/oban
```

## Architecture Patterns

### System Architecture Diagram

```text
sync_records/delete_documents call
        |
        v
  Scrypath.Sync public entrypoint
        |
        +--> [] ? ----yes----> build shared noop envelope
        |                        |
        |                        v
        |                  Telemetry.stop_metadata(:noop)
        |                        |
        |                        v
        |                     return {:ok, %{...}}
        |
        no
        |
        v
  mode branch (:inline | :manual | :oban)
        |
        +--> :oban ------> Scrypath.Oban.Enqueue ----> accepted envelope
        |
        +--> :manual ----> backend.upsert/delete ----> enqueue task envelope
        |
        +--> :inline ----> backend.upsert/delete
                               |
                               v
                    normalize initial task payload
                               |
                     invalid?--yes--> {:error, {:invalid_task_payload, ...}}
                               |
                               no
                               |
                               v
                       poll /tasks/:uid until
             succeeded | failed | cancelled | timeout | invalid poll payload
                               |
                               v
                    decorate shared result + telemetry
```

### Recommended Project Structure
```text
lib/
├── scrypath/sync.ex                 # Shared sync/delete orchestration and empty-batch no-op gate
├── scrypath/meilisearch.ex          # Initial task normalization from write responses
├── scrypath/meilisearch/tasks.ex    # Inline wait state machine and poll-payload validation
├── scrypath/telemetry.ex            # Shared stop-metadata shaping, including :noop
└── scrypath/oban/enqueue.ex         # Async accepted-envelope path that Phase 8 must bypass for []

test/
├── scrypath/sync_test.exs                 # Shared contract behavior across inline/manual/oban
├── scrypath/meilisearch/tasks_test.exs    # Deterministic task parser/state-machine edge cases
├── scrypath/telemetry_test.exs            # Low-cardinality metadata and :noop coverage
└── scrypath/live_meilisearch_verification_test.exs  # Narrow tagged live backend seam
```

### Pattern 1: Stage-Aware Boundary Normalization
**What:** Normalize and validate initial enqueue responses and polled task responses before the shared sync orchestration consumes them, returning tagged tuples instead of raw maps [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md] [VERIFIED: lib/scrypath/meilisearch.ex] [VERIFIED: lib/scrypath/meilisearch/tasks.ex].  
**When to use:** For every Meilisearch task payload entering the common sync path, including the first write response and each `/tasks/:uid` poll [CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks].  
**Example:**
```elixir
# Source: /Users/jon/projects/scrypath/lib/scrypath/meilisearch/tasks.ex
with {:ok, normalized} <- normalize_polled_task(response, :poll) do
  do_wait_for_task(normalized, config, started_at, poll_interval, timeout, polls + 1)
end
```

### Pattern 2: Shared No-Op Short-Circuit Before Mode Dispatch
**What:** Detect `[]` in the public batch entrypoints and return one shared explicit no-op envelope before backend dispatch or Oban enqueue [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md] [VERIFIED: lib/scrypath/sync.ex].  
**When to use:** `Scrypath.sync_records/3` and `Scrypath.delete_documents/3` only; not single-record wrappers, which naturally delegate after wrapping one item [VERIFIED: lib/scrypath/sync.ex].  
**Example:**
```elixir
# Source: /Users/jon/projects/scrypath/lib/scrypath/sync.ex
if documents == [] do
  {:ok, %{mode: sync_mode, status: :noop, document_ids: [], document_count: 0}}
else
  dispatch_upsert(schema_module, documents, config)
end
```

### Pattern 3: Mixed Reliability Test Boundary
**What:** Keep malformed payloads, timeout mapping, no-op envelopes, and transport errors in fast contract tests, while keeping only a few real backend seam checks in tagged integration tests [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md] [VERIFIED: test/scrypath/meilisearch/tasks_test.exs] [VERIFIED: test/scrypath/live_meilisearch_verification_test.exs].  
**When to use:** For all Phase 8 verification work; do not add new live-only expectations for library-owned contract behavior [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md].  
**Example:**
```elixir
# Source: https://hexdocs.pm/req/Req.Test.html
Req.Test.stub(MyStub, fn conn ->
  Req.Test.transport_error(conn, :timeout)
end)
```

### Anti-Patterns to Avoid
- **Permissive task fallthrough:** `Tasks.do_wait_for_task/6` currently returns `{:ok, task}` for any unrecognized non-queued status, which would make malformed task payloads look successful [VERIFIED: lib/scrypath/meilisearch/tasks.ex].
- **Backend dispatch for `[]`:** Current `Scrypath.Sync` always proceeds to dispatch after projecting the list, which would make empty-batch semantics depend on whichever backend or Oban path sees the call first [VERIFIED: lib/scrypath/sync.ex].
- **Live-only reliability semantics:** The project already isolates integration tests with `:integration`; using live backend tests for malformed payload semantics would add flakiness without improving seam coverage [VERIFIED: test/test_helper.exs] [VERIFIED: test/scrypath/live_meilisearch_verification_test.exs].
- **New public abstraction for task handling:** v1.1 is a hardening milestone, and the project explicitly avoids widening the public backend abstraction surface before trust is earned [VERIFIED: .planning/PROJECT.md].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP edge-case harness | A new mock transport library or bespoke fake HTTP stack [ASSUMED] | `Req.Test.stub/2`, `Req.Test.json/2`, and `Req.Test.transport_error/2` [CITED: https://hexdocs.pm/req/Req.Test.html] | The official Req test API already supports concurrent stubs and transport-error simulation, and the repo already uses it heavily [VERIFIED: test/scrypath/sync_test.exs] [VERIFIED: test/scrypath/meilisearch_test.exs]. |
| Shared no-op result shaping | Per-mode special cases scattered across backend and Oban modules [VERIFIED: lib/scrypath/sync.ex] [VERIFIED: lib/scrypath/oban/enqueue.ex] | One shared helper in `Scrypath.Sync` [VERIFIED: lib/scrypath/sync.ex] | The requirement is a common envelope across inline/manual/oban, so the public entrypoint is the only coherent place to own it [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md]. |
| Public task abstraction | New generic task protocol/facade [VERIFIED: .planning/PROJECT.md] | Internal stage-aware normalization helpers inside the Meilisearch seam [VERIFIED: lib/scrypath/meilisearch.ex] [VERIFIED: lib/scrypath/meilisearch/tasks.ex] | This phase is about hardening the shipped Meilisearch-first surface, not promising backend-generic task APIs [VERIFIED: .planning/PROJECT.md]. |
| Live integration orchestration | A new phase-specific verification framework [VERIFIED: lib/mix/tasks/verify.phase5.ex] | Existing ExUnit + tagged integration pattern, optionally mirrored in a `verify.phase8` task [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: test/test_helper.exs] | The project already has a precedent for focused tests plus optional live verification; reusing it keeps planning scope small [VERIFIED: lib/mix/tasks/verify.phase5.ex]. |

**Key insight:** Phase 8 is a boundary-hardening phase, not a framework-building phase; the planner should spend tasks on explicit tuple contracts and coverage holes, not on new abstractions or new harnesses [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md].

## Common Pitfalls

### Pitfall 1: Treating Unknown Task Payloads as Success
**What goes wrong:** Inline waits can return `{:ok, task}` for unrecognized terminal states or missing required fields if validation is not added before the state machine [VERIFIED: lib/scrypath/meilisearch/tasks.ex].  
**Why it happens:** The current parser uses permissive `Map.get` extraction and the final `do_wait_for_task/6` clause treats any other status as success [VERIFIED: lib/scrypath/meilisearch/tasks.ex].  
**How to avoid:** Normalize both initial and polled payloads through strict tuple-returning helpers that require usable `uid` and recognized status values before recursion [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md].  
**Warning signs:** A test payload like `%{"status" => "enqueued"}` or `%{"uid" => 301, "status" => "weird"}` does not fail fast [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md].

### Pitfall 2: Letting Empty Batches Reach Backend or Oban Paths
**What goes wrong:** `[]` behavior becomes mode-specific, potentially enqueueing meaningless Oban jobs or backend requests, and telemetry no longer has one shared story [VERIFIED: lib/scrypath/sync.ex] [VERIFIED: lib/scrypath/oban/enqueue.ex].  
**Why it happens:** Current public batch entrypoints compute metadata and always call `dispatch_*` without a no-op guard [VERIFIED: lib/scrypath/sync.ex].  
**How to avoid:** Short-circuit in `Scrypath.Sync` immediately after projection/ID collection and decorate the shared no-op envelope there [VERIFIED: lib/scrypath/sync.ex].  
**Warning signs:** Tests need to assert backend calls were not received, or Oban insert messages were not emitted, for empty lists [VERIFIED: test/scrypath/sync_test.exs].

### Pitfall 3: Adding Flaky Live Tests for Library-Owned Semantics
**What goes wrong:** Release confidence gets worse because malformed payload and no-op cases depend on environment state instead of deterministic contract harnesses [VERIFIED: test/test_helper.exs] [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md].  
**Why it happens:** It is tempting to push every reliability case into the real backend suite, but D-14 explicitly forbids that and the local machine does not currently have a running Meilisearch endpoint configured [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md] [VERIFIED: local env].  
**How to avoid:** Keep live tests to one inline write-and-wait, one reindex/settings flow, and one custom-ID flow, all of which already exist [VERIFIED: test/scrypath/live_meilisearch_verification_test.exs].  
**Warning signs:** A planned test needs malformed Meilisearch server behavior or empty-input live setup just to prove a Scrypath tuple contract [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md].

### Pitfall 4: Breaking Req.Test Ownership by Moving Work Into Other Processes
**What goes wrong:** Stubs disappear in spawned processes unless allowances are granted, which can make contract tests nondeterministic [CITED: https://hexdocs.pm/req/Req.Test.html].  
**Why it happens:** `Req.Test` is concurrent-safe, but cross-process access may require `Req.Test.allow/3` when requests happen outside the owning test process [CITED: https://hexdocs.pm/req/Req.Test.html].  
**How to avoid:** Keep Phase 8 contract tests in direct-process fake clients/stubs unless a new spawned-process test is intentional, then use allowances explicitly [CITED: https://hexdocs.pm/req/Req.Test.html].  
**Warning signs:** A test introduces `spawn/1`, a GenServer, or a task around HTTP calls and intermittent “no mock or stub” behavior appears [CITED: https://hexdocs.pm/req/Req.Test.html].

## Code Examples

Verified patterns from official and codebase sources:

### Deterministic HTTP Contract Stub
```elixir
# Source: https://hexdocs.pm/req/Req.Test.html
Req.Test.stub(MyStub, fn conn ->
  Req.Test.json(conn, %{"uid" => 101, "status" => "succeeded"})
end)
```

### Existing Shared Sync Decoration Pattern
```elixir
# Source: /Users/jon/projects/scrypath/lib/scrypath/sync.ex
{:ok,
 result
 |> Map.put(:mode, Keyword.fetch!(config, :sync_mode))
 |> Map.put(:status, result_status(config))}
```

### Existing Meilisearch Task Poll Shape
```elixir
# Source: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks
%{
  "uid" => 4,
  "status" => "succeeded",
  "type" => "documentAdditionOrUpdate"
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Permissive raw-map task normalization with unknown-status fallthrough [VERIFIED: lib/scrypath/meilisearch/tasks.ex] | Strict tuple-returning validation at backend boundaries [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md] | Phase 8 target, planned on 2026-04-16 [VERIFIED: .planning/ROADMAP.md] | Removes ambiguous “success” outcomes and makes malformed payloads explicit. |
| Backend-specific handling of empty batches by whatever path receives the call first [VERIFIED: lib/scrypath/sync.ex] | Shared public no-op envelope from `Scrypath.Sync` [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md] | Phase 8 target, planned on 2026-04-16 [VERIFIED: .planning/ROADMAP.md] | Keeps caller ergonomics and telemetry consistent across inline/manual/oban. |
| Broad live suite temptation for confidence [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md] | Focused contract tests plus narrow tagged live seam checks [VERIFIED: test/test_helper.exs] [VERIFIED: test/scrypath/live_meilisearch_verification_test.exs] | Already established by current repo and reaffirmed for Phase 8 [VERIFIED: lib/mix/tasks/verify.phase5.ex] | Better signal, faster feedback, and less flake. |

**Deprecated/outdated:**
- Relying on `"queued"` as a public normalized status is outdated for this phase; if retained for compatibility, it should collapse internally to `:enqueued` only [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md].
- Treating a malformed task map as “probably okay” is no longer acceptable for the launch-readiness milestone [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md].

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Adding Mox would increase setup cost without improving this phase materially. | Standard Stack / Don't Hand-Roll | Low; planner could still choose it, but it would widen scope. |

## Open Questions

1. **One shared parser or two helpers?**
   - What we know: The phase allows either separate enqueue/poll helpers or one stage-aware parser, as long as errors stay stable [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md].
   - What's unclear: Which split yields the cleanest internal code with the least duplication.
   - Recommendation: Plan for one internal normalization module or private helper family with explicit `stage` input, and only split if code review shows readability suffering [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md].

2. **Exact `problems` payload shape**
   - What we know: The error family and stage keys are locked, but the exact `problems` keyword shape is still discretionary [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md].
   - What's unclear: Whether to prefer field-oriented entries like `uid: :missing` or issue-oriented entries like `status: {:unknown, "weird"}`.
   - Recommendation: Keep `problems` field-oriented and deterministic so test assertions remain stable and inspectable [ASSUMED].

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All Phase 8 code and tests | ✓ [VERIFIED: local env] | `1.19.5` [VERIFIED: local env] | — |
| Erlang/OTP | All Phase 8 code and tests | ✓ [VERIFIED: local env] | `28` [VERIFIED: local env] | — |
| Mix | Test and verification commands | ✓ [VERIFIED: local env] | `1.19.5` [VERIFIED: local env] | — |
| Docker | Starting a disposable Meilisearch locally if needed | ✓ [VERIFIED: local env] | `29.3.1` [VERIFIED: local env] | Run against an external Meilisearch URL instead [VERIFIED: test/support/meilisearch_integration.ex]. |
| SQLite3 | Current live verification helper repo | ✓ [VERIFIED: local env] | `3.51.0` [VERIFIED: local env] | — |
| Meilisearch service | Tagged live verification for HARD-03 | ✗ right now [VERIFIED: local env] | — | Use contract tests for most Phase 8 work; start local Meilisearch or set `SCRYPATH_MEILISEARCH_URL` before live verification [VERIFIED: test/test_helper.exs] [VERIFIED: lib/mix/tasks/verify.phase5.ex]. |

**Missing dependencies with no fallback:**
- None for planning or unit/contract implementation [VERIFIED: local env].

**Missing dependencies with fallback:**
- Live Meilisearch service is currently absent, but the project already excludes integration tests by default and keeps most reliability coverage in fast tests [VERIFIED: test/test_helper.exs] [VERIFIED: local env].

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5` [VERIFIED: test/test_helper.exs] [VERIFIED: local env] |
| Config file | none; `test/test_helper.exs` controls integration exclusion [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/scrypath/meilisearch/tasks_test.exs test/scrypath/sync_test.exs test/scrypath/telemetry_test.exs -x` [VERIFIED: test/scrypath/meilisearch/tasks_test.exs] [VERIFIED: test/scrypath/sync_test.exs] [VERIFIED: test/scrypath/telemetry_test.exs] |
| Full suite command | `mix test` for local fast coverage, then `SCRYPATH_INTEGRATION=1 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test --include integration test/scrypath/live_meilisearch_verification_test.exs` for the live seam [VERIFIED: test/test_helper.exs] [VERIFIED: test/scrypath/live_meilisearch_verification_test.exs] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HARD-01 | Stable tuples for success, timeout, cancellation, failure, malformed payload, and transport errors in inline wait path | unit / contract | `mix test test/scrypath/meilisearch/tasks_test.exs test/scrypath/sync_test.exs -x` [VERIFIED: test/scrypath/meilisearch/tasks_test.exs] [VERIFIED: test/scrypath/sync_test.exs] | ✅ |
| HARD-02 | Shared empty-input no-op envelope across inline, manual, and oban, with telemetry metadata | unit / contract | `mix test test/scrypath/sync_test.exs test/scrypath/telemetry_test.exs -x` [VERIFIED: test/scrypath/sync_test.exs] [VERIFIED: test/scrypath/telemetry_test.exs] | ✅ |
| HARD-03 | Focused reliability surface plus narrow real-backend seam | integration + contract | `mix test test/scrypath/meilisearch/tasks_test.exs test/scrypath/sync_test.exs test/scrypath/telemetry_test.exs -x` and live command above [VERIFIED: test/scrypath/live_meilisearch_verification_test.exs] | ✅ |

### Sampling Rate
- **Per task commit:** `mix test test/scrypath/meilisearch/tasks_test.exs test/scrypath/sync_test.exs test/scrypath/telemetry_test.exs -x` [VERIFIED: test/scrypath/meilisearch/tasks_test.exs] [VERIFIED: test/scrypath/sync_test.exs] [VERIFIED: test/scrypath/telemetry_test.exs]
- **Per wave merge:** `mix test` [VERIFIED: mix.exs]
- **Phase gate:** Fast suite green plus one explicit live Meilisearch run before `/gsd-verify-work` [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md] [VERIFIED: test/scrypath/live_meilisearch_verification_test.exs]

### Wave 0 Gaps
- [ ] Expand [test/scrypath/meilisearch/tasks_test.exs](/Users/jon/projects/scrypath/test/scrypath/meilisearch/tasks_test.exs) with malformed initial payload, malformed poll payload, unknown status, missing uid, and transport-error cases [VERIFIED: test/scrypath/meilisearch/tasks_test.exs].
- [ ] Expand [test/scrypath/sync_test.exs](/Users/jon/projects/scrypath/test/scrypath/sync_test.exs) with empty-list no-op assertions for inline, manual, and oban, including “no backend call” / “no Oban insert” expectations [VERIFIED: test/scrypath/sync_test.exs].
- [ ] Expand [test/scrypath/telemetry_test.exs](/Users/jon/projects/scrypath/test/scrypath/telemetry_test.exs) with `status: :noop` and `document_count: 0` stop-metadata assertions [VERIFIED: test/scrypath/telemetry_test.exs].

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: .planning/ROADMAP.md] | — |
| V3 Session Management | no [VERIFIED: .planning/ROADMAP.md] | — |
| V4 Access Control | no [VERIFIED: .planning/ROADMAP.md] | — |
| V5 Input Validation | yes [VERIFIED: .planning/ROADMAP.md] | Strict task-payload validation in `Scrypath.Meilisearch` and `Scrypath.Meilisearch.Tasks` before result decoration [VERIFIED: lib/scrypath/meilisearch.ex] [VERIFIED: lib/scrypath/meilisearch/tasks.ex] |
| V6 Cryptography | no [VERIFIED: .planning/ROADMAP.md] | — |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed backend payload accepted as success | Tampering | Validate required keys and recognized statuses, return `{:error, {:invalid_task_payload, ...}}`, and assert those cases in contract tests [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md]. |
| Transport errors collapsed into generic success/failure ambiguity | Denial of Service | Preserve `{:error, {:transport_error, exception}}` from the client and test it with `Req.Test.transport_error/2` [VERIFIED: lib/scrypath/meilisearch/client.ex] [CITED: https://hexdocs.pm/req/Req.Test.html]. |
| Unnecessary job creation for empty batches | Denial of Service | Short-circuit `[]` in `Scrypath.Sync` before Oban enqueue or backend dispatch [VERIFIED: lib/scrypath/sync.ex] [VERIFIED: lib/scrypath/oban/enqueue.ex]. |
| High-cardinality telemetry leakage from backend-specific details on common events | Information Disclosure | Keep common telemetry limited to status/mode/count metadata and reserve backend-specific detail for backend-prefixed events [VERIFIED: lib/scrypath/telemetry.ex] [VERIFIED: test/scrypath/telemetry_test.exs]. |

## Sources

### Primary (HIGH confidence)
- [turn4view4](https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks) - Meilisearch task response shapes, `taskUid` vs `uid`, and terminal statuses
- [turn1view1](https://hexdocs.pm/req/Req.Test.html) - Req.Test concurrency, stubs, and transport-error helpers
- [https://hex.pm/packages/ecto](https://hex.pm/packages/ecto) - current Ecto package version and update date
- [https://hex.pm/packages/req](https://hex.pm/packages/req) - current Req package version and update date
- [https://hex.pm/packages/telemetry](https://hex.pm/packages/telemetry) - current Telemetry package version and update date
- [https://hex.pm/packages/oban](https://hex.pm/packages/oban) - current Oban package version and update date
- [https://hex.pm/packages/plug](https://hex.pm/packages/plug) - current Plug package version and update date
- [https://hex.pm/packages/nimble_options](https://hex.pm/packages/nimble_options) - current NimbleOptions package version and update date
- Local code and planning artifacts:
  - [sync.ex](/Users/jon/projects/scrypath/lib/scrypath/sync.ex)
  - [tasks.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch/tasks.ex)
  - [meilisearch.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch.ex)
  - [client.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch/client.ex)
  - [telemetry.ex](/Users/jon/projects/scrypath/lib/scrypath/telemetry.ex)
  - [sync_test.exs](/Users/jon/projects/scrypath/test/scrypath/sync_test.exs)
  - [tasks_test.exs](/Users/jon/projects/scrypath/test/scrypath/meilisearch/tasks_test.exs)
  - [telemetry_test.exs](/Users/jon/projects/scrypath/test/scrypath/telemetry_test.exs)
  - [live_meilisearch_verification_test.exs](/Users/jon/projects/scrypath/test/scrypath/live_meilisearch_verification_test.exs)
  - [verify.phase5.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase5.ex)

### Secondary (MEDIUM confidence)
- [prompts/elixir-best-practices-deep-research.md](/Users/jon/projects/scrypath/prompts/elixir-best-practices-deep-research.md) - tuple-first and assertive Elixir API guidance
- [prompts/elixir-opensource-libs-best-practices-deep-research.md](/Users/jon/projects/scrypath/prompts/elixir-opensource-libs-best-practices-deep-research.md) - OSS library boundary and DX guidance
- [prompts/ecto-best-practices-deep-research.md](/Users/jon/projects/scrypath/prompts/ecto-best-practices-deep-research.md) - Ecto boundary/orchestration guidance

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - current versions were verified from `mix.lock`, Hex package pages, and the repo already uses the recommended libraries [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/req].
- Architecture: HIGH - the phase is tightly constrained by the existing code seams and explicit discuss-phase decisions [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-CONTEXT.md] [VERIFIED: lib/scrypath/sync.ex].
- Pitfalls: HIGH - the main failure modes are directly observable in current code and official Req/Meilisearch docs [VERIFIED: lib/scrypath/meilisearch/tasks.ex] [CITED: https://hexdocs.pm/req/Req.Test.html] [CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks].

**Research date:** 2026-04-16
**Valid until:** 2026-05-16
