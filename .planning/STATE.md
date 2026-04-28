---
gsd_state_version: 1.0
milestone: v1.19
milestone_name: Production adoption proof and hardening
status: completed
last_updated: "2026-04-28T13:05:00Z"
last_activity: 2026-04-28
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 8
  completed_plans: 13
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-28)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** v1.19 closed; use `.planning/milestones/v1.19-MILESTONE-AUDIT.md` as the canonical next-step verdict

## Current Position

Phase: 76 — COMPLETE
Plan: 2 of 2

**Status:** Phase 76 complete; v1.19 closed as a readiness checkpoint with external validation still pending

**Last activity:** 2026-04-28

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

### Blockers / Concerns

- **Outside adopter evidence remains pending:** Plan 01 reran the live proof successfully after starting the documented example services, but the milestone still has no reviewed real outside adopter signal. The canonical wording and residuals live in **`.planning/milestones/v1.19-MILESTONE-AUDIT.md`**.
- Existing `71`–`73` phase directories remain in `.planning/phases/` in the working tree; phase numbering continues at `74`, so no collision exists for this milestone open.

### Deferred Items

(See **`.planning/PROJECT.md`** and **`.planning/MILESTONES.md`** for historical **audit-open** / quick-task ledger.)

### Nyquist audit ledger (AUDT-01 — immutable pointers)

Doc-contract tests require these maintainer artifact names remain discoverable from **STATE.md**: **`18-VERIFICATION.md`**, **`v1.4-MILESTONE-AUDIT.md`**, **`260416-eoj-SUMMARY.md`**, **`260416-if2-SUMMARY.md`**.

## Next Command

1. Review **`.planning/milestones/v1.19-MILESTONE-AUDIT.md`** before choosing the next milestone so the broader-adoption verdict remains canonical.
2. Seek real outside adopter evidence through the bounded intake path before reopening in-repo breadth.
3. **`/gsd-progress`** — snapshot the post-close state if you want a fresh planning baseline.

---

*Last updated: 2026-04-28 — closed **v1.19 — Production adoption proof and hardening** as a readiness checkpoint*

**Prior milestone:** **v1.18** — Sigra integration — **2026-04-26** (shipped + archived in-repo).

**Completed:** **v1.19** shipped + archived in-repo (**2026-04-28**) — phases **74–76** — **`milestones/v1.19-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Completed:** **v1.18** shipped + archived in-repo (**2026-04-26**) — phases **71–73** — **`milestones/v1.18-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Completed:** **v1.17** shipped + archived in-repo (**2026-04-23**) — phases **68–70** — **`milestones/v1.17-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Next:** use **`milestones/v1.19-MILESTONE-AUDIT.md`** as the canonical checkpoint verdict before opening another milestone.

**Completed Phase:** 76 (Evidence-backed hardening and release-readiness checkpoint) — 2/2 plans — 2026-04-28

**Planned Phases:** none currently open.
