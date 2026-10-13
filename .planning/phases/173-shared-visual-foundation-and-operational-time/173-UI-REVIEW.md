# Phase 173 — UI Review

**Audited:** 2026-10-12
**Source:** `1174a53f87d73c4e658029866a49c41d345452d9`
**Baseline:** Approved [173-UI-SPEC.md](173-UI-SPEC.md), interpreted with the accepted compact-header follow-up in [175-03-SUMMARY.md](../175-repair-and-verification/175-03-SUMMARY.md#L172)
**Screenshots:** Captured by the exact-source Phase 173 status E2E run. Inspected mounted unavailable at 390px: `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-phase173/scrypath_phase173_status_1174a53f_45633/screenshots/mounted-unavailable-mobile-390.png`. The run also produced mounted and standalone status views at 320/390/1279/1280/1440px in both themes. `localhost:8080` served the unrelated Traefik Proxy dashboard, so no extra app screenshot was taken.
**Interaction captures:** off (workflow.ui_interaction_capture is absent; default is false)

The current-source mounted/standalone status browser suite passed 6/6 at this SHA and cleaned up its disposable Compose resources. The token contrast check passed at this source with 0 AA failures and 43 AAA advisories. The inspected mobile capture shows one readable 14px unavailable explanation and the retained two-column backend/queue evidence. Its “Fixture scenario” selector belongs to the test harness, not the shipped interface.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Observation errors now use safe, operator-readable summaries; response bodies and raw exception details stay out of the rendered row. |
| 2. Visuals | 4/4 | Current mobile capture preserves the status hierarchy and retained evidence; the compact theme icons are an accepted responsive exception. |
| 3. Color | 4/4 | Neutral surfaces and local status cues follow the contract; the current contrast check has zero AA failures. |
| 4. Typography | 4/4 | Error and queue explanations use the 14px body role, asserted in the current browser suite. |
| 5. Spacing | 3/4 | Layout rhythm and targets match the contract; a decorative cue retains a fractional `.45em` offset outside the named scale. |
| 6. Experience Design | 4/4 | Current status coverage exercises mounted and standalone paths, error/empty/partial states, retained evidence, refresh, and responsive behavior. |

**Overall: 23/24**

No blocker remains. The only product polish warning is the fractional notice-cue offset; the remaining priorities below preserve the verified privacy and responsive behavior.

## Top 3 Priority Fixes

1. **Replace the fractional notice-cue offset** — `.45em` is outside the approved spacing scale — align the cue with flex geometry or an existing named value when this shared rule is next touched.
2. **Keep the error-summary mapping and redaction regression** — operators get a useful HTTP/transport summary without seeing response-body secrets or raw exception terms — retain the source mapping and the LiveView assertion that rejects secret body content.
3. **Keep the compact-header exception explicitly covered** — Phase 175 found real label clipping at narrow widths and approved hidden theme labels through 420px — preserve the accessible names, 44px targets, and 320/390px coverage.

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- [posture_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex#L437) now renders one unavailable sentence plus refresh guidance. `fetch_error_copy/1` maps known HTTP, transport, invalid-payload, truncated-history, and unsupported-backend cases to safe descriptions; the fallback is also sanitized ([posture_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex#L567)).
- **Privacy pass:** the HTTP 503 case displays the status code without rendering its response body. [The regression test](../../../scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs#L386) asserts that a fixture credential in the body is absent from the rendered row. The browser test asserts the safe fallback and rejects the former raw fixture atom ([phase173_status_actions.spec.ts](../../../examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts#L104)).
- Retained evidence copy is derived only from the retained snapshot; it no longer interpolates a raw error reason. Empty, queue-unused, partial, retry, and observation-history copy remains explicit.

### Pillar 2: Visuals (4/4)

- The exact-source 390px capture has a clear Search health heading, purpose statement, refresh action, degraded/unavailable summary, neutral metric surfaces, and retained backend/queue evidence. The error icon stays beside the single reason, and the technical evidence wraps within the two-column retained grid. The same run captures mounted/standalone cases, both themes, and responsive/rail boundaries.
- **Accepted exception, not a finding:** At widths up to 420px, theme text labels are visually hidden while native buttons keep their accessible names and 44px targets. Phase 175 documented real 320/390px clipping and approved this behavior; see [175-03-SUMMARY.md](../175-repair-and-verification/175-03-SUMMARY.md#L172). Do not revive the old Phase 173 label-visibility warning.
- The fixture scenario selector in the E2E capture is test-only and is excluded from the product score.

### Pillar 3: Color (4/4)

- [app.css](../../../scrypath_ops/assets/css/app.css#L23) defines the warm-neutral light and neutral dark palettes. The reviewed screens keep status color local to warning/error cues, use neutral metric/schema surfaces, and reserve violet for selection and interaction.
- The exact-source token contrast command passed: 0 AA failures and 43 AAA advisories. The advisories remain advisory; no contrast blocker was found.

### Pillar 4: Typography (4/4)

- The unavailable reason and queue-unobserved explanation use `text-ops-body` (14px) in [posture_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex#L410). The current status E2E asserts 14px for the unavailable reason; the new 390px image shows the copy remains legible as it wraps.
- Exact timestamps and optional technical context use the existing compact/monospace roles allowed by the UI contract. No new type role was added for this correction.

### Pillar 5: Spacing (3/4)

- The retained backend/queue grid uses two equal `minmax(0, 1fr)` columns and the existing 8px gap; the browser test checks the two-column layout at 390px. Status E2E also verifies the 24px schema rhythm, no page/row overflow, and 40px-or-greater action targets at narrow and rail-boundary widths.
- **WARNING:** [app.css](../../../scrypath_ops/assets/css/app.css#L578) still sets the notice cue's `margin-top: 0.45em`. This is a small decorative alignment detail rather than a page-layout defect, but it is not part of the approved spacing scale.

### Pillar 6: Experience Design (4/4)

- The exact-source status suite passed 6/6 across mounted and standalone routes. It covers healthy/degraded/unavailable, unknown/unused queue, empty, and partial outcomes; checks the sanitized failure message and 14px role; preserves retained evidence; and asserts responsive layout behavior.
- The Search health summary does not turn unavailable/unknown observations into zero or success, and refresh remains an explicit recovery action. Current responsive shell behavior was separately exercised by the 14/14 shell suite at `749c9d1b`; that earlier run is not represented as an exact-`1174a53f` shell rerun.
- The status run does not itself re-run clipboard outcomes. The timestamp-copy implementation is unchanged by the final sanitization fix; its earlier Phase 173 proof remains recorded in `173-04-SUMMARY.md` at `b12a7c4`, and is not relabeled as a 1174a53f browser run.

## Registry Safety

`components.json` is absent and the approved UI spec sets `shadcn_initialized: false`; no third-party component registry is used. Registry audit skipped.

## Files Audited

- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md`
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-CONTEXT.md`
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-01-PLAN.md` through `173-04-PLAN.md`
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-01-SUMMARY.md` through `173-04-SUMMARY.md`
- `.planning/phases/175-repair-and-verification/175-03-SUMMARY.md`
- `scrypath_ops/assets/css/app.css`
- `scrypath_ops/assets/css/DESIGN-TOKENS.md`
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex`
- `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`
- `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts`
- Current mounted/standalone status screenshots and browser results under `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-phase173/scrypath_phase173_status_1174a53f_45633/`
