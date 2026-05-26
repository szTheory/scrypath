---
gsd_state_version: 1.0
milestone: none
milestone_name: none
status: archived
last_updated: "2026-05-26T15:00:00.000Z"
last_activity: 2026-05-26 -- v1.26 Facet Value Vocabulary Search archived
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-26)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** Post-v1.26 Evaluation / Maintenance

## Current Position

Phase: none
Plan: none
Status: archived
Last activity: 2026-05-26 -- v1.26 Facet Value Vocabulary Search archived

```
Progress: [░░░░░░░░░░] 0%
```

## Accumulated Context

### Decisions

(See `.planning/PROJECT.md` Key Decisions.)

- **v1.26 archived:** Shipped `Scrypath.search_facet_values/4` for high-cardinality facet search, updated docs with LiveView examples, and locked the `mix verify.phase96` gate.
- **v1.25 archived:** Shipped `tenant_field:` declaration, `tenant_scope:` injection, and canonical multitenancy guide.
- **Phase 96 complete:** Created the `mix verify.phase96` gate, enhanced `search_facet_values/4` documentation with LiveView examples, and verified all facet-UX surfaces are regression-guarded in CI.
- **Phase 95 complete:** Created distinct `Scrypath.FacetSearchResult` struct to separate vocabulary hits from standard search document hits. The interface acts dynamically on `facet_query` parameters and routes through the existing Scrypath option validation pipeline.
- **Phase 93 plan 02 complete:** Added the `tenant_scope:` option and implemented `inject_tenant_scope!/2` to automatically and safely inject the tenant filter, catching conflicts with existing filters.
- **Phase 92 plan 03 complete:** Added canonical multitenancy guide covering shared-index model, explicit tenant parameter pattern, filter merge order footgun, tenant tokens, search_document/1 edge case, and schema declaration reference. Registered guides/multitenancy.md in ExDoc extras and groups_for_extras. Added docs_contract_test.exs assertions for multitenancy guide anchors.
- **Phase 93 plan 01 complete:** Included `:tenant` key in `schema_capabilities/1` root map to enable introspection of tenant isolation settings.
- **Phase 90 complete:** `Scrypath.Sync.RelatedWorker.perform/1` resolves job arguments gracefully and maps fan-out results onto the Oban worker contract — HTTP 4xx → `{:cancel, _}` (permanent), HTTP 5xx/generic → `{:error, _}` (transient retry), invalid schema/fan_out → `{:cancel, {:invalid_job, reason}}`. Recovery note: a single bug (mis-destructuring `Telemetry.span/3`, which returns the result directly) was the sole blocker and is fixed; full suite green (493 tests).

- **Phase 89 complete:** Implemented explicit metadata validation (`fan_outs`), created `Scrypath.sync_related/3` for executing resolvers inline or enqueuing via `RelatedWorker`, successfully integrating both execution modes securely.

- **Phase 88 complete:** Papercuts fixed and milestone frozen. Next-pull verdict is related-data propagation.

- **Phase 87 plan 02 complete:** Both submissions successfully passed the human verification checkpoint as genuine outside-adopter attempts and were classified as Class A (Defended-path). The findings were recorded in the evidence ledger, establishing a PASS state for the defended-path gate.
- **v1.15 close:** Second slice shipped **OPS2-01**–**OPS2-08** across phases **62–64**; persistence authority **(A)** file + GitOps; **OPSUI-FUT-02** / **Tier C** unchanged — **`milestones/v1.15-REQUIREMENTS.md`**.
- **v1.16 open:** Prioritize **execution honesty** over new indexing features; **stub-first OPSUI CI** unchanged; parallel **`.planning/research/`** refresh **skipped** at open (existing research retained).
- **v1.16 close:** Phase 67 added bounded execution-surface contracts, canonical JTBD playbook examples, truthful `v1.16-*` archive artifacts, and rolling traceability updates without claiming a new Hex release.
- **v1.17 open:** Freeze product breadth for one milestone and prove real-app adoption: canonical Phoenix example for inline/manual/Oban, one support contract, one adopter verify path, and at most three evidence-backed papercuts.
- **Phase 68 complete:** Published `guides/support-and-compatibility.md`, rewired README / guides / CONTRIBUTING to the canonical proof path, promoted the Phoenix example README into the source of truth for env/order/proof paths, and added live `:manual` example coverage plus bounded docs contracts.
- **Phase 69 complete:** Added the durable `mix verify.adopter` maintainer command, aligned README / CONTRIBUTING / support guide / example README / CI to the fast-vs-live adopter verify spine, and verified both the fast root path and live Phoenix example path locally.
- **Phase 70 complete:** Closed exactly three bounded adopter-friction papercuts in docs/contracts, then updated rolling planning truth and froze the `v1.17-*` archive trio with an explicit outside-integration-feedback-next verdict.
- **v1.17 close:** Treat the milestone as a readiness checkpoint, not another breadth step; outside integration feedback now displaces more in-repo polish unless new evidence says otherwise.
- **v1.18 close:** Optional Sigra integration shipped in-repo with compile guards, bounded LiveView gating, a canonical guide, a worked example, and a passed milestone audit.
- **v1.19 open:** The next step is not more feature breadth; it is defended production-adoption proof, explicit support boundaries, and only evidence-backed hardening that falls out of those proof runs.
- **Phase 65 discuss:** Hybrid catalog **Run now** + shared draft pipeline; **`start_async`/`handle_async`** lifecycle with **`run_id`**, timeout, **`cancel_async`**; **`scrypath_ops`** error registry + **`DocResolver`**; **no** Oban/DB default run path in this phase (deferred).
- Kept Runner.run_validated/3 as the canonical raw tuple seam and documented reason identity as the compatibility key.
- Kept playbook-schema-v1.md authoritative for JSON wire format only and linked execution semantics to the Runner moduledoc.
- Phase 66 plan 02: runner parity tests compare direct Scrypath calls to Runner.run_validated/3 on the same fixtures.
- Phase 66 plan 02: playbook dispatch preserves absent page opts and coerces JSON facet names so runner semantics match core search contracts.
- Pinned the audit-prefix contract to the Sigra 0.2.5 reserved-prefix set surfaced by `Sigra.Audit.log_multi/3`, because the dependency does not expose a public `reserved_prefixes/0` accessor.
- Implemented the fence as a standard Mix task with a pure `check/1` seam so the rule set is testable without shelling out.
- Phase 76 plan 01 accepted exactly one live-proof papercut and fixed it on the verify.adopter seam with a single task-test recurrence guard.
- **v1.19 close:** The defended Phoenix + Meilisearch proof surfaces are green, the optional Sigra branch remains honestly scoped, and the canonical audit verdict is **ready to seek broader outside production adoption on the defended surface, with external validation still pending**.
- Keep .planning/milestones/v1.19-MILESTONE-AUDIT.md as the only canonical broader-adoption verdict source.
- Use the weaker v1.19 close wording because no reviewed real outside adopter signal exists yet.
- **2026-04-28 reassessment:** Further internal Scrypath development is likely below the value threshold until real outside adopters exercise the defended surface. Default posture: pause new feature/depth milestones and reopen only for concrete adopter evidence or a clearly leverage-positive release/distribution need.
- **v1.20 open:** Despite the post-v1.19 pause posture, a narrow search-module milestone was activated because the work is already in motion in the repo and stays leverage-positive without widening backend scope or weakening the canonical broader-adoption verdict.
- **Phase 77 complete:** Locked the `Scrypath.SearchModule` declaration/runtime seam around context-owned modules, explicit merge ambiguity, and wrapper-first docs/tests without freezing helper internals as public contract.
- **Phase 78 complete:** Locked browser-shaped param normalization and structured request-edge `ParamError` behavior over the existing `Scrypath.search/3` runtime.
- **Phase 79 complete:** Locked one canonical `SearchModule` guide, thin Phoenix/README routing, bounded docs-contract coverage, and one direct wrapper-parity regression.
- **v1.20 close:** Search Module Foundation shipped and archived with a passed audit; the repo now has a thin, context-owned search-module layer without changing the canonical `v1.19` broader-adoption verdict.
- **v1.20 archive/code drift:** the archive currently claims `Scrypath.SearchModule` and its guide shipped, but the checked-out code does not expose that layer yet; reconcile the archive with code before treating the layer as fully grounded.
- **v1.21 open:** Reopen internal feature work only for a narrow-balanced slice: a framework-light public query-param toolkit plus thin optional Phoenix URL/form/LiveView helpers over the existing `Scrypath.search/3` path.
- **v1.21 guardrails:** contexts remain the application boundary, Phoenix stays optional, no public `%Scrypath.Query{}` contract ships, and this milestone does not widen into UI widgets, controller macros, or schema-generated runtime verbs.
- **v1.21 close:** The public request-edge toolkit, structured edge-error contract, optional pure Phoenix wrappers, canonical request-edge guide, and `mix verify.phase82` drift gate are now shipped and archived without widening the canonical runtime boundary.
- **v1.22 open:** Composition And Real-App Depth was activated as the next milestone because `v1.21` settled the request-edge contract and the remaining leverage-positive step inside the arc is reducing repeated real-app composition glue without turning Scrypath into a framework facade.
- **v1.22 roadmap:** The milestone is deliberately compressed into **three** phases starting at **Phase 83**: (**83**) preset/scope contract, (**84**) metadata reflection plus `search_many/2` parity, and (**85**) real-app proof plus drift gates.
- **v1.22 requirement coverage:** All **12** active requirements map exactly once across phases **83–85**; no tenant/auth, related-data, schema-generated runtime, or Phoenix-dependent core scope was admitted.
- **v1.22 close:** Composition And Real-App Depth shipped + archived in-repo on **2026-05-24** with a passed milestone audit, completed verification artifacts for phases **83–85**, and no active milestone reopened by default.
- **2026-05-24 repo-grounded assessment:** Scrypath looks roughly **86% done** for its stated scope: first schema, sync honesty, Phoenix integration, operator recovery, request-edge tooling, and bounded composition are all real, while outside-adopter proof, related-data propagation, and tenant-safe access remain the highest-leverage remaining gaps.
- **v1.23 open:** Reopen planning only for adopter-proof and trust-closure work. The next milestone is intentionally not another generic breadth slice; it exists to reconcile support/proof truth with the current tree, review real outside-adopter attempts, and decide whether Scrypath should stop soon or open one final product wedge.
- **v1.23 ranking locked at open:** if feature work reopens after outside-adopter review, the order is related-data propagation first, tenant-safe access second, and high-cardinality facet-value search third.
- **Support-truth drift found at open:** current planning opened with removed support/readiness surfaces and a stale `mix verify.adopter` fast target. Phase 86 is reconciling those seams back to branch-tip truth.
- **v1.23 close:** Outside-Adopter Evidence And Support-Truth Reconciliation shipped + archived in-repo on **2026-05-24**. Next-pull verdict is established: related-data propagation.
- **v1.24 open:** Related-Data and Dependency Propagation is now the active milestone to address the biggest correctness gap for real SaaS apps.
- [Phase ?]: Phase 91 plan 01 complete: rewrote guides/related-data-and-reindexing.md so Scrypath.sync_related/3 + internal RelatedWorker (sync_mode: :oban) are the canonical fan-out story; canonical strings locked as the shared contract for 91-02.
- [Phase ?]: Phase 91 plan 02 complete: verify.phase91 hermetic gate green (73 tests, 0 failures); docs-contract test inverted to lock sync_related/3 as canonical fan-out story; ExDoc hidden-module backtick fixed in guide (Rule 1 auto-fix).
- [Phase 91 plan 03 complete]: Phoenix example fan-out integration delivered — Author schema (Option A hand-written __scrypath__/1 accessors), Blog context with arity-safe resolver (records + ids + empty clauses), migration, extended Post schema, inline + oban fan-out smoke tests, and updated README. EXEC-02 demonstrable: Author rename re-syncs Post search docs on both inline and oban paths.
- **v1.24 close:** Related-Data and Dependency Propagation shipped + archived in-repo on **2026-05-25**. Next-pull verdict is tenant-safe search (AUTH-01).
- **v1.25 open:** Tenant-Safe Search is now the active milestone. AUTH-01 justified without waiting for further adopter evidence — the filter merge order bug is a concrete silent data-leak footgun for multi-tenant apps. Roadmap created 2026-05-25 with phases 92–94.
- **v1.25 roadmap rationale:** Phase 92 co-ships the canonical guide (TNNT-01) and `tenant_field:` declaration (TNNT-02) because the declaration and its documentation are co-dependent — shipping the option without the guide leaves adopters without a correct pattern. Phase 93 adds `schema_capabilities/1` reflection (TNNT-03) and `tenant_scope:` runtime enforcement (TNNT-04) — both depend on the `tenant_field:` groundwork from Phase 92. Phase 94 is a dedicated verification slice (TNNT-05) closing the hermetic gate and CI registration.

- **Phase 94 complete:** Created the `mix verify.phase94` gate, ran it (128 tests passing), and generated the milestone audit.
- **v1.25 close:** Tenant-Safe Search shipped + archived in-repo on **2026-05-26**. The `tenant_field:` option, `tenant_scope:` injection, and canonical multitenancy guide are all verified and complete. Next-pull verdict is TBD (awaiting adopter evidence or prioritization).

### Blockers / Concerns

- **Scope discipline for tenant-safe search:** Tenant ID must pass as an explicit argument through the context layer. Do not introduce automatic extraction from conn, plug assigns, or process dictionary — those break across Task.async, assign_async, and Oban workers.
- **Filter merge order is a silent footgun:** The filter merge order bug (Keyword.merge last-key-wins silently drops the tenant guard) is the highest-risk failure mode. The guide must contain working wrong/correct examples and `tenant_scope:` must hard-inject the filter at the library layer.
- **Scope discipline for the search-module arc:** Search modules must remain a thin context-owned layer over the existing runtime, not a slide into schema-generated APIs, Phoenix coupling, or hidden operational behavior.
- **Search-module archive drift:** `v1.20` archive files still claim a `Scrypath.SearchModule` layer, but the current checkout does not contain that module, its guide, or its tests. Treat the archive as historical/salvage-backed evidence, not as current shipped truth.
- **Future product ranking should stay evidence-bound:** do not let generic ergonomics or OPSUI breadth displace tenant-safe access or high-cardinality facet-value search unless the outside-adopter evidence actually points there.

### Deferred Items

(See **`.planning/PROJECT.md`** and **`.planning/MILESTONES.md`** for historical **audit-open** / quick-task ledger.)

- **v1.1 release-follow-through:** keep the closed-audit carry-forward visible but out of product milestone scope: (1) rerun the Phase 08 live verification seam only when a reachable `SCRYPATH_MEILISEARCH_URL` is available, and (2) rerun the Hex dry-run only when a publisher-scoped `HEX_API_KEY` is available. Source of truth: **`.planning/v1.1-MILESTONE-AUDIT.md`** and **`docs/releasing.md`**.
- **Salvage quarantine:** `salvage/20260508-151407-main-reconcile` preserves the pre-reconcile dirty worktree for forensic recovery only. Treat it as a mixed snapshot, not as a queued branch to re-land wholesale on `main`.
- **TNNT-FUT-01 deferred:** Per-tenant Meilisearch index routing — compliance/regulated use case only; not the default model due to Meilisearch sequential task processing at scale.
- **TNNT-FUT-02 deferred:** Tenant token generation helpers — host-app concern; Joken recipe belongs in the guide only, not as a library dependency.

### Nyquist audit ledger (AUDT-01 — immutable pointers)

Doc-contract tests require these maintainer artifact names remain discoverable from **STATE.md**: **`18-VERIFICATION.md`**, **`v1.4-MILESTONE-AUDIT.md`**, **`260416-eoj-SUMMARY.md`**, **`260416-if2-SUMMARY.md`**.

## Next Command

Run `/gsd:new-milestone` to propose and plan the next milestone.

---

*Last updated: 2026-05-26 — v1.26 Facet Value Vocabulary Search archived*

**Prior milestone:** **v1.26** — Facet Value Vocabulary Search — **2026-05-26** (shipped + archived in-repo).

**Completed:** **v1.25** shipped + archived in-repo (**2026-05-26**) — phases **92–94** — **`milestones/v1.25-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Completed:** **v1.24** shipped + archived in-repo (**2026-05-25**) — phases **89–91** — **`milestones/v1.24-{ROADMAP,REQUIREMENTS}.md`**.

**Completed:** **v1.22** shipped + archived in-repo (**2026-05-24**) — phases **83–85** — **`milestones/v1.22-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Completed:** **v1.21** shipped + archived in-repo (**2026-05-23**) — phases **80–82** — **`milestones/v1.21-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Completed:** **v1.20** shipped + archived in-repo (**2026-05-08**) — phases **77–79** — **`milestones/v1.20-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 91 P01 | ~2m | 2 tasks | 1 files |
| Phase 91 P02 | 10m | 2 tasks | 4 files |
| Phase 91 P03 | 20m | 3 tasks | 7 files |
| Phase 92 P03 | 15m | 2 tasks | 3 files |
| Phase 93 P01 | 3m | 2 tasks | 2 files |
| Phase 93 P02 | 5m | 3 tasks | 2 files |
