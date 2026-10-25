# Phase 175: Repair and Verification - Context

**Gathered:** 2026-10-10
**Status:** Ready for the UI design contract
**Decision authority:** The maintainer directed the agent to synthesize recommendations and proceed automatically, and reiterated that direction after compaction. The choices below are agent-recommended defaults adopted under that standing instruction; they are not verbatim interview answers or simulated maintainer/reviewer approval.

<domain>
## Phase Boundary

Deliver OPUX-20–OPUX-22 on the existing **Sync and drift** surface. Operators must be able to distinguish sync/queue observation, index-contract drift, and document evidence; choose an eligible ordinary recovery action or the separate advanced promotion path; and know what the exact operation did from current, correlated evidence.

Preserve the approved v1.43 scope, host-owned authorization, existing recovery/promotion capabilities and confirmation gates, Meilisearch task identity, Oban job identity, schema/index/document correlation, and the established Ops visual system. Do not add a new workflow or surface, public Scrypath API, authorization product, backend, framework, or dependency. Phase 176 owns Search and Playbooks; Phase 177 owns cross-surface consolidation and delivery proof.

</domain>

<decisions>
## Implementation Decisions

### Evidence and operator decision order

- **D-01:** Keep three evidence questions legible as separate results: (1) what the queue/backend reports, (2) whether the live index matches the declared contract, and (3) whether the expected document is observed in the active index. A clean contract check is not proof that projected documents are present; a queue success is not proof of active-index visibility. Give each result its own observed/unavailable state and relevant next step rather than compressing them into one green/failed verdict.
- **D-02:** Keep the common path ordered around refresh/observation, contract diagnosis, and eligible ordinary recovery. Keep promotion as a visually separate advanced action. This lets operators investigate or verify independently while reducing the chance that an index swap is mistaken for routine repair. Preserve the existing rule that prior failed work blocks promotion until resolved, while still allowing the operator to observe whether newly accepted recovery reached the backend and active index.
- **Tradeoff considered:** A single summary is quicker to scan but hides which evidence is missing or stale; multiple independent cards can become noisy. Keep the evidence distinctions and use the existing section/record primitives with concise labels, not a new nested dashboard.

### Operation identity and outcomes

- **D-03:** Retain the exact operation identity beside its outcome: schema, target/live index as relevant, queue job and attempt for Oban work, and Meilisearch task UID for backend work. Do not substitute the newest historical task or a matching status from another index/schema for the operation just initiated.
- **D-04:** Treat request acceptance as **accepted/enqueued**, not success; preserve a distinct in-progress state; show terminal success only when the matching operation's terminal evidence and the applicable index/document observation support it. Show remote task failure or cancellation as a terminal non-success with its identity. Keep observation timeout, transport failure, malformed/missing task data, and unavailable evidence as **unknown / could not be checked**, never as proof that the remote operation failed.
- **D-05:** Refresh/status-check controls remain observational. After an accepted, timed-out, or unknown operation, checking again must not resubmit the mutation. Retain the exact task/job reference and explain the next safe check. Preserve older failure history instead of clearing it to make the page look healthy.
- **Tradeoff considered:** More explicit lifecycle states use more copy and screen space, but collapsing them makes asynchronous Meilisearch behavior unsafe to interpret. Prefer concise action-adjacent status with exact IDs available/readable; do not hide the distinctions.

### Eligibility, confirmation, and selection

- **D-06:** Offer only actions currently supported and eligible for the selected allowlisted schema. Disabled/unavailable actions retain a concrete reason. UI state is explanatory only: resolve the URL schema against the live allowlist and re-check authorization, eligibility, schema/index identity, and fresh evidence on the server immediately before any mutation.
- **D-07:** Keep ordinary repair on the common task path and index promotion behind the existing advanced disclosure and explicit confirmation. Confirmation continues to name the schema, live index, target index, and alias change. Do not create a second authorization policy or make a frontend confirmation the security boundary.
- **D-08:** Preserve Phase 174's URL-backed schema continuity. When schema/index identity changes, invalidate evidence, pending operation context, or confirmations bound to the former target. An invalid/unavailable explicit target is a visible stop, never an implicit fallback to another schema.
- **Tradeoff considered:** Disabling an ineligible action reduces accidental attempts but can obscure how eligibility works; keep the existing reason visible. Avoid replacing the guard with a generic disabled state or a client-only check.

### Interaction quality and proof

- **D-09:** Use the existing neutral surfaces, OpsUi components/tokens, native controls, LiveView async/navigation patterns, visible focus, and status vocabulary. Pair color with text/icon/state; expose non-focus-moving progress and results programmatically without stealing focus or repeating noisy announcements. Keep long task/index/document IDs readable at narrow widths.
- **D-10:** Verify the decision paths through the rendered controls and mounted flows: eligible and blocked actions, confirmation, accepted/running/succeeded/failed/canceled/unknown outcomes, observation failure, exact task/job mismatch, wrong index/schema/document, refresh without resubmission, and evidence invalidation after target change. Inspect representative degraded states in light/dark and desktop/narrow layouts; use existing executable accessibility, focus/layout, LiveView, and disposable-stack checks. Direct screenshots supplement executable proof and do not replace it.
- **D-11:** No new dependency or component framework. Prefer existing primitives or a small local helper; a modest amount of repeated code is preferable to a dependency or abstraction without a demonstrated repeated need. Keep all changes within approved requirements and current existing lanes.
- **Tradeoff considered:** This verification set emphasizes dangerous boundary conditions rather than exhaustive cosmetic combinations; reuse passing evidence within its recorded source/scenario limits and add cases only when a named acceptance path requires them.

### the agent's Discretion

The UI contract may choose exact headings, labels, concise error/recovery copy, icon treatment, responsive spacing, and which existing OpsUi primitives fit each evidence group. The researcher/planner may choose how to organize the implementation and test tasks. Keep D-01–D-11 and the roadmap success criteria fixed; any new operation/capability or relaxation of an authorization/evidence gate is out of scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read the relevant references before designing, planning, or implementing.**

### Approved scope and operating constraints

- `.planning/PROJECT.md` — product promise, approved v1.43 lifecycle, user-directed design/release posture, and verification defaults.
- `.planning/REQUIREMENTS.md` — OPUX-20–OPUX-22 acceptance requirements.
- `.planning/ROADMAP.md` — Phase 175 boundary, success criteria, dependencies, and acceptance evidence.
- `.planning/STATE.md` — current completed-phase evidence, worktree, and next action.
- `.planning/research/v1.43/SCOPE.md` — approved milestone boundaries and evidence/release posture.
- `.planning/reference/OPERATOR-UI-REFINEMENT.md` — maintainer observations and UI refinement sequence.
- `.planning/reference/OPERATOR-UI-QUALITY.md` — hierarchy, status, responsive, accessibility, and evidence rules.
- `CONTRIBUTING.md` and `scrypath_ops/AGENTS.md` — required repository/Ops test and implementation conventions.
- `scrypath_ops/docs/operator-ia.md` — operator jobs, route hierarchy, failed-work recovery and advanced-promotion semantics.
- Root-only user-authored `/Users/jon/projects/scrypath/PRODUCT.md` and `/Users/jon/projects/scrypath/DESIGN.md` are preserved outside this worktree; consult them for the Impeccable UI contract. They are not represented as committed project files.

### Decisions and design system carried forward

- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-CONTEXT.md` — locked shared visual, state, accessibility, and dependency posture.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md` — selected Ops visual system and interaction contract.
- `.planning/phases/174-recovery-entry-and-diagnosis/174-CONTEXT.md` — locked schema continuity, action eligibility, failure history, and recovery handoffs.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — delivered token/component authority; revise only demonstrated patterns.
- `.planning/research/v1.42/UI-SYSTEM.md`, `.planning/research/v1.42/UI-STRUCTURE.md`, and `.planning/research/v1.42/UI-AUTOMATION.md` — historical component/state/test inventory; re-check current source before relying on a finding.
- `prompts/phoenix-live-view-best-practices-deep-research.md` and `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — local Phoenix/Elixir architecture guidance; installed-version official docs govern exact APIs.

### Current implementation and executable evidence

- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` — existing Sync and drift observations, recovery/promotion event flow, status presentation, and operation verification.
- `scrypath_ops/lib/scrypath_ops/recovery_observation.ex` — retained recovery receipt and task-observation evidence.
- `scrypath_ops/lib/scrypath_ops/promotion_eligibility.ex` — promotion guards and eligibility reasons.
- `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` — focused LiveView outcome, identity, eligibility, and no-resubmission coverage.
- `examples/scrypath_ecommerce/e2e/operator.spec.ts` — existing rendered/mounted operator journeys; confirm relevant fixtures and exact source scope before extending.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` and `scrypath_ops/assets/css/app.css` — shared components and theme tokens; extend only for demonstrated need.

### Primary external guidance

- [Meilisearch Tasks API specification](https://specs.meilisearch.dev/specifications/text/0060-tasks-api.html) — task UIDs, index identity, `enqueued`/`processing`/terminal statuses, and the limited meaning of `202 Accepted`.
- [Meilisearch Swap Indexes specification](https://specs.meilisearch.dev/specifications/text/0191-swap-indexes-api.html) — asynchronous swap operation and task identity.
- [Meilisearch task monitoring docs](https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks) — supported task-status monitoring model.
- [Phoenix LiveView v1.1.33 API](https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html) — locked dependency docs for asynchronous LiveView results and untrusted URL/event parameters.
- [WCAG 2.2: Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html) and [Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html) — accessible announcements and non-color status cues.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `ScrypathOps.RecoveryObservation` preserves the specific accepted recovery receipt and backend-task evidence; `SyncDriftLive` correlates a replacement job with task and target-document observations.
- `ScrypathOps.PromotionEligibility` centralizes eligibility checks and blocking reasons; `SyncDriftLive` already keeps promotion acceptance, running, completion, failure, timeout, and unknown outcomes distinct.
- `ScrypathOpsWeb.OpsUi` and the Phase 173 tokens provide shared sections, status, action, disclosure, and responsive patterns.

### Established Patterns

- Oban queue jobs and Meilisearch backend tasks are different operation identities and should keep their domain names.
- A `202 Accepted`/accepted receipt is not terminal completion. An observer transport failure is lack of evidence, not a remote failure.
- Current allowlist and host authorization are authoritative; URL/event values and rendered disabled states are not security boundaries.
- Refresh actions are observational and must not repeat a previously submitted mutation. Failure history remains visible.

### Integration Points

- The Sync and drift LiveView connects reconcile/queue observations, index contract checks, manual recovery status refresh, advanced promotion, and the existing Meilisearch adapter/task reader.
- Focused LiveView tests cover state branches. The mounted Playwright path can verify actual confirmation, status/identity rendering, selection continuity, and layout/focus behavior using disposable fixtures.
- The shared standalone and mounted Ops UI assets must keep consistent copy and semantics; no new package seam is needed.

</code_context>

<specifics>
## Specific Ideas

Recommendations were stress-tested through the relevant operator/on-call, product-trust, security/host, Meilisearch/Oban operations, Phoenix/LiveView, accessibility, responsive-design, test/CI, and maintenance lenses. The central adversarial cases are stale or cross-schema evidence, wrong task UID/index/document, unrelated historical success, remote cancellation, task expiry/not-found, observer timeout after accepted work, selection changes with a pending receipt/confirmation, stale eligibility, and a UI control whose server action is denied.

The UI decision stays focused on this LiveView and its distributed evidence boundary; graphics-engine, unrelated language/runtime, or new-service architecture alternatives do not change the approved outcome. Keep dependencies flat and reuse established primitives where they express the job clearly.

</specifics>

<deferred>
## Deferred Ideas

None. Any new repair capability, backend/auth product, operator surface, or change to host authorization remains out of scope and requires separate evidence and scope approval. Search and Playbooks remain Phase 176; final shared-pattern and delivery work remains Phase 177.

</deferred>

---

*Phase: 175-repair-and-verification*
*Context gathered: 2026-10-10*
