# Phase 51 — Technical research

**Question:** What do we need to know to plan adoption-path truth and discoverability well?

## Findings

### Doc-contract pattern (brownfield)

- **`test/scrypath/docs_contract_test.exs`** already loads `README.md`, `CONTRIBUTING.md`, golden-path, CI workflow, and guide paths via module attributes (`@readme`, `@contributing`, `@guides`, `@ci_workflow`). New invariants should extend this file (or a focused `docs_*_contract_test.exs` split per **D-01**) rather than adding shell-only gates.
- **Published-doc hygiene** tests forbid internal tokens such as **`VRFY-NN`** in published markdown; requirement IDs stay in planning/requirements tables, not user-facing prose.

### CI source of truth (`phoenix-example-integration`)

- **`.github/workflows/ci.yml`** (job `phoenix-example-integration`, lines ~273–343): `env` sets `PGPORT: "5433"`, `SCRYPATH_MEILISEARCH_URL: http://127.0.0.1:7700`, `SCRYPATH_EXAMPLE_INTEGRATION: "1"`; steps run `cd examples/phoenix_meilisearch`, then **`mix deps.get`**, then **`mix test`**.
- **`guides/golden-path.md`** “Integration smoke” section already documents **`mix deps.get`** in the CI sentence; **`CONTRIBUTING.md`** CI table row for the same job currently omits `mix deps.get` — a concrete drift to fix under **ONBD-03**.

### README vs CONTRIBUTING vs guides

- **README** = consumer front door; **one** memorable sync invariant + link to **`guides/sync-modes-and-visibility.md`** (per **D-05**, **D-11**–**D-12**); avoid duplicating the sync guide body.
- **CONTRIBUTING** = verify matrix, CI job ↔ commands, PR norms; short pointer block when touching sync/operator/published guides (**D-06**, **D-13**).
- **`guides/golden-path.md`** = linear `:inline` spine with explicit handoff to the sync guide in “What is next” (already present ~L142–143); keep CI vs **`./scripts/smoke.sh`** distinction explicit (**D-09**).

### Example app

- **`examples/phoenix_meilisearch/README.md`** remains the env/Compose/runbook authority; align any “what CI runs” callout with the exact `mix` sequence from the workflow, not **`smoke.sh`** (**D-08**, **D-09**).

## Pitfalls to avoid

- **Substring-only tests** without structure (**D-04**): prefer ordered-section anchors or single canonical phrases tied to one invariant.
- **Thin `mix verify.*`**: do not add `mix verify.phase51` unless CI needs a new job boundary (**D-02**).

## Validation Architecture

| Dimension | Approach |
|-----------|----------|
| **Automated** | `mix test test/scrypath/docs_contract_test.exs` after doc edits; full `mix test --exclude integration` before phase close. |
| **Sampling** | After each plan’s doc commits, run the docs contract file; after final wave, run full non-integration test slice. |
| **Manual** | Optional: follow README Quick Path + golden path once to confirm no contradictory pins (complements contracts). |
| **CI parity** | Grep `CONTRIBUTING.md` and example README against `.github/workflows/ci.yml` `phoenix-example-integration` block for identical `mix` steps and env keys. |

---

## RESEARCH COMPLETE
