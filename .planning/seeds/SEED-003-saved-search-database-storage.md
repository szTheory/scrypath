---
slug: saved-search-database-storage
title: Store ScrypathOps saved searches in a database table
status: planted
created: 2026-10-22
updated: 2026-10-22
---

# Seed: Store ScrypathOps saved searches in a database table

## Trigger

Surface this when planning the next ScrypathOps milestone, when an adopter reports that saving searches fails in a release, container or multi-node deploy (read-only, ephemeral or per-node `priv` folders), or when saved searches need per-user or per-tenant scoping.

## Why it exists

Saved searches are currently JSON files in the folder named by `config :scrypath_ops, playbook_workspace_dir:`. If it is unset, the page falls back to read-only examples. The maintainer's position (2026-10-22): users shouldn't have to care where saved searches are stored. The 2026-10-22 UI batch therefore removes the storage folder from the UI entirely (CONTENT-39) but keeps file storage (ARCH-01 deferred here). A database table fits Scrypath's Ecto-native positioning and works where a writable local folder doesn't.

## Scope

- decide between an Ecto-backed store as the default and a storage behaviour with Ecto and file implementations
- keep the v1 saved-search JSON format as the import/export interchange (sharing, git review, examples)
- migration or import path for existing files (e.g. the maintainer's `my-search.json`)
- adopter install cost: migration, Repo config, upgrade notes; update `.planning/PROJECT.md` if scope changes
- no storage-location choices in the UI

## Breadcrumbs

- `.planning/UI-FEEDBACK.md` (ARCH-01, CONTENT-39, UX-11)
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` (`mount/3` reads `playbook_workspace_dir`)
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` (`ops_workspace_mode_indicator/1`)
- `examples/scrypath_ecommerce/config/dev.exs`, `config/runtime.exs`
