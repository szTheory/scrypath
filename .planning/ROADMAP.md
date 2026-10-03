# Roadmap: Scrypath

## Milestones

- 🚧 **v1.42 ScrypathOps operator/admin UI** — Phase 172 (1 phase; roadmap ready 2026-10-03)
- ✅ **v1.41 Readiness Gate Follow-Through** — Phases 168–171 (4 phases, 19 plans; archived 2026-10-02; `tech_debt` accepted; original Phase 170 decision remains NOT READY at its cutoff; later separate readiness assessment is READY) — [archive](milestones/v1.41-ROADMAP.md)
- ✅ **v1.40 Readiness Evidence Closure** — Phases 165–167 (archived locally 2026-09-27; no Hex release; assessment remains NOT READY) — [archive](milestones/v1.40-ROADMAP.md)
- ✅ **v1.39 Pre-Operator UI Quality Readiness Ratchet** — Phases 162–164 (archived locally 2026-09-26) — [archive](milestones/v1.39-ROADMAP.md)
- ✅ **v1.38 Packaged Adopter Proof** — Phases 160–161 (shipped 2026-09-25; `scrypath 0.3.13`) — [archive](milestones/v1.38-ROADMAP.md)
- ✅ **v1.37 Code Quality Ratchet** — Phases 148–159 (shipped 2026-08-26) — [archive](milestones/v1.37-ROADMAP.md)
- ✅ **v1.36 Dependency Security Remediation** — Phases 144–147 (shipped 2026-08-25) — [archive](milestones/v1.36-ROADMAP.md)
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137–143 (shipped 2026-06-24) — [archive](milestones/v1.35-ROADMAP.md)
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128–136 (shipped 2026-06-29) — [archive](milestones/v1.34-ROADMAP.md)

## Current Posture

v1.41 completed all nine requirements across Phases 168–171 and is archived at [the v1.41 audit](milestones/v1.41-MILESTONE-AUDIT.md). The audit records 9/9 requirements, 4/4 phases, 6/6 integration paths, and 3/3 end-to-end flows with no gaps. It accepts nonblocking Nyquist validation-record debt in Phases 168–170. Phase 170 Plan 08 is complete in current GSD tracking (8/8); the attested `8c271…` source snapshot remains historical 17/18 with its original planning bytes preserved separately. The original dated maintainer decision remains **NOT READY** at [issue #86 comment 5940381507](https://github.com/szTheory/scrypath/issues/86#issuecomment-5940381507); a later, separate READY assessment is recorded at [issue #86 comment 5955742805](https://github.com/szTheory/scrypath/issues/86#issuecomment-5955742805), within its stated limits. Scrypath 0.3.14 publication, tag/Hex parity, and exact-main closeout passed in runs [36915979826](https://github.com/szTheory/scrypath/actions/runs/36915979826) and [36930660896](https://github.com/szTheory/scrypath/actions/runs/36930660896).

**Active milestone:** v1.42 is authorized by the maintainer's 2026-10-03 direction. Its eight requirements supersede the earlier four proposed incident-only requirements and cover demonstrated shared UI repairs plus verified incident recovery. Phase 172 is ready for its UI contract and implementation plans; another approval of the established direction is unnecessary. Keep `main` green and release only when a package change warrants it. Do not rerun Phase 170 or treat its frozen NOT READY assessment as the later readiness result. Historical “What's next” statements in the milestone index describe their archive cutoffs; this active posture controls current work.

## v1.42 — ScrypathOps operator/admin UI

**Milestone goal:** Operators can use a consistent, legible interface across the six existing surfaces and recover a search incident without losing its schema or mistaking accepted work for verified success.

**Scope:** [OPUX-01–OPUX-08](REQUIREMENTS.md), grounded in [the current UI reviews](research/v1.42/SUMMARY.md) and [the durable UI quality default](reference/OPERATOR-UI-QUALITY.md). Preserve the existing shell, palette, Phoenix components, public core APIs, and host authorization boundaries. Fix demonstrated problems; resolve visual hypotheses against current rendering before adding work.

**Structure:** One coherent phase owns the shared controls, affected screen behavior, recovery proof, and delivery. These changes serve the same existing operator journey and share the same acceptance evidence. Separate UI polish, test-only, or documentation-only phases would split that outcome and repeat completed v1.32–v1.34 work. Granularity is standard (config omits an explicit value); phase IDs are sequential (default).

## Phases

- [ ] **Phase 172: Consistent Operator UI and Verified Recovery** - Operators can navigate readable, accessible screens and verify recovery for the selected schema with trustworthy task and index evidence.

## Phase Details

### Phase 172: Consistent Operator UI and Verified Recovery

**Goal**: Operators can use the existing six surfaces consistently and complete a schema-preserving incident-recovery journey whose visible result matches actual backend state.
**Depends on**: Phase 171 (complete); the later source-bounded READY assessment and the maintainer's 2026-10-03 direction authorize this scope. No prior phase is reopened.
**Requirements**: OPUX-01, OPUX-02, OPUX-03, OPUX-04, OPUX-05, OPUX-06, OPUX-07, OPUX-08
**Success Criteria** (what must be TRUE):

1. Operators can read and use Control Room, Posture, Failed Sync, Sync/Drift, Search, and Playbooks at narrow and desktop widths with coherent shared visual roles and domain terms. Common actions and actionable reasons stay visible; Failed Sync's mobile summaries leave the records prominent; setup, empty, error, and partial states identify the next supported action. The catalog describes the components and tokens actually used.
2. Operators can use affected forms, modes, schema selectors, and file-action dialogs with a keyboard and assistive technology. Names, help, selected and disabled states are exposed, focus is visible, and dialogs contain focus through Tab/Shift-Tab, dismiss correctly, and return focus to their trigger.
3. Operators retain an allowed schema through Posture → Failed Sync → Sync/Drift, refresh, and browser back navigation. An invalid or unavailable selection produces a safe, explicit fallback and cannot silently submit an action against another target.
4. Operators can recover a known replayable failure by following rendered controls from Control Room through the recovery screens, with new work correlated to terminal backend success and the expected document in the active index. They can distinguish accepted/running work, success, failure, timeout, stale/unknown checks, and retained failure history. Recovery does not require promotion; advanced promotion uses the same current eligibility rules in its UI and server handler and never claims completion on task acceptance.
5. Maintainers can reproduce the changed behavior and meaningful responsive, keyboard, layout, and both-theme contrast checks through existing test/CI lanes, inspect before/after screenshots and retained failure diagnostics, and trace all eight requirements to actual evidence. Reviewed PR-first delivery has current required CI and exact-final-source closeout evidence, an explicit release/no-release decision, committed task-owned work, and recorded preview cleanup or intentional retention, with no pending routine human UAT or paid AI judge.

**Plans**: 3/8 plans executed

**Wave 1**
- [x] 172-01-PLAN.md — Readable shared controls and one shell shortcut tracer.

**Wave 2 (after Wave 1; disjoint ownership)**
- [x] 172-02-PLAN.md — Semantic forms and complete file-dialog interaction.
- [x] 172-03-PLAN.md — Schema-preserving navigation and compact failed-work triage.

**Wave 3 (after shared dialog and schema contracts)**
- [ ] 172-04-PLAN.md — Exact replacement-job/task/document recovery observation.

**Wave 4 (after recovery context)**
- [ ] 172-05-PLAN.md — Shared current promotion eligibility and honest swap progress.

**Wave 5 (after complete recovery surfaces)**
- [ ] 172-06-PLAN.md — Deterministic real mounted recovery and strict swap oracles.

**Wave 6 (after mounted identity proof)**
- [ ] 172-07-PLAN.md — Representative layout, keyboard, theme and screenshot evidence.

**Wave 7 (after all implementation evidence)**
- [ ] 172-08-PLAN.md — Review, PR delivery, release decision, completion tracking and final attestation.

**Cross-cutting constraints:** Preserve the existing shell/palette/48components; keep schema/context identity and failure history truthful; isolate seeded verification from preview4012; use existing lanes; commit all completion records before final attestation. See `172-SOURCE-AUDIT.md` in the phase directory for full requirement/decision/probe coverage.
**UI hint**: yes

#### Recommended implementation order

1. Establish the bounded UI contract from the six-screen inventory and captured baseline. Set readable type roles, component semantics, layering, vocabulary, and representative states/widths; reuse settled v1.32–v1.34 decisions. Inventory the 48 shipped `OpsUi` components and record concrete finding dispositions without rebuilding the design system.
2. Repair shared controls and affected layouts/copy with focused checks alongside each change. Prioritize dialog focus, labels/descriptions, mode selection and disabled semantics, readable action labels, mobile Failed Sync hierarchy, and explicit setup/partial/error guidance. Keep common actions visible and verbose evidence secondary.
3. Carry validated schema identity across the incident route and make recovery/current-check/promotion outcomes truthful. In the same slice, establish the replayable fixture and correlate newly created work, its terminal task, and unique document evidence through the rendered browser journey. Prove invalid selection, stale checks, refusal/failure/timeout, and retained-history boundaries at the cheapest reliable layer.
4. Complete focused responsive/keyboard/contrast proof, inspect matched before/after captures, and run the existing broad advisory matrix once when shared changes justify it. Review the PR, resolve material findings, reconcile requirement evidence, then complete the existing candidate/final exact-SHA closeout and cleanup protocol. Commit final tracking before the final attestation; do not edit its tracked source afterward.

#### Acceptance and evidence boundaries

- The UI source baseline is `3c83a58c9bc5af70a204957431ff66fd9db035de`; the current requirement record is committed at `a00bd5d`. The three specialist reports are planning evidence and their screenshots are bounded observations. Neither is a fresh runtime acceptance result.
- Reuse `mix verify.ops_ui`, existing component/LiveView contracts, the static contrast command, and the required mounted browser lane. Keep the full screenshot/contrast matrix advisory and inspect actual job/step results when citing it. An inventory check, contrast-only scan, mock visual judge, or passing unrelated CI cannot establish layout, accessibility, or recovery claims.
- The recovery oracle must reject old successful tasks, unrelated existing documents, the intentionally unrecoverable display fixture, and task acceptance alone. Identify the selected runtime schema/index, newly created work and expected document; assert terminal outcome and honest UI state. Retained failures need not disappear and a globally green dashboard is not an acceptance condition. Promotion remains independently bounded by existing capabilities.
- Cover changed behavior and representative light/dark, narrow/wide, keyboard, long-content, and stale/error states. Use browser geometry/focus checks where DOM tests cannot prove the behavior. Retain source/state/theme/viewport and work identities in diagnostics; a pass after retry remains flaky evidence. Measure incremental runtime rather than adding a broad recurring matrix or a new CI job by default.
- Keep the optional feedback preview at `http://127.0.0.1:4012/admin/search` (`scrypath-ui-v142`) separate from disposable seeded verification. Current captures are outside tracked source under `/private/tmp/scrypath-v142-review/`. Record preview ownership and the stop command at closeout; preserve unrelated services/worktrees/stashes.
- Historical evidence is reusable only within its source/scenario limits and after relevant changes are considered. The original Phase 170 NOT READY decision, later READY assessment, preserved frozen bytes, and inherited unresolved assumptions remain distinct. No Phase 170 replay, new public API, authorization product, backend abstraction, palette replacement, or forced release is part of this phase.

## Progress

**Execution Order:** Phase 172, with its UI contract and checked implementation plans before execution.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 172. Consistent Operator UI and Verified Recovery | v1.42 | 3/8 | In Progress|  |

**Coverage:** 8/8 current requirements mapped exactly once; no orphaned or duplicate assignments. Criteria 1–5 cover OPUX-01/03, OPUX-02, OPUX-04, OPUX-05/06, and OPUX-07/08 respectively.

_Completed milestone requirements and full phase details remain in their unchanged archives under `milestones/`._
