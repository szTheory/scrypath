# Phase 136 Dual Verify Report

**Requirement:** DUALVERIFY-01
**Plan:** 136-01
**Evidence started:** 2026-06-28T22:39:59Z
**Last updated:** 2026-06-28T22:45:58Z

DUALVERIFY-01 is being verified with source-backed Mix, ScrypathOps, browser,
contrast, motion, shell, mounted smoke, and screenshot evidence before Phase 136
closeout prose claims success.

## Source-Backed Lane

| Field | Value |
| --- | --- |
| Source commit | `0494d92385c242da2fbb2c0bb0abd8775456639c` |
| Starting git status | Dirty working tree with pre-existing UI/demo changes; see `Starting Dirty Tree Transcript` below. |
| PLAYWRIGHT_BASE_URL | `http://127.0.0.1:4012` |
| Boot method | Host Phoenix dev server from current checkout: `MIX_ENV=dev PHX_SERVER=true PORT=4012 PGHOST=localhost PGPORT=5432 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix phx.server` |
| Port | `4012` |
| Seed method | `MIX_ENV=dev PORT=4012 PGHOST=localhost PGPORT=5432 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix do ecto.create, ecto.migrate, scrypath.demo.seed, phx.server`; seed completed before the first server process was aborted for failing to expose HTTP. |
| Asset build command | `cd scrypath_ops && mix assets.build` |
| Stale-server safeguard | Existing `http://127.0.0.1:4002` container was not used for proof. A separate host process from this checkout serves `http://127.0.0.1:4012`, after rebuilding ScrypathOps assets and seeding the demo. |

## Task 1 Automated Gate Results

| Gate | Command | Result |
| --- | --- | --- |
| ScrypathOps asset build | `cd scrypath_ops && mix assets.build` | PASS: compiled ScrypathOps app, Tailwind 4.1.12, daisyUI 5.0.35, esbuild output `../priv/static/assets/js/app.js 307.3kb`. |
| Ecommerce Meilisearch lane | `cd examples/scrypath_ecommerce && make infra` | PASS: Meilisearch exposed at `http://127.0.0.1:7700`; `/health` returned `{"status":"available"}`. |
| Source-backed ecommerce server | `MIX_ENV=dev PHX_SERVER=true PORT=4012 ... mix phx.server` | PASS: `curl http://127.0.0.1:4012/` returned the Scrypath Ecommerce demo page. |
| Root ops UI gate | `mix verify.opsui` | PASS: 2 doctests, 147 tests, 0 failures. |
| App ops UI gate | `cd scrypath_ops && mix verify.opsui` | PASS: 2 doctests, 147 tests, 0 failures. |
| App precommit gate | `cd scrypath_ops && mix precommit` | PASS: 2 doctests, 147 tests, 0 failures. |

## Task 1 Notes

- No package install or upgrade was performed.
- No lockfile changes were introduced.
- `mix precommit` produced formatter-only diffs in two files that were clean at task start: `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` and `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`. Those command side effects were restored by explicit path before any commit.
- Generated ScrypathOps static outputs remain untracked/generated evidence and are not staged.

## Browser Gate Results

Pending Task 2.

## Screenshot Matrix

Pending Task 3.

## Artifact Hygiene

Generated artifacts stayed out of git staging as of Task 1. Phase 136 will commit only:

- `.planning/phases/136-milestone-verification-uat-s-g/136-DUALVERIFY-REPORT.md`
- `.planning/phases/136-milestone-verification-uat-s-g/136-ARTIFACT-MANIFEST.json`

## Starting Dirty Tree Transcript

The working tree was dirty before Task 1. Phase 136 commits must not stage these unrelated
source/demo changes unless a D-18 must-fix defect is identified and documented.

```text
 M .planning/STATE.md
 M examples/scrypath_ecommerce/.env.example
 M examples/scrypath_ecommerce/Makefile
 M examples/scrypath_ecommerce/README.md
 M examples/scrypath_ecommerce/assets/js/app.js
 M examples/scrypath_ecommerce/compose.dev.yaml
 M examples/scrypath_ecommerce/compose.yaml
 M examples/scrypath_ecommerce/docker-entrypoint.sh
 M examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts
 M examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts
 M examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts
 M examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts
 M examples/scrypath_ecommerce/e2e/operator.spec.ts
 M examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs
 M scrypath_ops/assets/css/app.css
 M scrypath_ops/assets/js/app.js
 M scrypath_ops/docs/operator-ia.md
 M scrypath_ops/lib/scrypath_ops/posture.ex
 M scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
 M scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
 M scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
 M scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
 M scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex
 M scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
 M scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
 M scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
 M scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
?? .planning/research/.cache/
?? .tmp/
?? docs/local-demo-docker-dx.md
?? examples/scrypath_ecommerce/.tmp/
?? examples/scrypath_ecommerce/compose.host-ports.yaml
?? examples/scrypath_ecommerce/e2e/p124_after.spec.ts
?? scrypath_ops/priv/static/assets/
?? scrypath_ops/priv/static/favicon-91f37b602a111216f1eef3aa337ad763.ico
?? scrypath_ops/priv/static/images/logo-353b3ad0b84cf978826c53e7a3ea537f.svg
?? scrypath_ops/priv/static/images/logo-353b3ad0b84cf978826c53e7a3ea537f.svg.gz
?? scrypath_ops/priv/static/images/logo.svg.gz
?? scrypath_ops/priv/static/robots-9e2c81b0855bbff2baa8371bc4a78186.txt
?? scrypath_ops/priv/static/robots-9e2c81b0855bbff2baa8371bc4a78186.txt.gz
?? scrypath_ops/priv/static/robots.txt.gz
?? test_e2e_plan.md
?? update_plans.py
?? update_plans2.py
```
