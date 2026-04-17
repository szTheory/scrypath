# Deep Research: Operator Polish and Drift Recovery Guide (v1.3 Phase 22)

**Milestone:** scrypath v1.3 — "Search Power That Phoenix Teams Reach For"
**Phase target:** richer `%FailedWork{}` + drift recovery guide (operator polish, NO surface expansion)
**Researched:** 2026-04-17
**Confidence:** HIGH

---

## Executive Recommendation

Ship the smallest set of additive `%FailedWork{}` fields that turns "a string reason" into "an operator-actionable classification", plus a markdown drift-recovery runbook that chains existing `Scrypath.*` verbs. No new public API verbs. No new Mix tasks. No new modules.

**Five concrete recommendations:**

1. **`reason_class` enum = 5 values: `:transport | :validation | :backend_rejected | :queue_exhausted | :unknown`.** Smallest honest set that makes the next-action unambiguous. `:throttled`, `:timeout`, `:auth` fold into `:transport`; `:queue_discard` and retry-exhaustion collapse to one class (`:queue_exhausted`) because they produce the same operator action. `:unknown` is not a failure mode — it is the honest default when we cannot classify reliably, and it must remain cheap to emit.

2. **Add 4 fields, all optional, all outside `@enforce_keys`, populated from already-flowing data:** `attempt`, `max_attempts`, `reason_class`, `last_attempt_at`. Keep the existing `failed_at` field populated for backward compatibility (it becomes a soft alias for `last_attempt_at` — same value, kept to avoid breaking any v1.2 consumer pattern-matching on `failed_at`). This collapses question 3 and 4 into a single answer.

3. **For inline failures, `attempt` and `max_attempts` stay `nil`.** Inline sync has no retry concept — surfacing `1/1` would be a lie, and config-dependent values would leak Scrypath internals. `nil` is self-describing: "the source system does not expose this."

4. **Drift recovery guide uses the SRE-standard symptom→diagnosis→action→verify layout**, as eight numbered scenarios, each pointing at a concrete `mix scrypath.*` chain. No decision tree (brittle), no runbook-per-symptom folder (wrong scale for a single-guide artifact).

5. **Telemetry: emit ONE new event, `[:scrypath, :operator, :failed_work, :observed]`, with `reason_class` in measurements metadata. No retry/reconcile telemetry in v1.3** — that is a separate design decision that deserves v1.4 scoping against real adopter signal.

Downstream: 5 REQ-IDs (OPS-05..OPS-09), detailed in the REQ-IDs section below.

---

## Reference Pattern Survey

| Reference | Error taxonomy | Attempt model | How exhaustion surfaces | What Scrypath adopts | What Scrypath rejects |
|---|---|---|---|---|---|
| **Oban** (v2.21) | None — free-text error tuples + `kind` (`:error | :exit | :throw`); user-supplied via `Oban.PerformError`; state enum `:scheduled | :available | :executing | :retryable | :completed | :cancelled | :discarded | :suspended` | Native `attempt` + `max_attempts` integers on `Oban.Job`; default `max_attempts: 20`; `errors: [%{at, attempt, error}]` list | `:discarded` reached via EITHER retry exhaustion OR explicit `:discard` tuple; use `errors` list length + last attempt to distinguish | `attempt`/`max_attempts` field names (lift directly from Oban.Job); the retryable-vs-exhausted distinction expressed via `reason_class: :queue_exhausted` when `state == :discarded` | Eight-state enum (too rich — Scrypath operator UX collapses to `:failed | :retrying`); `errors` list history (Scrypath stays single-summary) |
| **Sidekiq** (Ruby, v7+) | Free-text exception class + backtrace; no enum; fingerprinting is Pro-only | `retry_count` (starts at 0, first retry `retry_count: 1`); fixed formula 15→16→31→96... seconds; hard cap of 25 before Dead Set | `sidekiq_retries_exhausted` hook fires, then job moves to Dead Set (capped at 10k or 6mo); operator must manually retry via UI | The exhaustion hook concept (Scrypath's `reason_class: :queue_exhausted` is the analog); Sidekiq's "manual retry from a stable id" pattern matches Scrypath's existing `retry_sync_work/2` | Dead Set as a distinct queue (Oban uses `discarded` state instead — Scrypath follows Oban because that is its substrate); exponential backoff as library concern (Scrypath delegates to Oban) |
| **AWS SQS + DLQ** | Application-classified: transient / permanent / unknown ("tag your failures") | `maxReceiveCount` on the redrive policy; no in-message attempt field — the broker counts receives | DLQ on receive-count exhaustion; message sits there until operator replay | Transient/permanent/unknown as the **shape** of the taxonomy (HIGH influence on the 5-class recommendation); the "archive with enough context to debug later" principle maps onto Scrypath's `metadata: map()` | DLQ as a separate queue product (Scrypath has no queue, it reads from Oban which is the DLQ-equivalent already); explicit redrive operation (Scrypath has `retry_sync_work/2`) |
| **GCP Pub/Sub** | Ack deadline miss → redelivery; `NACK` → immediate redelivery; dead-letter topic after `maxDeliveryAttempts` | Delivery attempt count on the message | Dead-letter topic + Cloud Logging severity | — | Push/pull distinction (not relevant to Scrypath) |
| **Kafka consumers** | Application-handled; poison pill pattern; dead-letter topic convention | Offset-based; no built-in attempt count | Consumer skips + writes to DLT | The "poison payload" concept maps onto `retryable?: false` | All of Kafka's operational model (out of scope) |
| **Meilisearch task errors** (v1.15) | Three buckets: `invalid_request` / `internal` / `auth`. Specific codes include `invalid_document_id`, `invalid_filter`, `malformed_payload`, `invalid_index_uid`, `invalid_swap_indexes` (all `invalid_request`); `database_size_limit_reached`, `invalid_state`, `io_error`, `no_space_left_on_device`, `document_fields_limit_reached` (all `internal`); `missing_authorization_header`, `invalid_api_key` (all `auth`) | Meilisearch tasks do not retry internally; each task is terminal from Meilisearch's POV. Attempt is a Scrypath-side concept only when the job sits in Oban. | Failed task stays in the Meilisearch task log with `error: {code, message, type, link}` | The three-category shape (HIGHEST influence): Meilisearch `invalid_request` → Scrypath `:validation`; Meilisearch `internal` → Scrypath `:backend_rejected`; Meilisearch `auth` folds into `:transport` (auth is a transport-layer problem from Scrypath's vantage); Meilisearch's `error.code` string goes into `metadata.error_code` for deep-dive | Exposing every Meilisearch code as its own `reason_class` value (would create 20+ values that drift as Meilisearch adds codes — a guaranteed maintenance burden that delivers no operator action difference) |
| **HTTP 4xx/5xx** | 4xx = client error (don't retry without fix); 5xx = server error (retry may help); 429 = throttled | — | — | The "fix vs retry" split is the core insight — it maps cleanly to `:validation` (fix your data) vs `:transport`/`:backend_rejected` (retry may help) | Splitting `:transport` further by HTTP status code (adds noise without changing next action) |
| **Postgres PGERROR / SQLSTATE** | 5-char SQLSTATE (`08xxx` = connection, `22xxx` = data exception, `23xxx` = integrity violation, `40xxx` = transaction rollback, `53xxx` = resource, `XX` = internal) | — | — | The principle: group codes by **operator action**, not by surface cause. Scrypath's 5-class set mirrors Postgres's own "class" (the first two SQLSTATE chars) — Postgres itself rolls up 200+ codes into ~40 classes | Full SQLSTATE granularity (wrong scale for a library that does not own the error source) |
| **Oban docs** (troubleshooting) | Prose pages titled "Error Handling", "Job Lifecycle", "Troubleshooting" — structured as numbered problems, each with a symptoms/cause/fix paragraph | — | — | Voice (direct, short, example-heavy); structure (numbered problem-per-section within a single page); the explicit discouragement of rich error taxonomies | — |
| **Kubernetes troubleshooting docs** | Symptom lists ("pod stuck in CrashLoopBackOff", "pending forever"), each with a diagnosis path + commands | — | — | The symptom-anchored structure; copy-pasteable commands; verify-after step | The "events first" timeline framing (Scrypath has no event timeline — the analog is `sync_status/2` + `reconcile_sync/2`) |
| **Elasticsearch "Common problems" guide** | Symptom-anchored pages with "What's happening" / "What to do" / "How to verify" sections | — | — | The exact three-section template per scenario | Elastic's escalation-to-support section (not applicable to OSS library) |

**Strongest reference:** Google SRE book's standard runbook shape (symptom → diagnosis → remediation → verification → escalation) combined with Oban docs' short, direct voice. Worst reference for Scrypath's scale: Kafka/Pub/Sub's multi-topic-with-broker-side-counting model — irrelevant because Scrypath delegates retry accounting to Oban.

---

## `reason_class` Canonical Enum (with value-by-value justification)

**Recommended set (5 values):**

```elixir
@type reason_class ::
        :transport
        | :validation
        | :backend_rejected
        | :queue_exhausted
        | :unknown
```

### `:transport`

**Definition:** The operation never landed at the backend — or landed and disconnected — due to network, auth, rate-limiting, or timeout at the HTTP/transport layer.

**What an operator does next:** retry (`Scrypath.retry_sync_work/2`); if the class persists across retries, check `Scrypath.sync_status/2` for broader backend health and the Meilisearch server logs.

**What populates it from Meilisearch tasks:** task payloads where the task never ran because the request was rejected pre-task (rare — Meilisearch usually accepts and queues); Scrypath's own `Req` transport errors captured before a task id is assigned flow through `from_queue_job/3`, not `from_backend_task/3`.

**What populates it from Oban jobs:** `errors` list entries whose first line matches transport-layer patterns — `Req.TransportError`, `Mint.TransportError`, HTTP status 401/403/408/429/5xx, `:timeout`, `:closed`. Scrypath's classifier uses a short match table (see "Classification strategy" below).

**Folded-in concepts:** `:timeout`, `:throttled`, `:auth`. Rationale: every one of these produces the same operator action (retry, escalate if repeated). Splitting them buys zero triage differentiation; it triples the classifier surface that drifts with Meilisearch/Req upstream changes.

**HTTP 4xx/5xx mapping:** 4xx `auth` (401/403) + 408 timeout + 429 throttled + all 5xx → `:transport`. Pure "data is wrong" 4xx (400 malformed_payload, 422) → `:validation` (see below).

### `:validation`

**Definition:** The operation reached the backend or the queue worker, but the payload itself is malformed or violates a declared schema constraint. Retrying without fixing the data will not help.

**What an operator does next:** DO NOT retry. Inspect `reason` + `metadata.error_code` (Meilisearch) to identify the offending field; fix the schema declaration or source data; reindex if the fix is schema-level. Surface a `retryable?: false` on the FailedWork entry to signal this loudly.

**What populates it from Meilisearch tasks:** Meilisearch `error.type == "invalid_request"` with codes `invalid_document_id`, `invalid_filter`, `malformed_payload`, `invalid_index_uid`, `invalid_swap_indexes`, `missing_document_id`, `invalid_document_filter`. These are the Meilisearch bucket where the next action is ALWAYS "fix the payload or the schema", never "retry".

**What populates it from Oban jobs:** `errors` list entries matching `Ecto.CastError`, `ArgumentError` raised from `Scrypath.Projection`, `Scrypath.Document` construction failures, and any Scrypath-raised `ArgumentError` from the options validator caught at worker time.

**Why this deserves its own class and not `:backend_rejected`:** the operator action is materially different. A `:validation` failure is a bug in the caller's data or schema — retry is wrong; a `:backend_rejected` failure may be retryable once the backend recovers. Merging them would push operators toward the wrong action.

### `:backend_rejected`

**Definition:** The backend accepted the request, attempted to process it, and failed for internal reasons that are not the caller's fault: out of disk, index in corrupt state, resource limits exceeded, internal engine error.

**What an operator does next:** check backend health (not Scrypath); likely server-side intervention (free disk, restart, rebuild index). Retry is usually safe but only after the backend condition clears. A reindex may be required if the index is in an invalid state.

**What populates it from Meilisearch tasks:** `error.type == "internal"` with codes `database_size_limit_reached`, `invalid_state` (index corrupt, re-index required), `io_error`, `no_space_left_on_device`, `document_fields_limit_reached`, `dump_process_failed`, `internal_error`. Everything the Meilisearch docs bucket as "internal".

**What populates it from Oban jobs:** worker exceptions whose message matches "index is in an invalid state", "Meilisearch server error 5xx" that the classifier already handed to `:transport` (precedence: transport wins on 5xx; `:backend_rejected` requires a parsed Meilisearch error response).

**Precedence rule:** if a response carries BOTH transport-level failure markers AND a parsed Meilisearch `error.type`, prefer `:transport` — the operator's first-response action (retry later) is the same for both, but "transport" correctly signals the failure may have been the network hop, not the backend engine. The `metadata.error_code` field carries the Meilisearch code either way for deep-dive.

### `:queue_exhausted`

**Definition:** An Oban job reached `:discarded` state — either through retry exhaustion (`attempt >= max_attempts`) or through an explicit `:discard` return — and will not be retried without operator action.

**What an operator does next:** inspect the retry history in `reason`; decide whether the underlying data is still valid to replay; if yes, use `Scrypath.retry_sync_work/2` (which the recovery action already supports); if no, fix the data or schema first.

**What populates it from Meilisearch tasks:** never — Meilisearch tasks do not carry attempt history.

**What populates it from Oban jobs:** job state is `:discarded` (or the string `"discarded"`) AND the last error entry in `errors` does not already classify as `:validation` or `:backend_rejected` more specifically. When the last error DOES fit another class, that class takes precedence — `:queue_exhausted` is the rollup when exhaustion is the only thing we can say for sure.

**Why merge `:queue_discard` and exhausted retries into one class:** both surface the same operator decision ("this job is not coming back on its own — look at it"). Splitting them into two values doubles the classifier code while providing no action differentiation. The `metadata.discard_reason` field (new, optional) can carry `:exhausted | :explicit` for operators who want to know.

### `:unknown`

**Definition:** Scrypath's classifier could not confidently map the failure to one of the four concrete classes.

**What an operator does next:** inspect `reason` (free text, as in v1.2) and `metadata` directly. `:unknown` is a flag to the operator that this entry needs eyeball triage, not an automatic action hint.

**What populates it:** the classifier's default branch — any error that didn't match one of the four concrete classes. This is also the honest default for `from_backend_task/3` and `from_queue_job/3` if the error payload is missing or shaped unexpectedly.

**Important: `:unknown` is not a failure of the classifier — it is the classifier telling the truth.** The anti-feature list in FEATURES.md is explicit: "Rich failure taxonomy with 20+ error classes … wrong classes are worse than `:unknown`". We want `:unknown` to be cheap to emit and honestly common until we have adopter-reported failure corpora to calibrate against.

### What's lost by 3 values instead of 5?

A 3-value set (`:transient | :permanent | :unknown`, following SQS's taxonomy) loses:

- the validation-vs-backend distinction (collapsed to `:permanent`) — this erases the actionable difference between "fix your data" and "wait for the backend to recover".
- the queue-exhaustion signal (collapsed to `:permanent`) — this erases the "look at retry history" prompt that differentiates Oban-mode triage from inline-mode triage.

A 3-value set is honest but unhelpful. 5 values is the smallest count at which `reason_class` drives the next action by itself, without the operator having to re-read `reason` to decide.

### What's gained by adding `:throttled` / `:timeout` / `:auth`?

Nothing that the operator does differently. The first-response action is identical ("retry; escalate if persistent"). The `metadata.error_code` + the free-text `reason` already tell the operator *why* the transport failed. Making these first-class classes triples the classifier surface for zero triage leverage.

**Verdict: 5 values. The 3-value set is too coarse; the 8-value set is too granular for the adopter tier v1.3 targets (growth-stage Phoenix SaaS, not enterprise search-ops).**

### Classification strategy (for the Phase 22 plan to adopt)

Keep the classifier in `Scrypath.Operator.FailedWork` — not a new module. Two pure functions:

```elixir
@spec classify_backend_error(raw :: map()) :: reason_class()
@spec classify_queue_error(error_message :: String.t() | nil, state :: atom()) :: reason_class()
```

Both are deterministic pattern-matching over known shapes:
- `classify_backend_error/1` reads Meilisearch's `error.type` + `error.code` and maps to the 5-class set.
- `classify_queue_error/2` matches short prefix patterns in the error message (Oban stores errors as `Exception.format/3`-rendered strings, so prefix matching is reliable) and checks the Oban state.

Both have an explicit `:unknown` fallback branch.

---

## `FailedWork` Struct Evolution (before/after diff)

### Current (v1.2, shipped in `scrypath 0.3.0`)

```elixir
@enforce_keys [:id, :schema, :mode, :source, :operation, :state, :retryable?]
defstruct [
  :id, :schema, :mode, :source, :operation, :state, :retryable?,
  :reason, :failed_at,
  recovery: nil,
  metadata: %{}
]
```

### Proposed (v1.3, additive only)

```elixir
@enforce_keys [:id, :schema, :mode, :source, :operation, :state, :retryable?]
defstruct [
  :id, :schema, :mode, :source, :operation, :state, :retryable?,
  :reason, :failed_at,
  recovery: nil,
  metadata: %{},
  # NEW v1.3 — all optional, all outside @enforce_keys
  attempt: nil,           # non_neg_integer() | nil — current attempt number (Oban-sourced, nil elsewhere)
  max_attempts: nil,      # non_neg_integer() | nil — retry ceiling (Oban-sourced, nil elsewhere)
  reason_class: :unknown, # one of :transport | :validation | :backend_rejected | :queue_exhausted | :unknown
  last_attempt_at: nil    # DateTime.t() | nil — alias-equivalent of failed_at; see discussion below
]
```

### Field-by-field semantics

| Field | Added | Type | Default | Source of truth | When `nil`/default |
|---|---|---|---|---|---|
| `attempt` | **new** | `non_neg_integer() \| nil` | `nil` | `Oban.Job.attempt` | Inline + manual modes; Meilisearch-task-only failures |
| `max_attempts` | **new** | `non_neg_integer() \| nil` | `nil` | `Oban.Job.max_attempts` | Inline + manual modes; Meilisearch-task-only failures |
| `reason_class` | **new** | `reason_class()` atom | `:unknown` | Classifier over `raw` (backend task) or `errors` list (queue job) | When classifier cannot confidently decide |
| `last_attempt_at` | **new** | `DateTime.t() \| nil` | `nil` | Meilisearch `finishedAt` (task) OR Oban `attempted_at` (job) | When the source did not record one |
| `failed_at` | **existing** | `DateTime.t() \| nil` | `nil` | Same sources as `last_attempt_at` | — |

### `failed_at` vs `last_attempt_at` — crystal-clear resolution

**They are populated to the same value in v1.3.** Both equal `DateTime.t()` of the last recorded attempt. Here is why both exist and neither is dropped:

- **`failed_at` is kept as-is for backward compatibility.** The v1.2 docstring says "when the sync work was last observed to fail"; `scrypath 0.3.0` consumers pattern-match this field. Removing it or renaming it is a breaking struct change.
- **`last_attempt_at` is added because its name is unambiguous.** `failed_at` sounds like "when the original failure happened" (once), but Oban's `attempted_at` semantics are actually "when the most recent attempt ended" — every retry updates it. The v1.3 docstring on `last_attempt_at` says exactly that, eliminating ambiguity for new readers.

**Contract for v1.3:** `last_attempt_at == failed_at` always. If a future Scrypath version distinguishes "original failure timestamp" from "last retry timestamp", it will keep both fields populated-separately but never break the equality for v1.3-shaped data.

**Deprecation posture:** `failed_at` is NOT deprecated in v1.3. The guide and new docstrings steer readers toward `last_attempt_at`, but `failed_at` remains a first-class field for as long as Hex 0.x consumers may pattern-match on it. A soft `@deprecated` may be considered at the v2.0 semver boundary; v1.3 does not commit to that.

### Inline-failure semantics (question 2)

**Recommendation: `attempt: nil, max_attempts: nil` for all inline-mode failures.**

Reasoning:
- `1/1` is a lie. Inline has no retry — the first failure IS the final failure. Surfacing `1/1` implies a retry model that does not exist and invites an operator to look for retry telemetry that is not there.
- `nil/nil` is self-describing. Combined with `mode: :inline`, the operator reads "this is inline, attempts aren't a thing" without needing extra docs.
- Config-dependent values (e.g., if inline retries are ever added as a config option) would leak implementation detail. `nil` is forward-compatible.
- Oban-mode failures that somehow land without an `attempt` in the job record (shouldn't happen, but defensive coding) also fall through to `nil`. The `nil` path must not crash downstream code.

**Manual mode** gets the same treatment (`nil/nil`): manual sync returns accepted work immediately and relies on operator-managed retry, which Scrypath does not count internally.

### Retry exhaustion signal (question 5)

When `attempt >= max_attempts` in an Oban-mode failure:
- `state` remains `:failed` (the existing value) to avoid breaking pattern-matches. `:retrying` stays reserved for the intermediate state (`Oban.Job.state == "retryable"`).
- `retryable?` is set `false` by the classifier when the underlying job is `:discarded`.
- `reason_class` is set `:queue_exhausted` (unless a more specific class like `:validation` applies to the last error).
- `metadata.discard_reason` is populated with `:exhausted` or `:explicit`. This is a new optional metadata key, not a struct field — no contract change.

The operator reads this as: "`state: :failed, retryable?: false, reason_class: :queue_exhausted, attempt: 20/20` — Oban gave up; either fix the underlying data and manually enqueue, or accept the loss." That is honest and actionable.

Reference: Oban surfaces `:discarded` as a terminal state (fail and exhaust OR return `:discard` tuple); Sidekiq's Dead Set is the analog. Scrypath's `reason_class` is the single signal that lets an operator distinguish "try again" from "look at it".

### Backward compatibility (question 4) — summary

- All 4 new fields are outside `@enforce_keys`: additive, non-breaking.
- `failed_at` preserved verbatim, same semantics, same type.
- `@type t` widens the map type with optional fields — Dialyzer contract remains compatible (widening, not narrowing).
- No Hex major bump required. v1.3 ships as a minor (`0.4.0`) per release-please's conventional-commits routing.
- Every 0.3.0 consumer that pattern-matches `%FailedWork{retryable?: true}` keeps working unchanged. Every `struct!/1` call in existing tests continues to pass. No legacy_shape helper needed.

**Regression test required:** a compile-time struct-shape test that pins the 0.3.0 key set and asserts every new key has a benign default. This directly addresses PITFALLS.md P3.

---

## Drift Recovery Guide — Structure + Scenario List

### Layout decision: symptom-anchored runbook in one file

**Adopted format:** SRE-standard symptom → diagnosis → action → verify, as numbered scenarios within a single markdown file. Each scenario is ≤ 1 screenful with copy-paste commands.

**Rejected alternatives:**
- **Decision tree** (start node → branch questions → leaf action): brittle under growth, bad for 3am reading when you already know your symptom but need the resolution fast. Operators don't enter at the root — they enter at "search shows stale data".
- **Runbook-per-symptom folder** (`guides/drift/index-empty.md`, `guides/drift/stale-results.md`, ...): wrong scale for 6-8 scenarios. The cross-references between scenarios are dense; folder split kills that.
- **Long narrative walkthrough**: reads nicely, useless when paging at 3am. Oban's own troubleshooting docs prove short, symptom-anchored sections win.

**Voice reference:** Oban's "Error Handling" and "Job Lifecycle" hexdocs pages — direct, short paragraphs, example commands dominant.

**Structural reference:** Google SRE book's "Runbooks" chapter; Kubernetes troubleshooting page shape; Elasticsearch "Common problems" layout.

### Proposed file: `guides/drift-recovery.md`

**Proposed table of contents:**

```markdown
# Drift Recovery Runbook

> A symptom-anchored guide for operators triaging Scrypath drift in production.
> Each scenario: what you see → what it likely is → what to run → how to verify.
> All commands are the same `mix scrypath.*` tasks that ship with Scrypath —
> this guide does not introduce new operator verbs.

## Before you start: three reads that ground every scenario

1. `mix scrypath.status MyApp.Schema` — what the backend and queue actually look like right now
2. `mix scrypath.failed MyApp.Schema` — what work did not land, and why
3. `mix scrypath.reconcile MyApp.Schema` — a rolled-up report with recommended actions

Every scenario below assumes you have already run these three.

## The six scenarios

1. Index exists but hits zero documents
2. Sync reported success but search returns stale records
3. Backfill ran but document count diverges from the database row count
4. Failed-work queue piling up (but the entries are retryable)
5. Settings drift after external mutation (facets missing, ranking wrong)
6. Reindex stuck mid-cutover

## Appendix A: Reading the new `FailedWork.t()` fields

[Brief explanation of `reason_class`, `attempt`/`max_attempts`, `last_attempt_at`.]

## Appendix B: When `reason_class: :unknown` keeps recurring

[How to collect a sample for a GitHub issue. See question 8.]
```

### Scenario-by-scenario expansion

Every scenario follows the same four-section template: **Symptom** → **Diagnosis** → **Action** → **Verify**. The Phase 22 plan will flesh out exact shell output; this research locks the scenario set and command chain.

#### Scenario 1 — Index exists but hits zero documents

- **Symptom:** Search against the index returns `hits: []` for queries you know should match. `mix scrypath.status` shows the live index name correctly but `last_succeeded` is `nil` or stale.
- **Diagnosis:** The index was created (by Scrypath or external tooling) but never populated, OR a reindex created a new target and swapped to it before backfill completed.
- **Action:**
  ```bash
  mix scrypath.status MyApp.Schema
  mix scrypath.reconcile MyApp.Schema
  # If reindex visibility shows cutover: :completed with task_state: :idle and zero documents:
  iex> Scrypath.backfill(MyApp.Schema, repo: MyApp.Repo)
  ```
- **Verify:** `mix scrypath.status` shows non-nil `last_succeeded` in backend section; a sampled search returns hits.

#### Scenario 2 — Sync reported success but search returns stale records

- **Symptom:** `Scrypath.sync_*/2` returned `{:ok, _}` for your last write, but `Scrypath.search/3` still returns an old version of the document (or hits for a deleted document).
- **Diagnosis:** In `:oban` mode, `{:ok, _}` means durable enqueue — not search visibility. The job may still be processing, retrying, or have landed in `:discarded`. In `:inline` mode, the backend accepted the task but eventual consistency has not converged yet.
- **Action:**
  ```bash
  mix scrypath.status MyApp.Schema       # check backend.pending and queue state
  mix scrypath.failed MyApp.Schema       # check for a recent entry for this schema
  # Inspect the FailedWork entries by reason_class:
  #   :queue_exhausted → the job gave up; retry or fix data
  #   :validation      → the payload is bad; fix before retrying
  #   :backend_rejected → server-side issue; check Meilisearch
  #   :transport       → retry
  iex> Scrypath.retry_sync_work(MyApp.Schema, id: 601)
  ```
- **Verify:** The specific document's search result reflects the intended state; `mix scrypath.status` shows the work moved from `pending`/`retrying` to success.

#### Scenario 3 — Backfill ran but document count diverges from database row count

- **Symptom:** `Scrypath.backfill/2` returned `{:ok, %{documents: N}}` but the backend index document count is `M ≠ N`, or the database has `K ≠ N` rows.
- **Diagnosis:** Three common causes: (a) source rows that projected to `nil` documents (filtered out at projection time); (b) failed individual document upserts within the batch that returned a warning instead of a hard error; (c) concurrent writes during backfill that the batch did not see.
- **Action:**
  ```bash
  mix scrypath.reconcile MyApp.Schema
  # If drift_signals includes :failed_sync_work, the discrepancy is likely (b):
  mix scrypath.failed MyApp.Schema
  # For (a) or (c), run a report-first reconcile and consider:
  iex> Scrypath.reindex(MyApp.Schema, cutover?: false, repo: MyApp.Repo)
  # cutover?: false lets you inspect the target index before switching live traffic.
  ```
- **Verify:** Target index document count matches the expected row count (from your own `Repo.aggregate(Schema, :count)`).

#### Scenario 4 — Failed-work queue piling up (but entries are retryable)

- **Symptom:** `mix scrypath.failed` returns many entries, most with `retryable?: true` and `reason_class: :transport` or `:backend_rejected`.
- **Diagnosis:** A transient backend outage or rate-limit event created a burst of failures. Oban is retrying, but new failures are arriving faster than retries succeed.
- **Action:**
  ```bash
  mix scrypath.status MyApp.Schema
  # If backend.pending is growing and failed work has :transport class:
  mix scrypath.failed MyApp.Schema
  # Retry specific high-value entries:
  iex> Scrypath.retry_sync_work(MyApp.Schema, id: 601)
  # Do NOT loop retry_sync_work in a tight script — Oban already backs off.
  # Check Meilisearch health (rate limits, disk space, server logs) before mass retry.
  ```
- **Verify:** `mix scrypath.status` shows `backend.pending` shrinking and `last_succeeded` moving forward; failed-work count decreasing over time.

#### Scenario 5 — Settings drift after external mutation

- **Symptom:** Facet queries return empty `facet_distribution`; or relevance rules that you declared at the schema level are not reflected in search results. `mix scrypath.reconcile` reports unexpected drift signals.
- **Diagnosis:** Someone (or some tooling) applied Meilisearch settings directly to the live index, overriding the schema-declared settings. Scrypath's reindex path is the ONLY blessed path for settings mutation (see PITFALLS.md P5) — any other path causes this drift.
- **Action:**
  ```bash
  mix scrypath.reconcile MyApp.Schema
  # reconcile will flag setting drift in v1.3 (P2 differentiator from FEATURES.md).
  # To repair:
  iex> Scrypath.reindex(MyApp.Schema, cutover?: true, repo: MyApp.Repo)
  # This creates a new target index with the declared settings, backfills,
  # and swaps — the same ordered pipeline reindex always runs.
  ```
- **Verify:** Facet queries return populated distributions; ranking behavior matches declared rules. Inspect `Scrypath.Meilisearch.*` escape-hatch to confirm target-index settings match schema declarations.

#### Scenario 6 — Reindex stuck mid-cutover

- **Symptom:** `mix scrypath.reconcile` shows `reindex.task_state: :pending` or `reindex.cutover: :pending` for longer than expected; `mix scrypath.status` shows live index serving but you cannot tell if a rebuild is progressing.
- **Diagnosis:** Either a legitimate long-running backfill, OR the cutover task failed and left the target index orphaned, OR a Meilisearch server restart dropped the in-flight task.
- **Action:**
  ```bash
  mix scrypath.reconcile MyApp.Schema
  # If reindex.last_task.state == :failed or :pending for too long:
  iex> Scrypath.reconcile_sync(MyApp.Schema)
  # For recovery with a clean slate:
  iex> Scrypath.reindex(MyApp.Schema, cutover?: false, repo: MyApp.Repo)
  # cutover?: false lets you verify the target before committing.
  ```
- **Verify:** `mix scrypath.reconcile` reports `task_state: :completed` and `cutover: :completed`; the live index returns expected results after swap.

### What the guide deliberately does NOT introduce

- No `Scrypath.recover/2` verb. The guide is a composition tutorial over existing verbs, per the non-goal locked in the milestone context and PROJECT.md Out of Scope.
- No new Mix tasks. Every command chain uses the four existing `mix scrypath.{status, failed, retry, reconcile}` tasks.
- No decision-tree flowchart. The scenarios are the index; the operator reads the matching one.
- No dashboard mock-ups. Mix tasks + guides are the operator surface.

### Guide quality gates (for Phase 22 plan to enforce)

- [ ] Each of the 6 scenarios has symptom + diagnosis + ≥ 1 copy-paste command + verify step.
- [ ] Every command is either `mix scrypath.*` or `Scrypath.*` — no raw `Scrypath.Meilisearch.*` calls in the guide.
- [ ] Every scenario references `reason_class` where it disambiguates the action.
- [ ] Appendix A documents the 4 new `FailedWork` fields with one-liner meanings.
- [ ] Appendix B tells operators how to report recurrent `:unknown` classifications (a GitHub issue template link, not a quota threshold — see question 8).
- [ ] Word count ≤ 2500 (matches sibling guide `guides/operator-mix-tasks.md` density).

---

## Telemetry Surface

### Recommendation: ONE new event. That's it.

```elixir
:telemetry.execute(
  [:scrypath, :operator, :failed_work, :observed],
  %{count: 1},
  %{
    schema: MyApp.Blog.Post,
    mode: :oban,            # inline | manual | oban
    source: :oban,          # oban | meilisearch
    operation: :upsert,     # upsert | delete | unknown
    reason_class: :transport,  # the new v1.3 field
    retryable?: true,
    attempt: 3,
    max_attempts: 20
  }
)
```

**When emitted:** inside `Scrypath.Operator.FailedWork.from_backend_task/3` and `from_queue_job/3`, once per failed-work entry constructed during a `failed_sync_work/2` or `reconcile_sync/2` read.

**Why this event and not others:**

- **Unblocks the concrete "I want to page on drift" use case** by letting adopters attach a Telemetry.Metrics counter partitioned by `reason_class` — exactly the "count_by_class rollup" FEATURES.md lists as a P2 differentiator, achievable from the same data without a new API.
- **Does not emit on every retry** (retries flow through `Scrypath.retry_sync_work/2` → `Sync.*` → existing `[:scrypath, :sync, ...]` telemetry; adding a second event would duplicate coverage).
- **Does not emit on every reconcile** (reconcile reads; it doesn't cause the failure. Emitting on read would break the invariant that telemetry counts facts-about-the-system, not facts-about-Scrypath-reading-the-system).

**Rejected telemetry additions:**

- `[:scrypath, :operator, :retry, :start/:stop]` — retries already emit through the common sync path. Adding a parallel operator-retry span creates two event families for the same fact.
- `[:scrypath, :operator, :reconcile, :report]` — reconcile is a read, not a mutation. If operators want to track reconcile invocation, they instrument the Mix task themselves.
- `[:scrypath, :operator, :drift, :detected]` — vague; what counts as "drift"? Deferred until adopter signal specifies.

**Backward compatibility:** this is a new event family; it does not disturb any existing `[:scrypath, :sync | :search | :hydration | :meilisearch, ...]` event. Adopters who do not attach a handler see no behavior change.

**Phase 22 plan test coverage:** attach a capture handler in a test, call `Scrypath.failed_sync_work/2` against a fixture with known failures, assert the event fires with expected metadata shape. Same pattern as existing telemetry tests in `test/scrypath/`.

---

## Proposed REQ-IDs (OPS-05..)

Numbering continues from v1.2's OPS-01..OPS-04. Five IDs for Phase 22.

### OPS-05 — Additive `FailedWork.t()` fields

**Acceptance criteria:**
- `%Scrypath.Operator.FailedWork{}` gains four fields: `attempt: nil`, `max_attempts: nil`, `reason_class: :unknown`, `last_attempt_at: nil`.
- All four fields are outside `@enforce_keys`.
- `@type t` widens to include the new fields with nullable types (`:unknown` is a concrete default for `reason_class`; the other three default `nil`).
- A struct-shape regression test pins the v1.2 key set and asserts every new key is optional with the documented default.
- Every existing v1.2 consumer pattern-match (`%FailedWork{retryable?: true}`, etc.) compiles and passes unchanged.
- `failed_at` remains populated identically to v1.2; `last_attempt_at` is populated to the same value.

### OPS-06 — Deterministic `reason_class` classifier

**Acceptance criteria:**
- Private functions `classify_backend_error/1` and `classify_queue_error/2` exist in `Scrypath.Operator.FailedWork`.
- Meilisearch error types `invalid_request` → `:validation`; `internal` → `:backend_rejected`; `auth` → `:transport`; unrecognized → `:unknown`.
- Oban errors matching transport patterns (`Req.TransportError`, `Mint.TransportError`, HTTP 401/403/408/429/5xx, `:timeout`, `:closed`) → `:transport`.
- Oban errors matching data patterns (`Ecto.CastError`, Scrypath-raised `ArgumentError` from projection, malformed payload patterns) → `:validation`.
- Oban state `:discarded` where no more-specific class applies → `:queue_exhausted`.
- Every classifier branch has test coverage against a representative error fixture.
- `metadata.error_code` is populated from Meilisearch `error.code` when present.
- `metadata.discard_reason` is populated with `:exhausted | :explicit` for `:queue_exhausted` entries.

### OPS-07 — Inline/manual failure semantics for `attempt`/`max_attempts`

**Acceptance criteria:**
- `from_queue_job/3` populates `attempt` and `max_attempts` from the Oban job payload when present, `nil` otherwise.
- `from_backend_task/3` always sets `attempt: nil` and `max_attempts: nil` (Meilisearch tasks have no attempt concept).
- Inline-mode and manual-mode failures (observed through the queue_job path only when Oban is in use) correctly surface `nil/nil` when the source system does not expose attempt counts.
- A test covers the case where an Oban job is `:discarded` with `attempt == max_attempts`, asserting `retryable?: false` and `reason_class: :queue_exhausted`.

### OPS-08 — Drift recovery guide (`guides/drift-recovery.md`)

**Acceptance criteria:**
- New file `guides/drift-recovery.md` exists and is added to `mix.exs` `:extras` for hexdocs inclusion (same pattern as `guides/operator-mix-tasks.md`).
- The six scenarios listed in this research are each present with symptom + diagnosis + action + verify sections.
- Every command block references only `mix scrypath.{status, failed, retry, reconcile}` or `Scrypath.*` API functions — no `Scrypath.Meilisearch.*` direct calls in the main body.
- Appendix A documents the 4 new `FailedWork` fields in operator-facing language.
- Appendix B documents how to report recurrent `:unknown` classifications.
- `mix docs --warnings-as-errors` passes with the new guide included.
- `mix verify.phase14`-style doc contract verification passes.

### OPS-09 — Telemetry event `[:scrypath, :operator, :failed_work, :observed]`

**Acceptance criteria:**
- `Scrypath.Operator.FailedWork.from_backend_task/3` and `from_queue_job/3` emit `[:scrypath, :operator, :failed_work, :observed]` with `%{count: 1}` measurements and the metadata shape documented in the telemetry section above.
- A test attaches a `:telemetry` handler and asserts the event fires with the expected metadata keys and value types on both the backend-task and queue-job paths.
- The event is documented in the existing telemetry coverage section of README or `guides/` (the Phase 22 plan picks the exact location; no new documentation artifact required).
- No existing `[:scrypath, ...]` telemetry event shape or frequency changes.

### Stretch / optional REQ-ID (in-phase, not v1.4)

**OPS-10 (optional) — Failure-class rollup on `failed_sync_work/2`**

FEATURES.md lists this as a P2 differentiator. Phase 22 plan should decide whether to ship it or defer; this research neither requires nor precludes it.

**Acceptance (if adopted):**
- `Scrypath.failed_sync_work/2` return shape gains an optional `:count_by_class` rollup map alongside `:entries`, gated by an option (e.g., `rollup: true`) so the default v1.2 return shape is unchanged.
- `Mix.Tasks.Scrypath.Failed.run/1` surfaces the rollup in its rendered output when present.

---

## Coherence With v1.3 Feature Phases

### Question 10 — do faceting / relevance / multi-index introduce failure modes that need specific `reason_class` values?

**No new values needed. All v1.3 feature failures map cleanly onto the 5-class set.** Detail:

| v1.3 feature failure mode | Maps to | Rationale |
|---|---|---|
| Facet query references a non-faceted attribute | `:validation` | This is a caller-data/schema mismatch, not a backend-internal fault. Meilisearch returns `invalid_filter` or `attribute_not_filterable` — `invalid_request` category → `:validation`. The fix is to declare `faceting:` correctly and reindex. |
| A relevance setting (ranking rule, synonym map, stop-word list) fails to apply during reindex | `:backend_rejected` if Meilisearch rejects the settings payload as invalid internal state (e.g., `invalid_state` after corruption) | Retry usually doesn't help without operator attention. The reindex workflow already surfaces this via `reconcile_sync/2`. |
| A relevance setting is malformed (user declared an unknown typoTolerance key, a non-atom ranking rule, etc.) | `:validation` | Caught either at compile time by NimbleOptions nested validation, or at reindex time by Meilisearch as `invalid_request`. Either way, fix your declaration. |
| `search_many/2` partial failure — one sub-query errors, others succeed | The failed sub-query surfaces as `{:error, reason}` in the grouped result map; if it causes a FailedWork entry (for a sync write path, not a search read), the reason_class is whatever the underlying failure classifies as | Federation does not introduce new failure primitives; it's a compositional shape over the existing search/sync paths. |
| Multi-search request exceeds server-side limits (too many federated queries, too large aggregate payload) | `:backend_rejected` | Meilisearch's `database_size_limit_reached`-family codes; server-side resource limit hit. |
| Faceted search returns empty `facet_distribution` on a declared facet attribute | Surfaced via `reconcile_sync/2` drift signals, not `FailedWork` — this is a settings-drift symptom, not a sync failure. The drift-recovery guide Scenario 5 covers it. | |
| Backfill during reindex hits per-document validation errors on a schema that added a new required facet field | `:validation` for the individual failed documents; whole-reindex outcome reported by `Scrypath.reindex/2` return value | Existing pattern from v1.0; no change. |

**Coherence check passed:** the 5-class enum is future-compatible with the four other v1.3 feature phases. No coupling between Phase 22 and Phases B–D beyond the drift-recovery guide referencing newly available features (which it does at Scenario 5 for settings drift and throughout for the sync surface that already exists).

### Question 9 — does `reason_class` affect `RecoveryAction` recommendation?

**Recommendation: `reason_class` is purely descriptive in v1.3. Do not couple it to `RecoveryAction` generation.**

Reasoning:
- The existing `Scrypath.Operator.Reconcile.recommended_actions/4` logic derives actions from (a) the `recovery` already attached to each FailedWork by `from_queue_job/3`, and (b) reindex visibility. It does NOT branch on `reason_class` today, and it should not start.
- Coupling would mean `reconcile_sync/2` behavior depends on classifier accuracy. `:unknown` would have to be treated as "also recommend retry", which softens the report-first posture.
- The drift recovery guide (Phase 22's markdown artifact) is where `reason_class` drives next-action — operator-facing, not code-driven.
- This keeps the v1.2 locked design decision ("reconcile stays report-first, no auto-heal") intact. Using `reason_class` to influence recommended actions would be a subtle step toward auto-heal.

**Future coupling (v1.4+) is fine, but not now.** If adopter signal shows operators want "reconcile suppress retry action when reason_class is :validation", that's a defensible v1.4 scoping question against real evidence.

### Question 8 — classification fallback and `:unknown`

**Recommendation: guide operators toward a GitHub issue template when `:unknown` recurs, but do NOT prescribe a threshold.**

Reasoning:
- Thresholds are trouble. "File an issue when `:unknown` exceeds 10% of failed work" is unenforceable library-side and arbitrary for the operator.
- The honest prompt is: "If `:unknown` is the dominant class on your failed-work listing, that means Scrypath doesn't recognize your failure pattern. File a Github issue with `mix scrypath.failed MyApp.Schema` output (redacted) so we can calibrate the classifier." The Appendix B in the guide carries this exact prompt.
- This gives the library a feedback channel without creating a noisy alerting recommendation that most adopters won't want.
- The GitHub issue template (a `.github/ISSUE_TEMPLATE/classifier-gap.md` file — not part of Phase 22 acceptance, but a reasonable follow-on) would specify what fields to include.

---

## Non-Goal Tripwires

Five things Phase 22 MUST NOT do, even under plan pressure:

1. **Do NOT introduce a new public verb.** No `Scrypath.recover/2`, no `Scrypath.classify_failure/1`, no `Scrypath.drift_signal/2`. The operator surface stays at the v1.2 four-verb set: `sync_status`, `failed_sync_work`, `retry_sync_work`, `reconcile_sync`. Guide composes; code does not widen. PROJECT.md Out of Scope + FEATURES.md anti-feature list + ARCHITECTURE.md are unanimous.

2. **Do NOT add a new Mix task.** The four existing tasks are the complete operator CLI surface for v1.3. A `mix scrypath.drift` or `mix scrypath.classify` task would be a CLI product-surface widening, not an operator-polish extension.

3. **Do NOT promote new `FailedWork` fields into `@enforce_keys`.** Every new field is defaulted and optional. PITFALLS.md P3 is explicit; the struct-shape regression test enforces it.

4. **Do NOT let `reason_class` branch `reconcile_sync/2` recommended-action logic.** Report-first is a v1.2 locked design. Descriptive classification in v1.3; algorithmic coupling (if ever) in v1.4 against adopter evidence.

5. **Do NOT ship a richer enum than 5 values.** FEATURES.md warns: "Rich failure taxonomy with 20+ error classes … wrong classes are worse than `:unknown`". If the Phase 22 plan feels pressure to add `:throttled` or `:timeout` or `:auth`, the answer is "those are `:transport`; the `reason` free-text tells the operator *which* transport problem". The Meilisearch `error.code` in `metadata` is the escape valve for the 1% of cases that need finer granularity.

**Additional low-risk tripwires to watch:**

- Do not expose the classifier as a public function (`Scrypath.Operator.FailedWork.classify_backend_error/1` stays private). A public classifier would let adopters depend on exact match tables that we want to evolve as Meilisearch/Oban change.
- Do not emit telemetry on `retry_sync_work/2` paths — those already emit through `[:scrypath, :sync, ...]`.
- Do not add a `FailedWork.legacy_shape/1` helper "just in case". The struct change is additive; no migration helper is needed. Adding one would signal a non-additive change, which this isn't.

---

## Sources

### Primary (HIGH confidence — direct reads at HEAD)

- `/Users/jon/projects/scrypath/lib/scrypath/operator/failed_work.ex` — current struct + populators
- `/Users/jon/projects/scrypath/lib/scrypath/operator/reconcile.ex` — current reconcile recommended-action logic
- `/Users/jon/projects/scrypath/lib/scrypath/operator/recovery_action.ex` — recovery semantics
- `/Users/jon/projects/scrypath/lib/scrypath/operator/status.ex` — status shape
- `/Users/jon/projects/scrypath/lib/mix/tasks/scrypath.failed.ex` — Mix task voice
- `/Users/jon/projects/scrypath/docs/operator-support.md` — current operator docs voice
- `/Users/jon/projects/scrypath/guides/operator-mix-tasks.md` — existing guide structure
- `/Users/jon/projects/scrypath/ARCHITECTURE.md` — operator-visibility contract + report-first discipline
- `/Users/jon/projects/scrypath/.planning/PROJECT.md` — non-goals (operator polish narrow, no dashboard)
- `/Users/jon/projects/scrypath/.planning/research/FEATURES.md` — operator-polish table stakes + anti-features
- `/Users/jon/projects/scrypath/.planning/research/ARCHITECTURE.md` — FailedWork extension recommendation
- `/Users/jon/projects/scrypath/.planning/research/PITFALLS.md` — P3 (struct break), P8 (VALIDATION.md), P9 (non-goal creep)
- `/Users/jon/projects/scrypath/.planning/research/SUMMARY.md` — phase ordering + open-question posture

### Secondary (HIGH confidence — verified against current docs 2026-04-17)

- [Oban.Job — v2.21.1 docs](https://hexdocs.pm/oban/Oban.Job.html) — 8-state enum, `attempt`/`max_attempts`, errors list, discard semantics
- [Oban Job Lifecycle — v2.21.1](https://hexdocs.pm/oban/job_lifecycle.html) — retryable→discarded transition
- [Oban Error Handling — v2.20.2](https://hexdocs.pm/oban/error_handling.html) — default max_attempts 20
- [Oban Worker — v2.21.1](https://hexdocs.pm/oban/Oban.Worker.html) — `:discard` tuple semantics
- [Meilisearch error codes reference](https://www.meilisearch.com/docs/reference/errors/error_codes) — invalid_request / internal / auth categories, specific codes
- [Meilisearch error format specification](https://specs.meilisearch.dev/specifications/text/0061-error-format-and-definitions.html) — sync vs async error envelope shape

### Tertiary (MEDIUM confidence — industry references for reference-pattern survey)

- [Sidekiq Error Handling wiki](https://github.com/sidekiq/sidekiq/wiki/Error-Handling) — retry set, dead set, 25-retry cap, `sidekiq_retries_exhausted` hook
- [Sidekiq::JobRetry docs](https://www.rubydoc.info/gems/sidekiq/Sidekiq/JobRetry) — retry internals
- [AWS SQS dead-letter queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) — transient/permanent classification pattern
- [AWS Lambda: Understanding SQS retries](https://docs.aws.amazon.com/lambda/latest/operatorguide/sqs-retries.html) — retry cap + DLQ redrive
- [Dead Letter Queue Pattern — abstractalgorithms.dev](https://www.abstractalgorithms.dev/dead-letter-queue-pattern-poison-message-recovery) — "tag your failures: permanent / transient / unknown"
- [Scoutflo SRE Playbooks](https://github.com/Scoutflo/Scoutflo-SRE-Playbooks) — runbook structure reference
- [Runbook Template Library — dev.to](https://dev.to/thesius_code_7a136ae718b7/runbook-template-library-50p1) — symptom→diagnosis→remediation→verification structure
- [Elastic SRE troubleshooting](https://www.elastic.co/observability-labs/blog/sre-troubleshooting-ai-assistant-observability-runbooks) — runbook code-alongside-service discipline
- [Kubernetes troubleshooting guide — Spacelift 2026](https://spacelift.io/blog/kubernetes-troubleshooting) — symptom-anchored layout

---

*Deep research: Operator Polish + Drift Recovery Guide for scrypath v1.3 Phase 22*
*Researched: 2026-04-17*
*Downstream: gsd-roadmapper → Phase 22 → plan-phase researcher → PLAN.md with REQ-IDs OPS-05..OPS-09*
