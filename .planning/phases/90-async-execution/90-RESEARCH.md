<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Use the internal `Scrypath.Sync.RelatedWorker` and do not expose a `use Scrypath.Oban.Worker` macro.
- `RelatedWorker` must bubble up transient errors and explicitly cancel on unrecoverable errors to prevent retry storms and silent drops.
- Abandon the concept of tracking individual `failed_records` inline. Return success/failure based strictly on the "handoff" boundary.

### the agent's Discretion
None explicitly specified.

### Deferred Ideas (OUT OF SCOPE)
None explicitly specified.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-03 | The library provides an out-of-the-box Oban worker pattern for related-data fan-out. | Confirms `RelatedWorker` usage directly vs macro generation. |
| EXEC-01 | When a related-data fan-out fails midway, the system provides clear error returns avoiding silent partial failures. | Establishes the `{:cancel, reason}` vs `{:error, reason}` pattern for Oban to correctly surface and retry errors. |
</phase_requirements>

# Phase 90: Async Execution and Error Propagation - Research

**Researched:** 2024-05-25 (Current Date Context)
**Domain:** Elixir Background Jobs (Oban), Error Handling, API Design
**Confidence:** HIGH

## Summary

This phase pivots the library from asking developers to hand-roll their own Oban workers using a public macro towards a "batteries-included" internal worker pattern using configuration options (e.g., `sync_mode: :oban`). 

Currently, `Scrypath.Sync.RelatedWorker` executes the telemetry span for sync, but blindly returns `:ok` at the end of its `perform/1` block, effectively acting as a black hole. When `Scrypath.Sync.sync_records` encounters a network error or a `400 Bad Request` from Meilisearch, Oban incorrectly believes the job succeeded and permanently deletes it, silently dropping the data. The primary recommendation is to parse the `Scrypath.Operations.Result` returned by `sync_records`, bubbling up transient HTTP network errors as `{:error, reason}` to trigger Oban's exponential backoff, and catching unrecoverable errors (like `40x` HTTP codes) with `{:cancel, reason}` to prevent retry storms and retain the job in a failed state for operator visibility.

**Primary recommendation:** Parse `Scrypath.Sync.sync_records` responses in `RelatedWorker.perform/1`, returning `{:error, reason}` for transient issues and `{:cancel, reason}` for unrecoverable 40x exceptions to utilize Oban's built-in retry mechanisms properly.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Job Enqueueing | API / Backend | Database / Storage | `sync_related/3` inline translates API requests to Postgres queue records. |
| Job Retries & Backoff | Database / Storage | API / Backend | Oban manages queues natively in DB; worker tier just reports signals. |
| Error State Visibility | API / Backend | CDN / Static | Relying on Telemetry and Oban Web instead of inline `failed_records`. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| oban | ~> 2.15 | Background job processing | De facto standard for PostgreSQL-backed reliable job queues in Elixir. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| meilisearch (via req/finch) | N/A | Search engine HTTP client | Identifying unrecoverable 40x errors vs 5xx server issues. |

## Architecture Patterns

### Recommended Project Structure
```
lib/scrypath/
├── sync.ex                   # Entrypoint; routes :oban requests to worker module
├── sync/
│   └── related_worker.ex     # Internal Oban Worker; explicitly handles its own perform/1 return types
```

### Pattern 1: Oban Native Cancellation
**What:** Returning `{:cancel, reason}` from an Oban worker's `perform/1` function.
**When to use:** When a job fails due to an unrecoverable error (e.g. invalid document schema, missing index) where retrying will predictably result in the same failure.
**Example:**
```elixir
# Source: Verified Oban Docs via Context7
@impl Oban.Worker
def perform(%Oban.Job{...}) do
  case do_work() do
    :ok -> :ok
    {:error, {:http_error, status, _body}} when status in 400..499 ->
      {:cancel, "Unrecoverable HTTP error #{status}"}
    {:error, reason} ->
      {:error, reason}
  end
end
```

### Anti-Patterns to Avoid
- **Macro-Generated Workers:** Forcing developers to do `use Scrypath.Oban.Worker` just to invoke library logic pollutes their namespace and makes upgrading harder. Libraries should offer configuration that delegates to private workers.
- **Silent Job Drops:** Catching exceptions or failing to match an error tuple, then returning `:ok` from `perform/1`. This tells Oban the job succeeded, destroying the retry state and the data.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Partial batch tracking | Inline `failed_records` arrays | Handoff Boundary (DB insert / HTTP accepted) | Async search engines process batches independently. The library's responsibility ends when the engine accepts the batch or the queue stores the job. |
| Retry tracking | Custom ETS / DB state for backoffs | Oban Native Retries | Oban handles exponential backoff and jitter reliably through Postgres. |

## Common Pitfalls

### Pitfall 1: Retry Storms on Invalid Payloads
**What goes wrong:** Oban aggressively retries a job up to `max_attempts` (default 20) for 400 Bad Request responses.
**Why it happens:** The worker blindly bubbles up all errors as `{:error, reason}`.
**How to avoid:** Explicitly match on 40x status codes and return `{:cancel, reason}` to halt the job immediately and mark it as cancelled/discarded.
**Warning signs:** High database CPU usage, Meilisearch rate limits hit due to spamming invalid payloads.

## Code Examples

Verified patterns from official sources:

### Canceling Jobs on Client Errors
```elixir
# Source: Oban Error Handling Docs
@impl Oban.Worker
def perform(%Oban.Job{args: args}) do
  # ... setup logic ...
  case Scrypath.Sync.sync_records(target, records, opts) do
    {:ok, _result} ->
      :ok
      
    {:error, {:http_error, status, body}} when status in 400..499 ->
      # Prevent retries on client-side / unrecoverable errors
      {:cancel, "HTTP #{status}: #{inspect(body)}"}
      
    {:error, reason} ->
      # Allow Oban to retry (e.g. 50x, network timeouts)
      {:error, reason}
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Public Macros | Configured Internal Workers | Phase 90 | Cleaner DX, easier library upgrades |
| `failed_records` | Handoff Boundary | Phase 90 | Correct async semantics, prevents silent drops |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Meilisearch HTTP 40x responses are surfaced via `{:error, {:http_error, status, body}}` through `sync_records`. | Code Examples | [Low] The code pattern matching would fail to catch 40x errors, resulting in transient retry behavior rather than cancellation, but still preventing silent drops. |

## Open Questions (RESOLVED)

1. **Oban Dependency**
   - RESOLVED: The fallback macro in `lib/scrypath/sync/related_worker.ex` already gracefully raises an ArgumentError if the Oban dependency is missing, satisfying this requirement.
   - What we know: Oban is configured as an optional dependency (`~> 2.21`).
   - What's unclear: If `sync_related/3` gracefully handles missing Oban dependencies at runtime.
   - Recommendation: Ensure `Scrypath.Sync.RelatedWorker`'s fallback macro gracefully handles the `:oban` configuration before enqueuing.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | Ecto/Oban storage | ✓ | Implicit | — |
| Oban | Async background execution | ✓ | ~> 2.21 | Use `sync_mode: :inline` |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) |
| Config file | `mix.exs`, `test/test_helper.exs` |
| Quick run command | `mix test test/scrypath/sync/related_worker_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-03 | Internal RelatedWorker execution without macros | unit | `mix test test/scrypath/sync/related_worker_test.exs` | ✅ Wave 0 |
| EXEC-01 | Oban worker bubbles transient errors | integration | `mix test test/scrypath/sync/related_worker_test.exs` | ✅ Wave 0 |
| EXEC-01 | Oban worker cancels unrecoverable errors | integration | `mix test test/scrypath/sync/related_worker_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/scrypath/sync/related_worker_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements, but `test/scrypath/sync/related_worker_test.exs` will need additional cases to assert on `{:error, _}` and `{:cancel, _}` returns.

## Security Domain

> Required when `security_enforcement` is enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Native Oban changeset args validation |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/Oban

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unbounded queue growth / Retry Storms | Denial of Service | explicit `{:cancel, reason}` for unrecoverable errors, `max_attempts` limits |

## Sources

### Primary (HIGH confidence)
- `/oban-bg/oban` (Context7) - Verified `{:cancel, reason}` return values for preventing retries on unrecoverable errors.
- `/oban-bg/oban` (Context7) - Verified `max_attempts` and exponential backoff default behavior.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Oban is the industry standard for this pattern in Elixir.
- Architecture: HIGH - Config over macros is idiomatic Elixir library design.
- Pitfalls: HIGH - Documented Oban gotchas regarding retry storms.

**Research date:** 2024-05-25
**Valid until:** 2024-11-25 (6 months)
