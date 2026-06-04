---
phase: 128
slug: contrast-gate-harness-dark-seed-coverage-s-g
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 128 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `128-RESEARCH.md` §Validation Architecture. This phase IS a
> measurement harness, so the load-bearing proof is that the gate is **live**
> (fails on a real violation), not merely that it runs.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `@playwright/test` 1.54.2 (e2e) + dependency-free Node `.mjs` (token checker) |
| **Config file** | `examples/scrypath_ecommerce/playwright.config.ts` (existing) |
| **Quick run command** | `cd examples/scrypath_ecommerce && node contrast-checker.mjs --self-test` |
| **Full suite command** | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-contrast` |
| **Estimated runtime** | self-test <1s · `make contrast` <1s · full axe matrix ~2–4 min |

---

## Sampling Rate

- **After every task commit:** Run `node contrast-checker.mjs --self-test` (<1s, pure Node)
- **After every plan wave:** Run `npm run test:e2e:admin-contrast` + `npm run test:e2e:admin-matrix`
- **Before `/gsd:verify-work`:** Full suite (contrast matrix + token checker + 40-shot screenshot matrix) green
- **Max feedback latency:** <1s (self-test) for the inner loop; ~4 min for the full gate

---

## Per-Task Verification Map

| Behavior | Requirement | Threat Ref | Test Type | Automated Command | File Exists | Status |
|----------|-------------|------------|-----------|-------------------|-------------|--------|
| Gate exits non-zero on a real AA violation (`#767676`/`#fff` = 4.48:1) | CONTRAST-HARNESS-01 | — | unit (fixture) | `node contrast-checker.mjs --self-test` | ❌ W0 | ⬜ pending |
| Gate exits zero on a compliant pair (`#595959`/`#fff` = 7.0:1) | CONTRAST-HARNESS-01 | — | unit (fixture) | `node contrast-checker.mjs --self-test` | ❌ W0 | ⬜ pending |
| Golden WCAG math: black-on-white = 21.00:1 (D-13) | CONTRAST-HARNESS-01 | — | unit (fixture) | `node contrast-checker.mjs --self-test` | ❌ W0 | ⬜ pending |
| AAA-body advisory never affects exit code (D-20/D-21) | CONTRAST-HARNESS-01 | — | unit (fixture) | `node contrast-checker.mjs --self-test` | ❌ W0 | ⬜ pending |
| Cross-checker coherence: token checker ↔ axe agree on same fg/bg (D-12) | CONTRAST-HARNESS-01 | — | unit | `node contrast-checker.mjs --self-test` | ❌ W0 | ⬜ pending |
| D-15 lockstep: token-count assertion + untracked-muted-token grep fail loudly | CONTRAST-HARNESS-01 | — | unit | `make contrast` | ❌ W0 | ⬜ pending |
| system-dark exercises media-query cascade, not `[data-theme=dark]` (D-06/D-08) | CONTRAST-HARNESS-01 | — | e2e (invariants) | `npm run test:e2e:admin-contrast` | ❌ W0 | ⬜ pending |
| Full matrix (≈13 states × 3 modes × 2 viewports) gates AA on `violations[]` only | CONTRAST-HARNESS-01 | — | e2e | `npm run test:e2e:admin-contrast` | ❌ W0 | ⬜ pending |
| Existing 40-shot screenshot matrix still captures both themes (success crit #4) | CONTRAST-HARNESS-01 | — | e2e smoke | `npm run test:e2e:admin-matrix` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### The six load-bearing proofs (from RESEARCH.md §Validation Architecture)

1. **Gate is live, not dead** — known-failing pair `#767676/#fff` (4.48:1) MUST exit non-zero. A green run with a dead gate is the primary failure mode this phase must rule out.
2. **Compliant pair does not gate** — `#595959/#fff` (7.0:1) exits zero.
3. **Cross-checker coherence** — fast token checker and the axe gate render ONE verdict on the same fg/bg (identical sRGB compositing D-12 + identical thresholds D-14); proven via shared WCAG math + golden pairs + a `DESIGN-TOKENS.md` note that the algorithm matches axe-core.
4. **system-dark = media-query path** — D-08 invariants ARE the test: `<html>` has no `data-theme`; `matchMedia('(prefers-color-scheme: dark)').matches === true`; `data-theme-effective="dark"`.
5. **AAA advisory never gates** — exit code keys on `summary.aa_fail > 0` only; a case with `aaa_advisory > 0 && aa_fail === 0` exits 0.
6. **40-shot matrix intact** — `admin_screenshot_matrix.spec.ts` is unchanged and still captures both themes.

---

## Wave 0 Requirements

- [ ] `examples/scrypath_ecommerce/contrast-checker.mjs` — hand-rolled WCAG math + golden self-test (D-13), lockstep guards (D-15), `--self-test` flag covering proofs 1/2/3/5
- [ ] `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` — cloned axe matrix covering CONTRAST-HARNESS-01 e2e + D-08 system-dark invariants
- [ ] `scrypath_ops/assets/css/contrast-pairs.mjs` — D-11 muted-alpha manifest (input to the checker)
- [ ] `@axe-core/playwright` (4.11.3) devDependency — `npm install --save-dev @axe-core/playwright` in `examples/scrypath_ecommerce`

*No existing test infrastructure covers Phase 128 requirements; all gate files are new. The 40-shot screenshot matrix already exists and is exercised as a regression smoke.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `BODY_SELECTORS` allowlist actually targets body/long-form text | CONTRAST-HARNESS-01 | Allowlist correctness is a judgment call against rendered screens | Cross-check the allowlist against `prompts/scrypath-brand-book.md` + screen templates during planning/execution |

*All gating behaviors have automated verification; only the advisory AAA allowlist scope is a manual judgment.*

---

## Validation Sign-Off

- [ ] All tasks have an automated verify command or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (checker, spec, manifest, axe dep)
- [ ] No watch-mode flags
- [ ] Feedback latency < 1s for the self-test inner loop
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
