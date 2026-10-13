# Phase 174 — UI Review

**Audited:** 2026-10-13
**Baseline:** Approved [174-UI-SPEC.md](174-UI-SPEC.md), Phase 174 decisions D-01–D-05, and Phase 173 shared visual foundation
**Source revision:** `e92d5ae4e1131f792aab0185933c2c480885836e`
**Screenshots:** Not captured. `localhost:8080` answered, but it was not verified to serve this worktree; the known `localhost:4012` preview serves the normal checkout and was excluded.
**Interaction captures:** off (`workflow.ui_interaction_capture=false`)

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Partial refresh now distinguishes retained prior evidence from the case where no complete observation exists; tests assert no false success. |
| 2. Visuals | 3/4 | Contracted verdict → primary health route → secondary intents hierarchy is present, but current-source composition could not be inspected in a screenshot. |
| 3. Color | 3/4 | Semantic theme tokens, visible state text, and prior 0-AA-failure evidence support compliance; the 60/30/10 composition is not visually measurable at this revision. |
| 4. Typography | 4/4 | Audited phase surfaces use the shared `text-ops-*` hierarchy and monospace technical identities, without phase-specific type overrides. |
| 5. Spacing | 4/4 | Phase-owned additions use the contract’s 4/8/16/24/32px scale; no new arbitrary spacing appears in the audited templates. |
| 6. Experience Design | 4/4 | Partial-refresh, empty/setup, unavailable, and retry states are explicit; current-source Control Room and Search health tests pass. |

**Overall: 22/24**

## Top 3 Priority Fixes

1. **Capture Control Room and Search health at `e92d5ae4` from this worktree when a matching preview is available** — the current composition and responsive balance remain unverified visually — capture desktop, tablet, and mobile views from a server proven to use this worktree.
2. **Capture a matching-source view of the warning/error states** — the current UI relies on semantic state color plus text, but color distribution cannot be assessed from source alone — inspect both light and dark themes and confirm accent stays within the contract’s interaction-only roles.
3. **Refresh the responsive/focus/theme browser evidence after the latest delta** — prior Phase 174 evidence covers these contracts but predates this source revision — rerun the existing mounted/standalone browser matrix against the exact current source when that verification lane is available.

These are evidence gaps, not identified implementation blockers. No further code change is indicated by this audit.

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- The added no-prior-observation state says, “No prior complete observation is available; this partial result does not confirm current health.” It avoids presenting the healthy copy as a fresh result. See `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex:107-133`.
- If a prior complete observation exists, the notice identifies it as retained and says the refresh did not confirm current health. If schemas or backend are unavailable, the notice points to the setup guidance instead. This keeps the message aligned with the evidence available.
- Search health refresh no longer exposes raw backend error terms. It uses bounded, actionable copy, including HTTP status where appropriate, and tells the operator to refresh. See `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex:430-466`.
- Current-source tests assert the partial observation copy, retained-evidence distinction, absence of “Search health refreshed.”, empty-allowlist outcome, and missing-backend outcome.

### Pillar 2: Visuals (3/4)

- Control Room keeps the title and refresh in the toolbar, then renders one health verdict, its state/scope, the single primary **Inspect Search health** route, secondary intent cards, and the quiet guide. See `control_room_live.ex:87-217`.
- Search health keeps one article per schema with identity-first content and plain backend/queue groups; failed sync details remain disclosure-based rather than nested diagnostic cards. See `posture_live.ex:314-458` and `failed_sync_live.ex:600-694`.
- **WARNING:** No screenshot from this source revision was captured. Port 8080 answered but could not be tied to this worktree, and the known port 4012 preview serves another checkout. Visual composition, card balance, and mobile stacking therefore remain code-derived rather than directly observed.

### Pillar 3: Color (3/4)

- State meaning is conveyed with explicit labels and text, not hue alone. Failure copy uses the semantic `text-error` role; links and primary actions use shared interaction styles. The phase UI contract prohibits full warning/error surface fills and reserves accent for actual links/actions, navigation, selection, and focus.
- Phase 174’s recorded contrast gate reports 0 AA failures (43 AAA advisories) at the earlier exact revision `2375f6b71f57037e9e636ae060828e26f59a82c6`.
- **WARNING:** There is no screenshot at `e92d5ae4`, so the 60/30/10 surface distribution and light/dark composition are not confirmed for this revision. Prior contrast evidence is not proof of current visual distribution.

### Pillar 4: Typography (4/4)

- Shared components provide the heading/body hierarchy (`text-ops-h1`, `text-ops-h2`, `text-ops-h3`, `text-ops-body`, `text-ops-sm`); schema/module identities use monospace. The three phase LiveViews introduce no arbitrary font-size or weight override in the inspected templates.
- Full schema and work identities remain present in the markup, consistent with the contract’s wrap-instead-of-shrink rule. Responsive visual wrapping is backed by the earlier browser matrix, not a screenshot from this revision.

### Pillar 5: Spacing (4/4)

- Phase 174 permits only 4px, 8px, 16px, 24px, 32px, 48px, and 64px for newly introduced spacing. The current-source additions use `gap-ops-2`/`mt-ops-1` (4/8px) in Search health and the reviewed Control Room rhythm uses 8px/16px steps. See `posture_live.ex:438-444` and `control_room_live.ex:87-191`.
- Existing `mt-3` spacing in Failed sync empty/reference content and pre-existing shared control geometry are inherited Phase 173 values, not new Phase 174 overrides. No new arbitrary pixel/rem spacing was found in the inspected phase templates.

### Pillar 6: Experience Design (4/4)

- The Control Room now distinguishes (a) a partial refresh with a retained complete observation, (b) partial evidence with no prior complete observation, and (c) setup states where no schema health observation was possible. It preserves evidence and omits success feedback when the refresh is incomplete.
- Search health derives refresh success and telemetry outcome from nonempty schema observations with zero observation errors. Current tests assert degraded telemetry and no success feedback for both no configured schemas and missing backend; current tests also verify safe fetch-error copy and avoid leaking response-body content.
- Focused current-source verification: `mix test test/scrypath_ops_web/live/control_room_live_test.exs test/scrypath_ops_web/live/posture_live_test.exs` — **26 tests, 0 failures** using Elixir 1.19.5 / OTP 28. A compiler type warning was printed from `scrypath/lib/scrypath/sync.ex` and is outside this UI review’s scope.
- The prior exact-source browser evidence at `2375f6b71f57037e9e636ae060828e26f59a82c6` recorded mounted operator journeys 4/4, Phase 173 responsive/theme status 6/6, and 0 AA contrast failures. This evidence predates the current source and is reported as historical support, not a current exact-SHA browser pass.

## Registry Safety

Skipped: `.planning/phases/174-recovery-entry-and-diagnosis/174-UI-SPEC.md` records `shadcn_initialized: false`, and no `components.json` is present. No third-party UI registry blocks are declared.

## Files Audited

- `.planning/phases/174-recovery-entry-and-diagnosis/174-UI-SPEC.md`
- `.planning/phases/174-recovery-entry-and-diagnosis/174-CONTEXT.md`
- `.planning/phases/174-recovery-entry-and-diagnosis/174-DISCUSSION-LOG.md`
- `.planning/phases/174-recovery-entry-and-diagnosis/174-01-PLAN.md`, `174-02-PLAN.md`, `174-03-PLAN.md`
- `.planning/phases/174-recovery-entry-and-diagnosis/174-01-SUMMARY.md`, `174-02-SUMMARY.md`, `174-03-SUMMARY.md`
- `.planning/phases/174-recovery-entry-and-diagnosis/174-VALIDATION.md`, `174-VERIFICATION.md`, `174-REVIEW-DISPOSITION.md`
- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
- `scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs`
- `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`
- `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs`
- `scrypath_ops/assets/css/app.css`, `scrypath_ops/assets/css/DESIGN-TOKENS.md`
- `examples/scrypath_ecommerce/e2e/operator.spec.ts`
- `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts`
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md`
