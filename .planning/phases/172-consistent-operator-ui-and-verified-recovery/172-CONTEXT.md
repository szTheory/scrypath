# Phase 172: Consistent Operator UI and Verified Recovery

**Captured:** 2026-10-03 from the maintainer's explicit UI cleanup direction and approved v1.42 scope. This records existing answers; no new interview or approval is pending.

## Phase boundary

Improve the six existing ScrypathOps surfaces through shared consistency/accessibility repairs and an honest, schema-preserving incident recovery journey. See OPUX-01–08 and the roadmap's five success criteria. No new core API, authorization product, backend abstraction, or brand replacement.

## Decisions

- Show the current UI and retain an optional live feedback preview while work proceeds. User feedback can steer design; routine acceptance is automated. The latest request authorizes investigation, specialist fanout, implementation, and a clean finish.
- Use existing project evidence and conventional operational UI patterns. Preserve the shell, palette, system fonts, six surfaces, and shared component architecture. Avoid design churn, tiny action text, needless columns, and tables chosen merely for convenience.
- Keep current state, affected object, and next safe action prominent. Use coherent domain nouns and verb–object labels. Keep frequent actions visible and verbose technical evidence secondary.
- Use consistent named typography, spacing, padding, radius, color, shadow, motion, and layering roles. Inventory actual components and update their authority documentation alongside changed behavior.
- Make narrow layouts useful first; cover wide layouts, long identifiers, keyboard/focus, loading, setup-empty, errors, partial and stale data. Use semantic controls and full dialog focus lifecycle.
- Incident recovery leads the work: Control Room → Posture → Failed Sync → Sync/Drift, retaining the chosen allowed schema. Advanced index promotion is separate, has current eligibility enforced server-side, and never reports accepted tasks as completed.
- Recovery can succeed while original failure history remains. Prove newly accepted work and terminal backend success against a unique expected document in the correct active index. Do not force a global green status or zero failed-history count.
- Automate meaningful recurring checks in existing lanes. Use direct agent screenshot inspection, deterministic browser/layout/focus tests, LiveView tests, and both-theme contrast. No paid visual judge or new required job by default; broad screenshots remain advisory.
- Preserve Phase 170's frozen history and never rerun it. Keep completion bookkeeping writable: final source attestation follows completion tracking; later receipts can live in external CI/PR records and a separate planning-only successor without pretending they are the attested source tree.
- Finish through reviewed PR-first delivery, current required CI, explicit release/no-release decision, and clean task-owned artifacts/services. Preserve unrelated worktrees and stashes.

## Agent discretion

Choose bounded component, wording, layout, and test implementations that satisfy the existing requirements and observed findings. No repeat scope/theme interview is needed. Validate hypotheses before adding incidental repairs. Partition plans by ownership and meaningful outcomes, not a phase per document.

## Evidence and preview

- `.planning/reference/OPERATOR-UI-QUALITY.md` — durable future defaults.
- `.planning/research/v1.42/{SUMMARY,UI-STRUCTURE,UI-SYSTEM,UI-AUTOMATION}.md` — current findings, personas/JTBD, complete component inventory, and proof limitations.
- `scrypath_ops/docs/operator-ia.md`, `scrypath_ops/assets/css/DESIGN-TOKENS.md`, relevant `prompts/` — existing product/system authority.
- Preview: http://127.0.0.1:4012/admin/search, Compose project `scrypath-ui-v142`, worktree `/private/tmp/scrypath-admin-ui`. Never run reset/seed tests against this feedback instance.
- Baseline screenshots: `/private/tmp/scrypath-v142-review/`, outside tracked source. Visual observations are not runtime acceptance results.

## Deferred ideas

New workflows, frameworks/themes, wholesale CSS rewrites, paid review services, new core/host auth APIs, exhaustive matrices, and incidental changes without a named user impact require separate evidence. No remaining subjective choice blocks these established repairs.
