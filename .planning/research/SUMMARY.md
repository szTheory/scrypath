# Project Research Summary

**Project:** Scrypath  
**Domain:** Elixir library + optional operator LiveView (**OPSUI**)  
**Researched:** 2026-04-22  
**Confidence:** HIGH

## Executive summary

**v1.15** extends the **v1.14** playbook MVP toward **OPSUI-FUT-01** without opening **OPSUI-FUT-02**. The highest leverage is **playground → playbook** capture (removes JSON authoring friction), plus **catalog/metadata** so operators can manage many playbooks. A **bounded** second persistence story—**documented gitops** or **optional Ecto catalog**—should be chosen explicitly early to avoid dual-source bugs. **Stub-first** verification and **`operator-ia.md`** contracts stay non-negotiable.

## Key findings

### Stack

No new consumer-facing language floor; optional **Ecto** only if the milestone selects server-backed catalog — isolate behind config and contributor docs.

### Features (table stakes → differentiators)

- **Table stakes:** save-as-playbook; rename/duplicate; honest limits.  
- **Differentiators:** metadata-rich catalog; optional team catalog.  
- **Defer:** cluster observability; real-time collaborative editing.

### Architecture

Thin LiveView, fat **pure** mapping into **`V1`**; shared validation paths for paste/upload/**capture**.

### Critical pitfalls

1. **Encoder/schema mismatch** — fix with shared module + tests.  
2. **Dual persistence** — fix with explicit per-deploy authority.  
3. **IA drift** — fix with contract tests in phase that touches nav.

## Implications for roadmap

| Phase | Focus | Addresses |
|-------|-------|-------------|
| **62** | Playground capture + catalog file ops + metadata in JSON | Encoder, **OPS2-01**–**OPS2-03** |
| **63** | Bounded team persistence (docs **or** Ecto spike) + security copy | **OPS2-04**, **OPS2-07** |
| **64** | IA, **`verify.opsui`**, milestone **SHIP** bookkeeping | **OPS2-05**, **OPS2-06**, **OPS2-08** |

## Confidence

| Area | Level | Notes |
|------|-------|-------|
| Stack | HIGH | Brownfield |
| Features | MEDIUM | Persistence fork needs plan-phase lock |
| Architecture | HIGH | Matches existing **PlaybookLive** patterns |
| Pitfalls | HIGH | Known class from **v1.10–v1.14** |

## Sources

- **`.planning/milestones/v1.14-REQUIREMENTS.md`**, **`v1.10-REQUIREMENTS.md`** (**OPSUI-FUT-01**).  
- **`scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex`**, **`playbook/v1.ex`**.

---
*Research completed: 2026-04-22*  
*Ready for roadmap: yes*
