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
| 176-01-01 | 01 | 1 | OPUX-23 | T-176-01 | One real submit snapshots mode and criteria before queued dispatch; old result cannot be relabeled | LiveView + browser | `cd scrypath_ops && mix test test/scrypath_ops_web/live/search_live_test.exs`; `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-depth` | Yes — extend existing suites | ⬜ pending |
| 176-01-02 | 01 | 1 | OPUX-23 | T-176-02 | Complete, zero, partial, hard-failure and unavailable states expose true per-index evidence and concise status | LiveView + browser | Same focused Search and disposable admin-depth commands as 176-01-01 | Yes — extend existing suites | ⬜ pending |
| 176-02-01 | 02 | 2 | OPUX-23 | T-176-03 | Capture stores submitted criteria/metadata only; occupied Search filename is rejected | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/search_live_test.exs` | Yes — extend existing suite | ⬜ pending |
| 176-02-02 | 02 | 2 | OPUX-23 | T-176-03 | Progressive capture handles eligible zero/partial, retained failed-save fields and actual persisted handoff | Browser | `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-depth` | Yes — extend existing lane | ⬜ pending |
| 176-03-01 | 03 | 3 | OPUX-24 | T-176-04, T-176-05 | Draft source, independent save, replacement and actual write outcome stay distinct | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/playbook_live_test.exs` | Yes — extend existing suite | ⬜ pending |
| 176-03-02 | 03 | 3 | OPUX-24 | T-176-04 | Catalog → preview/common actions → outcome → import works in rendered responsive app | Browser | Disposable admin-depth command from 176-02-02 | Yes — extend existing lane | ⬜ pending |
| 176-04-01 | 04 | 4 | OPUX-24 | T-176-07 | Captured run source/criteria survive later load/import/save; stale replies, timeout, cancel and supersede retain guards | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/playbook_live_test.exs` | Yes — extend existing suite | ⬜ pending |
| 176-04-02 | 04 | 4 | OPUX-24 | T-176-06 | Upload/paste 256,000-byte boundary, malformed JSON and prior-preview retention work through rendered import | LiveView + browser | Focused Playbook and disposable admin-depth commands above | Yes — extend existing suites | ⬜ pending |
| 176-05-01 | 05 | 5 | OPUX-25 | T-176-08 | File actions stay contextual while server authorization, basename/path, collision and exact delete checks hold | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/playbook_live_test.exs` | Yes — extend existing suite | ⬜ pending |
| 176-05-02 | 05 | 5 | OPUX-25 | T-176-09 | Modal carries stable file identity, invalid value and logical visible return target metadata across patches | LiveView | Focused Playbook command above | Yes — extend existing suite | ⬜ pending |
| 176-05-03 | 05 | 5 | OPUX-23, OPUX-24, OPUX-25 | T-176-09 | Browser proves dialog focus/inertness/return and responsive hierarchy; phase gate runs | Browser + Ops gate | Disposable admin-depth command above; `make -C examples/scrypath_ecommerce contrast`; `mix verify.ops_ui` | Yes — extend existing lanes | ⬜ pending |

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
