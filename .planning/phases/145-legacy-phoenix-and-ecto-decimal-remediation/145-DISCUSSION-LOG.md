# Phase 145: Legacy Phoenix and Ecto/Decimal Remediation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-22
**Phase:** 145-legacy-phoenix-and-ecto-decimal-remediation
**Areas discussed:** Manifest bounds, Database proof, Endpoint proof

---

## Pending Todo

| Option | Description | Selected |
|--------|-------------|----------|
| Fold the legacy slice | Include the legacy Phoenix/Ecto/Decimal portion of the existing dependency-advisory todo in Phase 145 while leaving later graph work open | ✓ |
| Review but do not fold | Record the match without including it in this phase | |

**User's choice:** Fold the legacy slice into Phase 145.
**Notes:** The todo remains open until the ScrypathOps, ecommerce, and consolidated all-graph remediation completes in Phases 146-147.

---

## Area Selection and Research Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Manifest bounds | Decide exact pins, broad ranges, or bounded fixed-compatible cohorts and Decimal ownership | ✓ |
| Database proof | Decide how to prove migrations, fixtures, changesets/casts, and representative persistence | ✓ |
| Endpoint proof | Decide the role of ConnCase, a real Bandit listener, and the existing live service lane | ✓ |

**User's choice:** Discuss and consider all areas.
**Notes:** The user requested parallel subagent research, pros/cons/tradeoffs, current Elixir/Plug/Ecto/Phoenix idiom, successful peer lessons across ecosystems, maintainer/adopter DX, JTBD, domain language, security/architecture/DevOps/SRE lenses, and one coherent recommendation requiring minimal user arbitration. Three typed `gsd-advisor-researcher` agents researched the areas independently; the orchestrator cross-checked primary upstream documentation and applicable files under `prompts/`.

---

## Manifest Bounds

| Option | Description | Selected |
|--------|-------------|----------|
| Exact direct pins plus direct Decimal | Maximize lockless repeatability by pinning every target and making Decimal direct | |
| Broad compatible ranges | Keep broad manifest requirements and let fresh resolution select later framework/database lines | |
| Bounded compatible cohorts | Bound direct app-owned packages to the recorded fixed-compatible minor lines, keep Ecto/Decimal transitive, and use the lock for exact resolution | ✓ |

**User's choice:** Approved the researched bounded-cohort recommendation.
**Notes:** Phoenix `~> 1.8.9`, Bandit `~> 1.12.1`, Ecto SQL `~> 3.14.0`, and Postgrex `~> 0.22.4`; leave `phoenix_ecto` unless resolution proves a need; no direct Ecto/Decimal, override, or unrelated widening. The detached fresh probe admits compatible patches only inside those minor cohorts and must meet all recorded advisory floors.

---

## Database Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Existing suite and live smoke only | Rely on current aliases and full-service integration tests | |
| Focused Postgres contract | Add causal DataCase coverage for existing schemas, casts, inserts, queries, relationships, clean migration, and already-migrated no-op behavior | ✓ |
| Synthetic Decimal domain field | Add a Decimal schema field, migration, seed/fixture, and round-trip assertion | |

**User's choice:** Approved the focused Postgres-backed contract.
**Notes:** Use existing Post/Author behavior and generated SQL Sandbox patterns. Test-local fixture helpers are allowed for clarity. Do not invent a Decimal field or cross into live Scrypath synchronization from the causal database test.

---

## Endpoint Proof

| Option | Description | Selected |
|--------|-------------|----------|
| ConnCase only | Exercise the Phoenix endpoint pipeline in process without starting Bandit | |
| Real HTTP only | Start the Bandit listener and send a loopback request without a separate in-process endpoint contract | |
| Full service lane only | Use the Postgres/Meilisearch/Oban smoke as the sole endpoint evidence | |
| Layered contract | Use ConnCase plus one supervised ephemeral-port Bandit request as hard evidence and keep the full service lane supplemental | ✓ |

**User's choice:** Approved the layered endpoint contract.
**Notes:** Prove only normal HTTP/1 JSON/error processing and documented Bandit request telemetry. Do not add a route/socket or claim WebSocket, HTTP/2, session round-trip, browser, or UI coverage that the example does not expose.

---

## the agent's Discretion

- Exact focused test filenames and the location of private test fixture helpers.
- Exact supervised ephemeral-listener harness and existing HTTP client/OTP mechanism.
- Exact representative JSON path and malformed-cookie shape without adding an application route.
- Exact targeted Mix update commands, subject to the binding manifest intent and causal lock-diff rules.

## Deferred Ideas

- WebSocket or HTTP/2 behavioral tests are deferred unless a future phase mounts sockets or explicitly promises those protocols.
- No UI/UX, accessibility styling, theme, motion, or brand work applies to this dependency-only phase.
