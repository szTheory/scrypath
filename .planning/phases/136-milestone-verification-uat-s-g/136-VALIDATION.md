---
phase: 136
slug: milestone-verification-uat-s-g
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-28
---

# Phase 136 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Mix/ExUnit + Phoenix LiveViewTest; Playwright 1.60.0 with @axe-core/playwright 4.11.3; static Node contrast scripts |
| **Config file** | `scrypath_ops/mix.exs`; `examples/scrypath_ecommerce/playwright.config.ts`; `examples/scrypath_ecommerce/package.json`; `examples/scrypath_ecommerce/Makefile` |
| **Quick run command** | `mix verify.opsui` |
| **Full suite command** | `mix verify.opsui`; `cd scrypath_ops && mix verify.opsui`; source-backed ecommerce server plus `cd examples/scrypath_ecommerce && make contrast && npm run test:e2e:admin-contrast -- --reporter=line && npm run test:e2e:admin-depth -- --reporter=line && npm run test:e2e:path-motion -- --reporter=line && npm run test:e2e:admin-shell -- --reporter=line && ADMIN_SCREENSHOT_DIR=.tmp/phase-136/admin-matrix npm run test:e2e:admin-matrix -- --reporter=line && npm run test:e2e -- e2e/operator.spec.ts --reporter=line` |
| **Estimated runtime** | Quick gate: under 180 seconds; full browser closeout bundle: several minutes after source server is warm |

---

## Sampling Rate

- **After every task commit:** Run the narrow automated gate for the artifact touched. Use `mix verify.opsui` for source or report changes that depend on Phoenix behavior; use the relevant Playwright spec for browser evidence.
- **After source or asset changes:** Rebuild ScrypathOps assets, restart or verify the source-backed ecommerce server, and rerun every browser proof that could have consumed stale CSS/JS.
- **After every plan wave:** Run all gates affected by the wave and update `136-DUALVERIFY-REPORT.md` with command status, environment, retries, and artifact paths.
- **Before `/gsd:verify-work`:** Full Phase 136 suite must be green, the 40-shot matrix must be recaptured, reports/manifests must exist, and human UAT must be signed off or explicitly blocked.
- **Max feedback latency:** 180 seconds for Mix-only checks; full browser bundle latency is accepted only at wave/phase boundaries.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 136-01-01 | 01 | 1 | DUALVERIFY-01 | T-136-01 | Proof runs against current source, rebuilt assets, and a recorded `PLAYWRIGHT_BASE_URL`, not a stale/baked server lane | build/ops | `mix verify.opsui`; source-backed ecommerce boot transcript; `cd examples/scrypath_ecommerce && npm run test:e2e -- e2e/operator.spec.ts --reporter=line` | Existing scripts/specs present; Wave 0 records boot lane in report | pending |
| 136-01-02 | 01 | 1 | DUALVERIFY-01 | T-136-02 | AA contrast failures, reduced-motion regressions, focus regressions, and disabled axe color-contrast rules cannot be hidden | static + e2e/a11y | `cd examples/scrypath_ecommerce && make contrast && npm run test:e2e:admin-contrast -- --reporter=line && npm run test:e2e:admin-depth -- --reporter=line && npm run test:e2e:path-motion -- --reporter=line && npm run test:e2e:admin-shell -- --reporter=line` | Existing specs present | pending |
| 136-01-03 | 01 | 1 | DUALVERIFY-01 | T-136-03 | Screenshot evidence has expected count, checksums, source commit, and generated/committed status so artifact mismatch is detectable | e2e/screenshot + manifest | `ADMIN_SCREENSHOT_DIR=.tmp/phase-136/admin-matrix npm run test:e2e:admin-matrix -- --reporter=line`; manifest checksum generation; manifest count assertions | Existing screenshot spec present; Wave 0 creates manifest/report artifacts | pending |
| 136-02-01 | 02 | 2 | DUALVERIFY-01 | T-136-04 | Before/after, milestone audit, and UAT evidence make automation limits and accepted follow-ups explicit | docs/manual | `rg -n "DUALVERIFY-01|PASS|FAIL|follow-up|blocked" .planning/phases/136-milestone-verification-uat-s-g/136-*.md` plus final human UAT checklist | Wave 0 creates reports | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `136-DUALVERIFY-REPORT.md` - command transcript summary, environment, source-backed server lane, gate results, AA/AAA status, reduced-motion status, smoke status, artifact paths, defects, and follow-up decisions.
- [ ] `136-ARTIFACT-MANIFEST.json` - machine-readable generated artifact index with counts, paths, checksums, source commit, command provenance, and committed/generated status.
- [ ] `136-BEFORE-AFTER.md` - dark-weighted v1.33 to v1.34 claim-based gallery narrative with paired screenshot references.
- [ ] `136-MILESTONE-AUDIT.md` - requirement-by-requirement v1.34 audit across phases 128-136 and any evidence gaps.
- [ ] `136-UAT.md` - bounded job-based human UAT checklist, findings, sign-off status, and accepted follow-ups.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator trust, scanability, calmness, and theme parity across Control Room, Posture, Failed Sync, Sync/Drift, Search, and Playbooks | DUALVERIFY-01 | Automation cannot fully judge perceptual trust, task orientation, and whether the UI feels calm and trustworthy | Inspect the six operator surfaces dark-first, then light parity, then system-dark evidence; answer whether a maintainer can tell search posture, the next recovery/explore action, and whether the UI is accessible and trustworthy |
| v1.33 to v1.34 before/after claim fit | DUALVERIFY-01 | The final gallery is claim-based, not just a screenshot dump | Review each before/after row against the JTBD claims for route orientation, posture trust, failed-sync recovery, drift clarity, search exploration, playbook workspace clarity, shell restraint, focus, and theme parity |

---

## Validation Sign-Off

- [x] All Phase 136 closeout behaviors have automated gates, generated artifact checks, or explicit human UAT.
- [x] Sampling continuity: no 3 consecutive tasks may skip an automated or artifact-integrity check.
- [x] Wave 0 covers all missing report, manifest, before/after, audit, and UAT artifacts.
- [x] No watch-mode flags are used in validation commands.
- [x] Feedback latency target distinguishes quick Mix checks from full browser closeout gates.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
