# Support and compatibility

This guide is the single current support and readiness authority for Scrypath. Use it when you need supported runtime versions, the Phoenix + Meilisearch example path, sync-mode support, and the verification commands behind those claims.

## Supported baseline

- Elixir: `~> 1.17`
- OTP: the CI-tested tuples below cover OTP 26, 27, and 28; they do not establish upstream maintenance for every OTP line
- Search backend target for v1: Meilisearch
- Supported write paths in v1: `:inline`, `:manual`, `:oban`

## Install and release contract

Use this release-backed Hex dependency snippet for adopter installs:

```elixir
{:scrypath, "~> 0.3"}
```

Release-backed guidance is the default adopter path.
main may contain unreleased changes.

The source verification below describes this repository checkout. Dependency
and support changes become Hex-package claims only after a release containing
them is published.

This guide is the normative owner for install, runtime support, readiness, and release policy. Other surfaces should route here rather than restating a full policy matrix.

Those claims are intentionally narrow. They are backed by this repository's `mix.exs`, GitHub Actions workflow, published guides, and the runnable Phoenix example under `examples/phoenix_meilisearch/`.

## What the repo actively proves

### Elixir and OTP

`mix.exs` sets the library floor policy at Elixir `~> 1.17`.

GitHub Actions CI evidence currently exercises these explicit tuples:

- Elixir `1.17.3` with OTP `26.2.5`
- Elixir `1.18.4` with OTP `27.3`
- Elixir `1.19.0` with OTP `26.2.5`
- Elixir `1.19.0` with OTP `28.1`

Compatibility is policy plus verification: the Elixir floor remains `~> 1.17`,
and CI exercises the four listed combinations. These are discrete tuples, not
every combination in the Elixir and OTP ranges.

As of **2026-10-30**, the official Erlang/OTP version history marks OTP 26 as
**no longer supported** by the upstream project. Its history lists OTP 26.2.5.21
on 2026-05-26, while the upstream policy provides security updates and patches
for the latest three release lines. Scrypath's existing OTP 26 compatibility
tuple remains part of its test evidence; that test result does not mean OTP 26
still receives upstream security maintenance. See the [Erlang/OTP version
history and support policy](https://www.erlang.org/versions?v=26.2.5.21).

### Dependency and security status in this source checkout

The root manifest directly declares mandatory Telemetry as `{:telemetry,
"~> 1.0"}` and Req as `{:req, "~> 0.6.1 or ~> 0.7"}`. The Req union has two
different bounds: `~> 0.6.1` admits 0.6.1 and later patch releases below 0.7.0;
`~> 0.7` admits stable releases starting at 0.7.0 and below 1.0.0. It is not a
0.7.x-only bound. The installed-package proof currently has two concrete
witnesses, Req 0.6.3 and Req 0.7.5, resolved in separate consumers. Those
witnesses verify those versions and toolchains; they do not test every version
admitted by the broad 0.7 requirement. Recheck compatibility when a new stable
minor line, JSON or transport API, or upstream toolchain floor changes.

ScrypathOps keeps Sigra optional at `~> 1.5`. The source lock currently selects
non-retired Sigra 1.7.1, whose package metadata requires Elixir `~> 1.18`.
That is a separate optional Ops integration tier; it does not change the root
library's Elixir 1.17 floor or establish an OTP 27 minimum. In `basic` and
`proxy_headers` modes, the host remains responsible for authenticating HTTP,
LiveView WebSocket, and long-poll routes. Explicit `sigra` mode requires the
integration to be available and a valid local `:sudo_confirm_path`. Sensitive
actions also require valid user and organization context, no active
impersonation, and a current valid sudo confirmation. Selecting an auth mode
does not itself authenticate routes. See the [ScrypathOps production runbook](../scrypath_ops/README.md#production), which links to its detailed security boundary.

The final four source graphs were audited independently with Hex 2.5.1 on
2026-10-30. The root, Phoenix example, and ecommerce graph audits were clean.
The ScrypathOps audit remains affected and nonzero for two findings: high
severity in Cloak 1.1.4's AES-CTR authentication path ([EEF-CVE-2026-95105](https://osv.dev/vulnerability/EEF-CVE-2026-95105)) and medium severity in Cloak Ecto 1.3.0's PBKDF2 iteration-count handling ([EEF-CVE-2026-94206](https://osv.dev/vulnerability/EEF-CVE-2026-94206)). No advisory was ignored and no risk acceptance is implied. Bandit 1.14.1 is selected in Ops and both example graphs; the final audit reported no Bandit finding for those graphs. That fix does not clear the Cloak findings or make the aggregate audit clean.

Revisit the remaining findings when an upstream fixed release is available, a
relevant advisory or reachable-use/configuration changes, or maintainers make
an explicit dependency-risk policy decision. Compatibility tests, dependency
audits, and runtime security are separate evidence; a passing result in one
does not establish the others.

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

These verification commands run from a source checkout of the Scrypath repository; they are not part of the Hex package.

Other root `mix verify.*` capabilities are repository-maintainer commands, not
Hex APIs. Their current CI roles and the exact Ops and mounted-demo proof scope
are kept in the [contributor verification matrix](../CONTRIBUTING.md#ci).

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

If you are trying the documented path and encounter issues, or if you want to submit outside-adopter evidence for review, see [Outside-adopter intake](outside-adopter-intake.md). That guide owns the report classification vocabulary and maintainer routing actions; this support guide only routes to it.

## What this guide does not promise

Scrypath v1 does not currently promise:

- a public multi-backend support matrix beyond Meilisearch-first v1
- support for search engines other than Meilisearch
- a Phoenix-only architecture
- that every Elixir, OTP, Phoenix, Ecto, or Meilisearch combination outside the versions above is verified by CI
- that accepted sync work means immediate search visibility
- that the host application stops owning deployment, service, and search-visibility responsibilities

Scope-boundary and feature-lane reopen authority is owned by [Scope and reopen policy](scope-and-reopen-policy.md). This guide does not duplicate that policy body.

If you need the first-hour path, start with [Golden path](golden-path.md). If you need the runnable live example, continue to [`examples/phoenix_meilisearch/README.md`](../examples/phoenix_meilisearch/README.md). If you need sync semantics, use [Sync modes and visibility](sync-modes-and-visibility.md).
