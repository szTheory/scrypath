# Phase 41: Federation docs & contracts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **41-CONTEXT.md** — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 41 — Federation docs & contracts
**Areas discussed:** Verify slice & CI, `docs_contract_test` strictness, README vs guides placement, Score narrative vs federation (all four, user-selected “all”)

**Method:** Four parallel **`generalPurpose`** research subagents; orchestrator synthesized into one coherent decision set (user requested one-shot recommendations).

---

## 1) Verify slice and CI

| Option | Description | Selected |
|--------|-------------|----------|
| A | Dedicated **`mix verify.phase41`** + thin Mix task (match phase36–38) | ✓ |
| B | Fold into generic **`mix test` / `mix verify` only** | |
| C | Two-tier CI: fast static PR vs integration/nightly | ✓ (combined with A) |
| D | Doc contracts only, no named verify task | |

**User's choice:** Adopt **A + C** — named phase verify as **composer**; default PR runs static doc contracts; integration-tier for daemon/network if needed later.

**Notes:** Aligns with Rails/Laravel lesson: **fast default CI**, Meilisearch only where honest; avoids verify-task sprawl by keeping task **delegation-only**.

---

## 2) `docs_contract_test.exs` strictness

| Option | Description | Selected |
|--------|-------------|----------|
| A | Strict phrase + heading locks everywhere | |
| B | Hygiene-first (forbidden IDs, internal paths) | ✓ (baseline) |
| C | Structural / parser-based checks | ✓ (lite: README spine, “must mention” lists) |
| D | Full golden Markdown snapshots | |

**User's choice:** **B + C lite** — no prose locks; optional small **extracted-fact** golden lists for env/tasks if needed.

**Notes:** Jest-style snapshot footguns avoided; CONTRIBUTING should frame failures as **leak/structure**, not “wording police.”

---

## 3) Documentation placement

| Option | Description | Selected |
|--------|-------------|----------|
| A | README billboard + guides depth | ✓ |
| B | Golden path as primary narrative for federation | |
| C | Role-based hubs (adopter vs operator) | ✓ (partially via links/callouts, not full site restructure) |
| D | Diátaxis-lite (concept / task / reference) | ✓ (mapped onto **`multi-index-search.md`** + runbook guides) |

**User's choice:** **A + D**, with **`guides/multi-index-search.md`** as **single federation concept source**; README one-liner; golden-path pointers; labeled future OPSUI callout only.

**Notes:** Ecto/Oban/Req patterns cited by research (thin README, ops split, no README-as-novel).

---

## 4) Score narrative vs federation

| Pattern | Description | Selected |
|---------|-------------|----------|
| A | Two-layer retrieval vs merge | ✓ |
| B | Repeated “weights ≠ comparable scores” | ✓ (at first weight mention + `@doc`) |
| C | Product/editorial framing in examples | ✓ (supporting) |

**User's choice:** **A + B + C** with a **canonical `@doc` paragraph** on **`search_many/2`** plus guide expansion.

**Notes:** Meilisearch federation docs and Elasticsearch cross-index score lessons inform wording; Searchkick-style **raw score across models** footgun explicitly avoided.

---

## Claude's Discretion

- Exact **`verify.phase41`** task implementation details if a shared verify helper appears later—must remain orchestration-only.

## Deferred Ideas

- Optional external link checker in CI.
- REQUIREMENTS **FED-02** checkbox vs shipped Phase 40 — traceability cleanup when closing **FED-03**.
