# Phase 179: Bounded id lists and related-sync parity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-25
**Phase:** 179-bounded-id-lists-and-related-sync-parity
**Areas discussed:** Chunk size + Oban split, Deleted trigger records, Chunk failure semantics, Bad-args error shape

The maintainer selected all four areas and asked for a research fan-out: one researcher per area covering prior art, Elixir/Ecto/Oban idioms, footguns, an adversarial pass, and a coherent one-shot set of recommendations. Advisor mode used the `minimal_decisive` tier. The researchers disagreed in three places; the orchestrator resolved them before presenting:
- **One Oban job per chunk**, not one job that chunks internally.
- **Inline waits on each chunk's task**, not only the last task, because each Meilisearch task fails on its own.
- **A bare `{:error, reason}`**, with no written-ids metadata (Phase 178 D-05).

---

## Chunk size + Oban split

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed internal 1000, one unique job per chunk (transactional insert), one shared helper at every call site | Matches meilisearch-rails and Searchkick defaults; `insert_all` would drop `unique:` on open-source Oban | ✓ |
| Configurable `:max_ids_per_call` (1..10_000) | Tunable for large documents, but a new public name next to `:batch_size`, and nobody has asked for it | |
| One job that chunks internally | Unchanged result shape, but huge args, whole-job retries, meaningless per-job telemetry | |
| Chunk only in the Meilisearch adapter | Smallest change, but fakes and custom backends bypass it and Loader stays unbounded | |

**User's choice:** Accept (Recommended)

## Deleted trigger records

| Option | Description | Selected |
|--------|-------------|----------|
| Survivors only; skip the resolver when none survive; `missing_count` in span metadata; inline keeps caller structs | One resolver shape, matching Searchkick, Laravel and Oban practice | ✓ |
| Survivors plus missing ids (arity 2 or context map) | Nothing lost, but two resolver shapes and extra public surface | |
| Snapshot trigger data at enqueue | Contradicts #108 (jobs carry ids and load current records) | |
| Require fan-out before delete | An ordering rule adopters will get wrong | |

**User's choice:** Accept (Recommended)

## Chunk failure semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Halt at the first failed chunk with a bare `{:error, reason}`; add a `tasks:` list next to `task:` (last); one span | Keeps the error contract, matches the backfill precedent and the Meilisearch SDK batch APIs | ✓ |
| Continue on error and return per-chunk errors | `{:ok, _}` matchers and Oban would miss failures | |
| Nested per-chunk `batch_results[]` | Too heavy for a single sync call; this shape stays backfill-only | |

**User's choice:** Accept (Recommended)
**Notes:** While the context was being written, the separate `jobs:` key shown in the summary was folded into `tasks:`, because enqueue results already model Oban jobs as `Operations.Task`.

## Bad-args error shape

| Option | Description | Selected |
|--------|-------------|----------|
| Shared `JobArgs` decoder; `{:cancel, {:invalid_job, tag}}`; allowlisted keys with unknown keys ignored; upsert cancels on an unknown repo; shared `unique_opts/0` with sorted ids; legacy-args fixture | Consistent across the three workers and ready as Phase 180 telemetry tags | ✓ |
| Cancel on unknown opts keys | Stricter, but strands jobs during rolling deploys | |
| `{:discard, _}` / `{:error, _}` | Discard is deprecated, and error burns retries | |

**User's choice:** Accept (Recommended)

## Claude's Discretion

- Names of the chunking helper and the limit attribute
- How the multi-job insert transaction is done
- Whether `missing_count` also appears on the public related result

## Deferred Ideas

- A configurable chunk size (only on adopter demand; the name must not be `:batch_size`)
- An opt-in fan-out `on_missing:` hook
- Aligning the HTTP-4xx cancel reason string, and new telemetry events (Phase 180)
