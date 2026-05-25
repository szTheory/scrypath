# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans — [archive](milestones/v1.0-ROADMAP.md)
- [x] `v1.1` shipped on 2026-04-16 — 3 phases, 9 plans — [archive](milestones/v1.1-ROADMAP.md)
- [x] `v1.2` shipped on 2026-04-17 — 7 phases, 13 plans — [archive](milestones/v1.2-ROADMAP.md)
- [x] `v1.3` shipped on 2026-04-17 — 6 phases (18–23), 18 plans — [archive](milestones/v1.3-ROADMAP.md)
- [x] `v1.4` shipped on 2026-04-17 — 3 phases (24–26), 8 plans — [archive](milestones/v1.4-ROADMAP.md)
- [x] `v1.5` shipped in-repo (2026-04-18) — 2 phases (27–28), 5 plans — [archive](milestones/v1.5-ROADMAP.md)
- [x] `v1.6` shipped in-repo (2026-04-19) — 7 phases (29–35), 7 plans — [archive](milestones/v1.6-ROADMAP.md)
- [x] `v1.7` shipped in-repo (2026-04-20) — 3 phases (36–38), 7 plans — [archive](milestones/v1.7-ROADMAP.md)
- [x] `v1.8` shipped in-repo (2026-04-20) — 3 phases (39–41), 6 plans — [archive](milestones/v1.8-ROADMAP.md)
- [x] `v1.9` shipped in-repo (2026-04-20) — 2 phases (42–43), 5 plans — [archive](milestones/v1.9-ROADMAP.md)
- [x] `v1.10` shipped in-repo (2026-04-21) — 4 phases (44–47), 14 plans — [archive](milestones/v1.10-ROADMAP.md)
- [x] `v1.11` shipped in-repo (2026-04-21) — 3 phases (48–50), 11 plans — [archive](milestones/v1.11-ROADMAP.md)
- [x] `v1.12` shipped in-repo (2026-04-22) — 3 phases (51–53), 9 plans — [archive](milestones/v1.12-ROADMAP.md)
- [x] `v1.13` shipped + archived in-repo (2026-04-22) — 3 phases (54–56), 5 plans — [archive](milestones/v1.13-ROADMAP.md)
- [x] `v1.14` shipped + archived in-repo (2026-04-22) — 5 phases (57–61), 10 plans — [archive](milestones/v1.14-ROADMAP.md)
- [x] `v1.15` shipped + archived in-repo (2026-04-22) — 3 phases (62–64), 8 plans — [archive](milestones/v1.15-ROADMAP.md)
- [x] `v1.16` shipped + archived in-repo (2026-04-22) — 3 phases (65–67), 6 plans — [archive](milestones/v1.16-ROADMAP.md)
- [x] `v1.17` shipped + archived in-repo (2026-04-23) — 3 phases (68–70), 6 plans — [archive](milestones/v1.17-ROADMAP.md)
- [x] `v1.18` shipped + archived in-repo (2026-04-26) — 3 phases (71–73), 10 plans — [archive](milestones/v1.18-ROADMAP.md)
- [x] `v1.19` shipped + archived in-repo (2026-04-28) — 3 phases (74–76), 8 plans — [archive](milestones/v1.19-ROADMAP.md)
- [x] `v1.20` shipped + archived in-repo (2026-05-08) — 3 phases (77–79), 8 plans — [archive](milestones/v1.20-ROADMAP.md)
- [x] `v1.21` shipped + archived in-repo (2026-05-23) — 3 phases (80–82), 8 plans — [archive](milestones/v1.21-ROADMAP.md)
- [x] `v1.22` shipped + archived in-repo (2026-05-24) — 3 phases (83–85), 12 plans — [archive](milestones/v1.22-ROADMAP.md)
- [x] `v1.23` shipped + archived in-repo (2026-05-24) — 3 phases (86–88), 8 plans — [archive](milestones/v1.23-ROADMAP.md)
- [x] **`v1.24` shipped + archived in-repo** (**2026-05-25**) — *Related-Data and Dependency Propagation* — phases **89–91**, **9** plans — [archive](milestones/v1.24-ROADMAP.md) · [requirements](milestones/v1.24-REQUIREMENTS.md) · [audit](milestones/v1.24-MILESTONE-AUDIT.md)

## Current Milestone

**v1.25 — Tenant-Safe Search** — *active* — opened 2026-05-25

## Phases

- [ ] **Phase 92: Guide and Schema Declaration** - Canonical multitenancy guide + `tenant_field:` schema option; co-shipped to ensure the declaration and its documentation land together
- [ ] **Phase 93: Reflection and Runtime Enforcement** - `schema_capabilities/1` `:tenant` reflection + `tenant_scope:` hard-injected filter; both depend on the `tenant_field:` groundwork from Phase 92
- [ ] **Phase 94: Verification Gate** - `mix verify.phase94` hermetic gate covering all tenant-safety surfaces; CI registration and contributor guidance

## Phase Details

### Phase 92: Guide and Schema Declaration
**Goal**: Adopters can declare a tenant field in their schema once and follow a canonical guide to implement tenant-safe search correctly in a Phoenix SaaS app
**Depends on**: Nothing (first phase of v1.25)
**Requirements**: TNNT-01, TNNT-02
**Success Criteria** (what must be TRUE):
  1. A developer can follow `guides/multitenancy.md` to understand and implement the shared-index + filter-injection model without reading source code
  2. A developer can add `tenant_field: :tenant_id` to a Scrypath schema and the field is automatically present in both `filterable:` and the synced document projection without additional declarations
  3. `guides/multitenancy.md` contains working wrong/correct code examples for the filter merge order footgun so developers can recognize and avoid the silent data-leak
  4. The guide explains when Meilisearch tenant tokens apply (browser-direct only) and explicitly why per-tenant indexes are not the default model
**Plans**: TBD

### Phase 93: Reflection and Runtime Enforcement
**Goal**: Adopters can introspect schema tenant declarations programmatically and use `tenant_scope:` to have the library hard-inject the tenant filter at the call site — preventing filter merge order bugs entirely
**Depends on**: Phase 92
**Requirements**: TNNT-03, TNNT-04
**Success Criteria** (what must be TRUE):
  1. A developer can call `Scrypath.Metadata.schema_capabilities/1` on a schema with `tenant_field:` declared and get back a map containing a `:tenant` key naming the declared field
  2. A developer can call `Scrypath.Metadata.schema_capabilities/1` on a schema without `tenant_field:` declared and get back `nil` for the `:tenant` key
  3. A developer can pass `tenant_scope: tenant_id` to `Scrypath.search/3` and the library AND-combines that tenant filter with caller-supplied `filter:` opts — caller filters cannot shadow or overwrite the tenant guard
  4. Passing `tenant_scope:` without a `tenant_field:` declaration on the schema does not silently fail; the behavior is deterministic and documented
**Plans**: TBD

### Phase 94: Verification Gate
**Goal**: All tenant-safety surfaces are regression-guarded by a single hermetic task that contributors and CI can run to confirm nothing has drifted
**Depends on**: Phase 93
**Requirements**: TNNT-05
**Success Criteria** (what must be TRUE):
  1. `mix verify.phase94` runs without errors and exercises guide anchor assertions, `tenant_field:` auto-merge behavior, `schema_capabilities/1` `:tenant` reflection, and `tenant_scope:` injection in a single hermetic pass
  2. `mix verify.phase94` is registered in the CI `quality` job so a pull request that breaks any tenant-safety contract fails CI
  3. CONTRIBUTING guidance references `mix verify.phase94` so contributors know the gate exists and how to run it
**Plans**: TBD

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 92. Guide and Schema Declaration | 0/? | Not started | - |
| 93. Reflection and Runtime Enforcement | 0/? | Not started | - |
| 94. Verification Gate | 0/? | Not started | - |

<details>
<summary>✅ v1.24 — Phases 89–91 — SHIPPED + archived 2026-05-25 · <em>Related-Data and Dependency Propagation</em></summary>

### Phase 89: Related-Data Propagation Contract and API

**Goal:** Establish the public, explicit API and metadata structures required to declare and invoke related-data fan-out (e.g. `Scrypath.sync_related/3`) without hidden Ecto callback magic.
**Depends on:** none
**Requirements:** DATA-01, DATA-02
**Plans:** 3 plans

- [x] 89-01: Design the `Scrypath.sync_related/3` entrypoint and underlying capability struct for associating parent-child schemas.
- [x] 89-02: Update core execution runtime to explicitly accept and validate related-data fan-out intents.
- [x] 89-03: Establish baseline hermetic tests ensuring explicit orchestration overrides auto-magic execution.

### Phase 90: Async Execution and Error Propagation

**Goal:** Provide an out-of-the-box Oban worker pattern for large blast radii and ensure midway failures yield actionable errors rather than silent partial drops.
**Depends on:** Phase 89
**Requirements:** DATA-03, EXEC-01
**Plans:** 2 plans

- [x] 90-01-PLAN.md — Update RelatedWorker for explicit error propagation and cancellation.
- [x] 90-02-PLAN.md — Add integration tests for RelatedWorker error propagation behavior.

### Phase 91: Integration, Guides, and Verification

**Goal:** Update `guides/related-data-and-reindexing.md` to remove "temporary workaround" language, clearly document the new API, and lock those assertions in the docs-contract pipeline.
**Depends on:** Phase 90
**Requirements:** EXEC-02, TEST-01, TEST-02
**Plans:** 4 plans

- [x] 91-01-PLAN.md — Rewrite `guides/related-data-and-reindexing.md` so `sync_related/3` + the built-in Oban path are canonical; remove temporary-workaround framing; map inline-vs-oban to blast radius + latency (EXEC-02).
- [x] 91-02-PLAN.md — Add `mix verify.phase91` + invert the docs-contract assertion + register the task (TEST-01/TEST-02).
- [x] 91-03-PLAN.md — Polish `examples/phoenix_meilisearch`: `Author` schema + migration + `ScrypathDemo.Blog` context + arity-safe resolver, inline + oban fan-out smokes (EXEC-02).
- [x] 91-04-PLAN.md — Fix guide: hand-written `__scrypath__/1` accessor pattern replaces broken `use Scrypath, fan_outs:` snippet; docs-contract regression gate (gap-closure).

Full detail: [milestones/v1.24-ROADMAP.md](milestones/v1.24-ROADMAP.md).

</details>
