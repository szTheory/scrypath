# Phase 173: Shared Visual Foundation and Operational Time — Research

**Researched:** 2026-10-06  
**Domain:** Phoenix LiveView operations UI, browser preferences, timestamp provenance, accessible disclosure  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Primary research and adversarial synthesis are already delegated; do not reopen the product interview or palette decision.
- D-02–D-22: Treat the phase context decisions as locked. Preserve the approved warm-neutral light and neutral-dark palette, incumbent spacing and typography exceptions, existing native components/hooks, and no-new-dependency constraint. Requirements OPUX-09 through OPUX-15 define this phase’s scope. Both standalone Ops and mounted Ops are in scope. Keep the work bounded; phase 174+ owns later workflow refinements.
- Preserve full source ISO precision and source offset at the timestamp normalization seam; inspect source timestamp meaning before choosing presentation. Treat last completed indexed task as observed operational history, not document freshness.
- Do not mutate the retained preview at port 4012. Use disposable stacks for mutation fixtures.

### the agent's Discretion
- Implementation seams, test organization, and formatting details that do not conflict with the locked design contract.

### Deferred Ideas (OUT OF SCOPE)
- Later workflow refinements assigned to phase 174 and beyond.

> Note: Exact D-01–D-22 transcription was not available in the bounded handoff context. The approved decisions material to planning are recorded above; consult 173-CONTEXT.md for the canonical wording before locking plan details.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| OPUX-09 | Flat neutral shell in light, dark, System and responsive layouts. | Revise shared tokens; preserve functional scroll-edge cues and verify both asset entrypoints. |
| OPUX-10 | Explicit degraded, failed and unknown labels with local cues on neutral surfaces. | Preserve current classification; remove broad warning fills and whole-record outlines. |
| OPUX-11 | Neutral zero-error metrics; nonzero and unavailable values remain distinct. | Preserve observation meaning; zero does not prove health or freshness. |
| OPUX-12 | Exactly one selected theme preference with matching accessible state. | Guard storage, distinguish preference from appearance, cover OS changes, navigation, reload and tabs. |
| OPUX-13 | Quiet hover, focus, pressed, selected, disabled and busy states. | Reuse shared native components/hooks; preserve meaningful icon and label across patches. |
| OPUX-14 | Stable readable last-success times with exact timestamp/timezone access. | Preserve source precision/offset, associate age with observation snapshot, cover absent/unknown/future/failed checks. |
| OPUX-15 | Truthful full-ISO timestamp copying in standalone and mounted Ops. | Confirm only after writeText resolves; persistent failure plus selectable exact evidence; Checked has no copy. |
</phase_requirements>

## Summary

Implement this as a shared visual-foundation pass across existing Ops surfaces, then address operational-time semantics at the normalization boundary and in the existing time component. Avoid adding a theme, date, or clipboard dependency. The project already has native LiveView hooks, shared Ops components, CSS tokens, contract tests, and mounted-app browser tests. [VERIFIED: source paths below]

The critical correctness issue is timestamp provenance: queue completion and search-task finish times are observations of completed operational work, not indexed-document freshness. The current normalizer parses ISO text into DateTime and drops its source offset; the display truncates precision and computes relative time against the current render clock. Retain exact source text/offset and parsed instant together, and anchor humanized output to the refreshed snapshot. [VERIFIED: lib/scrypath/operator/state.ex:93-121; lib/scrypath/operator/status.ex:100-130; scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1203-1243]

**Primary recommendation:** preserve existing component and hook seams, make preference/storage behavior resilient in both entrypoints, and test the rendered contract plus real browser behavior. Static UI-spec captures are design evidence only; they do not prove application behavior.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Theme preference and persistence | Browser / Client | LiveView shell | Preference, system media query, local storage, and cross-tab changes are client state. |
| Neutral visual foundation and action states | Browser / Client | Frontend Server (SSR) | CSS/component contracts define appearance; LiveView assigns action state. |
| Completion timestamp provenance | API / Backend | Browser / Client | Normalize source timestamps once; display exact evidence and snapshot-stable relative text. |
| Disclosure and clipboard feedback | Browser / Client | Frontend Server (SSR) | Native details/clipboard APIs and hooks implement interaction in both entrypoints. |

## Project Constraints (from AGENTS.md)

- Scrypath is an Elixir OSS library; Phoenix/Ecto ecosystem fit and operational clarity are core product constraints.
- Consult prompts/ material for architecture, Phoenix/Elixir practices, and brand decisions. Preserve the approved brand direction.
- Keep edits focused, follow CONTRIBUTING.md verification, and preserve existing work.
- Keep the library Ecto-first and its internal backend seam; this UI phase does not change public backend scope.
- This artifact is the only assigned file. Existing dirty source and preview state must be preserved.

## Standard Stack

Use the current Elixir/Phoenix LiveView/EEx/CSS and existing browser hooks already in the repository; no dependency change is indicated. [VERIFIED: repo source and project constraints] Phoenix LiveView’s official hook guidance supports mounted/updated lifecycle handling and documents hook use outside LiveView. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.27/js-interop.html]

The browser Clipboard API’s writeText promise resolves after clipboard content is updated and can reject; storage access can throw SecurityError under browser policy. Guard storage reads/writes and make success feedback conditional on promise resolution. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText; https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage]

Use native disclosure and existing hooks; do not install a new dependency. Color must not be the only carrier of status, and status changes should be programmatically exposed without moving focus. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html; https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html]

## Architecture Patterns

### Timestamp normalization and presentation

Current source values are obtained from Meilisearch task finishedAt and Oban completed_at. The source state struct carries `at: DateTime.t() | nil`. [VERIFIED: lib/scrypath/operator/state.ex:13-25,34-68,93-121; quote: `at: DateTime.t() | nil`, `Map.get("finishedAt")`, `Map.get(:completed_at, Map.get(job, "completed_at"))`, `{:ok, datetime, _offset} -> datetime`]

Preserve the original ISO string at normalization with the parsed DateTime/instant; do not reconstruct the source string from DateTime. Compare future/past values at full available precision. Anchor relative display to the summary’s refreshed_at/snapshot time. “Last success” means newest completed task in inspected history, not that documents are current. [VERIFIED: lib/scrypath/operator/status.ex:100-130; `last_succeeded: last_completed(states)`; scrypath_ops/lib/scrypath_ops/posture.ex:53-83, which assigns refreshed_at on summary construction]

Use explicit presentations for absent success, absent timestamp, unavailable source, unknown time, and future completion; do not collapse these into zero or a fabricated date. Follow UI-SPEC thresholds and copy verbatim. Exact disclosure should show source-preserving evidence; clipboard success follows only a resolved writeText promise. [CITED: Clipboard API URL above]

### Theme preference

Keep selected preference (System, Light, Dark) separate from effective appearance. Guard localStorage access and fall back to in-memory behavior if blocked. Keep root and mounted entrypoint behavior aligned, including cross-tab changes and navigation/patch behavior. Current root layout has unguarded access and theme controls; mounted app duplicates theme initialization but lacks storage-event synchronization. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex:32-74; scrypath_ops/lib/scrypath_ops_web/components/layouts.ex:387-419; examples/scrypath_ecommerce/assets/js/app.js:30-77]

### Component seams

Prefer existing shared Ops time, shell, posture, and hook modules. CSS token work should avoid broad stateful selector regressions. Current OpsTime helper truncates to seconds and evaluates relative text against DateTime.utc_now(); current clipboard hooks in both bundles silently ignore failure. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1203-1243,1632-1659; scrypath_ops/assets/js/app.js:53-63; examples/scrypath_ecommerce/assets/js/app.js:90-99]

## Implementation-Ready File Seams

| Seam | Planning use |
|---|---|
| `lib/scrypath/operator/state.ex` | Preserve raw source ISO and parsed value/offset at the normalization seam. |
| `lib/scrypath/operator/status.ex` | Preserve completed-history meaning and no-success semantics. |
| `scrypath_ops/lib/scrypath_ops/posture.ex` and `.../live/posture_live.ex` | Snapshot refresh timing and retained observation behavior. |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | Shared status, action, time, disclosure and clipboard presentation. |
| `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex`, `.../layouts.ex`, both `assets/js/app.js` bundles | Theme preference and hook parity for standalone/mounted entrypoints. |
| `scrypath_ops/assets/css/app.css` and `priv/static/assets/css/app.css` | Existing tokens and generated/static asset parity. |
| `scrypath_ops/test/...` and `examples/scrypath_ecommerce/e2e/` | Existing contract, LiveView, and browser verification seams. |

## Common Pitfalls

- Treating task completion as document freshness; preserve the source meaning and label operational observation clearly.
- Dropping source offset/fractional precision by parsing then re-serializing or truncating to seconds.
- Computing relative labels from wall clock on each render, making a stable snapshot drift.
- Treating unknown, absent, future, or failed-source timestamps as zero, “never,” or success.
- Claiming copy succeeded when Clipboard API is missing or rejects; retain visible/selectable exact evidence on failure.
- Allowing localStorage exceptions to prevent app initialization; keep memory preference fallback and synchronize cross-tab updates.
- Styling status only by color, removing visible labels, or breaking focus/status announcement during async action changes.
- Verifying only standalone Ops: mounted app has a separate JS bundle and currently differs.
- Using the retained :4012 preview for mutating fixtures. Use a disposable stack.

## Validation Architecture

Validation is enabled in project config. Existing focused commands and relevant files were identified; commands were not run during this bounded research handoff. Treat them as planned verification, not test results.

| Req ID | Behavior | Test type | Automated command | Existing seam / gap |
|---|---|---|---|---|
| OPUX-09 | Flat neutral shell across themes and breakpoints | Contract + contrast + browser geometry | `mix verify.ops_ui`; `make -C examples/scrypath_ecommerce contrast` | Shell/token tests and `admin_shell_chrome.spec.ts`; replace obsolete gradient expectations. |
| OPUX-10 | Local explicit severity cues on neutral surfaces | Component + LiveView + browser | `cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs` | Exercise degraded/failed/unknown, retained failures and complete identifiers. |
| OPUX-11 | Neutral zero, distinct failure/unavailable metrics | Component + LiveView | Same focused Ops test command | Assert zero does not use success tone and unavailable is not zero. |
| OPUX-12 | Preference versus appearance, guarded storage, persistence | Browser state | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell` after disposable setup | Add storage denial/invalid values, OS changes, tabs, reload and patches for both entrypoints. |
| OPUX-13 | Quiet and busy action states, icon/label preservation | LiveView + browser | Focused Ops tests; `cd examples/scrypath_ecommerce && npm run test:e2e:admin-depth` after disposable setup | Exercise hover/focus/pressed/selected/disabled/busy plus server eligibility after patches. |
| OPUX-14 | Source ISO preservation, snapshot-stable age, accessible exact disclosure | Root unit + Ops LiveView + browser | `mix test test/scrypath/operator/status_test.exs`; focused Ops test command | Offset/fractional/future/absent/unknown/failed-source fixtures and unrelated rerenders. |
| OPUX-15 | Awaited clipboard success; denied/unavailable outcomes in both bundles | Browser with deferred/rejected clipboard stubs | Focused depth spec after disposable setup | Exact payload, repeated success reset, four-second dismissal, persistent failure, manual selection, Checked no-copy. |

Run Ops test paths from the `scrypath_ops` Mix project, not as `mix test scrypath_ops/test/...` from the root. Static contrast is service-free. Browser scripts named above exist in the ecommerce package manifest, but invocation alone does not start a server or prove standalone coverage. The planner must specify/create bounded disposable orchestration and fixture seams before listing those commands as complete gates. Existing canonical mounted orchestration is `make -C examples/scrypath_ecommerce verify-mounted`; the full advisory orchestration is `make -C examples/scrypath_ecommerce verify-e2e`. Keep the retained :4012 preview untouched. Product tests have not run in this planning task.

**Evidence boundary:** UI-SPEC static comp captures document visual exploration only; they do not establish LiveView behavior, browser storage resilience, clipboard truth, keyboard accessibility, or parity. Those require application tests/browser gates. Exact live browser command invocation and fixture stack orchestration remain unverified in this handoff.

## Project Baseline and Open Verification

The worktree had pre-existing dirty edits in Ops CSS, components, LiveViews, tests, design/reference docs, and mounted E2E coverage, plus untracked planning/design files. Phase 173 overlaps several of those paths. Preserve that baseline and review diffs before planning ownership; do not infer it is phase implementation or revert it. The retained preview is at `http://127.0.0.1:4012/admin/search` and must remain untouched.

Environment observed: Elixir 1.20.4, OTP 29, Node 22.14.0, Docker Compose 5.1.3, and a local Playwright binary. The prescribed tests were not run. Exact current status of the disposable-stack browser runner and current generated CSS synchronization are unverified.

## Security Domain

This phase does not alter authentication or authorization boundaries. Relevant browser controls are handling denied storage access safely, using Clipboard API promises without overstating success, and preserving accessible status semantics. ASVS categories V2 Authentication, V3 Session Management, V4 Access Control, and V6 Cryptography do not appear directly changed; V5 input validation is not a material new surface. [ASSUMED: based on bounded phase scope; verify if implementation expands to auth or server-supplied HTML]

## Sources

- [CITED: Phoenix LiveView JS interoperability](https://phoenix-live-view.hexdocs.pm/1.1.27/js-interop.html)
- [CITED: Clipboard.writeText](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText)
- [CITED: Window.localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage)
- [CITED: WCAG Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html)
- [CITED: WCAG Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html)
- [CITED: Oban.Job](https://oban.hexdocs.pm/Oban.Job.html); [CITED: Meilisearch v1.6 task completion fields](https://updates.cloud.meilisearch.com/publications/meilisearch-v1-6)
- [VERIFIED: in-repo source paths and exact quotes cited inline above]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Security scope remains limited to browser storage/clipboard/accessibility. | Security Domain | An implementation expansion could introduce auth or unsafe HTML concerns. |
| A2 | Existing generated static CSS should remain synchronized with source CSS. | Implementation seams | Build workflow may regenerate it differently; verify the project task during planning/execution. |

## Metadata

**Confidence breakdown:** stack HIGH (existing repo-native stack and no dependency decision); architecture MEDIUM (source seams inspected, browser behavior supported by primary docs); pitfalls MEDIUM (current source establishes concrete failure modes; browser gates not executed).  
**Research date:** 2026-10-06  
**Valid until:** 2026-11-05
