# Phase 44 — Technical research (OPSUI foundations)

**Question answered:** What do we need to know to plan the optional `scrypath_ops` Phoenix LiveView shell without polluting the Hex `scrypath` package?

## Summary

- **Layout:** Add a **second Mix project** at repo root (`scrypath_ops/`), sibling to the library, with `{:scrypath, path: ".."}`. Do **not** use `examples/` for OPSUI (privileged tooling vs adopter samples). Avoid umbrella unless already mandated.
- **Hex boundary:** Core `mix.exs` `package.files` is already a **whitelist** (`lib`, guides, docs, …); `scrypath_ops/` is **not** listed—confirm in docs that publishing runs **only** from the library directory and that `scrypath_ops` must never be added to `files`.
- **Phoenix shape:** Mirror `examples/phoenix_meilisearch` idioms (Phoenix ~> 1.8, Bandit, `scope`, pipelines) but with **`scope "/ops", ScrypathOpsWeb`** and a dedicated endpoint/router module set. Use **`live_session :ops`** with **`on_mount`** hooks reserved for auth (stubs acceptable in phase 44).
- **Security:** “Docs-only prod” is rejected by CONTEXT: implement **fail-closed** behavior in `prod` when operator HTTP surface would be exposed—e.g. refuse application start or omit `/ops` routes until **`OPSUI_AUTH_MODE`** (name per discretion) is set to a known non-empty value (`basic`, `proxy_headers`, future `oidc`). **Dev** may remain permissive only under `MIX_ENV=dev` with explicit documentation—never infer safety from localhost in containers.
- **Telemetry:** Shell events stay low-cardinality (screen labels, coarse outcomes); align wording with `docs/search-backend-sre.md`—no query text or per-record IDs in metadata.
- **Discoverability:** Short pointer from root `README.md` and/or a guide entry to `scrypath_ops/README.md` and `scrypath_ops/docs/operator-ia.md`; avoid duplicating long JTBD in `guides/`.

## Pitfalls

- **`check_origin` / WebSocket** in prod behind TLS-terminating proxies—document in SECURITY doc.
- **Accidental Hex inclusion** if someone expands `package.files` with a glob that sweeps `scrypath_ops/`—prefer explicit whitelist plus review checklist in plan acceptance criteria.

## Dependencies and versions

- Align Phoenix stack with `examples/phoenix_meilisearch` (Phoenix ~> 1.8.x, Elixir ~> 1.17) unless OPSUI needs a narrower range—document in `scrypath_ops/README.md`.

## Validation Architecture

Phase 44 validation should be **two-tier**:

1. **Library workspace:** `mix compile` and existing verification tasks remain green (OPSUI must not break the core project).
2. **OPSUI app:** After `scrypath_ops` exists, `cd scrypath_ops && mix compile` (and `mix test` once minimal test exists for fail-closed prod guard) provides fast feedback on every task.

Manual verification remains appropriate for **browser auth flows** once implemented in later phases; phase 44 focuses on **compile-time/route-level** fail-closed checks testable without a browser.

Sampling: run `mix compile` from repo root after changes to shared docs; run `mix compile` from `scrypath_ops` after app changes. Before phase close, run both in sequence.

## RESEARCH COMPLETE
