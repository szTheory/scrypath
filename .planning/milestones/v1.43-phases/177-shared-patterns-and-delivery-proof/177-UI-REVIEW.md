# Phase 177 — UI Review

**Audited:** 2026-10-12
**Baseline:** Approved `177-UI-SPEC.md`, Phase 177 context, delivered six-surface source, and retained direct image/interaction evidence
**Screenshots:** captured (90 direct images: 10 screen/state captures × 3 appearance modes × 3 viewport sizes; before/after at `examples/scrypath_ecommerce/test-results/phase177-before/` and `phase177-after/`)
**Interaction captures:** captured (60 selected Search/Playbooks depth images; see phase audit). No additional live capture performed because retained source-bound evidence exists and the example server was not needed.

The current product UI sources are unchanged since the evidence source SHA `6f227c062655d031e2bcb1484c939ad28ccc5290`; the worktree HEAD is later merge `ab9eb4a28f724c468ef76b4c59355333bc23f174`. The CSS correction’s exact baseline/after SHA and reports are recorded in `177-UI-AUDIT.md`. No code was changed for this review. Prior design approval establishes scope and tokens; it does not waive any unproven accessibility or visual defects.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Surface-specific task, empty, error, and recovery copy matches the contract; no generic task labels found in the audited surfaces. |
| 2. Visuals | 3/4 | Distinct scan paths and responsive compositions are evidenced; small legacy metric/eyebrow text remains dense and has AAA advisory contrast findings. |
| 3. Color | 3/4 | Corrected muted text and neutral-link AA defects; all retained rendered contrast scenarios pass AA, while legacy subtle roles still miss AAA. |
| 4. Typography | 3/4 | Strong heading/body hierarchy, but existing 11–12px compact labels/metadata and 600–700 weights remain below the phase’s preferred size/weight set. |
| 5. Spacing | 4/4 | The only Phase 177 spacing-related source delta is none; existing role tokens and responsive compositions remain governed by the inherited CSS/catalog contract. |
| 6. Experience Design | 4/4 | State-specific copy, action eligibility, refresh/loading semantics, modal confirmation, status announcements, and keyboard/interaction evidence are present. |

**Overall: 21/24**

---

## Top 3 Priority Fixes

1. **Raise compact metric labels and eyebrow/metadata text to the 14px body size where it carries required operational meaning** — improves scan/readability for dense health and recovery views — target the `ops_metric/1` and `ops_verdict/1` label roles in `ops_ui.ex`, then recapture representative changed slices in all nine theme/viewport combinations and rerun rendered contrast checks.
2. **Resolve the remaining AAA contrast advisories for repeated muted roles** — increases readability for low-vision operators, especially in light appearance — review `.ops-copper-eyebrow`, `.text-base-content/70`, and `.text-base-content/75` consumers against actual composed backgrounds; preserve status/accent roles and maintain AA while moving toward 7:1 where feasible.
3. **Unify compact token usage with the phase typography contract in a separately scoped UI change** — keeps labels, actions, and secondary evidence consistent across six surfaces — replace 11–12px helper treatments and 650/700 weights only where they carry meaningful copy; retain compact purely decorative metadata only with explicit rationale and visual verification.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- The approved UI contract defines six distinct tasks and exact contextual language. The current source preserves these distinctions, including “Start recovery,” “Pre-flight sync drift,” “Explore search,” “Refresh search health,” “Retry sync work,” “Run search,” and “Load preview.” See [control_room_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex:116), [posture_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex:142), [failed_sync_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex:527), [sync_drift_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1007), [search_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:787), and [playbook_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:952).
- Empty, missing-configuration, unavailable, and error states retain their distinct recovery instructions; the health verdict explicitly avoids claiming freshness ([control_room_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex:142)). No vague “Something went wrong” or generic submit/cancel copy was found in the relevant screens.
- Warning classification: none. This score reflects the declared contract and inspected source, not a claim that every possible runtime state was visually captured.

### Pillar 2: Visuals (3/4)

- Ten representative screen/state captures cover Control Room, Search health, Failed sync work, Sync and drift, Search results and zero results, and Playbooks empty workspace. Each has light, dark, and unoverridden System-dark at 390×844, 768×900, and 1440×900. Direct inspection and mapped after-images are recorded in [177-UI-AUDIT.md](177-UI-AUDIT.md).
- The six screen scan paths remain purpose-specific: posture/evidence/intent routes; fleet metrics/per-schema signals; failed-job eligibility and reasons; sync/queue/drift/freshness/promotion; bounded search criteria/result attribution; and workspace/catalog/preview/run. The baseline audit records 90 matching before/after filenames and 60 separate interaction-depth images.
- **WARNING:** compact labels are visually quieter and denser than the phase typography contract’s 14px copy target. The retained contrast report also records repeated AAA advisories for `.ops-copper-eyebrow` (4.55:1 light, 5.37:1 dark), `.text-base-content/70` (5.72:1 light), and `.text-base-content/75` (6.77:1 light). This does not fail AA, but slightly weakens secondary evidence hierarchy/readability.
- No current clipping or document-level overflow defect is established by the retained representative images and executable layout evidence. The scope does not imply every item in the 48-row state matrix received its own direct screenshot.

### Pillar 3: Color (3/4)

- The UI-SPEC palette and status semantics are reflected in the light/dark theme tokens. The Phase 177 source fix at `6f227c0` corrected two actual contrast defects: muted text cascade behavior and low-contrast neutral operator-guide links. Matched direct images show the correction, and the retained rendered axe reports show zero AA failures for incident, all-green, and empty scenarios.
- **WARNING:** AAA advisory findings remain (43 from the token checker; 80/80/32 rows across the three rendered axe scenarios). They cluster in small or muted text and are advisory rather than AA failures. The recommendation is to improve frequently read labels and supporting copy where the design can sustain it, not to use accent/status color more broadly.
- The before/after contrast findings and exact source identities are documented in [177-UI-AUDIT.md](177-UI-AUDIT.md). No third-party component registry applies; `components.json` is absent and the UI-SPEC declares no registry.

### Pillar 4: Typography (3/4)

- The six surfaces use a clear heading ladder and technical monospace treatment for exact identifiers. The existing token names establish body at 14px, subsection at 16px, section at 18px, and page title at 24px ([app.css](../../../scrypath_ops/assets/css/app.css:194)).
- **WARNING:** the established system also uses `--text-ops-xs` at 11px and `--text-ops-sm` at 12px, and the LiveView/component source uses these for metric labels, eyebrows, and supporting metadata; some legacy rules specify weight 650 or 700. The phase contract says changed work should use 14px body copy and only two weights. These compact values predate the Phase 177 contrast-only production delta, so they are not a scope violation by this phase, but they remain a legibility/polish gap relative to the approved contract’s target hierarchy.
- No new phase-specific typography was introduced; retain the current hierarchy and consider compact text remediation as a deliberate, visually verified change.

### Pillar 5: Spacing (4/4)

- The UI-SPEC applies its 4/8/16/24/32/48/64px scale to spacing introduced or changed by Phase 177. The sole production UI delta was CSS color/cascade behavior; no spacing declarations, template grouping, or layout breakpoints changed from the evidenced source SHA.
- Existing named `ops-*` roles and compact internals remain governed by `app.css` and `DESIGN-TOKENS.md`, as the contract explicitly requires. Their presence is not counted as a Phase 177 spacing defect. The direct matrix covers all three required widths and the source audit did not identify a concrete spacing or reachability defect.
- No spacing correction is recommended from this phase’s evidence.

### Pillar 6: Experience Design (4/4)

- Required evidence states are represented in current LiveView logic: unconfigured/missing backend, unavailable refresh, observed/degraded, empty, failed, partial, and success/no-results. Actions stay tied to eligibility and accepted work is not presented as completed; copy and receipts distinguish these states.
- Shared components provide accessible names and announcements for controls and async results. Examples include labelled Control Room sections and status role ([control_room_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex:100)), Search Results’ polite live region ([search_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:1044)), modal initial focus and labeled cancel action ([failed_sync_live.ex](../../../scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex:717)), and timestamp copy feedback ([ops_ui.ex](../../../scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1286)).
- Recorded executable evidence includes focused LiveView suites (68 operational tests and 55 Search/Playbooks tests), the full `mix verify.ops_ui` result (302 tests, 0 failures), 38 surface-depth tests, and a complete three-scenario rendered AA contrast pass. These are historical reports bound to the recorded source SHA; product UI source is unchanged since that SHA.
- No unresolved accessible-name, state, or task-completion blocker is confirmed from current source/evidence. The prior approval is treated as scope approval only; the typography/AAA advisories above remain review findings, not accepted waivers.

---

## Files Audited

- `.planning/phases/177-shared-patterns-and-delivery-proof/177-UI-SPEC.md`
- `.planning/phases/177-shared-patterns-and-delivery-proof/177-CONTEXT.md`
- `.planning/phases/177-shared-patterns-and-delivery-proof/177-01-PLAN.md` through `177-05-PLAN.md`
- `.planning/phases/177-shared-patterns-and-delivery-proof/177-01-SUMMARY.md` through `177-05-SUMMARY.md`
- `.planning/phases/177-shared-patterns-and-delivery-proof/177-UI-AUDIT.md` and `177-VALIDATION.md`
- `scrypath_ops/assets/css/app.css`, `scrypath_ops/assets/css/DESIGN-TOKENS.md`
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex`
- `examples/scrypath_ecommerce/test-results/phase177-before/` and `phase177-after/` (90 each)
- `examples/scrypath_ecommerce/test-results/phase177-before-depth/` and `phase177-after-depth/` (60 selected interaction images)
- `examples/scrypath_ecommerce/test-results/phase177-after-contrast/` (three rendered contrast scenario reports)
