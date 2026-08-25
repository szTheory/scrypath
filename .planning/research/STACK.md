# Stack Research

**Domain:** v1.36 dependency-security remediation across four independent Mix projects
**Researched:** 2026-08-21
**Confidence:** HIGH for the recorded advisory minima and local dependency graph; MEDIUM for migration impact; LOW only for the unresolved Postgrex publication discrepancy.

## Recommendation

Treat this as four isolated dependency-resolution batches, not a platform upgrade. Change direct constraints only where a current range can still select an advisory-affected release or cannot select the fixed line. Regenerate only the batch's own lockfile, resolve to the recorded fixed-compatible versions, run that batch's gates, then commit before proceeding.

The sole unavoidable source-compatibility change is Req 0.5 to 0.6.1. Req 0.6 deliberately disables automatic response decompression and stops auto-decoding compressed/archive/CSV bodies; Scrypath's JSON Meilisearch requests remain supported, but any caller relying on automatic compressed/archive/CSV decoding must explicitly opt in. The legacy Phoenix example also needs a coordinated Ecto/Ecto SQL 3.14 and Decimal 3 transition; do not attempt a Decimal-only lockfile edit.

## Exact Batch Plan

| Batch / project | Manifest changes required | Resolve / lock to at least | Why this is the smallest complete change | Must remain unchanged |
|---|---|---|---|---|
| 1. Root `scrypath` | `req: "~> 0.5"` → `"~> 0.6.1"`; `plug: "~> 1.18"` → `"~> 1.19.5"` (test-only floor) | Req `0.6.1`, Mint `1.9.3`, hpax `1.0.4`, Plug `1.19.5` | Req 0.6.1 is the first release fixing both recorded Req advisories. The new direct floors prevent a later fresh resolution returning to an affected release; Mint/hpax are correctly transitive through Req → Finch → Mint. | Keep Ecto, Oban, public Scrypath APIs, transport choices, and the test-only scope of Plug unchanged. Do not move Req to 0.7/0.8 RC or Plug to 1.20. |
| 2. `examples/phoenix_meilisearch` | `phoenix: "~> 1.8.5"` → `"~> 1.8.9"`; `ecto_sql: "~> 3.13"` → `"~> 3.14.0"`; `bandit: "~> 1.5"` → `"~> 1.12.1"`; `postgrex: ">= 0.0.0"` → a verified fixed `0.22.x` floor; no direct Req declaration is needed because root is a path dependency | Bandit `1.12.1`, Phoenix `1.8.9`, Plug `1.19.5`, Mint `1.9.3`, hpax `1.0.4`, Req `0.6.1+`, Ecto/Ecto SQL `3.14.x`, Decimal `3.0.0+`; Postgrex target needs publication verification (see below) | Ecto 3.13.5 requires Decimal `~> 2.0`; the checked-in root lock proves the Ecto 3.14 line accepts Decimal 3. Bandit 1.12.1 also covers the newer fragmented-WebSocket advisory, so it is the planned common server floor rather than the older 1.11.1-only remedy. | Keep Phoenix 1.8 (not 1.9), Oban 2.x, path dependency on root Scrypath, endpoint/router structure, and demo semantics. Do not add a direct Req merely to force a transitive package. |
| 3. `scrypath_ops` | `req` → `"~> 0.6.1"`; `phoenix` → `"~> 1.8.9"`; `bandit` → `"~> 1.12.1"`; `phoenix_live_view` → `"~> 1.1.33"`; `swoosh` → `"~> 1.26.3"`; `postgrex` → a verified fixed `0.22.x` floor | Shared Req/Mint/hpax/Plug floors above; Bandit `1.12.1`; Phoenix `1.8.9`; LiveView `1.1.33`; Swoosh `1.26.3`; fixed Postgrex `0.22.x` | Each listed direct floor makes the independently resolved app durable. Its production Swoosh client is `Swoosh.ApiClient.Req`, so the Req transition is a deployed integration point, not a dev-only update. | Preserve `Bandit.PhoenixAdapter`, LiveView 1.1, the mountable Ops contract, local mailer/test adapters, assets, and UI behavior. Do not upgrade Phoenix 1.9, LiveView 1.2, Swoosh 1.27, or Bandit beyond the security floor. |
| 4. `examples/scrypath_ecommerce` | Apply the same direct floors as Ops: Req `~> 0.6.1`, Phoenix `~> 1.8.9`, Bandit `~> 1.12.1`, LiveView `~> 1.1.33`, Swoosh `~> 1.26.3`, and verified fixed Postgrex `0.22.x` | Same Ops-compatible minima, resolved in this example's own lockfile | This project has its own graph and browser E2E surface; the path-mounted `scrypath_ops` does not make its lockfile equivalent to Ops's lockfile. | Preserve its `scrypath_ops` path dependency, E2E routes/tenant behavior, Phoenix 1.8 and LiveView 1.1 line. Do not combine this batch with Ops. |

## Fixed-Compatible Version Matrix

| Package | Recorded advisory-clearing minimum | Constraint to declare where direct | Compatibility / release-note action |
|---|---:|---|---|
| Req | `0.6.1` | `~> 0.6.1` in root, Ops, ecommerce | **Verified:** 0.6.0 removed automatic archive/CSV decoding; 0.6.1 disables automatic decompression unless `compressed: true`. Audit `Req.new/1` and `Req.request/2` call sites for an intentional reliance on those old defaults. Current Scrypath calls are JSON Meilisearch requests. |
| Mint | `1.9.3` | transitive; no direct declaration | Finch 0.21/0.22 accepts the Mint 1.x line. Verify the fresh solver selects 1.9.3+, not merely 1.9.0–1.9.2. |
| hpax | `1.0.4` | transitive; no direct declaration | Pulled by Mint and Bandit. Verify all four lockfiles select 1.0.4+. |
| Plug | `1.19.5` | Root: `~> 1.19.5`; web apps: transitive under Phoenix/Bandit/LiveView | Preserve Plug 1.19 within the maintenance scope. The root direct Plug dependency remains `only: :test`. |
| Bandit | `1.12.1` | `~> 1.12.1` in three web projects | **Verified:** 1.12.1 fixes fragmented WebSocket-frame DoS. Its 1.12.0 release also changed timeout separation via Thousand Island 1.5; exercise endpoints, WebSocket/LiveView, and E2E lifecycle rather than changing Bandit options proactively. |
| Phoenix | `1.8.9` | `~> 1.8.9` in three web projects | Remain on 1.8. Do not adopt 1.9; Phoenix's current changelog separately calls out rolling-deploy sequencing for 1.9, which is outside this remediation. |
| Phoenix LiveView | `1.1.33` | `~> 1.1.33` in Ops and ecommerce | **Verified:** 1.1.33 fixes redirect validation around ASCII tab/LF/CR. Keep LiveView 1.1, and regression-test mounted redirects/navigation. |
| Postgrex | triage states `0.22.4` | Do not write the constraint until Hex availability is confirmed | **Conflict:** the current official Hex API exposes `0.22.3` as the newest stable 0.22 release and returns no listed 0.22.4, while the authoritative local triage says `0.22.4` is the fixed minimum. This is a release-publication/advisory-feed mismatch, not permission to select 1.0.0-rc. Verify the EEF advisory record and Hex publication immediately before implementation; use the first published 0.22 release that the advisory marks fixed. |
| Swoosh | `1.26.3` | `~> 1.26.3` in Ops and ecommerce | **Verified:** release notes identify a Microsoft Graph sender-path injection fix. Preserve the configured Req API client and current mailer adapter configuration. |
| Ecto / Ecto SQL | `3.14.x` | Legacy example: `ecto_sql ~> 3.14.0`; resolver must select matching Ecto `3.14.x` | Ecto 3.14 requires Decimal `~> 3.0`; this is the intentional alignment that fixes the Decimal issue. Pin the minor line, not Ecto 3.15+. |
| Decimal | `3.0.0` | transitive through Ecto 3.14 | **Verified:** Decimal 3 defaults to decimal128 bounds and rejects formerly unbounded parse/cast values. Existing ordinary Ecto data flows should work, but test any unusually large decimal literals/fixtures and do not restore unbounded parsing absent a demonstrated need.

## Integration Points to Test

1. Root: `Scrypath.Meilisearch.Client` uses `Req.request/2` and `Req.new/1`; prove standard JSON request/response and error normalization after Req's changed decode/decompression defaults.
2. Phoenix example: HTTP/2, ordinary request parsing, endpoint startup, Ecto Repo migrations/queries, and Meilisearch smoke tests. The example inherits Req through the local root path dependency.
3. Ops: endpoint/LiveView WebSocket lifecycle, mounted redirects, Swoosh configured with `Swoosh.ApiClient.Req`, and `mix verify.opsui`.
4. Ecommerce: preserve mounted Ops behavior, tenant-aware E2E preparation, and browser flow proof after its independent solver run.

## What NOT to Use

| Avoid | Why | Use Instead |
|---|---|---|
| Lockfile-only changes where a direct range admits the vulnerable line | A clean install can resolve back to the affected release. | Raise the direct lower bound listed above, then regenerate the batch lockfile. |
| Package-head upgrades (Req 0.7+/0.8 RC, Phoenix 1.9, LiveView 1.2, Plug 1.20, Swoosh 1.27, Bandit newer than needed) | Expands behavioral and compatibility risk without serving the recorded advisories. | Recorded patched minima and their bounded minor-line constraints. |
| A Decimal-only upgrade in the legacy example | Ecto 3.13 requires Decimal `~> 2.0`; it cannot provide the needed 3.x resolution. | Coordinated Ecto/Ecto SQL 3.14.x plus Decimal 3.x resolution. |
| Postgrex 1.0.0 RC as a shortcut | It is a prerelease and is outside the recorded fixed-compatible maintenance plan. | The verified patched stable 0.22.x release once the 0.22.4 discrepancy is resolved. |

## Version Compatibility

| Package A | Compatible With | Notes |
|---|---|---|
| Req `0.6.1` | Finch 0.21/0.22, Mint `1.9.3`, Plug `1.19.5` | Req's release notes require behavior review for decompression/decoder defaults; no API redesign is required for current JSON use. |
| Ecto / Ecto SQL `3.14.x` | Decimal `3.x`, Postgrex `0.22.x`, Phoenix Ecto 4.7 | Root lock already demonstrates the Ecto 3.14 / Decimal 3 pairing; move the legacy example together. |
| Phoenix `1.8.9` | LiveView `1.1.33`, Bandit `1.12.1`, Plug `1.19.5` | This is a contained 1.8/1.1 web-stack resolution; test behavior but do not cross major/minor framework lines. |
| Swoosh `1.26.3` | Req `0.6.1` | Swoosh's declared Req compatibility includes 0.6; retain the configured `Swoosh.ApiClient.Req`. |

## Sources

- Local authoritative evidence: `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md` and `260816-tzr-RESEARCH.md` — recorded affected graphs, advisory minima, and batch sequence. **HIGH**.
- [Req 0.6.0 release](https://github.com/wojtekmach/req/releases/tag/v0.6.0) and [Req 0.6.1 release](https://github.com/wojtekmach/req/releases/tag/v0.6.1) — decoder and decompression migration behavior. **HIGH**.
- [Bandit changelog](https://github.com/mtrudel/bandit/blob/main/CHANGELOG.md) — 1.12.0 timeout/Thousand Island change and 1.12.1 WebSocket DoS fix. **HIGH**.
- [Phoenix LiveView 1.1.33 release](https://github.com/phoenixframework/phoenix_live_view/releases/tag/v1.1.33), [Swoosh 1.26.3 release](https://github.com/swoosh/swoosh/releases/tag/v1.26.3), and [Decimal 3.0.0 release](https://github.com/ericmj/decimal/releases/tag/v3.0.0) — security fixes and migration-sensitive changes. **HIGH**.
- Official [Hex package metadata](https://hex.pm/) for published versions and dependency declarations, queried 2026-08-21. **HIGH**, except it exposes the unresolved Postgrex `0.22.4` discrepancy described above.

---
*Stack research for: Scrypath v1.36 dependency security remediation*
*Researched: 2026-08-21*
