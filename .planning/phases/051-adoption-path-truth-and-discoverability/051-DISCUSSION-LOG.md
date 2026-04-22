# Phase 51: Adoption path truth and discoverability - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`051-CONTEXT.md`**.

**Date:** 2026-04-21  
**Phase:** 51 — Adoption path truth and discoverability  
**Areas discussed:** Doc-contract scope; README vs CONTRIBUTING IA; Example/CI parity; Sync authority placement  
**Mode:** User selected **all** gray areas; research via parallel subagents; orchestrator synthesized one coherent decision set.

---

## 1. Doc-contract scope (definition of done)

| Option | Description | Selected |
|--------|-------------|----------|
| ExUnit-only (`docs_contract_test.exs`) | All prose contracts in tests; `mix test` is the local gate | ✓ (primary) |
| New verify slices per theme | Each doc theme gets a new `mix verify.*` | |
| CI-only grep/shell | No local ExUnit for README/guides | |
| Hybrid | ExUnit truth + thin verify orchestration (existing pattern) | ✓ (paired with primary) |

**User's choice:** Hybrid with **ExUnit as source of truth** and **existing `mix verify.*` as scheduler**; no new verify tasks unless CI boundary requires it.  
**Notes:** Aligns with Hex OSS “`mix test` surprises least”; avoids Rails-style README-only social contracts for operational docs; mitigates brittle substrings via structured tests and optional file splits.

---

## 2. README vs CONTRIBUTING (first-hour narrative)

| Option | Description | Selected |
|--------|-------------|----------|
| README-heavy | Full story in README | |
| CONTRIBUTING-heavy | Consumers steered to CONTRIBUTING first | |
| Split IA | README = consumer; CONTRIBUTING = contributor; guides = depth | ✓ |

**User's choice:** Three-surface split per table.  
**Notes:** Matches Oban/Phoenix/Rails router patterns; ONBD-02 satisfied by explicit “one first-hour narrative” in README + CONTRIBUTING pointers to sync authority without duplicating lifecycle prose.

---

## 3. Example / CI parity

| Option | Description | Selected |
|--------|-------------|----------|
| `smoke.sh` as CI definition | Actions invoke script | |
| `mix test` in example as CI truth | Same cwd/env/commands as `phoenix-example-integration` | ✓ |
| Document both explicitly | Canonical Mix block + smoke as local Docker convenience | ✓ |

**User's choice:** **(B)** canonical + **(C)** explicit disclaimer that CI does not run `smoke.sh`.  
**Notes:** CONTRIBUTING job row should match workflow (includes `mix deps.get`).

---

## 4. Sync authority placement

| Option | Description | Selected |
|--------|-------------|----------|
| README duplicates full lifecycle | Second spec in README | |
| CONTRIBUTING teaches sync | Contributor doc becomes second manual | |
| Guide SSoT + shallow links | README router + CONTRIBUTING PR pointer + golden path handoff | ✓ |

**User's choice:** **`guides/sync-modes-and-visibility.md`** as SSoT; README = invariant + links; CONTRIBUTING = minimal bullets for PRs touching sync/operator/docs contracts; golden path = ordered handoff before `:oban`/`:manual`.  
**Notes:** Reduces “accepted ≠ visible” footgun without three-way duplication.

---

## Claude's Discretion

- CONTRIBUTING subsection wording and optional split of `docs_contract_test.exs` into multiple modules when size warrants.

## Deferred Ideas

- Phase 52 actionable errors and pitfalls doc (**ONBD-04**–**ONBD-06**).
- Phase 53 **`mix verify.opsui`** contributor spine (**VRFY-03**–**VRFY-04**).
