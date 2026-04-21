# Phase 50: Accessibility and verification hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **50-CONTEXT.md** — this log preserves the alternatives considered.

**Date:** 2026-04-21
**Phase:** 50 — Accessibility and verification hardening
**Areas discussed:** Heading + landmark model; Playground / federation form semantics; Dense triage tables; CI / verification (OPSUX-07)

---

## Selection

**User's choice:** Discuss **all** listed gray areas in one session; request deep research via subagents (pros/cons, ecosystem lessons, Phoenix idioms) and a **single coherent** recommendation set with minimal remaining decisions for the user.

**Notes:** Interactive multi-select was satisfied by explicit “all” plus expanded research brief. No `--auto` / `--chain` flags.

---

## Heading + landmark model

| Option | Description | Selected |
|--------|-------------|----------|
| A | Layout owns landmarks; **one visible `h1` per route** in page header; `h2`/`h3` inside panels | ✓ (base) |
| B | Layout **`h1` “product”**; page title as **`h2`** | |
| C | **Named `<section aria-labelledby>`** for 2–4 first-class blocks | ✓ (selective, on top of A) |
| D | Heavy **`role="region"`** on cards | (avoid default; prefer `section` + heading) |

**User's choice:** Lock **A + selective C**; reject **B**; avoid landmark soup from **D**.

**Notes:** Align **`h1`** string with **`page_title` / `live_title`**; add **skip link** to **`#ops-main`**.

---

## Playground + federation form semantics

| Option | Description | Selected |
|--------|-------------|----------|
| A | One form, **multiple `fieldset`/`legend`** chapters | ✓ |
| B | Headings + **`role="group"`** + `aria-labelledby` instead of fieldset | (secondary, non-radio clusters only) |
| C | Multiple sibling forms | (defer unless independent submit lifecycles) |
| D | Accordion/tabs disclosure | (defer unless density forces it) |

**User's choice:** **A** default; targeted **`aria-describedby`** + **`role="status"`** for honesty; strict **icon-only / visible label** rules.

---

## Dense triage tables

| Option | Description | Selected |
|--------|-------------|----------|
| A | Semantic **`<table>`** + **`th scope`** + sort **button** + **`aria-sort`** | ✓ |
| B | Expandable rows via **sibling `<tr>`** + `aria-expanded` / `aria-controls` | ✓ |
| C | Row **`role="group"`** toolbars + task-specific labels | ✓ |
| D | **`phx-update="stream"`** + natural keys + minimal focus hooks | ✓ |

**User's choice:** Cohesive **Sidekiq/Sentry-style** literal tables with restrained **`aria-live`**.

---

## CI / verification (OPSUX-07)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Extend **contract tests only** | ✓ (partial — keep existing) |
| B | **`LiveViewTest`** structural a11y asserts | ✓ (new layer) |
| C | **Wallaby** on every PR | ✗ (defer optional) |
| D | **`mix verify.opsui`** orchestration | ✓ |

**User's choice:** **A + B + D**; reject whole-page **snapshots**; optional browser tier deferred.

---

## Claude's Discretion

Exact `id` prefixes, optional `aria-labelledby` on `main` timing, minimal `phx-hook` for focus, and `mix verify.opsui` scope (full vs tagged subset) — see **50-CONTEXT.md** **Claude's Discretion**.

## Deferred Ideas

See **50-CONTEXT.md** `<deferred>` — Wallaby nightly, CSP nonce, formal WCAG audit.
