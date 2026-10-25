---
phase: "176"
slug: "search-and-playbooks"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-10"
validated: "2026-10-11"
---

# Phase 176 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest; Playwright for the existing browser lane |
| **Config file** | `scrypath_ops/mix.exs`; `examples/scrypath_ecommerce/package.json` |
| **Quick run command** | `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/scrypath_ops_web/live/search_live_test.exs test/scrypath_ops_web/live/playbook_live_test.exs` from `scrypath_ops/` |
| **Full suite command** | `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix verify.ops_ui` from the repository root |
| **Estimated runtime** | 2.82 seconds for the 52-test Search + Playbooks focused suite; full Ops gate passed on the committed tree |

---

## Sampling Rate

- **After every task commit:** Run the focused LiveView test for the changed surface.
- **After every plan wave:** Run `mix verify.ops_ui` and inspect the changed light/dark and narrow/desktop captures; run the existing browser and contrast lanes when layout or focus behavior changes.
- **Before phase verification:** Pass `mix verify.ops_ui` and the applicable focused browser/contrast checks.
- **Feedback latency:** Measured at 2.82 seconds for 52 focused Search + Playbooks tests with Elixir 1.19.0 / OTP 28.1.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 176-01-01 | 01 | 1 | OPUX-23 | T-176-01 | One real submit snapshots mode and criteria before queued dispatch; old result cannot be relabeled | LiveView + browser | Focused Search + Playbooks suite; admin-depth browser lane | Yes — existing suites | ✅ green |
| 176-01-02 | 01 | 1 | OPUX-23 | T-176-02 | Complete, zero, partial, hard-failure and unavailable states expose true per-index evidence and concise status | LiveView + browser | Focused Search + Playbooks suite; admin-depth browser lane | Yes — existing suites | ✅ green |
| 176-02-01 | 02 | 2 | OPUX-23 | T-176-03 | Capture stores submitted criteria/metadata only; occupied Search filename is rejected | LiveView | Focused Search + Playbooks suite; `mix verify.ops_ui` | Yes — existing suite | ✅ green |
| 176-02-02 | 02 | 2 | OPUX-23 | T-176-03 | Progressive capture handles eligible zero/partial, retained failed-save fields and actual persisted handoff | Browser | 38/38 admin-depth browser tests | Yes — existing lane | ✅ green |
| 176-03-01 | 03 | 3 | OPUX-24 | T-176-04, T-176-05 | Draft source, independent save, replacement and actual write outcome stay distinct | LiveView | Focused Search + Playbooks suite; `mix verify.ops_ui` | Yes — existing suite | ✅ green |
| 176-03-02 | 03 | 3 | OPUX-24 | T-176-04 | Catalog → preview/common actions → outcome → import works in rendered responsive app | Browser | 38/38 admin-depth browser tests | Yes — existing lane | ✅ green |
| 176-04-01 | 04 | 4 | OPUX-24 | T-176-07 | Captured run source/criteria survive later load/import/save; stale replies, timeout, cancel and supersede retain guards | LiveView | Focused Search + Playbooks suite; `mix verify.ops_ui` | Yes — existing suite | ✅ green |
| 176-04-02 | 04 | 4 | OPUX-24 | T-176-06 | Upload/paste 256,000-byte boundary, malformed JSON and prior-preview retention work through rendered import | LiveView + browser | Focused Search + Playbooks suite; 38/38 admin-depth browser tests | Yes — existing suites | ✅ green |
| 176-05-01 | 05 | 5 | OPUX-25 | T-176-08 | File actions stay contextual while server authorization, basename/path, collision and exact delete checks hold | LiveView | Focused Search + Playbooks suite; `mix verify.ops_ui` | Yes — existing suite | ✅ green |
| 176-05-02 | 05 | 5 | OPUX-25 | T-176-09 | Modal carries stable file identity, invalid value and logical visible return target metadata across patches | LiveView | Focused Search + Playbooks suite; `mix verify.ops_ui` | Yes — existing suite | ✅ green |
| 176-05-03 | 05 | 5 | OPUX-23, OPUX-24, OPUX-25 | T-176-09 | Browser proves dialog focus/inertness/return and responsive hierarchy; phase gate runs | Browser + Ops gate | 38/38 admin-depth browser tests; contrast; `mix verify.ops_ui`; asset build | Yes — existing lanes | ✅ green |

---

## Wave 0 Requirements

None — existing LiveView, Ops UI, disposable browser, and contrast infrastructure covers the phase. Extend existing tests for the named missing-risk cases; do not add a dependency or a required service.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions / Result |
|----------|-------------|------------|----------------------------|
| Reading order, hierarchy, wrapping, and status clarity in rendered before/after captures | OPUX-23, OPUX-24, OPUX-25 | Image and DOM assertions can detect geometry and state regressions, but cannot fully judge whether the hierarchy is easy to scan | Reviewed the changed Search and Playbooks captures in light/dark at desktop, tablet, and narrow widths, including empty/partial/error/disabled states, preview/run/save, Manage disclosure, and dialog validation. Evidence is in `examples/scrypath_ecommerce/test-results/phase176-management-evidence/`, `phase176-search-evidence/`, and `phase176-import-evidence/`. No pending user acceptance remains. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references — no new infrastructure is required
- [x] No watch-mode flags
- [x] Task-level feedback latency measured after toolchain selection
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Validated — all 12 task rows are covered by passing focused/integrated tests; browser, contrast, and asset gates passed. No coverage gaps were found.

## Validation Audit 2026-10-11

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Phase Closeout Verification — `3cc55bd`

Final-source checks for the Search/Playbooks UI and workspace Store:

| Check | Result |
|---|---|
| Store + Search + Playbooks focused ExUnit suite | 75 tests, 0 failures |
| `mix verify.ops_ui` from repository root | 2 doctests, 301 tests, 0 failures |
| Prior-phase operator status regression suite | 6 tests, 0 failures |
| `mix assets.build` from `scrypath_ops/` | passed |
| `make contrast` from `examples/scrypath_ecommerce/` | 0 AA failures; 43 AAA advisory findings |
| Isolated Compose Playwright `admin_surface_depth.spec.ts` | 38 passed, 0 failed |
| Code review | clean; 0 critical, 0 warning, 0 info findings |

The browser lane uses the separate `phase176-final` Compose project with host web ports removed. Its first invocation began before the web service passed health checks and all requests were refused; after waiting for the service health check, the same 38-case suite passed. The isolated containers, network, and playbook volume were removed afterward. The retained preview was not used.

The final Store change adds no dependencies. Existing compile-time Dialyzer and LiveView async-assign warnings remain outside this phase's changed files.
