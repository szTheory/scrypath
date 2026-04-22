# Phase 51: Adoption path truth and discoverability - Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning

<domain>
## Phase Boundary

Keep **README**, **`guides/golden-path.md`**, **`examples/phoenix_meilisearch`**, and **CONTRIBUTING** mutually **contract-true** for the first-hour adoption path and CI analogue (**ONBD-01**–**ONBD-03**). Work is doc-, contract-, and link-structure-first—no new library capabilities.

</domain>

<decisions>
## Implementation Decisions

### 1. Doc-contract enforcement (definition of done)

- **D-01:** **Assertions live in ExUnit**—extend **`test/scrypath/docs_contract_test.exs`** (and split into additional `test/scrypath/docs_*_contract_test.exs` modules if the file grows). Do **not** move prose contracts into shell-only CI or duplicate them across many Mix tasks.
- **D-02:** **`mix verify.*` tasks stay thin orchestrators**—reuse existing gates that already run `docs_contract_test` and `mix docs --warnings-as-errors`. Add a **new** `mix verify.phaseNN` **only** when CI needs a new job boundary, not for every new doc anchor.
- **D-03:** **Avoid CI-only doc gates** for content authors are expected to keep green before push; reserve YAML-only checks for infra that cannot run locally.
- **D-04:** Mitigate **substring museum** false confidence: prefer structured checks already in use (ordered sections, fence parsing, cross-file anchors); when adding strings, tie them to a single canonical phrase per invariant.

### 2. README vs CONTRIBUTING (single first-hour narrative, ONBD-02)

- **D-05:** **README** = Hex/GitHub **consumer front door**: positioning, install, **one** linear first-hour story (ends with “read next” into golden path), **thin** Phoenix wayfinding, **one** explicit line that **sync semantics authority** is **`guides/sync-modes-and-visibility.md`**. No second full manual in README.
- **D-06:** **CONTRIBUTING** = **how to change the repo**: verify matrix, CI job names, formatting/lint, PR norms—and a **short** “when you touch sync / operator / published guides” pointer block (bullets + links), **not** a duplicate lifecycle spec.
- **D-07:** **Guides + ExDoc** = **depth and operations** (sync modes, recovery, telemetry, advanced topics). **One authority per topic**; README and CONTRIBUTING **link**, they do not re-teach.

### 3. Example / CI parity (ONBD-03)

- **D-08:** **Canonical “what CI runs”** (authoritative for **`phoenix-example-integration`**): from clone root, with services reachable as in **`.github/workflows/ci.yml`** (`PGPORT=5433`, `SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700`, `SCRYPATH_EXAMPLE_INTEGRATION=1`):

```bash
cd examples/phoenix_meilisearch
mix deps.get
mix test
```

- **D-09:** **`examples/phoenix_meilisearch/scripts/smoke.sh`** = **local DX harness** (Docker Compose, defaults aligned to CI-shaped env, optional `--keep-up`). Docs must state clearly: **CI does not invoke `smoke.sh`**; it runs the **`mix` block above**. Wording: smoke reproduces the **same Mix entrypoint and env defaults**, not bitwise identity with the Actions runner (network, health waits, teardown differ).
- **D-10:** **CONTRIBUTING CI table** must stay **byte-honest** with the workflow (include `mix deps.get` if the job runs it; note Compose vs `services:` where readers will otherwise assume the wrong stack).

### 4. Sync authority surfacing (coherent with D-05–D-07)

- **D-11:** **`guides/sync-modes-and-visibility.md`** remains the **single source of truth** for sync modes, eventual consistency, operator lifecycle, and recovery language tied to those semantics.
- **D-12:** **README** keeps at most **one memorable invariant** plus **router links** (wayfinding + golden path)—the “warning label + map” pattern, not a second copy of the guide.
- **D-13:** **CONTRIBUTING** adds only a **minimal** subsection: link to sync guide, note doc-contract / verify expectations when behavior or operator-facing copy changes, rule “update canonical guide before duplicating semantics in README.”
- **D-14:** **`guides/golden-path.md`** stays the **linear `:inline` first-hour spine** with an explicit **handoff** before production-shaped modes (queue/manual)—do not rely on golden path alone as the only place sync authority is discoverable from README.

### Claude's Discretion

- Exact subsection titles and bullet count in CONTRIBUTING’s sync/doc pointer block.
- Whether to split `docs_contract_test.exs` into multiple modules in this phase vs the next refactor pass, as long as **D-01** holds.

### Folded Todos

(None — `todo.match-phase` returned no matches.)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **ONBD-01**, **ONBD-02**, **ONBD-03** acceptance criteria for Phase 51.
- `.planning/ROADMAP.md` — Phase 51 goal, success criteria, milestone boundary (**v1.12**).
- `.planning/PROJECT.md` — v1.12 vision, Tier A/B scope, “doc truth” non-negotiables.

### Doc authorities and examples

- `README.md` — Consumer entry, Quick Path snippet, Phoenix wayfinding, integration smoke pointer.
- `guides/golden-path.md` — Linear first-hour checklist (`:inline`); handoff to sync guide.
- `guides/sync-modes-and-visibility.md` — **Sync lifecycle authority** (modes, visibility, operator implications).
- `CONTRIBUTING.md` — Verify matrix, CI job ↔ local commands, contributor norms.
- `examples/phoenix_meilisearch/README.md` — Example env, Compose, and runbook detail.
- `examples/phoenix_meilisearch/scripts/smoke.sh` — Local orchestration (not CI definition).

### Contracts and CI

- `test/scrypath/docs_contract_test.exs` — Cross-doc anchors and drift gates.
- `.github/workflows/ci.yml` — **`phoenix-example-integration`** job env and `mix` steps (lines ~273–343).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`test/scrypath/docs_contract_test.exs`** — Already loads README, CONTRIBUTING, golden-path, example README; extend rather than inventing a parallel system.

### Established Patterns

- **`mix verify.*`** — Composes `mix test` slices, docs warnings, and other gates; meta-tests in doc contract file can keep verify tasks honest.

### Integration Points

- **`.github/workflows/ci.yml`** — Source of truth for which services and env vars **`phoenix-example-integration`** uses; docs and CONTRIBUTING must mirror it.

</code_context>

<specifics>
## Specific Ideas

- Ecosystem pattern: **Oban-style README** (features + install + deep links) + **Rails-style CONTRIBUTING** (router into canonical long docs)—applied here with **Scrypath’s** stricter **ExUnit doc contracts** than typical Rails README “social contracts.”
- **Canonical repro** vs **`smoke.sh`**: same **Mix** contract, different **orchestration** for services—state that explicitly to prevent “green locally, wrong cwd in CI” confusion.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 52** — Actionable `{:error, _}` messages, pitfalls slice, **`Scrypath` `@moduledoc`** (**ONBD-04**–**ONBD-06**).
- **Phase 53** — Root **`mix verify.opsui`** spine (**VRFY-03**, **VRFY-04**).

### Reviewed Todos (not folded)

(None.)

</deferred>

---

*Phase: 051-adoption-path-truth-and-discoverability*  
*Context gathered: 2026-04-21*
