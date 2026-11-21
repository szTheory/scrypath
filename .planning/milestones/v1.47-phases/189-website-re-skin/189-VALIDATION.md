---
phase: "189"
slug: "website-re-skin"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-20"
---

# Phase 189 — Validation Strategy

> Per-phase validation contract. Seeded from the "Validation Architecture" section of [189-RESEARCH.md](189-RESEARCH.md); the research table is the detailed source and this file is its sampling summary.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node built-in test runner (`node --test`), dependency-free static contract; ExUnit wrappers; Playwright-driven `website/scripts/check.mjs` for the hosted browser job |
| **Config file** | none (the contract and wrappers are created by plan 189-01) |
| **Quick run command** | `node --test website/scripts/site-contract.test.mjs && node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` |
| **Full suite command** | `mix verify.repository_contracts` and `mix verify.core` once per committed SHA, plus hosted `build-and-check` on the exact head |
| **Estimated runtime** | quick about 5 s; long gates about 15 min each (run in the background) |

---

## Sampling Rate

- **After every task commit:** the focused local checks (`node --test`, targeted `mix test`, `mix format --check-formatted`, actionlint)
- **After every plan wave:** the plan's own verify block; ExUnit wrapper planted and accept cases from the end of 189-01 on
- **Before verify-work:** one `mix verify.repository_contracts` per committed SHA (escalated permission for `FETCH_HEAD` on the first run) and `mix verify.core`
- **Max feedback latency:** quick checks under 10 s; the long gates run once per SHA by design (GATE-02)

---

## Per-Task Verification Map

| Criterion | Plan | Wave | Requirement | Automated command | Lane | Status |
|-----------|------|------|-------------|-------------------|------|--------|
| SC1 static contract (byte identity, token parity via role map, no literals in `website/src`, closed hex set, no root-absolute URLs, og meta, CSP, font-display, glyph allowlist, planted failures) | 01 | 1 | SITE-01, SITE-04 | `node --test website/scripts/site-contract.test.mjs`; `mix test test/mix/tasks/workflow_wiring_test.exs` | `core`, `repository-contracts` | ✅ local green; hosted on the exact head green |
| SC2 theme behavior (JS off, blocked storage, Light/Dark/System, persistence, reduced motion, forced colors, print) | 01-02 | 1-2 | SITE-02 | `node website/scripts/check.mjs` at `http://127.0.0.1:<port>/scrypath/` | `build-and-check` (non-required; exact-head `gh api` evidence) | ✅ local green; hosted on the exact head green |
| SC3 identity renders (fonts, hashes, computed families, one lockup, icons, contrast per pair id, 320 px, no console error or CSP violation) | 02 | 2 | SITE-01, SITE-03, SITE-06 | same `check.mjs`; copied WCAG function asserted against `brand/brand.json` | `build-and-check` | ✅ local green; hosted on the exact head green |
| SC4 deny-set and allowlist (18 hexes, `p189` entries gone, ceilings 5 and 197, planted old hex fails, `brand/**` in both workflow filters) | 02-03 | 2-3 | SITE-04 | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs`; `mix test test/mix/tasks/workflow_wiring_test.exs` | `core`, `repository-contracts` | ✅ local green; hosted on the exact head green |
| SC5 deploy evidence (exact-head `build-and-check`, deploy concurrency, smoke, rollback documented, non-required decision, one gate run per SHA, no stale receipt) | 03 | 3 | SITE-05, GATE-02 | `gh api repos/szTheory/scrypath/commits/<head>/check-runs`; workflow structure asserted in `workflow_wiring_test`; smoke on the merge commit | PR checks on the exact head; `deploy` job after merge (orchestrator evidence, recorded post-ship) | ✅ local green; hosted on the exact head green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers the test runner; plan 189-01 creates the contract, its ExUnit wrapper and the rewritten `check.mjs` as its tracer and guards, before the re-skin lands.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Not proved by any check (recorded, not gated): rendered quality and aesthetics, browsers other than Chromium including the meta CSP in Safari, real screen readers, social-platform card cropping, `.ico` rendering, the Pages `content-type` for `.woff2` until the first post-merge smoke. No aesthetic or independent-review approval is claimed.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency for quick checks under 10 s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** seeded 2026-11-20 by the orchestrator from RESEARCH.md; becomes `validated` when the phase verifier passes.
