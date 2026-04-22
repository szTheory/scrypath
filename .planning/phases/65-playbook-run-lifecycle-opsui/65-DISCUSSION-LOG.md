# Phase 65: Playbook run lifecycle (OPSUI) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`65-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 65 — Playbook run lifecycle (OPSUI)  
**Areas discussed:** Run entry points; LiveView async lifecycle; structured errors + docs; timeouts / cancel / disconnect  
**Mode:** User requested **all** areas with parallel subagent research + one-shot synthesis (expert default).

---

## Run entry points (catalog vs preview)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Catalog-only run in modal |  |
| B | Load-only gate; run only in preview | Partially (inspect-first) |
| C | Separate detail route as hub | Future-friendly; not required for 65 |
| D | Hybrid: catalog **Run now** = validate + shared draft + same run pipeline | ✓ |

**User's choice:** **Hybrid (D)** merged with **clear labeling (B)** — catalog gains an explicit **Run now** (name flexible) sharing **`draft_playbook`** and the preview run pipeline; **Load/Open** stays for staging without implying execution.

**Notes:** Research compared Postman, GitHub Actions dispatch, Retool; conclusion: never label **Run** unless execution is intended; show **what will run** next to the action.

---

## LiveView lifecycle (`idle` / `running` / `success` / `failure`)

| Option | Description | Selected |
|--------|-------------|----------|
| Sync `handle_event` | Run in LV process |  |
| Task + `handle_info` | Manual async |  |
| `start_async` / `handle_async` | Idiomatic LV; `cancel_async` | ✓ |
| Oban default | Durable cross-refresh | Deferred |

**User's choice:** **`start_async` + `handle_async`** with **`run_id`** versioning, **`cancel_async`**, **`render_async`** in tests; **no Oban** on the default path in Phase 65.

**Notes:** Oban+DB was evaluated for zero stuck `running` across disconnect; rejected for **Phase 65 scope** to preserve stub-first CI and push durability to a later phase. Timeouts + cancel cover “stuck” within a session.

---

## Structured errors + doc links

| Option | Description | Selected |
|--------|-------------|----------|
| Plain maps only | Wire-friendly | Partial (wire output) |
| Struct + registry + resolver | Stable contract | ✓ |

**User's choice:** **`scrypath_ops`** enrichment module + **reason registry** + **`DocResolver`** → **`failure_class`**, **`reason`**, **`message`**, **`copy`**, **`doc`** map; **two hops** = actionable primary + one deep link.

**Notes:** Stripe / K8s / Rust lessons synthesized; avoid Rails-style string-only errors as the sole contract.

---

## Timeouts, cancel, disconnect

| Policy | Choice | Selected |
|--------|--------|----------|
| Timeout | Wall-clock default ~60s | ✓ |
| Cancel | Soft via `cancel_async` + explicit button | ✓ |
| Tab close | No implicit cancel; honest remount | ✓ |
| DB source of truth | Full CI model | Deferred |

**User's choice:** **Timeout + explicit cancel + honest disconnect** without persistent run rows in Phase 65.

---

## Claude's Discretion

- Field naming inside **`RunUI`**, minor timeout tuning, scroll/focus polish.

## Deferred Ideas

- Durable **`run_id`** persistence, reconnect hydration, Oban-owned execution, log streaming — see **`65-CONTEXT.md` `<deferred>`**.
