---
phase: 128-contrast-gate-harness-dark-seed-coverage-s-g
verified: 2026-06-04T00:00:00Z
status: passed
score: 4/4
overrides_applied: 0
re_verification: null
gaps: []
deferred: []
human_verification: []
---

# Phase 128: Contrast Gate Harness — Verification Report

**Phase Goal:** Make WCAG AA/AAA measurable and the dark state-space observable before changing any pixels — add @axe-core/playwright, an admin_contrast_matrix.spec.ts (screens x {light, dark, system-dark} x seed scenarios; AA = build-fail, AAA-body = advisory report), npm run test:e2e:admin-contrast + make contrast, and a fast custom token-pair pre-check.
**Verified:** 2026-06-04
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `npm run test:e2e:admin-contrast` runs the full screen x {light, dark, system-dark} x scenario matrix and exits non-zero on any AA color-contrast violation | VERIFIED | `admin_contrast_matrix.spec.ts` runs 3 scenarios (incident/all_green/empty) x ~13 states x 3 ThemeModes x 2 viewports. Gate asserts `expect(aaFails).toBe(0)` after `writeContrastReport` (D-21 write-before-assert). Live run found 108 AA violations (22/60/26 per scenario), exited 1. |
| 2 | AAA (7:1) status for body/long-form text is reported without failing the build | VERIFIED | AAA pass uses `color-contrast-enhanced` scoped to BODY_SELECTORS; severity `aaa-body-advisory`; wrapped in try/catch (CR-03 fix — guards empty-body screens); NEVER increments aa_fail; NEVER affects exit code. Confirmed by self-test behavioral sub-proof: advisory fixture asserts `summary.aa_fail === 0` and exit code `0`. |
| 3 | A fast Node token-pair contrast checker (`make contrast`) grades every declared --color-* pair + documented muted alphas at AA/AAA with no browser | VERIFIED | `contrast-checker.mjs` (816 lines, zero npm deps — node:fs/promises + node:path + node:url only). `make contrast` runs in under 1 second, found 3 AA failures (`.ops-text-meta`, `.ops-cmdk__item-hint`, `.ops-cmdk__empty` at 3.9:1) + 12 AAA advisory in light theme, exited 1. `--self-test` exits 0 (gate-liveness proof). Both targets appear in `make help`. |
| 4 | The existing 40-shot screenshot matrix still captures both themes cleanly as the dark-audit substrate | VERIFIED | `admin_screenshot_matrix.spec.ts` last commit is `ae33d36` (v1.33) — no phase 128 commits touch it. Git diff confirms 0 changes. Live run per 128-03 SUMMARY: 3 test groups passed, 40 PNGs captured. |

**Score:** 4/4 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/scrypath_ecommerce/package.json` | `@axe-core/playwright ^4.11.3` devDep + `test:e2e:admin-contrast` script | VERIFIED | Grep confirmed `"@axe-core/playwright": "^4.11.3"` in devDependencies and `"test:e2e:admin-contrast": "playwright test e2e/admin_contrast_matrix.spec.ts"` in scripts. |
| `scrypath_ops/assets/css/contrast-pairs.mjs` | 13-entry MUTED_PAIRS manifest; token names only; 1 decorative; 1 large role; ops-badge-neutral bg=base-200 | VERIFIED | Node import confirms 13 entries. `"decorative"` count = 1. `.ops-handoff__eyebrow` has `role: "large"`. `.ops-badge-neutral` has `bg_token: "base-200"`. No hex values in file. |
| `examples/scrypath_ecommerce/contrast-checker.mjs` | Dependency-free ESM; WCAG math; D-15 guards; `--self-test` | VERIFIED | 816 lines. Zero npm imports (only node: built-ins). `--self-test` exits 0. Contains `21.00`, `#767676`, `#595959`, `aaa-body-advisory`, `GITHUB_STEP_SUMMARY`, `GITHUB_ACTIONS`. D-15 guard bidirectional (CR-01 + WR-02 fixes). Exit pattern: `process.exit(report.summary.aa_fail > 0 ? 1 : 0)`. |
| `examples/scrypath_ecommerce/Makefile` | `contrast` + `contrast-matrix` targets; both in `make help`; `CONTRAST_REPORT_DIR` var | VERIFIED | Both targets in `.PHONY` line. `CONTRAST_REPORT_DIR` appears 3 times (declaration + 2 usage). Both targets appear in `make help` output with description strings. |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` | contrast-pairs.mjs pointer + sRGB algorithm note + threshold reference | VERIFIED | `grep -q "contrast-pairs.mjs"` exits 0. `grep -q "sRGB"` exits 0. `grep -q "fg_channel"` exits 0 (formula present). |
| `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` | Full axe contrast gate; ThemeMode discriminated union; assertSystemDarkInvariants; 3 theme modes; D-04/D-20 two-pass axe; D-02 indices 10-13 | VERIFIED | All required patterns confirmed: `AxeBuilder`, `assertSystemDarkInvariants`, `system-dark`, `colorScheme.*dark`, `violations` (D-04 gate), `incomplete` (advisory only), `color-contrast-enhanced` (D-20 AAA pass), `aaa-body-advisory`, `not.toHaveAttribute.*data-theme` (D-08 invariant 1), index `"10"` (D-02 supplement). try/catch around AAA pass (CR-03). Scenario-scoped filenames `contrast-report.axe.${scenario}` (CR-02). |
| `.planning/phases/128-contrast-gate-harness-dark-seed-coverage-s-g/128-CONTRAST-REPORT.md` | Schema tag + summary + AA failures + AAA advisory + systemic note | VERIFIED | Contains `scrypath.contrast.v1`, `summary`, `systemic`, `aa_fail`, section for AA failures (108 total), section for AAA advisory (0 from axe, 12 from token checker). Gitignored raw artifacts noted. Status FAIL (108 violations) is correct — measurement phase. |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `contrast-checker.mjs` | `scrypath_ops/assets/css/contrast-pairs.mjs` | `import(PAIRS_PATH)` dynamic import | VERIFIED | `PAIRS_PATH = path.resolve(__dirname, "../../scrypath_ops/assets/css/contrast-pairs.mjs")`. Live run of `node contrast-checker.mjs` confirms MUTED_PAIRS imported successfully (D-15 Guard 2 passed). |
| `contrast-checker.mjs` | `scrypath_ops/assets/css/app.css` | `readFile(APP_CSS_PATH)` | VERIFIED | `APP_CSS_PATH = path.resolve(__dirname, "../../scrypath_ops/assets/css/app.css")`. D-15 Guard 1 parsed 20 tokens per theme block, D-15 Guard 2 found all muted text occurrences. No guard failure on live run. |
| `Makefile` | `contrast-checker.mjs` | `node contrast-checker.mjs` | VERIFIED | `make contrast` runs the checker in under 1 second. |
| `admin_contrast_matrix.spec.ts` | `@axe-core/playwright` | `import { AxeBuilder } from '@axe-core/playwright'` | VERIFIED | Import found at line 40. `@axe-core/playwright ^4.11.3` installed in node_modules. |
| `admin_contrast_matrix.spec.ts` | `e2e/helpers/e2e.ts` | `seedScenario, waitForLiveConnected, drainSearchQueue, waitForSearchVisible` | VERIFIED | All four helpers imported and used in the spec. `waitForLiveConnected` called inside every `gotoXxx` prepare helper; `assertSystemDarkInvariants` runs after it for system-dark mode. |
| `128-CONTRAST-REPORT.md` | `test-results/contrast/` (gitignored run artifacts) | curated promotion from gitignored per-scenario runs | VERIFIED | Report documents the provenance; raw artifacts gitignored; committed file references `test-results/contrast/` as the source directory. |

---

### Data-Flow Trace (Level 4)

Not applicable — this phase delivers a measurement harness + static manifest files, not a component that renders dynamic data. The checker reads real CSS (app.css) and writes real reports; the spec drives real Playwright test runs. Both verified as live in behavioral spot-checks below.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Gate-liveness: self-test exits 0 | `node contrast-checker.mjs --self-test` | "self-test passed", exit 0 | PASS |
| Fast checker finds real AA failures and exits 1 | `node contrast-checker.mjs` | 3 AA failures (3.9:1), 12 AAA advisory, exit 1 | PASS |
| `make contrast` appears in `make help` | `make help \| grep contrast` | "contrast-matrix" and "contrast" with descriptions | PASS |
| `@axe-core/playwright` devDep installed | grep in package.json | `"@axe-core/playwright": "^4.11.3"` | PASS |
| `test:e2e:admin-contrast` script present | grep in package.json | `"test:e2e:admin-contrast": "playwright test e2e/admin_contrast_matrix.spec.ts"` | PASS |
| contrast-pairs.mjs exports 13 entries | node ESM import + count | 13 entries, 1 decorative, 1 large, ops-badge-neutral bg=base-200 | PASS |
| app.css unchanged (scope guard) | `git diff --name-only app.css` | 0 lines (no changes) | PASS |
| admin_screenshot_matrix.spec.ts unchanged | `git diff --name-only` on file | 0 lines (last commit is ae33d36, pre-phase-128) | PASS |
| All phase 128 commits present | git log for 6 task + 4 fix commits | All 10 commits found (af1529e…d17b9eb) | PASS |

---

### Probe Execution

No `probe-*.sh` files declared or found for this phase. Behavioral spot-checks above serve as the equivalent.

---

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CONTRAST-HARNESS-01 | 128-01, 128-02, 128-03 | Automated WCAG contrast gate: axe matrix (light/dark/system-dark x seed scenarios), AA=build-fail, AAA advisory, re-runnable locally (`npm run test:e2e:admin-contrast` / `make contrast`), fast custom token-pair pre-check | SATISFIED | All four success criteria verified. Gate is live (exits 1 on real violations). REQUIREMENTS.md marks CONTRAST-HARNESS-01 as Complete at Phase 128. |

No orphaned requirements — only CONTRAST-HARNESS-01 is mapped to Phase 128 in REQUIREMENTS.md.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `e2e/admin_contrast_matrix.spec.ts` | 580 | `await page.waitForTimeout(500)` | INFO | In the `zero-results` search state (index "08"), a 500ms fixed wait is used after running a no-match search query. This is a minor test-reliability smell but does not affect the gate correctness — the search state that follows is intentionally "empty" and the wait is reasonable given the LiveView round-trip. Not a BLOCKER. |

No `TBD`, `FIXME`, or `XXX` debt markers found in any phase 128 modified files. No stubs or placeholder returns found. No hardcoded empty data flowing to rendering.

---

### Deferred Items

None — all four success criteria are observably achieved in the codebase. The per-scenario report overwrite limitation (noted in 128-CONTRAST-REPORT.md) was resolved by the CR-02 fix (scenario-namespaced filenames `contrast-report.axe.${scenario}.json`).

---

### Human Verification Required

None. All success criteria are verifiable programmatically:

1. The gate exists in code and runs (verified by self-test + live run evidence in 128-03 SUMMARY).
2. The AAA-only advisory path never affects exit code (verified by behavioral sub-proof in `--self-test`).
3. `make contrast` is a pure Node script verifiable without a browser (verified live).
4. Screenshot matrix regression is a file-existence + git-diff check (verified).

The live verification evidence provided by the orchestrator (3 scenarios x violations counts x exit codes) corroborates all code-level findings. No outstanding human items.

---

### Gaps Summary

No gaps. All four roadmap success criteria are achieved:

1. `npm run test:e2e:admin-contrast` — spec exists, wired, runs real axe matrix, exits non-zero on AA violations. VERIFIED.
2. AAA-body advisory — separate `color-contrast-enhanced` pass scoped to BODY_SELECTORS, never affects exit code, protected by try/catch. VERIFIED.
3. `make contrast` — dependency-free token-pair checker, no browser, exits non-zero on AA failures. VERIFIED.
4. 40-shot screenshot matrix — `admin_screenshot_matrix.spec.ts` unchanged (last commit pre-dates phase 128). VERIFIED.

The 108 AA violations and 3 fast-checker AA failures are the CORRECT and EXPECTED baseline for this measurement-only phase. They demonstrate the gate is live and reporting accurately. Downstream phases 129–136 fix the debt this harness measured.

---

_Verified: 2026-06-04_
_Verifier: Claude (gsd-verifier)_
