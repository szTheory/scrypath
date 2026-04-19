# Phase 29: Golden path and adoption documentation - Context

**Gathered:** 2026-04-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **ADPT-01..03** through documentation (and doc-only cross-links): one **linear golden path** from dependency install through a **working** `Scrypath.search/3` with **inline** sync; **decision-ready** documentation for **inline vs Oban vs manual**; **consistent** upgrade / semver / verify messaging across README, CHANGELOG pointers, and `docs/releasing.md`.

**Non-goals:** New search features, new sync modes, new examples beyond what existing `examples/phoenix_meilisearch` already supports for storytelling.

</domain>

<decisions>
## Implementation Decisions

### 1. Golden path spine (ADPT-01) — where the narrative lives

**Research summary**

| Approach | Pros | Cons | Ecosystem analogy |
|----------|------|------|-------------------|
| README as full linear story | Single file on GitHub; no navigation | README bloat; duplicates guides; hard to keep Meili + app steps in sync with `examples/` | Searchkick packs install + model + `reindex` + query into README — works but README becomes a second manual |
| README only + scattered guides | Reuses existing `guides/getting-started.md` | ADPT-01 asks for **one** path — readers still jump across files | Phoenix/Ecto norm is README + `guides/` — good split, but needs an explicit **ordered** spine |
| **Dedicated golden-path guide + short README** | One bookmarkable doc; README stays scannable; matches “library + guides” idiom | One more file to maintain | Laravel Scout: **Installation** then deep sections — framework docs assume a **canonical order**; Elixir libs (Ecto, Req) keep README short and push depth to guides |

**Footguns from other stacks**

- **Searchkick:** “Add gem → model → `reindex` → search” is clear, but **implicit callbacks** and “magical” sync are footguns Scrypath explicitly avoids — docs must keep **`sync_record` explicitness** visible in the golden path, not buried.
- **Scout:** **Queueing** called out immediately after install — lesson: golden path should **name** when you are on “happy path inline” vs “next step: queue for production” without implying Oban is required for first search.

**Locked decision — D-01**

- Add a **single linear guide** (recommended filename: `guides/golden-path.md`) that is the **canonical ADPT-01 narrative**: ordered checklist from `mix.exs` dep through Meilisearch available → minimal app config → `use Scrypath` schema → **one** context function with `sync_mode: :inline` → **`Scrypath.search/3`** returning hydrated records (IEx or minimal handler is fine; link to Phoenix walkthrough for UI depth).
- **README:** Keep positioning + **one** tight “Quick Path” teaser (or slim it slightly); add a prominent **“Start here: Golden path”** link as the **primary** entry for new adopters. Do **not** duplicate the full golden path in README.
- **`guides/getting-started.md`** remains the **conceptual** “three pieces” overview; the golden path guide **links backward** to it for readers who want theory first, but the default onboarding is **golden path → deep guides**.

### 2. Runnable Meilisearch and environment (golden path prerequisites)

**Research summary**

| Approach | Pros | Cons |
|----------|------|------|
| Docs only “install Meilisearch from upstream” | No drift vs Meili release cadence | Highest drop-off; versions mismatch CI/example |
| **Repo-aligned minimal runbook** (compose or one-liner) + upstream link | Matches `examples/phoenix_meilisearch` (ports, image tag, env vars); reproducible; idiomatic for Elixir teams using Docker | Must update when CI image pin moves |

**Locked decision — D-02**

- Golden path includes a **short, copy-pasteable** “bring up Meilisearch” section aligned with **`examples/phoenix_meilisearch/compose.yaml`** (image tag, default URL, optional Postgres if the path uses the example — keep **minimal**: Meilisearch + env vars sufficient if the narrative is search-only from fixture/IEx).
- State **`SCRYPATH_MEILISEARCH_URL`** (or documented equivalent) explicitly; link to **example README** for “full Phoenix + Postgres + smoke” depth (Phase 30 can extend automation story).
- Upstream Meilisearch docs linked as **“production hardening”**, not as the only way to get a binary running for the first tutorial.

### 3. Sync-mode comparison depth (ADPT-02)

**Research summary**

| Approach | Pros | Cons |
|----------|------|------|
| Expand README with full Oban/manual wiring | One scan for decision makers | Blends **product decision** with **operator manual**; README conflicts with `guides/sync-modes-and-visibility.md` |
| **README = decision matrix + links; guide = mechanics + Phoenix honesty** | Scout-style: **queueing** is prominent but not mixed with first query; matches Scrypath’s “accepted work ≠ visible” thesis | Requires disciplined cross-links |

**Footguns**

- **Scout:** Saving always syncs (or queues) — easy to assume “success means searchable.” Scrypath’s differentiator is **honesty** — README table stays, but golden path uses **inline** only; Oban/manual introduced as **“when you outgrow the tutorial”** with a single link into the sync guide.
- **Laravel:** Queue docs sit **right after** install — mirror that **ordering in the golden path’s closing section** (“Next: pick sync mode for production”), not in the first-run steps.

**Locked decision — D-03**

- **README:** Keep the **compact** mode table + **3–5 lines** on “pick mode by constraint” + link **`guides/sync-modes-and-visibility.md`** as the **authority** for semantics, recovery, and Phoenix implications.
- **`guides/sync-modes-and-visibility.md`:** Owns **full** narrative for `:inline` / `:oban` / `:manual`, operator visibility, and “what success in the controller/LiveView really means.”
- Golden path ends with **inline** only; a **“What’s next”** subsection points to sync guide + Oban docs **without** implementing Oban in the first-run doc.

### 4. Versioning, verify tasks, and changelog consistency (ADPT-03)

**Research summary**

| Approach | Pros | Cons |
|----------|------|------|
| Repeat full verify matrix in README | Visible in one place | Drifts from `docs/releasing.md`; contradicts Release Please flow |
| **Canonical `docs/releasing.md`; README summary + links; CHANGELOG user-facing** | Single source for gates; README stays honest; matches existing repo structure | Readers must click once for detail |

**Footguns**

- **Searchkick**-style versioned README branches per ES major — avoid duplicating that complexity in README; use **semver + verify task names** as the contract, documented once.
- **Hex / mix.exs vs README `{:scrypath, "~> x.y"}` drift** — footgun today; golden path and README should use a **`~>` compatible with current `mix.exs @version`** (or explicit “see `mix.exs` for exact floor”) so first copy-paste compiles.

**Locked decision — D-04**

- **`docs/releasing.md`:** Canonical for **Release Please**, `mix verify.phase11`, post-publish checks, parity — **no competing duplicate tables** elsewhere.
- **README:** Short **“Versioning & upgrades”** block: semver posture in plain language, **what verify protects**, link to **`docs/releasing.md`** and **CHANGELOG**.
- **CHANGELOG:** Remains **human-facing** release notes; **does not** replace releasing doc for maintainer gates.
- **Golden path:** Uses dependency snippet that **matches** current published line (coordinate with `mix.exs` when editing).

### 5. Ecto-only / API-only adopters

**Research summary**

| Approach | Pros | Cons |
|----------|------|------|
| Second full parallel tutorial | Inclusive | Scope creep; duplicates Phoenix example |
| **Phoenix-first golden path + explicit “Ecto without Phoenix” fork** | Matches majority adoption; respects `AGENTS.md` Ecto-first; API-only covered in **one subsection** | Non-Phoenix readers scroll past Phoenix links |

**Locked decision — D-05**

- Golden path is **Phoenix-oriented** (links to existing Phoenix guides for controllers/LiveView).
- Add **`## Ecto without Phoenix (API-only)`** (or equivalent): same **context-owned** `Scrypath.sync_record` / `Scrypath.search` pattern, **no** `MyAppWeb` — point to **`examples/phoenix_meilisearch`** as API-shaped reference or minimal Plug pipeline doc if present; avoid a second full tutorial.

### Cohesion principles (apply while editing)

- **One spine, many ribs:** `guides/golden-path.md` is the spine; README + getting-started + sync guide + releasing are ribs — **cross-link, don’t fork** content.
- **Explicit beats magic:** Every comparison to Scout/Searchkick should reinforce **explicit `sync_record` + `sync_mode`** in the first hour experience.
- **Operational honesty is UX:** First search success must not imply **atomic** DB+search or **immediate** visibility for queued/manual paths — language matches existing `guides/sync-modes-and-visibility.md`.

### Claude's Discretion

- Exact filename for the golden path guide if `golden-path.md` collides with marketing language — alternatives: `guides/first-search.md`, `guides/adoption-golden-path.md`.
- Whether the golden path uses **IEx-only** search proof vs **minimal HTTP route** in the doc (prefer whichever keeps the doc shortest while still showing **`Scrypath.search/3`**).

### Folded Todos

None (todo tooling unavailable in this session).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/REQUIREMENTS.md` — ADPT-01..03, v1.6 out-of-scope table, phase success criteria
- `.planning/ROADMAP.md` — Phase 29 row
- `.planning/PROJECT.md` — v1.6 adoption intent; core value

### Existing docs to edit or extend

- `README.md` — Quick Path, wayfinding, sync table, installation
- `guides/getting-started.md` — three-piece mental model
- `guides/sync-modes-and-visibility.md` — mode semantics and Phoenix implications
- `guides/phoenix-walkthrough.md` — deeper UI path (link target)
- `docs/releasing.md` — canonical release and verify contract
- `CHANGELOG.md` — adopter-facing release history
- `examples/phoenix_meilisearch/README.md` — compose, ports, smoke env vars

### Prior phase context (tone, not scope)

- `.planning/phases/028-operator-cli-docs-verify-gate/028-CONTEXT.md` — cross-link over duplication; explicit CLI↔API naming

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`examples/phoenix_meilisearch`:** Compose stack (Postgres + Meilisearch v1.15), `SCRYPATH_MEILISEARCH_URL`, `SCRYPATH_EXAMPLE_INTEGRATION`, `scripts/smoke.sh` — canonical **real** integration shape to reference from docs
- **`guides/getting-started.md`:** Already encodes context-owned search + `sync_mode: :inline` in `publish_post/2`

### Established patterns

- **Context boundary** for `Scrypath.search/3` and `Scrypath.sync_record/3` — golden path must not show controller-centric wiring as the primary pattern
- **Explicit `sync_mode`** — tutorial defaults to `:inline`; other modes deferred to sync guide

### Integration points

- README “Phoenix Wayfinding” list becomes the **secondary** navigation after the golden path link is added
- `mix.exs` `@version` / Hex release line must stay aligned with README dependency snippet (ADPT-03 hygiene)

</code_context>

<specifics>
## Specific Ideas

- Ecosystem benchmarks: **Laravel Scout** (install → queueing early → driver prerequisites), **Searchkick** (minimal getting started, strong footgun surface if callbacks implied), **Scout queueing warnings** — inform ordering and honesty of onboarding copy, not API design.
- User requested a **single coherent** recommendation set with **no** optional decision matrix — the decisions above are intended to be implemented as-written unless planning discovers a hard conflict.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 30:** Additional consumer-shaped smoke / Oban-backed example depth — explicitly out of scope for Phase 29 doc work unless a plan ties only **links** to existing artifacts.
- **Second runnable example** beyond `examples/phoenix_meilisearch` — not required for ADPT-01 if golden path links to it.

### Reviewed Todos (not folded)

None.

</deferred>

---

*Phase: 029-golden-path-adoption-documentation*
*Context gathered: 2026-04-18*
