# Phase 64: IA, verification, and milestone bookkeeping - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`64-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 64 — IA, verification, and milestone bookkeeping  
**Areas discussed:** IA depth vs minimal sync; **`mix verify.opsui`** breadth; milestone SHIP bookkeeping; **`docs_contract_test`** expansion  
**Mode:** User requested **all** areas + parallel subagent research + single synthesized recommendation set.

---

## IA depth vs minimal sync (OPS2-05)

| Approach | Description | Selected |
|----------|-------------|----------|
| A — Minimal always-on | Nav table + JSON fence ↔ **`Nav.primary/0`** / router; contract task + **`operator_ia_contract_test`** green | ✓ (baseline) |
| B — Targeted narrative refresh | JTBD / follow-up column updates when jobs or canonical docs change; link out, no runbook duplication in IA | ✓ (milestone-gated) |
| C — Full editorial IA | Broad persona/JTBD rewrites on every change |  |

**User's choice:** **A + targeted B** — mechanical IA as non-negotiable default; deeper prose only when operational meaning shifts, with **thin IA, fat guides**.

**Notes:** Cross-ecosystem research (Rails engines, LiveDashboard registry, Oban “truth in docs”, K8s/Grafana nav drift) supports **derived nav from code** + **short operator index**.

---

## `mix verify.opsui` coverage (OPS2-06)

| Approach | Description | Selected |
|----------|-------------|----------|
| Exhaustive LiveView | Every branch via DOM tests |  |
| Pyramid + stub verticals | Unit/`V1`/Store + one **happy-path** **`LiveViewTest`** per primary shipped action + contracts | ✓ |
| Heavy integration in default | Live Meilisearch / browser in default **`mix test`** |  |

**User's choice:** **Pyramid + stub verticals**; default gate remains **full `scrypath_ops` test** via **`verify.opsui`**; **no** live Meilisearch on this path.

**Notes:** Aligns with Sidekiq/Go **`-short`** / merge-gate vs nightly patterns; Phoenix/LiveView idioms favor **`LiveViewTest`** without external daemons in default CI.

---

## Milestone close / SHIP (OPS2-08)

| Approach | Description | Selected |
|----------|-------------|----------|
| Heavy close | **`milestones/v1.15-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`** + rolling canon updates | ✓ |
| Light only | Rolling files only, no frozen trio |  |
| Conflate Hex bump | Milestone bookkeeping PR also bumps version without release PR discipline |  |

**User's choice:** **Heavy close** for **v1.15** ship boundary + **Hex/changelog on release PR spine** (explicit exception only if team declares single merge).

**Notes:** Matches **v1.14** precedent and **SHIP-01** evidence expectations; avoids “planning says shipped, Hex lags” two-truths footgun.

---

## `docs_contract_test` expansion

| Approach | Description | Selected |
|----------|-------------|----------|
| Targeted anchors | New **`mix …`** strings, verify matrix, ordered steps when adoption-critical | ✓ |
| Reactive only | Extend tests only after drift discovered |  |
| Full README golden | Snapshot entire README |  |

**User's choice:** **Targeted anchors** for **62–63**-introduced adoption surfaces; reject full-document golden files.

**Notes:** Django doctest / Rails snapshot anti-patterns cited; Scrypath’s existing **substring + order + hygiene** style preserved.

---

## Claude's Discretion

- Execute-phase may choose exact test files and minimal doc anchor strings within the above constraints.

## Deferred Ideas

- Playwright-on-all-flows; default CI Meilisearch for OPSUI.  
- Optional second-tier **`@tag`** split for LV tests—only if measured pain.
