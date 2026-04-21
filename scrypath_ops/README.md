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

Publishing the **`scrypath`** Hex package is done **only** from the **parent** library directory (`../` relative to this app), using the root `mix.exs` — not from this app.

## Production

When you run a **release** in **`MIX_ENV=prod`**, **`OPSUI_AUTH_MODE`** is **mandatory** and must be one of the values enforced at boot (see **`scrypath_ops/docs/SECURITY.md`**). Read that file before exposing `/ops` on a network.

## Learn more

* [Phoenix guides](https://hexdocs.pm/phoenix/overview.html)
