---
phase: 132
slug: a11y-contrast-remediation-both-themes-hard-gate-g
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
---

# Phase 132 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir ExUnit via `mix verify.opsui`; Node static contrast checker; Playwright Test + axe matrix |
| **Config file** | `scrypath_ops/mix.exs`; `examples/scrypath_ecommerce/playwright.config.ts`; `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` |
| **Quick run command** | `cd examples/scrypath_ecommerce && node contrast-checker.mjs` |
| **Full suite command** | `cd scrypath_ops && mix assets.build && mix verify.opsui`; then `cd ../examples/scrypath_ecommerce && npm run test:e2e:admin-contrast` |
| **Estimated runtime** | Quick checker under 10 seconds; full browser gate depends on local server/browser startup |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/scrypath_ecommerce && node contrast-checker.mjs`
- **After every plan wave:** Run `cd scrypath_ops && mix assets.build && mix verify.opsui`, then `cd ../examples/scrypath_ecommerce && node contrast-checker.mjs`
- **Before `$gsd-verify-work`:** Full suite must be green, including `cd examples/scrypath_ecommerce && npm run test:e2e:admin-contrast`
- **Max feedback latency:** Static checker feedback should stay under 10 seconds; browser gate is reserved for wave/phase closure

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 132-01-01 | 01 | 1 | A11Y-TOKEN-01 | T-132-01 | N/A - static CSS/token contrast remediation | static/unit | `cd examples/scrypath_ecommerce && node contrast-checker.mjs` | yes | pending |
| 132-01-02 | 01 | 1 | A11Y-TOKEN-01 | T-132-01 | N/A - static CSS/token contrast remediation | unit/a11y | `cd scrypath_ops && mix verify.opsui` | yes | pending |
| 132-02-01 | 02 | 2 | A11Y-TOKEN-01 | T-132-02 | N/A - browser contrast validation | e2e | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-contrast` | yes | pending |
| 132-02-02 | 02 | 2 | A11Y-TOKEN-01 | T-132-02 | N/A - token documentation and visual-diff evidence | visual/static | `cd examples/scrypath_ecommerce && node e2e/light-pixel-diff.mjs` after any required recapture | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

- `examples/scrypath_ecommerce/contrast-checker.mjs` exists and checks token-pair AA failures plus manifest lockstep.
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` exists and covers light, dark, and system-dark browser contrast.
- `scrypath_ops/mix.exs` exposes `mix verify.opsui`.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` exists for documenting new contrast token floors.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual hierarchy remains unchanged while contrast improves | A11Y-TOKEN-01 | Automated contrast gates prove ratios but not whether the phase accidentally changed perceived hierarchy or shell chrome reserved for Phase 135 | Inspect before/after screenshots for light, dark, and system-dark; confirm no layout, copy, spacing, header chrome, or motion changes were introduced |

---

## Validation Sign-Off

- [x] All tasks have automated verification or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Static feedback latency target documented
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
