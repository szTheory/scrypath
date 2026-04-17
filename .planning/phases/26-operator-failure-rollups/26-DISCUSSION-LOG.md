# Phase 26: Operator failure rollups - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `26-CONTEXT.md`.

**Date:** 2026-04-17
**Phase:** 26 — Operator failure rollups
**Areas discussed:** Public API shape; rollup data shape; Mix/CLI UX; Reconcile parity (research-backed synthesis in chat, then locked in CONTEXT)

---

## Session summary

| Topic | Direction chosen |
|-------|------------------|
| API surface | Opt-in on `failed_sync_work/2`; default `{:ok, [FailedWork.t()]}`; no separate summary API as primary path (FEATURES.md) |
| Counts shape | Named struct; dense five `reason_class` keys; `total` + `version` |
| Mix | Default rollup + per-row class; `--json`; optional `--no-class-summary` |
| Reconcile | Additive field; same pure aggregator from `failed_work` |

**Notes:** Parallel subagents reviewed Elixir idioms, Searchkick/Scout patterns (delegation to queues), and repo-specific OPERATOR_POLISH / FEATURES constraints.

---

## Deferred ideas

None.
