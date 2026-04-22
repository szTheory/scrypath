# Stack Research — Scrypath v1.15 (OPSUI second slice)

**Researched:** 2026-04-22  
**Confidence:** HIGH (brownfield — existing stack)

## Existing validated stack (do not churn)

- **Elixir / Phoenix / LiveView** — `scrypath_ops` operator app (optional dep), same as **v1.10–v1.14**.
- **`Scrypath`** core APIs — `search_many/2`, playground ceilings, federation options unchanged as contract surface.
- **`ScrypathOps.Playbook.V1`** + **`Playbook.Store`** / **`Runner`** — file workspace + `SCRYPATH_OPS_PLAYBOOK_DIR` from **v1.14**.

## Additions under consideration

| Addition | When needed | Notes |
|---------|-------------|-------|
| **Ecto + Postgres** (optional) | Only if milestone locks **server-backed catalog** | Keep **file workspace** default; migrations behind explicit config; no mandatory new infra for contributors. |
| **Phoenix LiveView uploads** | Already used for JSON import | Reuse patterns for export naming / metadata forms. |

## Versions

- Match repo **`.tool-versions`** / CI; no new runtime floor for **v1.15** unless Ecto path forces it (then document in phase plan).

## Integration points

- **`SearchPlaygroundStubAdapter`** — extend stub coverage for new LiveView events; no live Meilisearch in default **`mix verify.opsui`**.
- **`docs_contract_test.exs`** — anchor new **README** / **CONTRIBUTING** / **`operator-ia.md`** strings if user-visible.

---
*Stack research for milestone **v1.15***
