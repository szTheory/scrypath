# Support and compatibility

This guide is the single current support and readiness authority for Scrypath. Use it when you need supported runtime versions, the Phoenix + Meilisearch example path, sync-mode support, and the verification commands behind those claims.

## Supported baseline

- Elixir: `~> 1.17`
- OTP: 26 through 28
- Search backend target for v1: Meilisearch
- Supported write paths in v1: `:inline`, `:manual`, `:oban`

## Install and release contract

Use this release-backed Hex dependency snippet for adopter installs:

```elixir
{:scrypath, "~> 0.3"}
```

Release-backed guidance is the default adopter path.
main may contain unreleased changes.

This guide is the normative owner for install and release policy. Other surfaces should route here rather than restating a full policy matrix.

Those claims are intentionally narrow. They are backed by this repository's `mix.exs`, GitHub Actions workflow, published guides, and the runnable Phoenix example under `examples/phoenix_meilisearch/`.

## What the repo actively proves

### Elixir and OTP

`mix.exs` sets the library floor policy at Elixir `~> 1.17`.

GitHub Actions CI evidence currently exercises these explicit tuples:

- Elixir `1.17.3` with OTP `26.2.5`
- Elixir `1.19.0` with OTP `28.1`

Compatibility is policy plus verification: the floor policy remains `~> 1.17`, and CI tuple evidence is anchored to the two combinations above. That means Scrypath publicly supports Elixir 1.17 through the current stable line this repo tests, with OTP 26 through 28 as the tested runtime range.

### Phoenix + Meilisearch adoption path

Scrypath is Ecto-first and Phoenix-friendly:

- the core API is built around Ecto schemas and explicit repo-backed hydration
- the published onboarding path uses Phoenix-shaped contexts, controllers, and LiveView guides
- the canonical real-app example is the Phoenix + Meilisearch app under `examples/phoenix_meilisearch/`

This is an adoption posture, not a promise that Scrypath requires Phoenix. The library remains usable in Ecto applications without Phoenix, but the actively verified real-app path is Phoenix + Meilisearch.

### Meilisearch posture

Scrypath v1 publicly targets Meilisearch first.

The verified Meilisearch target today is the `v1.15` minor line:

- CI service images use `getmeili/meilisearch:v1.15`
- the Phoenix example Compose stack uses `getmeili/meilisearch:v1.15`

If you run a different Meilisearch version, treat that as outside the repo's explicit support contract until CI and the example move with it.

### Synchronization modes

The public v1 write-path contract covers:

- `:inline`
- `:manual`
- `:oban`

This guide names the supported modes, but it does not restate their operational semantics. Use [Sync modes and visibility](sync-modes-and-visibility.md) for what those modes mean, how eventual consistency shows up, and what "done" does or does not imply.

## Verification command family

The adopter verification path is intentionally split into two depths:

- `mix verify.adopter` is the fast, service-free contract check for support/readiness guidance.
- `mix verify.adopter --live` is the prerequisite-bound live check that requires `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL`.

The live command executes `cd examples/phoenix_meilisearch && mix deps.get && mix test`.

That split preserves operational honesty: fast mode protects support/readiness guidance, while live mode checks the Phoenix + Meilisearch example path against real services.

## Repo clone versus Hex package boundary

The Phoenix example lives in this repository and depends on Scrypath via a local `path:` dependency. That means:

- the library itself is published on Hex
- the runnable Phoenix example path is a repo-clone workflow, not part of the Hex package artifact
- the example README is the authoritative live runbook for env vars, service startup, and CI parity details

If you are evaluating the packaged library only, start with the public guides and README. If you need the runnable real-app path, use the repository checkout and follow [`examples/phoenix_meilisearch/README.md`](../examples/phoenix_meilisearch/README.md).

## In-repo verification versus outside-adopter evidence

Scrypath currently has in-repo verification for its Phoenix + Meilisearch path. That is not the same thing as reviewed outside-adopter evidence.

- in-repo verification means the current checkout, CI, guides, and example app support the documented path
- outside-adopter evidence means a real external integration has been reviewed and folded back into the support posture

If you are trying the documented path and encounter issues, or if you want to submit outside-adopter evidence for review, see [Outside-adopter intake](outside-adopter-intake.md).

## What this guide does not promise

Scrypath v1 does not currently promise:

- a public multi-backend support matrix beyond Meilisearch-first v1
- support for search engines other than Meilisearch
- a Phoenix-only architecture
- that every Elixir, OTP, Phoenix, Ecto, or Meilisearch combination outside the versions above is verified by CI
- that accepted sync work means immediate search visibility
- that the host application stops owning deployment, service, and search-visibility responsibilities

If you need the first-hour path, start with [Golden path](golden-path.md). If you need the runnable live example, continue to [`examples/phoenix_meilisearch/README.md`](../examples/phoenix_meilisearch/README.md). If you need sync semantics, use [Sync modes and visibility](sync-modes-and-visibility.md).
