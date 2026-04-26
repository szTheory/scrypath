---
gsd_state_version: 1.0
milestone: v1.18
milestone_name: — in progress)
status: ready_to_plan
last_updated: "2026-04-26T06:12:53Z"
last_activity: 2026-04-26
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 3
  completed_plans: 2
  percent: 17
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-25)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** Phase 72 — sensitive-action-wiring-in-opsui-liveviews

## Current Position

Phase: 72 (sensitive-action-wiring-in-opsui-liveviews) — READY TO PLAN
Plan: Not started

**Status:** Ready to plan

**Last activity:** 2026-04-26

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
- **Phase 65 discuss:** Hybrid catalog **Run now** + shared draft pipeline; **`start_async`/`handle_async`** lifecycle with **`run_id`**, timeout, **`cancel_async`**; **`scrypath_ops`** error registry + **`DocResolver`**; **no** Oban/DB default run path in this phase (deferred).
- Kept Runner.run_validated/3 as the canonical raw tuple seam and documented reason identity as the compatibility key.
- Kept playbook-schema-v1.md authoritative for JSON wire format only and linked execution semantics to the Runner moduledoc.
- Phase 66 plan 02: runner parity tests compare direct Scrypath calls to Runner.run_validated/3 on the same fixtures.
- Phase 66 plan 02: playbook dispatch preserves absent page opts and coerces JSON facet names so runner semantics match core search contracts.
- Pinned the audit-prefix contract to the Sigra 0.2.5 reserved-prefix set surfaced by `Sigra.Audit.log_multi/3`, because the dependency does not expose a public `reserved_prefixes/0` accessor.
- Implemented the fence as a standard Mix task with a pure `check/1` seam so the rule set is testable without shelling out.

### Blockers / Concerns

- **None.**

### Deferred Items

(See **`.planning/PROJECT.md`** and **`.planning/MILESTONES.md`** for historical **audit-open** / quick-task ledger.)

### Nyquist audit ledger (AUDT-01 — immutable pointers)

Doc-contract tests require these maintainer artifact names remain discoverable from **STATE.md**: **`18-VERIFICATION.md`**, **`v1.4-MILESTONE-AUDIT.md`**, **`260416-eoj-SUMMARY.md`**, **`260416-if2-SUMMARY.md`**.

## Next Command

1. **`/gsd-discuss-phase 71`** — gather context and clarify the foundation-phase approach (compile-guard shape, OperatorContext field hydration sources, gating funnel ergonomics, audit-prefix taxonomy) before planning. **Recommended next step.**
2. **`/gsd-plan-phase 71`** — produce **`71-{01,02,03}-PLAN.md`** once discussion locks the gray areas.
3. **`/gsd-progress`** — snapshot the v1.18 opening state.

---

*Last updated: 2026-04-25 — **v1.18 — Sigra integration** opened; SIGRA-01..10 requirements and phases 71–73 roadmap committed*

**Prior milestone:** **v1.17** — Integration confidence & adopter proof — **2026-04-23** (readiness checkpoint).

**Completed:** **v1.16** shipped + archived in-repo (**2026-04-22**) — phases **65–67** — **`milestones/v1.16-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Completed:** **v1.17** shipped + archived in-repo (**2026-04-23**) — phases **68–70** — **`milestones/v1.17-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Next:** **`/gsd-discuss-phase 71`** to clarify foundation-phase gray areas before plan generation.

**Completed Phase:** 70 (Papercuts and readiness checkpoint) — 2/2 plans — 2026-04-23

**Planned Phases:** 71 (foundation, 3 plans), 72 (LiveView wiring, 2 plans), 73 (guide + worked example, 2 plans) — see **`.planning/ROADMAP.md`** § *Phases (milestone v1.18 — in progress)*.
