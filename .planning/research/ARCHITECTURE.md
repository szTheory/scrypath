# Architecture Research: v1.36 Dependency Security Remediation

**Domain:** Multi-project Elixir/Mix dependency maintenance
**Researched:** 2026-08-21
**Confidence:** HIGH for repository topology and required CI gates; MEDIUM for the upstream fixed-version compatibility asserted by the advisory ledger.

## Executive Summary

Scrypath is a repository with four independently resolved Mix projects, not an umbrella application or a single shared dependency graph. Each project owns a `mix.exs` and a `mix.lock`; `mix deps.get` run from one working directory does not rewrite or validate another project's resolution. The remediation must therefore be four sequential, graph-local commits, each restricted to its manifest/lockfile pair (plus only the tests or code required to resolve a demonstrated compatibility break).

The path dependencies create a directional source relationship, not a lockfile relationship: `scrypath_ops` and the legacy Phoenix example consume root `scrypath` by path, while ecommerce consumes both root `scrypath` and `scrypath_ops` by path. A downstream `mix deps.get` must still solve its own complete graph against those local sources. Root batch success proves the root lock and library behavior; it does not prove that the three downstream solvers select the safe versions. Conversely, ecommerce is the only graph that compiles the mounted Ops app inside the host application, but it must not be used as a substitute for the dedicated Ops graph test.

The smallest architecture-preserving sequence is: root HTTP client; legacy Phoenix example with its Ecto/Decimal coordinated upgrade; standalone ScrypathOps; then ecommerce/mounted-Ops. This follows source and risk dependencies while retaining fault isolation. Do not add a workspace, copy locks, centralize constraints, or alter CI topology solely for this maintenance milestone.

## Standard Architecture

### Dependency-resolution overview

```
Repository root (independent Mix project)             Required root CI gates
mix.exs + mix.lock                                    main-ci / repo-hygiene /
Scrypath library                                      release-truth / phase99-trust
        │
        │ local source only: {:scrypath, path: ".."} or "../.."
        ├─────────────────────────────┐
        │                             │
        ▼                             ▼
scrypath_ops/                    examples/phoenix_meilisearch/
mix.exs + mix.lock               mix.exs + mix.lock
Ops Phoenix graph                legacy Phoenix graph
        │                             (separate direct solver)
        │ local source only: {:scrypath_ops, path: "../../scrypath_ops"}
        ▼
examples/scrypath_ecommerce/
mix.exs + mix.lock
ecommerce Phoenix + mounted Ops graph
```

### Lock-graph ownership and proof

| Graph / working directory | Owned resolver inputs | Local path inputs | Batch | Minimum proof before next batch |
|---|---|---|---|---|
| Root `.` | `mix.exs`, `mix.lock` | none | 1 | root clean resolution, compile, fast test, `verify`, phase 11, phase 99 |
| `examples/phoenix_meilisearch` | example `mix.exs`, example `mix.lock` | `../../` `scrypath` | 2 | example `deps.get` + test, then root fast test |
| `scrypath_ops` | Ops `mix.exs`, Ops `mix.lock` | `../` `scrypath` | 3 | root `mix verify.opsui`, then root required gates |
| `examples/scrypath_ecommerce` | ecommerce `mix.exs`, ecommerce `mix.lock` | `../../` `scrypath`; `../../scrypath_ops` | 4 | root and ecommerce clean resolution, ecommerce DB preparation; advisory browser proof when services are available |

All four current locks carry distinct resolver state. The legacy example is intentionally different: its locked Ecto/Ecto SQL 3.13.5 require Decimal 2.x, so the recorded fix requires an explicit aligned Ecto/Ecto SQL 3.14.x move before Decimal 3.x can resolve. The other three locks already select Ecto/Ecto SQL 3.14.0 and Decimal 3.1.1; that change belongs only to the legacy graph.

## Recommended Change and Verification Sequence

### Batch 1 — Root Scrypath HTTP client

**Owned files:** root `mix.exs` and `mix.lock` only, unless a documented Req 0.6 compatibility failure requires a narrow core code/test adjustment.

1. Change the direct `Req` constraint to the recorded compatible line (`~> 0.6.1`), then run `mix deps.get` from repository root.
2. Inspect root `mix.lock`; do not assume downstream locks changed. Confirm the recorded root set is no longer selected: Req 0.5.18, Mint 1.8.0, hpax 1.0.3, and Plug 1.19.2.
3. Run, in root: `mix compile --warnings-as-errors`; `mix test --exclude integration --exclude docs_contract`; `mix verify --exclude integration`; `mix verify.phase11`; `mix verify.phase99`.
4. Commit only after all gates pass. Stop here on a resolver, compiler, or gate failure.

### Batch 2 — Legacy Phoenix example and Ecto/Decimal alignment

**Owned files:** `examples/phoenix_meilisearch/mix.exs` and `examples/phoenix_meilisearch/mix.lock`, plus only example-local compatibility edits if tests require them.

1. From `examples/phoenix_meilisearch`, update constraints and run `mix deps.get` there. This graph owns its own Bandit, Phoenix, Ecto, Ecto SQL, and path-to-root Scrypath selection.
2. Move Ecto and Ecto SQL together to the recorded 3.14.x compatibility line; do not try to force Decimal 3 into the prior Ecto 3.13 solution.
3. Run `mix test` in that directory (the test alias creates/migrates its Postgres database). Then return to root and run `mix test --exclude integration --exclude docs_contract` to prove the path-consumed root remains sound.
4. Treat the CI `phoenix-example-integration` job (Postgres + Meilisearch, same `cd` → `deps.get` → `test` shape) as the authoritative live follow-up, not `scripts/smoke.sh`.

### Batch 3 — Standalone ScrypathOps web/client graph

**Owned files:** `scrypath_ops/mix.exs` and `scrypath_ops/mix.lock`, plus only Ops-local compatibility edits if necessary.

1. Resolve from `scrypath_ops`, never by running root `mix deps.get`. Keep its path reference to root `scrypath`; do not add a public dependency abstraction.
2. Lock the recorded fixed-compatible web/client set: Bandit, Phoenix, Phoenix LiveView, Plug, Postgrex, Mint, hpax, Swoosh, and Req.
3. From root run `mix verify.opsui`. It deliberately executes `cd scrypath_ops && mix deps.get && mix test` with Postgres and no Meilisearch, matching the dedicated CI job.
4. Re-run batch-1 root gates because root and Ops interact through a local path dependency. Commit only when both the graph-local and root proof are green.

### Batch 4 — Ecommerce web/client and mounted-Ops graph

**Owned files:** `examples/scrypath_ecommerce/mix.exs` and `examples/scrypath_ecommerce/mix.lock`, plus only ecommerce-local compatibility edits if necessary.

1. Start with root `mix deps.get`, then run `mix deps.get` from `examples/scrypath_ecommerce`. The former proves root separately; the latter is the only command that resolves ecommerce's direct graph with both local paths.
2. Select the same recorded safe family as Ops independently. Matching versions are an outcome to verify, not a reason to copy Ops' lockfile.
3. Run `mix e2e.prepare` in the ecommerce directory for Ecto/database readiness. This is required local proof but not a browser substitute.
4. When Postgres, Meilisearch, Node, and Playwright are available, run the documented advisory `phase105-e2e` sequence. It proves the mounted `scrypath_ops` asset/application path and is valuable regression evidence, but remains advisory—not a condition that silently weakens the four required merge gates.

## Clean-resolution Protocol

Before every batch, record `git status --short`, then operate in exactly one graph's working directory. Use ordinary `mix deps.get` with that graph's lock retained: this is a reproducibility check plus a constrained resolver refresh. Do not run `deps.unlock --unused`, `deps.update` without package scope, delete `deps/` or `_build/`, or copy a lockfile between projects as a substitute for a resolution.

After every `deps.get`, inspect that graph's `mix.lock` and run `mix deps.tree`/`mix deps` from the same directory when a required indirect version did not move as expected. A lock diff should be explainable by direct constraints and their required transitive consequences; unrelated package churn is a stop signal, not an acceptable side effect of security work.

Root's test alias can delegate selected test-file paths to Ops or ecommerce, but it is not a dependency resolver. Use the directory-native commands above for resolution and application tests; use delegated root tests only as an additional invocation convenience.

## Required vs Advisory Gates

| Level | Gates | Meaning |
|---|---|---|
| Mandatory per-batch | Each batch's `mix deps.get`, compile/test gate, and specified root proof | Required to establish a clean, graph-local remediation before advancing |
| Required merge gates | `main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust` | CI blockers for green-main; all root-oriented and triggered by the root lock change |
| Required path proof | `mix verify.opsui` / `scrypath-ops` CI for the Ops batch | Required because the Ops graph consumes root by path; CI path filter includes root and Ops manifests/locks |
| Advisory evidence | `compatibility-truth`, `deep-quality`, live integration jobs, `phase105-e2e` | Run when available or as CI supplies them; report failure, but do not relabel them as required for this milestone |

The `scrypath-ops` pull-request path filter observes `scrypath_ops/**`, `lib/**`, root `mix.exs`, root `mix.lock`, and `scrypath_ops/mix.lock`. It does not key off either example lockfile. Therefore a legacy or ecommerce-only change requires its explicit directory-native proof; a skipped Ops job would not establish safety for those graphs.

## Anti-Patterns

### Treating path dependencies as a shared lock

**What goes wrong:** Root `mix deps.get` passes and the work is declared complete.

**Why it is wrong:** Path packages expose local source, while each consuming Mix project still independently solves and locks the complete transitive graph.

**Do this instead:** Refresh and inspect all four locks in their own directory, retaining each graph's own manifest and lock ownership.

### Stacking all upgrades before proof

**What goes wrong:** A broad resolver diff and failures appear after four batches have accumulated.

**Why it is wrong:** The failing graph and changed constraints are no longer attributable, and downstream tests can hide which lock introduced incompatible behavior.

**Do this instead:** One manifest/lock batch, its native proof, its root regression proof, then one commit. Stop immediately on the first failed required gate.

### Reusing ecommerce E2E as Ops proof

**What goes wrong:** A passing or skipped browser lane is treated as proof that `scrypath_ops` resolves and tests independently.

**Why it is wrong:** E2E is advisory and environment-dependent; it verifies the mounted integration, not the standalone Ops project's whole test contract.

**Do this instead:** Keep `mix verify.opsui` mandatory in batch 3 and use phase105 only as the final integration-evidence layer.

### Centralizing dependencies or changing CI topology

**What goes wrong:** The maintenance milestone introduces an umbrella/workspace, shared lockfile, new required job, or package-head upgrades.

**Why it is wrong:** It expands scope and changes the established release-train architecture without evidence that the existing four-project topology is broken.

**Do this instead:** Preserve the topology, target the recorded fixed-compatible versions, and improve no CI policy unless a separate approved change requires it.

## Stop Conditions and Handoff

Stop the current batch—and do not start the next—if any of these occurs: the solver cannot select the recorded floor under declared constraints; the lockfile changes unrelated packages without a clear constraint path; compile/tests/required verification fail; a path project compiles against an unexpected root source; or an advisory remains in that graph after resolution. Consult the relevant upstream migration/release notes before changing another constraint, then retry only the current graph.

The handoff from every phase should include: the exact manifest and lockfile diff; `mix deps`/lock evidence that the recorded affected packages no longer resolve in that graph; commands run with working directory; gate results; and an explicit statement of advisory lanes that were unavailable or failed. The milestone closes only when all four separate `mix deps.get` resolutions no longer select the recorded advisory packages and their required proofs are green.

## Sources

- `.planning/PROJECT.md` — current v1.36 scope and four isolated batches.
- `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md` — reproduced graph inventory, fixed-compatible targets, and per-batch gates.
- `.planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md` — acceptance and ordered execution constraint.
- `mix.exs`, `scrypath_ops/mix.exs`, `examples/phoenix_meilisearch/mix.exs`, `examples/scrypath_ecommerce/mix.exs` and their four `mix.lock` files — independent project and path-dependency topology.
- `CONTRIBUTING.md`, `.github/workflows/ci.yml`, and `lib/mix/tasks/verify.opsui.ex` — local command contracts, CI path filters, and required/advisory gate boundaries.

---
*Architecture research for: Scrypath v1.36 Dependency Security Remediation*
*Researched: 2026-08-21*
