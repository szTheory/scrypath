# Milestone candidates — developer-first roadmap stack

**Purpose:** Prioritized themes for **`/gsd-new-milestone`** — **onboarding + QoL** for people using and contributing to Scrypath; **avoid busywork** and maintainer-only work masquerading as product.  
**Last reviewed:** 2026-05-31 — **v1.29** shipped (contract repair and proof hardening). Repo-grounded reassessment keeps Scrypath at **~96–98% done** for its stated Meilisearch-first, Ecto-native, Phoenix-friendly scope. The last planned product wedges — related-data propagation, tenant-safe search, facet value search, adopter contract hardening, realistic E2E proof, and bounded contract repair — are shipped. Default posture is **release, maintenance, support truth, proof stability, outside-adopter evidence, and otherwise stop**. If feature work reopens, it should require a concrete production bug, reviewed outside-adopter evidence, or an explicit strategic wedge.

**Reconciliation note:** the `v1.20` archive says `Scrypath.SearchModule` shipped, but the current checkout does not expose that layer or its guide. This was resolved as archive-correction on 2026-05-27 and must not drive future feature selection.

**Post-v1.29 closeout note:** related-data fan-out shipped in v1.24, and v1.29 repaired normal `use Scrypath, fan_outs:` reflection, hardened the v1.28 tenant/category E2E readiness proof, and refreshed roadmap/JTBD truth. Default posture is now maintenance-and-evidence mode. New milestones should be silent by default unless there is release work, support/proof drift, outside-adopter evidence, a concrete bug, or a deliberate strategic build decision.

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
| **B1** | **Related-data and dependency propagation** | **Done in v1.24** — `Scrypath.sync_related/3`, `RelatedWorker`, canonical guide rewrite, Phoenix example fan-out. Keep here as historical context. |
| **B2** | **Tenant-safe search access story** | **Done in v1.25** — `guides/multitenancy.md`, `tenant_field:`, `schema_capabilities/1` reflection, and `tenant_scope:` hard-injection. Keep here as historical context. |
| **B3** | **Composition and real-app depth over the query toolkit** | **Done in v1.22** — keep here only as historical context so future planning does not reopen the same wedge accidentally |
| **B4** | **Facet value vocabulary search (`search_facet_values/4`)** | **Done in v1.26** — first-class facade API, `FacetSearchResult`, Meilisearch `/facet-search` routing, LiveView examples, and `mix verify.phase96`. Keep here as historical context. |
| **B5** | **Autocomplete / suggestion flows** | Only with outside-adopter evidence. Otherwise stop after the v1.26/v0.3.8 release train lands. |

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
| **E1** | **Outside-adopter evidence and support-truth reconciliation** | **Done in v1.23; continue as maintenance evidence loop** — no new feature milestone should open unless outside-adopter evidence shows a concrete gap. |
| **E2** | **Adopter Contract Hardening (docs/support/install/proof coherence)** | **Done in v1.27** — canonical contract freeze, support/proof boundary reconciliation, and trust gates shipped. Keep as historical context only. |
| **E3** | **Contract Repair and Proof Hardening** | **Done in v1.29** — repaired `use Scrypath, fan_outs:` reflection, hardened the tenant/category E2E readiness proof, refreshed roadmap/JTBD truth, and avoided new runtime breadth. |

### Tier F — Current maintenance pull

| # | Theme | Notes |
|---|--------|--------|
| **F1** | **Release + adoption evidence + planning truth** | Current default after the bounded repair pass. Keep main green, keep release truth coherent, and capture outside-adopter evidence before opening new product work. This is maintenance posture, not an endless roadmap. |

### Tier G — Companion surface

| # | Theme | Notes |
|---|--------|--------|
| **G1** | **Public website launch surface** | Shipped as a GitHub Pages companion to HexDocs. Keep release truth, screenshots, and persona routes in sync with the package; do not expand it into a second docs site. |

## Unified operating lanes (post-v1.26)

Use these lanes to avoid reopening feature breadth by habit:

- **Maintenance lane (default):** patch train, docs/support truth, outside-adopter evidence loop, and planning-truth reconciliation while `main` stays green.
- **Silence lane:** when there is no release follow-through, support/proof drift, production bug, or outside-adopter evidence, do not manufacture a milestone. Say the release train is idle.
- **Feature lane (evidence-gated):** open only via approved PR-scoped milestone when a concrete bug, reviewed outside-adopter evidence, or explicit strategic wedge justifies it.
- **Merge contract for feature lane:** serious milestone work merges only after PR CI is green; avoid direct-`main` depth work.

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
| 3 | **v1.13** (**POLISH-***) | **Shipped v1.13** |
| 4 | **E1** | **Shipped v1.23** — adopter evidence + support-truth reconciliation |
| 5 | **B1** | **Shipped v1.24** — `sync_related/3`, fan-out, canonical guide |
| 6 | **B2** | **Shipped v1.25** — tenant guide, declaration, reflection, and runtime enforcement. |
| 7 | **B4** | **Shipped v1.26** — `search_facet_values/4` wrapping `/facet-search`. |
| 8 | **E2** | **Shipped v1.27** — Adopter Contract Hardening. |
| 9 | **G1 / v1.28** | **Shipped v1.28** — realistic demo app, mountable admin UI proof, and advisory browser E2E lane. |
| 10 | **E3** | **Shipped v1.29** — contract repair and proof hardening. |
| 11 | **F1** | Current maintenance pull: release truth, outside-adopter evidence, and planning-truth refresh. |
| 12 | **B5** | Only with adopter evidence. Otherwise stop after contract repair / proof hardening. |
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
4. After v1.29, the default answer to generic “what next?” prompts is **no feature milestone** unless there is release work, support/proof drift, outside-adopter evidence, a concrete bug, or an explicit strategic build decision.
5. If feature work reopens, treat this file as PR-lane input: define the wedge first, run it on a PR branch, and do not merge until PR CI is green.
6. Do not keep asking whether Scrypath is done at every milestone boundary. Treat the durable answer as: **the stated v1 library scope is effectively done; maintain by default; build strategically only when evidence changes the decision.**

---

*Sources: **PROJECT.md**, **STATE.md**, **MILESTONES.md**, **RETROSPECTIVE.md**, **ROADMAP.md**, **CONTRIBUTING.md**, **README.md**, **examples/phoenix_meilisearch/README.md**.*
