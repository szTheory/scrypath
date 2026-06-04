---
phase: "131"
plan: "04"
subsystem: validation
tags: [d11-bundle, contrast-gate, pixel-diff, copper-aa, wcag, dark-mode, human-verify]

dependency_graph:
  requires:
    - phase: "131-02"
      provides: "app.css glow + shadow tokens applied; pixel-diff baseline re-captured"
    - phase: "131-03"
      provides: "ops_page_header eyebrow swapped to .ops-copper-eyebrow; DESIGN-TOKENS.md lockstep"
  provides:
    - "D-11 bundle gate results recorded green: mix verify.opsui exit 0; contrast-checker 3 AA / 12 AAA; light-pixel-diff 0/20; Cluster 1 = 0"
    - "Copper 9-pairing AA table re-confirmed all PASS (static F8 assertion vs live @plugin hex values)"
    - "Human-verify APPROVED: seated depth, quiet glow, copper eyebrow on all screens, light non-regression"
    - "GLOW-01 + COPPER-01 proven met; Cluster 3 primary-violet formally deferred to Phase 132 (A11Y-TOKEN-01)"
    - "Phase 131 complete — full dark signature (glow + ambient depth + copper accent) shipped and gate-verified"
  affects:
    - Phase 132 (A11Y-TOKEN-01: primary-violet Cluster 3 fix inherits this deferred baseline)
    - Phase 133/134 (copper-node/badge per-screen copper — D-01a — inherits .ops-copper-node, .ops-copper-badge stubs)

tech_stack:
  added: []
  patterns:
    - "D-11 proof bundle re-run pattern: rebuild assets first (Pitfall 5), then four scripts in order"
    - "Cluster scoping pattern: Cluster 1 = phase gate; Cluster 3 = out-of-scope-known-fail (deferred ref)"
    - "F8 static assertion pattern: copper AA table is a manual re-confirmation against live hex, not machine-checked"

key_files:
  created: []
  modified:
    - .planning/phases/131-glow-dark-shadow-and-copper-accent-system-r-g/131-VALIDATION.md

key-decisions:
  - "D-11 gate condition for Phase 131 is Cluster 1 = 0 (not matrix exit 0); Cluster 3 primary-violet 4.3:1 is out-of-scope known-fail deferred to Phase 132 exactly as Phase 130-VERIFICATION documented"
  - "Copper AA is a static design-contract assertion (F8): copper classes use raw var(--color-secondary)/var(--color-base-content) refs the contrast harness does not track; manual WCAG 2.1 sRGB re-confirmation is the correct gate"
  - "Badge-text rule confirmed: .ops-copper-badge uses color: var(--color-base-content), NOT var(--color-secondary) (light AA fails at 4.15:1 with secondary)"

requirements-completed: [GLOW-01, COPPER-01]

metrics:
  duration: "~20min"
  completed: "2026-06-04"
  tasks_completed: 3
  files_modified: 1
---

# Phase 131 Plan 04: D-11 Gate Bundle + Human-Verify Summary

**Full D-11 proof bundle recorded green (mix verify.opsui exit 0 / 3 AA + 12 AAA baseline unchanged / 0/20 pixel-diff / Cluster 1 = 0), copper 9-pairing AA table re-confirmed all PASS, and human-verify APPROVED on all four perceptual criteria (seated depth, glow restraint, copper eyebrow, light non-regression).**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-06-04
- **Completed:** 2026-06-04
- **Tasks:** 3 (2 auto + 1 checkpoint:human-verify)
- **Files modified:** 1 (131-VALIDATION.md)

## Accomplishments

- D-11 bundle ran against fully-assembled Phase 131 CSS and recorded all four gates green in 131-VALIDATION.md; GLOW-01 + COPPER-01 formally proven met
- Copper 9-pairing AA table manually re-confirmed against live `@plugin` hex values — all 6 text pairings pass WCAG 2.1 AA; badge-text rule (base-content not secondary) re-verified; narrowest margins 4.64:1–4.84:1 both clear 4.5:1 threshold
- Human checkpoint APPROVED 2026-06-04 on all four perceptual criteria; Phase 131 dark signature (ambient seated depth + quiet violet glow + copper eyebrow) confirmed correct and light mode pixel-identical

## Task Commits

Each task was committed atomically:

1. **Task 1 + 2: Run the D-11 proof bundle and record results + copper AA re-confirmation** — `10025f3` (docs)
2. **Task 3: Human-verify APPROVED — record checkpoint result** — `1e14367` (docs)

**Plan metadata:** _(to be added in final commit)_

## D-11 Bundle Gate Results (all green)

| Gate | Command | Result | Status |
|------|---------|--------|--------|
| Gate 1 | `mix verify.opsui` | 129 tests, 0 failures, exit 0 | ✅ PASS |
| Gate 2 | `node contrast-checker.mjs` | 3 AA / 12 AAA (Phase 128 baseline unchanged) | ✅ PASS |
| Gate 3 | `node e2e/light-pixel-diff.mjs` | Failed pairs: 0 / 20, exit 0 | ✅ PASS |
| Gate 4 | `npm run test:e2e:admin-contrast` | Cluster 1 = 0 (gate condition met); Cluster 3 deferred | ✅ PASS |

**Gate 4 cluster detail:**
- Cluster 1 (`.leading-4` ramp): **0 violations** — gate condition met across all 3 scenarios
- Cluster 3 (primary-violet `#6c5ce7` @ 4.3:1 on cream): OUT-OF-SCOPE KNOWN-FAIL — deferred to Phase 132 (A11Y-TOKEN-01), exactly as Phase 130-VERIFICATION documented. 36 total Cluster 3 violations across 3 scenarios (incident 8, all_green 16, empty 12), all `.ops-nav-item-active` / `.bg-primary`. NOT gated in Phase 131.

**Pitfall 5 compliance:** Assets rebuilt via `mix assets.build` (scrypath_ops) before all four scripts to ensure gate scripts see final Phase 131 app.css.

## Copper AA Re-Confirmation (all 9 PASS)

**Method:** Manual WCAG 2.1 sRGB relative-luminance re-confirmation against live `@plugin` hex values from app.css dark block (lines 23–59) and light block (lines 61–97). Static F8 assertion — copper classes use raw `var(--color-secondary)` / `var(--color-base-content)` refs the contrast harness does not track.

| # | Pairing | Theme | Ratio | Verdict |
|---|---------|-------|-------|---------|
| 1 | `base-content` text on copper-badge tinted bg (copper 12% on surface-2) | Dark | 12.07:1 | ✅ PASS |
| 2 | `base-content` text on copper-badge tinted bg (copper 12% on surface-1) | Light | 14.86:1 | ✅ PASS |
| 3 | `.ops-copper-eyebrow` (secondary) on surface-1 | Dark | 5.13:1 | ✅ PASS |
| 4 | `.ops-copper-eyebrow` (secondary) on surface-1 | Light | 4.84:1 | ✅ PASS |
| 5 | `secondary-content` (`#0c0f14`) on solid copper `#c17a3e` | Dark | 5.59:1 | ✅ PASS |
| 6 | Copper text `#c17a3e` on `--ops-surface-2` `#1b2230` | Dark | 4.64:1 | ✅ PASS |
| 7 | `--shadow-ops-glow` (box-shadow, decorative) | Dark | — | Exempt |
| 8 | `--shadow-ops-panel-dark` (box-shadow, decorative) | Dark | — | Exempt |
| 9 | `.ops-shell` wash alpha reduction | Both | — | Exempt |

**Verdict: ALL 9 PAIRINGS CONFIRMED PASS.** Narrowest text margins: 4.64:1 (copper on surface-2 dark) and 4.84:1 (eyebrow on surface-1 light) — both clear the 4.5:1 AA threshold. Badge-text rule confirmed: `.ops-copper-badge` uses `color: var(--color-base-content)`, not `var(--color-secondary)` (secondary on copper-badge tinted bg would fail AA in light at ~4.15:1).

## Human-Verify Result: APPROVED

**Date:** 2026-06-04
**Criteria confirmed:**

| Criterion | Result |
|-----------|--------|
| Dark seated-depth reads correctly | APPROVED — panels pressed into surface with border shadow, not floating |
| Violet glow is appropriately quiet and scoped | APPROVED — glow appears only on route mark, active nav pill, recommended intent-card; absent on text, resting panels, background floods |
| Copper eyebrow renders correctly on all screens | APPROVED — copper renders on all 6 screens at ~5% accent ratio |
| Light mode unchanged (0/20 pixel-diff confirmed) | APPROVED — light mode pixel-identical; 0/20 confirmed |

## Files Created/Modified

- `.planning/phases/131-glow-dark-shadow-and-copper-accent-system-r-g/131-VALIDATION.md` — Per-Task Verification Map completed (all ✅); D-11 bundle gate results recorded verbatim; copper 9-pairing AA table recorded; Manual-Only Verifications table updated with APPROVED status; Validation Sign-Off approval section recorded; `nyquist_compliant: true` confirmed in frontmatter

## Decisions Made

- D-11 gate condition for Phase 131 is **Cluster 1 = 0**, not matrix exit 0. Cluster 3 primary-violet (`.ops-nav-item-active` / `.bg-primary` at 4.3:1 on cream) is out-of-scope known-fail, deferred to Phase 132 (A11Y-TOKEN-01). This is the same scoping as Phase 130-VERIFICATION.
- Copper AA table is a static design-contract assertion (F8 pattern): re-confirmation against live hex values is the correct gate, not the contrast harness checker.
- Badge-text rule re-verified as an acceptance criterion: `var(--color-secondary)` must NOT be used as badge label text in light (would fail at ~4.15:1); `var(--color-base-content)` is the correct rule.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None introduced in this plan. Pre-existing deferred copper stubs (`.ops-copper-badge`, `.ops-copper-node`, `.ops-copper-node--fill` per-screen application — D-01a) are tracked in 131-01-SUMMARY.md and deferred to Phase 134.

## Threat Flags

None. This is a verification-only plan: runs existing gate scripts (pre-existing Phase 128/130 scripts), records results in a planning doc. No production code changes, no input/auth/network/data flow introduced.

## Phase 131 Complete

GLOW-01 + COPPER-01 are proven met. The full dark signature system — ambient seated depth via `--shadow-ops-panel-dark` on `.ops-panel` / intent-cards / command palette / flash, quiet violet glow via `--shadow-ops-glow` scoped to route mark / active nav / recommended card, copper eyebrow on all 6 operator screens via `.ops-copper-eyebrow` — is shipped, gate-verified, and human-approved. Light mode is pixel-identical (0/20). Cluster 3 primary-violet is the one known-fail deferred to Phase 132.

## Next Phase Readiness

- Phase 132 (A11Y-TOKEN-01): Primary-violet `#6c5ce7` @ 4.3:1 on cream is the Cluster 3 known-fail deferred here. The deferred baseline is formally documented in 131-VALIDATION.md.
- Phase 133/134 (D-01a copper per-screen): `.ops-copper-badge`, `.ops-copper-node`, `.ops-copper-node--fill` CSS classes and design documentation are in place (Plans 02+03); the per-screen application of copper badges/nodes is the remaining copper scope.

## Self-Check: PASSED

- [x] `131-VALIDATION.md` modified with all Task 3 APPROVED entries
- [x] Per-Task Verification Map SC-1 updated from "awaiting" to APPROVED
- [x] Manual-Only Verifications: all 4 rows updated with APPROVED 2026-06-04 status
- [x] Validation Sign-Off Approval section updated from "pending" to full APPROVED narrative
- [x] `nyquist_compliant: true` in frontmatter (set during Task 1)
- [x] Commit 10025f3 exists (Tasks 1+2)
- [x] Commit 1e14367 exists (Task 3)
- [x] D-11 bundle gate results all recorded green
- [x] Copper 9-pairing AA table re-confirmed all PASS
- [x] Human-verify APPROVED with all four perceptual criteria documented

---
*Phase: 131-glow-dark-shadow-and-copper-accent-system-r-g*
*Completed: 2026-06-04*
