# Requirements: Scrypath — v1.43 ScrypathOps UI refinement

**Defined:** 2026-10-06
**Status:** Approved by the maintainer on 2026-10-06 together with the five-phase roadmap. Implementation has not started.
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.43 Requirements

Refine the six existing operator surfaces. Continue the OPUX family after completed v1.42 OPUX-01–OPUX-08; none of the new requirements is completed by initialization.

### Shared visual foundation

- [x] **OPUX-09**: Operators see a flat neutral page background throughout the operator shell in explicit light/dark, OS-driven System appearance, and responsive layouts; decorative shell gradients are removed without removing functional scroll-edge cues.
- [x] **OPUX-10**: Operators can identify degraded, failed, and unknown states through explicit text and restrained local icon/badge cues on neutral summary/schema surfaces, without broad yellow fills or whole-record status outlines.
- [x] **OPUX-11**: Operators see zero-error counts as ordinary neutral metrics rather than green success outlines; nonzero and unavailable values remain distinguishable, and zero errors do not imply overall health or document freshness.
- [x] **OPUX-12**: Operators see exactly one selected theme preference with matching accessible state. System alone looks selected while appearance follows OS changes; preference survives reload/navigation and remains coherent across tabs.
- [x] **OPUX-13**: Operators can recognize and use shared quiet actions with deliberate hover, keyboard focus, pressed, selected, disabled, and busy states in both themes; busy refresh/actions retain meaningful icons and labels across existing usages.
- [x] **OPUX-14**: Operators can read operational last-success times in a human-readable form and access the exact timestamp/timezone; the display remains stable between checks, and absent or unobserved success stays distinct from an observed success.
- [x] **OPUX-15**: Operators can copy an operational last-success timestamp as full ISO evidence using a discoverable keyboard-accessible control in standalone and mounted Ops. “Timestamp copied” appears briefly only after clipboard success; unavailable/denied access is explained truthfully, and routine Checked metadata has no copy control.

### Recovery entry and diagnosis

- [x] **OPUX-16**: Operators entering Control Room can identify the current state, affected search scope, and next safe action in a clear reading order without duplicated explanations or competing secondary controls.
- [x] **OPUX-17**: Operators inspecting Search health can scan worst-first schema records with readable complete identifiers/times, one meaningful surface per schema, and plain Backend/Queue diagnostic groups; section spacing and concise next-check actions remain clear without redundant nested containers.
- [ ] **OPUX-18**: Operators inspecting Failed sync work can see the failure reason, source/work identity, and recovery availability before opening verbose evidence; the common supported recovery action is discoverable while retained history, eligibility rules, and safety gates stay explicit.
- [ ] **OPUX-19**: Operators retain their selected allowed schema across rendered recovery handoffs, refresh, and back navigation after changing selection; invalid/unavailable targets cannot silently become actions on a different schema.

### Repair and verification

- [ ] **OPUX-20**: Operators using Sync and drift can distinguish index-contract drift from document freshness and observation from repair or advanced promotion, with a clear next step for ordinary recovery and a separate advanced promotion path.
- [ ] **OPUX-21**: Operators can distinguish accepted, running, terminal success/failure, and unavailable/unknown observations for repair/promotion work while retaining exact task identity; failed observation cannot masquerade as failed or completed remote work.
- [ ] **OPUX-22**: Operators can review and perform supported repair/promotion through the existing confirmation, authorization, and eligibility gates; completion remains tied to authoritative task/index/document evidence rather than acceptance, a flash, or historic unrelated work.

### Search and saved checks

- [ ] **OPUX-23**: Operators using Search can identify the target/query controls, primary run action, and results in a clear hierarchy without redundant run actions for the same task; empty/error/partial states, disabled behavior, and optional diagnostic evidence remain usable.
- [ ] **OPUX-24**: Operators using Playbooks can distinguish preview, execution, results, and saving, with common run/save actions prioritized and existing workspace, import, validation, and read-only behaviors preserved.
- [ ] **OPUX-25**: Operators can discover occasional Playbook rename/duplicate/delete actions without those actions competing with common work; destructive confirmation and dialog keyboard, validation, focus containment/return, and LiveView patch behavior remain correct.

### Shared pattern consolidation and delivery

- [ ] **OPUX-26**: Operators encounter the same demonstrated section/object grouping, action, status, and feedback patterns across all six surfaces; the existing component/token system owns those patterns, superseded styling is removed, and DESIGN.md plus the component/token catalog describe the delivered vocabulary without a fixed arbitrary component count.
- [ ] **OPUX-27**: Operators can use the refined workflows in both themes, at narrow/desktop widths, with keyboard/focus and reduced-motion behavior intact. Each slice supplies direct before/after image inspection and relevant automated layout/state/contrast proof; changed recovery seams also receive mounted evidence in existing lanes, with no paid judge or pending routine human UAT.
- [ ] **OPUX-28**: Maintainers can trace every delivered requirement to committed verification and reviewed PR-first source/CI evidence, including an explicit release/no-release decision and cleanup or intentional preview retention; completion bookkeeping precedes final-source attestation and archived evidence remains within its source limits.

## Verification and design contract

The agreed scope and verification defaults in `research/v1.43/SCOPE.md` apply to every phase. Substantial visual changes start with realistic light/dark comps, and selected decisions enter that frontend phase's GSD `UI-SPEC.md` before implementation planning. The first representative Search health comp includes degraded data, zero/error/unknown metrics, queue failures, long diagnostic values/timestamps, quiet-action states, and the theme preference control.

Review representative desktop/mobile renders and an intermediate width where the changed layout crosses a breakpoint. Tests must exercise changed controls/forms and schema-changing rendered navigation, not only direct event handlers or preselected URLs. Capture inventories and passing behavior tests do not alone establish visual quality. Keep missing backend/configuration, loading, partial/unknown, absent success, clipboard failure, disabled/busy, and long-content states truthful.

Use the existing Ops LiveView/component suite, token contrast, focused browser lanes, and mounted recovery/promotion proof as applicable. Every slice closes its own relevant acceptance; Phase 177 consolidates the demonstrated system and delivery evidence rather than deferring earlier verification. Run mutating fixtures in a disposable stack and preserve the feedback preview at `http://127.0.0.1:4012/admin/search`.

## Future Requirements

No additional capability is promoted to a future promise by this UI refinement. Existing infrastructure automation and broader API/backend/auth ideas remain direction or separately evidenced candidates; they need their own scoped milestone.

## Out of Scope

| Feature | Reason |
| --- | --- |
| New core search APIs, public backend abstraction, relevance features, or workflow expansion | This milestone refines existing operator behavior; new capabilities need separate evidence and scope. |
| Infrastructure provisioning, capacity, backups/restores, or new automation | Host teams own those operations today; long-term automation direction is not shipped scope. |
| Host authorization product or changes to action safety/eligibility policy | Preserve existing host-owned authorization and confirmation boundaries. |
| New UI surfaces, component framework replacement, or wholesale unrelated CSS rewrite | Improve demonstrated patterns in the existing system; extract only after repeated usage justifies it. |
| Binding exploratory brand-book hex values or a new public brand/adoption claim | Palette revision is explicitly authorized; identity and product facts remain constraints. |
| New required CI service/job, recurring paid AI review, or routine human UAT | Reuse existing economical evidence lanes and resolve visual choices before implementation. |
| Automatic package version bump/release | GSD v1.43 is a planning version. Decide release necessity from delivered package changes. |
| Replaying Phase 172/170 or rewriting archived source receipts | Prior work is complete and immutable/source-bounded; new source needs its own evidence. |
| Reseeding the maintainer feedback preview or clearing unrelated working-tree changes | Preserve preview data and the current local baseline; use disposable verification services. |

## Traceability

Approved roadmap mapping. Each requirement appears in exactly one phase; every requirement remains pending implementation and verification.

| Requirement | Phase | Status |
| --- | --- | --- |
| OPUX-09 | Phase 173 | Complete |
| OPUX-10 | Phase 173 | Complete |
| OPUX-11 | Phase 173 | Complete |
| OPUX-12 | Phase 173 | Complete |
| OPUX-13 | Phase 173 | Complete |
| OPUX-14 | Phase 173 | Complete |
| OPUX-15 | Phase 173 | Complete |
| OPUX-16 | Phase 174 | Complete |
| OPUX-17 | Phase 174 | Complete |
| OPUX-18 | Phase 174 | Pending |
| OPUX-19 | Phase 174 | Pending |
| OPUX-20 | Phase 175 | Pending |
| OPUX-21 | Phase 175 | Pending |
| OPUX-22 | Phase 175 | Pending |
| OPUX-23 | Phase 176 | Pending |
| OPUX-24 | Phase 176 | Pending |
| OPUX-25 | Phase 176 | Pending |
| OPUX-26 | Phase 177 | Pending |
| OPUX-27 | Phase 177 | Pending |
| OPUX-28 | Phase 177 | Pending |

**Coverage:**
- v1.43 requirements: 20 total
- Mapped to exactly one approved phase: 20
- Unmapped: 0
- Approved: 20
- Implemented or verified: 0

---
*Requirements defined: 2026-10-06 from the approved milestone brief.*
*Last updated: 2026-10-06 after explicit requirements and roadmap approval.*
