# Phase 49: Visual hierarchy, theming, and Phoenix ergonomics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **49-CONTEXT.md** — this log preserves the alternatives considered.

**Date:** 2026-04-21
**Phase:** 49 — Visual hierarchy, theming, and Phoenix ergonomics
**Areas discussed:** Shared `/ops` page scaffold; Theme + first paint; Dense operator UI (tables, warnings); Phoenix ergonomics vs Phase 50 boundary

**Mode:** User selected **all** gray areas and requested **parallel subagent research** plus a **single cohesive recommendation set** (delegated “one-shot” decisions captured in **CONTEXT.md**).

---

## Shared `/ops` page scaffold

| Option | Description | Selected |
|--------|-------------|----------|
| A — Layout slots only | Enforced regions from shell; heavier API churn | |
| B — Shared function components only | Flexible; convention-by-documentation | |
| C — Hybrid (chrome in layout + `ops_scaffold` in components) | Global chrome dumb; scan hierarchy composable per LiveView | ✓ |
| D — Mega-template / LiveComponent owns all | High coupling; poor fit for four heterogeneous tools | |

**User's choice:** **Hybrid (C)** — formalized in **CONTEXT** as **D-01**–**D-03** (scaffold components inside `inner_block`, width policy for dense tables, `page_title` + single `h1` discipline).

**Notes:** Subagent compared Sidekiq, ActiveAdmin, Django admin, K8s/Grafana patterns; rejected mega-template for N=4 heterogeneous screens.

---

## Theme + first paint

| Option | Description | Selected |
|--------|-------------|----------|
| Client-only + inline head bootstrap | Minimal server surface; matches current `root.html.heex` | ✓ |
| SSR cookie/session mirrored theme | Better no-JS / CSP; more plumbing | Deferred (optional) |
| `class="dark"` parallel to `data-theme` | shadcn-style; conflicts with daisyUI contract | ✗ |

**User's choice:** **Keep `phx:theme` + `data-theme` + synchronous head script**; **document and fix** `dark:` / **system** interaction (**D-07**); **fix `theme_toggle` effective state** (**D-08**).

**Notes:** Research flagged `@custom-variant dark` vs daisyUI **`prefersdark`** mismatch under **system** mode as the primary technical footgun.

---

## Dense operator data (tables, warnings)

| Option | Description | Selected |
|--------|-------------|----------|
| Raw Tailwind only | Maximum control; risks inconsistent voice | |
| daisyUI primitives directly in LiveViews | Fast; drift without wrappers | |
| Thin wrappers around daisyUI + utilities | Semantic ops vocabulary + themed implementation | ✓ |

**User's choice:** **Thin wrappers** + **severity → variant mapping** + **card vs flat panel rules** + **horizontal scroll / width variants** (**D-11**–**D-14**).

**Notes:** Prior art distilled from AWS Health, PagerDuty, Datadog, Sidekiq UIs — density, sticky context, degraded vs broken semantics.

---

## Phoenix ergonomics vs Phase 50

| Option | Description | Selected |
|--------|-------------|----------|
| Bundle a11y into Phase 49 | Faster but blurs milestone requirements | |
| Strict boundary: 49 = Phoenix conventions, 50 = AT semantics | Matches **OPSUX-05** vs **OPSUX-06/07** | ✓ |

**User's choice:** **Explicit boundary** + **8-item audit list** themes (**D-15**–**D-19**, **CONTEXT** narrative): flash path, `live_title` suffix, shell leak, `~p`, no duplicate IA tests.

**Notes:** Cohesion with Phase **48** — no second nav contract.

---

## Claude's Discretion

Exact module naming for scaffold wrappers, per-route width values, and implementation detail for **`matchMedia`** vs head script for **D-08**.

## Deferred Ideas

See **49-CONTEXT.md** `<deferred>` — Phase **50** a11y/CI, optional SSR theme, visual-diff CI.
