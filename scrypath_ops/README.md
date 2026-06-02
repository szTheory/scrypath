# ScrypathOps

Optional **Phoenix + LiveView** operator shell for the Scrypath repository. It lives next to the **`:scrypath`** library; it is **not** published to Hex as part of the `scrypath` package.

## Prerequisites

- **Elixir** `~> 1.17` and **Erlang/OTP** as described in the repo root [`AGENTS.md`](../AGENTS.md) / [`README.md`](../README.md).
- **PostgreSQL** reachable with the credentials in `config/dev.exs` (or override with `DATABASE_URL` via `config/runtime.exs`).

## Clone and run

Clone the **repository root** (so `scrypath_ops/mix.exs` resolves `{:scrypath, path: ".."}` to the library):

```bash
git clone https://github.com/szTheory/scrypath.git
cd scrypath/scrypath_ops
mix setup
mix phx.server
```

Then open [http://localhost:4000](http://localhost:4000).

## Mounted host app assets

When a Phoenix host mounts ScrypathOps under a path such as `/admin/search/*`, the host
root layout must load the operator stylesheet for those routes:

```heex
<link phx-track-static rel="stylesheet" href="/admin/search/assets/css/app.css" />
```

The host JavaScript should also handle the operator shell events:

- `phx:set-theme` — set or clear `data-theme` on `document.documentElement` and persist the
  explicit light/dark preference when present.
- `phx:copy_run_diagnostics` — copy the playbook run diagnostics payload to the clipboard.

The e-commerce demo wires both pieces in its root layout and app JavaScript so `/admin/search/*`
looks and behaves like the standalone `/ops` shell without loading a second LiveSocket.

## OPSUI schema allowlist

The `/ops` LiveViews only load schema modules listed in **`schema_allowlist`** under
**`:scrypath_ops`** (set in `config/*.exs` or at runtime). There is **no** reflection-based
discovery in `scrypath_ops/lib`.

- **Config key:** `config :scrypath_ops, :schema_allowlist, [MyApp.Blog.Post]`
- **Environment variable (optional):** `SCRYPATH_OPS_SCHEMAS` — comma-separated dotted
  module names (for example `MyApp.Blog.Post,MyApp.Catalog.Item`). When set, it replaces
  the compile-time allowlist when `config/runtime.exs` runs.

Additional **`Scrypath.*`** runtime options (`:backend`, `:meilisearch_url`, `:index_prefix`,
`:sync_mode`, `:oban`, `:oban_queue`, etc.) belong under `:scrypath_ops` as well so
`ScrypathOps.Schemas.scrypath_opts/0` can build the keyword passed into operator APIs.

Publishing the **`scrypath`** Hex package is done **only** from the **parent** library directory (`../` relative to this app), using the root `mix.exs` — not from this app.

## Search playground bounds

The `/ops/search` playground validates **`page.size`** and schema breadth **before** calling `Scrypath`, using the same ceilings as `Scrypath.MultiSearch.Entries` (page **≤ 50**, default **≤ 10** schemas per multi-search).

| Config key (`config :scrypath_ops, …`) | Meaning |
| --- | --- |
| `:search_playground_default_page_size` | Default page size (**15** if unset or invalid). Clamped to **`1..max_page_size`**. |
| `:search_playground_max_page_size` | Upper bound for **`page.size`** in the UI (**50** max, aligned with the library). Hosts may set a lower ceiling in **`[1, 50]`**. |
| `:search_playground_max_schemas` | Maximum schemas selectable in multi mode (**1..10**; invalid values fall back to **10**). |
| `:search_playground_adapter` | Behaviour implementing `ScrypathOps.SearchPlayground.Adapter` — defaults to `ScrypathOps.SearchPlayground.Adapter.Scrypath`. **Intended for tests and local stubs only**; production should keep the default. |

Optional environment variables (read in `config/runtime.exs`, same spirit as `SCRYPATH_OPS_SCHEMAS`):

| Variable | Maps to |
| --- | --- |
| `SCRYPATH_OPS_SEARCH_DEFAULT_PAGE_SIZE` | `:search_playground_default_page_size` |
| `SCRYPATH_OPS_SEARCH_MAX_PAGE_SIZE` | `:search_playground_max_page_size` |
| `SCRYPATH_OPS_SEARCH_MAX_SCHEMAS` | `:search_playground_max_schemas` |

## Production

When you run a **release** in **`MIX_ENV=prod`**, **`OPSUI_AUTH_MODE`** is **mandatory** and must be one of the values enforced at boot (see **`scrypath_ops/docs/SECURITY.md`**). Read that file before exposing `/ops` on a network.

## Learn more

* [Team playbook persistence](docs/team-playbook-persistence.md) — workspace directory, **`SCRYPATH_OPS_PLAYBOOK_DIR`**, GitOps, and **`mix scrypath_ops.playbooks.validate`**
* [Phoenix guides](https://hexdocs.pm/phoenix/overview.html)
