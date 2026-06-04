# Phase 123 Verification: Micro-animation layer (MOTION-01)

**Date:** 2026-06-03
**Branch:** `gsd/v1.33-admin-ui-insane-polish`
**Gate phase:** yes

## Gate results

| # | Check | Command | Result |
|---|-------|---------|--------|
| 1 | scrypath_ops tests (CI shape) | `mix verify.opsui` (repo root) | **PASS** — 2 doctests, 129 tests, 0 failures (baseline parity) |
| 2 | scrypath_ops tests | `cd scrypath_ops && mix test` | **PASS** — same suite, 129/0 (covered by #1) |
| 3 | ecommerce host compile | `cd examples/scrypath_ecommerce && mix compile --warnings-as-errors` | **PASS** — clean, exit 0 |
| 4 | 40-shot screenshot matrix (no static regression) | seed → `mix phx.server` :4002 → `npm run test:e2e:admin-matrix` | **PASS** — 3 scenarios, 40 shots, all passed |
| 5 | reduced-motion neutralization + functional integrity | Playwright `reducedMotion: "reduce"` | **PASS** — see below |

## Boot procedure used (gotchas honored)
- `cd scrypath_ops && mix assets.build` first (else LiveView won't connect / motion classes absent).
- Meilisearch up via `make infra` (healthy on :7700); local Postgres ready.
- Seed run **separately** (`make seed`) — seeds the `incident` scenario; the matrix then re-seeds
  per-scenario over `/dev/e2e/seed`.
- `mix phx.server` started **standalone** (seed consumes `app.start`), non-sandbox dev DB on :4002.
- Verified `ease-ops-exit`, `ease-ops-out`, `ops-modal-out`, `ops-fade-out`, `ops-cmdk--closing`
  all present in the compiled `priv/static/assets/css/app.css` (Tailwind source scan picked up the
  new class strings in `.ex`/`.js`).

## Screenshot matrix (no static regression)
- 40 PNGs in `examples/scrypath_ecommerce/.tmp/admin-screenshots/` (20 light / 20 dark).
- Motion changes are transitions/keyframes only; at rest they are identity, so no pixel change is
  expected. Spot-confirmed both themes:
  - `00-control-room--{light,dark}--desktop--incident.png` — verdict hero ("Degraded", amber tone +
    dot), intent cards, nav, contrast all intact (this is the A2 surface).
  - `06-search--light--desktop--results.png` — `.ops-result-row` list (Hit 1–15) resting styling
    unchanged (A4 only touches hover/press timing, invisible at rest).
- No committed baseline exists in-repo (`.tmp` is gitignored/transient), so the check is "layouts +
  contrast unchanged in both themes", confirmed by inspection.

## Reduced-motion (`prefers-reduced-motion: reduce`)
Driven via Playwright `reducedMotion: "reduce"`:
- Command palette: `Ctrl+K` opens (visible), `Escape` closes (hidden) — **works**.
- Interruptibility: open → Escape → immediate re-open → **stays open** (pending close cancelled).
- Cheat sheet: `?` opens, `Escape` closes — **works**.
- Disclosure: Failed-Sync reason-rollup `<details>` summary click → **toggles** open/closed.
- Neutralization proof: `.ops-verdict` computed `transition-duration` = `1e-05s` (0.01ms), i.e. the
  global `@media (prefers-reduced-motion: reduce)` rule overrides the 200ms tone-settle to ~instant.
- (Two 404 console messages on the search page are a pre-existing asset 404, unrelated to motion.)

## A3 decision
**Skipped.** A CSS-only stagger re-fires on every LiveView DOM patch of the result list, reading as
flicker; first-reveal gating needs a forbidden JS hook. Documented in DESIGN-TOKENS.md and SUMMARY.

## DESIGN-TOKENS.md lockstep
Updated with the enter/exit keyframe table, the A1 asymmetry rule, the A2 coordination contract, the
A4 press/hover authority, and the A3 skip rationale. Matches `app.css`.

## Verdict
All five gate checks **PASS**. MOTION-01 complete; no behavior changes; reduced-motion-safe.
