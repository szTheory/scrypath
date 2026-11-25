---
phase: "196"
slug: "fixtures-and-three-adopters"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-21"
---

# Phase 196 — Validation Strategy

> Seeded from the Validation Architecture section of [196-RESEARCH.md](196-RESEARCH.md), which holds the full requirement-to-test map and the local mirror of each required CI lane. No human UAT: every row is an executable check or a recorded decision. The plans own the per-task map.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19) with `Phoenix.LiveViewTest` and `LazyHTML` in `scrypath_ops`; ExUnit at the root; `node --test` for CI scripts |
| **Config file** | `scrypath_ops/test/test_helper.exs`; root `test/test_helper.exs` |
| **Quick run command** | `cd scrypath_ops && MIX_ENV=test mix scrypath_fixtures.check_fixtures` (DB-free, about 0.5 s) plus the one changed test file |
| **Full suite command** | `mix verify.ops_ui` from the repo root (Postgres reachable) |
| **Estimated runtime** | quick: seconds; full: 6 to 8 min |

## Sampling Rate

- **After every task commit:** `mix format --check-formatted`, the fixtures check task, the one changed test file
- **After every plan wave:** root contract set, ops fixtures tests, `scripts/ci/pre_push.sh`
- **Before verify-work:** local mirror of every required lane on the committed head, then hosted CI green on the exact PR head
- **Max feedback latency:** 60 s for the quick run

## Per-Task Verification Map

| Requirement | Check | Test type | Status |
|-------------|-------|-----------|--------|
| FIX-01 | Logistify builders, fake client, real `Status` and `Posture`, rendered `/ops/health` with a deep queue and nothing failed; unknown enum raises | ops LiveViewTest + unit | ⬜ pending |
| FIX-02 | Builder shapes equal the recorded Meilisearch payloads; failure strings from a closed table with resolving `source:`; hostile text only as escapes | check task + ops unit | ⬜ pending |
| FIX-03 | Every scenario of the three adopters round-trips the real normalizers; "(fictional)" labels; denylist words absent | check task + ops unit | ⬜ pending |
| FIX-04 | Check runs first in the `test` alias, DB-free, one planted failure per invariant; two renders with different `now` differ only in time text; `fixtures/` never ships; classifier and boundary decisions; phase173 sources unchanged | root + ops tests | ⬜ pending |

## Wave 0 Requirements

- [ ] `fixtures/scrypath_fixtures` project skeleton, the check task and the ops wiring
- [ ] Root boundary, archive, classifier, formatter and namespace-fence edits listed in the research "Wave 0 Gaps"

## Manual-Only Verifications

All phase behaviors have automated verification. Hosted `ops-ui` timings are recorded evidence, not a pass or fail gate.

## Validation Sign-Off

- [ ] All tasks have an automated verify or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without an automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
