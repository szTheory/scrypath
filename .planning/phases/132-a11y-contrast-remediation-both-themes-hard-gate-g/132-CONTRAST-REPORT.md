# Phase 132 Contrast Report

Started: 2026-06-04T21:08:18Z

## Static Token Gate

Command order proof:

```console
$ cd scrypath_ops && mix assets.build
≈ tailwindcss v4.1.12

/*! 🌼 daisyUI 5.0.35 */
Done in 91ms

  ../priv/static/assets/js/app.js  299.8kb

⚡ Done in 13ms
```

The asset build exited 0 before any static or browser contrast proof, so `scrypath_ops/priv/static/assets/css/app.css` reflects `scrypath_ops/assets/css/app.css`.

Fast token checker:

```console
$ cd examples/scrypath_ecommerce && CONTRAST_REPORT_DIR=test-results/contrast/phase132-token node contrast-checker.mjs

Contrast check: PASS
  AA failures:  0
  AAA advisory: 17
  Report: test-results/contrast/phase132-token/contrast-report.token.json
```

## Ops UI Regression Gate

```console
$ cd scrypath_ops && mix verify.opsui
Nav contract OK: operator-ia.md matches Nav.primary/0
Running ExUnit with seed: 723219, max_cases: 36
...
Finished in 3.0 seconds (1.9s async, 1.1s sync)
2 doctests, 129 tests, 0 failures
```

The command exited 0. The run emitted transient Postgrex `too_many_connections` connection logs during the test run, matching the previously documented local environment noise, but the suite completed green.

## Browser AA Matrix

Pending Task 2.

## AAA Body Advisory

Static token advisory status is report-only:

- Token checker `AAA advisory: 17`
- AAA findings did not affect the static gate exit status.
- Phase 132 keeps AA as the hard gate and does not change thresholds or typography to chase AAA.

Browser AAA body advisory evidence is pending Task 2.

## Light Baseline Recapture

Pending Task 2.

## Scope Guard

This proof plan did not modify package manifests or ScrypathOps Elixir source files:

- `scrypath_ops/lib/**` unchanged
- `examples/scrypath_ecommerce/package.json` unchanged
- `examples/scrypath_ecommerce/package-lock.json` unchanged
- root `package.json` unchanged
- root `package-lock.json` unchanged

Generated evidence and build outputs are evidence artifacts only unless already tracked. Do not stage or commit `test-results/`, `.tmp/`, or untracked `scrypath_ops/priv/static/**` outputs for this plan.
