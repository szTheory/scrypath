---
phase: 135
slug: shell-chrome-polish-dual-theme-s
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-26
---

# Phase 135 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Phoenix LiveViewTest; Playwright 1.60.0 with @axe-core/playwright 4.11.3 |
| **Config file** | `examples/scrypath_ecommerce/playwright.config.ts`; ExUnit through `scrypath_ops/mix.exs` |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/ops_a11y_contract_test.exs` |
| **Full suite command** | `cd scrypath_ops && mix verify.opsui`; plus, after the source server is booted, `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --reporter=line && npm run test:e2e:admin-contrast -- --reporter=line` |
| **Estimated runtime** | Quick ExUnit: under 20 seconds; focused Playwright: under 120 seconds once the server is warm; full ops UI gate: under 180 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick ExUnit shell/a11y contract command.
- **After every browser/CSS task commit:** Run `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --reporter=line` against a booted source server.
- **After every plan wave:** Run `cd scrypath_ops && mix verify.opsui`, `cd examples/scrypath_ecommerce && make contrast`, and the focused shell Playwright spec.
- **Before `/gsd:verify-work`:** Full suite must be green.
- **Max feedback latency:** 180 seconds for focused gates after the server is warm.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 135-01-01 | 01 | 1 | SHELL-DARK-01 | T-135-01 | Shell chrome exposes correct theme and ARIA state without adding routes or untrusted HTML | Playwright interaction/computed-style | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --reporter=line` | No - Wave 0 creates `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` and package script | pending |
| 135-01-02 | 01 | 1 | SHELL-DARK-01 | T-135-02 | Header/nav contrast, active states, and `.ops-shell` wash remain AA-clean in light, dark, and system-dark | Playwright + axe/computed-style | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --reporter=line && npm run test:e2e:admin-contrast -- --reporter=line` | Partial - contrast matrix exists; shell spec missing | pending |
| 135-01-03 | 01 | 1 | SHELL-DARK-01 | T-135-03 | Command palette and shortcut sheet use honest dialog semantics, visible focus, and controlled client-only filtering | Playwright interaction/a11y | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --reporter=line` | No - Wave 0 creates shell spec | pending |
| 135-01-04 | 01 | 1 | SHELL-DARK-01 | T-135-04 | Flash keeps role/text/icon status signals and non-color-only communication in both themes | ExUnit + Playwright | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_a11y_contract_test.exs && cd ../examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --reporter=line` | Existing component tests exist; shell browser coverage missing | pending |

---

## Wave 0 Requirements

- [ ] `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` - focused browser coverage for hidden chrome, shell computed styles, command palette/sheet behavior, theme transitions, flash, nav, and `.ops-shell` wash.
- [ ] `examples/scrypath_ecommerce/package.json` - script `test:e2e:admin-shell` running the focused shell spec.
- [ ] Optional static contract additions in `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` or a narrowly-scoped CSS contract test if implementation adds new shell classes or tokens that need cheap tripwires.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Quiet ambient glow read of `.ops-shell` on Night | SHELL-DARK-01 | The final "quiet, not a blob" judgment is partially perceptual even though computed-style guards can prevent regression-prone values | Capture or inspect Control Room, Posture, Failed Sync, Sync/Drift, Search, and Playbooks in Night and confirm the wash is ambient, not a discrete purple blob |

---

## Validation Sign-Off

- [x] All planned shell behaviors have automated verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks may skip automated verification.
- [x] Wave 0 covers missing browser shell references.
- [x] No watch-mode flags are used in validation commands.
- [x] Feedback latency target is under 180 seconds after server warm-up.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
