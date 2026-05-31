# Phase 102 Validation Plan

## Overview
This document outlines the validation steps required to ensure Phase 102 (Admin UI Router Engine Refactor) meets its objectives and success criteria.

## Phase Success Criteria
1. `scrypath_ops` no longer attempts to start Web/DB dependencies in default/production environments.
2. Host applications can inject `scrypath_ops_routes("/path", repo: MyApp.Repo)`.
3. `scrypath_ops` CSS does not bleed into the host application.
4. Developers can still use `mix phx.server` inside `scrypath_ops` for local development.

## Validation Steps

### 1. Application Dependency Isolation
**Objective:** Ensure `ScrypathOpsWeb.Endpoint` and `ScrypathOps.Repo` only start when explicitly configured.
**Method:**
- Run `mix test` inside `scrypath_ops`.
- Start a generic Elixir session (`iex -S mix`) without `standalone: true` and verify `ScrypathOps.Repo` is NOT running.
- Start the dev server (`mix phx.server`) and verify `ScrypathOps.Repo` IS running.

### 2. Router Macro and Configuration Injection
**Objective:** Ensure the macro `scrypath_ops_routes/2` mounts correctly and accepts validated configuration.
**Method:**
- Check compilation (`mix compile`) without errors.
- Ensure the `DevRouter` works by browsing to `http://localhost:4000/ops`.
- Verify `NimbleOptions` raises an error if an invalid `repo` is passed to the macro.

### 3. Asset Delivery and CSS Isolation
**Objective:** Ensure assets are delivered dynamically via `AssetPlug` and CSS doesn't bleed.
**Method:**
- Hit `http://localhost:4000/ops/assets/app.css` and verify it returns a 200 OK with correct CSS headers.
- Inspect the generated CSS and verify styles are prefixed (e.g., `sop-` class names or wrapped in a specific selector) to prevent bleeding into a host application's styles.

### 4. Regression Testing
**Objective:** Ensure existing tests continue to pass.
**Method:**
- Run `mix test` across the `scrypath_ops` project. All tests should pass.
