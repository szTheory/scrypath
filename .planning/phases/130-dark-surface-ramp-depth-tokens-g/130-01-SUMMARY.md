---
phase: 130
plan: "01"
subsystem: e2e-tooling, mix-aliases
tags: [pixel-diff, light-gate, devdeps, mix-alias, darktoken]
dependency_graph:
  requires: []
  provides:
    - "examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs — Wave 0 light pixel-identity gate"
    - "pixelmatch + pngjs devDependencies installed in examples/scrypath_ecommerce/"
    - "mix verify.opsui alias (scrypath_ops/mix.exs) — D-13 fixed"
  affects:
    - "DARKTOKEN-01-c — Wave 0 unblocked"
    - "D-13 doc-drift resolved — mix verify.opsui is now a literal runnable target"
tech_stack:
  added:
    - "pixelmatch ^5.3.0 (npm devDep)"
    - "pngjs ^7.0.0 (npm devDep)"
  patterns:
    - "Node.js ESM script with path.resolve(__dirname, ...) path setup (contrast-checker.mjs analog)"
    - "pixelmatch PNG diff loop with pass/fail accumulation and exit-code contract"
    - "Mix alias composition: [\"test\", \"opsui.test_a11y\"]"
key_files:
  created:
    - "examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs"
  modified:
    - "examples/scrypath_ecommerce/package.json"
    - "examples/scrypath_ecommerce/package-lock.json"
    - "scrypath_ops/mix.exs"
decisions:
  - "FRESH_DIR defaults to .tmp/pixel-diff-fresh (not test-results/) to stay consistent with BASELINE_DIR's .tmp/ convention"
  - "SKIP + totalFail++ if fresh PNG missing — caller must pre-shoot before running script"
metrics:
  duration: "~5 min"
  completed: "2026-06-04"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 4
---

# Phase 130 Plan 01: Light Pixel-Identity Gate + verify.opsui Alias Summary

**One-liner:** Wave 0 light pixel-diff gate (pixelmatch/pngjs, 20 PNGs, exit-code contract) and `mix verify.opsui` alias fixing D-13 doc-drift.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add pixelmatch+pngjs devDeps and write light-pixel-diff.mjs | d89e990 | package.json, package-lock.json, e2e/light-pixel-diff.mjs |
| 2 | Add verify.opsui alias to scrypath_ops/mix.exs (D-13) | 5c13930 | scrypath_ops/mix.exs |

## What Was Built

### light-pixel-diff.mjs (new)

Disposable Phase 130 DARKTOKEN-01-c gate. Reads the 20 light-only baseline PNGs from `.tmp/admin-screenshots/` (filtered by `--light--` + `.png`), reads the corresponding fresh PNGs from `FRESH_DIR`, diffs each pair with `pixelmatch` at `threshold: 0`, writes diff PNGs to `DIFF_DIR` for any failing pair, and exits:
- `0` — all 20 pairs have 0 diff pixels (PASS)
- `1` — any pair has > 0 diff pixels (FAIL)
- `2` — script error (empty baseline dir, unexpected exception)

Structurally mirrors `contrast-checker.mjs`: ESM imports, `__dirname` from `fileURLToPath`, `path.resolve` path setup, `async function main()` called via `.catch(err => { process.exit(2); })`.

### package.json + npm install

Added `"pixelmatch": "^5.3.0"` and `"pngjs": "^7.0.0"` to `devDependencies`. `npm install` ran; package-lock.json updated with 3 new packages (0 vulnerabilities).

### mix.exs verify.opsui alias

Added `"verify.opsui": ["test", "opsui.test_a11y"]` after the `"opsui.test_a11y"` alias. Fixes D-13 doc-drift: `mix verify.opsui` is now a literal runnable target executing `mix test` then `mix opsui.test_a11y`.

## Verification Results

| Check | Result |
|-------|--------|
| `node --check e2e/light-pixel-diff.mjs` | OK |
| `grep '"pixelmatch"' package.json` | `"pixelmatch": "^5.3.0"` present |
| `grep '"pngjs"' package.json` | `"pngjs": "^7.0.0"` present |
| `grep '"verify.opsui"' mix.exs` | 1 match |
| `mix compile` (scrypath_ops) | 0 warnings |
| `mix test` (scrypath_ops) | 129 tests, 0 failures |
| deps installed in node_modules | pixelmatch + pngjs confirmed via node require |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns beyond `.tmp/` (gitignored), or schema changes.

## Self-Check: PASSED

- `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` — FOUND
- `examples/scrypath_ecommerce/package.json` — FOUND (pixelmatch + pngjs present)
- `scrypath_ops/mix.exs` — FOUND (verify.opsui alias present, 1 match)
- Commit d89e990 — FOUND
- Commit 5c13930 — FOUND
