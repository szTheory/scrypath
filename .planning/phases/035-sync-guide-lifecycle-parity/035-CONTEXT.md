# Phase 35: Sync guide lifecycle parity - Context

**Gathered:** 2026-04-19  
**Status:** Ready for planning

<domain>
## Phase Boundary

Close **v1.6-MILESTONE-AUDIT.md** gap **INT-SYNC-GUIDE-AUTHORITY**: README points adopters at **`guides/sync-modes-and-visibility.md`** as the authority for lifecycle / Phoenix / recovery language, while README also shows the operator lifecycle chain **`requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded`** — that chain is not yet first-class in the guide. Per **`.planning/REQUIREMENTS.md`** phase 35 success criterion: either the guide carries the lifecycle vocabulary README points at, or README narrows the authority claim.

**Requirements touched:** ADPT-02, ADPT-03.

**In scope:** Doc-only edits to **`README.md`**, **`guides/sync-modes-and-visibility.md`**, and **narrow** extensions to **`test/scrypath/docs_contract_test.exs`** that lock parity without brittle prose cloning.

**Out of scope:** New library APIs; golden-path tutorial rewrites (spine remains **`guides/golden-path.md`**); changing **`examples/phoenix_meilisearch`** unless a doc pass finds a hard contradiction (default: align docs only).

</domain>

<decisions>
## Implementation Decisions

### 1. Authority repair strategy (README ↔ guide)

- **D-01 (Hybrid — recommended by research):** **Enrich the guide** so the README “authority” sentence is true on first deep read, **and** add a **surgical README precision line**: the guide is the **normative reference** for per-state semantics, Phoenix implications, and recovery posture; the lifecycle string in the README is the **same progression** described in the guide; **if README and guide ever disagree, the guide wins.** This avoids pure “narrow README only,” which fixes the lie but can hide high-signal vocabulary from GitHub-first readers (Scout/Searchkick pattern: README orientation, deep docs for contracts).

### 2. Lifecycle string placement

- **D-02:** **README teaser + guide canonical:** Keep the **one-line operator lifecycle chain** in **`README.md`** for at-a-glance operators and ADPT-02 decision surface. Add a **single prominent section** early in **`guides/sync-modes-and-visibility.md`** (immediately after **The Contract** or integrated into it) containing the **exact same chain**, short gloss per node (what is / is not implied for search visibility), and how **`:inline` / `:oban` / `:manual`** relate without re-deriving the whole mode narrative twice. Use a stable heading suitable for deep links (e.g. **Operator lifecycle** or **Shared operator lifecycle**) so README can anchor “see guide § …”.

- **D-03:** Do **not** maintain two full parallel specifications (no duplicated long tables); one expanded normative block lives in the guide only.

### 3. Doc contract / `mix verify`

- **D-04:** Extend **`test/scrypath/docs_contract_test.exs`** with **minimal parity locks** on **stable tokens**, not marketing voice: e.g. require the guide to contain the lifecycle progression string (or tightly scoped substrings that cannot pass without the real vocabulary: `requested`, `enqueued`, `processing`, `backend_accepted`, `retrying`, `discarded` in coherent context — choose the least brittle option during implementation). Follow existing **`assert_contains_all(@guides["guides/sync-modes-and-visibility.md"], [...])`** pattern (phase 33–34 style).

- **D-05:** Do **not** add long duplicate sentences across README + guide + tests; avoid ordered multi-paragraph locks. Prefer **identifiers + one canonical lifecycle string** as the contract.

### 4. README promise scope

- **D-06:** Treat the audit item primarily as a **guide parity bug**, not a README retreat: **do not remove** the Sync Modes table, heuristics, or “choosing a mode” copy that satisfy **ADPT-02**. At most **one** tightening edit to the authority sentence if needed for honesty (e.g. naming the new guide subsection).

- **D-07:** Do **not** trim Phoenix / recovery promises from the README sentence unless the guide fails to cover them after edits — subagent consensus: the guide already covers those dimensions; the substantive gap is **terminological continuity** (lifecycle chain) into the guide.

### 5. Ecosystem and product coherence

- **D-08:** Stay aligned with **phase 29 / 34** shape: README = **compact decision surface**; **`guides/sync-modes-and-visibility.md`** = **depth + operational honesty**; golden path remains the linear ADPT-01 spine elsewhere.

- **D-09 (Footguns to avoid):** No silent dual spec (if both show the chain, README must state guide wins); no “README-only lifecycle” that the guide omits; no overly aggressive README diet that pushes mode choice entirely behind a click.

### Claude's Discretion

- Exact **heading title** and anchor slug for the new lifecycle section; whether definitions use a **small table** vs prose; exact **`assert_contains_all`** token list to balance brittleness vs regression prevention; optional README micro-edit wording.

### Folded Todos

- None — `todo.match-phase` returned no matches for **035**.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and audit

- `.planning/REQUIREMENTS.md` — Phase 35 success criteria; ADPT-02, ADPT-03
- `.planning/ROADMAP.md` — Phase 35 goal row
- `.planning/v1.6-MILESTONE-AUDIT.md` — `INT-SYNC-GUIDE-AUTHORITY`, `gaps.integration`
- `.planning/PROJECT.md` — v1.6 adoption and operational honesty

### Prior phase context

- `.planning/phases/034-golden-path-readme-and-ci-alignment/034-CONTEXT.md` — Explicit deferral of **`INT-SYNC-GUIDE-AUTHORITY`** to phase 35
- `.planning/phases/029-golden-path-adoption-documentation/029-CONTEXT.md` — README vs guide roles (compact vs authority)

### Files to edit / lock

- `README.md` — Sync Modes authority paragraph + optional anchor link
- `guides/sync-modes-and-visibility.md` — new / expanded operator lifecycle vocabulary
- `test/scrypath/docs_contract_test.exs` — parity assertions for guide (and only if justified, README)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`test/scrypath/docs_contract_test.exs`** — `@guides["guides/sync-modes-and-visibility.md"]` already locked with mode headings and key phrases; extend the existing list in the guides bundle test (around the sync-modes assertions).

### Established patterns

- **Spine vs ribs:** Golden path owns linear first-hour narrative; sync guide owns mode semantics; README routes and compares modes without duplicating full operator manual.

### Integration points

- **`mix verify.phase11`** — doc contract tests are part of the always-on gate; new assertions must stay cheap and stable.

</code_context>

<specifics>
## Specific Ideas

User requested **parallel subagent research** (ecosystem idioms, Scout/Searchkick-style doc splits, footguns) and **one-shot coherent recommendations** — synthesized above into **D-01–D-09** with hybrid **guide enrichment + README precision + minimal doc tests**.

</specifics>

<deferred>
## Deferred Ideas

**None** — discussion stayed within phase 35 doc parity scope.

### Reviewed todos (not folded)

- None.

</deferred>

---

*Phase: 35-sync-guide-lifecycle-parity*  
*Context gathered: 2026-04-19*
