# Stack Research

**Domain:** Elixir OSS library (`scrypath`) + optional in-repo Phoenix operator app (`scrypath_ops`) for Meilisearch-backed search sync and inspection.

**Researched:** 2026-04-21 (milestone **v1.14** — B1 + B2)

**Confidence:** HIGH for current repo stack; MEDIUM for optional playbook persistence choices.

## Recommended Stack

### Core Technologies (unchanged)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir / OTP | 1.17+ / OTP 26+ | Library + OPSUI runtime | Project support floor per **AGENTS.md** |
| Ecto | current | Schema projection, sync | Core product surface |
| Meilisearch | HTTP API | Public v1 backend | Positioning and shipped adapter |
| Phoenix LiveView | current in `scrypath_ops` | Operator UI | Already validated **OPSUI-07** |

### Supporting libraries (v1.14 scope)

| Library | Purpose | When to Use |
|---------|---------|-------------|
| **Postgres (Ecto SQL)** | Optional persistence for saved playbooks | Only if multi-user / durable playbooks are in-scope for **OPSUI-FUT-01** MVP; otherwise prefer **file export/import** or **local session** to limit ops burden |
| **Jason** (already transitive) | Serialize playbook payloads (query + opts) | Any saved-query feature |
| **Existing `SearchPlayground` adapter** | Swap real `Scrypath` vs stub in test | Keep; extend behaviour behind behaviour, not global singletons |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `mix verify.opsui` | Contributor spine for OPSUI | **v1.12** — extend when playbooks add LiveView paths |
| `LiveViewTest` | Regression on critical flows | **OPSUI-10** — add cases for save/load playbook |

## What NOT to Add (v1.14)

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| New heavy JS build pipeline | OPSUI stays Phoenix-native | LiveView + existing components |
| Meilisearch cluster agent inside OPSUI | **OPSUI-FUT-02** explicitly out | Keep HTTP to configured host only |
| Core Hex dependency on Phoenix | Breaks library boundary | All playbook UI in **`scrypath_ops`** |

## Stack Patterns by Variant

**If playbook MVP is “single operator, same machine”:**

- JSON export/import of playground form state + metadata; no DB migration in `scrypath_ops` initially.

**If playbook must be “shared across team members” (original FUT-01 wording):**

- Ecto schema + migrations in **`scrypath_ops`** only; authz aligned with **OPSUI-08** (who can read/write playbooks).

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `scrypath` (Hex) | Consumer Phoenix apps | Playbooks do not ship in artifact |
| `scrypath_ops` | Path dep / monorepo | May depend on local `scrypath` |

## Sources

- [Searchkick](https://github.com/ankane/searchkick/) — console `reindex`, async promotion patterns (analogy: operator repeatability, not API copy).
- [Meilisearch Laravel Scout guide](https://www.meilisearch.com/docs/guides/laravel_scout) — docs-first testing and Meilisearch option pass-through (analogy: keep wire options explicit in saved payloads).
- Repo: **`scrypath_ops/lib/scrypath_ops/search_playground.ex`**, **`scrypath_ops/lib/scrypath_ops_web/live/search_live.ex`**.

---
*Stack research for: Scrypath v1.14 (B1+B2)*
