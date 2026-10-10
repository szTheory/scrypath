# Phase 175: Repair and Verification - Research

**Researched:** 2026-10-10  
**Domain:** Phoenix LiveView operator workflows, async task observation, Meilisearch repair safety  
**Confidence:** HIGH for repository behavior and pinned request semantics; MEDIUM for external docs

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Use the accepted audit and rubric as binding inputs. Do not restart a broad interview or repeat already fixed hierarchy/brand work. Evaluate relevant operator/product, design/accessibility, Phoenix/browser, security, asynchronous evidence, and maintenance concerns; stop when another pass would not change the recommendation.
- **D-02:** Prefer existing components, native controls, and small owned code over another dependency. The current palette, theme picker, typography, spacing, quiet actions, time/copy feedback, and mobile/keyboard conventions carry forward. Resolve the affected compositions in 175-UI-SPEC.md before implementation planning; do not reinitialize Impeccable or repair sidecars incidentally.
- **D-03:** The page answers: "Did this recovery work, and does the index configuration match?" Keep a real visible schema selector, scope-matching content/URLs, and full module/index identifiers available. Specific recovery links retain the validated schema. Control Room and Search health always return to all schemas. The later maintainer correction supersedes older Phase 174 D-06/D-19 overview target labels/navigation.
- **D-04:** Lead with the active retry's outcome when a valid retry handoff exists, then ordinary sync status, index configuration, and a separately disclosed advanced promotion path. A normal visit has no invented retry panel. State and its useful next read-only action precede verbose diagnostics; exact composition and concise labels remain agent discretion within the UI contract.
- **D-05:** Use state-appropriate ordinary actions: pending work offers a progress check; known failures link to that schema's Failed sync work; unavailable observations explain how to retry the check or inspect configuration. Refresh/check only observes. Existing explicit retry stays attached to its inspected source-qualified failed record. Configuration differences do not authorize an automatic repair or create a new UI mutation; point to the existing supported runbook where needed.
- **D-06:** Interface copy uses **Index configuration** for declared fields/search settings versus the live index. Keep \`index_contract_drift\` and other established technical API names in code/diagnostics. Matching configuration says nothing about whether database records have reached search. No zero counters, quiet summary, finished queue job, or configuration match may imply fleet health, document freshness, or promotion readiness.
- **D-07:** Preserve automatic bounded sync inspection and explicit/lazy configuration comparison. An unrun comparison stays quiet "Not checked". Successful comparison detail is optional; actionable differences are exposed. Loading, missing backend/setup, incomplete reads, and unknown values remain explicit. A configuration-read failure does not erase an independently valid sync result or imply that documents differ.
- **D-08:** Keep decision-changing failures, blockers, uncertainty and current scope visible; disclose raw flags, successful comparison tables, framework details, and verbose diagnostics. Zero-work states omit redundant counts and explanations. Tooltips supplement needed terms, rather than justify irrelevant facts. Keep technical identities readable and wrapped rather than truncated.
- **D-09:** Distinguish accepted/queued, authoritatively running, terminal success, terminal failure/cancellation, and unavailable/unconfirmed outcomes. A busy observer is a check in progress, not proof the backend is running. Do not synthesize a running state merely because a wait is active or time has elapsed. A successful enqueue/HTTP response/flash is acceptance only.
- **D-10:** An active recovery receipt retains the exact replacement queue job, attempt, operation, source failure, schema/index and matching backend task UID where known. Queue completion without task/document evidence remains an intermediate outcome. "Recovery verified" requires the matching authoritative queue/task and active-index document effect, including the expected absence for a delete; never a historic unrelated success or a generic search hit.
- **D-11:** Failed reads, missing task IDs, inaccessible/expired/restarted receipt storage, superseded attempts, wrong endpoint/Oban instance/repo/prefix/node, schema changes and stale async callbacks cannot become zero, success, or a failed remote task. Preserve the established bounded receipt and generation/host identity rules. Retained failure history remains history and continues to affect promotion under the existing policy; it need not erase verification of a different accepted retry.
- **D-12:** Retain the returned promotion task UID through accepted, terminal and unconfirmed outcomes. Only a matching terminal task outcome supports "Index swap completed" or a remote task failure. A failed/timed-out observation remains unconfirmed and offers safe read-only rechecking; refreshing must not submit another swap. Keep task completion, current index state and observed document effect separate when presenting what has been established.
- **D-13:** Advanced index promotion remains available in its own native disclosure rather than competing with ordinary checks. Preserve deliberate expansion through appropriate LiveView patches. Once there is active accepted/running/unconfirmed work or a terminal error, its state and identity must be discoverable without searching a silently collapsed panel. Settle its rendered visibility/focus behavior in the UI contract.
- **D-14:** Show the relevant readiness/blocking reason and safe next step. Preserve the current fail-closed eligibility evaluation: allowed schema, supported backend, current same-context reports, distinct observed live/target indexes, observed reindex/cutover state, no unresolved pending or failed work, and matching configuration. Do not loosen or expand eligibility policy as a UI cleanup. A blocking historic failure is not automatically deleted or ignored.
- **D-15:** Confirmation shows the full schema and exact live/target index pair and a plain description of the effect. Keep cancellation, focus containment/return, host sensitive-action authorization/sudo, current-allowlist validation, prerequisite rechecks immediately before submission, and existing duplicate/in-flight guards. A disabled or hidden client control is never the enforcement boundary. An auth return restores context without replaying a mutation.
- **D-16:** Correct the existing "live alias" explanation to match the actual Meilisearch index swap. The source calls \`swap_indexes\` for the live/target pair; describe promoting the prepared target through that swap without inventing an alias API or changing public behavior. Include the operator-facing effect in ordinary copy and preserve detailed swap consequences in supporting documentation/diagnostics. Validate the pinned backend's existing semantics in research; do not adopt newer optional API features from current docs.
- **D-17:** Reuse passing audit/phase evidence within its source and scenario limits; inspect current code and cover missing Phase 175 claims independently. Prior 57-case UX proof verifies presentation/navigation, not every repair/promotion path. Each phase closes its own requirements with rendered event/navigation proof, authoritative correlation, relevant standalone and mounted paths, and exact-source PR/CI evidence.
- **D-18:** Exercise healthy/empty/unrun, pending/running, terminal success/failure/cancellation, incomplete/unknown, configuration mismatch, retained history, stale/superseded context, unavailable/removed schema, and loading/disabled states. Include non-first schema selection, exact returned UID, wrong/historical task and document evidence, double submission, mutation-time prerequisite changes, auth return, and timeout followed by safe checking. Test upsert content and delete absence where supported; a direct handler call alone does not prove a changed form or confirmation.
- **D-19:** Inspect realistic before/after affected compositions in light/dark at desktop/narrow and a relevant intermediate breakpoint; retain System/reduced-motion/keyboard/focus parity. Use existing LiveView/component, token-contrast, focused browser and mounted lanes. Mutations and fixture seeding belong only in owned disposable stacks. Preserve both retained previews, the original dirty checkout, frozen Phase 173 source, and unrelated resources; no routine human UAT, paid visual judge or new required job.
- **D-20:** Maintain PR-first delivery. Discussion is planning-only and leaves OPUX-20–22 pending. The next command is $gsd-ui-phase 175, then $gsd-plan-phase 175; automatic chaining remains disabled. No merge, release, host trust approval or advisory-risk acceptance is inferred from recommendation-following.

### the agent's Discretion

Choose concise state/action/help copy, exact layout/disclosure placement consistent with the hierarchy above, restrained local status cues, and bounded internal factoring only where actual reuse warrants it. Researchers/planners own implementation and proof design. Correct demonstrated contract/correlation bugs within the approved scope; a genuinely unresolved product or safety-policy change requires explicit maintainer direction.

### Deferred Ideas (OUT OF SCOPE)

No new feature was requested. Preserve the existing boundaries: broad brand redesign, automatic recovery/backfill/reindex, durable receipt/history services, generalized live freshness monitoring, new backend/auth policy, infrastructure operations, and additional Search/Playbook scope are outside Phase 175. Phases 176–177 retain their approved work. None is promoted to a product promise by this context.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPUX-20 | Distinguish index configuration, document freshness, observation/mutation, ordinary repair/advanced promotion. | Separate reconcile/config reads and document-effect observation already exist; add exact promotion task recheck. |
| OPUX-21 | Distinguish accepted/queued, authoritative running, terminal and unknown; failed reads remain unknown. | Task source and recovery/document correlation patterns ground state mapping and tests. |
| OPUX-22 | Mutations are eligible, host-authorized, confirmed and supported by matching task/index/document evidence. | Preserve gates/eligibility; add exact UID observation and executable standalone/mounted proof. |
</phase_requirements>

## Summary

SyncDriftLive already retains the returned Meilisearch task UID and handles matching terminal results, but “Refresh checks” refreshes reconcile/configuration/eligibility only. Add a read-only exact-UID task observation: normalized `enqueued` remains accepted/queued; only an exact-UID response normalized to `processing` establishes running. Failed reads remain unknown, and checking never resubmits a swap. Revalidate current schema and host/runtime identity when applying async results, following recovery observation's stronger checks. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:150-175,244-344,497-510,719-727,738-883; 175-PATTERNS.md task-normalization analog]

Keep retry source-qualified in Failed sync work; checks remain observations; promotion stays fail-closed, confirmed, allowlisted and gated at mutation time. Put status/UID outside native disclosure to preserve manual expansion without hiding active/terminal state. Prior 57 UX cases prove presentation/navigation only. Phase 175 needs rendered events, exact task/document correlation and standalone/mounted mutation paths on owned disposable stacks. [CITED: 175-CONTEXT.md D-05,D-09–D-19; 175-UI-SPEC.md; VERIFIED: sync_drift_live.ex:206-229,295-344,805-883,1297-1387]

**Primary recommendation:** Add localized exact-task recheck using existing client and recovery selection/runtime guards; keep status/UID visible outside disclosure; preserve policy; verify rendered transitions and mounted paths.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Schema/workflow URL selection | Frontend Server (SSR) | Browser / Client | LiveView resolves allowlisted selection and owns patch state. |
| Promotion authorization/eligibility | API / Backend | Frontend Server (SSR) | Server rechecks gate, allowlist, reports and eligibility before mutation. |
| Swap submission/task lookup | API / Backend | Database / Storage | Meilisearch owns task truth; server stores UID and observes it. |
| Recovery verification | API / Backend | Database / Storage | Queue/task and active-index effect are checked against receipt. |
| Disclosure expansion/focus | Browser / Client | Frontend Server (SSR) | Browser owns native details; existing hook preserves patches. |

## Standard Stack

| Library | Version | Purpose |
|---------|---------|---------|
| Phoenix | 1.8.12 | Existing operator app |
| Phoenix LiveView | 1.1.33 | Events, async results, rendered behavior |
| Req | 0.6.3 | Existing HTTP client |
| Meilisearch | v1.15 | Public v1 backend/task authority |
| Oban | 2.23.0 | Optional queue path and job identity |
| ExUnit / Phoenix.LiveViewTest | Installed | Rendered event and behavior tests |
| Playwright | Existing ecommerce package | Mounted browser interaction |

Versions are pinned in scrypath_ops/mix.lock:35,40,46, root mix.lock:30, and CONTRIBUTING.md:211-215/CI service config. No packages are recommended; legitimacy audit is not applicable.

## Architecture Patterns

### System Architecture

~~~text
Operator browser -> scoped Sync/drift LiveView
  -> refresh: independent sync/config observations
  -> check swap: retained UID -> exact Meilisearch task read
  -> retry handoff: bounded receipt -> queue/task -> active-index effect
  -> promote: host gate + fresh prerequisites + eligibility -> swap -> returned UID
Rendered state <- accepted / running / terminal / unknown
~~~

### Recommended Project Structure

Keep changes in scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex. Reuse RecoveryObservation, DocumentObservation, PromotionEligibility, OperatorSelection and existing task client. Extend owned LiveView and focused observation tests only as needed. [VERIFIED: opened source and test files.]

### Exact task observation, not resubmission

Store UID returned on accepted submission. “Check swap status” requests that UID; only matching task data is authoritative. Keep request-in-flight separate from remote state. Failed GET or missing UID remains unknown. Never call swap from check event. [CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations; VERIFIED: lib/scrypath/meilisearch/client.ex:42-54,80-83; sync_drift_live.ex:150-175,805-883]

The source quotes @queued_statuses [:enqueued, :processing]; final statuses include :succeeded, :failed, :cancelled; timeout is {:error, {:timeout, task}}. Use these source values. Observer activity is not remote running. [VERIFIED: lib/scrypath/meilisearch/tasks.ex:11,99-183]

### Revalidate scope for async results

Capture generation, schema, UID and available host/runtime identity. Before publishing result, require current allowlist and matching runtime; stale results cannot overwrite new selection. Recovery checks generation, receipt, selection, endpoint, Oban instance, node, repo and prefix. Reuse this local pattern without a broad abstraction. [VERIFIED: sync_drift_live.ex:244-344,461-510,550-684,719-727]

### Preserve native disclosure state

Leave details user-controlled; do not force open on patches. Put current status/UID outside. Existing OpsHealthDetails and ops_hooks.js preserve manual open/focus through patches. [VERIFIED: sync_drift_live.ex:1297-1348; posture_live.ex:410-417,570-586; ops_hooks.js:36-97]

### Anti-Patterns

- Spinner/busy/elapsed wait presented as remote running.
- Failed task read presented as remote failure or success.
- Refreshing reports instead of checking retained UID.
- Resubmitting swap after unconfirmed outcome.
- Calling the swap an alias rename or adding newer optional request fields to v1.15.
- Hiding consequential status/UID inside collapsed details.

## Don't Hand-Roll

| Problem | Use | Why |
|---------|-----|-----|
| Task lifecycle | Existing Tasks and Client.task(uid, opts) | Existing exact request/state contracts. |
| Schema selection | OperatorSelection.resolve/2 and configured allowlist | Safe canonical URL behavior. |
| Host authorization | Gating plus fresh server validation | Browser is not trust boundary. |
| Recovery effect proof | RecoveryObservation + DocumentObservation | Exact correlation and expected active-index effect. |
| Disclosure/focus | Native details and existing hook | Existing patch behavior. |

**Key insight:** Missing evidence means unknown mutation outcome; the safe follow-up observes the same UID.

## Pinned Meilisearch Semantics

Project CI/compose pins v1.15. Existing client POSTs /swap-indexes with an indexes pair and GETs /tasks/{task_uid}. [VERIFIED: CONTRIBUTING.md:211-215; .github/workflows/ci.yml:76-77,164-166; compose.yaml:8-9; lib/scrypath/meilisearch/client.ex:42-54,80-83]

Official swap docs describe an asynchronous pairwise swap of documents, primary key, settings and task history; acceptance returns a task UID. Current docs show optional rename, but installed request/pinned contract do not use it; do not add it. Replace inaccurate “live alias” copy with the swap effect. [CITED: https://www.meilisearch.com/docs/reference/api/indexes/swap-indexes; VERIFIED: client.ex:42-54]

## Common Pitfalls

| Pitfall | Prevention |
|---------|------------|
| Busy observer mistaken for backend running | Keep checking separate; exact task response establishes running. |
| Wrong task or stale schema callback displayed | Exact UID/current selection/runtime on success and error; otherwise unknown. |
| Queue completion mistaken for repaired document | Correlate attempt/task; verify upsert projection or delete absence at active index. |
| Stale eligibility authorizes swap | Gate, allowlist, fresh reports/config, eligibility, duplicate guard before POST. |

[VERIFIED: sync_drift_live.ex:244-344,461-510,719-727,805-905; recovery_observation.ex:118-173; document_observation.ex:36-155; gating.ex:21-49,111-127; promotion_eligibility.ex:4-72.]

## Code Examples

Existing request boundary:

~~~elixir
swap_indexes(source_uid, target_uid, opts)
task(task_uid, opts)
~~~

Use existing Client functions. Request shape is {"indexes": [source_uid, target_uid]}; lookup is /tasks/{task_uid}. [VERIFIED: lib/scrypath/meilisearch/client.ex:42-54,80-83]

Rendered proof should submit actual check/confirmation event and assert status, retained UID and no second swap. Cover wrong UID, read error, timeout/recheck, terminal states, schema/host changes, duplicate submission, auth return and changed prerequisites. Direct handler calls do not prove rendered control/URL behavior. [VERIFIED: sync_drift_live_test.exs:260-377,498-651; scrypath_ops/AGENTS.md:137-218]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | Focused tests | No selected asdf version | Installed versions include 1.19.5 / OTP 28; floor 1.17 | Select project-supported version |
| Node/npm | Mounted lane | Yes | Node v22.14.0 / npm 11.1.0 | — |
| Docker | Owned disposable proof | Yes | 29.5.2 | — |
| Meilisearch | Mounted proof | Not probed | — | Owned disposable compose only during execution |

No service/container/preview/seed data was started or changed.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / Phoenix.LiveViewTest; Playwright mounted browser |
| Config file | scrypath_ops/test/test_helper.exs |
| Quick run command | From scrypath_ops/: mix test test/scrypath_ops_web/live/sync_drift_live_test.exs test/scrypath_ops/promotion_eligibility_test.exs test/scrypath_ops/recovery_observation_test.exs test/scrypath_ops/document_observation_test.exs |
| Full suite command | Repo root: mix verify.ops_ui; mounted: mix verify.ecommerce_mounted or make -C examples/scrypath_ecommerce verify-mounted |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPUX-20 | Rendered selection, distinct config/freshness, read-only refresh, swap wording | LiveView/browser | cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs | Yes; add event/copy assertions |
| OPUX-21 | Exact UID accepted/running/terminal/unknown; failed reads unknown; recovery effect | LiveView/unit | Focused command above | Yes; add running/recheck and stale-context |
| OPUX-22 | Host-authorized confirmation and exact task evidence, standalone/mounted | LiveView/Playwright | mix verify.ops_ui; mix verify.ecommerce_mounted | Lanes exist; Phase 175 cases needed |

### Sampling Rate

- Per task commit: focused ExUnit command above.
- Per wave merge: mix verify.ops_ui.
- Phase gate: owned disposable mounted proof, ops UI gate, green exact-SHA CI.

### Wave 0 Gaps

- Rendered Check swap status proves exact UID query, no resubmission, accepted/running, timeout, read error, wrong UID and terminal states.
- Callback tests cover changed allowlist/schema, endpoint/Oban/repo/prefix/node and stale generation on success/error.
- Disclosure expansion survives patches while active status/UID stays outside and visible.
- Render confirmation/auth return, changed prerequisites, duplicate submit and host gate; cover standalone and mounted disposable paths.
- Assert pinned-v1.15 request/response and corrected copy; cover upsert projection and delete absence.
- Select active asdf Elixir before repository commands.

Existing tests cover eligibility match, exact returned UID, stale recovery selection, promotion terminal/timeout and current-refresh no-resubmit, receipt expiry/context, and document upsert/delete. Prior 57 UX cases are presentation/navigation, not Phase 175 behavior proof. [VERIFIED: sync_drift_live_test.exs:164-209,260-377,498-651; promotion_eligibility_test.exs; recovery_observation_test.exs; document_observation_test.exs; accepted audit.]

## Security Domain

Security enforcement is enabled. Current OWASP ASVS v5 categories relevant here: V2 validation/business logic, V3 web frontend, V6 authentication, V7 session, V8 authorization, V11 cryptography, V12 secure communication. V2/V8 cover mutation validation and host authorization; V3 rendered confirmation; preserve V6/V7/V12; no new cryptography. Older V2 Authentication/V4 Access Control labels are not current v5 labels. [CITED: https://owasp.org/projects/asvs]

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Validation/business logic | Yes | Server-side schema, pair and fresh-precondition validation |
| V3 Web frontend | Yes | Native controls, focus-safe confirmation; no client-only authorization |
| V6 Authentication | Preserve | Existing host authentication |
| V7 Session management | Preserve | Existing session/sudo; no mutation replay |
| V8 Authorization | Yes | Existing sensitive-action gate and allowlist |
| V11 Cryptography | No new surface | Reuse current transport/auth |
| V12 Secure communication | Preserve | Existing configured backend client |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged/stale promotion event | Tampering/Elevation | Host gate and fresh validation before POST |
| Cross-schema/wrong-task callback | Spoofing/Tampering | Allowlist, exact UID, generation/runtime identity |
| Read failure rendered as remote failure | Repudiation/Information | Preserve unknown; distinguish observer error |
| Duplicate promotion after timeout | Tampering | Retain UID, GET only, retain mutation guard |

## Project Constraints (from AGENTS.md)

- Preserve Elixir OSS, Ecto-first/Phoenix-friendly scope; Meilisearch is public v1 target and adapter seam stays internal.
- Keep inline, Oban and manual sync; state eventual consistency, delete semantics, backfills and reindexing explicitly.
- Prioritize minimal setup/Phoenix ergonomics, correctness and operational clarity; public release waits for quality bar.
- Follow CONTRIBUTING; focus edits, run named checks, update .planning/PROJECT.md only for intentional scope/shipped-claim changes.
- Keep main green and PR-first for feature work; close with executable/exact-SHA evidence, not routine human UAT or simulated approval.
- In scrypath_ops use existing Req; no HTTPoison/Tesla/httpc/new dependencies. Follow Phoenix 1.8, CSS/JS hook patterns, native controls and accessible LiveView tests.
- Use idiomatic Elixir and safe allowlisted selection; never create atoms from user input or bypass server gates. Avoid Process.sleep/Process.alive?; use start_supervised! and focused CONTRIBUTING checks.

## Open Questions

1. The subsequent pattern map resolves the task response seam: configured `meilisearch_client` with `Client` fallback, `Client.task(uid, config)` returns a map, and `TaskPayload.normalize/2` extracts `taskUid`/`uid` while keeping `enqueued` distinct from `processing`. Implementation preflight must still pin tests to the configured client's actual response and reject a normalized UID different from the requested UID. This is a technical check, not an unresolved product decision; see `175-PATTERNS.md`.

## Sources

### Primary (HIGH confidence)

- 175-CONTEXT.md, 175-UI-SPEC.md, REQUIREMENTS.md, ROADMAP.md — scope, UI contract, OPUX requirements.
- sync_drift_live.ex, promotion_eligibility.ex, recovery_observation.ex, document_observation.ex, gating.ex, operator_selection.ex, client.ex, tasks.ex — code behavior and seams.
- CONTRIBUTING.md, root/app AGENTS.md, focused tests, ops_hooks.js — constraints and verification.

### Secondary (MEDIUM confidence)

- https://www.meilisearch.com/docs/reference/api/indexes/swap-indexes — swap effects/async response.
- https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations — task UID/lifecycle.
- https://owasp.org/projects/asvs — current category numbering.
- https://design-system.service.gov.uk/components/details/ — native disclosure guidance.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Local exact-task observation in SyncDriftLive is smallest adequate approach. | Summary | Client behavior may warrant a small existing-module helper. |
| A2 | Existing task GET response suffices for authoritative running without new API/dependency. | Pattern | Incorrect mapping could misstate state; inspect normalizer. |
| A3 | ASVS category descriptions cited correspond to current v5. | Security | Verify official version details before locking controls. |

## Metadata

**Confidence breakdown:** Stack HIGH (lock/config); architecture HIGH (opened code); pitfalls HIGH for repository, MEDIUM for external docs.  
**Research date:** 2026-10-10  
**Valid until:** 2026-11-09
