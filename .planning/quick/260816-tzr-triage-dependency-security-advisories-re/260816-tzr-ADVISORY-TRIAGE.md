---
quick_id: 260816-tzr
status: triage-complete-remediation-pending
date: 2026-08-16
scope: dependency-security-advisories
---

# Dependency Security Advisory Triage Ledger

> **Status — 2026-08-16:** Advisories were reproduced in four independently resolved Mix projects. Triage is complete; **remediation is pending**. No source file, dependency manifest, or lockfile was changed, and this checkout does not claim any advisory is fixed.

## Reproduction inventory

| Project | Affected locked packages |
| --- | --- |
| Root `scrypath` | `hpax 1.0.3`, `mint 1.8.0`, `plug 1.19.2`, `req 0.5.18` |
| `scrypath_ops` | `bandit 1.11.1`, `hpax 1.0.3`, `mint 1.8.0`, `phoenix 1.8.7`, `phoenix_live_view 1.1.31`, `plug 1.19.2`, `postgrex 0.22.2`, `req 0.5.18`, `swoosh 1.26.0` |
| `examples/phoenix_meilisearch` | `bandit 1.10.4`, `decimal 2.3.0`, `hpax 1.0.3`, `mint 1.7.1`, `phoenix 1.8.5`, `plug 1.19.1`, `postgrex 0.22.0`, `req 0.5.17` |
| `examples/scrypath_ecommerce` | Same affected package set as `scrypath_ops` |

Reproduction evidence is the local `mix deps.get` result in each project on 2026-08-16. Fixed minima below clear the **recorded advisory set only**; they are not an instruction to upgrade opportunistically to current package heads.

## Advisory and exposure matrix

| Package / affected versions | Advisory IDs (severity) | Fixed minimum | Directness / introducing path | Runtime surface and confidence | Primary evidence |
| --- | --- | --- | --- | --- | --- |
| `hpax 1.0.3` (all projects) | `EEF-CVE-2026-58226` (HIGH) | `1.0.4` | Transitive: `Req → Finch → Mint → hpax` in core; also `Bandit → hpax` in web apps | HTTP/2 HPACK parsing. **Confirmed surface:** core outbound HTTP and Bandit inbound HTTP/2; neither is exempt. | [EEF CNA](https://cna.erlef.org/cves/CVE-2026-58226.html), [GHSA](https://github.com/elixir-mint/hpax/security/advisories/GHSA-jj2p-32j7-whj2), [Hex](https://hex.pm/packages/hpax) |
| `mint 1.7.1` (Phoenix example), `1.8.0` (others) | `49754` HIGH; `48861` LOW; `48862` HIGH; `49753` MEDIUM; `56810` HIGH; `58229` HIGH; `59246` MEDIUM; `59249` MEDIUM | `1.9.3` (earlier fixes: `1.9.0`, `1.9.1`, `1.9.2`) | Transitive: `Req → Finch → Mint` | Outbound HTTP parsing via the Meilisearch client and configured Swoosh Req client. **Credible/configuration-dependent:** malicious upstream response or pooled connection preconditions vary; no blanket exemption. | [EEF CNA CVE-2026-49754](https://cna.erlef.org/cves/CVE-2026-49754.html), [GHSA](https://github.com/advisories/GHSA-2p26-p43x-fhp8), [Hex](https://hex.pm/packages/mint) |
| `req 0.5.17` / `0.5.18` | `EEF-CVE-2026-49755` (HIGH), `EEF-CVE-2026-49756` (LOW) | `0.6.1` (`0.6.0` fixes only 49756) | Direct in root, Ops, ecommerce; transitive local-path dependency in Phoenix example | Core Meilisearch HTTP and Ops production `Swoosh.ApiClient.Req`. **Confirmed surface:** decompression and multipart code are present; call options need audit. | [EEF CNA 49755](https://cna.erlef.org/cves/CVE-2026-49755.html), [GHSA](https://github.com/advisories/GHSA-655f-mp8p-96gv), [Hex](https://hex.pm/packages/req) |
| `plug 1.19.1` / `1.19.2` | `8468` HIGH; `54892` HIGH; `56813` LOW; `56814` MEDIUM | `1.19.5` | Root direct test-only; transitive/runtime through Phoenix, Bandit, and LiveView in web apps | Root is test-only. **Credible/configuration-dependent:** web apps have `Plug.Parsers`, controllers, LiveView, and uploads, making parser/cookie exposure credible. | [EEF CNA 54892](https://cna.erlef.org/cves/CVE-2026-54892.html), [GHSA](https://github.com/advisories/GHSA-468c-vq7p-gh64), [Hex](https://hex.pm/packages/plug) |
| `bandit 1.10.4` (Phoenix example) | `42788` MEDIUM; `39805` MEDIUM; `39807` MEDIUM; `39804` HIGH; `39803` HIGH; `39806` HIGH; `42786` HIGH | `1.11.1` for this legacy advisory set; planned batch minimum `1.12.1` | Direct web-server dependency | `Bandit.PhoenixAdapter` is selected. **Confirmed surface:** inbound request, WebSocket, and HTTP/2 handling. | [EEF CNA 39803](https://cna.erlef.org/cves/CVE-2026-39803.html), [GHSA](https://github.com/advisories/GHSA-9q9q-324x-93r2), [Hex](https://hex.pm/packages/bandit) |
| `bandit 1.11.1` (Ops, ecommerce) | `EEF-CVE-2026-65623` (HIGH) | `1.12.1` | Direct web-server dependency | `Bandit.PhoenixAdapter` and LiveView WebSockets. **Confirmed surface:** fragmented inbound WebSocket traffic. | [EEF CNA](https://cna.erlef.org/cves/CVE-2026-65623.html), [GHSA](https://github.com/advisories/GHSA-vg8x-66vg-5pxh), [Hex](https://hex.pm/packages/bandit) |
| `phoenix 1.8.5` (Phoenix example), `1.8.7` (Ops, ecommerce) | Example: `32689` HIGH, `56811` HIGH, `56812` MEDIUM. Ops/ecommerce: `56811` HIGH, `56812` MEDIUM | `1.8.9` | Direct web framework | Inbound channel/long-poll/presence paths and LiveView endpoints. **Credible/configuration-dependent:** post-upgrade app configuration review required. | [EEF CNA 32689](https://cna.erlef.org/cves/CVE-2026-32689.html), [EEF CNA 56811](https://cna.erlef.org/cves/CVE-2026-56811.html), [GHSA](https://github.com/advisories/GHSA-628h-q48j-jr6q), [Hex](https://hex.pm/packages/phoenix) |
| `phoenix_live_view 1.1.31` (Ops, ecommerce) | `EEF-CVE-2026-64941` (LOW) | `1.1.33` | Direct web framework integration | Redirect validation in mounted LiveView apps. **Reduced confidence but not exempt:** no targeted audit showed whether the affected URL path is user-controlled. | [EEF CNA](https://cna.erlef.org/cves/CVE-2026-64941.html), [GHSA](https://github.com/advisories/GHSA-36m4-rm57-3prf), [Hex](https://hex.pm/packages/phoenix_live_view) |
| `postgrex 0.22.0` (Phoenix example), `0.22.2` (Ops, ecommerce) | `32687` HIGH; `58225` LOW; `66838` MEDIUM (as applicable) | `0.22.4` | Direct database driver | Ecto Repos run in all web apps. **Reduced confidence but not exempt:** no local `Postgrex.Notifications.listen/unlisten` or `Postgrex.stream(..., comment: ...)` call was found. | [EEF CNA 66838](https://cna.erlef.org/cves/CVE-2026-66838.html), [GHSA](https://github.com/advisories/GHSA-r73h-97w8-m54h), [Hex](https://hex.pm/packages/postgrex) |
| `decimal 2.3.0` (Phoenix example) | `EEF-CVE-2026-32686` (MEDIUM) | `3.0.0` | Transitive: `Ecto 3.13.5 → Decimal ~> 2.0` | Ecto parameter/cast use. **Confirmed surface:** the fix requires Ecto/Ecto SQL 3.14 alignment because a Decimal-only update conflicts with the declared range. | [EEF CNA](https://cna.erlef.org/cves/CVE-2026-32686.html), [Hex](https://hex.pm/packages/decimal) |
| `swoosh 1.26.0` (Ops, ecommerce) | `EEF-CVE-2026-54893` (LOW) | `1.26.3` | Direct mailer | Ops config uses Swoosh and production selects Req API client. **Reduced confidence but not exempt:** Microsoft Graph adapter was not found locally, but deployment adapter selection can vary. | [EEF CNA](https://cna.erlef.org/cves/CVE-2026-54893.html), [GHSA](https://github.com/advisories/GHSA-754j-98wh-57rf), [Hex](https://hex.pm/packages/swoosh) |

## Ordered remediation plan — pending

Apply and verify one batch before starting the next; stop on any failed gate and consult upstream migration/release notes before every constraint change.

1. **Root core client — medium risk.** Change root `Req` constraint to `~> 0.6.1`; resolve `Req 0.6.1+`, `Mint 1.9.3`, `hpax 1.0.4`, and `Plug 1.19.5`.
2. **Legacy Phoenix example/Ecto–Decimal alignment — high regression risk.** Resolve Bandit `1.12.1`, Phoenix `1.8.9`, Plug `1.19.5`, Postgrex `0.22.4`, Mint `1.9.3`, hpax `1.0.4`, Req `0.6.x`; align Ecto/Ecto SQL to `3.14.x` so Decimal resolves to `3.0.0+`.
3. **ScrypathOps web/client graph — medium/high runtime risk.** Resolve the shared fixed minima plus Bandit `1.12.1`, Phoenix `1.8.9`, Phoenix LiveView `1.1.33`, Postgrex `0.22.4`, Swoosh `1.26.3`, and `Req ~> 0.6.1`.
4. **Ecommerce web/client graph — medium/high runtime risk.** Repeat the Ops-compatible fixed-minimum resolution separately because ecommerce is the browser E2E app and mounts ScrypathOps by path dependency.

### Verification gates after each batch

| Batch | Required gates |
| --- | --- |
| Root core client | `mix deps.get`; `mix compile --warnings-as-errors`; `mix test --exclude integration --exclude docs_contract`; `mix verify --exclude integration`; `mix verify.phase11`; `mix verify.phase99` |
| Legacy Phoenix example | `cd examples/phoenix_meilisearch && mix deps.get && mix test`; then root `mix test --exclude integration --exclude docs_contract` |
| ScrypathOps | `mix verify.opsui` from root; then the root required gates above |
| Ecommerce | `mix deps.get`; `cd examples/scrypath_ecommerce && mix deps.get && mix e2e.prepare`; run the advisory `phase105-e2e` CI lane/documented browser checks when services are available |

## Unresolved reachability questions

- Which Mint response-parsing paths can receive attacker-controlled upstream responses?
- Which Req call options/configuration enable decompression exposure in deployed clients?
- Which Swoosh adapter is selected in every deployed environment, and does any use the affected adapter path?
- Are Postgrex notification or stream/comment paths introduced outside the current source scan?

These questions lower confidence only where stated above; they do not remove advisory risk. Remediation remains pending.
