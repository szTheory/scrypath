# Stack Research

**Project:** Scrypath v1.41
**Updated:** 2026-09-28 after specialist primary-source review
**Confidence:** High for observed versions and declared constraints; runtime compatibility unexecuted.

## Recommended Stack

Keep Elixir 1.17+ and the existing Ecto/Phoenix/Oban/Req/Finch/Meilisearch topology. No new package, public API, support floor, or UI dependency is required. Current Mint advisories require **1.11.0 or a later release verified against refreshed advisories**; the initial 1.10.1 target is superseded.

| Maintained graph | Observed Mint / HPAX | Bounded action |
|---|---|---|
| Root `mix.lock` | 1.10.1 / 1.1.0 | Update Mint; retain other entries unless required by its resolution. |
| `examples/phoenix_meilisearch/mix.lock` | 1.9.3 / 1.0.4 | Update Mint and necessary HPAX subtree. |
| `examples/scrypath_ecommerce/mix.lock` | 1.9.3 / 1.0.4 | Update Mint and necessary HPAX subtree. |
| `scrypath_ops/mix.lock` | 1.9.3 / 1.0.4 | Update Mint and necessary HPAX subtree; no UI change. |

Every observed Finch constraint admits Mint 1.11.0. Mint 1.11.0 requires HPAX `~> 1.1`; both accept Elixir `~> 1.15`. Confirm solver and behavior results during execution; compatible metadata is not a test pass.

## Verification and Dependency Policy

Run direct audits for each graph; root deep-quality audit does not cover child locks. Make the explicit four-graph coverage recur within the existing advisory lane with a cheap omission guard, aggregate findings, lock preservation and measured incremental fetch/runtime cost. Hex audit does not compile or start services, but a clean environment may require dependency fetches. Keep repository inventory/orchestration outside the shipped package surface; do not duplicate root scanning. Reuse existing root/backend, Phoenix path/package, mounted ecommerce, and standalone Ops proof. Ops PR/main jobs must be inspected because manual closeout dispatch skips them. The package harness must establish actual resolved Hex-lock identity after swapping Scrypath provenance, not only its Git tag. Prefer focused deterministic regression for that boundary.

Use targeted Mint resolution and inspect all transitive changes; necessary HPAX changes are in scope. Do not broaden to `deps.update --all`, direct Mint minimum constraints, or unrelated bot updates. A library's lockfile is ignored by consuming projects: repository remediation does not upgrade adopter locks or impose a published minimum. Root `mix.lock` is the contributor graph, not the published library contract.

## Sources

The full six-advisory table, graph/CI source lines, alternatives and effective-lock proof gap are in [SECURITY-REVIEW.md](SECURITY-REVIEW.md). Authoritative upstream: [Mint security advisories](https://github.com/elixir-mint/mint/security/advisories), [1.11.0 metadata](https://hex.pm/api/packages/mint/releases/1.11.0), [HPAX 1.1.0 metadata](https://hex.pm/api/packages/hpax/releases/1.1.0), [Elixir library guidance](https://elixir.hexdocs.pm/library-guidelines.html), [Mix update](https://hexdocs.pm/mix/Mix.Tasks.Deps.Update.html), [Hex audit](https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html).
