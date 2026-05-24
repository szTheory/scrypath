# Milestone candidates — developer-first roadmap stack

**Purpose:** Prioritized themes for **`/gsd-new-milestone`** — **onboarding + QoL** for people using and contributing to Scrypath; **avoid busywork** and maintainer-only work masquerading as product.  
**Last reviewed:** 2026-05-24 — **v1.22** shipped and the repo-grounded done-ness assessment puts Scrypath at roughly **86% done** for its stated scope. The canonical portfolio posture is still the **v1.19** readiness verdict: seek broader outside production adoption on the defended surface, with external validation still pending. The canonical verdict lives in **`milestones/v1.19-MILESTONE-AUDIT.md`**.

**Reconciliation note:** the `v1.20` archive says `Scrypath.SearchModule` shipped, but the current checkout does not expose that layer or its guide. Treat that as a live gap to reconcile before assuming archive and code are perfectly aligned.

---

## Where things stand

### Admin / operator UI

**Shipped:** optional in-repo **`scrypath_ops`** (LiveView), outside the core Hex package — **v1.10** (**OPSUI-01..10**), **v1.11** operator shell polish (**OPSUI-01..07** sense in **`milestones/v1.11-{REQUIREMENTS,ROADMAP}.md`**). **v1.10** archive: **`milestones/v1.10-{REQUIREMENTS,ROADMAP}.md`**.

**Intentionally not in v1.10 / still future:**

- **OPSUI-FUT-01** — editable saved queries / team playbooks (`milestones/v1.10-REQUIREMENTS.md` § v2+).
- **OPSUI-FUT-02** — Meilisearch “vendor dashboard” parity (same section).
- **Phase 47 deferred ideas** — full browser E2E everywhere, visual regression as default CI gate, real Meilisearch inside **`scrypath_ops`** CI, exhaustive table matrices (`phases/47-verification-hardening/47-CONTEXT.md` `<deferred>`).

So: **honest operator visibility over library APIs — done for v1.** Deeper productized admin (saved playbooks, cluster observability, heavy E2E) remains **future**.

### QoL / DX vs “Searchkick-level” expectations

The library has strong **Ecto-native indexing + Meilisearch sync modes**, **search / facets / federation**, **per-query tuning pipeline + runtime**, **operator Mix tasks + drift tooling**, **adoption guides + doc contracts**, and **OPSUI** for triage and inspection.

The preserved branch **`salvage/20260508-151407-main-reconcile`** is intentionally not part of this roadmap. It is a quarantine snapshot from the `main` reconciliation, not an implied upcoming milestone.

**Gaps people still reasonably expect** (none implied “done” by **v1.11**):

| Theme | Why it still matters | Where it shows up in notes |
|--------|----------------------|----------------------------|
| **Consumer “first hour” + ongoing DX** | Golden path exists; remaining leverage is **example parity**, **support-contract clarity**, **verify discoverability**, and a few evidence-backed papercuts | **v1.6** arc + **`.planning/PROJECT.md`** adoption narrative |
| **One contributor verify spine for OPSUI** | Contributors should not hunt five docs for the right **`mix verify.*`** subset | **47-CONTEXT** D-04 sense |
| **OPSUI + real backend in CI** | Deferred on purpose; library integration jobs carry Meilisearch truth | **47-CONTEXT** `<deferred>` |
| **Planning / maintainer tooling friction** | Milestone archival pain — **helps maintainers**, not Hex consumers | **`.planning/RETROSPECTIVE.md`** |
| **Audit-open hygiene** | Stub **`quick_task`** rows + UAT noise — **morale / noise**, low product leverage unless it misleads | **`.planning/STATE.md`** § Deferred Items; **`.planning/MILESTONES.md`** “Known deferred” |
| **Product boundaries still explicit** | Multi-backend, vectors/hybrid/personalization stay **out of scope** until pressure | **`.planning/PROJECT.md`** Out of Scope |

---

## Ranked backlog (developer PoV — pick off in order)

Order = **default** pull sequence for **`/gsd-new-milestone`**. Merge adjacent tiers only when one milestone naturally covers both.

### Tier A — Highest leverage (“library great” for devs) — shipped **v1.12**

| # | Theme | Notes |
|---|--------|--------|
| **A1** | **Consumer onboarding + day-to-day QoL** | **Done (v1.12)** — golden path ↔ README contracts, pitfalls, actionable errors |
| **A2** | **Single contributor entry for optional OPSUI** | **Done (v1.12)** — root **`mix verify.opsui`** + docs/CI locks |

### Tier B — Highest-leverage product gaps if feature work reopens

| # | Theme | Notes |
|---|--------|--------|
| **B1** | **Related-data and dependency propagation** | Biggest correctness gap for real SaaS apps once documents include tags, ownership, counts, or joined fields |
| **B2** | **Tenant-safe search access story** | Biggest credibility gap for B2B Phoenix adopters; prefixes are not the same thing as authorization |
| **B3** | **Composition and real-app depth over the query toolkit** | **Done in v1.22** — keep here only as historical context so future planning does not reopen the same wedge accidentally |
| **B4** | **High-cardinality facet value search** | Useful for larger catalogs, but behind the three gaps above |
| **B5** | **Autocomplete / suggestion flows** | Valuable later, but should not outrun correctness and SaaS-boundary work |

### Tier C — Defer until a failure mode is proven

| # | Theme | Notes |
|---|--------|--------|
| **C1** | **Meilisearch inside `scrypath_ops` CI** | Only if stub + LiveView + contracts **miss** wire/regression you actually hit |
| **C2** | **Playwright (or similar) on 1–2 flows** | Only if the above still misses **user-visible** breakage |

### Tier D — Maintainer / planning hygiene (not “product”)

| # | Theme | Notes |
|---|--------|--------|
| **D1** | **GSD milestone archive / phases path reliability** | Reduces **your** planning friction; **near-zero** Hex consumer onboarding impact — separate track or tiny slice when it blocks weekly |
| **D2** | **Retire `quick_task` stub rows / quiet `audit-open`** | **Busywork** unless CI or new contributors are misled |
| **D3** | **Release-only credential / live-proof follow-through** | Keep the **v1.1** carry-forward visible as maintainer ops work: rerun live verification when `SCRYPATH_MEILISEARCH_URL` is reachable and rerun Hex dry-run when a publisher-scoped `HEX_API_KEY` exists; do not promote this into a consumer milestone by default |

### Tier E — Current default pull before any new feature milestone

| # | Theme | Notes |
|---|--------|--------|
| **E1** | **Outside-adopter evidence and support-truth reconciliation** | **Active as v1.23** — reconcile current proof/support truth with the tree, review real adopter attempts, and use that evidence to decide whether Scrypath should stop soon or open one final wedge |

### Still explicit strategy (unchanged)

| # | Theme | Notes |
|---|--------|--------|
| **—** | **`.planning/PROJECT.md` Out of Scope** | Multi-backend, hybrid/personalization, etc. — only with **adoption evidence** |

---

## Suggested sequencing (one coherent thread)

| Step | Pull from | Rationale |
|------|------------|-----------|
| 1 | **A1** | **Shipped v1.12** |
| 2 | **A2** | **Shipped v1.12** |
| 3 | **v1.13** (**POLISH-***) | Voice + Hex narrative + contributor entry (**`milestones/v1.13-REQUIREMENTS.md`**) |
| 4 | **E1** | Current active pull after `v1.22`; do not reopen feature work casually |
| 5 | **B1** | Highest-leverage correctness work if real product work reopens |
| 6 | **B2** | SaaS boundary clarity after related-data pressure is understood |
| 7 | **B4**, then **B5** | Catalog depth and delight features only after the bigger gaps close |
| Parallel | **D*** | When annoyance cost exceeds fix cost — do not headline a consumer milestone here |

---

## How to use this file

1. Before **`/gsd-new-milestone`**, ask six questions before picking a theme:
   - Which adopter flow gets better?
   - What truth can the app honestly say after a write returns?
   - What is the tenant boundary?
   - How do related-data changes trigger reindex or fan-out?
   - What operator recovery path proves this flow is honest?
   - Is this still above the post-`v1.19` diminishing-returns line?
2. Optionally split strong themes into **`.planning/seeds/SEED-*.md`** so **`/gsd-new-milestone`** auto-offers matching seeds (see **`gsd-plant-seed`**).
3. After each shipped milestone, **update this file** — what landed, what moved, and whether the repo is now actually near “stop soon” territory.

---

*Sources: **PROJECT.md**, **STATE.md**, **MILESTONES.md**, **RETROSPECTIVE.md**, **ROADMAP.md**, **CONTRIBUTING.md**, **README.md**, **examples/phoenix_meilisearch/README.md**.*
