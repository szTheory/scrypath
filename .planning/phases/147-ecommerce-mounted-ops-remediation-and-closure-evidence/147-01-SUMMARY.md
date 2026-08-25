---
phase: 147-ecommerce-mounted-ops-remediation-and-closure-evidence
plan: "01"
subsystem: ecommerce-dependency-security
tags: [elixir, mix, hex, docker, playwright, github-actions]
provides:
  - graph-local ecommerce dependency remediation candidate
  - zero-touch Docker verification for mounted integration and browser flows
  - always-running focused CI gate and operator documentation
affects: [phase-147-closure-evidence, ecommerce-example-ci]
key-files:
  created:
    - examples/scrypath_ecommerce/compose.e2e.yaml
    - examples/scrypath_ecommerce/Dockerfile.e2e
    - examples/scrypath_ecommerce/scripts/verify-e2e.sh
  modified:
    - examples/scrypath_ecommerce/mix.exs
    - examples/scrypath_ecommerce/mix.lock
    - .github/workflows/ci.yml
key-decisions:
  - "Use a hermetic Compose project with no published ports, version-matched Chromium, health-gated services, owned teardown, and retained failure artifacts."
  - "Keep the focused mounted lane required and run the complete browser/parity/contrast lane through the same verifier on demand."
requirements-completed: []
completed: 2026-08-25
status: complete
---

# Phase 147 Plan 01: Ecommerce Remediation and Zero-Touch Verification Summary

The ecommerce graph is remediated in graph-local candidate `fca4c827a59596e2a66bc2d1ac3516b4c0c5681e`; its diff contains only `examples/scrypath_ecommerce/mix.exs` and `examples/scrypath_ecommerce/mix.lock`. Reusable verifier and CI support landed immediately before it in `e623dad`.

## Dependency result

- Phoenix `1.8.13`, LiveView `1.1.33`, Bandit `1.12.5`, Swoosh `1.26.3`, Postgrex `0.22.4`, Req `0.6.3`, Plug `1.20.3`, Mint `1.9.3`, and hpax `1.0.4` satisfy the approved ranges.
- Locked resolution, warning-clean application compilation, focused controller tests, `mix precommit`, `mix e2e.prepare`, and unsuppressed `mix hex.audit` passed in an isolated physical temporary graph.
- Candidate lock SHA-256: `93fb034fe108de0ac9160512a74031e668cd5c78d107bc43fc31043749ab2fa8`.

## Automated integration and E2E result

- `make verify-mounted`: PASS, 4 focused mounted Playwright tests, first attempt, one worker, zero retries.
- `make verify-e2e`: PASS, 99 browser tests plus 20 light-parity checks; static contrast PASS with zero AA failures and 38 advisory AAA findings.
- Both runs provisioned Postgres, Meilisearch, Phoenix, assets, fixtures, and Chromium without host ports or host-installed browser dependencies, then removed their containers, network, and named playbook volume.
- CI now exposes the focused verifier as the distinct always-running `ecommerce-mounted-smoke` job and retains verifier reports/logs on failure.

## Deviations from Plan

- Added the example formatter configuration required by its existing `mix precommit` alias.
- Bridged the explicit disposable playbook workspace into the mounted dependency at runtime because dependency `runtime.exs` files are not imported by parent applications.
- Relaxed one controller test from an unstable utility-class match to the stable LiveView navigation contract.
- Applied formatter-only changes surfaced by the new formatter configuration.

## Self-Check: PASSED

- Candidate commit scope is exactly the ecommerce manifest and lock.
- Verifier scripts, Compose model, workflow wiring, and cleanup invariants are contract-tested.
- Pre-existing `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, research cache, and milestone-audit work remain uncommitted and untouched by Phase 147 commits.
