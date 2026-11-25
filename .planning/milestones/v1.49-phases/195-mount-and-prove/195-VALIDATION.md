---
phase: "195"
slug: "mount-and-prove"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-21"
---

# Phase 195 — Validation Strategy

> Seeded from the Validation Architecture section of [195-RESEARCH.md](195-RESEARCH.md). No human UAT: every row is an executable check or a recorded number.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19) with `Phoenix.LiveViewTest` and `LazyHTML` in `scrypath_ops`; ExUnit at the root |
| **Config file** | `scrypath_ops/test/test_helper.exs`; root `test/test_helper.exs` |
| **Quick run command** | root: `mix test test/mix/tasks/dependency_boundary_contract_test.exs test/release/package_metadata_test.exs`; ops: `mix test test/scrypath_ops_web/catalog_contract_test.exs test/scrypath_ops_web/catalog_routes_test.exs test/scrypath_ops_web/ops_shell_contract_test.exs` (in `scrypath_ops/`) |
| **Full suite command** | `mix verify.ops_ui` from the repo root (Postgres reachable) |
| **Estimated runtime** | quick: seconds to about 30 s; full: 6 to 8 min |

## Sampling Rate

- **After every task commit:** `mix format --check-formatted` (root) and the focused test files
- **After every plan wave:** root boundary and package tests, the ops catalog tests, `mix precommit` in `scrypath_ops`
- **Before verify-work:** local mirror of every required lane on the committed head (research table), then hosted CI green on the exact PR head
- **Max feedback latency:** 60 s for the quick run

## Per-Task Verification Map

The plans own this map: each task's `<verify>`, `<phase_gate>` and `<acceptance_criteria>` in 195-01, 195-02 and 195-03 are authoritative. The research "Validation Architecture" table is the seed. The research's separate `storybook_render_all_test.exs` and `storybook_planted_test.exs` were renamed and merged into `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs` (orchestrator decision 5): the file Phase 197 extends, with mount, render-all and planted-tree describes.

| Requirement | Check | Test type | Status |
|-------------|-------|-----------|--------|
| MOUNT-01 | dependency present, `~> 1.5`, `only: [:dev, :test]`; planted loosening fails; storybook-only packages absent from mounted and prod graphs | root unit + scratch-consumer integration | ✅ green |
| MOUNT-01 | `verify-dependency-boundaries.sh` forbids the names for prod and host only; mutation fails; tarball refutes `fixtures` and `storybook` | root unit | ✅ green |
| MOUNT-02 | guard outside the `quote` (AST), planted removal and move-inside fail; flag truth table; prod route table has no `/storybook` | root + ops unit, integration probe | ✅ green |
| MOUNT-03 | every variation of five primitives renders through the real iframe route; planted failing tree is detected; `storybook.js` registers the `app.js` hooks | ops unit | ✅ green |
| MOUNT-04 | `GO-NO-GO.md` has the required headings and numbers; ADR 0001 amended; one verdict per trigger | doc check (`grep -c`) plus recorded hosted numbers | ✅ green |
| FLOW-01, FLOW-03 | PR titles; no staged config files | `git diff --cached --name-only` check | ✅ green |

## Wave 0 Requirements

- [x] `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs` (mount, render-all, planted tree) and `catalog_routes_test.exs`
- [x] `scrypath_ops/test/support/` planted backend, endpoint and router (one module per file)
- [x] Root helper `has_node_outside_quote?/2` and the new and edited cases in `dependency_boundary_contract_test.exs`

## Manual-Only Verifications

All phase behaviors have automated verification. Hosted `ops-ui` timings are recorded evidence in `GO-NO-GO.md`, not a pass or fail gate.

## Validation Sign-Off

- [x] All tasks have an automated verify or a Wave 0 dependency
- [x] Sampling continuity: no 3 consecutive tasks without an automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-11-21 by the goal-backward verification (8/8, see 195-VERIFICATION.md)
