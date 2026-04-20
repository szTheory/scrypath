# Stack Research

**Domain:** Phoenix operator admin UI over Scrypath (Meilisearch-first)
**Researched:** 2026-04-20
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir | 1.17+ (project floor) | Same runtime as Scrypath consumers | Matches library support; no second language for maintainers |
| Phoenix | 1.7+ typical consumer | HTTP + LiveView host for OPSUI | Idiomatic for target audience; LiveView fits dashboards |
| Phoenix LiveView | ships with Phoenix | Server-rendered interactive UI | Low JS surface for ops screens; matches “conventional Phoenix” goal |
| Scrypath (path dep) | workspace / Hex | Search + sync operator APIs | UI is a thin client over existing functions and structs |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix HTML / HEEx | with Phoenix | Templates and components | All surfaces |
| Telemetry / :telemetry_poller (optional) | ecosystem standard | If UI reads live aggregates | Only when not duplicating metrics product; prefer Scrypath-owned events per SRE doc |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| mix phx.server | Local OPSUI dev | Same env vars / Meilisearch URL patterns as integration examples |
| ExUnit + Phoenix.LiveViewTest | Regression safety | Satisfies OPSUI-10 without brittle full-browser CI for core |

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| LiveView | Dead controllers + Alpine | If team bans WS; loses server-driven state simplicity for dashboards |
| Example / sibling app | LiveDashboard-only extension | Insufficient for federation-honest custom layouts and JTBD flows |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Shipping OPSUI inside `lib/scrypath` on Hex | Widens package boundary and dependency graph for all consumers | Dedicated `apps/ops_ui` or separate package per OPSUI-09 |
| High-cardinality dashboard tags | Matches anti-patterns in `docs/search-backend-sre.md` | Aggregate by `schema`, `index`, `sync_mode`, `reason_class` |

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| OPSUI app | `scrypath` on same OTP/Elixir floor as repo | CI matrix should include at least one consumer compile |

## Sources

- `.planning/PROJECT.md` — packaging and core value
- `docs/search-backend-sre.md` — telemetry cardinality and event prefixes
- Phoenix / LiveView official docs — UI conventions (general patterns)

---
*Stack research for: Scrypath v1.10 OPSUI*
*Researched: 2026-04-20*
