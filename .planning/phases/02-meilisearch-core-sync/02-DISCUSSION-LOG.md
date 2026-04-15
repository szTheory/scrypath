# Phase 2: Meilisearch Core Sync - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-15
**Phase:** 02-meilisearch-core-sync
**Areas discussed:** Sync API shape, Delete identity contract, Inline failure semantics, Meilisearch-specific surface

---

## Sync API shape

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit lifecycle verbs under `Scrypath.*` | Public upsert/delete plus manual or batch variants with explicit invocation | ✓ |
| Generic dispatcher | Single `sync` entry point with action and options routing | |
| Automatic callbacks or wrapper magic | Implicit sync attached to writes | |

**User's choice:** One-shot recommendation set requested; selected the research-backed recommendation for explicit lifecycle verbs under `Scrypath.*`.
**Notes:** Keep sync explicit in contexts, collapse insert and update into upsert semantics, and do not introduce callback magic that conflicts with Ecto norms or Phase 1 decisions.

---

## Delete identity contract

| Option | Description | Selected |
|--------|-------------|----------|
| Projection-derived identity | Let `search_document/1` define the authoritative document id | |
| Metadata-field identity only | Restrict identity to `document_id: :field` and disallow custom identity logic | |
| Explicit identity contract | Default to `document_id`, with a dedicated custom identity hook when needed | ✓ |

**User's choice:** One-shot recommendation set requested; selected the research-backed recommendation for an explicit identity contract.
**Notes:** Delete must capture identity before the row disappears, and `search_document/1` must not silently become a second identity source.

---

## Inline failure semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Inline means enqueue only | Return once Meilisearch accepts the task | |
| Inline waits for terminal task result | Return success only after the task has succeeded | ✓ |
| Inline is dual-behavior via options | Let callers switch waiting behavior per call | |

**User's choice:** One-shot recommendation set requested; selected the research-backed recommendation that inline waits for terminal task completion.
**Notes:** Manual mode remains the enqueue-oriented operator path. Inline must not lie about completion or search visibility.

---

## Meilisearch-specific surface

| Option | Description | Selected |
|--------|-------------|----------|
| Common path only | Keep everything behind `Scrypath.*` and defer a public Meilisearch namespace | |
| Narrow common path plus explicit `Scrypath.Meilisearch.*` | Common sync verbs plus a small backend-specific escape hatch | ✓ |
| Meilisearch-first public surface | Make `Scrypath.Meilisearch.*` the main runtime API | |

**User's choice:** One-shot recommendation set requested; selected the research-backed recommendation for a narrow common path plus explicit `Scrypath.Meilisearch.*`.
**Notes:** Keep the common path honest and small, and put task handling, raw responses, and backend-native operations behind explicit namespacing.

---

## the agent's Discretion

- Exact public function names and result-struct names.
- Exact timeout and polling defaults for inline mode.
- Exact dedicated identity-hook name and validation details.

## Deferred Ideas

- Automatic callback-driven sync wiring
- Broader Meilisearch settings surface beyond the minimum Phase 2 escape hatch
- Larger shared-index ergonomics beyond the stable-id contract needed now
