---
phase: 173-shared-visual-foundation-and-operational-time
plan: 01
subsystem: ops-ui
tags: [phoenix, liveview, tailwind, playwright, theme]
requires: []
provides:
  - A shared neutral operator shell with explicit system/light/dark preference controls.
  - Storage-safe theme behavior across mounted and standalone LiveSockets.
  - Isolated mounted and standalone production PostureLive fixtures and disposable verification.
affects: [173-02, 173-03, 173-04]
actuals:
  tokens: 20151
  tasks: 3
  commits: 5
tech-stack:
  added: []
  patterns:
    - Test-only fixture providers feed production LiveViews through real Status and State paths.
    - Phase browser scopes use uniquely named disposable Compose projects with fail-closed cleanup.
key-files:
  created:
    - examples/scrypath_ecommerce/compose.phase173.yaml
    - examples/scrypath_ecommerce/scripts/verify-phase173.sh
    - examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts
    - scrypath_ops/test/support/phase173_fixture_source.ex
  modified:
    - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
    - scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/assets/js/app.js
    - examples/scrypath_ecommerce/assets/js/app.js
requirements-completed: [OPUX-09, OPUX-12]
coverage:
  - id: D1
    description: Mounted and standalone operator shells share a neutral theme floor and accessible, preference-backed theme controls.
    requirement: OPUX-09
    verification:
      - kind: unit
        ref: scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs (10 tests)
        status: pass
      - kind: e2e
        ref: bash examples/scrypath_ecommerce/scripts/verify-phase173.sh shell (11/11 tests)
        status: pass
      - kind: automated_ui
        ref: screenshots in /var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-phase173/scrypath_phase173_shell_5befd00e_89591/screenshots
        status: pass
    human_judgment: false
  - id: D2
    description: Theme preference survives reload, LiveView navigation, OS changes, cross-tab updates, and unavailable localStorage in both entrypoints.
    requirement: OPUX-12
    verification:
      - kind: e2e
        ref: phase173_shell.spec.ts (11/11 mounted and standalone cases pass)
        status: pass
    human_judgment: false
duration: not-recorded-after-context-restart
completed: 2026-10-10
status: complete
---

# Phase 173 Plan 01 Summary

**Mounted and standalone Scrypath Ops now share a neutral shell with explicit, storage-resilient theme preferences and source-backed browser fixtures.**

## Performance

- **Duration:** Not recorded after the session restart.
- **Started:** Resumed from a prior session; the original start timestamp was not available.
- **Completed:** 2026-10-10.
- **Tasks:** 3.
- **Files modified:** 24 since the phase execution base.

## Accomplishments

- Added accessible System, Light, and Dark selection with one preference-backed selected state, guarded persistence, cross-tab synchronization, and in-memory fallback when browser storage is denied.
- Added deterministic test-only providers and routes that render the production PostureLive through Scrypath status/state code in both mounted and standalone apps.
- Added a disposable Compose runner and 11 browser cases for theme persistence, responsive shell behavior, artwork failure, long navigation labels, and LiveSocket error/reconnect behavior.
- Reserved the normal 44px touch-target height for wordmark links so the labeled home action remains usable when both decorative logo images fail.

## Task Commits

1. **T1: Introduce the neutral shell and explicit preference state** — `78f366b`, `bd29794`, `5befd00`.
2. **T2: Provide isolated production PostureLive fixtures** — `0340a7b`.
3. **T3: Prove shell and preference behavior in both entrypoints** — `a2e1cf6`.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/scrypath_ops_web/ops_shell_contract_test.exs` — 10 tests, 0 failures.
- `make -C examples/scrypath_ecommerce contrast` — pass; 0 AA failures, 37 AAA advisory findings.
- `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh shell` — 11 browser tests passed across mounted and standalone entrypoints; source-to-render and asset checks passed; disposable containers, volume, and network were removed.
- `bash -n` on the three Phase 173 scripts and `git diff --check` — pass.
- Browser run output recorded HEAD `5befd00` before the implementation slices were committed. The tested working-tree contents were committed unchanged as `0340a7b` and `a2e1cf6`.

## Visual Evidence

Actual before captures came from the clean base commit `b96f4da` in an unpublished Compose network. Actual after captures came from the Phase 173 shell fixture run. The before and after pages use different data fixtures, so these images support shell/layout review and do not claim a data-identical status comparison.

- Before, base app: `before-light-1440.png`, `before-dark-1440.png`, `before-light-390.png`, `before-dark-390.png` in `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-phase173/scrypath_phase173_shell_5befd00e_89591/screenshots/`.
- After, mounted app: `mounted-{light,dark,system}-{390,1440}.png` in the same directory.
- After, standalone app: `standalone-{light,dark,system}-{390,1440}.png` in the same directory.
- Inspected desktop light and mobile dark captures for both entrypoints. Preference labels remain legible and selected states are distinct; mobile content wraps without horizontal overflow. Full-panel warning and success color treatment is intentionally left for Plan 03.
- The base screenshots include the original app's observed degraded two-schema data; the after screenshots use a fixed healthy fixture row. `:4012` was not used.

## Deviations

- Added the 44px wordmark minimum height after the artwork-failure browser case found that the home link collapsed when its decorative SVGs failed. This directly satisfies the planned empty-artwork resilience requirement.
- The deterministic reconnect test explicitly disconnects and reconnects the exposed LiveSocket because Chromium's offline emulator did not reliably emit the Phoenix disconnected class for an already-established WebSocket.
- No dependencies were added.

## Next Plan

Plan 02 adds validated timestamp provenance and snapshot-stable operational time rendering.
