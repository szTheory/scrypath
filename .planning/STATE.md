---
gsd_state_version: 1.0
milestone: v1.20
milestone_name: Search Module Foundation
status: shipped
last_updated: "2026-05-08T21:15:00Z"
last_activity: 2026-05-08
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-08)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** Post-v1.20 milestone transition — keep the search-module arc narrow and decide whether `v1.21` is worth opening

## Current Position

Phase: 79 — Complete
Plan: —

**Status:** `v1.20` shipped and archived; no active milestone is currently open

**Last activity:** 2026-05-08 — Archived `v1.20` and advanced rolling planning truth to post-close posture

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

### Blockers / Concerns

- **Outside adopter evidence remains pending:** Plan 01 reran the live proof successfully after starting the documented example services, but the milestone still has no reviewed real outside adopter signal. The canonical wording and residuals live in **`.planning/milestones/v1.19-MILESTONE-AUDIT.md`**.
- **Diminishing-returns guardrail:** In the absence of real adopter evidence, additional internal proof/polish work is presumed low leverage and should not become the next milestone by default.
- **Scope discipline for the search-module arc:** Search modules must remain a thin context-owned layer over the existing runtime, not a slide into schema-generated APIs, Phoenix coupling, or hidden operational behavior.
- Existing `71`–`73` phase directories remain in `.planning/phases/` in the working tree; phase numbering continues at `74`, so no collision exists for this milestone open.

### Deferred Items

(See **`.planning/PROJECT.md`** and **`.planning/MILESTONES.md`** for historical **audit-open** / quick-task ledger.)

- **Salvage quarantine:** `salvage/20260508-151407-main-reconcile` preserves the pre-reconcile dirty worktree for forensic recovery only. Treat it as a mixed snapshot, not as a queued branch to re-land wholesale on `main`.

### Nyquist audit ledger (AUDT-01 — immutable pointers)

Doc-contract tests require these maintainer artifact names remain discoverable from **STATE.md**: **`18-VERIFICATION.md`**, **`v1.4-MILESTONE-AUDIT.md`**, **`260416-eoj-SUMMARY.md`**, **`260416-if2-SUMMARY.md`**.

## Next Command

1. Treat Scrypath as paused for internal feature development unless real outside adopter evidence or a clearly leverage-positive release need justifies reopening.
2. If reopening the active arc, evaluate **v1.21 — Query Toolkit And Phoenix Edge Helpers** against that bar first.
3. Start the next milestone with **`$gsd-new-milestone`** so fresh requirements and roadmap scope are defined explicitly.

---

*Last updated: 2026-05-08 — archived **v1.20 Search Module Foundation***

**Prior milestone:** **v1.19** — Production adoption proof and hardening — **2026-04-28** (shipped + archived in-repo).

**Completed:** **v1.19** shipped + archived in-repo (**2026-04-28**) — phases **74–76** — **`milestones/v1.19-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Completed:** **v1.18** shipped + archived in-repo (**2026-04-26**) — phases **71–73** — **`milestones/v1.18-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Completed:** **v1.17** shipped + archived in-repo (**2026-04-23**) — phases **68–70** — **`milestones/v1.17-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Next:** Open a fresh milestone only if `v1.21` still clears the post-`v1.19` leverage bar.

**Completed Phase:** 79 (Docs, examples, and contract coverage) — 2/2 plans — 2026-05-08

**Planned Phases:** none until a new milestone opens.
