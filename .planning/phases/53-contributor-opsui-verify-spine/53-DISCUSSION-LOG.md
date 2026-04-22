# Phase 53: Contributor OPSUI verify spine - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **53-CONTEXT.md**.

**Date:** 2026-04-21  
**Phase:** 53 — Contributor OPSUI verify spine  
**Areas discussed:** README surfacing (**VRFY-04**), Mix **`@moduledoc`**, doc-contract tests, prerequisites placement  
**Mode:** User requested **all** areas + parallel subagent research + one-shot synthesized recommendations (no per-turn **Q&A** menu).

---

## README surfacing vs Phase 51 thin README

| Approach | Description | Selected |
|----------|-------------|----------|
| A | One sentence in operator blurb: visible **`mix verify.opsui`** + link to **CONTRIBUTING** | ✓ (primary) |
| B | Small end-of-README “Maintainers / verification” bullets (≤3) if blurb crowded | ✓ (fallback) |
| C | Link-only to **CONTRIBUTING** without visible command | ✗ |
| D | Duplicate verify matrix in **README** | ✗ |

**User's choice:** Delegated to research synthesis — **A** (or **B** if needed), never **C**/**D**.

**Notes:** Matches Elixir OSS habit (README names a few canonical **Mix** entrypoints; **CONTRIBUTING** owns matrices). Avoids drift and second-manual **README**.

---

## Mix task `@moduledoc` vs `@shortdoc` only

| Option | Description | Selected |
|--------|-------------|----------|
| Rich short `@moduledoc` | Summary + prerequisites + link to **CONTRIBUTING**; task visible in **`mix help`** | ✓ |
| `@moduledoc false` | Minimal code; task hidden from public **`mix help`** list in current Mix | ✗ |

**User's choice:** Research-backed — enable real **`@moduledoc`** aligned with Phoenix/Ecto-style tasks.

**Notes:** Verified locally: **`verify.opsui`** missing from **`mix help`**; **`mix help verify.opsui`** reports no documentation.

---

## Doc-contract tests

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded **ExUnit** | **`ordered?`** **CONTRIBUTING** ↔ **`ci.yml`** for **`scrypath-ops`**; presence of **`mix verify.opsui`** in **README** + **CONTRIBUTING**; optional **`verify.opsui.ex`** markers | ✓ |
| Manual only | No new tests | ✗ |
| Substring museum | Full script / long prose duplicated in tests | ✗ |

**User's choice:** Synthesis — **1–2** structural tests mirroring Phase **51** patterns.

---

## Prerequisites source of truth

| Layer | Role | Selected |
|-------|------|----------|
| **CONTRIBUTING** | Canonical prerequisites + CI table | ✓ |
| **`mix help verify.opsui`** | Summary + link | ✓ |
| **README** | One-line router, no full tables | ✓ |
| **`scrypath_ops/README`** | Optional DB/app depth if linked from **CONTRIBUTING** | Optional |

**User's choice:** **CONTRIBUTING**-canonical depth; **README** and **`@moduledoc`** summarize and link.

---

## Claude's Discretion

(None recorded — decisions explicit in **53-CONTEXT.md**.)

## Deferred Ideas

(None.)
