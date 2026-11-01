# Phase 184 — UI Review

**Audited:** 2026-10-30
**Baseline:** Abstract six-pillar standards, constrained by `184-CONTEXT.md` D-20's preservation scope and the existing `DESIGN.md` / operator quality model. No phase UI-SPEC exists.
**Screenshots:** Not captured — the named retained preview's required source preflight refused; the existing safety stop was preserved.
**Interaction captures:** off (workflow.ui_interaction_capture is false)
**Method:** Code-only phase review, comparison with the phase base, inspection of existing evidence records, and an isolated source-level gating reproduction. No new browser, keyboard, or live-preview observations.

## Scope and evidence limits

Phase 184 changes dependency availability, development diagnostics, optional authentication controls, and asset generation/runtime ownership. It authorizes preservation of the existing interface, not a redesign. This review uses `/private/tmp/scrypath-phase184-execution/review-files.txt` and `review-scope-metadata.json` rather than the smaller partial task-commit inventory. The inventory contains 63 surviving source/documentation/test files; deleted Mailer/test files were also accounted for through the execution summaries and source diff.

The reviewed checkout was `/Users/jon/projects/scrypath`, branch `planning/v1.45-foundation-ci`, HEAD `abd5e6ee5d872efd26e0e032d64afcc13556c7b4`. The comparison base was `aab0e0d349a867b92f96b20c38ae25eea34a2075`. The checkout's existing `.planning/config.json` edit was preserved. The only changes between hosted candidate `5173ceb49c4ec94154032592e7eaf487b6666df7` and this review HEAD were `AGENTS.md` and `184-VALIDATION.md`; the UI implementation therefore matches that candidate. This is file-content evidence, not a claim that the current planning successor already has its own terminal closeout.

The external `candidate-2-final.json` receipt reports successful required mounted verification, full ecommerce E2E, and Ops UI execution in [candidate CI run 41029783634](https://github.com/szTheory/scrypath/actions/runs/41029783634). It also retains the failed deep-quality advisory result for the unaccepted Cloak findings. These are recorded executable outcomes, not a new rendered critique by this auditor. The receipt remains at `/private/tmp/scrypath-phase184-10-20261030T072352Z/receipts/candidate-2-final.json`.

`184-06-SUMMARY.md` records an earlier disposable full-browser run, 30 light-parity captures, zero AA failures, 101 AAA advisory items, and selected visual inspection of Search and health at desktop/mobile sizes across themes. Its source and dirty-source fingerprint are explicitly recorded there. That selected inspection does not establish full-inventory aesthetic acceptance at the final candidate. This auditor did not inspect those images or relabel them as current captures.

### Retained preview disposition

`.planning/UI-PREVIEW.json` names `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`, branch `ui/next`, and `http://127.0.0.1:4002`. The Plan 10 record says its read-only `ui:preflight` refused because `origin/main` is absent. Its dirty `scrypath_ops/priv/static/assets/css/app.css` and untracked ecommerce playbooks remain preserved. This audit did not probe that URL or unrelated development ports, reconcile the checkout, restart/reseed services, change data, or collect screenshots.

No screenshot was attempted, so there are no failed capture files. The generic port-discovery/capture procedure was deliberately not run under the project-specific safety stop. The existing `.planning/ui-reviews/.gitignore` was inspected read-only and already contains all seven required image patterns plus `interaction/`; no storage change was needed. Future project UI evidence belongs in the documented `ui-review-artifacts/` lifecycle. No runtime receipt was copied into the checkout.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | New denied-action messages explain a technical requirement but omit the operator's recovery step. |
| 2. Visuals | 3/4, provisional | Presentation source is unchanged; current full-inventory rendered hierarchy is unreviewed. |
| 3. Color | 3/4, provisional | No new color/accent usage; current theme-wide distribution and denial-state contrast are unreviewed. |
| 4. Typography | 3/4, provisional | No new sizes/weights; wrapping and readability of the new denial text lack rendered evidence. |
| 5. Spacing | 3/4, provisional | No new spacing classes or layout values; actual compact denial-state geometry is unreviewed. |
| 6. Experience Design | 2/4 | A valid operator without a sudo timestamp loses the previous confirmation redirect. |

**Overall: 17/24 — phase-preservation assessment with limited rendered evidence.**

The four provisional visual grades mean source preservation is substantially supported, while excellence is not demonstrated by this code-only audit. Their warnings are evidence gaps, not four invented visual regressions. This number is not a whole-product design pass or an acceptance gate. Existing untouched design choices have not been reclassified as Phase 184 defects merely because a generic size/weight heuristic would flag them.

## Top 3 Priority Fixes

1. **Restore a reachable confirmation step for a valid operator with no sudo timestamp.** The new requested-Sigra branch leaves that operator at an error flash, while an expired timestamp opens confirmation. After validating identity and rejecting impersonation, route the ordinary unconfirmed state to the configured local confirmation path with encoded `return_to`, or provide an equivalent explicit confirmation action. Keep the protected callback unexecuted until confirmation; malformed identity, invalid/future timestamps, and unavailable integration must continue to fail closed. See finding E1.
2. **Make denied-action copy identify the next actor and step.** Missing identity/organization and unavailable integration need clear host/session repair guidance; confirmation failures need a named way to confirm again. Preserve precise diagnostic detail in developer startup errors. See finding C1.
3. **Add rendered coverage of the requested-Sigra interaction.** Use an isolated authenticated fixture to exercise an unconfirmed operator, malformed context, stale confirmation, and successful return through a real sensitive control. Check error announcement, focus, dialog visibility, and callback nonexecution. The existing saved-search UI fixture explicitly uses basic mode, so passing UI tests do not cover these new Sigra states. This is an evidence repair, not permission to use or alter the stopped retained preview. See finding E2.

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**C1 — WARNING, actual changed-copy issue: denial text lacks a recovery instruction.** `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex:82`, `:102`, `:107`, and `:213` tell the operator that identity/context, sudo confirmation, or the integration is required. They do not explain whether to confirm access again, restore the session/organization, or ask the host administrator to fix integration setup. This affects `ROLE-OPS` recovery work and `ROLE-OWNER` saved-search/index actions. The terms are legitimate for this engineering audience; the defect is the missing next step, not the presence of a technical noun.

Use state-specific recovery copy. For example, an ordinary unconfirmed operator should get a confirmation action; missing host context should say the action was blocked and direct the operator to restore the session or contact the host administrator. Avoid suggesting blind retries for a configuration failure. Do not disclose additional identity values in the flash.

Positive evidence: developer startup messages are more actionable. `security.ex:64` supplies the local-path configuration shape and existing support references; `integrations/sigra/capability.ex:14` explains installing the optional integration and recompiling. These messages are boot diagnostics, so implementation-specific detail is appropriate there. The reordered SearchLive error helpers at `search_live.ex:2051` and `:2059` retain their prior strings and behavior. No new generic Submit/OK/Save control label or new empty/loading screen was introduced by this phase.

### Pillar 2: Visuals (3/4, provisional)

**V1 — WARNING, evidence gap: full current rendered hierarchy and protected-action feedback were not inspected.** The maintained inventory is eight surfaces: storefront, Control Room, Search health, Failed sync work, Sync and drift, Search, Saved searches, and Help (`examples/scrypath_ecommerce/e2e/ui-review.mjs:12`). This audit checked that inventory before narrowing to changed dependency/auth effects. No new screen/theme/width observation is claimed for any of those surfaces. In particular, the new denial flash has not been assessed while a destructive-action sheet remains open.

The phase diff contains **zero added `class=` attributes** in the eight changed Ops runtime source files. There are no changes under either app's assets/static sources, the Ops shared components/layouts, or the storefront web components. SearchLive's only change moves three private helper clauses without changing HEEx (`search_live.ex:2059`). Existing shell hierarchy, skip link, named compact-navigation button, and labelled main region remain in `components/layouts.ex:50`, `:67`, and `:108`. The shared error flash retains `role="alert"`, an icon, and a labelled close button (`components/core_components.ex:48`, `:63`, `:69`). These are positive structural checks, not rendered/focus verification.

The development dashboard remains conditional on capability and route policy (`dev_router.ex:4`, `:71`). Removing `/dev/mailbox` is the approved removal of unused development tooling, not a missing operator destination. Supported `/ops` routing remains at `dev_router.ex:49`.

### Pillar 3: Color (3/4, provisional)

**K1 — WARNING, evidence gap: current 60/30/10 distribution and denial-state theme contrast are not established by source equality.** Do not infer an excellent color grade from brand-compliant primary tokens or a successful asset request.

Added-line scans of the changed Ops runtime files found **zero color literals and zero new accent classes**. Neither app's CSS/theme source changed. Existing light/dark primary values are in `scrypath_ops/assets/css/app.css:32` and `:76`; the shared flash keeps base-content text with a 90% base / 10% semantic error surface at `app.css:2429` and `:2440`. No accent-overuse regression was found in this phase. Existing token hex values are intentional authorities, not newly scattered hardcoded colors.

The asset boundary builds current source and verifies nonempty bundles (`Dockerfile:31`), copies only the static trees (`:67`, `:103`), and digests production output (`:71`). The runtime proof checks bytes, hashes, and Content-Type (`verify-dependency-boundaries.sh:664`). These checks support stylesheet delivery; they cannot measure perceived accent distribution or certify contrast on every state. Earlier AA results and AAA advisories remain bound to their recorded run.

### Pillar 4: Typography (3/4, provisional)

**T1 — WARNING, evidence gap: the new denial text has no current rendered wrapping/readability observation.** This matters at narrow widths and alongside any active confirmation sheet. No clipped text or bad font size is asserted without that observation.

Added-line scans found **zero new typography utility classes**. Existing tokens remain 11/12/14/16/18px supporting roles and 24/18/16px heading roles (`app.css:196`, `:205`). In the unchanged CSS, font-size declarations reference body 30 times, small 45, extra-small 5, medium 2, section heading 1, and subsection heading 2; four other declarations use inheritance or existing literal rem sizes. Literal weight declarations use 400 (6), 500 (2), 600 (24), 650 (10), and 700 (3). These are declaration counts, not rendered text frequency. The established system includes metadata and component roles beyond a generic four-size/two-weight heuristic; this phase adds none and provides no basis for a typography redesign.

### Pillar 5: Spacing (3/4, provisional)

**S1 — WARNING, evidence gap: compact protected-action feedback geometry is not observed.** The new messages reuse the existing overlay, but source reuse does not prove that longer text, an open sheet, focus placement, and narrow navigation coexist correctly.

Added-line scans found **zero new spacing utilities or arbitrary spacing values** in the changed runtime files. Shell padding and responsive widths remain at `components/layouts.ex:108`; schema controls still wrap and use the shared spacing tokens (`app.css:1022`). The flash retains full-width, text-wrap structure (`core_components.ex:61`). No new density, shell rhythm, touch-target, or overflow defect was established. A future evidence pass should inspect the changed denial state at the documented 1440/768/390 widths and themes, without changing CSS merely to improve a provisional score.

### Pillar 6: Experience Design (2/4)

**E1 — WARNING, actual phase regression: an ordinary unconfirmed operator has no confirmation handoff.** `OperatorContext` explicitly permits `sudo_at: nil` and builds it when no confirmed timestamp exists (`integrations/sigra/operator_context.ex:6`, `:12`, `:39`). With valid user/org identity and no impersonation, the new Sigra branch sends that timestamp through `sudo_status/1`, whose fallback is `:invalid`; the result is only an error flash (`gating.ex:93`, `:101`, `:163`). An old timestamp instead calls `confirm_sudo/1` and preserves encoded `return_to` (`:98`, `:123`). Before this phase, `stale_sudo?(_)` returned true, so the same valid context with a nil timestamp reached confirmation.

A fresh isolated Elixir source probe exited 0 and produced:

```text
SOURCE_REPRO current_nil_sudo=error_without_redirect current_stale_sudo=confirmation_redirect baseline_nil_sudo=confirmation_redirect protected_callbacks=not_run
```

The probe loaded actual current and baseline gating source, using in-memory LiveView flash/navigation and Audit stubs. It proves branch behavior and callback nonexecution; it does not prove a real login/confirmation journey or a remote authentication issue. No endpoint, browser, database, preview, or persisted fixture was used. The actual supplied host may expose its own confirmation link, so this review does not claim every host configuration has an unavoidable task blocker. The shared UI handoff nevertheless regressed and should be repaired without weakening denial policy.

**E2 — WARNING, changed-state coverage gap: helper denial tests do not establish a usable rendered journey.** The new table explicitly includes `operator_context(sudo_at: nil)` and asserts a nonempty error flash (`gating_test.exs:48`, `:179`), thereby preserving the problematic UX. Stale/fresh sudo and host-mode callback checks exist at `:72`, `:101`, and `:133`. The saved-search LiveView fixture was changed to basic auth because its router lacks Sigra OnMount (`search_saved_searches_test.exs:32`). That is an honest fixture choice, but it leaves a gap for new requested-Sigra errors triggered by actual controls, including Saved search deletion (`search_live.ex:344`) and failed-work retry (`failed_sync_live.ex:307`). Verify recovery and announcement through those seams rather than accepting “a flash string exists” as UI completion.

Positive state evidence: requested unavailable Sigra fails during startup validation before supervision (`security.ex:26`; `application.ex:9`); invalid identity/impersonation cannot reach the sensitive callback; stale confirmation retains the return path; basic/proxy behavior remains host-owned. The clean-consumer suite checks dependency absence, startup, core children, and callback nonexecution (`test/release/ops_dependency_boundary_test.exs:35`, `:390`, `:436`). Core observation, PubSub, and TaskSupervisor remain independent of development diagnostics (`application.ex:21`). Missing asset output fails explicitly at runtime startup (`docker-e2e-entrypoint.sh:17`). No new asynchronous UI flow or destructive operation was added that would require inventing a new loading/empty-state design.

## Coverage disposition and recommendations

There are **two concrete changed-UI findings** (C1 and E1). E2 is the specific interaction-evidence repair; V1/K1/T1/S1 record overlapping rendered-coverage limits, not additional product defects. No BLOCKER was established by this audit. Subjective visual review remains nonblocking; no human UAT or simulated approval is introduced as phase acceptance.

The full inventory's setup → search, health → affected work → eligible recovery → document check, settings/change → evidence, query → saved check → replay, and Help journeys were not newly driven by this auditor. Existing executable results remain useful within their exact scope. The most useful next implementation action is the bounded confirmation-recovery repair with an isolated rendered Sigra fixture. A later complete visual critique can use a correctly proven source and owned evidence; the retained-preview stop persists until its cause is actually resolved by its owner.

The registry condition was checked after scoring: no `components.json` exists at root, Ops, or ecommerce, and no phase UI-SPEC declares third-party registries. The shadcn registry audit is not applicable; no registry package or external source was fetched.

## Files Audited

- Context and policy: `AGENTS.md`, `.planning/UI-PREVIEW.json`, `.planning/reference/UI-WORKTREE-LEARNINGS.md`, `examples/scrypath_ecommerce/e2e/UI-REVIEW.md`, `DESIGN.md`, `.planning/reference/OPERATOR-UI-QUALITY.md`; all twelve Phase 184 PLAN/SUMMARY pairs, `184-CONTEXT.md`, and `184-ACCEPTANCE.md`.
- Changed runtime/UI seams: `scrypath_ops/lib/scrypath_ops/application.ex`, `integrations/sigra/capability.ex`, `integrations/sigra/gating.ex`, `security.ex`, `scrypath_ops/lib/scrypath_ops_web/dev_router.ex`, `endpoint.ex`, `telemetry.ex`, and the `live/search_live.ex` diff.
- Adjacent feedback/auth/call sites: `integrations/sigra/operator_context.ex`, `on_mount.ex`, `scrypath_ops_web/components/core_components.ex`, `components/layouts.ex`, and targeted `live/failed_sync_live.ex` control wiring. These unchanged files provide context, not phase ownership.
- Presentation preservation: asset/static/component path diffs for both apps; targeted `scrypath_ops/assets/css/app.css` and `DESIGN-TOKENS.md` token, flash, typography, and wrapping rules.
- Build/runtime seams: `examples/scrypath_ecommerce/Dockerfile`, `docker-e2e-entrypoint.sh`, `scripts/phase173-standalone-entrypoint.sh`, `scripts/verify-dependency-boundaries.sh`, `config/prod.exs`, `config/runtime.exs`, and the changed Ops/ecommerce Mix dependency/asset aliases and configuration diffs.
- State/behavior evidence: `scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs`, `security_validation_test.exs`, the saved-search UI fixture diff, relevant `test/release/ops_dependency_boundary_test.exs` probes, and inventory/coverage definitions in `examples/scrypath_ecommerce/e2e/ui-review.mjs`, `ui_followup.spec.ts`, and `ui_reconciliation.spec.ts`.
- External metadata/receipt: `/private/tmp/scrypath-phase184-execution/review-files.txt`, `review-scope-metadata.json`, `review-evaluation-scope.json`, and `/private/tmp/scrypath-phase184-10-20261030T072352Z/receipts/candidate-2-final.json`. Raw runtime evidence remains outside the checkout.

**Recommendation count:** Three priority recommendations (two product repairs and one targeted evidence repair); one additional consolidated full-inventory visual-evidence recommendation. No source, config, service, visual baseline, or other report was changed by this audit.
