# Roadmap: Scrypath

## Milestones

- 📋 **v1.43 ScrypathOps UI refinement** — Phases 173–177 (5 approved phases, 0 plans; ready for Phase 173 discussion)
- ✅ **v1.42 ScrypathOps operator/admin UI** — Phase172 (1 phase, 8 plans; archived2026-10-04) — [archive](milestones/v1.42-ROADMAP.md)
- ✅ **v1.41 Readiness Gate Follow-Through** — Phases 168–171 (4 phases, 19 plans; archived 2026-10-02; `tech_debt` accepted; original Phase 170 decision remains NOT READY at its cutoff; later separate readiness assessment is READY) — [archive](milestones/v1.41-ROADMAP.md)
- ✅ **v1.40 Readiness Evidence Closure** — Phases 165–167 (archived locally 2026-09-27; no Hex release; assessment remains NOT READY) — [archive](milestones/v1.40-ROADMAP.md)
- ✅ **v1.39 Pre-Operator UI Quality Readiness Ratchet** — Phases 162–164 (archived locally 2026-09-26) — [archive](milestones/v1.39-ROADMAP.md)
- ✅ **v1.38 Packaged Adopter Proof** — Phases 160–161 (shipped 2026-09-25; `scrypath 0.3.13`) — [archive](milestones/v1.38-ROADMAP.md)
- ✅ **v1.37 Code Quality Ratchet** — Phases 148–159 (shipped 2026-08-26) — [archive](milestones/v1.37-ROADMAP.md)
- ✅ **v1.36 Dependency Security Remediation** — Phases 144–147 (shipped 2026-08-25) — [archive](milestones/v1.36-ROADMAP.md)
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137–143 (shipped 2026-06-24) — [archive](milestones/v1.35-ROADMAP.md)
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128–136 (shipped 2026-06-29) — [archive](milestones/v1.34-ROADMAP.md)

## Current Posture

**v1.43 scope/version, inventory reuse, all 20 requirements, and this five-phase roadmap were explicitly approved on 2026-10-06. Phase 173 is ready for discussion; no implementation has started.** Numbering continues at Phase 173. v1.42 completed Phase172:8 plans,8 requirements, independent verification38/38 truths,6/6 integration connections and5/5 flows. See the [milestone audit](milestones/v1.42-MILESTONE-AUDIT.md).

PR91 delivered the operator UI and recovery corrections; ReleasePleasePR92 published Scrypath0.3.15 at `8dd20e8966acd17a4ef5acec653c00dc31faab49`. [Publish run37181522723](https://github.com/szTheory/scrypath/actions/runs/37181522723) passed live Hex/consumer/HexDocs and package/tag parity. Both task-owned verifier stacks are removed; preview4012 is intentionally retained for optional feedback.

All completion and archive records precede the enclosing final exact-source attestation. Its receipt is external to the final source. No completed phase should be replayed. The v1.43 requirements and roadmap are approved; the next lifecycle command is `$gsd-discuss-phase 173`, followed by `$gsd-ui-phase 173` for the comp-first UI contract and `$gsd-plan-phase 173`. Discussion and the UI contract settle the visual approach before implementation planning; no phase execution has begun.

The original Phase170 NOT READY decision and frozen17/18 snapshot remain historical; its separately authorized tracking replacement and later READY assessment remain distinct in the v1.41 archive. Nothing in v1.42 rewrites those decisions or resolves inherited assumptions beyond their stated limits.

## v1.43 ScrypathOps UI refinement

**Milestone goal:** Operators can inspect, recover, and verify search across the six existing surfaces with a calmer shared visual language, clear safe actions, and truthful task/index/document evidence.

**Status:** Requirements and roadmap explicitly approved on 2026-10-06. Phase 173 is ready for discussion. Phases 173–177 have no implementation plans, execution, or verification yet.

**Overview:** Establish the shared light/dark visual treatment and operational time behavior first, then refine the recovery entry, diagnosis, repair, and verification journey. Clarify Search and Playbooks within that visual world, and finish by consolidating patterns demonstrated on all six surfaces with source-bounded delivery evidence. Each phase proves its own changed behavior with relevant executable checks and direct before/after visual inspection; Phase 177 does not defer earlier acceptance. Reuse the v1.42 inventories as orientation and recheck touched source, without replaying completed fixes.

**Design sequence:** Discuss Phase 173 next. Use the installed Impeccable Operate guidance with root `PRODUCT.md` and `DESIGN.md` to compare realistic degraded Search health comps in light and dark before broad visual implementation. The comps include zero/error/unknown metrics, queue failures, long identifiers and times, quiet-action states, and the theme selector. Capture the selected treatment in Phase 173 `UI-SPEC.md` through `$gsd-ui-phase 173` before `$gsd-plan-phase 173`. Later frontend phases refine their UI contracts within that treatment. Preserve the existing UI phase and safety gates.

**Boundaries:** Retain host-owned authorization and mutation confirmation/eligibility, selected allowed-schema handoffs, full schema/index/task IDs, retained failure history, and accepted/running/terminal/unknown distinctions. Confirm completion from authoritative task/index/document evidence. Preserve light/dark/System, keyboard/focus, reduced motion, and standalone/mounted behavior. This milestone adds no core API, backend or auth product, infrastructure automation, UI surface, framework, new required CI service, or paid visual judge. Use disposable stacks for mutating browser proof; retain the feedback preview at `http://127.0.0.1:4012/admin/search` and unrelated working-tree changes.

## Phases

- [ ] **Phase 173: Shared Visual Foundation and Operational Time** - Operators see one calm, truthful visual language and usable time/copy feedback in the existing shell and representative Search health view.
- [ ] **Phase 174: Recovery Entry and Diagnosis** - Operators can identify affected work and reach the next safe recovery action across Control Room, Search health, and Failed sync work.
- [ ] **Phase 175: Repair and Verification** - Operators can distinguish observation, repair, and promotion, then verify actual outcomes in Sync and drift.
- [ ] **Phase 176: Search and Playbooks** - Operators can run searches and saved checks with clear common actions, results, and safe occasional controls.
- [ ] **Phase 177: Shared Patterns and Delivery Proof** - Operators encounter the demonstrated patterns consistently on all six surfaces and maintainers can inspect source-bounded delivery evidence.

## Phase Details

### Phase 173: Shared Visual Foundation and Operational Time
**Goal**: Operators can read state and act on it through a coherent neutral visual foundation, one theme preference, and trustworthy operational time feedback.
**Depends on**: Nothing in v1.43; Phase 172 is complete and archived.
**Requirements**: OPUX-09, OPUX-10, OPUX-11, OPUX-12, OPUX-13, OPUX-14, OPUX-15
**Success Criteria** (what must be TRUE):
  1. In light, dark, System, and responsive layouts, operators see a flat neutral shell; degraded/failed/unknown states have explicit text and restrained local cues, while zero-error metrics remain neutral and never imply document freshness.
  2. Operators see exactly one selected theme preference, including System while OS appearance changes, with visual and accessible state agreeing across reload, navigation, and tabs.
  3. Shared quiet actions remain recognizable and usable in both themes through hover, focus, pressed, selected, disabled, and busy states; a busy action keeps its meaningful icon and label.
  4. Operators can read stable human-readable last-success times, inspect the exact timestamp and timezone, and distinguish absent or unobserved success from observed success.
  5. In standalone and mounted Ops, operators can copy the full ISO last-success timestamp by keyboard or pointer and receive brief confirmation only after success; denied/unavailable clipboard access is explained, and routine Checked metadata offers no copy action.
**Plans**: TBD
**UI hint**: yes
**Acceptance**: Compare realistic degraded Search health light/dark comps before planning; inspect representative before/after desktop/mobile renders and use existing theme, accessibility, contrast, component, and focused browser checks for changed controls and states.

### Phase 174: Recovery Entry and Diagnosis
**Goal**: Operators can enter an incident, identify the affected schema/work and next safe action, and carry their chosen allowed schema through diagnosis.
**Depends on**: Phase 173
**Requirements**: OPUX-16, OPUX-17, OPUX-18, OPUX-19
**Success Criteria** (what must be TRUE):
  1. Control Room leads with the current state, affected search scope, and next safe action in a clear reading order, without repeated explanation or competing secondary controls.
  2. Search health presents worst-first schema records with complete readable identifiers and times, one meaningful surface per schema, plain Backend/Queue groups, clear section spacing, and concise next-check actions.
  3. Failed sync work exposes the failure reason, work/source identity, and eligibility of the common supported recovery action before optional verbose evidence; retained failure history and safety gates remain visible.
  4. After changing schema in the rendered UI, operators keep that allowed selection through recovery handoffs, refresh, and back navigation; invalid or unavailable targets never turn into actions on another schema.
**Plans**: TBD
**UI hint**: yes
**Acceptance**: Inspect before/after recovery views in both themes and relevant widths; run focused rendered-navigation, focus/layout, state, and mounted handoff proof in existing lanes, including a changed schema selection.

### Phase 175: Repair and Verification
**Goal**: Operators can choose a supported repair or advanced promotion safely and tell what actually happened from authoritative evidence.
**Depends on**: Phase 174
**Requirements**: OPUX-20, OPUX-21, OPUX-22
**Success Criteria** (what must be TRUE):
  1. Sync and drift separates index-contract drift from document freshness, observation from mutation, and ordinary repair from advanced promotion, with a clear next step for each applicable state.
  2. Operators can distinguish accepted, running, terminal success/failure, and unavailable or unknown observations while retaining exact task identity; an observation failure cannot appear as a failed remote task.
  3. Operators can review and perform only eligible, host-authorized repair or promotion behind existing confirmation gates, and see completion only when the matching task/index/document evidence supports it rather than when work is merely accepted or an unrelated historical task finishes.
**Plans**: TBD
**UI hint**: yes
**Acceptance**: Inspect before/after Sync and drift states in both themes and relevant widths; exercise confirmation/eligibility, rendered controls, exact task and document correlations, and mounted repair/promotion paths in disposable stacks.

### Phase 176: Search and Playbooks
**Goal**: Operators can run searches and saved checks with a clear input-to-result flow and safe, discoverable management controls.
**Depends on**: Phase 175
**Requirements**: OPUX-23, OPUX-24, OPUX-25
**Success Criteria** (what must be TRUE):
  1. Search makes target/query controls, one primary run action, and results easy to scan; empty, error, partial, disabled, and optional diagnostic states remain usable without duplicate run actions.
  2. Playbooks clearly distinguishes preview, execution, results, and saving; common run/save actions lead while existing workspace, import, validation, and read-only behavior remains available.
  3. Operators can find rename, duplicate, and delete without those occasional actions competing with common work; destructive confirmation and dialog keyboard, validation, focus containment/return, and LiveView patch behavior remain correct.
**Plans**: TBD
**UI hint**: yes
**Acceptance**: Inspect before/after Search and Playbooks in both themes and relevant widths; exercise changed forms and dialogs through rendered controls with existing LiveView, focus/layout, and focused browser checks.

### Phase 177: Shared Patterns and Delivery Proof
**Goal**: Operators receive a consistent six-surface workspace, and maintainers can trace the delivered behavior to bounded, reviewable evidence.
**Depends on**: Phase 176
**Requirements**: OPUX-26, OPUX-27, OPUX-28
**Success Criteria** (what must be TRUE):
  1. Across Control Room, Search health, Failed sync work, Sync and drift, Search, and Playbooks, operators encounter the same demonstrated grouping, action, status, and feedback vocabulary; the delivered token/component catalog and `DESIGN.md` describe it without an arbitrary component count or superseded styling.
  2. Operators can use the refined paths in light, dark, and System appearance at narrow and desktop widths, with keyboard/focus and reduced-motion behavior intact; direct before/after inspection and relevant executable layout/state/contrast proof are available for every slice, with mounted evidence for changed recovery seams.
  3. Maintainers can trace all 20 requirements to committed verification and reviewed PR-first source/CI evidence, see the explicit release or no-release decision, and inspect task-owned cleanup or intentional preview retention without extending archived receipts beyond their source.
**Plans**: TBD
**UI hint**: yes
**Acceptance**: Check six-surface consistency and shared tokens against demonstrated use; consolidate evidence already produced by each slice and run only the final source-specific checks required by the existing delivery gates. No paid judge or pending routine human UAT.

## Progress

**Execution order:** 173 → 174 → 175 → 176 → 177. Phase 173 is ready for discussion; execution has not started.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 173. Shared Visual Foundation and Operational Time | 0/TBD | Ready to discuss | - |
| 174. Recovery Entry and Diagnosis | 0/TBD | Not started | - |
| 175. Repair and Verification | 0/TBD | Not started | - |
| 176. Search and Playbooks | 0/TBD | Not started | - |
| 177. Shared Patterns and Delivery Proof | 0/TBD | Not started | - |
