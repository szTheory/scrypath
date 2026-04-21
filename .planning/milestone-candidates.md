# Milestone candidates — stock take after v1.10

**Purpose:** Roughly prioritized themes to pull from when running **`/gsd-new-milestone`**.  
**Last reviewed:** 2026-04-21 (post-**v1.10** OPSUI archive).

---

## Where things stand

### Admin / operator UI

**You did ship an operator admin UI:** optional in-repo **`scrypath_ops`** (LiveView), outside the core Hex package, aligned with **OPSUI-01..10** (posture, failed-sync triage, sync/drift read-only context, bounded search playground, federation-honest inspector, security model, CI contract tests). Archive: **`milestones/v1.10-{REQUIREMENTS,ROADMAP}.md`**.

**Intentionally not in v1.10 (already written down):**

- **OPSUI-FUT-01** — editable saved queries / team playbooks (`milestones/v1.10-REQUIREMENTS.md` § v2+).
- **OPSUI-FUT-02** — Meilisearch “vendor dashboard” parity (same section).
- **Phase 47 deferred ideas** — full browser E2E everywhere, visual regression as default CI gate, real Meilisearch inside **`scrypath_ops`** CI, exhaustive table matrices (`phases/47-verification-hardening/47-CONTEXT.md` `<deferred>`).

So: **“admin UI” in the sense of honest operator visibility over library APIs — done for v1.** Deeper productized admin (saved playbooks, cluster observability, heavy E2E) remains **future**.

### QoL / DX vs “Searchkick-level” expectations

The library has strong **Ecto-native indexing + Meilisearch sync modes**, **search / facets / federation**, **per-query tuning pipeline + runtime**, **operator Mix tasks + drift tooling**, **adoption guides + doc contracts**, and **OPSUI** for triage and inspection.

**Gaps people still reasonably expect** (none of these are implied “done” by v1.10):

| Theme | Why it still matters | Where it shows up in notes |
|--------|----------------------|----------------------------|
| **Planning / maintainer tooling friction** | `gsd-sdk query milestone.complete` → **`phasesArchive` / version** failures forced **manual** milestone archival across **v1.5–v1.10** | **`.planning/RETROSPECTIVE.md`** (v1.5–v1.10 sections) |
| **Audit-open hygiene** | Same **quick_task** stub rows + UAT listing noise acknowledged at multiple closes | **`.planning/STATE.md`** § Deferred Items; **`.planning/MILESTONES.md`** “Known deferred” |
| **OPSUI + real backend in CI** | Deferred on purpose; library integration jobs carry Meilisearch truth | **47-CONTEXT** `<deferred>` |
| **Consumer-facing “it just works” polish** | Golden path exists; ongoing work is **discoverability**, example parity, and “first hour” ergonomics | **v1.6** arc + **`.planning/PROJECT.md`** adoption narrative |
| **Product boundaries still explicit** | Multi-backend, vectors/hybrid/personalization stay **out of scope** until pressure | **`.planning/PROJECT.md`** Out of Scope |

---

## Rough priority for *next* milestones (edit as you learn)

**P0 — Process / trust (small milestone or first phase of next)**

1. **Close or fix the recurring milestone-complete / phases-archive path** so archival is not manual every time (RETROSPECTIVE theme).
2. **Resolve or retire the two historical `quick_task` stub rows** (or replace with real quick dirs) so **`audit-open`** stops recycling the same noise — optional but improves maintainer morale.

**P1 — OPSUI “second slice” (if you want more admin UX)**

3. **Saved queries / operator playbooks** (**OPSUI-FUT-01**) — medium; needs auth + storage story; keep write/recovery verbs honest.
4. **Root `mix verify.opsui`** (or equivalent) if not already landed everywhere contributors look — contributor DX (**47-CONTEXT** D-04).

**P2 — Depth vs breadth**

5. **Selective Playwright (or similar) smoke** on 1–2 critical OPSUI flows — only if LiveView tests stop catching real breakage (**47** deferred).
6. **Meilisearch in `scrypath_ops` CI** — only if stub/LiveView coverage proves insufficient vs regressions in wire format.
7. **Library-side QoL** from adoption feedback: better error messages, generator/scaffold, “common mistakes” doc — gather from issues/adopters before locking.

**P3 — Product expansion (explicit strategy)**

8. Anything in **`.planning/PROJECT.md`** Out of Scope (multi-backend, hybrid retrieval, etc.) — only revisit with explicit adoption evidence.

---

## How to use this file

1. Before **`/gsd-new-milestone`**, skim this list and pick **one dominant theme** for the milestone (or merge P0 + one P1).
2. Optionally split strong themes into **`.planning/seeds/SEED-*.md`** so **`/gsd-new-milestone`** auto-offers matching seeds (see **`gsd-plant-seed`**).
3. After you ship the next milestone, **update the priority table** (what landed, what moved, what new feedback arrived).

---

*Stock take written from: **PROJECT.md**, **STATE.md**, **MILESTONES.md**, **RETROSPECTIVE.md**, **v1.10-REQUIREMENTS.md**, **ROADMAP.md**, **phases/47-verification-hardening/47-CONTEXT.md**.*
