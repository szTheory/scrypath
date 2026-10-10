# Phase 175: Repair and Verification - Context

**Gathered:** 2026-10-10
**Status:** Discussion complete; ready for the Phase 175 UI contract before planning
**Decision authority:** Carry forward the maintainer's accepted whole-workflow audit, concrete UI feedback, dependency preference, and instruction to follow established recommendations until a working result is ready. This invocation introduces no new product preference or approval of a mutation. The workflow's skip assessment found the meaningful product choices already decided; technical evidence gaps remain research/planning work, not questions for the maintainer.
**Preparation baseline:** `e58416844a6a2e3ad6a94cbc1396109a31096757`; latest production source `22d5cd016cd8014ea2887615bd66efa093d69e1b`. Work in `/private/tmp/scrypath-phase173-20261006-155750/phase174-execution`, branch `gsd/phase-174-recovery-entry-and-diagnosis`. No formal Phase 175 implementation or verification is claimed here.

<domain>
## Phase Boundary

Deliver OPUX-20–OPUX-22 on the existing Sync and drift workflow and its repair/verification handoffs: distinguish configuration comparison from document freshness, make ordinary recovery and advanced index promotion distinct, retain truthful progress/outcomes and exact work identity, and prove supported mutations behind the existing confirmation, eligibility, and host-authorization gates.

The accepted audit follow-up is the current presentation baseline. Keep the six existing surfaces, approved cool-neutral palette/theme picker, established components, existing library contracts, and current host-owned safety policy. Failed sync work owns its existing per-record retry; Sync and drift observes its accepted receipt and provides the existing advanced promotion. No generic repair button, automatic retry, automatic reindex/backfill, new freshness scan, durable workflow engine, public API/backend/auth product, infrastructure automation, dependency, or required CI service is added.

Phases 173–174 are complete. Phase 176 owns Search/Playbooks and Phase 177 owns final shared-pattern/delivery consolidation; neither absorbs Phase 175's acceptance. This context neither reopens historical work nor extends an old exact-source receipt.
</domain>

<decisions>
## Implementation Decisions

### Apply the accepted workflow and design direction

- **D-01:** Use the accepted audit and rubric as binding inputs. Do not restart a broad interview or repeat already fixed hierarchy/brand work. Evaluate relevant operator/product, design/accessibility, Phoenix/browser, security, asynchronous evidence, and maintenance concerns; stop when another pass would not change the recommendation.
- **D-02:** Prefer existing components, native controls, and small owned code over another dependency. The current palette, theme picker, typography, spacing, quiet actions, time/copy feedback, and mobile/keyboard conventions carry forward. Resolve the affected compositions in `175-UI-SPEC.md` before implementation planning; do not reinitialize Impeccable or repair sidecars incidentally.

### Make the current job and scope clear — OPUX-20

- **D-03:** The page answers: "Did this recovery work, and does the index configuration match?" Keep a real visible schema selector, scope-matching content/URLs, and full module/index identifiers available. Specific recovery links retain the validated schema. Control Room and Search health always return to all schemas. The later maintainer correction supersedes older Phase 174 D-06/D-19 overview target labels/navigation.
- **D-04:** Lead with the active retry's outcome when a valid retry handoff exists, then ordinary sync status, index configuration, and a separately disclosed advanced promotion path. A normal visit has no invented retry panel. State and its useful next read-only action precede verbose diagnostics; exact composition and concise labels remain agent discretion within the UI contract.
- **D-05:** Use state-appropriate ordinary actions: pending work offers a progress check; known failures link to that schema's Failed sync work; unavailable observations explain how to retry the check or inspect configuration. Refresh/check only observes. Existing explicit retry stays attached to its inspected source-qualified failed record. Configuration differences do not authorize an automatic repair or create a new UI mutation; point to the existing supported runbook where needed.

### Bound the meaning of each check — OPUX-20

- **D-06:** Interface copy uses **Index configuration** for declared fields/search settings versus the live index. Keep `index_contract_drift` and other established technical API names in code/diagnostics. Matching configuration says nothing about whether database records have reached search. No zero counters, quiet summary, finished queue job, or configuration match may imply fleet health, document freshness, or promotion readiness.
- **D-07:** Preserve automatic bounded sync inspection and explicit/lazy configuration comparison. An unrun comparison stays quiet "Not checked". Successful comparison detail is optional; actionable differences are exposed. Loading, missing backend/setup, incomplete reads, and unknown values remain explicit. A configuration-read failure does not erase an independently valid sync result or imply that documents differ.
- **D-08:** Keep decision-changing failures, blockers, uncertainty and current scope visible; disclose raw flags, successful comparison tables, framework details, and verbose diagnostics. Zero-work states omit redundant counts and explanations. Tooltips supplement needed terms, rather than justify irrelevant facts. Keep technical identities readable and wrapped rather than truncated.

### Describe actual work and observation separately — OPUX-21

- **D-09:** Distinguish accepted/queued, authoritatively running, terminal success, terminal failure/cancellation, and unavailable/unconfirmed outcomes. A busy observer is a check in progress, not proof the backend is running. Do not synthesize a running state merely because a wait is active or time has elapsed. A successful enqueue/HTTP response/flash is acceptance only.
- **D-10:** An active recovery receipt retains the exact replacement queue job, attempt, operation, source failure, schema/index and matching backend task UID where known. Queue completion without task/document evidence remains an intermediate outcome. "Recovery verified" requires the matching authoritative queue/task and active-index document effect, including the expected absence for a delete; never a historic unrelated success or a generic search hit.
- **D-11:** Failed reads, missing task IDs, inaccessible/expired/restarted receipt storage, superseded attempts, wrong endpoint/Oban instance/repo/prefix/node, schema changes and stale async callbacks cannot become zero, success, or a failed remote task. Preserve the established bounded receipt and generation/host identity rules. Retained failure history remains history and continues to affect promotion under the existing policy; it need not erase verification of a different accepted retry.
- **D-12:** Retain the returned promotion task UID through accepted, terminal and unconfirmed outcomes. Only a matching terminal task outcome supports "Index swap completed" or a remote task failure. A failed/timed-out observation remains unconfirmed and offers safe read-only rechecking; refreshing must not submit another swap. Keep task completion, current index state and observed document effect separate when presenting what has been established.

### Keep advanced promotion deliberate — OPUX-22

- **D-13:** Advanced index promotion remains available in its own native disclosure rather than competing with ordinary checks. Preserve deliberate expansion through appropriate LiveView patches. Once there is active accepted/running/unconfirmed work or a terminal error, its state and identity must be discoverable without searching a silently collapsed panel. Settle its rendered visibility/focus behavior in the UI contract.
- **D-14:** Show the relevant readiness/blocking reason and safe next step. Preserve the current fail-closed eligibility evaluation: allowed schema, supported backend, current same-context reports, distinct observed live/target indexes, observed reindex/cutover state, no unresolved pending or failed work, and matching configuration. Do not loosen or expand eligibility policy as a UI cleanup. A blocking historic failure is not automatically deleted or ignored.
- **D-15:** Confirmation shows the full schema and exact live/target index pair and a plain description of the effect. Keep cancellation, focus containment/return, host sensitive-action authorization/sudo, current-allowlist validation, prerequisite rechecks immediately before submission, and existing duplicate/in-flight guards. A disabled or hidden client control is never the enforcement boundary. An auth return restores context without replaying a mutation.
- **D-16:** Correct the existing "live alias" explanation to match the actual Meilisearch index swap. The source calls `swap_indexes` for the live/target pair; describe promoting the prepared target through that swap without inventing an alias API or changing public behavior. Include the operator-facing effect in ordinary copy and preserve detailed swap consequences in supporting documentation/diagnostics. Validate the pinned backend's existing semantics in research; do not adopt newer optional API features from current docs.

### Close this phase with evidence, not a later review — OPUX-20–22

- **D-17:** Reuse passing audit/phase evidence within its source and scenario limits; inspect current code and cover missing Phase 175 claims independently. Prior 57-case UX proof verifies presentation/navigation, not every repair/promotion path. Each phase closes its own requirements with rendered event/navigation proof, authoritative correlation, relevant standalone and mounted paths, and exact-source PR/CI evidence.
- **D-18:** Exercise healthy/empty/unrun, pending/running, terminal success/failure/cancellation, incomplete/unknown, configuration mismatch, retained history, stale/superseded context, unavailable/removed schema, and loading/disabled states. Include non-first schema selection, exact returned UID, wrong/historical task and document evidence, double submission, mutation-time prerequisite changes, auth return, and timeout followed by safe checking. Test upsert content and delete absence where supported; a direct handler call alone does not prove a changed form or confirmation.
- **D-19:** Inspect realistic before/after affected compositions in light/dark at desktop/narrow and a relevant intermediate breakpoint; retain System/reduced-motion/keyboard/focus parity. Use existing LiveView/component, token-contrast, focused browser and mounted lanes. Mutations and fixture seeding belong only in owned disposable stacks. Preserve both retained previews, the original dirty checkout, frozen Phase 173 source, and unrelated resources; no routine human UAT, paid visual judge or new required job.
- **D-20:** Maintain PR-first delivery. Discussion is planning-only and leaves OPUX-20–22 pending. The next command is `$gsd-ui-phase 175`, then `$gsd-plan-phase 175`; automatic chaining remains disabled. No merge, release, host trust approval or advisory-risk acceptance is inferred from recommendation-following.

### Agent's Discretion

Choose concise state/action/help copy, exact layout/disclosure placement consistent with the hierarchy above, restrained local status cues, and bounded internal factoring only where actual reuse warrants it. Researchers/planners own implementation and proof design. Correct demonstrated contract/correlation bugs within the approved scope; a genuinely unresolved product or safety-policy change requires explicit maintainer direction.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read the relevant references before planning or implementing. All repository paths are relative to the project root.**

### Approved scope and decision authority

- `.planning/ROADMAP.md` — Phase 175 goal, OPUX-20–22, per-phase acceptance and later-phase boundaries.
- `.planning/REQUIREMENTS.md` — complete approved requirements and design/verification constraints; dated initialization prose does not supersede its current completed rows.
- `.planning/PROJECT.md` — product truth, existing verification/design lifecycle, PR-first posture and handoff policy.
- `.planning/STATE.md` — current working checkout, preserved previews, completed phases and source-bounded evidence limits.
- `.planning/reference/OPERATOR-UX-RUBRIC.md` — task/scope/state/action/diagnostic hierarchy, quiet healthy states, domain language, safety and evidence rules.
- `.planning/reference/OPERATOR-UX-AUDIT-2026-10-09.md` — accepted follow-up baseline and binding Phase 175 inputs; original heuristic score is not an after-fix approval.
- `.planning/research/v1.43/SCOPE.md` — approved reuse/boundaries and comp-first sequence; original checkout statements are historical, current STATE governs.
- `.planning/reference/OPERATOR-UI-REFINEMENT.md` and `.planning/reference/OPERATOR-UI-QUALITY.md` — concrete feedback and economical per-slice proof.
- `.planning/phases/174-recovery-entry-and-diagnosis/174-CONTEXT.md` — inherited exact-identity, selection, host-auth and stale-result decisions, with the overview corrections noted above.
- `.planning/phases/174-recovery-entry-and-diagnosis/174-VERIFICATION.md` — completed dependency evidence, within its declared source/scenario limits.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md` — inherited visual/action/time behavior; later accepted DESIGN.md changes govern superseded palette/copy.

### Product, platform and delivered UI

- `PRODUCT.md` — co-primary integrator/operator audience and existing capability/ownership boundaries.
- `DESIGN.md` — current cool-neutral treatment, terminology and shared hierarchy.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — implemented component/token vocabulary.
- `scrypath_ops/docs/operator-ia.md` — recovery and preflight loops; its alias wording is a scoped copy correction under D-16.
- `guides/sync-modes-and-visibility.md` — accepted versus visibility/completion contracts.
- `guides/drift-recovery.md` — existing report-first repair/reindex runbook, not permission for a new automatic operation.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — thin LiveViews, contexts, URL-owned selection, async/state/latency guidance; confirm version-specific APIs against the installed dependency.
- `CONTRIBUTING.md` — focused checks, existing CI lanes, PR-first and two-stage exact-source closeout.

### Primary guidance checked for this discussion

- [Meilisearch asynchronous operations](https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations) — acceptance is enqueued, task progress/terminal status and exact UID are separate facts.
- [Meilisearch swap indexes](https://www.meilisearch.com/docs/reference/api/indexes/swap-indexes) — actual pairwise swap semantics and its asynchronous task response; no new API option is approved.
- [GOV.UK details guidance](https://design-system.service.gov.uk/components/details/) — disclose secondary expert information while keeping necessary decisions visible.

Version-specific LiveView security documentation could not be fetched in this preparation; no new API claim or upgrade is made. Research should use installed source/official version documentation for the implementation.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — schema picker, sections, refresh controls, quiet actions, status, native disclosure, modal, exact-value/time and handoff components.
- `scrypath_ops/assets/css/app.css` and `scrypath_ops/assets/js/ops_hooks.js` — delivered theme/action/focus/disclosure conventions; reuse rather than replace.
- `scrypath_ops/lib/scrypath_ops/operator_selection.ex` — canonical allowlist resolution, encoded scoped workflow paths and unavailable explicit target behavior.

### Established Patterns

- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` — automatic reconciliation, explicit configuration read, generation invalidation, retry receipt observation, promotion confirmation and exact task UID async result handling. Current plain sync outcome, quiet unrun configuration and successful/mismatched disclosures are the audit baseline.
- `scrypath_ops/lib/scrypath_ops/promotion_eligibility.ex` — current same-context fail-closed eligibility rules, including retained failure history. Preserve policy and recheck at submission.
- `scrypath_ops/lib/scrypath_ops/recovery_observation.ex` — bounded opaque host/generation receipt with exact worker/attempt/runtime/task correlation; telemetry provides identity, not verified success.
- `scrypath_ops/lib/scrypath_ops/document_observation.ex` — authoritative active-index expected upsert/delete effect check with explicit running/failed/unknown outcomes.
- `lib/scrypath/meilisearch/index_management.ex` — existing live/target naming and swap call; public/core behavior is not redesigned here.

### Integration Points and Research Follow-ups

- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` — accepted source-qualified retry receipt and exact-schema Sync and drift handoff; do not duplicate its mutation controls.
- `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex` — existing host sensitive-action/sudo boundary.
- `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`, `scrypath_ops/test/scrypath_ops/promotion_eligibility_test.exs`, `scrypath_ops/test/scrypath_ops/recovery_observation_test.exs` — existing correlation, stale-result, confirmation, timeout and eligibility assertions. Inventory rendered/browser coverage before adding narrowly useful proof.
- `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts`, `examples/scrypath_ecommerce/e2e/phase174_recovery.spec.ts`, `examples/scrypath_ecommerce/e2e/operator_ux_followup.spec.ts` — existing mounted/disposable and audit presentation evidence; recheck selectors/oracles and use disposable fixtures for mutation cases.
- Source observations requiring investigation: promotion currently keeps only accepted/terminal/unconfirmed UI status while waiting; its "Refresh checks" refreshes reconcile/configuration, not explicitly the retained task. Confirm how authoritative running/task re-observation should satisfy OPUX-21 without confusing observer activity or resubmitting. Promotion async callbacks check generation/UID; recheck current allowlist/context safety before displaying an outcome, as recovery callbacks already do. Advanced disclosure currently has server-owned `open`; test patch persistence/active-result visibility. Treat these as research questions, not verified bugs or a predetermined implementation.

No codebase maps, phase SPEC/context/plans/checkpoint, matching todos, or packaged/raw spike/sketch findings were present at initialization. Scout used current relevant source and test inventories.
</code_context>

<specifics>
## Specific Ideas

- A clear sync/configuration view is compact and calm; it does not repeat five zero counters or verbose reassurance. The useful optional action is checking index configuration.
- A completed queue job with missing backend/document evidence says what finished and what remains unconfirmed; it does not say recovery succeeded.
- After a swap observation times out, keep the exact task UID and a safe checking action. Unknown remote outcome must not become an invitation to submit another swap.
- One schema can be selected while another is worse in overall health. Show the selected schema only on the workflow with an actual selector and retain all-schema overview returns.
- The maintainer reviews the implemented working result; do not ask them to reopen basic clarity issues already covered by the rubric.
</specifics>

<deferred>
## Deferred Ideas

No new feature was requested. Preserve the existing boundaries: broad brand redesign, automatic recovery/backfill/reindex, durable receipt/history services, generalized live freshness monitoring, new backend/auth policy, infrastructure operations, and additional Search/Playbook scope are outside Phase 175. Phases 176–177 retain their approved work. None is promoted to a product promise by this context.
</deferred>

---

*Phase: 175-repair-and-verification*
*Context gathered: 2026-10-10*
