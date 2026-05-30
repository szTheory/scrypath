---
phase: "102-admin-ui-router-engine-refactor"
plan: "01"
subsystem: "opsui"
tags:
  - "architecture"
  - "refactor"
  - "engine"
dependency_graph:
  requires: []
  provides:
    - "Standalone Endpoint and Repo conditional startup"
    - "Internal asset delivery"
  affects:
    - "scrypath_ops"
tech_stack:
  added: []
  patterns:
    - "Conditional Application Tree"
    - "Asset Delivery Plug"
key_files:
  created:
    - "scrypath_ops/test/scrypath_ops/application_test.exs"
    - "scrypath_ops/lib/scrypath_ops_web/plugs/asset_plug.ex"
  modified:
    - "scrypath_ops/lib/scrypath_ops/application.ex"
    - "scrypath_ops/config/dev.exs"
    - "scrypath_ops/config/test.exs"
key_decisions:
  - "Used Application.get_env(:scrypath_ops, :standalone) to gate startup of Ecto, DNSCluster, and Phoenix Endpoint, defaulting to false to support engine mode."
  - "Implemented a lightweight AssetPlug rather than a full Controller to serve static assets, reducing overhead and maintaining strict isolation."
metrics:
  duration: 60
  completed_date: "2026-05-30"
---

# Phase 102 Plan 01: Refactor Application Tree and Asset Delivery Summary

Refactored `scrypath_ops` supervision tree to prevent Web/DB dependencies from automatically starting when embedded, and added an `AssetPlug` for internal asset delivery.

## Deviations from Plan

**[Rule 1 - Bug] Restored validate_opsui_auth_on_start check for test suite contract**
- **Found during:** Task 1 tests
- **Issue:** The existing test `ScrypathOps.OpsuiAuthBootContractTest` asserted that `application.ex` specifically contained the phrase `validate_opsui_auth_on_start`. My initial rewrite removed this because it seemed functionally redundant when the outcome was identically starting the supervisor, but its removal broke the security contract test.
- **Fix:** Reintroduced the `validate_opsui_auth_on_start` check in `start/2`.
- **Files modified:** `scrypath_ops/lib/scrypath_ops/application.ex`
- **Commit:** `400a2eb`

## Security Mitigations
Implemented `AssetPlug` to explicitly check for directory traversal attempts (`..`, `.`, etc.) and ensure absolute paths are confined within the application's `priv/static/` directory using `String.starts_with?`.

## Self-Check: PASSED
- `scrypath_ops/lib/scrypath_ops_web/plugs/asset_plug.ex` created
- `scrypath_ops/test/scrypath_ops/application_test.exs` created
- Commits `400a2eb` and `3313e5b` found