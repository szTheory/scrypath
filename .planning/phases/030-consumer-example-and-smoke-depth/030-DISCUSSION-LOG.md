# Phase 30: Consumer example and smoke depth - Discussion Log

> **Audit trail only.** Decisions are captured in `030-CONTEXT.md`.

**Date:** 2026-04-18
**Phase:** 30 — Consumer example and smoke depth
**Areas discussed:** EXAM-01 shape, EXAM-02 doc topology, smoke script semantics, release smoke vs example split

---

## EXAM-01 — second consumer scenario

| Option | Description | Selected |
|--------|-------------|----------|
| Oban in existing Phoenix example | Second integration test + Oban wiring | ✓ |
| Second example app | Clear split, higher maintenance | |
| Extend release consumer smoke only | Packaging-only, not live Meilisearch | |

**User's choice:** Follow agent recommendations — **Oban-backed path in `examples/phoenix_meilisearch`**.

**Notes:** Align **`oban_queue`** with **`Scrypath.Oban.UpsertWorker`** (`:scrypath`).

---

## EXAM-02 — runbook + CI

| Option | Description | Selected |
|--------|-------------|----------|
| Example README SSOT + thin golden path + CONTRIBUTING index | Low drift, adoption-friendly | ✓ |
| Duplicate env tables in multiple files | | |

**User's choice:** Follow recommendations.

---

## Smoke script

| Option | Description | Selected |
|--------|-------------|----------|
| Default teardown + `--keep-up` | Explicit escape hatch | ✓ |
| Two scripts only | | |

**User's choice:** Follow recommendations; hard-fail health waits.

---

## Release smoke vs example

| Option | Description | Selected |
|--------|-------------|----------|
| Runtime in example; packaging in `consumer_smoke_test` | Matches trust chain | ✓ |

**User's choice:** Follow recommendations.

---

## Deferred Ideas

- Dedicated CI job for example smoke (optional future work).
