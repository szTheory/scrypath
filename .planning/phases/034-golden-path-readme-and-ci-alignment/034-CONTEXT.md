# Phase 34: Golden path, README, and CI alignment - Context

**Gathered:** 2026-04-19  
**Status:** Ready for planning

<domain>
## Phase Boundary

Close **v1.6-MILESTONE-AUDIT.md** integration gaps **INT-GOLDEN-VS-README-SCHEMA** and **INT-GOLDEN-PATH-CI-STORY** within the roadmap scope: **one** canonical first-schema story across **README** and **`guides/golden-path.md`** (including `status` field representation), and golden-path prose that matches **`.github/workflows/ci.yml`** for **`phoenix-example-integration`** on pull requests (no “local-only / optional CI” fiction).

**Requirements touched:** ADPT-01, ADPT-02, ADPT-03, VRFY-01 (per `.planning/REQUIREMENTS.md` phase 34 success criteria).

**Out of scope for this phase:** README ↔ **`guides/sync-modes-and-visibility.md`** lifecycle vocabulary depth (**Phase 35**); new library APIs; changing the example app’s data model **unless** a doc-only pass discovers a hard contradiction (default: align **docs** to **`examples/phoenix_meilisearch`** as shipped).

</domain>

<decisions>
## Implementation Decisions

### 1. Canonical `status` in the first-schema snippet (README ↔ golden path)

- **D-01:** Use **`field :status, :string`** in **both** `README.md` (Quick Path / any retained schema fence) and **`guides/golden-path.md`** so the public first-schema story matches **`examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex`** and existing **`filter: [status: "published"]`** controller examples.
- **D-02:** Do **not** use **`Ecto.Enum`** in the canonical dual-doc snippet for this milestone slice — avoids mixed atom/string filter story in the first hour and avoids retuning the runnable example for doc parity.
- **D-03:** Optional **one short sentence** in the golden path (not a second tutorial): real apps may add **`validate_inclusion`** or adopt **`Ecto.Enum`** when they want typed states — **without** changing the canonical copy-paste block in this phase.

### 2. Golden path ↔ CI narrative

- **D-04:** **Remove** phrasing that implies example integration is only **“local”** or **“optional CI wiring”** (including the literal **`optional CI wiring`** where it creates false expectations).
- **D-05:** Replace with **accurate** copy: on **pull requests**, GitHub Actions runs **`phoenix-example-integration`** against **`examples/phoenix_meilisearch`** with live **Postgres** + **Meilisearch** (align service/image language with **`CONTRIBUTING.md`** / **`ci.yml`** — do not invent job behavior).
- **D-06:** Keep **env tables and command matrices** in **`examples/phoenix_meilisearch/README.md`** and job/guarantee mapping in **`CONTRIBUTING.md`**; the golden path holds **one short paragraph + links**, not a duplicate CI matrix.

### 3. `docs_contract_test.exs` (contract lock)

- **D-07:** **Update** tests that currently require the **`optional CI wiring`** substring so they assert the **new** CI narrative (stable substrings such as **`phoenix-example-integration`** plus **pull request** semantics — pick wording during implementation and lock it in tests).
- **D-08:** **Add** a **narrow** parity check: README and **`guides/golden-path.md`** both contain the **same canonical `status` representation** (e.g. shared token **`field :status, :string`** and consistent **`use Scrypath`** field lines for the first-schema block). Avoid asserting entire fenced blocks byte-for-byte; avoid duplicating CONTRIBUTING’s full job list inside golden-path assertions.

### 4. README Quick Path shape (spine discipline, Phase 29 coherence)

- **D-09:** **`guides/golden-path.md`** remains the **canonical linear** ADPT-01 spine. After schema alignment, **slim README Quick Path**: keep **`mix` deps** install block, **Start here** link, smoke **cwd** guidance (Phase 33), positioning; **replace** the three large duplicate fences (schema + context + controller) with **short prose** naming the three layers plus **at most one micro-snippet** (e.g. only `use Scrypath, ...` **or** only a **`Scrypath.search/3`** call) and a **single CTA** into the golden path for the full path.
- **D-10:** Preserve **`test/scrypath/docs_contract_test.exs`** expectations that require high-signal README sections (installation, golden-path link, operator contract snippets, etc.) — adjust assertions if headings or ordering change, but do not drop verify coverage without replacing it.

### Ecosystem and DX principles (why this coheres)

- **Least surprise:** copy-paste from README matches the guide matches the example; filters stay string-shaped like Meilisearch’s HTTP filters.
- **Operational honesty (product value):** CI copy matches **`.github/workflows/ci.yml`**; adopters and maintainers see the same trust story as **VRFY-01**.
- **Spine vs ribs (Phase 29):** one maintained tutorial depth in **`guides/golden-path.md`**; README routes and signals without a second full tutorial.

### Claude's Discretion

- Exact **micro-snippet** choice in README (only `use Scrypath` vs only `search` call) and final **sentence-level** CI wording, provided **D-04–D-06** and contract tests stay satisfied.
- Whether to add a **brief** “enum upgrade” aside in the golden path vs only in a deeper guide later.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and audit

- `.planning/REQUIREMENTS.md` — Phase 34 success criteria; ADPT / VRFY traceability
- `.planning/ROADMAP.md` — Phase 34 goal row
- `.planning/v1.6-MILESTONE-AUDIT.md` — `INT-GOLDEN-VS-README-SCHEMA`, `INT-GOLDEN-PATH-CI-STORY`, `gaps.flows` (golden path → CI)
- `.planning/PROJECT.md` — v1.6 adoption/trust intent; operational honesty

### Prior phase context (spine decision)

- `.planning/phases/029-golden-path-adoption-documentation/029-CONTEXT.md` — Golden path as canonical ADPT-01 narrative; README teaser discipline

### Files to edit / lock

- `README.md`
- `guides/golden-path.md`
- `CONTRIBUTING.md` — reference only unless CI copy requires a cross-link fix for consistency
- `.github/workflows/ci.yml` — reference for truthful job names and triggers
- `test/scrypath/docs_contract_test.exs` — contract updates per **D-07**, **D-08**

### Runnable example (schema truth)

- `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex` — canonical `status` shape for doc parity
- `examples/phoenix_meilisearch/README.md` — runbook depth; do not fork env tables into golden path

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`test/scrypath/docs_contract_test.exs`** — established pattern: `assert_contains_all`, `ordered?`, guide map `@guides`, `@readme`, `@contributing`, `@ci_workflow`; extend rather than introducing a second doc test harness.
- **`examples/phoenix_meilisearch`** — Postgres + Meilisearch + Oban integration tests; **`phoenix-example-integration`** runs `mix test` from example directory.

### Established patterns

- Phase **33** contracts already enforce **`cd examples/phoenix_meilisearch`** before **`./scripts/smoke.sh`** and link CONTRIBUTING job names to cwd — phase **34** layers **schema + CI narrative** locks without undoing those.

### Integration points

- Doc edits must keep **ExDoc** / published paths valid; any new required phrases must stay **free of bare `ADPT-NN` tokens** in user-facing prose (existing tests forbid that pattern in published docs).

</code_context>

<specifics>
## Specific Ideas

User requested **research-backed, one-shot coherent recommendations** and **“do it”** to capture planning context: decisions **D-01–D-10** consolidate subagent output (README shape) plus maintainer judgment on **`:string` `status`**, **CI honesty**, and **contract-test** scope.

</specifics>

<deferred>
## Deferred Ideas

### Phase 35 (explicit)

- **`INT-SYNC-GUIDE-AUTHORITY`**: README “sync modes authority” sentence vs depth in **`guides/sync-modes-and-visibility.md`** — **Phase 35** only.

### Reviewed todos

- None — `gsd-sdk query todo.match-phase` unavailable in this environment; no folded todos.

**If none otherwise:** None — discussion stayed within phase scope.

</deferred>

---

*Phase: 34-golden-path-readme-and-ci-alignment*  
*Context gathered: 2026-04-19*
