---
milestone: v1.2
phase: 15
topic: live_operator_verification
status: validated
validated: 2026-04-17
---

# v1.2 Phase 15 — Live operator verification — Validation

## Scope

Evidence for the **live Meilisearch** operator integration exercised by:

- `test/scrypath/live_operator_verification_test.exs` (`@moduletag :integration`)

This module is invoked by **`mix verify.phase13`** when `--skip-integration` is **not** passed and `SCRYPATH_MEILISEARCH_URL` is set (see `lib/mix/tasks/verify.phase13.ex`).

## Evidence model

| Tier | Role |
|------|------|
| **Canonical** | GitHub Actions job **`phase13-verification`** — starts `getmeili/meilisearch:v1.15`, sets `SCRYPATH_INTEGRATION=1` and `SCRYPATH_MEILISEARCH_URL`, runs `mix verify.phase13` (full path including live tests). |
| **Local / debugging** | Reproduce CI with Docker + the same env vars (below). Optional for contributors; **not** a substitute for a green CI run on `main`. |

## CI receipt (canonical)

- **Workflow:** `.github/workflows/ci.yml`  
- **Job:** `phase13-verification`  
- **Service image:** `getmeili/meilisearch:v1.15`  
- **Run (success on `main`):** https://github.com/szTheory/scrypath/actions/runs/24581329311  
- **Commit:** `2c303eb87e4ba30981bd2c129e20252954cdb7e0`

**Excerpts from CI log (same run):**

```text
==> Running focused Phase 13 operator tests
Finished in 7.3 seconds (7.3s async, 0.00s sync)
68 tests, 0 failures
==> Running live Meilisearch operator verification
Finished in 0.7 seconds (0.00s async, 0.7s sync)
2 tests, 0 failures
```

Exit code for the step: `0`.

## Local reproduction (optional)

Match CI:

```bash
docker run -d --name scrypath-meili-verify -p 7700:7700 \
  -e MEILI_NO_ANALYTICS=true getmeili/meilisearch:v1.15
# wait for /health, then:
SCRYPATH_INTEGRATION=1 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.phase13
docker rm -f scrypath-meili-verify
```

## Drift protocol

If `live_operator_verification_test.exs` or the CI job changes, update excerpts and cite a **new** successful `phase13-verification` run on `main`. Do not mark live behavior **N/A** while claiming operator live verification.
