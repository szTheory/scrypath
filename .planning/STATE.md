---
gsd_state_version: 1.0
milestone: v1.22
milestone_name: Composition And Real-App Depth
status: ready_to_plan
last_updated: 2026-05-23T14:15:09.682Z
last_activity: 2026-05-23
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 3
  completed_plans: 16
  percent: 0
stopped_at: Phase 83 complete (3/3) — ready to discuss Phase 84
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-23)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** Phase 84 — metadata reflection and multi search parity

## Current Position

Phase: 84
Plan: Not started

**Status:** Ready to plan

**Last activity:** 2026-05-23

## Accumulated Context

### Decisions

(See `.planning/PROJECT.md` Key Decisions.)

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

### Blockers / Concerns

- **Outside adopter evidence remains pending:** Plan 01 reran the live proof successfully after starting the documented example services, but the milestone still has no reviewed real outside adopter signal. The canonical wording and residuals live in **`.planning/milestones/v1.19-MILESTONE-AUDIT.md`**.
- **Diminishing-returns guardrail:** In the absence of real adopter evidence, additional internal proof/polish work is presumed low leverage and should not become the next milestone by default.
- **Scope discipline for the search-module arc:** Search modules must remain a thin context-owned layer over the existing runtime, not a slide into schema-generated APIs, Phoenix coupling, or hidden operational behavior.
- **Search-module archive drift:** `v1.20` planning claims a `Scrypath.SearchModule` layer, but the current checkout does not contain that module or its guide. Treat that as a reconciliation task, not as settled product truth.
- **Public param grammar risk:** `v1.21` froze browser-shaped param semantics on purpose; future composition work should extend that contract only with real adopter pressure.
- **v1.22 scope guard:** Composition work must stay bounded to reusable presets/scopes, `search_many/2`-aligned composition, and UI metadata exposure; no schema-generated runtime verbs, UI widgets, or Phoenix-coupled runtime core should slip in under this milestone.
- Existing `71`–`73` phase directories remain in `.planning/phases/` in the working tree; phase numbering continues at `74`, so no collision exists for this milestone open.

### Deferred Items

(See **`.planning/PROJECT.md`** and **`.planning/MILESTONES.md`** for historical **audit-open** / quick-task ledger.)

- **v1.1 release-follow-through:** keep the closed-audit carry-forward visible but out of product milestone scope: (1) rerun the Phase 08 live verification seam only when a reachable `SCRYPATH_MEILISEARCH_URL` is available, and (2) rerun the Hex dry-run only when a publisher-scoped `HEX_API_KEY` is available. Source of truth: **`.planning/v1.1-MILESTONE-AUDIT.md`** and **`docs/releasing.md`**.
- **Salvage quarantine:** `salvage/20260508-151407-main-reconcile` preserves the pre-reconcile dirty worktree for forensic recovery only. Treat it as a mixed snapshot, not as a queued branch to re-land wholesale on `main`.

### Nyquist audit ledger (AUDT-01 — immutable pointers)

Doc-contract tests require these maintainer artifact names remain discoverable from **STATE.md**: **`18-VERIFICATION.md`**, **`v1.4-MILESTONE-AUDIT.md`**, **`260416-eoj-SUMMARY.md`**, **`260416-if2-SUMMARY.md`**.

## Next Command

1. Review `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` for the Phase **83–85** mapping.
2. Run `$gsd-discuss-phase 83`.
3. Keep the post-`v1.19` outside-adopter guardrail explicit while shaping composition scope.

---

*Last updated: 2026-05-23 — roadmap created for **v1.22 Composition And Real-App Depth***

**Prior milestone:** **v1.19** — Production adoption proof and hardening — **2026-04-28** (shipped + archived in-repo).

**Completed:** **v1.19** shipped + archived in-repo (**2026-04-28**) — phases **74–76** — **`milestones/v1.19-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Completed:** **v1.18** shipped + archived in-repo (**2026-04-26**) — phases **71–73** — **`milestones/v1.18-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Completed:** **v1.17** shipped + archived in-repo (**2026-04-23**) — phases **68–70** — **`milestones/v1.17-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Completed:** **v1.21** shipped + archived in-repo (**2026-05-23**) — phases **80–82** — **`milestones/v1.21-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Next:** Discuss and plan **Phase 84 — Metadata Reflection And Multi-Search Parity**.
