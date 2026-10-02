---
status: resolved
trigger: Recheck the required ecommerce-mounted failure on public main at 40c9978c975dbfb42db75511f44ff0369c8d7d88 (run 36419998362). First verify whether a newer exact-SHA pass supersedes it; if not, identify the cause and restore the required gate or prove it is infrastructure-only. Compare passing run 36390328588; do not assume a source regression from the path-only rewrite.
created: 2026-09-28
updated: 2026-09-28
---

# Debug Session: ecommerce-mounted readiness

## Symptoms

- **Expected:** The required mounted-commerce CI job completes its focused browser checks successfully on public `main`.
- **Actual:** Run `36419998362` failed `ecommerce-mounted (required)` at the exact requested SHA. Its browser container exited with code 70 before starting any browser test.
- **Error:** `Mounted web service did not remain ready for three consecutive checks.` The verifier then reported `Docker verifier failed (scope=focused, exit=70)`.
- **Timeline:** The failure was recorded on 2026-09-28 after the history-only rewrite. Earlier run `36390328588` passed the same mounted check at `ff542202a5864744644f5bbe3011934a9a994a60`.
- **Reproduction:** Run `make verify-mounted` against the exact public-main tree and inspect the service and health-check logs. First determine whether a newer successful run exists for the requested SHA.

## Current Focus

- **bug_class:** `heisenbug-mandelbug`
- **Hypothesis:** Confirmed. The Compose-wide `PHX_SERVER=true` permits the pre-final `mix e2e.prepare` and `mix scrypath.demo.seed` processes to start temporary endpoints through `Mix.Task.run("app.start")`. A transient endpoint satisfies the one-shot Compose healthcheck, browser starts, that process exits, and the fixed 60-second browser probe can expire before the entrypoint's final persistent `mix phx.server` reaches readiness.
- **Test:** Completed. The supported exact-SHA closeout passed, then a clean export of that SHA with only the two command-scoped environment changes passed the focused Docker verifier.
- **Expecting:** Met. The hosted required gate is green and the regression proof keeps Compose from starting the browser until the final persistent endpoint is healthy.
- **Next action:** Carry the two-file fix forward through the normal PR-first change path. Do not dispatch more CI solely for this resolved session.

```yaml
reasoning_checkpoint:
  hypothesis: "The global PHX_SERVER=true lets two finite preparation Mix processes publish a temporary endpoint; Compose health becomes healthy before the final server starts, so the browser consumes its 60-second probe budget after the temporary endpoint exits."
  confirming_evidence:
    - "The failing attempt-1 browser ran although its web log stopped before the final-server entrypoint message."
    - "compose.yaml exports PHX_SERVER=true; config/test.exs maps it to Endpoint server: true; both e2e.prepare_search and scrypath.demo.seed call Mix.Task.run(\"app.start\")."
    - "The browser begins only after Compose health and fails after a fixed 60-attempt readiness loop; the source-identical exact SHA passes in a fresh isolated local archive."
  falsification_test: "With PHX_SERVER=false scoped to both preparation commands, Compose must not start browser until the final mix phx.server endpoint is available; an early browser start before the final-server message would disprove this mechanism."
  fix_rationale: "Scope PHX_SERVER=false to both finite app-starting preparation commands, while the final mix phx.server retains the container's true value. This prevents the healthcheck from observing a temporary process without altering the final server or probe contract."
  blind_spots: "The existing failed-run artifacts lack per-probe timestamps and health-status history, so the exact point each temporary endpoint stopped responding is not recorded."
  candidate_causes:
    - "config/code: PHX_SERVER is inherited by e2e.prepare and scrypath.demo.seed even though they only prepare data."
    - "environment: cold hosted initialization leaves a longer-than-60-second interval between a temporary endpoint exiting and the final server becoming ready."
  and_gate: "yes — the failure needs both an early temporary endpoint to satisfy Compose health and enough subsequent cold work for the browser's fixed probe budget to expire."
```

## Evidence

- timestamp: 2026-09-28 - No project skill directory or debug knowledge-base entry is present, so there is no project-specific rule or prior resolution to test first.
- timestamp: 2026-09-28 - `examples/scrypath_ecommerce/docker-playwright.sh` exits 70 only when 60 attempts cannot obtain three consecutive successful `curl --fail --max-time 5 http://web:4002/` checks. It runs after Compose reports `web` healthy, and it exits before invoking Playwright. The failure is therefore a post-health endpoint-availability failure, not a browser assertion.
- timestamp: 2026-09-28 - GitHub's exact-SHA workflow inventory lists only CI run `36419998362` for `40c9978c975dbfb42db75511f44ff0369c8d7d88`; its second attempt concluded `failure`. There is no newer exact-SHA CI pass that supersedes the recorded failure. The job failed only at `mix verify.ecommerce_mounted` and uploaded two non-expired diagnostic archives, one from each failed attempt.
- timestamp: 2026-09-28 - The failed hosted job log contains the browser's readiness exit and Compose cleanup, but no `web-1` application output because Compose attached only `browser`. The uploaded `compose.log` is therefore required to distinguish a crashed application from failed in-network probes.
- timestamp: 2026-09-28 - GitHub tree APIs returned 357 relevant blobs at both SHAs. The authenticated, path-and-blob-SHA comparison of `mix.exs`, `mix.lock`, `config/`, `lib/`, `scrypath_ops/`, `examples/scrypath_ecommerce/`, and `.github/workflows/` was empty. The passing and failing commits therefore contain identical mounted-verifier, application, dependency-lock, configuration, and CI source; a history-only rewrite did not introduce this failure.
- timestamp: 2026-09-28 - Both failed CI-attempt artifacts were downloaded and each contains only `compose.log`. The logs show the web container completed database preparation, both asset builds, deterministic seed setup, and reached `Starting the persistent E2E server...` before the browser declared readiness failure. No failure stack trace was visible in the unfiltered archive output, so lifecycle-specific extraction remains necessary.
- timestamp: 2026-09-28 - The identical source tree still resolves several mutable runtime inputs: `postgres:16-alpine`, `getmeili/meilisearch:v1.15`, `mcr.microsoft.com/playwright:v1.60.0-noble`, and OS packages from `apt-get`. These are candidate environment causes, not evidence of a change.
- timestamp: 2026-09-28 - The two failure-attempt archives diverge in startup progress despite the same SHA and resolved Postgres 16.15/Meilisearch 1.15.2 versions. Attempt 1 was stopped after `mix e2e.prepare` had prepared search indexes, before deterministic seed output or the final-server launch. Attempt 2 completed seed setup and printed `Starting the persistent E2E server...`, but did not emit an endpoint-ready line before the browser timed out. Neither archive contains an application crash or fatal stack trace.
- timestamp: 2026-09-28 - A separate isolated archive at exact SHA `40c9978c975dbfb42db75511f44ff0369c8d7d88` completed `make verify-mounted`: three consecutive readiness probes and all four focused Playwright checks passed; cleanup completed. This directly refutes a deterministic source or locked-dependency failure.
- timestamp: 2026-09-28 - The early-endpoint candidate has a direct static chain but is not confirmed: the Compose `web` environment exports `PHX_SERVER=true`; `config/test.exs` maps that variable to `Endpoint, server: true`; and the pre-final `e2e.prepare_search` task calls `Mix.Task.run("app.start")`. The first failed artifact ended before the entrypoint's final `mix phx.server` command, although its browser had already run. Whether Phoenix binds the endpoint during that task must be established before treating this as a root cause.
- timestamp: 2026-09-28 - Bug class: `heisenbug-mandelbug`. The same source and locked dependencies produced a hosted failure twice, a prior hosted pass, and a fresh isolated local pass. No SBFL run applies because this integration failure has no passing/failing per-test coverage spectrum and the symptom is non-deterministic.
- timestamp: 2026-09-28 - Root-cause mechanism confirmed. `e2e.prepare_search` and `scrypath.demo.seed` both execute `Mix.Task.run("app.start")`; the globally inherited `PHX_SERVER=true` makes the test endpoint eligible to listen in each finite prep process. The first failed attempt's browser ran while the web log still preceded the final `mix phx.server` entrypoint message, directly demonstrating that Compose health had observed a pre-final process. The isolated exact-source local pass explains why this configuration fault is timing-dependent.
- timestamp: 2026-09-28 - Installed Phoenix endpoint-supervisor source confirms the configuration mechanism: it derives `server?` from endpoint configuration and, when true, includes `server_children`, which invoke the adapter's listening-server child specs. Phoenix endpoint documentation likewise defines `server: true` as starting the web server in the endpoint supervision tree. Therefore each pre-final `app.start` process can bind the healthcheck port while `PHX_SERVER=true` is inherited.
- timestamp: 2026-09-28 - Concrete source chain: `docker-e2e-entrypoint.sh:18` runs the first finite process, `mix e2e.prepare`; `e2e.prepare_search.ex:24` calls `Mix.Task.run("app.start")`. After asset work, `docker-e2e-entrypoint.sh:34` runs the second finite process, `mix scrypath.demo.seed`; `scrypath.demo.seed.ex:117` calls `Mix.Task.run("app.start")` (and invokes `e2e.prepare_search` again at line 118). The only intended persistent launch is `docker-e2e-entrypoint.sh:37`.
- timestamp: 2026-09-28 - The readiness contract makes that sequence unsafe: `compose.yaml:35` exports `PHX_SERVER=true`; `config/test.exs:25-30` maps it to a public bind and `Endpoint, server: true`; `compose.yaml:52-60` marks `web` healthy after one successful `curl` on port 4002; `compose.e2e.yaml:27-29` starts `browser` on that health status; and `docker-playwright.sh:17-31` permits only 60 attempts before exit 70.
- timestamp: 2026-09-28 - The failure artifact's `compose.log` begins with the browser's readiness probe and exit 70, while its `web` stream reaches `Preparing the deterministic database and search indexes...`, the prepared-index messages, asset-building messages, and `Building mounted ScrypathOps assets...` but contains no `Starting the persistent E2E server...` entry. This is the observed early-health-before-final-server ordering that the source chain predicts.
- timestamp: 2026-09-28 - Supported exact-SHA closeout run `36439562644` passed all five required jobs, coverage, and the closeout attestation at `40c9978c975dbfb42db75511f44ff0369c8d7d88`. `deep-quality` remained advisory and failed only on the already-known Mint advisories.
- timestamp: 2026-09-28 - Applied the minimal complete source fix in `docker-e2e-entrypoint.sh`: both finite app-starting setup commands now run with `PHX_SERVER=false`; the final `mix phx.server` command continues to inherit Compose's `PHX_SERVER=true`. Added a Phase 147 contract assertion for that ownership boundary.
- timestamp: 2026-09-28 - A clean export of the exact public SHA with only the two-line entrypoint fix completed `make verify-mounted`: Compose waited for `web` before starting `browser`, three readiness checks passed, all four focused Playwright tests passed, and cleanup removed the stack resources.
- timestamp: 2026-09-28 - Ran `mix test --no-start test/scrypath/phase147_e2e_contract_test.exs` inside the cached project Docker image because the host has no configured Elixir/OTP toolchain; all 3 tests passed with 0 failures. `git diff --check` also passed.
- timestamp: 2026-09-28 - `ci_monitor.cjs test-summary 36419998362` shows required `ecommerce-mounted` failed; required core, package, repository-contracts, and backend jobs succeeded.
- timestamp: 2026-09-28 - `ci_monitor.cjs grep 36419998362` confirms every checked-out job used `40c9978c975dbfb42db75511f44ff0369c8d7d88`; the mounted failure came from readiness stability, before any Playwright test began.
- timestamp: 2026-09-28 - `ci_monitor.cjs test-summary 36390328588` shows the mounted job succeeded; its logs show all four focused Playwright tests passed at `ff542202a5864744644f5bbe3011934a9a994a60`.
- timestamp: 2026-09-28 - `ci_monitor.cjs runs --branch main` only lists `workflow_dispatch` runs; it cannot establish whether a newer scheduled run supersedes the recorded result.

## Eliminated

- hypothesis: The recorded run tested a different commit - eliminated because checkout logs identify the requested exact SHA.
- hypothesis: A Playwright assertion failed in the recorded run - eliminated because the browser verifier exited during its pre-test service readiness check.
- hypothesis: A deterministic application crash or locked-source dependency change prevented the final endpoint from starting - eliminated because both failed artifacts lack a crash/fatal trace, all relevant source/tree blobs are identical to the earlier hosted pass, and an isolated exact-source run passed the full focused verifier.

## Resolution

- **root_cause:** An AND-gated startup-readiness defect: (1) `PHX_SERVER=true` leaks into `mix e2e.prepare` and `mix scrypath.demo.seed`, whose `app.start` calls expose temporary endpoints that satisfy Compose health before the final server starts; and (2) cold hosted initialization can outlast the browser script's fixed 60-second post-health probe budget after a temporary endpoint exits.
- **fix:** Applied: `examples/scrypath_ecommerce/docker-e2e-entrypoint.sh` scopes `PHX_SERVER=false` to `mix e2e.prepare` and `mix scrypath.demo.seed`; the final persistent `mix phx.server` retains `PHX_SERVER=true`.
- **verification:** Newer exact-SHA hosted closeout `36439562644` passed all required jobs, coverage, and attestation on the unchanged public SHA. A clean export of that SHA plus the fix passed `make verify-mounted` with all four focused Playwright tests; Docker cleanup completed. The focused ExUnit contract passed in the cached project Docker image (3 tests, 0 failures), and `git diff --check` passed. The hosted closeout validates the public SHA, not the uncommitted fix.
- **files_changed:** ["examples/scrypath_ecommerce/docker-e2e-entrypoint.sh", "test/scrypath/phase147_e2e_contract_test.exs"]
- **oracle_type:** specified
- **targeted_regression_check:** `test/scrypath/phase147_e2e_contract_test.exs` asserts `PHX_SERVER=false` scopes both preparation commands and the final server command remains the sole persistent endpoint launch. The ExUnit contract and acceptance check passed: `make verify-mounted` from a clean exact-SHA archive with only the fix, using the existing three-consecutive-probe assertion as the oracle.

## Handoff

- The debug is resolved. Keep the two-file readiness fix in the working tree until it is carried through a reviewed PR or deliberately deferred; it has not been committed or pushed.
- Do not dispatch CI just to repeat this resolved investigation. The exact-SHA public gate is green at run `36439562644`; the flaky readiness mechanism and local regression checks are documented above.
- The workspace branch is 137 commits ahead of public `main`; do not push or ship that branch as-is. The next GSD lifecycle step after this debug is `$gsd-new-milestone`; keep the local fix separate from its scope and preserve it for a clean PR path. v1.40 Phase 167 is the last completed phase; there is no active phase.
