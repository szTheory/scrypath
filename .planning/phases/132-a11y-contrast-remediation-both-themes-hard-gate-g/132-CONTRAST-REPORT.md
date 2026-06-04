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

Environment preparation:

```console
$ cd examples/scrypath_ecommerce && MIX_ENV=test mix e2e.prepare
Prepared E2E search index settings for ecommerce__product.
Prepared E2E search index settings for ecommerce__variant.
```

The first prepare attempt failed because local Meilisearch was not running (`:econnrefused`). The existing ecommerce `make infra` target started Meilisearch on `127.0.0.1:7700`, `/health` returned `{"status":"available"}`, and the prepare command above then exited 0. The run emitted transient Postgrex `too_many_connections` logs but completed successfully.

Phoenix server:

```console
$ cd examples/scrypath_ecommerce && MIX_ENV=test PHX_SERVER=true SCRYPATH_E2E_NO_SANDBOX=1 mix phx.server
$ curl http://127.0.0.1:4002/
SERVING
```

Browser contrast matrix:

```console
$ cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 CONTRAST_REPORT_DIR=test-results/contrast/phase132 npm run test:e2e:admin-contrast

> scrypath-ecommerce-e2e@0.1.0 test:e2e:admin-contrast
> playwright test e2e/admin_contrast_matrix.spec.ts

Running 3 tests using 1 worker
  ✓  1 [chromium] › e2e/admin_contrast_matrix.spec.ts:404:7 › admin contrast matrix — incident (26.9s)
  ✓  2 [chromium] › e2e/admin_contrast_matrix.spec.ts:404:7 › admin contrast matrix — all_green (23.7s)
  ✓  3 [chromium] › e2e/admin_contrast_matrix.spec.ts:404:7 › admin contrast matrix — empty (21.7s)

  3 passed (1.2m)
```

Generated browser reports:

| Scenario | Report | AA failures | AAA advisory |
| --- | --- | ---: | ---: |
| incident | `test-results/contrast/phase132/contrast-report.axe.incident.json` | 0 | 0 |
| all_green | `test-results/contrast/phase132/contrast-report.axe.all_green.json` | 0 | 0 |
| empty | `test-results/contrast/phase132/contrast-report.axe.empty.json` | 0 | 12 |

Theme matrix AA status:

AA failures: 0 for light, dark, and system-dark.

| Theme mode | AA failures | Notes |
| --- | ---: | --- |
| light | 0 | Explicit light matrix covered by the passing Playwright run. |
| dark | 0 | Explicit dark matrix covered by the passing Playwright run. |
| system-dark | 0 | System-dark matrix covered by the passing Playwright run and its runtime invariants. |

Suppression guard:

```console
$ cd examples/scrypath_ecommerce && rg "exclude\(|disableRules|color-contrast.*disabled" e2e/admin_contrast_matrix.spec.ts
# no matches
```

The browser contrast matrix exited 0 without axe exclusions, disabled rules, or color-contrast suppression.

## AAA Body Advisory

Static token advisory status is report-only:

- Token checker `AAA advisory: 17`
- AAA findings did not affect the static gate exit status.
- Phase 132 keeps AA as the hard gate and does not change thresholds or typography to chase AAA.

Browser AAA body advisory status is also report-only:

- `incident`: `AAA advisory: 0`
- `all_green`: `AAA advisory: 0`
- `empty`: `AAA advisory: 12`
- Empty-scenario advisory entries are all body/long-form `color-contrast-enhanced` findings at `6.76` against target `7`, split across explicit dark and system-dark.
- AAA advisory findings did not affect the Playwright exit status.

## Light Baseline Recapture

Fresh screenshot matrix:

```console
$ cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 ADMIN_SCREENSHOT_DIR=.tmp/pixel-diff-fresh npm run test:e2e:admin-matrix

> scrypath-ecommerce-e2e@0.1.0 test:e2e:admin-matrix
> playwright test e2e/admin_screenshot_matrix.spec.ts

Running 3 tests using 1 worker
  ✓  1 [chromium] › e2e/admin_screenshot_matrix.spec.ts:80:7 › admin screenshot matrix — incident (7.3s)
  ✓  2 [chromium] › e2e/admin_screenshot_matrix.spec.ts:80:7 › admin screenshot matrix — all_green (4.4s)
  ✓  3 [chromium] › e2e/admin_screenshot_matrix.spec.ts:80:7 › admin screenshot matrix — empty (6.4s)

  3 passed (18.8s)
```

Baseline recapture:

```console
$ cd examples/scrypath_ecommerce && mkdir -p .tmp/admin-screenshots && find .tmp/pixel-diff-fresh -maxdepth 1 -type f -name '*--light--*.png' -exec cp {} .tmp/admin-screenshots/ \;
$ cd examples/scrypath_ecommerce && find .tmp/admin-screenshots -maxdepth 1 -type f -name '*--light--*.png' | wc -l
      20
```

Light pixel diff after recapture:

```console
$ cd examples/scrypath_ecommerce && PIXEL_DIFF_FRESH_DIR=.tmp/pixel-diff-fresh node e2e/light-pixel-diff.mjs
Baseline: /Users/jon/projects/scrypath/examples/scrypath_ecommerce/.tmp/admin-screenshots
Fresh:    .tmp/pixel-diff-fresh
Diff out: /Users/jon/projects/scrypath/examples/scrypath_ecommerce/.tmp/pixel-diff-out
Light PNGs to diff: 20

OK:   00-control-room--light--desktop--incident.png
OK:   00-control-room--light--mobile--incident.png
OK:   01-posture--light--desktop--incident.png
OK:   01-posture--light--mobile--incident.png
OK:   02-failed-sync--light--desktop--populated.png
OK:   02-failed-sync--light--mobile--populated.png
OK:   03-sync-drift--light--desktop--drift.png
OK:   03-sync-drift--light--mobile--drift.png
OK:   04-control-room--light--desktop--all-green.png
OK:   04-control-room--light--mobile--all-green.png
OK:   05-posture--light--desktop--all-green.png
OK:   05-posture--light--mobile--all-green.png
OK:   06-search--light--desktop--results.png
OK:   06-search--light--mobile--results.png
OK:   07-failed-sync--light--desktop--empty.png
OK:   07-failed-sync--light--mobile--empty.png
OK:   08-search--light--desktop--zero-results.png
OK:   08-search--light--mobile--zero-results.png
OK:   09-playbooks--light--desktop--empty-workspace.png
OK:   09-playbooks--light--mobile--empty-workspace.png

Light pixel-diff: PASS
  Failed pairs: 0 / 20
```

The intentional light-token visual change is handled by recapturing the light baseline, not by forcing pixel identity against Phase 131.

## Scope Guard

This proof plan did not modify package manifests or ScrypathOps Elixir source files:

- `scrypath_ops/lib/**` unchanged
- `examples/scrypath_ecommerce/package.json` unchanged
- `examples/scrypath_ecommerce/package-lock.json` unchanged
- root `package.json` unchanged
- root `package-lock.json` unchanged

Generated evidence and build outputs are evidence artifacts only unless already tracked. Do not stage or commit `test-results/`, `.tmp/`, or untracked `scrypath_ops/priv/static/**` outputs for this plan.

Task 2 evidence artifacts kept out of git:

- `examples/scrypath_ecommerce/test-results/contrast/phase132/**`
- `examples/scrypath_ecommerce/.tmp/pixel-diff-fresh/**`
- `examples/scrypath_ecommerce/.tmp/admin-screenshots/**`
- untracked `scrypath_ops/priv/static/**`
