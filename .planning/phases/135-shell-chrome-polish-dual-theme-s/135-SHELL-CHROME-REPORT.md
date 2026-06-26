# Phase 135 Shell Chrome Report

**Requirement:** SHELL-DARK-01
**Plan:** 135-04
**Evidence date:** 2026-06-26

## Automated Gate Results

| Gate | Command | Result |
| --- | --- | --- |
| Ops UI focused/static gate | `cd scrypath_ops && mix verify.opsui` | PASS: 2 doctests, 146 tests, 0 failures |
| Ops UI precommit gate | `cd scrypath_ops && mix precommit` | PASS: 2 doctests, 146 tests, 0 failures |
| Fast contrast gate | `cd examples/scrypath_ecommerce && make contrast` | PASS: AA failures 0, AAA advisory 19 |
| Focused shell browser proof | `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-shell -- --reporter=line` | PASS: 30/30 |
| Browser contrast matrix | `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-contrast -- --reporter=line` | PASS: 3/3 |

The browser gates reused the already-running source ecommerce stack at `http://127.0.0.1:4002`.

## D-03 Light-Change Gate

No D-03 light-theme exception was recorded in `135-02-SUMMARY.md` or `135-03-SUMMARY.md`.
Because no recorded light exception exists, the conditional `node e2e/light-pixel-diff.mjs`
gate was not run for Plan 135-04.

## Generated Artifact Hygiene

Generated proof artifacts stayed out of git staging:

- `.tmp/` remains untracked.
- `examples/scrypath_ecommerce/test-results/` remains ignored/untracked from git status.
- `scrypath_ops/priv/static/**` remains untracked.

`mix precommit` produced formatter-only diffs in three unrelated LiveView files during the gate run.
Those files were clean before the command, were not part of Plan 135-04, and were restored by explicit
path after inspection so the evidence commit stays scoped to this report.
