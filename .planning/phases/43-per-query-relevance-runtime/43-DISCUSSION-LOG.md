# Phase 43: Per-query relevance runtime - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `43-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 43-per-query relevance runtime
**Areas discussed:** Public API shape for Plane B tuning, `search_many/2` placement & merge semantics, `show_ranking_score_details` policy, verify/CI strategy

**Mode:** User selected **all** gray areas and requested **parallel subagent research** + **synthesized recommendations** (no interactive Q&A turns).

---

## 1) Public keyword shape (flat vs nested vs hybrid)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Flat keywords | `:ranking_score_threshold`, etc. on `search/3` | |
| B — Single `:per_query` map | One top-level key, allowlisted inner map | ✓ |
| C — Hybrid flat + nested | “Common” flat + “advanced” nested | |

**Research notes:** Flat matches naive Keyword habits but **collides** as surface grows; hybrid creates **two precedences**; Rails/Searchkick permissive hashes teach **typo + semver** pain; nested request bags + validation match **Ecto-grade** expectations.

**User's choice:** Accept synthesized **B** (`:per_query` map).

---

## 2) `search_many/2` — shared only vs entry only vs both

| Option | Description | Selected |
|--------|-------------|----------|
| Shared only | Single validation path; poor per-index federation | |
| Entry only | Verbose; fights shared_opts pattern | |
| Both + explicit inner merge | Allow both; `Map.merge(shared, entry)` for inner keys | ✓ |

**Research notes:** Meilisearch query objects are per-request; Scrypath adds shared/entry ergonomics. **Whole-map wholesale replace** for `:per_query` would **drop** shared keys when an entry overrides one field — **rejected**; **documented** `Map.merge/2` for the inner map after outer keyword merge.

**User's choice:** Accept synthesized **both** with **inner key-wise merge**.

---

## 3) `show_ranking_score_details`

| Option | Description | Selected |
|--------|-------------|----------|
| Always public | Simple semver; prod footgun risk | |
| Mix.env / compile gate | Rejected for Hex library | |
| Docs-only (no keyword) | Pushes bypass; weak forensics | |
| Ship + docs + telemetry | Discourage prod; observable misuse | ✓ |

**Research notes:** `Mix.env` in a dependency is **not** a reliable host-app prod signal.

**User's choice:** Accept **ship + operational discipline** (no hard prod block in Phase 43).

---

## 4) `mix verify.phase43` vs extend `verify.phase41`

| Option | Description | Selected |
|--------|-------------|----------|
| Extend phase41 | Couples FED vs TUNE gates | |
| New `verify.phase43` | Local failures, roadmap alignment | ✓ |

**User's choice:** **Dedicated `mix verify.phase43`** + `docs_contract_test` pins.

---

## Claude's Discretion

Inner atom naming style, exact telemetry attachment point, minor Mix task structure.

## Deferred Ideas

- Optional `Application` config hard-disable for ranking score details in prod if abuse appears post-ship.
