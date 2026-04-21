# Phase 47: Verification & hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **47-CONTEXT.md** — this log preserves the alternatives considered.

**Date:** 2026-04-21
**Phase:** 47 — Verification & hardening
**Areas discussed:** CI entry shape; anti-drift strategy; critical wiring scope; external dependencies in CI

---

## Research method

Parallel **generalPurpose** subagents were run (one per gray area). Findings were merged into a single coherent recommendation set recorded as **implementation decisions** in **47-CONTEXT.md**.

---

## 1) CI entry shape

| Option | Description | Selected |
|--------|-------------|----------|
| A — Subdir only | `cd scrypath_ops && mix test` in CI | ✓ (as job body) |
| B — Root delegate | `mix verify.opsui` from repo root | ✓ (for DX, same commands as CI) |
| C — Path filters | PR gating + always on `main` | ✓ |
| D — Hybrid | A + B + C | ✓ **(chosen package)** |

**User's choice:** Adopt **hybrid (D)** — dedicated job mirroring **`phoenix-example-integration`**, dual lockfile cache keys, conservative PR **`paths`** including **`lib/**`**, unconditional run on **`main`**, plus root **`mix verify.opsui`**.

**Notes:** Sibling Phoenix app is idiomatically **not** folded into library root **`mix test`**; avoids umbrella confusion and keeps Hex surface clean.

---

## 2) Anti-drift strategy

| Option | Description | Selected |
|--------|-------------|----------|
| LiveViewTest + hooks | `data-testid`, policy strings, `element/2` | ✓ |
| Doc contract tests | `operator-ia.md` + router spine | ✓ |
| HTML golden snapshots | Full-page diff | ✗ (explicitly rejected for v1.10) |

**User's choice:** **Hybrid** — new **narrow** ops-local doc contract module + extend existing **LiveView** tests; **no** full-page snapshots.

**Notes:** Mirrors **`docs_contract_test.exs`** philosophy; learns from Jest snapshot fatigue (large opaque diffs, rubber-stamp updates).

---

## 3) Critical wiring scope

**User's choice:** Risk-prioritized slice aligned with **Oban Web / LiveDashboard / Sidekiq Web** lessons—**thin UI over injected backends**, **fail-closed security**, **honesty invariants** (posture rows, failed-sync rollups, reconcile vs contract drift), plus **search/federation** branches already covered by stubs.

**Explicit defer:** Playwright-wide E2E, real Meilisearch in OPSUI job, exhaustive table UX matrices, per-event telemetry goldens.

---

## 4) External dependencies in CI

| Option | Description | Selected |
|--------|-------------|----------|
| A — Stubs only | No Meilisearch in OPSUI job | ✓ |
| B — Real Meilisearch | Dedicated service in OPSUI job | ✗ |
| C — Layered | Default A; real server in existing library/example jobs | ✓ |

**User's choice:** **Layered (C)** — OPSUI default CI stays **deterministic**; wire confidence remains in **existing** **`phase5` / `meilisearch-smoke` / `phoenix-example-integration` / `:integration`** paths.

**Notes:** Idiomatic Elixir: config injection, **`Req.Test`**, disciplined **`Application.put_env`** + **`on_exit`** in ops tests.

---

## Claude's Discretion

- Subagent-suggested YAML path-filter details left to planner (**47-CONTEXT** D-20).
- Optional **`verify.opsui`** inclusion of format check inside **`scrypath_ops`**.

## Deferred Ideas

See **47-CONTEXT.md** `<deferred>` — E2E browsers, visual regression as default, Meilisearch inside OPSUI CI, exhaustive table matrices.
