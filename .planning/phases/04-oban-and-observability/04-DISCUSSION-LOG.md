# Phase 4: Oban and Observability - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-15
**Phase:** 4-Oban and Observability
**Areas discussed:** Oban public integration shape, Async job payload and execution model, Telemetry surface and event naming, Operator-facing consistency story

---

## Oban public integration shape

| Option | Description | Selected |
|--------|-------------|----------|
| Keep Oban on existing `Scrypath.*` verbs plus narrow transactional helper | Preserve one public sync API via `sync_mode: :oban`, with a small `Scrypath.Oban` helper for `Ecto.Multi` / `Repo.transact` | ✓ |
| Primary mirrored `Scrypath.Oban.*` sync API | Make Oban-specific enqueue verbs the main public async surface | |
| Separate companion package | Move Oban support to a separate package such as `scrypath_oban` | |

**User's choice:** One-shot recommendation set requested; selected the research-backed recommendation to keep Oban on the existing `Scrypath.*` verbs and add only a narrow transactional helper.
**Notes:** The goal was one coherent recommendation set optimized for least surprise, great DX, and strong software architecture. The final recommendation rejected both a parallel sync API and a separate package for the core v1 async path.

---

## Async job payload and execution model

| Option | Description | Selected |
|--------|-------------|----------|
| Operation-specific normalized workers | Separate upsert and delete workers with JSON-safe normalized payloads carrying projected documents or resolved document ids | ✓ |
| Source-id reload workers | Jobs reload rows and re-project inside the worker based on source ids | |
| Two-stage debounce or flush model | Queue lightweight events first and aggregate later through a flusher/orchestrator | |

**User's choice:** One-shot recommendation set requested; selected the research-backed recommendation for operation-specific workers with normalized payloads.
**Notes:** The final recommendation kept projection and identity resolution explicit before enqueue, rejected hidden repo reload behavior, and preserved the locked delete-id contract from Phase 2.

---

## Telemetry surface and event naming

| Option | Description | Selected |
|--------|-------------|----------|
| Stable common-path spans only | Expose only a very small shared Telemetry surface on `Scrypath.*` | |
| Layered common plus backend-specific spans | Stable common spans for shared workflows plus explicit `Scrypath.Meilisearch.*` spans for backend detail | ✓ |
| Fine-grained public events for every internal step | Make internal pipeline stages public Telemetry API surface | |

**User's choice:** One-shot recommendation set requested; selected the research-backed recommendation for a layered Telemetry model.
**Notes:** The recommendation favored stable common spans plus explicit backend-specific spans, low-cardinality public metadata, and direct compatibility with Telemetry and OpenTelemetry conventions.

---

## Operator-facing consistency story

| Option | Description | Selected |
|--------|-------------|----------|
| Contract-first mode matrix and lifecycle states | Document `:inline`, `:manual`, and `:oban` through explicit guarantees plus a shared async lifecycle | ✓ |
| Oban-centric framing | Tell the story primarily as durable background sync through Oban | |
| Convenience-first automatic background sync narrative | Optimize for marketing simplicity over precise consistency semantics | |

**User's choice:** One-shot recommendation set requested; selected the research-backed recommendation for a contract-first consistency story.
**Notes:** The final recommendation explicitly distinguished durable enqueue from search freshness and treated retries, discarded jobs, and drift as normal operational concerns instead of edge cases.

---

## the agent's Discretion

- Exact worker module names and internal payload field layout
- Exact retry classification, backoff defaults, and accepted-result struct details
- Exact stable common Telemetry metadata field names

## Deferred Ideas

- Source-id reload workers
- Debounce or buffer-flush orchestration as the default async model
- Separate `scrypath_oban` companion package
- A second full `Scrypath.Oban.*` public sync API
