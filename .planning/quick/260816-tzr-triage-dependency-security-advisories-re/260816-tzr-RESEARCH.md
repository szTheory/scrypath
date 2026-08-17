# Dependency Security Advisory Triage

**Date:** 2026-08-16  
**Scope:** Read-only triage of root, `scrypath_ops`, `examples/phoenix_meilisearch`, and `examples/scrypath_ecommerce`. No source, manifest, or lockfile was changed.

## Executive finding

`mix deps.get` reproduced advisories in all four independently resolved Mix projects. [VERIFIED: local `mix deps.get`, 2026-08-16] The core library has client-side HTTP exposure through direct `Req`; the Ops app and both examples additionally run public Phoenix/Bandit endpoints and Postgres. [VERIFIED: local `mix.exs`, lockfiles, and endpoint configuration]

The smallest complete fix is not a one-commit quick upgrade: it requires a core dependency-constraint change (`Req` 0.5 → 0.6), a legacy-example Ecto/Decimal alignment, and separate lockfile updates for Ops and the ecommerce example. [INFERENCE: local dependency constraints and fixed-version evidence] **Recommendation: keep this quick task triage-only and open a follow-up security-remediation phase with four atomic commits.**

## Reproduction inventory

| Project | Result | Locked affected packages |
|---|---|---|
| root `scrypath` | advisories reproduced | `hpax 1.0.3`, `mint 1.8.0`, `plug 1.19.2`, `req 0.5.18` |
| `scrypath_ops` | advisories reproduced | `bandit 1.11.1`, `hpax 1.0.3`, `mint 1.8.0`, `phoenix 1.8.7`, `phoenix_live_view 1.1.31`, `plug 1.19.2`, `postgrex 0.22.2`, `req 0.5.18`, `swoosh 1.26.0` |
| `examples/phoenix_meilisearch` | advisories reproduced | `bandit 1.10.4`, `decimal 2.3.0`, `hpax 1.0.3`, `mint 1.7.1`, `phoenix 1.8.5`, `plug 1.19.1`, `postgrex 0.22.0`, `req 0.5.17` |
| `examples/scrypath_ecommerce` | advisories reproduced | same affected package set as Ops |

All rows: [VERIFIED: local `mix deps.get`, 2026-08-16].

## Advisory matrix

The exact advisory IDs and severities below are from Mix’s EEF feed; fixed releases/ranges are from the EEF CNA records or GitHub Security Advisory API. [VERIFIED: local `mix deps.get`; [EEF CNA](https://cna.erlef.org/); [GitHub advisories](https://github.com/advisories)]

| Package / locked versions | Advisory IDs (severity) | First release fixing every listed advisory | Directness and introducing path | Runtime surface / exposure assessment | Evidence |
|---|---|---|---|---|---|
| `hpax 1.0.3` (all projects) | `EEF-CVE-2026-58226` (HIGH) | `1.0.4` | transitive: `Req → Finch → Mint → hpax` in core; also `Bandit → hpax` in web apps | HTTP/2 HPACK parsing. Core reaches it only via outbound client calls; web apps also accept HTTP/2 traffic through Bandit. Do not treat either path as non-exploitable. | [EEF CNA](https://cna.erlef.org/cves/CVE-2026-58226.html), [GHSA](https://github.com/elixir-mint/hpax/security/advisories/GHSA-jj2p-32j7-whj2), [Hex](https://hex.pm/packages/hpax) |
| `mint 1.7.1` (Phoenix example); `1.8.0` (others) | `49754` HIGH, `48861` LOW, `48862` HIGH, `49753` MEDIUM, `56810` HIGH, `58229` HIGH, `59246` MEDIUM, `59249` MEDIUM | `1.9.3` (the highest required fixed version; earlier fixes are `1.9.0`, `1.9.1`, `1.9.2`) | transitive: `Req → Finch → Mint` | Outbound HTTP parsing used by Scrypath’s Meilisearch client and configured Swoosh Req client. Attack precondition varies by advisory (malicious/untrusted upstream response or pooled connection); source review did not establish a blanket exemption. | [EEF CNA CVE-2026-49754](https://cna.erlef.org/cves/CVE-2026-49754.html), [GHSA 1.9.0](https://github.com/advisories/GHSA-2p26-p43x-fhp8), [Hex](https://hex.pm/packages/mint) |
| `req 0.5.17` / `0.5.18` | `EEF-CVE-2026-49755` (HIGH), `EEF-CVE-2026-49756` (LOW) | `0.6.1` covers both (`0.6.0` fixes only 49756) | direct in root, Ops, ecommerce; transitive from local path dependency in Phoenix example | Core uses it for Meilisearch HTTP. Ops production config explicitly selects `Swoosh.ApiClient.Req`. Decompression-bomb and multipart construction paths are therefore present; per-call option audit remains required. | [EEF CNA CVE-2026-49755](https://cna.erlef.org/cves/CVE-2026-49755.html), [GHSA](https://github.com/advisories/GHSA-655f-mp8p-96gv), [Hex](https://hex.pm/packages/req) |
| `plug 1.19.1` / `1.19.2` | `8468` HIGH, `54892` HIGH, `56813` LOW, `56814` MEDIUM | `1.19.5` within the 1.19 line | root direct test-only; transitive/runtime via Phoenix, Bandit, and LiveView in web apps | Root is test-only. Ops and examples have `Plug.Parsers`, normal controller routes, LiveView, and file upload handling, so request parsing/cookie exposure is credible; exact attacker reachability is configuration-dependent. | [EEF CNA CVE-2026-54892](https://cna.erlef.org/cves/CVE-2026-54892.html), [GHSA 8468](https://github.com/advisories/GHSA-468c-vq7p-gh64), [Hex](https://hex.pm/packages/plug) |
| `bandit 1.10.4` (Phoenix example) | `42788` MEDIUM, `39805` MEDIUM, `39807` MEDIUM, `39804` HIGH, `39803` HIGH, `39806` HIGH, `42786` HIGH | `1.11.1` covers this legacy set | direct web-server dependency | The Phoenix example config selects `Bandit.PhoenixAdapter`; vulnerable request/WebSocket/HTTP2 handling is on its inbound public-server surface. | [EEF CNA CVE-2026-39803](https://cna.erlef.org/cves/CVE-2026-39803.html), [GHSA](https://github.com/advisories/GHSA-9q9q-324x-93r2), [Hex](https://hex.pm/packages/bandit) |
| `bandit 1.11.1` (Ops, ecommerce) | `EEF-CVE-2026-65623` (HIGH) | `1.12.1` | direct web-server dependency | Ops and ecommerce select `Bandit.PhoenixAdapter` and expose LiveView WebSockets; fragmented WebSocket traffic is a relevant inbound surface. | [EEF CNA](https://cna.erlef.org/cves/CVE-2026-65623.html), [GHSA](https://github.com/advisories/GHSA-vg8x-66vg-5pxh), [Hex](https://hex.pm/packages/bandit) |
| `phoenix 1.8.5` (Phoenix example) | `32689` HIGH, `56811` HIGH, `56812` MEDIUM | `1.8.9` covers all | direct web framework | Inbound long-poll/channel joins and browser presence client are used by the demo’s Phoenix/LiveView surface; the app configuration must be reviewed after upgrade. | [EEF CNA CVE-2026-32689](https://cna.erlef.org/cves/CVE-2026-32689.html), [GHSA](https://github.com/advisories/GHSA-628h-q48j-jr6q), [Hex](https://hex.pm/packages/phoenix) |
| `phoenix 1.8.7` (Ops, ecommerce) | `56811` HIGH, `56812` MEDIUM | `1.8.9` | direct web framework | Same inbound channel/presence surface; Ops and ecommerce mount LiveView endpoints. | [EEF CNA CVE-2026-56811](https://cna.erlef.org/cves/CVE-2026-56811.html), [Hex](https://hex.pm/packages/phoenix) |
| `phoenix_live_view 1.1.31` (Ops, ecommerce) | `EEF-CVE-2026-64941` (LOW) | `1.1.33` | direct web framework integration | Redirect validation is present in the mounted LiveView applications. No targeted audit proved whether the affected URL path is user-controlled here. | [EEF CNA](https://cna.erlef.org/cves/CVE-2026-64941.html), [GHSA](https://github.com/advisories/GHSA-36m4-rm57-3prf), [Hex](https://hex.pm/packages/phoenix_live_view) |
| `postgrex 0.22.0` (Phoenix example); `0.22.2` (Ops, ecommerce) | `32687` HIGH, `58225` LOW, `66838` MEDIUM (as applicable to locked version) | `0.22.4` | direct database driver | All three web apps run Ecto Repos. Source review did not find `Postgrex.Notifications.listen/unlisten` or `Postgrex.stream(..., comment: ...)` calls, which lowers confidence of those specific paths but is not a non-exploitability claim. | [EEF CNA CVE-2026-66838](https://cna.erlef.org/cves/CVE-2026-66838.html), [GHSA 32687](https://github.com/advisories/GHSA-r73h-97w8-m54h), [Hex](https://hex.pm/packages/postgrex) |
| `decimal 2.3.0` (Phoenix example) | `EEF-CVE-2026-32686` (MEDIUM) | `3.0.0` | transitive: `Ecto 3.13.5 → Decimal ~> 2.0` | Ecto parameter/cast use is present in the example. Fixing Decimal requires moving that example’s Ecto/Ecto SQL resolution to the 3.14 line; a Decimal-only lock change conflicts with its declared dependency range. | [EEF CNA](https://cna.erlef.org/cves/CVE-2026-32686.html), [Hex](https://hex.pm/packages/decimal) |
| `swoosh 1.26.0` (Ops, ecommerce) | `EEF-CVE-2026-54893` (LOW) | `1.26.3` | direct mailer | Ops config uses Swoosh; production config selects its Req API client. The reported Microsoft Graph adapter path was not found in local config, but adapter deployment can vary by operator. | [EEF CNA](https://cna.erlef.org/cves/CVE-2026-54893.html), [GHSA](https://github.com/advisories/GHSA-754j-98wh-57rf), [Hex](https://hex.pm/packages/swoosh) |

## Recommended remediation sequence

Apply one batch, run its gates, and commit before beginning the next. [VERIFIED: `dependency-upgrade` skill]

1. **Core client batch — medium risk.** In root `mix.exs`, constrain `req` to the fixed 0.6 line (recommend `~> 0.6.1`, resolving latest compatible `0.6.x`), then update root `Req`, `Mint` to `1.9.3`, `hpax` to `1.0.4`, and `Plug` to `1.19.5`. This is a required public dependency-constraint change, not a lock-only update. [INFERENCE: local constraints; [Req GHSA](https://github.com/advisories/GHSA-655f-mp8p-96gv)]
2. **Legacy Phoenix example batch — high regression risk.** Update its web/network lock graph to the minimum fixed releases: Bandit `1.12.1`, Phoenix `1.8.9`, Plug `1.19.5`, Postgrex `0.22.4`, Mint `1.9.3`, hpax `1.0.4`, and Req `0.6.x`; align Ecto/Ecto SQL to `3.14.x` so Decimal resolves to `3.x`. This is isolated because it changes an older example’s Ecto generation and lockfile. [INFERENCE: local lock dependency ranges and EEF fixed-version data]
3. **ScrypathOps batch — medium/high runtime risk.** Update its independent lockfile to the same shared web/client fixes plus LiveView `1.1.33` and Swoosh `1.26.3`; update its `Req` constraint to `~> 0.6.1`. Treat Bandit `1.11 → 1.12` as an isolated runtime-minor upgrade within this commit. [INFERENCE: local manifest and EEF fixed-version data]
4. **Ecommerce example batch — medium/high runtime risk.** Repeat the Ops-compatible web/client resolution in its independent manifest/lockfile. Keep it separate because it is the browser E2E application and mounts ScrypathOps through a path dependency. [INFERENCE: local manifest and application structure]

Do not opportunistically upgrade to current package heads: the cited fixed minima are sufficient to clear the recorded advisories, while current Hex releases are newer (`Bandit 1.12.4`, `Mint 1.9.3`, `Phoenix 1.8.11`, `Plug 1.20.3`, `Postgrex 0.22.4`, `Req 0.7.2`). [VERIFIED: Hex package metadata, 2026-08-16]

## Verification gates per batch

| Batch | Required command sequence |
|---|---|
| Core | `mix deps.get`; `mix compile --warnings-as-errors`; `mix test --exclude integration --exclude docs_contract`; `mix verify --exclude integration`; `mix verify.phase11`; `mix verify.phase99` |
| Legacy Phoenix example | `cd examples/phoenix_meilisearch && mix deps.get && mix test`; then root `mix test --exclude integration --exclude docs_contract` |
| Ops | `mix verify.opsui` from repository root; then root required gates above |
| Ecommerce | `mix deps.get`; `cd examples/scrypath_ecommerce && mix deps.get && mix e2e.prepare`; run the advisory `phase105-e2e` CI lane / its documented browser checks when environment services are available |

The root required gates are `main-ci`, `repo-hygiene`, `release-truth`, and `phase99-trust`; `mix verify.opsui` mirrors the dedicated Ops CI job. [VERIFIED: `CONTRIBUTING.md` and `lib/mix/tasks/verify*.ex`]

## Deferred and unknown

- Exact attacker reachability remains unproven for Mint response-parsing advisories, Req decompression settings, and adapter-selected Swoosh behavior; retain the advisory risk until a targeted configuration/call-site audit is performed. [INFERENCE: local source scan]
- The Phoenix example is the only project pinned to Ecto 3.13/Decimal 2.x. Its fix is a framework-compatible minor-line update but needs its own regression batch. [VERIFIED: local `examples/phoenix_meilisearch/mix.lock`; [EEF CNA](https://cna.erlef.org/cves/CVE-2026-32686.html)]
- GitHub’s public advisory API returned records for several earlier advisories, while newer EEF records are canonicalized through the EEF CNA/OSV feed; fixed versions above use the EEF record where GitHub did not expose an API record. [VERIFIED: GitHub advisory API and EEF CNA records, 2026-08-16]

## Sources

- Local manifests and lockfiles: `mix.exs`, `mix.lock`, `scrypath_ops/mix.{exs,lock}`, and both example `mix.{exs,lock}` files. [VERIFIED: local source]
- Advisory inventory: `mix deps.get` executed in each of the four Mix projects. [VERIFIED: local command]
- [Erlang Ecosystem Foundation CNA](https://cna.erlef.org/) advisory records and their linked package-repository GHSAs. [VERIFIED: primary advisory source]
- [GitHub Security Advisories](https://github.com/advisories) for published affected ranges and first patched versions. [VERIFIED: primary advisory source]
- [Hex package metadata](https://hex.pm/) for current published releases. [VERIFIED: primary package registry]
