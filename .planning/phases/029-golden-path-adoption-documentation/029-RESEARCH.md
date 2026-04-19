# Phase 29 — Technical Research

**Question:** What do we need to know to plan ADPT-01..03 (golden path, sync-mode clarity, versioning consistency) well?

## Findings

### Repository facts

- **`mix.exs`** declares **`@version "0.3.3"`** while **`README.md`** still shows **`{:scrypath, "~> 0.3.0"}`** — adopters get a confusing floor vs current release; golden path and README must align with a **`~>`** range compatible with **`@version`** (029-CONTEXT D-04).
- **ExDoc extras** are enumerated explicitly in **`mix.exs`** `docs/0` → **`extras:`** and **`groups_for_extras:`**. A new **`guides/golden-path.md`** is **not** picked up automatically; it **must** be added to **`extras`** and placed under **"Getting Started"** (or adjacent) or it will be absent from HexDocs.
- **`guides/getting-started.md`** already encodes the three-piece model and **`sync_mode: :inline`** in **`publish_post/2`** — golden path should **link back** here for theory-first readers (029-CONTEXT D-01).
- **`guides/sync-modes-and-visibility.md`** already owns full **`:inline` / `:oban` / `:manual`** semantics and Phoenix honesty — README should stay a **compact table + links**, not a second authority (029-CONTEXT D-03).
- **`docs/releasing.md`** is the maintainer canonical gate doc (**`mix verify.phase11`**, Release Please, post-publish tasks) — adopters need a **short README bridge** that points here without duplicating tables (029-CONTEXT D-04).
- **`examples/phoenix_meilisearch/README.md`** documents **Compose**, **`SCRYPATH_MEILISEARCH_URL`**, **`SCRYPATH_EXAMPLE_INTEGRATION`**, **Meilisearch v1.15**, **Postgres 5433** — golden path “bring up Meilisearch” should **align** with this file (029-CONTEXT D-02).

### Ecosystem patterns (documentation only)

- **Laravel Scout** surfaces queueing soon after install — mirror **ordering**: golden path finishes on **inline**; **“What’s next”** points to sync guide + Oban docs without implementing Oban in the first hour (029-CONTEXT).
- **Searchkick** packs a linear README story but risks implying **implicit sync** — Scrypath docs must keep **`Scrypath.sync_record/3`** and **`sync_mode`** visible in the golden path.

### Planning implications

- Minimum **three executable plans** (or three waves) mapping **ADPT-01**, **ADPT-02**, **ADPT-03** to grep-verifiable doc edits and **`mix.exs`** ExDoc registration.
- No application code or schema migrations — **no** schema-push gate.
- UI-SPEC gate **skipped** — phase is documentation-only (no UI keywords in goal beyond “reader”).

## Validation Architecture

Phase 29 is **documentation-first**. Automated feedback is **not** ExUnit feature tests; it is **docs compile + format + release-doc contract** already used in CI.

| Dimension | Signal source | Sampling command | Pass criterion |
|-----------|----------------|------------------|----------------|
| Markdown hygiene | edited `.md` files | `mix format --check-formatted` | exit 0 |
| Docs / warnings | ExDoc | `MIX_ENV=test mix docs --warnings-as-errors` | exit 0, no warnings |
| Release doc contract | library verify | `mix verify.phase11` (or documented subset if full gate too heavy per task) | exit 0 where cited in plan |

**Nyquist note:** After each plan wave, run **`mix format --check-formatted`** and **`MIX_ENV=test mix docs --warnings-as-errors`** so broken ExDoc extras or bad links in compiled docs surface before merge.

## RESEARCH COMPLETE
