---
phase: "176"
slug: "search-and-playbooks"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-10"
---

# Phase 176 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest; Playwright for the existing browser lane |
| **Config file** | `scrypath_ops/mix.exs`; `examples/scrypath_ecommerce/package.json` |
| **Quick run command** | `mix test test/scrypath_ops_web/live/search_live_test.exs test/scrypath_ops_web/live/playbook_live_test.exs` from `scrypath_ops/` |
| **Full suite command** | `mix verify.ops_ui` from the repository root |
| **Estimated runtime** | Not measured in this shell; no Elixir/Mix version is selected |

---

## Sampling Rate

- **After every task commit:** Run the focused LiveView test for the changed surface.
- **After every plan wave:** Run `mix verify.ops_ui` and inspect the changed light/dark and narrow/desktop captures; run the existing browser and contrast lanes when layout or focus behavior changes.
- **Before `$gsd-verify-work`:** Pass `mix verify.ops_ui` and the applicable focused browser/contrast checks.
- **Feedback latency:** Keep task-level checks focused; measure runtime when a supported local BEAM toolchain is available.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 176-01-01 | 01 | 1 | OPUX-23 | T-176-01 | Results and capture use submitted criteria; current form edits cannot relabel prior evidence | LiveView | `mix test test/scrypath_ops_web/live/search_live_test.exs` from `scrypath_ops/` | Yes — extend existing suite | ⬜ pending |
| 176-01-02 | 01 | 1 | OPUX-23 | T-176-01 | One native submit remains; result status is concise and does not move focus | Browser | `npm run test:e2e:admin-depth` from `examples/scrypath_ecommerce/` against a disposable stack | Yes — extend existing lane | ⬜ pending |
| 176-02-01 | 02 | 2 | OPUX-24 | T-176-02 | Draft, run, import, and save state retain their distinct source and persistence meaning | LiveView | `mix test test/scrypath_ops_web/live/playbook_live_test.exs` from `scrypath_ops/` | Yes — extend existing suite | ⬜ pending |
| 176-02-02 | 02 | 2 | OPUX-24 | T-176-02 | Preview, run, result, and save hierarchy works through rendered controls on both themes and widths | Browser | `npm run test:e2e:admin-depth` from `examples/scrypath_ecommerce/` against a disposable stack | Yes — extend existing lane | ⬜ pending |
| 176-03-01 | 03 | 3 | OPUX-25 | T-176-03 | File mutation remains server-authorized, path-safe, collision-safe, and exact-name-confirmed | LiveView | `mix test test/scrypath_ops_web/live/playbook_live_test.exs` from `scrypath_ops/` | Yes — extend existing suite | ⬜ pending |
| 176-03-02 | 03 | 3 | OPUX-25 | T-176-03 | Dialog validation and visible logical focus return survive real LiveView row patches | Browser | `npm run test:e2e:admin-depth` from `examples/scrypath_ecommerce/` against a disposable stack | Yes — extend existing lane | ⬜ pending |

---

## Wave 0 Requirements

None — existing LiveView, Ops UI, disposable browser, and contrast infrastructure covers the phase. Extend existing tests for the named missing-risk cases; do not add a dependency or a required service.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Directly judge reading order, hierarchy, wrapping, and status clarity in rendered before/after captures | OPUX-23, OPUX-24, OPUX-25 | Image and DOM assertions can detect geometry and state regressions, but cannot fully judge whether the hierarchy is easy to scan | Inspect changed Search and Playbooks states in light/dark at desktop/narrow widths and at a changed breakpoint. Include long identifiers and filenames, empty/partial/error/disabled states, preview/run/save, Manage disclosure, and dialog validation. Record the inspected capture paths in the phase evidence. This is implementation evidence, not a pending user acceptance round. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references — no new infrastructure is required
- [ ] No watch-mode flags
- [ ] Task-level feedback latency measured after toolchain selection
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
