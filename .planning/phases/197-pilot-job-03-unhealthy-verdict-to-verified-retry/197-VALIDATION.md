---
phase: "197"
slug: "pilot-job-03-unhealthy-verdict-to-verified-retry"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-22"
---

# Phase 197 — Validation Strategy

> Seeded from the Validation Architecture section of [197-RESEARCH.md](197-RESEARCH.md), which holds the requirement-to-test map and the local mirror of each required CI lane. No human UAT: every row is an executable check or a recorded decision; the maintainer's look at Pause 1 is feedback, not a completion gate. The plans own the per-task map.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19) with `Phoenix.LiveViewTest` and `LazyHTML` in `scrypath_ops`; root ExUnit; `node --test` for CI scripts and the preflight |
| **Config file** | `scrypath_ops/test/test_helper.exs`; root `test/test_helper.exs` |
| **Quick run command** | the one changed test file, plus `cd scrypath_ops && MIX_ENV=test mix scrypath_fixtures.check_fixtures` |
| **Full suite command** | `mix verify.ops_ui` from the repo root (Postgres reachable; `HEX_HTTP_TIMEOUT=120` locally) |
| **Estimated runtime** | quick: seconds; full: 6 to 8 min |

## Sampling Rate

- **After every task commit:** `mix format --check-formatted`, the changed test file, the fixtures check
- **After every plan wave:** the ops catalog and journey tests, root contract set, `scripts/ci/pre_push.sh`
- **Before verify-work:** local mirror of every required lane on the committed head, then hosted CI green on the exact PR head
- **Max feedback latency:** 60 s for the quick run

## Per-Task Verification Map

| Requirement | Check | Test type | Status |
|-------------|-------|-----------|--------|
| PILOT-01 | Mounted journey (Health row, Failed sync prefilled, denial with positive control and absence check, retry with exactly one insert, return link with the same context) written first, green on current code; repaired stale-sudo test renders the row | ops LiveViewTest | ⬜ pending |
| PILOT-02 | Stale-sudo return_to defect (D1) fixed in scrypath_ops with its own test; no root `lib/` change | ops test + diff guard | ⬜ pending |
| PILOT-03 | View-models and shared components; canonicalized before and after parity shows no unintended change; journey green unmodified; D3 crash becomes a closed state with its own test | ops tests + local parity capture | ⬜ pending |
| PILOT-04 | Tiered stories with JOB ids in paths, both themes, descriptions lint | catalog contract test | ⬜ pending |
| PILOT-05 | Catalog contract test: render-all, route and component coverage (no counts), no identical variations, copy lint, DOM hygiene, each with a planted failure; ledger row 11 of 12 | ops test + root wiring test | ⬜ pending |
| PILOT-06 | Seeded storybook on 127.0.0.1:4003, `storybook` block in `UI-PREVIEW.json`, landing page with `main@sha`, preflight checks it, AGENTS.md matches | node test + ops test + script run | ⬜ pending |
| PILOT-07 | Pause note written with the feedback-row template; the run then stops | doc check | ⬜ pending |

## Wave 0 Requirements

- [ ] Journey test file under `scrypath_ops/test/scrypath_ops_web/live/`, stubs and helpers
- [ ] Parity capture script and its canonicalizer (local, not committed as a gate)

## Manual-Only Verifications

All phase behaviors have automated verification. The maintainer's look at the storybook is the milestone's Pause 1 feedback, recorded in a dated note; it does not gate completion.

## Validation Sign-Off

- [ ] All tasks have an automated verify or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without an automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
