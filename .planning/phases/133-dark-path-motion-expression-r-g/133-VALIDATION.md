---
phase: 133
slug: dark-path-motion-expression-r-g
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-24
---

# Phase 133 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `mix verify.opsui` (Elixir/ExUnit + static CSS asserts) + Playwright (focused e2e) |
| **Config file** | `lib/mix/tasks/verify.opsui.ex`; `examples/scrypath_ecommerce/e2e/` (Playwright) |
| **Quick run command** | `mix verify.opsui` |
| **Full suite command** | `mix verify.opsui` + asset rebuild/host compile + focused Playwright motion spec (dark+light) |
| **Estimated runtime** | ~60–120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.opsui`
- **After every plan wave:** Run `mix verify.opsui` + asset rebuild + focused Playwright motion spec
- **Before `/gsd-verify-work`:** Full proof bundle (D-05) must be green
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

> Planner fills this map from PLAN.md task IDs. The locked D-05 proof bundle binds DARKMOTION-01 to:
> static CSS asserts (transform/opacity-only, tokenized durations <300ms), reduced-motion neutralization,
> focused Playwright reduced-motion + interaction checks in dark AND light, a LiveView patch/re-run
> no-re-fire-flicker check, and a small targeted screenshot set per shipped anchor.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {N}-01-01 | 01 | 1 | DARKMOTION-01 | — / — | transform/opacity-only motion, <300ms, reduced-motion-safe | static-css | `mix verify.opsui` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Reuse existing `mix verify.opsui` static CSS asserts (extend with transform/opacity-only + <300ms token checks for new motion classes)
- [ ] Reuse existing Playwright harness (`examples/scrypath_ecommerce/e2e/helpers/e2e.ts`) for a focused motion spec
- [ ] No new framework install — existing infrastructure covers all phase requirements

*Existing infrastructure covers all phase requirements; Phase 133 extends asserts, it does not bootstrap a framework.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| "Reads deliberate/infrastructural in dark" subjective tone | DARKMOTION-01 | Aesthetic judgement not pixel-assertable | Defer full milestone UAT to Phase 136 (DUALVERIFY-01); Phase 133 confirms functional integrity + reduced-motion + no-re-fire via automation only |

*Transient motion's perceptual quality is manual; all functional/safety properties have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
