---
status: pending_human
phase: 50-accessibility-and-verification-hardening
updated: 2026-04-21
---

# Phase 50 — Manual verification (OPSUX-06 / OPSUX-07)

Automation covers DOM contracts (`ops_a11y_contract_test.exs`) and LiveView regressions. Complete this checklist on a built `/ops` instance before marking the phase fully accepted in release review.

## Environment

- [ ] URL: `http://localhost:4000` (or staging) — record: _______________
- [ ] Browser + version: _______________
- [ ] Screen reader (if applicable): VoiceOver / NVDA / other: _______________

## Keyboard pass

Route order: **posture** → **failed-sync** → **sync-drift** → **search**.

- [ ] **Posture (`/ops/posture`)**: Tab order reaches skip link first, then primary nav; refresh control reachable; table readable with column headers.
- [ ] **Failed sync (`/ops/failed-sync`)**: Schema selector operable; table headers align with cells; row detail disclosure is keyboard-openable.
- [ ] **Sync / drift (`/ops/sync-drift`)**: Reconcile and drift actions reachable; tabular summaries make sense when read linearly.
- [ ] **Search (`/ops/search`)**: Mode toggles and fieldset groupings announced sensibly; submit runs from keyboard; federation status region not excessively chatty.

## Screen reader pass

- [ ] Skip link (“Skip to operator content”) moves focus to main content (`#ops-main`).
- [ ] Page title (`h1` / `#ops-page-title`) is announced once per route (no duplicate titles).
- [ ] **Search** playground: legends for Query, Limits, Federation, and Actions are distinct and match on-screen grouping.

## Automated gate (CI / local)

Record what ran before human sign-off:

- [x] `mix verify.opsui` (repo root) — **PASS** (full `scrypath_ops` suite)
- [x] `cd scrypath_ops && mix opsui.test_a11y` — **PASS** (`--only opsui_a11y`)

## Outcome

**Result:** PASS / FAIL / BLOCKED (circle one)

**Notes:**

________________________________________________________________________________

**Sign:** _______________ **Date:** _______________
