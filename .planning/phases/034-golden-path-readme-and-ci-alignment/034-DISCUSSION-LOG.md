# Phase 34: Golden path, README, and CI alignment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`034-CONTEXT.md`**.

**Date:** 2026-04-19  
**Phase:** 34 — Golden path, README, and CI alignment  
**Areas discussed:** Canonical `status` snippet; Golden path CI narrative; `docs_contract_test` strategy; README Quick Path shape

---

## 1. Canonical `status` in the first-schema snippet

| Option | Description | Selected |
|--------|-------------|----------|
| A — `Ecto.Enum` | README-style enum field; stricter in-app types | |
| B — `:string` | Matches golden path + `examples/phoenix_meilisearch` + string filters | ✓ |
| C — Hybrid | Different representations per doc | |

**User's choice:** Delegated one-shot recommendation set; locked **`:string`** everywhere for canonical snippets (see **D-01–D-03** in CONTEXT).

**Notes:** Avoids INT-GOLDEN-VS-README-SCHEMA; avoids mixed Enum field + `"published"` filter in the first hour; doc-only phase defaults to aligning README to example without migrations.

---

## 2. Golden path ↔ CI narrative

| Option | Description | Selected |
|--------|-------------|----------|
| Full CI matrix in golden path | Self-contained but duplicates CONTRIBUTING | |
| One accurate paragraph + CONTRIBUTING link | PR truth + DRY | ✓ |
| CI detail only in CONTRIBUTING | Risks readers missing PR gate | |

**User's choice:** Delegated; retire **“optional CI wiring”** / local-only fiction; state **`phoenix-example-integration`** on PRs + link out (**D-04–D-06**).

---

## 3. `docs_contract_test.exs` strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Literal swap only | Update wrong string | Partial |
| Narrow schema parity | Shared tokens in README + golden path | ✓ |
| Byte-identical full fences | Too brittle | |

**User's choice:** Replace obsolete literal; add narrow README ↔ golden-path parity for agreed schema tokens (**D-07–D-08**).

---

## 4. README Quick Path shape

| Option | Description | Selected |
|--------|-------------|----------|
| Full triple fences | Searchkick-like; high drift vs spine | |
| Slim teaser + CTA to golden path | Matches Phase 29 spine; least drift | ✓ |

**User's choice:** Delegated; slim Quick Path after alignment (**D-09–D-10**).

---

## Claude's Discretion

Micro-snippet choice in README; optional enum upgrade aside placement (**CONTEXT** Claude's Discretion).

## Deferred Ideas

- Sync guide authority vs README — **Phase 35** (`INT-SYNC-GUIDE-AUTHORITY`).
