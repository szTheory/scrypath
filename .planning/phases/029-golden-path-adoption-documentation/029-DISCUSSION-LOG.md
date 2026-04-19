# Phase 29: Golden path and adoption documentation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `029-CONTEXT.md`.

**Date:** 2026-04-18
**Phase:** 29 — Golden path and adoption documentation
**Areas discussed:** (1) Golden path spine, (2) Meilisearch runbook, (3) Sync-mode doc split, (4) Versioning canonical source, (5) Ecto-only path — via research synthesis (no interactive Q&A tool in session)

---

## Session notes

**User intent:** Deep research across all five gray areas; pros/cons with examples; idiomatic Elixir/Phoenix/Ecto patterns; lessons from Scout, Searchkick, Laravel Scout; one-shot cohesive recommendations aligned with Scrypath vision (explicit sync, operational honesty, great DX).

**Method:** Primary sources — `README.md`, `guides/getting-started.md`, `guides/sync-modes-and-visibility.md`, `docs/releasing.md`, `examples/phoenix_meilisearch/README.md`; secondary — public documentation patterns for Laravel Scout, Searchkick README structure.

**Subagents:** Not used — GSD universal anti-patterns in this workspace disallow non-`gsd-*` Task subagent types; no `gsd-phase-researcher` tool was available in the agent tool list.

---

## Area 1 — Golden path spine

| Option | Description | Selected |
|--------|-------------|----------|
| README-only linear | Full story in README | |
| Guides only (scattered) | No single spine | |
| **Dedicated guide + README teaser** | `guides/golden-path.md` + README link | ✓ |

**User's choice:** Accepted synthesized recommendation (dedicated canonical guide, README as entry).
**Notes:** Aligns with Hex ecosystem norm (README overview, guides for depth); avoids Searchkick-style README sprawl.

---

## Area 2 — Meilisearch prerequisites

| Option | Description | Selected |
|--------|-------------|----------|
| Upstream-only | Link out, no repo steps | |
| **Repo-aligned compose/env** | Match example + link upstream for prod | ✓ |

**User's choice:** Accepted synthesized recommendation.
**Notes:** Reduces version skew vs CI/example; Docker-first is common for Elixir integration tutorials.

---

## Area 3 — Sync-mode documentation

| Option | Description | Selected |
|--------|-------------|----------|
| README expansion | Full wiring in README | |
| **README matrix + guide depth** | Decision in README, mechanics in sync guide | ✓ |

**User's choice:** Accepted synthesized recommendation.
**Notes:** Mirrors Scout’s “queueing near install” as **ordering** in docs, not as mandatory first-run complexity.

---

## Area 4 — Versioning and verify messaging

| Option | Description | Selected |
|--------|-------------|----------|
| Duplicate matrix in README | Full verify table in README | |
| **`docs/releasing.md` canonical** | README + CHANGELOG summaries + links | ✓ |

**User's choice:** Accepted synthesized recommendation.
**Notes:** Addresses README vs `mix.exs` version drift as explicit hygiene task.

---

## Area 5 — Ecto-only / API-only

| Option | Description | Selected |
|--------|-------------|----------|
| Parallel full tutorial | Second golden path | |
| **Phoenix-first + Ecto-only subsection** | Single path with fork section | ✓ |

**User's choice:** Accepted synthesized recommendation.

---

## Claude's Discretion

- Final filename for golden path guide and minimal proof surface (IEx vs HTTP) left to planner/implementer within D-01 constraints.

## Deferred Ideas

- Phase 30 example/smoke expansion — noted for later milestone only.
