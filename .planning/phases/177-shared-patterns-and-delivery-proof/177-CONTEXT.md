# Phase 177: Shared Patterns and Delivery Proof - Context

**Gathered:** 2026-10-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Consolidate the demonstrated design and interaction vocabulary across Control Room, Search health, Failed sync work, Sync and drift, Search, and Playbooks; update the design/token documentation to describe the delivered system; and make the v1.43 delivery evidence traceable without changing the limits of earlier receipts. This phase may correct specific drift the six-surface audit proves, but it does not add operator capabilities, reopen completed acceptance without new evidence, change core APIs, introduce a public backend/auth product, replace the UI framework, add required CI services, or add paid visual review.

</domain>

<decisions>
## Implementation Decisions

The user authorized automatic follow-through on recommendations and requested broad, role-based analysis. The following are the one-pass recommended choices, synthesized across product/design, accessibility, Phoenix/LiveView engineering, QA, security, release/operations, and maintainer-review lenses. They were not individually selected through interactive questions.

### Shared six-surface vocabulary and design catalog

- **D-01:** Audit all six named surfaces against the delivered UI and existing phase evidence. Document the shared grouping, action, status, and feedback patterns that are actually demonstrated. Components with the same function should remain recognizable and consistently identified; labels and layouts may remain contextual when the task or result differs. Preserve each surface's distinct operator job and evidence semantics.
- **D-02:** Use `ScrypathOpsWeb.OpsUi`, `app.css`, and `DESIGN-TOKENS.md` as the current component/token authority. Reconcile `DESIGN.md` and the token catalog with implemented behavior, including concise examples and concrete superseded rules. Do not impose an arbitrary component count, turn every named pattern into a new component, or perform a broad redesign. If inspection finds no source drift, documentation-only consolidation is sufficient; if it finds a specific mismatch, correct only that evidenced mismatch and verify the affected behavior.
- **D-03:** Keep dependency and abstraction growth evidence-driven. Prefer the current native Phoenix/LiveView and token/component patterns; a small amount of local repetition is acceptable when a shared abstraction has no demonstrated repeated need. Add no dependency, framework, CI lane, or evidence service for catalog completeness alone.
- **D-04:** Carry forward OPUX-27's six-surface quality contract: light, dark, and System appearance; desktop and narrow widths; keyboard operation and visible focus; reduced motion; direct before/after inspection; and relevant executable layout, state, and contrast evidence for changed slices. Include mounted evidence when a recovery handoff changes. Preserve prior phase results only for their recorded source and scenarios. Do not substitute screenshots, a score, PR approval, or routine human UAT for behavioral proof.

### Requirement-level verification and delivery evidence

- **D-05:** Create one committed 20-requirement trace. For each OPUX requirement, link to its authoritative phase verification/behavior evidence and recorded source SHA, then to the reviewed PR source SHA and applicable required CI checks, recording the exact SHA each check tested. Link to existing reports rather than copying them into a second aggregate bundle. Keep local phase evidence, hosted PR evidence, and unknown/missing evidence clearly distinct.
- **D-06:** Reuse earlier evidence within its stated limits. Run Phase 177's specific checks and the existing final-source delivery gates, plus only checks invalidated by changed source. Do not rerun every prior suite solely to refresh timestamps, represent an old local pass as hosted proof, or extend v1.42's archived receipts to v1.43.
- **D-07:** Record any source mismatch or unavailable review/check as unresolved evidence; never infer requirement-level behavior from a green branch alone. Complete all plan summaries, verification/audit records, release and cleanup records before recording a final-source attestation. Keep that receipt external to the frozen source it attests.

### Release decision and task-owned cleanup

- **D-08:** Decide release/no-release from the final Hex package file set and diff. If the change remains limited to ScrypathOps and planning/design records excluded from the Hex package, record no Hex release and do not bump package version merely to finish v1.43. Reassess only if a package-included change warrants publication. The current `scrypath_ops/mix.exs` comment and root package configuration indicate ScrypathOps is excluded; verify the final package boundary at closeout.
- **D-09:** Track each task-owned disposable stack with its owner, purpose, Compose project/service/container identifiers, allocated port, collected evidence, and cleanup result/command. Remove only those disposable resources after evidence capture. Preserve the feedback preview at `http://127.0.0.1:4012/admin/search`, its volumes, and unrelated services; record that it is the normal-checkout bind mount, its owner/purpose, and its stop command. Do not treat this retained preview as evidence for the phase worktree.
- **D-10:** Do not claim OPUX-28 complete without committed requirement-level verification plus actual reviewed PR source and required CI evidence for the exact tested source. Prepare local changes and their evidence first; if hosted review or checks are unavailable, report the precise gap instead of simulating approval or weakening the criterion.

### the agent's Discretion

- Choose the concise catalog examples and the format/placement of the 20-row evidence trace, so long as the source SHA and evidence boundary are explicit for each requirement.
- Choose the smallest existing verification commands that prove changes; use repository conventions and avoid redundant checks.
- Preserve the current worktree `/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis` and branch `gsd/phase-174-recovery-entry-diagnosis`; keep the normal checkout and port 4012 preview untouched.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Approved scope, requirements, and continuity
- `.planning/ROADMAP.md` — Phase 177 goal, success criteria, sequence, and canonical refs.
- `.planning/REQUIREMENTS.md` — Approved OPUX-09–OPUX-28 requirements and statuses.
- `.planning/PROJECT.md` — Product constraints, operator UI and verification defaults, and GSD handoff policy.
- `.planning/STATE.md` — Current exact phase/source status, retained preview, and historical evidence boundaries.
- `.planning/research/v1.43/SCOPE.md` — Approved milestone boundary, quality acceptance, no-new-dependency/CI policy, and evidence rules.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-CONTEXT.md` — Shared visual foundation and time/copy decisions.
- `.planning/phases/174-recovery-entry-and-diagnosis/174-CONTEXT.md` — Recovery selection, safety, and status-language decisions.
- `.planning/phases/175-repair-and-verification/175-CONTEXT.md` — Operation identity, authoritative outcomes, and verification/dependency decisions.
- `.planning/phases/176-search-and-playbooks/176-CONTEXT.md` — Search/Playbooks behavior and preserved semantics.
- `.planning/phases/176-search-and-playbooks/176-UI-SPEC.md` — Existing system, spacing, typography, colors, responsive, and accessibility contract.

### Design system, implementation, and quality
- `.planning/reference/OPERATOR-UI-QUALITY.md` — Maintainer quality rules for interaction, accessibility, responsive behavior, evidence, and cleanup.
- `.planning/reference/OPERATOR-UI-REFINEMENT.md` — Approved refinement direction and six-surface acceptance.
- `.planning/research/v1.42/UI-SYSTEM.md` — Prior component/token inventory; orientation only, recheck current source.
- `.planning/research/v1.42/UI-STRUCTURE.md` — Six operator surfaces and their distinct jobs.
- `.planning/research/v1.42/UI-AUTOMATION.md` — Existing test, browser, mounted, contrast, and cleanup lanes.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — Current implemented token/component catalog.
- `scrypath_ops/assets/css/app.css` — Token definitions and shared component styling.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — Shared Phoenix function-component authority.
- `scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs` — Existing guard that every current `OpsUi` export is represented in the catalog.
- `scrypath_ops/mix.exs` — Ops verification aliases; inspect existing commands before adding checks.
- `mix.exs` — Root package boundary; confirm final Hex contents at release closeout.
- `prompts/scrypath-brand-book.md` — Exploratory brand and voice reference; not a binding color or UI contract.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` and `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Local release/OSS research prompts; validate project-specific release claims against current repository config and primary sources.
- `PRODUCT.md` — Referenced by the approved roadmap but absent from this worktree; do not assume its contents. Use `.planning/PROJECT.md` and the approved scope as current product truth.
- `DESIGN.md` — Required delivered design documentation but absent from this worktree at discussion time; create/update it to describe the evidenced, implemented system.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ScrypathOpsWeb.OpsUi` in `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — shared Phoenix function components for shell content, sections, actions, fields, statuses, records, disclosures, and dialogs.
- `scrypath_ops/assets/css/app.css` and `DESIGN-TOKENS.md` — the shared styling/tokens and role inventory for current `OpsUi` exports.
- `design_tokens_contract_test.exs` — already verifies catalog coverage of exported components; extend only for a concrete unguarded contract, not to enforce a fixed component count.
- Existing per-phase LiveView, component, browser, contrast, and mounted evidence from Phases 173–176 — reuse with each report's source/scenario boundary intact.

### Established Patterns
- Phoenix server-rendered LiveView and function components own state and event behavior; preserve native controls and existing JS hooks.
- Shared tokens/components express repeated patterns, while each surface retains its task-specific evidence, hierarchy, and safe actions.
- Status meaning is textual and evidence-backed; color remains a local cue. System preference, narrow layouts, keyboard/focus, and reduced-motion behavior are existing acceptance dimensions.
- Focused local changes and existing economical test lanes are preferred; no new dependency or generalized abstraction without a demonstrated need.

### Integration Points
- The six existing operator LiveViews and shared `OpsUi`/CSS are the audit boundary; map catalog examples back to the actual consumers.
- Root `DESIGN.md` plus `scrypath_ops/assets/css/DESIGN-TOKENS.md` form the documentation deliverable; existing contract tests guard catalog drift.
- Phase verification artifacts map OPUX-09–28 to local source/test results; the final delivery trace connects those results to reviewed PR and exact-SHA required CI evidence.
- Root Mix package configuration determines whether any change reaches Hex; the separate Ops app has its own verification aliases.

</code_context>

<specifics>
## Specific Ideas

- Keep demonstrated patterns consistent without flattening the distinct operator jobs of the six surfaces.
- The user's dependency preference applies: local, explicit code or modest duplication is preferable to an unnecessary dependency or abstraction.
- Treat direct before/after visual inspection as complementary to executable layout/state/contrast proof. No paid visual judge and no pending routine human UAT.
- Preserve the feedback preview at port 4012 and its data; only remove task-owned disposable stacks.
- Use WCAG's consistent-identification guidance for components that actually share a function; contextual labels remain appropriate for distinct actions/results.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the approved Phase 177 boundary.

</deferred>

---

*Phase: 177-shared-patterns-and-delivery-proof*
*Context gathered: 2026-10-11*
